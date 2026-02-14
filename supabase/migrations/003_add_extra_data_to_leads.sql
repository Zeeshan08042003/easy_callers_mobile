-- ============================================
-- Add extra_data column to leads table
-- Stores any Excel columns that don't map to known fields
-- Run this in Supabase SQL Editor AFTER 001_initial_schema.sql
-- ============================================

ALTER TABLE public.leads
ADD COLUMN IF NOT EXISTS extra_data JSONB DEFAULT '{}'::jsonb;

-- Add a comment for clarity
COMMENT ON COLUMN public.leads.extra_data IS 'Stores extra columns from uploaded files that do not map to standard lead fields';
