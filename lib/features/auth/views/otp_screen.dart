import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/auth/controllers/auth_controller.dart';

/// OTP verification screen for first-time employee activation.
class OTPScreen extends StatelessWidget {
  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  color: Color(0xff2D201C),
                ),
              ),

              const SizedBox(height: 8),

              Obx(() => Text(
                    "Enter the 6-digit OTP sent to\n${controller.email.value}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  )),

              const SizedBox(height: 40),

              // OTP Input
              Obx(() => TextField(
                    onChanged: (val) => controller.otpCode.value = val,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 12,
                      color: Color(0xff2D201C),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: const Color(0xff2D201C),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        letterSpacing: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xff2D201C), width: 1.5),
                      ),
                      errorText: controller.otpError.value.isNotEmpty
                          ? controller.otpError.value
                          : null,
                    ),
                  )),

              const SizedBox(height: 30),

              // Verify button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.verifyOTP(),
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
                              "VERIFY OTP",
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
    );
  }
}
