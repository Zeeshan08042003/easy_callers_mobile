import 'package:easy_callers_mobile/auth/sign_up_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../constants/utils.dart';
import '../dashboard/dashboard_screen.dart';
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
                child: Sign_Up_TextField(
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
              Sign_Up_TextField(
                errorMessage: controller.passwordError.value,
                suffixIcon: true,
                labelText: "Password",
                enableBorderColor: Color(0xffD6D6D6),
                focusedBorderColor: CustomColors.black,
                labelTextColor: CustomColors.black,
                cursorColor: CustomColors.black,
                onChanged: (txt) => controller.password(txt),
              ),
              SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
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
                  child: ATButtonV3(
                    title: "LOGIN",
                    containerWidth: 147,
                    height: 50,
                    color: Color(0xff2D201C),
                    textColor: CustomColors.white,
                    radius: 25,
                    onTap: () async {
                      controller.verify();
                      var val = {
                        "email": controller.email.value,
                        "password": controller.password.value
                      };
                      print(val);
                      // await controller.login(email: controller.email.value, password: controller.password.value);
                      Get.to(() => DashboardScreen());
                    },
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


class LoginController extends GetxController{
  RxString email = "".obs;
  RxString password = "".obs;
  RxString emailError = "".obs;
  RxString passwordError = "".obs;
  RxBool enableButton = false.obs;


  verify(){
    bool isValid = true;
    RegExp regExp = RegExp(Constants.EMAIL_REGEX);
    RegExp regExp1 = RegExp(Constants.PASS_REGEX1);

    if (email.value.length == 0) {
      emailError('Please enter email');
      isValid = false;
    } else if (!regExp.hasMatch(email.value)) {
      emailError('Please enter valid email');
      isValid = false;
    } else {
      emailError('');
    }

    if (password.value.length == 0) {
      passwordError('Please enter password');
      isValid = false;
    } else if (!regExp1.hasMatch(password.value)) {
      passwordError('Please enter valid password');
      isValid = false;
    } else {
      passwordError('');
    }

    enableButton(isValid);
    print("button val : ${enableButton.value}");
  }
}