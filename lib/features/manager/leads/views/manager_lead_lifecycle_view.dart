import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:intl/intl.dart';

class ManagerLeadLifecycleController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final String projectId;
  final String? managerId;
  final String status;
  final String title;

  final leads = <LeadModel>[].obs;
  final isLoading = false.obs;

  ManagerLeadLifecycleController({
    required this.projectId,
    this.managerId,
    required this.status,
    required this.title,
  });

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    try {
      isLoading.value = true;
      List<LeadModel> result;
      if (status == 'all') {
        result = await _leadService.getProjectLeads(projectId, managerId: managerId);
      } else {
        result = await _leadService.getProjectLeadsByStatus(
          projectId: projectId,
          status: status,
          managerId: managerId,
        );
      }
      leads.value = result;
    } catch (e) {
      print('Error fetching leads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    try {
      await _leadService.updateLeadStatus(leadId, newStatus);
      leads.removeWhere((l) => l.id == leadId);
      Get.snackbar('Success', 'Lead status updated to ${newStatus.displayName}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status');
    }
  }
}

class ManagerLeadLifecycleView extends StatelessWidget {
  final String projectId;
  final String? managerId;
  final String status;
  final String title;

  const ManagerLeadLifecycleView({
    super.key,
    required this.projectId,
    this.managerId,
    required this.status,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a unique tag for this specific status/project view
    final tag = '${projectId}_${status}_${managerId ?? "owner"}';
    final controller = Get.put(
      ManagerLeadLifecycleController(
        projectId: projectId,
        managerId: managerId,
        status: status,
        title: title,
      ),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.leads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.1), size: 64),
                const SizedBox(height: 16),
                Text(
                  'No leads found in this status',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.leads.length,
          itemBuilder: (context, index) {
            final lead = controller.leads[index];
            return _buildLeadCard(lead, controller);
          },
        );
      }),
    );
  }

  Widget _buildLeadCard(LeadModel lead, ManagerLeadLifecycleController controller) {
    // Manager can only Converted/Drop if lead is in visit_completed or already converted
    bool canManage = lead.status == LeadStatus.visitCompleted || lead.status == LeadStatus.converted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    lead.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lead.phone.isNotEmpty ? lead.phone.first : 'No Phone',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (canManage)
                _buildActionMenu(lead, controller)
            ],
          ),
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              lead.notes!,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Added ${DateFormat('dd MMM').format(lead.createdAt)}',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last Active ${DateFormat('dd MMM, hh:mm a').format(lead.updatedAt)}',
                      style: TextStyle(color: AppColors.primary.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              if (!canManage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lead.status.displayName.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(LeadModel lead, ManagerLeadLifecycleController controller) {
    return PopupMenuButton<LeadStatus>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      color: const Color(0xFF1E2432),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (status) => controller.updateLeadStatus(lead.id, status),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: LeadStatus.converted,
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text('Mark Converted', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: LeadStatus.drop,
          child: Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 12),
              Text('Mark as Drop', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
