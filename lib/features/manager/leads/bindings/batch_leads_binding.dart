import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/batch_leads_controller.dart';

class BatchLeadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BatchLeadsController>(() => BatchLeadsController());
  }
}
