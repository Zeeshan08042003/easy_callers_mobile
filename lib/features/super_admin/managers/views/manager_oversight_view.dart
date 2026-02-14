import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/models/manager_model.dart';

import 'package:easy_callers_mobile/features/manager/employees/views/employee_detail_view.dart';
import 'package:easy_callers_mobile/features/manager/employees/bindings/employee_detail_binding.dart';
import '../../../../app/routes/app_routes.dart';

class ManagerOversightView extends StatelessWidget {
  const ManagerOversightView({super.key});

  @override
  Widget build(BuildContext context) {
    final ManagerModel? manager = Get.arguments is ManagerModel ? Get.arguments : null;
    final String name = manager?.fullName ?? 'Marcus Sterling';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name),
              const SizedBox(height: 30),
              _buildPeriodToggle(),
              const SizedBox(height: 30),
              _buildConversionCard(),
              const SizedBox(height: 30),
              _buildLeadStatusChart(),
              const SizedBox(height: 30),
              _buildTeamMembersHeader(),
              const SizedBox(height: 15),
              _buildTeamMembersList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
            decoration: BoxDecoration(
              color: const Color(0xFF1E2432),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
        Column(
          children: [
            Text(
              'OVERSIGHT VIEW',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=manager'),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem('Week', true)),
          Expanded(child: _buildToggleItem('Month', false)),
          Expanded(child: _buildToggleItem('Quarter', false)),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected) {
    return Container(
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
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildConversionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.auto_graph_rounded, color: Colors.white.withOpacity(0.2), size: 60),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collective Visit Conversion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '24.8%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+3.2%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.3,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadStatusChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEAD STATUS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                _buildLegendItem('INTERESTED', Colors.white),
                const SizedBox(width: 15),
                _buildLegendItem('NOT INTERESTED', AppColors.textSecondary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161C28),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('MON', 0.6, 0.4),
              _buildBar('TUE', 0.8, 0.2),
              _buildBar('WED', 0.5, 0.5),
              _buildBar('THU', 0.9, 0.1),
              _buildBar('FRI', 0.7, 0.3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBar(String day, double interested, double notInterested) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 120 * notInterested,
                decoration: const BoxDecoration(
                  color: Color(0xFF64748B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 120 * interested,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTeamMembersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'TEAM MEMBERS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View All', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTeamMembersList() {
    final members = [
      {'name': 'Alex Rivera', 'visits': 18, 'conv': 32, 'status': 'Active'},
      {'name': 'Sarah Jenkins', 'visits': 14, 'conv': 21, 'status': 'Away'},
      {'name': 'David Chen', 'visits': 22, 'conv': 18, 'status': 'Active'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        return InkWell(
          onTap: () => Get.to(() => const EmployeeDetailView(), binding: EmployeeDetailBinding(), arguments: member),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161C28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://i.pravatar.cc/150?u=${member['name']}',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${member['visits']} Visits • ${member['conv']}% Conv.',
                        style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  member['status'] as String,
                  style: TextStyle(
                    color: member['status'] == 'Active' ? const Color(0xFF3B82F6) : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary.withOpacity(0.4), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: AppColors.background,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Managers'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}
