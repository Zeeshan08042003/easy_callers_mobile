-- ============================================
-- Migration 029: Auto-confirm user email on activation
-- ============================================
-- Problem: When employees or managers are activated via signUp(),
-- Supabase may not auto-confirm their email. This causes "email not confirmed"
-- errors when they try to login again after logout.
--
-- Solution: Create a SECURITY DEFINER function that confirms the user's email
-- in auth.users after activation. This function uses the service_role
-- to update the auth.users table directly.
-- ============================================

-- Function to confirm a user's email in auth.users
-- This must run as SECURITY DEFINER to access auth.users
CREATE OR REPLACE FUNCTION public.confirm_user_email(input_auth_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the auth.users table to mark email as confirmed
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    updated_at = now()
  WHERE id = input_auth_id;
END;
$$;

-- Grant execute permission to authenticated users (activation happens while authenticated)
GRANT EXECUTE ON FUNCTION public.confirm_user_email(UUID) TO authenticated;

-- Also grant to anon for the case where signUp is called without prior auth
GRANT EXECUTE ON FUNCTION public.confirm_user_email(UUID) TO anon;

-- Update the activate_employee function to also confirm the email
CREATE OR REPLACE FUNCTION public.activate_employee(
  input_email TEXT,
  input_auth_id UUID
) RETURNS SETOF public.employees LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Activate the employee record
  UPDATE public.employees
  SET auth_id = input_auth_id,
      is_active = true,
      otp_code = NULL,
      otp_expires_at = NULL
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND auth_id IS NULL;

  -- Confirm the email in auth.users so login works after logout
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now()),
      updated_at = now()
  WHERE id = input_auth_id;

  RETURN QUERY SELECT * FROM public.employees WHERE auth_id = input_auth_id LIMIT 1;
END;
$$;

-- Update the activate_manager function to also confirm the email
CREATE OR REPLACE FUNCTION public.activate_manager(
  input_email TEXT,
  input_auth_id UUID
) RETURNS SETOF public.managers LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Activate the manager record
  UPDATE public.managers
  SET auth_id = input_auth_id,
      is_active = true,
      otp_code = NULL,
      otp_expires_at = NULL
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(input_email))
    AND auth_id IS NULL;

  -- Confirm the email in auth.users so login works after logout
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now()),
      updated_at = now()
  WHERE id = input_auth_id;

  RETURN QUERY SELECT * FROM public.managers WHERE auth_id = input_auth_id LIMIT 1;
END;
$$;

-- Re-grant execute permissions (in case they were affected)
GRANT EXECUTE ON FUNCTION public.activate_employee(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_manager(TEXT, UUID) TO authenticated;
