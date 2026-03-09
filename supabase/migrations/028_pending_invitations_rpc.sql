-- ============================================
-- 028: SECURITY DEFINER function to fetch pending invitations
-- ============================================
-- 
-- PROBLEM:
--   When a manager fetches pending invitations with embedded joins,
--   the join to super_admins table fails because managers have no
--   SELECT policy on super_admins. This can cause the entire query
--   to return empty results.
--
-- SOLUTION:
--   A SECURITY DEFINER function that fetches pending invitations
--   with all needed data, bypassing RLS for the joins.
-- ============================================

CREATE OR REPLACE FUNCTION public.get_pending_invitations_for_manager(input_manager_id UUID)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  manager_id UUID,
  role TEXT,
  status TEXT,
  visible_to_super_admin BOOLEAN,
  can_upload BOOLEAN,
  invited_by_super_admin_id UUID,
  invited_by_manager_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  project_name TEXT,
  project_subtitle TEXT,
  inviter_name TEXT,
  manager_first_name TEXT,
  manager_last_name TEXT,
  manager_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  -- Verify the caller is this manager (security check)
  IF NOT EXISTS (
    SELECT 1 FROM public.managers WHERE managers.id = input_manager_id AND auth_id = auth.uid()
  ) THEN
    -- Also allow super admins to view
    IF NOT EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()) THEN
      RETURN;
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    pm.id,
    pm.project_id,
    pm.manager_id,
    pm.role,
    pm.status,
    pm.visible_to_super_admin,
    pm.can_upload,
    pm.invited_by_super_admin_id,
    pm.invited_by_manager_id,
    pm.created_at,
    pm.updated_at,
    p.name AS project_name,
    p.subtitle AS project_subtitle,
    COALESCE(
      (SELECT sa.first_name || ' ' || sa.last_name FROM public.super_admins sa WHERE sa.id = pm.invited_by_super_admin_id),
      (SELECT m2.first_name || ' ' || m2.last_name FROM public.managers m2 WHERE m2.id = pm.invited_by_manager_id)
    ) AS inviter_name,
    m.first_name AS manager_first_name,
    m.last_name AS manager_last_name,
    m.email AS manager_email
  FROM public.project_members pm
  JOIN public.projects p ON p.id = pm.project_id
  JOIN public.managers m ON m.id = pm.manager_id
  WHERE pm.manager_id = input_manager_id
    AND pm.status = 'pending'
  ORDER BY pm.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_pending_invitations_for_manager(UUID) TO authenticated;
