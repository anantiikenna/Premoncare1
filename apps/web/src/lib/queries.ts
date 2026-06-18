import { createClient as createServerClient } from './supabase-server'
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
    const supabase = await createServerClient()
    return base.getProfile(supabase, userId)
}

export async function getAppointments(userId: string, role: 'patient' | 'doctor') {
    const supabase = await createServerClient()
    return base.getAppointments(supabase, userId, role)
}

export async function getForumPosts(category?: string, status: 'approved' | 'pending' | 'rejected' | 'all' = 'approved') {
    const supabase = await createServerClient()
    return base.getForumPosts(supabase, category, status)
}

export async function getForumPostById(postId: string) {
    const supabase = await createServerClient()
    return base.getForumPostById(supabase, postId)
}

export async function getCommentsByPostId(postId: string) {
    const supabase = await createServerClient()
    return base.getCommentsByPostId(supabase, postId)
}

export async function getAdminStats() {
    const supabase = await createServerClient()
    return base.getAdminStats(supabase)
}

export async function getAllProfiles() {
    const supabase = await createServerClient()
    return base.getAllProfiles(supabase)
}

export async function getHealthRecords(patientId: string) {
    const supabase = await createServerClient()
    return base.getHealthRecords(supabase, patientId)
}

export async function getMedicalDocuments(patientId: string) {
    const supabase = await createServerClient()
    return base.getMedicalDocuments(supabase, patientId)
}

export async function getPatientDocumentsForDoctor(doctorId: string) {
    const supabase = await createServerClient()
    return base.getPatientDocumentsForDoctor(supabase, doctorId)
}

export async function createPayment(payment: PaymentPayload) {
    const supabase = await createServerClient()
    return base.createPayment(supabase, payment)
}

export async function getPayments(userId?: string) {
    const supabase = await createServerClient()
    return base.getPayments(supabase, userId)
}

export async function approvePayment(paymentId: string) {
    const supabase = await createServerClient()
    return base.approvePayment(supabase, paymentId)
}

export async function getDoctorSchedule(doctorId: string) {
    const supabase = await createServerClient()
    return base.getDoctorSchedule(supabase, doctorId)
}

export async function updateDoctorSchedule(schedule: DoctorSchedule[]) {
    const supabase = await createServerClient()
    return base.updateDoctorSchedule(supabase, schedule)
}

export async function updateAppointmentStatus(appointmentId: string, updates: AppointmentUpdates) {
    const supabase = await createServerClient()
    return base.updateAppointmentStatus(supabase, appointmentId, updates)
}

export async function updateProfile(userId: string, updates: ProfileUpdates) {
    const supabase = await createServerClient()
    return base.updateProfile(supabase, userId, updates)
}

export async function getMedicalProfile(patientId: string) {
    const supabase = await createServerClient()
    return base.getMedicalProfile(supabase, patientId)
}

export async function upsertMedicalProfile(userId: string, profileData: MedicalProfileData) {
    const supabase = await createServerClient()
    return base.upsertMedicalProfile(supabase, userId, profileData)
}

export async function getDoctors(specialty?: string) {
    const supabase = await createServerClient()
    return base.getDoctors(supabase, specialty)
}

export async function createPrescription(prescriptionData: PrescriptionData) {
    const supabase = await createServerClient()
    return base.createPrescription(supabase, prescriptionData)
}

export async function getPatientPrescriptions(patientId: string) {
    const supabase = await createServerClient()
    return base.getPatientPrescriptions(supabase, patientId)
}

export async function sendMessage(senderId: string, receiverId: string, content: string) {
    const supabase = await createServerClient()
    return base.sendMessage(supabase, senderId, receiverId, content)
}

export async function getConversations(userId: string) {
    const supabase = await createServerClient()
    return base.getConversations(supabase, userId)
}

export async function getMessages(userId: string, otherUserId: string) {
    const supabase = await createServerClient()
    return base.getMessages(supabase, userId, otherUserId)
}

export async function markMessagesAsRead(userId: string, senderId: string) {
    const supabase = await createServerClient()
    return base.markMessagesAsRead(supabase, userId, senderId)
}

export async function submitReview(reviewData: ReviewData) {
    const supabase = await createServerClient()
    return base.submitReview(supabase, reviewData)
}

export async function getDoctorReviews(doctorId: string) {
    const supabase = await createServerClient()
    return base.getDoctorReviews(supabase, doctorId)
}

export async function getDoctorsWithRatings(specialty?: string) {
    const supabase = await createServerClient()
    return base.getDoctorsWithRatings(supabase, specialty)
}

export async function getUserNotifications(userId: string) {
    const supabase = await createServerClient()
    return base.getUserNotifications(supabase, userId)
}

export async function createNotification(notification: NotificationPayload) {
    const supabase = await createServerClient()
    return base.createNotification(supabase, notification)
}

export async function markNotificationAsRead(notificationId: string) {
    const supabase = await createServerClient()
    return base.markNotificationAsRead(supabase, notificationId)
}

export async function markAllNotificationsAsRead(userId: string) {
    const supabase = await createServerClient()
    return base.markAllNotificationsAsRead(supabase, userId)
}

export async function getAdminReports() {
    const supabase = await createServerClient()
    return base.getAdminReports(supabase)
}

export async function getAdminUserDetail(userId: string) {
    const supabase = await createServerClient()
    return base.getAdminUserDetail(supabase, userId)
}

export async function rejectPayment(paymentId: string, reason: string) {
    const supabase = await createServerClient()
    return base.rejectPayment(supabase, paymentId, reason)
}

export async function getAuditTimeline(limit?: number) {
    const supabase = await createServerClient()
    return base.getAuditTimeline(supabase, limit)
}
