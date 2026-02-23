import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/leads/controllers/distribution_details_controller.dart';

class DistributionDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DistributionDetailsController>(
      () => DistributionDetailsController(),
    );
  }
}
