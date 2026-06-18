import { createClient as createBrowserClient } from './supabase'
import * as base from './queries-base'
import { 
    PaymentPayload, 
    AppointmentUpdates, 
    ProfileUpdates, 
    MedicalProfileData, 
    PrescriptionData, 
    ReviewData, 
    NotificationPayload,
    DoctorSchedule
} from './types'

export async function getProfile(userId: string) {
    const supabase = createBrowserClient()
    return base.getProfile(supabase, userId)
}

export async function getAppointments(userId: string, role: 'patient' | 'doctor') {
    const supabase = createBrowserClient()
    return base.getAppointments(supabase, userId, role)
}

export async function getForumPosts(category?: string, status: 'approved' | 'pending' | 'rejected' | 'all' = 'approved') {
    const supabase = createBrowserClient()
    return base.getForumPosts(supabase, category, status)
}

export async function getForumPostById(postId: string) {
    const supabase = createBrowserClient()
    return base.getForumPostById(supabase, postId)
}

export async function getCommentsByPostId(postId: string) {
    const supabase = createBrowserClient()
    return base.getCommentsByPostId(supabase, postId)
}

export async function getAdminStats() {
    const supabase = createBrowserClient()
    return base.getAdminStats(supabase)
}

export async function getAllProfiles() {
    const supabase = createBrowserClient()
    return base.getAllProfiles(supabase)
}

export async function getHealthRecords(patientId: string) {
    const supabase = createBrowserClient()
    return base.getHealthRecords(supabase, patientId)
}

export async function createPayment(payment: PaymentPayload) {
    const supabase = createBrowserClient()
    return base.createPayment(supabase, payment)
}

export async function getPayments(userId?: string, recipientId?: string) {
    const supabase = createBrowserClient()
    return base.getPayments(supabase, userId, recipientId)
}

export async function approvePayment(paymentId: string, adminId?: string) {
    const supabase = createBrowserClient()
    return base.approvePayment(supabase, paymentId, adminId)
}

export async function getDoctorSchedule(doctorId: string) {
    const supabase = createBrowserClient()
    return base.getDoctorSchedule(supabase, doctorId)
}

export async function updateDoctorSchedule(schedule: DoctorSchedule[]) {
    const supabase = createBrowserClient()
    return base.updateDoctorSchedule(supabase, schedule)
}

export async function updateAppointmentStatus(appointmentId: string, updates: AppointmentUpdates) {
    const supabase = createBrowserClient()
    return base.updateAppointmentStatus(supabase, appointmentId, updates)
}

export async function updateProfile(userId: string, updates: ProfileUpdates) {
    const supabase = createBrowserClient()
    return base.updateProfile(supabase, userId, updates)
}

export async function getMedicalProfile(patientId: string) {
    const supabase = createBrowserClient()
    return base.getMedicalProfile(supabase, patientId)
}

export async function upsertMedicalProfile(userId: string, profileData: MedicalProfileData) {
    const supabase = createBrowserClient()
    return base.upsertMedicalProfile(supabase, userId, profileData)
}

export async function getDoctors(specialty?: string) {
    const supabase = createBrowserClient()
    return base.getDoctors(supabase, specialty)
}

export async function createPrescription(prescriptionData: PrescriptionData) {
    const supabase = createBrowserClient()
    return base.createPrescription(supabase, prescriptionData)
}

export async function getPatientPrescriptions(patientId: string) {
    const supabase = createBrowserClient()
    return base.getPatientPrescriptions(supabase, patientId)
}

export async function sendMessage(senderId: string, receiverId: string, content: string) {
    const supabase = createBrowserClient()
    return base.sendMessage(supabase, senderId, receiverId, content)
}

export async function getConversations(userId: string) {
    const supabase = createBrowserClient()
    return base.getConversations(supabase, userId)
}

export async function getMessages(userId: string, otherUserId: string) {
    const supabase = createBrowserClient()
    return base.getMessages(supabase, userId, otherUserId)
}

export async function markMessagesAsRead(userId: string, senderId: string) {
    const supabase = createBrowserClient()
    return base.markMessagesAsRead(supabase, userId, senderId)
}

export async function submitReview(reviewData: ReviewData) {
    const supabase = createBrowserClient()
    return base.submitReview(supabase, reviewData)
}

export async function getDoctorReviews(doctorId: string) {
    const supabase = createBrowserClient()
    return base.getDoctorReviews(supabase, doctorId)
}

export async function getDoctorsWithRatings(specialty?: string) {
    const supabase = createBrowserClient()
    return base.getDoctorsWithRatings(supabase, specialty)
}

export async function getUserNotifications(userId: string) {
    const supabase = createBrowserClient()
    return base.getUserNotifications(supabase, userId)
}

export async function createNotification(notification: NotificationPayload) {
    try {
        const response = await fetch('/api/notifications/dispatch', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                userId: notification.user_id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                link: notification.link,
            }),
        })

        if (!response.ok) {
            const error = await response.text()
            console.error('[Client Notification Error]:', error)
            return { data: null, error: { message: error } }
        }

        const data = await response.json()
        return { data: data.push?.dbId, error: null }
    } catch (err) {
        console.error('[Client Notification Exception]:', err)
        return { data: null, error: err }
    }
}

export async function markNotificationAsRead(notificationId: string) {
    const supabase = createBrowserClient()
    return base.markNotificationAsRead(supabase, notificationId)
}

export async function markAllNotificationsAsRead(userId: string) {
    const supabase = createBrowserClient()
    return base.markAllNotificationsAsRead(supabase, userId)
}

export async function getAdminReports() {
    const supabase = createBrowserClient()
    return base.getAdminReports(supabase)
}

export async function getAdminUserDetail(userId: string) {
    const supabase = createBrowserClient()
    return base.getAdminUserDetail(supabase, userId)
}

export async function rejectPayment(paymentId: string, reason: string, adminId?: string) {
    const supabase = createBrowserClient()
    return base.rejectPayment(supabase, paymentId, reason, adminId)
}

export async function getAuditTimeline(limit?: number) {
    const supabase = createBrowserClient()
    return base.getAuditTimeline(supabase, limit)
}
