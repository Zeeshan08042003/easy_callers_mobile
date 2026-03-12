import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_upload_service.dart';
import 'package:easy_callers_mobile/features/super_admin/services/system_service.dart';

/// Initial bindings that register all core services.
/// Called once when the app starts.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (already initialized in main.dart via Get.put)
    // These are accessed here for reference

    // Auth service is already initialized in main.dart

    // Lead services
    Get.lazyPut<WebService>(() => WebService(), fenix: true);
    Get.lazyPut<LeadUploadService>(() => LeadUploadService(), fenix: true);
    
    // System settings service
    Get.lazyPut<SystemService>(() => SystemService(), fenix: true);
  }
}
