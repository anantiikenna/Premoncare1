-- Cleanup script to reverse schema.sql

-- 1. Remove tables from realtime publication
alter publication supabase_realtime drop table if exists appointments;
alter publication supabase_realtime drop table if exists forum_posts;
alter publication supabase_realtime drop table if exists forum_comments;

-- 2. Drop triggers
drop trigger if exists on_auth_user_created on auth.users;

-- 3. Drop tables (in reverse dependency order)
drop table if exists system_settings;
drop table if exists forum_comments;
drop table if exists forum_posts;
drop table if exists health_records;
drop table if exists appointments;
drop table if exists profiles;

-- 4. Drop functions
-- Using CASCADE to ensure dependent triggers (like the one on auth.users) are also dropped
drop function if exists public.handle_new_user() cascade;

-- 5. Drop custom types
drop type if exists verification_status;
drop type if exists user_role;

-- 6. Drop storage policies
-- Note: These are dropped by name, assuming they exist on storage.objects
drop policy if exists "Users can upload their own verification documents." on storage.objects;
drop policy if exists "Admins can view all verification documents." on storage.objects;
drop policy if exists "Patients can view their own record attachments." on storage.objects;
drop policy if exists "Doctors can upload and view record attachments." on storage.objects;

-- 7. Extensions (Optional: usually kept unless a full reset is desired)
-- drop extension if exists "uuid-ossp";
