-- ============================================
-- Easy Callers - Initial Database Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension (usually already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,                              -- Links to Supabase Auth user
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
  max_employees INTEGER,                            -- Future: limit employees per plan
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. LEAD BATCHES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.lead_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name TEXT NOT NULL,
  file_url TEXT,
  total_leads INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 3. LEADS TABLE
-- ============================================
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
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. CALL LOGS TABLE
-- ============================================
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

-- ============================================
-- 5. DAILY REPORTS TABLE
-- ============================================
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

-- ============================================
-- 6. NOTIFICATIONS TABLE
-- ============================================
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

-- ============================================
-- 7. ACTIVITY LOG TABLE (Super Admin audit trail)
-- ============================================
CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  performed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,                                  -- 'user', 'lead', 'batch', etc.
  target_id UUID,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- INDEXES for performance
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
-- UPDATED_AT TRIGGER FUNCTION
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
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: USERS
-- ============================================

-- Super Admin can see all users
CREATE POLICY "super_admin_all_users" ON public.users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Manager can see themselves + their employees
CREATE POLICY "manager_see_team" ON public.users
  FOR SELECT USING (
    auth_id = auth.uid()
    OR manager_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );

-- Manager can insert employees under themselves
CREATE POLICY "manager_insert_employee" ON public.users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'manager'
    )
    AND role = 'employee'
  );

-- Manager can update their employees
CREATE POLICY "manager_update_employee" ON public.users
  FOR UPDATE USING (
    manager_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );

-- Employee can see themselves
CREATE POLICY "employee_see_self" ON public.users
  FOR SELECT USING (auth_id = auth.uid());

-- Employee can update themselves
CREATE POLICY "employee_update_self" ON public.users
  FOR UPDATE USING (auth_id = auth.uid());

-- ============================================
-- RLS POLICIES: LEADS
-- ============================================

-- Super Admin can see all leads
CREATE POLICY "super_admin_all_leads" ON public.leads
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Manager can manage leads they uploaded or that are assigned to their employees
CREATE POLICY "manager_leads" ON public.leads
  FOR ALL USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
    OR assigned_to IN (
      SELECT id FROM public.users WHERE manager_id IN (
        SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
      )
    )
  );

-- Employee can see leads assigned to them
CREATE POLICY "employee_see_assigned_leads" ON public.leads
  FOR SELECT USING (
    assigned_to IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- Employee can update leads assigned to them (status, notes)
CREATE POLICY "employee_update_assigned_leads" ON public.leads
  FOR UPDATE USING (
    assigned_to IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- ============================================
-- RLS POLICIES: LEAD BATCHES
-- ============================================

CREATE POLICY "super_admin_all_batches" ON public.lead_batches
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
  );

CREATE POLICY "manager_own_batches" ON public.lead_batches
  FOR ALL USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- ============================================
-- RLS POLICIES: CALL LOGS
-- ============================================

CREATE POLICY "super_admin_all_call_logs" ON public.call_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
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
    employee_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- ============================================
-- RLS POLICIES: DAILY REPORTS
-- ============================================

CREATE POLICY "super_admin_all_reports" ON public.daily_reports
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
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
    employee_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- ============================================
-- RLS POLICIES: NOTIFICATIONS
-- ============================================

CREATE POLICY "user_own_notifications" ON public.notifications
  FOR ALL USING (
    user_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "super_admin_all_notifications" ON public.notifications
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- ============================================
-- RLS POLICIES: ACTIVITY LOG
-- ============================================

CREATE POLICY "super_admin_activity_log" ON public.activity_log
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role = 'super_admin'
    )
  );

CREATE POLICY "manager_own_activity" ON public.activity_log
  FOR SELECT USING (
    performed_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- ============================================
-- STORAGE BUCKET for lead file uploads
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('lead-files', 'lead-files', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
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
