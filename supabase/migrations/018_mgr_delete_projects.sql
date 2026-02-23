-- Diagnostics for delete project
DO $$
BEGIN
  -- Double check super admin delete policies
  DROP POLICY IF EXISTS "sa_delete_projects" ON public.projects;
  CREATE POLICY "sa_delete_projects" ON public.projects
    FOR DELETE USING (
      created_by_super_admin_id = public.get_my_super_admin_id()
    );

  -- Double check manager delete policies
  DROP POLICY IF EXISTS "mgr_delete_projects" ON public.projects;
  CREATE POLICY "mgr_delete_projects" ON public.projects
    FOR DELETE USING (
      created_by_manager_id = public.get_my_manager_id()
    );

END $$;
