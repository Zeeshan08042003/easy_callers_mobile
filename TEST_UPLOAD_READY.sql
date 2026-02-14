-- ============================================
-- TEST: Check if Excel Upload Will Work
-- Run this to test if the RLS policies allow manager uploads
-- ============================================

-- Step 1: Check if you're logged in as a manager
SELECT 
  'Current User' as check_type,
  auth.uid() as auth_id,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ Logged in'
    ELSE '❌ Not logged in'
  END as status;

-- Step 2: Check if your manager record exists
SELECT 
  'Manager Record' as check_type,
  id,
  email,
  first_name || ' ' || last_name as name,
  CASE 
    WHEN is_active THEN '✅ Active'
    ELSE '❌ Inactive'
  END as status
FROM managers
WHERE auth_id = auth.uid();

-- Step 3: Check RLS policies on lead_batches
SELECT 
  'RLS Policies' as check_type,
  policyname,
  cmd as operation,
  CASE 
    WHEN cmd = 'INSERT' AND with_check IS NOT NULL THEN '✅ INSERT allowed'
    WHEN cmd = 'SELECT' AND qual IS NOT NULL THEN '✅ SELECT allowed'
    WHEN cmd = 'UPDATE' AND qual IS NOT NULL THEN '✅ UPDATE allowed'
    WHEN cmd = 'DELETE' AND qual IS NOT NULL THEN '✅ DELETE allowed'
    ELSE '⚠️ Check policy'
  END as status
FROM pg_policies
WHERE tablename = 'lead_batches'
  AND policyname LIKE 'manager%'
ORDER BY cmd;

-- Step 4: Test if you can see existing batches (if any)
SELECT 
  'Existing Batches' as check_type,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see ' || COUNT(*) || ' batch(es)'
    ELSE 'ℹ️ No batches yet (this is OK)'
  END as status
FROM lead_batches;
