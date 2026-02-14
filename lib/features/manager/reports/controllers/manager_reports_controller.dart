import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class ManagerReportsController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxMap teamPerformance = <String, dynamic>{}.obs;
  final RxMap leadFunnel = <String, int>{}.obs;
  final RxList activityStats = <Map<String, dynamic>>[].obs;
  
  final RxBool isLoading = true.obs;
  final Rx<DateTimeRange> selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ).obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) return;

      // Run in parallel
      final results = await Future.wait([
        _leadService.getTeamPerformanceOverview(
          managerId,
          startDate: selectedDateRange.value.start,
          endDate: selectedDateRange.value.end,
        ),
        _leadService.getTeamLeadFunnel(managerId),
        _leadService.getTeamActivityStats(managerId),
      ]);

      teamPerformance.value = results[0] as Map<String, dynamic>;
      leadFunnel.value = results[1] as Map<String, int>;
      activityStats.value = results[2] as List<Map<String, dynamic>>;
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateDateRange(DateTimeRange range) {
    selectedDateRange.value = range;
    fetchAllData();
  }
}
