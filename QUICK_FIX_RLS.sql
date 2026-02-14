-- ============================================
-- QUICK FIX: Lead Batches RLS Policy (For Separate Role Tables Schema)
-- Copy and paste this ENTIRE file into Supabase SQL Editor and click RUN
-- ============================================

-- Step 1: Drop the old policy if it exists
DROP POLICY IF EXISTS "manager_own_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "manager_insert_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "manager_select_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "manager_update_batches" ON public.lead_batches;
DROP POLICY IF EXISTS "manager_delete_batches" ON public.lead_batches;

-- Step 2: Create new policies for MANAGERS table (not users table)

-- Manager can INSERT batches (WITH CHECK validates the new row)
CREATE POLICY "manager_insert_batches" ON public.lead_batches
  FOR INSERT WITH CHECK (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- Manager can SELECT their own batches
CREATE POLICY "manager_select_batches" ON public.lead_batches
  FOR SELECT USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- Manager can UPDATE their own batches
CREATE POLICY "manager_update_batches" ON public.lead_batches
  FOR UPDATE USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- Manager can DELETE their own batches
CREATE POLICY "manager_delete_batches" ON public.lead_batches
  FOR DELETE USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- Step 3: Verify the policies were created
SELECT 
  policyname, 
  cmd,
  CASE 
    WHEN qual IS NOT NULL THEN 'Has USING clause'
    ELSE 'No USING clause'
  END as using_clause,
  CASE 
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
    ELSE 'No WITH CHECK clause'
  END as with_check_clause
FROM pg_policies
WHERE tablename = 'lead_batches'
  AND policyname LIKE 'manager%'
ORDER BY policyname;
