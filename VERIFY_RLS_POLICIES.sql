-- ============================================
-- VERIFY: Check if RLS Policies are Correctly Set Up
-- Run this to verify your lead_batches policies
-- ============================================

-- Check all policies on lead_batches table
SELECT 
  policyname, 
  cmd as operation,
  CASE 
    WHEN qual IS NOT NULL THEN '✅ Has USING'
    ELSE '❌ No USING'
  END as using_clause,
  CASE 
    WHEN with_check IS NOT NULL THEN '✅ Has WITH CHECK'
    ELSE '❌ No WITH CHECK'
  END as with_check_clause,
  CASE 
    WHEN cmd = 'INSERT' AND with_check IS NOT NULL THEN '✅ CORRECT'
    WHEN cmd = 'SELECT' AND qual IS NOT NULL THEN '✅ CORRECT'
    WHEN cmd = 'UPDATE' AND qual IS NOT NULL THEN '✅ CORRECT'
    WHEN cmd = 'DELETE' AND qual IS NOT NULL THEN '✅ CORRECT'
    WHEN cmd = 'ALL' THEN '⚠️ Generic policy'
    ELSE '❌ WRONG'
  END as status
FROM pg_policies
WHERE tablename = 'lead_batches'
ORDER BY policyname;
