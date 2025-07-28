import 'package:easy_callers_mobile/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var controller = Get.put(CallController());

    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "Poppins",
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}


class CallController extends GetxController {
  final numberController = TextEditingController();
  final callLog = ''.obs;


  static const MethodChannel platform =
  MethodChannel('com.easy_callers/call');


  makeCallForIos(String number) async {
    await platform.invokeMethod('startCall', number);

    platform.setMethodCallHandler((call) async {
      if (call.method == 'callEnded') {
        String duration = call.arguments;
        print("⏱️ Call duration: $duration");
        // Continue your logic as in Kotlin
      }
    });
  }

  launchWhatsAppChatForIos(String number, {String message = "Hello Zeeshan Ahmed"}) async {
    try {
      await platform.invokeMethod('whatsappChat', {
        'number': number,
        'message': message,
      });
    } catch (e) {
      print("Failed to open WhatsApp: $e");
    }
  }

  Future<void> makeCall() async {
    final number = numberController.text.trim();
    if (number.isEmpty) {
      Get.snackbar('Error', 'Please enter a number');
      return;
    }

    try {
      // Await call log result after call ends
      final String? log = await platform.invokeMethod('startCall', {'number': number});
      callLog.value = log ?? 'No call log received';
    } on PlatformException catch (e) {
      Get.snackbar('Error', 'Failed to start call: ${e.message}');
    }
  }

  Future<void> sendWhatsAppMessage(List<String> numbers, String message) async {
    try {
      await platform.invokeMethod('sendBulkWhatsAppMessages', {
        'numbers': numbers,
        'message': message,
      });
    } catch (e) {
      print("Error sending messages: $e");
    }
  }

  static Future<void> sendSMS(String number, String message) async {
    try {
      await platform.invokeMethod('sendSMS', {
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
