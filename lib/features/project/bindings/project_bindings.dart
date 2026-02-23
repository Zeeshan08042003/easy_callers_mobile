import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_list_controller.dart';
import 'package:easy_callers_mobile/features/project/controllers/create_project_controller.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_detail_controller.dart';

class ProjectListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProjectListController());
  }
}

class CreateProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateProjectController());
  }
}

class ProjectDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProjectDetailController());
  }
}
