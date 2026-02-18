-- ============================================
-- Add get_employee_for_otp Function
-- This function is used during employee first-time activation
-- ============================================

-- Create the function to get employee by email for OTP verification
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_employee_for_otp(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_employee_for_otp(TEXT) TO anon;

-- Add comment
COMMENT ON FUNCTION public.get_employee_for_otp IS 'Retrieves employee record by email for OTP verification during first-time activation. Uses case-insensitive email matching.';
