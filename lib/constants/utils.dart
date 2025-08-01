import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomColors{
  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

class
Constants{
  static const EMAIL_REGEX =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  static const PASS_REGEX1 = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{7,}$';

  static const TextStyle constantStyle = TextStyle(
    fontSize: 12,
  );
}

class AssetUtils{
  static const String imageDir = "resources/images";

  static const String leads = "$imageDir/leads.svg";
  static const String phone = "$imageDir/phone.svg";
  static const String email = "$imageDir/email.svg";
  static const String singleLead = "$imageDir/single_lead.svg";
}

showSnackBar({required String message, int? seconds}) {
  if (message.isNotEmpty) {
    if (seconds != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds ?? 1),
        ),
      );
    }
  }
}


void showCustomToast(BuildContext context, {required String title, required String subtitle}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 80,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.black54),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto remove the toast after 2 seconds
  Future.delayed(Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}
