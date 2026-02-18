import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/employee/views/lead_detail_view.dart';
import 'package:easy_callers_mobile/features/employee/views/call_history_view.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';

class EmployeeDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<LeadModel> assignedLeads = <LeadModel>[].obs;
  final RxList<LeadModel> pendingFollowups = <LeadModel>[].obs;
  final RxMap<String, dynamic> todayStats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxInt currentNavIndex = 0.obs;

  // Stats observables
  final RxInt pendingLeadsCount = 0.obs;
  final RxInt contactedLeadsCount = 0.obs;
  final RxDouble dailyProgress = 0.0.obs;

  // Employee info
  String get employeeName {
    final employee = _authService.currentEmployee.value;
    if (employee == null) return 'Employee';
    return employee.firstName;
  }

  String get employeeInitials {
    final employee = _authService.currentEmployee.value;
    if (employee == null) return 'E';
    final first = employee.firstName.isNotEmpty ? employee.firstName[0] : '';
    final last = employee.lastName.isNotEmpty ? employee.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  final RxnString profileImageUrl = RxnString();

  String get goalPercentage {
    if (todayStats['goal'] == null || todayStats['goal'] == 0) return '0% Goal';
    final percentage = ((contactedLeadsCount.value / todayStats['goal']) * 100).toInt();
    return '$percentage% Goal';
  }

  @override
  void onInit() {
    super.onInit();
    _loadEmployeeProfile();
    refreshData();
  }

  void _loadEmployeeProfile() {
    final employee = _authService.currentEmployee.value;
    if (employee != null && employee.profileImageUrl != null) {
      profileImageUrl.value = employee.profileImageUrl;
    }
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      final employeeId = _authService.currentEmployee.value?.id;
      if (employeeId == null) return;

      // Parallel fetch
      final results = await Future.wait([
        _leadService.getLeadsByEmployee(employeeId),
        _leadService.getTodayFollowUps(employeeId),
        _getEmployeeStats(employeeId),
      ]);

      assignedLeads.value = results[0] as List<LeadModel>;
      pendingFollowups.value = results[1] as List<LeadModel>;
      todayStats.value = results[2] as Map<String, dynamic>;

      // Update stats
      _updateStats();
    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _getEmployeeStats(String employeeId) async {
    try {
      // Get today's call logs to calculate stats
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final callLogs = await _leadService.getCallLogsForDateRange(
        employeeId: employeeId,
        startDate: todayStart,
        endDate: todayEnd,
      );

      final totalCalls = callLogs.length;
      final connectedCalls = callLogs.where((log) => log.callStatus?.value == 'connected').length;
      final interestedLeads = callLogs.where((log) => log.leadStatus?.value == 'interested').length;

      return {
        'calls_today': totalCalls,
        'connected_today': connectedCalls,
        'interested_today': interestedLeads,
        'goal': 24, // This should come from settings or be configurable
        'conversion_rate': totalCalls > 0 ? (interestedLeads / totalCalls) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting employee stats: $e');
      return {
        'calls_today': 0,
        'connected_today': 0,
        'interested_today': 0,
        'goal': 24,
        'conversion_rate': 0.0,
      };
    }
  }

  void _updateStats() {
    // Count pending leads (assigned but not contacted)
    pendingLeadsCount.value = assignedLeads.where((lead) {
      return lead.status.value == 'assigned' || lead.status.value == 'new';
    }).length;

    // Count contacted leads (from today's stats)
    contactedLeadsCount.value = todayStats['calls_today'] ?? 0;

    // Calculate daily progress
    final goal = todayStats['goal'] ?? 24;
    if (goal > 0) {
      dailyProgress.value = (contactedLeadsCount.value / goal).clamp(0.0, 1.0);
    }
  }

  void startCalling() {
    if (assignedLeads.isEmpty) return;
    
    // Navigate to the first lead in the queue
    final firstLead = assignedLeads.first;
    Get.to(() => LeadDetailView(lead: firstLead));
  }

  void onNavTap(int index) {
    currentNavIndex.value = index;
    
    switch (index) {
      case 0:
        // Already on home, just refresh
        if (currentNavIndex.value == 0) {
          refreshData();
        }
        break;
      case 1:
        // Navigate to Call History
        Get.to(() => const CallHistoryView());
        break;
      case 2:
        // Navigate to Stats (to be implemented)
        Get.snackbar('Coming Soon', 'Stats view will be available soon');
        break;
      case 3:
        // Navigate to Profile
        Get.to(() => const ProfileView(), binding: ProfileBinding());
        break;
    }
  }

  int get totalCallsToday => todayStats['calls_today'] ?? 0;
  int get interestedLeads => todayStats['interested_today'] ?? 0;
  double get conversionRate => todayStats['conversion_rate'] ?? 0.0;
}
