import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import '../controllers/manager_oversight_controller.dart';

import 'package:easy_callers_mobile/features/manager/employees/views/employee_detail_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/employee_detail_binding.dart';
import '../../../../app/routes/app_routes.dart';

class ManagerOversightView extends StatelessWidget {
  const ManagerOversightView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerOversightController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (controller.isPrivate) {
            return _buildPrivateState(controller);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller.manager.fullName),
                const SizedBox(height: 30),
                _buildPeriodToggle(controller),
                const SizedBox(height: 30),
                _buildConversionCard(controller),
                const SizedBox(height: 30),
                _buildLeadStatusChart(controller),
                const SizedBox(height: 30),
                _buildTeamMembersHeader(),
                const SizedBox(height: 15),
                _buildTeamMembersList(controller),
                const SizedBox(height: 100),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPrivateState(ManagerOversightController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildHeader(controller.manager.fullName),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 24),
                  const Text(
                    'Private Agency Report',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reports for independent agencies are not visible to Super Admins by default. Access must be granted by the agency manager.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2432),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
        Column(
          children: [
            Text(
              'AGENCY OVERSIGHT',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 44), // Spacer to balance the back button
      ],
    );
  }

  Widget _buildPeriodToggle(ManagerOversightController controller) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem(controller, 'Daily', 'daily')),
          Expanded(child: _buildToggleItem(controller, 'Weekly', 'weekly')),
          Expanded(child: _buildToggleItem(controller, 'Yearly', 'yearly')),
        ],
      ),
    );
  }

  Widget _buildToggleItem(ManagerOversightController controller, String label, String value) {
    final isSelected = controller.selectedPeriod.value == value;
    return GestureDetector(
      onTap: () => controller.switchPeriod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF242C3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversionCard(ManagerOversightController controller) {
    final rate = controller.conversionRate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.selectedPeriod.value.capitalizeFirst} Interest Rate',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.auto_graph_rounded, color: Colors.white.withOpacity(0.3), size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadStatusChart(ManagerOversightController controller) {
    final counts = controller.statusCounts;
    final total = counts.values.fold(0, (sum, v) => sum + v);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEAD STATUS DISTRIBUTION',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161C28),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: total == 0 
            ? const Center(child: Text('No lead data available', style: TextStyle(color: AppColors.textSecondary)))
            : Column(
                children: [
                  _buildStatusRow('Interested', counts['interested'] ?? 0, total, AppColors.success),
                  const SizedBox(height: 12),
                  _buildStatusRow('Follow up', counts['follow_up'] ?? 0, total, AppColors.warning),
                  const SizedBox(height: 12),
                  _buildStatusRow('New Lead', counts['new'] ?? 0, total, AppColors.primary),
                  const SizedBox(height: 12),
                  _buildStatusRow('Not Interested', counts['not_interested'] ?? 0, total, AppColors.danger),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color) {
    final percent = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMembersHeader() {
    return const Text(
      'TEAM PERFORMANCE',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTeamMembersList(ManagerOversightController controller) {
    final employees = controller.employees;

    if (employees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF161C28),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('No employees found', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employees.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161C28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: emp['profile_image_url'] != null 
                    ? NetworkImage(emp['profile_image_url']) 
                    : null,
                child: emp['profile_image_url'] == null 
                    ? const Icon(Icons.person, color: AppColors.primary) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emp['calls']} Calls • ${emp['conversion']}% Conv.',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: emp['status'] == 'Active' 
                      ? AppColors.success.withOpacity(0.1) 
                      : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emp['status'],
                  style: TextStyle(
                    color: emp['status'] == 'Active' ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
