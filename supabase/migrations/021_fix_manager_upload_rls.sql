-- ============================================
-- Fix: Enforce can_upload permission in RLS
-- ============================================

-- Function to check if a manager can upload to a project
CREATE OR REPLACE FUNCTION public.can_current_manager_upload(p_project_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_manager_id UUID;
BEGIN
  v_manager_id := public.get_my_manager_id();
  IF v_manager_id IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.project_members
    WHERE project_id = p_project_id
      AND manager_id = v_manager_id
      AND status = 'accepted'
      AND (role = 'owner' OR can_upload = true)
  );
END;
$$;

-- Update lead_batches RLS
DROP POLICY IF EXISTS "mgr_project_batches" ON public.lead_batches;
CREATE POLICY "mgr_project_batches" ON public.lead_batches
  FOR ALL
  USING (
    uploaded_by = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_member_project_ids())
  )
  WITH CHECK (
    uploaded_by = public.get_my_manager_id()
    AND (
      -- Either they are the owner or have explicit can_upload permission
      public.can_current_manager_upload(project_id)
    )
  );

-- Update leads RLS
DROP POLICY IF EXISTS "mgr_project_leads" ON public.leads;
CREATE POLICY "mgr_project_leads" ON public.leads
  FOR ALL
  USING (
    uploaded_by = public.get_my_manager_id()
    OR project_id IN (SELECT public.get_my_member_project_ids())
  )
  WITH CHECK (
    uploaded_by = public.get_my_manager_id()
    AND (
      public.can_current_manager_upload(project_id)
    )
  );
