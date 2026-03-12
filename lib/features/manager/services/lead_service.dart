import 'dart:convert';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/employee/models/daily_report_model.dart';
import 'package:easy_callers_mobile/features/employee/models/notification_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/employee/models/lead_status_model.dart';
import 'package:easy_callers_mobile/core/services/web_service.dart';
export 'package:easy_callers_mobile/core/services/web_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

extension LeadServiceApi on WebService {

  // ============================================
  // LEAD QUERIES
  // ============================================

  Future<WebResponse<LeadModel>> getLeadById(String leadId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['leads', leadId],
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(
        apiResponse: apiResponse,
        payload: LeadModel.fromJson(data['data']),
      );
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<LeadModel>>> getLeadsByManager(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<LeadModel>>> getLeadsByEmployee(String employeeId, {int page = 1, int pageSize = 20, String? projectId, LeadStatus? status}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': pageSize.toString(),
    };
    if (projectId != null) queryParams['project_id'] = projectId;
    if (status != null) queryParams['status'] = status.value;

    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'leads'],
      params: queryParams,
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<int>> getLeadsCountByEmployee(String employeeId, {LeadStatus? status, String? projectId}) async {
    final queryParams = {'per_page': '1'};
    if (projectId != null) queryParams['project_id'] = projectId;
    if (status != null) queryParams['status'] = status.value;

    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'leads'],
      params: queryParams,
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: data['data']['total'] ?? 0);
    }
    return WebResponse(apiResponse: apiResponse, payload: 0);
  }

  Future<WebResponse<List<LeadModel>>> getLeadsByStatus(String managerId, LeadStatus status) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: {'status': status.value},
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<LeadModel>>> getUnassignedLeads(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: {'unassigned': 'true'},
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<LeadModel>>> getTodayFollowUps(String employeeId, {String? projectId}) async {
    final queryParams = {'follow_up': 'today'};
    if (projectId != null) queryParams['project_id'] = projectId;

    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'leads'],
      params: queryParams,
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  // ============================================
  // LEAD MUTATIONS
  // ============================================

  Future<WebResponse<bool>> updateLeadStatus(String leadId, LeadStatus status) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.PUT,
      path: ['employee', 'leads', leadId, 'status'],
      body: {'status': status.value},
    );
    return WebResponse(
      apiResponse: apiResponse, 
      payload: apiResponse.status == API_STATUS.SUCCESS,
    );
  }

  Future<WebResponse<bool>> assignLead(String leadId, String employeeId) async {
    return _assignLeadsBatch([leadId], employeeId);
  }

  Future<WebResponse<bool>> reassignLead(String leadId, String newEmployeeId) async {
    return _assignLeadsBatch([leadId], newEmployeeId);
  }

  Future<WebResponse<bool>> splitLeadsEqually({
    required List<String> leadIds,
    required List<String> employeeIds,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.POST,
      path: ['manager', 'leads', 'distribute'],
      body: {
        'lead_ids': leadIds,
        'employee_ids': employeeIds,
      },
    );
    return WebResponse(
      apiResponse: apiResponse,
      payload: apiResponse.status == API_STATUS.SUCCESS,
    );
  }

  Future<WebResponse<bool>> splitLeadsCustom({
    required List<String> leadIds,
    required Map<String, int> employeeLeadCounts,
  }) async {
    try {
      for (final entry in employeeLeadCounts.entries) {
          final count = entry.value;
          final empId = entry.key;
          
          if (count == 0 || leadIds.isEmpty) continue;
          
          final end = (count).clamp(0, leadIds.length);
          final assignedLeadIds = leadIds.sublist(0, end);
          leadIds.removeRange(0, end);

          if (assignedLeadIds.isNotEmpty) {
            await _assignLeadsBatch(assignedLeadIds, empId);
          }
      }
      return WebResponse(apiResponse: ApiResponse(status: API_STATUS.SUCCESS), payload: true);
    } catch (e) {
      return WebResponse(apiResponse: ApiResponse(status: API_STATUS.FAIL), payload: false);
    }
  }

  Future<WebResponse<bool>> _assignLeadsBatch(List<String> leadIds, String employeeId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.PUT,
      path: ['manager', 'leads', 'assign-batch'],
      body: {
        'lead_ids': leadIds,
        'assigned_to': employeeId,
      },
    );
    return WebResponse(
      apiResponse: apiResponse,
      payload: apiResponse.status == API_STATUS.SUCCESS
    );
  }

  // ============================================
  // UNATTENDED LEADS
  // ============================================

  Future<WebResponse<int>> getUnattendedLeadsCount(String managerId) async {
    final response = await getUnattendedLeads(managerId);
    return WebResponse(apiResponse: response.apiResponse, payload: response.payload?.length ?? 0);
  }

  Future<WebResponse<List<LeadModel>>> getUnattendedLeads(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: {'unattended': 'true'},
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<int>> reassignUnattendedLeadsToEmployee({
    required String managerId,
    required String targetEmployeeId,
  }) async {
     final leadsResponse = await getUnattendedLeads(managerId);
     if (leadsResponse.payload == null || leadsResponse.payload!.isEmpty) {
        return WebResponse(apiResponse: leadsResponse.apiResponse, payload: 0);
     }
     final leadIds = leadsResponse.payload!.map((l) => l.id).toList();
     final successResponse = await _assignLeadsBatch(leadIds, targetEmployeeId);
     return WebResponse(
        apiResponse: successResponse.apiResponse, 
        payload: (successResponse.payload == true) ? leadIds.length : 0
     );
  }

  // ============================================
  // BATCH QUERIES
  // ============================================

  Future<WebResponse<List<String>>> getUnassignedLeadsFromBatch(String batchId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'batches', batchId, 'unassigned'],
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final leads = data['data'] as List;
      final list = leads.map((l) => l['id'].toString()).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<String>>> getUnassignedLeadsForProject(String projectId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: {
        'unassigned': 'true',
        'project_id': projectId,
      },
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => json['id'].toString()).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<LeadBatchModel?>> getLatestBatchWithUnassignedLeads(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'batches'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final batches = (data['data'] as List).map((x) => LeadBatchModel.fromJson(x)).toList();

      for (var batch in batches) {
        final unassignedResponse = await getUnassignedLeadsFromBatch(batch.id);
        if (unassignedResponse.payload != null && unassignedResponse.payload!.isNotEmpty) {
          return WebResponse(apiResponse: apiResponse, payload: batch);
        }
      }
      return WebResponse(apiResponse: apiResponse, payload: null);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<LeadBatchModel?>> getLatestBatchWithUnassignedLeadsForProject({
    String? managerId,
    required String projectId,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'batches'], 
      params: {'project_id': projectId},
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final batches = (data['data'] as List).map((x) => LeadBatchModel.fromJson(x)).toList();

      for (var batch in batches) {
        final unassignedResponse = await getUnassignedLeadsFromBatch(batch.id);
        if (unassignedResponse.payload != null && unassignedResponse.payload!.isNotEmpty) {
          return WebResponse(apiResponse: apiResponse, payload: batch);
        }
      }
      return WebResponse(apiResponse: apiResponse, payload: null);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<bool>> deleteLeadBatch(String batchId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.DELETE,
      path: ['manager', 'batches', batchId],
    );
    return WebResponse(apiResponse: apiResponse, payload: apiResponse.status == API_STATUS.SUCCESS);
  }

  // ============================================
  // PROJECT STATS / LEAD STATUS
  // ============================================

  Future<WebResponse<Map<String, dynamic>>> getProjectDashboardStats({
    String? managerId,
    required String projectId,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'dashboard'],  
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: data['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: {'totalLeads': 0, 'assignedLeads': 0, 'performance': 0.0});
  }

  Future<WebResponse<Map<String, int>>> getProjectStatusCounts({
    required String projectId,
    String? managerId,
    bool todayOnly = false,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['projects', projectId, 'stats'],  
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: Map<String, int>.from(data['data']));
    }
    return WebResponse(apiResponse: apiResponse, payload: {'follow_up': 0, 'visiting': 0, 'visit_completed': 0, 'converted': 0, 'all': 0});
  }

  Future<WebResponse<List<LeadModel>>> getProjectLeadsByStatus({
    required String projectId,
    required String status,
    String? managerId,
    bool todayOnly = false,
  }) async {
    final queryParams = <String, String>{
      'project_id': projectId,
      'status': status,
      if (todayOnly) 'today': 'true',
    };
    
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: queryParams,
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<LeadModel>>> getProjectLeads(String projectId, {String? managerId}) async {
    final queryParams = {'project_id': projectId};
    
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'leads'], 
      params: queryParams,
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((json) => LeadModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  // ============================================
  // CALL LOGS
  // ============================================

  Future<WebResponse<CallLogModel>> addCallLog(CallLogModel callLog) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.POST,
      path: ['employee', 'calls'],
      body: callLog.toInsertJson(),
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: CallLogModel.fromJson(data['data']));
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<CallLogModel>>> getCallLogsByEmployee(String employeeId, {int limit = 200}) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'employees', employeeId, 'calls'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final items = data['data']['data'] ?? data['data']; 
      final list = (items as List).map((json) => CallLogModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<List<CallLogModel>>> getCallLogsByLead(String leadId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['leads', leadId, 'calls'],
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((json) => CallLogModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<CallLogModel?>> getLastCallByEmployee(String employeeId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'calls'], 
      params: {'limit': '1'},
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final items = data['data']['data'] as List;
      if (items.isNotEmpty) {
        return WebResponse(apiResponse: apiResponse, payload: CallLogModel.fromJson(items.first));
      }
    }
    return WebResponse(apiResponse: apiResponse, payload: null);
  }

  Future<WebResponse<CallLogModel?>> getLastCallByManager(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'calls', 'latest'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      if (data['data'] != null) {
        return WebResponse(apiResponse: apiResponse, payload: CallLogModel.fromJson(data['data']));
      }
    }
    return WebResponse(apiResponse: apiResponse, payload: null);
  }

  Future<WebResponse<List<CallLogModel>>> getCallLogsForDateRange({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'employees', employeeId, 'calls'], 
      params: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        if (projectId != null) 'project_id': projectId,
      }
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final items = data['data']['data'] ?? data['data']; 
      final list = (items as List).map((json) => CallLogModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  // ============================================
  // DAILY REPORTS
  // ============================================

  Future<WebResponse<List<DailyReportModel>>> getMonthlyReports({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'reports'], 
      params: {
        'year': year.toString(),
        'month': month.toString(),
      }
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((json) => DailyReportModel.fromJson(json)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse);
  }

  Future<WebResponse<DailyReportModel>> generateDailyReport({
    required String employeeId,
    DateTime? date,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.POST,
      path: ['employee', 'reports', 'generate'],
      body: {
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      }
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: DailyReportModel.fromJson(data['data']));
    }
    return WebResponse(apiResponse: apiResponse);
  }

  // ============================================
  // ADVANCED ANALYTICS (Manager Reporting)
  // ============================================

  Future<WebResponse<Map<String, dynamic>>> getTeamPerformanceOverview(
    String managerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'performance'], 
      params: {
         if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
         if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
      }
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: data['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: { 'total_calls': 0, 'total_interested': 0, 'avg_conversion': 0.0, 'active_agents': 0 });
  }

  Future<WebResponse<Map<String, int>>> getTeamLeadFunnel(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'funnel'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: Map<String, int>.from(data['data']));
    }
    return WebResponse(apiResponse: apiResponse, payload: { 'new': 0, 'assigned': 0, 'connected': 0, 'interested': 0, 'follow_up': 0, 'converted': 0 });
  }

  Future<WebResponse<List<Map<String, dynamic>>>> getTeamActivityStats(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'activity'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: List<Map<String,dynamic>>.from(data['data']));
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  // ============================================
  // EMPLOYEE MANAGEMENT (Manager queries)
  // ============================================

  Future<WebResponse<List<EmployeeModel>>> getEmployeesByManager(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'employees'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((j) => EmployeeModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<List<EmployeeModel>>> getProjectCallersByManager({
    required String projectId,
    required String managerId,
  }) async {
    return getEmployeesByManager(managerId);
  }

  Future<WebResponse<bool>> deactivateEmployee(String employeeId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.DELETE,
      path: ['manager', 'employees', employeeId], 
    );
    return WebResponse(apiResponse: apiResponse, payload: apiResponse.status == API_STATUS.SUCCESS);
  }

  Future<WebResponse<Map<String, dynamic>>> getEmployeeStats(String employeeId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['employee', 'analytics', 'dashboard'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      return WebResponse(apiResponse: apiResponse, payload: data['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: {
      'calls_today': 0, 'interested_today': 0, 'conversion_rate': 0.0,
      'total_leads': 0, 'total_calls': 0, 'interested_leads': 0, 'callback_leads': 0,
    });
  }

  Future<WebResponse<List<LeadModel>>> getFollowUpsByEmployee(String employeeId) async {
    return getTodayFollowUps(employeeId);
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<WebResponse<bool>> createNotification({
    required String userId,
    required UserRole userRole,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? metadata,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.POST,
      path: ['notifications'],
      body: {
          'title': title,
          'body': body,
          'type': type.value,
          'metadata': metadata,
      }
    );
    return WebResponse(apiResponse: apiResponse, payload: apiResponse.status == API_STATUS.SUCCESS);
  }

  Future<WebResponse<List<NotificationModel>>> getUnreadNotifications({
    required String userId,
    required UserRole userRole,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['notifications'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((j) => NotificationModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<bool>> markNotificationRead(String notificationId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.POST,
      path: ['notifications', notificationId, 'read'],
    );
    return WebResponse(apiResponse: apiResponse, payload: apiResponse.status == API_STATUS.SUCCESS);
  }

  // ============================================
  // MANAGER DASHBOARD VIEWS
  // ============================================

  Future<WebResponse<Map<String, dynamic>>> getManagerDashboardStats(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'dashboard'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      return WebResponse(apiResponse: apiResponse, payload: jsonDecode(apiResponse.stringData!)['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: { 'totalLeads': 0, 'assignedLeads': 0, 'performance': 0.0 });
  }

  Future<WebResponse<List<Map<String, dynamic>>>> getManagerTeamStats(String managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['manager', 'analytics', 'team'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      return WebResponse(apiResponse: apiResponse, payload: List<Map<String,dynamic>>.from(jsonDecode(apiResponse.stringData!)['data']));
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<List<double>>> getWeeklyDistribution(String managerId) async {
    return WebResponse(apiResponse: ApiResponse(status: API_STATUS.SUCCESS), payload: List.filled(6, 0.0));
  }

  // ============================================
  // SUPER ADMIN QUERIES
  // ============================================

  Future<WebResponse<Map<String, dynamic>>> getGlobalStats({String? projectId, String? superAdminId}) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'analytics', 'dashboard'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      return WebResponse(apiResponse: apiResponse, payload: jsonDecode(apiResponse.stringData!)['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: { 'manager_count': 0, 'employee_count': 0, 'lead_count': 0, 'agency_count': 0, 'call_count': 0 });
  }

  Future<WebResponse<List<ManagerModel>>> getAllManagers({String? currentSuperAdminId}) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'managers'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((j) => ManagerModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<List<ManagerModel>>> getNetworkManagers({required String currentSuperAdminId}) async {
    return getAllManagers();
  }

  Future<WebResponse<List<ManagerModel>>> getAllManagersAndAgencies({String? currentSuperAdminId}) async {
    return getAllManagers();
  }

  Future<WebResponse<List<EmployeeModel>>> getAllEmployees() async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'employees'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((j) => EmployeeModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<List<EmployeeModel>>> getEmployeesByProject(String projectId) async {
    return WebResponse(apiResponse: ApiResponse(status: API_STATUS.SUCCESS), payload: []);
  }

  Future<WebResponse<List<LeadModel>>> getAllLeads({int limit = 100}) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'leads'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data']['data'] as List).map((j) => LeadModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<List<Map<String, dynamic>>>> getRegionalPerformance({
    String? projectId,
    String? currentSuperAdminId,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'analytics', 'regional'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      return WebResponse(apiResponse: apiResponse, payload: List<Map<String,dynamic>>.from(jsonDecode(apiResponse.stringData!)['data']));
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }

  Future<WebResponse<Map<String, dynamic>>> getManagerAnalytics({
    required String managerId,
    required String period, 
    String? currentSuperAdminId,
  }) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['sa', 'managers', managerId, 'analytics'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      return WebResponse(apiResponse: apiResponse, payload: jsonDecode(apiResponse.stringData!)['data']);
    }
    return WebResponse(apiResponse: apiResponse, payload: {'error': 'Failed'});
  }

  // ============================================
  // LEAD STATUS
  // ============================================

  Future<WebResponse<List<LeadStatusModel>>> getLeadStatuses(String? managerId) async {
    final apiResponse = await callApi(
      method: HTTP_METHODS.GET,
      path: ['systems', 'statuses'], 
    );
    if (apiResponse.status == API_STATUS.SUCCESS) {
      final data = jsonDecode(apiResponse.stringData!);
      final list = (data['data'] as List).map((j) => LeadStatusModel.fromJson(j)).toList();
      return WebResponse(apiResponse: apiResponse, payload: list);
    }
    return WebResponse(apiResponse: apiResponse, payload: []);
  }
}
