import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/controllers/employee_dashboard_controller.dart';

class EmployeeDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeDashboardController>(
      () => EmployeeDashboardController(),
    );
  }
}
