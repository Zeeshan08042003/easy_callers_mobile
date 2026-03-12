import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
import 'package:easy_callers_mobile/app/bindings/initial_binding.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_upload_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'features/employee/controllers/call_controller.dart';
import 'package:easy_callers_mobile/core/services/background_upload_manager.dart';

import 'features/project/services/project_service.dart';

import 'package:easy_callers_mobile/core/config/flavor_config.dart';

bootstrapApp() async {

  // Initialize Supabase with Flavor Config
  final supabaseService = await SupabaseService.init(
    url: FlavorConfig.instance.supabaseUrl,
    anonKey: FlavorConfig.instance.supabaseAnonKey,
  );
  Get.put(supabaseService);

  // Initialize notification service
  final notificationService = await NotificationService().init();
  Get.put(notificationService);

  // Initialize storage service
  final storageService = await StorageService.init();
  Get.put(storageService);

  // Initialize Auth service
  Get.put(AuthService(), permanent: true);

  // Register CallController (platform channel for calls)
  Get.put(CallController());

  // Register ProjectService
  Get.put(ProjectService());

  // Register Lead Services (Dependencies for BackgroundUploadManager)
  Get.put(WebService());
  Get.put(LeadUploadService());
  
  // Register BackgroundUploadManager
  Get.put(BackgroundUploadManager());

  runApp(const MyApp());
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlavorConfig(
      name: 'prod',
      variables: {
        'supabaseUrl': 'https://nlabqohuthloefqtcdzt.supabase.co',
        'supabaseAnonKey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sYWJxb2h1dGhsb2VmcXRjZHp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4NzYxMTksImV4cCI6MjA4NjQ1MjExOX0.3ojSxvQJ6A7UrIWHo1Q7ER5H84NvqwY-02eO2DQbHeA',
      },
    );
    
    await bootstrapApp();
  } catch (e) {
    print('Critical Initialization Error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to start app: $e\n\nPlease check your internet connection or contact support.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: FlavorConfig.instance.name == 'beta' ? 'Easy Callers Beta' : 'Easy Callers',
      debugShowCheckedModeBanner: FlavorConfig.isBeta,
      theme: ThemeData(
        fontFamily: "Poppins",
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff2D201C),
        brightness: Brightness.light,
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}

/// Platform channel controller for native calling, WhatsApp, and SMS.
/// Kept from the original codebase.
// class CallController extends GetxController {
//   final numberController = TextEditingController();
//   final callLog = ''.obs;
//
//   static const MethodChannel _platform =
//       MethodChannel('com.easy_callers/call');
//
//   makeCallForIos(String number) async {
//     await _platform.invokeMethod('startCall', number);
//
//     _platform.setMethodCallHandler((call) async {
//       if (call.method == 'callEnded') {
//         String duration = call.arguments;
//         print("⏱️ Call duration: $duration");
//       }
//     });
//   }
//
//   launchWhatsAppChatForIos(String number,
//       {String message = "Hello"}) async {
//     try {
//       await _platform.invokeMethod('whatsappChat', {
//         'number': number,
//         'message': message,
//       });
//     } catch (e) {
//       print("Failed to open WhatsApp: $e");
//     }
//   }
//
//   Future<void> makeCall({String? phoneNumber}) async {
//     final number = phoneNumber ?? numberController.text.trim();
//     if (number.isEmpty) {
//       Get.snackbar('Error', 'Please enter a number');
//       return;
//     }
//
//     try {
//       final dynamic logData =
//           await _platform.invokeMethod('startCall', {'number': number});
//
//       if (logData is Map) {
//         callLog.value = logData['display_string'] ?? 'Call finished';
//       } else if (logData is String) {
//         callLog.value = logData;
//       } else {
//         callLog.value = 'No call log received';
//       }
//     } on PlatformException catch (e) {
//       Get.snackbar('Error', 'Failed to start call: ${e.message}');
//     }
//   }
//
//   Future<void> sendWhatsAppMessage(
//       List<String> numbers, String message) async {
//     try {
//       await _platform.invokeMethod('sendBulkWhatsAppMessages', {
//         'numbers': numbers,
//         'message': message,
//       });
//     } catch (e) {
//       print("Error sending messages: $e");
//     }
//   }
//
//   static Future<void> sendSMS(String number, String message) async {
//     try {
//       await _platform.invokeMethod('sendSMS', {
//         'number': number,
//         'message': message,
//       });
//     } on PlatformException catch (e) {
//       print("Failed to send SMS: ${e.message}");
//     }
//   }
//
//   @override
//   void onClose() {
//     numberController.dispose();
//     super.onClose();
//   }
// }
