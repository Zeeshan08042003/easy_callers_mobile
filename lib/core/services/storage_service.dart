import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:get/get.dart';

class StorageService extends GetxService {
  late final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final service = StorageService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // Generic methods
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setJson(String key, Map<String, dynamic> value) => 
      _prefs.setString(key, jsonEncode(value));
      
  Map<String, dynamic>? getJson(String key) {
    final str = _prefs.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();

  // Keys
  static const String keyUserRole = 'user_role';
  static const String keyUserProfile = 'user_profile';
  static const String keyIsLoggedIn = 'is_logged_in';
}
