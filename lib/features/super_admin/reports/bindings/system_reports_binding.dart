import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/controllers/system_reports_controller.dart';

class SystemReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemReportsController>(
      () => SystemReportsController(),
    );
  }
}
