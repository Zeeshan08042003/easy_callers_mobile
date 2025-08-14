import 'package:easy_callers_mobile/auth/reset_password.dart';
import 'package:easy_callers_mobile/dashboard/dashboard_screen.dart';
import 'package:easy_callers_mobile/webservices/webservices.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/utils.dart';
import '../../webservices/model/login_model.dart';

class LoginController extends GetxController {
  RxString email = "".obs;
  RxString password = "".obs;
  RxString emailError = "".obs;
  RxString passwordError = "".obs;
  RxString newPassword = "".obs;
  RxString confirmPassword = "".obs;
  RxString newPasswordError = "".obs;
  RxString confirmPasswordError = "".obs;
  RxBool enableButton = false.obs;
  RxBool isPasswordReset = false.obs;
  var webservice = WebService();
  Rx<User?> userData = Rx<User?>(null);
  Rx<Company?> companyData = Rx<Company?>(null);
  var errorMsg = "".obs;
  var isLoading = false.obs;

  verify() async {
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
    if (enableButton.value == true) {
        await getUserLogin(
            email.value,password.value);
    }
    print("button val : ${enableButton.value}");
  }

  verifyPassword() async {
    bool isValid = true;
    RegExp regExp = RegExp(Constants.PASS_REGEX1);
    RegExp regExp1 = RegExp(Constants.PASS_REGEX1);

    if (newPassword.value.length == 0) {
      newPasswordError('Please enter Password');
      isValid = false;
    } else if (!regExp1.hasMatch(newPassword.value)) {
      newPasswordError('Please enter valid Password');
      isValid = false;
    } else {
      newPasswordError('');
    }

    if (confirmPassword.value.length == 0) {
      confirmPasswordError('Please enter password');
      isValid = false;
    } else if (!regExp1.hasMatch(confirmPassword.value)) {
      confirmPasswordError('Please enter valid password');
      isValid = false;
    } else {
      confirmPasswordError('');
    }
    enableButton(isValid);
    if (enableButton.value == true) {
        await resetPassword(
          password :newPassword.value,confirmPassword: confirmPassword.value
        );
    }
    print("button val : ${enableButton.value}");
  }

  getUserLogin(String email,String password) async {
    isLoading(true);
    var response = await webservice.getLogin(email, password);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (response.apiResponse.status == API_STATUS.SUCCESS) {
      if (response.payload?.success == true) {
        print("if");
        var user = response.payload?.data?.user;
        var company = response.payload?.data?.company;
        userData(user);
        companyData(company);
        await prefs.setString("token", response.payload?.token ?? '');
        if(user?.isActive == false){
          var data = await Get.to(() => ResetPasswordScreen(isActive: user?.isActive));
          if(data == true){
            await prefs.setString("userId", user?.id ?? '');
            await prefs.setString("companyId", user?.companyId ?? '');
            await prefs.setString("name", "${response.payload?.data?.user?.firstName} ${response.payload?.data?.user?.lastName}");
            await prefs.setString("email", response.payload?.data?.user?.email??'');
            await Get.offAll(() => DashboardScreen());
          }else{
            Get.back();
          }
        }else{
          await prefs.setString("userId", user?.id ?? '');
          await prefs.setString("companyId", user?.companyId ?? '');
          await prefs.setString("name", "${response.payload?.data?.user?.firstName} ${response.payload?.data?.user?.lastName}");
          await prefs.setString("email", response.payload?.data?.user?.email??'');
          await Get.offAll(() => DashboardScreen());
        }
      } else if (response.payload?.success == false) {
        print('else');
        String msg = response.payload?.message ?? 'Something went wrong';
        errorMsg(msg);
        print(msg); // ✅ this will print the actual error message
      }else{
        print('else 2');
      }
    }
    isLoading(false);
  }


  resetPassword({String? confirmPassword ,String? password}) async {
    isPasswordReset(true);
    var response = await webservice.getPasswordReset(confirmPassword??'', password??'');
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        Get.back(result: true);
      }
    }
    isPasswordReset(false);
  }


}
