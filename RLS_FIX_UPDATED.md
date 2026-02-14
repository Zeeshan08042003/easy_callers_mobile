# ✅ FIXED: RLS Policy Error

## Error You Got
```
ERROR: 42P01: relation "public.users" does not exist
```

## What Was Wrong

The first version of the fix referenced `public.users` table, but your database uses **separate role tables**:
- `public.super_admins`
- `public.managers` ✅ (This is what we need!)
- `public.employees`

## ✅ Fixed Files

I've updated both files to use `public.managers` instead of `public.users`:

1. **`QUICK_FIX_RLS.sql`** - Updated ✅
2. **`supabase/migrations/007_fix_lead_batches_rls.sql`** - Updated ✅

---

## 🚀 How to Apply the Fix

### **Step 1:** Open Supabase Dashboard
- Go to your Supabase project
- Click **"SQL Editor"** in the left sidebar

### **Step 2:** Run the Fixed SQL
- Open the file: **`QUICK_FIX_RLS.sql`** (the updated one)
- Copy **ALL** the content
- Paste into Supabase SQL Editor
- Click **"Run"**

### **Step 3:** Verify Success
You should see output like:
```
Success. No rows returned

policyname                | cmd    | using_clause      | with_check_clause
--------------------------|--------|-------------------|-------------------
manager_delete_batches    | DELETE | Has USING clause  | No WITH CHECK clause
manager_insert_batches    | INSERT | No USING clause   | Has WITH CHECK clause
manager_select_batches    | SELECT | Has USING clause  | No WITH CHECK clause
manager_update_batches    | UPDATE | Has USING clause  | No WITH CHECK clause
```

---

## 📋 What the Fix Does

Creates **4 policies** for the `lead_batches` table:

```sql
-- For INSERT operations
CREATE POLICY "manager_insert_batches" ON public.lead_batches
  FOR INSERT WITH CHECK (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- For SELECT operations
CREATE POLICY "manager_select_batches" ON public.lead_batches
  FOR SELECT USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- For UPDATE operations
CREATE POLICY "manager_update_batches" ON public.lead_batches
  FOR UPDATE USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );

-- For DELETE operations
CREATE POLICY "manager_delete_batches" ON public.lead_batches
  FOR DELETE USING (
    uploaded_by IN (
      SELECT id FROM public.managers WHERE auth_id = auth.uid()
    )
  );
```

---

## 🎯 After Running the Fix

Test your Excel upload again:

1. **Open your app**
2. **Login as a manager**
3. **Upload your Excel file**
4. **Expected result:**
   ```
   ✅ Excel parsed successfully
   ✅ Detected: first_name, last_name, phone
   ✅ Batch record created
   ✅ 4 leads inserted
   ✅ Success: "Uploaded 4 leads successfully!"
   ```

---

## 🔍 Troubleshooting

### If you still get an error:

**Check 1: Is the manager logged in?**
```sql
SELECT auth.uid();
```
Should return a UUID (not null)

**Check 2: Does the manager exist in the managers table?**
```sql
SELECT id, email, first_name, last_name, auth_id 
FROM managers 
WHERE auth_id = auth.uid();
```
Should return 1 row with the manager's details

**Check 3: Are the policies created?**
```sql
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'lead_batches';
```
Should show the 4 new policies + super_admin policy

---

## 📊 Your Database Schema

Your app uses **separate tables for each role**:

| Table | Purpose | Who Can Access |
|-------|---------|----------------|
| `super_admins` | Super admin users | Super admins only |
| `managers` | Manager users | Super admins + self |
| `employees` | Employee users | Super admins + manager + self |
| `lead_batches` | Excel upload batches | Super admins + uploading manager |
| `leads` | Individual leads | Super admins + manager + assigned employee |

This is **different** from the single `users` table approach, which is why the first fix didn't work.

---

## ✅ Summary

**Problem:** RLS policy referenced `public.users` which doesn't exist  
**Solution:** Updated to use `public.managers` table  
**Status:** Fixed and ready to run  

**Just run the updated `QUICK_FIX_RLS.sql` file!** 🎉
