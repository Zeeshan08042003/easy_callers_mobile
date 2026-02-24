import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/employee_detail_controller.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/all_assigned_leads_view.dart';
import 'package:intl/intl.dart';

class EmployeeDetailView extends GetView<EmployeeDetailController> {
  const EmployeeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Performance Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.employee.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 30),
              _buildCallVolumeChart(),
              const SizedBox(height: 30),
              _buildLastCallActivity(),
              const SizedBox(height: 30),
              _buildRecentLeadDistribution(),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildProfileHeader() {
    final emp = controller.employee.value!;
    final bool isOTPExpired = !emp.isActive && emp.isOTPExpired;

    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: const CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: emp.isActive
                      ? AppColors.success
                      : (isOTPExpired ? AppColors.danger : AppColors.warning),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emp.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              if (emp.isActive)
                Text(
                  'Active Lead Representative',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (isOTPExpired)
                Row(
                  children: [
                    const Text(
                      'OTP Expired ',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.resendOTP(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh,
                                size: 12, color: AppColors.danger),
                            SizedBox(width: 4),
                            Text(
                              'Resend',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Pending Activation',
                  style: TextStyle(
                    color: AppColors.warning.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildProfileBadge(
                      emp.isActive ? 'TOP PERFORMER' : 'NEW AGENT',
                      emp.isActive ? AppColors.primary : AppColors.warning),
                  const SizedBox(width: 12),
                  Text(
                    '• Team Alpha',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = controller.stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('AVG. CALL DURATION', '4m 12s', '+8%', AppColors.success),
        _buildStatCard('CONVERSION RATE', '18.4%', '+2%', AppColors.primary),
        _buildStatCard('LEADS HANDLED', stats['total_leads']?.toString() ?? '0', 'This Month', null),
        _buildStatCard('TOTAL SALES', '\$12.4k', '+12%', AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subValue, Color? trendColor) {
    return Container(
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
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (trendColor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, color: trendColor, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          subValue,
                          style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    subValue,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallVolumeChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Call Volume',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last 6 Months',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'].map((m) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(m, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastCallActivity() {
    return Obx(() {
      // Hide section if no recent calls
      if (controller.recentCalls.isEmpty) {
        return const SizedBox.shrink();
      }

      final lastCall = controller.recentCalls.first;

      // Lead status
      final leadStatusStr = lastCall.leadStatus?.toString() ?? '';
      String statusLabel = leadStatusStr.isNotEmpty
          ? leadStatusStr.replaceAll('_', ' ').capitalize!
          : 'Unknown';
      Color statusColor;
      if (leadStatusStr == 'interested' || leadStatusStr == 'visiting') {
        statusColor = AppColors.success;
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
        callStatusColor = AppColors.success;
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
            'Last Call Activity',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                          Text(
                            lastCall.leadPhone ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _buildProfileBadge(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCallMeta('Call Status', callStatusLabel, callStatusColor),
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
        ],
      );
    });
  }

  Widget _buildCallMeta(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Color _getStatusColor(String statusValue) {
    switch (statusValue) {
      case 'new':
        return Colors.blueAccent;
      case 'assigned':
        return Colors.amber;
      case 'connected':
        return Colors.tealAccent;
      case 'not_connected':
        return Colors.redAccent;
      case 'interested':
        return Colors.greenAccent;
      case 'not_interested':
        return Colors.grey;
      case 'follow_up':
        return Colors.orangeAccent;
      case 'converted':
        return AppColors.success;
      case 'closed':
        return Colors.blueGrey;
      default:
        return Colors.amber;
    }
  }

  Widget _buildRecentLeadDistribution() {
    final allLeads = controller.assignedLeads;
    final totalCount = controller.totalLeadsCount.value;
    // Show only first 5 leads on the detail page
    final previewLeads = allLeads.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Lead Distribution ($totalCount)',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (totalCount > 0)
              TextButton(
                onPressed: () => Get.to(() => const AllAssignedLeadsView()),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (previewLeads.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Center(
              child: Text(
                'No leads assigned yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewLeads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lead = previewLeads[index];
              final statusDisplay = lead.status.displayName.toUpperCase();
              final statusColor = _getStatusColor(lead.status.value);
              final timeAgo = 'Assigned ${_getRelativeTime(lead.createdAt)}';
              return _buildDistributionItem(lead.name, timeAgo, statusDisplay, statusColor);
            },
          ),
      ],
    );
  }

  Widget _buildDistributionItem(String name, String time, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.background,
      child: Obx(() {
        final hasUnattendedLeads = controller.unattendedLeadsCount.value > 0;
        final isActive = controller.employee.value?.isActive ?? false;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show unattended leads button if available and employee is active
            if (hasUnattendedLeads && isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: controller.isReassigning.value 
                      ? null 
                      : () => _showReassignConfirmation(),
                  icon: controller.isReassigning.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.autorenew, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.isReassigning.value
                            ? 'Reassigning...'
                            : 'Reassign Unattended Leads',
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.unattendedLeadsCount.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            // Original action buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Assign New Lead'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  void _showReassignConfirmation() {
    final count = controller.unattendedLeadsCount.value;
    final employeeName = controller.employee.value?.firstName ?? 'this employee';
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.autorenew, color: AppColors.warning),
            SizedBox(width: 12),
            Text(
              'Reassign Unattended Leads',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This will reassign $count unattended lead${count != 1 ? 's' : ''} to $employeeName.\n\nUnattended leads are those that have been assigned for more than 24 hours but have no call activity.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.reassignUnattendedLeads();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
  }
}
