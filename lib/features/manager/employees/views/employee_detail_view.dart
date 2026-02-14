import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/employee_detail_controller.dart';

class EmployeeDetailView extends GetView<EmployeeDetailController> {
  const EmployeeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Performance Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.employee.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 30),
              _buildCallVolumeChart(),
              const SizedBox(height: 30),
              _buildLastCallActivity(),
              const SizedBox(height: 30),
              _buildRecentLeadDistribution(),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildProfileHeader() {
    final emp = controller.employee.value!;
    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: const CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emp.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Senior Lead Representative',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildProfileBadge('TOP PERFORMER', AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '• Team Alpha',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = controller.stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('AVG. CALL DURATION', '4m 12s', '+8%', AppColors.success),
        _buildStatCard('CONVERSION RATE', '18.4%', '+2%', AppColors.primary),
        _buildStatCard('LEADS HANDLED', stats['total_leads']?.toString() ?? '0', 'This Month', null),
        _buildStatCard('TOTAL SALES', '\$12.4k', '+12%', AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subValue, Color? trendColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (trendColor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, color: trendColor, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          subValue,
                          style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    subValue,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallVolumeChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Call Volume',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last 6 Months',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'].map((m) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(m, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastCallActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Call Activity',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Jenkins',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Corporate Account Lead',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildProfileBadge('Interested', AppColors.success),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCallMeta('Duration', '12m 45s'),
                  _buildCallMeta('Time', '2:45 PM'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recording', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const Row(
                        children: [
                          Icon(Icons.play_arrow, color: AppColors.primary, size: 14),
                          Text('Listen', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentLeadDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Lead Distribution',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.assignedLeads.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lead = controller.assignedLeads[index];
            return _buildDistributionItem(lead.name, 'Assigned 2h ago', 'IN PROGRESS', Colors.amber);
          },
        ),
      ],
    );
  }

  Widget _buildDistributionItem(String name, String time, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.assignment_ind_outlined, size: 18),
              label: const Text('Assign New Lead'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
