import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/employee/feedback/controllers/call_feedback_controller.dart';

class CallFeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CallFeedbackController>(
      () => CallFeedbackController(),
    );
  }
}
