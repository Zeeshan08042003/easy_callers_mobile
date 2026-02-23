-- ============================================
-- Add caller (employee) assignment to projects
-- Manager can assign "all" or "selected" employees
-- ============================================

-- 1. Add caller_assignment column to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'projects' 
    AND column_name = 'caller_assignment'
  ) THEN
    ALTER TABLE public.projects 
      ADD COLUMN caller_assignment TEXT DEFAULT 'all' CHECK (caller_assignment IN ('all', 'selected'));
  END IF;
END $$;

-- 2. Create project_callers table (links employees to projects)
CREATE TABLE IF NOT EXISTS public.project_callers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  added_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, employee_id)
);

-- 3. Index
CREATE INDEX IF NOT EXISTS idx_project_callers_project ON public.project_callers(project_id);
CREATE INDEX IF NOT EXISTS idx_project_callers_employee ON public.project_callers(employee_id);

-- 4. RLS
ALTER TABLE public.project_callers ENABLE ROW LEVEL SECURITY;

-- Super Admin can manage callers in their projects
DROP POLICY IF EXISTS "sa_all_project_callers" ON public.project_callers;
CREATE POLICY "sa_all_project_callers" ON public.project_callers
  FOR ALL USING (
    project_id IN (SELECT public.get_my_sa_project_ids())
  );

-- Manager can manage callers in projects they created
DROP POLICY IF EXISTS "mgr_manage_project_callers" ON public.project_callers;
CREATE POLICY "mgr_manage_project_callers" ON public.project_callers
  FOR ALL USING (
    project_id IN (SELECT public.get_my_created_project_ids())
  );

-- Manager can view callers in projects they are members of
DROP POLICY IF EXISTS "mgr_view_project_callers" ON public.project_callers;
CREATE POLICY "mgr_view_project_callers" ON public.project_callers
  FOR SELECT USING (
    project_id IN (SELECT public.get_my_member_project_ids())
  );
