// Test file to demonstrate intelligent content detection
// This shows how the system handles Excel files WITHOUT proper headers

void main() {
  print('=== Intelligent Content Detection Test ===\n');
  
  print('📋 Scenario 1: Excel with NO headers (just data)');
  print('─────────────────────────────────────────────────');
  print('Row 1: John Doe | 9876543210 | john@email.com');
  print('Row 2: Jane Smith | 9876543211 | jane@email.com');
  print('Row 3: Bob Wilson | 9876543212 | bob@email.com');
  print('');
  print('✅ System will analyze content and detect:');
  print('   - Column 1: NAME (alphabetic pattern)');
  print('   - Column 2: PHONE (numeric pattern, 10 digits)');
  print('   - Column 3: EMAIL (contains @)');
  print('');
  
  print('📋 Scenario 2: Excel with unclear headers');
  print('─────────────────────────────────────────────────');
  print('Row 1: Col1 | Col2 | Col3');
  print('Row 2: John Doe | 9876543210 | john@email.com');
  print('Row 3: Jane Smith | 9876543211 | jane@email.com');
  print('');
  print('✅ System will ignore unclear headers and analyze data:');
  print('   - Column 1: NAME (detected from content)');
  print('   - Column 2: PHONE (detected from content)');
  print('   - Column 3: EMAIL (detected from content)');
  print('');
  
  print('📋 Scenario 3: Mixed format (only name and phone)');
  print('─────────────────────────────────────────────────');
  print('Row 1: John Doe | +91 98765-43210');
  print('Row 2: Jane Smith | (123) 456-7890');
  print('Row 3: Bob Wilson | 9876543212');
  print('');
  print('✅ System will detect:');
  print('   - Column 1: NAME');
  print('   - Column 2: PHONE (various formats cleaned)');
  print('');
  
  print('📋 Scenario 4: Reverse order (phone first, then name)');
  print('─────────────────────────────────────────────────');
  print('Row 1: 9876543210 | John Doe');
  print('Row 2: 9876543211 | Jane Smith');
  print('Row 3: 9876543212 | Bob Wilson');
  print('');
  print('✅ System will detect:');
  print('   - Column 1: PHONE (numeric pattern)');
  print('   - Column 2: NAME (alphabetic pattern)');
  print('');
  
  print('\n=== Detection Logic ===\n');
  
  print('🔍 Phone Number Detection:');
  final phoneExamples = [
    '9876543210',
    '+91 9876543210',
    '(123) 456-7890',
    '+1-555-123-4567',
    '98765 43210',
  ];
  
  for (var phone in phoneExamples) {
    final isPhone = isPhoneNumber(phone);
    print('   ${isPhone ? "✅" : "❌"} "$phone" → ${isPhone ? "PHONE" : "NOT PHONE"}');
  }
  
  print('\n🔍 Email Detection:');
  final emailExamples = [
    'john@email.com',
    'jane.smith@company.co.in',
    'test@test.org',
    'notanemail',
    'missing@domain',
  ];
  
  for (var email in emailExamples) {
    final isEmail = isEmailAddress(email);
    print('   ${isEmail ? "✅" : "❌"} "$email" → ${isEmail ? "EMAIL" : "NOT EMAIL"}');
  }
  
  print('\n🔍 Name Detection:');
  final nameExamples = [
    'John Doe',
    'Jane Smith',
    'O\'Brien',
    'Mary-Jane',
    'Dr. Smith',
    '123',
    'A',
    'john@email.com',
  ];
  
  for (var name in nameExamples) {
    final isName = isNameString(name);
    print('   ${isName ? "✅" : "❌"} "$name" → ${isName ? "NAME" : "NOT NAME"}');
  }
  
  print('\n=== Scoring System ===\n');
  print('The system analyzes the first 5 data rows and scores each column:');
  print('');
  print('Example Analysis:');
  print('Column 1: 5 names detected → Name Score: 5');
  print('Column 2: 5 phones detected → Phone Score: 5');
  print('Column 3: 4 emails detected → Email Score: 4');
  print('');
  print('Result:');
  print('✅ Column 1 assigned as NAME (highest name score)');
  print('✅ Column 2 assigned as PHONE (highest phone score)');
  print('✅ Column 3 assigned as EMAIL (highest email score)');
  print('');
  
  print('=== Benefits ===\n');
  print('✅ Works with Excel files that have NO headers');
  print('✅ Works with unclear headers (Col1, Col2, etc.)');
  print('✅ Automatically detects phone, email, and name columns');
  print('✅ Handles any column order');
  print('✅ Cleans phone numbers automatically');
  print('✅ No manual intervention required');
  print('');
  print('🎯 This makes the upload feature truly intelligent!');
}

// Helper functions matching the actual implementation

bool isPhoneNumber(String value) {
  final cleaned = value.replaceAll(RegExp(r'[\s\-().]'), '');
  
  if (cleaned.startsWith('+')) {
    final digits = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15;
  }
  
  final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 7 && digits.length <= 15 && digits.length == cleaned.length;
}

bool isEmailAddress(String value) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );
  return emailRegex.hasMatch(value);
}

bool isNameString(String value) {
  if (value.length < 2 || value.length > 100) return false;
  
  final nameRegex = RegExp(r"^[a-zA-Z\s.'\-]+$", caseSensitive: false);
  if (!nameRegex.hasMatch(value)) return false;
  
  final letterCount = value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
  return letterCount >= 2;
}
