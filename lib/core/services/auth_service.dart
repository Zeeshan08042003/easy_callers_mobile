import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_callers_mobile/features/super_admin/models/super_admin_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/core/constants/supabase_constants.dart';
import 'dart:convert';

/// Handles all authentication logic with separate role tables:
/// - Super Admin & Manager: email/password login
/// - Employee: OTP-based first activation, then employee/password
/// - Session management
class AuthService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();
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

      // 1. Authenticate with Supabase Auth
      final normalizedEmail = email.toLowerCase().trim();
      final response = await _supabase.client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      if (response.user == null) {
        error.value = 'Login failed. Please check your credentials.';
        return null;
      }

      // 2. Detect which role table this user belongs to
      final result = await _supabase.detectCurrentUser();
      if (result == null) {
        error.value = 'User profile not found. Contact your administrator.';
        await _supabase.client.auth.signOut();
        return null;
      }

      // 3. Set current user based on role
      _setCurrentUser(result.role, result.profile);

      // 4. Check if user is active
      if (result.role == UserRole.employee) {
        final emp = result.profile as EmployeeModel;
        if (!emp.isActive) {
          error.value =
              'Your account is not active. Please verify with OTP first.';
          await _supabase.client.auth.signOut();
          _clearCurrentUser();
          return null;
        }
      } else if (result.role == UserRole.manager || result.role == UserRole.agency) {
        final mgr = result.profile as ManagerModel;
        if (!mgr.isActive) {
          error.value =
              'Your account is not active. Please verify with OTP first.';
          await _supabase.client.auth.signOut();
          _clearCurrentUser();
          return null;
        }
      }

      return result.role;
    } on AuthException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = 'An unexpected error occurred: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // ACCOUNT ACTIVATION (NATIVE OTP)
  // ============================================

  /// Request a native Supabase OTP for account activation
  Future<bool> requestActivationOTP(String email) async {
    try {
      isLoading.value = true;
      error.value = '';

      final normalizedEmail = email.toLowerCase().trim();

      // 1. Verify user exists in our DB first
      final managerChecked = await _supabase.client.rpc(
        'get_manager_for_otp',
        params: {'input_email': normalizedEmail},
      );
      
      final employeeChecked = await _supabase.client.rpc(
        'get_employee_for_otp',
        params: {'input_email': normalizedEmail},
      );

      if ((managerChecked == null || managerChecked.isEmpty) && 
          (employeeChecked == null || employeeChecked.isEmpty)) {
        error.value = 'No account found with this email. Please contact your administrator.';
        return false;
      }

      // 2. Trigger Supabase native OTP
      await _supabase.client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
      );

      return true;
    } catch (e) {
      error.value = 'Failed to send OTP: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER: CREATE EMPLOYEE
  // ============================================


  /// Create a new employee (called by Manager)
  Future<EmployeeModel?> createEmployee({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final managerId = currentManager.value?.id;
      if (managerId == null && currentSuperAdmin.value == null) {
        error.value = 'Only managers can create employees.';
        return null;
      }

      // Insert into employees table
      final normalizedEmail = email.toLowerCase().trim();
      final insertData = {
        'email': normalizedEmail,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': false,
        'manager_id': managerId,
      };
      if (phone != null) insertData['phone'] = phone;

      final response = await _supabase.employeesTable
          .insert(insertData)
          .select()
          .single();

      final employee = EmployeeModel.fromJson(response);
      return employee;
    } catch (e) {
      error.value = 'Error creating employee: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // SUPER ADMIN: CREATE MANAGER
  // ============================================

  /// Create a new manager (called by Super Admin)
  Future<ManagerModel?> createManager({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (currentSuperAdmin.value == null) {
        error.value = 'Only super admins can create managers.';
        return null;
      }

      final normalizedEmail = email.toLowerCase().trim();

      // 1. Insert into managers table (no OTP needed here now)
      final insertData = <String, dynamic>{
        'email': normalizedEmail,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': false,
        'created_by_super_admin_id': currentSuperAdmin.value!.id,
        'manager_type': 'manager',
      };
      if (phone != null) insertData['phone'] = phone;

      final response = await _supabase.managersTable
          .insert(insertData)
          .select()
          .single();

      final manager = ManagerModel.fromJson(response);

      // 2. Log the action
      await _logActivity(
        action: 'create_manager',
        targetType: 'manager',
        targetId: manager.id,
        details: {'manager_email': email},
      );

      return manager;
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

  /// Verify native Supabase OTP
  Future<UserRole?> verifyActivationOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final normalizedEmail = email.toLowerCase().trim();
      
      // 1. Verify with Supabase
      final response = await _supabase.client.auth.verifyOTP(
        email: normalizedEmail,
        token: otpCode,
        type: OtpType.email,
      );

      if (response.session == null) {
        error.value = 'Invalid or expired OTP.';
        return null;
      }

      // 2. Identify role
      final managerData = await _supabase.managersTable
          .select()
          .ilike('email', normalizedEmail)
          .maybeSingle();
      
      if (managerData != null) return UserRole.manager;

      final employeeData = await _supabase.employeesTable
          .select()
          .ilike('email', normalizedEmail)
          .maybeSingle();
      
      if (employeeData != null) return UserRole.employee;

      error.value = 'Account role not recognized.';
      return null;
    } catch (e) {
      error.value = 'OTP verification failed: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete account activation: set password and activate account
  Future<bool> completeActivation({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final normalizedEmail = email.toLowerCase().trim();
      
      // 1. Update password (assumes user is already session-authed by verifyOTP)
      await _supabase.client.auth.updateUser(
        UserAttributes(password: password),
      );

      final authId = _supabase.client.auth.currentUser?.id;
      if (authId == null) {
        error.value = 'Session lost. Please try again.';
        return false;
      }

      // 2. Update our DB record
      if (role == UserRole.manager || role == UserRole.agency) {
        await _supabase.managersTable.update({
          'auth_id': authId,
          'is_active': true,
        }).ilike('email', normalizedEmail);
      } else if (role == UserRole.employee) {
        await _supabase.employeesTable.update({
          'auth_id': authId,
          'is_active': true,
        }).ilike('email', normalizedEmail);
      }

      // 3. Set current session
      final profileResponse = await _supabase.detectCurrentUser();
      if (profileResponse != null) {
        _setCurrentUser(profileResponse.role, profileResponse.profile);
      }
      
      return true;
    } catch (e) {
      error.value = 'Activation failed: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER: SELF REGISTRATION
  // ============================================
  
  /// Register a new manager (self-registration)
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

      // 1. Create auth account
      final normalizedEmail = email.toLowerCase().trim();
      final authResponse = await _supabase.client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      if (authResponse.user == null) {
        error.value = 'Failed to create auth account.';
        return null;
      }

      final authId = authResponse.user!.id;

      // 2. Insert into managers table
      // Default max_employees to 10 for new self-registered managers
      final insertData = <String, dynamic>{
        'auth_id': authId,
        'email': normalizedEmail,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': true,
        'max_employees': 10,
        'manager_type': 'agency',
      };
      if (phone != null) insertData['phone'] = phone;

      final response = await _supabase.managersTable
          .insert(insertData)
          .select()
          .single();

      final manager = ManagerModel.fromJson(response);
      
      // 3. Set current user session
      _setCurrentUser(UserRole.agency, manager);
      
      // 4. Log initial activity
      await _logActivity(
        action: 'manager_self_registration',
        targetType: 'manager',
        targetId: manager.id,
        details: {'email': normalizedEmail},
      );

      return manager;
    } on AuthException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = 'Registration error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
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

      if (cachedRoleStr != null && cachedProfile != null) {
        final role = UserRole.fromString(cachedRoleStr);
        final profile = _parseProfile(role, cachedProfile);
        
        // Populate reactive variables
        _setCurrentUser(role, profile, saveToStorage: false);
        return role;
      }

      // 2. If nothing in storage, check Supabase
      if (_supabase.isLoggedIn) {
        final result = await _supabase.detectCurrentUser();
        if (result != null) {
          _setCurrentUser(result.role, result.profile);
          return result.role;
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
      await _supabase.client.auth.signOut();
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

    // Save to local storage for persistence
    if (saveToStorage) {
      _storage.setString(StorageService.keyUserRole, role.value);
      if (profileJson != null) {
        _storage.setJson(StorageService.keyUserProfile, profileJson);
      }
      _storage.setBool(StorageService.keyIsLoggedIn, true);
    }

    // Start listening for notifications if we have a userId
    if (userId != null) {
      _notificationService.listenToNotifications(userId, role);
    }
  }

  void _clearCurrentUser() {
    currentRole.value = null;
    currentSuperAdmin.value = null;
    currentManager.value = null;
    currentEmployee.value = null;
  }

  /// Log an activity
  Future<void> _logActivity({
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final role = currentRole.value;
      final userId = currentUserId;
      if (role == null || userId == null) return;

      final insertData = <String, dynamic>{
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details ?? {},
      };

      // Set the correct performer column based on current role
      switch (role) {
        case UserRole.superAdmin:
          insertData['performer_super_admin_id'] = userId;
          break;
        case UserRole.manager:
        case UserRole.agency:
          insertData['performer_manager_id'] = userId;
          break;
        case UserRole.employee:
          insertData['performer_employee_id'] = userId;
          break;
      }

      await _supabase.activityLogTable.insert(insertData);
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

}
