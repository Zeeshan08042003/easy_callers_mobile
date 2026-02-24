-- ============================================
-- FIX: Create Missing Employee Record
-- Use this if you need to manually add the employee
-- ============================================

-- Option 1: If you want to create the employee manually
-- Replace the values with actual employee information

INSERT INTO public.employees (
  email,
  first_name,
  last_name,
  is_active,
  manager_id,
  otp_code,
  otp_expires_at,
  created_at,
  updated_at
) VALUES (
  'aliabbas@gmail.com',           -- Email (must match exactly)
  'Ali',                           -- First name
  'Abbas',                         -- Last name
  false,                           -- Not active yet (will activate with OTP)
  NULL,                            -- Manager ID (set to actual manager UUID if you have one)
  '123456',                        -- OTP code (6 digits)
  NOW() + INTERVAL '24 hours',     -- OTP expires in 24 hours
  NOW(),
  NOW()
);


-- Option 2: Check if the employee already exists but with different email format
SELECT 
  id,
  email,
  first_name,
  last_name,
  is_active,
  created_at
FROM public.employees
WHERE 
  email ILIKE '%ali%' 
  OR email ILIKE '%abbas%'
  OR first_name ILIKE '%ali%'
  OR last_name ILIKE '%abbas%';

-- Option 3: List ALL employees to see what's in the database
SELECT 
  id,
  email,
  first_name,
  last_name,
  is_active,
  manager_id,
  otp_code,
  created_at
FROM public.employees
ORDER BY created_at DESC;

-- Option 4: Clean up orphaned auth users (users in Auth but not in employees table)
-- WARNING: This will delete the auth account for aliabbas@gmail.com
-- Only run this if you want to start fresh
-- You'll need to run this in Supabase Dashboard > Authentication > Users
-- Find aliabbas@gmail.com and delete it manually
