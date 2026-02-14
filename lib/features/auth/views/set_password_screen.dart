import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/auth/controllers/auth_controller.dart';

/// Screen for employees to set their password after OTP verification.
/// This completes the activation process.
class SetPasswordScreen extends StatelessWidget {
  const SetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final obscurePassword = true.obs;
    final obscureConfirm = true.obs;

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff2D201C)),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                "Set Your\nPassword",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  color: Color(0xff2D201C),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Create a secure password for your account",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              // Password field
              const Text(
                "Password",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff2D201C),
                ),
              ),
              const SizedBox(height: 6),
              Obx(() => TextField(
                    onChanged: (val) => controller.password.value = val,
                    obscureText: obscurePassword.value,
                    cursorColor: const Color(0xff2D201C),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xff2D201C), width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => obscurePassword.toggle(),
                      ),
                      errorText: controller.passwordError.value.isNotEmpty
                          ? controller.passwordError.value
                          : null,
                    ),
                  )),

              const SizedBox(height: 16),

              // Confirm password field
              const Text(
                "Confirm Password",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff2D201C),
                ),
              ),
              const SizedBox(height: 6),
              Obx(() => TextField(
                    onChanged: (val) =>
                        controller.confirmPassword.value = val,
                    obscureText: obscureConfirm.value,
                    cursorColor: const Color(0xff2D201C),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xff2D201C), width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => obscureConfirm.toggle(),
                      ),
                      errorText:
                          controller.confirmPasswordError.value.isNotEmpty
                              ? controller.confirmPasswordError.value
                              : null,
                    ),
                  )),

              const SizedBox(height: 12),

              // Password requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password must:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _requirementRow("Be at least 6 characters long"),
                    _requirementRow("Match the confirmation"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Activate button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.setPasswordAndActivate(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2D201C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "ACTIVATE ACCOUNT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  )),

              const SizedBox(height: 20),

              // Error message
              Obx(() => controller.error.value.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        controller.error.value,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
