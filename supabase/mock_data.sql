-- ============================================================
-- PREMON CARE: COMPREHENSIVE MOCK DATA SEED SCRIPT
-- Updated: 2026-08 (timestamps relative to now() — always current)
-- Covers EVERY table in the schema with realistic data
-- Uses past (~90 days), present (today), and future (7–30 days ahead)
-- RUN THIS IN YOUR SUPABASE SQL EDITOR
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$
DECLARE
    -- ── Doctor UUIDs ──────────────────────────────────────────
    d1  UUID := 'd1111111-1111-1111-1111-111111111111';
    d2  UUID := 'd2222222-2222-2222-2222-222222222222';
    d3  UUID := 'd3333333-3333-3333-3333-333333333333';
    d4  UUID := 'd4444444-4444-4444-4444-444444444444';
    d5  UUID := 'd5555555-5555-5555-5555-555555555555';

    -- ── Patient UUIDs ─────────────────────────────────────────
    p1  UUID := 'a1111111-1111-1111-1111-111111111111';
    p2  UUID := 'a2222222-2222-2222-2222-222222222222';
    p3  UUID := 'a3333333-3333-3333-3333-333333333333';
    p4  UUID := 'a4444444-4444-4444-4444-444444444444';
    p5  UUID := 'a5555555-5555-5555-5555-555555555555';
    p6  UUID := 'a6666666-6666-6666-6666-666666666666';
    p7  UUID := 'a7777777-7777-7777-7777-777777777777';
    p8  UUID := 'a8888888-8888-8888-8888-888888888888';
    p9  UUID := 'a9999999-9999-9999-9999-999999999999';
    p10 UUID := 'a0000000-0000-0000-0000-000000000000';

    -- ── Admin UUID ────────────────────────────────────────────
    adm UUID := 'adadadad-adad-adad-adad-adadadadadad';

    -- ── Appointment UUIDs ─────────────────────────────────────
    ap1  UUID := uuid_generate_v4();
    ap2  UUID := uuid_generate_v4();
    ap3  UUID := uuid_generate_v4();
    ap4  UUID := uuid_generate_v4();
    ap5  UUID := uuid_generate_v4();
    ap6  UUID := uuid_generate_v4();
    ap7  UUID := uuid_generate_v4();
    ap8  UUID := uuid_generate_v4();
    ap9  UUID := uuid_generate_v4();
    ap10 UUID := uuid_generate_v4();
    ap11 UUID := uuid_generate_v4();
    ap12 UUID := uuid_generate_v4();
    ap13 UUID := uuid_generate_v4();
    ap14 UUID := uuid_generate_v4();
    ap15 UUID := uuid_generate_v4();

    -- ── Payment UUIDs ─────────────────────────────────────────
    pay1  UUID := uuid_generate_v4();
    pay2  UUID := uuid_generate_v4();
    pay3  UUID := uuid_generate_v4();
    pay4  UUID := uuid_generate_v4();
    pay5  UUID := uuid_generate_v4();
    pay6  UUID := uuid_generate_v4();
    pay7  UUID := uuid_generate_v4();
    pay8  UUID := uuid_generate_v4();
    pay9  UUID := uuid_generate_v4();
    pay10 UUID := uuid_generate_v4();
    pay11 UUID := uuid_generate_v4();

    -- ── Subscription Plan UUIDs ───────────────────────────────
    plan1 UUID := uuid_generate_v4();
    plan2 UUID := uuid_generate_v4();
    plan3 UUID := uuid_generate_v4();

    -- ── Medical Record UUIDs ──────────────────────────────────
    mr1 UUID := uuid_generate_v4();
    mr2 UUID := uuid_generate_v4();
    mr3 UUID := uuid_generate_v4();
    mr4 UUID := uuid_generate_v4();
    mr5 UUID := uuid_generate_v4();
    mr6 UUID := uuid_generate_v4();

    -- ── Forum UUIDs ───────────────────────────────────────────
    fc1 UUID := uuid_generate_v4();
    fc2 UUID := uuid_generate_v4();
    fc3 UUID := uuid_generate_v4();
    fc4 UUID := uuid_generate_v4();
    fc5 UUID := uuid_generate_v4();

    fp1 UUID := uuid_generate_v4();
    fp2 UUID := uuid_generate_v4();
    fp3 UUID := uuid_generate_v4();
    fp4 UUID := uuid_generate_v4();
    fp5 UUID := uuid_generate_v4();
    fp6 UUID := uuid_generate_v4();
    fp7 UUID := uuid_generate_v4();

    fr1 UUID := uuid_generate_v4();
    fr2 UUID := uuid_generate_v4();
    fr3 UUID := uuid_generate_v4();
    fr4 UUID := uuid_generate_v4();
    fr5 UUID := uuid_generate_v4();
    fr6 UUID := uuid_generate_v4();

    -- ── Payout UUIDs ──────────────────────────────────────────
    po1 UUID := uuid_generate_v4();
    po2 UUID := uuid_generate_v4();
    po3 UUID := uuid_generate_v4();

    -- ── Refund/Dispute UUIDs ──────────────────────────────────
    ref1 UUID := uuid_generate_v4();
    dis1 UUID := uuid_generate_v4();
    dis2 UUID := uuid_generate_v4();

    -- ── Review UUIDs ──────────────────────────────────────────
    rev1 UUID := uuid_generate_v4();
    rev2 UUID := uuid_generate_v4();
    rev3 UUID := uuid_generate_v4();
    rev4 UUID := uuid_generate_v4();
    rev5 UUID := uuid_generate_v4();
    rev6 UUID := uuid_generate_v4();

    -- ── Prescription UUIDs ────────────────────────────────────
    rx1 UUID := uuid_generate_v4();
    rx2 UUID := uuid_generate_v4();
    rx3 UUID := uuid_generate_v4();
    rx4 UUID := uuid_generate_v4();
    rx5 UUID := uuid_generate_v4();

    -- ── Doctor Sub UUIDs ──────────────────────────────────────
    ds1 UUID := uuid_generate_v4();
    ds2 UUID := uuid_generate_v4();
    ds3 UUID := uuid_generate_v4();
    ds4 UUID := uuid_generate_v4();
    ds5 UUID := uuid_generate_v4();

BEGIN

-- ============================================================
-- 0. STORAGE BUCKETS (all 7 required buckets)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('avatars',               'avatars',               true),
    ('patient-medical-vault', 'patient-medical-vault', false),
    ('medical-documents',     'medical-documents',     false),
    ('patient-verifications', 'patient-verifications', false),
    ('doctor-verifications',  'doctor-verifications',  false),
    ('doctor-identities',     'doctor-identities',     false),
    ('payment-receipts',      'payment-receipts',      false)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 1. AUTH USERS (5 doctors + 10 patients + 1 admin)
-- ============================================================
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
) VALUES
-- Admin
('00000000-0000-0000-0000-000000000000', adm, 'authenticated', 'authenticated', 'admin@premoncare.com',       crypt('AdminPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Platform Admin"}', now(), now(), '', '', '', ''),
-- Doctors
('00000000-0000-0000-0000-000000000000', d1,  'authenticated', 'authenticated', 'dr.adaeze@premoncare.com',   crypt('DoctorPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Adaeze Nwosu"}',    now()-interval '90 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', d2,  'authenticated', 'authenticated', 'dr.ibrahim@premoncare.com',  crypt('DoctorPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Ibrahim Musa"}',    now()-interval '85 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', d3,  'authenticated', 'authenticated', 'dr.chinedu@premoncare.com',  crypt('DoctorPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Chinedu Okafor"}',  now()-interval '80 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', d4,  'authenticated', 'authenticated', 'dr.fatima@premoncare.com',   crypt('DoctorPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Fatima Al-Hassan"}',now()-interval '70 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', d5,  'authenticated', 'authenticated', 'dr.emeka@premoncare.com',    crypt('DoctorPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Emeka Eze"}',       now()-interval '60 days', now(), '', '', '', ''),
-- Patients (emails match profiles exactly)
('00000000-0000-0000-0000-000000000000', p1,  'authenticated', 'authenticated', 'john.doe@mail.com',          crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"John Doe"}',       now()-interval '60 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p2,  'authenticated', 'authenticated', 'jane.smith@mail.com',        crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Jane Smith"}',     now()-interval '55 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p3,  'authenticated', 'authenticated', 'michael.j@mail.com',         crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Michael Johnson"}', now()-interval '50 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p4,  'authenticated', 'authenticated', 'emily.davis@mail.com',       crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Emily Davis"}',    now()-interval '45 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p5,  'authenticated', 'authenticated', 'chris.olatunji@mail.com',    crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Chris Olatunji"}', now()-interval '42 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p6,  'authenticated', 'authenticated', 'amanda.white@mail.com',      crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Amanda White"}',   now()-interval '40 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p7,  'authenticated', 'authenticated', 'emeka.nnamdi@mail.com',      crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Emeka Nnamdi"}',   now()-interval '35 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p8,  'authenticated', 'authenticated', 'sarah.lee@mail.com',         crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Sarah Lee"}',      now()-interval '30 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p9,  'authenticated', 'authenticated', 'samuel.j@mail.com',          crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Samuel Jackson"}', now()-interval '25 days', now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', p10, 'authenticated', 'authenticated', 'blessing.ok@mail.com',       crypt('Patient123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Blessing Okafor"}',now()-interval '20 days', now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 2. PROFILES (all schema columns included)
-- ============================================================
INSERT INTO public.profiles (
    id, email, username, full_name, avatar_url, title, role, requested_role,
    verification_status, account_status,
    specialty, experience_years, clinic_address,
    consultation_fee, video_fee, in_person_fee,
    rating, review_count, consultation_counts, verified_medical_answers,
    helpful_votes, patients_helped, is_online, last_seen,
    about_text, specializations_list, education,
    identity_document_front_url, identity_type,
    verification_document_url, medical_license_number,
    languages_spoken, preferred_consultation_types,
    hourly_rate, payment_instructions,
    dob, gender, blood_group, next_of_kin_name,
    next_of_kin_phone, emergency_contact_name, emergency_contact_phone,
    phone, address,
    subscription_status, subscription_expires_at, last_subscription_payment_at,
    fee_status, email_alerts_enabled, fcm_token,
    biometric_enabled, two_factor_enabled, medical_records_shared_by_default
) VALUES
-- ── Admin ────────────────────────────────────────────────────
(adm, 'admin@premoncare.com', 'premoncare_admin', 'Admin', null, null,
 'admin', 'admin', 'approved', 'active',
 null, null, null, null, null, null, null, 0, 0, 0, 0, 0, false, now(),
 'Platform administrator account', '{}', '[]',
 null, null, null, null, null, '{}',
 null, null,
 null, null, null, null, null, null, null,
 '+2348000000000', 'Premon Care HQ, Lagos',
 'inactive', null, null, 'none',
 true, null, false, true, false),

-- ── Doctors ──────────────────────────────────────────────────
(d1, 'dr.adaeze@premoncare.com', 'dr_adaeze', 'Adaeze Nwosu', null, 'Dr.',
 'doctor', 'doctor', 'approved', 'active',
 'Cardiology', 10, 'Heartcare Clinic, Lagos Island',
 15000, 12000, 20000, 4.8, 120, 450, 34, 210, 450, true, now()-interval '10 min',
 'Board-certified cardiologist with 10+ years managing hypertension, heart failure, and arrhythmias. I believe every patient deserves a personalised care plan.',
 ARRAY['Hypertension','Heart Failure','Arrhythmia','ECG Interpretation'],
 '[{"degree":"MBBS","institution":"University of Lagos","year":2014},{"degree":"FWACP (Cardiology)","institution":"West African College of Physicians","year":2018}]',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'National ID',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'MED-LAG-20180045', 'English, Igbo, Yoruba', ARRAY['video','in_person'],
 15000, 'Bank Transfer: Dr. Adaeze Nwosu / Access Bank / 0123456701. Upload receipt after transfer.',
 '1988-03-14', 'female', 'O+', null, null, null, null,
 '+2348011110001', '5 Bourdillon Road, Ikoyi, Lagos',
 'active', now()+interval '6 months', now()-interval '5 days',
 'active', true, null, false, false, false),

(d2, 'dr.ibrahim@premoncare.com', 'dr_ibrahim', 'Ibrahim Musa', null, 'Dr.',
 'doctor', 'doctor', 'approved', 'active',
 'Pediatrics', 8, 'Children''s Med Centre, Abuja',
 12000, 10000, 16000, 4.9, 95, 300, 28, 165, 300, true, now()-interval '1 hour',
 'Dedicated pediatrician passionate about child health and vaccination. I speak plainly with parents and put kids at ease.',
 ARRAY['Childhood Infections','Nutrition','Vaccination','Neonatal Care'],
 '[{"degree":"MBBS","institution":"Ahmadu Bello University","year":2015},{"degree":"FWACP (Paediatrics)","institution":"West African College of Physicians","year":2020}]',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'Passport',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'MED-ABJ-20200032', 'English, Hausa', ARRAY['video','audio'],
 12000, 'Bank Transfer: Dr. Ibrahim Musa / Zenith Bank / 0123456702. Upload receipt after transfer.',
 '1990-07-22', 'male', 'A+', null, null, null, null,
 '+2348011110002', '12 Aminu Kano Crescent, Wuse 2, Abuja',
 'active', now()+interval '4 months', now()-interval '20 days',
 'active', true, null, false, false, false),

(d3, 'dr.chinedu@premoncare.com', 'dr_chinedu', 'Chinedu Okafor', null, 'Dr.',
 'doctor', 'doctor', 'approved', 'active',
 'Neurology', 12, 'Brain Health Institute, Lagos',
 20000, 18000, 25000, 4.9, 150, 500, 52, 295, 500, false, now()-interval '3 hours',
 'Senior neurologist specialising in migraines, epilepsy, and stroke recovery. I use evidence-based protocols to deliver the best patient outcomes.',
 ARRAY['Migraines','Epilepsy','Stroke','Neuropathy','MS'],
 '[{"degree":"MBBS","institution":"University of Ibadan","year":2012},{"degree":"FMCP (Neurology)","institution":"National Postgraduate Medical College","year":2017}]',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'Driver''s License',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'MED-LAG-20170021', 'English, Igbo', ARRAY['video'],
 20000, 'Bank Transfer: Dr. Chinedu Okafor / GTBank / 0123456703. Upload receipt after transfer.',
 '1985-11-05', 'male', 'B+', null, null, null, null,
 '+2348011110003', '22 Admiralty Way, Lekki Phase 1, Lagos',
 'active', now()+interval '8 months', now()-interval '10 days',
 'active', true, null, false, false, false),

(d4, 'dr.fatima@premoncare.com', 'dr_fatima', 'Fatima Al-Hassan', null, 'Dr.',
 'doctor', 'doctor', 'approved', 'active',
 'Dermatology', 7, 'Glow Skin Clinic, Kano',
 15000, 12000, 18000, 4.6, 75, 180, 19, 98, 180, true, now()-interval '30 min',
 'Dermatologist helping patients achieve healthy, radiant skin through personalised treatment plans. Specialising in acne, eczema, and pigmentation disorders.',
 ARRAY['Acne','Eczema','Psoriasis','Pigmentation','Skin Cancer Screening'],
 '[{"degree":"MBBS","institution":"Bayero University Kano","year":2016},{"degree":"Dip. Dermatology","institution":"University of Cardiff","year":2021}]',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'National ID',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'MED-KAN-20210011', 'English, Hausa, Arabic', ARRAY['video','in_person'],
 15000, 'Bank Transfer: Dr. Fatima Al-Hassan / First Bank / 0123456704. Upload receipt after transfer.',
 '1992-06-18', 'female', 'AB+', null, null, null, null,
 '+2348011110004', '8 Zoo Road, Kano',
 'active', now()+interval '3 months', now()-interval '30 days',
 'active', true, null, false, false, false),

(d5, 'dr.emeka@premoncare.com', 'dr_emeka', 'Emeka Eze', null, 'Dr.',
 'doctor', 'doctor', 'approved', 'active',
 'General Practice', 5, 'City Wellness Centre, Enugu',
 8000, 7000, 10000, 4.7, 88, 200, 15, 75, 200, true, now()-interval '45 min',
 'Compassionate GP providing holistic, preventative care for the whole family. Your first port of call for any health concern.',
 ARRAY['General Checkup','Flu & Infections','Preventative Care','Chronic Disease Management'],
 '[{"degree":"MBBS","institution":"University of Nigeria, Nsukka","year":2019}]',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'National ID',
 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
 'MED-ENU-20190078', 'English, Igbo', ARRAY['video','audio','text'],
 8000, 'Bank Transfer: Dr. Emeka Eze / UBA / 0123456705. Upload receipt after transfer.',
 '1994-02-28', 'male', 'O-', null, null, null, null,
 '+2348011110005', '3 Independence Layout, Enugu',
 'active', now()+interval '2 months', now()-interval '45 days',
 'active', true, null, false, false, false),

-- ── Patients ─────────────────────────────────────────────────
(p1,  'john.doe@mail.com',       'johndoe',     'John Doe',        null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '2 hours', null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1990-04-12', 'male',   'O+',  'Mary Doe',          '+2348011111101', 'Mary Doe',          '+2348011111101', '+2348011111101', '14 Broad Street, Lagos Island', 'inactive', null, null, 'none', true, null, false, false, false),
(p2,  'jane.smith@mail.com',     'janesmith',   'Jane Smith',      null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '1 hour',  null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1993-08-25', 'female', 'A+',  'James Smith',       '+2348011111102', 'James Smith',       '+2348011111102', '+2348011111102', '7 Adeola Odeku Street, VI, Lagos', 'inactive', null, null, 'none', true, null, false, false, false),
(p3,  'michael.j@mail.com',      'michaelj',    'Michael Johnson', null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, false, now()-interval '5 hours', null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1985-11-30', 'male',   'B+',  'Linda Johnson',     '+2348011111103', 'Linda Johnson',     '+2348011111103', '+2348011111103', '33 Allen Avenue, Ikeja, Lagos', 'inactive', null, null, 'none', true, null, false, false, false),
(p4,  'emily.davis@mail.com',    'emilydavis',  'Emily Davis',     null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '30 min',  null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1998-01-07', 'female', 'AB-', 'Robert Davis',      '+2348011111104', 'Robert Davis',      '+2348011111104', '+2348011111104', '19 Oduduwa Crescent, GRA, Ikeja', 'inactive', null, null, 'none', true, null, false, false, false),
(p5,  'chris.olatunji@mail.com', 'chrisolat',   'Chris Olatunji',  null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '15 min',  null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1988-06-14', 'male',   'O-',  'Grace Olatunji',    '+2348011111105', 'Grace Olatunji',    '+2348011111105', '+2348011111105', '5 Fola Osibo Street, Lekki, Lagos', 'inactive', null, null, 'none', true, null, false, false, false),
(p6,  'amanda.white@mail.com',   'amandaw',     'Amanda White',    null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, false, now()-interval '8 hours', null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1995-03-19', 'female', 'A-',  'Frank White',       '+2348011111106', 'Frank White',       '+2348011111106', '+2348011111106', '10 Yakubu Gowon Way, Kaduna', 'inactive', null, null, 'none', true, null, false, false, false),
(p7,  'emeka.nnamdi@mail.com',   'emekannamdi', 'Emeka Nnamdi',    null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '20 min',  null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1991-09-09', 'male',   'B-',  'Ngozi Nnamdi',      '+2348011111107', 'Ngozi Nnamdi',      '+2348011111107', '+2348011111107', '2 Trans-Ekulu, Enugu', 'inactive', null, null, 'none', true, null, false, false, false),
(p8,  'sarah.lee@mail.com',      'sarahlee',    'Sarah Lee',       null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '3 hours', null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1997-12-03', 'female', 'O+',  'Tom Lee',           '+2348011111108', 'Tom Lee',           '+2348011111108', '+2348011111108', '45 Awolowo Road, Ikoyi, Lagos', 'inactive', null, null, 'none', true, null, false, false, false),
(p9,  'samuel.j@mail.com',       'samuelj',     'Samuel Jackson',  null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, false, now()-interval '6 hours', null, '{}', '[]', null, null, null, null, null, '{}', null, null, '1982-07-17', 'male',   'AB+', 'Priscilla Jackson', '+2348011111109', 'Priscilla Jackson', '+2348011111109', '+2348011111109', '9 Ring Road, Ibadan', 'inactive', null, null, 'none', true, null, false, false, false),
(p10, 'blessing.ok@mail.com',    'blessingo',   'Blessing Okafor', null, null, 'patient', 'patient', 'unsubmitted', 'active', null, null, null, null, null, null, null, 0, 0, 0, 0, 0, true,  now()-interval '1 hour',  null, '{}', '[]', null, null, null, null, null, '{}', null, null, '2000-05-22', 'female', 'A+',  'Charles Okafor',    '+2348011111110', 'Charles Okafor',    '+2348011111110', '+2348011111110', '18 New Market Road, Onitsha', 'inactive', null, null, 'none', true, null, false, false, false)
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, title = EXCLUDED.title, role = EXCLUDED.role,
    requested_role = EXCLUDED.requested_role,
    specialty = EXCLUDED.specialty, rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count, consultation_fee = EXCLUDED.consultation_fee,
    about_text = EXCLUDED.about_text, is_online = EXCLUDED.is_online,
    last_seen = EXCLUDED.last_seen,
    verification_status = EXCLUDED.verification_status,
    subscription_status = EXCLUDED.subscription_status,
    subscription_expires_at = EXCLUDED.subscription_expires_at,
    fee_status = EXCLUDED.fee_status,
    payment_instructions = EXCLUDED.payment_instructions,
    email_alerts_enabled = EXCLUDED.email_alerts_enabled,
    phone = EXCLUDED.phone,
    address = EXCLUDED.address;


-- ============================================================
-- 3. DOCTOR SCHEDULES
-- ============================================================
INSERT INTO public.doctor_schedules (doctor_id, timezone, emergency_availability, auto_accept)
VALUES
    (d1, 'Africa/Lagos', true,  false),
    (d2, 'Africa/Lagos', true,  true),
    (d3, 'Africa/Lagos', false, false),
    (d4, 'Africa/Lagos', false, false),
    (d5, 'Africa/Lagos', true,  true)
ON CONFLICT (doctor_id) DO UPDATE SET
    emergency_availability = EXCLUDED.emergency_availability,
    auto_accept = EXCLUDED.auto_accept;


-- ============================================================
-- 4. SYSTEM SETTINGS (ensure defaults exist)
-- ============================================================
INSERT INTO public.system_settings (
    id, auto_approve_enabled, auto_approve_delay_minutes,
    payment_methods_allowed, digital_gateway,
    allow_doctor_pricing, base_consultation_fee, manual_payment_instructions
) VALUES (
    'default', false, 0, 'both', 'dodo', true, 8000,
    'Bank Transfer: Premon Care / Naira Merchant Bank / Account: 0123456789. Please upload your payment receipt after transfer.'
) ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 5. SUBSCRIPTION PLANS
-- ============================================================
INSERT INTO public.subscription_plans (id, name, description, price, duration_months, features, is_active)
VALUES
    (plan1, 'Starter', 'Perfect for newly onboarded doctors building their patient base.',
     15000, 1, ARRAY['Online profile listing','Patient messaging','Appointment management','Analytics dashboard'], true),
    (plan2, 'Professional', 'Best for active practitioners with regular consultations.',
     40000, 3, ARRAY['Everything in Starter','Priority search placement','Emergency consultations enabled','Advanced analytics','Priority support'], true),
    (plan3, 'Premium Annual', 'Maximum value for established medical professionals.',
     120000, 12, ARRAY['Everything in Professional','Annual billing discount','Dedicated account manager','Featured profile badge','Custom availability rules'], true)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 6. PAYMENTS (all manual P2P — digital gateways disabled)
-- ============================================================
INSERT INTO public.payments (id, created_at, user_id, amount, status, method, receipt_url, transaction_id, recipient_id, duration_minutes, rejection_reason)
VALUES
-- Approved consultation payments (past)
(pay1,  now()-interval '45 days', p1,  15000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-001', d1,  30, null),
(pay2,  now()-interval '40 days', p2,  12000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-002', d2,  30, null),
(pay3,  now()-interval '35 days', p3,  20000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-003', d3,  60, null),
(pay4,  now()-interval '30 days', p4,  15000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-004', d4,  30, null),
(pay5,  now()-interval '25 days', p5,   8000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-005', d5,  30, null),
(pay6,  now()-interval '20 days', p6,  15000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-006', d1,  30, null),
(pay7,  now()-interval '15 days', p7,  12000, 'approved', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-007', d2,  30, null),
-- Pending subscription payment (Sarah Lee - awaiting admin verification)
(pay8,  now()-interval '10 days', p8,  40000, 'pending',  'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-008', null, null, null),
-- Pending consultation payment (Samuel → Dr. Chinedu)
(pay9,  now()-interval '5 days',  p9,  15000, 'pending',  'manual', null,                                                                       'TXN-PAY-009', d3,  30, null),
-- Rejected payment
(pay10, now()-interval '2 days',  p10, 40000, 'rejected', 'manual', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'TXN-PAY-010', null, null, 'Insufficient documentation — receipt image unreadable'),
-- Emergency payment (pending — patient accepted, awaiting verification)
(pay11, now()-interval '7 minutes', p5, 100000, 'pending', 'manual', null, 'TXN-PAY-EMG-001', d2, 30, null)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 7. APPOINTMENTS (past, present/today, and future)
-- ============================================================
INSERT INTO public.appointments (id, created_at, patient_id, doctor_id, appointment_date, status, reason, consultation_mode, duration_minutes, is_emergency, total_amount, payment_id, is_doctor_approved, is_patient_approved, meeting_link, reminder_sent, metadata)
VALUES
-- ── Past completed ────────────────────────────────────────────
(ap1,  now()-interval '44 days', p1,  d1, now()-interval '44 days'+interval '10 hours', 'completed', 'Chest pain and shortness of breath during exercise',       'video',     30, false, 45000,  pay1, true,  true,  'https://meet.premoncare.com/room/ap1',  true,  '{}'),
(ap2,  now()-interval '39 days', p2,  d2, now()-interval '39 days'+interval '14 hours', 'completed', 'Child''s recurring fever and loss of appetite',             'video',     30, false, 37500,  pay2, true,  true,  'https://meet.premoncare.com/room/ap2',  true,  '{}'),
(ap3,  now()-interval '34 days', p3,  d3, now()-interval '34 days'+interval '11 hours', 'completed', 'Severe migraine for 3 days unresponsive to paracetamol',    'video',     60, false, 100000, pay3, true,  true,  'https://meet.premoncare.com/room/ap3',  true,  '{}'),
(ap4,  now()-interval '29 days', p4,  d4, now()-interval '29 days'+interval '15 hours', 'completed', 'Persistent acne flare-up and skin discolouration',           'video',     30, false, 30000,  pay4, true,  true,  'https://meet.premoncare.com/room/ap4',  true,  '{}'),
(ap5,  now()-interval '24 days', p5,  d5, now()-interval '24 days'+interval '9 hours',  'completed', 'Annual general health checkup',                              'video',     30, false, 40000,  pay5, true,  true,  'https://meet.premoncare.com/room/ap5',  true,  '{}'),
(ap6,  now()-interval '19 days', p6,  d1, now()-interval '19 days'+interval '16 hours', 'completed', 'High blood pressure follow-up after 3 weeks on medication',  'video',     30, false, 45000,  pay6, true,  true,  'https://meet.premoncare.com/room/ap6',  true,  '{}'),
(ap7,  now()-interval '14 days', p7,  d2, now()-interval '14 days'+interval '13 hours', 'completed', 'Child vaccination schedule review',                          'audio',     30, false, 37500,  pay7, true,  true,  'https://meet.premoncare.com/room/ap7',  true,  '{}'),
-- ── Past cancelled ────────────────────────────────────────────
(ap8,  now()-interval '12 days', p8,  d3, now()-interval '11 days'+interval '10 hours', 'cancelled', 'Numbness and tingling in left arm',                          'video',     30, false, 0,      null, false, true,  null,                                    false, '{}'),
-- ── Today / pending ───────────────────────────────────────────
(ap9,  now()-interval '1 hour',  p9,  d1, now()+interval '2 hours', 'pending',   'Follow-up on hypertension medication side effects',          'video',     30, false, 45000,  pay9, false, true,  'https://meet.premoncare.com/room/ap9',  false, '{}'),
(ap10, now()-interval '30 min',  p10, d5, now()+interval '3 hours', 'pending',   'Fatigue, dizziness and low energy for 2 weeks',              'video',     30, false, 40000,  null, false, true,  null,                                    false, '{}'),
-- ── Future confirmed (properly in the future) ────────────────
(ap11, now()-interval '2 days',  p1,  d3, now()+interval '10 days'+interval '10 hours', 'confirmed', 'Neurological review — recurring severe headaches',           'video',     30, false, 0,      null, true,  true,  'https://meet.premoncare.com/room/ap11', false, '{}'),
(ap12, now()-interval '1 day',   p3,  d4, now()+interval '20 days'+interval '14 hours', 'confirmed', 'Eczema management and new topical treatment plan',           'in_person', 30, false, 0,      null, true,  true,  null,                                    false, '{}'),
-- ── Emergency: active request (guest — doctor hasn''t responded yet) ─
(ap13, now()-interval '2 minutes', null, d1, now()-interval '2 minutes', 'emergency_request', 'EMERGENCY CONSULTATION (Guest)', 'video', 15, true, 25000, null, false, true, null, false,
 '{"is_guest": true, "guest_token": "guest_1750000000000", "guest_email": "guest@example.com", "pricing_multiplier": 5}'),
-- ── Emergency: doctor accepted, awaiting patient payment ─────
(ap14, now()-interval '8 minutes', p5,  d2, now()-interval '8 minutes', 'emergency_accepted', 'EMERGENCY: Severe chest pain radiating to left arm', 'video', 30, true, 100000, pay11, true, true, 'https://meet.premoncare.com/room/ap14', false, '{}'),
-- ── Emergency: doctor declined (guest) ───────────────────────
(ap15, now()-interval '20 minutes', null, d3, now()-interval '20 minutes', 'emergency_declined', 'EMERGENCY CONSULTATION (Guest)', 'video', 15, true, 25000, null, false, true, null, false,
 '{"is_guest": true, "guest_token": "guest_1750000000001", "guest_email": "patient0@example.com", "pricing_multiplier": 5}')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 8. TIME BALANCES (consultation credits between patients & doctors)
-- ============================================================
INSERT INTO public.time_balances (patient_id, doctor_id, minutes_remaining, created_at, updated_at)
VALUES
    (p1, d1, 45,  now()-interval '44 days', now()-interval '10 days'),
    (p2, d2, 30,  now()-interval '39 days', now()-interval '5 days'),
    (p3, d3, 30,  now()-interval '34 days', now()-interval '2 days'),
    (p4, d4, 60,  now()-interval '29 days', now()-interval '1 day'),
    (p5, d5, 30,  now()-interval '24 days', now()-interval '3 days'),
    (p6, d1, 15,  now()-interval '19 days', now()-interval '7 days'),
    (p7, d2, 30,  now()-interval '14 days', now()-interval '4 days'),
    (p1, d5, 30,  now()-interval '20 days', now()-interval '6 days'),
    (p2, d1, 0,   now()-interval '30 days', now()-interval '15 days'),
    (p8, d3, 60,  now()-interval '5 days',  now()-interval '1 day')
ON CONFLICT (patient_id, doctor_id) DO UPDATE SET
    minutes_remaining = EXCLUDED.minutes_remaining,
    updated_at = now();


-- ============================================================
-- 9. MEDICAL PROFILES (patient health details)
-- ============================================================
INSERT INTO public.medical_profiles (id, blood_group, genotype, allergies, chronic_conditions, emergency_contact_name, emergency_contact_phone, updated_at)
VALUES
    (p1,  'O+',  'AA', 'Penicillin',         'Hypertension',                   'Mary Doe',          '+2348011111101', now()-interval '30 days'),
    (p2,  'A+',  'AS', 'None',                'Asthma',                         'James Smith',       '+2348011111102', now()-interval '25 days'),
    (p3,  'B+',  'AA', 'Sulfonamides',        'Type 2 Diabetes',                'Linda Johnson',     '+2348011111103', now()-interval '20 days'),
    (p4,  'AB-', 'SS', 'Latex',               'Sickle Cell Anaemia',            'Robert Davis',      '+2348011111104', now()-interval '15 days'),
    (p5,  'O-',  'AS', 'None',                'None',                           'Grace Olatunji',    '+2348011111105', now()-interval '10 days'),
    (p6,  'A-',  'AA', 'NSAIDs',              'Hypertension, High Cholesterol', 'Frank White',       '+2348011111106', now()-interval '8 days'),
    (p7,  'B-',  'AC', 'None',                'Chronic Back Pain',              'Ngozi Nnamdi',      '+2348011111107', now()-interval '5 days'),
    (p8,  'O+',  'AA', 'Codeine',             'Migraine',                       'Tom Lee',           '+2348011111108', now()-interval '3 days'),
    (p9,  'AB+', 'AS', 'Aspirin, Tree nuts',  'Hypertension, Anxiety',          'Priscilla Jackson', '+2348011111109', now()-interval '2 days'),
    (p10, 'A+',  'AA', 'None',                'None',                           'Charles Okafor',    '+2348011111110', now()-interval '1 day')
ON CONFLICT (id) DO UPDATE SET
    blood_group = EXCLUDED.blood_group,
    genotype = EXCLUDED.genotype,
    allergies = EXCLUDED.allergies,
    chronic_conditions = EXCLUDED.chronic_conditions;


-- ============================================================
-- 10. MEDICAL RECORDS
-- ============================================================
INSERT INTO public.medical_records (id, patient_id, title, description, record_type, document_url, authorized_doctors, created_at)
VALUES
    (mr1, p1,  'Annual Blood Panel',           'Full blood count, lipids, HbA1c',              'lab_result',   'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d1],     now()-interval '60 days'),
    (mr2, p1,  'Echocardiogram Report',        'Echo showing mild LV hypertrophy',             'imaging',      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d1, d3], now()-interval '45 days'),
    (mr3, p2,  'Chest X-Ray',                  'Clear lungs, no consolidation',                'imaging',      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d2],     now()-interval '55 days'),
    (mr4, p3,  'HbA1c Test Result',            'HbA1c = 7.8% — needs active management',      'lab_result',   'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d3, d5], now()-interval '35 days'),
    (mr5, p4,  'Haematology Report',           'Sickle cell screen, CBC',                      'lab_result',   'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d4],     now()-interval '30 days'),
    (mr6, p5,  'Childhood Immunisation Record','All recommended vaccines up to date',           'immunization', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', ARRAY[d2],     now()-interval '20 days')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 11. RECORD PERMISSIONS
-- ============================================================
INSERT INTO public.record_permissions (record_id, doctor_id, granted_at)
VALUES
    (mr2, d1, now()-interval '44 days'),
    (mr2, d3, now()-interval '20 days'),
    (mr4, d3, now()-interval '35 days'),
    (mr4, d5, now()-interval '10 days')
ON CONFLICT (record_id, doctor_id) DO NOTHING;


-- ============================================================
-- 12. PRESCRIPTIONS
-- ============================================================
INSERT INTO public.prescriptions (id, patient_id, doctor_id, medication_name, dosage, frequency, duration, instructions, created_at)
VALUES
    (rx1, p1, d1, 'Amlodipine',          '5mg',   'Once daily',       '3 months',  'Take in the morning with food. Monitor BP weekly.',       now()-interval '44 days'),
    (rx2, p1, d1, 'Atorvastatin',        '20mg',  'Once daily (PM)',  '3 months',  'Take at night. Avoid grapefruit juice.',                   now()-interval '44 days'),
    (rx3, p3, d3, 'Sumatriptan',         '50mg',  'At onset of pain', 'As needed', 'Use at first sign of migraine. Max 2 doses/day.',         now()-interval '34 days'),
    (rx4, p3, d3, 'Metformin',           '500mg', 'Twice daily',      '6 months',  'Take with meals. Check blood sugar twice weekly.',         now()-interval '34 days'),
    (rx5, p4, d4, 'Betamethasone Cream', '0.05%', 'Twice daily',      '4 weeks',   'Apply thin layer to affected areas only.',                 now()-interval '29 days')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 13. REVIEWS (linked to completed appointments)
-- ============================================================
INSERT INTO public.reviews (id, appointment_id, patient_id, doctor_id, rating, comment, created_at)
VALUES
    (rev1, ap1, p1, d1, 5, 'Dr. Adaeze was incredibly thorough and calming. She explained every step clearly and followed up after our session. Highly recommended!', now()-interval '43 days'),
    (rev2, ap2, p2, d2, 5, 'Dr. Ibrahim is amazing with kids! My daughter actually enjoyed the appointment. Very professional and patient.',                         now()-interval '38 days'),
    (rev3, ap3, p3, d3, 5, 'Dr. Chinedu''s knowledge of neurology is outstanding. My migraine plan finally works after years of struggling. I''m grateful.',       now()-interval '33 days'),
    (rev4, ap4, p4, d4, 4, 'Dr. Fatima was knowledgeable and kind. The new skincare routine she prescribed is already showing results. Would visit again.',         now()-interval '28 days'),
    (rev5, ap5, p5, d5, 5, 'Dr. Emeka made me feel completely comfortable. Great communicator, very thorough for a general checkup.',                               now()-interval '23 days'),
    (rev6, ap6, p6, d1, 5, 'Second consultation with Dr. Adaeze and she''s just as great. My BP is finally under control thanks to her dedication.',               now()-interval '18 days')
ON CONFLICT (appointment_id) DO NOTHING;


-- ============================================================
-- 14. MESSAGES (chat threads between patients & doctors)
-- ============================================================
INSERT INTO public.messages (sender_id, receiver_id, content, is_read, type, created_at)
VALUES
-- Thread: p1 <-> d1 (post-appointment follow-up)
(p1, d1, 'Hello Dr. Adaeze, I wanted to say thank you. I''ve been taking the Amlodipine and my BP readings this week are 128/82. Is that good progress?', true, 'text', now()-interval '40 days'),
(d1, p1, 'Hello John! That''s excellent progress — a significant improvement. Keep monitoring daily and we''ll review again in our next appointment. Well done!', true, 'text', now()-interval '40 days'+interval '2 hours'),
(p1, d1, 'Thank you doctor. I also wanted to ask — should I be worried about the mild ankle swelling I''ve noticed?', true, 'text', now()-interval '38 days'),
(d1, p1, 'That can be a side effect of Amlodipine. It''s usually minor. Elevate your legs when resting. If it gets worse, message me immediately.', true, 'text', now()-interval '38 days'+interval '1 hour'),

-- Thread: p2 <-> d2 (child health)
(p2, d2, 'Dr. Ibrahim, my daughter''s fever came back yesterday. It was 38.9°C. She''s eating a little now but very tired.', true, 'text', now()-interval '35 days'),
(d2, p2, 'Thank you for the update, Jane. Please continue the paracetamol dose as prescribed and give her plenty of fluids. If fever exceeds 39.5°C or lasts more than 48h, take her to the ER.', true, 'text', now()-interval '35 days'+interval '30 minutes'),
(p2, d2, 'Understood doctor. The fever broke this morning. She seems much better! Thank you.', true, 'text', now()-interval '33 days'),
(d2, p2, 'Wonderful news! Keep an eye out for any rashes or lethargy. She should be fully recovered in 2-3 days.', true, 'text', now()-interval '33 days'+interval '1 hour'),

-- Thread: p3 <-> d3 (unread — dashboard badge)
(p3, d3, 'Doctor, I had another migraine episode yesterday despite taking the Sumatriptan. It helped after 2 hours but I feel very drained today.', false, 'text', now()-interval '3 days'),
(d3, p3, 'I''m sorry to hear that. The drug needs 30-45 minutes to work. If it took longer, the episode may have been a more severe type. Let''s discuss preventative therapy in our next appointment.', false, 'text', now()-interval '3 days'+interval '2 hours'),

-- Thread: p9 <-> d1 (upcoming appointment)
(p9, d1, 'Good morning Dr. Adaeze. I''m looking forward to our appointment later today. I''ve been keeping a log of my BP readings to share with you.', false, 'text', now()-interval '2 hours'),
(d1, p9, 'Good morning Samuel! That''s very proactive — thank you. Please also note the times you took your medication. See you soon!', false, 'text', now()-interval '1 hour');


-- ============================================================
-- 15. NOTIFICATIONS
-- ============================================================
INSERT INTO public.notifications (user_id, title, message, type, is_read, link, created_at)
VALUES
-- Patient notifications
(p1,  'Payment Approved',         'Your payment of ₦15,000 to Dr. Adaeze Nwosu has been verified.',          'payment',     true,  '/patient/payments',     now()-interval '43 days'),
(p1,  'Appointment Confirmed',    'Your appointment with Dr. Adaeze on this date at 10:00 AM is confirmed.',  'appointment', true,  '/patient/appointments', now()-interval '44 days'),
-- NOTE: 'prescription' is not in the notifications type CHECK; using 'other' instead
(p1,  'New Prescription',         'Dr. Adaeze Nwosu has issued you a new prescription. Tap to view.',         'other',       true,  '/patient/vault',        now()-interval '43 days'),
(p2,  'Payment Approved',         'Your payment of ₦12,000 to Dr. Ibrahim Musa has been verified.',          'payment',     true,  '/patient/payments',     now()-interval '38 days'),
(p3,  'Appointment Completed',    'Your consultation with Dr. Chinedu Okafor has ended. Leave a review!',    'appointment', true,  '/patient/appointments', now()-interval '33 days'),
(p3,  'Unread Message',           'Dr. Chinedu Okafor sent you a message. Tap to view.',                      'message',     false, '/messages',             now()-interval '3 days'),
(p9,  'Appointment Reminder',     'You have an appointment with Dr. Adaeze today at the scheduled time.',     'appointment', false, '/patient/appointments', now()-interval '2 hours'),
(p10, 'Payment Rejected',         'Your payment of ₦40,000 was rejected. Please resubmit with valid receipt.','payment',    false, '/patient/payments',     now()-interval '2 days'),
(p8,  'Appointment Cancelled',    'Your appointment with Dr. Chinedu Okafor has been cancelled.',             'appointment', false, '/patient/appointments', now()-interval '12 days'),

-- Doctor notifications
(d1,  'New Appointment Request',  'John Doe has requested a 30-minute video consultation.',                    'appointment', true,  '/doctor/appointments',  now()-interval '44 days'),
(d1,  'New Appointment Request',  'Samuel Jackson has requested a 30-minute video consultation.',              'appointment', false, '/doctor/appointments',  now()-interval '2 hours'),
(d1,  'Payment Received',         'A consultation payment of ₦15,000 from John Doe has been approved.',       'payment',     true,  '/doctor/dashboard',     now()-interval '43 days'),
(d2,  'New Appointment Request',  'Jane Smith has requested a 30-minute video consultation.',                  'appointment', true,  '/doctor/appointments',  now()-interval '39 days'),
(d3,  'New Message',              'Michael Johnson sent you a message about his recent migraine episode.',     'message',     false, '/messages',             now()-interval '3 days'),
(d5,  'New Appointment Request',  'Blessing Okafor has requested a 30-minute video consultation.',            'appointment', false, '/doctor/appointments',  now()-interval '30 minutes'),

-- Emergency notifications
(d1,  'EMERGENCY Consultation Request',   'A patient has requested an EMERGENCY 15-minute consultation. Fee: ₦25,000', 'appointment', false, '/doctor/appointments', now()-interval '2 minutes'),
(d2,  'Emergency Request Accepted',       'Your emergency consultation has been accepted. Awaiting patient payment.',   'appointment', false, '/doctor/appointments', now()-interval '8 minutes'),
(p5,  'Emergency Request Accepted',       'Dr. Ibrahim Musa has accepted your emergency consultation. Please proceed with payment.', 'appointment', false, '/patient/appointments', now()-interval '8 minutes'),
(d3,  'Emergency Request Declined',       'An emergency consultation request has timed out.',                           'appointment', false, '/doctor/appointments', now()-interval '20 minutes'),

-- Admin notifications
(adm, 'New Doctor Application',   'Dr. Emeka Eze has submitted their verification documents for review.',    'system',      true,  '/admin/verifications',  now()-interval '60 days'),
(adm, 'Payment Pending Approval', 'A manual payment of ₦40,000 from Sarah Lee is awaiting verification.',   'payment',     false, '/admin/payments',       now()-interval '10 days'),
(adm, 'New Dispute Filed',        'A payment dispute has been raised by patient Samuel Jackson.',            'system',      false, '/admin/disputes',       now()-interval '5 days');


-- ============================================================
-- 16. DOCTOR SUBSCRIPTIONS
-- ============================================================
INSERT INTO public.doctor_subscriptions (id, doctor_id, plan_id, status, start_date, expiry_date, last_payment_date, last_payment_amount, auto_renew)
VALUES
    (ds1, d1, plan2, 'active',        now()-interval '1 month',  now()+interval '2 months', now()-interval '1 month',  40000,  true),
    (ds2, d2, plan2, 'active',        now()-interval '2 months', now()+interval '1 month',  now()-interval '2 months', 40000,  true),
    (ds3, d3, plan3, 'active',        now()-interval '3 months', now()+interval '9 months', now()-interval '3 months', 120000, false),
    (ds4, d4, plan1, 'expiring_soon', now()-interval '30 days',  now()+interval '5 days',   now()-interval '30 days',  15000,  true),
    (ds5, d5, plan1, 'active',        now()-interval '15 days',  now()+interval '15 days',  now()-interval '15 days',  15000,  false)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 17. PAYOUTS (doctor earnings)
-- ============================================================
INSERT INTO public.payouts (id, created_at, doctor_id, amount, status, transaction_count, due_date, processed_at, processed_by)
VALUES
    (po1, now()-interval '30 days', d1, 75000, 'approved', 5, now()-interval '32 days', now()-interval '28 days', adm),
    (po2, now()-interval '15 days', d2, 36000, 'approved', 3, now()-interval '17 days', now()-interval '13 days', adm),
    (po3, now()-interval '2 days',  d1, 30000, 'pending',  2, now()+interval '5 days',  null,                     null)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 18. REFUNDS
-- ============================================================
INSERT INTO public.refunds (id, created_at, payment_id, patient_id, amount, reason, status, processed_at, processed_by)
VALUES
    (ref1, now()-interval '11 days', pay8, p8, 40000, 'Doctor cancelled appointment on the day with no prior notice. Patient requests full refund.', 'pending', null, null)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 19. DISPUTES
-- ============================================================
INSERT INTO public.disputes (id, created_at, transaction_id, user_id, patient_id, doctor_id, amount, risk_level, category, title, description, status)
VALUES
    (dis1, now()-interval '10 days', 'TXN-PAY-008', p8, p8, d3, 40000, 'high', 'consultation',
     'Doctor no-show — appointment cancelled without notice',
     'I booked and paid for a 60-minute consultation with Dr. Chinedu Okafor. The appointment was cancelled 10 minutes before with no explanation. I am requesting a full refund and formal review.',
     'under_review'),
    (dis2, now()-interval '5 days', 'TXN-PAY-009', p9, p9, d3, 15000, 'medium', 'payment',
     'Payment approved but appointment not yet confirmed',
     'I made a payment 5 days ago and it shows as pending in my dashboard even though I received a confirmation SMS. Please investigate.',
     'open')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 20. AUDIT LOGS
-- ============================================================
INSERT INTO public.audit_logs (created_at, admin_id, action_type, severity, description, metadata)
VALUES
    (now()-interval '90 days', adm, 'verification', 'info',     'Doctor verification approved: Dr. Adaeze Nwosu',      '{"doctor_id":"d1111111-1111-1111-1111-111111111111","action":"approve"}'),
    (now()-interval '85 days', adm, 'verification', 'info',     'Doctor verification approved: Dr. Ibrahim Musa',      '{"doctor_id":"d2222222-2222-2222-2222-222222222222","action":"approve"}'),
    (now()-interval '80 days', adm, 'verification', 'info',     'Doctor verification approved: Dr. Chinedu Okafor',    '{"doctor_id":"d3333333-3333-3333-3333-333333333333","action":"approve"}'),
    (now()-interval '70 days', adm, 'verification', 'info',     'Doctor verification approved: Dr. Fatima Al-Hassan',  '{"doctor_id":"d4444444-4444-4444-4444-444444444444","action":"approve"}'),
    (now()-interval '60 days', adm, 'verification', 'info',     'Doctor verification approved: Dr. Emeka Eze',         '{"doctor_id":"d5555555-5555-5555-5555-555555555555","action":"approve"}'),
    (now()-interval '43 days', adm, 'financial',    'info',     'Payment TXN-PAY-001 approved: John Doe → Dr. Adaeze (₦15,000)', '{"payment_id":"TXN-PAY-001","amount":15000}'),
    (now()-interval '38 days', adm, 'financial',    'info',     'Payment TXN-PAY-002 approved: Jane Smith → Dr. Ibrahim (₦12,000)', '{"payment_id":"TXN-PAY-002","amount":12000}'),
    (now()-interval '28 days', adm, 'financial',    'info',     'Payout of ₦75,000 processed for Dr. Adaeze Nwosu',   '{"payout_id":"po1","doctor":"Dr. Adaeze Nwosu"}'),
    (now()-interval '10 days', adm, 'security',     'high',     'Dispute filed: Doctor no-show reported by Sarah Lee', '{"dispute_id":"dis1","risk":"high"}'),
    (now()-interval '2 days',  adm, 'financial',    'moderate', 'Payment TXN-PAY-010 rejected — unreadable receipt',   '{"payment_id":"TXN-PAY-010","reason":"invalid_receipt"}');


-- ============================================================
-- 21. DEVICE SESSIONS
-- ============================================================
INSERT INTO public.device_sessions (user_id, device_name, ip_address, location, last_active_at, is_current, created_at)
VALUES
    (p1,  'iPhone 15 Pro',      '105.112.44.12', 'Lagos, Nigeria', now()-interval '2 hours', true,  now()-interval '60 days'),
    (p1,  'MacBook Pro 14"',    '105.112.44.13', 'Lagos, Nigeria', now()-interval '2 days',  false, now()-interval '30 days'),
    (d1,  'Samsung Galaxy S24', '197.210.55.21', 'Lagos, Nigeria', now()-interval '10 min',  true,  now()-interval '90 days'),
    (d2,  'iPad Pro',           '41.58.102.7',   'Abuja, Nigeria', now()-interval '1 hour',  true,  now()-interval '85 days'),
    (adm, 'Dell XPS 15',        '192.168.1.100', 'Lagos, Nigeria', now()-interval '5 min',   true,  now()-interval '100 days');


-- ============================================================
-- 22. NOTIFICATION CHANNELS CONFIG
-- ============================================================
INSERT INTO public.notification_channels_config (id, is_enabled, config, updated_at)
VALUES
    ('in_app',   true,  '{"priority":"high"}',   now()),
    ('email',    true,  '{"provider":"loops"}',   now()),
    ('sms',      false, '{"provider":"termii"}',  now()),
    ('push',     true,  '{"provider":"fcm"}',     now()),
    ('telegram', false, '{}',                     now()),
    ('whatsapp', false, '{}',                     now())
ON CONFLICT (id) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    config = EXCLUDED.config,
    updated_at = now();


-- ============================================================
-- 23. ADMIN NOTIFICATION SETTINGS
-- ============================================================
INSERT INTO public.admin_notification_settings (admin_id, alert_types, updated_at)
VALUES
    (adm, ARRAY['doctor_verified','payment_verified','dispute_filed','new_registration','payout_requested'], now())
ON CONFLICT (admin_id) DO UPDATE SET alert_types = EXCLUDED.alert_types;


-- ============================================================
-- 24. FORUM CATEGORIES
-- ============================================================
INSERT INTO public.forum_categories (id, name, description, icon_name, is_active, created_at)
VALUES
    (fc1, 'General Health',     'Discuss general health topics, tips, and lifestyle',               'heart_pulse',  true, now()-interval '90 days'),
    (fc2, 'Mental Health',      'Support and discussions about mental well-being',                  'brain',        true, now()-interval '90 days'),
    (fc3, 'Nutrition & Diet',   'Questions about food, nutrition, and dietary plans',               'apple',        true, now()-interval '90 days'),
    (fc4, 'Chronic Conditions', 'Managing diabetes, hypertension, and other long-term conditions', 'activity',     true, now()-interval '90 days'),
    (fc5, 'Ask a Doctor',       'Get verified answers from licensed practitioners',                 'stethoscope',  true, now()-interval '90 days')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 25. FORUM POSTS
-- ============================================================
INSERT INTO public.forum_posts (id, created_at, updated_at, author_id, category_id, title, content, is_anonymous, is_ask_doctor_queue, status, upvotes, view_count)
VALUES
    (fp1, now()-interval '50 days', now()-interval '50 days', p1,  fc4, 'Tips for lowering blood pressure naturally without medication?',
     'I was recently diagnosed with Stage 1 hypertension (138/88). My doctor suggested lifestyle changes first before medication. Has anyone successfully lowered their BP through diet and exercise alone? What worked for you?',
     false, false, 'approved', 87, 320),

    (fp2, now()-interval '45 days', now()-interval '44 days', p2,  fc1, 'When should a toddler start speaking full sentences?',
     'My 2-year-old daughter says about 20-30 words but hasn''t started combining them yet. Her paediatrician isn''t concerned but I''m still worried. Is this a developmental red flag?',
     false, false, 'approved', 54, 215),

    (fp3, now()-interval '40 days', now()-interval '38 days', p3,  fc4, 'Managing Type 2 Diabetes with Nigerian food — practical tips?',
     'Newly diagnosed with T2D. I''m from Anambra and our diet is very carb-heavy (garri, rice, yam). My doctor put me on Metformin but I''m struggling to adapt my diet. Any Nigerians here managing diabetes well? What do you eat?',
     false, false, 'approved', 143, 620),

    (fp4, now()-interval '30 days', now()-interval '28 days', p5,  fc2, 'Has anyone tried therapy for work-related burnout? Did it help?',
     'I''ve been exhausted for months — no motivation, constant irritability, can''t sleep properly. My GP says it''s burnout. He recommended CBT therapy but I''m not sure it will work for me. Has anyone in Nigeria tried it?',
     true,  false, 'approved', 72, 280),

    (fp5, now()-interval '20 days', now()-interval '19 days', p7,  fc5, 'What are the early signs of a stroke I should know about?',
     'My father had a minor stroke 2 years ago. I''m worried about my own risk because I have high BP and my diet isn''t great. What are the very early warning signs I should watch out for?',
     false, true,  'approved', 91, 405),

    (fp6, now()-interval '10 days', now()-interval '9 days',  p9,  fc3, 'Is intermittent fasting safe with hypertension medication?',
     'I''ve been reading about intermittent fasting (16:8) and want to try it for weight loss. But I take Amlodipine every morning. Is it safe to fast? Will it affect how the medication works?',
     false, true,  'approved', 38, 190),

    (fp7, now()-interval '5 days',  now()-interval '4 days',  p10, fc1, 'Best multivitamins available in Nigeria pharmacies?',
     'I''ve been feeling generally run-down and my doctor mentioned I may be vitamin D and B12 deficient. Which multivitamin supplements are reliably available at Nigerian pharmacies? Are the local brands okay or should I go for imported ones?',
     false, false, 'approved', 29, 145)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 26. FORUM REPLIES (doctor & patient answers)
-- ============================================================
INSERT INTO public.forum_replies (id, created_at, post_id, author_id, content, is_anonymous, replied_as_doctor, helpful_votes, is_accepted_answer, status)
VALUES
    (fr1, now()-interval '49 days', fp1, d1,
     'Great question! As a cardiologist, I''d recommend the DASH diet — low sodium, high potassium (bananas, sweet potatoes). Combine this with 30 minutes of brisk walking 5 days a week. Reduce alcohol, quit smoking, and manage stress. Many Stage 1 hypertensives achieve control within 3-6 months without medication.',
     false, true, 65, true, 'approved'),

    (fr2, now()-interval '48 days', fp1, p6,
     'I managed to bring mine from 145/92 down to 126/80 in 4 months. I cut out processed food, salt, and started walking every morning. The key for me was also reducing stress — I started journalling.',
     false, false, 22, false, 'approved'),

    (fr3, now()-interval '44 days', fp2, d2,
     'Every child develops at their own pace! At 24 months, the milestone is typically around 50 words and beginning to combine 2 words (e.g. "more juice"). If your daughter isn''t there by 30 months, a speech and language assessment would be worthwhile. A hearing test is also a good first step to rule out any auditory processing issues.',
     false, true, 42, true, 'approved'),

    (fr4, now()-interval '39 days', fp3, d3,
     'Living with T2D in Nigeria is absolutely manageable. Switch from pounded yam to small portions of unripe plantain (lower GI). Oats, beans, and ugwu soup are your friends. Avoid fruit juice — eat the whole fruit instead. Most importantly, check your blood sugar 2 hours after each meal to learn how your body responds.',
     false, true, 98, true, 'approved'),

    (fr5, now()-interval '19 days', fp5, d3,
     'Remember the FAST acronym: **Face drooping**, **Arm weakness**, **Speech difficulty**, **Time to call emergency**. Additional early signs include sudden severe headache with no known cause, sudden vision loss in one or both eyes, and sudden loss of balance. With hypertension as a risk factor, please ensure your BP is consistently below 130/80.',
     false, true, 78, true, 'approved'),

    (fr6, now()-interval '9 days', fp6, d1,
     'Amlodipine can be taken with or without food, so a 16:8 fasting window is generally safe. However, fasting can lower blood pressure further, which may cause dizziness especially in the morning. Monitor your BP daily when you start. If you feel lightheaded, break the fast and contact your doctor. I''d recommend a brief check-in before starting.',
     false, true, 31, true, 'approved')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 27. FORUM SAVES & FOLLOWS
-- ============================================================
INSERT INTO public.forum_saves (user_id, post_id, created_at)
VALUES
    (p1,  fp1, now()-interval '49 days'),
    (p1,  fp5, now()-interval '18 days'),
    (p2,  fp2, now()-interval '44 days'),
    (p3,  fp3, now()-interval '38 days'),
    (p3,  fp6, now()-interval '8 days'),
    (p5,  fp4, now()-interval '27 days'),
    (p7,  fp5, now()-interval '19 days'),
    (p9,  fp6, now()-interval '9 days')
ON CONFLICT (user_id, post_id) DO NOTHING;

INSERT INTO public.forum_follows (user_id, post_id, category_id, created_at)
VALUES
    (p1,  fp1,  null, now()-interval '49 days'),
    (p3,  fp3,  null, now()-interval '38 days'),
    (p5,  null, fc2,  now()-interval '28 days'),
    (p7,  fp5,  null, now()-interval '18 days'),
    (p9,  null, fc4,  now()-interval '15 days'),
    (p10, null, fc1,  now()-interval '4 days')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 28. FORUM REPORTS (content moderation examples)
-- ============================================================
INSERT INTO public.forum_reports (created_at, reporter_id, post_id, reply_id, reason, status)
VALUES
    (now()-interval '15 days', p4, fp4, null,
     'This post contains potentially misleading mental health advice that could discourage seeking professional help.',
     'pending')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 29. HEALTH RECORDS (clinical notes between doctors & patients)
-- ============================================================
INSERT INTO public.health_records (patient_id, doctor_id, content, created_at)
VALUES
    (p1, d1, 'Patient presents with elevated BP (142/90). Started on Amlodipine 5mg. Follow-up in 4 weeks to assess response. Lifestyle modifications discussed: DASH diet, 30min daily exercise, sodium restriction.', now()-interval '44 days'),
    (p2, d2, 'Child (2y 4m) presenting with recurrent febrile episodes. Temperature 38.9°C. Prescribed paracetamol 120mg q6h. Advised mother on hydration and warning signs requiring ER visit. Follow-up in 1 week.', now()-interval '39 days'),
    (p3, d3, 'Patient reports severe migraine (8/10 pain) lasting 72 hours, unresponsive to OTC analgesics. Started Sumatriptan 50mg PRN. Discussed migraine diary and trigger identification. Referred for MRI to exclude secondary causes.', now()-interval '34 days'),
    (p4, d4, 'Moderate acne vulgaris on cheeks and forehead (Grade 3). Started topical adapalene 0.1% + benzoyl peroxide 2.5%. Advised on sun protection and gentle skincare routine. Review in 8 weeks.', now()-interval '29 days'),
    (p5, d5, 'Annual checkup: BP 120/78, BMI 23.4, HbA1c 5.2% (normal). All vitals within normal range. Bloods sent for full panel including lipids, FBC, renal. Counseled on maintaining current lifestyle.', now()-interval '24 days'),
    (p6, d1, 'Follow-up: BP improved to 130/84 on current regimen. Patient reports mild ankle swelling — likely Amlodipine side effect. Advised leg elevation. Continue current dose, recheck in 4 weeks. If swelling persists, consider switching to ARB.', now()-interval '19 days')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 30. MEDICAL DOCUMENTS (patient-uploaded files in medical vault)
-- ============================================================
INSERT INTO public.medical_documents (patient_id, title, file_url, file_type, status, created_at)
VALUES
    (p1, 'Annual Blood Panel Results',    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'active',   now()-interval '60 days'),
    (p1, 'Echocardiogram Report',         'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'active',   now()-interval '45 days'),
    (p2, 'Chest X-Ray Report',            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'active',   now()-interval '55 days'),
    (p3, 'HbA1c Lab Results',             'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'active',   now()-interval '35 days'),
    (p4, 'Haematology Report',            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'active',   now()-interval '30 days'),
    (p5, 'Immunisation Card',             'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'image/jpeg',      'active',   now()-interval '20 days'),
    (p8, 'Previous Migraine MRI',         'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 'archived', now()-interval '90 days'),
    (p9, 'BP Monitoring Log (2 weeks)',    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'text/csv',        'active',   now()-interval '7 days')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 31. FEE NEGOTIATION MESSAGES (doctor ↔ admin pricing discussions)
-- ============================================================
INSERT INTO public.fee_negotiation_messages (doctor_id, sender_id, sender_role, message, created_at)
VALUES
    (d1, d1, 'doctor',  'Good morning. I''d like to discuss adjusting my consultation fee from ₦15,000 to ₦18,000 based on increased demand and 10 years of practice. Happy to provide supporting data.', now()-interval '15 days'),
    (d1, adm, 'admin',  'Thank you Dr. Adaeze. We''ve reviewed your request. Given your patient volume and rating, we can approve ₦16,500 as a starting point. We''ll revisit in 3 months.',       now()-interval '14 days'),
    (d1, d1, 'doctor',  'That sounds reasonable. I accept ₦16,500. Thank you for the consideration.',                                                                                             now()-interval '13 days'),
    (d5, d5, 'doctor',  'Hi admin. I''m new but getting good patient feedback. Can we discuss increasing my video fee from ₦7,000 to ₦9,000?',                                                      now()-interval '7 days'),
    (d5, adm, 'admin',  'Hi Dr. Emeka. Great to hear you''re getting positive feedback! Let''s schedule a review after your first 50 consultations. We''ll reassess then.',                       now()-interval '6 days')
ON CONFLICT DO NOTHING;

END $$;
