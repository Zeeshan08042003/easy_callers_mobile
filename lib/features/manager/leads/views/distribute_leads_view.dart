import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/distribute_leads_controller.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';

class DistributeLeadsView extends GetView<DistributeLeadsController> {
  const DistributeLeadsView({super.key});


  @override
  Widget build(BuildContext context) {
    Get.put(DistributeLeadsController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Distribute Leads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('History', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildBatchCard(),
                  const SizedBox(height: 30),
                  _buildDistributionMethodToggle(),
                  const SizedBox(height: 30),
                  _buildTeamAllocationHeader(),
                  const SizedBox(height: 15),
                  _buildEmployeeAllocationList(),
                  const SizedBox(height: 100), // Bottom padding for fixed buttons
                ],
              ),
            ),
          ),
          _buildBottomActionPanel(),
        ],
      ),
    );
  }

  Widget _buildBatchCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                controller.mesh.value != null ? 'CURRENT BATCH' : 'CURRENT PROJECT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
                controller.totalBatchLeads.value.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              )),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                controller.mesh.value != null ? Icons.description_outlined : Icons.folder_open_outlined, 
                color: AppColors.textSecondary, 
                size: 14
              ),
              const SizedBox(width: 4),
              Obx(() => Text(
                controller.projectName.value.isNotEmpty ? controller.projectName.value : 'No Name',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionMethodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribution Method',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 15),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildToggleButton('Split Equally', DistributionMethod.equal)),
              Expanded(child: _buildToggleButton('Custom Split', DistributionMethod.custom)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, DistributionMethod m) {
    return Obx(() {
      final isSelected = controller.method.value == m;
      return InkWell(
        onTap: () => controller.setMethod(m),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTeamAllocationHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Team Allocation',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Obx(() => Text(
          '${controller.employees.length} Active Caller${controller.employees.length != 1 ? 's' : ''}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        )),
      ],
    );
  }

  Widget _buildEmployeeAllocationList() {
    return Obx(() {
      if (controller.isDistributing.value && controller.employees.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      
      if (controller.employees.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Employees',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activate employees to distribute leads',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.employees.length,
        separatorBuilder: (context, index) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          final employee = controller.employees[index];
          return _buildAllocationCard(employee);
        },
      );
    });
  }

  Widget _buildAllocationCard(EmployeeModel employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Top Performer • 98% CR',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() => RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${controller.allocations[employee.id] ?? 0} ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'LDS',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Obx(() => SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: AppColors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: (controller.allocations[employee.id] ?? 0).toDouble(),
              min: 0,
              max: controller.totalBatchLeads.value.toDouble(),
              onChanged: controller.method.value == DistributionMethod.custom
                ? (val) => controller.updateCustomAllocation(employee.id, val.toInt())
                : null,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Allocation Progress',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Obx(() => Text(
                '${controller.currentlyAllocated} / ${controller.totalBatchLeads.value} leads',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              )),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Obx(() => LinearProgressIndicator(
              value: controller.totalBatchLeads.value > 0 
                ? controller.currentlyAllocated / controller.totalBatchLeads.value 
                : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            )),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isDistributing.value ? null : controller.executeDistribution,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isDistributing.value 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded),
                      SizedBox(width: 10),
                      Text('Execute Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
            )),
          ),
        ],
      ),
    );
  }
}
