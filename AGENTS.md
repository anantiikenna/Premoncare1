# AI Agents Configuration (Premon Care)

This project is structured as a **Monorepo (npm workspaces)** with frontend clients separated into web and mobile workspaces.

## Project Architecture
- **Monorepo**: Root `package.json` utilizing npm workspaces (`apps/*`, `packages/*`).
- **Web App (`apps/web`)**: Next.js 16.2.1 (App Router + Proxy).
- **Mobile App (`apps/mobile`)**: Flutter.
- **Database/Auth**: Supabase (via `@supabase/ssr`), shared backend logic.
- **Payments**: Manual P2P receipt upload only. All digital payment gateways (Dodo, Paystack) are **disabled**.
- **Styling**: Vanilla CSS (TailwindCSS 4 fallback).

## Network Bound Proxy (Boundary) - Web App
The core Next.js project uses `apps/web/src/proxy.ts` (formerly `middleware.ts`) for session management and route protection.

## Context for Agents
- **Session Handling**: Next.js uses `apps/web/src/proxy.ts` -> `apps/web/src/lib/supabase-middleware.ts`. **Performance Rule**: Middleware matcher must exclude `/api/` routes (since `withSecurity` protects them). Middleware caches the user role in a `premon_role` cookie to eliminate redundant database queries on page loads. Agents must preserve this caching architecture.
- **Inactivity Timeout**: Both Web (`InactivityProvider`) and Mobile (`InactivityDetector`) implement a strict 15-minute inactivity auto-logout to comply with HIPAA. The timers are tied to active Supabase sessions and reset via user pointer/keyboard events.
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

## AI Build Diagnostics
- **FCM Notifications**: Backend logic for push notifications resides in `apps/web/src/lib/notification-service.ts`.
- **Transactional Emails (Loops)**: The backend unifies Push and Email notifications. When a payload sets `send_email: true`, the service fetches the user's secure email from `auth.users` via Supabase Admin API and dispatches an email via `loops`. **Requires `LOOPS_API_KEY` in `apps/web/.env`**.
- **Security Boundary**: **Firebase Admin SDK keys (Private Key, etc.) and Loops API keys MUST NEVER be added to `apps/mobile` or `.env` files in that workspace.** They are strictly server-side credentials and must only reside in `apps/web`.
- **Token Sync**: Mobile clients only retrieve and sync their `fcm_token` to the Supabase `profiles` table. For push notifications (admin broadcasts, emergency alerts), mobile dispatches via the web API `/api/notifications/dispatch` to leverage Firebase Admin SDK server-side. Mobile never holds Firebase credentials.

## AI Build Diagnostics
Built-in `browserLogForwarding` is enabled in `apps/web/next.config.ts`. If a web build error occurs, check the forwarded logs from the server-side build agent.

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
| Supabase Anon Key | `apps/web/.env.local`, `apps/mobile` (public) | Never expose to server-side admin operations |
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

## Engineering Discipline

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
- Coverage gates are real: `npm run test -- --coverage --ci` enforces 30% branches/functions/lines in CI. Untested new code pulls the ratio down — add tests in the same PR.

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

#### Cross-Platform Contracts Pinned by Tests
- **Jitsi room name:** `PremonCare-{appointmentId}` on `https://8x8.vc` — enforced by BOTH `apps/mobile/test/meeting_room_test.dart` and `apps/web/src/__tests__/components/meeting-room.test.tsx`. Renaming rooms or changing servers requires editing the mobile builder, the web component, and both tests in the same commit.
- **Emergency price:** `rate = consultation_fee || hourly_rate || 50`; `amount = round(rate × 5 × duration ÷ 60)` (5× base hourly rate — NEVER the old `fee × 5 / 15` block formula, which charged 4× the spec). Implementations: `apps/web/src/lib/emergency-pricing.ts` ↔ `apps/mobile/lib/core/pricing.dart`, pinned by `emergency-pricing.test.ts` and `pricing_test.dart` with identical fixtures. Changing the formula requires editing both libs and both tests in the same commit.
- Same idea for any shared enum/status string: search both platforms AND both test dirs before changing.

#### Test Priority Backlog (highest value first)
1. Middleware/session guards: `proxy.ts`, `supabase-middleware.ts`, `role-redirect.ts` (admin blocking, role cookie caching, matcher excludes `/api/`) — **done**
2. `withSecurity` route-handler tests: 403 role mismatch, 429 rate limit, XSS sanitization, JWT-sourced identity
3. Mobile `router.dart` redirect rules (admin 3-layer block) via widget test
4. HIPAA inactivity timers: `InactivityDetector` (mobile) + `InactivityProvider` (web) with `fake_async` — **done**
5. Emergency flow math/state: 5× price formula (**done**), 3-min accept timeout → `emergency_declined`, payment gate
6. `audit.ts` log shape (no PHI, `user_id` field) — **done**; GDPR export/delete RPC wrappers
7. Providers: `appointment_provider` status mapping, `verification_provider` wizard payload, `forum`/`messaging`/`records` (record_permissions scoping)

**Agent rule:** When adding a new feature, always check for existing test patterns in the codebase. Match the existing test framework and conventions. Never remove existing tests. When you discover a new test-runner quirk, document it in this section.

### CI/CD Gates
GitHub Actions runs on every push to `main`/`develop` and all PRs:

**Web (`.github/workflows/web-ci.yml`):**
1. `npm run lint` — ESLint with zero warnings
2. `npm run typecheck` — TypeScript strict mode
3. `npm run test -- --coverage --ci` — Jest with coverage thresholds (30% branches/functions/lines)
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
- Branch naming: `feature/short-description`, `fix/short-description`
- Always run lint/typecheck before committing
