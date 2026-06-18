# Premoncare System Architecture Guide

This document outlines the technical architecture of the Premoncare platform, focusing on the synchronization between the Next.js Web Application and the Flutter Mobile Application.

## 🏗️ Core Technology Stack
- **Frontend (Web)**: Next.js 16 (App Router), TailwindCSS / Vanilla CSS.
- **Frontend (Mobile)**: Flutter (SDK ^3.11), Riverpod 3.0 State Management.
- **Backend / Database**: Supabase (PostgreSQL, Auth, Storage, Realtime).
- **Payments**: P2P Manual Verification (Bank Transfer) with receipt upload.

---

## 🔄 Cross-Platform Synchronization
Web and Mobile clients communicate primarily through **Supabase Realtime**.

### 1. Messaging System
- **Provider**: `messaging_provider.dart` (Mobile) / `chat.tsx` (Web).
- **Mechanism**: Both clients listen to the `messages` table for new inserts where `recipient_id` matches the current user.
- **Mark as Read**: Handled via a RPC or direct update to the `is_read` column.

### 2. Social Forum
- **Provider**: `forum_provider.dart`.
- **Logic**: A global `StreamProvider` that broadcasts posts and comments.
- **Parity**: Mobile uses `ChoiceChip` for category filtering to match the Web's sidebar navigation.

---

## 🏦 Manual Payment Workflow
Since Premoncare uses a P2P decentralized financial model, payments are verified manually by practitioners.

1. **Patient**: Uploads a screenshot/photo of the bank transfer receipt.
2. **Database**: A record is created in `payments` table with status `pending`.
3. **Doctor**: Receives a notification (Realtime) on their dashboard.
4. **Approval**: Doctor reviews the receipt image and clicks **Approve**, which triggers a database trigger to update the patient's consultation status.

---

## 🔐 Medical Records Sharing Protocol
Privacy is the core of Premoncare. Medical records are NOT shared by default.

### Selective Access
1. **Records Vault**: Patients upload files to their private storage bucket.
2. **Permissions Table**: A join table `record_permissions` tracks which `doctor_id` can see which `file_id`.
3. **Sharing**: On Mobile, the `record_sharing_sheet.dart` allows patients to select a verified doctor to grant temporary or permanent access.
4. **Practitioner View**: Doctors only see records in their "Shared with me" section if a row exists in the permissions table.

---

## 🎨 Design System
Premoncare uses a **Modern Glassmorphism** design language.
- **Mobile**: Custom `GlassCard` widget with backdrop filters and specular borders.
- **Web**: `.glass-panel` CSS utility with dynamic hover-reveal effects.
- **Aesthetic**: Vibrant indigo primary colors (#0F62FE) mixed with translucent surfaces.

---

## 🛠️ Maintenance & Scaling
- **Adding Features**: Ensure any database schema change is reflected in both `apps/web/src/lib/types.ts` and `apps/mobile/lib/core/models/`.
- **Building Mobile**: Run `flutter build apk` or `flutter build ios` after ensuring all environment variables in `.env` match the production Supabase project.
