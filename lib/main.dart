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
import 'dashboard/lead_list.dart';
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