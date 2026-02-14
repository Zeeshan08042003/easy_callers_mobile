import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';
import 'package:easy_callers_mobile/features/auth/views/login_screen.dart';
import 'package:easy_callers_mobile/features/auth/views/otp_screen.dart';
import 'package:easy_callers_mobile/features/auth/views/set_password_screen.dart';

// These will be uncommented as the screens are built
import 'package:easy_callers_mobile/features/super_admin/dashboard/views/super_admin_dashboard_view.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/bindings/super_admin_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/views/system_reports_view.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/bindings/system_reports_binding.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/views/system_settings_view.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/bindings/system_settings_binding.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/manager_list_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/add_manager_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/manager_oversight_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/bindings/manager_bindings.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/lead_controller_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/lead_controller_binding.dart';
import 'package:easy_callers_mobile/features/manager/reports/views/manager_reports_view.dart';
import 'package:easy_callers_mobile/features/manager/reports/bindings/manager_reports_binding.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/employee_detail_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/employee_detail_binding.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/manager_team_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/manager_team_binding.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/views/employee_dashboard_view.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/bindings/employee_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/support/views/support_view.dart';
import 'package:easy_callers_mobile/features/employee/feedback/views/call_feedback_view.dart';
import 'package:easy_callers_mobile/features/employee/feedback/bindings/call_feedback_binding.dart';
// import 'package:easy_callers_mobile/features/employee/views/employee_dashboard.dart';

class AppPages {
  static final pages = <GetPage>[
    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const NewLoginScreen(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const Scaffold(body: Center(child: Text('Notifications'))),
    ),
    GetPage(
      name: AppRoutes.support,
      page: () => const SupportView(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OTPScreen(),
    ),
    GetPage(
      name: AppRoutes.setPassword,
      page: () => const SetPasswordScreen(),
    ),

    // Super Admin
    GetPage(
      name: AppRoutes.superAdminDashboard,
      page: () => const SuperAdminDashboardView(),
      binding: SuperAdminDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.systemReports,
      page: () => const SystemReportsView(),
      binding: SystemReportsBinding(),
    ),
    GetPage(
      name: AppRoutes.systemSettings,
      page: () => const SystemSettingsView(),
      binding: SystemSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.managerList,
      page: () => const ManagerListView(),
      binding: ManagerListBinding(),
    ),
    GetPage(
      name: AppRoutes.addManager,
      page: () => const AddManagerView(),
      binding: AddManagerBinding(),
    ),
    GetPage(
      name: AppRoutes.managerDetail,
      page: () => const ManagerOversightView(),
    ),

    // Manager
    GetPage(
      name: AppRoutes.leadOverview,
      page: () => const ManagerDashboardView(),
      binding: ManagerDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.teamAnalytics,
      page: () => const ManagerReportsView(),
      binding: ManagerReportsBinding(),
    ),
    GetPage(
      name: AppRoutes.splitLeads,
      page: () => const DistributeLeadsView(),
      binding: DistributeLeadsBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeDetail,
      page: () => const EmployeeDetailView(),
      binding: EmployeeDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeList,
      page: () => const ManagerTeamView(),
      binding: ManagerTeamBinding(),
    ),
    GetPage(
      name: AppRoutes.managerDashboard,
      page: () => const ManagerDashboardView(),
      binding: ManagerDashboardBinding(),
    ),

    // Employee
    GetPage(
      name: AppRoutes.employeeDashboard,
      page: () => const EmployeeDashboardView(),
      binding: EmployeeDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.callFeedback,
      page: () => const CallFeedbackView(),
      binding: CallFeedbackBinding(),
    ),
  ];
}
