import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/controllers/system_settings_controller.dart';

class SystemSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemSettingsController>(
      () => SystemSettingsController(),
    );
  }
}
