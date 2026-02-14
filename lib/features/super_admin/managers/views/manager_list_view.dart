import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/models/manager_model.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/manager_list_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/views/add_manager_view.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/bindings/manager_bindings.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

class ManagerListView extends GetView<ManagerListController> {
  const ManagerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Agency Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.managers.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (controller.filteredManagers.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: controller.fetchManagers,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.filteredManagers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildManagerCard(controller.filteredManagers[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddManagerView(), binding: AddManagerBinding()),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          onChanged: controller.searchManagers,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search agency or manager...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildManagerCard(ManagerModel manager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              image: manager.profileImageUrl != null
                  ? DecorationImage(image: NetworkImage(manager.profileImageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: manager.profileImageUrl == null
                ? const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  manager.email,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSmallBadge(
                      'ACTIVE', 
                      manager.isActive ? AppColors.success : AppColors.textSecondary
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Since ${manager.createdAt.year}',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 16),
            onPressed: () => Get.to(
              () => const ManagerDashboardView(), 
              binding: ManagerDashboardBinding(),
              arguments: manager.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center_outlined, color: Colors.white.withOpacity(0.1), size: 100),
          const SizedBox(height: 20),
          const Text(
            'No agencies found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          Text(
            'Try searching for something else or add a new manager',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
