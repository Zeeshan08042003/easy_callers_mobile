import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/manager_list_controller.dart';
import 'package:easy_callers_mobile/features/auth/views/login_screen.dart';

class AddManagerController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> createManager() async {
    if (!_validateFields()) return;

    try {
      isLoading.value = true;
      final manager = await _authService.createManager(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      );

      if (manager != null) {
        // Since Supabase auto-logs-in the new user on signUp,
        // we must log out the manager account to let the Super Admin log back in.
        await _authService.logout();
        
        Get.offAll(() => const NewLoginScreen());
        Get.snackbar(
          'Success', 
          'Manager created! You have been logged out. Please log back in as Super Admin.',
          duration: const Duration(seconds: 5),
        );
      } else {
        print("manager creating error: ${_authService.error.value}");
        Get.snackbar('Error', _authService.error.value);
      }
    } catch (e) {
      print("manager creating error: $e");
      Get.snackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateFields() {
    if (firstNameController.text.isEmpty || 
        lastNameController.text.isEmpty || 
        emailController.text.isEmpty || 
        passwordController.text.isEmpty) {
      Get.snackbar('Required', 'Please fill in all mandatory fields');
      return false;
    }
    if (passwordController.text.length < 6) {
      Get.snackbar('Invalid', 'Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
