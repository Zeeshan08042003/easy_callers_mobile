import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/controllers/super_admin_dashboard_controller.dart';
import 'package:easy_callers_mobile/core/models/manager_model.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/manager_list_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/add_manager_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/bindings/manager_bindings.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/views/system_settings_view.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/bindings/system_settings_binding.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/views/system_reports_view.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/bindings/system_reports_binding.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

import '../../../manager/leads/bindings/lead_controller_binding.dart';
import '../../../manager/leads/views/lead_controller_view.dart';
import '../../managers/views/manager_oversight_view.dart';

class SuperAdminDashboardView extends GetView<SuperAdminDashboardController> {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildTotalVisitsCard(),
                const SizedBox(height: 20),
                _buildSmallStatsGrid(),
                const SizedBox(height: 30),
                _buildSearchField(),
                const SizedBox(height: 30),
                _buildRecentManagersHeader(),
                const SizedBox(height: 15),
                _buildRecentManagersList(),
                const SizedBox(height: 80), // Space for bottom nav or FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddManagerView(), binding: AddManagerBinding()),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Super Admin',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GLOBAL NETWORK CONTROL',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2432),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () => Get.to(() => const ProfileView(), binding: ProfileBinding()),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin'),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTotalVisitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Visits',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F46).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+12%',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.totalLeads.value.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
              (Match m) => '${m[1]},'
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          )),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.65,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildSmallStatCard('MANAGERS', controller.totalManagers)),
        const SizedBox(width: 15),
        Expanded(child: _buildSmallStatCard('EMPLOYEES', controller.totalEmployees)),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, RxInt count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            count.value.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2432).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search agencies or managers...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary.withOpacity(0.5), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRecentManagersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Managers',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => Get.to(() => const ManagerListView(), binding: ManagerListBinding()),
          child: const Text(
            'See All',
            style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentManagersList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (controller.recentManagers.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentManagers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final manager = controller.recentManagers[index];
          return _buildManagerCard(manager);
        },
      );
    });
  }

  Widget _buildManagerCard(ManagerModel manager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              manager.profileImageUrl ?? 'https://i.pravatar.cc/150?u=${manager.id}',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Urban Living Realty', // Example agency name from screenshot
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.to(() => const ManagerOversightView(), arguments: manager),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2432),
              foregroundColor: const Color(0xFF3B82F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('View Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.people_outline, color: AppColors.textSecondary.withOpacity(0.3), size: 60),
            const SizedBox(height: 15),
            Text(
              'No managers found',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Theme(
      data: ThemeData(canvasColor: AppColors.background),
      child: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Get.to(() => const SystemReportsView(), binding: SystemReportsBinding());
          }
          if (index == 2) {
            Get.to(() => const ManagerListView(), binding: ManagerListBinding());
          }
          if (index == 3) {
            Get.to(() => const SystemSettingsView(), binding: SystemSettingsBinding());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment_rounded), label: 'Agencies'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'System'),
        ],
      ),
    );
  }
}
