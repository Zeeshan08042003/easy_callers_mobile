# Employee Authentication Issues - Diagnosis & Fix

## Problem Summary

### Error 1: Missing Database Function
```
PostgrestException(message: Could not find the function public.get_employee_for_otp(input_email) 
in the schema cache, code: PGRST202)
```

**Root Cause:** The Flutter app calls `get_employee_for_otp()` function, but it was never created in the database.

### Error 2: Complex Authentication Flow
The current employee authentication flow is overly complex with multiple failure points:
1. OTP verification uses RPC call to non-existent function
2. Employee activation has 3 different query methods (ILIKE, exact match, manual filter)
3. Excessive debug logging clutters the code
4. Poor error messages for users

---

## Solutions Implemented

### 1. Created Missing Database Functions

**File:** `supabase/migrations/008_add_employee_otp_function.sql`
- Creates `get_employee_for_otp()` function
- Uses case-insensitive email matching
- Returns full employee record for OTP verification

**File:** `supabase/migrations/009_simplified_employee_auth.sql`
- `employee_exists()` - Check if employee email exists
- `activate_employee_account()` - One-step activation with OTP verification
- `resend_employee_otp()` - Regenerate OTP with proper expiry

### 2. Simplified Authentication Service

**File:** `lib/core/services/auth_service_improved.dart`
- Cleaner code with better error handling
- Removed redundant query methods
- Better user-facing error messages
- Simplified activation flow

---

## How to Apply the Fix

### Step 1: Run Database Migrations

Execute these SQL files in your Supabase SQL Editor **in order**:

1. **First:** `supabase/migrations/008_add_employee_otp_function.sql`
2. **Then:** `supabase/migrations/009_simplified_employee_auth.sql`

Or run them via Supabase CLI:
```bash
supabase db push
```

### Step 2: Replace Auth Service (Optional but Recommended)

Replace your current `auth_service.dart` with the improved version:
```bash
# Backup current file
cp lib/core/services/auth_service.dart lib/core/services/auth_service_backup.dart

# Use the improved version
cp lib/core/services/auth_service_improved.dart lib/core/services/auth_service.dart
```

### Step 3: Test the Flow

1. **Create Employee** (as Manager):
   - Email: test@example.com
   - Note the OTP code

2. **Activate Employee**:
   - Enter email
   - Enter OTP
   - Set password
   - Should activate successfully

3. **Login as Employee**:
   - Use email and password
   - Should login successfully

---

## Employee Authentication Flow (Simplified)

### Current Flow (Complex - 5 steps):
```
1. Manager creates employee → OTP generated
2. Employee enters email → Navigate to OTP screen
3. Employee enters OTP → RPC call to get_employee_for_otp
4. OTP verified → Navigate to password screen
5. Employee sets password → 3 different query attempts → Activation
```

### Improved Flow (Simple - 3 steps):
```
1. Manager creates employee → OTP generated
2. Employee enters email + OTP → Single RPC call verifies
3. Employee sets password → Single RPC call activates account
```

---

## Testing Checklist

- [ ] Database functions created successfully
- [ ] Employee creation works (Manager role)
- [ ] OTP verification works
- [ ] Employee activation works
- [ ] Employee login works
- [ ] Error messages are clear and helpful

---

## Common Issues & Solutions

### Issue: "No employee account found"
**Solution:** Verify the email exactly matches what the manager entered. Check in Supabase dashboard.

### Issue: "Invalid OTP"
**Solution:** 
- Check OTP hasn't expired (24 hours)
- Verify OTP code matches exactly
- Use resend OTP if needed

### Issue: "Account exists but password is incorrect"
**Solution:** Employee already activated. Use regular login, not first-time activation flow.

---

## Database Schema Reference

### Employees Table
```sql
CREATE TABLE public.employees (
  id UUID PRIMARY KEY,
  auth_id UUID UNIQUE,           -- Links to Supabase Auth
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT false,  -- false until OTP verified
  manager_id UUID,
  otp_code TEXT,                 -- 6-digit code
  otp_expires_at TIMESTAMPTZ,    -- 24 hours from creation
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

### Key Functions
- `get_employee_for_otp(email)` - Fetch employee for OTP verification
- `activate_employee_account(email, otp, auth_id)` - Activate in one step
- `resend_employee_otp(email)` - Generate new OTP

---

## Next Steps

1. **Immediate:** Run the database migrations to fix the PGRST202 error
2. **Recommended:** Replace auth_service.dart with the improved version
3. **Optional:** Add email/SMS integration to send OTP codes automatically
4. **Future:** Consider adding password reset functionality

---

## Questions?

If you encounter any issues:
1. Check Supabase logs for detailed error messages
2. Verify RLS policies allow the operations
3. Ensure employee email is correctly formatted (lowercase, trimmed)
4. Check that OTP hasn't expired
