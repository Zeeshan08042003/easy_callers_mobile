import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/controllers/super_admin_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_list_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/controllers/system_reports_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/manager_list_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/controllers/system_settings_controller.dart';

class SuperAdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminDashboardController>(() => SuperAdminDashboardController());
    Get.lazyPut<ProjectListController>(() => ProjectListController());
    Get.lazyPut<SystemReportsController>(() => SystemReportsController());
    Get.lazyPut<ManagerListController>(() => ManagerListController());
    Get.lazyPut<SystemSettingsController>(() => SystemSettingsController());
  }
}
