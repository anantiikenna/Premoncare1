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
// 3. RATE LIMITER (In-Memory / Upstash Redis)
// ==========================================
// IMPORTANT: The in-memory Map only works in single-instance deployments.
// For serverless (Netlify/Vercel), each function invocation creates a new Map.
// PRODUCTION RECOMMENDATION: Install @upstash/ratelimit + @upstash/redis
// and uncomment the Upstash implementation below.
//
// To enable Upstash:
//   1. npm install @upstash/ratelimit @upstash/redis
//   2. Add UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN to .env.local
//   3. Swap the implementation below (see UPSTASH block)

// --- In-Memory Implementation (development/single-instance only) ---
const ipRequestCache = new Map<string, { count: number, resetAt: number }>()
const RATE_LIMIT_WINDOW_MS = 60 * 1000 // 1 minute
const MAX_REQUESTS_PER_WINDOW = 60 // 60 requests per minute
const CLEANUP_INTERVAL_MS = 5 * 60 * 1000 // Cleanup stale entries every 5 min

// Periodic cleanup to prevent memory leaks from stale IPs
let lastCleanup = Date.now()
function maybeCleanup() {
    const now = Date.now()
    if (now - lastCleanup > CLEANUP_INTERVAL_MS) {
        lastCleanup = now
        for (const [ip, record] of ipRequestCache) {
            if (now > record.resetAt) ipRequestCache.delete(ip)
        }
    }
}

function getTrustedIp(req: NextRequest): string {
    // In production behind a reverse proxy, x-forwarded-for contains the real client IP
    const forwarded = req.headers.get('x-forwarded-for')
    if (forwarded) {
        // Take the first (leftmost) IP, which is the original client
        const firstIp = forwarded.split(',')[0]?.trim()
        if (firstIp) return firstIp
    }
    return req.headers.get('x-real-ip') || 'unknown'
}

function checkRateLimit(ip: string): boolean {
    maybeCleanup()
    const now = Date.now()
    const record = ipRequestCache.get(ip)

    if (!record || now > record.resetAt) {
        ipRequestCache.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS })
        return true
    }

    if (record.count >= MAX_REQUESTS_PER_WINDOW) {
        return false
    }

    record.count++
    return true
}

// --- Upstash Implementation (production serverless) ---
// Uncomment below and comment out in-memory implementation above:
/*
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
    redis: Redis.fromEnv(),
    limiter: Ratelimit.slidingWindow(MAX_REQUESTS_PER_WINDOW, `${RATE_LIMIT_WINDOW_MS / 1000} s`),
    analytics: true,
})

async function checkRateLimitUpstash(ip: string): Promise<boolean> {
    const { success } = await ratelimit.limit(ip)
    return success
}
*/

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
        const ip = getTrustedIp(req)
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
