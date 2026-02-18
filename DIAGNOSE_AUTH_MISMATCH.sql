-- ============================================
-- DIAGNOSE: Auth vs Employees Table Mismatch
-- Run this to find the problem
-- ============================================

-- 1. Check if employee exists in employees table
SELECT 
  id,
  email,
  first_name,
  last_name,
  is_active,
  auth_id,
  otp_code,
  otp_expires_at,
  created_at
FROM public.employees
WHERE LOWER(TRIM(email)) = LOWER(TRIM('aliabbas@gmail.com'));

-- 2. Check ALL employees in the table
SELECT 
  id,
  email,
  first_name,
  last_name,
  is_active,
  auth_id,
  manager_id,
  created_at
FROM public.employees
ORDER BY created_at DESC;

-- 3. Check if user exists in Supabase Auth (you'll need to check this in Supabase Dashboard)
-- Go to: Authentication > Users
-- Look for: aliabbas@gmail.com

-- 4. Check for email variations (spaces, case differences)
SELECT 
  id,
  email,
  LENGTH(email) as email_length,
  first_name,
  last_name,
  CASE 
    WHEN email != TRIM(email) THEN 'Has leading/trailing spaces'
    WHEN email != LOWER(email) THEN 'Has uppercase letters'
    ELSE 'Clean'
  END as email_status
FROM public.employees
ORDER BY created_at DESC;

-- 5. Find similar emails
SELECT 
  id,
  email,
  first_name,
  last_name,
  is_active
FROM public.employees
WHERE email ILIKE '%ali%' OR email ILIKE '%abbas%';
