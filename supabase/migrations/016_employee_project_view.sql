-- ============================================
-- Employee Project View Access
-- Allows employees to see projects they are assigned to
-- ============================================

-- Get the current user's employee record ID
CREATE OR REPLACE FUNCTION public.get_my_employee_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.employees WHERE auth_id = auth.uid() LIMIT 1;
$$;

-- Get project IDs where the current employee is a caller
CREATE OR REPLACE FUNCTION public.get_my_assigned_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT pc.project_id 
  FROM public.project_callers pc
  WHERE pc.employee_id = public.get_my_employee_id();
$$;

-- Employee can view callers in their assigned projects (optional but good for consistency)
DROP POLICY IF EXISTS "emp_view_project_callers" ON public.project_callers;
CREATE POLICY "emp_view_project_callers" ON public.project_callers
  FOR SELECT USING (
    employee_id = public.get_my_employee_id()
  );

-- Employee can see projects they are assigned to
DROP POLICY IF EXISTS "emp_view_projects" ON public.projects;
CREATE POLICY "emp_view_projects" ON public.projects
  FOR SELECT USING (
    id IN (SELECT public.get_my_assigned_project_ids())
  );
