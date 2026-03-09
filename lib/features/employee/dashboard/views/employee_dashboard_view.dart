import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/controllers/employee_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/employee/views/lead_detail_view.dart';
import 'package:easy_callers_mobile/features/employee/views/call_history_view.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';
import 'package:intl/intl.dart';

import '../../../manager/models/lead_model.dart';

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
              _buildProjectSelector(),
              _buildStatsCards(),
              _buildProgressBar(),
              _buildStartCallingButton(),
              _buildQueueAndFollowupSection(),
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

  Widget _buildProjectSelector() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final selected = controller.selectedProject.value;
        if (selected == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: GestureDetector(
            onTap: () => _showProjectPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2432),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selected.subtitle != null &&
                            selected.subtitle!.isNotEmpty)
                          Text(
                            selected.subtitle!,
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (controller.projects.length > 1) ...[
                    Text(
                      '${controller.projects.length}',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary.withOpacity(0.5), size: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showProjectPicker() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2030),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Switch Project',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                itemCount: controller.projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final project = controller.projects[index];
                  final isSelected =
                      project.id == controller.selectedProject.value?.id;
                  return GestureDetector(
                    onTap: () {
                      controller.selectProject(project);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : const Color(0xFF232B3E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.4)
                              : Colors.white.withOpacity(0.03),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (project.subtitle != null &&
                                    project.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    project.subtitle!,
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildQueueAndFollowupSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Schedule',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomTabBar(),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedQueueTab.value == 0) {
                return _buildQueueList();
              } else {
                return _buildFollowUpList();
              }
            }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'QUEUE', controller.assignedLeads.length),
          _buildTabItem(1, 'FOLLOW-UPS', controller.pendingFollowups.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, int count) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedQueueTab.value = index,
        child: Obx(() {
          final isSelected = controller.selectedQueueTab.value == index;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQueueList() {
    if (controller.assignedLeads.isEmpty) {
      return _buildEmptyQueue('No pending leads in queue');
    }
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.assignedLeads.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lead = controller.assignedLeads[index];
            return _buildLeadQueueCard(lead);
          },
        ),
        const SizedBox(height: 20),
        if (controller.hasMoreLeads.value)
          Obx(() => controller.isLoadingMore.value
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: controller.loadMoreLeads,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Load More Leads'),
                  ),
                )),
      ],
    );
  }

  Widget _buildFollowUpList() {
    if (controller.pendingFollowups.isEmpty) {
      return _buildEmptyQueue('No follow-ups scheduled for today');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.pendingFollowups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lead = controller.pendingFollowups[index];
        return _buildLeadQueueCard(lead, isFollowUp: true);
      },
    );
  }

  Widget _buildLeadQueueCard(LeadModel lead, {bool isFollowUp = false}) {
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
    final colorIndex = lead.name.hashCode.abs() % colors.length;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFollowUp)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DUE',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lead.phone.isNotEmpty ? lead.phone.first.toString() : 'No Phone',
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
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue(String message) {
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
            message,
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
