import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/project/controllers/create_project_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';

/// Full-screen view for selecting managers (agencies) for a project.
class ManagerSelectionView extends StatelessWidget {
  const ManagerSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateProjectController>();

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
          'Select Agencies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.selectedManagerIds.length ==
                        controller.allManagers.length
                    ? controller.deselectAllManagers
                    : controller.selectAllManagers,
                child: Text(
                  controller.selectedManagerIds.length ==
                          controller.allManagers.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          // Selection counter
          Obx(() => Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.primary.withOpacity(0.08),
                child: Text(
                  '${controller.selectedManagerIds.length} of ${controller.allManagers.length} agencies selected',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),

          // Manager list
          Expanded(
            child: Obx(() {
              if (controller.isLoadingManagers.value) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                );
              }

              if (controller.allManagers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center_outlined,
                          color: Colors.white.withOpacity(0.1), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No managers found',
                        style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.allManagers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final manager = controller.allManagers[index];
                  return _buildManagerCard(manager, controller);
                },
              );
            }),
          ),

          // Done button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.selectedManagerIds.isNotEmpty
                          ? () => Get.back()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done (${controller.selectedManagerIds.length} selected)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(
      ManagerModel manager, CreateProjectController controller) {
    return Obx(() {
      final isSelected = controller.selectedManagerIds.contains(manager.id);
      return GestureDetector(
        onTap: () => controller.toggleManager(manager.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    manager.initials,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.primary : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      manager.email,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.3),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
