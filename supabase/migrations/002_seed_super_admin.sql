-- ============================================
-- Seed Super Admin Account (for separate tables schema)
-- Run AFTER 004_separate_role_tables.sql
-- ============================================
-- 
-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Click "Add User" → "Create New User"
-- 3. Enter:
--    Email: zeeshan.easycaller@gmail.com
--    Password: (choose a secure password)
--    Check "Auto Confirm User"
-- 4. Copy the UUID of the created auth user
-- 5. Replace 'AUTH_USER_UUID_HERE' below with that UUID
-- 6. Run this SQL in the SQL Editor
-- ============================================

INSERT INTO public.super_admins (
  auth_id,
  email,
  first_name,
  last_name,
  is_active
) VALUES (
  'AUTH_USER_UUID_HERE',
  'zeeshan.easycaller@gmail.com',
  'Zeeshan',
  'Admin',
  true
) ON CONFLICT (email) DO NOTHING;
