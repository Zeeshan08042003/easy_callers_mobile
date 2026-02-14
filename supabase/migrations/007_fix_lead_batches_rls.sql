-- ============================================
-- FIX: Lead Batches RLS Policy for Manager INSERT
-- (For Separate Role Tables Schema)
-- ============================================

-- Drop the existing policy that's too restrictive
DROP POLICY IF EXISTS "manager_own_batches" ON public.lead_batches;

-- Create separate policies for different operations

-- Manager can INSERT batches with their own ID
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
