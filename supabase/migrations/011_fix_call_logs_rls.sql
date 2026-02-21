-- ============================================
-- Fix: Add missing RLS policies for call_logs
-- Employees need INSERT + SELECT on their own call logs
-- Managers need SELECT on their team's call logs
-- Also drop the restrictive call_status CHECK constraint
-- ============================================

-- Drop existing policies if they exist (safe re-run)
DROP POLICY IF EXISTS "employee_own_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "employee_insert_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "employee_select_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "manager_team_call_logs" ON public.call_logs;
DROP POLICY IF EXISTS "manager_select_call_logs" ON public.call_logs;

-- 1. Employees can INSERT their own call logs
CREATE POLICY "employee_insert_call_logs" ON public.call_logs
  FOR INSERT
  WITH CHECK (
    employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid())
  );

-- 2. Employees can SELECT (read) their own call logs
CREATE POLICY "employee_select_call_logs" ON public.call_logs
  FOR SELECT
  USING (
    employee_id IN (SELECT id FROM public.employees WHERE auth_id = auth.uid())
  );

-- 3. Managers can SELECT call logs for their team's employees
CREATE POLICY "manager_select_call_logs" ON public.call_logs
  FOR SELECT
  USING (
    employee_id IN (
      SELECT e.id FROM public.employees e
      JOIN public.managers m ON e.manager_id = m.id
      WHERE m.auth_id = auth.uid()
    )
  );

-- 4. Drop the restrictive call_status CHECK constraint
-- The app now stores raw call statuses like 'Completed', 'Declined or Failed', etc.
ALTER TABLE public.call_logs DROP CONSTRAINT IF EXISTS call_logs_call_status_check;
