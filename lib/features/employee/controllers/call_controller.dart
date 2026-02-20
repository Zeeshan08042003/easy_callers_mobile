import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/call_session_model.dart';


class CallController extends GetxController {
  final numberController = TextEditingController();

  /// Reactive state
  Rx<CallSession?> callSession = Rx<CallSession?>(null);
  RxBool isSubmittingData = false.obs;
  RxBool isLoading = false.obs;

  static const MethodChannel _platform =
  MethodChannel('com.easy_callers/call');

  // ------------------------------------------------------------
  // RESET SESSION
  // ------------------------------------------------------------

  void resetCallSession() {
    callSession.value = null;
  }

  // ------------------------------------------------------------
  // iOS CALL
  // ------------------------------------------------------------

  Future<CallSession?> makeCallForIos({
    required String phoneNumber,
  }) async {
    resetCallSession();
    try {
      await _platform.invokeMethod('startCall', phoneNumber);

      final completer = Completer<String?>();

      _platform.setMethodCallHandler((call) async {
        if (call.method == 'callEnded') {
          final String duration = call.arguments ?? '';
          completer.complete(duration);
        }
      });

      final duration = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => null,
      );


      if (duration != null) {
        callSession(
          CallSession.fromIos(
            number: phoneNumber,
            duration: duration,
            status: "completed",
          ),
        );

        return callSession.value;
      }
    } on PlatformException catch (e) {
      isLoading(false);
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Error', e.message ?? 'iOS call failed');
    }
    return null;
  }

  // ------------------------------------------------------------
  // ANDROID CALL
  // ------------------------------------------------------------

  Future<CallSession?> makeCall({
    required String phoneNumber,
  }) async {
    resetCallSession();

    try {
      final result = await _platform.invokeMethod(
        'startCall',
        {'number': phoneNumber},
      );

      if (result != null) {

        // 🔥 Native already returns Map
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(result);

        callSession.value = CallSession.fromJson(data);

        return callSession.value;
      }
    } on PlatformException catch (e) {
      isLoading(false);
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Error', e.message ?? 'Android call failed');
    }

    return null;
  }

  // ------------------------------------------------------------
  // WHATSAPP
  // ------------------------------------------------------------

  Future<void> sendWhatsAppMessage(
      List<String> numbers,
      String defaultMessage,
      ) async {
    try {
      await _platform.invokeMethod('sendBulkWhatsAppMessages', {
        'numbers': numbers,
        'message': defaultMessage,
      });
    } catch (e) {
      debugPrint("WhatsApp error: $e");
    }
  }

  // ------------------------------------------------------------
  // SMS
  // ------------------------------------------------------------

  Future<void> sendSMS(String number, String message) async {
    try {
      await _platform.invokeMethod('sendSMS', {
        'number': number,
        'message': message,
      });
    } on PlatformException catch (e) {
      debugPrint("SMS failed: ${e.message}");
    }
  }

  // ------------------------------------------------------------
  // IOS WHATSAPP
  // ------------------------------------------------------------
  launchWhatsAppChatForIos(String number,
      {String message = "Hello"}) async {
    try {
      await _platform.invokeMethod('whatsappChat', {
        'number': number,
        'message': message,
      });
    } catch (e) {
      print("Failed to open WhatsApp: $e");
    }
  }



  @override
  void onClose() {
    numberController.dispose();
    super.onClose();
  }
}
