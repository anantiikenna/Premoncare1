'use server'

import { createClient } from '@/lib/supabase-server'
import { sendNotification } from '@/lib/notification-service'
import { revalidatePath } from 'next/cache'

export async function proposeFollowupAction(formData: {
    patientId: string,
    doctorId: string,
    doctorName: string,
    date: string,
    time: string,
    reason: string
}) {
    const supabase = await createClient()

    // 1. Send the notification to the patient
    const result = await sendNotification({
        user_id: formData.patientId,
        title: 'New Follow-up Proposal',
        message: `Dr. ${formData.doctorName} has proposed a follow-up session on ${formData.date} at ${formData.time}.`,
        type: 'appointment_proposal',
        link: `/patient/appointments?propose=${formData.doctorId}&date=${formData.date}&time=${formData.time}`,
        send_email: true
    })

    if (result?.success) {
        revalidatePath('/doctor/dashboard')
        return { success: true }
    }

    return { success: false, error: 'Failed to send proposal' }
}
