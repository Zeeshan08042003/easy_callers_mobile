-- ============================================
-- Convert phone column to array
-- ============================================

DO $$
BEGIN
  -- First drop the secondary_phones if it exists from the previous iteration
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'leads' 
    AND column_name = 'secondary_phones'
  ) THEN
    ALTER TABLE public.leads DROP COLUMN secondary_phones;
  END IF;

  -- Then change phone to TEXT[]
  IF (
    SELECT data_type FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'leads' 
    AND column_name = 'phone'
  ) = 'text' THEN
    ALTER TABLE public.leads 
      ALTER COLUMN phone TYPE TEXT[] USING ARRAY[phone];
  END IF;
END $$;
