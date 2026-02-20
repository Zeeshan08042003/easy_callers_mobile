-- Create lead_statuses table
CREATE TABLE IF NOT EXISTS public.lead_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  value TEXT NOT NULL,
  display_name TEXT NOT NULL,
  lead_status_mapping TEXT DEFAULT 'follow_up' CHECK (lead_status_mapping IN (
    'new', 'assigned', 'connected', 'not_connected',
    'interested', 'not_interested', 'follow_up',
    'converted', 'closed'
  )),
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(value, manager_id)
);

-- Handle global uniqueness for null manager_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_lead_statuses_value_global ON public.lead_statuses (value) WHERE manager_id IS NULL;

-- Insert default statuses
INSERT INTO public.lead_statuses (value, display_name, lead_status_mapping) VALUES
('interested', 'Interested', 'interested'),
('not_interested', 'Not Interested', 'not_interested'),
('follow_up', 'Follow Up', 'follow_up'),
('callback', 'Callback', 'follow_up'),
('visiting', 'Visiting', 'converted'),
('closed', 'Closed', 'closed')
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE public.lead_statuses ENABLE ROW LEVEL SECURITY;

-- Everyone can read active statuses
CREATE POLICY "everyone_read_active_statuses" ON public.lead_statuses
  FOR SELECT USING (is_active = true);

-- Managers and Super Admins can manage statuses
CREATE POLICY "super_admins_manage_all" ON public.lead_statuses
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid())
  );

CREATE POLICY "managers_manage_own" ON public.lead_statuses
  FOR ALL USING (
    manager_id IS NOT NULL AND 
    manager_id IN (SELECT id FROM public.managers WHERE auth_id = auth.uid())
  );

-- Update call_logs and leads check constraints to be more flexible or removed
ALTER TABLE public.call_logs DROP CONSTRAINT IF EXISTS call_logs_lead_status_check;
ALTER TABLE public.leads DROP CONSTRAINT IF EXISTS leads_status_check;
