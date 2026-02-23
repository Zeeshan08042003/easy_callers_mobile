-- Add created_by_super_admin_id to managers table
ALTER TABLE public.managers
ADD COLUMN created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL;

-- Update RLS policies (optional, but good for security if managers should only be seen by their creator, though super admins usually see all. Let's keep it simple and just add the column for filtering.)
