-- ============================================
-- 025: Fix infinite recursion in managers policy
-- ============================================

-- The previous policy used an EXISTS (SELECT 1 FROM managers) which triggered
-- a recursive check on the same table. We now use the SECURITY DEFINER 
-- helper function get_my_manager_id() which bypasses RLS safely.

DROP POLICY IF EXISTS "managers_view_agencies" ON public.managers;

CREATE POLICY "managers_view_agencies_secure" ON public.managers
FOR SELECT
USING (
  (public.get_my_manager_id() IS NOT NULL) -- Current user is a manager
  AND manager_type = 'agency'              -- The target row is an agency
);
