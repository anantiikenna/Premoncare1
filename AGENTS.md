# AI Agents Configuration — Premon Care

> **Purpose:** This file tells AI agents how to work in this codebase. Every agent MUST read this file before making changes. Update this file when the project evolves.

## Project Overview

- **Name:** Premon Care (Premoncare)
- **Description:** Telehealth platform connecting patients with verified doctors — appointments, emergency consultations, video visits, medical records, messaging, and a social forum.
- **Stack:** Next.js 16 (web) + Flutter (mobile) + Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Monorepo:** Yes — npm workspaces (`apps/*`, `packages/*`)
- **Domain:** Healthcare (HIPAA / GDPR apply — see Compliance section)

---

## Project Architecture

### Directory Structure
```
/
├── apps/
│   ├── web/          # Next.js 16 (App Router + Proxy)
│   └── mobile/       # Flutter (flavors: user, admin)
├── packages/         # Shared libraries
├── supabase/         # Database schema, migrations
│   ├── schema.sql    # Single source of truth for DB (fresh install)
│   └── update_live.sql  # Cumulative live migrations
└── AGENTS.md         # This file
```

### Tech Stack
| Layer | Technology | Notes |
|---|---|---|
| **Frontend (Web)** | Next.js 16.2.1 | App Router + `proxy.ts` (session boundary) |
| **Frontend (Mobile)** | Flutter | Flavors: `user` (patients/doctors), `admin` |
| **Backend** | Supabase (self-hosted on Coolify) | Auth, DB, Storage, Realtime |
| **Database** | PostgreSQL | RLS enabled on every table |
| **Push Notifications** | FCM | Server-side only (Firebase Admin SDK in web) |
| **Email** | Loops | Transactional (server-side only) |
| **Deployment (Web)** | Netlify | CI/CD via GitHub Actions |
| **Deployment (Mobile)** | Manual APK / Firebase-ready | Flavor-based binaries |
| **Payments** | Manual P2P receipt upload | Digital gateways (Dodo, Paystack) disabled |

### Project Architecture (summary)
- **Monorepo**: Root `package.json` utilizing npm workspaces (`apps/*`, `packages/*`).
- **Web App (`apps/web`)**: Next.js 16.2.1 (App Router + Proxy).
- **Mobile App (`apps/mobile`)**: Flutter.
- **Database/Auth**: Supabase (via `@supabase/ssr`), shared backend logic.
- **Payments**: Manual P2P receipt upload only. All digital payment gateways (Dodo, Paystack) are **disabled**.
- **Styling**: Vanilla CSS (TailwindCSS 4 fallback).

## Network Bound Proxy (Boundary) - Web App
The core Next.js project uses `apps/web/src/proxy.ts` (formerly `middleware.ts`) for session management and route protection.

## Context for Agents

### What You Must Know Before Changing Code

1. **Data flows through multiple layers.** A change to the database schema affects Supabase, the web API, and the mobile client. Always check all three.
2. **RLS is the primary security boundary.** Application code can have bugs. RLS policies cannot be bypassed by application bugs. Always verify RLS when touching data access.
3. **Realtime is event-driven.** Many features depend on Supabase Realtime subscriptions (appointments, emergency handshake, messaging, forum). Adding a new table or column for real-time sync requires adding it to the Realtime publication and setting `REPLICA IDENTITY FULL`.
4. **Secrets have strict boundaries.** Server-side keys (Firebase Admin SDK, Loops API key, service role key) MUST NEVER exist in client-side code. Mobile never holds server credentials.
5. **Admin is isolated.** Admin users are blocked from patient/doctor interfaces at 3 layers (login, splash/router on mobile; middleware, login form, route redirects on web). Never route admin users through patient/doctor flows.

### API Security Pattern
Every API route MUST use the security wrapper:
```ts
// ALWAYS
export const POST = withSecurity(async (req, { sessionUser }) => { /* role-checked, JWT-sourced id */ })

// NEVER
export const POST = async (req) => { const { userId } = await req.json() /* UNTRUSTED */ }
```

### Session Handling
- **Authentication Method:** Email + password via Supabase Auth. Sessions are managed through `@supabase/ssr` cookies on web and the Supabase client on mobile.
- Web: `apps/web/src/proxy.ts` → `apps/web/src/lib/supabase-middleware.ts` validates sessions on every request. **Performance Rule**: Middleware matcher must exclude `/api/` routes (since `withSecurity` protects them) and cache the user role in a `premon_role` cookie to prevent redundant DB queries.
- Mobile: Supabase client with anon key + RLS only.
- Session tokens live in httpOnly cookies on web (via `@supabase/ssr`) — never in `localStorage`.
- **Inactivity Timeout**: Both Web (`InactivityProvider`) and Mobile (`InactivityDetector`) implement a strict 15-minute inactivity auto-logout to comply with HIPAA. The timers are tied to active Supabase sessions and reset via user pointer/keyboard events.

### Core domain rules
- **API Endpoints**: Any core API route (`apps/web/src/app/api/...`) MUST be wrapped in the `withSecurity` higher-order function from `apps/web/src/lib/security.ts` to enforce Rate Limiting, strict CORS, and Role-Based Access checking. Never read sensitive IDs directly from the request body—extract them securely from the `sessionUser` parameter.
- **Input Validation**: Use `zod` and `isomorphic-dompurify` integrated in `security.ts` to guarantee payload sanitization against server-side XSS.
- **Data Fetching**: Prefer Server Components in the web app with `createServerClient` from `apps/web/src/lib/supabase-server.ts`.
- **Payment Verification**: Manual P2P verification is handled in the Admin/Doctor dashboards.
- **Emergency Guest Booking**: Both Web and Mobile support an "Emergency" flow with an **Uber-style doctor acceptance handshake**.
    - Price multiplier: **5x** doctor's base hourly rate.
    - Identification: Guest users tracked via `guest_token` in appointment `metadata`. `patient_id` is nullable for guest bookings.
    - Status flow: `emergency_request` → Doctor accepts → `emergency_accepted` → Patient pays → `ongoing`.
    - **Handshake**: After the patient submits an emergency request, the doctor has **3 minutes** to Accept or Decline via real-time alerts (FCM push + in-app Realtime subscription). If the doctor declines or times out, the status becomes `emergency_declined` and the patient is prompted to find another doctor.
    - **Real-Time Subscriptions**: Both platforms use Supabase Realtime (`postgres_changes`) to listen for status updates on the appointment row.
    - **Doctor-Side UI**: Mobile shows an emergency banner on the dashboard with tap-to-accept flow (`doctor_emergency_request_screen.dart`). Web shows a real-time `EmergencyRequestAlert` component with countdown rings and Accept/Decline buttons.
    - **Patient-Side UI**: Mobile uses `emergency_waiting_screen.dart` (animated countdown + status). Web uses `/emergency-waiting` page (SVG ring + Realtime redirect to checkout).
    - **Guest Retention**: After the consultation, guest users are prompted to create a permanent account to retain their consultation history.
- **Practitioner Registration**: There is NO direct "Doctor" registration. ALL users (including practitioners) MUST register as a **Patient** first.
    - Path to Professional Status: Register as Patient -> Log In -> Access "Verification Wizard" in Profile -> Submit Credentials -> Wait for Admin Approval.
    - This flow prevents platform abuse and ensures rigorous auditing.
- **Unified Account Switching**: Once approved, doctors can seamlessly switch between their **Patient Dashboard** and **Doctor Dashboard** via their Profile or the Top Navigation Bar. This allows them to seek care as a patient while managing their professional practice on the same account.

## Supabase Security & Data API Compliance
- **Explicit Grants (May 30 Update)**: Starting May 30, new Supabase projects do NOT expose tables in the "public" schema to the Data API by default. **ALL tables** created in the `public` schema MUST include explicit `GRANT` statements.
  - Example: 
    ```sql
    GRANT SELECT ON public.your_table TO anon;
    GRANT SELECT, INSERT, UPDATE, DELETE ON public.your_table TO authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON public.your_table TO service_role;
    ```
  - Without these explicit grants, the Flutter client and Next.js web app (via `supabase-js`) will fail with a `42501` permission denied error when attempting to query the tables.

## Data Architecture

### Database Schema — SQL File Management Rule

**Only two SQL files are maintained for schema management:**

```
supabase/schema.sql      → Fresh install (full schema from scratch)
supabase/update_live.sql → Existing DB  (safe incremental migration)
```

#### schema.sql
- Contains the complete database schema for a new installation
- Includes: extensions, enums, tables, indexes, RLS policies, triggers, functions
- Run once when setting up a new database
- After running, execute `supabase/mock_data.sql` for demo data

#### update_live.sql
- Safe to re-run on an existing database
- Uses `IF NOT EXISTS`, `ON CONFLICT DO NOTHING`, and exception handling (`EXCEPTION WHEN duplicate_object THEN NULL`)
- Adds new enums, columns, tables, RLS, triggers, indexes
- Migrates existing data when adding new columns

#### Mock data files
```
supabase/mock_data.sql  → Demo/seed data (run after schema.sql)
supabase/cleanup.sql    → Removes demo data (keeps schema)
```

#### What NOT to do
- Do NOT create standalone migration files (e.g., `003_add_feature.sql`)
- Do NOT create numbered migration files (e.g., `001_initial.sql`, `002_rls.sql`)
- Do NOT create temporary migration files for individual features
- Every schema change goes into **schema.sql** (fresh) AND **update_live.sql** (incremental)

#### Pattern for adding a new feature to SQL

When adding a new table/column/enum:

1. **schema.sql** — add the full definition in the correct section (enums, tables, RLS, triggers)
2. **update_live.sql** — add the incremental version with `IF NOT EXISTS`, `DO $$ BEGIN ... EXCEPTION` blocks, and data migration
3. **mock_data.sql** — add demo data if applicable
4. **cleanup.sql** — add cleanup if applicable

**In update_live.sql (incremental pattern):**
```sql
DO $$
BEGIN
  CREATE TYPE public.new_status AS ENUM ('A','B','C');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.new_table (
  id uuid primary key default gen_random_uuid(),
  ...
);

ALTER TABLE public.new_table ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  CREATE POLICY "new_table_select_auth"
    ON public.new_table FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
```

**Also required for every new table (see Supabase Security section):**
- Explicit `GRANT` statements for `anon` / `authenticated` / `service_role`
- RLS policies covering all CRUD operations

### Data Flow Pattern
```
User Action → Client UI → API/SDK → Database (RLS enforced) → Realtime (if applicable) → Other Clients
```

### Realtime Requirements
For any table that needs real-time sync:
1. Add `REPLICA IDENTITY FULL`
2. Add to the `supabase_realtime` publication
3. Add RLS policies for `SELECT` (authenticated users)
4. Add client-side subscription filtering by relevant ID

### Database change audit (summary)
Full procedure: see the **Continuous Data-Reflection Audit** (Step 1: verify the source of truth against LIVE row counts; Step 2: build the blast-radius matrix across all 10 layers).

## AI Build Diagnostics
- **Browser logs**: Built-in `browserLogForwarding` is enabled in `apps/web/next.config.ts`. If a web build error occurs, check the forwarded logs from the server-side build agent.
- **FCM Notifications**: Backend logic for push notifications resides in `apps/web/src/lib/notification-service.ts`.
- **Transactional Emails (Loops)**: The backend unifies Push and Email notifications. When a payload sets `send_email: true`, the service fetches the user's secure email from `auth.users` via Supabase Admin API and dispatches an email via `loops`. **Requires `LOOPS_API_KEY` in `apps/web/.env`**.
- **Security Boundary**: **Firebase Admin SDK keys (Private Key, etc.) and Loops API keys MUST NEVER be added to `apps/mobile` or its config files (`.env`, `dev.json`).** They are strictly server-side credentials and must only reside in `apps/web`. Mobile config is injected at compile time via `--dart-define` (`dev.json` → `--dart-define-from-file`) — never as a bundled asset.
- **Token Sync**: Mobile clients only retrieve and sync their `fcm_token` to the Supabase `profiles` table. For push notifications (admin broadcasts, emergency alerts), mobile dispatches via the web API `/api/notifications/dispatch` to leverage Firebase Admin SDK server-side. Mobile never holds Firebase credentials.

## Core Systems & Mobile Architecture
- **Messaging & Sync**: Web and Mobile clients communicate through **Supabase Realtime**. The messaging system listens to the `messages` table and supports rich attachments (JSONB). The Social Forum uses a global `StreamProvider` to broadcast posts.
- **Mobile Notifications & Alerts**: Mobile uses a dedicated `Notification Center` with sticky emergency alerts and categorized tabs for clinical, appointment, and payment events.
- **Mobile Administration**: The mobile platform supports full administrative parity, including a `DoctorVerificationPanel`, `FinancialModerationScreen`, and `DisputeResolutionCenter` for on-the-go mediation between patients and doctors.
- **Medical Records Sharing**: Privacy is default. Records uploaded to private buckets use a join table `record_permissions` to track which `doctor_id` has access to which `file_id`. Mobile uses `record_sharing_sheet.dart` to manage access.
- **Design System**: Premoncare enforces a **Modern Glassmorphism** aesthetic. Use `GlassCard` (with backdrop filters) on Mobile and `.glass-panel` utilities on Web. Primary color is Indigo (`#0F62FE`). All colors are centralized in `AppColors` (`core/app_colors.dart`) with theme-aware methods for dark mode support.
- **Flavor-Based App Deployment**: The mobile app uses **Flutter Flavors** to generate distinct binaries:
    - **User App (`user`)**: For Patients and Doctors (`com.premoncare.app`).
    - **Admin App (`admin`)**: For Platform Administrators (`com.premoncare.admin`).
    - Core logic is shared, but entry points (`main_user.dart` vs `main_admin.dart`) and UI flows are isolated.

## Video Consultation (Mobile)
- **Native SDK**: Mobile uses `jitsi_meet_flutter_sdk: ^13.1.0` for real-time video consultations (not iframe).
- **API**: `JitsiMeet().join(options, listener)` with `JitsiMeetEventListener` callbacks.
- **Room Naming**: `PremonCare-{appointmentId}` on server `https://8x8.vc` (MUST match `meeting-room.tsx` — pinned by tests on both platforms).
- **Event Callbacks**: `conferenceJoined`, `conferenceTerminated`, `audioMutedChanged`, `videoMutedChanged`, `readyToClose`.
- **Controls**: Mute, camera toggle, chat, screen share, end call.
- **Navigation**: Appointment detail screen passes `doctorName`, `specialty`, `durationMinutes` as extras to the consultation route.

## Design System — AppColors & Dark Mode
- **Single Source of Truth**: `apps/mobile/lib/core/app_colors.dart` — all colors defined as `AppColors` static constants.
- **Static Constants**: `primary`, `success`, `error`, `warning`, `info`, `pink`, `teal`, `slate800`–`slate50`, etc.
- **Theme-Aware Methods**: 12 methods (`surfaceOf`, `backgroundOf`, `textPrimaryOf`, `textSecondaryOf`, `textTertiaryOf`, `borderOf`, `borderLightOf`, `dividerOf`, `successLightOf`, `warningLightOf`, `errorLightOf`, `infoLightOf`) that switch between light/dark palettes based on `Theme.of(context).brightness`.
- **Dark Mode**: `ThemeModeNotifier` (Riverpod `Notifier<ThemeMode>`) + `themeModeProvider`, persists via `SharedPreferences`.
- **Typography**: `AppTypography` with `h1`–`h4`, `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`, `caption`, `overline` + theme-aware `Of(context)` variants.
- **Migration**: All 2,046 inline `Color(0xFF...)` values migrated to `AppColors` tokens.

## Settings & Privacy Persistence
- **Notification Preferences**: 8 toggles (push, email, appointments, payments, clinical, forum, emergency, marketing) persist to `SharedPreferences`. The `email` toggle also syncs `email_alerts_enabled` to the `profiles` table server-side.
- **Biometric & Privacy**: 5 toggles (biometric lock, profile visibility, online status, research data, crash reporting) persist to `SharedPreferences`.
- **Accessibility**: Text scale slider, high contrast, reduce animations, screen reader hints — all persist.
- **Health Preferences**: Weight/height/temperature units, date format — all persist.
- **Language & Region**: 6 languages, 6 regions, 6 currencies — all persist.
- **Login & Security**: Confirm password has independent visibility toggle (`_obscureConfirm`). Password change via Supabase `updateUser`.
- **About**: Website (`www.premoncare.com`) and email (`hello@premoncare.com`) are tappable via `url_launcher`.
- **Device Sessions**: Real platform name via `Platform.isAndroid`/`Platform.isIOS` (not hardcoded "Mobile App").

## Admin Access Blocking
- **Mobile (3 layers)**: Login screen rejects admin with signout + error; splash screen signs out admin on startup; router redirect catches any admin that slips through.
- **Web (3 layers)**: Middleware redirects admin from `/doctor/*` and `/patient/*` to `/admin/dashboard`; login form rejects admin with signout + error; login/register routes redirect admin to admin dashboard.
- **Enforcement**: Admin users cannot access patient/doctor APK or web portal under any circumstances.

## Presence, Online heartbeats, & Live Operations
- **Interactive Toggles**: Doctors manually toggle their clinical availability via dynamic sliders on their dashboards (Web & Mobile), writing `profiles.is_online = true` and updating `profiles.last_seen`.
- **Heartbeat & Sweep**: While active, background routines (`setInterval` on Web, `Timer.periodic` on Mobile) dispatch heartbeat pings every 60 seconds updating `profiles.last_seen`. A secure database routine (`sweep_offline_doctors()`) automatically sets `is_online = false` if a doctor fails to heartbeat for 2 minutes (preventing zombie listings).
- **Admin Live Operations Monitor**: Realtime operations are audited via administrative widgets subscribing to **Supabase Realtime Stream channels** to monitor active consultations (`status = 'ongoing'`) and active clinical availability.

---

## Compliance & Regulatory Posture

### HIPAA (Health Insurance Portability and Accountability Act)
Premoncare handles **Protected Health Information (PHI)**: medical records, prescriptions, symptoms, diagnoses, consultation notes, and emergency requests.

| Requirement | Current Status | Implementation |
|---|---|---|
| **Access Controls** | Implemented | RLS on every table; role-based `patient`/`doctor`/`admin` enforced at DB + API + UI layers |
| **Inactivity Timeout** | Implemented | 15-minute auto-logout on Web and Mobile platforms (HIPAA Addressable Spec) |
| **Audit Logging** | Implemented | `audit_logs` table with `log_phi_access()` RPC for medical records, prescriptions, messages. User-initiated actions (deletion, export) logged |
| **Encryption in Transit** | Implemented | Supabase enforces TLS on all connections |
| **Encryption at Rest** | Inherited | Supabase Storage encrypts at rest (AES-256). Verify via Supabase dashboard |
| **Minimum Necessary** | Implemented | Doctors see only their own patients via RLS. Admin sees all but is role-gated |
| **BAA (Business Associate Agreement)** | Self-Hosted | Supabase is self-hosted on Coolify — Supabase Inc. has no access to PHI. BAA with Supabase Inc. not required. Infrastructure BAA obligations fall on the hosting provider (see below) |
| **Breach Notification** | Implemented | See Incident Response section below. 60-day notification window documented |
| **Physical Safeguards** | Inherited | Supabase hosts on AWS/GCP with SOC 2 Type II |

**What an agent must NEVER do with PHI:**
- Never log patient names, medical records, or symptoms to console/log files
- Never store PHI in localStorage, SharedPreferences, or browser cookies
- Never transmit PHI to third-party analytics or tracking services
- Never hardcode patient IDs in URLs visible to other users
- Never bypass RLS policies by using service_role client in client-side code

### GDPR (General Data Protection Regulation)
Applies to any EU user. Premoncare must support:

| Right | Implementation Required |
|---|---|
| **Right to Access** | Users can view all their data in their dashboard |
| **Right to Rectification** | Profile editing, medical record updates |
| **Right to Erasure** | Implemented: `soft_delete_user()` RPC marks profile as deleted, anonymizes auth email. `purge_deleted_accounts()` permanently deletes after 30 days |
| **Right to Portability** | Implemented: `export_user_data()` RPC returns JSON of all user data. Web: `/api/user/export` download. Mobile: clipboard copy |
| **Consent** | Registration collects health data — explicit consent required at signup (HIPAA checkbox) |
| **Data Minimization** | Only collect what's needed. No unnecessary tracking |
| **Breach Notification** | 72-hour notification to supervisory authority |

**What an agent must do for GDPR:**
- Never add tracking cookies without consent
- Never share user data with third parties without explicit opt-in
- Never retain data longer than necessary — implement soft-delete with 30-day purge
- Always provide a way for users to see what data you hold about them

### SOC 2 (Service Organization Control)
SOC 2 applies to cloud infrastructure providers, not directly to Premoncare. However:
- **Supabase** holds SOC 2 Type II — inherit their compliance posture
- **Firebase/Google Cloud** holds SOC 2 — inherit for FCM
- Premoncare can cite these reports in its own compliance documentation
- If Premoncare grows, pursue SOC 2 Type II independently (requires 6-12 month audit period)

### WCAG (Web Content Accessibility Guidelines)
- Web app uses semantic HTML, ARIA labels, keyboard navigation
- Mobile uses `Semantics` widgets, `accessibleNavigation`, screen reader hints
- Text scale slider in settings, high contrast mode, reduce animations toggle
- Agents must not regress accessibility: always add `Semantics` labels to interactive elements, maintain color contrast ratios

---

## Security Posture & Data Protection

### Threat Model
| Threat | Mitigation |
|---|---|
| **SQL Injection** | Supabase uses parameterized queries. Never interpolate user input into raw SQL |
| **XSS (Cross-Site Scripting)** | `isomorphic-dompurify` sanitizes all API inputs. Never render raw HTML |
| **CSRF** | Supabase uses JWT tokens in headers, not cookies. SameSite cookies enabled |
| **IDOR (Insecure Direct Object Reference)** | RLS ensures users can only access their own rows. Never expose IDs in URLs without auth checks |
| **Privilege Escalation** | Admin routes blocked at 3 layers (login, splash, router). Never trust client-side role claims |
| **Session Hijacking** | Supabase refresh token rotation. Proxy validates session on every request |
| **Broken Access Control** | `withSecurity` HOF enforces role checking on all API routes |
| **Data Leakage** | Private storage buckets. Guest data isolated via `guest_token`. Medical records use `record_permissions` join table |

### Secrets Management
| Secret | Location | NEVER |
|---|---|---|
| Supabase Anon Key | `apps/web/.env.local`, `apps/mobile/dev.json` (public) | Never expose to server-side admin operations |
| Supabase Service Role Key | `apps/web/.env.local` ONLY | Never add to mobile, never commit to git, never expose in client bundles |
| Firebase Admin SDK | `apps/web/.env.local` ONLY | Never add to mobile workspace |
| Loops API Key | `apps/web/.env.local` ONLY | Never add to mobile workspace |
| Stripe/Payment Keys | N/A (disabled) | Payment gateways are disabled |

**Agent rule:** Before adding any credential, ask: "Is this a public or secret key?" Public keys go in client bundles. Secret keys stay in server-only `.env` files and are never imported in `'use client'` components.

### API Security Boundary
Every API route MUST follow this pattern:
```typescript
// CORRECT
import { withSecurity } from '@/lib/security'
export const POST = withSecurity(async (req, { sessionUser }) => {
  // sessionUser.id is trusted — extracted from JWT
  // sessionUser.role is trusted — extracted from profiles table
})

// WRONG — never do this
export const POST = async (req) => {
  const { userId } = await req.json() // UNTRUSTED — attacker controls this
}
```

### Mobile Security Boundary
- Mobile NEVER holds Firebase Admin SDK credentials
- Mobile NEVER holds server-side API keys
- Mobile dispatches push notifications via web API (`/api/notifications/dispatch`)
- Mobile syncs only `fcm_token` to Supabase profiles table
- Mobile uses `supabase-js` client with anon key + RLS only

---

## Continuous Data-Reflection Audit & UI/UX Test Procedure

**Use for:** every change that touches data (queries, schemas, statuses, APIs, derived counts, labels) — and for UI changes. Run this procedure top to bottom. Nothing ships until Step 5 is green. **The visual pass is part of the loop for every UI/UX change:** any change that alters rendered UI must also complete Step 6 (UI/UX Testing — responsive/theme/states/visual diff) before it is called done — audit UI/UX the same way you audit data.

### STEP 1 — FIND THE SOURCE OF TRUTH (before writing code)

1. Identify the entity the user's words map to (e.g. "Properties" → which table/endpoint actually holds them?).
2. Verify with **row counts against the LIVE database**, not assumptions: `select count(*)` on every candidate table. (Premoncare: live Supabase is self-hosted on Coolify — run counts via the Supabase SQL Editor.)
3. Record the result:
   - **Authoritative source:** `<table/endpoint>` (rows: N)
   - **Empty/seed/legacy sources:** `<table>` (rows: 0 — do not read)
4. If two tables could hold the same concept, the source with live rows wins. Note the choice in the commit message.

### STEP 2 — CONTINUOUS HIERARCHY AUDIT (every single change)

Before editing, build the **blast-radius map**: the changed field/data at the center, every consumer radiating outward. Grep the whole repo for each name:

```
<old-field-name>  <old-table-name>  <old-status-enum>  <old-label>
hrefs/links containing the route  ·  API routes  ·  shared lib functions
tests  ·  docs (*.md)  ·  SQL schema files
```

Audit matrix — fill this in for EVERY change (add rows until empty):

| # | Layer | Files | Reads changed data? | Updated? |
|---|-------|-------|--------------------|----------|
| 1 | Database / schema (`supabase/schema.sql` + `supabase/update_live.sql`, both!) | | | |
| 2 | API / server routes (`apps/web/src/app/api/…`) | | | |
| 3 | Shared lib / domain logic (`apps/web/src/lib/…`, `apps/mobile/lib/core/…`) | | | |
| 4 | Parent pages (lists, dashboards, counts, cards) | | | |
| 5 | Child/detail pages (by id, tabs, panels) | | | |
| 6 | Sibling pages (anything showing the same entity: badges, filters, legends, empty states) | | | |
| 7 | Navigation / quick actions / links / redirects (`proxy.ts`, mobile `router.dart`) | | | |
| 8 | Tests (unit + integration + fixtures — BOTH platforms when a contract is shared) | | | |
| 9 | Documentation (AGENTS.md, CHANGELOG.md, README) | | | |
| 10 | Audit log / history instrumentation | | | |

**Propagation rules (apply in this order):**
- **Count changed** → find EVERY card/stat/label that displays it.
- **Status/enum changed** → update EVERY status→label map, status→color map, status→badge-variant map, legend, filter option, and sort order. One new enum value = N map entries, not one. Shared enum/status strings must change on BOTH platforms AND both test dirs (see Cross-Platform Contracts above).
- **Field/table renamed** → all queries, selects, joins, embeds, exports.
- **Hierarchy (parent→child)** → parent shows child counts/names; child shows parent name/ID; both must agree. A child type split into subtypes means the parent's grouping/filter logic changes too.
- **Route/param added** → every entry point that should link into it (list → detail → deep link `?param=`), including wiring the param through each component layer until it reaches the leaf.

Rules of engagement:
- Never delete a working feature to satisfy the audit — replace its input.
- Retired features: remove **UI/code references only**; keep DB tables/columns (future may need it) unless the user explicitly orders a destructive change.
- Fix every row in the matrix, or write "N/A — reason" in it. The matrix is the review artifact; include its summary in the final report.

### STEP 3 — IMPLEMENT (focused, no drive-by refactors)

- Match existing code style, libraries, and patterns in the repo.
- Business logic lives in one shared module — never duplicated in components (pricing: `emergency-pricing.ts` ↔ `pricing.dart` pattern).
- Demo/fictional data stays clearly separated from official data.
- No comments unless the repo already comments that kind of line.

### STEP 4 — GET THE UI/UX TEST SKILL ONLINE (before writing UI tests)

> Tooling changes fast — **search the web first**, never trust training-data test tooling.

1. Web search: `<framework> <version> UI testing best practices <current year>`.
2. Read 1–2 authoritative results (official docs > vendor blogs) and note:
   - Correct locator strategy (role/text/testid first — never brittle CSS chains)
   - Correct test-runner invocation for THIS repo's versions
   - Viewports/device profiles to cover
3. If a project skill fits (available_skills), load it. Otherwise follow the freshly fetched guidance. Record the source URL in your test file header or report so the choice is auditable.

### STEP 5 — VERIFY (all three must pass; fix → re-run until green)

| Gate | Command (this repo) | Pass = |
|------|--------------------|--------|
| Lint / analyze | Web: `npm run lint` (ESLint known to hang on this machine — flag it to the user, never skip silently). Mobile: `flutter analyze` | 0 errors |
| Types / build | Web: `npx tsc --noEmit` + `npm run build`. Mobile: `flutter build apk --flavor user --debug` | exit 0 |
| Tests | Web: from `apps/web` — `$env:CI='true'; npx jest --ci --runInBand --forceExit` (see Verified Test Commands above). Mobile: `flutter test` (from `apps/mobile`) | 100% green |

- If a shell command hangs/timeouts: retry once, then redirect output to a temp file and read it (`cmd *> out.txt; echo $LASTEXITCODE`). Never run web + mobile suites in parallel.

### STEP 6 — UI/UX TESTING (live app, per the skill fetched in Step 4)

**The visual pass is now part of the loop for UI/UX changes** — Step 6 is mandatory (not optional polish) whenever rendered UI changes. A UI/UX change is incomplete until the visual pass below has been run and recorded in the audit log (see "Visual Pass" in the Audit Log Template):

- **E2E happy path** against the real app (build+start, not dev): login → navigate → select record → verify detail → perform action → verify the record appears. Assert **on user-visible text**, not internals.
- **Data-parity assertion (the critical one):** for each dashboard/list number, fetch the same count from the database/API in the test and assert equality. This is what catches "page reads empty legacy table" bugs.
- **Responsive matrix:** 320, 360, 768, 1280 px — no overflow, no clipped controls, touch targets ≥ 40 px, primary actions reachable one-handed.
- **Theme:** test light AND dark, and test the state where the host re-renders client-side (SPA bailout) — reload with stored dark preference and assert the theme survives.
- **States:** loading skeletons, empty states, error messages (user-friendly, no raw DB/stack errors).
- **Visual diff:** screenshots at fixed viewports; compare to baseline; review diffs — never bulk-approve snapshot updates.
- **AuthZ sanity:** a lower-privilege role must not see admin-only actions (hidden buttons AND server-side check). Remember the admin 3-layer block (patient/doctor portals).
- Known project-specific checks (from this repo): seeded logins `admin@premoncare.com`/`AdminPass123!`, doctors `DoctorPass123!`, patients `Patient123!`; live host (Netlify) may serve via client-side render, so hydration-sensitive behavior must be re-verified on the deployed URL, not just localhost; after deploy confirm `NEXT_PUBLIC_ANDROID_APK_URL` and run a smoke test on one page.

### STEP 7 — REPORT, COMMIT, SHIP

1. **Report** the audit matrix + test results + any N/A rows to the user.
2. **Commit** only intended files (never `.env*`, keys, untracked junk):
   `fix: <what> — reflects <source> across <pages touched>`
3. **Push**, then confirm `git status -sb` shows in-sync with `origin`.
4. Confirm the deploy pipeline picked it up (Netlify re-runs Steps 5–6 on the live URL; smoke-test one page there).
5. Update `CHANGELOG.md` and this file / the walkthrough doc if pages, routes, or roles changed.

---

## Engineering Discipline

### Mandatory Audit Phase (Every Task)
Before marking ANY task as complete, agents MUST complete this verification sequence:

**Web (Next.js):**
1. Run `npm run typecheck` (or `npx tsc --noEmit`) — zero errors required
2. Run `npm run lint` (or `npx eslint src/`) — zero warnings required (ESLint is known to hang on this machine — flag it to the user, never skip silently)
3. Run `npm run test` — all tests pass (required for **every** change: feature, bugfix, refactor or SQL — not only new features)
4. Run `npm run build` — clean build required
5. Verify no regressions in related components (check imports, shared types)

**Mobile (Flutter):**
1. Run `flutter analyze` — zero errors required (`--no-fatal-infos`; infos are tolerated, errors/warnings are not)
2. Run `flutter test` — all tests pass
3. Run `flutter build apk --flavor user --debug` — clean build
4. Verify no regressions in related widgets/screens

**Database (Supabase):**
1. If schema changed: verify `GRANT` statements exist for new tables
2. If new table: verify RLS policies cover all CRUD operations
3. If Realtime needed: verify `REPLICA IDENTITY FULL` and publication membership
4. Run affected queries in Supabase SQL Editor to verify RLS enforcement
5. **Schema changes are only done when applied to a real database** — file edits alone do not migrate the DB. Apply `update_live.sql` (or `schema.sql` for fresh installs), then smoke-test the affected write/read path (e.g. insert + read back) so enum/column mismatches are caught immediately

**Cross-cutting checks:**
- [ ] No hardcoded URLs — use environment variables
- [ ] No secrets in client-side code
- [ ] No PHI/PII in console/logs
- [ ] All new API routes wrapped in `withSecurity`
- [ ] All new database tables have RLS + GRANTs
- [ ] CSS uses CSS variables (not hardcoded colors) for dark mode support
- [ ] Stream subscriptions stored and cancelled in `dispose()`/cleanup
- [ ] Error handling: no empty catch blocks — log or surface errors

**Agent rule:** Never claim a task is "done" without running the audit phase. If the analyzer/linter/build tool hangs, flag the issue to the user rather than skipping verification.

### Code Review Policy
- All changes require review before merge to `main`
- Security-sensitive changes (auth, payments, RLS, API routes) require 2 reviewers
- Agent-generated code follows the same review process as human code

### Testing Strategy
| Layer | Tool | Command | What to Test |
|---|---|---|---|
| **Unit** | Dart `test`, Jest | `flutter test`, `npx jest --ci` | Business logic, data transforms, utility functions |
| **Widget/Component** | Flutter widget tests, React Testing Library | `flutter test`, `npx jest --ci` | UI rendering, user interactions |
| **Integration** | Flutter integration tests, Playwright/Cypress | `flutter test integration_test/` | End-to-end flows (booking, payment, messaging) |
| **API** | Supabase SQL Editor, curl/Postman | Manual | RLS policies, RPC functions, edge functions |
| **Security** | Manual review | Manual | RLS bypass attempts, role escalation, IDOR |

**Test locations:**
- Web: `apps/web/src/__tests__/` — Jest + React Testing Library
- Mobile: `apps/mobile/test/` — Flutter widget tests

#### Testing Is Mandatory (learned the hard way — do not skip)
- **Every bug fix MUST include a regression test** whenever the defect is at logic level (e.g., join-gate payment checks, status transitions, post-call routing). The video-consultation audit (F1–F6) exists because these paths were untested.
- **Every new feature ships with tests**: minimum one unit/widget test covering the happy path plus the failure/permission path. Web components get RTL tests; mobile screens get widget tests.
- **Security-sensitive changes** (auth, roles, payments, middleware, RLS-adjacent queries) require tests at BOTH layers: automated test + manual verification of the DB policy.
- **Never delete, skip, or `it.skip` an existing test to get green.** Fix the code or fix the test — deleting coverage is a regression.
- Run the **affected** suites before committing: touch `apps/web` → jest; touch `apps/mobile` → flutter test; touch both → both (sequentially, see quirks below).
- Coverage gates are real: `npm run test -- --coverage --ci` enforces the ratcheted floor (currently 6% statements/branches/lines, 4% functions — RAISE the numbers when you add substantial tests, never lower them). Untested new code pulls the ratio down — add tests in the same PR.

**Agent rule (feature completeness):** A feature is not done when its UI exists — it is done when tests prove the feature works AND its results actually surface everywhere users can see them. Every new feature must ship with end-to-end coverage of:
1. **The core action** (create/book/upload/approve/delete) completing successfully.
2. **Every reflection of that action** — counts, list rows, badges, labels, stat cards, empty states, exports, links/navigation and deep-link params that display or depend on the new data.
3. **Data parity** — the test fetches the count/record from the API inside the test and asserts the UI shows the same value. Never hard-code record counts in tests (they break the moment real data changes).

```text
New feature
   ↓
Its core action has an E2E test (happy path)
   ↓
Every place the result is reflected (list/count/label/link) has an assertion
   ↓
Parity: UI value === API value (fetched inside the test)
   ↓
Test cleans up any records it created (never pollute shared/demo data)
```

For this product the E2E suite must additionally guard the domain-critical pipelines end-to-end: **emergency booking** (request → doctor accept/decline → price gate → checkout redirect), **video consultation** (room name `PremonCare-{appointmentId}` joins on both platforms), and **realtime messaging/forum** (subscription fires, message renders for the other party). Add equivalent pipeline guards for any new real-time or payment flow.

### Mandatory Walk-Through (Every User-Facing Change)
After completing any change that affects the user experience, agents MUST perform an end-to-end walk-through of the affected flow (this is the E2E gate — the repo has no automated `test:e2e` script).

**Before walk-through:**
- [ ] Dev server is running (`npm run dev` for web, `flutter run --flavor user --dart-define-from-file=dev.json` for mobile)
- [ ] You are logged in as the relevant role (patient, doctor, admin — seeded: `admin@premoncare.com`/`AdminPass123!`, doctors `DoctorPass123!`, patients `Patient123!`)
- [ ] Database has test data covering the changed feature

**Walk-through checklist:**
1. **Entry point** — How does the user reach this feature? (URL, button, notification, deep link)
2. **Happy path** — Complete the primary action from start to finish without errors
3. **Loading states** — Verify spinners/skeletons appear while data loads
4. **Empty states** — Verify the UI handles no-data gracefully (not a blank screen or crash)
5. **Error states** — Trigger a failure (invalid input, network error) and verify friendly error messages
6. **Role-based access** — Verify the feature works for each authorized role and blocks unauthorized roles
7. **Mobile responsiveness** — If web, verify at 320/360/768/1280px, touch targets ≥ 40px
8. **Dark mode** — If CSS variables/`AppColors` were changed, verify both light and dark themes render correctly
9. **Real-time** — If applicable, open two browser tabs/devices and verify changes sync live
10. **Navigation** — Verify back buttons, breadcrumbs, and redirects work correctly
11. **Session** — Verify the feature handles expired sessions gracefully (redirect to login, not a crash)

**Document the walk-through:**
```markdown
### Walk-Through: [Feature Name]
- **Entry Point:** [How I reached the feature]
- **Happy Path:** [Pass/Fail — notes]
- **Empty State:** [Pass/Fail/N/A]
- **Error State:** [Pass/Fail — notes]
- **Role Access:** [Which roles tested]
- **Dark Mode:** [Pass/Fail/N/A]
- **Real-Time:** [Pass/Fail/N/A]
- **Issues Found:** [List any bugs discovered during walk-through]
```

**Agent rule:** If the walk-through reveals a bug, fix it before marking the task complete. Document any known limitations or follow-up items.

#### Verified Test Commands & Environment Quirks (this machine/repo)
- **Web:** from `apps/web`: `$env:CI='true'; npx jest --ci --runInBand --forceExit --silent` — plain `npm run test` can hang (watch mode/stderr pipe). Redirect output to a temp file on slow machines.
- **Never run web + mobile suites in parallel** — CPU contention causes multi-minute timeouts. Run sequentially with generous timeouts (jest ~2–10 min cold, flutter test ~1.5–3 min).
- **Type gate:** `npx tsc --noEmit` from `apps/web`. ESLint is known to hang — flag it to the user instead of skipping verification silently.
- **Flutter:** `flutter test` must run with workdir `apps/mobile` (repo root has no `test/`). `dart analyze lib` cold runs can exceed 5 minutes — use large timeouts and write output to a file, then read it.
- PowerShell may report jest stderr as "NativeCommandError" noise — check the output file and `Tests:` summary line, not the stream label.

#### Test Harness Rules (discovered by debugging — violating these breaks tests)
- **React dedupe is load-bearing:** `apps/web/jest.config.js` `moduleNameMapper` pins `react`, `react/(.*)`, `react-dom`, `react-dom/(.*)` to `apps/web/node_modules` because `@testing-library/react` hoists to the workspace root with a different React copy (→ "Objects are not valid as a React child" in ANY rendering test). **Never remove those mappings.**
- **Jest module-hoisting:** variables referenced inside `jest.mock(...)` factories MUST be prefixed `mock` (e.g., `mockSupabase`), or jest throws at runtime.
- **Supabase mocks:** chain shape is `from() → select()/update() → eq()/maybeSingle()` — mock every link the code touches.
- **Flutter widget-test harness order (load-bearing):** in `setUpAll`: `SharedPreferences.setMockInitialValues({})` **before** `Supabase.initialize(url: ..., anonKey: 'test-anon-key')`; wrap `ProviderScope(overrides: [initialThemeModeProvider.overrideWith(...)])` around pumped widgets so system theme can't flip assertions.
- **Jitsi web mock:** set `(window as any).JitsiMeetExternalAPI = MockClass` in `beforeEach`, `delete` it in `afterEach`; also stub `HTMLMediaElement.prototype.play/pause` (jsdom lacks them).
- **Supabase builder fakes (mobile):** fakes of the postgrest chain must match the *declared* return types (`SupabaseQueryBuilder.select` → `PostgrestFilterBuilder<PostgrestList>`, not a transform builder — a mismatch fails only at runtime via noSuchMethod forwarder type-checks, and `Notifier.build`'s async fetches SWALLOW it). Never cast `then` callbacks to `FutureOr Function(dynamic)` (contravariance makes it throw); call them via dynamic dispatch. One class cannot implement two instantiations of `RawPostgrestBuilder` (`Future<List>` vs `Future<Map>` conflict) — split into filter/transform/map fakes over a shared recorder. See `verification_provider_test.dart`.
- **Riverpod 3 + instant fakes:** `container.read()` yields to microtasks before the element's state is set, so an unawaited fetch started in `Notifier.build` that resolves on a microtask can read `state` BEFORE init (throws "uninitialized provider", often swallowed by the provider's own catch). Builder fakes must resolve on the EVENT queue (`Future.delayed(Duration.zero, ...)`) — microtask resolution (`Future.value`) lands inside the init window; a real network never does.
- **Typed `then` beats noSuchMethod for postgrest fakes:** a `then` answered through `noSuchMethod` always returns runtime `Future<dynamic>`, which fails strict subtype checks inside `Future.wait` (`Future<dynamic>` is not `Future<Null>`/`Future<List<…>>`). Implement `then` as a real override returning a genuinely-typed future (`Future<PostgrestList>.delayed(...).then(onValue)`) on every fake the production code awaits, and keep `noSuchMethod` only for the unawaited chain members (`eq`/`insert`/`single`/…). Also: `Future.wait` over autoDispose stream hydration + instant fakes requires an active `container.listen` subscription while awaiting `provider.future`, or the element disposes during loading ("provider was disposed during loading state").

#### Cross-Platform Contracts Pinned by Tests
- **Jitsi room name:** `PremonCare-{appointmentId}` on `https://8x8.vc` — enforced by BOTH `apps/mobile/test/meeting_room_test.dart` and `apps/web/src/__tests__/components/meeting-room.test.tsx`. Renaming rooms or changing servers requires editing the mobile builder, the web component, and both tests in the same commit.
- **Emergency price:** `rate = consultation_fee || hourly_rate || 50`; `amount = round(rate × 5 × duration ÷ 60)` (5× base hourly rate — NEVER the old `fee × 5 / 15` block formula, which charged 4× the spec). Implementations: `apps/web/src/lib/emergency-pricing.ts` ↔ `apps/mobile/lib/core/pricing.dart`, pinned by `emergency-pricing.test.ts` and `pricing_test.dart` with identical fixtures. Changing the formula requires editing both libs and both tests in the same commit.
- Same idea for any shared enum/status string: search both platforms AND both test dirs before changing.

#### Test Priority Backlog (highest value first)
1. Middleware/session guards: `proxy.ts`, `supabase-middleware.ts`, `role-redirect.ts` (admin blocking, role cookie caching, matcher excludes `/api/`) — **done**
2. `withSecurity` route-handler tests: 403 role mismatch, 429 rate limit, XSS sanitization, JWT-sourced identity — **done** (`with-security.test.ts`: CORS/preflight, 60/min rate limit + rightmost-XFF keying + webhook bypass, 401 no-session/Bearer-fallback, 403 role mismatch + missing profile, JWT-sourced identity vs attacker body, 500 without stack leak; `security.test.ts`: `sanitizeInput`/`sanitizeObject` XSS suite)
3. Mobile `router.dart` redirect rules (admin 3-layer block) via widget test — **on hold (per maintainer)**
4. HIPAA inactivity timers: `InactivityDetector` (mobile) + `InactivityProvider` (web) with `fake_async` — **done**
5. Emergency flow math/state: 5× price formula, 3-min accept timeout → `emergency_declined`, payment gate (**done**) — `emergency-waiting.test.tsx` + `emergency_appointment_model_test.dart`
6. `audit.ts` log shape (no PHI, `user_id` field) — **done**; GDPR export/delete RPC wrappers — **done** (`user-gdpr-routes.test.ts`: JWT-sourced identity, IDOR guard, 429/403 passthroughs, no DB-detail leaks)
7. Providers: `appointment_provider` status mapping, `verification_provider` wizard payload — **done** (`verification_provider_test.dart`: wizard step machine, consultation-mode toggle, submit payload contract with JWT-sourced id, storage bucket routing, status hydration); `forum`/`messaging`/`records` (record_permissions scoping) — **done** (`records_forum_messaging_test.dart`: MedicalRecord/ForumPost/Message `fromJson` contracts, patient vs doctor records scoping, forum visibility (approved OR own-pending), chat two-party filter, conversationsProvider inbox grouping, service write contracts for upload/toggleAuthorization/createPost/toggleSavePost/upvotePost RPC/sendMessage/markAsRead; JWT-sourced ids, no PHI in logs, guest no-ops)

**Agent rule:** When adding a new feature, always check for existing test patterns in the codebase. Match the existing test framework and conventions. Never remove existing tests. When you discover a new test-runner quirk, document it in this section.

### CI/CD Gates
GitHub Actions runs on every push to `main`/`develop` and on every PR to `main`. The `pull_request` triggers intentionally carry **no path filters** so every required check reports on every PR (path-filtered runs would leave required checks pending and block merges):

**Web (`.github/workflows/web-ci.yml`):**
1. `npm run lint` — ESLint with zero warnings
2. `npm run typecheck` — TypeScript strict mode
3. `npm run test -- --coverage --ci` — Jest with ratcheted coverage thresholds (6% statements/branches/lines, 4% functions)
4. `npm run build` — Next.js production build

**Mobile (`.github/workflows/mobile-ci.yml`):**
1. `flutter analyze` — Dart static analysis
2. `flutter test --coverage` — Widget and unit tests
3. `flutter build apk --flavor user` — Android build

**Pre-commit (`.githooks/pre-commit`):**
- Runs ESLint + TypeScript on staged web files
- Runs `flutter analyze` on staged mobile files
- Install: `make hooks` or `git config core.hooksPath .githooks`

**Local CI:**
- `make ci` — runs lint + typecheck + test + build for web
- `make lint` — runs all linters
- `make test` — runs all tests

**E2E gate:** There is no automated `test:e2e` script — the **Mandatory Walk-Through** (below) is the E2E gate. CI runs the unit/widget/integration suites on every push/PR; the walk-through covers the feature core actions + visible reflections + UI↔API data parity and must pass before a user-facing change is called done.

**Branch Verification Workflow (CI/CD-gated merges):**
`main` is protected — the ONLY path for changes to land is a pull request whose CI run is fully green. Red checks = the work stays on its branch; it never reaches `main`.

1. Branch off `main` with a namespaced name: `feature/…`, `fix/…`, `test/…` (e.g. `test/verification-suite`).
   - **Why `/`, not `_`:** `/` is git's namespace separator — the ecosystem convention (git-flow, GitHub, GitLab). It groups branches by type in `git branch`, PR lists, and CI. Branch names are not files, so file naming rules (snake_case) do not apply. `test_verification-suite` works but is off-convention.
2. Push the branch → open a PR into `main`.
3. CI runs ALL jobs on EVERY PR (no path filters): Web CI — `Lint`, `Type Check`, `Test` (Jest incl. security suites + ratcheted coverage gates), `Build`; Mobile CI — `Analyze`, `Mobile Test`, `Build Android`.
4. All checks green → merge the PR. Any check red → fix on the same branch and push; CI re-runs. **Never merge red.**
5. Branch protection (GitHub → Settings → Branches → rule for `main`): require a PR before merging, require status checks `Lint`, `Type Check`, `Test`, `Build`, `Analyze`, `Mobile Test`, `Build Android`, disallow bypass, no force-pushes.

### Error Handling Convention
```
User-facing errors: Show friendly message via toast/snackbar
Internal errors: Log to console/error service with context
Security errors: Return generic "Unauthorized" — never reveal why
Database errors: Never expose raw Supabase error messages to client
```

**Agent rule:** Every `catch` block must handle the error appropriately. Never swallow errors silently. Never expose stack traces to users.

### Dependency Management
- Pin major versions in `package.json` / `pubspec.yaml`
- Run `npm audit` / `dart pub outdated` monthly
- Never add a new dependency without checking if the functionality already exists
- Prefer built-in SDK methods over third-party packages
- Document why each major dependency is used in `AGENTS.md`

### Monitoring & Alerting
- Web build errors: Check `browserLogForwarding` in `next.config.ts`
- Supabase errors: Check Supabase Dashboard → Logs
- FCM delivery: Check Firebase Console → Cloud Messaging
- Mobile crashes: Check Firebase Crashlytics (if enabled)

### Incident Response
1. **Detect** — Monitor error rates, user reports, audit log anomalies
2. **Contain** — Revoke compromised credentials, disable affected features, isolate affected systems
3. **Eradicate** — Fix the root cause, deploy patch, rotate all potentially exposed secrets
4. **Recover** — Restore service, verify functionality, confirm RLS policies intact
5. **Document** — Update `CHANGELOG.md`, notify affected users if PHI was exposed
6. **Improve** — Add monitoring/test to prevent recurrence

**HIPAA Breach Notification (60-day window):**
- If PHI is exposed, notify affected individuals within **60 days** of discovery
- Notify HHS (Department of Health and Human Services) if >500 individuals affected
- Notify media if >500 individuals in a single state/jurisdiction
- Document the breach: what data, how many users, root cause, remediation
- Maintain breach log for 6 years (HIPAA requirement)

**GDPR Breach Notification (72-hour window):**
- Notify supervisory authority within **72 hours** of becoming aware of a breach
- If high risk to individuals, notify affected users without undue delay
- Document: nature of breach, categories/number of individuals, likely consequences, measures taken

**Agent rule:** If you discover a potential data exposure during code review or development, IMMEDIATELY flag it as a security incident. Do not attempt to fix it silently.

### Error & Incident Protocol

**When you find a bug:**
1. **Check if it's a security issue** (auth bypass, data leak, privilege escalation, IDOR)
2. **Check if it affects data integrity** (wrong writes, missing validation, status transitions)
3. **Check if it affects real-time sync** (stale data, missing events, missing publication membership)
4. **Fix the root cause**, not the symptom
5. **Add a regression test** (logic-level defects — see Testing Is Mandatory)
6. **Update `CHANGELOG.md`** with the fix
7. **Verify the fix** with tests or manual walk-through

**When you're unsure:**
1. Read the existing code patterns in similar files
2. Check `CHANGELOG.md` for context on past decisions
3. Search for related issues in git history
4. Ask the user for clarification — don't guess on security-critical decisions

### Compliance Certification Path
1. **Document** — This file IS your documentation baseline
2. **Implement** — Technical controls (RLS, encryption, audit logs, inactivity timeout)
3. **Verify** — Test controls, run security reviews (see Mandatory Audit Phase)
4. **Certify** — Engage auditor for HIPAA / SOC 2 / ISO 27001 when the business needs it
5. **Maintain** — Update this file when controls change

### Data Retention & Deletion
| Data Type | Retention | Deletion Method |
|---|---|---|
| User profiles | Until account deletion | Cascade delete via `auth.users on delete cascade` |
| Medical records | Until account deletion | Soft-delete with 30-day purge |
| Messages | Until account deletion | Soft-delete with 30-day purge |
| Forum posts | Permanent (unless deleted by user/admin) | Hard delete with author confirmation |
| Audit logs | 7 years (regulatory requirement) | Never delete |
| Device sessions | 90 days | Auto-cleanup cron |
| Login attempts | 1 hour | Auto-cleanup function `cleanup_old_login_attempts()` |
| Notifications | 30 days | Auto-cleanup cron |

### Naming Conventions
- **Files**: `snake_case` (Dart/Flutter), `kebab-case` (Next.js routes), `camelCase` (TS/JS modules)
- **Database tables**: `snake_case`, plural (`profiles`, `forum_posts`, `medical_records`)
- **Database columns**: `snake_case` (`created_at`, `patient_id`, `is_emergency`)
- **Enums**: `snake_case` values (`emergency_request`, `action_taken`)
- **React components**: `PascalCase` (`PostCard`, `BookingForm`)
- **Dart widgets**: `PascalCase` (`ChatListScreen`, `EmergencyWaitingScreen`)
- **Functions**: `camelCase` in JS/TS, `camelCase` in Dart (methods), `snake_case` for DB functions
- **Constants**: `UPPER_SNAKE_CASE` for global constants, `camelCase` for local constants

### Git Conventions
- Commit messages: `type(scope): description` (e.g., `fix(mobile): avatar upload RLS path`)
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`
- Never commit `.env` files, secrets, or API keys
- Branch naming: `feature/short-description`, `fix/short-description`, `test/short-description` (e.g., `test/verification-suite`) — `/` is a namespace separator (git convention), not snake_case; branch names are not files
- Always run lint/typecheck before committing

---

## Agent Workflow Checklist

When starting ANY task in this codebase:

- [ ] Read this `AGENTS.md` file
- [ ] Read `CHANGELOG.md` for recent context
- [ ] Identify affected files across all layers (DB → API → UI)
- [ ] Check existing patterns in similar files
- [ ] Verify RLS policies if touching data access
- [ ] Check secrets boundary (server vs client)
- [ ] Run lint/typecheck before committing
- [ ] **Run the test suite — for every change, not only new features**
- [ ] Update `CHANGELOG.md` if the change is user-facing
- [ ] Never commit secrets or PHI
- [ ] **Run the Continuous Data-Reflection Audit** (source of truth + 10-layer blast matrix)
- [ ] **Audit UI/UX** — the visual pass is part of the loop: run Step 6 (responsive/theme/states/visual diff) for every UI/UX change
- [ ] **Run the mandatory walk-through** for user-facing changes
- [ ] **Verify zero type/lint errors before committing**
- [ ] **Commit with descriptive message** following `type(scope): description` convention

---

## Audit Log Template

After completing a task, document what was verified:

```markdown
### Audit: [Task Name]
- **Typecheck:** [pass/fail — errors if any]
- **Lint:** [pass/fail — warnings if any]
- **Build:** [pass/fail]
- **Tests:** [pass/fail — count]
- **RLS/Security:** [checked/not applicable]
- **Dark Mode:** [CSS variables verified/not applicable]
- **Stream Cleanup:** [subscriptions cancelled/not applicable]
- **Error Handling:** [no empty catch blocks verified]
- **Visual Pass (UI/UX changes):** [pass/fail/N/A — responsive 320/360/768/1280, light+dark theme, loading/empty/error states, visual diff reviewed]
- **Walk-Through:** [pass/fail — issues found or "no issues"]
```

---

*Last Updated: 2026-10-16*
*Template version: 1.0.0*
