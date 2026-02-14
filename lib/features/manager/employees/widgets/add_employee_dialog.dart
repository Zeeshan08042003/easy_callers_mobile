import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/manager/employees/controllers/manager_team_controller.dart';

class AddEmployeeDialog extends StatelessWidget {
  const AddEmployeeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerTeamController>();
    if (controller.activeOTP.value.isEmpty) {
      controller.generateOTP();
    }

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
              Obx(() => controller.activeOTP.value.isNotEmpty 
                ? _buildOTPSection(controller)
                : const SizedBox.shrink()),
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

  Widget _buildOTPSection(ManagerTeamController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'ACTIVATION OTP',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final otp = controller.activeOTP.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final char = otp.length > index ? otp[index] : '';
                return _buildOTPBox(char);
              }),
            );
          }),
          const SizedBox(height: 20),
          Obx(() => Text(
                'This code expires in ${controller.formattedTimer}',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 11,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOTPBox(String char) {
    return Container(
      width: 40,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: char.isNotEmpty ? AppColors.primary : Colors.white.withOpacity(0.1),
          width: char.isNotEmpty ? 2 : 1,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
