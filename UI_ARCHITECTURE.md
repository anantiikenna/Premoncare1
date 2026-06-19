# UI Architecture — Premoncare Web Reference

This document serves as the absolute inventory of all visual interfaces, processes, and interactive elements within the Premoncare Web Platform. Use this as the source of truth for UI/UX consistency and feature parity audits.

---

## 🔓 1. Public & Authentication Layer
| Type | View / Element | Workflow / Critical Steps |
| :--- | :--- | :--- |
| **Page** | `Landing Page (/)` | 1. Hero Exposure -> 2. "Emergency" vs "General" Selection -> 3. Service Education -> 4. Footer Portal. |
| **Page** | `Login (/login)` | 1. Credential Entry -> 2. Session Validation -> 3. Role-Based Dashboard Redirection. |
| **Page** | `Registration (/register)` | **Step 1:** Identity -> **Step 2:** Terms Consent -> **Step 3:** OTP Sync. [STATUS: IMPLEMENTED] |
| **Page** | `Forgot Password` | 1. Account Identity (Email) -> 2. Dispatch Success View -> 3. Check Mail CTA. |
| **Page** | `Reset Password` | 1. Link Validation -> 2. Password Strength Check -> 3. Secure Reset -> 4. Auto-Login. |
| **Page** | `Emergency (/emergency)` | 1. Quick Match Filters -> 2. Doctor Inventory -> 3. Guest Details -> 4. 5x Booking -> 5. Redirect to Waiting. |
| **Page** | `Emergency Waiting (/emergency-waiting)` | 1. SVG Countdown Ring (3 min) -> 2. Real-Time Status via Supabase Realtime -> 3. On Accept: Redirect to Checkout -> 4. On Decline/Timeout: Find Another Doctor. |
| **Page** | `Account Conversion` | 1. Session Token Auth -> 2. Benefit Visualization -> 3. Final Profile Upgrade -> 4. Record Migration. |
| **Overlay**| `OTP Verification` | 1. Code Input -> 2. Backend Validation -> 3. Resend Logic (60s) -> 4. Success Animation. |

---

## 🏥 2. Patient Ecosystem (Care Hub)
### A. Core Pages & Routes
*   **`Dashboard (/patient/dashboard)`**: The central "Command Center" view with health summaries.
*   **`My Records (/patient/records)`**: The "Medical Vault" for encrypted documents.
*   **`Appointments (/patient/appointments)`**: Booking history and new scheduling portal.
*   **`Forum Hub (/patient/forum)`**: Community category feed and trending topics.
*   **`Messages (/patient/messages)`**: Real-time secure consultation threads.
*   **`Digital Rx (/patient/prescriptions)`**: Chronological list of issued medications.
*   **`Consultation Credits (/patient/credits)`**: Financial management and transaction logs.
*   **`Profile Settings (/patient/profile)`**: Personal data, security, and verification status.

### B. Dynamic Sections & Overlays
| Type | View / Element | Workflow / Logic |
| :--- | :--- | :--- |
| **Section** | `Booking Wizard` | **1.** Specialist Selection -> **2.** Slot Discovery -> **3.** Duration/Reason -> **4.** Payment/Receipt. |
| **Overlay** | `P2P Receipt Upload` | 1. Upload Screenshot -> 2. Enter Ref ID -> 3. Dispatch to Admin Audit -> 4. "Pending" Alert. |
| **Overlay** | `Access Control` | 1. Select Doctor -> 2. Review Permission Scopes -> 3. Biometric/OTP Auth -> 4. Keys Decrypted. |
| **Overlay** | `Forum Guidelines` | 1. Mandatory Read -> 2. Rule Consent (Checkbox) -> 3. Profile "Community Access" Unlock. |
| **Overlay** | `Doctor Review` | 1. Star Rating (1-5) -> 2. Text Review -> 3. Tip Option -> 4. Verification & Publish. |
| **Overlay** | `Prescription Detail` | 1. View Rx Metadata -> 2. Dosage Guide -> 3. Doctor Notes -> 4. Print/Download PDF. |
| **Section** | `Virtual Meeting Room` | 1. Mic/Cam Test -> 2. Secure Handshake -> 3. Peer-to-Peer Stream -> 4. Clinical Recording Opt-in. |

---

## 🩺 3. Practitioner Ecosystem (Command Center)
### A. Core Pages & Routes
*   **`Main Command Center (/doctor/dashboard)`**: Analytics-heavy view with revenue/schedule stats.
*   **`Schedule View (/doctor/appointments)`**: Timeline-based management of daily bookings.
*   **`Consultation Hub (/doctor/messages)`**: Direct patient interaction portal.
*   **`Prescription Tool (/doctor/prescriptions)`**: Professional Rx generation interface.
*   **`Induction Portal (/doctor/apply)`**: The "Practitioner Verification Wizard."

### B. Dynamic Sections & Overlays
| Type | View / Element | Workflow / Logic |
| :--- | :--- | :--- |
| **Section** | `Emergency Request Alert` (Web) | Real-time card with SVG countdown ring (3 min), Accept/Decline buttons, toast notifications. Listens to Supabase Realtime on `appointments` table. Auto-declines on timeout. |
| **Section** | `Practitioner Induction`| **1.** Specialty Setup -> **2.** MDCN License -> **3.** ID/Selfie Audit -> **4.** Fee Negotiation. [REJECTION HANDLED] |

| **Overlay** | `Prescription Builder` | 1. Patient Selection -> 2. Medication/Dosage Entry -> 3. Instruction Mapping -> 4. Digital Sign-off. |
| **Overlay** | `Propose Follow-up` | 1. Select Follow-up Date/Time -> 2. Add Clinical Reason -> 3. Send Proposal -> 4. Await Patient Payment. |
| **Overlay** | `Fee Acceptance` | 1. Review Admin Offer -> 2. Accept Terms -> 3. Credits Setup -> 4. "Active" Platform Status. |
| **Overlay** | `Consultation Hub` | 1. Incoming Alert -> 2. Accept/Reject -> 3. Note Review -> 4. Launch Virtual Room. |
| **Overlay** | `Schedule Detail` | 1. Tap Timeline Card -> 2. View Patient Case Summary -> 3. Edit Record -> 4. Update Status. |

---

## ⚖️ 4. Admin Infrastructure (Governance)
### A. Core Pages & Routes
*   **`System Analytics (/admin/dashboard)`**: High-level platform health metrics.
*   **`User Management (/admin/users)`**: Global database of all platform participants.
*   **`Practitioner Audit (/admin/doctors)`**: Verification queue and fee negotiation portal.
*   **`Payment Audit (/admin/payments)`**: P2P receipt verification and credit approval queue.
*   **`Moderation Hub (/admin/forum)`**: Queue for reported posts and global announcements.

### B. Dynamic Sections & Overlays
| Type | View / Element | Workflow / Logic |
| :--- | :--- | :--- |
| **Drawer** | `User Detail Panel` | 1. Select User -> 2. Review Medical History -> 3. View Billing Logs -> 4. Action (Ban/Warn/Promote). |
| **Overlay** | `Practitioner Audit` | 1. View Credentials -> 2. Biometric Verification -> 3. License Validity Check -> 4. Final Approval. |
| **Overlay** | `Payment Verification` | 1. Review P2P Receipt -> 2. Cross-check Bank Entry -> 3. Approve Payment -> 4. Auto-Credit Top-up. |
| **Overlay** | `Moderation Wizard` | 1. Reported Content Context -> 2. Apply Rulebook -> 3. Dispatch Action -> 4. Notify Reporter. |
| **Overlay** | `System Broadcast` | 1. Message Creation -> 2. Audience Selection -> 3. Schedule/Send -> 4. Analytics Delivery. |

---

## 🔄 5. Global Navigation Architecture (Standardized)

### A. Role-Based Mappings
- **Patient Platform**:
  - **Top Bar**: Premon Care Logo (left), 🔔 Notification Icon (right).
  - **Bottom Navigation**: 🏠 Home (Dashboard) | 🔍 Explore | 📅 Appointments | 💬 Community | 👤 Profile.
  - **Avatar Action**: Tapping the top-right avatar triggers the **Patient Profile Menu**: My Profile, Medical Records, Permissions, Credits, Settings, Logout.
- **Doctor Platform**:
  - **Top Bar**: Premon Care Practitioner Logo (left), 🔔 👤 Notification + Avatar (right).
  - **Bottom Navigation**: 🏠 Dashboard | 📅 Appointments | 👥 Patients | 💬 Community | 👤 Profile.
  - **Avatar Action**: Tapping the top-right avatar triggers the **Doctor Profile Menu**: Doctor Profile, Verification Status, Subscription, Availability, Earnings, Settings, Logout.
- **Admin Platform**:
  - **Top Bar**: ☰ Drawer Trigger (left), Premon Care Admin (center/left), 🔔 👩 Admin Notification + Avatar (right).
  - **Bottom Navigation** (Max 5 items): 🏠 Dashboard | 👥 Users | 👨‍⚕️ Doctors | 💬 Forum | ⋯ More.
  - **More Menu**: 📊 Reports | 💰 Financial | 📋 Audit Timeline | 🚨 Emergency Queue | ⚙️ Settings | 📦 Subscriptions | 🤝 Disputes.
  - **Drawer**: Dashboard, User Management, Doctor Verification, Financial Moderation, P2P Monitoring, Emergency Queue, Forum Moderation, Reports, Audit Timeline, Subscription Plans, Dispute Resolution, Platform Settings.

### B. Global Rules & Consistency
1. **Notifications**: Always placed in the Top-Right (🔔) across all platforms.
2. **Profile Avatar**: Always placed in the Top-Right (👤) across all platforms.
3. **Hamburger Menus**: **ONLY Admin** gets the hamburger drawer. Patients and Doctors must never have a hamburger navigation drawer.
4. **Parity**: Mobile and Web platforms must match these route targets and screen segmentation.

---
*Last Updated: June 2026 (Emergency Handshake Flow, P2P-Only Payments)*
