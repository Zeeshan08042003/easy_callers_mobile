# 🔍 Employee Not Found During Password Setup - Diagnostic Guide

## Error
```
=== Employee Activation Debug ===
Normalized email: 'sharmanatasha536@gmail.com'
Found 0 employee record(s)
```

---

## 🔍 Possible Causes

### **1. Employee Was Never Created**
The employee record doesn't exist in the database.

**Check:**
```sql
SELECT * FROM employees WHERE email ILIKE '%natasha%';
```

### **2. Email Mismatch**
The email in the database is different from what's being searched.

**Common Issues:**
- Extra spaces: `'sharmanatasha536@gmail.com '` (space at end)
- Different casing: `'SharmanatashA536@gmail.com'`
- Typo in database: `'sharmanatasha53@gmail.com'` (missing 6)

**Check:**
```sql
SELECT id, email, LENGTH(email) as len
FROM employees
WHERE email LIKE '%sharma%';
```

### **3. Employee in Different Table**
Employee might be in `managers` or `super_admins` table instead.

**Check:**
```sql
SELECT 'employees' as table_name, email FROM employees WHERE email ILIKE '%natasha%'
UNION ALL
SELECT 'managers' as table_name, email FROM managers WHERE email ILIKE '%natasha%'
UNION ALL
SELECT 'super_admins' as table_name, email FROM super_admins WHERE email ILIKE '%natasha%';
```

### **4. Database Connection Issue**
The app is connected to wrong Supabase project.

**Check:** Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your environment.

---

## 🚀 Quick Diagnostic Steps

### **Step 1: Run Diagnostic SQL**

Open Supabase SQL Editor and run:
```sql
-- Check if employee exists
SELECT id, email, first_name, last_name, is_active, otp_code, created_at
FROM employees
WHERE email ILIKE 'sharmanatasha536@gmail.com';

-- If not found, show all employees
SELECT id, email, first_name, last_name, created_at
FROM employees
ORDER BY created_at DESC
LIMIT 10;
```

### **Step 2: Check Employee Creation**

Did you create the employee through the app?

**If YES:**
- Check the manager dashboard logs
- Verify the employee appears in the database

**If NO:**
- Create the employee first using the manager dashboard
- Or create manually in Supabase

### **Step 3: Manual Employee Creation (If Needed)**

If the employee doesn't exist, create it manually:

```sql
INSERT INTO employees (
  email,
  first_name,
  last_name,
  is_active,
  manager_id,
  otp_code,
  otp_expires_at
) VALUES (
  'sharmanatasha536@gmail.com',
  'Natasha',
  'Sharma',
  false,
  'YOUR_MANAGER_ID_HERE',  -- Replace with actual manager ID
  '123456',  -- OTP code
  NOW() + INTERVAL '24 hours'
);
```

---

## 🔧 Temporary Fix: Update Auth Service

I'll update the auth service to provide better error messages and handle edge cases.

### **Changes to Make:**

1. **Better Email Normalization**
   ```dart
   final normalizedEmail = email.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
   ```

2. **Try Multiple Query Methods**
   - First: Exact match
   - Second: ILIKE
   - Third: LOWER() comparison

3. **Show All Employees in Debug**
   - If not found, list all employees to help identify the issue

---

## 📊 Expected Flow

### **Normal Flow:**
```
1. Manager creates employee
   ↓
2. Employee record inserted with OTP
   ↓
3. Employee receives OTP
   ↓
4. Employee enters email + OTP
   ↓
5. OTP verified ✅
   ↓
6. Employee sets password
   ↓
7. activateEmployee() finds record ✅
   ↓
8. Account activated ✅
```

### **Current Issue:**
```
1-5. ✅ (OTP verified successfully)
   ↓
6. Employee sets password
   ↓
7. activateEmployee() searches for record
   ↓
8. ❌ Found 0 records
   ↓
9. Activation fails
```

---

## 🎯 Root Cause Analysis

The fact that **OTP verification worked** but **activation failed** suggests:

### **Scenario A: Different Email Used**
- OTP verification used one email
- Password setup used different email
- **Solution:** Ensure same email is used in both steps

### **Scenario B: Record Deleted Between Steps**
- Employee record existed during OTP
- Record was deleted before password setup
- **Solution:** Check database logs

### **Scenario C: Transaction Issue**
- OTP verification didn't commit
- Record not actually in database
- **Solution:** Check database transaction logs

---

## 🔍 Debug Checklist

Run these checks in order:

- [ ] **Check if employee exists in database**
  ```sql
  SELECT * FROM employees WHERE email ILIKE 'sharmanatasha536@gmail.com';
  ```

- [ ] **Check all employees to see what's there**
  ```sql
  SELECT id, email, first_name, last_name FROM employees ORDER BY created_at DESC LIMIT 10;
  ```

- [ ] **Check if email has extra spaces**
  ```sql
  SELECT id, email, LENGTH(email), TRIM(email) FROM employees;
  ```

- [ ] **Check if employee is in wrong table**
  ```sql
  SELECT 'employees' as tbl, email FROM employees WHERE email LIKE '%natasha%'
  UNION ALL
  SELECT 'managers', email FROM managers WHERE email LIKE '%natasha%';
  ```

- [ ] **Verify Supabase project connection**
  - Check `SUPABASE_URL` in your app
  - Ensure you're looking at the correct project in Supabase dashboard

---

## 🚀 Immediate Actions

### **Action 1: Run Diagnostic SQL**

Use the file `DIAGNOSE_EMPLOYEE_EMAIL.sql` I created:
1. Open Supabase SQL Editor
2. Copy and run the queries
3. Share the results

### **Action 2: Check App Logs**

Look for these log messages:
```
=== OTP Verification Debug ===
Normalized email: '...'
Found X employee record(s) for email: ...
```

**If OTP verification found the employee but activation didn't, there's a data inconsistency.**

### **Action 3: Verify Email Consistency**

Make sure the EXACT same email is used in:
1. Employee creation
2. OTP verification
3. Password setup

---

## 💡 Quick Workaround

If you need to activate the employee immediately:

### **Option 1: Manual Activation (SQL)**
```sql
-- 1. Find the employee
SELECT id, email FROM employees WHERE email ILIKE '%natasha%';

-- 2. Create auth account manually in Supabase Auth dashboard
-- Email: sharmanatasha536@gmail.com
-- Password: [choose password]
-- Copy the auth user ID

-- 3. Update employee record
UPDATE employees
SET 
  auth_id = 'AUTH_USER_ID_HERE',  -- Paste auth ID from step 2
  is_active = true,
  otp_code = NULL,
  otp_expires_at = NULL
WHERE email ILIKE 'sharmanatasha536@gmail.com';
```

### **Option 2: Recreate Employee**
```dart
// In manager dashboard, delete and recreate the employee
// Then try activation again
```

---

## 📋 Next Steps

1. **Run the diagnostic SQL** (`DIAGNOSE_EMPLOYEE_EMAIL.sql`)
2. **Share the results** so I can see what's in the database
3. **I'll update the auth service** with better error handling
4. **We'll fix the root cause** once we identify it

**Let me know what the diagnostic SQL shows!** 🔍
