import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/employee/controllers/call_history_controller.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:intl/intl.dart';

class CallHistoryView extends StatelessWidget {
  const CallHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CallHistoryController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Call History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            onPressed: controller.showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildFilterTabs(controller),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshCallHistory,
              color: AppColors.primary,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (controller.filteredLeads.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildLeadsList(controller);
              }),
            ),
          ),
          _buildWeeklyPerformance(controller),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CallHistoryController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          controller: controller.searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search clients or numbers',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: controller.onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(CallHistoryController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab(
              label: 'All',
              isSelected: controller.selectedFilter.value == 'all',
              onTap: () => controller.selectedFilter.value = 'all',
            ),
            const SizedBox(width: 10),
            _buildFilterTab(
              label: 'Missed',
              isSelected: controller.selectedFilter.value == 'missed',
              onTap: () => controller.selectedFilter.value = 'missed',
            ),
            const SizedBox(width: 10),
            _buildFilterTab(
              label: 'Follow-up',
              isSelected: controller.selectedFilter.value == 'followup',
              onTap: () => controller.selectedFilter.value = 'followup',
            ),
            const SizedBox(width: 10),
            _buildFilterTab(
              label: 'Visiting',
              isSelected: controller.selectedFilter.value == 'visiting',
              onTap: () => controller.selectedFilter.value = 'visiting',
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Each item = 1 lead (latest call log), tappable to see full history
  Widget _buildLeadsList(CallHistoryController controller) {
    return Obx(() {
      final leads = controller.filteredLeads;

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final latestLog = leads[index];
          final callCount = controller.getCallCountForLead(latestLog.leadId);
          return _buildLeadCard(controller, latestLog, callCount);
        },
      );
    });
  }

  Widget _buildLeadCard(CallHistoryController controller, CallLogModel latestLog, int callCount) {
    // Determine lead status color and icon based on latest call
    final leadStatusStr = latestLog.leadStatus?.toString() ?? '';
    final callStatusValue = (latestLog.callStatus ?? 'unknown').toLowerCase();

    IconData icon;
    Color statusColor;
    String statusLabel;

    // Priority: lead status > call status
    if (leadStatusStr == 'visiting') {
      icon = Icons.location_on_rounded;
      statusColor = AppColors.success;
      statusLabel = 'Visiting';
    } else if (leadStatusStr == 'interested') {
      icon = Icons.thumb_up_rounded;
      statusColor = AppColors.success;
      statusLabel = 'Interested';
    } else if (leadStatusStr == 'not_interested') {
      icon = Icons.thumb_down_rounded;
      statusColor = const Color(0xFFFF6B6B);
      statusLabel = 'Not Interested';
    } else if (leadStatusStr == 'callback' || leadStatusStr == 'follow_up') {
      icon = Icons.access_time_rounded;
      statusColor = const Color(0xFFFFB84D);
      statusLabel = leadStatusStr == 'callback' ? 'Callback' : 'Follow-up';
    } else if (leadStatusStr == 'closed') {
      icon = Icons.check_circle_rounded;
      statusColor = AppColors.textSecondary;
      statusLabel = 'Closed';
    } else if (callStatusValue.contains('completed') || callStatusValue.contains('connected')) {
      icon = Icons.phone_rounded;
      statusColor = AppColors.primary;
      statusLabel = 'Completed';
    } else if (callStatusValue.contains('declined') || callStatusValue.contains('failed') ||
        callStatusValue.contains('missed') || callStatusValue.contains('no_answer')) {
      icon = Icons.phone_missed_rounded;
      statusColor = const Color(0xFFFF6B6B);
      statusLabel = 'Missed';
    } else {
      icon = Icons.phone_callback_rounded;
      statusColor = AppColors.textSecondary;
      statusLabel = latestLog.callStatus ?? 'Unknown';
    }

    // Time
    final timeAgo = _getRelativeTime(latestLog.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => _showLeadCallHistory(controller, latestLog),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Lead info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latestLog.leadName ?? 'Unknown Lead',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call count badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (callCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$callCount calls',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet with all call history for a specific lead
  void _showLeadCallHistory(CallHistoryController controller, CallLogModel latestLog) {
    final allLogs = controller.getLogsForLead(latestLog.leadId);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestLog.leadName ?? 'Unknown Lead',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latestLog.leadPhone ?? ''} • ${allLogs.length} call${allLogs.length != 1 ? 's' : ''}',
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            // Call logs list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: allLogs.length,
                itemBuilder: (context, index) {
                  return _buildCallLogDetailItem(allLogs[index], index == 0);
                },
              ),
            ),
            // Call Client Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => controller.navigateToLeadDetail(latestLog.leadId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.phone_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Call Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildCallLogDetailItem(CallLogModel log, bool isLatest) {
    final callStatusValue = (log.callStatus ?? 'unknown').toLowerCase();
    final leadStatusStr = log.leadStatus?.toString() ?? '';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt);
    final duration = _formatDuration(log.callDurationSeconds);

    // Determine call status display
    String callStatusLabel;
    Color callStatusColor;
    IconData callIcon;

    if (callStatusValue.contains('completed') || callStatusValue.contains('connected')) {
      callStatusLabel = 'Connected';
      callStatusColor = AppColors.success;
      callIcon = Icons.call_made_rounded;
    } else if (callStatusValue.contains('declined') || callStatusValue.contains('failed')) {
      callStatusLabel = 'Declined / Failed';
      callStatusColor = const Color(0xFFFF6B6B);
      callIcon = Icons.call_missed_rounded;
    } else if (callStatusValue.contains('no_answer') || callStatusValue.contains('no answer')) {
      callStatusLabel = 'No Answer';
      callStatusColor = const Color(0xFFFF6B6B);
      callIcon = Icons.call_missed_outgoing_rounded;
    } else if (callStatusValue.contains('busy')) {
      callStatusLabel = 'Busy';
      callStatusColor = const Color(0xFFFFB84D);
      callIcon = Icons.phone_paused_rounded;
    } else {
      callStatusLabel = log.callStatus ?? 'Unknown';
      callStatusColor = AppColors.textSecondary;
      callIcon = Icons.phone_rounded;
    }

    // Lead status badge
    String? leadStatusLabel;
    Color? leadStatusColor;
    if (leadStatusStr == 'visiting') {
      leadStatusLabel = 'VISITING';
      leadStatusColor = AppColors.success;
    } else if (leadStatusStr == 'interested') {
      leadStatusLabel = 'INTERESTED';
      leadStatusColor = AppColors.success;
    } else if (leadStatusStr == 'not_interested') {
      leadStatusLabel = 'NOT INTERESTED';
      leadStatusColor = const Color(0xFFFF6B6B);
    } else if (leadStatusStr == 'callback' || leadStatusStr == 'follow_up') {
      leadStatusLabel = leadStatusStr == 'callback' ? 'CALLBACK' : 'FOLLOW-UP';
      leadStatusColor = const Color(0xFFFFB84D);
    } else if (leadStatusStr == 'closed') {
      leadStatusLabel = 'CLOSED';
      leadStatusColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.primary.withOpacity(0.05) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest ? AppColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(callIcon, color: callStatusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                callStatusLabel,
                style: TextStyle(
                  color: callStatusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LATEST',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                duration,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (leadStatusLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: leadStatusColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                leadStatusLabel,
                style: TextStyle(
                  color: leadStatusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (log.feedback != null && log.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.feedback!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (log.followUpDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  leadStatusStr == 'visiting' ? Icons.location_on : Icons.event_rounded,
                  size: 13,
                  color: leadStatusStr == 'visiting' ? AppColors.success : const Color(0xFFFFB84D),
                ),
                const SizedBox(width: 4),
                Text(
                  leadStatusStr == 'visiting'
                      ? 'Visit: ${DateFormat('dd MMM yyyy, hh:mm a').format(log.followUpDate!)}'
                      : 'Follow-up: ${DateFormat('dd MMM yyyy').format(log.followUpDate!)}',
                  style: TextStyle(
                    color: leadStatusStr == 'visiting' ? AppColors.success : const Color(0xFFFFB84D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('dd MMM').format(dateTime);
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            color: AppColors.textSecondary.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Call History',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call logs will appear here',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance(CallHistoryController controller) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPerformanceStat(
                      value: controller.weeklyTotalCalls.value.toString(),
                      label: 'TOTAL CALLS',
                    ),
                    const SizedBox(width: 32),
                    _buildPerformanceStat(
                      value: '${controller.weeklySuccessRate.value}%',
                      label: 'SUCCESS RATE',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildPerformanceStat({
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
