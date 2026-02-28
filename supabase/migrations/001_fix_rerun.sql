-- ============================================
-- EASY CALLERS - MASTER CONSOLIDATED SCHEMA
-- This script flushes and recreates the entire database schema
-- Use this for a clean database recreation.
-- ============================================

-- ============================================
-- STEP 1: CLEANUP EVERYTHING
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all triggers
    FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public') LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || r.trigger_name || ' ON ' || r.event_object_table;
    END LOOP;

    -- Drop all policies
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON ' || quote_ident(r.tablename);
    END LOOP;
END $$;

DROP TABLE IF EXISTS public.system_settings CASCADE;
DROP TABLE IF EXISTS public.activity_log CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.daily_reports CASCADE;
DROP TABLE IF EXISTS public.call_logs CASCADE;
DROP TABLE IF EXISTS public.leads CASCADE;
DROP TABLE IF EXISTS public.lead_statuses CASCADE;
DROP TABLE IF EXISTS public.lead_batches CASCADE;
DROP TABLE IF EXISTS public.project_callers CASCADE;
DROP TABLE IF EXISTS public.project_members CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.managers CASCADE;
DROP TABLE IF EXISTS public.super_admins CASCADE;
DROP TABLE IF EXISTS public.users CASCADE; -- Legacy table

-- ============================================
-- STEP 2: EXTENSIONS & BASIC FUNCTIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 3: ROLE TABLES
-- ============================================

-- 3.1 Super Admins
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

-- 3.2 Managers
CREATE TABLE public.managers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT false, -- Starts inactive till OTP
  max_employees INTEGER,
  manager_type TEXT DEFAULT 'manager' CHECK (manager_type IN ('manager', 'agency')),
  created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  otp_code TEXT,
  otp_expires_at TIMESTAMPTZ,
  is_sa_visible BOOLEAN DEFAULT false,
  agency_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3.3 Employees (Callers)
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
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT employees_email_lowercase_check CHECK (email = LOWER(TRIM(email)))
);

-- ============================================
-- STEP 4: PROJECTS SYSTEM
-- ============================================

CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  subtitle TEXT,
  instruction TEXT,
  caller_assignment TEXT DEFAULT 'all' CHECK (caller_assignment IN ('all', 'selected')),
  created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  created_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT one_project_creator CHECK (
    ((created_by_super_admin_id IS NOT NULL)::int + (created_by_manager_id IS NOT NULL)::int) = 1
  )
);

CREATE TABLE public.project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  visible_to_super_admin BOOLEAN DEFAULT false,
  invited_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  invited_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  can_upload BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, manager_id)
);

CREATE TABLE public.project_callers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  added_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, employee_id)
);

-- ============================================
-- STEP 5: DATA TABLES
-- ============================================

CREATE TABLE public.lead_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name TEXT NOT NULL,
  file_url TEXT,
  total_leads INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.lead_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  value TEXT NOT NULL,
  display_name TEXT NOT NULL,
  lead_status_mapping TEXT DEFAULT 'follow_up' CHECK (lead_status_mapping IN (
    'new', 'assigned', 'follow_up', 'not_interested',
    'visiting', 'visit_completed', 'converted', 'drop'
  )),
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(value, manager_id)
);

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
  status TEXT DEFAULT 'new', -- Check constraint removed to rely on dynamic statuses
  uploaded_by UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  batch_id UUID REFERENCES public.lead_batches(id) ON DELETE SET NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.call_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  call_status TEXT, -- Dynamic statuses from system
  call_duration TEXT,
  call_duration_seconds INTEGER DEFAULT 0,
  lead_status TEXT, -- Linked to lead_statuses value
  feedback TEXT,
  follow_up_date TIMESTAMPTZ,
  follow_up_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

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

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT CHECK (type IN (
    'follow_up_reminder', 'lead_assigned', 'report_ready',
    'otp', 'general', 'super_admin_change', 'lead_reassigned',
    'employee_deactivated', 'project_invitation', 
    'project_invitation_accepted', 'project_invitation_declined'
  )),
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT one_recipient_only CHECK (
    ((super_admin_id IS NOT NULL)::int + (manager_id IS NOT NULL)::int + (employee_id IS NOT NULL)::int) = 1
  )
);

CREATE TABLE public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  performer_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  performer_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  performer_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT one_performer_only CHECK (
    ((performer_super_admin_id IS NOT NULL)::int + (performer_manager_id IS NOT NULL)::int + (performer_employee_id IS NOT NULL)::int) = 1
  )
);

CREATE TABLE public.system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name TEXT NOT NULL DEFAULT 'Easy Callers',
  support_email TEXT,
  support_phone TEXT,
  max_leads_per_employee INTEGER DEFAULT 100,
  daily_call_target INTEGER DEFAULT 50,
  maintenance_mode BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES public.super_admins(id) ON DELETE SET NULL
);

-- ============================================
-- STEP 6: INDEXES
-- ============================================
CREATE INDEX idx_sa_auth ON public.super_admins(auth_id);
CREATE INDEX idx_mgr_auth ON public.managers(auth_id);
CREATE INDEX idx_mgr_type ON public.managers(manager_type);
CREATE INDEX idx_emp_auth ON public.employees(auth_id);
CREATE INDEX idx_emp_mgr ON public.employees(manager_id);
CREATE INDEX idx_projects_sa ON public.projects(created_by_super_admin_id);
CREATE INDEX idx_projects_mgr ON public.projects(created_by_manager_id);
CREATE INDEX idx_pm_project ON public.project_members(project_id);
CREATE INDEX idx_pm_manager ON public.project_members(manager_id);
CREATE INDEX idx_pc_project ON public.project_callers(project_id);
CREATE INDEX idx_pc_employee ON public.project_callers(employee_id);
CREATE INDEX idx_leads_batch ON public.leads(batch_id);
CREATE INDEX idx_leads_assign ON public.leads(assigned_to);
CREATE INDEX idx_leads_project ON public.leads(project_id);
CREATE INDEX idx_lead_statuses_mgr ON public.lead_statuses(manager_id);
CREATE UNIQUE INDEX idx_lead_statuses_value_global ON public.lead_statuses (value) WHERE manager_id IS NULL;

-- ============================================
-- STEP 7: TRIGGERS
-- ============================================
CREATE TRIGGER update_super_admins_updated_at BEFORE UPDATE ON public.super_admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_managers_updated_at BEFORE UPDATE ON public.managers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_project_members_updated_at BEFORE UPDATE ON public.project_members FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON public.system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7.2 Lead Assignment Notifications
CREATE OR REPLACE FUNCTION public.handle_lead_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' AND NEW.assigned_to IS NOT NULL) OR
     (TG_OP = 'UPDATE' AND NEW.assigned_to IS DISTINCT FROM OLD.assigned_to AND NEW.assigned_to IS NOT NULL) THEN
    
    INSERT INTO public.notifications (
      employee_id,
      title,
      body,
      type,
      metadata
    ) VALUES (
      NEW.assigned_to,
      'New Lead Assigned',
      'You have been assigned a new lead: ' || NEW.name,
      'lead_assigned',
      jsonb_build_object('lead_id', NEW.id, 'lead_name', NEW.name)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER tr_on_lead_assignment
AFTER INSERT OR UPDATE OF assigned_to ON public.leads
FOR EACH ROW EXECUTE FUNCTION public.handle_lead_assignment_notification();

-- ============================================
-- STEP 8: HELPER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_manager_id() RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT id FROM public.managers WHERE auth_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_my_super_admin_id() RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT id FROM public.super_admins WHERE auth_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_my_member_project_ids() RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT pm.project_id FROM public.project_members pm WHERE pm.manager_id = public.get_my_manager_id() AND pm.status = 'accepted';
$$;

CREATE OR REPLACE FUNCTION public.get_my_created_project_ids() RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT id FROM public.projects WHERE created_by_manager_id = public.get_my_manager_id();
$$;

CREATE OR REPLACE FUNCTION public.get_my_sa_project_ids() RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT id FROM public.projects WHERE created_by_super_admin_id = public.get_my_super_admin_id();
$$;

CREATE OR REPLACE FUNCTION public.get_visible_to_sa_project_ids() RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT pm.project_id FROM public.project_members pm WHERE pm.visible_to_super_admin = true AND pm.status = 'accepted';
$$;

CREATE OR REPLACE FUNCTION public.get_employee_for_otp(input_email TEXT) RETURNS SETOF public.employees LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.employees WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email));
END;
$$;

CREATE OR REPLACE FUNCTION public.get_manager_for_otp(input_email TEXT) RETURNS SETOF public.managers LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.managers WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email));
END;
$$;

-- Activate employee: links auth_id and sets is_active (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.activate_employee(
  input_email TEXT,
  input_auth_id UUID
) RETURNS SETOF public.employees LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.employees
  SET auth_id = input_auth_id,
      is_active = true,
      otp_code = NULL,
      otp_expires_at = NULL
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND auth_id IS NULL;

  RETURN QUERY SELECT * FROM public.employees WHERE auth_id = input_auth_id LIMIT 1;
END;
$$;

-- Activate manager: links auth_id and sets is_active (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.activate_manager(
  input_email TEXT,
  input_auth_id UUID
) RETURNS SETOF public.managers LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.managers
  SET auth_id = input_auth_id,
      is_active = true,
      otp_code = NULL,
      otp_expires_at = NULL
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND auth_id IS NULL;

  RETURN QUERY SELECT * FROM public.managers WHERE auth_id = input_auth_id LIMIT 1;
END;
$$;


-- ============================================
-- STEP 9: DEFAULT DATA
-- ============================================
INSERT INTO public.lead_statuses (value, display_name, lead_status_mapping) VALUES
('follow_up', 'Follow Up', 'follow_up'),
('not_interested', 'Not Interested', 'not_interested'),
('visiting', 'Visiting', 'visiting'),
('visit_completed', 'Visit Completed', 'visit_completed'),
('converted', 'Converted', 'converted'),
('drop', 'Drop', 'drop')
ON CONFLICT DO NOTHING;

INSERT INTO public.system_settings (company_name, support_email)
VALUES ('Easy Callers', 'support@easycallers.com')
ON CONFLICT DO NOTHING;

-- ============================================
-- STEP 10: RLS POLICIES
-- ============================================
-- DESIGN PRINCIPLES:
--   1. Super Admin = god mode (simple EXISTS check on all tables)
--   2. Manager = scoped to own data + member projects
--   3. Employee = scoped to own assigned leads only
--   4. FOR ALL replaced with per-operation policies where INSERT needs WITH CHECK
--   5. SECURITY DEFINER helper functions bypass RLS for lookups

ALTER TABLE public.super_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_callers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10.1 SUPER ADMIN (Full bypass on everything)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE POLICY "sa_full_access" ON public.super_admins FOR ALL
  USING (auth_id = auth.uid());

CREATE POLICY "sa_manage_managers" ON public.managers FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_employees" ON public.employees FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_projects" ON public.projects FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_project_members" ON public.project_members FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_project_callers" ON public.project_callers FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_leads" ON public.leads FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_batches" ON public.lead_batches FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_call_logs" ON public.call_logs FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_daily_reports" ON public.daily_reports FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_notifications" ON public.notifications FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_activity_log" ON public.activity_log FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "sa_manage_lead_statuses" ON public.lead_statuses FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10.2 MANAGER
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Self: read/update own record; email-match fallback for first-time activation
CREATE POLICY "mgr_self_select" ON public.managers FOR SELECT
  USING (auth_id = auth.uid() OR (auth_id IS NULL AND LOWER(email) = LOWER(auth.jwt() ->> 'email')));
CREATE POLICY "mgr_self_update" ON public.managers FOR UPDATE
  USING (auth_id = auth.uid() OR (auth_id IS NULL AND LOWER(email) = LOWER(auth.jwt() ->> 'email')))
  WITH CHECK (true);
-- Self-registration INSERT (independent manager)
CREATE POLICY "mgr_self_insert" ON public.managers FOR INSERT
  WITH CHECK (auth_id = auth.uid());

-- View collaborators (other managers in shared projects + agencies)
CREATE POLICY "mgr_view_collaborators" ON public.managers FOR SELECT
  USING (
    id IN (SELECT manager_id FROM public.project_members WHERE project_id IN (SELECT public.get_my_member_project_ids()))
    OR manager_type = 'agency'
  );

-- Employees: full CRUD on own team
CREATE POLICY "mgr_employees_select" ON public.employees FOR SELECT
  USING (manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_employees_insert" ON public.employees FOR INSERT
  WITH CHECK (manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_employees_update" ON public.employees FOR UPDATE
  USING (manager_id = public.get_my_manager_id())
  WITH CHECK (manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_employees_delete" ON public.employees FOR DELETE
  USING (manager_id = public.get_my_manager_id());

-- Projects: see own + member projects
CREATE POLICY "mgr_projects_select" ON public.projects FOR SELECT
  USING (created_by_manager_id = public.get_my_manager_id() OR id IN (SELECT public.get_my_member_project_ids()));
CREATE POLICY "mgr_projects_insert" ON public.projects FOR INSERT
  WITH CHECK (created_by_manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_projects_update" ON public.projects FOR UPDATE
  USING (created_by_manager_id = public.get_my_manager_id())
  WITH CHECK (created_by_manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_projects_delete" ON public.projects FOR DELETE
  USING (created_by_manager_id = public.get_my_manager_id());

-- Project Members: manage own created projects + see own memberships
CREATE POLICY "mgr_pm_select" ON public.project_members FOR SELECT
  USING (project_id IN (SELECT public.get_my_created_project_ids()) OR manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_pm_insert" ON public.project_members FOR INSERT
  WITH CHECK (project_id IN (SELECT public.get_my_created_project_ids()));
CREATE POLICY "mgr_pm_update" ON public.project_members FOR UPDATE
  USING (project_id IN (SELECT public.get_my_created_project_ids()) OR manager_id = public.get_my_manager_id())
  WITH CHECK (true);
CREATE POLICY "mgr_pm_delete" ON public.project_members FOR DELETE
  USING (project_id IN (SELECT public.get_my_created_project_ids()));

-- Project Callers: manage callers in own projects
CREATE POLICY "mgr_pc_select" ON public.project_callers FOR SELECT
  USING (
    project_id IN (SELECT public.get_my_created_project_ids())
    OR project_id IN (SELECT public.get_my_member_project_ids())
  );
CREATE POLICY "mgr_pc_insert" ON public.project_callers FOR INSERT
  WITH CHECK (
    project_id IN (SELECT public.get_my_created_project_ids())
    OR project_id IN (SELECT public.get_my_member_project_ids())
  );
CREATE POLICY "mgr_pc_delete" ON public.project_callers FOR DELETE
  USING (
    project_id IN (SELECT public.get_my_created_project_ids())
    OR project_id IN (SELECT public.get_my_member_project_ids())
  );

-- Leads: full CRUD on own uploaded + member project leads
CREATE POLICY "mgr_leads_select" ON public.leads FOR SELECT
  USING (uploaded_by = public.get_my_manager_id() OR project_id IN (SELECT public.get_my_member_project_ids()));
CREATE POLICY "mgr_leads_insert" ON public.leads FOR INSERT
  WITH CHECK (uploaded_by = public.get_my_manager_id());
CREATE POLICY "mgr_leads_update" ON public.leads FOR UPDATE
  USING (uploaded_by = public.get_my_manager_id() OR project_id IN (SELECT public.get_my_member_project_ids()))
  WITH CHECK (true);
CREATE POLICY "mgr_leads_delete" ON public.leads FOR DELETE
  USING (uploaded_by = public.get_my_manager_id());

-- Lead Batches: full CRUD on own batches + member project batches
CREATE POLICY "mgr_batches_select" ON public.lead_batches FOR SELECT
  USING (uploaded_by = public.get_my_manager_id() OR project_id IN (SELECT public.get_my_member_project_ids()));
CREATE POLICY "mgr_batches_insert" ON public.lead_batches FOR INSERT
  WITH CHECK (uploaded_by = public.get_my_manager_id());
CREATE POLICY "mgr_batches_update" ON public.lead_batches FOR UPDATE
  USING (uploaded_by = public.get_my_manager_id())
  WITH CHECK (true);
CREATE POLICY "mgr_batches_delete" ON public.lead_batches FOR DELETE
  USING (uploaded_by = public.get_my_manager_id());

-- Lead Statuses: own custom statuses + global ones
CREATE POLICY "mgr_statuses" ON public.lead_statuses FOR ALL
  USING (manager_id = public.get_my_manager_id() OR manager_id IS NULL)
  WITH CHECK (manager_id = public.get_my_manager_id());

-- Call Logs: read call logs for own employees
CREATE POLICY "mgr_call_logs_select" ON public.call_logs FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE manager_id = public.get_my_manager_id()));

-- Daily Reports: read reports for own employees
CREATE POLICY "mgr_daily_reports_select" ON public.daily_reports FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE manager_id = public.get_my_manager_id()));

-- Notifications: own notifications
CREATE POLICY "mgr_notifications_select" ON public.notifications FOR SELECT
  USING (manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_notifications_update" ON public.notifications FOR UPDATE
  USING (manager_id = public.get_my_manager_id())
  WITH CHECK (true);

-- Activity Log: insert own activities
CREATE POLICY "mgr_activity_insert" ON public.activity_log FOR INSERT
  WITH CHECK (performer_manager_id = public.get_my_manager_id());
CREATE POLICY "mgr_activity_select" ON public.activity_log FOR SELECT
  USING (performer_manager_id = public.get_my_manager_id());

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10.3 EMPLOYEE (Caller)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Self: read/update own record; email-match fallback for OTP activation
CREATE POLICY "emp_self_select" ON public.employees FOR SELECT
  USING (auth_id = auth.uid() OR (auth_id IS NULL AND LOWER(email) = LOWER(auth.jwt() ->> 'email')));
CREATE POLICY "emp_self_update" ON public.employees FOR UPDATE
  USING (auth_id = auth.uid() OR (auth_id IS NULL AND LOWER(email) = LOWER(auth.jwt() ->> 'email')))
  WITH CHECK (true);

-- Leads: read only assigned leads that are NOT in terminal/manager-control statuses
CREATE POLICY "emp_leads_select" ON public.leads FOR SELECT
  USING (
    assigned_to IN (SELECT id FROM public.employees WHERE auth_id = auth.uid())
    AND status NOT IN ('visit_completed', 'converted', 'drop')
  );
-- Employee can update lead status (e.g., from assigned → follow_up)
CREATE POLICY "emp_leads_update" ON public.leads FOR UPDATE
  USING (
    assigned_to IN (SELECT id FROM public.employees WHERE auth_id = auth.uid())
    AND status NOT IN ('visit_completed', 'converted', 'drop')
  )
  WITH CHECK (true);

-- Call Logs: full CRUD on own calls
CREATE POLICY "emp_calls_select" ON public.call_logs FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_calls_insert" ON public.call_logs FOR INSERT
  WITH CHECK (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_calls_update" ON public.call_logs FOR UPDATE
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()))
  WITH CHECK (true);

-- Daily Reports: read own reports
CREATE POLICY "emp_reports_select" ON public.daily_reports FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_reports_insert" ON public.daily_reports FOR INSERT
  WITH CHECK (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_reports_update" ON public.daily_reports FOR UPDATE
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()))
  WITH CHECK (true);

-- Notifications: own notifications
CREATE POLICY "emp_notifications_select" ON public.notifications FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_notifications_update" ON public.notifications FOR UPDATE
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()))
  WITH CHECK (true);

-- Activity Log: insert own activities
CREATE POLICY "emp_activity_insert" ON public.activity_log FOR INSERT
  WITH CHECK (performer_employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));
CREATE POLICY "emp_activity_select" ON public.activity_log FOR SELECT
  USING (performer_employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));

-- Project Callers: employees can see which projects they are assigned to
CREATE POLICY "emp_pc_select" ON public.project_callers FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid()));

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10.4 SYSTEM SETTINGS & LEAD STATUSES (Read for all authenticated)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE POLICY "super_admin_manage_settings" ON public.system_settings FOR ALL
  USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));
CREATE POLICY "everyone_read_settings" ON public.system_settings FOR SELECT USING (true);
CREATE POLICY "everyone_read_active_statuses" ON public.lead_statuses FOR SELECT USING (is_active = true);

-- ============================================
-- STEP 11: STORAGE
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('lead-files', 'lead-files', false) ON CONFLICT (id) DO NOTHING;
CREATE POLICY "storage_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'lead-files' AND (
    EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.managers WHERE auth_id = auth.uid())
  ));
CREATE POLICY "storage_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'lead-files' AND (
    EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.managers WHERE auth_id = auth.uid())
  ));

GRANT EXECUTE ON FUNCTION public.get_employee_for_otp(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_manager_for_otp(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.activate_employee(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_manager(TEXT, UUID) TO authenticated;

ALTER TABLE public.notifications REPLICA IDENTITY FULL;

-- DONE
