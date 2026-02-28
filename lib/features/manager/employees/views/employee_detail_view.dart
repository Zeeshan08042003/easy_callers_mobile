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
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _showEditDialog(context),
            tooltip: 'Edit Employee',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.employee.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.employee.value == null) {
          return const Center(
            child: Text('Employee not found', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 24),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildStatsGrid(context),
                const SizedBox(height: 24),
                _buildLastCallActivity(),
                const SizedBox(height: 24),
                _buildRecentLeadDistribution(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // ============================================
  // PROFILE HEADER
  // ============================================

  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      final emp = controller.employee.value;
      if (emp == null) return const SizedBox.shrink();

      final bool isOTPExpired = !emp.isActive && emp.isOTPExpired;

      return Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width < 360 ? 32 : 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    emp.initials,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: emp.isActive
                        ? AppColors.success
                        : (isOTPExpired ? AppColors.danger : AppColors.warning),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (emp.isActive)
                  Text(
                    'Active Lead Representative',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isOTPExpired)
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'OTP Expired',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => controller.resendOTP(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 12, color: AppColors.danger),
                              SizedBox(width: 4),
                              Text('Resend',
                                style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
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
                      color: AppColors.warning.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                _buildProfileBadge(
                  emp.isActive ? 'ACTIVE' : 'INACTIVE',
                  emp.isActive ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ============================================
  // EMPLOYEE INFO CARD
  // ============================================

  Widget _buildInfoCard() {
    return Obx(() {
      final emp = controller.employee.value;
      if (emp == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            _buildInfoRow(Icons.email_rounded, 'Email', emp.email),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
            _buildInfoRow(
              Icons.phone_rounded,
              'Phone',
              emp.phone ?? 'Not set',
            ),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'Joined',
              DateFormat('dd MMM yyyy').format(emp.createdAt),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
            _buildInfoRow(
              Icons.verified_user_rounded,
              'Status',
              emp.isActive ? 'Active' : 'Inactive',
              valueColor: emp.isActive ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================
  // STATS GRID (responsive)
  // ============================================

  Widget _buildStatsGrid(BuildContext context) {
    final stats = controller.stats;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 360 ? 1 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.6,
      children: [
        _buildStatCard(
          'TOTAL LEADS',
          stats['total_leads']?.toString() ?? '0',
          'All time',
          null,
        ),
        _buildStatCard(
          'CALLS MADE',
          stats['total_calls']?.toString() ?? '0',
          'All time',
          null,
        ),
        _buildStatCard(
          'INTERESTED',
          stats['interested_leads']?.toString() ?? '0',
          'Converted',
          AppColors.success,
        ),
        _buildStatCard(
          'CALLBACK',
          stats['callback_leads']?.toString() ?? '0',
          'Pending',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subValue, Color? trendColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (trendColor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subValue,
                      style: TextStyle(color: trendColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subValue,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: 9,
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

  // ============================================
  // LAST CALL ACTIVITY
  // ============================================

  Widget _buildLastCallActivity() {
    return Obx(() {
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: callStatusColor.withValues(alpha: 0.1),
                      child: Icon(
                        callStatusValue.contains('completed') || callStatusValue.contains('connected')
                            ? Icons.call_made_rounded
                            : Icons.call_missed_rounded,
                        color: callStatusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastCall.leadName ?? 'Unknown Lead',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lastCall.leadPhone ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildProfileBadge(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildCallMeta('Status', callStatusLabel, callStatusColor)),
                    Flexible(child: _buildCallMeta('Duration', durationStr, Colors.white)),
                    Flexible(child: _buildCallMeta('Time', timeStr, Colors.white)),
                    Flexible(child: _buildCallMeta('Date', dateStr, Colors.white)),
                  ],
                ),
                if (lastCall.feedback != null && lastCall.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_rounded, size: 14, color: AppColors.textSecondary),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ============================================
  // LEAD DISTRIBUTION
  // ============================================

  Widget _buildRecentLeadDistribution() {
    return Obx(() {
      final allLeads = controller.assignedLeads;
      final totalCount = controller.totalLeadsCount.value;
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
    });
  }

  Widget _buildDistributionItem(String name, String time, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BOTTOM ACTIONS
  // ============================================

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: AppColors.background,
        child: Obx(() {
          final hasUnattendedLeads = controller.unattendedLeadsCount.value > 0;
          final isActive = controller.employee.value?.isActive ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUnattendedLeads && isActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isReassigning.value
                        ? null
                        : () => _showReassignConfirmation(),
                    icon: controller.isReassigning.value
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.autorenew, size: 18),
                    label: Text(
                      controller.isReassigning.value
                          ? 'Reassigning...'
                          : 'Reassign Unattended (${controller.unattendedLeadsCount.value})',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDialog(Get.context!),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.resendOTP(),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Resend OTP', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ============================================
  // EDIT DIALOG
  // ============================================

  void _showEditDialog(BuildContext context) {
    controller.populateEditForm();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Employee',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(Icons.close, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // First Name
              _buildTextField(
                controller: controller.firstNameController,
                label: 'First Name',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 14),

              // Last Name
              _buildTextField(
                controller: controller.lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              // Phone
              _buildTextField(
                controller: controller.phoneController,
                label: 'Phone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Email
              _buildTextField(
                controller: controller.emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Active/Inactive toggle
              Obx(() {
                final isActive = controller.employee.value?.isActive ?? false;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isActive ? AppColors.success : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isActive ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isActive ? 'Employee can login and make calls' : 'Employee cannot access the app',
                              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Obx(() => Switch(
                        value: controller.employee.value?.isActive ?? false,
                        onChanged: controller.isUpdating.value
                            ? null
                            : (_) => controller.toggleActiveStatus(),
                        activeColor: AppColors.success,
                      )),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isUpdating.value
                      ? null
                      : () async {
                          final success = await controller.updateEmployee();
                          if (success) Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: controller.isUpdating.value
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  Widget _buildProfileBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Color _getStatusColor(String statusValue) {
    switch (statusValue) {
      case 'new': return Colors.blueAccent;
      case 'assigned': return Colors.amber;
      case 'connected': return Colors.tealAccent;
      case 'not_connected': return Colors.redAccent;
      case 'interested': return Colors.greenAccent;
      case 'not_interested': return Colors.grey;
      case 'follow_up': return Colors.orangeAccent;
      case 'converted': return AppColors.success;
      case 'closed': return Colors.blueGrey;
      default: return Colors.amber;
    }
  }

  void _showReassignConfirmation() {
    final count = controller.unattendedLeadsCount.value;
    final employeeName = controller.employee.value?.firstName ?? 'this employee';

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.autorenew, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Reassign Leads',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'This will reassign $count unattended lead${count != 1 ? 's' : ''} to $employeeName.\n\nUnattended leads are those assigned for more than 24 hours with no call activity.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
