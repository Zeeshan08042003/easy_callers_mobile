import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/splash/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
