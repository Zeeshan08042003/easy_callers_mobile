import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/system_settings_model.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';

class SystemService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  
  final Rx<SystemSettingsModel?> settings = Rx<SystemSettingsModel?>(null);
  final RxBool isLoading = false.obs;

  Future<SystemService> init() async {
    await fetchSettings();
    return this;
  }

  Future<void> fetchSettings() async {
    try {
      isLoading.value = true;
      final response = await _supabase.client
          .from('system_settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        settings.value = SystemSettingsModel.fromJson(response);
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
      final updateData = newSettings.toJson();
      updateData['updated_by'] = adminId;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.client
          .from('system_settings')
          .update(updateData)
          .eq('id', newSettings.id);

      settings.value = newSettings;
      return true;
    } catch (e) {
      print('Error updating system settings: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
