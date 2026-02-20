import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';

class ManagerRegistrationController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString phone = ''.obs;

  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString firstNameError = ''.obs;
  final RxString lastNameError = ''.obs;

  RxBool get isLoading => _authService.isLoading;
  RxString get error => _authService.error;

  Future<void> register() async {
    if (!_validate()) return;

    final manager = await _authService.registerManager(
      email: email.value.trim(),
      password: password.value,
      firstName: firstName.value.trim(),
      lastName: lastName.value.trim(),
      phone: phone.value.trim().isEmpty ? null : phone.value.trim(),
    );

    if (manager != null) {
      Get.snackbar('Success', 'Welcome to Easy Callers!');
      Get.offAll(() => const ManagerDashboardView(), binding: ManagerDashboardBinding());
    } else if (error.value.isNotEmpty) {
      Get.snackbar('Registration Failed', error.value);
    }
  }

  bool _validate() {
    bool isValid = true;

    final emailRegex = RegExp(r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (email.value.trim().isEmpty) {
      emailError.value = 'Please enter your email';
      isValid = false;
    } else if (!emailRegex.hasMatch(email.value.trim())) {
      emailError.value = 'Please enter a valid email';
      isValid = false;
    } else {
      emailError.value = '';
    }

    if (firstName.value.trim().isEmpty) {
      firstNameError.value = 'First name is required';
      isValid = false;
    } else {
      firstNameError.value = '';
    }

    if (lastName.value.trim().isEmpty) {
      lastNameError.value = 'Last name is required';
      isValid = false;
    } else {
      lastNameError.value = '';
    }

    if (password.value.isEmpty) {
      passwordError.value = 'Password is required';
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
}
