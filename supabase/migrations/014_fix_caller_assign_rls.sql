-- ============================================
-- 1. Allow managers to see their callers and assign them to any project they belong to
-- ============================================

-- Ensure managers can update project_members to accept invites
DROP POLICY IF EXISTS "mgr_update_own_membership" ON public.project_members;
CREATE POLICY "mgr_update_own_membership" ON public.project_members
  FOR UPDATE USING (
    manager_id = public.get_my_manager_id()
  );

-- Managers can ONLY see their own membership if Super Admin created it
-- UNLESS they are the creator of the project, then they see all members
DROP POLICY IF EXISTS "mgr_view_members" ON public.project_members;
CREATE POLICY "mgr_view_members" ON public.project_members
  FOR SELECT USING (
    manager_id = public.get_my_manager_id() OR
    project_id IN (SELECT public.get_my_created_project_ids())
  );

-- Drop previous conflicting policies
DROP POLICY IF EXISTS "mgr_view_own_membership" ON public.project_members;
DROP POLICY IF EXISTS "mgr_manage_own_project_members" ON public.project_members;

-- Project Callers (Employees)
-- Managers can add their employees to ANY project they are a member of
DROP POLICY IF EXISTS "mgr_manage_project_callers" ON public.project_callers;
CREATE POLICY "mgr_manage_project_callers" ON public.project_callers
  FOR ALL USING (
    manager_id = public.get_my_manager_id() AND
    project_id IN (SELECT public.get_my_member_project_ids())
  );

-- Fix Lead Batches and Leads again
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
