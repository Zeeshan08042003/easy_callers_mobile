import 'dart:convert';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/system_settings_model.dart';
import 'package:easy_callers_mobile/core/services/web_service.dart';

class SystemService extends GetxService {
  final WebService _webService = Get.find<WebService>();
  
  final Rx<SystemSettingsModel?> settings = Rx<SystemSettingsModel?>(null);
  final RxBool isLoading = false.obs;

  Future<SystemService> init() async {
    await fetchSettings();
    return this;
  }

  Future<void> fetchSettings() async {
    try {
      isLoading.value = true;
      final response = await _webService.callApi(
        method: HTTP_METHODS.GET,
        path: ['sa', 'settings'],
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final settingsData = data['data'];
        if (settingsData != null) {
          settings.value = SystemSettingsModel.fromJson(settingsData);
        }
      }
    } catch (e) {
      print('Error fetching system settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSettings(SystemSettingsModel newSettings, String adminId) async {
    try {
      isLoading.value = true;
      
      final response = await _webService.callApi(
        method: HTTP_METHODS.PUT,
        path: ['sa', 'settings'],
        body: newSettings.toJson(),
      );

      if (response.status == API_STATUS.SUCCESS) {
        // Backend returns the updated row 
        final data = jsonDecode(response.stringData!);
        final updatedData = data['data'];
        
        settings.value = SystemSettingsModel.fromJson(updatedData);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating system settings: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
