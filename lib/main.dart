import 'dart:async';
import 'dart:convert';

import 'package:easy_callers_mobile/auth/login_screen.dart';
import 'package:easy_callers_mobile/dashboard/LeadsPagination.dart';
import 'package:easy_callers_mobile/feedback/feedback_screen.dart';
import 'package:easy_callers_mobile/splash_screen/splash_screen.dart';
import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:easy_callers_mobile/webservices/webservices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dashboard/dashboard_controller.dart';
import 'webservices/model/call_logs_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DependenciesInjection.init();
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "Poppins",
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class DependenciesInjection{
  static void init(){
    Get.put<GetConnect>(GetConnect());
  }
}


class CallController extends GetxController {
  final numberController = TextEditingController();
  Rx<CallLogModel?> callLog = Rx<CallLogModel?>(null);
  RxBool isSubmittingData = false.obs;
  RxBool isLoading = false.obs;

  static const MethodChannel _platform =
  MethodChannel('com.easy_callers/call');


  Future<String?> makeCallForIos(String number) async {
    try {
      // Initiate the iOS call
      await _platform.invokeMethod('startCall', number);

      // Wait for callEnded callback with duration
      final completer = Completer<String?>();

      _platform.setMethodCallHandler((call) async {
        if (call.method == 'callEnded') {
          final String duration = call.arguments ?? '';
          print("⏱️ Call duration: $duration");
          completer.complete(duration);
        }
      });

      // Return when duration is received or timeout after 60s
      return completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print("⏳ Timeout waiting for callEnded");
          return null;
        },
      );
    } on PlatformException catch (e) {
      print("❌ iOS call failed: ${e.message}");
      Get.snackbar('Error', 'Failed to start iOS call: ${e.message}');
      return null;
    }
  }


  launchWhatsAppChatForIos(String number, {String message = "Hello Zeeshan Ahmed"}) async {
    try {
      await _platform.invokeMethod('whatsappChat', {
        'number': number,
        'message': message,
      });
    } catch (e) {
      print("Failed to open WhatsApp: $e");
    }
  }

  Future<CallLogModel?> makeCall({
    String? phoneNumber,
    bool? fromFeedbackScreen,
    required Leads lead,
  }) async {
    isLoading(true);
    if(Get.isDialogOpen == true){
      Get.back();
    }
    if (isLoading.value == true) {
      Get.dialog(
        Center(
          child: CircularProgressIndicator(color: Color(0xff000000)),
        ),
        barrierDismissible: false,
      );
    }

    callLog(null);
    try {
      final result = await _platform.invokeMethod('startCall', {'number': phoneNumber});
      print("results are : $result");

      if (result != null) {
        callLog(CallLogModel.fromJson(jsonDecode(result)));
        print("data is here : ${callLog.value?.status}");

        isLoading(false);
        Get.back(); // 👈 close the loader dialog

        if (fromFeedbackScreen == true) {
          await Get.off(() => FeedbackScreen(lead: lead));
        } else {
          await Get.to(() => FeedbackScreen(lead: lead));
        }
      } else {
        print("⚠️ Invalid or no call log received");
        isLoading(false);
        Get.back(); // 👈 close the loader dialog
      }
    } on PlatformException catch (e) {
      print('❌ Platform error: ${e.message}');
      isLoading(false);
      Get.back(); // 👈 close the loader dialog
    }

    return null;
  }


  Future<void> sendWhatsAppMessage(List<String> numbers, String message) async {
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

  int convertDurationToSeconds(String duration) {
    final parts = duration.split(':').map(int.parse).toList();
    if (parts.length != 3) return 0; // safety check

    final hours = parts[0];
    final minutes = parts[1];
    final seconds = parts[2];

    return hours * 3600 + minutes * 60 + seconds;
  }



  submitData({
   required String status,
   required String leadId,
   required String callDuration,
   required String notes,
  }) async {
    isSubmittingData(true);
    var response = await WebService().submitCallLog(
        status: status,
        leadId: leadId,
        callDuration: callDuration,
        notes: notes);
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        print("Data ${response.payload?.data}");
        Get.back();
        if (Get.isRegistered<DashBoardController>()) {
          Get.delete<DashBoardController>(); // Clean old one
        }else  if (Get.isRegistered<LeadPaginationController>()) {
          Get.delete<LeadPaginationController>(); // Clean old one
        }
        print("data");
      }
    }
    isSubmittingData(false);
  }


  checkPermission(){

  }

  @override
  void onClose() {
    numberController.dispose();
    super.onClose();
  }
}
