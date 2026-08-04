# Premon Care — Premium Healthcare Platform

A comprehensive healthcare management system built with **Next.js 16** (Web), **Flutter** (Mobile), and **Supabase** (self-hosted on Coolify). Features P2P financial model, biometric identity verification, real-time clinical messaging, smart appointment scheduling, and encrypted video consultations.

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| **Node.js** | 20+ | Web app runtime |
| **npm** | 10+ | Web dependency management |
| **Flutter** | 3.29+ | Mobile app |
| **Dart** | 3.7+ | Mobile SDK |
| **Java** | 17+ | Android builds |
| **Supabase** | Self-hosted (Coolify) | Auth, Database, Storage, Realtime |
| **Firebase** | Free tier | FCM push notifications |

### Self-Hosted Supabase (Coolify)

This project uses a self-hosted Supabase instance on Coolify. You need:

- A running Supabase instance (URL + Anon Key + Service Role Key)
- PostgreSQL access for schema migrations
- Storage buckets configured (see below)

If you don't have Supabase self-hosted yet, follow the [Coolify Supabase guide](https://coolify.io/docs/knowledge-base/supabase).

---

## Installation

### 1. Clone & Install

```bash
git clone https://github.com/your-org/premoncare.git
cd premoncare

# Install all dependencies
make install
# OR manually:
cd apps/web && npm install && cd ../..
cd apps/mobile && flutter pub get && cd ../..
```

### 2. Environment Variables

#### Web (`apps/web/.env.local`)

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

#### Mobile (`apps/mobile/.env`)

```env
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

> **Security:** Mobile only uses the anon key + RLS. Never put Firebase Admin SDK or service role keys here.

### 3. Database Setup

#### Fresh Install
1. Go to your Supabase SQL Editor
2. Run `supabase/schema.sql` — creates all tables, RLS policies, functions, triggers
3. Run `supabase/mock_data.sql` — optional, seeds demo data

#### Existing Instance
1. Run `supabase/update_live.sql` — cumulative migrations, safe to re-run

### 4. Storage Buckets

Create these in Supabase Dashboard → Storage:

| Bucket | Visibility | Purpose |
|---|---|---|
| `avatars` | Public | User profile pictures |
| `doctor-verifications` | Private | Medical licenses, credentials |
| `doctor-identities` | Private | Government IDs, biometric selfies |
| `payment-receipts` | Private | P2P payment proofs |
| `health-records` | Private | Clinical record attachments |
| `patient-verifications` | Private | Patient identity verification |

### 5. Realtime Publications

Ensure these tables are in the Supabase Realtime publication:
- `appointments`, `messages`, `notifications`, `profiles`, `payments`, `forum_posts`, `forum_replies`, `forum_reports`

Run in SQL Editor:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_reports;
```

### 6. pg_cron Schedules

Enable `pg_cron` extension, then schedule:
```sql
SELECT cron.schedule('cleanup-login-attempts', '5 * * * *', 'SELECT cleanup_old_login_attempts()');
SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notifications()');
SELECT cron.schedule('cleanup-device-sessions', '0 3 * * *', 'SELECT cleanup_old_device_sessions()');
SELECT cron.schedule('purge-deleted-accounts', '0 4 * * *', 'SELECT purge_deleted_accounts()');
SELECT cron.schedule('sweep-offline-doctors', '* * * * *', 'SELECT sweep_offline_doctors()');
```

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

flutter run --flavor user          # Run user app (patients/doctors)
flutter run --flavor admin         # Run admin app
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
│   ├── web/                    # Next.js 16 (App Router)
│   │   ├── src/
│   │   │   ├── app/            # Pages & API routes
│   │   │   ├── components/     # React components
│   │   │   ├── lib/            # Utilities, security, queries
│   │   │   └── __tests__/      # Jest tests
│   │   ├── jest.config.ts      # Jest configuration
│   │   └── .prettierrc         # Prettier config
│   └── mobile/                 # Flutter
│       ├── lib/
│       │   ├── core/           # Theme, router, supabase, colors
│       │   ├── features/       # Feature modules (auth, forum, etc.)
│       │   └── main_*.dart     # Flavor entry points
│       ├── test/               # Flutter tests
│       └── analysis_options.yaml
├── supabase/
│   ├── schema.sql              # Single source of truth (DB)
│   ├── update_live.sql         # Cumulative live migrations
│   └── mock_data.sql           # Demo data seed
├── .github/
│   ├── workflows/
│   │   ├── web-ci.yml          # Web CI pipeline
│   │   └── mobile-ci.yml       # Mobile CI pipeline
│   └── PULL_REQUEST_TEMPLATE.md
├── .githooks/
│   └── pre-commit              # Lint + analyze before commit
├── AGENTS.md                   # AI agent guidelines
├── AGENTS.template.md          # Universal template for new projects
├── CHANGELOG.md                # Version history
├── Makefile                    # Task runner
└── package.json                # Root workspace config
```

---

## Flavors (Mobile)

| Flavor | Package ID | Audience |
|---|---|---|
| `user` | `com.premoncare.app` | Patients & Doctors |
| `admin` | `com.premoncare.admin` | Platform Administrators |

Admin users are blocked from the user app at 3 layers (login, splash, router).

---

## API Security Pattern

Every API route MUST use the `withSecurity` wrapper:

```typescript
import { withSecurity } from '@/lib/security'

// CORRECT
export const POST = withSecurity(async (req, sessionUser) => {
  // sessionUser.id is trusted — extracted from JWT
})

// WRONG — never do this
export const POST = async (req) => {
  const { userId } = await req.json() // UNTRUSTED
}
```

---

## HIPAA & GDPR Compliance

| Requirement | Status |
|---|---|
| **RLS on all tables** | Implemented |
| **Role-based access (patient/doctor/admin)** | Implemented |
| **PHI audit logging** | Implemented (`log_phi_access()` RPC) |
| **GDPR Right to Erasure** | Implemented (`soft_delete_user()` RPC) |
| **GDPR Right to Portability** | Implemented (`export_user_data()` RPC) |
| **Breach notification** | Documented (60-day HIPAA, 72-hour GDPR) |
| **BAA with Supabase** | Not needed — self-hosted on Coolify |
| **Encryption in transit** | Supabase enforces TLS |
| **Encryption at rest** | Configure on your VPS (LUKS/dm-crypt) |

### Self-Hosted Infrastructure Responsibilities

Since Supabase is self-hosted on Coolify:
- **You** manage disk encryption on your VPS
- **You** manage PostgreSQL SSL (`sslmode=require`)
- **You** manage backups (encrypted, access-controlled)
- **You** manage SSH access and VPN
- **You** need a BAA from your VPS provider (Hetzner, DigitalOcean, AWS, etc.)

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Web** | Next.js 16, React 19, TypeScript, TailwindCSS 4 |
| **Mobile** | Flutter 3.29, Dart, Riverpod |
| **Backend** | Supabase (self-hosted), PostgreSQL, PostgREST |
| **Auth** | Supabase Auth (email OTP) |
| **Storage** | Supabase Storage (private buckets) |
| **Realtime** | Supabase Realtime (`postgres_changes`) |
| **Push** | Firebase Cloud Messaging (server-side only) |
| **Email** | Loops (transactional) |
| **Video** | Jitsi Meet (native SDK on mobile) |
| **Payments** | Manual P2P only (no gateways) |

---

## Documentation

| File | Purpose |
|---|---|
| [README.md](README.md) | Setup, installation, architecture |
| [AGENTS.md](AGENTS.md) | AI agent guidelines, compliance, security |
| [AGENTS.template.md](AGENTS.template.md) | Universal template for new projects |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SYSTEM_WALKTHROUGH.md](SYSTEM_WALKTHROUGH.md) | Full system walkthrough |
| [UI_ARCHITECTURE.md](UI_ARCHITECTURE.md) | UI component architecture |
| [DESIGN.md](DESIGN.md) | Design system documentation |

---

## License

Private — All rights reserved.
