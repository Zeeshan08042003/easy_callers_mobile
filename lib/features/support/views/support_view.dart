import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/services/system_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final systemService = Get.find<SystemService>();
    final settings = systemService.settings.value;

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
          'Contact Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildSupportHeader(),
            const SizedBox(height: 60),
            _buildContactCard(
              title: 'Email Support',
              subtitle: settings?.supportEmail ?? 'support@easycallers.com',
              icon: Icons.email_rounded,
              onTap: () => _launchUrl('mailto:${settings?.supportEmail}'),
            ),
            const SizedBox(height: 20),
            _buildContactCard(
              title: 'Phone Support',
              subtitle: settings?.supportPhone ?? '+1 234 567 890',
              icon: Icons.phone_rounded,
              onTap: () => _launchUrl('tel:${settings?.supportPhone}'),
            ),
            const SizedBox(height: 60),
            Text(
              'Available 24/7 for ${settings?.companyName ?? "Easy Callers"} Partners',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 60),
        ),
        const SizedBox(height: 24),
        const Text(
          'How can we help you?',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Our team is here to assist with your agency growth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildContactCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
