import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/profile/controllers/profile_controller.dart';
import 'package:easy_callers_mobile/features/auth/views/login_screen.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   _buildProfileCard(),
                   const SizedBox(height: 32),
                   _buildMenuSection(context),
                   const SizedBox(height: 40),
                   _buildLogoutButton(),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Settings & Profile',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.background),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            controller.userName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            controller.userRole,
            style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            controller.userEmail,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT SETTINGS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuItem(Icons.person_outline_rounded, 'Edit personal information', () {}),
        _buildMenuItem(Icons.notifications_none_rounded, 'Notification preferences', () {}),
        _buildMenuItem(Icons.security_rounded, 'Security & Privacy', () {}),
        const SizedBox(height: 32),
        const Text(
          'RESOURCES',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuItem(Icons.help_outline_rounded, 'Support Center', () {}),
        _buildMenuItem(Icons.info_outline_rounded, 'About Application', () {}),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: AppColors.cardBg.withOpacity(0.5),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.2)),
          ),
        ),
        child: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  void _showLogoutConfirmation() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm Logout',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to log out of your account? You will need to re-authenticate to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.logout();
                      Get.offAll(() => const NewLoginScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
