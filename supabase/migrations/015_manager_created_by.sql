-- Add created_by_super_admin_id to managers table
-- This allows tracking which Super Admin created which manager
ALTER TABLE public.managers
ADD COLUMN IF NOT EXISTS created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL;

-- Note: No RLS changes needed as SAs have bypass access, 
-- this is used for app-level filtering.
