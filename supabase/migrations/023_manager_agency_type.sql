-- ============================================
-- 023: Add manager_type column to distinguish managers from agencies
-- ============================================

-- Add manager_type column: 'manager' (created by SA) or 'agency' (independent)
ALTER TABLE public.managers
ADD COLUMN IF NOT EXISTS manager_type TEXT DEFAULT 'manager'
CHECK (manager_type IN ('manager', 'agency'));

-- Backfill existing data:
-- Managers with created_by_super_admin_id set → 'manager'
-- Managers without a creator (independent) → 'agency'
UPDATE public.managers
SET manager_type = CASE
  WHEN created_by_super_admin_id IS NOT NULL THEN 'manager'
  ELSE 'agency'
END
WHERE manager_type IS NULL OR manager_type = 'manager';

-- Index for fast filtering by type
CREATE INDEX IF NOT EXISTS idx_managers_type ON public.managers(manager_type);

-- Note: RLS policies are unchanged — SAs still have broad access.
-- The manager_type column is used for application-level filtering.
