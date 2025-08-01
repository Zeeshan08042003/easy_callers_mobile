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
  RxBool enableButton = false.obs;
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
        await prefs.setString("userId", user?.id ?? '');
        await prefs.setString("companyId", user?.companyId ?? '');
        await prefs.setString("token", response.payload?.token ?? '');
        Get.offAll(() => DashboardScreen());
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
}
