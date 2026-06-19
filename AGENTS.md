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
- **Session Handling**: Use `apps/web/src/lib/supabase-middleware.ts` within the Next.js `proxy` function.
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
- **Token Sync**: Mobile clients only retrieve and sync their `fcm_token` to the Supabase `profiles` table. They do not trigger the push itself.

## AI Build Diagnostics
Built-in `browserLogForwarding` is enabled in `apps/web/next.config.ts`. If a web build error occurs, check the forwarded logs from the server-side build agent.

## Core Systems & Mobile Architecture
- **Messaging & Sync**: Web and Mobile clients communicate through **Supabase Realtime**. The messaging system listens to the `messages` table and supports rich attachments (JSONB). The Social Forum uses a global `StreamProvider` to broadcast posts.
- **Mobile Notifications & Alerts**: Mobile uses a dedicated `Notification Center` with sticky emergency alerts and categorized tabs for clinical, appointment, and payment events.
- **Mobile Administration**: The mobile platform supports full administrative parity, including a `DoctorVerificationPanel`, `FinancialModerationScreen`, and `DisputeResolutionCenter` for on-the-go mediation between patients and doctors.
- **Medical Records Sharing**: Privacy is default. Records uploaded to private buckets use a join table `record_permissions` to track which `doctor_id` has access to which `file_id`. Mobile uses `record_sharing_sheet.dart` to manage access.
- **Design System**: Premoncare enforces a **Modern Glassmorphism** aesthetic. Use `GlassCard` (with backdrop filters) on Mobile and `.glass-panel` utilities on Web. Primary color is Indigo (`#0F62FE`).
- **Flavor-Based App Deployment**: The mobile app uses **Flutter Flavors** to generate distinct binaries:
    - **User App (`user`)**: For Patients and Doctors (`com.premoncare.app`).
    - **Admin App (`admin`)**: For Platform Administrators (`com.premoncare.admin`).
    - Core logic is shared, but entry points (`main_user.dart` vs `main_admin.dart`) and UI flows are isolated.

## Presence, Online heartbeats, & Live Operations
- **Interactive Toggles**: Doctors manually toggle their clinical availability via dynamic sliders on their dashboards (Web & Mobile), writing `profiles.is_online = true` and updating `profiles.last_seen`.
- **Heartbeat & Sweep**: While active, background routines (`setInterval` on Web, `Timer.periodic` on Mobile) dispatch heartbeat pings every 60 seconds updating `profiles.last_seen`. A secure database routine (`sweep_offline_doctors()`) automatically sets `is_online = false` if a doctor fails to heartbeat for 2 minutes (preventing zombie listings).
- **Admin Live Operations Monitor**: Realtime operations are audited via administrative widgets subscribing to **Supabase Realtime Stream channels** to monitor active consultations (`status = 'ongoing'`) and active clinical availability.
