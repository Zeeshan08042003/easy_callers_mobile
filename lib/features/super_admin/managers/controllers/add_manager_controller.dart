import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/manager_list_controller.dart';

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

      final email = emailController.text.trim();
      final password = passwordController.text;
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      final result = await _authService.createManager(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      );

      if (result != null) {
        final manager = result.manager;
        final otp = result.otp;
        // Refresh the manager list if it exists
        if (Get.isRegistered<ManagerListController>()) {
          Get.find<ManagerListController>().fetchManagers();
        }
        
        Get.back(); // Close create screen
        _showSuccessDialog(
          name: '$firstName $lastName',
          email: email,
          otp: otp ?? 'N/A',
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

  void _showSuccessDialog({
    required String name,
    required String email,
    required String otp,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Manager Created!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Credential card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _credentialRow('Email', email),
                  const SizedBox(height: 12),
                  _credentialRow('OTP Code', otp),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Share via WhatsApp button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaWhatsApp(
                  name: name,
                  email: email,
                  otp: otp,
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share via WhatsApp',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _shareViaWhatsApp({
    required String name,
    required String email,
    required String otp,
  }) async {
    final message = Uri.encodeComponent(
      'Hello $name,\n\n'
      'Your Easy Callers manager account has been created.\n\n'
      '📧 Email: $email\n'
      '🔐 OTP Code: $otp\n\n'
      'Please download the app and activate your account using this OTP.\n\n'
      'Thank you!',
    );

    final url = Uri.parse('https://wa.me/?text=$message');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open WhatsApp');
    }
  }

  bool _validateFields() {
    if (firstNameController.text.isEmpty || 
        lastNameController.text.isEmpty || 
        emailController.text.isEmpty) {
      Get.snackbar('Required', 'Please fill in all mandatory fields');
      return false;
    }
    if (!GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Invalid', 'Please enter a valid email address');
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
