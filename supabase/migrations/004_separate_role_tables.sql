-- ============================================
-- Easy Callers - Separate Role Tables Schema (Fixed with Connections)
-- establishes explicit FK connections for notifications and activity logs
-- ============================================

-- ============================================
-- STEP 1: SAFE CLEANUP 
-- ============================================
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'super_admins') THEN
    DROP TRIGGER IF EXISTS update_super_admins_updated_at ON public.super_admins;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'managers') THEN
    DROP TRIGGER IF EXISTS update_managers_updated_at ON public.managers;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'employees') THEN
    DROP TRIGGER IF EXISTS update_employees_updated_at ON public.employees;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'leads') THEN
    DROP TRIGGER IF EXISTS update_leads_updated_at ON public.leads;
  END IF;
END $$;

-- Drop all policies
DO $$ 
DECLARE
  _tbl text;
  _pol text;
BEGIN
  FOR _tbl, _pol IN 
    SELECT schemaname || '.' || tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %s', _pol, _tbl);
  END LOOP;
END $$;

DROP TABLE IF EXISTS public.activity_log CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.daily_reports CASCADE;
DROP TABLE IF EXISTS public.call_logs CASCADE;
DROP TABLE IF EXISTS public.leads CASCADE;
DROP TABLE IF EXISTS public.lead_batches CASCADE;
DROP TABLE IF EXISTS public.super_admins CASCADE;
DROP TABLE IF EXISTS public.managers CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Enable UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. SUPER ADMINS TABLE
-- ============================================
CREATE TABLE public.super_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. MANAGERS TABLE
-- ============================================
CREATE TABLE public.managers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  max_employees INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 3. EMPLOYEES TABLE
-- ============================================
CREATE TABLE public.employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT false,
  manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  otp_code TEXT,
  otp_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. LEAD BATCHES TABLE
-- ============================================
CREATE TABLE public.lead_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name TEXT NOT NULL,
  file_url TEXT,
  total_leads INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 5. LEADS TABLE
-- ============================================
CREATE TABLE public.leads (
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
  uploaded_by UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  batch_id UUID REFERENCES public.lead_batches(id) ON DELETE SET NULL,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 6. CALL LOGS TABLE
-- ============================================
CREATE TABLE public.call_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
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
-- 7. DAILY REPORTS TABLE
-- ============================================
CREATE TABLE public.daily_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
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
-- 8. NOTIFICATIONS TABLE (POLYMORPHIC FKs)
-- ============================================
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Explicit connections to each role table
  super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
  
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT CHECK (type IN (
    'follow_up_reminder', 'lead_assigned', 'report_ready',
    'otp', 'general', 'super_admin_change', 'lead_reassigned',
    'employee_deactivated'
  )),
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Ensure exactly one recipient is set
  CONSTRAINT one_recipient_only CHECK (
    ( (super_admin_id IS NOT NULL)::int + 
      (manager_id IS NOT NULL)::int + 
      (employee_id IS NOT NULL)::int ) = 1
  )
);

-- ============================================
-- 9. ACTIVITY LOG TABLE (POLYMORPHIC FKs)
-- ============================================
CREATE TABLE public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Explicit connections to the performer
  performer_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  performer_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  performer_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Ensure exactly one performer is set
  CONSTRAINT one_performer_only CHECK (
    ( (performer_super_admin_id IS NOT NULL)::int + 
      (performer_manager_id IS NOT NULL)::int + 
      (performer_employee_id IS NOT NULL)::int ) = 1
  )
);

-- ============================================
-- TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_super_admins_updated_at BEFORE UPDATE ON public.super_admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_managers_updated_at BEFORE UPDATE ON public.managers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.super_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------
-- RLS Policies: SUPER ADMINS (View everything)
-- --------------------------------------------
CREATE POLICY "super_admin_self" ON public.super_admins FOR ALL USING (auth_id = auth.uid());
CREATE POLICY "super_admin_access_all" ON public.managers FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_employees" ON public.employees FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_leads" ON public.leads FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_batches" ON public.lead_batches FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_calls" ON public.call_logs FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_reports" ON public.daily_reports FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_notifs" ON public.notifications FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "super_admin_access_activity" ON public.activity_log FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

-- --------------------------------------------
-- RLS Policies: MANAGERS
-- --------------------------------------------
CREATE POLICY "manager_self_access" ON public.managers FOR ALL USING (auth_id = auth.uid());
CREATE POLICY "manager_own_employees" ON public.employees FOR ALL USING (manager_id IN (SELECT id FROM public.managers WHERE auth_id = auth.uid()));
CREATE POLICY "manager_own_leads" ON public.leads FOR ALL USING (uploaded_by IN (SELECT id FROM public.managers WHERE auth_id = auth.uid()));
CREATE POLICY "manager_own_notifs" ON public.notifications FOR ALL USING (manager_id IN (SELECT id FROM public.managers WHERE auth_id = auth.uid()));

-- --------------------------------------------
-- RLS Policies: EMPLOYEES
-- --------------------------------------------
CREATE POLICY "employee_self_access" ON public.employees FOR ALL USING (auth_id = auth.uid());
CREATE POLICY "employee_own_leads" ON public.leads FOR SELECT USING (assigned_to IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "employee_own_notifs" ON public.notifications FOR ALL USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));

-- Storage
INSERT INTO storage.buckets (id, name, public) VALUES ('lead-files', 'lead-files', false) ON CONFLICT (id) DO NOTHING;
CREATE POLICY "storage_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'lead-files' AND (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()) OR EXISTS (SELECT 1 FROM public.managers WHERE auth_id = auth.uid())));
CREATE POLICY "storage_read" ON storage.objects FOR SELECT USING (bucket_id = 'lead-files' AND (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()) OR EXISTS (SELECT 1 FROM public.managers WHERE auth_id = auth.uid())));
