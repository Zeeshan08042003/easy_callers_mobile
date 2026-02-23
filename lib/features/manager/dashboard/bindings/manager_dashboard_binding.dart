import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/manager_team_controller.dart';
import 'package:easy_callers_mobile/features/manager/reports/controllers/manager_reports_controller.dart';
import 'package:easy_callers_mobile/features/profile/controllers/profile_controller.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_list_controller.dart';

class ManagerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagerDashboardController>(() => ManagerDashboardController());
    Get.lazyPut<ManagerTeamController>(() => ManagerTeamController());
    Get.lazyPut<ManagerReportsController>(() => ManagerReportsController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<ProjectListController>(() => ProjectListController());
  }
}
