import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/managers/controllers/add_manager_controller.dart';

class AddManagerView extends GetView<AddManagerController> {
  const AddManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Register New Agency',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('BRANCH MANAGER PROFILE'),
            const SizedBox(height: 16),
            _buildTextField('First Name', controller.firstNameController, Icons.person_outline),
            _buildTextField('Last Name', controller.lastNameController, Icons.person_outline),
            _buildTextField('Phone Number (Optional)', controller.phoneController, Icons.phone_outlined, isPhone: true),
            
            const SizedBox(height: 32),
            _buildSectionHeader('LOGIN CREDENTIALS'),
            const SizedBox(height: 16),
            _buildTextField('Email Address', controller.emailController, Icons.email_outlined, isEmail: true),
            _buildTextField('Temporary Password', controller.passwordController, Icons.lock_outline, isPassword: true),
            
            const SizedBox(height: 48),
            _buildCreateButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildTextField(String label, TextEditingController textController, IconData icon, {bool isPassword = false, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: textController,
              obscureText: isPassword,
              keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(() => ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.createManager,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: controller.isLoading.value
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Register & Activate Branch',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      )),
    );
  }
}
