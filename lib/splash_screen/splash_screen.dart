import 'package:easy_callers_mobile/dashboard/dashboard_screen.dart';
import 'package:easy_callers_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(SplashController());
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 246, 247, 247),
            ],
            stops: [0, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Swype",
                style: TextStyle(
                    color: const Color.fromARGB(255, 15, 79, 132),
                    fontSize: 40.0
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SplashController extends GetxController{



  final controller = Get.put(CallController());

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    checkingScreen();
  }


  checkingScreen() async {
    var pref = await SharedPreferences.getInstance();
    var userId = pref.getString("userId");
    if (userId == null) {
      return Get.offAll(() => LoginScreen());
    } else{
      return Get.offAll(()=> DashboardScreen());
    }
  }
}
