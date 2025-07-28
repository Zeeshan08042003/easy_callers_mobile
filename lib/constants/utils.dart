import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomColors{
  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

class Constants{
  static const EMAIL_REGEX =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  static const PASS_REGEX1 = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{7,}$';
}

showSnackBar({required String message, int? seconds}) {
  if (message.isNotEmpty) {
    if (seconds != null)
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds ?? 1),
        ),
      );
    }
  }
}
