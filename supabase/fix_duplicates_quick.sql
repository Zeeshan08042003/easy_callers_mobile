-- ============================================
-- QUICK FIX: Remove Duplicate Employees
-- Run this in Supabase SQL Editor
-- ============================================

-- First, let's see what duplicates exist
SELECT email, COUNT(*) as count, 
       STRING_AGG(id::text, ', ') as ids,
       STRING_AGG(created_at::text, ', ') as created_dates
FROM public.employees
GROUP BY email
HAVING COUNT(*) > 1;

-- If you see duplicates above, run the following to fix them:

-- Delete duplicates, keeping only the most recent record for each email
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

-- Normalize all emails to lowercase
UPDATE public.employees
SET email = LOWER(TRIM(email))
WHERE email != LOWER(TRIM(email));

-- Verify no duplicates remain
SELECT email, COUNT(*) as count
FROM public.employees
GROUP BY email
HAVING COUNT(*) > 1;

-- If the above returns no rows, you're good!
