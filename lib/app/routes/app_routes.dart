class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String setPassword = '/set-password';
  static const String managerRegistration = '/manager-registration';

  // Super Admin
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String managerList = '/super-admin/managers';
  static const String addManager = '/super-admin/add-manager';
  static const String managerDetail = '/super-admin/manager-detail';
  static const String systemReports = '/super-admin/reports';
  static const String systemSettings = '/super-admin/settings';

  // Manager
  static const String managerDashboard = '/manager/dashboard';
  static const String uploadLeads = '/manager/upload-leads';
  static const String leadBatches = '/manager/lead-batches';
  static const String splitLeads = '/manager/split-leads';
  static const String employeeList = '/manager/employees';
  static const String addEmployee = '/manager/add-employee';
  static const String employeeDetail = '/manager/employee-detail';
  static const String employeeReports = '/manager/employee-reports';
  static const String teamAnalytics = '/manager/team-analytics';
  static const String dailyFollowups = '/manager/daily-followups';
  static const String leadOverview = '/manager/lead-overview';

  // Employee
  static const String employeeDashboard = '/employee/dashboard';
  static const String assignedLeads = '/employee/assigned-leads';
  static const String callFeedback = '/employee/call-feedback';
  static const String callHistory = '/employee/call-history';
  static const String followupList = '/employee/followup-list';
  static const String employeeProfile = '/employee/profile';

  // Shared
  static const String leadDetail = '/lead-detail';
  static const String notifications = '/notifications';
  static const String support = '/support';
}
