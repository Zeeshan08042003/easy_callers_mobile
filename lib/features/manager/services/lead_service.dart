import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/employee/models/daily_report_model.dart';
import 'package:easy_callers_mobile/features/employee/models/notification_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/employee/models/lead_status_model.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for all lead-related database operations.
/// Used by Super Admin, Manager, and Employee controllers.
class LeadService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  // ============================================
  // LEAD UPLOAD & PARSING
  // ============================================

  /// Pick a file, parse leads, and upload everything to Supabase
  Future<LeadBatchModel?> pickAndUploadLeads(String managerId) async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return null;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final file = File(filePath);

      // 2. Parse Excel
      final leadsData = await _parseExcelLeads(file);
      if (leadsData.isEmpty) {
        throw 'No valid leads found in the file. Ensure you have "Name" and "Phone" columns.';
      }

      // 3. Create Lead Batch record
      final batchResponse = await _supabase.client.from('lead_batches').insert({
        'file_name': fileName,
        'total_leads': leadsData.length,
        'uploaded_by': managerId,
      }).select().single();

      final batch = LeadBatchModel.fromJson(batchResponse);

      // 4. Upload File to Storage
      final fileUrl = await _uploadToStorage(file, batch.id);
      
      // Update batch with file URL
      if (fileUrl != null) {
        await _supabase.client
            .from('lead_batches')
            .update({'file_url': fileUrl})
            .eq('id', batch.id);
      }

      // 5. Bulk Insert Leads
      final List<Map<String, dynamic>> finalLeads = leadsData.map((lead) {
        return {
          ...lead,
          'uploaded_by': managerId,
          'batch_id': batch.id,
          'status': LeadStatus.newLead.value,
        };
      }).toList();

      // Supabase supports bulk insert via list
      await _supabase.leadsTable.insert(finalLeads);

      return batch;
    } catch (e) {
      print('Error picking/uploading leads: $e');
      rethrow;
    }
  }

  /// Parse Excel file and return list of lead maps
  /// Uses intelligent column detection and phone cleaning
  Future<List<Map<String, dynamic>>> _parseExcelLeads(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> leads = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // First row is headers
      final rawHeaders = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();
      final headers = rawHeaders.map((h) => h.toLowerCase()).toList();

      // Map headers to our field names using regex
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

      if (!hasNameAfterDetection && !hasPhoneAfterDetection) {
        continue; // Skip this sheet
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

        // Database requires BOTH name AND phone (NOT NULL constraints)
        final hasName = (lead['name'] as String? ?? '').isNotEmpty;
        final hasPhone = (lead['phone'] as String? ?? '').isNotEmpty;

        // Only add if we have BOTH name AND phone
        if (hasName && hasPhone) {
          leads.add(lead);
        } else if (hasPhone && !hasName) {
          // If we have phone but no name, use a placeholder
          lead['name'] = 'Unknown';
          leads.add(lead);
          print('⚠️ Row has phone but no name, using "Unknown" as placeholder');
        } else if (hasName && !hasPhone) {
          // If we have name but no phone, skip this row
          print('⚠️ Skipping row: has name "${lead['name']}" but no phone number');
        } else {
          // No name and no phone, skip
          print('⚠️ Skipping row: no name and no phone number');
        }
      }

      // Only process the first sheet
      break;
    }
    return leads;
  }

  /// Upload file to Supabase Storage
  Future<String?> _uploadToStorage(File file, String batchId) async {
    try {
      final extension = p.extension(file.path);
      final fileName = 'batch_$batchId$extension';
      
      await _supabase.client.storage
          .from('lead-files')
          .upload(fileName, file);

      return _supabase.client.storage
          .from('lead-files')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading to storage: $e');
      return null;
    }
  }

  // ============================================
  // LEAD QUERIES
  // ============================================

  /// Get all leads uploaded by a specific manager
  Future<List<LeadModel>> getLeadsByManager(String managerId) async {
    try {
      final response = await _supabase.leadsTable
          .select('*, employees(first_name, last_name)')
          .eq('uploaded_by', managerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching leads by manager: $e');
      return [];
    }
  }

  /// Get leads assigned to a specific employee with pagination support
  Future<List<LeadModel>> getLeadsByEmployee(String employeeId, {int page = 1, int pageSize = 20}) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase.leadsTable
          .select()
          .eq('assigned_to', employeeId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getLeadsCountByEmployee(String employeeId, {LeadStatus? status}) async {
    try {
      var query = _supabase.leadsTable
          .select('id')
          .eq('assigned_to', employeeId);
      
      if (status != null) {
        query = query.eq('status', status.value);
      }
      
      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get leads by status for a manager's team
  Future<List<LeadModel>> getLeadsByStatus(
      String managerId, LeadStatus status) async {
    try {
      final response = await _supabase.leadsTable
          .select('*, employees(first_name, last_name)')
          .eq('uploaded_by', managerId)
          .eq('status', status.value)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching leads by status: $e');
      return [];
    }
  }

  /// Get unassigned leads for a manager
  Future<List<LeadModel>> getUnassignedLeads(String managerId) async {
    try {
      final response = await _supabase.leadsTable
          .select()
          .eq('uploaded_by', managerId)
          .isFilter('assigned_to', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching unassigned leads: $e');
      return [];
    }
  }

  /// Get today's follow-up leads for an employee
  Future<List<LeadModel>> getTodayFollowUps(String employeeId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get call logs with follow-up dates for today
      final callLogs = await _supabase.callLogsTable
          .select('lead_id')
          .eq('employee_id', employeeId)
          .gte('follow_up_date', todayStart.toIso8601String())
          .lt('follow_up_date', todayEnd.toIso8601String());

      final leadIds =
          (callLogs as List).map((log) => log['lead_id'] as String).toSet();

      if (leadIds.isEmpty) return [];

      final response = await _supabase.leadsTable
          .select()
          .inFilter('id', leadIds.toList());

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching today follow-ups: $e');
      return [];
    }
  }

  // ============================================
  // LEAD MUTATIONS
  // ============================================

  /// Update lead status
  Future<bool> updateLeadStatus(String leadId, LeadStatus status) async {
    try {
      await _supabase.leadsTable
          .update({'status': status.value}).eq('id', leadId);
      return true;
    } catch (e) {
      print('Error updating lead status: $e');
      return false;
    }
  }

  /// Assign a lead to an employee
  Future<bool> assignLead(String leadId, String employeeId) async {
    try {
      await _supabase.leadsTable.update({
        'assigned_to': employeeId,
        'status': LeadStatus.assigned.value,
      }).eq('id', leadId);
      return true;
    } catch (e) {
      print('Error assigning lead: $e');
      return false;
    }
  }

  /// Reassign a lead to a different employee
  Future<bool> reassignLead(String leadId, String newEmployeeId) async {
    try {
      await _supabase.leadsTable.update({
        'assigned_to': newEmployeeId,
      }).eq('id', leadId);
      return true;
    } catch (e) {
      print('Error reassigning lead: $e');
      return false;
    }
  }

  /// Get count of unattended leads for a manager's team
  /// Unattended leads are those that are assigned but have no call logs
  /// and were assigned more than 24 hours ago
  Future<int> getUnattendedLeadsCount(String managerId) async {
    try {
      // Get all employees under this manager
      final employees = await getEmployeesByManager(managerId);
      final employeeIds = employees.map((e) => e.id).toList();

      if (employeeIds.isEmpty) return 0;

      // Get leads assigned to these employees with status 'assigned'
      // that were created more than 24 hours ago
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      
      final leadsResponse = await _supabase.leadsTable
          .select('id')
          .inFilter('assigned_to', employeeIds)
          .eq('status', LeadStatus.assigned.value)
          .lt('updated_at', twentyFourHoursAgo.toIso8601String());

      final leads = (leadsResponse as List);
      
      if (leads.isEmpty) return 0;

      final leadIds = leads.map((l) => l['id'] as String).toList();
      
      // Get all lead IDs that HAVE call logs in a single query
      final logsResponse = await _supabase.callLogsTable
          .select('lead_id')
          .inFilter('lead_id', leadIds);
      
      final leadIdsWithLogs = (logsResponse as List)
          .map((log) => log['lead_id'] as String)
          .toSet();

      // Count leads that DO NOT have logs
      int unattendedCount = 0;
      for (var id in leadIds) {
        if (!leadIdsWithLogs.contains(id)) {
          unattendedCount++;
        }
      }

      return unattendedCount;
    } catch (e) {
      print('Error getting unattended leads count: $e');
      return 0;
    }
  }

  /// Get unattended leads for a manager's team
  /// Returns list of LeadModel objects that are assigned but have no call logs
  Future<List<LeadModel>> getUnattendedLeads(String managerId) async {
    try {
      // Get all employees under this manager
      final employees = await getEmployeesByManager(managerId);
      final employeeIds = employees.map((e) => e.id).toList();

      if (employeeIds.isEmpty) return [];

      // Get leads assigned to these employees with status 'assigned'
      // that were created more than 24 hours ago
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      
      final leadsResponse = await _supabase.leadsTable
          .select('*, employees(first_name, last_name)')
          .inFilter('assigned_to', employeeIds)
          .eq('status', LeadStatus.assigned.value)
          .lt('updated_at', twentyFourHoursAgo.toIso8601String());

      final leads = (leadsResponse as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
      
      if (leads.isEmpty) return [];

      final leadIds = leads.map((l) => l.id).toList();

      // Get all lead IDs that HAVE call logs in a single query
      final logsResponse = await _supabase.callLogsTable
          .select('lead_id')
          .inFilter('lead_id', leadIds);
      
      final leadIdsWithLogs = (logsResponse as List)
          .map((log) => log['lead_id'] as String)
          .toSet();

      // Filter leads that DO NOT have logs
      return leads.where((l) => !leadIdsWithLogs.contains(l.id)).toList();
    } catch (e) {
      print('Error getting unattended leads: $e');
      return [];
    }
  }

  /// Reassign unattended leads to a specific employee
  /// Returns the number of leads reassigned
  Future<int> reassignUnattendedLeadsToEmployee({
    required String managerId,
    required String targetEmployeeId,
  }) async {
    try {
      // Get unattended leads
      final unattendedLeads = await getUnattendedLeads(managerId);
      
      if (unattendedLeads.isEmpty) return 0;

      // Reassign all leads in a single bulk update
      final leadIds = unattendedLeads.map((l) => l.id).toList();
      
      await _supabase.leadsTable.update({
        'assigned_to': targetEmployeeId,
        'updated_at': DateTime.now().toIso8601String(),
      }).inFilter('id', leadIds);

      return leadIds.length;
    } catch (e) {
      print('Error reassigning unattended leads: $e');
      return 0;
    }
  }

  /// Get IDs of unassigned leads from a specific batch
  Future<List<String>> getUnassignedLeadsFromBatch(String batchId) async {
    try {
      final response = await _supabase.leadsTable
          .select('id')
          .eq('batch_id', batchId)
          .eq('status', LeadStatus.newLead.value)
          .limit(10000); // Increase limit to handle larger batches

      return (response as List).map((l) => l['id'] as String).toList();
    } catch (e) {
      print('Error fetching unassigned leads: $e');
      return [];
    }
  }

  /// Get the latest batch with unassigned leads for a manager
  /// Returns null if no batches have unassigned leads
  Future<LeadBatchModel?> getLatestBatchWithUnassignedLeads(String managerId) async {
    try {
      // Get all batches by this manager, ordered by most recent first
      final batchesResponse = await _supabase.client
          .from('lead_batches')
          .select()
          .eq('uploaded_by', managerId)
          .order('created_at', ascending: false)
          .limit(10); // Check last 10 batches

      final batches = (batchesResponse as List)
          .map((json) => LeadBatchModel.fromJson(json))
          .toList();

      // For each batch, check if it has unassigned leads
      for (final batch in batches) {
        final unassignedLeads = await getUnassignedLeadsFromBatch(batch.id);
        if (unassignedLeads.isNotEmpty) {
          // Found a batch with unassigned leads
          return batch;
        }
      }

      // No batches with unassigned leads
      return null;
    } catch (e) {
      print('Error fetching latest batch with unassigned leads: $e');
      return null;
    }
  }

  /// Bulk assign leads equally among employees
  Future<bool> splitLeadsEqually({
    required List<String> leadIds,
    required List<String> employeeIds,
  }) async {
    try {
      if (employeeIds.isEmpty || leadIds.isEmpty) return false;

      final leadsPerEmployee = leadIds.length ~/ employeeIds.length;
      final remainder = leadIds.length % employeeIds.length;

      var currentIndex = 0;

      for (var i = 0; i < employeeIds.length; i++) {
        var count = leadsPerEmployee;
        if (i < remainder) count++; // Distribute remainder

        final assignedLeadIds =
            leadIds.sublist(currentIndex, currentIndex + count);
        currentIndex += count;

        // Update in bulk for this employee
        if (assignedLeadIds.isNotEmpty) {
          await _updateLeadsInChunks(assignedLeadIds, {
            'assigned_to': employeeIds[i],
            'status': LeadStatus.assigned.value,
          });
        }
      }

      return true;
    } catch (e) {
      print('LeadService Error splitting leads: $e');
      if (e is PostgrestException) {
        print('Postgrest Details: ${e.message}, ${e.details}, ${e.hint}');
      }
      return false;
    }
  }

  /// Helper to update leads in chunks to avoid URL length limits (400 Bad Request)
  Future<void> _updateLeadsInChunks(List<String> leadIds, Map<String, dynamic> data) async {
    const int chunkSize = 30; // Even smaller chunk size to be super safe
    for (var i = 0; i < leadIds.length; i += chunkSize) {
      final chunk = leadIds.sublist(
        i, 
        i + chunkSize > leadIds.length ? leadIds.length : i + chunkSize
      );
      
      try {
        await _supabase.leadsTable.update(data).inFilter('id', chunk);
      } catch (e) {
        print('Error updating chunk $i to ${i + chunk.length}: $e');
        rethrow;
      }
    }
  }

  /// Custom split - assign specific number of leads per employee
  Future<bool> splitLeadsCustom({
    required List<String> leadIds,
    required Map<String, int> employeeLeadCounts, // employeeId -> count
  }) async {
    try {
      var currentIndex = 0;

      for (final entry in employeeLeadCounts.entries) {
        final employeeId = entry.key;
        final count = entry.value;

        final end = (currentIndex + count).clamp(0, leadIds.length);
        final assignedLeadIds = leadIds.sublist(currentIndex, end);
        currentIndex = end;

        // Update in bulk for this employee
        if (assignedLeadIds.isNotEmpty) {
          // Update in chunks to avoid URL length issues
          await _updateLeadsInChunks(assignedLeadIds, {
            'assigned_to': employeeId,
            'status': LeadStatus.assigned.value,
          });
        }
      }

      return true;
    } catch (e) {
      print('LeadService Error custom splitting leads: $e');
      if (e is PostgrestException) {
        print('Postgrest Details: ${e.message}, ${e.details}, ${e.hint}');
      }
      return false;
    }
  }

  // ============================================
  // CALL LOGS
  // ============================================

  /// Add a call log entry
  Future<CallLogModel?> addCallLog(CallLogModel callLog) async {
    try {
      final response = await _supabase.callLogsTable
          .insert(callLog.toInsertJson())
          .select()
          .single();

      // Also update the lead status based on the call outcome
      if (callLog.leadStatus != null) {
        // If it's a dynamic status (String), we need to find its mapping
        // For backward compatibility, we still support the enum
        final leadStatus = await _getLeadStatusMapping(callLog.leadStatus!);
        await updateLeadStatus(callLog.leadId, leadStatus);
      }

      return CallLogModel.fromJson(response);
    } catch (e) {
      print('Error adding call log: $e');
      return null;
    }
  }

  /// Get call logs for a specific employee
  Future<List<CallLogModel>> getCallLogsByEmployee(String employeeId,
      {int limit = 50}) async {
    try {
      final response = await _supabase.callLogsTable
          .select('*, leads(name, phone)')
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CallLogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching call logs: $e');
      return [];
    }
  }

  /// Get call logs for a specific lead
  Future<List<CallLogModel>> getCallLogsByLead(String leadId) async {
    try {
      final response = await _supabase.callLogsTable
          .select('*, employees(first_name, last_name)')
          .eq('lead_id', leadId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CallLogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching call logs for lead: $e');
      return [];
    }
  }

  /// Get the last call log for an employee (most recent call)
  Future<CallLogModel?> getLastCallByEmployee(String employeeId) async {
    try {
      final response = await _supabase.callLogsTable
          .select('*, leads(name, phone)')
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CallLogModel.fromJson(response);
    } catch (e) {
      print('Error fetching last call: $e');
      return null;
    }
  }

  /// Get employee call logs for a date range (for reports)
  Future<List<CallLogModel>> getCallLogsForDateRange({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase.callLogsTable
          .select('*, leads(name, phone)')
          .eq('employee_id', employeeId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CallLogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching call logs for date range: $e');
      return [];
    }
  }

  // ============================================
  // DAILY REPORTS
  // ============================================

  /// Get daily reports for an employee for a given month
  Future<List<DailyReportModel>> getMonthlyReports({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final response = await _supabase.dailyReportsTable
          .select()
          .eq('employee_id', employeeId)
          .gte('report_date', startDate.toIso8601String().split('T')[0])
          .lte('report_date', endDate.toIso8601String().split('T')[0])
          .order('report_date', ascending: true);

      return (response as List)
          .map((json) => DailyReportModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching monthly reports: $e');
      return [];
    }
  }

  /// Generate/update daily report for an employee (call at end of day or on demand)
  Future<DailyReportModel?> generateDailyReport({
    required String employeeId,
    DateTime? date,
  }) async {
    try {
      final reportDate = date ?? DateTime.now();
      final dayStart = DateTime(reportDate.year, reportDate.month, reportDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Fetch today's call logs
      final callLogs = await _supabase.callLogsTable
          .select()
          .eq('employee_id', employeeId)
          .gte('created_at', dayStart.toIso8601String())
          .lt('created_at', dayEnd.toIso8601String());

      final logs = (callLogs as List);

      // Calculate stats
      final totalCalls = logs.length;
      final connectedCalls =
          logs.where((l) => l['call_status'] == 'connected').length;
      final notConnectedCalls = totalCalls - connectedCalls;
      final interestedLeads =
          logs.where((l) => l['lead_status'] == 'interested').length;
      final notInterestedLeads =
          logs.where((l) => l['lead_status'] == 'not_interested').length;
      final followUps =
          logs.where((l) => l['follow_up_date'] != null).length;

      final totalDuration = logs.fold<int>(
          0, (sum, l) => sum + ((l['call_duration_seconds'] as int?) ?? 0));
      final avgDuration = totalCalls > 0 ? totalDuration ~/ totalCalls : 0;

      // Upsert the daily report
      final reportData = {
        'employee_id': employeeId,
        'report_date': dayStart.toIso8601String().split('T')[0],
        'total_calls': totalCalls,
        'connected_calls': connectedCalls,
        'not_connected_calls': notConnectedCalls,
        'interested_leads': interestedLeads,
        'not_interested_leads': notInterestedLeads,
        'follow_ups_scheduled': followUps,
        'avg_call_duration_seconds': avgDuration,
        'total_call_duration_seconds': totalDuration,
      };

      final response = await _supabase.dailyReportsTable
          .upsert(reportData, onConflict: 'employee_id,report_date')
          .select()
          .single();

      return DailyReportModel.fromJson(response);
    } catch (e) {
      print('Error generating daily report: $e');
      return null;
    }
  }

  // ============================================
  // ADVANCED ANALYTICS (Manager Reporting)
  // ============================================

  /// Get team-wide performance overview for a manager
  Future<Map<String, dynamic>> getTeamPerformanceOverview(
    String managerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      // 1. Get all employee IDs under this manager
      final employees = await getEmployeesByManager(managerId);
      final employeeIds = employees.map((e) => e.id).toList();

      if (employeeIds.isEmpty) {
        return {
          'total_calls': 0,
          'total_interested': 0,
          'avg_conversion': 0.0,
          'active_agents': 0,
        };
      }

      // 2. Fetch daily reports for all employees in range
      final reportsResponse = await _supabase.client
          .from('daily_reports')
          .select()
          .inFilter('employee_id', employeeIds)
          .gte('report_date', start.toIso8601String().split('T')[0])
          .lte('report_date', end.toIso8601String().split('T')[0]);

      final reports = reportsResponse as List;
      
      int totalCalls = 0;
      int totalInterested = 0;
      Set<String> activeAgents = {};

      for (var report in reports) {
        totalCalls += (report['total_calls'] as int? ?? 0);
        totalInterested += (report['interested_leads'] as int? ?? 0);
        activeAgents.add(report['employee_id'] as String);
      }

      double conversion = totalCalls > 0 
          ? (totalInterested / totalCalls) * 100 
          : 0.0;

      return {
        'total_calls': totalCalls,
        'total_interested': totalInterested,
        'avg_conversion': conversion,
        'active_agents': activeAgents.length,
      };
    } catch (e) {
      print('Error fetching team performance: $e');
      return {};
    }
  }

  /// Get lead distribution by status for the entire team
  Future<Map<String, int>> getTeamLeadFunnel(String managerId) async {
    try {
      // Get all leads uploaded by this manager
      final response = await _supabase.leadsTable
          .select('status')
          .eq('uploaded_by', managerId);

      final leads = response as List;
      final Map<String, int> funnel = {
        'new': 0,
        'assigned': 0,
        'connected': 0,
        'interested': 0,
        'follow_up': 0,
        'converted': 0,
      };

      for (var lead in leads) {
        final status = lead['status'] as String;
        funnel[status] = (funnel[status] ?? 0) + 1;
      }

      return funnel;
    } catch (e) {
      print('Error fetching lead funnel: $e');
      return {};
    }
  }

  /// Get daily call volume for the team (last 7 days)
  Future<List<Map<String, dynamic>>> getTeamActivityStats(String managerId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final employees = await getEmployeesByManager(managerId);
      final employeeIds = employees.map((e) => e.id).toList();

      if (employeeIds.isEmpty) return [];

      final reportsResponse = await _supabase.client
          .from('daily_reports')
          .select('report_date, total_calls')
          .inFilter('employee_id', employeeIds)
          .gte('report_date', sevenDaysAgo.toIso8601String().split('T')[0])
          .order('report_date', ascending: true);

      final reports = reportsResponse as List;
      
      // Group by date
      final Map<String, int> dailyTotals = {};
      for (var report in reports) {
        final date = report['report_date'] as String;
        final calls = report['total_calls'] as int? ?? 0;
        dailyTotals[date] = (dailyTotals[date] ?? 0) + calls;
      }

      return dailyTotals.entries.map((e) => {
        'date': e.key,
        'calls': e.value,
      }).toList();
    } catch (e) {
      print('Error fetching daily activity: $e');
      return [];
    }
  }

  // ============================================
  // EMPLOYEE MANAGEMENT (Manager queries)
  // ============================================

  /// Get all employees under a manager
  Future<List<EmployeeModel>> getEmployeesByManager(String managerId) async {
    try {
      final response = await _supabase.employeesTable
          .select()
          .eq('manager_id', managerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmployeeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  /// Deactivate an employee and notify the manager
  Future<bool> deactivateEmployee(String employeeId) async {
    try {
      await _supabase.employeesTable
          .update({'is_active': false}).eq('id', employeeId);

      return true;
    } catch (e) {
      print('Error deactivating employee: $e');
      return false;
    }
  }

  /// Get employee stats summary (for manager/employee dashboard)
  Future<Map<String, dynamic>> getEmployeeStats(String employeeId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Today's calls
      final todayLogsResponse = await _supabase.callLogsTable
          .select()
          .eq('employee_id', employeeId)
          .gte('created_at', todayStart.toIso8601String())
          .lt('created_at', todayEnd.toIso8601String());
      
      final todayLogs = todayLogsResponse as List;
      final todayCalls = todayLogs.length;
      final todayInterested =
          todayLogs.where((l) => l['lead_status'] == 'interested').length;

      // Total assigned leads
      final totalLeadsRes = await _supabase.leadsTable
          .select('id')
          .eq('assigned_to', employeeId);

      double conversionRate = todayCalls > 0 
          ? (todayInterested / todayCalls) * 100 
          : 0.0;

      return {
        'calls_today': todayCalls,
        'interested_today': todayInterested,
        'conversion_rate': conversionRate,
        'total_leads': (totalLeadsRes as List).length,
      };
    } catch (e) {
      print('Error fetching employee stats: $e');
      return {
        'calls_today': 0,
        'interested_today': 0,
        'conversion_rate': 0.0,
        'total_leads': 0,
      };
    }
  }

  /// Get leads with follow-up or callback status for an employee
  Future<List<LeadModel>> getFollowUpsByEmployee(String employeeId) async {
    try {
      final response = await _supabase.leadsTable
          .select('*, employees(first_name, last_name)')
          .eq('assigned_to', employeeId)
          .or('status.eq.follow_up,status.eq.callback')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching follow-ups: $e');
      return [];
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required UserRole userRole,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'title': title,
        'body': body,
        'type': type.value,
        'metadata': metadata ?? {},
      };

      // Set the correct foreign key based on role
      switch (userRole) {
        case UserRole.superAdmin:
          insertData['super_admin_id'] = userId;
          break;
        case UserRole.manager:
          insertData['manager_id'] = userId;
          break;
        case UserRole.employee:
          insertData['employee_id'] = userId;
          break;
      }

      await _supabase.notificationsTable.insert(insertData);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Get unread notifications for a user
  Future<List<NotificationModel>> getUnreadNotifications({
    required String userId,
    required UserRole userRole,
  }) async {
    try {
      var query = _supabase.notificationsTable
          .select()
          .eq('is_read', false);

      // Filter by the correct role column
      switch (userRole) {
        case UserRole.superAdmin:
          query = query.eq('super_admin_id', userId);
          break;
        case UserRole.manager:
          query = query.eq('manager_id', userId);
          break;
        case UserRole.employee:
          query = query.eq('employee_id', userId);
          break;
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase.notificationsTable
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  /// Get dashboard statistics for a manager
  Future<Map<String, dynamic>> getManagerDashboardStats(String managerId) async {
    try {
      // 1. Total leads uploaded by this manager
      // Use .count() with CountOption.exact to bypass 1000 row limit
      final totalLeads = await _supabase.leadsTable
          .count(CountOption.exact)
          .eq('uploaded_by', managerId);

      // 2. Assigned leads
      final assignedLeads = await _supabase.leadsTable
          .count(CountOption.exact)
          .eq('uploaded_by', managerId)
          .not('assigned_to', 'is', null);

      // 3. Performance (Converted leads / Total leads)
      final convertedLeads = await _supabase.leadsTable
          .count(CountOption.exact)
          .eq('uploaded_by', managerId)
          .eq('status', LeadStatus.converted.value);
      
      final performance = totalLeads > 0 
          ? (convertedLeads / totalLeads) * 100 
          : 0.0;

      print('📊 Dashboard Stats for $managerId: total=$totalLeads, assigned=$assignedLeads, performance=$performance');

      return {
        'totalLeads': totalLeads,
        'assignedLeads': assignedLeads,
        'performance': performance,
      };
    } catch (e) {
      print('Error fetching manager dashboard stats: $e');
      return {
        'totalLeads': 0,
        'assignedLeads': 0,
        'performance': 0.0,
      };
    }
  }

  /// Get simplified team performance for manager dashboard
  Future<List<Map<String, dynamic>>> getManagerTeamStats(String managerId) async {
    try {
      final employees = await getEmployeesByManager(managerId);
      final List<Map<String, dynamic>> teamStats = [];

      for (final emp in employees) {
        // Get today's report
        final today = DateTime.now().toIso8601String().split('T')[0];
        final reportResponse = await _supabase.client
            .from('daily_reports')
            .select()
            .eq('employee_id', emp.id)
            .eq('report_date', today)
            .maybeSingle();

        int callsCount = 0;
        double progress = 0.0;
        int statusColor = 0xFFF59E0B; // Orange (Away/Idle) by default

        if (reportResponse != null) {
          callsCount = reportResponse['total_calls'] ?? 0;
          // Progress is calls / daily target (mocked target of 50)
          progress = (callsCount / 50).clamp(0.0, 1.0);
          if (callsCount > 0) statusColor = 0xFF10B981; // Green (Active)
        }

        teamStats.add({
          'name': emp.fullName,
          'calls': '$callsCount Calls',
          'progress': progress,
          'status': callsCount > 0 ? 'Active' : 'Idle',
          'statusColor': statusColor,
        });
      }

      return teamStats;
    } catch (e) {
      print('Error fetching team stats: $e');
      return [];
    }
  }

  // ============================================
  // SUPER ADMIN QUERIES
  // ============================================

  /// Get global system stats for Super Admin
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final results = await Future.wait([
        _supabase.managersTable.select('id'),
        _supabase.employeesTable.select('id'),
        _supabase.leadsTable.select('id'),
        _supabase.callLogsTable.select('id'),
      ]);

      return {
        'manager_count': (results[0] as List).length,
        'employee_count': (results[1] as List).length,
        'lead_count': (results[2] as List).length,
        'call_count': (results[3] as List).length,
      };
    } catch (e) {
      print('Error fetching global stats: $e');
      return {
        'manager_count': 0,
        'employee_count': 0,
        'lead_count': 0,
        'call_count': 0,
      };
    }
  }

  /// Get all managers (for Super Admin)
  Future<List<ManagerModel>> getAllManagers() async {
    try {
      final response = await _supabase.managersTable
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ManagerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching managers: $e');
      return [];
    }
  }

  /// Get all employees across all managers (for Super Admin)
  Future<List<EmployeeModel>> getAllEmployees() async {
    try {
      final response = await _supabase.employeesTable
          .select('*, managers(first_name, last_name)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmployeeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all employees: $e');
      return [];
    }
  }

  /// Get all leads across the system (for Super Admin)
  Future<List<LeadModel>> getAllLeads({int limit = 100}) async {
    try {
      final response = await _supabase.leadsTable
          .select(
              '*, employees(first_name, last_name), managers(first_name, last_name)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all leads: $e');
      return [];
    }
  }

  /// Get cross-agency performance comparison (for Super Admin)
  Future<List<Map<String, dynamic>>> getRegionalPerformance() async {
    try {
      final managers = await getAllManagers();
      final List<Map<String, dynamic>> regionalData = [];

      for (var manager in managers) {
        // Fetch stats for each manager branch
        final leadsResponse = await _supabase.leadsTable
            .select('id')
            .eq('uploaded_by', manager.id);
        
        final leads = leadsResponse as List;
        
        final employees = await getEmployeesByManager(manager.id);
        final employeeIds = employees.map((e) => e.id).toList();

        int totalCalls = 0;
        if (employeeIds.isNotEmpty) {
           final callsResponse = await _supabase.callLogsTable
              .select('id')
              .inFilter('employee_id', employeeIds);
           totalCalls = (callsResponse as List).length;
        }

        regionalData.add({
          'manager_name': manager.fullName,
          'lead_count': leads.length,
          'employee_count': employees.length,
          'call_count': totalCalls,
          'conversion_rate': totalCalls > 0 ? (leads.length / totalCalls) * 100 : 0.0,
        });
      }

      return regionalData;
    } catch (e) {
      print('Error fetching regional performance: $e');
      return [];
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  // ============================================
  // DYNAMIC LEAD STATUSES
  // ============================================

  /// Get available lead statuses for a manager/employee
  Future<List<LeadStatusModel>> getLeadStatuses(String? managerId) async {
    try {
      var query = _supabase.client.from('lead_statuses').select().eq('is_active', true);
      
      if (managerId != null) {
        // Fetch global statuses (manager_id is null) OR statuses for this specific manager
        query = query.or('manager_id.is.null,manager_id.eq.$managerId');
      } else {
        query = query.isFilter('manager_id', null);
      }

      final response = await query.order('created_at', ascending: true);
      return (response as List).map((json) => LeadStatusModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching lead statuses: $e');
      return [];
    }
  }

  Future<LeadStatus> _getLeadStatusMapping(dynamic callLeadStatus) async {
    if (callLeadStatus is CallLeadStatus) {
      return _mapCallLeadStatusToLeadStatus(callLeadStatus);
    }
    
    // If it's a string, look it up in the database or use a fallback
    final statusValue = callLeadStatus.toString();
    try {
      final response = await _supabase.client
          .from('lead_statuses')
          .select('lead_status_mapping')
          .eq('value', statusValue)
          .maybeSingle();
      
      if (response != null && response['lead_status_mapping'] != null) {
        return LeadStatus.fromString(response['lead_status_mapping']);
      }
    } catch (e) {
       print('Error getting lead status mapping for $statusValue: $e');
    }

    return LeadStatus.followUp; // Default fallback
  }

  LeadStatus _mapCallLeadStatusToLeadStatus(CallLeadStatus callLeadStatus) {
    switch (callLeadStatus) {
      case CallLeadStatus.interested:
        return LeadStatus.interested;
      case CallLeadStatus.notInterested:
        return LeadStatus.notInterested;
      case CallLeadStatus.followUp:
        return LeadStatus.followUp;
      case CallLeadStatus.callback:
        return LeadStatus.followUp;
      case CallLeadStatus.visiting:
        return LeadStatus.converted;
      case CallLeadStatus.closed:
        return LeadStatus.closed;
    }
  }

  // ============================================
  // EXCEL PARSING HELPER METHODS
  // ============================================

  /// Known column types that we skip (serial numbers, etc.)
  static const _skipHeaders = {
    'sr no', 'sr no.', 'sr.no', 'sr.no.', 's.no', 's no', 'sno',
    'serial', 'serial no', 'serial no.', '#', 'no.', 'sl no', 'sl no.',
  };

  /// Map column headers to our field names using regex patterns
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
  bool _isPhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-().]'), '');
    
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      return digits.length >= 7 && digits.length <= 15;
    }
    
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
  bool _isName(String value) {
    if (value.length < 2 || value.length > 100) return false;
    
    final nameRegex = RegExp(r"^[a-zA-Z\s.'\-]+$", caseSensitive: false);
    if (!nameRegex.hasMatch(value)) return false;
    
    final letterCount = value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return letterCount >= 2;
  }
}
