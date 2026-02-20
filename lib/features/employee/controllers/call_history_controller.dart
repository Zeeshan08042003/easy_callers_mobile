import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class CallHistoryController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<CallLogModel> callLogs = <CallLogModel>[].obs;
  final RxList<CallLogModel> filteredCallLogs = <CallLogModel>[].obs;
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
      if (employeeId == null) return;

      // Fetch call logs
      final logs = await _leadService.getCallLogsByEmployee(employeeId, limit: 100);
      callLogs.value = logs;
      
      // Calculate weekly stats
      _calculateWeeklyStats(logs);
      
      // Apply filters
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load call history: $e');
    } finally {
      isLoading.value = false;
    }
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
        return isConnected &&
            (log.leadStatus?.value == 'interested' ||
                log.leadStatus?.value == 'callback');
      }).length;

      weeklySuccessRate.value = ((successfulCalls / weeklyLogs.length) * 100).round();
    } else {
      weeklySuccessRate.value = 0;
    }
  }

  void _applyFilters() {
    var filtered = callLogs.toList();

    // Apply filter
    switch (selectedFilter.value) {
      case 'missed':
        filtered = filtered.where((log) {
          final status = log.callStatus?.toLowerCase() ?? '';
          return status.contains('declined') ||
              status.contains('failed') ||
              status.contains('no_answer') ||
              status.contains('busy') ||
              status.contains('rejected') ||
              status.contains('missed');
        }).toList();
        break;
      case 'followup':
        filtered = filtered.where((log) {
          return log.followUpDate != null;
        }).toList();
        break;
      default:
        // 'all' - no filtering
        break;
    }

    // Apply search
    final searchQuery = searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        final name = (log.leadName ?? '').toLowerCase();
        final phone = (log.leadPhone ?? '').toLowerCase();
        return name.contains(searchQuery) || phone.contains(searchQuery);
      }).toList();
    }

    filteredCallLogs.value = filtered;
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
            _buildFilterOption('Missed Calls', 'missed'),
            _buildFilterOption('Follow-ups', 'followup'),
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

  Map<String, List<CallLogModel>> get groupedCallLogs {
    final Map<String, List<CallLogModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var log in filteredCallLogs) {
      final logDate = DateTime(
        log.createdAt.year,
        log.createdAt.month,
        log.createdAt.day,
      );

      String dateKey;
      if (logDate == today) {
        dateKey = 'TODAY';
      } else if (logDate == yesterday) {
        dateKey = 'YESTERDAY';
      } else {
        dateKey = DateFormat('MMMM d, yyyy').format(logDate).toUpperCase();
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(log);
    }

    return grouped;
  }
}
