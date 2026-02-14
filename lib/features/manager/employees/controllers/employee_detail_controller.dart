import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/models/employee_model.dart';
import 'package:easy_callers_mobile/core/models/lead_model.dart';
import 'package:easy_callers_mobile/core/models/call_log_model.dart';
import 'package:easy_callers_mobile/core/services/lead_service.dart';

class EmployeeDetailController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();

  final Rx<EmployeeModel?> employee = Rx<EmployeeModel?>(null);
  final RxList<CallLogModel> recentCalls = <CallLogModel>[].obs;
  final RxList<LeadModel> assignedLeads = <LeadModel>[].obs;
  final RxMap<String, dynamic> stats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is EmployeeModel) {
      employee.value = Get.arguments as EmployeeModel;
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (employee.value == null) return;

    try {
      isLoading.value = true;
      final empId = employee.value!.id;

      // Fetch in parallel
      final results = await Future.wait([
        _leadService.getCallLogsByEmployee(empId, limit: 1),
        _leadService.getLeadsByEmployee(empId),
        _leadService.getEmployeeStats(empId),
      ]);

      recentCalls.value = results[0] as List<CallLogModel>;
      assignedLeads.value = (results[1] as List<LeadModel>).reversed.take(5).toList();
      stats.value = results[2] as Map<String, dynamic>;

    } catch (e) {
      Get.snackbar('Error', 'Failed to load performance data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
