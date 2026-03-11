import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
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

  /// Delete a lead batch and all its associated leads
  Future<bool> deleteLeadBatch(String batchId) async {
    try {
      // 1. Delete all leads associated with this batch
      // We do this first because the FK is ON DELETE SET NULL, 
      // but we want the leads GONE when the batch is deleted.
      await _supabase.leadsTable
          .delete()
          .eq('batch_id', batchId);

      // 2. Delete the batch record
      await _supabase.client
          .from('lead_batches')
          .delete()
          .eq('id', batchId);

      return true;
    } catch (e) {
      print('Error deleting lead batch: $e');
      return false;
    }
  }

  // ============================================
  // BACKGROUND-COMPATIBLE UPLOAD METHODS
  // ============================================

  /// Pick a file without starting the upload.
  /// Returns the FilePickerResult so the caller can start the upload later.
  Future<FilePickerResult?> pickFileOnly() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
  }

  /// Upload leads from an already-picked file (no project).
  /// Accepts a progress callback for background upload tracking.
  Future<LeadBatchModel?> pickAndUploadLeadsFromResult({
    required FilePickerResult pickerResult,
    required String managerId,
    void Function(double)? onProgress,
  }) async {
    try {
      if (pickerResult.files.single.path == null) return null;

      final filePath = pickerResult.files.single.path!;
      final fileName = pickerResult.files.single.name;
      final file = File(filePath);

      onProgress?.call(0.1);

      // 1. Parse Excel
      final leadsData = await _parseExcelLeads(file);
      if (leadsData.isEmpty) {
        throw 'No valid leads found in the file. Ensure you have "Name" and "Phone" columns.';
      }
      onProgress?.call(0.3);

      // 2. Create Lead Batch record
      final batchResponse = await _supabase.client.from('lead_batches').insert({
        'file_name': fileName,
        'total_leads': leadsData.length,
        'uploaded_by': managerId,
      }).select().single();

      final batch = LeadBatchModel.fromJson(batchResponse);
      onProgress?.call(0.4);

      // 3. Upload File to Storage
      final fileUrl = await _uploadToStorage(file, batch.id);
      if (fileUrl != null) {
        await _supabase.client
            .from('lead_batches')
            .update({'file_url': fileUrl})
            .eq('id', batch.id);
      }
      onProgress?.call(0.5);

      // 4. Bulk Insert Leads in chunks
      final List<Map<String, dynamic>> finalLeads = leadsData.map((lead) {
        return {
          ...lead,
          'uploaded_by': managerId,
          'batch_id': batch.id,
          'status': LeadStatus.newLead.value,
        };
      }).toList();

      await _insertLeadsInChunks(finalLeads, onProgress, 0.5, 1.0);

      onProgress?.call(1.0);
      return batch;
    } catch (e) {
      print('Error uploading leads: $e');
      rethrow;
    }
  }

  /// Upload leads from an already-picked file to a specific project.
  /// Accepts a progress callback for background upload tracking.
  Future<LeadBatchModel?> pickAndUploadLeadsToProjectFromResult({
    required FilePickerResult pickerResult,
    String? managerId,
    required String projectId,
    void Function(double)? onProgress,
  }) async {
    try {
      if (pickerResult.files.single.path == null) return null;

      final filePath = pickerResult.files.single.path!;
      final fileName = pickerResult.files.single.name;
      final file = File(filePath);

      onProgress?.call(0.1);

      // 1. Parse Excel
      final leadsData = await _parseExcelLeads(file);
      if (leadsData.isEmpty) {
        throw 'No valid leads found in the file. Ensure you have "Name" and "Phone" columns.';
      }
      onProgress?.call(0.3);

      // 2. Create Lead Batch record WITH project_id
      final batchResponse = await _supabase.client.from('lead_batches').insert({
        'file_name': fileName,
        'total_leads': leadsData.length,
        'uploaded_by': managerId,
        'project_id': projectId,
      }).select().single();

      final batch = LeadBatchModel.fromJson(batchResponse);
      onProgress?.call(0.4);

      // 3. Upload File to Storage
      final fileUrl = await _uploadToStorage(file, batch.id);
      if (fileUrl != null) {
        await _supabase.client
            .from('lead_batches')
            .update({'file_url': fileUrl})
            .eq('id', batch.id);
      }
      onProgress?.call(0.5);

      // 4. Bulk Insert Leads WITH project_id in chunks
      final List<Map<String, dynamic>> finalLeads = leadsData.map((lead) {
        return {
          ...lead,
          'uploaded_by': managerId,
          'batch_id': batch.id,
          'project_id': projectId,
          'status': LeadStatus.newLead.value,
        };
      }).toList();

      await _insertLeadsInChunks(finalLeads, onProgress, 0.5, 1.0);

      onProgress?.call(1.0);
      return batch;
    } catch (e) {
      print('Error uploading leads to project: $e');
      rethrow;
    }
  }

  /// Insert leads in chunks of 100, reporting progress between progressStart and progressEnd.
  Future<void> _insertLeadsInChunks(
    List<Map<String, dynamic>> leads,
    void Function(double)? onProgress,
    double progressStart,
    double progressEnd,
  ) async {
    const chunkSize = 100;
    for (var i = 0; i < leads.length; i += chunkSize) {
      final end = (i + chunkSize < leads.length) ? i + chunkSize : leads.length;
      final chunk = leads.sublist(i, end);
      await _supabase.leadsTable.insert(chunk);

      final progress = progressStart +
          (progressEnd - progressStart) * (end / leads.length);
      onProgress?.call(progress);
    }
  }

  /// Pick a file, parse leads, and upload to a specific project
  Future<LeadBatchModel?> pickAndUploadLeadsToProject({
    String? managerId,
    required String projectId,
  }) async {
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

      // 3. Create Lead Batch record WITH project_id
      final batchResponse = await _supabase.client.from('lead_batches').insert({
        'file_name': fileName,
        'total_leads': leadsData.length,
        'uploaded_by': managerId,
        'project_id': projectId,
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

      // 5. Bulk Insert Leads WITH project_id
      final List<Map<String, dynamic>> finalLeads = leadsData.map((lead) {
        return {
          ...lead,
          'uploaded_by': managerId,
          'batch_id': batch.id,
          'project_id': projectId,
          'status': LeadStatus.newLead.value,
        };
      }).toList();

      // Supabase supports bulk insert via list
      await _supabase.leadsTable.insert(finalLeads);

      return batch;
    } catch (e) {
      print('Error picking/uploading leads to project: $e');
      rethrow;
    }
  }

  /// Parse Excel file and return list of lead maps
  /// Uses intelligent column detection and phone cleaning
  Future<List<Map<String, dynamic>>> _parseExcelLeads(File file) async {
    final bytes = await file.readAsBytes();
    // Use compute to run CPU-intensive parsing in a background isolate
    return await compute(ExcelParser.parseExcel, bytes);
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

  /// Get a single lead by its ID
  Future<LeadModel?> getLeadById(String leadId) async {
    try {
      final response = await _supabase.leadsTable
          .select()
          .eq('id', leadId)
          .maybeSingle();
      
      if (response == null) return null;
      return LeadModel.fromJson(response);
    } catch (e) {
      print('Error fetching lead by ID: $e');
      return null;
    }
  }

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
  Future<List<LeadModel>> getLeadsByEmployee(String employeeId, {int page = 1, int pageSize = 20, String? projectId, LeadStatus? status}) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      print('📋 getLeadsByEmployee: empId=$employeeId, page=$page, projectId=$projectId, status=${status?.value}');

      var query = _supabase.leadsTable
          .select()
          .eq('assigned_to', employeeId);
      
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      if (status != null) {
        query = query.eq('status', status.value);
      }
          
      final response = await query.order('created_at', ascending: false).range(from, to);

      print("✅ getLeadsByEmployee: returned ${response.length} leads");

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getLeadsByEmployee ERROR: $e');
      if (e is PostgrestException) {
        print('   Postgrest: code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      }
      return [];
    }
  }

  Future<int> getLeadsCountByEmployee(String employeeId, {LeadStatus? status, String? projectId}) async {
    try {
      var query = _supabase.leadsTable
          .select('id')
          .eq('assigned_to', employeeId);
      
      if (status != null) {
        query = query.eq('status', status.value);
      }
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      
      final response = await query;
      print("response of getLeadsCountByEmployee :- ${response.length}");
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
  Future<List<LeadModel>> getTodayFollowUps(String employeeId, {String? projectId}) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get call logs with follow-up dates up to today (includes overdue)
      final callLogs = await _supabase.callLogsTable
          .select('lead_id')
          .eq('employee_id', employeeId)
          .lt('follow_up_date', todayEnd.toIso8601String());

      final leadIds =
          (callLogs as List).map((log) => log['lead_id'] as String).toSet().toList();

      final List<String> followUpStatuses = [
        LeadStatus.followUp.value,
        'callback',
        'visiting',
      ];

      // Build query for leads
      var query = _supabase.leadsTable.select();
      
      if (leadIds.isNotEmpty) {
        // Leads that have a scheduled date OR are in a follow-up status
        // and belong to this employee
        query = query.or('id.in.(${leadIds.join(",")}),status.in.(${followUpStatuses.join(",")})');
      } else {
        // Only leads in follow-up statuses
        query = query.inFilter('status', followUpStatuses);
      }

      query = query.eq('assigned_to', employeeId);
          
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final response = await query;
      print('getTodayFollowUps: found ${(response as List).length} follow-ups for $employeeId');

      return response
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
          .eq('status', LeadStatus.newLead.value.toLowerCase())
          .limit(10000); // Increase limit to handle larger batches

      print("response is ${response.length}");
      print("batch id : $batchId}");
      return (response as List).map((l) => l['id'] as String).toList();
    } catch (e) {
      print('Error fetching unassigned leads: $e');
      return [];
    }
  }

  /// Get ALL unassigned lead IDs across ALL batches in a project
  Future<List<String>> getUnassignedLeadsForProject(String projectId) async {
    try {
      final response = await _supabase.leadsTable
          .select('id')
          .eq('project_id', projectId)
          .eq('status', LeadStatus.newLead.value.toLowerCase())
          .limit(50000);

      return (response as List).map((l) => l['id'] as String).toList();
    } catch (e) {
      print('Error fetching unassigned leads for project: $e');
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

  /// Get the latest batch with unassigned leads for a specific project
  Future<LeadBatchModel?> getLatestBatchWithUnassignedLeadsForProject({
    String? managerId,
    required String projectId,
  }) async {
    try {
      var query = _supabase.client
          .from('lead_batches')
          .select()
          .eq('project_id', projectId);

      if (managerId != null) {
        query = query.eq('uploaded_by', managerId);
      }

      final batchesResponse = await query
          .order('created_at', ascending: false)
          .limit(10);

      final batches = (batchesResponse as List)
          .map((json) => LeadBatchModel.fromJson(json))
          .toList();

      for (final batch in batches) {
        final unassignedLeads = await getUnassignedLeadsFromBatch(batch.id);
        if (unassignedLeads.isNotEmpty) {
          return batch;
        }
      }

      return null;
    } catch (e) {
      print('Error fetching latest batch for project: $e');
      return null;
    }
  }

  /// Get dashboard statistics for a specific project
  Future<Map<String, dynamic>> getProjectDashboardStats({
    String? managerId,
    required String projectId,
  }) async {
    try {
      // Fetch manager's employees to include leads assigned to them for filtering
      List<String> employeeIds = [];
      if (managerId != null) {
        final employees = await getEmployeesByManager(managerId);
        employeeIds = employees.map((e) => e.id).toList();
      }

      // 1. Total leads in this project (optionally filtered by manager)
      var totalQuery = _supabase.leadsTable
          .count(CountOption.exact)
          .eq('project_id', projectId);
      
      if (managerId != null) {
        if (employeeIds.isNotEmpty) {
          totalQuery = totalQuery.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
        } else {
          totalQuery = totalQuery.eq('uploaded_by', managerId);
        }
      }
      final totalLeads = await totalQuery;

      // 2. Assigned leads in this project
      var assignedQuery = _supabase.leadsTable
          .count(CountOption.exact)
          .eq('project_id', projectId)
          .not('assigned_to', 'is', null);

      if (managerId != null) {
        if (employeeIds.isNotEmpty) {
          assignedQuery = assignedQuery.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
        } else {
          assignedQuery = assignedQuery.eq('uploaded_by', managerId);
        }
      }
      final assignedLeads = await assignedQuery;

      // 3. Performance (Contacted / Assigned)
      var uncontactedQuery = _supabase.leadsTable
          .count(CountOption.exact)
          .eq('project_id', projectId)
          .not('assigned_to', 'is', null)
          .inFilter('status', ['new', 'assigned']);

      if (managerId != null) {
        if (employeeIds.isNotEmpty) {
          uncontactedQuery = uncontactedQuery.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
        } else {
          uncontactedQuery = uncontactedQuery.eq('uploaded_by', managerId);
        }
      }
      final uncontactedLeads = await uncontactedQuery;

      final contactedLeads = assignedLeads - uncontactedLeads;
      final performance = assignedLeads > 0
          ? (contactedLeads / assignedLeads) * 100
          : 0.0;

      return {
        'totalLeads': totalLeads,
        'assignedLeads': assignedLeads,
        'performance': performance,
      };
    } catch (e) {
      print('Error fetching project dashboard stats: $e');
      return {
        'totalLeads': 0,
        'assignedLeads': 0,
        'performance': 0.0,
      };
    }
  }

  /// Get status-specific counts for a project
  Future<Map<String, int>> getProjectStatusCounts({
    required String projectId,
    String? managerId,
    bool todayOnly = false,
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      // Fetch manager's employees to include leads assigned to them
      List<String> employeeIds = [];
      if (managerId != null) {
        final employees = await getEmployeesByManager(managerId);
        employeeIds = employees.map((e) => e.id).toList();
      }

      Future<int> countStatus(String status) async {
        var query = _supabase.leadsTable
            .count(CountOption.exact)
            .eq('project_id', projectId)
            .eq('status', status);
            
        if (todayOnly) {
          query = query.gte('updated_at', todayStart);
        }

        if (managerId != null) {
          if (employeeIds.isNotEmpty) {
            // Include leads uploaded by manager OR assigned to their team
            query = query.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
          } else {
            query = query.eq('uploaded_by', managerId);
          }
        }
        
        return await query;
      }

      final results = await Future.wait([
        countStatus('follow_up'),
        countStatus('visiting'),
        countStatus('visit_completed'),
        countStatus('converted'),
        // Total leads for this project/manager combo
        () async {
          var query = _supabase.leadsTable
              .count(CountOption.exact)
              .eq('project_id', projectId);
          
          if (managerId != null) {
            final employees = await getEmployeesByManager(managerId);
            final employeeIds = employees.map((e) => e.id).toList();
            if (employeeIds.isNotEmpty) {
              query = query.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
            } else {
              query = query.eq('uploaded_by', managerId);
            }
          }
          return await query;
        }(),
      ]);

      return {
        'follow_up': results[0],
        'visiting': results[1],
        'visit_completed': results[2],
        'converted': results[3],
        'all': results[4],
      };
    } catch (e) {
      print('Error fetching project status counts: $e');
      return {
        'follow_up': 0,
        'visiting': 0,
        'visit_completed': 0,
        'converted': 0,
      };
    }
  }

  Future<List<LeadModel>> getProjectLeadsByStatus({
    required String projectId,
    required String status,
    String? managerId,
    bool todayOnly = false,
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      var query = _supabase.leadsTable
          .select('*, employees:assigned_to(first_name, last_name), managers:uploaded_by(first_name, last_name)')
          .eq('project_id', projectId)
          .eq('status', status);

      if (todayOnly) {
        query = query.gte('updated_at', todayStart);
      }

      if (managerId != null) {
        final employees = await getEmployeesByManager(managerId);
        final employeeIds = employees.map((e) => e.id).toList();
        
        if (employeeIds.isNotEmpty) {
          query = query.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
        } else {
          query = query.eq('uploaded_by', managerId);
        }
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching leads by status: $e');
      return [];
    }
  }

  /// Fetch all leads for a project
  Future<List<LeadModel>> getProjectLeads(String projectId, {String? managerId}) async {
    try {
      var query = _supabase.leadsTable
          .select('*, employees:assigned_to(first_name, last_name), managers:uploaded_by(first_name, last_name)')
          .eq('project_id', projectId);

      if (managerId != null) {
        final employees = await getEmployeesByManager(managerId);
        final employeeIds = employees.map((e) => e.id).toList();
        
        if (employeeIds.isNotEmpty) {
          query = query.or('uploaded_by.eq.$managerId,assigned_to.in.(${employeeIds.map((id) => '"$id"').join(",")})');
        } else {
          query = query.eq('uploaded_by', managerId);
        }
      }

      final response = await query
          .order('updated_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching project leads: $e');
      return [];
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
        final leadStatus = await _getLeadStatusMapping(callLog.leadStatus!);
        
        final Map<String, dynamic> updates = {
          'status': leadStatus.value,
        };

        // If visit completed, lead moves to manager (unassigned from employee)
        if (leadStatus == LeadStatus.visitCompleted) {
          updates['assigned_to'] = null;
        }

        await _supabase.leadsTable.update(updates).eq('id', callLog.leadId);
      }

      return CallLogModel.fromJson(response);
    } catch (e) {
      print('Error adding call log: $e');
      return null;
    }
  }

  /// Get call logs for a specific employee
  Future<List<CallLogModel>> getCallLogsByEmployee(String employeeId,
      {int limit = 200}) async {
    try {
      final response = await _supabase.callLogsTable
          .select('*, leads!left(name, phone)')
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false)
          .limit(limit);

      print('getCallLogsByEmployee: fetched ${(response as List).length} logs for $employeeId');

      return response
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

  /// Get the most recent call log across all employees under a manager
  Future<CallLogModel?> getLastCallByManager(String managerId) async {
    try {
      // Get all employees for this manager
      final employees = await getEmployeesByManager(managerId);
      if (employees.isEmpty) return null;

      final employeeIds = employees.map((e) => e.id).toList();

      final response = await _supabase.callLogsTable
          .select('*, leads!left(name, phone), employees!left(first_name, last_name)')
          .inFilter('employee_id', employeeIds)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CallLogModel.fromJson(response);
    } catch (e) {
      print('Error fetching last call for manager: $e');
      return null;
    }
  }

  /// Get employee call logs for a date range (for reports)
  Future<List<CallLogModel>> getCallLogsForDateRange({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
  }) async {
    try {
      var selectQuery = '*, leads!inner(name, phone)';
      if (projectId != null) {
        selectQuery = '*, leads!inner(name, phone, project_id)';
      }

      var query = _supabase.callLogsTable
          .select(selectQuery)
          .eq('employee_id', employeeId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (projectId != null) {
        query = query.eq('leads.project_id', projectId);
      }

      final response = await query.order('created_at', ascending: false);

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

  /// Get only the active callers (employees) who are assigned to a specific project
  /// by a specific manager. Used when distributing leads in project context.
  Future<List<EmployeeModel>> getProjectCallersByManager({
    required String projectId,
    required String managerId,
  }) async {
    try {
      // Query project_callers table for this project
      final response = await _supabase.client
          .from('project_callers')
          .select('''
            *,
            employee:employee_id(*)
          ''')
          .eq('project_id', projectId);

      final list = response as List;
      print('📋 getProjectCallersByManager: Found ${list.length} project_callers rows for project $projectId');
      
      final result = <EmployeeModel>[];
      final skipped = <String>[];
      
      for (final row in list) {
        if (row['employee'] == null || row['employee'] is! Map) {
          print('  ⚠️ Skipping row — employee data is null or invalid');
          continue;
        }
        
        final empJson = row['employee'] as Map<String, dynamic>;
        final emp = EmployeeModel.fromJson(empJson);
        final addedBy = row['added_by_manager_id'] as String?;
        
        print('  👤 Caller: ${emp.fullName} (id=${emp.id}), '
            'emp.managerId=${emp.managerId}, addedBy=$addedBy, '
            'isActive=${emp.isActive}, lookingForManager=$managerId');
        
        // Include if employee is active AND belongs to this manager's context:
        // 1. employee's manager_id matches the current manager
        // 2. OR the employee was specifically added to this project by this manager
        // 3. OR added_by_manager_id is null (added by SA — should still be visible 
        //    to the manager who is a member of this project)
        if (!emp.isActive) {
          skipped.add('${emp.fullName} (inactive)');
          continue;
        }
        
        final belongsToManager = emp.managerId == managerId;
        final addedByManager = addedBy == managerId;
        final addedByOther = addedBy != null && addedBy != managerId;
        
        // Include if: belongs to manager, or was added by this manager,
        // or was added by someone else (SA) but the employee is under this manager
        if (belongsToManager || addedByManager || (!addedByOther && addedBy == null)) {
          result.add(emp);
        } else {
          skipped.add('${emp.fullName} (manager mismatch: emp.managerId=${emp.managerId}, addedBy=$addedBy)');
        }
      }
      
      print('✅ Returning ${result.length} callers, skipped: $skipped');
      return result;
    } catch (e) {
      print('❌ Error fetching project callers by manager: $e');
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
          .select('id, status')
          .eq('assigned_to', employeeId);
      final allLeads = totalLeadsRes as List;

      // Status breakdowns
      final interestedLeads = allLeads.where((l) => l['status'] == 'interested').length;
      final callbackLeads = allLeads.where((l) =>
          l['status'] == 'callback' || l['status'] == 'follow_up').length;

      // Total calls (all time)
      final totalCallsRes = await _supabase.callLogsTable
          .select('id')
          .eq('employee_id', employeeId);
      final totalCalls = (totalCallsRes as List).length;

      double conversionRate = todayCalls > 0 
          ? (todayInterested / todayCalls) * 100 
          : 0.0;

      return {
        'calls_today': todayCalls,
        'interested_today': todayInterested,
        'conversion_rate': conversionRate,
        'total_leads': allLeads.length,
        'total_calls': totalCalls,
        'interested_leads': interestedLeads,
        'callback_leads': callbackLeads,
      };
    } catch (e) {
      print('Error fetching employee stats: $e');
      return {
        'calls_today': 0,
        'interested_today': 0,
        'conversion_rate': 0.0,
        'total_leads': 0,
        'total_calls': 0,
        'interested_leads': 0,
        'callback_leads': 0,
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
        case UserRole.agency:
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
        case UserRole.agency:
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

      // 3. Performance (Contacted leads / Assigned leads)
      // Any lead assigned that is no longer 'new' or 'assigned' is considered contacted
      final uncontactedLeads = await _supabase.leadsTable
          .count(CountOption.exact)
          .eq('uploaded_by', managerId)
          .not('assigned_to', 'is', null)
          .inFilter('status', ['new', 'assigned']);
          
      final contactedLeads = assignedLeads - uncontactedLeads;
      
      final performance = assignedLeads > 0 
          ? (contactedLeads / assignedLeads) * 100 
          : 0.0;

      print('📊 Dashboard Stats for $managerId: total=$totalLeads, assigned=$assignedLeads, contacted=$contactedLeads, performance=$performance');

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

      if (employees.isEmpty) return [];

      final employeeIds = employees.map((e) => e.id).toList();
      
      // Get today start
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final logsResponse = await _supabase.callLogsTable
          .select('employee_id')
          .inFilter('employee_id', employeeIds)
          .gte('created_at', todayStart);

      final Map<String, int> employeeCallCounts = {};
      for (final e in employees) {
        employeeCallCounts[e.id] = 0;
      }
      
      for (final log in logsResponse as List) {
        final empId = log['employee_id'] as String;
        if (employeeCallCounts.containsKey(empId)) {
          employeeCallCounts[empId] = employeeCallCounts[empId]! + 1;
        }
      }

      for (final emp in employees) {
        final callsCount = employeeCallCounts[emp.id] ?? 0;
        final progress = (callsCount / 50).clamp(0.0, 1.0);
        final statusColor = callsCount > 0 ? 0xFF10B981 : 0xFFF59E0B;

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

  /// Get weekly distribution data for the manager's team (Monday-Saturday)
  Future<List<double>> getWeeklyDistribution(String managerId) async {
    try {
      final employees = await getEmployeesByManager(managerId);
      if (employees.isEmpty) return List.filled(6, 0.0);
      final employeeIds = employees.map((e) => e.id).toList();

      final now = DateTime.now();
      final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
      final monday = now.subtract(Duration(days: currentDay - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final sunday = startOfWeek.add(const Duration(days: 6));
      final endOfWeek = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

      final response = await _supabase.callLogsTable
          .select('created_at')
          .inFilter('employee_id', employeeIds)
          .gte('created_at', startOfWeek.toIso8601String())
          .lte('created_at', endOfWeek.toIso8601String());

      final List<int> dailyCounts = List.filled(6, 0);
      for (final log in response as List) {
        final date = DateTime.parse(log['created_at']);
        if (date.weekday >= 1 && date.weekday <= 6) {
          dailyCounts[date.weekday - 1]++;
        }
      }

      int maxCount = 0;
      for (final count in dailyCounts) {
        if (count > maxCount) maxCount = count;
      }

      if (maxCount == 0) return List.filled(6, 0.0);

      // Normalize to 0.0 ... 1.0
      return dailyCounts.map((count) => count / maxCount).toList();

    } catch (e) {
      print('Error calculating weekly distribution: $e');
      return List.filled(6, 0.0);
    }
  }

  // ============================================
  // SUPER ADMIN QUERIES
  // ============================================

  /// Get global system stats for Super Admin
  Future<Map<String, dynamic>> getGlobalStats({String? projectId, String? superAdminId}) async {
    try {
      if (projectId != null) {
        // Stats for a specific project
      final results = await Future.wait([
        // Unique employees from project_callers
        _supabase.projectCallersTable.select('employee_id').eq('project_id', projectId),
        // Leads for this project
        _supabase.leadsTable.select('id').eq('project_id', projectId),
        // Call logs for this project (join with leads to filter by project_id)
        _supabase.callLogsTable
            .select('id, leads!inner(project_id)')
            .eq('leads.project_id', projectId),
      ]);

        // In a project, we count unique managers and agencies from project_members
      final membersResponse = await _supabase.projectMembersTable
          .select('manager:manager_id(manager_type)')
          .eq('project_id', projectId);
      
      final members = membersResponse as List;
      final int managerCountInProject = members
          .where((m) => m['manager'] != null && m['manager']['manager_type'] == 'manager')
          .length;
      final int agencyCountInProject = members
          .where((m) => m['manager'] != null && m['manager']['manager_type'] == 'agency')
          .length;

      return {
        'manager_count': managerCountInProject,
        'employee_count': (results[0] as List).map((e) => e['employee_id']).toSet().length,
        'lead_count': (results[1] as List).length,
        'agency_count': agencyCountInProject,
        'call_count': (results[2] as List).length,
      };
      }

      // ── SA-scoped stats ──
      if (superAdminId != null) {
        // 1. Get only managers created by this SA (agencies excluded)
        final managersResponse = await _supabase.managersTable
            .select('id')
            .eq('is_active', true)
            .eq('created_by_super_admin_id', superAdminId);
        final managerIds = (managersResponse as List).map((m) => m['id'] as String).toList();

        // 2. Get employees under those managers
        int employeeCount = 0;
        if (managerIds.isNotEmpty) {
          final empResponse = await _supabase.employeesTable
              .select('id')
              .inFilter('manager_id', managerIds);
          employeeCount = (empResponse as List).length;
        }

        // 3. Get leads from this SA's projects only
        final projectsResponse = await _supabase.projectsTable
            .select('id')
            .eq('created_by_super_admin_id', superAdminId);
        final projectIds = (projectsResponse as List).map((p) => p['id'] as String).toList();

        int leadCount = 0;
        if (projectIds.isNotEmpty) {
          final leadsResponse = await _supabase.leadsTable
              .select('id')
              .inFilter('project_id', projectIds);
          leadCount = (leadsResponse as List).length;
        }

        // 4. Get agency count (independent) - Only those in at least one of this SA's projects
      int agencyCount = 0;
      if (projectIds.isNotEmpty) {
        final membersResponse = await _supabase.projectMembersTable
            .select('manager:manager_id(id, manager_type)')
            .inFilter('project_id', projectIds);
        
        final members = membersResponse as List;
        agencyCount = members
            .where((m) => m['manager'] != null && m['manager']['manager_type'] == 'agency')
            .map((m) => m['manager']['id'])
            .toSet()
            .length;
      }

      return {
        'manager_count': managerIds.length,
        'employee_count': employeeCount,
        'lead_count': leadCount,
        'agency_count': agencyCount,
        'call_count': 0, // skip expensive call count for dashboard
      };
      }

      // Fallback: unscoped global stats (should not be used for SA dashboards)
    final results = await Future.wait([
      _supabase.managersTable.select('id').eq('manager_type', 'manager'),
      _supabase.employeesTable.select('id'),
      _supabase.leadsTable.select('id'),
      _supabase.managersTable.select('id').eq('manager_type', 'agency'),
    ]);

    return {
      'manager_count': (results[0] as List).length,
      'employee_count': (results[1] as List).length,
      'lead_count': (results[2] as List).length,
      'agency_count': (results[3] as List).length,
      'call_count': 0,
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

  /// Get managers created by this Super Admin only (no agencies).
  Future<List<ManagerModel>> getAllManagers({String? currentSuperAdminId}) async {
    try {
      var query = _supabase.managersTable.select();
      
      if (currentSuperAdminId != null) {
        // Only managers created by this SA — agencies are separate
        // No is_active filter: show both active and inactive managers
        query = query.eq('created_by_super_admin_id', currentSuperAdminId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ManagerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching managers: $e');
      return [];
    }
  }

  /// Get the "network" of managers for a Super Admin:
  /// Their own created managers + independent agencies that are in any of their projects.
  Future<List<ManagerModel>> getNetworkManagers({required String currentSuperAdminId}) async {
    try {
      // 1. Get managers created by this SA
      final myManagers = await getAllManagers(currentSuperAdminId: currentSuperAdminId);
      
      // 2. Get agencies invited to their projects
      final projectsResponse = await _supabase.projectsTable
          .select('id')
          .eq('created_by_super_admin_id', currentSuperAdminId);
      final projectIds = (projectsResponse as List).map((p) => p['id'] as String).toList();
      
      if (projectIds.isEmpty) return myManagers;

      final membersResponse = await _supabase.projectMembersTable
          .select('manager:manager_id(*)')
          .inFilter('project_id', projectIds);
      
      final invitedMembers = membersResponse as List;
      final Set<String> myManagerIds = myManagers.map((m) => m.id).toSet();
      
      final invitedAgencies = invitedMembers
          .where((m) => m['manager'] != null && m['manager']['manager_type'] == 'agency')
          .map((m) => ManagerModel.fromJson(m['manager']))
          .where((agency) => !myManagerIds.contains(agency.id))
          .toList();

      // De-duplicate invited agencies across multiple projects
      final Map<String, ManagerModel> uniqueAgencies = {};
      for (var agency in invitedAgencies) {
        uniqueAgencies[agency.id] = agency;
      }

      return [...myManagers, ...uniqueAgencies.values];
    } catch (e) {
      print('Error fetching network managers: $e');
      return [];
    }
  }

  /// Get both SA-created managers AND independent agencies (for invite sheets).
  Future<List<ManagerModel>> getAllManagersAndAgencies({String? currentSuperAdminId}) async {
    try {
      var query = _supabase.managersTable.select().eq('is_active', true);
      
      if (currentSuperAdminId != null) {
        query = query.or('created_by_super_admin_id.eq.$currentSuperAdminId,created_by_super_admin_id.is.null');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ManagerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching managers and agencies: $e');
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

  /// Get all employees assigned to a project across all managers
  Future<List<EmployeeModel>> getEmployeesByProject(String projectId) async {
    try {
      final response = await _supabase.projectCallersTable
          .select('*, employee:employee_id(*, manager:manager_id(first_name, last_name))')
          .eq('project_id', projectId);
      
      return (response as List)
          .where((pc) => pc['employee'] != null)
          .map((pc) => EmployeeModel.fromJson(pc['employee']))
          .toList();
    } catch (e) {
      print('Error fetching project employees: $e');
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
  Future<List<Map<String, dynamic>>> getRegionalPerformance({
    String? projectId,
    String? currentSuperAdminId,
  }) async {
    try {
      List<ManagerModel> managers;
      if (projectId != null) {
        // ... (existing project logic)
        final memberData = await _supabase.projectMembersTable
            .select('manager:manager_id(*)')
            .eq('project_id', projectId)
            .eq('status', 'accepted');
        
        managers = (memberData as List)
            .where((m) => m['manager'] != null)
            .map((m) => ManagerModel.fromJson(m['manager']))
            .toList();
      } else {
        managers = await getAllManagers(currentSuperAdminId: currentSuperAdminId);
      }

      final List<Map<String, dynamic>> regionalData = [];

      for (var manager in managers) {
        // Enforce visibility rule: 
        // SA sees all if they created the manager OR if manager allowed it.
        final bool isVisible = manager.createdBySuperAdminId == currentSuperAdminId || 
                              manager.isSaVisible;
        
        if (!isVisible) {
          regionalData.add({
            'manager_name': manager.fullName,
            'lead_count': 0,
            'employee_count': 0,
            'call_count': 0,
            'conversion_rate': 0.0,
            'is_private': true,
          });
          continue;
        }

        // Fetch stats for each manager branch
        var leadsQuery = _supabase.leadsTable.select('id').eq('uploaded_by', manager.id);
        if (projectId != null) {
          leadsQuery = leadsQuery.eq('project_id', projectId);
        }
        
        final leadsResponse = await leadsQuery;
        final leads = leadsResponse as List;
        
        final employees = await getEmployeesByManager(manager.id);
        final employeeIds = employees.map((e) => e.id).toList();

        int totalCalls = 0;
        if (employeeIds.isNotEmpty) {
           var callsQuery = _supabase.callLogsTable.select('id');
           
           if (projectId != null) {
              // Join with leads to filter calls by project
              callsQuery = _supabase.callLogsTable
                  .select('id, leads!inner(project_id)')
                  .eq('leads.project_id', projectId);
           }
           
           final callsResponse = await callsQuery.inFilter('employee_id', employeeIds);
           totalCalls = (callsResponse as List).length;
        }

        regionalData.add({
          'manager_name': manager.fullName,
          'lead_count': leads.length,
          'employee_count': employees.length,
          'call_count': totalCalls,
          'conversion_rate': totalCalls > 0 ? (leads.length / totalCalls) * 100 : 0.0,
          'is_private': false,
        });
      }

      return regionalData;
    } catch (e) {
      print('Error fetching regional performance: $e');
      return [];
    }
  }

  /// Get comprehensive manager analytics for Super Admin Oversight
  Future<Map<String, dynamic>> getManagerAnalytics({
    required String managerId,
    required String period, // 'daily', 'weekly', 'yearly'
    String? currentSuperAdminId,
  }) async {
    try {
      // 1. Fetch the manager to check visibility
      final managerResponse = await _supabase.managersTable
          .select()
          .eq('id', managerId)
          .single();
      
      final manager = ManagerModel.fromJson(managerResponse);
      final bool isVisible = manager.createdBySuperAdminId == currentSuperAdminId || 
                            manager.isSaVisible;

      if (!isVisible) {
        return {'is_private': true};
      }

      // 2. Fetch Timeframe Data
      DateTime start;
      final now = DateTime.now();
      if (period == 'daily') {
        start = DateTime(now.year, now.month, now.day);
      } else if (period == 'weekly') {
        start = now.subtract(const Duration(days: 7));
      } else {
        // yearly
        start = DateTime(now.year, 1, 1);
      }

      // 3. Fetch Lead Statuses Distribution
      final leadsResponse = await _supabase.leadsTable
          .select('status')
          .eq('uploaded_by', managerId);
      
      final leads = leadsResponse as List;
      final Map<String, int> statusCounts = {};
      for (var l in leads) {
        final s = (l['status'] ?? 'new').toString();
        statusCounts[s] = (statusCounts[s] ?? 0) + 1;
      }

      // 4. Fetch Employee Performance
      final employees = await getEmployeesByManager(managerId);
      final List<Map<String, dynamic>> employeeStats = [];

      for (var emp in employees) {
        final callLogs = await _supabase.callLogsTable
            .select('id, lead_status')
            .eq('employee_id', emp.id)
            .gte('created_at', start.toIso8601String());
        
        final logs = callLogs as List;
        final connectedCount = logs.length;
        final interestedCount = logs.where((l) => l['lead_status'] == 'interested').length;

        employeeStats.add({
          'id': emp.id,
          'name': emp.fullName,
          'profile_image_url': emp.profileImageUrl,
          'calls': connectedCount,
          'conversion': connectedCount > 0 ? (interestedCount / connectedCount * 100).round() : 0,
          'status': emp.isActive ? 'Active' : 'Inactive',
        });
      }

      // 5. Calculate overall conversion for timeframe
      int totalCalls = 0;
      int totalInterested = 0;
      for (var stats in employeeStats) {
        totalCalls += (stats['calls'] as int);
        totalInterested += ((stats['calls'] as int) * (stats['conversion'] as int) / 100).round();
      }

      return {
        'is_private': false,
        'conversion_rate': totalCalls > 0 ? (totalInterested / totalCalls * 100) : 0.0,
        'status_counts': statusCounts,
        'employees': employeeStats,
        'total_leads': leads.length,
      };
    } catch (e) {
      print('Error fetching manager analytics: $e');
      return {'error': e.toString()};
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
      case CallLeadStatus.followUp:
        return LeadStatus.followUp;
      case CallLeadStatus.notInterested:
        return LeadStatus.notInterested;
      case CallLeadStatus.visiting:
        return LeadStatus.visiting;
      case CallLeadStatus.visitCompleted:
        return LeadStatus.visitCompleted;
      case CallLeadStatus.converted:
        return LeadStatus.converted;
      case CallLeadStatus.drop:
        return LeadStatus.drop;
    }
  }


}

/// Helper class to parse Excel files in a background isolate (compute)
class ExcelParser {
  static const Set<String> _skipHeaders = {
    'sr no', 'sr no.', 'sr.no', 'sr.no.', 's.no', 's no', 'sno',
    'serial', 'serial no', 'serial no.', '#', 'no.', 'sl no', 'sl no.',
  };

  static Future<List<Map<String, dynamic>>> parseExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> leads = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.rows.isEmpty) continue;

      final rawHeaders = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();
      final headers = rawHeaders.map((h) => h.toLowerCase()).toList();

      var columnMap = _mapColumns(headers);

      final hasName = columnMap['name'] != null || columnMap['first_name'] != null;
      final hasPhone = columnMap['phone'] != null;

      if (!hasName && !hasPhone && sheet.rows.length > 1) {
        columnMap = _detectColumnsByContent(sheet, rawHeaders);
      }

      final hasNameAfterDetection = columnMap['name'] != null || columnMap['first_name'] != null;
      final hasPhoneAfterDetection = columnMap['phone'] != null;

      if (!hasNameAfterDetection && !hasPhoneAfterDetection) {
        continue;
      }

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final lead = <String, dynamic>{};

        for (final entry in columnMap.entries) {
          if (entry.value != null && entry.value! < row.length) {
            final cellValue = row[entry.value!]?.value?.toString().trim();
            if (cellValue != null && cellValue.isNotEmpty) {
              if (entry.key == 'phone') {
                lead[entry.key] = _extractPhoneNumbers(cellValue);
              } else {
                lead[entry.key] = cellValue;
              }
            }
          }
        }

        if (!lead.containsKey('name') || (lead['name'] as String? ?? '').isEmpty) {
          final firstName = (lead.remove('first_name') as String?) ?? '';
          final lastName = (lead.remove('last_name') as String?) ?? '';
          final combined = '$firstName $lastName'.trim();
          if (combined.isNotEmpty) {
            lead['name'] = combined;
          }
        } else {
          lead.remove('first_name');
          lead.remove('last_name');
        }

        final hasNameRow = (lead['name'] as String? ?? '').isNotEmpty;
        final phones = lead['phone'] as List<String>? ?? [];
        final hasPhoneRow = phones.isNotEmpty;

        if (hasNameRow && hasPhoneRow) {
          leads.add(lead);
        } else if (hasPhoneRow && !hasNameRow) {
          lead['name'] = 'Unknown';
          leads.add(lead);
        }
      }
      break;
    }
    return leads;
  }

  static Map<String, int?> _mapColumns(List<String> headers) {
    final map = <String, int?>{
      'name': null, 'first_name': null, 'last_name': null, 'phone': null,
      'email': null, 'location': null, 'project_name': null, 'budget': null,
      'source': null, 'notes': null,
    };

    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (_skipHeaders.contains(h)) continue;

      if (_matchesRegex(h, r'^(first[\s_-]?name|f[\s_-]?name|fname)$')) {
        map['first_name'] = i;
      } else if (_matchesRegex(h, r'^(last[\s_-]?name|l[\s_-]?name|lname|surname|sur[\s_-]?name)$')) {
        map['last_name'] = i;
      } else if (_matchesRegex(h, r'^(name|full[\s_-]?name|client[\s_-]?name|customer[\s_-]?name|lead[\s_-]?name|contact[\s_-]?name|party[\s_-]?name|buyer[\s_-]?name|owner[\s_-]?name|client|customer|contact)$')) {
        map['name'] = i;
      } else if (_matchesRegex(h, r'^(phone|mobile|cell|tel|telephone|mob|contact|whatsapp|ph|number|no)[\s_-]?(number|no|num)?\.?$')) {
        map['phone'] = i;
      } else if (_matchesRegex(h, r'^(email|e[\s_-]?mail|mail)[\s_-]?(address|id)?$')) {
        map['email'] = i;
      } else if (_matchesRegex(h, r'^(location|city|area|address|region|locality|place|town|district|state|pincode|pin[\s_-]?code|zip|postal)$')) {
        map['location'] = i;
      } else if (_matchesRegex(h, r'^(project|property|scheme|flat|plot|site|tower)[\s_-]?(name)?$')) {
        map['project_name'] = i;
      } else if (_matchesRegex(h, r'^(budget|amount|price|investment|range|cost|value)[\s_-]?(range)?$')) {
        map['budget'] = i;
      } else if (_matchesRegex(h, r'^(source|lead[\s_-]?source|channel|platform|origin|via|campaign|medium|portal)$')) {
        map['source'] = i;
      } else if (_matchesRegex(h, r'^(notes?|remarks?|comments?|description|observation|feedback|status|requirement)$')) {
        map['notes'] = i;
      }
    }
    return map;
  }

  static bool _matchesRegex(String header, String pattern) {
    final regex = RegExp(pattern, caseSensitive: false);
    return regex.hasMatch(header);
  }

  static String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[()-.]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = '+' + cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    }
    return cleaned;
  }

  static List<String> _extractPhoneNumbers(String value) {
    if (value.isEmpty) return [];
    final parts = value.split(RegExp(r'[,;/|]'));
    final List<String> cleanedPhones = [];
    for (var part in parts) {
      final cleaned = _cleanPhoneNumber(part.trim());
      if (cleaned.isNotEmpty && _isPhoneNumber(cleaned)) {
        cleanedPhones.add(cleaned);
      }
    }
    return cleanedPhones;
  }

  static Map<String, int?> _detectColumnsByContent(dynamic sheet, List<String> rawHeaders) {
    final map = <String, int?>{'name': null, 'phone': null, 'email': null};
    final sampleSize = sheet.rows.length > 6 ? 6 : sheet.rows.length;
    final columnScores = <int, Map<String, int>>{};
    for (var colIdx = 0; colIdx < rawHeaders.length; colIdx++) {
      columnScores[colIdx] = {'phone': 0, 'email': 0, 'name': 0};
    }
    for (var rowIdx = 1; rowIdx < sampleSize; rowIdx++) {
      final row = sheet.rows[rowIdx];
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        final cellValue = row[colIdx]?.value?.toString().trim() ?? '';
        if (cellValue.isEmpty) continue;
        if (_isPhoneNumber(cellValue)) {
          columnScores[colIdx]!['phone'] = columnScores[colIdx]!['phone']! + 1;
        } else if (_isEmail(cellValue)) {
          columnScores[colIdx]!['email'] = columnScores[colIdx]!['email']! + 1;
        } else if (_isName(cellValue)) {
          columnScores[colIdx]!['name'] = columnScores[colIdx]!['name']! + 1;
        }
      }
    }
    var maxPhoneScore = 0; var phoneColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (scores['phone']! > maxPhoneScore) { maxPhoneScore = scores['phone']!; phoneColIdx = colIdx; }
    });
    if (phoneColIdx >= 0 && maxPhoneScore > 0) map['phone'] = phoneColIdx;
    var maxEmailScore = 0; var emailColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (colIdx != phoneColIdx && scores['email']! > maxEmailScore) { maxEmailScore = scores['email']!; emailColIdx = colIdx; }
    });
    if (emailColIdx >= 0 && maxEmailScore > 0) map['email'] = emailColIdx;
    var maxNameScore = 0; var nameColIdx = -1;
    columnScores.forEach((colIdx, scores) {
      if (colIdx != phoneColIdx && colIdx != emailColIdx && scores['name']! > maxNameScore) { maxNameScore = scores['name']!; nameColIdx = colIdx; }
    });
    if (nameColIdx >= 0 && maxNameScore > 0) map['name'] = nameColIdx;
    return map;
  }

  static bool _isPhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-().]'), '');
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      return digits.length >= 7 && digits.length <= 15;
    }
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15 && digits.length == cleaned.length;
  }

  static bool _isEmail(String value) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', caseSensitive: false).hasMatch(value);
  }

  static bool _isName(String value) {
    if (value.length < 2 || value.length > 100) return false;
    if (!RegExp(r"^[a-zA-Z\s.'\-]+$", caseSensitive: false).hasMatch(value)) return false;
    return value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length >= 2;
  }
}
