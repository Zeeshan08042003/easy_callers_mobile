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
import 'package:easy_callers_mobile/features/project/views/project_list_view.dart';
import 'package:easy_callers_mobile/features/project/views/create_project_view.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/manager_lead_lifecycle_view.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/core/widgets/lead_card.dart';
import 'package:intl/intl.dart';

class ManagerDashboardView extends GetView<ManagerDashboardController> {
  const ManagerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
        index: controller.currentTabIndex.value,
        children: [
          _buildDashboardHome(),
          const ProjectListView(),
          const ManagerTeamView(),
          const ManagerReportsView(),
          const ProfileView(),
        ],
      )),
      bottomNavigationBar: Obx(() => _buildBottomNav()),
    );
  }

  Widget _buildDashboardHome() {
    return RefreshIndicator(
      onRefresh: () { 
        return controller.fetchDashboardData();
      },
      child: SafeArea(
        child: Obx(() {
          // Show create project prompt if no projects exist
          if (controller.hasNoProjects.value && !controller.isLoadingProjects.value) {
            return _buildNoProjectsState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildProjectSelector(),
                const SizedBox(height: 24),
                _buildActionRow(),
                const SizedBox(height: 30),
                _buildStatsRow(),
                const SizedBox(height: 25),
                _buildPerformanceCard(),
                const SizedBox(height: 30),
                _buildLastCallActivity(),
                _buildWeeklyDistribution(),
                const SizedBox(height: 30),
                _buildLifecycleTabsSection(),
                const SizedBox(height: 100), // Extra space at bottom
              ],
            ),
          );
        }),
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
                'Dashboard',
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
                'Lead Distribution & Performance',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
              onTap: () => controller.switchTab(4),
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

  // ============================================
  // NO PROJECTS STATE
  // ============================================

  Widget _buildNoProjectsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 32),
            const Text(
              'Create Your First Project',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Projects organize your leads and callers.\nCreate a project to start uploading excel sheets and distributing leads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.to(() => const CreateProjectView());
                  if (result != null && result is ProjectModel) {
                    controller.onProjectCreated(result);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Create Project',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PROJECT SELECTOR
  // ============================================

  Widget _buildProjectSelector() {
    return Obx(() {
      final selected = controller.selectedProject.value;
      if (selected == null) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
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
      );
    });
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Switch Project',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      Get.back();
                      final result =
                          await Get.to(() => const CreateProjectView());
                      if (result != null && result is ProjectModel) {
                        controller.onProjectCreated(result);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.only(left: 20, right: 20, bottom: 30),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (project.subtitle != null &&
                                    project.subtitle!.isNotEmpty)
                                  Text(
                                    project.subtitle!,
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
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

  Widget _buildActionRow() {
    return Obx(() {
      final hasLastBatch = controller.lastUploadedBatch.value != null;
      
      return Column(
        children: [
          // New Upload Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (controller.isLoading.value || controller.isUploading.value || !controller.canUploadExcel.value) 
                      ? null 
                      : () => controller.uploadLeads(),
                  icon: controller.isUploading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          controller.canUploadExcel.value 
                              ? Icons.cloud_upload_outlined 
                              : Icons.lock_outline_rounded, 
                          size: 24,
                          color: Colors.white,
                        ),
                  label: Text(
                    controller.isUploading.value
                        ? 'Uploading...'
                        : (controller.canUploadExcel.value ? 'New Upload' : 'Upload Restricted'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: controller.canUploadExcel.value ? 4 : 0,
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
          
          // Distribute Button (shown if unassigned leads exist in any batch)
          if (controller.unassignedCount.value > 0) ...[
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
              Obx(() {
                final dist = controller.weeklyDistribution;
                if (dist.isEmpty) return const SizedBox.shrink();
                final bars = dist.length >= 5 ? dist.sublist(dist.length - 5) : dist;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(bars.length, (index) {
                    final factor = bars[index] == 0.0 ? 0.05 : bars[index];
                    return Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                      child: _buildMiniBar(40, factor, isHigh: index == bars.length - 1),
                    );
                  }),
                );
              }),
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
              Obx(() =>
                  FractionallySizedBox(
                widthFactor: (controller.teamPerformance.value / 100).clamp(0.02, 1.0),
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
              ),)
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

  Widget _buildLastCallActivity() {
    return Obx(() {
      final lastCall = controller.lastCallLog.value;
      if (lastCall == null) return const SizedBox.shrink();

      // Lead status
      final leadStatusStr = lastCall.leadStatus?.toString() ?? '';
      String statusLabel = leadStatusStr.isNotEmpty
          ? leadStatusStr.replaceAll('_', ' ').capitalize!
          : 'Unknown';
      Color statusColor;
      if (leadStatusStr == 'interested' || leadStatusStr == 'visiting') {
        statusColor = const Color(0xFF10B981);
      } else if (leadStatusStr == 'not_interested') {
        statusColor = const Color(0xFFFF6B6B);
      } else if (leadStatusStr == 'callback' || leadStatusStr == 'follow_up') {
        statusColor = const Color(0xFFFFB84D);
      } else {
        statusColor = AppColors.textSecondary;
      }

      // Duration
      final durationSecs = lastCall.callDurationSeconds;
      final durationStr = durationSecs > 0
          ? '${durationSecs ~/ 60}m ${durationSecs % 60}s'
          : '0s';

      // Time & Date
      final timeStr = DateFormat('h:mm a').format(lastCall.createdAt);
      final dateStr = DateFormat('dd MMM').format(lastCall.createdAt);

      // Call status
      final callStatusValue = (lastCall.callStatus ?? 'Unknown').toLowerCase();
      String callStatusLabel;
      Color callStatusColor;
      if (callStatusValue.contains('completed') || callStatusValue.contains('connected')) {
        callStatusLabel = 'Connected';
        callStatusColor = const Color(0xFF10B981);
      } else if (callStatusValue.contains('declined') || callStatusValue.contains('failed')) {
        callStatusLabel = 'Declined';
        callStatusColor = const Color(0xFFFF6B6B);
      } else if (callStatusValue.contains('busy')) {
        callStatusLabel = 'Busy';
        callStatusColor = const Color(0xFFFFB84D);
      } else {
        callStatusLabel = lastCall.callStatus ?? 'Unknown';
        callStatusColor = AppColors.textSecondary;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST CALL ACTIVITY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161C28),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: callStatusColor.withOpacity(0.1),
                      child: Icon(
                        callStatusValue.contains('completed') || callStatusValue.contains('connected')
                            ? Icons.call_made_rounded
                            : Icons.call_missed_rounded,
                        color: callStatusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastCall.leadName ?? 'Unknown Lead',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (lastCall.employeeName != null && lastCall.employeeName!.isNotEmpty)
                            Text(
                              'Caller: ${lastCall.employeeName}',
                              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCallMeta('Status', callStatusLabel, callStatusColor),
                    _buildCallMeta('Duration', durationStr, Colors.white),
                    _buildCallMeta('Time', timeStr, Colors.white),
                    _buildCallMeta('Date', dateStr, Colors.white),
                  ],
                ),
                if (lastCall.feedback != null && lastCall.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lastCall.feedback!,
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      );
    });
  }

  Widget _buildCallMeta(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLifecycleTabsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEAD LIFECYCLE',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            GestureDetector(
              onTap: () {
                final status = controller.selectedLifecycleTab.value == 0 ? 'follow_up' : 
                               controller.selectedLifecycleTab.value == 1 ? 'visiting' : 
                               controller.selectedLifecycleTab.value == 2 ? 'visit_completed' : 'all';
                
                final title = controller.selectedLifecycleTab.value == 0 ? 'Follow-up' : 
                               controller.selectedLifecycleTab.value == 1 ? 'Visiting' : 
                               controller.selectedLifecycleTab.value == 2 ? 'Completed' : 'All Leads';
                
                Get.to(() => ManagerLeadLifecycleView(
                  projectId: controller.selectedProject.value!.id,
                  status: status,
                  title: title,
                  managerId: controller.oversightManagerId,
                ));
              },
              child: const Text(
                'FULL VIEW',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Custom TabBar
        Obx(() => Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2432),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildLifecycleTab(0, 'Follow-up', controller.dailyFollowUps.value),
              _buildLifecycleTab(1, 'Visiting', controller.dailyVisiting.value),
              _buildLifecycleTab(2, 'Completed', controller.visitCompleted.value),
              _buildLifecycleTab(3, 'All', controller.allActivityCount.value),
            ],
          ),
        )),
        
        const SizedBox(height: 25),
        
        // Leads List
        Obx(() {
          if (controller.isLoadingLeads.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          
          if (controller.dashboardLeads.isEmpty) {
            return _buildEmptyLeadsState();
          }
          
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.dashboardLeads.length.clamp(0, 10), // Show only top 10 on dashboard
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lead = controller.dashboardLeads[index];
              return LeadCard(
                lead: lead,
                onStatusChanged: (newStatus) {
                  controller.updateLeadStatus(lead.id, newStatus);
                },
                onTap: () {
                  final status = controller.selectedLifecycleTab.value == 0 ? 'follow_up' : 
                                 controller.selectedLifecycleTab.value == 1 ? 'visiting' : 
                                 controller.selectedLifecycleTab.value == 2 ? 'visit_completed' : 'all';
                  
                  final title = controller.selectedLifecycleTab.value == 0 ? 'Follow-up' : 
                                 controller.selectedLifecycleTab.value == 1 ? 'Visiting' : 
                                 controller.selectedLifecycleTab.value == 2 ? 'Completed' : 'All Leads';
                  
                  Get.to(() => ManagerLeadLifecycleView(
                    projectId: controller.selectedProject.value!.id,
                    status: status,
                    title: title,
                    managerId: controller.oversightManagerId,
                  ));
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildLifecycleTab(int index, String label, int count) {
    final isSelected = controller.selectedLifecycleTab.value == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setLifecycleTab(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLeadsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2432).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, 
               color: Colors.white.withOpacity(0.05), size: 64),
          const SizedBox(height: 16),
          Text(
            'No leads found',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Change the tab or check back later',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
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
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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
        currentIndex: controller.currentTabIndex.value,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: controller.switchTab,
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
              child: Icon(Icons.folder_outlined, size: 26),
            ),
            label: 'Projects',
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
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
