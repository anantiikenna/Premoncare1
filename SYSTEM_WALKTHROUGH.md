# 🏥 Premon Care - System Walkthrough

Welcome to the **Premon Care Platform**. This document provides a comprehensive guide to the system's architecture, user roles, and core workflows. It is updated continuously as new features are implemented.

---

## 🔐 1. Identity & Security Architecture

The system is built on a **"Security First"** principle, leveraging Supabase Row Level Security (RLS) to ensure data isolation.

### 🛡️ Zero-Trust API Routing
- **Middleware Boundary**: The platform leverages a secure wrapper (`src/lib/security.ts`) that envelops every API endpoint.
- **Strict Validations**: `Zod` enforces payload schema exactness, and `isomorphic-dompurify` sanitizes outputs against Cross-Site Scripting (XSS).
- **In-Memory Rate Limiting**: All client traffic is governed by dynamic rate limiting bounds per Minute.
- **CORS Protection**: Enforces origin domains, securing both web views and Flutter native mobile endpoints securely.
- **Global HSTS Headers**: Forces non-negotiable HTTPS traffic preventing downgrade protocols.

### 👥 User Roles (Standardized Entry)

The platform enforces a mandatory **3-Step Registration Pipeline** for all users:
1.  **Step 1: Identity**: Legal Name, Email, and a complex Password.
2.  **Step 2: Terms Consent**: Interactive review and explicit agreement to the Terms of Service and Privacy Policy.
3.  **Step 3: OTP Sync**: Real-time email verification. The user account is not activated until the 7-digit secure code is verified against the backend.

**Note**: All users (including practitioners) register as Patients initially.

- **Standard Account (Patient)**: The default role for all verified users. Access to booking, medical records, and community forums.
- **Practitioner (Doctor)**: A standard account that has been elevated via the Professional Induction Flow.
  - **Mandatory Registration Flow**: There is no "Doctor" option on the signup page. Professionals must register as a patient, then fill out the **Verification Wizard** (Professional details, License, etc.) within their patient dashboard and wait for **Admin Approval**.
  - **Unified Experience**: Doctors maintain full patient functionality! They can manage their personal health and book colleagues for consultations.
  - **Switching Dashboards**: Approved doctors can toggle between the **Patient View** and **Doctor View** at any time. This is accessible from the Profile menu or the navigation header.
- **Administrator**: Total oversight, tiered professional verification, and system configuration.

### Professional Induction Flow (Verification Wizard)
To prevent unauthorized privilege escalation, the platform uses a **4-Step Verification Wizard**:
1. **Professional Profile**: Candidates provide their specialty, years of experience, and upload their medical license.
2. **Identity Documents**: Candidates upload a government-issued ID (Passport, National ID) to a 256-bit encrypted private vault.
3. **Facial Biometrics**: A live selfie is captured using the browser's camera. This image is used by administrators to verify the practitioner is the person on the identity document.
4. **Manual Audit & Review**: Administrators perform a side-by-side comparison of the medical license, government ID, and live selfie before promoting the user to the `doctor` role.
5. **Rejection & Rectification**: If the information provided is insufficient or invalid, the administrator rejects the application with a specific **`rejection_reason`**. Candidates can view this reason in their dashboard and rectify the issues (e.g., upload a clearer ID) to re-submit for review.


---

## 📅 2. Patient Experience (P2P Financial Model)

### Consultation Credits Booking & UI
- **Direct P2P Payments**: Patients pay doctors directly for consultations via manual receipt upload. All digital payment gateways (Dodo, Paystack) are **disabled**.
- **Session Durations**: Patients choose between **15, 30, 45, or 60 minute** consultations.
- **Consultation Credits**: Consultation minutes are tracked as "Consultation Credits". Upon verifying a patient's payment, the doctor credits the patient's balance with the purchased minutes.
- **Dynamic Pricing**: Fees are calculated in **Naira (₦)** based on the doctor's negotiated hourly rate (e.g., `₦Rate * (Duration/60)`).
- **Automated Redirects**: If a patient has insufficient credits to book, the system automatically redirects them to the payment dashboard with pre-filled fee and duration parameters.

### Health Management
- **Medical Profile**: A secure, encrypted space for allergies, medications, and health history. Access is restricted to the patient and their assigned practitioners.
- **Clinical Records**: Patients can view notes and prescriptions issued by their doctors immediately after a consultation.

### 🚨 Emergency Guest Booking (Rapid Access — Uber-Style Handshake)
The platform supports a high-urgency flow for critical health situations:
- **Registration Bypass**: Users can browse and book doctors without a standard account.
- **Dynamic 5x Pricing**: Emergency consultations carry a **500% premium** (5x the doctor's base rate) to ensure immediate attention and immediate practitioner payouts.
- **Guest Tracking**: Guest users are tracked via `guest_token` in appointment `metadata`. `patient_id` is nullable for guest bookings.

#### 🤝 Doctor Acceptance Handshake (3-Minute Window)
1. **Patient Submits Request**: The patient selects a doctor and confirms the emergency booking. The appointment is created with status `emergency_request`.
2. **Doctor Receives Alert**: The doctor receives a real-time notification (FCM push + in-app Realtime subscription) with a countdown timer.
3. **Doctor Responds** (within 3 minutes):
   - **Accept**: Status changes to `emergency_accepted`. The patient sees payment instructions and proceeds with P2P payment.
   - **Decline**: Status changes to `emergency_declined`. The patient is prompted to find another doctor.
   - **Timeout**: If no response within 3 minutes, the request auto-declines and the patient is prompted to find another doctor.
4. **Patient Pays**: After acceptance, the patient sees the 5x fee and doctor's P2P payment instructions.
5. **Consultation Begins**: Once payment is confirmed, the status changes to `ongoing` and the video session starts.

#### Platform Implementations
- **Mobile Doctor UI**: `doctor_emergency_request_screen.dart` — urgent red theme, countdown ring, Accept/Decline buttons.
- **Mobile Doctor Dashboard**: `doctor_dashboard.dart` — live emergency request banner with tap-to-accept flow.
- **Web Doctor UI**: `EmergencyRequestAlert` component — real-time card with SVG timer, Accept/Decline, toast notifications.
- **Mobile Patient UI**: `emergency_waiting_screen.dart` — animated countdown pulse, status updates via Realtime.
- **Web Patient UI**: `/emergency-waiting` page — SVG ring timer, Realtime redirect to checkout on accept.

#### Database Schema
- `appointments.status` supports: `emergency_request`, `emergency_accepted`, `emergency_declined`, `pending`, `confirmed`, `cancelled`, `completed`, `ongoing`.
- `appointments.patient_id` is nullable for guest emergency bookings.
- `appointments.metadata` stores `guest_token`, `is_guest`, `pricing_multiplier` for guest tracking.

---

## 🩺 3. Practitioner Experience

### Revenue & Subscription Management
- **Decentralized Verification**: Doctors act as their own financial auditors. They review uploaded receipts from patients and approve them to unlock consultation time.
- **Tiered Platform Subscriptions**: Doctors pay the platform for access. They can choose to subscribe for **1, 3, 6, or 12 months** based on a negotiated monthly rate.
- **Automated Activation**: Upon admin verification of a doctor's platform fee, their dashboard is automatically unlocked or extended.

### Telemedicine
- **Web**: Secure video consultations via Jitsi Meet Iframe API (`8x8.vc`). Dynamic room creation per appointment ID.
- **Mobile**: Native Jitsi SDK (`jitsi_meet_flutter_sdk: ^13.1.0`). Real-time mute/video toggle synced to Jitsi. Controls: mute, camera, chat, screen share, end call.
- **Automatic Room Creation**: No external accounts required; rooms are dynamically generated as `PremonCare-{appointmentId}`.

### 💬 Real-Time Clinical Communications (Mobile & Web)
- **Secure Messaging**: End-to-end HIPAA-conscious messaging via Supabase Realtime.
- **Clinical Attachments**: Seamlessly send Prescriptions, Lab Reports, Images, and Geolocation context within threads.
- **Operational Clarity**: Read receipts, online presence tracking, and clear unread dividers to maintain communication flow.

---

## 🏛️ 4. Administration & Governance

### Governance, Live Audit Trail & System Parity
The platform supports **Multi-Admin Oversight** with complete **Web-to-Mobile Parity**:
- **Administrative Audit & Live Monitoring**: Every critical action (Doctor verification, system config change, suspicious login) is recorded in the newly introduced `audit_logs` table. Administrators have access to a real-time Audit Timeline Viewer across both platforms to instantly trace and mitigate security threats.
- **Granular Security Controls**: Both Web and Mobile clients now feature a comprehensive Settings & Privacy Center allowing users to toggle Biometrics, 2FA, and monitor active `device_sessions`.
- **Admin Notifications**: Administrators receive real-time alerts when P2P payments are verified between users to ensure platform transparency and prevent fraud.

### Financial Moderation & Mobile Control
- **Platform Fee Review**: Admins verify practitioner subscription receipts in the **Financial Dashboard**.
- **Currency Control**: The platform is localized to **Naira (₦)** across all pricing and report modules.
- **Mobile Administration**: Full-featured moderation tools available on the mobile application, enabling on-the-go Doctor Verification (Approval/Rejection/Info Requests) and instantaneous mass Payout execution.

---

- **User Control**: Users can toggle email alerts on/off directly from their **Profile Settings**.
- **Unified Dispatcher**: The platform uses a central API (`/api/notifications/dispatch`) that bridges business logic to both Email and FCM services.

---

## 📲 7. Real-Time Push Notifications (FCM)

The platform supports native push notifications for iOS and Android via **Firebase Cloud Messaging (FCM)**.

### 🔔 Mobile Push Strategy
- **Database-First**: Every notification is first recorded in the Supabase `notifications` table for persistent history.
- **Async Delivery**: Upon record creation, a server-side service attempts to dispatch a real-time push via FCM if the user has an active `fcm_token` synced to their profile.
- **Cross-Platform**: Notifications appear in the mobile app foreground (via local alerts) or background (system tray).

### 🛡️ Notification Security Boundary
To prevent unauthorized access, the platform enforces a strict cryptographic boundary:
- **Server-Only Admin SDK**: The Firebase Admin SDK and its associated Private Keys are restricted to the **Web Backend**. They are never included in the mobile binary.
- **Client-Side Registration**: Mobile clients are only responsible for retrieving their own Push Token and syncing it safely to their private profile via Supabase.

### 🚨 Mobile Notification Center
- **Mission Control UI**: A dedicated, high-fidelity hub on the mobile application for all alerts.
- **Sticky Priorities**: Emergency alerts are pinned to the top of the feed to ensure immediate visibility.
- **Categorized Tabs**: Streamlined navigation between 'All', 'Unread', 'Appointments', 'Payments', and 'Emergency' categories.

---

## ⚙️ 8. Settings & Privacy Center (Mobile)

All settings persist to `SharedPreferences` and survive app restarts.

| Category | Controls | Persistence |
| :--- | :--- | :--- |
| **Notification Preferences** | Push, email, appointment, payment, clinical, forum, emergency, marketing toggles | `SharedPreferences` keys: `notif_push`, `notif_email`, etc. |
| **Biometric & Privacy** | Biometric lock, profile visibility, online status, research data sharing, crash reporting | `SharedPreferences` keys: `privacy_biometric`, `privacy_profile_visible`, etc. |
| **Accessibility** | Text scale (0.8x–1.5x), high contrast, reduce animations, screen reader hints | `SharedPreferences` keys: `access_text_scale`, `access_high_contrast`, etc. |
| **Health Preferences** | Weight (kg/lbs), height (cm/ft/in), temperature (°C/°F), date format | `SharedPreferences` keys: `health_weight_unit`, etc. |
| **Language & Region** | 6 languages, 6 regions, 6 currencies | `SharedPreferences` keys: `locale_language`, `locale_region`, `locale_currency` |
| **Login & Security** | Change password (current + new + confirm), email verification, forgot password | Supabase `auth.updateUser` |
| **About** | Version info, tappable website (`www.premoncare.com`), tappable email (`hello@premoncare.com`) | `url_launcher` for links |
| **Device Sessions** | Current device (real platform name via `Platform.isAndroid`/`Platform.isIOS`), logout all | Supabase `auth.signOut` |

---

## 🛠️ 6. Technical Stack

| Category | Technology |
| :--- | :--- |
| **Frontend** | Next.js 16.2.2 (App Router), TypeScript, Tailwind CSS v4 |
| **Mobile** | Flutter 3.x, Riverpod 3.3.2, go_router 17.3.0 |
| **Backend** | Supabase (Auth, Database, Storage) |
| **Currency** | Optimized for Naira (₦) |
| **Time Tracking** | Custom balance-minute logic for P2P consultations |
| **Audit Log** | Real-time `audit_logs` engine with Web/Mobile visualization |
| **Device Security** | Persistent `device_sessions` tracking and revocation |
| **Video (Web)** | Jitsi Meet Iframe API (`8x8.vc`) |
| **Video (Mobile)** | `jitsi_meet_flutter_sdk: ^12.1.3` (native SDK) |
| **Email** | Nodemailer with Gmail SMTP & Branded HTML Templates |
| **Push Notifications** | Firebase Cloud Messaging (FCM) via Admin SDK |
| **Settings Persistence** | `shared_preferences` (Mobile) |
| **Tappable Links** | `url_launcher` (Mobile) |
| **UI Components** | Radix UI (shadcn/ui), Lucide Icons (Web); AppColors + AppTypography (Mobile) |

---

> [!CAUTION]
> **Biometric Privacy & Retention**: Live selfie captures and government ID documents are stored exclusively for identity verification purposes. These artifacts are retained for the duration of the practitioner's active status and are deleted upon account closure in compliance with privacy regulations.

> [!TIP]
> **Accountability**: Admins can now find the specific auditor for any professional verification in the `profiles.verified_by` field.

> [!IMPORTANT]
> **P2P Growth**: The direct-payment model ensures doctors receive their funds directly while the platform maintains a healthy relationship with providers through transparent subscription fees.
