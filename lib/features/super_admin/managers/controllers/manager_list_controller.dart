import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';

class ManagerListController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ManagerModel> managers = <ManagerModel>[].obs;
  final RxList<ManagerModel> filteredManagers = <ManagerModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchManagers();
  }

  Future<void> fetchManagers() async {
    try {
      isLoading.value = true;
      final saId = _authService.currentSuperAdmin.value?.id;
      if (saId == null) return;

      // Only fetch SA's own created managers (not network agencies)
      final result = await _leadService.getAllManagers(currentSuperAdminId: saId);
      managers.assignAll(result);
      filteredManagers.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load managers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void searchManagers(String query) {
    if (query.isEmpty) {
      filteredManagers.assignAll(managers);
    } else {
      filteredManagers.assignAll(
        managers.where((m) => 
          m.fullName.toLowerCase().contains(query.toLowerCase()) || 
          m.email.toLowerCase().contains(query.toLowerCase())
        ).toList(),
      );
    }
  }

  Future<void> resendOTP(ManagerModel manager) async {
    try {
      isLoading.value = true;
      final otp = await _authService.resendManagerOTP(manager.email);
      isLoading.value = false;

      if (otp != null) {
        _showOTPResultDialog(
          name: manager.fullName,
          email: manager.email,
          otp: otp,
        );
        // Refresh list to update OTP expiry
        await fetchManagers();
      } else {
        Get.snackbar('Error', 'Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP: $e');
      isLoading.value = false;
    }
  }

  void _showOTPResultDialog({
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
              child: const Icon(Icons.send_rounded,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'OTP Resent!',
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
                  _credentialRow('New OTP', otp),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      'Your Easy Callers manager account OTP has been resent.\n\n'
      '📧 Email: $email\n'
      '🔐 OTP Code: $otp\n\n'
      'Please use this OTP to activate your account.\n\n'
      'Thank you!',
    );

    final url = Uri.parse('https://wa.me/?text=$message');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open WhatsApp');
    }
  }

  Future<void> toggleManagerStatus(ManagerModel manager) async {
    try {
      isLoading.value = true;
      await fetchManagers();
      Get.snackbar('Success', 'Manager status updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update manager: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
