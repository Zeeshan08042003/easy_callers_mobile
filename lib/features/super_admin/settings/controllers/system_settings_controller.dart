import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/models/system_settings_model.dart';
import 'package:easy_callers_mobile/core/services/system_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class SystemSettingsController extends GetxController {
  final SystemService _systemService = Get.find<SystemService>();
  final AuthService _authService = Get.find<AuthService>();

  late TextEditingController companyNameController;
  late TextEditingController supportEmailController;
  late TextEditingController supportPhoneController;
  late TextEditingController maxLeadsController;
  late TextEditingController callTargetController;
  
  final RxBool maintenanceMode = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initFields();
  }

  void _initFields() {
    final s = _systemService.settings.value;
    companyNameController = TextEditingController(text: s?.companyName ?? '');
    supportEmailController = TextEditingController(text: s?.supportEmail ?? '');
    supportPhoneController = TextEditingController(text: s?.supportPhone ?? '');
    maxLeadsController = TextEditingController(text: (s?.maxLeadsPerEmployee ?? 100).toString());
    callTargetController = TextEditingController(text: (s?.dailyCallTarget ?? 50).toString());
    maintenanceMode.value = s?.maintenanceMode ?? false;
  }

  Future<void> saveSettings() async {
    final currentSettings = _systemService.settings.value;
    if (currentSettings == null) return;

    final adminId = _authService.currentSuperAdmin.value?.id;
    if (adminId == null) {
      Get.snackbar('Error', 'Unauthorized action');
      return;
    }

    try {
      isLoading.value = true;
      final newSettings = SystemSettingsModel(
        id: currentSettings.id,
        companyName: companyNameController.text,
        supportEmail: supportEmailController.text,
        supportPhone: supportPhoneController.text,
        maxLeadsPerEmployee: int.tryParse(maxLeadsController.text) ?? 100,
        dailyCallTarget: int.tryParse(callTargetController.text) ?? 50,
        maintenanceMode: maintenanceMode.value,
        updatedAt: DateTime.now(),
      );

      final success = await _systemService.updateSettings(newSettings, adminId);
      if (success) {
        Get.snackbar('Success', 'System settings updated successfully');
      } else {
        Get.snackbar('Error', 'Failed to update settings');
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    companyNameController.dispose();
    supportEmailController.dispose();
    supportPhoneController.dispose();
    maxLeadsController.dispose();
    callTargetController.dispose();
    super.onClose();
  }
}
