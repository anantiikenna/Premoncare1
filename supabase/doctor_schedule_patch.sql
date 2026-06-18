-- Doctor Schedule Management System
-- This patch adds the necessary infrastructure for managing practitioner availability.

CREATE TABLE IF NOT EXISTS doctor_schedules (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  doctor_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
  weekly_hours JSONB DEFAULT '[
    {"day": "Monday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Tuesday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Wednesday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Thursday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Friday", "enabled": true, "start": "08:00", "end": "17:00"},
    {"day": "Saturday", "enabled": false, "start": "09:00", "end": "13:00"},
    {"day": "Sunday", "enabled": false, "start": "00:00", "end": "00:00"}
  ]'::jsonb,
  break_times JSONB DEFAULT '[]'::jsonb,
  vacation_mode BOOLEAN DEFAULT false,
  emergency_availability BOOLEAN DEFAULT false,
  auto_accept BOOLEAN DEFAULT false,
  timezone TEXT DEFAULT 'Africa/Lagos',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE doctor_schedules ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Doctors can manage their own schedule." ON doctor_schedules;
CREATE POLICY "Doctors can manage their own schedule." 
  ON doctor_schedules FOR ALL 
  USING (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Anyone can view doctor schedules." ON doctor_schedules;
CREATE POLICY "Anyone can view doctor schedules." 
  ON doctor_schedules FOR SELECT 
  USING (true);

-- Function to handle schedule initialization on profile promotion
CREATE OR REPLACE FUNCTION public.initialize_doctor_schedule()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'doctor' AND (OLD.role IS NULL OR OLD.role != 'doctor') THEN
    INSERT INTO doctor_schedules (doctor_id)
    VALUES (NEW.id)
    ON CONFLICT (doctor_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for schedule initialization
DROP TRIGGER IF EXISTS on_doctor_promotion ON profiles;
CREATE TRIGGER on_doctor_promotion
  AFTER UPDATE OF role ON profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.initialize_doctor_schedule();
