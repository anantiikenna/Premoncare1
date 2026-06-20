-- ============================================================
-- LIVE MIGRATION: Emergency Handshake Flow
-- Run this in your Supabase SQL Editor
-- Each statement runs independently — safe to re-run
-- ============================================================

-- 1. Add missing columns (safe if already exists)
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS is_emergency boolean DEFAULT false;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS total_amount numeric DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS payment_instructions text;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS rejection_reason text;

-- 2. Update status check constraint for emergency flow
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_status_check;
ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN (
    'pending',
    'emergency_pending',
    'emergency_request',
    'emergency_accepted',
    'emergency_declined',
    'confirmed',
    'cancelled',
    'completed',
    'ongoing'
  ));

-- 3. Performance indexes
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status
  ON public.appointments (doctor_id, status);

CREATE INDEX IF NOT EXISTS idx_appointments_emergency_requests
  ON public.appointments (doctor_id, created_at DESC)
  WHERE status = 'emergency_request';

-- 4. Realtime publication (skip if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
  END IF;
END $$;

-- 5. Verify
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'appointments'
AND column_name IN ('metadata', 'is_emergency', 'total_amount')
ORDER BY ordinal_position;
