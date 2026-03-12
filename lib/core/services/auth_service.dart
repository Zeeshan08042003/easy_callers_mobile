import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/super_admin_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
import 'package:easy_callers_mobile/core/services/web_service.dart';
import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

/// Handles auth via Laravel Backend APIs (replaces Supabase auth)
class AuthService extends GetxService {
  final WebService _webService = Get.find<WebService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final StorageService _storage = Get.find<StorageService>();

  /// The detected role of the current user
  final Rx<UserRole?> currentRole = Rx<UserRole?>(null);

  /// Current user profiles (only one will be non-null)
  final Rx<SuperAdminModel?> currentSuperAdmin = Rx<SuperAdminModel?>(null);
  final Rx<ManagerModel?> currentManager = Rx<ManagerModel?>(null);
  final Rx<EmployeeModel?> currentEmployee = Rx<EmployeeModel?>(null);

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message
  final RxString error = ''.obs;

  /// Convenience getters
  String? get currentUserId {
    switch (currentRole.value) {
      case UserRole.superAdmin:
        return currentSuperAdmin.value?.id;
      case UserRole.manager:
        return currentManager.value?.id;
      case UserRole.employee:
        return currentEmployee.value?.id;
      default:
        return null;
    }
  }

  String? get currentUserName {
    switch (currentRole.value) {
      case UserRole.superAdmin:
        return currentSuperAdmin.value?.fullName;
      case UserRole.manager:
        return currentManager.value?.fullName;
      case UserRole.employee:
        return currentEmployee.value?.fullName;
      default:
        return null;
    }
  }

  // ============================================
  // LOGIN
  // ============================================

  /// Login with email and password (all roles)
  Future<UserRole?> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'login'],
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final token = data['token'];
        final roleStr = data['role'];
        final userData = data['user'];

        // Save token immediately so subsequent helpers pass it correctly
        await _storage.setString('token', token);

        // Convert string role to enum
        UserRole? role;
        if (roleStr == 'super_admin') role = UserRole.superAdmin;
        else if (roleStr == 'manager') role = UserRole.manager;
        else if (roleStr == 'agency') role = UserRole.agency;
        else if (roleStr == 'employee') role = UserRole.employee;

        if (role != null) {
          _setCurrentUser(role, _parseProfile(role, userData));
          return role;
        } else {
          error.value = "Unknown role returned by server.";
          await logout();
          return null;
        }
      } else {
        error.value = _extractErrorMessage(response);
        return null;
      }
    } catch (e) {
      error.value = 'An unexpected error occurred: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER: CREATE EMPLOYEE
  // ============================================
  
  // Note: Creating an employee is handled via ManagerController in Laravel, 
  // so we'll likely move this out of AuthService eventually, but for now
  // we use the current web service method structure.
  
  Future<({EmployeeModel? employee, String? otp})> createEmployee({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['manager', 'employees'],
        body: {
          'email': email.trim().toLowerCase(),
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        // API returns { "success": true, "data": employee_object }
        final empMap = data['data'];
        final employee = EmployeeModel.fromJson(empMap);
        
        // Laravel handles sending the OTP behind the scenes (we don't receive it raw anymore)
        return (employee: employee, otp: "Sent via Email");
      } else {
        error.value = _extractErrorMessage(response);
        return (employee: null, otp: null);
      }
    } catch (e) {
      error.value = 'Error creating employee: $e';
      return (employee: null, otp: null);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // SUPER ADMIN: CREATE MANAGER
  // ============================================

  Future<({ManagerModel? manager, String? otp})?> createManager({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['sa', 'managers'],
        body: {
          'email': email.trim().toLowerCase(),
          'first_name': firstName,
          'last_name': lastName,
          'manager_type': 'manager',
          if (phone != null) 'phone': phone,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final managerMap = data['data'];
        final manager = ManagerModel.fromJson(managerMap);
        
        return (manager: manager, otp: "Sent via Email");
      } else {
        error.value = _extractErrorMessage(response);
        return null;
      }
    } catch (e) {
      error.value = 'Error creating manager: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER OTP ACTIVATION
  // ============================================

  Future<bool> verifyManagerOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Verify OTP via standard API Route
      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'manager', 'verify-otp'],
        body: {
          'email': email.trim().toLowerCase(),
          'otp_code': otpCode,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        return true;
      } else {
        error.value = _extractErrorMessage(response);
        return false;
      }
    } catch (e) {
      error.value = 'Error verifying OTP: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<ManagerModel?> activateManager({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'manager', 'activate'],
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final token = data['token'];
        final userData = data['manager'] ?? data['data'];
        
        await _storage.setString('token', token);
        final manager = ManagerModel.fromJson(userData);
        _setCurrentUser(manager.isAgency ? UserRole.agency : UserRole.manager, manager);
        return manager;
      } else {
        error.value = _extractErrorMessage(response);
        return null;
      }
    } catch (e) {
      error.value = 'Error activating manager: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER: SELF REGISTRATION
  // ============================================

  Future<ManagerModel?> registerManager({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'manager', 'register'],
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'manager_type': 'agency',
          if (phone != null) 'phone': phone,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final token = data['token'];
        final userData = data['manager'] ?? data['data'];

        await _storage.setString('token', token);
        final manager = ManagerModel.fromJson(userData);
        _setCurrentUser(UserRole.agency, manager);
        return manager;
      } else {
        error.value = _extractErrorMessage(response);
        return null;
      }
    } catch (e) {
      error.value = 'Registration error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // EMPLOYEE OTP ACTIVATION
  // ============================================

  Future<bool> verifyEmployeeOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'employee', 'verify-otp'],
        body: {
          'email': email.trim().toLowerCase(),
          'otp_code': otpCode,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        return true;
      } else {
        error.value = _extractErrorMessage(response);
        return false;
      }
    } catch (e) {
      error.value = 'Unexpected error: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<EmployeeModel?> activateEmployee({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'employee', 'activate'],
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final token = data['token'];
        final userData = data['employee'] ?? data['data'];

        await _storage.setString('token', token);
        final employee = EmployeeModel.fromJson(userData);
        _setCurrentUser(UserRole.employee, employee);
        return employee;
      } else {
        error.value = _extractErrorMessage(response);
        return null;
      }
    } catch (e) {
      error.value = 'Error activating employee: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend OTP for an employee
  Future<String?> resendEmployeeOTP(String employeeEmail) async {
      try {
        final response = await _webService.callApi(
          method: HTTP_METHODS.POST,
          path: ['manager', 'employees', 'resend-otp'],
          body: {
            'email': employeeEmail.trim().toLowerCase(),
          },
        );
        if (response.status == API_STATUS.SUCCESS) return "Sent";
        return null;
      } catch (e) { return null; }
  }

  /// Resend OTP for a manager
  Future<String?> resendManagerOTP(String managerEmail) async {
    try {
        final response = await _webService.callApi(
          method: HTTP_METHODS.POST,
          path: ['sa', 'managers', 'resend-otp'],
          body: {
            'email': managerEmail.trim().toLowerCase(),
          },
        );
        if (response.status == API_STATUS.SUCCESS) return "Sent";
        return null;
      } catch (e) { return null; }
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================

  /// Check if there's an existing session and load user profile
  Future<UserRole?> restoreSession() async {
    try {
      // 1. Check local storage first
      final cachedRoleStr = _storage.getString(StorageService.keyUserRole);
      final cachedProfile = _storage.getJson(StorageService.keyUserProfile);
      final token = await _storage.getString('token');

      if (cachedRoleStr != null && cachedProfile != null && token != null) {
        // We have a local token. Ideally we'd test it via an `/auth/me` endpoint.
        final response = await _webService.callApi(
          method: HTTP_METHODS.GET,
          path: ['auth', 'me'],
        );

        if (response.status == API_STATUS.SUCCESS) {
           final data = jsonDecode(response.stringData!);
           final roleStr = data['role'];
           final userData = data['user'];

           UserRole? role;
           if (roleStr == 'super_admin') role = UserRole.superAdmin;
           else if (roleStr == 'manager') role = UserRole.manager;
           else if (roleStr == 'agency') role = UserRole.agency;
           else if (roleStr == 'employee') role = UserRole.employee;

           if (role != null) {
              _setCurrentUser(role, _parseProfile(role, userData));
              return role;
           }
        }
      }
      
      return null;
    } catch (e) {
      print('Error restoring session: $e');
      return null;
    }
  }

  dynamic _parseProfile(UserRole role, Map<String, dynamic> json) {
    switch (role) {
      case UserRole.superAdmin:
        return SuperAdminModel.fromJson(json);
      case UserRole.manager:
      case UserRole.agency:
        return ManagerModel.fromJson(json);
      case UserRole.employee:
        return EmployeeModel.fromJson(json);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _notificationService.stopListening();
      
      // Attempt backend logout (invalidates token)
      await _webService.callApi(
        method: HTTP_METHODS.POST,
        path: ['auth', 'logout'],
      );

      await _storage.clear();
      _clearCurrentUser();
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  void _setCurrentUser(UserRole role, dynamic profile, {bool saveToStorage = true}) {
    _clearCurrentUser();
    currentRole.value = role;

    String? userId;
    Map<String, dynamic>? profileJson;

    switch (role) {
      case UserRole.superAdmin:
        final admin = profile as SuperAdminModel;
        currentSuperAdmin.value = admin;
        userId = admin.id;
        profileJson = admin.toJson();
        break;
      case UserRole.manager:
      case UserRole.agency:
        final manager = profile as ManagerModel;
        currentManager.value = manager;
        userId = manager.id;
        profileJson = manager.toJson();
        break;
      case UserRole.employee:
        final employee = profile as EmployeeModel;
        currentEmployee.value = employee;
        userId = employee.id;
        profileJson = employee.toJson();
        break;
    }

    if (saveToStorage) {
      _storage.setString(StorageService.keyUserRole, role.value);
      if (profileJson != null) {
        _storage.setJson(StorageService.keyUserProfile, profileJson);
      }
      _storage.setBool(StorageService.keyIsLoggedIn, true);
    }

    if (userId != null) {
      // Uses generic backend sockets in future updates
      _notificationService.listenToNotifications(userId, role);
    }
  }

  void _clearCurrentUser() {
    currentRole.value = null;
    currentSuperAdmin.value = null;
    currentManager.value = null;
    currentEmployee.value = null;
  }

  String _extractErrorMessage(ApiResponse response) {
    if (response.stringData == null) return "Unknown error occurred.";
    try {
      final decoded = jsonDecode(response.stringData!);
      return decoded['message'] ?? decoded['error'] ?? "Request failed with status ${response.exception_message}";
    } catch (_) {
      return "Something went wrong.";
    }
  }
}
