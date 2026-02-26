import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    // Artificial delay for splash aesthetic
    await Future.delayed(const Duration(seconds: 2));

    final role = await _authService.restoreSession();

    if (role == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    switch (role) {
      case UserRole.superAdmin:
        Get.offAllNamed(AppRoutes.superAdminDashboard);
        break;
      case UserRole.manager:
      case UserRole.agency:
        Get.offAllNamed(AppRoutes.managerDashboard);
        break;
      case UserRole.employee:
        Get.offAllNamed(AppRoutes.employeeDashboard);
        break;
    }
  }
}
