import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/employee_detail_controller.dart';

class AllAssignedLeadsView extends StatelessWidget {
  const AllAssignedLeadsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeDetailController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          'Assigned Leads (${controller.totalLeadsCount.value})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
      ),
      body: Obx(() {
        final leads = controller.assignedLeads;

        if (controller.isLoading.value && leads.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No leads assigned yet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: leads.length + (controller.hasMoreLeads.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Load More button at the end
            if (index == leads.length) {
              return _buildLoadMoreButton(controller);
            }

            final lead = leads[index];
            final statusDisplay = lead.status.displayName.toUpperCase();
            final statusColor = _getStatusColor(lead.status.value);
            final timeAgo = _getRelativeTime(lead.createdAt);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    // Lead number badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Lead info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondary.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                lead.phone,
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time, size: 12, color: AppColors.textSecondary.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusDisplay,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildLoadMoreButton(EmployeeDetailController controller) {
    final remaining = controller.totalLeadsCount.value - controller.assignedLeads.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: SizedBox(
        width: double.infinity,
        child: Obx(() => OutlinedButton(
          onPressed: controller.isLoadingMore.value
              ? null
              : () => controller.loadMoreLeads(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: controller.isLoadingMore.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : Text(
                  remaining > 0
                      ? 'Load More ($remaining remaining)'
                      : 'Load More',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        )),
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Color _getStatusColor(String statusValue) {
    switch (statusValue) {
      case 'new':
        return Colors.blueAccent;
      case 'assigned':
        return Colors.amber;
      case 'connected':
        return Colors.tealAccent;
      case 'not_connected':
        return Colors.redAccent;
      case 'interested':
        return Colors.greenAccent;
      case 'not_interested':
        return Colors.grey;
      case 'follow_up':
        return Colors.orangeAccent;
      case 'converted':
        return AppColors.success;
      case 'closed':
        return Colors.blueGrey;
      default:
        return Colors.amber;
    }
  }
}
