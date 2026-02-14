import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/manager_list_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/add_manager_controller.dart';

class ManagerListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagerListController>(
      () => ManagerListController(),
    );
  }
}

class AddManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddManagerController>(
      () => AddManagerController(),
    );
  }
}
