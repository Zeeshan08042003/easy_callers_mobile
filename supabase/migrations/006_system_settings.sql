-- System Settings Table
CREATE TABLE public.system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name TEXT NOT NULL DEFAULT 'Easy Callers',
  support_email TEXT,
  support_phone TEXT,
  max_leads_per_employee INTEGER DEFAULT 100,
  daily_call_target INTEGER DEFAULT 50,
  maintenance_mode BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES public.super_admins(id) ON DELETE SET NULL
);

-- Insert default settings
INSERT INTO public.system_settings (company_name, support_email)
VALUES ('Easy Callers', 'support@easycallers.com')
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "super_admin_manage_settings" ON public.system_settings
FOR ALL USING (EXISTS (SELECT 1 FROM public.super_admins WHERE auth_id = auth.uid()));

CREATE POLICY "everyone_read_settings" ON public.system_settings
FOR SELECT USING (true);
