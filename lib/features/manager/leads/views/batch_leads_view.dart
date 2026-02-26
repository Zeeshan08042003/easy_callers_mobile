import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/batch_leads_controller.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';

class BatchLeadsView extends StatelessWidget {
  const BatchLeadsView({super.key});

  BatchLeadsController get controller => Get.find<BatchLeadsController>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BatchLeadsController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary.withOpacity(0.5),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('All Leads'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.allLeads.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              )),
            ),
            Tab(
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Attended'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.attendedLeads.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              )),
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
        return TabBarView(
          controller: controller.tabController,
          children: [
            _buildAllLeadsTab(),
            _buildAttendedLeadsTab(),
          ],
        );
      }),
    );
  }

  // ============================================
  // TAB 1: ALL LEADS
  // ============================================

  Widget _buildAllLeadsTab() {
    if (controller.allLeads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        title: 'No Leads',
        subtitle: 'This batch has no leads yet',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.allLeads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildLeadCard(controller.allLeads[index]);
        },
      ),
    );
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  if (lead.assignedToName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lead.assignedToName!,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (lead.email != null || lead.location != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (lead.email != null) ...[
                  Icon(Icons.email_outlined,
                      size: 12, color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      lead.email!,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (lead.email != null && lead.location != null)
                  const SizedBox(width: 12),
                if (lead.location != null) ...[
                  Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textSecondary.withOpacity(0.4)),
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
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // TAB 2: ATTENDED LEADS
  // ============================================

  Widget _buildAttendedLeadsTab() {
    if (controller.attendedLeads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.phone_callback_outlined,
        title: 'No Attended Leads',
        subtitle: 'No calls have been made for this batch yet',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.attendedLeads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildAttendedCard(controller.attendedLeads[index]);
        },
      ),
    );
  }

  Widget _buildAttendedCard(CallLogModel log) {
    final callStatusColor = _getCallStatusColor(log.callStatus);

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
          // Lead name + caller name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.leadName ?? 'Unknown Lead',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (log.leadPhone != null)
                      Text(
                        log.leadPhone!,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Call status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: callStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.callStatus ?? 'Unknown',
                  style: TextStyle(
                    color: callStatusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Details row: caller, duration, time
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Caller name
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          log.employeeName ?? 'Unknown Caller',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Duration
                if (log.callDuration != null || log.callDurationSeconds > 0) ...[
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        log.callDuration ?? _formatSeconds(log.callDurationSeconds),
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                // Time
                const SizedBox(width: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(log.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Feedback if available
          if (log.feedback != null && log.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded,
                    size: 14, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log.feedback!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
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
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.1), size: 72),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.primary;
      case LeadStatus.visiting:
        return AppColors.success;
      case LeadStatus.followUp:
        return AppColors.warning;
      case LeadStatus.converted:
        return const Color(0xFF10B981);
      case LeadStatus.notInterested:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getCallStatusColor(String? status) {
    if (status == null) return AppColors.textSecondary;
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('connected')) {
      return AppColors.success;
    } else if (s.contains('declined') || s.contains('failed') || s.contains('busy')) {
      return AppColors.danger;
    } else if (s.contains('no answer') || s.contains('not reachable')) {
      return AppColors.warning;
    }
    return AppColors.textSecondary;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatSeconds(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
