# Changelog

All notable changes to the Premon Care platform are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased] - 2026-07-27

### Fixed
- **Netlify Build**: Dynamic import `notifications-dispatch` in `queries-base.ts` to prevent `firebase-admin` and `nodemailer` (Node.js-only packages) from leaking into Client Component bundles via `queries-client.ts`, causing 55 Turbopack build errors (`fs`, `child_process`, `net`, `tls`, `dns` module-not-found).
- **SQL Schema**: Added `SET ROLE postgres` to `schema.sql` to bypass `42501: must be owner of table` errors in Supabase SQL Editor.
- **SQL Schema**: Wrapped all `ALTER PUBLICATION`, `ALTER TABLE realtime.messages`, and forum publication statements in `DO $$ ... EXCEPTION WHEN OTHERS` safe blocks.
- **SQL Migration**: Added `SET ROLE postgres` to `update_live.sql` to bypass ownership errors.
- **SQL Migration**: Wrapped `ALTER PUBLICATION` statements in safe `DO` blocks with exception handling.

---

## [1.3.0] - 2026-07-26

### Fixed
- **SQL Migration**: Safe constraint rebuilds in `update_live.sql` — clean invalid appointment statuses before adding CHECK constraints to avoid constraint violation errors on re-run.
- **SQL Migration**: Wrapped `REPLICA IDENTITY` statements in `DO $$ ... EXCEPTION WHEN OTHERS` blocks (previously `EXCEPTION WHEN insufficient_privilege` which didn't catch all ownership errors).
- **Emergency Access Flow**: 7 issues resolved across web and mobile:
  1. Web emergency booking `shouldCreateUser: true` → `false` (no orphan auth accounts for guests).
  2. Mobile emergency waiting timeout now navigates to `/emergency-failed` after 2s delay.
  3. Mobile `_handleAccepted` passes complete extras (`durationMinutes`, `appointmentId`, `consultationType`) to `BookingConfirmedScreen`.
  4. Web emergency doctor query filters with `.eq('is_emergency', true)`.
  5. Mobile emergency doctors fallback to all online doctors if none have `is_emergency: true`.
  6. Mobile emergency insert includes `reason` and `consultation_mode`.
  7. Web guest phone cleanup with `localStorage.removeItem('premon_guest_phone')`.
- **Emergency Guest Booking RLS**: New policies for guest INSERT (`patient_id IS NULL AND is_emergency = true`), guest SELECT (via `guest_token`), guest UPDATE (link `patient_id`), and admin ALL on `appointments`.
- **Schema**: Added `accepted_at timestamp with time zone` column to appointments table.

### Added
- **Login Flow**: Email existence verification — queries `profiles` table before sending OTP; shows "sign up first" if email not found.
- **Login Flow**: Admin role blocking — prevents admin emails from logging into patient/doctor platform.
- **OTP Verification**: Blocks admin users after OTP verification completes.
- **OTP Resend**: Fixed `_resendOtp()` to use `shouldCreateUser: false`.

---

## [1.2.0] - 2026-07-25

### Changed
- **Admin Dashboard UI/UX Overhaul** (17 screens):
  - Mesh circle background with gradient hero KPI card.
  - Shadows added to all cards (`AdminCard`, `AdminStatCard`, `AdminListSkeleton`).
  - Uppercase overline section headers with `AppTypography`.
  - Shared `AdminStatCard` widget extracted for reuse.
  - Dark mode fix across all 17 admin screens — ~300+ hardcoded `AppColors.slate*` values replaced with theme-aware `*Of(context)` variants.
- **Gradle**: Reduced JVM heap from `-Xmx8G` to `-Xmx4G` and `-XX:MaxMetaspaceSize` from `4G` to `2G` due to OOM on 11GB system.
- **Dependencies**: `flutter pub upgrade` updated 3 packages; `jitsi_meet_flutter_sdk` already at `^13.0.0`.

### Files Modified
`admin_dashboard.dart`, `admin_shared_widgets.dart`, `admin_scaffold.dart`, `admin_charts_widget.dart`, `admin_emergency_queue_screen.dart`, `admin_reports_screen.dart`, `admin_audit_timeline_screen.dart`, `dispute_resolution_screen.dart`, `doctor_verification_panel.dart`, `forum_moderation_panel.dart`, `financial_moderation_screen.dart`, `user_management_panel.dart`, `notification_control_panel.dart`, `subscription_plan_control.dart`, `doctor_subscription_management.dart`, `p2p_monitoring_panel.dart`, `admin_avatar.dart`

---

## [1.1.0] - 2026-07-20

### Added
- **Admin Dispute Resolution Center**: Full dispute resolution and forum moderation dashboard screens.
- **Admin Avatar Widget**: `AdminAvatar` component for consistent user profile display.
- **Appointment Rescheduling**: Patients and doctors can reschedule existing appointments.
- **Doctor Patients Screen**: Doctors can view and search their patient list.
- **Emergency Availability Toggle**: Doctors can toggle emergency availability with snackbar feedback.
- **Settings Screens**: Various settings screens for user preferences and data management.

### Fixed
- **Auth**: OTP downgraded to 7 digits, password visibility hardened, responsive OTP layout.
- **Forum**: Wired all screens to real Supabase data, removed all dead buttons.
- **Financial**: Replaced hardcoded admin data with live queries, wired all dead buttons.
- **Security**: Comprehensive security audit remediation — RLS policies for all tables, auth screen hardening.
- **Realtime**: Supabase Realtime best practices implementation.
- **Video**: Audit and fix video meeting lifecycle and display issues.
- **Database**: Schema consistency, missing RPCs, column name mismatches.
- **Dark Mode**: Replaced hardcoded colors with `AppColors` theme-aware methods.

### Changed
- **Payment System**: Removed Dodo Payments and Paystack gateway integrations. P2P manual receipt verification only.
- **Web Admin Pages**: All admin pages wired to real Supabase data (audit timeline, reports, subscriptions, disputes, emergency queue, doctor profiles).
- **Mobile Dead Buttons**: Fixed 46 buttons across 24 files (auth, patient, forum, doctor, admin, shared).
- **Web Dead Buttons**: Fixed 20+ buttons across 12 files.
- **Mobile UX Overhaul**: 13 fixes including design tokens (`AppColors`, `AppTypography`), admin auth gate, registration improvements, splash screen error handling, WCAG font compliance, onboarding brand colors.

### Deprecated
- `/api/payments/webhook` and `/api/payments/paystack/webhook` endpoints (return 501).

---

## [1.0.0] - 2026-06-18

### Added
- **Core Platform Launch**:
  - Patient dashboard, doctor search, booking flow, payment verification.
  - Doctor dashboard, appointment management, schedule management, earnings.
  - Admin dashboard, user management, doctor verification, financial moderation.
  - Real-time messaging between patients and doctors.
  - Medical records vault with doctor access permissions.
  - Forum ecosystem (posts, replies, reports, categories, saves, follows).
  - Subscription plans and doctor subscriptions.
  - Notification system (push via FCM, email via Loops).
  - Video consultations via Jitsi Meet.
  - Emergency guest booking with OTP.
  - Device session tracking and security audit logs.
  - Dispute resolution system.
  - Review and rating system.
- **Mobile App (Flutter)**:
  - Flavor-based deployment (User App + Admin App).
  - Riverpod state management.
  - Glassmorphism design system (`GlassCard`, `AppColors`).
  - Dark mode with theme persistence.
  - Settings and privacy persistence via SharedPreferences.
  - Biometric lock support.
  - Multi-language and multi-currency support.
- **Web App (Next.js 16)**:
  - App Router + Proxy for session management.
  - Supabase SSR integration.
  - Real-time subscriptions via Supabase Realtime.
  - Manual P2P payment receipt upload and verification.
  - Guest emergency booking flow.
- **Infrastructure**:
  - Supabase (Auth, Database, Realtime, Storage, Edge Functions).
  - Firebase Admin SDK for FCM push notifications.
  - Loops for transactional emails.
  - Netlify deployment for web app.
  - PostgreSQL with Row Level Security (RLS) on all tables.

---

*This changelog is auto-generated from git commit history and manually curated for clarity.*
