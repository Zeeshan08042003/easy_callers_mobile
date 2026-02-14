import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_callers_mobile/core/constants/supabase_constants.dart';
import 'package:easy_callers_mobile/core/models/super_admin_model.dart';
import 'package:easy_callers_mobile/core/models/manager_model.dart';
import 'package:easy_callers_mobile/core/models/employee_model.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

/// Singleton service that wraps the Supabase client.
/// Initialized once in main.dart and accessed via GetX.
class SupabaseService extends GetxService {
  late final SupabaseClient _client;

  SupabaseClient get client => _client;

  /// Current Supabase Auth user
  User? get currentAuthUser => _client.auth.currentUser;

  /// Current auth session
  Session? get currentSession => _client.auth.currentSession;

  /// Whether the user is logged in
  bool get isLoggedIn => currentAuthUser != null;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Initialize Supabase (call once in main.dart)
  static Future<SupabaseService> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );

    final service = SupabaseService();
    service._client = Supabase.instance.client;
    return service;
  }

  // ============================================
  // TABLE HELPERS
  // ============================================

  SupabaseQueryBuilder from(String table) => _client.from(table);

  /// Role tables
  SupabaseQueryBuilder get superAdminsTable =>
      _client.from(SupabaseConstants.superAdminsTable);

  SupabaseQueryBuilder get managersTable =>
      _client.from(SupabaseConstants.managersTable);

  SupabaseQueryBuilder get employeesTable =>
      _client.from(SupabaseConstants.employeesTable);

  /// Data tables
  SupabaseQueryBuilder get leadsTable =>
      _client.from(SupabaseConstants.leadsTable);

  SupabaseQueryBuilder get leadBatchesTable =>
      _client.from(SupabaseConstants.leadBatchesTable);

  SupabaseQueryBuilder get callLogsTable =>
      _client.from(SupabaseConstants.callLogsTable);

  SupabaseQueryBuilder get dailyReportsTable =>
      _client.from(SupabaseConstants.dailyReportsTable);

  SupabaseQueryBuilder get notificationsTable =>
      _client.from(SupabaseConstants.notificationsTable);

  SupabaseQueryBuilder get activityLogTable =>
      _client.from(SupabaseConstants.activityLogTable);

  /// Storage
  SupabaseStorageClient get storage => _client.storage;

  // ============================================
  // USER LOOKUP (checks all 3 role tables)
  // ============================================

  /// Detect which role the current auth user has and return their profile.
  /// Checks super_admins → managers → employees in order.
  /// Returns a record with the role and the model.
  Future<({UserRole role, dynamic profile})?> detectCurrentUser() async {
    if (currentAuthUser == null) return null;
    final authId = currentAuthUser!.id;

    try {
      // 1. Check super_admins
      final adminData = await superAdminsTable
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      if (adminData != null) {
        return (
          role: UserRole.superAdmin,
          profile: SuperAdminModel.fromJson(adminData)
        );
      }

      // 2. Check managers
      final managerData = await managersTable
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      if (managerData != null) {
        return (
          role: UserRole.manager,
          profile: ManagerModel.fromJson(managerData)
        );
      }

      // 3. Check employees
      final employeeData = await employeesTable
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      if (employeeData != null) {
        return (
          role: UserRole.employee,
          profile: EmployeeModel.fromJson(employeeData)
        );
      }

      return null;
    } catch (e) {
      print('Error detecting user role: $e');
      return null;
    }
  }
}
