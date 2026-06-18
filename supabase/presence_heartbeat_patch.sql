-- DDL Patch: Presence Heartbeat Tracking & Auto-Offline Sweep

-- 1. Add last_seen column to public.profiles if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
          AND column_name = 'last_seen'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN last_seen timestamp with time zone DEFAULT now();
    END IF;
END $$;

-- 2. Create the offline doctors sweeper function
CREATE OR REPLACE FUNCTION public.sweep_offline_doctors() 
RETURNS void AS $$
BEGIN
    UPDATE public.profiles 
    SET is_online = false 
    WHERE role = 'doctor' 
      AND is_online = true 
      AND last_seen < now() - interval '2 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Expose function or view to verify heartbeat status (Optional)
COMMENT ON FUNCTION public.sweep_offline_doctors() IS 'Sweeps and marks inactive doctors as offline after 2 minutes of no heartbeat.';
