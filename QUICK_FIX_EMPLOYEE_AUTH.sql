-- ============================================
-- QUICK FIX: Employee Authentication
-- Run this in Supabase SQL Editor to fix the PGRST202 error
-- ============================================

-- This script creates the missing get_employee_for_otp function
-- that your Flutter app is trying to call

CREATE OR REPLACE FUNCTION public.get_employee_for_otp(input_email TEXT)
RETURNS TABLE (
  id UUID,
  auth_id UUID,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN,
  manager_id UUID,
  otp_code TEXT,
  otp_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.auth_id,
    e.email,
    e.first_name,
    e.last_name,
    e.phone,
    e.profile_image_url,
    e.is_active,
    e.manager_id,
    e.otp_code,
    e.otp_expires_at,
    e.created_at,
    e.updated_at
  FROM public.employees e
  WHERE LOWER(TRIM(e.email)) = LOWER(TRIM(input_email));
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_employee_for_otp(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_employee_for_otp(TEXT) TO anon;

-- Verify the function was created
SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines
WHERE routine_schema = 'public' 
  AND routine_name = 'get_employee_for_otp';

-- Test the function (replace with actual employee email)
-- SELECT * FROM public.get_employee_for_otp('test@example.com');
