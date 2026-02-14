import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

class ManagerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagerDashboardController>(() => ManagerDashboardController());
  }
}
