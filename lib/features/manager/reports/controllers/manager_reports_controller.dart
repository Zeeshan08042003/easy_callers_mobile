import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class ManagerReportsController extends GetxController {
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxMap teamPerformance = <String, dynamic>{}.obs;
  final RxMap leadFunnel = <String, int>{}.obs;
  final RxList activityStats = <Map<String, dynamic>>[].obs;
  
  final RxBool isLoading = true.obs;
  
  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;
  final Rx<DateTimeRange> selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ).obs;

  @override
  void onInit() {
    super.onInit();
    
    // Check for oversight mode
    if (Get.arguments is String) {
      oversightManagerId = Get.arguments as String;
    } else if (Get.arguments is ManagerModel) {
      oversightManagerId = (Get.arguments as ManagerModel).id;
    }

    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
      if (managerId == null) return;

      // Run in parallel
      final results = await Future.wait([
        _webService.getTeamPerformanceOverview(
          managerId,
          startDate: selectedDateRange.value.start,
          endDate: selectedDateRange.value.end,
        ),
        _webService.getTeamLeadFunnel(managerId),
        _webService.getTeamActivityStats(managerId),
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
