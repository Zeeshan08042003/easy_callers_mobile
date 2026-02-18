import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
import 'package:easy_callers_mobile/app/routes/app_pages.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';
import 'package:easy_callers_mobile/app/bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  final supabaseService = await SupabaseService.init();
  Get.put(supabaseService);

  // Initialize notification service
  final notificationService = await NotificationService().init();
  Get.put(notificationService);

  // Register CallController (platform channel for calls)
  Get.put(CallController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Easy Callers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Poppins",
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff2D201C),
        brightness: Brightness.light,
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.login,
      getPages: AppPages.pages,
    );
  }
}

/// Platform channel controller for native calling, WhatsApp, and SMS.
/// Kept from the original codebase.
class CallController extends GetxController {
  final numberController = TextEditingController();
  final callLog = ''.obs;

  static const MethodChannel _platform =
      MethodChannel('com.easy_callers/call');

  makeCallForIos(String number) async {
    await _platform.invokeMethod('startCall', number);

    _platform.setMethodCallHandler((call) async {
      if (call.method == 'callEnded') {
        String duration = call.arguments;
        print("⏱️ Call duration: $duration");
      }
    });
  }

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

  Future<void> makeCall({String? phoneNumber}) async {
    final number = phoneNumber ?? numberController.text.trim();
    if (number.isEmpty) {
      Get.snackbar('Error', 'Please enter a number');
      return;
    }

    try {
      final dynamic logData =
          await _platform.invokeMethod('startCall', {'number': number});
      
      if (logData is Map) {
        callLog.value = logData['display_string'] ?? 'Call finished';
      } else if (logData is String) {
        callLog.value = logData;
      } else {
        callLog.value = 'No call log received';
      }
    } on PlatformException catch (e) {
      Get.snackbar('Error', 'Failed to start call: ${e.message}');
    }
  }

  Future<void> sendWhatsAppMessage(
      List<String> numbers, String message) async {
    try {
      await _platform.invokeMethod('sendBulkWhatsAppMessages', {
        'numbers': numbers,
        'message': message,
      });
    } catch (e) {
      print("Error sending messages: $e");
    }
  }

  static Future<void> sendSMS(String number, String message) async {
    try {
      await _platform.invokeMethod('sendSMS', {
        'number': number,
        'message': message,
      });
    } on PlatformException catch (e) {
      print("Failed to send SMS: ${e.message}");
    }
  }

  @override
  void onClose() {
    numberController.dispose();
    super.onClose();
  }
}
