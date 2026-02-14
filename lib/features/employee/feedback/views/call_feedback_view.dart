import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/employee/feedback/controllers/call_feedback_controller.dart';
import 'package:intl/intl.dart';

class CallFeedbackView extends GetView<CallFeedbackController> {
  const CallFeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Call Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadSummary(),
            const SizedBox(height: 32),
            _buildSectionTitle('CALL RESULT'),
            const SizedBox(height: 16),
            _buildCallStatusChips(),
            const SizedBox(height: 32),
            _buildSectionTitle('LEAD INTEREST LEVEL'),
            const SizedBox(height: 16),
            _buildLeadStatusChips(),
            const SizedBox(height: 32),
            _buildSectionTitle('ADDITIONAL NOTES'),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 32),
            _buildFollowUpPicker(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildSubmitButton(),
    );
  }

  Widget _buildLeadSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.lead.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  controller.lead.phone,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_enabled_rounded, color: AppColors.success),
            onPressed: () {}, // Trigger call again if needed
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCallStatusChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: CallStatus.values.map((status) => _buildStatusChip<CallStatus>(status)).toList(),
    );
  }

  Widget _buildLeadStatusChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: CallLeadStatus.values.map((status) => _buildStatusChip<CallLeadStatus>(status)).toList(),
    );
  }

  Widget _buildStatusChip<T>(T status) {
    final String label = status is CallStatus ? status.displayName : (status as CallLeadStatus).displayName;
    return Obx(() {
      final bool isSelected = (status is CallStatus) 
          ? controller.callStatus.value == status 
          : controller.leadStatus.value == status;
      
      return InkWell(
        onTap: () {
          if (status is CallStatus) {
            controller.callStatus.value = status;
          } else {
            controller.leadStatus.value = status as CallLeadStatus;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller.feedbackController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Discussed project timeline and budget concerns...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildFollowUpPicker() {
    return Obx(() {
      final status = controller.leadStatus.value;
      if (status != CallLeadStatus.followUp && status != CallLeadStatus.callback) {
        return const SizedBox.shrink();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionTitle('SCHEDULE FOLLOW-UP'),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: Get.context!,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) controller.setFollowUpDate(date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    controller.followUpDate.value == null 
                        ? 'Select Date' 
                        : DateFormat('EEEE, MMM d').format(controller.followUpDate.value!),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: controller.isLoading.value 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save & Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        )),
      ),
    );
  }
}
