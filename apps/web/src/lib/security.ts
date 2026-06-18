import DOMPurify from 'isomorphic-dompurify'
import { NextResponse, type NextRequest } from 'next/server'
import { createClient } from './supabase-server'

// ==========================================
// 1. INPUT SANITIZATION
// ==========================================

export function sanitizeInput(input: string | undefined | null): string {
    if (!input) return ''
    return DOMPurify.sanitize(input.trim())
}

export function sanitizeObject<T extends Record<string, any>>(obj: T): T {
    const sanitized = { ...obj }
    for (const key in sanitized) {
        if (typeof sanitized[key] === 'string') {
            sanitized[key] = sanitizeInput(sanitized[key] as string) as any
        } else if (typeof sanitized[key] === 'object' && sanitized[key] !== null && !Array.isArray(sanitized[key])) {
            sanitized[key] = sanitizeObject(sanitized[key]) as any
        }
    }
    return sanitized
}

// ==========================================
// 2. CORS MANAGEMENT
// ==========================================

const ALLOWED_ORIGINS = process.env.ALLOWED_CORS_ORIGINS 
    ? process.env.ALLOWED_CORS_ORIGINS.split(',').map(o => o.trim())
    : ['http://localhost:3000', 'capacitor://localhost', 'http://localhost', 'https://premoncare.netlify.app']

export function setCorsHeaders(res: NextResponse, requestOrigin: string | null) {
    if (requestOrigin && ALLOWED_ORIGINS.includes(requestOrigin)) {
        res.headers.set('Access-Control-Allow-Origin', requestOrigin)
        res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        res.headers.set('Access-Control-Allow-Credentials', 'true')
    }
    return res
}

// ==========================================
// 3. RATE LIMITER (In-Memory / Redis pattern)
// ==========================================
// NOTE: Best practice advice dictates using Upstash/Redis for global serverless state.
// Since you may scale, we wrap our simple memory Map in a way that can be easily swapped.
// If UPSTASH_REDIS_REST_URL is configured, you could insert real @upstash/ratelimit logic here.
const ipRequestCache = new Map<string, { count: number, timestamp: number }>()
const RATE_LIMIT_WINDOW_MS = 60 * 1000 // 1 minute
const MAX_REQUESTS_PER_WINDOW = 60 // 60 requests per minute

function checkRateLimit(ip: string): boolean {
    const now = Date.now()
    const record = ipRequestCache.get(ip)

    if (!record) {
        ipRequestCache.set(ip, { count: 1, timestamp: now })
        return true
    }

    if (now - record.timestamp > RATE_LIMIT_WINDOW_MS) {
        // Reset window
        ipRequestCache.set(ip, { count: 1, timestamp: now })
        return true
    }

    if (record.count >= MAX_REQUESTS_PER_WINDOW) {
        return false // Rate limit exceeded
    }

    record.count++
    return true
}

// ==========================================
// 4. ROUTE PROTECTION HIGHER-ORDER WRAPPER
// ==========================================

type SecurityOptions = {
    requireAuth?: boolean
    requireRoles?: ('patient' | 'doctor' | 'admin')[]
    isWebhook?: boolean
}

export async function withSecurity(
    req: NextRequest, 
    handler: (req: NextRequest, sessionUser?: any) => Promise<NextResponse>,
    options: SecurityOptions = { requireAuth: true, isWebhook: false }
): Promise<NextResponse> {
    const requestOrigin = req.headers.get('origin')
    
    // Handle OPTIONS Preflight for CORS
    if (req.method === 'OPTIONS') {
        const preflightRes = new NextResponse(null, { status: 204 })
        return setCorsHeaders(preflightRes, requestOrigin)
    }

    // 1. Rate Limiting Check
    if (!options.isWebhook) {
        const ip = req.headers.get('x-forwarded-for') || 'unknown'
        if (!checkRateLimit(ip)) {
            const res = NextResponse.json({ error: 'Too Many Requests' }, { status: 429 })
            return setCorsHeaders(res, requestOrigin)
        }
    }

    // 2. Authentication Check
    let sessionUser = null
    if (options.requireAuth) {
        const supabase = await createClient()
        const { data: { user }, error: authError } = await supabase.auth.getUser()
        
        if (authError || !user) {
            const res = NextResponse.json({ error: 'Unauthorized Access' }, { status: 401 })
            return setCorsHeaders(res, requestOrigin)
        }

        sessionUser = user

        // Role verification logic
        if (options.requireRoles && options.requireRoles.length > 0) {
            const { data: profile } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single()
                
            if (!profile || !options.requireRoles.includes(profile.role)) {
                const res = NextResponse.json({ error: 'Forbidden' }, { status: 403 })
                return setCorsHeaders(res, requestOrigin)
            }
        }
    }

    try {
        // Run handler
        const response = await handler(req, sessionUser)
        return setCorsHeaders(response, requestOrigin)
    } catch (error) {
        console.error('[API Error]:', error)
        // Prevent exposing internal stacktraces to client
        const res = NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
        return setCorsHeaders(res, requestOrigin)
    }
}
