import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/super_admin_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/views/super_admin_dashboard_view.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/bindings/super_admin_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/views/employee_dashboard_view.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/bindings/employee_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/auth/views/otp_screen.dart';
import 'package:easy_callers_mobile/features/auth/views/set_password_screen.dart';
import 'package:easy_callers_mobile/features/auth/views/login_screen.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

/// Auth controller used by LoginScreen, OTPScreen, SetPasswordScreen.
/// Handles role-based routing after successful authentication.
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Form fields
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxString otpCode = ''.obs;

  // Validation errors
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString otpError = ''.obs;

  // State
  RxBool get isLoading => _authService.isLoading;
  RxString get error => _authService.error;
  
  // Role-specific current users
  Rx<UserRole?> get currentRole => _authService.currentRole;
  Rx<SuperAdminModel?> get currentSuperAdmin => _authService.currentSuperAdmin;
  Rx<ManagerModel?> get currentManager => _authService.currentManager;
  Rx<EmployeeModel?> get currentEmployee => _authService.currentEmployee;
  
  // For first-time activation
  final Rx<UserRole?> detectedActivationRole = Rx<UserRole?>(null);

  // ============================================
  // LOGIN
  // ============================================

  /// Validate and attempt login
  Future<void> login() async {
    if (!_validateLoginForm()) return;

    final role = await _authService.login(
      email: email.value.trim(),
      password: password.value,
    );

    if (role != null) {
      _navigateToDashboard(role);
    } else if (error.value.isNotEmpty) {
      Get.snackbar('Login Failed', error.value);
    }
  }

  /// Navigate to the appropriate dashboard based on role
  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        Get.offAll(() => const SuperAdminDashboardView(), binding: SuperAdminDashboardBinding());
        break;
      case UserRole.manager:
      case UserRole.agency:
        Get.offAll(() => const ManagerDashboardView(), binding: ManagerDashboardBinding());
        break;
      case UserRole.employee:
        Get.offAll(() => const EmployeeDashboardView(), binding: EmployeeDashboardBinding());
        break;
    }
  }

  // ============================================
  // OTP VERIFICATION (Employee first login)
  // ============================================

  /// Navigate to OTP screen
  Future<void> goToOTPScreen() async {
    if (email.value.trim().isEmpty) {
      emailError.value = 'Please enter your email first';
      return;
    }
    emailError.value = '';

    final success = await _authService.requestActivationOTP(email.value);
    if (success) {
      Get.to(() => const OTPScreen());
    } else {
      Get.snackbar('Error', error.value);
    }
  }

  /// Verify OTP
  Future<void> verifyOTP() async {
    otpError.value = '';
    final emailVal = email.value.trim();
    final otpVal = otpCode.value.trim();

    final role = await _authService.verifyActivationOTP(
      email: emailVal,
      otpCode: otpVal,
    );

    if (role != null) {
      detectedActivationRole.value = role;
      Get.to(() => const SetPasswordScreen());
    } else if (error.value.isNotEmpty) {
      Get.snackbar('Verification Failed', error.value);
    }
  }

  // ============================================
  // SET PASSWORD (Employee activation)
  // ============================================

  /// Set password and activate the account
  Future<void> setPasswordAndActivate() async {
    if (!_validatePasswordForm()) return;

    final role = detectedActivationRole.value;
    final emailVal = email.value.trim();
    final passVal = password.value;

    if (role == null) {
      Get.snackbar('Error', 'Session lost. Please try again.');
      return;
    }

    final success = await _authService.completeActivation(
      email: emailVal,
      password: passVal,
      role: role,
    );

    if (success) {
      Get.snackbar('Success', 'Account activated successfully!');
      _navigateToDashboard(role);
    } else if (error.value.isNotEmpty) {
      Get.snackbar('Activation Failed', error.value);
    }
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    final emailVal = email.value.trim();
    if (emailVal.isEmpty) return;

    final success = await _authService.requestActivationOTP(emailVal);
    if (success) {
      Get.snackbar('OTP Sent', 'A new verification code has been sent to your email.');
    } else {
      Get.snackbar('Error', error.value);
    }
  }

  // ============================================
  // LOGOUT
  // ============================================

  Future<void> logout() async {
    await _authService.logout();
    Get.offAll(() => const NewLoginScreen());
  }

  // ============================================
  // VALIDATION
  // ============================================

  bool _validateLoginForm() {
    bool isValid = true;

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (email.value.trim().isEmpty) {
      emailError.value = 'Please enter your email';
      isValid = false;
    } else if (!emailRegex.hasMatch(email.value.trim())) {
      emailError.value = 'Please enter a valid email';
      isValid = false;
    } else {
      emailError.value = '';
    }

    if (password.value.isEmpty) {
      passwordError.value = 'Please enter your password';
      isValid = false;
    } else if (password.value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else {
      passwordError.value = '';
    }

    return isValid;
  }

  bool _validatePasswordForm() {
    bool isValid = true;

    if (password.value.isEmpty) {
      passwordError.value = 'Please enter a password';
      isValid = false;
    } else if (password.value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else {
      passwordError.value = '';
    }

    if (confirmPassword.value != password.value) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    } else {
      confirmPasswordError.value = '';
    }

    return isValid;
  }

  /// Clear all form data
  void clearForm() {
    email.value = '';
    password.value = '';
    confirmPassword.value = '';
    otpCode.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    otpError.value = '';
  }
}
