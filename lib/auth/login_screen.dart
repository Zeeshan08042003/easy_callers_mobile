import 'package:easy_callers_mobile/auth/reset_password.dart';
import 'package:easy_callers_mobile/auth/sign_up_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../constants/utils.dart';
import '../dashboard/dashboard_screen.dart';
import 'controller/login_controller.dart';
import 'custom_buttons.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(LoginController());
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: Text(
                  "Login into\nyour Account",
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 32,
                      color: CustomColors.black),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Obx(
                  ()=> Sign_Up_TextField(
                    errorMessage: controller.emailError.value,
                    labelText: "Email",
                    enableBorderColor: Color(0xffD6D6D6),
                    focusedBorderColor: CustomColors.black,
                    labelTextColor: CustomColors.black,
                    cursorColor: CustomColors.black,
                    onChanged: (txt) {
                      controller.email(txt);
                    },
                  ),
                ),
              ),
              Obx(()=>
                 Visibility(
                    visible: controller.emailError.isNotEmpty,
                    child: SizedBox(height: 10)),
              ),
              Obx(
                ()=> Sign_Up_TextField(
                  errorMessage: controller.passwordError.value,
                  suffixIcon: true,
                  labelText: "Password",
                  enableBorderColor: Color(0xffD6D6D6),
                  focusedBorderColor: CustomColors.black,
                  labelTextColor: CustomColors.black,
                  cursorColor: CustomColors.black,
                  onChanged: (txt) => controller.password(txt),
                ),
              ),
              Obx(()=>
                Visibility(
                  visible: controller.errorMsg.isNotEmpty,
                  child: Column(
                    children: [
                      SizedBox(height: 5,),
                      Text(controller.errorMsg.value,style: TextStyle(
                        color: Colors.red,fontSize: 16
                      )),
                      SizedBox(height: 5,)
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    // Get.to(() => ResetPasswordScreen(isActive: true));
                  },
                  child: Text(
                    "Resend Password",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                        color: CustomColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Obx(()=>
                    ATButtonV3(
                      title: "LOGIN",
                      containerWidth: 147,
                      isLoading: controller.isLoading.value,
                      height: 50,
                      color: Color(0xff2D201C),
                      textColor: CustomColors.white,
                      radius: 25,
                      loaderHeight: 20,
                      loaderWidth: 20,
                      onTap: () async {
                        var val = await controller.verify();
                        // var val = {
                        //   "email": controller.email.value,
                        //   "password": controller.password.value
                        // };
                        print(val);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}





