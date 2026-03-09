-- ============================================
-- 027: Fix project visibility for pending invitations
-- ============================================
-- 
-- PROBLEM:
--   When a Super Admin invites a Manager to a project, the invitation
--   row in project_members is visible to the manager (via mgr_pm_select),
--   but the PROJECT itself is invisible because mgr_projects_select only
--   includes projects where status = 'accepted' (via get_my_member_project_ids).
--   This causes the invitation to appear with null project name.
--
-- SOLUTION:
--   Add a helper function that returns project IDs where the manager
--   has ANY membership (pending, accepted, declined), and update the
--   projects SELECT policy to include pending invitation projects.
-- ============================================

-- 1. New helper: returns project IDs where manager has any membership status
CREATE OR REPLACE FUNCTION public.get_my_all_member_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT pm.project_id
  FROM public.project_members pm
  WHERE pm.manager_id = public.get_my_manager_id();
$$;

-- 2. Update the projects SELECT policy for managers
--    Now includes projects with pending invitations (not just accepted)
DROP POLICY IF EXISTS "mgr_projects_select" ON public.projects;
CREATE POLICY "mgr_projects_select" ON public.projects FOR SELECT
  USING (
    created_by_manager_id = public.get_my_manager_id()
    OR id IN (SELECT public.get_my_all_member_project_ids())
  );
