-- ============================================
-- SIMPLIFIED EMPLOYEE AUTHENTICATION
-- This migration simplifies the employee login flow
-- ============================================

-- 1. Add a helper function to check if employee exists by email
CREATE OR REPLACE FUNCTION public.employee_exists(input_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.employees 
    WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
  );
END;
$$;

-- 2. Create a simplified function to activate employee
CREATE OR REPLACE FUNCTION public.activate_employee_account(
  input_email TEXT,
  input_otp TEXT,
  input_auth_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_id UUID;
  v_employee JSONB;
BEGIN
  -- Find the employee and verify OTP
  SELECT id INTO v_employee_id
  FROM public.employees
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND otp_code = input_otp
    AND otp_expires_at > NOW()
    AND is_active = false;
  
  -- If not found, return error
  IF v_employee_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid OTP or OTP expired'
    );
  END IF;
  
  -- Update employee: activate and link auth_id
  UPDATE public.employees
  SET 
    auth_id = input_auth_id,
    is_active = true,
    otp_code = NULL,
    otp_expires_at = NULL,
    updated_at = NOW()
  WHERE id = v_employee_id;
  
  -- Return the updated employee
  SELECT jsonb_build_object(
    'success', true,
    'employee', row_to_json(e.*)
  ) INTO v_employee
  FROM public.employees e
  WHERE e.id = v_employee_id;
  
  RETURN v_employee;
END;
$$;

-- 3. Function to resend OTP
CREATE OR REPLACE FUNCTION public.resend_employee_otp(input_email TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_otp TEXT;
  v_employee_id UUID;
BEGIN
  -- Generate new 6-digit OTP
  v_new_otp := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
  
  -- Update employee with new OTP
  UPDATE public.employees
  SET 
    otp_code = v_new_otp,
    otp_expires_at = NOW() + INTERVAL '24 hours',
    updated_at = NOW()
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND is_active = false
  RETURNING id INTO v_employee_id;
  
  -- Check if employee was found
  IF v_employee_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Employee not found or already activated'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'otp', v_new_otp,
    'message', 'OTP sent successfully'
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.employee_exists(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.activate_employee_account(TEXT, TEXT, UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.resend_employee_otp(TEXT) TO authenticated, anon;

-- Add comments
COMMENT ON FUNCTION public.employee_exists IS 'Check if an employee exists with the given email';
COMMENT ON FUNCTION public.activate_employee_account IS 'Activate employee account after OTP verification';
COMMENT ON FUNCTION public.resend_employee_otp IS 'Generate and update a new OTP for employee activation';
