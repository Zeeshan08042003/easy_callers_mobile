import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/super_admin/settings/controllers/system_settings_controller.dart';

class SystemSettingsView extends GetView<SystemSettingsController> {
  const SystemSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'System Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('GENERAL INFORMATION'),
            _buildCard([
              _buildTextField('Company Name', controller.companyNameController),
              _buildTextField('Support Email', controller.supportEmailController),
              _buildTextField('Support Phone', controller.supportPhoneController),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('LIMITS & PERFORMANCE'),
            _buildCard([
              _buildTextField('Max Leads per Agent', controller.maxLeadsController, isNumber: true),
              _buildTextField('Daily Call Target', controller.callTargetController, isNumber: true),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('SYSTEM STATUS'),
            _buildCard([
              _buildMaintenanceSwitch(),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSwitch() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Mode',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Disable all non-admin access',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        Switch.adaptive(
          value: controller.maintenanceMode.value,
          onChanged: (val) => controller.maintenanceMode.value = val,
          activeColor: AppColors.primary,
        ),
      ],
    ));
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Update System Settings',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
        )),
      ),
    );
  }
}
