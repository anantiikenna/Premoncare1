import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

const PUBLIC_ROUTES = ['/', '/login', '/register', '/emergency', '/emergency-waiting', '/support', '/account-conversion']

export async function updateSession(request: NextRequest) {
    let supabaseResponse = NextResponse.next({
        request,
    })

    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY

    const supabase = createServerClient(
        url || 'https://placeholder.supabase.co',
        key || 'placeholder-key',
        {
            cookies: {
                getAll() {
                    return request.cookies.getAll()
                },
                setAll(cookiesToSet) {
                    cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
                    supabaseResponse = NextResponse.next({
                        request,
                    })
                    cookiesToSet.forEach(({ name, value, options }) =>
                        supabaseResponse.cookies.set(name, value, options)
                    )
                },
            },
        }
    )

    const pathname = request.nextUrl.pathname

    // Skip auth check for purely public routes to avoid blocking page loads
    if (PUBLIC_ROUTES.includes(pathname)) {
        return supabaseResponse
    }

    // refreshing the auth token
    const { data: { user } } = await supabase.auth.getUser()

    // Handle protected routes
    if (!user && (
        pathname.startsWith('/admin') ||
        pathname.startsWith('/doctor') ||
        pathname.startsWith('/patient') ||
        pathname.startsWith('/notifications') ||
        pathname.startsWith('/messages') ||
        pathname.startsWith('/profile')
    )) {
        return NextResponse.redirect(new URL('/login', request.url))
    }

    if (user) {
        // Fetch role to enforce route protection
        let role = request.cookies.get('premon_role')?.value

        if (!role) {
            const { data: profile } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single()

            role = profile?.role || 'patient'
            
            // Cache role in cookie to skip DB query on next request
            supabaseResponse.cookies.set('premon_role', role, {
                path: '/',
                maxAge: 60 * 60 * 24 * 7, // 1 week
                httpOnly: false,
                secure: process.env.NODE_ENV === 'production',
                sameSite: 'lax',
            })
        }

        // Prevent cross-role access
        if (pathname.startsWith('/admin') && role !== 'admin') {
            return NextResponse.redirect(new URL(`/${role}/dashboard`, request.url))
        }
        if (pathname.startsWith('/doctor') && pathname !== '/doctor/apply' && role !== 'doctor') {
            return NextResponse.redirect(new URL(role === 'admin' ? '/admin/dashboard' : `/${role}/dashboard`, request.url))
        }
        if (pathname.startsWith('/patient') && role !== 'patient') {
            return NextResponse.redirect(new URL(role === 'admin' ? '/admin/dashboard' : `/${role}/dashboard`, request.url))
        }

        // Redirect admin away from login/register to admin dashboard
        if ((pathname === '/login' || pathname === '/register') && role === 'admin') {
            return NextResponse.redirect(new URL('/admin/dashboard', request.url))
        }

        // Redirect from login/register if already authenticated
        if (pathname === '/login' || pathname === '/register') {
            return NextResponse.redirect(new URL(`/${role}/dashboard`, request.url))
        }
    }

    return supabaseResponse
}
