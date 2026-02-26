import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';

/// Represents a manager in the project with team stats for this batch
class BatchManagerInfo {
  final String managerId;
  final String managerName;
  final List<String> employeeIds;
  final int totalLeads;       // leads assigned to this manager's team
  final int assignedLeads;    // how many from this batch went to their team
  final int unassignedLeads;  // uploaded but not yet assigned
  final int followUpCount;
  final int visitingCount;
  final int visitCompletedCount;
  final int convertedCount;

  BatchManagerInfo({
    required this.managerId,
    required this.managerName,
    required this.employeeIds,
    required this.totalLeads,
    required this.assignedLeads,
    required this.unassignedLeads,
    required this.followUpCount,
    required this.visitingCount,
    required this.visitCompletedCount,
    required this.convertedCount,
  });

  bool get hasAssigned => assignedLeads > 0;
  int get totalVisits => visitingCount + visitCompletedCount;
  double get assignmentRate =>
      totalLeads > 0 ? (assignedLeads / totalLeads) * 100 : 0;
}

class SABatchAnalyticsController extends GetxController
    with GetTickerProviderStateMixin {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  late final LeadBatchModel batch;
  late final TabController tabController;

  final RxBool isLoading = true.obs;
  final RxBool isLoadingLeads = false.obs;

  // Project managers with team stats
  final RxList<BatchManagerInfo> managers = <BatchManagerInfo>[].obs;
  final Rx<BatchManagerInfo?> selectedManager = Rx<BatchManagerInfo?>(null);

  // Stored batch-level totals
  int _batchFollowUp = 0;
  int _batchVisiting = 0;
  int _batchVisitCompleted = 0;
  int _batchConverted = 0;

  // Displayed stats (change with manager selection)
  final RxInt totalBatchLeads = 0.obs;
  final RxInt totalAssigned = 0.obs;
  final RxInt totalFollowUp = 0.obs;
  final RxInt totalVisiting = 0.obs;
  final RxInt totalVisitCompleted = 0.obs;
  final RxInt totalConverted = 0.obs;

  // Leads list for selected tab
  final RxList<LeadModel> filteredLeads = <LeadModel>[].obs;
  final RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    batch = Get.arguments as LeadBatchModel;
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTab.value = tabController.index;
        _fetchLeadsForTab();
      }
    });
    refreshData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      await _fetchProjectManagers();
      _showOverallStats();
      await _fetchLeadsForTab();
    } catch (e) {
      print('Error loading batch analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 1. Get all managers in this project
  /// 2. For each manager, get their employees
  /// 3. Count leads in this batch assigned to those employees
  Future<void> _fetchProjectManagers() async {
    try {
      // Get the project ID from the batch
      final projectId = batch.projectId;
      if (projectId == null) return;

      // Step 1: Get accepted project members (managers)
      final membersResponse = await _supabase.client
          .from('project_members')
          .select('manager_id, manager:manager_id(id, first_name, last_name)')
          .eq('project_id', projectId)
          .eq('status', 'accepted');

      final membersList = membersResponse as List;

      // Step 2: Get all leads from this batch
      final leadsResponse = await _supabase.leadsTable
          .select('id, status, assigned_to, uploaded_by')
          .eq('batch_id', batch.id);

      final batchLeads = leadsResponse as List;

      // Overall batch totals
      int bTotal = batchLeads.length;
      int bAssigned = 0;
      int bFollowUp = 0;
      int bVisiting = 0;
      int bVisitCompleted = 0;
      int bConverted = 0;

      for (final l in batchLeads) {
        final s = l['status'] as String? ?? 'new';
        if (l['assigned_to'] != null) bAssigned++;
        if (s == 'follow_up') bFollowUp++;
        if (s == 'visiting') bVisiting++;
        if (s == 'visit_completed') bVisitCompleted++;
        if (s == 'converted') bConverted++;
      }

      totalBatchLeads.value = bTotal;
      totalAssigned.value = bAssigned;
      _batchFollowUp = bFollowUp;
      _batchVisiting = bVisiting;
      _batchVisitCompleted = bVisitCompleted;
      _batchConverted = bConverted;

      // Step 3: For each manager, get their employees and match
      final List<BatchManagerInfo> result = [];

      for (final member in membersList) {
        final managerId = member['manager_id'] as String;
        String managerName = 'Unknown';
        if (member['manager'] != null && member['manager'] is Map) {
          final m = member['manager'] as Map<String, dynamic>;
          managerName =
              '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
        }

        // Get this manager's employees
        final empResponse = await _supabase.client
            .from('employees')
            .select('id')
            .eq('manager_id', managerId);

        final empIds =
            (empResponse as List).map((e) => e['id'] as String).toList();

        // Count leads assigned to this manager's team from this batch
        // Also count leads uploaded by this manager
        int mTotal = 0;
        int mAssigned = 0;
        int mUnassigned = 0;
        int mFollowUp = 0;
        int mVisiting = 0;
        int mVisitCompleted = 0;
        int mConverted = 0;

        for (final lead in batchLeads) {
          final assignedTo = lead['assigned_to'] as String?;
          final uploadedBy = lead['uploaded_by'] as String?;
          final status = lead['status'] as String? ?? 'new';

          // Lead belongs to this manager if:
          // - assigned to one of their employees, OR
          // - uploaded by this manager
          final belongsToManager = (assignedTo != null && empIds.contains(assignedTo)) ||
              uploadedBy == managerId;

          if (!belongsToManager) continue;

          mTotal++;
          if (assignedTo != null && empIds.contains(assignedTo)) {
            mAssigned++;
          }
          if (uploadedBy == managerId && assignedTo == null) {
            mUnassigned++;
          }
          if (status == 'follow_up') mFollowUp++;
          if (status == 'visiting') mVisiting++;
          if (status == 'visit_completed') mVisitCompleted++;
          if (status == 'converted') mConverted++;
        }

        result.add(BatchManagerInfo(
          managerId: managerId,
          managerName: managerName,
          employeeIds: empIds,
          totalLeads: mTotal,
          assignedLeads: mAssigned,
          unassignedLeads: mUnassigned,
          followUpCount: mFollowUp,
          visitingCount: mVisiting,
          visitCompletedCount: mVisitCompleted,
          convertedCount: mConverted,
        ));
      }

      // Sort by highest visits first
      result.sort((a, b) => b.totalVisits.compareTo(a.totalVisits));

      managers.value = result;
    } catch (e) {
      print('Error fetching project managers: $e');
    }
  }

  void _showOverallStats() {
    totalFollowUp.value = _batchFollowUp;
    totalVisiting.value = _batchVisiting;
    totalVisitCompleted.value = _batchVisitCompleted;
    totalConverted.value = _batchConverted;
  }

  void selectManager(BatchManagerInfo manager) {
    selectedManager.value = manager;
    totalFollowUp.value = manager.followUpCount;
    totalVisiting.value = manager.visitingCount;
    totalVisitCompleted.value = manager.visitCompletedCount;
    totalConverted.value = manager.convertedCount;
    _fetchLeadsForTab();
  }

  void clearManagerFilter() {
    selectedManager.value = null;
    _showOverallStats();
    _fetchLeadsForTab();
  }

  /// Fetch leads for the selected status tab.
  /// When a manager is selected, filter by their employees (assigned_to)
  /// + leads they uploaded.
  Future<void> _fetchLeadsForTab() async {
    try {
      isLoadingLeads.value = true;

      final statuses = ['follow_up', 'visiting', 'visit_completed', 'converted'];
      final status = statuses[selectedTab.value];

      var query = _supabase.leadsTable
          .select(
              '*, employees:assigned_to(first_name, last_name), managers:uploaded_by(first_name, last_name)')
          .eq('batch_id', batch.id)
          .eq('status', status);

      final manager = selectedManager.value;

      if (manager != null && manager.employeeIds.isNotEmpty) {
        // Show leads assigned to this manager's team OR uploaded by this manager
        query = query.or(
            'assigned_to.in.(${manager.employeeIds.map((id) => '"$id"').join(",")}),uploaded_by.eq.${manager.managerId}');
      } else if (manager != null) {
        // Manager has no employees — only show leads they uploaded
        query = query.eq('uploaded_by', manager.managerId);
      }

      final response = await query.order('updated_at', ascending: false);

      filteredLeads.value = (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching leads for tab: $e');
      filteredLeads.value = [];
    } finally {
      isLoadingLeads.value = false;
    }
  }
}
