# DESIGN.md — Premoncare Master Design Document

🎯 **Design Philosophy**
Premoncare is built on three core principles:
- **Trust First**: Healthcare must feel safe, calm, and credible.
- **Clarity Over Complexity**: Users should never feel confused.
- **Speed & Accessibility**: Actions must be fast, obvious, and responsive.

> [!IMPORTANT]
> This document defines the *Visual Identity* and *Philosophy*. For a complete technical inventory of all Web Pages, Modals, and Sections, refer to [UI_ARCHITECTURE.md](file:///c:/Users/Ikenna/Codesss/premoncare/UI_ARCHITECTURE.md).

🎨 **Visual Identity**
### 🌈 Color System
| Role | Color | Usage |
| :--- | :--- | :--- |
| **Primary** | #5B6CFF | Buttons, links, active states (Electric Indigo) |
| **Secondary** | #00C2A8 | Success, highlights |
| **Danger** | #FF4D4F | Errors, critical alerts |
| **Warning** | #FFA940 | Pending states |
| **Background** | #F8FAFC | Main app background |
| **Surface** | #FFFFFF | Cards, modals |
| **Text Primary** | #1F2937 | Headings |
| **Text Secondary** | #6B7280 | Descriptions |

### 🧱 Typography
- **Font**: Inter (Primary), Outfit (Headings)
- **Heading 1**: 28px-32px, Black/900
- **Heading 2**: 20px-24px, Black/900
- **Body**: 14px-16px, Medium/500
- **Caption**: 11px-12px, Black/900 (Uppercase tracking)

### 🔲 Spacing & Radius
- **Grid**: 8px (xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px)
- **Border Radius**: Cards: 24px-32px, Buttons: 14px, Inputs: 12px

---

🚀 **Initial User Experience (Mobile Specific)**
### 1. Splash Screen
- **View**: Official Premoncare logo centered on a vibrant indigo gradient background.
- **Animation**: Subtle logo scale-up on entry.

### 2. Onboarding Flow
- **Slide 1**: "Find Specialized Doctors" (Healthcare discovery).
- **Slide 2**: "Instant Consultations" (Emergency & Scheduled).
- **Slide 3**: "Secure Medical Records" (Medical Vault security).
- **Action**: "Get Started" (Redirect to Login/Register).

---

🔐 **Authentication & Access Flow**
### 1. Registration (Patient First Rule)
- **Step 1**: Basic Info (Name, Email, Phone).
- **Step 2**: Role Selection (Default: Patient). *Note: Doctors must register as patients first.*
- **Step 3**: Terms & Privacy Consent (Toggle switches).
- **Step 4**: OTP Verification (Email/SMS).
  - **Logic**: 6-digit code entry, resend timer (60s), success animation.

### 2. Login & Security
- **View**: Minimalist login with "Vibrant Indigo" accents.
- **Password Recovery**: Email entry -> Success message -> Reset link -> New password (with strength meter).
- **Session Management**: Secure persistent sessions with "Session Expired" modal.

---

🏥 **Patient Experience (Web & Mobile)**
### 1. Dashboard
- **Stats**: Total Bookings, Active Prescriptions, Health Progress.
- **Quick Actions**: Book Doctor, View Records, Community Chat.
- **Empty State**: Illustration-based with clear CTA.

### 2. Doctor Discovery & Booking
- **Search**: Category filters (General, Pediatrics, etc.), Search bar, Ratings.
- **Profile**: Profile photo, Specialization, Experience, Reviews, Pricing (₦).
- **Booking Flow**: 
  - **Step 1**: Select Date & Time.
  - **Step 2**: Select Duration (15m, 30m, 60m).
  - **Step 3**: Summary & Payment Selection.
  - **Step 4**: Confirmation / Receipt Upload.

### 3. Medical Vault
- **View**: Categorized folders (Lab Results, Prescriptions, Medical Images).
- **Detail**: File preview, download option, share with doctor.

### 4. Consultation Credits & Payments
- **View**: Current Balance (₦), Credit Card Top-up, P2P History.
- **Top-up Flow**: Select Amount -> Payment Method -> Result Screen.

### 5. Community Forum
- **View**: Feed of health topics, "Create Post" button.
- **Detail**: Post content, comments, "Expert Answer" badge for practitioners.

---

🩺 **Doctor/Practitioner Experience**
### 1. Practitioner Onboarding (Verification Wizard)
- **Step 1**: Professional Credentials (MDCN License No, Specialization).
- **Step 2**: Identity Verification (ID Card upload).
- **Step 3**: Facial Recognition (Liveness check - Mobile Only).
- **Step 4**: Profile Setup (Bio, Availability).

### 2. Appointment Manager (The "Command Center")
- **Stats**: Today's Sessions, Upcoming, Pending requests.
- **Requests List**: Patient name, requested time, "Accept/Reject" buttons.
- **Daily Timeline**: Vertical line with time-stamped session cards.
- **Donut Chart**: visual split of session statuses.

### 3. Consultation Room (Virtual Meeting)
- **View**: Full-screen video (Mobile) / Split-view Video + Records (Web).
- **In-Call Actions**: Mute, Camera, Chat, View Records, End Call.
- **Post-Call**: Prescription entry form, Consultation notes.

### 4. Earnings & Analytics
- **View**: Total Balance (₦), Recent Payouts, Earnings Chart (Weekly/Monthly).

---

⚖️ **Admin Command Center (Web)**
### 1. Dashboard Overview
- **Metrics**: Total Users, Total Revenue, Pending Verifications, Reported Posts.

### 2. Practitioner Verification
- **List**: All pending practitioner applications.
- **Detail**: View MDCN license photo, ID photo, bio.
- **Actions**: Approve, Request More Info, Reject.

### 3. Payment Audit
- **List**: All P2P transaction receipts uploaded by users.
- **Action**: Mark as Verified -> Auto-update user credits.

### 4. Forum & Content Control
- **List**: Reported posts/comments.
- **Action**: View context, Delete, Warn user, Dismiss report.

---

🚨 **Emergency Guest Flow**
- **Trigger**: "Emergency" button on landing/splash.
- **Flow**: One-click Search -> Instant Match -> 5x Base Rate (₦) -> Direct Call.
- **Post-Call**: Account creation prompt to sync emergency history to a permanent profile.

---

🛠️ **Universal Features & Components**
### 1. Notification Center
- **Views**: All notifications, Unread only.
- **Types**: Appointment Reminders, Chat Messages, Payment Confirmed, Admin Alerts.

### 2. Profile & Account Settings
- **Views**: Edit Profile, Change Password, Notification Preferences.
- **Switch Role**: **"Switch to Practitioner"** (Only for approved doctors) — Instant dashboard swap.

### 3. Navigation (Main Layout)
- **Web**: Left Sidebar (Icon + Label), Top Header (Logo + Profile), role-specific menus.
- **Mobile / Global Navigation Standards**:
  
  #### 📱 PATIENT APP
  - **Bottom Navigation (Fixed Everywhere)**:
    - 🏠 Home (Patient Dashboard)
    - 🔍 Explore (Doctor Search, Doctor Profile, Specialties)
    - 📅 Appointments (Bookings, Upcoming, History)
    - 💬 Community (Forum, Ask Doctor, Saved Discussions)
    - 👤 Profile (Settings, Medical Records, Notifications, Permissions, Credits)
  - **Top Bar**:
    - Left: Premon Care Logo
    - Right: 🔔 (Notification Icon)
  - **Profile Menu** (When tapping avatar):
    - My Profile, Medical Records, Permissions, Credits, Settings, Logout (No hamburger menu).

  #### 🩺 DOCTOR APP
  - **Bottom Navigation**:
    - 🏠 Dashboard (Doctor metrics)
    - 📅 Appointments (Today's appointments, Schedule, Availability)
    - 👥 Patients (Patient list, Medical records, Notes, Prescriptions)
    - 💬 Community (Forum, Ask Doctor, Contributions)
    - 👤 Profile (Subscription, Verification, Earnings, Settings, Logout)
  - **Top Bar**:
    - Left: Premon Care Logo
    - Right: 🔔 👤 (Notification icon, Doctor profile avatar)
  - **Doctor Profile Menu** (When tapping avatar):
    - Doctor Profile, Verification Status, Subscription, Availability, Earnings, Settings, Logout (No hamburger menu).

  #### 🛡️ ADMIN APP
  - **Bottom Navigation (Keep ONLY 5 items)**:
    - 🏠 Dashboard
    - 👥 Users
    - 👨‍⚕️ Doctors
    - 💬 Forum
    - ⋯ More
  - **More Menu** (Contains):
    - 📊 Reports & Insights, 💰 Financial Moderation, 📋 Audit Timeline, 🚨 Emergency Queue, ⚙️ Settings, 📦 Subscription Plans, 🤝 Dispute Resolution.
  - **Top Bar**:
    - Left: ☰ (Hamburger Menu icon - opens Admin Drawer)
    - Center/Left: Premon Care Admin
    - Right: 🔔 👩 Admin (Notification icon, Admin profile avatar)
  - **Admin Drawer**:
    - Dashboard, User Management, Doctor Verification, Financial Moderation, P2P Monitoring, Emergency Queue, Forum Moderation, Reports, Audit Timeline, Subscription Plans, Dispute Resolution, Platform Settings.

  #### 🌐 GLOBAL RULES
  - **Notifications**: Always top-right 🔔 for all roles.
  - **Profile Placement**: Always top-right avatar image for all roles.
  - **Hamburger Menu**: ONLY Admin gets the Hamburger Menu/Drawer. Patient and Doctor must NOT have a hamburger menu.

### 4. Common UI Elements
- **Modals**: Glassmorphism background, centered content, top-right close.
- **Skeleton Loaders**: Gray-scale pulsing boxes for images, lines for text.
- **Empty States**: Soft illustration + "No Data Found" + Primary CTA.

---

💡 **The Golden Rule**
*“Every visual element must serve the patient's peace of mind. Use soft shadows, rounded shapes, and clear, non-medical language wherever possible.”*
