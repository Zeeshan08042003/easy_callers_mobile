import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/distribute_leads_controller.dart';

class DistributeLeadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DistributeLeadsController>(
      () => DistributeLeadsController(),
    );
  }
}
