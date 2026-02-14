# Employee Login Error Fix - PGRST116

## Problem
Employees were unable to login after registration, getting the error:
```
PostgrestException(message: Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows, hint: null)
```

## Root Cause
The error was caused by **duplicate employee records** in the database. When the code used `.single()` to fetch an employee by email, Supabase returned an error because it found multiple matching records instead of exactly one.

The duplicates likely occurred due to:
1. Missing or improperly enforced UNIQUE constraint on the email column
2. Email case sensitivity issues (e.g., `User@Example.com` vs `user@example.com`)
3. Emails with trailing/leading whitespace

## Solution

### 1. Code Changes (COMPLETED ✅)
Updated `/lib/core/services/auth_service.dart` to:

- **Email Normalization**: All emails are now converted to lowercase and trimmed before any database operation
- **Duplicate Detection**: Changed from `.single()` to fetching all matching records and checking the count
- **Better Error Messages**: Clear error messages when duplicates are detected, including logging of duplicate record IDs

**Functions Updated:**
- `login()` - Normalizes email before authentication
- `verifyEmployeeOTP()` - Detects and reports duplicates
- `activateEmployee()` - Detects duplicates before activation
- `createEmployee()` - Normalizes email on creation
- `createManager()` - Normalizes email on creation
- `resendEmployeeOTP()` - Normalizes email on update

### 2. Database Cleanup (ACTION REQUIRED ⚠️)

You need to clean up the duplicate records in your Supabase database.

#### Option A: Quick Fix (Recommended)
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Open the file: `supabase/fix_duplicates_quick.sql`
4. Copy and paste the SQL into the editor
5. Run the script

This will:
- Show you which emails have duplicates
- Delete duplicate records (keeping the most recent one)
- Normalize all emails to lowercase
- Verify the fix worked

#### Option B: Full Migration
If you want a more comprehensive fix with constraints and triggers:
1. Apply the migration: `supabase/migrations/005_fix_duplicate_employees.sql`
2. This adds:
   - Automatic email normalization trigger
   - Check constraint to ensure emails are always lowercase
   - Duplicate cleanup

## Testing Steps

After running the database cleanup:

1. **Verify duplicates are removed:**
   ```sql
   SELECT email, COUNT(*) as count
   FROM public.employees
   GROUP BY email
   HAVING COUNT(*) > 1;
   ```
   This should return 0 rows.

2. **Test employee login:**
   - Try logging in with the employee account
   - Should now work without the PGRST116 error

3. **Test new employee creation:**
   - Create a new employee with mixed-case email (e.g., `Test@Example.com`)
   - Verify OTP
   - Set password
   - Login should work

## Current Status

✅ Code updated to handle duplicates gracefully
✅ Email normalization implemented across all auth operations
✅ SQL scripts created for database cleanup
⚠️ **ACTION REQUIRED**: Run the SQL cleanup script in Supabase Dashboard

## Files Modified
- `/lib/core/services/auth_service.dart` - Email normalization and duplicate detection

## Files Created
- `/supabase/migrations/005_fix_duplicate_employees.sql` - Full migration with constraints
- `/supabase/fix_duplicates_quick.sql` - Quick cleanup script for immediate use

## Next Steps
1. Run the SQL cleanup script in Supabase Dashboard (use `fix_duplicates_quick.sql`)
2. Test employee login
3. If issues persist, check the console logs for the duplicate record IDs
4. Optionally apply the full migration for long-term prevention
