-- ============================================
-- Fix Duplicate Employee Records
-- This migration removes duplicate employee records
-- keeping only the most recent one for each email
-- ============================================

-- Step 1: Identify and log duplicates
DO $$
DECLARE
  duplicate_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO duplicate_count
  FROM (
    SELECT email, COUNT(*) as cnt
    FROM public.employees
    GROUP BY email
    HAVING COUNT(*) > 1
  ) duplicates;
  
  RAISE NOTICE 'Found % duplicate email(s) in employees table', duplicate_count;
END $$;

-- Step 2: Delete duplicate records, keeping only the most recent one
-- (based on created_at timestamp)
DELETE FROM public.employees
WHERE id IN (
  SELECT id
  FROM (
    SELECT id,
           email,
           ROW_NUMBER() OVER (
             PARTITION BY LOWER(TRIM(email))
             ORDER BY created_at DESC, id DESC
           ) as row_num
    FROM public.employees
  ) ranked
  WHERE row_num > 1
);

-- Step 3: Normalize existing emails to lowercase and trim whitespace
UPDATE public.employees
SET email = LOWER(TRIM(email))
WHERE email != LOWER(TRIM(email));

-- Step 4: Ensure UNIQUE constraint exists on email
-- Drop existing constraint if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'employees_email_key'
  ) THEN
    ALTER TABLE public.employees DROP CONSTRAINT employees_email_key;
  END IF;
END $$;

-- Add UNIQUE constraint back
ALTER TABLE public.employees
ADD CONSTRAINT employees_email_key UNIQUE (email);

-- Step 5: Add a check constraint to ensure emails are always lowercase
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'employees_email_lowercase_check'
  ) THEN
    ALTER TABLE public.employees
    ADD CONSTRAINT employees_email_lowercase_check
    CHECK (email = LOWER(TRIM(email)));
  END IF;
END $$;

-- Step 6: Create a trigger to automatically normalize emails on insert/update
CREATE OR REPLACE FUNCTION normalize_employee_email()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email = LOWER(TRIM(NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS normalize_employee_email_trigger ON public.employees;

CREATE TRIGGER normalize_employee_email_trigger
BEFORE INSERT OR UPDATE OF email ON public.employees
FOR EACH ROW
EXECUTE FUNCTION normalize_employee_email();

-- Step 7: Verify the fix
DO $$
DECLARE
  duplicate_count INTEGER;
  total_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM public.employees;
  
  SELECT COUNT(*) INTO duplicate_count
  FROM (
    SELECT email, COUNT(*) as cnt
    FROM public.employees
    GROUP BY email
    HAVING COUNT(*) > 1
  ) duplicates;
  
  RAISE NOTICE 'Total employees: %', total_count;
  RAISE NOTICE 'Remaining duplicates: %', duplicate_count;
  
  IF duplicate_count > 0 THEN
    RAISE WARNING 'Still have duplicate emails! Manual intervention required.';
  ELSE
    RAISE NOTICE 'All duplicates resolved successfully!';
  END IF;
END $$;
