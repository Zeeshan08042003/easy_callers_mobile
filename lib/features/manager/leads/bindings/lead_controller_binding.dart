import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/lead_controller_controller.dart';

import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

class LeadControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeadControllerController>(
      () => LeadControllerController(),
    );
    Get.lazyPut<ManagerDashboardController>(
      () => ManagerDashboardController(),
    );
  }
}
