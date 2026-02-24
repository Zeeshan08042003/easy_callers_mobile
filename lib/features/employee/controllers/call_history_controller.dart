import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/employee/views/lead_detail_view.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class CallHistoryController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  /// All raw call logs from the server
  final RxList<CallLogModel> callLogs = <CallLogModel>[].obs;

  /// Grouped by lead: leadId -> list of all call logs (sorted newest first)
  final RxMap<String, List<CallLogModel>> logsByLead = <String, List<CallLogModel>>{}.obs;

  /// Filtered leads (1 per lead - latest call log), sorted by most recent update
  final RxList<CallLogModel> filteredLeads = <CallLogModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxInt weeklyTotalCalls = 0.obs;
  final RxInt weeklySuccessRate = 0.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    refreshCallHistory();

    // Listen to filter changes
    ever(selectedFilter, (_) => _applyFilters());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> refreshCallHistory() async {
    try {
      isLoading.value = true;

      final employeeId = _authService.currentEmployee.value?.id;
      if (employeeId == null) {
        print('CallHistory: No employee ID found');
        return;
      }

      print('CallHistory: Loading call logs for employee: $employeeId');

      // Fetch all call logs
      final logs = await _leadService.getCallLogsByEmployee(employeeId, limit: 200);
      print('CallHistory: Fetched ${logs.length} call logs');
      callLogs.value = logs;

      // Group by lead
      _groupByLead(logs);

      // Calculate weekly stats
      _calculateWeeklyStats(logs);

      // Apply filters
      _applyFilters();
    } catch (e) {
      print('CallHistory: Error loading call history: $e');
      Get.snackbar('Error', 'Failed to load call history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Groups all call logs by leadId. Each list is sorted newest first.
  void _groupByLead(List<CallLogModel> logs) {
    final Map<String, List<CallLogModel>> grouped = {};

    for (final log in logs) {
      if (!grouped.containsKey(log.leadId)) {
        grouped[log.leadId] = [];
      }
      grouped[log.leadId]!.add(log);
    }

    // Each group is already sorted newest first (from server ORDER BY created_at DESC)
    logsByLead.value = grouped;
  }

  /// Get all call logs for a specific lead
  List<CallLogModel> getLogsForLead(String leadId) {
    return logsByLead[leadId] ?? [];
  }

  /// Get the total call count for a lead
  int getCallCountForLead(String leadId) {
    return logsByLead[leadId]?.length ?? 0;
  }

  void _calculateWeeklyStats(List<CallLogModel> logs) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklyLogs = logs.where((log) {
      return log.createdAt.isAfter(weekAgo);
    }).toList();

    weeklyTotalCalls.value = weeklyLogs.length;

    if (weeklyLogs.isNotEmpty) {
      final successfulCalls = weeklyLogs.where((log) {
        final status = log.callStatus?.toLowerCase() ?? '';
        final isConnected = status.contains('completed') || status.contains('connected');
        final leadStatusStr = log.leadStatus?.toString() ?? '';
        return isConnected &&
            (leadStatusStr == 'interested' ||
                leadStatusStr == 'callback');
      }).length;

      weeklySuccessRate.value = ((successfulCalls / weeklyLogs.length) * 100).round();
    } else {
      weeklySuccessRate.value = 0;
    }
  }

  void _applyFilters() {
    // Step 1: Get the latest (most recent) call log per lead
    final latestPerLead = <CallLogModel>[];
    for (final entry in logsByLead.entries) {
      if (entry.value.isNotEmpty) {
        latestPerLead.add(entry.value.first); // first = newest (sorted DESC)
      }
    }

    // Step 2: Apply tab filter on the latest call log per lead
    var filtered = latestPerLead;

    switch (selectedFilter.value) {
      case 'followup':
        filtered = filtered.where((log) {
          final leadStatusStr = log.leadStatus?.toString() ?? '';
          return log.followUpDate != null && leadStatusStr != 'visiting';
        }).toList();
        break;
      case 'visiting':
        filtered = filtered.where((log) {
          final leadStatusStr = log.leadStatus?.toString() ?? '';
          final notes = log.followUpNotes?.toLowerCase() ?? '';
          return leadStatusStr == 'visiting' || notes == 'visiting';
        }).toList();
        break;
      default:
        // 'all' - no filtering
        break;
    }

    // Step 3: Apply search
    final searchQuery = searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        final name = (log.leadName ?? '').toLowerCase();
        final phone = (log.leadPhone ?? '').toLowerCase();
        return name.contains(searchQuery) || phone.contains(searchQuery);
      }).toList();
    }

    // Step 4: Sort by most recently updated (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    print('CallHistory: Filter "${selectedFilter.value}" → ${filtered.length} leads (from ${logsByLead.length} unique leads)');
    filteredLeads.value = filtered;
  }

  void onSearchChanged(String query) {
    _applyFilters();
  }

  void showFilterOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildFilterOption('All Calls', 'all'),
            _buildFilterOption('Follow-ups', 'followup'),
            _buildFilterOption('Visiting', 'visiting'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return Obx(() => ListTile(
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: selectedFilter.value == value
          ? const Icon(Icons.check, color: Color(0xFF4A90E2))
          : null,
      onTap: () {
        selectedFilter.value = value;
        Get.back();
      },
    ));
  }

  /// Navigate to lead detail for calling
  Future<void> navigateToLeadDetail(String leadId) async {
    try {
      // Close the bottom sheet first
      Get.back();

      // Fetch the full lead model
      final lead = await _leadService.getLeadById(leadId);
      if (lead != null) {
        Get.to(() => LeadDetailView(lead: lead));
      } else {
        Get.snackbar(
          'Error',
          'Could not find this lead',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error navigating to lead detail: $e');
    }
  }
}
