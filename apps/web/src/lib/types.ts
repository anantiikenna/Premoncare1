export interface PaymentPayload {
    amount: number;
    method: string;
    user_id: string;
    recipient_id?: string | null;
    duration_minutes?: number | null;
    status: 'pending' | 'approved' | 'rejected';
    reference?: string;
    proof_url?: string;
    rejection_reason?: string | null;
    processed_by?: string;
    transaction_id?: string;
}

export interface AppointmentUpdates {
    status?: 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'rescheduled';
    reason?: string;
    appointment_date?: string;
}

export interface ProfileUpdates {
    full_name?: string;
    avatar_url?: string;
    dob?: string;
    gender?: string;
    phone?: string;
    address?: string;
    next_of_kin_name?: string;
    next_of_kin_phone?: string;
    emergency_contact_name?: string;
    emergency_contact_phone?: string;
    blood_group?: string;
    identity_document_url?: string;
    bank_name?: string;
    account_name?: string;
    account_number?: string;
    specialty?: string;
    experience_years?: number;
    clinic_address?: string;
    consultation_fee?: number;
    payment_instructions?: string;
    email_alerts_enabled?: boolean;
    verification_status?: 'pending' | 'approved' | 'rejected' | 'unsubmitted';
    updated_at?: string;
}

export interface MedicalProfileData {
    blood_group?: string;
    genotype?: string;
    allergies?: string;
    chronic_conditions?: string;
    emergency_contact_name?: string;
    emergency_contact_phone?: string;
}

export interface PrescriptionData {
    patient_id: string;
    doctor_id: string;
    medication_name: string;
    dosage: string;
    frequency: string;
    duration: string;
    instructions?: string;
}

export interface ReviewData {
    patient_id: string;
    doctor_id: string;
    rating: number;
    comment?: string;
}

export interface NotificationPayload {
    user_id: string;
    title: string;
    message: string;
    type: 'system' | 'appointment' | 'payment' | 'prescription' | 'message' | 'appointment_proposal' | 'other';
    link?: string;
    fcm_status?: 'pending' | 'sent' | 'failed' | 'skipped';
    send_email?: boolean;
}

export interface Notification {
    id: string;
    user_id: string;
    title: string;
    message: string;
    type: 'system' | 'appointment' | 'payment' | 'prescription' | 'message' | 'appointment_proposal' | 'other';
    is_read: boolean;
    link?: string;
    fcm_status: 'pending' | 'sent' | 'failed' | 'skipped';
    created_at: string;
}

export interface DoctorSchedule {
    doctor_id: string;
    day_of_week: number;
    start_time: string;
    end_time: string;
    is_available: boolean;
}

export interface Profile {
    id: string;
    full_name: string;
    email?: string;
    avatar_url?: string;
    role?: 'patient' | 'doctor' | 'admin';
    requested_role?: 'doctor' | 'admin';
    specialty?: string;
    experience_years?: number;
    clinic_address?: string;
    consultation_fee?: number;
    verification_status?: 'pending' | 'approved' | 'rejected';
    verified_by?: string;
    negotiated_fee?: number;
    fee_status?: string;
    subscription_status?: 'active' | 'expired';
    subscription_expires_at?: string;
    last_subscription_payment_at?: string;
    account_status?: string;
    rejection_reason?: string | null;
    verification_document_url?: string;
    identity_document_url?: string;
    live_selfie_url?: string;
    medical_license_number?: string;
    languages_spoken?: string;
    address_document_url?: string;
    preferred_consultation_types?: string[];
    fcm_token?: string;
    dob?: string;
    gender?: string;
    next_of_kin_name?: string;
    next_of_kin_phone?: string;
    emergency_contact_name?: string;
    emergency_contact_phone?: string;
    blood_group?: string;
    bank_name?: string;
    account_name?: string;
    account_number?: string;
    created_at: string;
    auditor?: { full_name: string };
}

export interface AppointmentWithDetails {
    id: string;
    created_at: string;
    appointment_date: string;
    status: 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'rescheduled';
    reason?: string;
    patient_id: string;
    doctor_id: string;
    patient: { full_name: string; avatar_url?: string };
    doctor: { full_name: string; avatar_url?: string };
}

export interface ForumPostWithAuthor {
    id: string;
    author_id: string;
    title: string;
    content: string;
    category: string;
    status: 'approved' | 'pending' | 'rejected';
    created_at: string;
    author: { full_name: string; avatar_url?: string };
}

export interface CommentWithAuthor {
    id: string;
    post_id: string;
    author_id: string;
    content: string;
    created_at: string;
    author: { full_name: string; avatar_url?: string };
}

export interface Conversation {
    contact: Profile;
    lastMessage: {
        id: string;
        content: string;
        created_at: string;
        sender_id: string;
        receiver_id: string;
        is_read: boolean;
    };
    unreadCount: number;
}

export interface DoctorActivity {
    id: string;
    name: string;
    specialty?: string;
    total: number;
    completed: number;
    cancelled: number;
    pending: number;
    uniquePatients: number;
    patients?: Set<string>;
}

export interface MedicalRecord {
    id: string;
    patient_id: string;
    title: string;
    description?: string;
    record_type: 'lab_result' | 'prescription' | 'imaging' | 'immunization' | 'clinical_note' | 'other';
    document_url: string;
    authorized_doctors: string[];
    created_at: string;
}
