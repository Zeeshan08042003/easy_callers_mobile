-- ============================================
-- Fix: Manager access to Super Admin created projects
-- 
-- Problem: Mangers can't upload sheets to projects created by Super Admins
--          because the policy "mgr_project_batches" only grants access to
--          projects they belong to, but the RLS for inserting lead_batches
--          might be failing, or the project_members logic is incomplete.
-- ============================================

-- Ensure managers can insert lead batches for ANY project they are a member of
DROP POLICY IF EXISTS "mgr_project_batches" ON public.lead_batches;
CREATE POLICY "mgr_project_batches" ON public.lead_batches
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids()) OR
    uploaded_by = public.get_my_manager_id()
  );

DROP POLICY IF EXISTS "mgr_project_leads" ON public.leads;
CREATE POLICY "mgr_project_leads" ON public.leads
  FOR ALL USING (
    project_id IN (SELECT public.get_my_member_project_ids()) OR
    uploaded_by = public.get_my_manager_id()
  );

-- Managers should see all project callers assigned to a project they are a member of
-- (to allow them to assign leads to those callers)
DROP POLICY IF EXISTS "mgr_view_project_callers" ON public.project_callers;
CREATE POLICY "mgr_view_project_callers" ON public.project_callers
  FOR SELECT USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );

