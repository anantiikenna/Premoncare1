import { NextRequest, NextResponse } from 'next/server'
import { withSecurity } from '@/lib/security'
import { createClient } from '@/lib/supabase-server'

async function exportHandler(req: NextRequest, sessionUser: any) {
    const supabase = await createClient()
    const userId = sessionUser!.id

    const { data, error } = await supabase.rpc('export_user_data', {
        p_user_id: userId,
    })

    if (error) {
        return NextResponse.json({ error: 'Failed to export data' }, { status: 500 })
    }

    return new NextResponse(JSON.stringify(data, null, 2), {
        headers: {
            'Content-Type': 'application/json',
            'Content-Disposition': `attachment; filename="premoncare-data-${new Date().toISOString().split('T')[0]}.json"`,
        },
    })
}

export async function GET(req: NextRequest) {
    return withSecurity(req, exportHandler, { requireAuth: true })
}
