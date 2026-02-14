-- ============================================
-- SAFE RE-RUN: Drop existing objects first, then recreate
-- Paste this ENTIRE script in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: DROP EXISTING TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_leads_updated_at ON public.leads;

-- ============================================
-- STEP 2: DROP EXISTING RLS POLICIES (safe - won't error if missing)
-- ============================================
-- Users policies
DROP POLICY IF EXISTS "super_admin_all_users" ON public.users;
DROP POLICY IF EXISTS "manager_see_team" ON public.users;
DROP POLICY IF EXISTS "manager_insert_employee" ON public.users;
DROP POLICY IF EXISTS "manager_update_employee" ON public.users;
DROP POLICY IF EXISTS "employee_see_self" ON public.users;
DROP POLICY IF EXISTS "employee_update_self" ON public.users;

-- Leads policies
DROP POLICY IF EXISTS "super_admin_all_leads" ON public.leads;
DROP POLICY IF EXISTS "manager_leads" ON public.leads;
DROP POLICY IF EXISTS "employee_see_assigned_leads" ON public.leads;
DROP POLICY IF EXISTS "employee_update_assigned_leads" ON public.leads;

-- Lead batches policies  
DROP POLICY IF EXISTS "super_admin_all_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "manager_own_batches" ON public.lead_batches;

-- Call logs policies
DROP POLICY IF EXISTS "super_admin_all_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "manager_team_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "employee_own_call_logs" ON public.call_logs;

-- Daily reports policies
DROP POLICY IF EXISTS "super_admin_all_reports" ON public.daily_reports;
DROP POLICY IF EXISTS "manager_team_reports" ON public.daily_reports;
DROP POLICY IF EXISTS "employee_own_reports" ON public.daily_reports;

-- Notifications policies
DROP POLICY IF EXISTS "user_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "super_admin_all_notifications" ON public.notifications;

-- Activity log policies
DROP POLICY IF EXISTS "super_admin_activity_log" ON public.activity_log;
DROP POLICY IF EXISTS "manager_own_activity" ON public.activity_log;

-- Storage policies
DROP POLICY IF EXISTS "manager_upload_files" ON storage.objects;
DROP POLICY IF EXISTS "manager_read_files" ON storage.objects;

-- ============================================
-- STEP 3: CREATE EXTENSION
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 4: CREATE TABLES (IF NOT EXISTS - safe)
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'manager', 'employee')),
  manager_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT false,
  otp_code TEXT,
  otp_expires_at TIMESTAMPTZ,
  profile_image_url TEXT,
  max_employees INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.lead_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name TEXT NOT NULL,
  file_url TEXT,
  total_leads INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  location TEXT,
  project_name TEXT,
  budget TEXT,
  source TEXT,
  notes TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN (
    'new', 'assigned', 'connected', 'not_connected',
    'interested', 'not_interested', 'follow_up',
    'converted', 'closed'
  )),
  uploaded_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
  batch_id UUID REFERENCES public.lead_batches(id) ON DELETE SET NULL,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.call_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  call_status TEXT CHECK (call_status IN (
    'connected', 'not_connected', 'busy',
    'switched_off', 'wrong_number', 'not_reachable'
  )),
  call_duration TEXT,
  call_duration_seconds INTEGER DEFAULT 0,
  lead_status TEXT CHECK (lead_status IN (
    'interested', 'not_interested', 'follow_up',
    'callback', 'converted', 'closed'
  )),
  feedback TEXT,
  follow_up_date TIMESTAMPTZ,
  follow_up_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.daily_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  report_date DATE NOT NULL,
  total_calls INTEGER DEFAULT 0,
  connected_calls INTEGER DEFAULT 0,
  not_connected_calls INTEGER DEFAULT 0,
  interested_leads INTEGER DEFAULT 0,
  not_interested_leads INTEGER DEFAULT 0,
  follow_ups_scheduled INTEGER DEFAULT 0,
  avg_call_duration_seconds INTEGER DEFAULT 0,
  total_call_duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, report_date)
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT CHECK (type IN (
    'follow_up_reminder', 'lead_assigned', 'report_ready',
    'otp', 'general', 'super_admin_change', 'lead_reassigned',
    'employee_deactivated'
  )),
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  performed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add extra_data column if it doesn't exist already
ALTER TABLE public.leads ADD COLUMN IF NOT EXISTS extra_data JSONB DEFAULT '{}'::jsonb;

-- ============================================
-- STEP 5: INDEXES (IF NOT EXISTS - safe)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_manager_id ON public.users(manager_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON public.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_leads_assigned_to ON public.leads(assigned_to);
CREATE INDEX IF NOT EXISTS idx_leads_uploaded_by ON public.leads(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_leads_batch_id ON public.leads(batch_id);
CREATE INDEX IF NOT EXISTS idx_leads_status ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_call_logs_lead_id ON public.call_logs(lead_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_employee_id ON public.call_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_created_at ON public.call_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_daily_reports_employee_date ON public.daily_reports(employee_id, report_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_activity_log_performed_by ON public.activity_log(performed_by);

-- ============================================
-- STEP 6: TRIGGER FUNCTION + TRIGGERS (dropped first, so safe to create)
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at
  BEFORE UPDATE ON public.leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 7: ENABLE RLS
-- ============================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 8: RLS POLICIES (dropped first, so safe to create)
-- ============================================

-- USERS
CREATE POLICY "super_admin_all_users" ON public.users
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_see_team" ON public.users
  FOR SELECT USING (
    auth_id = auth.uid()
    OR manager_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager')
  );

CREATE POLICY "manager_insert_employee" ON public.users
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'manager')
    AND role = 'employee'
  );

CREATE POLICY "manager_update_employee" ON public.users
  FOR UPDATE USING (
    manager_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager')
  );

CREATE POLICY "employee_see_self" ON public.users
  FOR SELECT USING (auth_id = auth.uid());

CREATE POLICY "employee_update_self" ON public.users
  FOR UPDATE USING (auth_id = auth.uid());

-- LEADS
CREATE POLICY "super_admin_all_leads" ON public.leads
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_leads" ON public.leads
  FOR ALL USING (
    uploaded_by IN (SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager')
    OR assigned_to IN (
      SELECT id FROM public.users WHERE manager_id IN (
        SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
      )
    )
  );

CREATE POLICY "employee_see_assigned_leads" ON public.leads
  FOR SELECT USING (
    assigned_to IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "employee_update_assigned_leads" ON public.leads
  FOR UPDATE USING (
    assigned_to IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- LEAD BATCHES
CREATE POLICY "super_admin_all_batches" ON public.lead_batches
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_own_batches" ON public.lead_batches
  FOR ALL USING (
    uploaded_by IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- CALL LOGS
CREATE POLICY "super_admin_all_call_logs" ON public.call_logs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_team_call_logs" ON public.call_logs
  FOR SELECT USING (
    employee_id IN (
      SELECT id FROM public.users WHERE manager_id IN (
        SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
      )
    )
  );

CREATE POLICY "employee_own_call_logs" ON public.call_logs
  FOR ALL USING (
    employee_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- DAILY REPORTS
CREATE POLICY "super_admin_all_reports" ON public.daily_reports
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_team_reports" ON public.daily_reports
  FOR SELECT USING (
    employee_id IN (
      SELECT id FROM public.users WHERE manager_id IN (
        SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
      )
    )
  );

CREATE POLICY "employee_own_reports" ON public.daily_reports
  FOR SELECT USING (
    employee_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- NOTIFICATIONS
CREATE POLICY "user_own_notifications" ON public.notifications
  FOR ALL USING (
    user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "super_admin_all_notifications" ON public.notifications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

-- ACTIVITY LOG
CREATE POLICY "super_admin_activity_log" ON public.activity_log
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id = auth.uid() AND u.role = 'super_admin')
  );

CREATE POLICY "manager_own_activity" ON public.activity_log
  FOR SELECT USING (
    performed_by IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- ============================================
-- STEP 9: STORAGE BUCKET
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('lead-files', 'lead-files', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "manager_upload_files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'lead-files'
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role IN ('super_admin', 'manager')
    )
  );

CREATE POLICY "manager_read_files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'lead-files'
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role IN ('super_admin', 'manager')
    )
  );

-- ============================================
-- DONE! All tables, indexes, triggers, RLS policies, and storage bucket are set up.
-- ============================================
