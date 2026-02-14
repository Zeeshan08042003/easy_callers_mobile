# Excel Upload Improvements - Lead Management System

## 🎯 Overview
Fixed and enhanced the Excel upload functionality for managers to import leads data into Supabase. The system now uses **regex-based fuzzy matching** to handle any variation of column names and properly cleans phone numbers before saving.

## ✅ Key Improvements

### 1. **Flexible Column Name Matching**
Previously, the system used exact string matching which failed when column names varied slightly. Now it uses regex patterns to match columns intelligently.

#### Phone Number Columns (22+ variations recognized):
- `phone`, `mobile`, `cell`, `tel`, `telephone`
- `contact no`, `contact no.`, `phone no`, `phone no.`, `mobile no`, `mobile no.`
- `no`, `number` (standalone)
- `ph no`, `ph no.`, `cell no`, `cell no.`
- `whatsapp`, `whatsapp no`, `whatsapp no.`
- `contact number`, `phone number`, `mobile number`
- And many more variations with spaces, dashes, or underscores

#### Name Columns (22+ variations recognized):
- `name`, `full name`
- `client name`, `customer name`, `lead name`, `contact name`
- `party name`, `buyer name`, `owner name`
- `client`, `customer`, `contact`
- `first name`, `firstname`, `first_name`, `fname`, `f name`
- `last name`, `lastname`, `last_name`, `lname`, `surname`

#### Other Supported Fields:
- **Email**: `email`, `e-mail`, `mail`, `email address`, `email id`
- **Location**: `location`, `city`, `area`, `address`, `region`, `locality`, `place`, `town`, `district`, `state`, `pincode`, `zip`
- **Project**: `project`, `property`, `scheme`, `flat`, `plot`, `site`, `tower`, `project name`
- **Budget**: `budget`, `amount`, `price`, `investment`, `range`, `cost`, `value`
- **Source**: `source`, `lead source`, `channel`, `platform`, `origin`, `via`, `campaign`
- **Notes**: `notes`, `remarks`, `comments`, `description`, `observation`, `feedback`, `status`

### 2. **Phone Number Cleaning & Normalization**
Phone numbers are now automatically cleaned before saving to ensure consistency:

#### Examples:
```
Input                  → Cleaned Output
"+91 98765-43210"     → "919876543210"
"(123) 456-7890"      → "1234567890"
"9876543210"          → "9876543210"
"+1-555-123-4567"     → "15551234567"
"98765 43210"         → "9876543210"
"(91) 9876543210"     → "919876543210"
```

#### Cleaning Process:
1. Removes all whitespace
2. Removes formatting characters: `()`, `-`, `.`
3. Keeps only digits
4. Preserves leading `+` for international numbers

### 3. **Better Error Messages**
When column detection fails, the system now shows:
- All headers found in the Excel file
- Which columns were successfully detected
- Column numbers for detected fields

Example error message:
```
Could not find "Name" or "Phone" columns in the file.
Found headers: Sr No, Client, Contact No, Email
Detected: name (column 2), phone (column 3), email (column 4)
```

## 📊 Supported Excel Formats

### Format 1: Basic
```
| Sr No | Name          | No         |
|-------|---------------|------------|
| 1     | John Doe      | 9876543210 |
| 2     | Jane Smith    | 9876543211 |
```
✅ Detects: `name`, `phone`

### Format 2: Split Names
```
| First Name | Last Name | Mobile No. |
|------------|-----------|------------|
| John       | Doe       | 9876543210 |
| Jane       | Smith     | 9876543211 |
```
✅ Detects: `first_name`, `last_name` (auto-merged to `name`), `phone`

### Format 3: Detailed
```
| Client Name | Contact No | Email           | Location |
|-------------|------------|-----------------|----------|
| John Doe    | 9876543210 | john@email.com  | Mumbai   |
| Jane Smith  | 9876543211 | jane@email.com  | Delhi    |
```
✅ Detects: `name`, `phone`, `email`, `location`

### Format 4: Variations
```
| Customer | Ph No.     | Budget  | Project Name |
|----------|------------|---------|--------------|
| John Doe | 9876543210 | 50 Lakh | Tower A      |
```
✅ Detects: `name`, `phone`, `budget`, `project_name`

## 🔧 Technical Implementation

### Files Modified:
- **`lib/core/services/lead_upload_service.dart`**
  - Replaced `_matchesAny()` with `_matchesRegex()` for flexible pattern matching
  - Added `_cleanPhoneNumber()` method for phone normalization
  - Enhanced error messages with column detection feedback
  - Updated field extraction to clean phone numbers

### Key Methods:

#### `_mapColumns(List<String> headers)`
Maps Excel column headers to database field names using regex patterns.

#### `_matchesRegex(String header, String pattern)`
Performs case-insensitive regex matching on column headers.

#### `_cleanPhoneNumber(String phone)`
Normalizes phone numbers by removing formatting and keeping only digits.

## 🚀 Usage

The improvements are automatic. Managers can now:

1. **Upload Excel files** with any column naming convention
2. **Phone numbers** are automatically cleaned and normalized
3. **Names** are properly extracted whether split or combined
4. **Extra columns** are preserved in the `extra_data` field
5. **Clear error messages** if columns can't be detected

## 📝 Database Schema

Leads are saved to Supabase with the following structure:

```dart
{
  'name': 'John Doe',              // Required (or phone)
  'phone': '9876543210',           // Required (or name), cleaned
  'email': 'john@email.com',       // Optional
  'location': 'Mumbai',            // Optional
  'project_name': 'Tower A',       // Optional
  'budget': '50 Lakh',             // Optional
  'source': 'Website',             // Optional
  'notes': 'Interested in 2BHK',   // Optional
  'status': 'new',                 // Default
  'uploaded_by': 'manager_id',     // Auto-filled
  'batch_id': 'batch_id',          // Auto-filled
  'extra_data': {                  // Unmapped columns
    'Custom Field': 'value'
  }
}
```

## ✨ Benefits

1. **No More Failed Uploads**: Handles any reasonable column naming
2. **Clean Data**: Phone numbers are normalized for consistency
3. **Flexible**: Works with various Excel formats from different sources
4. **User-Friendly**: Clear error messages help managers fix issues
5. **Data Preservation**: Extra columns are saved, nothing is lost

## 🧪 Testing

Run the test file to see all supported variations:
```bash
dart test_excel_matching.dart
```

This demonstrates:
- All supported column name variations
- Phone number cleaning examples
- Real-world Excel format examples

## 🔍 Validation Rules

- **At least one required**: Name OR Phone must be present
- **Phone cleaning**: Automatic normalization
- **Name merging**: First + Last name automatically combined
- **Empty rows**: Skipped automatically
- **Serial numbers**: Columns like "Sr No", "S.No" are ignored
- **Extra data**: Unmapped columns stored in `extra_data` field

---

**Last Updated**: February 14, 2026
**Version**: 2.0.1
