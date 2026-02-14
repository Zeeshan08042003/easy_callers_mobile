import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/manager_team_controller.dart';
import 'package:easy_callers_mobile/features/manager/employees/widgets/add_employee_dialog.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/employee_detail_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/employee_detail_binding.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/lead_controller_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/lead_controller_binding.dart';
import 'package:easy_callers_mobile/features/manager/reports/views/manager_reports_view.dart';
import 'package:easy_callers_mobile/features/manager/reports/bindings/manager_reports_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

import '../../../profile/bindings/profile_binding.dart';
import '../../../profile/views/profile_view.dart';

class ManagerTeamView extends GetView<ManagerTeamController> {
  const ManagerTeamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchEmployees,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value && controller.employees.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.employees.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: controller.employees.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final employee = controller.employees[index];
                      return _buildEmployeeCard(employee);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Members',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your lead representatives',
                style: TextStyle(
                  color: AppColors.textSecondary, 
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 26),
              onPressed: () => Get.dialog(const AddEmployeeDialog()),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search employees...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip('All Employees', true),
              _buildFilterChip('Active (12)', false),
              _buildFilterChip('Inactive (0)', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(dynamic employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => const EmployeeDetailView(), binding: EmployeeDetailBinding(), arguments: employee),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://i.pravatar.cc/150?u=${employee.id}',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '18 Visits • 32% Conv.', // Example stats
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Text(
              'Active',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, color: AppColors.textSecondary.withOpacity(0.2), size: 80),
          const SizedBox(height: 20),
          Text(
            'No employees in your team yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Theme(
      data: ThemeData(
        canvasColor: const Color(0xFF0F172A),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          if (index == 0) Get.offAll(() => const ManagerDashboardView(), binding: ManagerDashboardBinding());
          if (index == 2) Get.to(() => const ManagerReportsView(), binding: ManagerReportsBinding());
          if (index == 3) Get.to(() => const ProfileView(), binding: ProfileBinding());
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Icon(Icons.grid_view_rounded, size: 26),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Icon(Icons.people_rounded, size: 26),
            ),
            label: 'Agents',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Icon(Icons.bar_chart_rounded, size: 26),
            ),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Icon(Icons.settings_rounded, size: 26),
            ),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
