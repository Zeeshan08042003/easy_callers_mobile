-- ============================================
-- Fix OTP Expiry: Compute server-side using NOW()
-- Ensures OTP expiry is always correct regardless of client device clock
-- ============================================

-- Update sa_create_manager to always compute OTP expiry server-side
CREATE OR REPLACE FUNCTION public.sa_create_manager(
  input_email TEXT,
  input_first_name TEXT,
  input_last_name TEXT,
  input_phone TEXT DEFAULT NULL,
  input_manager_type TEXT DEFAULT 'manager',
  input_otp_code TEXT DEFAULT NULL,
  input_otp_expires_at TIMESTAMPTZ DEFAULT NULL  -- kept for signature compatibility, but IGNORED
) RETURNS SETOF public.managers
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_super_admin_id UUID;
  v_normalized_email TEXT;
  v_otp_expires TIMESTAMPTZ;
BEGIN
  SELECT id INTO v_super_admin_id
  FROM public.super_admins
  WHERE auth_id = auth.uid();
  
  IF v_super_admin_id IS NULL THEN
    RAISE EXCEPTION 'Only super admins can create managers';
  END IF;

  v_normalized_email := LOWER(TRIM(input_email));

  IF EXISTS (SELECT 1 FROM public.managers WHERE LOWER(TRIM(email)) = v_normalized_email) THEN
    RAISE EXCEPTION 'A manager with this email already exists';
  END IF;

  -- Always compute expiry server-side: NOW() + 24 hours
  v_otp_expires := NOW() + INTERVAL '24 hours';

  RETURN QUERY
  INSERT INTO public.managers (
    email, first_name, last_name, phone, is_active,
    manager_type, created_by_super_admin_id, otp_code, otp_expires_at
  ) VALUES (
    v_normalized_email, input_first_name, input_last_name, input_phone, false,
    input_manager_type, v_super_admin_id, input_otp_code, v_otp_expires
  )
  RETURNING *;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sa_create_manager(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;

-- RPC to resend OTP server-side (computes expiry with NOW())
CREATE OR REPLACE FUNCTION public.resend_manager_otp(
  input_email TEXT,
  input_otp_code TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.managers
  SET otp_code = input_otp_code,
      otp_expires_at = NOW() + INTERVAL '24 hours'
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email));
END;
$$;

GRANT EXECUTE ON FUNCTION public.resend_manager_otp(TEXT, TEXT) TO authenticated;
