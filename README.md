# 🏥 Premon Care - Premium Care

Premon Care is a comprehensive, state-of-the-art healthcare management system built with Next.js (Web), Flutter (Mobile), and Supabase. It features a decentralized **P2P Financial Model**, **Biometric Identity Verification**, real-time clinical messaging, smart appointment scheduling, and encrypted video consultations, offering true cross-platform parity between Web and Mobile clients.

## 🚀 Quick Start Guide

Follow these steps to get your own instance of Premon Care up and running.

### 1. Prerequisites
- **Node.js** (v18 or higher)
- **Supabase Account**: You'll need a project on [Supabase](https://supabase.com).
- **Gmail SMTP**: Required for the premium branded notification engine.

### 2. Installation
Clone the repository (or download the source) and install the dependencies:

```bash
# Navigate to the project directory
cd health-app

# Install dependencies
npm install
```

### 3. Environment Configuration
Create a `.env.local` file in the root directory and add your Supabase and SMTP credentials.

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-public-key
NEXT_PUBLIC_SITE_URL=https://premoncare.netlify.app

# Email Notifications (Gmail SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM_NAME='Premon Care'
SMTP_FROM_EMAIL=no-reply@premoncare.com
```

### 4. Database Setup (Supabase)
This project uses a custom schema with automated triggers and strict RLS policies.
1. Go to your **Supabase SQL Editor**.
2. Copy and paste the contents of `supabase/schema.sql`.
3. Run the script. This will initialize `profiles`, `appointments`, `medical_profiles`, `health_records`, and the `notifications` engine.
4. If updating an existing instance, run `supabase/update_live.sql` to apply the emergency handshake flow, RLS policies, and latest schema patches.

### 5. Storage Setup
Create the following buckets in the **Supabase Storage** tab to enable the identity vault and financial engine:
- **`avatars`** (Public): For user profile pictures.
- **`doctor-verifications`** (Private): For medical licenses and credentials.
- **`doctor-identities`** (Private): For government IDs and Biometric Selfie captures.
- **`payment-receipts`** (Private): For manual P2P consultation fee proofs and doctor subscription receipts.
- **`health-records`** (Private): For clinical record attachments.
- **`patient-verifications`** (Private): For general user identity verification.

### 6. Running the App
Start the development server:

```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to see the live application.

---

## 🏗️ Architecture & Features

### 🔐 Identity & Biometric Security
- **4-Step Verification Wizard**: A rigorous induction flow for practitioners including professional credentials, government identity, and **Live Facial Biometrics**.
- **Private Vault Storage**: Sensitive identity documents are stored with 256-bit encryption in restricted storage buckets.
- **Role Flexibility**: Approved practitioners maintain a "Universal Profile," allowed to switch between providing care and managing their own personal health.

### 📅 P2P Financial Architecture
- **Direct P2P Model**: Patients pay doctors directly for consultations. No middleman fees.
- **Consultation Credits**: Consultation minutes are tracked as "Consultation Credits," unlocked only after manual receipt verification by the practitioner.
- **Emergency Consultations**: A high-priority flow allowing guest users to bypass registration for immediate care. Emergency sessions carry a **5x premium rate** (500% base) for rapid intervention.
- **Naira (₦) Localization**: Full platform localization for the Nigerian market, including dynamic fee calculations.

### 🎥 Virtual Consultations (Zero-Config)
The video calling system is integrated via the **Jitsi Meet iframe API**. 
- **No Server Installation Required**: Connects securely to the Jitsi/8x8 global infrastructure.
- **Automated Room Creation**: Meeting rooms are dynamically created and destroyed based on appointment IDs.

### 🏛️ Multi-Admin Governance & Mobile Administration
- **Audit Trail & Live Monitoring**: Every critical action is recorded in the `audit_logs` table. Administrators have access to a real-time Audit Timeline Viewer across both Web and Mobile platforms to instantly trace fraud, system configuration changes, and suspicious logins.
- **Financial Moderation**: Admins verify platform subscription receipts to unlock practitioner dashboards.
- **Mobile Admin Power**: Full administrative control ported to the mobile application, featuring instant Verification Approval dialogs and mass Payout Execution directly from the mobile Admin dashboard.
- **Granular Security Controls**: Users can manage Biometrics, 2FA, and actively monitor their `device_sessions` via the high-fidelity Settings & Privacy Center, achieving true Web-to-Mobile feature parity.

### 💬 Real-Time Clinical Communications
- **Secure Messaging**: HIPAA-ready messaging system available on both platforms.
- **Rich Media**: Support for sharing Prescriptions, Lab Reports, Images, and Geolocation data directly within consultation threads.
- **High-Fidelity Notifications**: A dedicated mobile Notification Center providing sticky emergency alerts, categorized views, and contextual actions (e.g., immediate "Join Call" buttons).

---

## 🛠️ Tech Stack
- **Framework**: Next.js 15+ (App Router)
- **Backend**: Supabase (Auth, DB, Storage)
- **Email**: Nodemailer with Gmail SMTP & Branded HTML Templates
- **UI Components**: Radix UI (via shadcn/ui) & Lucide Icons
- **Video**: Jitsi Meet Iframe API

---

## 📄 Documentation Links
- [System Walkthrough](SYSTEM_WALKTHROUGH.md)
- [Project Readme (This File)](README.md)
- [AI Agent Config](AGENTS.md)
