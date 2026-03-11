import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/controllers/super_admin_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/manager_list_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/add_manager_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/bindings/manager_bindings.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/views/system_settings_view.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/bindings/system_settings_binding.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/views/system_reports_view.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/bindings/system_reports_binding.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';
import 'package:easy_callers_mobile/features/project/views/project_list_view.dart';
import 'package:easy_callers_mobile/features/project/views/project_detail_view.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

import '../../../manager/leads/bindings/lead_controller_binding.dart';
import '../../../manager/leads/views/lead_controller_view.dart';
import '../../managers/views/manager_oversight_view.dart';

class SuperAdminDashboardView extends GetView<SuperAdminDashboardController> {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminDashboardController(), permanent: true);
    // Always refresh data when dashboard is built (handles hot restart)
    controller.refreshDashboard();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
        index: controller.currentTabIndex.value,
        children: [
          _buildDashboardHome(),
          const ProjectListView(),
          const SystemReportsView(),
          const ManagerListView(),
          const SystemSettingsView(),
        ],
      )),
      floatingActionButton: Obx(() => controller.currentTabIndex.value == 0 ? FloatingActionButton(
        heroTag: 'sa_dashboard_fab',
        onPressed: () => Get.to(() => const AddManagerView()),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ) : const SizedBox.shrink()),
      bottomNavigationBar: Obx(() => _buildBottomNav()),
    );
  }

  Widget _buildDashboardHome() {
    return SafeArea(
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
              _buildProjectsHeader(),
              const SizedBox(height: 15),
              _buildProjectsList(),
              const SizedBox(height: 30),
              _buildRecentManagersHeader(),
              const SizedBox(height: 15),
              _buildRecentManagersList(),
              const SizedBox(height: 80), // Space for bottom nav or FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
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
              onTap: () => Get.to(() => const ProfileView()),
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
          Text(
            'Total Leads',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
        ],
      ),
    );
  }

  Widget _buildSmallStatsGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: _buildSmallStatCard('MANAGERS', controller.totalManagers)
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140, 
            child: _buildSmallStatCard('EMPLOYEES', controller.totalEmployees)
          ),
          Obx(() => controller.totalAgencies.value > 0 
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 140,
                  child: _buildSmallStatCard('AGENCIES', controller.totalAgencies)
                ),
              )
            : const SizedBox.shrink()
          ),
        ],
      ),
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
          onPressed: () => controller.switchTab(3),
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
            onPressed: () => Get.to(
              () => const ManagerOversightView(), 
              arguments: manager,
            ),
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

  Widget _buildProjectsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Projects',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => controller.switchTab(1),
          child: const Text(
            'See All',
            style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.recentProjects.isEmpty) {
        return const SizedBox.shrink();
      }
      if (controller.recentProjects.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, color: AppColors.textSecondary.withOpacity(0.2), size: 40),
              const SizedBox(height: 12),
              Text(
                'Create your first project to organize managers',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ),
        );
      }
      return SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.recentProjects.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final project = controller.recentProjects[index];
            return _buildProjectMiniCard(project);
          },
        ),
      );
    });
  }

  Widget _buildProjectMiniCard(ProjectModel project) {
    return GestureDetector(
      onTap: () => Get.to(() => const ProjectDetailView(), arguments: project),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161C28),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_rounded, color: AppColors.primary, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${project.memberCount ?? 0} MGRS',
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.subtitle ?? 'Project Workspace',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
        currentIndex: controller.currentTabIndex.value,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: controller.switchTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment_rounded), label: 'Agencies'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'System'),
        ],
      ),
    );
  }
}
