import { SupabaseClient } from '@supabase/supabase-js'
import { 
    PaymentPayload, 
    AppointmentUpdates, 
    ProfileUpdates, 
    MedicalProfileData, 
    PrescriptionData, 
    ReviewData, 
    NotificationPayload,
    DoctorSchedule,
    DoctorActivity,
    Profile
} from './types'

// Fire-and-forget notification via API route to avoid leaking firebase-admin/nodemailer into client bundles
async function dispatchNotificationViaApi(payload: {
    userId: string;
    title: string;
    message: string;
    type: string;
    link?: string;
    sendEmail?: boolean;
    emailTemplate?: string;
    emailData?: Record<string, any>;
}) {
    try {
        await fetch(`${process.env.NEXT_PUBLIC_SITE_URL || ''}/api/notifications/dispatch`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
    } catch (e) {
        console.error('Notification dispatch failed', e);
    }
}

export async function getProfile(supabase: SupabaseClient, userId: string) {
    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()
    return { data, error }
}

export async function getAppointments(supabase: SupabaseClient, userId: string, role: 'patient' | 'doctor') {
    const query = supabase
        .from('appointments')
        .select(`
            *,
            patient:profiles!appointments_patient_id_fkey(full_name, avatar_url),
            doctor:profiles!appointments_doctor_id_fkey(full_name, avatar_url)
        `)
        .order('appointment_date', { ascending: true })

    if (role === 'patient') {
        query.eq('patient_id', userId)
    } else {
        query.eq('doctor_id', userId)
    }

    return await query
}

export async function getForumPosts(supabase: SupabaseClient, category?: string, status: 'approved' | 'pending' | 'rejected' | 'all' = 'approved') {
    let query = supabase
        .from('forum_posts')
        .select(`
            *,
            author:profiles!forum_posts_author_id_fkey(full_name, avatar_url, role),
            category:forum_categories!forum_posts_category_id_fkey(id, name, icon_name)
        `)
        .order('created_at', { ascending: false })

    if (category && category !== 'All') {
        // Parallel: fetch category ID and apply filter
        const { data: cat } = await supabase
            .from('forum_categories')
            .select('id')
            .eq('name', category)
            .single()
        if (cat) {
            query = query.eq('category_id', cat.id)
        }
    }

    if (status !== 'all') {
        query = query.eq('status', status)
    }

    return await query
}

export async function getForumPostById(supabase: SupabaseClient, postId: string) {
    const { data, error } = await supabase
        .from('forum_posts')
        .select(`
            *,
            author:profiles!forum_posts_author_id_fkey(full_name, avatar_url)
        `)
        .eq('id', postId)
        .single()
    return { data, error }
}

export async function getCommentsByPostId(supabase: SupabaseClient, postId: string) {
    return await supabase
        .from('forum_replies')
        .select(`
            *,
            author:profiles!forum_replies_author_id_fkey(full_name, avatar_url, role)
        `)
        .eq('post_id', postId)
        .order('created_at', { ascending: true })
}

export async function getAdminStats(supabase: SupabaseClient) {
    const now = new Date().toISOString()
    
    const [
        { count: totalUsers },
        { count: totalAppointments },
        { count: totalPosts },
        { count: totalRecords },
        { count: pendingVerifications },
        { count: expiredSubscriptions },
        { data: approvedPayments },
        { data: pendingPayments }
    ] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }),
        supabase.from('appointments').select('*', { count: 'exact', head: true }),
        supabase.from('forum_posts').select('*', { count: 'exact', head: true }),
        supabase.from('medical_records').select('*', { count: 'exact', head: true }),
        supabase.from('profiles')
            .select('*', { count: 'exact', head: true })
            .or('role.eq.doctor,requested_role.eq.doctor')
            .eq('verification_status', 'pending'),
        supabase.from('profiles')
            .select('*', { count: 'exact', head: true })
            .eq('role', 'doctor')
            .eq('subscription_status', 'active')
            .lt('subscription_expires_at', now),
        supabase.from('payments').select('amount').eq('status', 'approved'),
        supabase.from('payments').select('amount').eq('status', 'pending'),
    ])

    const totalRevenue = approvedPayments?.reduce((sum, p) => sum + (Number(p.amount) || 0), 0) || 0
    const pendingRevenue = pendingPayments?.reduce((sum, p) => sum + (Number(p.amount) || 0), 0) || 0

    return {
        totalUsers: totalUsers || 0,
        totalAppointments: totalAppointments || 0,
        totalPosts: totalPosts || 0,
        totalRecords: totalRecords || 0,
        pendingVerifications: pendingVerifications || 0,
        expiredSubscriptions: expiredSubscriptions || 0,
        totalRevenue,
        pendingRevenue
    }
}

export async function getAllProfiles(supabase: SupabaseClient) {
    return await supabase
        .from('profiles')
        .select('id, full_name, email, role, verification_status, requested_role, subscription_status, avatar_url, verification_document_url, updated_at')
        .order('updated_at', { ascending: false })
}

export async function getHealthRecords(supabase: SupabaseClient, patientId: string) {
    return await supabase
        .from('medical_records')
        .select(`
            *,
            doctor:profiles!medical_records_doctor_id_fkey(full_name)
        `)
        .eq('patient_id', patientId)
        .order('created_at', { ascending: false })
}

export async function getMedicalDocuments(supabase: SupabaseClient, patientId: string) {
    return await supabase
        .from('medical_records')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', { ascending: false })
}

export async function getPatientDocumentsForDoctor(supabase: SupabaseClient, doctorId: string) {
    // 1. Get all patient IDs who have appointments with this doctor
    const { data: appointments } = await supabase
        .from('appointments')
        .select('patient_id')
        .eq('doctor_id', doctorId)
    
    const patientIds = Array.from(new Set(appointments?.map(a => a.patient_id) || []))
    
    if (patientIds.length === 0) return { data: [], error: null }
    
    // 2. Get documents for those patients
    return await supabase
        .from('medical_records')
        .select(`
            *,
            patient:profiles!medical_records_patient_id_fkey(full_name)
        `)
        .in('patient_id', patientIds)
        .order('created_at', { ascending: false })
}

export async function createPayment(supabase: SupabaseClient, payment: PaymentPayload) {
    const { data, error } = await supabase
        .from('payments')
        .insert(payment)
        .select()
        .single()

    if (!error && data && payment.method === 'manual') {
        // Find the recipient name or admin context
        const recipientId = payment.recipient_id; // If null, it goes to Admin (Subscription)
        
        // Notify the relevant person that a new receipt is awaiting verification
        const recipientContext = recipientId ? 'Doctor' : 'Admin';
        const notificationTarget = recipientId || null; // Null targets Admin in dispatcher logic or specific fallback

        // Note: For subscriptions (recipientId is null), we notify the system/admin
        // If recipientId exists, it's a doctor receiving a consultation payment
        
        // We'll use a unified dispatch call
        // If recipientId is null, we might need a way to find all admins, 
        // but for now, we dispatch to the specific recipient or system alert.
        if (recipientId) {
            dispatchNotificationViaApi({
                userId: recipientId,
                title: 'New Payment Receipt',
                message: `A patient has uploaded a manual receipt for verification.`,
                type: 'payment',
                link: '/doctor/payments'
            });
        } else {
            // For subscriptions, we could notify all admins or a system log.
            // For now, let's assume there's an admin notification service or we ignore if handled by dashboard polling.
            // But usually, we want an alert.
        }
    }

    return { data, error }
}

export async function getPayments(supabase: SupabaseClient, userId?: string, recipientId?: string) {
    let query = supabase.from('payments').select(`
        *, 
        user:profiles!payments_user_id_fkey(full_name),
        recipient:profiles!payments_recipient_id_fkey(full_name),
        auditor:profiles!payments_processed_by_fkey(full_name)
    `)
    if (userId) {
        query = query.eq('user_id', userId)
    }
    if (recipientId) {
        query = query.eq('recipient_id', recipientId)
    }
    return await query.order('created_at', { ascending: false })
}

export async function approvePayment(supabase: SupabaseClient, paymentId: string, adminOrDoctorId?: string) {
    const { data: payment } = await supabase.from('payments').select('user_id, amount').eq('id', paymentId).single()
    
    if (!payment) return { data: null, error: { message: 'Payment not found' } as unknown as { message: string } }

    // Use centralized database logic
    const { data, error } = await supabase.rpc('approve_payment', {
        p_payment_id: paymentId,
        p_processor_id: adminOrDoctorId
    })

    if (!error) {
        // Unified Dispatch (Push + Email) to the Patient
        dispatchNotificationViaApi({
            userId: (payment as any).user_id,
            title: 'Payment Approved',
            message: `Your payment of ₦${(payment as any).amount.toLocaleString()} has been verified.`,
            type: 'payment',
            link: '/patient/dashboard',
            sendEmail: true,
            emailTemplate: 'paymentApproval',
            emailData: {
                amount: (payment as any).amount,
                status: 'approved'
            }
        })

        // Broadcast Transparency Notification to Admins
        const { data: admins } = await supabase.from('profiles').select('id').eq('role', 'admin')
        if (admins) {
            for (const admin of admins) {
                // Do not notify if the admin was the one who processed it
                if (admin.id === adminOrDoctorId) continue;
                
                dispatchNotificationViaApi({
                    userId: admin.id,
                    title: 'P2P Payment Verified',
                    message: `A payment of ₦${(payment as any).amount.toLocaleString()} was verified by an auditor.`,
                    type: 'system',
                    link: '/admin/finance'
                })
            }
        }
    }
    return { data, error }
}

export async function getDoctorSchedule(supabase: SupabaseClient, doctorId: string) {
    return await supabase
        .from('doctor_schedules')
        .select('*')
        .eq('doctor_id', doctorId)
        .eq('is_available', true)
}

export async function updateDoctorSchedule(supabase: SupabaseClient, schedule: DoctorSchedule[]) {
    return await supabase
        .from('doctor_schedules')
        .upsert(schedule)
}

export async function updateAppointmentStatus(supabase: SupabaseClient, appointmentId: string, updates: AppointmentUpdates) {
    let oldApt = null
    if (updates.status) {
        const { data } = await supabase
            .from('appointments')
            .select('patient_id, doctor:profiles!appointments_doctor_id_fkey(full_name), status')
            .eq('id', appointmentId)
            .single()
        oldApt = data
    }

    const result = await supabase
        .from('appointments')
        .update(updates)
        .eq('id', appointmentId)

    if (updates.status && oldApt && oldApt.status !== updates.status) {
        const title = `Appointment ${updates.status.charAt(0).toUpperCase() + updates.status.slice(1)}`
        const message = `Dr. ${(oldApt.doctor as unknown as { full_name: string }).full_name} has ${updates.status} your appointment.`
        
        // Unified Dispatch
        dispatchNotificationViaApi({
            userId: oldApt.patient_id,
            title,
            message,
            type: 'appointment',
            link: '/patient/appointments'
        })
    }
    return result
}

export async function updateProfile(supabase: SupabaseClient, userId: string, updates: ProfileUpdates) {
    return await supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId)
}

export async function getMedicalProfile(supabase: SupabaseClient, patientId: string) {
    const { data, error } = await supabase
        .from('medical_profiles')
        .select('*')
        .eq('id', patientId)
        .single()
    return { data, error }
}

export async function getTimeBalance(supabase: SupabaseClient, patientId: string, doctorId: string) {
    return await supabase
        .from('time_balances')
        .select('minutes_remaining')
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .single()
}

export async function getAdminNotificationSettings(supabase: SupabaseClient, adminId: string) {
    return await supabase
        .from('admin_notification_settings')
        .select('*')
        .eq('admin_id', adminId)
        .single()
}

export async function updateAdminNotificationSettings(supabase: SupabaseClient, adminId: string, settings: Record<string, unknown>) {
    return await supabase
        .from('admin_notification_settings')
        .upsert({ ...settings, admin_id: adminId })
}

export async function upsertMedicalProfile(supabase: SupabaseClient, userId: string, profileData: MedicalProfileData) {
    const dataWithId = { ...profileData, id: userId, updated_at: new Date().toISOString() }
    return await supabase
        .from('medical_profiles')
        .upsert(dataWithId)
}

export async function getDoctors(supabase: SupabaseClient, specialty?: string) {
    let query = supabase
        .from('profiles')
        .select('id, full_name, avatar_url, specialty, experience_years, clinic_address, consultation_fee')
        .eq('role', 'doctor')
        
    if (specialty && specialty !== 'All') {
        query = query.eq('specialty', specialty)
    }
    
    return await query
}

export async function createPrescription(supabase: SupabaseClient, prescriptionData: PrescriptionData) {
    const result = await supabase
        .from('prescriptions')
        .insert(prescriptionData)
        .select()
        .single()

    if (result.data) {
        const { data: doctor } = await supabase.from('profiles').select('full_name').eq('id', prescriptionData.doctor_id).single()
        const title = 'New Prescription Issued'
        const message = `Dr. ${(doctor as { full_name: string })?.full_name || 'Your doctor'} has issued a new prescription for ${prescriptionData.medication_name}.`
        
        // Unified Dispatch
        dispatchNotificationViaApi({
            userId: prescriptionData.patient_id,
            title,
            message,
            type: 'prescription',
            link: '/patient/prescriptions'
        })
    }
    return result
}

export async function getPatientPrescriptions(supabase: SupabaseClient, patientId: string) {
    return await supabase
        .from('prescriptions')
        .select(`
            *,
            doctor:profiles!doctor_id(full_name, specialty, clinic_address)
        `)
        .eq('patient_id', patientId)
        .order('created_at', { ascending: false })
}

export async function sendMessage(supabase: SupabaseClient, senderId: string, receiverId: string, content: string) {
    const result = await supabase
        .from('messages')
        .insert({
            sender_id: senderId,
            receiver_id: receiverId,
            content
        })
        .select()
        .single()

    if (result.data) {
        const { data: sender } = await supabase.from('profiles').select('full_name').eq('id', senderId).single()
        const { data: receiver } = await supabase.from('profiles').select('role').eq('id', receiverId).single()
        
        const messageLink = receiver?.role === 'doctor' ? '/doctor/messages' : '/patient/messages'
        const title = 'New Message'
        const message = `You have a new message from ${(sender as { full_name: string })?.full_name || 'a user'}: "${content.slice(0, 30)}${content.length > 30 ? '...' : ''}"`

        // Unified Dispatch
        dispatchNotificationViaApi({
            userId: receiverId,
            title,
            message,
            type: 'message',
            link: messageLink
        })
    }
    return result
}

export async function getConversations(supabase: SupabaseClient, userId: string) {
    const { data: messages, error } = await supabase
        .from('messages')
        .select(`
            id,
            created_at,
            sender:profiles!sender_id(id, full_name, avatar_url, role),
            receiver:profiles!receiver_id(id, full_name, avatar_url, role),
            content,
            is_read
        `)
        .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
        .order('created_at', { ascending: false })

    if (error || !messages) return { data: null, error }

    const conversationsMap = new Map()

    for (const msg of messages) {
        const sender = (Array.isArray(msg.sender) ? msg.sender[0] : msg.sender) as Profile
        const receiver = (Array.isArray(msg.receiver) ? msg.receiver[0] : msg.receiver) as Profile
        const otherUser = sender.id === userId ? receiver : sender
        
        if (!conversationsMap.has(otherUser.id)) {
            conversationsMap.set(otherUser.id, {
                contact: otherUser,
                lastMessage: msg,
                unreadCount: receiver.id === userId && !msg.is_read ? 1 : 0
            })
        } else {
            if (receiver.id === userId && !msg.is_read) {
                const existing = conversationsMap.get(otherUser.id)
                existing.unreadCount += 1
            }
        }
    }

    return { data: Array.from(conversationsMap.values()), error: null }
}

export async function getMessages(supabase: SupabaseClient, userId: string, otherUserId: string) {
    return await supabase
        .from('messages')
        .select(`
            id,
            created_at,
            sender_id,
            receiver_id,
            content,
            is_read
        `)
        .or(`and(sender_id.eq.${userId},receiver_id.eq.${otherUserId}),and(sender_id.eq.${otherUserId},receiver_id.eq.${userId})`)
        .order('created_at', { ascending: true })
}

export async function markMessagesAsRead(supabase: SupabaseClient, userId: string, senderId: string) {
    return await supabase
        .from('messages')
        .update({ is_read: true })
        .eq('receiver_id', userId)
        .eq('sender_id', senderId)
        .eq('is_read', false)
}

export async function submitReview(supabase: SupabaseClient, reviewData: ReviewData) {
    return await supabase
        .from('reviews')
        .insert(reviewData)
}

export async function getDoctorReviews(supabase: SupabaseClient, doctorId: string) {
    return await supabase
        .from('reviews')
        .select(`
            *,
            patient:profiles!patient_id(full_name, avatar_url)
        `)
        .eq('doctor_id', doctorId)
        .order('created_at', { ascending: false })
}

export async function getDoctorsWithRatings(supabase: SupabaseClient, specialty?: string) {
    let query = supabase
        .from('profiles')
        .select(`
            id, 
            full_name, 
            avatar_url, 
            specialty, 
            experience_years, 
            clinic_address,
            consultation_fee,
            reviews:reviews(rating)
        `)
        .eq('role', 'doctor')
        
    if (specialty && specialty !== 'All') {
        query = query.eq('specialty', specialty)
    }
    
    return await query
}

export async function getUserNotifications(supabase: SupabaseClient, userId: string) {
    return await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
}

export async function createNotification(supabase: SupabaseClient, notification: NotificationPayload) {
    return await supabase
        .from('notifications')
        .insert(notification)
}

export async function markNotificationAsRead(supabase: SupabaseClient, notificationId: string) {
    return await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)
}

export async function markAllNotificationsAsRead(supabase: SupabaseClient, userId: string) {
    return await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false)
}

export async function getAdminReports(supabase: SupabaseClient) {
    // Revenue summary
    const { data: allPayments } = await supabase
        .from('payments')
        .select('status, amount, method, created_at, user:profiles(full_name)')
        .order('created_at', { ascending: false })

    const totalRevenue = allPayments?.filter(p => p.status === 'approved').reduce((sum, p) => sum + Number(p.amount), 0) || 0
    const pendingRevenue = allPayments?.filter(p => p.status === 'pending').reduce((sum, p) => sum + Number(p.amount), 0) || 0
    const totalPayments = allPayments?.length || 0
    const approvedPayments = allPayments?.filter(p => p.status === 'approved').length || 0

    // Doctor activity
    const { data: allAppointments } = await supabase
        .from('appointments')
        .select(`
            id, status, created_at,
            doctor:profiles!appointments_doctor_id_fkey(id, full_name, specialty),
            patient:profiles!appointments_patient_id_fkey(id, full_name)
        `)
        .order('created_at', { ascending: false })

    // Aggregate per-doctor stats
    const doctorMap = new Map<string, DoctorActivity>()
    for (const apt of allAppointments || []) {
        const doc = (Array.isArray(apt.doctor) ? apt.doctor[0] : apt.doctor) as Profile
        if (!doc?.id) continue
        if (!doctorMap.has(doc.id)) {
            doctorMap.set(doc.id, {
                id: doc.id,
                name: doc.full_name,
                specialty: doc.specialty,
                total: 0,
                completed: 0,
                cancelled: 0,
                pending: 0,
                uniquePatients: 0,
                patients: new Set()
            })
        }
        const entry = doctorMap.get(doc.id)
        if (entry) {
            entry.total++
            if (apt.status === 'completed') entry.completed++
            if (apt.status === 'cancelled') entry.cancelled++
            if (apt.status === 'pending') entry.pending++
            const pat = (Array.isArray(apt.patient) ? apt.patient[0] : apt.patient) as Profile
            if (pat?.id) entry.patients?.add(pat.id)
        }
    }

    const doctorActivity = Array.from(doctorMap.values()).map(d => ({
        ...d,
        uniquePatients: d.patients?.size || 0,
        patients: undefined
    }))

    return {
        totalRevenue,
        pendingRevenue,
        totalPayments,
        approvedPayments,
        allPayments: allPayments || [],
        allAppointments: allAppointments || [],
        doctorActivity
    }
}

export async function getAdminUserDetail(supabase: SupabaseClient, userId: string) {
    const [profileRes, appointmentsRes, paymentsRes, medProfileRes, prescriptionsRes] = await Promise.all([
        supabase.from('profiles').select('*').eq('id', userId).single(),
        supabase.from('appointments').select(`
            id, status, appointment_date, reason,
            doctor:profiles!appointments_doctor_id_fkey(full_name, specialty),
            patient:profiles!appointments_patient_id_fkey(full_name)
        `).or(`patient_id.eq.${userId},doctor_id.eq.${userId}`).order('appointment_date', { ascending: false }),
        supabase.from('payments').select('*').eq('user_id', userId).order('created_at', { ascending: false }),
        supabase.from('medical_profiles').select('*').eq('id', userId).single(),
        supabase.from('prescriptions').select(`*, doctor:profiles!doctor_id(full_name)`).eq('patient_id', userId).order('created_at', { ascending: false })
    ])

    return {
        profile: profileRes.data,
        appointments: appointmentsRes.data || [],
        payments: paymentsRes.data || [],
        medicalProfile: medProfileRes.data,
        prescriptions: prescriptionsRes.data || []
    }
}

export async function rejectPayment(supabase: SupabaseClient, paymentId: string, reason: string, adminOrDoctorId?: string) {
    const { data: payment } = await supabase.from('payments').select('user_id, amount').eq('id', paymentId).single()
    
    if (!payment) return { data: null, error: { message: 'Payment not found' } as unknown as { message: string } }

    // Use centralized database logic
    return await supabase.rpc('reject_payment', {
        p_payment_id: paymentId,
        p_reason: reason,
        p_processor_id: adminOrDoctorId
    })
}

export interface AuditEvent {
    id: string
    type: 'verification' | 'payment' | 'forum' | 'appointment' | 'system'
    title: string
    description: string
    timestamp: string
    severity: 'info' | 'success' | 'warning' | 'danger'
    actor: string
    target?: string
    meta: Record<string, string>
    rawData?: Record<string, unknown>
}

export async function getAuditTimeline(supabase: SupabaseClient, limit = 50) {
    const now = new Date()
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()

    const [verificationsRes, paymentsRes, forumRes, appointmentsRes] = await Promise.all([
        supabase
            .from('profiles')
            .select('id, full_name, role, verification_status, verified_by, updated_at, created_at, specialty')
            .or('role.eq.doctor,requested_role.eq.doctor')
            .not('verification_status', 'is', null)
            .neq('verification_status', 'unsubmitted')
            .gte('updated_at', thirtyDaysAgo)
            .order('updated_at', { ascending: false })
            .limit(limit),
        supabase
            .from('payments')
            .select('id, amount, status, method, created_at, processed_by, rejection_reason, user:profiles!payments_user_id_fkey(full_name), recipient:profiles!payments_recipient_id_fkey(full_name)')
            .gte('created_at', thirtyDaysAgo)
            .order('created_at', { ascending: false })
            .limit(limit),
        supabase
            .from('forum_posts')
            .select('id, title, status, created_at, author_id, author:profiles!forum_posts_author_id_fkey(full_name)')
            .gte('created_at', thirtyDaysAgo)
            .order('created_at', { ascending: false })
            .limit(limit),
        supabase
            .from('appointments')
            .select('id, status, created_at, reason, patient:profiles!appointments_patient_id_fkey(full_name), doctor:profiles!appointments_doctor_id_fkey(full_name, specialty)')
            .gte('created_at', thirtyDaysAgo)
            .order('created_at', { ascending: false })
            .limit(limit),
    ])

    const events: AuditEvent[] = []

    for (const doc of verificationsRes.data || []) {
        const statusLabel = doc.verification_status === 'approved' ? 'Approved' : doc.verification_status === 'rejected' ? 'Rejected' : 'Submitted'
        const severity = doc.verification_status === 'approved' ? 'success' : doc.verification_status === 'rejected' ? 'danger' : 'info'
        events.push({
            id: `ver-${doc.id}`,
            type: 'verification',
            title: `Doctor Verification ${statusLabel}`,
            description: `${doc.full_name}'s professional verification was ${statusLabel.toLowerCase()}${doc.specialty ? ` for ${doc.specialty}` : ''}.`,
            timestamp: doc.updated_at || doc.created_at,
            severity,
            actor: 'System',
            target: doc.full_name,
            meta: {
                'Doctor ID': doc.id.slice(0, 8),
                'Status': doc.verification_status || 'unknown',
                'Specialty': doc.specialty || 'N/A',
            },
            rawData: doc as unknown as Record<string, unknown>,
        })
    }

    for (const pay of paymentsRes.data || []) {
        const userName = (pay.user as unknown as { full_name?: string })?.full_name || 'Unknown'
        const recipientName = (pay.recipient as unknown as { full_name?: string })?.full_name || 'Platform'
        const statusLabel = pay.status === 'approved' ? 'Approved' : pay.status === 'rejected' ? 'Rejected' : 'Submitted'
        const severity = pay.status === 'approved' ? 'success' : pay.status === 'rejected' ? 'danger' : 'warning'
        events.push({
            id: `pay-${pay.id}`,
            type: 'payment',
            title: `Payment ${statusLabel}`,
            description: `₦${Number(pay.amount).toLocaleString()} payment ${statusLabel.toLowerCase()} from ${userName} to ${recipientName}.`,
            timestamp: pay.created_at,
            severity,
            actor: pay.processed_by || 'System',
            target: userName,
            meta: {
                'Amount': `₦${Number(pay.amount).toLocaleString()}`,
                'Method': pay.method || 'N/A',
                'Status': pay.status,
                ...(pay.rejection_reason ? { 'Reason': pay.rejection_reason } : {}),
            },
            rawData: pay as unknown as Record<string, unknown>,
        })
    }

    for (const post of forumRes.data || []) {
        const authorName = (post.author as unknown as { full_name?: string })?.full_name || 'Unknown'
        events.push({
            id: `forum-${post.id}`,
            type: 'forum',
            title: 'Forum Post Created',
            description: `"${post.title}" posted by ${authorName}.`,
            timestamp: post.created_at,
            severity: 'info',
            actor: authorName,
            target: post.title,
            meta: {
                'Post ID': post.id.slice(0, 8),
                'Status': post.status,
            },
            rawData: post as unknown as Record<string, unknown>,
        })
    }

    for (const apt of appointmentsRes.data || []) {
        const patientName = (apt.patient as unknown as { full_name?: string })?.full_name || 'Unknown'
        const doctorName = (apt.doctor as unknown as { full_name?: string })?.full_name || 'Unknown'
        const statusLabel = apt.status?.charAt(0).toUpperCase() + (apt.status?.slice(1) || '')
        const severity = apt.status === 'completed' ? 'success' : apt.status === 'cancelled' ? 'danger' : apt.status === 'pending' ? 'warning' : 'info'
        events.push({
            id: `apt-${apt.id}`,
            type: 'appointment',
            title: `Appointment ${statusLabel}`,
            description: `Appointment between ${patientName} and ${doctorName} was ${apt.status}.`,
            timestamp: apt.created_at,
            severity,
            actor: doctorName,
            target: patientName,
            meta: {
                'Patient': patientName,
                'Doctor': doctorName,
                'Status': apt.status || 'unknown',
                ...(apt.reason ? { 'Reason': apt.reason } : {}),
            },
            rawData: apt as unknown as Record<string, unknown>,
        })
    }

    events.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())

    const totalActions = events.length
    const securityAlerts = events.filter(e => e.severity === 'danger').length
    const recentChanges = events.filter(e => {
        const diff = Date.now() - new Date(e.timestamp).getTime()
        return diff < 24 * 60 * 60 * 1000
    }).length

    return {
        events: events.slice(0, limit),
        stats: { totalActions, securityAlerts, recentChanges },
    }
}

