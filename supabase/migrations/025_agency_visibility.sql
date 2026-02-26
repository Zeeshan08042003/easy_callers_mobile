-- ============================================
-- Easy Callers - Agency & Manager Visibility Migration
-- Ensures managers can see each other within projects and agencies are visible to others
-- ============================================

-- 1. Update Project Members RLS
-- Managers should be able to see all members of projects they are part of
DROP POLICY IF EXISTS "mgr_view_project_members" ON public.project_members;
CREATE POLICY "mgr_view_project_members" ON public.project_members
  FOR SELECT USING (
    manager_id = public.get_my_manager_id() -- See self
    OR project_id IN (SELECT public.get_my_member_project_ids()) -- See fellow members
    OR project_id IN (SELECT public.get_my_created_project_ids()) -- See members in projects I created
  );

-- 2. Update Managers RLS
-- Managers should be able to see other managers if they are in the same project
DROP POLICY IF EXISTS "mgr_view_collaborators" ON public.managers;
CREATE POLICY "mgr_view_collaborators" ON public.managers
  FOR SELECT USING (
    -- See self
    auth_id = auth.uid()
    -- See other managers who are in my network (same projects)
    OR id IN (
      SELECT pm.manager_id 
      FROM public.project_members pm 
      WHERE pm.project_id IN (SELECT public.get_my_member_project_ids())
    )
    -- See all agencies (independent ones) for collaboration and invitation
    OR manager_type = 'agency'
  );

-- 3. Update Employees RLS (if needed)
-- Managers in the same project should be able to see employees assigned to that project
-- This is already partially handled by mgr_own_employees, but we might need broader access for project collaboration
CREATE POLICY "mgr_view_project_employees" ON public.employees
  FOR SELECT USING (
    id IN (
      SELECT pc.employee_id 
      FROM public.project_callers pc
      WHERE pc.project_id IN (SELECT public.get_my_member_project_ids())
    )
  );

-- Note: SAs already have "super_admin_access_all" which covers everything.
