import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';

class SystemReportsController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();

  final RxList regionalPerformance = <Map<String, dynamic>>[].obs;
  final RxMap globalStats = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _leadService.getGlobalStats(),
        _leadService.getRegionalPerformance(),
      ]);

      globalStats.value = results[0] as Map<String, dynamic>;
      regionalPerformance.value = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load system reports: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
