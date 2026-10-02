# Premon Care — Premium Healthcare Platform

A comprehensive, HIPAA/GDPR-compliant healthcare management system built with **Next.js 16** (Web), **Flutter 3.47** (Mobile), and **Supabase** (self-hosted on Coolify). Features a P2P financial model, biometric identity verification, real-time clinical messaging, smart appointment scheduling, emergency consultations, and encrypted video calls.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Storage Buckets](#storage-buckets)
- [Running the Apps](#running-the-apps)
- [Project Structure](#project-structure)
- [Core Systems](#core-systems)
  - [Verification Wizard](#verification-wizard)
  - [Emergency Booking](#emergency-booking)
  - [Video Consultations](#video-consultations)
  - [Messaging & Realtime](#messaging--realtime)
  - [Notifications](#notifications)
  - [Dark Mode & Design System](#dark-mode--design-system)
  - [Localization (i18n)](#localization-i18n)
- [Security](#security)
- [HIPAA & GDPR Compliance](#hipaa--gdpr-compliance)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)
- [License](#license)

---

## Features

### Patient Features
- **Smart Appointment Booking** — Search doctors by specialty, view schedules, book video/in-person consultations
- **Emergency consultations** — Uber-style emergency flow with real-time doctor acceptance handshake (5x base rate)
- **Medical Records Vault** — Upload, manage, and selectively share encrypted medical documents with doctors
- **Prescription Management** — View prescriptions, acknowledge receipt, track medication history
- **Real-time Messaging** — Encrypted chat with doctors, rich attachments, read receipts
- **Social Forum** — Community health discussions, ask-a-doctor queue, trending topics, upvoting
- **P2P Payments** — Manual payment with receipt upload and admin verification
- **Guest Emergency Booking** — Non-registered users can book emergency consultations with guest tracking

### Doctor Features
- **Clinical Dashboard** — Today's appointments, patient queue, earnings overview, real-time status
- **Schedule Management** — Configure weekly availability, set consultation rates, manage time blocks
- **Consultation Notes** — Digital prescription pad, medical notes, consultation summaries
- **Video Consultations** — Native Jitsi Meet integration with screen share, mute, chat
- **Patient Records Access** — Request and view shared medical records with audit logging
- **Earnings Analytics** — Revenue tracking, payout history, subscription management
- **Emergency Response** — Real-time emergency alerts with 3-minute accept/decline countdown

### Admin Features
- **Doctor Verification Panel** — Review credentials, approve/reject/revoke practitioner applications
- **Financial Moderation** — P2P payment verification, bulk approve/reject, payout processing
- **Dispute Resolution** — Handle patient-doctor disputes with evidence review and resolution
- **User Management** — Search, filter, suspend, verify users across all roles
- **Emergency Queue** — Monitor real-time emergency requests, assign doctors
- **System Monitor** — Live operations dashboard, active consultations, online doctors
- **Notification Broadcasts** — System-wide announcements, targeted clinical alerts

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENTS                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Web (Next.js)│  │ Mobile (Flutter)│  │  Admin (Flutter)│ │
│  │  App Router   │  │ Riverpod      │  │  Flavor-based   │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘  │
│         │                 │                  │           │
│         └────────┬────────┴──────────────────┘           │
│                  │                                       │
│  ┌───────────────▼───────────────────────────────┐      │
│  │          Supabase (Self-hosted)                │      │
│  │  ┌─────────┐ ┌──────────┐ ┌────────────────┐  │      │
│  │  │ Auth    │ │ Database │ │ Storage        │  │      │
│  │  │ (OTP)   │ │ (Postgres│ │ (Private       │  │      │
│  │  │         │ │  + RLS)  │ │  Buckets)      │  │      │
│  │  └─────────┘ └──────────┘ └────────────────┘  │      │
│  │  ┌──────────────────┐ ┌──────────────────┐    │      │
│  │  │ Realtime         │ │ Edge Functions   │    │      │
│  │  │ (postgres_changes│ │ (Server-side     │    │      │
│  │  │  + broadcasts)   │ │  notifications)  │    │      │
│  │  └──────────────────┘ └──────────────────┘    │      │
│  └───────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Firebase FCM │  │ Loops Email  │  │ Jitsi Meet   │  │
│  │ (Push Notif) │  │ (Transactional│ │ (Video Calls) │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| **Self-hosted Supabase** | Full PHI control, no third-party data access, HIPAA compliance without BAA with Supabase Inc. |
| **Manual P2P payments** | Avoids PCI-DSS scope; patients upload receipts, admins verify |
| **Flavor-based mobile builds** | Separate APKs for user/admin prevents privilege escalation |
| **CSS variables (web) + AppColors (mobile)** | Theme-aware color system with dark mode support |
| **15-minute inactivity timeout** | HIPAA addressable specification for automatic session termination |

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| **Node.js** | 20+ | Web app runtime |
| **npm** | 10+ | Web dependency management |
| **Flutter** | 3.47+ | Mobile app |
| **Dart** | 3.13+ | Mobile SDK |
| **Java** | 17+ | Android builds |
| **Supabase** | Self-hosted (Coolify) | Auth, Database, Storage, Realtime |
| **Firebase** | Free tier | FCM push notifications |

### Self-Hosted Supabase (Coolify)

This project uses a self-hosted Supabase instance on Coolify. You need:

- A running Supabase instance (URL + Anon Key + Service Role Key)
- PostgreSQL access for schema migrations
- Storage buckets configured (see [Storage Buckets](#storage-buckets))
- `pg_cron` extension enabled for scheduled cleanup tasks
- Realtime enabled for the required tables

If you don't have Supabase self-hosted yet, follow the [Coolify Supabase guide](https://coolify.io/docs/knowledge-base/supabase).

---

## Installation

### 1. Clone & Install

```bash
git clone https://github.com/anantiikenna/Premoncare1.git
cd Premoncare1

# Install all dependencies
make install
# OR manually:
cd apps/web && npm install && cd ../..
cd apps/mobile && flutter pub get && cd ../..
```

### 2. Database Setup

#### Fresh Install
1. Go to your Supabase SQL Editor
2. Run `supabase/schema.sql` — creates all 33 tables, RLS policies, functions, triggers
3. Run `supabase/mock_data.sql` — optional, seeds demo data

#### Existing Instance
1. Run `supabase/update_live.sql` — cumulative migrations, safe to re-run (uses `_safe_policy()` for idempotent operations)

### 3. Storage Buckets

Create these in Supabase Dashboard → Storage:

| Bucket | Visibility | Purpose |
|---|---|---|
| `avatars` | Public | User profile pictures |
| `doctor-verifications` | Private | Medical licenses, credentials |
| `doctor-identities` | Private | Government IDs, biometric selfies |
| `payment-receipts` | Private | P2P payment proofs |
| `health-records` | Private | Clinical record attachments |
| `patient-verifications` | Private | Patient identity verification |
| `medical-documents` | Private | Shared medical records |

### 4. Realtime Publications

Ensure these tables are in the Supabase Realtime publication:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_reports;
-- Other tables should already be in the publication from schema.sql
```

### 5. pg_cron Schedules

Enable `pg_cron` extension, then schedule:

```sql
SELECT cron.schedule('cleanup-login-attempts', '5 * * * *', 'SELECT cleanup_old_login_attempts()');
SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notifications()');
SELECT cron.schedule('cleanup-device-sessions', '0 3 * * *', 'SELECT cleanup_old_device_sessions()');
SELECT cron.schedule('purge-deleted-accounts', '0 4 * * *', 'SELECT purge_deleted_accounts()');
SELECT cron.schedule('sweep-offline-doctors', '* * * * *', 'SELECT sweep_offline_doctors()');
```

---

## Environment Variables

### Web (`apps/web/.env.local`)

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-supabase-url.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Firebase (FCM Push Notifications) — Server-side ONLY
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY=your-private-key

# Email (Loops)
LOOPS_API_KEY=your-loops-api-key

# Site
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

> **Security:** `SUPABASE_SERVICE_ROLE_KEY`, `FIREBASE_*`, and `LOOPS_API_KEY` are server-side only. Never add them to mobile or client bundles.

### Mobile (`apps/mobile/.env`)

```env
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

> **Security:** Mobile only uses the anon key + RLS. Never put Firebase Admin SDK or service role keys here.

---

## Running the Apps

### Web

```bash
make dev          # Start dev server (http://localhost:3000)
make build        # Production build
make lint         # ESLint
make typecheck    # TypeScript check
make test         # Jest tests
make format       # Prettier formatting
```

### Mobile

```bash
cd apps/mobile

flutter run --flavor user            # Run user app (patients/doctors)
flutter run --flavor admin           # Run admin app
flutter run --flavor user --release  # Release build
```

### Build APKs

```bash
cd apps/mobile
flutter build apk --flavor user --dart-define=ENV=production
flutter build apk --flavor admin --dart-define=ENV=production
```

### Full CI (Local)

```bash
make ci    # Runs lint + typecheck + test + build for web
make lint  # Runs all linters
make test  # Runs all tests
```

---

## Project Structure

```
premoncare/
├── apps/
│   ├── web/                          # Next.js 16 (App Router + Proxy)
│   │   ├── src/
│   │   │   ├── app/                  # Pages & API routes
│   │   │   │   ├── admin/            # Admin dashboard pages
│   │   │   │   ├── doctor/           # Doctor dashboard pages
│   │   │   │   ├── patient/          # Patient dashboard pages
│   │   │   │   ├── api/              # API routes (withSecurity wrapper)
│   │   │   │   └── emergency-waiting # Emergency status page
│   │   │   ├── components/           # React components
│   │   │   │   ├── admin/            # Admin-specific components
│   │   │   │   ├── doctor/           # Doctor-specific components
│   │   │   │   ├── patient/          # Patient-specific components
│   │   │   │   ├── layout/           # Dashboard layout, nav, sidebar
│   │   │   │   ├── messaging/        # Chat components
│   │   │   │   └── ui/               # Shared UI primitives
│   │   │   ├── lib/                  # Utilities, security, queries
│   │   │   │   ├── supabase-middleware.ts  # Session management
│   │   │   │   ├── supabase-server.ts      # Server-side client
│   │   │   │   ├── security.ts             # withSecurity HOF, rate limiting
│   │   │   │   └── notification-service.ts # FCM + Loops dispatch
│   │   │   └── __tests__/            # Jest tests (27 passing)
│   │   ├── jest.config.ts
│   │   └── next.config.ts
│   │
│   └── mobile/                       # Flutter 3.47 (Flavor-based)
│       ├── lib/
│       │   ├── core/                 # Foundation layer
│       │   │   ├── app_colors.dart   # AppColors: single source of truth
│       │   │   ├── app_typography.dart # AppTypography with theme-aware variants
│       │   │   ├── router.dart       # GoRouter with role-based redirects
│       │   │   ├── providers.dart    # Global Riverpod providers
│       │   │   ├── supabase_locator.dart # Supabase client initialization
│       │   │   └── services/         # Privacy, biometric, admin services
│       │   ├── features/             # Feature modules
│       │   │   ├── auth/             # Login, register, onboarding, splash
│       │   │   ├── patient/          # Dashboard, profile, records, bookings
│       │   │   ├── doctor/           # Dashboard, appointments, earnings, schedule
│       │   │   ├── admin/            # Verification, moderation, financial, monitor
│       │   │   ├── forum/            # Social forum, post detail, ask-a-doctor
│       │   │   ├── messaging/        # Chat list, chat detail
│       │   │   ├── records/          # Medical records vault, sharing
│       │   │   ├── verification/     # Practitioner verification wizard
│       │   │   ├── settings/         # Privacy, notifications, accessibility
│       │   │   ├── appointments/     # Consultation, booking confirmed
│       │   │   └── emergency/        # Emergency request, waiting, failed
│       │   ├── shared/               # Shared widgets & providers
│       │   │   ├── widgets/          # GlassCard, AnimatedBackground, etc.
│       │   │   └── providers/        # Shared Riverpod providers
│       │   ├── l10n/                 # Localization (6 locales)
│       │   │   ├── app_en.arb        # 750+ translation keys
│       │   │   └── app_localizations.dart # Generated + manual
│       │   └── main_*.dart           # Flavor entry points
│       ├── test/                     # Flutter tests
│       └── android/                  # Android-specific config
│
├── supabase/                         # Database layer
│   ├── schema.sql                    # Single source of truth (33 tables, 2000+ lines)
│   ├── update_live.sql               # Cumulative live migrations
│   ├── mock_data.sql                 # Demo data seed
│   └── cleanup.sql                   # Reset script (33 tables, 15 enums, 22 functions)
│
├── .github/
│   ├── workflows/
│   │   ├── web-ci.yml                # Web CI: lint → typecheck → test → build
│   │   └── mobile-ci.yml             # Mobile CI: analyze → test → build
│   └── PULL_REQUEST_TEMPLATE.md
│
├── .githooks/
│   └── pre-commit                    # ESLint + TypeScript + flutter analyze
│
├── AGENTS.md                         # AI agent guidelines (comprehensive)
├── AGENTS.template.md                # Universal template for new projects
├── CHANGELOG.md                      # Version history
├── DESIGN.md                         # Design system documentation
├── UI_ARCHITECTURE.md                # UI component architecture
├── SYSTEM_WALKTHROUGH.md             # Full system walkthrough
├── admin_guide.md                    # Admin operations guide
├── Makefile                          # Task runner (dev, lint, test, build, ci)
└── package.json                      # Root workspace config (npm workspaces)
```

---

## Core Systems

### Verification Wizard

The practitioner verification system is a 4-step wizard that allows patients to become verified doctors.

**Flow:**
1. **Patient** → Profile → "Practitioner Registration" tile → `/verify-practitioner`
2. **Step 1: Professional Profile** — Title, specialty, years of experience, medical license number
3. **Step 2: Identity Documents** — Government ID upload, proof of address
4. **Step 3: Facial Biometrics** — Live selfie for identity matching
5. **Step 4: Review & Submit** — Summary of all provided information
6. On submit → `verification_status` → `pending` → wizard shows "Pending Review" screen

**Status Lifecycle:**
```
unsubmitted → pending → approved
                     ↘ under_review → approved
                     ↘ rejected → (resubmit) → unsubmitted
                     ↘ approved → (revoke by admin) → unsubmitted
```

**Admin Actions (Doctor Verification Panel):**
| Current Status | Available Actions |
|---|---|
| `pending` | Approve, Reject, Request More Info |
| `under_review` | Approve, Reject |
| `approved` | Revoke Verification |
| `rejected` | — (shows rejected message) |

**Key Files:**
- Mobile: `features/verification/verify_practitioner_screen.dart` (gateway)
- Mobile: `features/verification/verification_provider.dart` (state management)
- Mobile: `features/admin/doctor_verification_panel.dart` (admin UI)
- Mobile: `core/services/admin_service.dart` (approve/reject/reset)
- Web: `components/admin/user-management.tsx` (reset verification)

**Security Rules:**
- Once approved, the "Practitioner Registration" tile hides from the profile menu
- Approved users see a celebration screen if they navigate to `/verify-practitioner`
- Admin can revoke verification → status reverts to `unsubmitted` → doctor must re-submit from scratch
- Admin promotes `role` from `patient` to `doctor` on approval

---

### Emergency Booking

An Uber-style emergency consultation flow for urgent medical needs.

**Flow:**
1. Patient taps "Emergency" → selects reason → submits request
2. System finds available doctors with `is_emergency: true`
3. Doctor receives real-time alert (FCM push + in-app banner) with **3-minute countdown**
4. Doctor **Accepts** → status → `emergency_accepted` → patient proceeds to checkout
5. Doctor **Declines** or **times out** → status → `emergency_declined` → patient finds another doctor
6. Patient pays (5x base hourly rate) → status → `ongoing` → video consultation begins

**Guest Booking:**
- Non-registered users can book emergencies via phone number
- Guest tracked via `guest_token` in appointment `metadata`
- `patient_id` is nullable for guest bookings
- After consultation, guest is prompted to create an account

**Key Files:**
- Mobile: `features/emergency/emergency_request_screen.dart`
- Mobile: `features/emergency/emergency_waiting_screen.dart` (animated countdown)
- Web: `app/emergency/page.tsx` (doctor search)
- Web: `app/emergency-waiting/page.tsx` (SVG ring + Realtime redirect)
- API: `app/api/emergency/request/route.ts` (request creation)
- API: `app/api/emergency/accept/route.ts` (doctor acceptance)

---

### Video Consultations

Native Jitsi Meet integration for real-time video consultations.

- **SDK:** `jitsi_meet_flutter_sdk: ^13.1.0`
- **Room Naming:** `PremonCare-{appointmentId}` on server `https://8x8.vc`
- **Controls:** Mute, camera toggle, chat, screen share, end call
- **Event Callbacks:** `conferenceJoined`, `conferenceTerminated`, `audioMutedChanged`, `videoMutedChanged`, `readyToClose`
- **Navigation:** Appointment detail screen passes `doctorName`, `specialty`, `durationMinutes` to consultation route

---

### Messaging & Realtime

All real-time communication uses **Supabase Realtime** (`postgres_changes`).

**Messaging:**
- Private 1:1 conversations between patients and doctors
- Rich attachments (JSONB support)
- Read receipts
- Chat list search by name/specialty/message content

**Realtime Subscriptions:**
| Table | Purpose |
|---|---|
| `appointments` | Live status updates (pending → confirmed → ongoing → completed) |
| `messages` | Real-time chat delivery |
| `notifications` | In-app notification feed |
| `forum_replies` | Live comment updates on forum posts |
| `forum_reports` | Admin moderation alerts |

---

### Notifications

Unified push + email notification system.

- **Push (FCM):** Server-side only via Firebase Admin SDK
- **Email (Loops):** Transactional emails for key events
- **In-app:** Categorized tabs (clinical, appointment, payment, emergency)
- **Emergency alerts:** Sticky priority alerts that persist until acknowledged

**Notification Preferences (8 toggles):**
Push, Email, Appointments, Payments, Clinical, Forum, Emergency, Marketing

---

### Dark Mode & Design System

**Design Language:** Modern Glassmorphism with backdrop filters.

**Color System:**
- **Single source of truth:** `apps/mobile/lib/core/app_colors.dart` (`AppColors`)
- **Theme-aware methods:** `surfaceOf(context)`, `textPrimaryOf(context)`, `borderOf(context)`, etc. (12 methods)
- **Dark mode:** `ThemeModeNotifier` (Riverpod) + `themeModeProvider`, persists via `SharedPreferences`
- **Primary color:** Indigo (`#0F62FE`)

**Standard Border Radius:** `{8, 12, 16, 20, 24, 32}`

**Web:** CSS variables in `globals.css` → `app_colors.css`

**Components:**
- `GlassCard` — Lightweight `BoxDecoration` + gradient (no BackdropFilter for performance)
- `AnimatedBackground` — Circle orbs animation (no BackdropFilter)

---

### Localization (i18n)

Full internationalization support with 6 locales.

| Locale | Language |
|---|---|
| `en` | English (default) |
| `fr` | French |
| `yo` | Yoruba |
| `ig` | Igbo |
| `ha` | Hausa |
| `sw` | Swahili |

**Infrastructure:**
- `l10n.yaml` → `lib/l10n/app_en.arb` (750+ translation keys)
- `AppLocalizations` class (4600+ lines) with all locale implementations
- `flutter: generate: true` in `pubspec.yaml`

---

## Security

### API Security Pattern

Every API route MUST use the `withSecurity` wrapper:

```typescript
import { withSecurity } from '@/lib/security'

// CORRECT
export const POST = withSecurity(async (req, { sessionUser }) => {
  // sessionUser.id is trusted — extracted from JWT
  // sessionUser.role is trusted — extracted from profiles table
})

// WRONG — never do this
export const POST = async (req) => {
  const { userId } = await req.json() // UNTRUSTED — attacker controls this
}
```

### Security Features

| Feature | Implementation |
|---|---|
| **Rate Limiting** | Applied via `withSecurity` on all API routes |
| **Input Sanitization** | `isomorphic-dompurify` + `zod` validation |
| **XSS Prevention** | Server-side HTML sanitization |
| **CSRF Protection** | Supabase JWT tokens in headers |
| **IDOR Prevention** | RLS ensures users access only their own rows |
| **Session Management** | 15-minute inactivity auto-logout (HIPAA) |
| **Role Caching** | Middleware caches user role in `premon_role` cookie |
| **PHI Protection** | All `debugPrint` calls wrapped in `kDebugMode` guards |

### Admin Access Blocking

**Mobile (3 layers):**
1. Login screen rejects admin with signout + error
2. Splash screen signs out admin on startup
3. Router redirect catches any admin that slips through

**Web (3 layers):**
1. Middleware redirects admin from `/doctor/*` and `/patient/*` to `/admin/dashboard`
2. Login form rejects admin with signout + error
3. Login/register routes redirect admin to admin dashboard

### Secrets Management

| Secret | Location | NEVER |
|---|---|---|
| Supabase Anon Key | `apps/web/.env.local`, `apps/mobile` (public) | Never expose to server-side admin operations |
| Supabase Service Role Key | `apps/web/.env.local` ONLY | Never add to mobile, never commit to git |
| Firebase Admin SDK | `apps/web/.env.local` ONLY | Never add to mobile workspace |
| Loops API Key | `apps/web/.env.local` ONLY | Never add to mobile workspace |

---

## HIPAA & GDPR Compliance

### HIPAA

| Requirement | Status | Implementation |
|---|---|---|
| **Access Controls** | Implemented | RLS on every table; role-based `patient`/`doctor`/`admin` enforced at DB + API + UI layers |
| **Inactivity Timeout** | Implemented | 15-minute auto-logout on Web and Mobile platforms |
| **Audit Logging** | Implemented | `audit_logs` table with `log_phi_access()` RPC |
| **Encryption in Transit** | Implemented | Supabase enforces TLS on all connections |
| **Encryption at Rest** | Inherited | Supabase Storage encrypts at rest (AES-256) |
| **Minimum Necessary** | Implemented | Doctors see only their own patients via RLS |
| **BAA** | Self-Hosted | No BAA with Supabase Inc. required (self-hosted on Coolify) |
| **Breach Notification** | Documented | 60-day notification window |

### GDPR

| Right | Implementation |
|---|---|
| **Right to Access** | Users can view all their data in their dashboard |
| **Right to Rectification** | Profile editing, medical record updates |
| **Right to Erasure** | `soft_delete_user()` RPC + 30-day purge |
| **Right to Portability** | `export_user_data()` RPC → JSON download |
| **Consent** | Registration collects health data with explicit HIPAA checkbox |
| **Data Minimization** | Only collect what's needed |
| **Breach Notification** | 72-hour notification to supervisory authority |

### Self-Hosted Infrastructure Responsibilities

Since Supabase is self-hosted on Coolify:
- **You** manage disk encryption on your VPS (LUKS/dm-crypt)
- **You** manage PostgreSQL SSL (`sslmode=require`)
- **You** manage backups (encrypted, access-controlled)
- **You** manage SSH access and VPN
- **You** need a BAA from your VPS provider (Hetzner, DigitalOcean, AWS, etc.)

---

## CI/CD

### Web Pipeline (`.github/workflows/web-ci.yml`)

1. `npm run lint` — ESLint with zero warnings
2. `npm run typecheck` — TypeScript strict mode
3. `npm run test -- --coverage --ci` — Jest with coverage thresholds (30%)
4. `npm run build` — Next.js production build

### Mobile Pipeline (`.github/workflows/mobile-ci.yml`)

1. `flutter analyze` — Dart static analysis
2. `flutter test --coverage` — Widget and unit tests
3. `flutter build apk --flavor user` — Android build

### Pre-commit Hooks

```bash
# Install
make hooks
# OR
git config core.hooksPath .githooks
```

Runs ESLint + TypeScript on staged web files and `flutter analyze` on staged mobile files.

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|---|---|
| **Mobile build fails** | Run `flutter clean && flutter pub get` |
| **Web typecheck errors** | Run `npm install` in `apps/web/` |
| **Supabase 42501 errors** | Run the GRANT statements from `schema.sql` on your database |
| **RLS policy errors** | Ensure `update_live.sql` has been run in Supabase Dashboard |
| **FCM notifications not working** | Check `FIREBASE_*` env vars are set in `apps/web/.env.local` |
| **Verification wizard shows after approval** | Ensure latest code is deployed; check `verification_status` in profiles table |
| **Dark mode flash on load** | Ensure `ThemeModeNotifier` is initialized in `ProviderScope` with `initialThemeModeProvider` |

### Flutter Analyzer Hangs

If `flutter analyze` hangs on this machine, it's likely a system-level issue. The codebase has been manually reviewed for correctness.

### Database Migrations

Always run `update_live.sql` in the Supabase Dashboard SQL Editor — it uses `_safe_policy()` for idempotent policy creation and won't fail on re-run.

---

## Documentation

| File | Purpose |
|---|---|
| [README.md](README.md) | Setup, installation, architecture (this file) |
| [AGENTS.md](AGENTS.md) | AI agent guidelines, compliance, security rules |
| [AGENTS.template.md](AGENTS.template.md) | Universal template for new projects |
| [CHANGELOG.md](CHANGELOG.md) | Version history with detailed change logs |
| [DESIGN.md](DESIGN.md) | Design system documentation |
| [UI_ARCHITECTURE.md](UI_ARCHITECTURE.md) | UI component architecture |
| [SYSTEM_WALKTHROUGH.md](SYSTEM_WALKTHROUGH.md) | Full system walkthrough |
| [admin_guide.md](admin_guide.md) | Admin operations guide |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Detailed architecture documentation |

---

## License

Private — All rights reserved.
