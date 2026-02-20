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
    final controller = Get.put(LeadDetailController(lead: lead));

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
            const SizedBox(height: 32),
            _buildLeadInfo(controller),
            const SizedBox(height: 32),
            _buildCallDynamicStatus(controller),
            const SizedBox(height: 32),
            _buildUpdateCallStatus(controller),
            const SizedBox(height: 32),
            _buildCallSummary(controller),
            const SizedBox(height: 32),
            _buildFollowUpReminder(controller),
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
        ),
        const SizedBox(height: 8),
        Text(
          lead.projectName ?? 'Senior Director • TechSolutions Inc.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
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
            onTap: () => controller.sendMobileSMS(),
          ),
        ),
        const SizedBox(width: 12),
        Visibility(
          visible: lead.email != null,
          child: Expanded(
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone_android_rounded,
            label: 'WHATSAPP',
            onTap: () => controller.whatsappMsg(),
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
        onPressed: () => controller.makeCall(),
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

  //will show proper call log report over here
  Widget _buildLeadInfo(LeadDetailController controller) {
    return Visibility(
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              label: 'LAST CONTACTED',
              value: '2 days ago',
              icon: Icons.access_time_rounded,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(icon, color: AppColors.textSecondary, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCallStatus(LeadDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                
                // Keep some default colors
                if (status.value == 'interested') chipColor = AppColors.success;
                if (status.value == 'not_interested') chipColor = const Color(0xFFFF6B6B);
                if (status.value == 'follow_up') chipColor = AppColors.warning;
                if (status.value == 'closed') chipColor = AppColors.danger;
                if (status.value == 'visiting') chipColor = AppColors.success;

                return _buildStatusChip(
                  label: status.displayName,
                  isSelected: controller.selectedStatus.value == status.value,
                  onTap: () => controller.selectedStatus.value = status.value,
                  color: chipColor,
                );
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

  Widget _buildCallSummary(LeadDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Widget _buildFollowUpReminder(LeadDetailController controller) {
    return Obx(() {
      final statusValue = controller.selectedStatus.value;
      
      // Find the status model to see the mapping
      final statusModel = controller.availableLeadStatuses.firstWhereOrNull(
        (s) => s.value == statusValue
      );
      
      bool needsFollowUp = statusValue == 'callback' ||
          statusValue == 'interested' ||
          statusValue == 'follow_up';
          
      if (statusModel != null) {
        needsFollowUp = statusModel.leadStatusMapping == 'follow_up' || 
                       statusModel.value == 'callback' || 
                       statusModel.value == 'interested';
      }

      if (!needsFollowUp) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Set follow-up reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Obx(() => Switch(
                  value: controller.followUpEnabled.value,
                  onChanged: (value) {
                    controller.followUpEnabled.value = value;
                    if (value) {
                      _showFollowUpDatePicker(controller);
                    }
                  },
                  activeColor: AppColors.primary,
                )),
          ],
        ),
      );
    });
  }

  void _showFollowUpDatePicker(LeadDetailController controller) async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      controller.followUpDate.value = date;
    } else {
      controller.followUpEnabled.value = false;
    }
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
        margin: const EdgeInsets.symmetric(vertical: 10),
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
      margin: const EdgeInsets.symmetric(vertical: 10),
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
