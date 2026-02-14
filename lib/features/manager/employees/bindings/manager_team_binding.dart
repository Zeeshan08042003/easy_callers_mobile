import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/manager_team_controller.dart';

class ManagerTeamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagerTeamController>(
      () => ManagerTeamController(),
    );
  }
}
