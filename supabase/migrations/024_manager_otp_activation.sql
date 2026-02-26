-- ============================================
-- Easy Callers - Manager OTP Activation Migration
-- Adds OTP fields to managers for mandatory first-time activation
-- ============================================

-- 1. Add OTP fields to managers table
ALTER TABLE public.managers ADD COLUMN IF NOT EXISTS otp_code TEXT;
ALTER TABLE public.managers ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMPTZ;

-- 2. Modify is_active default to false for new managers
ALTER TABLE public.managers ALTER COLUMN is_active SET DEFAULT false;

-- 3. Create get_manager_for_otp function
CREATE OR REPLACE FUNCTION public.get_manager_for_otp(input_email TEXT)
RETURNS TABLE (
  id UUID,
  auth_id UUID,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  profile_image_url TEXT,
  is_active BOOLEAN,
  manager_type TEXT,
  created_by_super_admin_id UUID,
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
    m.id,
    m.auth_id,
    m.email,
    m.first_name,
    m.last_name,
    m.phone,
    m.profile_image_url,
    m.is_active,
    m.manager_type,
    m.created_by_super_admin_id,
    m.otp_code,
    m.otp_expires_at,
    m.created_at,
    m.updated_at
  FROM public.managers m
  WHERE LOWER(TRIM(m.email)) = LOWER(TRIM(input_email));
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_manager_for_otp(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_manager_for_otp(TEXT) TO anon;

-- Add comment
COMMENT ON FUNCTION public.get_manager_for_otp IS 'Retrieves manager record by email for OTP verification during first-time activation.';
