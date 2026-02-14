import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/auth/controllers/auth_controller.dart';

/// Login screen used by all roles (Super Admin, Manager, Employee)
class NewLoginScreen extends StatelessWidget {
  const NewLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Title
                const Text(
                  "Welcome\nBack",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 36,
                    color: Color(0xff2D201C),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Login to continue managing your leads",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 50),

                // Email field
                Obx(() => _buildTextField(
                      label: "Email",
                      error: controller.emailError.value,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => controller.email.value = val,
                    )),

                const SizedBox(height: 16),

                // Password field
                Obx(() => _buildTextField(
                      label: "Password",
                      error: controller.passwordError.value,
                      isPassword: true,
                      onChanged: (val) => controller.password.value = val,
                    )),

                const SizedBox(height: 12),

                // Employee OTP link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => controller.goToOTPScreen(),
                    child: const Text(
                      "First time employee? Verify OTP",
                      style: TextStyle(
                        color: Color(0xff2D201C),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Login button
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.login(),
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
                                "LOGIN",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String error,
    bool isPassword = false,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    final obscure = isPassword ? true.obs : false.obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff2D201C),
          ),
        ),
        const SizedBox(height: 6),
        Obx(() => TextField(
              onChanged: onChanged,
              obscureText: obscure.value,
              keyboardType: keyboardType,
              cursorColor: const Color(0xff2D201C),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: isPassword ? '••••••' : 'Enter your $label',
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
                  borderSide:
                      const BorderSide(color: Color(0xff2D201C), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red.shade300),
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => obscure.toggle(),
                      )
                    : null,
              ),
            )),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
