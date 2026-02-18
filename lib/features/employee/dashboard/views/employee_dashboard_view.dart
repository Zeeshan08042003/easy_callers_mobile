import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/controllers/employee_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/employee/views/lead_detail_view.dart';
import 'package:easy_callers_mobile/features/employee/views/call_history_view.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';
import 'package:intl/intl.dart';

class EmployeeDashboardView extends GetView<EmployeeDashboardController> {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildStatsCards(),
              _buildProgressBar(),
              _buildStartCallingButton(),
              _buildUpcomingQueue(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      'Hello, ${controller.employeeName}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
                GestureDetector(
                  onTap: () => Get.to(
                    () => const ProfileView(),
                    binding: ProfileBinding(),
                  ),
                  child: Obx(() => CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    backgroundImage: controller.profileImageUrl.value != null
                        ? NetworkImage(controller.profileImageUrl.value!)
                        : null,
                    child: controller.profileImageUrl.value == null
                        ? Text(
                            controller.employeeInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'PENDING',
                value: controller.pendingLeadsCount,
                subtitle: 'Leads',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                label: 'CONTACTED',
                value: controller.contactedLeadsCount,
                subtitle: controller.goalPercentage,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required RxInt value,
    required String subtitle,
    required Color color,
  }) {
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            value.value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          )),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(() {
          final progress = controller.dailyProgress.value;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: (progress * 100).toInt(),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - progress) * 100).toInt(),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStartCallingButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final hasLeads = controller.assignedLeads.isNotEmpty;
          return SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: hasLeads ? controller.startCalling : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.cardBg,
                disabledForegroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: hasLeads ? 4 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasLeads ? Icons.play_arrow_rounded : Icons.check_circle_outline,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasLeads ? 'Start Calling' : 'All Caught Up!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUpcomingQueue() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Queue',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full leads list
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.assignedLeads.isEmpty) {
                return _buildEmptyQueue();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.assignedLeads.length > 3 
                    ? 3 
                    : controller.assignedLeads.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lead = controller.assignedLeads[index];
                  return _buildLeadQueueCard(lead);
                },
              );
            }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadQueueCard(dynamic lead) {
    // Get initials from name
    final nameParts = lead.name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : lead.name.substring(0, 2).toUpperCase();

    // Generate color based on name
    final colors = [
      AppColors.primary,
      AppColors.success,
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB84D),
      const Color(0xFF9B59B6),
    ];
    final colorIndex = lead.name.hashCode % colors.length;

    return GestureDetector(
      onTap: () => Get.to(
        () => LeadDetailView(lead: lead),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors[colorIndex].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: colors[colorIndex],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lead.phone,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => Get.to(
                  () => LeadDetailView(lead: lead),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'All Caught Up!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No pending leads at the moment',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Obx(() => BottomNavigationBar(
          currentIndex: controller.currentNavIndex.value,
          onTap: controller.onNavTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 24),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded, size: 24),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded, size: 24),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              label: 'PROFILE',
            ),
          ],
        )),
      ),
    );
  }
}
