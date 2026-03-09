-- ============================================
-- 026: SECURITY DEFINER function for Super Admin to create Manager
-- Fixes RLS issue where Super Admin cannot INSERT into managers table
-- ============================================
-- 
-- PROBLEM:
--   When a Super Admin tries to INSERT into the managers table via the client,
--   the RLS policy sa_manage_managers checks:
--     EXISTS (SELECT 1 FROM super_admins WHERE auth_id = auth.uid())
--   This nested SELECT also goes through RLS on super_admins.
--   In some edge cases (e.g., RLS policy evaluation order, caching),
--   this circular check can fail.
--
-- SOLUTION:
--   Use a SECURITY DEFINER function that bypasses RLS entirely,
--   but validates that the caller is actually a super admin.
-- ============================================

CREATE OR REPLACE FUNCTION public.sa_create_manager(
  input_email TEXT,
  input_first_name TEXT,
  input_last_name TEXT,
  input_phone TEXT DEFAULT NULL,
  input_manager_type TEXT DEFAULT 'manager',
  input_otp_code TEXT DEFAULT NULL,
  input_otp_expires_at TIMESTAMPTZ DEFAULT NULL
) RETURNS SETOF public.managers
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_super_admin_id UUID;
  v_normalized_email TEXT;
BEGIN
  -- 1. Verify caller is a super admin
  SELECT id INTO v_super_admin_id
  FROM public.super_admins
  WHERE auth_id = auth.uid();
  
  IF v_super_admin_id IS NULL THEN
    RAISE EXCEPTION 'Only super admins can create managers';
  END IF;

  -- 2. Normalize email
  v_normalized_email := LOWER(TRIM(input_email));

  -- 3. Check if manager with this email already exists
  IF EXISTS (SELECT 1 FROM public.managers WHERE LOWER(TRIM(email)) = v_normalized_email) THEN
    RAISE EXCEPTION 'A manager with this email already exists';
  END IF;

  -- 4. Insert the new manager
  RETURN QUERY
  INSERT INTO public.managers (
    email,
    first_name,
    last_name,
    phone,
    is_active,
    manager_type,
    created_by_super_admin_id,
    otp_code,
    otp_expires_at
  ) VALUES (
    v_normalized_email,
    input_first_name,
    input_last_name,
    input_phone,
    false,  -- Starts inactive, activated via OTP
    input_manager_type,
    v_super_admin_id,
    input_otp_code,
    input_otp_expires_at
  )
  RETURNING *;
END;
$$;

-- Grant execute to authenticated users (the function itself validates super admin role)
GRANT EXECUTE ON FUNCTION public.sa_create_manager(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;
