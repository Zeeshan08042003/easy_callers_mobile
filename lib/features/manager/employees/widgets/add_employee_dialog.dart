import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/manager_team_controller.dart';

class AddEmployeeDialog extends StatelessWidget {
  const AddEmployeeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerTeamController>();

    return Dialog(
      backgroundColor: AppColors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildFieldLabel('FIRST NAME'),
              _buildTextField('e.g. John', controller.firstNameController),
              const SizedBox(height: 16),
              _buildFieldLabel('LAST NAME'),
              _buildTextField('e.g. Doe', controller.lastNameController),
              const SizedBox(height: 16),
              _buildFieldLabel('EMAIL ADDRESS'),
              _buildTextField('john.doe@company.com', controller.emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildFieldLabel('PHONE (OPTIONAL)'),
              _buildTextField('+1 234 567 890', controller.phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 30),
              const SizedBox(height: 30),
              // Share via WhatsApp button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareEmployeeViaWhatsApp(controller),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Access Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isCreating.value ? null : () => controller.createEmployee(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isCreating.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }


  void _shareEmployeeViaWhatsApp(ManagerTeamController controller) async {
    final email = controller.emailController.text.trim();
    final name = '${controller.firstNameController.text.trim()} ${controller.lastNameController.text.trim()}'.trim();
    final message = Uri.encodeComponent(
      'Hello${name.isNotEmpty ? ' $name' : ''},\n\n'
      'Your Easy Callers employee account has been created.\n\n'
      '📧 Email: $email\n\n'
      'Check your email for an activation code. Use that code in the app to set your password.\n\n'
      'Thank you!',
    );

    final url = Uri.parse('https://wa.me/?text=$message');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open WhatsApp');
    }
  }
}
