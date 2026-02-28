import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/config/flavor_config.dart';

class StorageService extends GetxService {
  late final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final service = StorageService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // Helper to get prefixed key
  String _pk(String key) => '${FlavorConfig.instance.name}_$key';

  // Generic methods
  Future<bool> setString(String key, String value) => _prefs.setString(_pk(key), value);
  String? getString(String key) => _prefs.getString(_pk(key));
  
  Future<bool> setBool(String key, bool value) => _prefs.setBool(_pk(key), value);
  bool? getBool(String key) => _prefs.getBool(_pk(key));

  Future<bool> setInt(String key, int value) => _prefs.setInt(_pk(key), value);
  int? getInt(String key) => _prefs.getInt(_pk(key));

  Future<bool> setJson(String key, Map<String, dynamic> value) => 
      _prefs.setString(_pk(key), jsonEncode(value));
      
  Map<String, dynamic>? getJson(String key) {
    final str = _prefs.getString(_pk(key));
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> remove(String key) => _prefs.remove(_pk(key));
  Future<bool> clear() => _prefs.clear();

  // Keys
  static const String keyUserRole = 'user_role';
  static const String keyUserProfile = 'user_profile';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLastProjectID = 'last_project_id';
}
