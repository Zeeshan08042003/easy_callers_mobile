import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = false.obs;

  String get userName {
    switch (_authService.currentRole.value) {
      case UserRole.superAdmin:
        return _authService.currentSuperAdmin.value?.fullName ?? 'Admin';
      case UserRole.manager:
      case UserRole.agency:
        return _authService.currentManager.value?.fullName ?? 'Manager';
      case UserRole.employee:
        return _authService.currentEmployee.value?.fullName ?? 'Employee';
      default:
        return 'User';
    }
  }

  String get userEmail {
    switch (_authService.currentRole.value) {
      case UserRole.superAdmin:
        return _authService.currentSuperAdmin.value?.email ?? '';
      case UserRole.manager:
      case UserRole.agency:
        return _authService.currentManager.value?.email ?? '';
      case UserRole.employee:
        return _authService.currentEmployee.value?.email ?? '';
      default:
        return '';
    }
  }

  String get userRole {
    switch (_authService.currentRole.value) {
      case UserRole.superAdmin:
        return 'System Administrator';
      case UserRole.manager:
        return 'Team Manager';
      case UserRole.agency:
        return 'Agency Owner';
      case UserRole.employee:
        return 'Sales Representative';
      default:
        return '';
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // AuthController handles the redirection or we can do it here
    // But since we transitioned to direct navigation, we should go to login
  }
}
