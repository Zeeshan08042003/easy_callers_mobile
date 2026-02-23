-- ============================================
-- Easy Callers - Projects System Migration
-- Adds project management with invitation system
-- ============================================

-- ============================================
-- 1. PROJECTS TABLE
-- A project is a container for lead batches/leads.
-- Can be created by Super Admin or Manager.
-- ============================================
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  subtitle TEXT,
  instruction TEXT,
  -- Creator references (polymorphic)
  created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  created_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  -- Exactly one creator must be set
  CONSTRAINT one_project_creator CHECK (
    ((created_by_super_admin_id IS NOT NULL)::int + 
     (created_by_manager_id IS NOT NULL)::int) = 1
  )
);

-- ============================================
-- 2. PROJECT MEMBERS TABLE
-- Links managers to projects with invitation flow.
-- ============================================
CREATE TABLE IF NOT EXISTS public.project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE NOT NULL,
  -- 'owner' = the manager who created the project, 'member' = invited manager
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  -- Invitation status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  -- Manager can toggle this to share their project with super admin
  visible_to_super_admin BOOLEAN DEFAULT false,
  -- Who invited this manager
  invited_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  invited_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  -- A manager can only be in a project once
  UNIQUE(project_id, manager_id)
);

-- ============================================
-- 3. ADD project_id TO lead_batches
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'lead_batches' 
    AND column_name = 'project_id'
  ) THEN
    ALTER TABLE public.lead_batches 
      ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================
-- 4. ADD project_id TO leads
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'leads' 
    AND column_name = 'project_id'
  ) THEN
    ALTER TABLE public.leads 
      ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================
-- 5. INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_projects_created_by_sa ON public.projects(created_by_super_admin_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_by_mgr ON public.projects(created_by_manager_id);
CREATE INDEX IF NOT EXISTS idx_project_members_project ON public.project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_manager ON public.project_members(manager_id);
CREATE INDEX IF NOT EXISTS idx_project_members_status ON public.project_members(status);
CREATE INDEX IF NOT EXISTS idx_lead_batches_project ON public.lead_batches(project_id);
CREATE INDEX IF NOT EXISTS idx_leads_project ON public.leads(project_id);

-- ============================================
-- 6. TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
CREATE TRIGGER update_projects_updated_at 
  BEFORE UPDATE ON public.projects 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_project_members_updated_at ON public.project_members;
CREATE TRIGGER update_project_members_updated_at 
  BEFORE UPDATE ON public.project_members 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. ADD invitation notification types
-- ============================================
-- Update the notifications type check constraint to include new types
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check CHECK (
  type IN (
    'follow_up_reminder', 'lead_assigned', 'report_ready',
    'otp', 'general', 'super_admin_change', 'lead_reassigned',
    'employee_deactivated',
    -- New project-related types
    'project_invitation', 'project_invitation_accepted', 'project_invitation_declined'
  )
);

-- ============================================
-- 8. HELPER FUNCTIONS (SECURITY DEFINER = bypasses RLS)
-- These break the circular dependency between projects ↔ project_members
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_manager_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.managers WHERE auth_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_my_super_admin_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.super_admins WHERE auth_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_my_member_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT pm.project_id 
  FROM public.project_members pm
  WHERE pm.manager_id = public.get_my_manager_id();
$$;

CREATE OR REPLACE FUNCTION public.get_my_created_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.projects 
  WHERE created_by_manager_id = public.get_my_manager_id();
$$;

CREATE OR REPLACE FUNCTION public.get_my_sa_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.projects 
  WHERE created_by_super_admin_id = public.get_my_super_admin_id();
$$;

CREATE OR REPLACE FUNCTION public.get_visible_to_sa_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT pm.project_id 
  FROM public.project_members pm
  WHERE pm.visible_to_super_admin = true 
    AND pm.status = 'accepted';
$$;

-- ============================================
-- 9. ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 10. RLS POLICIES: PROJECTS
-- ============================================

DROP POLICY IF EXISTS "sa_view_projects" ON public.projects;
CREATE POLICY "sa_view_projects" ON public.projects
  FOR SELECT USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
    OR id IN (SELECT public.get_visible_to_sa_project_ids())
  );

DROP POLICY IF EXISTS "sa_insert_projects" ON public.projects;
CREATE POLICY "sa_insert_projects" ON public.projects
  FOR INSERT WITH CHECK (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

DROP POLICY IF EXISTS "sa_update_projects" ON public.projects;
CREATE POLICY "sa_update_projects" ON public.projects
  FOR UPDATE USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

DROP POLICY IF EXISTS "sa_delete_projects" ON public.projects;
CREATE POLICY "sa_delete_projects" ON public.projects
  FOR DELETE USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

DROP POLICY IF EXISTS "mgr_view_projects" ON public.projects;
CREATE POLICY "mgr_view_projects" ON public.projects
  FOR SELECT USING (
    created_by_manager_id = public.get_my_manager_id()
    OR id IN (SELECT public.get_my_member_project_ids())
  );

DROP POLICY IF EXISTS "mgr_insert_projects" ON public.projects;
CREATE POLICY "mgr_insert_projects" ON public.projects
  FOR INSERT WITH CHECK (
    created_by_manager_id = public.get_my_manager_id()
  );

DROP POLICY IF EXISTS "mgr_update_projects" ON public.projects;
CREATE POLICY "mgr_update_projects" ON public.projects
  FOR UPDATE USING (
    created_by_manager_id = public.get_my_manager_id()
  );

-- ============================================
-- 11. RLS POLICIES: PROJECT MEMBERS
-- ============================================

DROP POLICY IF EXISTS "sa_all_project_members" ON public.project_members;
CREATE POLICY "sa_all_project_members" ON public.project_members
  FOR ALL USING (
    project_id IN (SELECT public.get_my_sa_project_ids())
  );

DROP POLICY IF EXISTS "mgr_view_own_membership" ON public.project_members;
CREATE POLICY "mgr_view_own_membership" ON public.project_members
  FOR SELECT USING (
    manager_id = public.get_my_manager_id()
  );

DROP POLICY IF EXISTS "mgr_update_own_membership" ON public.project_members;
CREATE POLICY "mgr_update_own_membership" ON public.project_members
  FOR UPDATE USING (
    manager_id = public.get_my_manager_id()
  );

DROP POLICY IF EXISTS "mgr_manage_own_project_members" ON public.project_members;
CREATE POLICY "mgr_manage_own_project_members" ON public.project_members
  FOR ALL USING (
    project_id IN (SELECT public.get_my_created_project_ids())
  );

-- ============================================
-- 12. Update lead_batches RLS to include project access
-- ============================================
DROP POLICY IF EXISTS "mgr_project_batches" ON public.lead_batches;
CREATE POLICY "mgr_project_batches" ON public.lead_batches
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );

-- ============================================
-- 13. Update leads RLS to include project access
-- ============================================
DROP POLICY IF EXISTS "mgr_project_leads" ON public.leads;
CREATE POLICY "mgr_project_leads" ON public.leads
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );
