-- Add FCM Token column to the profiles table
-- This allows push notifications to be sent to user devices
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token text;
