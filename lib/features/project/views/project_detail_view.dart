import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_detail_controller.dart';
import 'package:easy_callers_mobile/features/project/models/project_member_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribution_details_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribution_details_binding.dart';

class ProjectDetailView extends StatelessWidget {
  const ProjectDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProjectDetailController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value && controller.project.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final project = controller.project.value;
        if (project == null) {
          return const Center(
            child: Text('Project not found',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: AppColors.background,
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Get.back(),
              ),
              actions: [
                if (controller.canDeleteProject)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => _confirmDeleteProject(context, controller),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  project.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.folder_outlined,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    if (project.subtitle != null &&
                        project.subtitle!.isNotEmpty) ...[
                      Text(
                        project.subtitle!,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Instruction
                    if (project.instruction != null &&
                        project.instruction!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: AppColors.warning, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Instructions',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              project.instruction!,
                              style: TextStyle(
                                color:
                                    AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Quick Stats
                    _buildStatsRow(controller),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context, controller),
                    const SizedBox(height: 28),

                    // Members Section
                    _buildSectionHeader(
                      'Members',
                      Icons.people_outline_rounded,
                      controller.canInviteManagers
                          ? () => _showInviteManagerSheet(context, controller)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildMembersList(controller),
                    const SizedBox(height: 28),

                    // Callers (Employees) Section
                    _buildCallersSection(context, controller),
                    const SizedBox(height: 28),

                    // Excel Sheets / Batches Section
                    _buildSectionHeader(
                      'Excel Sheets',
                      Icons.table_chart_outlined,
                      null,
                    ),
                    const SizedBox(height: 12),
                    _buildBatchesList(controller),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteProject(
      BuildContext context,
      ProjectDetailController controller,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text(
            'Delete Project',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this project? '
                'This action cannot be undone and will permanently delete all '
                'associated leads, call logs, and members.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ✅ SAFE CLOSE
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // ✅ CLOSE DIALOG FIRST
                await controller.deleteProject();   // THEN DELETE
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildStatsRow(ProjectDetailController controller) {
    return Obx(() => Row(
          children: [
            _buildStatCard(
              'Leads',
              '${controller.leadCount.value}',
              Icons.contacts_outlined,
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Sheets',
              '${controller.batchCount.value}',
              Icons.upload_file_rounded,
              AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Members',
              '${controller.members.length}',
              Icons.people_outline_rounded,
              AppColors.warning,
            ),
          ],
        ));
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProjectDetailController controller) {
    return Row(
      children: [
        if (controller.canUploadLeads)
          Expanded(
            child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isUploading.value
                      ? null
                      : controller.uploadLeadsToProject,
                  icon: controller.isUploading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded, size: 20),
                  label: Text(
                      controller.isUploading.value
                          ? 'Uploading...'
                          : 'Upload Excel',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                )),
          ),
        if (controller.canInviteManagers) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showInviteManagerSheet(context, controller),
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Invite Manager',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, VoidCallback? onAdd) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 22),
          ),
      ],
    );
  }

  Widget _buildMembersList(ProjectDetailController controller) {
    return Obx(() {
      final activeMembers = controller.members.where((m) => m.managerIsActive).toList();
      
      if (activeMembers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    color: Colors.white.withOpacity(0.1), size: 40),
                const SizedBox(height: 8),
                Text(
                  'No members yet',
                  style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: activeMembers.map((member) {
          return _buildMemberCard(member, controller);
        }).toList(),
      );
    });
  }

  Widget _buildMemberCard(ProjectMemberModel member, ProjectDetailController controller) {
    Color statusColor;
    switch (member.status) {
      case 'accepted':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'declined':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(member.managerName ?? '?'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
                  member.managerName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (member.managerEmail != null)
                  Text(
                    member.managerEmail!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (member.isOwner)
                Text(
                  'Owner',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (controller.canInviteManagers && !member.isOwner) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _confirmRemoveMember(member, controller),
              icon: Icon(Icons.close_rounded,
                  color: AppColors.danger.withOpacity(0.6), size: 18),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchesList(ProjectDetailController controller) {
    return Obx(() {
      if (controller.batches.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.table_chart_outlined,
                    color: Colors.white.withOpacity(0.1), size: 40),
                const SizedBox(height: 8),
                Text(
                  'No excel sheets uploaded yet',
                  style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your first excel sheet to get started',
                  style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: controller.batches.map((batch) {
          return _buildBatchCard(batch, controller);
        }).toList(),
      );
    });
  }

  Widget _buildBatchCard(LeadBatchModel batch, ProjectDetailController controller) {
    return GestureDetector(
      onTap: () {
        controller.handleBatchTap(batch);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${batch.totalLeads} leads',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      if (batch.uploadedByName != null) ...[
                        Text(
                          ' • ${batch.uploadedByName}',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _formatDate(batch.createdAt),
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
            if (controller.canDeleteProject || 
                (controller.isManager && batch.uploadedBy == controller.currentManagerId)) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDeleteBatch(batch, controller),
                icon: Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger.withOpacity(0.6), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBatch(LeadBatchModel batch, ProjectDetailController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Excel Sheet?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete "${batch.fileName}" and all associated leads. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteBatch(batch.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CALLERS SECTION
  // ============================================

  Widget _buildCallersSection(BuildContext context, ProjectDetailController controller) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Callers',
            Icons.phone_in_talk_rounded,
            controller.canManageCallers && controller.callerAssignment.value == 'selected'
                ? () => _showAddCallerSheet(context, controller)
                : null,
          ),
          const SizedBox(height: 12),

          // All / Selected toggle
          if (controller.canManageCallers) ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.toggleCallerAssignment('all'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.callerAssignment.value == 'all'
                            ? AppColors.primary
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.callerAssignment.value == 'all'
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: controller.callerAssignment.value == 'all'
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All Callers',
                            style: TextStyle(
                              color: controller.callerAssignment.value == 'all'
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.toggleCallerAssignment('selected'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.callerAssignment.value == 'selected'
                            ? AppColors.primary
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.callerAssignment.value == 'selected'
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            color: controller.callerAssignment.value == 'selected'
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select',
                            style: TextStyle(
                              color: controller.callerAssignment.value == 'selected'
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
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
            const SizedBox(height: 12),
          ],

          // Info text
          if (controller.callerAssignment.value == 'all')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All your callers are included in this project',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Callers list (when "selected" mode)
          if (controller.callerAssignment.value == 'selected') ...[
            if (controller.projectCallers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off_outlined,
                          color: Colors.white.withOpacity(0.1), size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No callers selected',
                        style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add callers to this project',
                        style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.4),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...controller.projectCallers.map((caller) {
                return _buildCallerCard(caller, controller);
              }),
          ],
        ],
      );
    });
  }

  Widget _buildCallerCard(dynamic caller, ProjectDetailController controller) {
    final employee = caller as dynamic;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                employee.initials,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                  employee.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  employee.email,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (controller.canManageCallers)
            IconButton(
              onPressed: () => controller.removeCaller(employee.id),
              icon: Icon(Icons.close_rounded,
                  color: AppColors.danger.withOpacity(0.6), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  void _showAddCallerSheet(BuildContext context, ProjectDetailController controller) {
    controller.loadAvailableCallers();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Caller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select an employee to add to this project',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Obx(() {
                      if (controller.availableCallers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded,
                                  color: Colors.white.withOpacity(0.1),
                                  size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No available callers to add',
                                style: TextStyle(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.6)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All your employees are already added',
                                style: TextStyle(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.4),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: controller.availableCallers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final emp = controller.availableCallers[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emp.initials,
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        emp.email,
                                        style: TextStyle(
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.addCaller(emp.id);
                                    Get.back();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Add',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteManagerSheet(BuildContext context, ProjectDetailController controller) {
    controller.loadAvailableManagers();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Invite Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a manager to invite to this project',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Obx(() {
                      if (controller.availableManagers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  color: Colors.white.withOpacity(0.1),
                                  size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No available managers to invite',
                                style: TextStyle(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.6)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: controller.availableManagers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildAvailableManagerCard(
                              controller.availableManagers[index], controller);
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableManagerCard(ManagerModel manager, ProjectDetailController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                manager.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
                  manager.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  manager.email,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.inviteManager(manager.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Invite',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(ProjectMemberModel member, ProjectDetailController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Member',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${member.managerName ?? 'this member'} from the project?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeMember(member.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
