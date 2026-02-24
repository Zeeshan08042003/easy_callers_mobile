-- ============================================
-- Fix: Manager access to Super Admin created projects
-- 
-- Issues fixed:
-- 1. Manager cannot upload Excel sheets to SA-created projects
-- 2. Manager should manage their own callers in any accepted project
-- 3. Super Admin must explicitly grant "can_upload" permission per manager
-- 4. Members list should be hidden from managers in SA-created projects
-- ============================================

-- ============================================
-- 1. ADD: can_upload permission column to project_members
--    Super Admin controls whether a manager can upload Excel sheets.
--    Defaults to false (SA must explicitly grant permission).
-- ============================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'project_members' 
    AND column_name = 'can_upload'
  ) THEN
    ALTER TABLE public.project_members 
      ADD COLUMN can_upload BOOLEAN DEFAULT false;
  END IF;
END $$;

-- ============================================
-- 2. FIX: lead_batches RLS for Manager INSERT
--    USING = applies to SELECT/UPDATE/DELETE
--    WITH CHECK = applies to INSERT
-- ============================================

DROP POLICY IF EXISTS "mgr_project_batches" ON public.lead_batches;
CREATE POLICY "mgr_project_batches" ON public.lead_batches
  FOR ALL
  USING (
    uploaded_by = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_member_project_ids())
  )
  WITH CHECK (
    uploaded_by = public.get_my_manager_id()
    AND project_id IN (SELECT public.get_my_member_project_ids())
  );

-- ============================================
-- 3. FIX: leads RLS for Manager INSERT
-- ============================================

DROP POLICY IF EXISTS "mgr_project_leads" ON public.leads;
CREATE POLICY "mgr_project_leads" ON public.leads
  FOR ALL
  USING (
    uploaded_by = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_member_project_ids())
  )
  WITH CHECK (
    uploaded_by = public.get_my_manager_id()
    AND project_id IN (SELECT public.get_my_member_project_ids())
  );

-- ============================================
-- 4. FIX: project_callers RLS
--    Manager can add/remove their own employees to any project they belong to
-- ============================================

DROP POLICY IF EXISTS "mgr_manage_project_callers" ON public.project_callers;
DROP POLICY IF EXISTS "mgr_view_project_callers" ON public.project_callers;

CREATE POLICY "mgr_manage_project_callers" ON public.project_callers
  FOR ALL
  USING (
    added_by_manager_id = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_member_project_ids())
  )
  WITH CHECK (
    added_by_manager_id = public.get_my_manager_id()
    AND project_id IN (SELECT public.get_my_member_project_ids())
  );

-- ============================================
-- 5. FIX: project_members SELECT for manager
--    Manager sees only their own membership row
--    Plus all members for projects they created
-- ============================================

DROP POLICY IF EXISTS "mgr_view_members" ON public.project_members;
DROP POLICY IF EXISTS "mgr_view_own_membership" ON public.project_members;

CREATE POLICY "mgr_view_members" ON public.project_members
  FOR SELECT USING (
    manager_id = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_created_project_ids())
  );

-- ============================================
-- 6. FIX: get_my_member_project_ids only for ACCEPTED memberships
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_member_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT pm.project_id 
  FROM public.project_members pm
  WHERE pm.manager_id = public.get_my_manager_id()
    AND pm.status = 'accepted';
$$;
