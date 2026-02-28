class SupabaseConstants {
  // Credentials are now managed via FlavorConfig (lib/core/config/flavor_config.dart)
  // See main_prod.dart and main_beta.dart for environment-specific URLs.

  // Role tables
  static const String superAdminsTable = 'super_admins';
  static const String managersTable = 'managers';
  static const String employeesTable = 'employees';

  // Data tables
  static const String leadsTable = 'leads';
  static const String leadBatchesTable = 'lead_batches';
  static const String callLogsTable = 'call_logs';
  static const String dailyReportsTable = 'daily_reports';
  static const String notificationsTable = 'notifications';
  static const String activityLogTable = 'activity_log';

  // Project tables
  static const String projectsTable = 'projects';
  static const String projectMembersTable = 'project_members';
  static const String projectCallersTable = 'project_callers';

  // Storage buckets
  static const String leadFilesBucket = 'lead-files';
}
