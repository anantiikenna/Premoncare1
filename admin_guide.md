# Admin Operations & System Control Guide (Premon Care)

Welcome to the administrative control guide. This document details how administrators configure, monitor, audit, and moderate critical clinical and financial systems inside Premon Care.

---

## 1. System Administration & Role Escalation

### A. Promoting Your First Admin
To assign administrative rights to a user:
1. Sign up for an account at `/register` on the patient web client.
2. Open your secure **Supabase Dashboard**.
3. Navigate to **Table Editor** -> **profiles**.
4. Locate your user entry and change the `role` column value from `patient` to `admin`.
5. Log out and log back in to access administrative views.

Alternatively, execute the following SQL:
```sql
UPDATE public.profiles 
SET role = 'admin' 
WHERE id = 'YOUR_USER_UUID';
```

### B. Row Level Security (RLS)
The database enforces strict RLS policies to safeguard patient privacy:
*   Only users authenticated with the `admin` role can query the `blocked_users` or access advanced operational panels.
*   Medical verification files reside in the private `patient-verifications` storage bucket, accessible exclusively by administrative accounts.

---

## 2. Managing Verifications & Registrations

### A. Practitioner Verification Process
As detailed in the security architecture, doctors cannot register directly. They register as patients first and submit credentials via the Verification Wizard.
1. Navigate to the **User Directory** -> **Doctor Verification Panel**.
2. Review the submitted credentials, qualifications, and medical license numbers.
3. Click the **"View Document"** links to securely stream the uploaded credentials from Supabase Storage.
4. Select **Approve** (marks profile as `doctor` role) or **Reject** (marks as `rejected` with custom feedback).

---

## 3. Financial Policies & Pricing Models

### A. Gateway Configurations
Admins manage clinical financial settings inside the **Configuration Center**:
*   **Active Digital Gateway**: Live toggle switches between Dodo Payments and Paystack.
*   **Global Base Fee**: Define the default consultation rate for all practitioners.
*   **Custom Doctor Pricing**: Enable to allow approved doctors to define custom fees in their clinical settings.
*   **Emergency Multiplier**: Handles emergency guest bookings at a **5x multiplier** of the doctor's base rate.

### B. Manual Payment Moderation
For patients choosing manual bank transfers:
1. Go to **Financial Overview** -> **Payment Review**.
2. Audit the uploaded proof-of-payment receipt.
3. Select **Approve** to unlock the booking slot, or **Reject** to block the consult.

### C. P2P Dispute Resolution Center
To manage manual payment claims and verify transaction histories:
1. Navigate to the **Dispute Resolution Center** inside the Admin Dashboard.
2. Review patient-doctor evidence, adjust session risk levels, and issue final administrative settlements.

---

## 4. Live Operations Monitor (Real-Time Presence)

The dashboard features a premium, real-time administrative command widget:
1.  **Active Specialist Pool**: Visualizes all online doctors (`is_online = true`) tracked via dynamic client heartbeats.
2.  **Live Consultations Feed**: Subscribes directly via **Supabase Realtime Stream Channels** to track ongoing consultations (`status = 'ongoing'`), showing Patient vs Practitioner details, duration, and an administrative **"Moderate Meeting"** bypass.
