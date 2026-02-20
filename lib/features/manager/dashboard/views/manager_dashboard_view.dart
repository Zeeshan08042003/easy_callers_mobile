import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/manager_team_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/manager_team_binding.dart';
import 'package:easy_callers_mobile/features/manager/reports/views/manager_reports_view.dart';
import 'package:easy_callers_mobile/features/manager/reports/bindings/manager_reports_binding.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';

class ManagerDashboardView extends GetView<ManagerDashboardController> {
  const ManagerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () { 
        return controller.fetchDashboardData();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildActionRow(),
                const SizedBox(height: 30),
                _buildStatsRow(),
                const SizedBox(height: 25),
                _buildPerformanceCard(),
                const SizedBox(height: 30),
                _buildWeeklyDistribution(),
                const SizedBox(height: 30),
                _buildTeamStatusSection(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
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
              'Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lead Distribution & Performance',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
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
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=manager'),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActionRow() {
    return Obx(() {
      final hasLastBatch = controller.lastUploadedBatch.value != null;
      final batchLeads = controller.lastUploadedBatch.value?.totalLeads ?? 0;
      
      return Column(
        children: [
          // New Upload Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : () => controller.uploadLeads(),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 24),
                  label: const Text(
                    'New Upload',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF161C28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 26),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          
          // Distribute Button (shown if unassigned leads exist)
          if (hasLastBatch && controller.unassignedCount.value > 0) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : () => controller.distributeLeads(),
                icon: const Icon(Icons.share_outlined, size: 24),
                label: Text(
                  'Distribute ${controller.unassignedCount.value} Leads',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Green color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _buildStatCard(
            'Total Leads',
            controller.totalLeads.value.toString(),
            '+12%',
            Icons.people_rounded,
            const Color(0xFF2563EB),
          )),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Obx(() => _buildStatCard(
            'Leads Assigned',
            '${controller.leadsAssigned.value}%',
            'Target',
            Icons.check_box_rounded,
            const Color(0xFF3B82F6),
          )),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subtext, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: subtext.startsWith('+') ? const Color(0xFF065F46).withOpacity(0.15) : const Color(0xFF1E2432),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  subtext,
                  style: TextStyle(
                    color: subtext.startsWith('+') ? const Color(0xFF10B981) : AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Performance',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    '${controller.teamPerformance.value}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMiniBar(40, 0.4),
                  const SizedBox(width: 6),
                  _buildMiniBar(40, 0.7),
                  const SizedBox(width: 6),
                  _buildMiniBar(40, 0.5),
                  const SizedBox(width: 6),
                  _buildMiniBar(40, 0.8),
                  const SizedBox(width: 6),
                  _buildMiniBar(40, 1.0, isHigh: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.92,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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

  Widget _buildMiniBar(double maxHeight, double factor, {bool isHigh = false}) {
    return Container(
      width: 12,
      height: maxHeight * factor,
      decoration: BoxDecoration(
        color: isHigh ? AppColors.primary : AppColors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildWeeklyDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'WEEKLY DISTRIBUTION',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF3B82F6), size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161C28),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < 6; i++)
                Obx(() {
                  final days = ['M', 'T', 'W', 'T', 'F', 'S'];
                  final isToday = i == 3; 
                  final value = controller.weeklyDistribution.isNotEmpty 
                      ? controller.weeklyDistribution[i] 
                      : 0.0;
                      
                  return _buildDayBar(
                    days[i], 
                    value, 
                    isToday: isToday
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayBar(String day, double factor, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2432),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 80 * factor,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : const Color(0xFF2563EB).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: TextStyle(
            color: isToday ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEAM STATUS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF161C28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildToggleItem('ACTIVE', true),
                  _buildToggleItem('ALL', false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: controller.teamMembers.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTeamMemberItem(
                  member['name'],
                  member['calls'],
                  member['progress'],
                  Color(member['statusColor']),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildToggleItem(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF242C3B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTeamMemberItem(String name, String calls, double progress, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  'https://i.pravatar.cc/150?u=$name',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF161C28), width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      calls,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary.withOpacity(0.4)),
            onPressed: () {},
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
        currentIndex: 0,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          if (index == 1) Get.to(() => const ManagerTeamView(), binding: ManagerTeamBinding());
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
