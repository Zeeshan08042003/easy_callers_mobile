import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class ManagerOversightController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  late ManagerModel manager;
  final RxString selectedPeriod = 'weekly'.obs; // 'daily', 'weekly', 'yearly'
  final RxMap<String, dynamic> analytics = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ManagerModel) {
      manager = Get.arguments;
      fetchAnalytics();
    } else {
      Future.microtask(() {
        if (Get.isRegistered<ManagerOversightController>()) {
          Get.back();
          Get.snackbar('Error', 'No manager data found');
        }
      });
    }
  }

  void switchPeriod(String period) {
    selectedPeriod.value = period;
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      final saId = _authService.currentSuperAdmin.value?.id;
      final result = await _leadService.getManagerAnalytics(
        managerId: manager.id,
        period: selectedPeriod.value,
        currentSuperAdminId: saId,
      );
      analytics.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load manager analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isPrivate => analytics['is_private'] ?? false;
  
  double get conversionRate => (analytics['conversion_rate'] ?? 0.0).toDouble();
  
  List<dynamic> get employees => analytics['employees'] ?? [];
  
  Map<String, int> get statusCounts => Map<String, int>.from(analytics['status_counts'] ?? {});
}
