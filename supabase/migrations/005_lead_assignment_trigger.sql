-- Function to handle lead assignment notifications
CREATE OR REPLACE FUNCTION public.handle_lead_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if assigned_to has changed and is not null
  IF (TG_OP = 'INSERT' AND NEW.assigned_to IS NOT NULL) OR
     (TG_OP = 'UPDATE' AND NEW.assigned_to IS DISTINCT FROM OLD.assigned_to AND NEW.assigned_to IS NOT NULL) THEN
    
    INSERT INTO public.notifications (
      employee_id,
      title,
      body,
      type,
      metadata
    ) VALUES (
      NEW.assigned_to,
      'New Lead Assigned',
      'You have been assigned a new lead: ' || NEW.name,
      'lead_assigned',
      jsonb_build_object('lead_id', NEW.id, 'lead_name', NEW.name)
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for lead assignment
DROP TRIGGER IF EXISTS tr_on_lead_assignment ON public.leads;
CREATE TRIGGER tr_on_lead_assignment
AFTER INSERT OR UPDATE OF assigned_to ON public.leads
FOR EACH ROW
EXECUTE FUNCTION public.handle_lead_assignment_notification();

-- Enable replication for notifications table so real-time works
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
