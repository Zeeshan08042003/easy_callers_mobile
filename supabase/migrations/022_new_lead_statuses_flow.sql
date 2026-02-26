-- ============================================
-- Fix: Update lead statuses and mapping constraints
-- ============================================

-- 1. Drop existing constraint if it exists
ALTER TABLE public.lead_statuses DROP CONSTRAINT IF EXISTS lead_statuses_lead_status_mapping_check;

-- 2. Update existing rows that might violate the new constraint
-- Map old statuses to the closest new ones
UPDATE public.lead_statuses 
SET lead_status_mapping = 'follow_up' 
WHERE lead_status_mapping IN ('interested', 'callback');

UPDATE public.lead_statuses 
SET lead_status_mapping = 'not_interested' 
WHERE lead_status_mapping = 'not_connected';

UPDATE public.lead_statuses 
SET lead_status_mapping = 'visiting' 
WHERE lead_status_mapping = 'connected';

-- Finally, ensure any other unknown mapping is set to 'new' or something valid
UPDATE public.lead_statuses 
SET lead_status_mapping = 'new' 
WHERE lead_status_mapping NOT IN (
  'new', 'assigned', 'follow_up', 'not_interested',
  'visiting', 'visit_completed', 'converted', 'drop'
);

-- 3. Add updated constraint
ALTER TABLE public.lead_statuses ADD CONSTRAINT lead_statuses_lead_status_mapping_check 
  CHECK (lead_status_mapping IN (
    'new', 'assigned', 'follow_up', 'not_interested',
    'visiting', 'visit_completed', 'converted', 'drop'
  ));

-- 4. Update existing default statuses or insert new ones
-- Clear old defaults that are no longer valid for the new flow
DELETE FROM public.lead_statuses WHERE manager_id IS NULL AND value IN ('interested', 'callback', 'closed');

-- Insert/Update new default statuses (global, where manager_id is NULL)
-- We'll do this in two steps or use a targeted ON CONFLICT
-- Since ON CONFLICT can only target one unique constraint/index at a time, 
-- and we have both UNIQUE(value, manager_id) and a partial index for NULLs,
-- it's safer to just delete and re-insert the global ones.

DELETE FROM public.lead_statuses 
WHERE manager_id IS NULL 
AND value IN ('follow_up', 'not_interested', 'visiting', 'visit_completed', 'converted', 'drop');

INSERT INTO public.lead_statuses (value, display_name, lead_status_mapping, manager_id) VALUES
('follow_up', 'Follow Up', 'follow_up', NULL),
('not_interested', 'Not Interested', 'not_interested', NULL),
('visiting', 'Visiting', 'visiting', NULL),
('visit_completed', 'Visit Completed', 'visit_completed', NULL),
('converted', 'Converted', 'converted', NULL),
('drop', 'Drop', 'drop', NULL);

-- 5. Update leads table status check if it exists
ALTER TABLE public.leads DROP CONSTRAINT IF EXISTS leads_status_check;
