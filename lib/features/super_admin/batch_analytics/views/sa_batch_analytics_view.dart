import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/super_admin/batch_analytics/controllers/sa_batch_analytics_controller.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:intl/intl.dart';

class SABatchAnalyticsView extends StatelessWidget {
  const SABatchAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SABatchAnalyticsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.batch.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${controller.batch.totalLeads} total leads',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return Column(
          children: [
            // Manager Selection
            _buildManagerSelector(controller, context),

            // Summary Stats
            _buildSummaryCard(controller),

            // Status Tabs
            _buildStatusTabs(controller),

            // Leads List
            Expanded(child: _buildLeadsList(controller)),
          ],
        );
      }),
    );
  }

  // =============================================
  // MANAGER SELECTOR
  // =============================================
  Widget _buildManagerSelector(
      SABatchAnalyticsController controller, BuildContext context) {
    return Obx(() {
      if (controller.managers.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                const SizedBox(width: 10),
                Text(
                  'No managers in this project',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final selected = controller.selectedManager.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: GestureDetector(
          onTap: () => _showManagerSelectionSheet(controller, context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected != null
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected != null
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                // Manager avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: selected != null
                        ? AppColors.primaryGradient
                        : LinearGradient(colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      selected != null
                          ? Icons.person_rounded
                          : Icons.people_alt_rounded,
                      color: selected != null
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Manager name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected?.managerName ?? 'Select Manager',
                        style: TextStyle(
                          color: selected != null
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected != null
                            ? '${selected.totalLeads} leads • ${selected.employeeIds.length} team members'
                            : 'Tap to select a manager',
                        style: TextStyle(
                          color: selected != null
                              ? AppColors.primary
                              : AppColors.textSecondary.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Assignment badge
                if (selected != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected.hasAssigned
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selected.hasAssigned
                          ? '${selected.assignedLeads} assigned'
                          : 'Not assigned',
                      style: TextStyle(
                        color: selected.hasAssigned
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: selected != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showManagerSelectionSheet(
      SABatchAnalyticsController controller, BuildContext context) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.65),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (controller.selectedManager.value != null)
                    GestureDetector(
                      onTap: () {
                        controller.clearManagerFilter();
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            // Manager list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: controller.managers.length,
                itemBuilder: (context, index) {
                  final mgr = controller.managers[index];
                  return _buildManagerOption(mgr, controller);
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildManagerOption(
      BatchManagerInfo info, SABatchAnalyticsController controller) {
    return Obx(() {
      final isSelected =
          controller.selectedManager.value?.managerId == info.managerId;

      return InkWell(
        onTap: () {
          controller.selectManager(info);
          Get.back();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppColors.primaryGradient
                      : LinearGradient(colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04),
                        ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    info.managerName.isNotEmpty
                        ? info.managerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.managerName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip(
                            '${info.totalLeads} leads', AppColors.primary),
                        _buildMiniChip(
                            '${info.employeeIds.length} team',
                            const Color(0xFF3B82F6)),
                        _buildMiniChip(
                            '${info.totalVisits} visits',
                            const Color(0xFF8B5CF6)),
                        _buildMiniChip(
                          info.hasAssigned
                              ? '${info.assignedLeads} assigned'
                              : 'Not assigned',
                          info.hasAssigned
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Checkmark
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =============================================
  // SUMMARY STATS CARD
  // =============================================
  Widget _buildSummaryCard(SABatchAnalyticsController controller) {
    return Obx(() {
      final manager = controller.selectedManager.value;
      final label = manager != null
          ? '${manager.managerName}\'s Team'
          : 'Overall Stats';

      return Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1F2E), Color(0xFF161C28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (manager != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${manager.employeeIds.length} members',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryStat('Follow-ups',
                    controller.totalFollowUp.value, const Color(0xFFF97316)),
                _buildSummaryStat('Visiting',
                    controller.totalVisiting.value, const Color(0xFF3B82F6)),
                _buildSummaryStat('Completed',
                    controller.totalVisitCompleted.value, const Color(0xFF8B5CF6)),
                _buildSummaryStat('Converted',
                    controller.totalConverted.value, AppColors.success),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =============================================
  // STATUS TABS
  // =============================================
  Widget _buildStatusTabs(SABatchAnalyticsController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2432),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller.tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary.withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        labelPadding: EdgeInsets.zero,
        tabs: [
          Obx(() =>
              _buildTabItem('Follow-up', controller.totalFollowUp.value)),
          Obx(() =>
              _buildTabItem('Visiting', controller.totalVisiting.value)),
          Obx(() => _buildTabItem(
              'Completed', controller.totalVisitCompleted.value)),
          Obx(() =>
              _buildTabItem('Converted', controller.totalConverted.value)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(count.toString(),
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // LEADS LIST
  // =============================================
  Widget _buildLeadsList(SABatchAnalyticsController controller) {
    return Obx(() {
      if (controller.isLoadingLeads.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (controller.filteredLeads.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded,
                  color: Colors.white.withOpacity(0.08), size: 64),
              const SizedBox(height: 12),
              Text(
                'No leads in this status',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => await controller.refreshData(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.filteredLeads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildLeadCard(controller.filteredLeads[index]);
          },
        ),
      );
    });
  }

  Widget _buildLeadCard(LeadModel lead) {
    final statusColor = _getStatusColor(lead.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lead name + status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getInitials(lead.name),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (lead.phone.isNotEmpty)
                      Text(
                        lead.phone.first,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lead.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Team member who updated + timestamp
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Assigned employee (team member)
                if (lead.assignedToName != null) ...[
                  Icon(Icons.person_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      lead.assignedToName!,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (lead.status == LeadStatus.visitCompleted ||
                    lead.status == LeadStatus.converted) ...[
                  Icon(Icons.person_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      lead.uploadedByName ?? 'Team Lead',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Icon(Icons.person_off_outlined,
                      size: 14,
                      color: AppColors.warning.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    'Unassigned',
                    style: TextStyle(
                      color: AppColors.warning.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                // Last updated time
                Icon(Icons.update_rounded,
                    size: 12,
                    color: AppColors.textSecondary.withOpacity(0.3)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(lead.updatedAt),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Location row
          if (lead.location != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    lead.location!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // HELPERS
  // =============================================
  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.followUp:
        return const Color(0xFFF97316);
      case LeadStatus.visiting:
        return const Color(0xFF3B82F6);
      case LeadStatus.visitCompleted:
        return const Color(0xFF8B5CF6);
      case LeadStatus.converted:
        return AppColors.success;
      case LeadStatus.drop:
        return AppColors.danger;
      case LeadStatus.newLead:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
