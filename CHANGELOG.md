# Changelog

All notable changes to the Premon Care platform are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased] - 2026-07-31

### Added
- **Android App Release v1.0.1**: Video-consultation hardening release (`1.0.1+2`, tag `v1.0.1` on `premoncare-releases`).

### Fixed
- **Emergency payment gate (F3)**: Join/Start Meeting buttons for `emergency_accepted` appointments now require `payment_status='completed'` on both web and mobile; entering the room no longer bypasses the pay step.
- **Completed rejoin (F4)**: `completed` consultations can rejoin their room again (label "Rejoin Meeting"); mobile ownership gate no longer allows `pending` status.
- **Doctor post-call routing (F2)**: Doctors ending a call are routed to the doctor dashboard instead of the patient review screen (which inserted reviews with the wrong `patient_id`).
- **iOS permissions (F1)**: Added `NSCameraUsageDescription` + `NSMicrophoneUsageDescription` to `Info.plist` — Jitsi calls would have crashed on iOS.
- **Call duration (F5)**: Web meeting room now persists `duration_minutes` on call end, matching mobile.
- **Jitsi toolbar (F6)**: Trimmed to mic/camera/screen/chat/hangup/fullscreen/tileview/settings on web and mobile — removes invite/recording/livestreaming/download (HIPAA + no invite-link leakage).
- **Cross-platform docs (F7)**: `AGENTS.md`, `README.md`, `SYSTEM_WALKTHROUGH.md` room naming corrected to `PremonCare-{appointmentId}` (pinned by tests on both platforms).

### Added
- **Testing**: Middleware/session guard suite (proxy matcher, `updateSession` role guards + `premon_role` cookie caching, `role-redirect`), cross-platform Jitsi room parity tests, upgraded `next/server` test harness (cookie jars, `NextResponse.next`, status handling). 92 web tests total. AGENTS.md/AGENTS.template.md now mandate regression tests for bug fixes and record verified test commands + harness rules.
- **GDPR Right to Erasure**: `soft_delete_user()` RPC marks profile as deleted, anonymizes auth email. `purge_deleted_accounts()` permanently deletes after 30-day grace period. Both web and mobile settings updated to use soft-delete API.
- **GDPR Right to Portability**: `export_user_data()` RPC returns JSON of all user data (profile, appointments, messages, medical records, prescriptions, payments, reviews, forum posts/replies). Web: `/api/user/export` download endpoint. Mobile: `download_data_screen.dart` calls RPC and copies to clipboard.
- **HIPAA PHI Audit Logging**: `log_phi_access()` RPC for tracking medical records, prescriptions, and messages access. Audit logs include user_id, action, resource_type, and details.
- **HIPAA Breach Notification**: Documented 60-day HIPAA and 72-hour GDPR breach notification procedures in `AGENTS.md` incident response section.
- **Data Retention Auto-Cleanup**: `cleanup_old_notifications()` (30 days), `cleanup_old_device_sessions()` (90 days) functions with pg_cron schedule templates.
- **SQL Migration**: Added `user_id`, `action`, `details` columns to `audit_logs` table. Added RLS policies for user self-service (view own logs, insert own logs).
- **SQL Migration**: Added `deleted_at`, `deletion_reason` columns to `profiles` table for GDPR soft-delete.
- **Web API**: `/api/user/export` — authenticated data export endpoint. `/api/user/delete` — soft-delete endpoint.
- **Web Settings**: Added "Download My Data (GDPR)" button in Privacy & Data section.
- **Mobile Download Data**: Updated to call `export_user_data()` RPC and copy JSON to clipboard instead of just logging an audit entry.
- **AGENTS.md**: Updated HIPAA audit logging status to Implemented. Updated GDPR Right to Erasure and Portability to Implemented. Added breach notification documentation with HIPAA 60-day and GDPR 72-hour windows. Added agent rule for security incident flagging. Updated BAA status — self-hosted Supabase on Coolify means no BAA with Supabase Inc. required.
- **Testing**: Jest config + 3 test suites for web (security sanitization, user-facing-errors, Badge component). Added `@testing-library/react`, `@testing-library/jest-dom`, `ts-jest`, `jest-environment-jsdom` dev dependencies.
- **CI/CD**: GitHub Actions workflows for web (lint → typecheck → test → build) and mobile (analyze → test → build Android). Runs on push to main/develop and PRs.
- **Code Formatting**: Prettier config (`.prettierrc`) for web. Added `format`, `format:check`, `typecheck`, `test` scripts to web `package.json`.
- **Pre-commit Hooks**: `.githooks/pre-commit` script runs ESLint + TypeScript check on web files and `flutter analyze` on mobile files before allowing commits.
- **PR Template**: `.github/PULL_REQUEST_TEMPLATE.md` with security checklist, testing checklist, and deployment notes.
- **Task Runner**: `Makefile` with targets for `dev`, `lint`, `test`, `build`, `format`, `typecheck`, `analyze`, `ci`, `clean`, `hooks`.
- **Root Scripts**: Workspace-level npm scripts for `dev:web`, `build:web`, `lint:web`, `test:web`, `typecheck:web`, `format:web`, `analyze:mobile`, `test:mobile`.
- **Mobile Avatar Upload RLS**: Changed storage path from `avatars/{userId}.{ext}` to `{userId}/avatar_{timestamp}.{ext}` to comply with RLS policy `(storage.foldername(name))[1] = auth.uid()`.
- **Mobile Gender Casing**: Standardized to lowercase (`'male'`/`'female'`/`'other'`) on save, with display capitalization. Matches web behavior.
- **Web Profile Realtime**: Added Realtime subscription on `profiles` table in `dashboard-layout.tsx` for live profile updates across tabs.
- **Web Avatar in Header**: Replaced generic `User` icon with actual `profile?.avatar_url` image in the header.
- **Web Profile State Refresh**: Replaced `window.location.reload()` with re-fetch + `setState` in both patient and doctor `profile-settings.tsx`.
- **Mobile Forum Report**: Added `status: 'pending'` to Supabase insert in `forum_provider.dart`.
- **Web Forum Category**: `post-form.tsx` now looks up `category_id` from `forum_categories` table. `post-card.tsx` handles object/string category. `post-detail.tsx` added category join to query.
- **Mobile Dispute Status**: Changed all `'closed'` references to `'dismissed'` (valid enum value) in `dispute_resolution_screen.dart` and `financial_moderation_screen.dart`.
- **Mobile Dispute Status Standardization**: Changed all `'in_review'` to `'under_review'` across dispute resolution and financial moderation screens.
- **Mobile Doctor Verification**: Added role promotion from `patient` to `doctor` on admin approval with guard to prevent overwriting existing roles. Added notification dispatch via web API.
- **Mobile Emergency Booking**: Removed duplicate direct DB notification insert; dispatches only via `/api/notifications/dispatch` to prevent duplicates.
- **Mobile Emergency Accept/Decline**: Removed duplicate direct DB notification insert; dispatches only via `/api/notifications/dispatch`.
- **Web Doctor Dashboard Status**: Fixed `'scheduled'` → `'confirmed'` for pending appointments in `doctor/dashboard/page.tsx`.
- **Mobile Messaging Notifications**: Added FCM push dispatch via web API after message insert in `messaging_provider.dart`.
- **Web Moderation Report Status**: Changed `'resolved'` → `'action_taken'` (valid enum value) in `moderation-dashboard.tsx`. Added `resolved_at` timestamp.
- **Web Booking Form**: Added missing `consultation_mode: 'video'`, `total_amount: 0`, `is_emergency: false` fields to insert.
- **Web Admin Emergency Queue**: Fixed `.eq('type', 'emergency')` → `.eq('is_emergency', true)`.
- **SQL Schema**: Added `REPLICA IDENTITY FULL` on `profiles`, `forum_posts`, `forum_replies`, `forum_reports`. Added `forum_reports` to Realtime publication.
- **Web Forum Realtime**: Added Realtime subscription for `forum_replies` in `comment-section.tsx`.
- **Mobile Doctor Appointments**: Changed `FutureProvider` → `StreamProvider` using `.stream(primaryKey: ['id'])` for real-time updates.
- **Mobile Bulk Payment Audit**: Added `processed_by: adminId` to approve update in `financial_moderation_screen.dart`.
- **Mobile Report Reason Dialog**: Replaced hardcoded `'Reported by user'` with user input `AlertDialog` in both `forum_list_screen.dart` and `post_detail_screen.dart`.
- **iOS Foreground Notifications**: Removed `android != null` check, added `DarwinNotificationDetails` in `notification_service.dart`.
- **Mobile FCM Token Refresh**: Added `_fcm.onTokenRefresh.listen()` + `_syncTokenToServer()` method in `notification_service.dart`.
- **Mobile Admin Broadcasts**: Added FCM push dispatch via web API loop in `sendSystemNotification()` in `admin_service.dart`.
- **Mobile Notification Preferences**: Added server-side sync of `email_alerts_enabled` to `profiles` table alongside local SharedPreferences.
- **Mobile Chat List Search**: Converted `ChatListScreen` to `ConsumerStatefulWidget` with search filtering by name/specialty/message content.
- **Web Forum Search**: Converted `ForumFeed` to client component with local state search filtering by title/content/author name.
- **Web Patient/Doctor Appointments Realtime**: Added `postgres_changes` subscription on `appointments` table for live updates.
- **Web Doctor Appointments Realtime**: Added `postgres_changes` subscription on `appointments` table for doctor-side live updates.

### Added
- **SQL Migration**: Added `under_review` enum value to `dispute_status` for standardized dispute workflow.
- **SQL Migration**: Added `email_alerts_enabled` boolean column to `profiles` table for notification preference sync.

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
