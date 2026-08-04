import { NextRequest, NextResponse } from 'next/server'
import { withSecurity } from '@/lib/security'
import { createClient } from '@/lib/supabase-server'

async function deleteHandler(req: NextRequest, sessionUser: any) {
    const supabase = await createClient()
    const userId = sessionUser!.id

    let reason: string | null = null
    try {
        const body = await req.json()
        reason = body.reason || null
    } catch {}

    const { data, error } = await supabase.rpc('soft_delete_user', {
        p_user_id: userId,
        p_reason: reason,
    })

    if (error) {
        return NextResponse.json({ error: 'Failed to process deletion request' }, { status: 500 })
    }

    if (data?.error) {
        return NextResponse.json({ error: data.error }, { status: 403 })
    }

    return NextResponse.json({
        success: true,
        message: 'Account scheduled for deletion in 30 days. You can contact support to cancel this request within that period.',
    })
}

export async function POST(req: NextRequest) {
    return withSecurity(req, deleteHandler, { requireAuth: true })
}
