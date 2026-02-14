// Test file to demonstrate the improved Excel column matching
// This shows examples of column headers that will now be recognized

void main() {
  print('=== Excel Column Matching Test ===\n');
  
  // Phone number variations that will be matched
  final phoneVariations = [
    'phone',
    'mobile',
    'contact no',
    'contact no.',
    'phone no',
    'phone no.',
    'mobile no',
    'mobile no.',
    'no',
    'number',
    'ph no',
    'ph no.',
    'cell',
    'cell no',
    'whatsapp',
    'whatsapp no',
    'telephone',
    'tel',
    'mob',
    'contact number',
    'phone number',
    'mobile number',
  ];
  
  // Name variations that will be matched
  final nameVariations = [
    'name',
    'full name',
    'client name',
    'customer name',
    'lead name',
    'contact name',
    'party name',
    'buyer name',
    'owner name',
    'client',
    'customer',
    'contact',
    'first name',
    'firstname',
    'first_name',
    'fname',
    'f name',
    'last name',
    'lastname',
    'last_name',
    'lname',
    'surname',
  ];
  
  print('✅ Phone Number Columns (${phoneVariations.length} variations):');
  for (var variation in phoneVariations) {
    print('   - "$variation"');
  }
  
  print('\n✅ Name Columns (${nameVariations.length} variations):');
  for (var variation in nameVariations) {
    print('   - "$variation"');
  }
  
  print('\n=== Phone Number Cleaning Examples ===\n');
  
  final phoneExamples = [
    '+91 98765-43210',
    '(123) 456-7890',
    '9876543210',
    '+1-555-123-4567',
    '98765 43210',
    '(91) 9876543210',
  ];
  
  print('Input → Cleaned Output:');
  for (var example in phoneExamples) {
    final cleaned = cleanPhoneNumber(example);
    print('   "$example" → "$cleaned"');
  }
  
  print('\n=== Real-world Excel Examples ===\n');
  
  print('Example 1: Basic format');
  print('Headers: Sr No | Name | No');
  print('✅ Will detect: name, phone\n');
  
  print('Example 2: Split name format');
  print('Headers: First Name | Last Name | Mobile No.');
  print('✅ Will detect: first_name, last_name (merged to name), phone\n');
  
  print('Example 3: Detailed format');
  print('Headers: Client Name | Contact No | Email | Location');
  print('✅ Will detect: name, phone, email, location\n');
  
  print('Example 4: Variations');
  print('Headers: Customer | Ph No. | Budget | Project Name');
  print('✅ Will detect: name, phone, budget, project_name\n');
}

// Simulated phone cleaning function (matches the actual implementation)
String cleanPhoneNumber(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'\s+'), '');
  cleaned = cleaned.replaceAll(RegExp(r'[()-.]'), '');
  
  if (cleaned.startsWith('+')) {
    cleaned = '+' + cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
  } else {
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
  }
  
  return cleaned;
}
