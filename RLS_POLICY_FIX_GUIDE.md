# 🔒 RLS Policy Error - Fix Guide

## Error Message
```
PostgrestException(message: new row violates row-level security policy for table "lead_batches", 
code: 42501, details: Forbidden, hint: null)
```

## What This Means

✅ **Good News:** Your Excel parsing is working perfectly!  
❌ **Problem:** Supabase Row-Level Security (RLS) is blocking the database insert.

The RLS policy on the `lead_batches` table is preventing managers from inserting new batch records.

---

## Root Cause

In your current RLS policy (line 292-297 of `001_initial_schema.sql`):

```sql
CREATE POLICY "manager_own_batches" ON public.lead_batches
  FOR ALL USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );
```

**Problem:** The `FOR ALL USING` clause only checks for SELECT/UPDATE/DELETE operations. For INSERT operations, you need `WITH CHECK` instead of `USING`.

---

## The Fix

I've created a migration file: **`007_fix_lead_batches_rls.sql`**

This migration:
1. **Drops** the old restrictive policy
2. **Creates** separate policies for each operation (INSERT, SELECT, UPDATE, DELETE)
3. **Uses `WITH CHECK`** for INSERT to validate the uploaded_by field

---

## How to Apply the Fix

### Option 1: Run in Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - Open your project
   - Navigate to **SQL Editor**

2. **Copy and paste this SQL:**

```sql
-- Drop the existing policy
DROP POLICY IF EXISTS "manager_own_batches" ON public.lead_batches;

-- Manager can INSERT batches with their own ID
CREATE POLICY "manager_insert_batches" ON public.lead_batches
  FOR INSERT WITH CHECK (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );

-- Manager can SELECT their own batches
CREATE POLICY "manager_select_batches" ON public.lead_batches
  FOR SELECT USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );

-- Manager can UPDATE their own batches
CREATE POLICY "manager_update_batches" ON public.lead_batches
  FOR UPDATE USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );

-- Manager can DELETE their own batches
CREATE POLICY "manager_delete_batches" ON public.lead_batches
  FOR DELETE USING (
    uploaded_by IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid() AND role = 'manager'
    )
  );
```

3. **Click "Run"**

4. **Verify** - You should see:
   ```
   Success. No rows returned
   ```

---

### Option 2: Using Supabase CLI

If you have Supabase CLI set up:

```bash
# Navigate to your project
cd /Users/sw/Desktop/projects/easy_callers_mobile

# Run the migration
supabase db push
```

---

## What Changed

### Before (Broken):
```sql
CREATE POLICY "manager_own_batches" ON public.lead_batches
  FOR ALL USING (...)  -- ❌ USING doesn't work for INSERT
```

### After (Fixed):
```sql
-- Separate policy for INSERT
CREATE POLICY "manager_insert_batches" ON public.lead_batches
  FOR INSERT WITH CHECK (...)  -- ✅ WITH CHECK validates INSERT

-- Separate policy for SELECT
CREATE POLICY "manager_select_batches" ON public.lead_batches
  FOR SELECT USING (...)  -- ✅ USING validates SELECT
```

---

## Why This Happened

Supabase RLS has different clauses for different operations:

| Operation | Clause | Purpose |
|-----------|--------|---------|
| **INSERT** | `WITH CHECK` | Validates the NEW row being inserted |
| **SELECT** | `USING` | Filters which rows can be read |
| **UPDATE** | `USING` + `WITH CHECK` | Validates both old and new rows |
| **DELETE** | `USING` | Filters which rows can be deleted |

Your original policy used `FOR ALL USING`, which only applies the `USING` clause. This works for SELECT/UPDATE/DELETE, but **fails for INSERT** because INSERT needs `WITH CHECK`.

---

## Testing After Fix

After applying the migration, test the upload:

1. **Upload your Excel file** through the manager dashboard
2. **Expected result:**
   ```
   ✅ Detected first_name at column 1
   ✅ Detected last_name at column 2
   ✅ Detected phone at column 3
   ✅ 4 leads saved successfully!
   ```

3. **Check Supabase:**
   - Go to **Table Editor** → `lead_batches`
   - You should see a new batch record
   - Go to **Table Editor** → `leads`
   - You should see your imported leads

---

## Verification Queries

Run these in Supabase SQL Editor to verify:

### Check if policies exist:
```sql
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'lead_batches';
```

### Check recent batches:
```sql
SELECT id, file_name, total_leads, uploaded_by, created_at
FROM lead_batches
ORDER BY created_at DESC
LIMIT 5;
```

### Check recent leads:
```sql
SELECT id, name, phone, batch_id, created_at
FROM leads
ORDER BY created_at DESC
LIMIT 10;
```

---

## Common RLS Issues

### Issue 1: "Forbidden" on INSERT
**Cause:** Missing `WITH CHECK` clause  
**Fix:** Use `FOR INSERT WITH CHECK` instead of `FOR ALL USING`

### Issue 2: "Forbidden" on UPDATE
**Cause:** Missing `USING` clause  
**Fix:** Use `FOR UPDATE USING` (or both `USING` and `WITH CHECK`)

### Issue 3: Can't see own records
**Cause:** `auth.uid()` doesn't match `auth_id` in users table  
**Fix:** Verify user is logged in and has correct auth_id

---

## Security Notes

The new policies ensure:

✅ **Managers can only insert batches with their own ID**  
✅ **Managers can only see their own batches**  
✅ **Managers can only update/delete their own batches**  
✅ **Super admins can do everything** (via separate policy)  
✅ **Employees have no access** to lead_batches (as intended)

---

## Next Steps

1. **Apply the SQL migration** (Option 1 or 2 above)
2. **Test the Excel upload** again
3. **Verify data** in Supabase tables
4. **Check for any other RLS errors**

---

## If Still Getting Errors

If you still get RLS errors after applying this fix, check:

1. **Is the user authenticated?**
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   print('User: ${user?.id}');
   ```

2. **Does the user have a record in the users table?**
   ```sql
   SELECT id, email, role, auth_id 
   FROM users 
   WHERE auth_id = '<your-auth-id>';
   ```

3. **Is the role correct?**
   - Should be `'manager'` for managers
   - Check: `SELECT role FROM users WHERE auth_id = auth.uid();`

4. **Check other tables:**
   - Similar RLS issues might exist for `leads` table
   - We can fix those too if needed

---

**Apply the migration and the upload should work!** 🚀
