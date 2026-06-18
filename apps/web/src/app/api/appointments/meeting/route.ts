import { NextResponse, type NextRequest } from 'next/server'
import { createClient } from '@/lib/supabase-server'
import { withSecurity, sanitizeObject } from '@/lib/security'
import { z } from 'zod'

const meetingSchema = z.object({
    appointmentId: z.string().uuid(),
    meetingLink: z.string().url(),
})

async function meetingHandler(request: NextRequest, sessionUser?: any) {
    const jsonBody = await request.json()
    const parsed = meetingSchema.safeParse(jsonBody)

    if (!parsed.success) {
        return NextResponse.json({ error: 'Invalid meeting data provided.' }, { status: 400 })
    }

    const { appointmentId, meetingLink } = sanitizeObject(parsed.data)
    
    // sessionUser is guaranteed to exist due to requireAuth: true
    const doctorId = sessionUser.id 

    const supabase = await createClient()

    // Enforce strict Row-level + Application level security:
    // Only the doctor assigned to this appointment can update the meeting link
    const { data: appointment, error: appointmentError } = await supabase
        .from('appointments')
        .select('id, doctor_id')
        .eq('id', appointmentId)
        .single()

    if (appointmentError || !appointment) {
        return NextResponse.json({ error: 'Appointment not found or unauthorized.' }, { status: 404 })
    }

    if (appointment.doctor_id !== doctorId) {
        return NextResponse.json({ error: 'Forbidden. You are not assigned to this appointment.' }, { status: 403 })
    }

    // Update the meeting link safely
    const { error: updateError } = await supabase
        .from('appointments')
        .update({ meeting_link: meetingLink })
        .eq('id', appointmentId)

    if (updateError) {
        console.error('Failed to update meeting link:', updateError)
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
    }

    return NextResponse.json({ success: true, message: 'Secure meeting link attached.' })
}

export async function POST(req: NextRequest) {
    // Only 'doctor' role is allowed to attach meeting links to appointments
    return withSecurity(req, meetingHandler, { requireAuth: true, requireRoles: ['doctor'] })
}

export async function OPTIONS(req: NextRequest) {
    return withSecurity(req, async () => NextResponse.json({}), { requireAuth: false })
}
