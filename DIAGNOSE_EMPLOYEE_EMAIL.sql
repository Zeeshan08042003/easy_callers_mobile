-- Diagnostic Query: Find Employee by Email
-- Run this in Supabase SQL Editor to check if the employee exists

-- 1. Check exact email match
SELECT id, email, first_name, last_name, is_active, otp_code, otp_expires_at, created_at
FROM employees
WHERE email = 'sharmanatasha536@gmail.com';

-- 2. Check case-insensitive match
SELECT id, email, first_name, last_name, is_active, otp_code, otp_expires_at, created_at
FROM employees
WHERE LOWER(email) = LOWER('sharmanatasha536@gmail.com');

-- 3. Check with ILIKE (what the app uses)
SELECT id, email, first_name, last_name, is_active, otp_code, otp_expires_at, created_at
FROM employees
WHERE email ILIKE 'sharmanatasha536@gmail.  com';

-- 4. Show ALL employees to see what's in the database
SELECT id, email, first_name, last_name, is_active, manager_id, created_at
FROM employees
ORDER BY created_at DESC;

-- 5. Check for emails with extra spaces or special characters
SELECT 
  id, 
  email,
  LENGTH(email) as email_length,
  first_name, 
  last_name,
  CASE 
    WHEN email != TRIM(email) THEN 'Has spaces'
    WHEN email != LOWER(email) THEN 'Has uppercase'
    ELSE 'Clean'
  END as email_status
FROM employees
ORDER BY created_at DESC;

-- 6. Find similar emails (in case of typo)
SELECT id, email, first_name, last_name
FROM employees
WHERE email LIKE '%sharma%' OR email LIKE '%natasha%';
