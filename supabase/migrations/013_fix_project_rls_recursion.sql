-- ============================================
-- Fix: Infinite recursion in project RLS policies
-- 
-- Problem: projects policies reference project_members,
--          project_members policies reference projects → loop
--
-- Solution: Use SECURITY DEFINER functions to bypass RLS
--           when doing cross-table checks.
-- ============================================

-- ============================================
-- 1. Helper functions (SECURITY DEFINER = bypasses RLS)
-- ============================================

-- Get the current user's manager record ID
CREATE OR REPLACE FUNCTION public.get_my_manager_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.managers WHERE auth_id = auth.uid() LIMIT 1;
$$;

-- Get the current user's super admin record ID
CREATE OR REPLACE FUNCTION public.get_my_super_admin_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.super_admins WHERE auth_id = auth.uid() LIMIT 1;
$$;

-- Get project IDs where the current manager is a member (bypasses RLS on project_members)
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

-- Get project IDs created by the current manager (bypasses RLS on projects)
CREATE OR REPLACE FUNCTION public.get_my_created_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.projects 
  WHERE created_by_manager_id = public.get_my_manager_id();
$$;

-- Get project IDs created by the current super admin (bypasses RLS on projects)
CREATE OR REPLACE FUNCTION public.get_my_sa_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.projects 
  WHERE created_by_super_admin_id = public.get_my_super_admin_id();
$$;

-- Get project IDs visible to super admin (bypasses RLS on project_members)
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
-- 2. DROP all existing project policies
-- ============================================

-- Projects table
DROP POLICY IF EXISTS "sa_view_projects" ON public.projects;
DROP POLICY IF EXISTS "sa_insert_projects" ON public.projects;
DROP POLICY IF EXISTS "sa_update_projects" ON public.projects;
DROP POLICY IF EXISTS "sa_delete_projects" ON public.projects;
DROP POLICY IF EXISTS "mgr_view_projects" ON public.projects;
DROP POLICY IF EXISTS "mgr_insert_projects" ON public.projects;
DROP POLICY IF EXISTS "mgr_update_projects" ON public.projects;

-- Project members table
DROP POLICY IF EXISTS "sa_all_project_members" ON public.project_members;
DROP POLICY IF EXISTS "mgr_view_own_membership" ON public.project_members;
DROP POLICY IF EXISTS "mgr_update_own_membership" ON public.project_members;
DROP POLICY IF EXISTS "mgr_manage_own_project_members" ON public.project_members;

-- Lead batches / leads project policies
DROP POLICY IF EXISTS "mgr_project_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "mgr_project_leads" ON public.leads;

-- ============================================
-- 3. RECREATE POLICIES: PROJECTS (using helper functions)
-- ============================================

-- Super Admin can see their own projects + visible-to-SA projects
CREATE POLICY "sa_view_projects" ON public.projects
  FOR SELECT USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
    OR id IN (SELECT public.get_visible_to_sa_project_ids())
  );

-- Super Admin can create projects
CREATE POLICY "sa_insert_projects" ON public.projects
  FOR INSERT WITH CHECK (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

-- Super Admin can update their own projects
CREATE POLICY "sa_update_projects" ON public.projects
  FOR UPDATE USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

-- Super Admin can delete their own projects
CREATE POLICY "sa_delete_projects" ON public.projects
  FOR DELETE USING (
    created_by_super_admin_id = public.get_my_super_admin_id()
  );

-- Manager can see projects they created OR are a member of
-- Uses SECURITY DEFINER function to read project_members WITHOUT triggering its RLS
CREATE POLICY "mgr_view_projects" ON public.projects
  FOR SELECT USING (
    created_by_manager_id = public.get_my_manager_id()
    OR id IN (SELECT public.get_my_member_project_ids())
  );

-- Manager can create projects
CREATE POLICY "mgr_insert_projects" ON public.projects
  FOR INSERT WITH CHECK (
    created_by_manager_id = public.get_my_manager_id()
  );

-- Manager can update their own projects
CREATE POLICY "mgr_update_projects" ON public.projects
  FOR UPDATE USING (
    created_by_manager_id = public.get_my_manager_id()
  );

-- ============================================
-- 4. RECREATE POLICIES: PROJECT MEMBERS (using helper functions)
-- ============================================

-- Super Admin can manage members of their own projects
-- Uses SECURITY DEFINER function to read projects WITHOUT triggering its RLS
CREATE POLICY "sa_all_project_members" ON public.project_members
  FOR ALL USING (
    project_id IN (SELECT public.get_my_sa_project_ids())
  );

-- Manager can view their own membership records
CREATE POLICY "mgr_view_own_membership" ON public.project_members
  FOR SELECT USING (
    manager_id = public.get_my_manager_id()
  );

-- Manager can update their own membership (accept/decline, toggle visibility)
CREATE POLICY "mgr_update_own_membership" ON public.project_members
  FOR UPDATE USING (
    manager_id = public.get_my_manager_id()
  );

-- Manager can manage members of projects they created
-- Uses SECURITY DEFINER function to read projects WITHOUT triggering its RLS
CREATE POLICY "mgr_manage_own_project_members" ON public.project_members
  FOR ALL USING (
    project_id IN (SELECT public.get_my_created_project_ids())
  );

-- ============================================
-- 5. RECREATE POLICIES: LEAD BATCHES & LEADS (project access)
-- ============================================

-- Manager can access batches in projects they belong to
CREATE POLICY "mgr_project_batches" ON public.lead_batches
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );

-- Manager can access leads in projects they belong to
CREATE POLICY "mgr_project_leads" ON public.leads
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );
