import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/controllers/super_admin_dashboard_controller.dart';

class SuperAdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminDashboardController>(
      () => SuperAdminDashboardController(),
    );
  }
}
