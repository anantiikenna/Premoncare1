-- ----------------------------------------------------------------------------
-- System Parity Patch: Audit Logs, Device Sessions, and Privacy Toggles
-- ----------------------------------------------------------------------------

-- 1. Create Enums for Audit Logs
DO $$ BEGIN
    CREATE TYPE audit_action_type AS ENUM ('verification', 'financial', 'security', 'system');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE audit_severity AS ENUM ('info', 'moderate', 'high');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action_type audit_action_type NOT NULL,
    severity audit_severity NOT NULL DEFAULT 'info',
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 3. Create Device Sessions Table
CREATE TABLE IF NOT EXISTS public.device_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    device_name TEXT NOT NULL,
    ip_address TEXT,
    location TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_current BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Update Profiles Table with Privacy & Security Controls
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS medical_records_shared_by_default BOOLEAN DEFAULT false;

-- 5. Enable RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_sessions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for Audit Logs
-- Only admins can view audit logs
DO $$ BEGIN
    CREATE POLICY "Admins can view audit logs" ON public.audit_logs
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = auth.uid() AND role = 'admin'
            )
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Admins can insert audit logs
DO $$ BEGIN
    CREATE POLICY "Admins can insert audit logs" ON public.audit_logs
        FOR INSERT WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = auth.uid() AND role = 'admin'
            )
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 7. RLS Policies for Device Sessions
DO $$ BEGIN
    CREATE POLICY "Users can view their own device sessions" ON public.device_sessions
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their own device sessions" ON public.device_sessions
        FOR DELETE USING (auth.uid() = user_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
