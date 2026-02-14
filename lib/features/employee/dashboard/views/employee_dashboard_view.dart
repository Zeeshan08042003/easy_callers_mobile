import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/widgets/lead_card.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/controllers/employee_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

import '../../feedback/bindings/call_feedback_binding.dart';
import '../../feedback/views/call_feedback_view.dart';

class EmployeeDashboardView extends GetView<EmployeeDashboardController> {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildStatsGrid(),
              _buildSectionTitle('PRIORITY FOLLOW-UPS'),
              _buildFollowUpHorizontalList(),
              _buildSectionTitle('NEW ASSIGNMENTS'),
              _buildAssignmentsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Workspace',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Performance is up 12% today',
                  style: TextStyle(color: AppColors.success.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Get.to(() => const ProfileView(), binding: ProfileBinding()),
              child: const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.6,
          children: [
            _buildMiniStatCard('TOTAL CALLS', '32', Icons.phone_callback_rounded, AppColors.primary),
            _buildMiniStatCard('INTERESTED', '08', Icons.stars_rounded, AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpHorizontalList() {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.pendingFollowups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEmptySection('No follow-ups due today'),
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: controller.pendingFollowups.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final lead = controller.pendingFollowups[index];
              return _buildFollowUpCard(lead);
            },
          ),
        );
      }),
    );
  }

  Widget _buildFollowUpCard(dynamic lead) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DUE IN 2H',
                style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 14),
            ],
          ),
          const Spacer(),
          Text(
            lead.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            lead.projectName ?? 'No Project',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return Obx(() {
      if (controller.assignedLeads.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildEmptySection('All leads caught up!'),
          ),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final lead = controller.assignedLeads[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              child: LeadCard(
                lead: lead,
                onActionPressed: () => Get.to(() => const CallFeedbackView(), binding: CallFeedbackBinding(), arguments: lead),
              ),
            );
          },
          childCount: controller.assignedLeads.length,
        ),
      );
    });
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Theme(
      data: ThemeData(canvasColor: AppColors.background),
      child: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'LEADS'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: 'NOTIFS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'PROFILE'),
        ],
      ),
    );
  }
}
