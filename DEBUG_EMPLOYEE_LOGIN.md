# Debug Information for Employee Login Issue

## Changes Made

### 1. Case-Insensitive Email Search
Changed all email queries from `.eq()` (exact match) to `.ilike()` (case-insensitive match).

**Functions Updated:**
- `verifyEmployeeOTP()` - Now uses ILIKE
- `activateEmployee()` - Now uses ILIKE and updates by ID
- `resendEmployeeOTP()` - Now uses ILIKE

### 2. Enhanced Debug Logging

When you try to verify OTP now, you'll see detailed logs like:

```
=== OTP Verification Debug ===
Original email: 'MoeenNagori@Gmail.com'
Normalized email: 'moeennagori@gmail.com'
Found 1 employee record(s) for email: moeennagori@gmail.com
```

**If no employee is found**, the app will show:
```
DEBUG: Fetching all employee emails to compare...
Total employees in database: 2
  - ID: abc-123, Email: 'MoeenNagori@Gmail.com', Name: Moeen Nagori
  - ID: def-456, Email: 'test@example.com', Name: Test User
```

This will help us identify:
- Exact email format in the database
- Any whitespace or special characters
- Case differences

## What to Do Next

1. **Run the app** and try to verify OTP with the employee email
2. **Check the console logs** (filter by "I/flutter")
3. **Share the debug output** with me

The logs will show:
- What email you entered
- What email we're searching for (normalized)
- How many records were found
- If none found: all emails in the database for comparison

## Expected Outcomes

### Scenario A: Email Found (Success)
```
=== OTP Verification Debug ===
Original email: 'moeennagori@gmail.com'
Normalized email: 'moeennagori@gmail.com'
Found 1 employee record(s) for email: moeennagori@gmail.com
```
✅ OTP verification should proceed normally

### Scenario B: Email Not Found (Will Show All Emails)
```
=== OTP Verification Debug ===
Original email: 'moeennagori@gmail.com'
Normalized email: 'moeennagori@gmail.com'
Found 0 employee record(s) for email: moeennagori@gmail.com
DEBUG: Fetching all employee emails to compare...
Total employees in database: 2
  - ID: xxx, Email: 'MoeenNagori@Gmail.com', Name: Moeen Nagori
  - ID: yyy, Email: 'another@email.com', Name: Another User
```
❌ This would indicate the ILIKE query isn't working as expected

### Scenario C: Multiple Records Found
```
=== OTP Verification Debug ===
Original email: 'moeennagori@gmail.com'
Normalized email: 'moeennagori@gmail.com'
Found 2 employee record(s) for email: moeennagori@gmail.com
ERROR: Duplicate employee records found for moeennagori@gmail.com
Record IDs: abc-123, def-456
```
❌ Need to run the SQL cleanup script

## Troubleshooting

If ILIKE doesn't work (Scenario B above), it might be because:
1. Supabase RLS policies are blocking the query
2. The email has invisible characters (zero-width spaces, etc.)
3. Database collation issues

In that case, we'll need to:
1. Check the RLS policies
2. Update the database to normalize emails
3. Use a different matching strategy
