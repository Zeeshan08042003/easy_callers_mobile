import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/reports/controllers/manager_reports_controller.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/views/manager_dashboard_view.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:easy_callers_mobile/features/manager/employees/views/manager_team_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/manager_team_binding.dart';

import 'package:easy_callers_mobile/features/profile/views/profile_view.dart';
import 'package:easy_callers_mobile/features/profile/bindings/profile_binding.dart';

class ManagerReportsView extends GetView<ManagerReportsController> {
  const ManagerReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'ANALYTICS HUB',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Team Performance',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _showDateRangePicker(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPerformanceGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('CALL ACTIVITY (LAST 7 DAYS)'),
              const SizedBox(height: 16),
              _buildActivityChart(),
              const SizedBox(height: 32),
              _buildSectionTitle('LEAD DISTRIBUTION'),
              const SizedBox(height: 16),
              _buildLeadDistributionChart(),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    final stats = controller.teamPerformance;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total TEAM Calls', stats['total_calls']?.toString() ?? '0', Icons.phone_callback_rounded),
        _buildStatCard('Potential Leads', stats['total_interested']?.toString() ?? '0', Icons.star_rounded),
        _buildStatCard('Conv. Rate', "${(stats['avg_conversion'] as double?)?.toStringAsFixed(1) ?? '0'}%", Icons.trending_up_rounded),
        _buildStatCard('Active Agents', stats['active_agents']?.toString() ?? '0', Icons.people_alt_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 16),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final data = controller.activityStats;
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No data found", style: TextStyle(color: Colors.white54))));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.map((item) {
                final index = data.indexOf(item);
                return FlSpot(index.toDouble(), (item['calls'] as int).toDouble());
              }).toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDistributionChart() {
    final funnel = controller.leadFunnel;
    if (funnel.isEmpty) return const SizedBox.shrink();

    final statuses = funnel.keys.toList();
    final List<Color> colors = [
      AppColors.primary,
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: funnel.entries.toList().asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: entry.value.toDouble(),
                    title: '',
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: funnel.entries.toList().asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text("${entry.key.toUpperCase()} (${entry.value})", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
     final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.updateDateRange(picked);
    }
  }


}
