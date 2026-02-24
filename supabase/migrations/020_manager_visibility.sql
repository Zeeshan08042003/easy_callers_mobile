-- Add visibility flag and agency name to managers
-- Controls whether a Super Admin can see detailed reports for an independent manager
ALTER TABLE public.managers
ADD COLUMN IF NOT EXISTS is_sa_visible BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS agency_name TEXT;

-- Update RLS if needed, though SAs already have broad access.
-- This column is mainly for application-level filtering as requested.
