-- ============================================================
-- Forum Ecosystem Patch — Premoncare
-- Run this in the Supabase SQL Editor against the live database.
-- Idempotent: safe to run multiple times.
-- ============================================================

-- 1. Drop legacy forum_comments table (replaced by forum_replies)
DROP TABLE IF EXISTS forum_comments CASCADE;

-- 2. Create forum_categories (if not exists)
CREATE TABLE IF NOT EXISTS forum_categories (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  name text not null,
  description text,
  icon_name text,
  is_active boolean default true
);

-- 3. Recreate forum_posts with expanded schema
--    Use a DO block to add columns if table already exists
DO $$
BEGIN
  -- Add columns that may be missing from the old basic forum_posts
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'forum_posts' AND table_schema = 'public') THEN
    -- Add updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'updated_at') THEN
      ALTER TABLE forum_posts ADD COLUMN updated_at timestamp with time zone default now();
    END IF;
    -- Add category_id (new FK to forum_categories)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'category_id') THEN
      ALTER TABLE forum_posts ADD COLUMN category_id uuid references forum_categories(id) on delete set null;
    END IF;
    -- Add attachments
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'attachments') THEN
      ALTER TABLE forum_posts ADD COLUMN attachments text[];
    END IF;
    -- Add is_anonymous
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'is_anonymous') THEN
      ALTER TABLE forum_posts ADD COLUMN is_anonymous boolean default false;
    END IF;
    -- Add is_ask_doctor_queue
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'is_ask_doctor_queue') THEN
      ALTER TABLE forum_posts ADD COLUMN is_ask_doctor_queue boolean default false;
    END IF;
    -- Add upvotes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'upvotes') THEN
      ALTER TABLE forum_posts ADD COLUMN upvotes integer default 0;
    END IF;
    -- Add view_count
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'view_count') THEN
      ALTER TABLE forum_posts ADD COLUMN view_count integer default 0;
    END IF;
    -- Ensure author_id has ON DELETE CASCADE (safe re-add via constraint)
    -- Drop old category text column if it exists (replaced by category_id FK)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'forum_posts' AND column_name = 'category' AND data_type = 'text') THEN
      ALTER TABLE forum_posts DROP COLUMN category;
    END IF;
  ELSE
    -- Create from scratch if table doesn't exist at all
    CREATE TABLE forum_posts (
      id uuid default uuid_generate_v4() primary key,
      created_at timestamp with time zone default now(),
      updated_at timestamp with time zone default now(),
      author_id uuid references profiles(id) on delete cascade not null,
      category_id uuid references forum_categories(id) on delete set null,
      title text not null,
      content text not null,
      attachments text[],
      is_anonymous boolean default false,
      is_ask_doctor_queue boolean default false,
      status forum_post_status default 'approved'::forum_post_status,
      upvotes integer default 0,
      view_count integer default 0
    );
  END IF;
END
$$;

-- 4. Create forum_replies
CREATE TABLE IF NOT EXISTS forum_replies (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  post_id uuid references forum_posts(id) on delete cascade not null,
  author_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  attachments text[],
  is_anonymous boolean default false,
  replied_as_doctor boolean default false,
  helpful_votes integer default 0,
  is_accepted_answer boolean default false,
  status forum_post_status default 'approved'::forum_post_status
);

-- 5. Create forum_reports
CREATE TABLE IF NOT EXISTS forum_reports (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  reporter_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade,
  reply_id uuid references forum_replies(id) on delete cascade,
  reason text not null,
  status forum_report_status default 'pending'::forum_report_status,
  resolved_at timestamp with time zone,
  resolved_by uuid references profiles(id)
);

-- 6. Create forum_saves
CREATE TABLE IF NOT EXISTS forum_saves (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade not null,
  unique(user_id, post_id)
);

-- 7. Create forum_follows
CREATE TABLE IF NOT EXISTS forum_follows (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade,
  category_id uuid references forum_categories(id) on delete cascade,
  check ((post_id is not null and category_id is null) or (post_id is null and category_id is not null))
);

-- ============================================================
-- GRANTS (May 30 Compliance)
-- ============================================================
GRANT SELECT ON public.forum_categories TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_categories TO service_role;

GRANT SELECT ON public.forum_posts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_posts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_posts TO service_role;

GRANT SELECT ON public.forum_replies TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_replies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_replies TO service_role;

GRANT SELECT ON public.forum_reports TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reports TO service_role;

GRANT SELECT ON public.forum_saves TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_saves TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_saves TO service_role;

GRANT SELECT ON public.forum_follows TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_follows TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_follows TO service_role;

-- ============================================================
-- RLS ENABLE
-- ============================================================
ALTER TABLE forum_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_follows ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES (idempotent — drop then create)
-- ============================================================

-- ── forum_categories ──
DROP POLICY IF EXISTS "Anyone can view active categories" ON forum_categories;
CREATE POLICY "Anyone can view active categories"
  ON forum_categories FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage categories" ON forum_categories;
CREATE POLICY "Admins can manage categories"
  ON forum_categories FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ── forum_posts ──
DROP POLICY IF EXISTS "Anyone can read approved posts" ON forum_posts;
CREATE POLICY "Anyone can read approved posts"
  ON forum_posts FOR SELECT
  USING (status = 'approved' OR auth.uid() = author_id);

DROP POLICY IF EXISTS "Authenticated users can create posts" ON forum_posts;
CREATE POLICY "Authenticated users can create posts"
  ON forum_posts FOR INSERT
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can update own posts" ON forum_posts;
CREATE POLICY "Authors can update own posts"
  ON forum_posts FOR UPDATE
  USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Admins can moderate all posts" ON forum_posts;
CREATE POLICY "Admins can moderate all posts"
  ON forum_posts FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ── forum_replies ──
DROP POLICY IF EXISTS "Anyone can read approved replies" ON forum_replies;
CREATE POLICY "Anyone can read approved replies"
  ON forum_replies FOR SELECT
  USING (status = 'approved' OR auth.uid() = author_id);

DROP POLICY IF EXISTS "Authenticated users can create replies" ON forum_replies;
CREATE POLICY "Authenticated users can create replies"
  ON forum_replies FOR INSERT
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can update own replies" ON forum_replies;
CREATE POLICY "Authors can update own replies"
  ON forum_replies FOR UPDATE
  USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Admins can moderate all replies" ON forum_replies;
CREATE POLICY "Admins can moderate all replies"
  ON forum_replies FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ── forum_reports ──
DROP POLICY IF EXISTS "Authenticated users can create reports" ON forum_reports;
CREATE POLICY "Authenticated users can create reports"
  ON forum_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Users can view own reports" ON forum_reports;
CREATE POLICY "Users can view own reports"
  ON forum_reports FOR SELECT
  USING (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Admins can manage all reports" ON forum_reports;
CREATE POLICY "Admins can manage all reports"
  ON forum_reports FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ── forum_saves ──
DROP POLICY IF EXISTS "Users can manage own saves" ON forum_saves;
CREATE POLICY "Users can manage own saves"
  ON forum_saves FOR ALL
  USING (auth.uid() = user_id);

-- ── forum_follows ──
DROP POLICY IF EXISTS "Users can manage own follows" ON forum_follows;
CREATE POLICY "Users can manage own follows"
  ON forum_follows FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE forum_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE forum_replies;

-- ============================================================
-- SEED: Default Forum Categories
-- ============================================================
INSERT INTO forum_categories (name, description, icon_name, is_active) VALUES
  ('General Health', 'Discuss general health topics, tips, and lifestyle', 'heart_pulse', true),
  ('Mental Health', 'Support and discussions about mental well-being', 'brain', true),
  ('Nutrition & Diet', 'Questions about food, nutrition, and dietary plans', 'apple', true),
  ('Pregnancy & Parenting', 'Pregnancy, childcare, and parenting discussions', 'baby', true),
  ('Chronic Conditions', 'Managing diabetes, hypertension, and other long-term conditions', 'activity', true),
  ('Medications & Drugs', 'Questions about prescriptions, OTC drugs, and side effects', 'pill', true),
  ('Fitness & Exercise', 'Workout routines, sports injuries, and physical therapy', 'dumbbell', true),
  ('Ask a Doctor', 'Get verified answers from licensed practitioners', 'stethoscope', true)
ON CONFLICT DO NOTHING;
