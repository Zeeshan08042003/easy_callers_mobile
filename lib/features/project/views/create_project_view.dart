import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/project/controllers/create_project_controller.dart';
import 'package:easy_callers_mobile/features/project/views/caller_selection_view.dart';

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

            // Caller Assignment
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
              'Choose which callers are part of this project',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            controller.callerAssignment.value = 'all',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: controller.callerAssignment.value == 'all'
                                ? AppColors.primary
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  controller.callerAssignment.value == 'all'
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color:
                                    controller.callerAssignment.value == 'all'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'All Callers',
                                style: TextStyle(
                                  color: controller.callerAssignment.value ==
                                          'all'
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            controller.callerAssignment.value = 'selected',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color:
                                controller.callerAssignment.value == 'selected'
                                    ? AppColors.primary
                                    : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: controller.callerAssignment.value ==
                                      'selected'
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                color: controller.callerAssignment.value ==
                                        'selected'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Select Callers',
                                style: TextStyle(
                                  color: controller.callerAssignment.value ==
                                          'selected'
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
                )),

            // Employee preview (when "selected" mode) or info text (when "all")
            Obx(() {
              if (controller.callerAssignment.value == 'all') {
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
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All your callers will be included in this project',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // "selected" mode
              if (controller.isLoadingEmployees.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              }

              if (controller.allEmployees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_off_outlined,
                              color: Colors.white.withOpacity(0.1), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'No employees found',
                            style: TextStyle(
                                color:
                                    AppColors.textSecondary.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Show first 3 employees + "View All" button
              final previewList = controller.allEmployees.take(3).toList();
              final totalCount = controller.allEmployees.length;
              final selectedCount = controller.selectedEmployeeIds.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Selection counter
                  Row(
                    children: [
                      Text(
                        '$selectedCount of $totalCount selected',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (selectedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$selectedCount',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Preview cards (max 3)
                  ...previewList.map((emp) {
                    final isSelected =
                        controller.selectedEmployeeIds.contains(emp.id);
                    return GestureDetector(
                      onTap: () => controller.toggleEmployee(emp.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.4)
                                : Colors.white.withOpacity(0.03),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  emp.initials,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
                                      fontSize: 13,
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
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary
                                      .withOpacity(0.3),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // "View All" button
                  if (totalCount > 3) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Get.to(() => const CallerSelectionView()),
                        icon: const Icon(Icons.people_outline_rounded,
                            size: 18),
                        label: Text(
                          'View All $totalCount Callers',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.3)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),

            // Visibility toggle (only for managers)
            if (controller.isManager) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Obx(() => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.visibility_outlined,
                              color: AppColors.warning, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visible to Super Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Allow super admin to see this project',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: controller.visibleToSuperAdmin.value,
                          onChanged: (val) =>
                              controller.visibleToSuperAdmin.value = val,
                          activeColor: AppColors.success,
                        ),
                      ],
                    )),
              ),
            ],

            const SizedBox(height: 40),

            // Create button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:(){
                      controller.isLoading.value
                          ? null
                          : controller.createProject();
                    },
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
