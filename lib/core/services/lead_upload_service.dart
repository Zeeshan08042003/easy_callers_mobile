import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/constants/supabase_constants.dart';
import 'package:easy_callers_mobile/core/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';


/// Service for handling lead file uploads and parsing.
/// Supports Excel (.xlsx, .xls) files.
/// PDF parsing will be handled via Supabase Edge Function in the future.
class LeadUploadService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  final RxBool isUploading = false.obs;
  final RxBool isParsing = false.obs;
  final RxString error = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // ============================================
  // FILE PICKING
  // ============================================

  /// Pick an Excel or PDF file from the device
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;
      return result.files.first;
    } catch (e) {
      error.value = 'Error picking file: $e';
      return null;
    }
  }

  // ============================================
  // EXCEL PARSING
  // ============================================

  /// Known column types that we map to our lead fields.
  /// Any header NOT matching these gets stored in extra_data.
  static const _skipHeaders = {
    'sr no', 'sr no.', 'sr.no', 'sr.no.', 's.no', 's no', 'sno',
    'serial', 'serial no', 'serial no.', '#', 'no.', 'sl no', 'sl no.',
  };

  /// Parse an Excel file and extract lead data.
  ///
  /// Handles two common formats from real-world data:
  /// - Format 1: sr no | name | no  (single name column)
  /// - Format 2: First Name | Last Name | Mobile No.  (split name columns)
  ///
  /// Any columns that don't match known fields are stored in 'extra_data'.
  Future<List<Map<String, dynamic>>> parseExcelFile(PlatformFile file) async {
    try {
      isParsing.value = true;
      error.value = '';

      Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        error.value = 'Could not read file data.';
        return [];
      }

      final excel = Excel.decodeBytes(bytes);
      final leads = <Map<String, dynamic>>[];

      // Process the first sheet
      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        // First row is headers
        final rawHeaders = sheet.rows.first
            .map((cell) => cell?.value?.toString().trim() ?? '')
            .toList();
        final headers = rawHeaders.map((h) => h.toLowerCase()).toList();

        // Map headers to our field names
        var columnMap = _mapColumns(headers);

        // Check if headers are missing or unclear
        final hasName = columnMap['name'] != null ||
            columnMap['first_name'] != null;
        final hasPhone = columnMap['phone'] != null;

        // If no name/phone detected from headers, try intelligent content detection
        if (!hasName && !hasPhone && sheet.rows.length > 1) {
          print('📊 No clear headers detected. Analyzing content...');
          columnMap = _detectColumnsByContent(sheet, rawHeaders);
        }

        // Re-check after content detection
        final hasNameAfterDetection = columnMap['name'] != null ||
            columnMap['first_name'] != null;
        final hasPhoneAfterDetection = columnMap['phone'] != null;

        // Identify extra columns (not mapped to any known field and not skipped)
        final mappedIndices = columnMap.values
            .where((v) => v != null)
            .map((v) => v!)
            .toSet();
        final extraColumns = <int, String>{}; // index -> original header name
        for (var i = 0; i < headers.length; i++) {
          if (!mappedIndices.contains(i) && !_skipHeaders.contains(headers[i])) {
            if (rawHeaders[i].isNotEmpty) {
              extraColumns[i] = rawHeaders[i]; // Keep original casing
            }
          }
        }

        if (!hasNameAfterDetection && !hasPhoneAfterDetection) {
          // Build helpful error message showing what was detected
          final detectedColumns = <String>[];
          columnMap.forEach((key, value) {
            if (value != null) {
              detectedColumns.add('$key (column ${value + 1})');
            }
          });
          
          error.value =
              'Could not find "Name" or "Phone" columns in the file.\n'
              'Found headers: ${rawHeaders.join(", ")}\n'
              '${detectedColumns.isNotEmpty ? "Detected: ${detectedColumns.join(", ")}" : "No columns were recognized."}\n'
              'Tip: Ensure your Excel has at least a Name or Phone column.';
          return [];
        }

        // Process data rows (skip header row)
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final lead = <String, dynamic>{};

          // Extract mapped fields
          for (final entry in columnMap.entries) {
            if (entry.value != null && entry.value! < row.length) {
              final cellValue = row[entry.value!]?.value?.toString().trim();
              if (cellValue != null && cellValue.isNotEmpty) {
                // Clean phone numbers before storing
                if (entry.key == 'phone') {
                  lead[entry.key] = _cleanPhoneNumber(cellValue);
                } else {
                  lead[entry.key] = cellValue;
                }
              }
            }
          }

          // Build the final name from first_name + last_name if 'name' isn't set
          if (!lead.containsKey('name') || (lead['name'] as String? ?? '').isEmpty) {
            final firstName = (lead.remove('first_name') as String?) ?? '';
            final lastName = (lead.remove('last_name') as String?) ?? '';
            final combined = '$firstName $lastName'.trim();
            if (combined.isNotEmpty) {
              lead['name'] = combined;
            }
          } else {
            // Clean up split fields if name was already found
            lead.remove('first_name');
            lead.remove('last_name');
          }

          // Collect extra column values into extra_data
          final extraData = <String, String>{};
          for (final entry in extraColumns.entries) {
            if (entry.key < row.length) {
              final cellValue = row[entry.key]?.value?.toString().trim();
              if (cellValue != null && cellValue.isNotEmpty) {
                extraData[entry.value] = cellValue;
              }
            }
          }
          if (extraData.isNotEmpty) {
            lead['extra_data'] = extraData;
          }

          // Only add if we have at least a name or phone
          if ((lead['name'] as String? ?? '').isNotEmpty ||
              (lead['phone'] as String? ?? '').isNotEmpty) {
            leads.add(lead);
          }
        }

        // Only process the first sheet
        break;
      }

      return leads;
    } catch (e) {
      error.value = 'Error parsing Excel file: $e';
      return [];
    } finally {
      isParsing.value = false;
    }
  }

  /// Map column headers to our field names using regex patterns.
  ///
  /// Uses flexible regex matching to handle real-world variations:
  /// - "name" / "client name" / "customer" → name
  /// - "first name" / "fname" → first_name  (will be merged with last_name → name)
  /// - "last name" / "surname" → last_name
  /// - "phone" / "mobile" / "contact no" / "number" → phone
  Map<String, int?> _mapColumns(List<String> headers) {
    final map = <String, int?>{
      'name': null,
      'first_name': null,
      'last_name': null,
      'phone': null,
      'email': null,
      'location': null,
      'project_name': null,
      'budget': null,
      'source': null,
      'notes': null,
    };

    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];

      // Skip serial number columns
      if (_skipHeaders.contains(h)) continue;

      // Use regex patterns for flexible matching
      // Priority: Check specific patterns first, then general ones

      // First name - must check before general "name"
      if (_matchesRegex(h, r'^(first[\s_-]?name|f[\s_-]?name|fname)$')) {
        map['first_name'] = i;
      }
      // Last name - must check before general "name"
      else if (_matchesRegex(h, r'^(last[\s_-]?name|l[\s_-]?name|lname|surname|sur[\s_-]?name)$')) {
        map['last_name'] = i;
      }
      // Full name variations - check after first/last name
      else if (_matchesRegex(h, r'^(name|full[\s_-]?name|client[\s_-]?name|customer[\s_-]?name|lead[\s_-]?name|contact[\s_-]?name|party[\s_-]?name|buyer[\s_-]?name|owner[\s_-]?name|client|customer|contact)$')) {
        map['name'] = i;
      }
      // Phone variations - VERY FLEXIBLE to catch "no", "number", "contact no", etc.
      else if (_matchesRegex(h, r'^(phone|mobile|cell|tel|telephone|mob|contact|whatsapp|ph|number|no)[\s_-]?(number|no|num)?\.?$')) {
        map['phone'] = i;
      }
      // Email variations
      else if (_matchesRegex(h, r'^(email|e[\s_-]?mail|mail)[\s_-]?(address|id)?$')) {
        map['email'] = i;
      }
      // Location variations
      else if (_matchesRegex(h, r'^(location|city|area|address|region|locality|place|town|district|state|pincode|pin[\s_-]?code|zip|postal)$')) {
        map['location'] = i;
      }
      // Project variations
      else if (_matchesRegex(h, r'^(project|property|scheme|flat|plot|site|tower)[\s_-]?(name)?$')) {
        map['project_name'] = i;
      }
      // Budget variations
      else if (_matchesRegex(h, r'^(budget|amount|price|investment|range|cost|value)[\s_-]?(range)?$')) {
        map['budget'] = i;
      }
      // Source variations
      else if (_matchesRegex(h, r'^(source|lead[\s_-]?source|channel|platform|origin|via|campaign|medium|portal)$')) {
        map['source'] = i;
      }
      // Notes variations
      else if (_matchesRegex(h, r'^(notes?|remarks?|comments?|description|observation|feedback|status|requirement)$')) {
        map['notes'] = i;
      }
    }

    return map;
  }

  /// Check if header matches a regex pattern
  bool _matchesRegex(String header, String pattern) {
    final regex = RegExp(pattern, caseSensitive: false);
    return regex.hasMatch(header);
  }

  /// Clean and normalize phone numbers
  /// Removes spaces, dashes, parentheses, and other special characters
  /// Keeps only digits and optional leading + for international numbers
  String _cleanPhoneNumber(String phone) {
    // Remove all whitespace
    String cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    
    // Remove common phone number formatting characters
    cleaned = cleaned.replaceAll(RegExp(r'[()-.]'), '');
    
    // Keep only digits and leading +
    if (cleaned.startsWith('+')) {
      cleaned = '+' + cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    return cleaned;
  }

  /// Intelligent content detection for Excel files without clear headers
  /// Analyzes actual cell values to determine column types
  Map<String, int?> _detectColumnsByContent(dynamic sheet, List<String> rawHeaders) {
    final map = <String, int?>{
      'name': null,
      'phone': null,
      'email': null,
    };

    // Analyze first 5 data rows (skip header row)
    final sampleSize = sheet.rows.length > 6 ? 6 : sheet.rows.length;
    final columnScores = <int, Map<String, int>>{}; // column index -> {type: score}

    // Initialize scores for each column
    for (var colIdx = 0; colIdx < rawHeaders.length; colIdx++) {
      columnScores[colIdx] = {'phone': 0, 'email': 0, 'name': 0};
    }

    // Analyze sample rows (skip first row which might be headers)
    for (var rowIdx = 1; rowIdx < sampleSize; rowIdx++) {
      final row = sheet.rows[rowIdx];
      
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        final cellValue = row[colIdx]?.value?.toString().trim() ?? '';
        if (cellValue.isEmpty) continue;

        // Check if it's a phone number
        if (_isPhoneNumber(cellValue)) {
          columnScores[colIdx]!['phone'] = columnScores[colIdx]!['phone']! + 1;
        }
        // Check if it's an email
        else if (_isEmail(cellValue)) {
          columnScores[colIdx]!['email'] = columnScores[colIdx]!['email']! + 1;
        }
        // Check if it's a name (alphabetic with possible spaces)
        else if (_isName(cellValue)) {
          columnScores[colIdx]!['name'] = columnScores[colIdx]!['name']! + 1;
        }
      }
    }

    // Assign columns based on highest scores
    // Priority: phone > email > name (phone is most critical)
    
    // Find phone column (highest phone score)
    var maxPhoneScore = 0;
    var phoneColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (scores['phone']! > maxPhoneScore) {
        maxPhoneScore = scores['phone']!;
        phoneColIdx = colIdx;
      }
    });
    if (phoneColIdx >= 0 && maxPhoneScore > 0) {
      map['phone'] = phoneColIdx;
      print('✅ Detected phone column at index $phoneColIdx (score: $maxPhoneScore)');
    }

    // Find email column (highest email score, excluding phone column)
    var maxEmailScore = 0;
    var emailColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (colIdx != phoneColIdx && scores['email']! > maxEmailScore) {
        maxEmailScore = scores['email']!;
        emailColIdx = colIdx;
      }
    });
    if (emailColIdx >= 0 && maxEmailScore > 0) {
      map['email'] = emailColIdx;
      print('✅ Detected email column at index $emailColIdx (score: $maxEmailScore)');
    }

    // Find name column (highest name score, excluding phone and email)
    var maxNameScore = 0;
    var nameColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (colIdx != phoneColIdx && colIdx != emailColIdx && scores['name']! > maxNameScore) {
        maxNameScore = scores['name']!;
        nameColIdx = colIdx;
      }
    });
    if (nameColIdx >= 0 && maxNameScore > 0) {
      map['name'] = nameColIdx;
      print('✅ Detected name column at index $nameColIdx (score: $maxNameScore)');
    }

    return map;
  }

  /// Check if a string looks like a phone number
  /// Accepts: digits with optional +, spaces, dashes, parentheses
  /// Must have 7-15 digits
  bool _isPhoneNumber(String value) {
    // Remove common formatting
    final cleaned = value.replaceAll(RegExp(r'[\s\-().]'), '');
    
    // Check if it starts with + and has digits
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      return digits.length >= 7 && digits.length <= 15;
    }
    
    // Check if it's all digits (or mostly digits)
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15 && digits.length == cleaned.length;
  }

  /// Check if a string looks like an email
  bool _isEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(value);
  }

  /// Check if a string looks like a name
  /// Should be mostly alphabetic with possible spaces, dots, apostrophes
  /// Should not be too short (at least 2 chars) or too long (max 100 chars)
  bool _isName(String value) {
    // Should have at least 2 characters
    if (value.length < 2 || value.length > 100) return false;
    
    // Should be mostly letters (allow spaces, dots, apostrophes, hyphens)
    final nameRegex = RegExp(r"^[a-zA-Z\s.'\-]+$", caseSensitive: false);
    if (!nameRegex.hasMatch(value)) return false;
    
    // Should have at least some letters
    final letterCount = value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return letterCount >= 2;
  }

  // ============================================
  // UPLOAD & SAVE TO DATABASE
  // ============================================

  /// Full upload flow:
  /// 1. Upload file to Supabase Storage
  /// 2. Parse the file
  /// 3. Create a lead batch record
  /// 4. Insert all leads into the database
  Future<LeadBatchModel?> uploadAndSaveLeads({
    required PlatformFile file,
    required String uploadedByUserId,
  }) async {
    try {
      isUploading.value = true;
      error.value = '';
      uploadProgress.value = 0;

      // 1. Upload the file to Supabase Storage
      uploadProgress.value = 0.1;
      final fileUrl = await _uploadFileToStorage(file);
      uploadProgress.value = 0.3;

      // 2. Parse the file
      final parsedLeads = await parseExcelFile(file);
      uploadProgress.value = 0.5;

      if (parsedLeads.isEmpty) {
        error.value = error.value.isEmpty
            ? 'No leads found in the file.'
            : error.value;
        return null;
      }

      // 3. Create batch record
      final batchData = {
        'file_name': file.name,
        'file_url': fileUrl,
        'total_leads': parsedLeads.length,
        'uploaded_by': uploadedByUserId,
      };

      final batchResponse = await _supabase.leadBatchesTable
          .insert(batchData)
          .select()
          .single();

      final batch = LeadBatchModel.fromJson(batchResponse);
      uploadProgress.value = 0.6;

      // 4. Insert leads into database
      final leadInserts = parsedLeads.map((lead) {
        final insert = <String, dynamic>{
          'name': lead['name'] ?? 'Unknown',
          'phone': lead['phone'] ?? '',
          'email': lead['email'],
          'location': lead['location'],
          'project_name': lead['project_name'],
          'budget': lead['budget'],
          'source': lead['source'],
          'notes': lead['notes'],
          'status': 'new',
          'uploaded_by': uploadedByUserId,
          'batch_id': batch.id,
        };

        // Store extra unmapped columns in extra_data
        if (lead.containsKey('extra_data')) {
          insert['extra_data'] = lead['extra_data'];
        }

        return insert;
      }).toList();

      // Insert in batches of 100
      for (var i = 0; i < leadInserts.length; i += 100) {
        final end =
            (i + 100 < leadInserts.length) ? i + 100 : leadInserts.length;
        final chunk = leadInserts.sublist(i, end);
        await _supabase.leadsTable.insert(chunk);

        uploadProgress.value =
            0.6 + (0.4 * (end / leadInserts.length));
      }

      uploadProgress.value = 1.0;
      return batch;
    } catch (e) {
      error.value = 'Error uploading leads: $e';
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  /// Upload file to Supabase Storage
  Future<String?> _uploadFileToStorage(PlatformFile file) async {
    try {
      Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';

      await _supabase.storage
          .from(SupabaseConstants.leadFilesBucket)
          .uploadBinary(fileName, bytes);

      final url = _supabase.storage
          .from(SupabaseConstants.leadFilesBucket)
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Error uploading file to storage: $e');
      return null;
    }
  }
}
