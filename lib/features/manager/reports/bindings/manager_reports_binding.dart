import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/reports/controllers/manager_reports_controller.dart';

class ManagerReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagerReportsController>(
      () => ManagerReportsController(),
    );
  }
}
