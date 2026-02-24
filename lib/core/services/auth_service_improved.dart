import 'dart:math';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_callers_mobile/features/super_admin/models/super_admin_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

/// IMPROVED Authentication Service
/// 
/// Simplified employee authentication flow with better error handling
/// and cleaner code structure.
class AuthService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final NotificationService _notificationService = Get.find<NotificationService>();

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

      // 4. Check if employee is active
      if (result.role == UserRole.employee) {
        final emp = result.profile as EmployeeModel;
        if (!emp.isActive) {
          error.value =
              'Your account is not active. Please complete activation first.';
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
  // EMPLOYEE OTP ACTIVATION (SIMPLIFIED)
  // ============================================

  /// Verify OTP for employee first-time activation
  Future<bool> verifyEmployeeOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final normalizedEmail = email.toLowerCase().trim();
      
      // Call the database function to get employee
      final result = await _supabase.client.rpc(
        'get_employee_for_otp',
        params: {'input_email': normalizedEmail},
      );

      if (result == null || (result is List && result.isEmpty)) {
        error.value = 'No employee account found with this email.';
        return false;
      }

      // Parse the employee data
      final employeeData = result is List ? result.first : result;
      final employee = EmployeeModel.fromJson(employeeData);

      // Verify OTP
      if (employee.otpCode != otpCode) {
        error.value = 'Invalid OTP code. Please try again.';
        return false;
      }

      // Check expiration
      if (employee.isOTPExpired) {
        error.value = 'OTP has expired. Please request a new one.';
        return false;
      }

      return true;
    } catch (e) {
      error.value = 'Error verifying OTP: $e';
      print('OTP Verification Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete employee activation: set password and activate account
  Future<EmployeeModel?> activateEmployee({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final normalizedEmail = email.toLowerCase().trim();
      String? authUserId;

      // 1. Create or get auth account
      try {
        final authResponse = await _supabase.client.auth.signUp(
          email: normalizedEmail,
          password: password,
        );

        if (authResponse.user != null) {
          authUserId = authResponse.user!.id;
        } else {
          error.value = 'Failed to create account. Please try again.';
          return null;
        }
      } on AuthException catch (e) {
        // If user already exists, try to sign in
        if (e.message.contains('already registered') || 
            e.message.contains('User already registered')) {
          try {
            final signInResponse = await _supabase.client.auth.signInWithPassword(
              email: normalizedEmail,
              password: password,
            );
            
            if (signInResponse.user != null) {
              authUserId = signInResponse.user!.id;
            } else {
              error.value = 'Account exists but password is incorrect.';
              return null;
            }
          } catch (signInError) {
            error.value = 'Account exists but password is incorrect.';
            return null;
          }
        } else {
          throw e;
        }
      }

      if (authUserId == null) {
        error.value = 'Failed to create or access account.';
        return null;
      }

      // 2. Find employee record using ILIKE for case-insensitive match
      final employeeRecords = await _supabase.employeesTable
          .select()
          .ilike('email', normalizedEmail);

      if (employeeRecords.isEmpty) {
        error.value = 'No employee account found. Contact your manager.';
        return null;
      }

      if (employeeRecords.length > 1) {
        error.value = 'Multiple accounts found. Contact your administrator.';
        return null;
      }

      // 3. Update employee: activate and link auth_id
      final employeeId = employeeRecords.first['id'];
      await _supabase.employeesTable.update({
        'auth_id': authUserId,
        'is_active': true,
        'otp_code': null,
        'otp_expires_at': null,
      }).eq('id', employeeId);

      // 4. Fetch and return updated employee
      final data = await _supabase.employeesTable
          .select()
          .eq('id', employeeId)
          .single();

      final employee = EmployeeModel.fromJson(data);
      _setCurrentUser(UserRole.employee, employee);
      
      return employee;
    } on AuthException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = 'Error activating employee: $e';
      print('Activation Error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER: CREATE EMPLOYEE
  // ============================================

  /// Generate a 6-digit OTP
  String generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Create a new employee (called by Manager)
  Future<({EmployeeModel? employee, String? otp})> createEmployee({
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
        return (employee: null, otp: null);
      }

      // Generate OTP
      final otp = generateOTP();
      final otpExpiry = DateTime.now().add(const Duration(hours: 24));

      // Insert into employees table
      final normalizedEmail = email.toLowerCase().trim();
      final insertData = {
        'email': normalizedEmail,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': false,
        'manager_id': managerId,
        'otp_code': otp,
        'otp_expires_at': otpExpiry.toIso8601String(),
      };
      if (phone != null) insertData['phone'] = phone;

      final response = await _supabase.employeesTable
          .insert(insertData)
          .select()
          .single();

      final employee = EmployeeModel.fromJson(response);
      return (employee: employee, otp: otp);
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

  /// Create a new manager (called by Super Admin)
  Future<ManagerModel?> createManager({
    required String email,
    required String password,
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

      // 1. Create auth account
      final normalizedEmail = email.toLowerCase().trim();
      final tempAuth = await _supabase.client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      if (tempAuth.user == null) {
        error.value = 'Failed to create auth account for manager.';
        return null;
      }

      final authId = tempAuth.user!.id;

      // 2. Insert into managers table
      final insertData = <String, dynamic>{
        'auth_id': authId,
        'email': normalizedEmail,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': true,
        'created_by_super_admin_id': currentSuperAdmin.value!.id,
      };
      if (phone != null) insertData['phone'] = phone;

      final response = await _supabase.managersTable
          .insert(insertData)
          .select()
          .single();

      // 3. Log the action
      await _logActivity(
        action: 'create_manager',
        targetType: 'manager',
        targetId: response['id'],
        details: {'manager_email': email},
      );

      return ManagerModel.fromJson(response);
    } on AuthException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = 'Error creating manager: $e';
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
      if (!_supabase.isLoggedIn) return null;

      final result = await _supabase.detectCurrentUser();
      if (result != null) {
        _setCurrentUser(result.role, result.profile);
        return result.role;
      }
      return null;
    } catch (e) {
      print('Error restoring session: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _notificationService.stopListening();
      await _supabase.client.auth.signOut();
      _clearCurrentUser();
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  void _setCurrentUser(UserRole role, dynamic profile) {
    _clearCurrentUser();
    currentRole.value = role;

    String? userId;

    switch (role) {
      case UserRole.superAdmin:
        final admin = profile as SuperAdminModel;
        currentSuperAdmin.value = admin;
        userId = admin.id;
        break;
      case UserRole.manager:
        final manager = profile as ManagerModel;
        currentManager.value = manager;
        userId = manager.id;
        break;
      case UserRole.employee:
        final employee = profile as EmployeeModel;
        currentEmployee.value = employee;
        userId = employee.id;
        break;
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

  /// Resend OTP for an employee
  Future<String?> resendEmployeeOTP(String employeeEmail) async {
    try {
      final otp = generateOTP();
      final otpExpiry = DateTime.now().add(const Duration(hours: 24));

      final normalizedEmail = employeeEmail.toLowerCase().trim();
      await _supabase.employeesTable.update({
        'otp_code': otp,
        'otp_expires_at': otpExpiry.toIso8601String(),
      }).ilike('email', normalizedEmail);

      return otp;
    } catch (e) {
      print('Error resending OTP: $e');
      return null;
    }
  }
}
