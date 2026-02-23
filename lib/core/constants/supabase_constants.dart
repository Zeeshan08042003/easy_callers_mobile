class SupabaseConstants {
  static const String supabaseUrl = 'https://nlabqohuthloefqtcdzt.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_SzKr1K2YLyckX3CvWDJ2xA_pBsiYRRC';

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
