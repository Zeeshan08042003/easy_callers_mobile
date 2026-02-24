import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/reports/controllers/system_reports_controller.dart';

class SystemReportsView extends GetView<SystemReportsController> {
  const SystemReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SystemReportsController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'System-Wide Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectSelector(),
              const SizedBox(height: 30),
              _buildSectionTitle('GLOBAL KPIs'),
              const SizedBox(height: 16),
              _buildGlobalStatsGrid(),
              const SizedBox(height: 40),
              _buildSectionTitle('AGENCY PERFORMANCE COMPARISON'),
              const SizedBox(height: 16),
              _buildAgencyComparisonChart(),
              const SizedBox(height: 40),
              _buildSectionTitle('BRANCH BREAKDOWN'),
              const SizedBox(height: 16),
              _buildAgencyList(),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedProject.value?.id,
          hint: const Text('All Projects', style: TextStyle(color: Colors.white, fontSize: 14)),
          dropdownColor: AppColors.cardBg,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Projects', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            ...controller.availableProjects.map((p) => DropdownMenuItem<String>(
              value: p.id,
              child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            )),
          ],
          onChanged: (val) {
            if (val == null) {
              controller.onProjectSelected(null);
            } else {
              final project = controller.availableProjects.firstWhere((p) => p.id == val);
              controller.onProjectSelected(project);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildGlobalStatsGrid() {
    final s = controller.globalStats;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Total System Leads', s['lead_count']?.toString() ?? '0', Icons.auto_graph_rounded),
        _buildStatCard('Total System Calls', s['call_count']?.toString() ?? '0', Icons.call_made_rounded),
        _buildStatCard('Registered Agencies', s['manager_count']?.toString() ?? '0', Icons.apartment_rounded),
        _buildStatCard('Field Employees', s['employee_count']?.toString() ?? '0', Icons.groups_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyComparisonChart() {
    final data = controller.regionalPerformance;
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['lead_count'] as int).toDouble(),
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAgencyList() {
    final data = controller.regionalPerformance;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final agency = data[index];
        final bool isPrivate = agency['is_private'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agency['manager_name'] ?? 'Unknown Branch',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isPrivate 
                        ? 'Private Agency'
                        : '${agency['employee_count']} Agents • ${agency['lead_count']} Total Leads',
                      style: TextStyle(
                        color: isPrivate ? AppColors.danger : AppColors.textSecondary, 
                        fontSize: 12
                      ),
                    ),
                  ],
                ),
              ),
              if (isPrivate)
                const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 16)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(agency['conversion_rate'] as double).toStringAsFixed(1)}% CR',
                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
