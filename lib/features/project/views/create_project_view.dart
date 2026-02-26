import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/project/controllers/create_project_controller.dart';
import 'package:easy_callers_mobile/features/project/views/caller_selection_view.dart';
import 'package:easy_callers_mobile/features/project/views/manager_selection_view.dart';

class CreateProjectView extends StatelessWidget {
  const CreateProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateProjectController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Create Project',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.create_new_folder_outlined,
                    color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 30),

            // Project Name
            const Text(
              'Project Name *',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildInputField(
              controller: controller.nameController,
              hint: 'e.g. Real Estate Q1 2026',
              icon: Icons.folder_outlined,
              maxLines: 1,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Subtitle
            const Text(
              'Subtitle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A short tagline for this project',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildInputField(
              controller: controller.subtitleController,
              hint: 'e.g. Premium property leads for Q1',
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Instruction
            const Text(
              'Instruction',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Guidelines for the team working on this project',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildInputField(
              controller: controller.instructionController,
              hint: 'e.g. Focus on high-value leads first. Call between 10 AM - 6 PM only.',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Manager/Agency Assignment Section
            // const SizedBox(height: 24),
            // const Text(
            //   'Agency Assignment',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Text(
            //   'Choose which independent agencies or managers are part of this project',
            //   style: TextStyle(
            //     color: AppColors.textSecondary.withOpacity(0.5),
            //     fontSize: 12,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // _buildAgencyAssignmentSelector(controller),
            // _buildAgencyPreview(controller),

            // Caller Assignment Section (Only for Managers)
            if (controller.isManager) ...[
              const SizedBox(height: 24),
              const Text(
                'Caller Assignment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose which callers from your team are part of this project',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _buildCallerAssignmentSelector(controller),
              _buildCallerPreview(controller),
            ],

            const SizedBox(height: 32),

            // Create button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.createProject(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Project',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyAssignmentSelector(CreateProjectController controller) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            label: 'All Agencies',
            icon: Icons.apartment_rounded,
            isSelected: controller.managerAssignment.value == 'all',
            onTap: () => controller.managerAssignment.value = 'all',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            label: 'Select Agencies',
            icon: Icons.person_search_rounded,
            isSelected: controller.managerAssignment.value == 'selected',
            onTap: () => controller.managerAssignment.value = 'selected',
          ),
        ),
      ],
    ));
  }

  Widget _buildCallerAssignmentSelector(CreateProjectController controller) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            label: 'All Callers',
            icon: Icons.groups_rounded,
            isSelected: controller.callerAssignment.value == 'all',
            onTap: () => controller.callerAssignment.value = 'all',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            label: 'Select Callers',
            icon: Icons.person_search_rounded,
            isSelected: controller.callerAssignment.value == 'selected',
            onTap: () => controller.callerAssignment.value = 'selected',
          ),
        ),
      ],
    ));
  }

  Widget _buildRoleCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyPreview(CreateProjectController controller) {
    return Obx(() {
      if (controller.managerAssignment.value == 'all') {
        return _buildInfoBox('All available managers and agencies will be invited');
      }

      if (controller.isLoadingManagers.value) {
        return _buildLoading();
      }

      if (controller.allManagers.isEmpty) {
        return _buildEmptyState('No agencies found', Icons.business_center_outlined);
      }

      final previewList = controller.allManagers.take(3).toList();
      return _buildGeneralPreviewList(
        items: previewList,
        totalCount: controller.allManagers.length,
        selectedCount: controller.selectedManagerIds.length,
        onToggle: controller.toggleManager,
        isSelected: (id) => controller.selectedManagerIds.contains(id),
        onViewAll: () => Get.to(() => const ManagerSelectionView()),
        viewAllLabel: 'View All Agencies',
      );
    });
  }

  Widget _buildCallerPreview(CreateProjectController controller) {
    return Obx(() {
      if (controller.callerAssignment.value == 'all') {
        return _buildInfoBox('All your callers will be included in this project');
      }

      if (controller.isLoadingEmployees.value) {
        return _buildLoading();
      }

      if (controller.allEmployees.isEmpty) {
        return _buildEmptyState('No callers found', Icons.person_off_outlined);
      }

      final previewList = controller.allEmployees.take(3).toList();
      return _buildGeneralPreviewList(
        items: previewList,
        totalCount: controller.allEmployees.length,
        selectedCount: controller.selectedEmployeeIds.length,
        onToggle: controller.toggleEmployee,
        isSelected: (id) => controller.selectedEmployeeIds.contains(id),
        onViewAll: () => Get.to(() => const CallerSelectionView()),
        viewAllLabel: 'View All Callers',
      );
    });
  }

  Widget _buildInfoBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.only(top: 20),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.1), size: 36),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralPreviewList({
    required List<dynamic> items,
    required int totalCount,
    required int selectedCount,
    required Function(String) onToggle,
    required bool Function(String) isSelected,
    required VoidCallback onViewAll,
    required String viewAllLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '$selectedCount of $totalCount selected',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          final id = item.id;
          final selected = isSelected(id);
          return GestureDetector(
            onTap: () => onToggle(id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? AppColors.primary.withOpacity(0.4) : Colors.white.withOpacity(0.03)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        item.initials,
                        style: TextStyle(color: selected ? AppColors.primary : AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(item.email, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3), size: 22),
                ],
              ),
            ),
          );
        }),
        if (totalCount > 3) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              label: Text(viewAllLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.primary)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
