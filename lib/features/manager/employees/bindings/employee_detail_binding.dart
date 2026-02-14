import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/employee_detail_controller.dart';

class EmployeeDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeDetailController>(
      () => EmployeeDetailController(),
    );
  }
}
