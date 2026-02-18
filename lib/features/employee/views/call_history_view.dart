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

                if (controller.filteredCallLogs.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildCallLogsList(controller);
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
      child: Obx(() => Row(
        children: [
          _buildFilterTab(
            label: 'All Calls',
            isSelected: controller.selectedFilter.value == 'all',
            onTap: () => controller.selectedFilter.value = 'all',
          ),
          const SizedBox(width: 12),
          _buildFilterTab(
            label: 'Missed',
            isSelected: controller.selectedFilter.value == 'missed',
            onTap: () => controller.selectedFilter.value = 'missed',
          ),
          const SizedBox(width: 12),
          _buildFilterTab(
            label: 'Follow-up',
            isSelected: controller.selectedFilter.value == 'followup',
            onTap: () => controller.selectedFilter.value = 'followup',
          ),
        ],
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

  Widget _buildCallLogsList(CallHistoryController controller) {
    return Obx(() {
      final groupedLogs = controller.groupedCallLogs;
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: groupedLogs.length,
        itemBuilder: (context, index) {
          final dateKey = groupedLogs.keys.elementAt(index);
          final logs = groupedLogs[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  dateKey,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...logs.map((log) => _buildCallLogCard(log)).toList(),
            ],
          );
        },
      );
    });
  }

  Widget _buildCallLogCard(CallLogModel log) {
    // Determine icon and color based on call status
    IconData icon;
    Color iconColor;
    Color bgColor;
    String statusText;

    final callStatusValue = log.callStatus?.value ?? 'unknown';
    switch (callStatusValue) {
      case 'connected':
        icon = Icons.person_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.1);
        statusText = 'Completed';
        break;
      case 'no_answer':
        icon = Icons.person_outline_rounded;
        iconColor = const Color(0xFFFF6B6B);
        bgColor = const Color(0xFFFF6B6B).withOpacity(0.1);
        statusText = 'No Answer';
        break;
      case 'busy':
        icon = Icons.phone_missed_rounded;
        iconColor = const Color(0xFFFFB84D);
        bgColor = const Color(0xFFFFB84D).withOpacity(0.1);
        statusText = 'Busy';
        break;
      default:
        icon = Icons.phone_callback_rounded;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.cardBg;
        statusText = 'Follow-up';
    }

    // Check if it's a follow-up
    final isFollowUp = log.followUpDate != null;
    if (isFollowUp) {
      icon = Icons.access_time_rounded;
      iconColor = const Color(0xFFFFB84D);
      bgColor = const Color(0xFFFFB84D).withOpacity(0.1);
      statusText = 'Follow-up';
    }

    // Format time
    final timeStr = DateFormat('HH:mm').format(log.createdAt);
    
    // Calculate duration
    final duration = _formatDuration(log.callDurationSeconds ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.leadName ?? 'Unknown Lead',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: _getStatusColor(log),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  duration,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.phone_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    onPressed: () {
                      // Call again
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CallLogModel log) {
    if (log.leadStatus != null) {
      switch (log.leadStatus!.value) {
        case 'interested':
          return AppColors.success;
        case 'not_interested':
          return const Color(0xFFFF6B6B);
        case 'callback':
        case 'follow_up':
          return const Color(0xFFFFB84D);
        default:
          return AppColors.textSecondary;
      }
    }
    return AppColors.textSecondary;
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
