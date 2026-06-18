import { createClient } from '@/lib/supabase-server'
import { sendEmail, templates } from '@/lib/email-service'
import { NextResponse, type NextRequest } from 'next/server'
import { withSecurity, sanitizeObject } from '@/lib/security'
import { z } from 'zod'

const emailRequestSchema = z.object({
    type: z.enum(['consultationFee', 'paymentApproval', 'accountActivation', 'bookingInstructions']),
    data: z.record(z.string(), z.any())
})

async function emailHandler(req: NextRequest, sessionUser?: any) {
    const jsonBody = await req.json()
    const parsed = emailRequestSchema.safeParse(jsonBody)

    if (!parsed.success) {
        return NextResponse.json({ success: false, error: 'Invalid Request Body' }, { status: 400 })
    }

    const { type, data } = sanitizeObject(parsed.data)
    const userId = sessionUser.id
    
    const supabase = await createClient()

    // 1. Check if user has email alerts enabled
    const { data: profile } = await supabase
        .from('profiles')
        .select('email, full_name, email_alerts_enabled')
        .eq('id', userId)
        .single()

    if (!profile || profile.email_alerts_enabled === false) {
        return NextResponse.json({ success: true, message: 'Skipped: User disabled alerts or not found' })
    }

    let emailContent: { subject: string, html: string } | null = null

    switch (type) {
        case 'consultationFee':
            emailContent = templates.consultationFee(
                profile.full_name,
                data.patientName as string,
                data.amount as number,
                data.duration as number
            )
            break
        case 'paymentApproval':
            emailContent = templates.paymentApproval(
                profile.full_name,
                data.amount as number,
                data.status as 'approved' | 'rejected' | 'pending'
            )
            break
        case 'accountActivation':
            emailContent = templates.accountActivation(
                profile.full_name,
                data.expiryDate as string
            )
            break
        case 'bookingInstructions':
            emailContent = templates.bookingInstructions(
                profile.full_name,
                data.doctorName as string,
                data.amount as number,
                data.instructions as string
            )
            break
    }

    if (emailContent) {
        await sendEmail({
            to: profile.email,
            subject: emailContent.subject,
            html: emailContent.html
        })
    }

    return NextResponse.json({ success: true })
}

export async function POST(req: NextRequest) {
    return withSecurity(req, emailHandler, { requireAuth: true })
}
export async function OPTIONS(req: NextRequest) {
    return withSecurity(req, async () => NextResponse.json({}), { requireAuth: false })
}
