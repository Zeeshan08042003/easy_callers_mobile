import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/controllers/lead_detail_controller.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart';
import '../controllers/call_controller.dart';

class LeadDetailView extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailView({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    // Use unique tag per lead so each lead gets a fresh controller
    final controller = Get.put(LeadDetailController(lead: lead), tag: lead.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'LEAD DETAILS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Edit lead details
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildLeadHeader(controller),
            const SizedBox(height: 24),
            _buildActionButtons(controller),
            const SizedBox(height: 32),
            _buildCallButton(controller),
            _buildLeadInfo(controller),
            _buildCallDynamicStatus(controller),
            _buildUpdateCallStatus(controller),

            _buildActionDateTimePicker(controller),
            _buildCallSummary(controller),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(controller),
    );
  }

  Widget _buildLeadHeader(LeadDetailController controller) {
    // Get initials from name
    final nameParts = lead.name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : lead.name.substring(0, 2).toUpperCase();

    // Build subtitle with project name and manager name
    final project = lead.projectTitle ?? lead.projectName;
    final manager = lead.uploadedByName;
    String subtitle = '';
    if (project != null && project.isNotEmpty) {
      subtitle = project;
    }
    if (manager != null && manager.isNotEmpty) {
      subtitle += subtitle.isNotEmpty ? ' • $manager' : manager;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          lead.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Phone number
        if (lead.phone.isNotEmpty)
          Text(
            lead.phone.first,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        Text(
          "Lead managed by : ",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LeadDetailController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.message_rounded,
            label: 'MESSAGE',
            onTap: () => _handleActionWithMultiplePhones(
              controller,
              'Send SMS To',
              (phone) => controller.sendMobileSMS(phoneNumber: phone),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (lead.email != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.email_rounded,
              label: 'EMAIL',
              onTap: () async {
                if (lead.email != null) {
                  final uri = Uri.parse('mailto:${lead.email}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                } else {
                  Get.snackbar('No Email', 'This lead has no email address');
                }
              },
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone_android_rounded,
            label: 'WHATSAPP',
            onTap: () => _handleActionWithMultiplePhones(
              controller,
              'WhatsApp To',
              (phone) => controller.whatsappMsg(phoneNumber: phone),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(LeadDetailController controller) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _handleActionWithMultiplePhones(
          controller,
          'Call Number',
          (phone) => controller.makeCall(phoneNumber: phone),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Obx(() => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_rounded, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Call Client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (controller.callDurationSeconds.value > 0)
                  Text(
                    'Last duration: ${Duration(seconds: controller.callDurationSeconds.value).toString().split('.').first.padLeft(8, "0")}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.normal),
                  ),
              ],
            )),
      ),
    );
  }

  void _handleActionWithMultiplePhones(
    LeadDetailController controller, 
    String title, 
    Function(String) onSelected
  ) {
    if (lead.phone.isEmpty) return;
    
    final allPhones = lead.phone.where((p) => p.isNotEmpty).toList();
    if (allPhones.length <= 1) {
      if (allPhones.isNotEmpty) onSelected(allPhones.first);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2030),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...allPhones.map((phone) {
              final isPrimary = phone == lead.phone.first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Get.back();
                    onSelected(phone);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          title.contains('SMS') 
                            ? Icons.message_rounded 
                            : title.contains('WhatsApp') 
                              ? Icons.phone_android_rounded 
                              : Icons.phone_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  //will show proper call log report over here
  Widget _buildLeadInfo(LeadDetailController controller) {
    return Obx(() {
      if (controller.isLoadingLastCall.value) {
        return Container(
          margin: EdgeInsets.only(top: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        );
      }

      final lastCall = controller.lastCallLog.value;
      if (lastCall == null) {
        // No previous call — hide the section
        return const SizedBox.shrink();
      }

      // Calculate relative time
      final diff = DateTime.now().difference(lastCall.createdAt);
      String lastContactedStr;
      if (diff.inMinutes < 1) {
        lastContactedStr = 'Just now';
      } else if (diff.inMinutes < 60) {
        lastContactedStr = '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        lastContactedStr = '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inDays < 7) {
        lastContactedStr = '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else {
        lastContactedStr = DateFormat('dd MMM yyyy').format(lastCall.createdAt);
      }

      // Call status
      final callStatusValue = (lastCall.callStatus ?? 'Unknown').toLowerCase();
      String callStatusLabel;
      Color callStatusColor;
      if (callStatusValue.contains('completed') || callStatusValue.contains('connected')) {
        callStatusLabel = 'Connected';
        callStatusColor = AppColors.success;
      } else if (callStatusValue.contains('declined') || callStatusValue.contains('failed')) {
        callStatusLabel = 'Declined / Failed';
        callStatusColor = const Color(0xFFFF6B6B);
      } else if (callStatusValue.contains('busy')) {
        callStatusLabel = 'Busy';
        callStatusColor = const Color(0xFFFFB84D);
      } else {
        callStatusLabel = lastCall.callStatus ?? 'Unknown';
        callStatusColor = AppColors.textSecondary;
      }

      // Lead status
      final leadStatusStr = lastCall.leadStatus?.toString() ?? '';
      String? leadStatusLabel;
      Color? leadStatusColor;
      if (leadStatusStr == 'visiting') {
        leadStatusLabel = 'Visiting';
        leadStatusColor = AppColors.success;
      } else if (leadStatusStr == 'interested') {
        leadStatusLabel = 'Interested';
        leadStatusColor = AppColors.success;
      } else if (leadStatusStr == 'not_interested') {
        leadStatusLabel = 'Not Interested';
        leadStatusColor = const Color(0xFFFF6B6B);
      } else if (leadStatusStr == 'callback' || leadStatusStr == 'follow_up') {
        leadStatusLabel = leadStatusStr == 'callback' ? 'Callback' : 'Follow-up';
        leadStatusColor = const Color(0xFFFFB84D);
      } else if (leadStatusStr == 'closed') {
        leadStatusLabel = 'Closed';
        leadStatusColor = AppColors.textSecondary;
      } else if (leadStatusStr.isNotEmpty) {
        leadStatusLabel = leadStatusStr;
        leadStatusColor = AppColors.textSecondary;
      }

      // Duration
      final durationSecs = lastCall.callDurationSeconds;
      final durationStr = durationSecs > 0
          ? '${durationSecs ~/ 60}m ${durationSecs % 60}s'
          : '0s';

      return Container(
        margin: EdgeInsets.only(top: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Last Connected" with time
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'LAST CONNECTED',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  lastContactedStr,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            const SizedBox(height: 14),

            // Call Status Row
            Row(
              children: [
                _buildReportLabel('Call Status'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: callStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    callStatusLabel,
                    style: TextStyle(
                      color: callStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lead Status Row
            if (leadStatusLabel != null) ...[
              Row(
                children: [
                  _buildReportLabel('Lead Status'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: leadStatusColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      leadStatusLabel,
                      style: TextStyle(
                        color: leadStatusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Duration Row
            Row(
              children: [
                _buildReportLabel('Duration'),
                const Spacer(),
                Text(
                  durationStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date/Time Row
            Row(
              children: [
                _buildReportLabel('Date & Time'),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(lastCall.createdAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Notes
            if (lastCall.feedback != null && lastCall.feedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Follow-up / Visiting date
            if (lastCall.followUpDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    leadStatusStr == 'visiting' ? Icons.location_on_rounded : Icons.event_rounded,
                    size: 14,
                    color: leadStatusStr == 'visiting' ? AppColors.success : const Color(0xFFFFB84D),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      leadStatusStr == 'visiting'
                          ? 'Visit: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastCall.followUpDate!)}'
                          : 'Follow-up: ${DateFormat('dd MMM yyyy').format(lastCall.followUpDate!)}',
                      style: TextStyle(
                        color: leadStatusStr == 'visiting' ? AppColors.success : const Color(0xFFFFB84D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildReportLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildUpdateCallStatus(LeadDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        const Text(
          'UPDATE CALL STATUS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.5/1,
              ),
              itemCount: controller.availableLeadStatuses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
            final status = controller.availableLeadStatuses[index];

            Color chipColor = AppColors.primary;

            if (status.value == 'interested') chipColor = AppColors.success;
            if (status.value == 'not_interested') chipColor = const Color(0xFFFF6B6B);
            if (status.value == 'follow_up') chipColor = AppColors.warning;
            if (status.value == 'closed') chipColor = AppColors.danger;
            if (status.value == 'visiting') chipColor = AppColors.success;

            // Each chip gets its own Obx to react to selectedStatus changes immediately
            return Obx(() {
              final isSelected = controller.selectedStatus.value == status.value;
              return _buildStatusChip(
                label: status.displayName,
                isSelected: isSelected,
                onTap: () {
                  controller.selectedStatus.value = status.value;
                },
                color: chipColor,
              );
            });
          },
            ))
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionDateTimePicker(LeadDetailController controller) {
    return Obx(() {
      final statusValue = controller.selectedStatus.value;
      final bool requiresDateTime = statusValue == 'visiting' || 
          statusValue == 'follow_up';

      if (!requiresDateTime) {
        return const SizedBox.shrink();
      }

      final isVisiting = statusValue == 'visiting';
      final color = isVisiting ? AppColors.success : AppColors.warning;
      final label = isVisiting ? 'Visiting Date & Time' : 'Follow-up Date & Time';
      final icon = isVisiting ? Icons.calendar_month_rounded : Icons.event_repeat_rounded;

      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Date picker
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDateTimeAction(controller, isDate: true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.visitingDate.value != null
                              ? color.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 18,
                            color: controller.visitingDate.value != null
                                ? color
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            controller.visitingDate.value != null
                                ? DateFormat('dd/MM/yyyy').format(controller.visitingDate.value!)
                                : 'Select Date',
                            style: TextStyle(
                              color: controller.visitingDate.value != null
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Time picker
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDateTimeAction(controller, isDate: false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.visitingTime.value != null
                              ? color.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: controller.visitingTime.value != null
                                ? color
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            controller.visitingTime.value != null
                                ? controller.visitingTime.value!.format(Get.context!)
                                : 'Select Time',
                            style: TextStyle(
                              color: controller.visitingTime.value != null
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _pickDateTimeAction(LeadDetailController controller, {required bool isDate}) async {
    if (isDate) {
      final date = await showDatePicker(
        context: Get.context!,
        initialDate: controller.visitingDate.value ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date != null) {
        controller.visitingDate.value = date;
      }
    } else {
      final time = await showTimePicker(
        context: Get.context!,
        initialTime: controller.visitingTime.value ?? const TimeOfDay(hour: 10, minute: 0),
      );
      if (time != null) {
        controller.visitingTime.value = time;
      }
    }
  }

  Widget _buildCallSummary(LeadDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'CALL SUMMARY & NOTES',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller.notesController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter details about the conversation...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSaveButton(LeadDetailController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Obx(() => ElevatedButton(
                onPressed:
                    controller.isLoading.value ? null : controller.saveUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.cardBg,
                  disabledForegroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: AppColors.background)
                    : const Text(
                        'Save Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              )),
        ),
      ),
    );
  }

  Widget _buildCallDynamicStatus(LeadDetailController controller) {
    return Obx(() {
      final session = controller.callController.callSession.value;

      if (session == null) {
        return _buildEmptyCallState();
      }

      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: session.statusBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: session.statusColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              session.isConnected
                  ? Icons.call_made
                  : Icons.call_missed,
              color: session.statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.status,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: session.statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Duration: ${session.duration}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyCallState() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: const [
          Icon(Icons.call, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "No call activity yet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }



}
