import 'package:easy_callers_mobile/webservices/model/getScriptModel.dart';
import 'package:easy_callers_mobile/webservices/webservices.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';

class ScriptController extends GetxController{
  var isDeleting  = false.obs;
  var isLoading  = false.obs;
  var searchQuery = ''.obs;

  RxList<ScriptModel> scripts = <ScriptModel>[].obs;
  RxList<Scripts> allScript = <Scripts>[].obs;
  RxBool isCreatingNewScript = false.obs;

  var selectedIndices = <int>{}.obs;

  void toggleSelection(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
    }
  }

  void clearSelection() {
    selectedIndices.clear();
  }

  bool get isInSelectionMode => selectedIndices.isNotEmpty;

  deleteSelectedScripts(List<String?> ids) async {
    await Get.dialog(Obx(()=>
       DeleteConformation(
        title: 'Attention!',
        subtitle: 'Are you sure you want to delete script.',
        btnText: 'Delete',
        isLoading: isDeleting.value,
        padding: EdgeInsets.all(16),
        loaderWidth: 20,
        loaderHeight: 20,
        onTap: () async {
          isDeleting(true);
          try {
            // Get selected script IDs
            final ids = selectedIndices
                .map((i) => allScript[i].id)
                .where((id) => id != null && id.isNotEmpty)
                .toList();

            if (ids.isEmpty) {
              isDeleting(false);
              return;
            }

            // Call bulk delete API
            await deleteScript(ids);

            // Refresh the script list
            await getAllScript();

            // Clear selection and close dialog
            clearSelection();
            Get.back();
          } catch (e) {
            print("Error deleting scripts: $e");
          }
          isDeleting(false);
        },
        onCancel: (){
          Get.back();
         clearSelection();
        },
      ),
    ));


  }







  createNewScript(String title,String script){
    isCreatingNewScript(true);
    scripts.add(
        ScriptModel(
            title: title,
            script: script)
    );
    Get.back();
    isCreatingNewScript(false);
   }




  @override
  void onInit() {
    super.onInit();
    getAllScript();
    // Add sample data
    // scripts.addAll([
      // ScriptModel(
      //     title: "Piramal Group",
      //     script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      //  ScriptModel(
      //     title: "Piramal Group",
      //     script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      //  ScriptModel(
      //     title: "Piramal Group",
      //     script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      // ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
    // ]);
  }


  getAllScript() async {
    isLoading(true);
    var response = await WebService().getAllScript();
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        allScript(response.payload?.data?.scripts);
      }
    }
    isLoading(false);
  }

  addNewScript(String title,String script) async {
    isCreatingNewScript(true);
    var response = await WebService().addNewScript(title, script);
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        Get.back();
        await getAllScript();
      }
    }
    isCreatingNewScript(false);
  }


  deleteScript(List<String?> scriptId) async {
    var response = await WebService().deleteScript(scriptId: scriptId);
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        // Get.back();
      }
    }
  }


  updateData({String? title,String? script,String? scriptId}) async {
    isCreatingNewScript(true);
    var response = await WebService().updateScript(
      title: title,scriptId: scriptId,script: script
    );
    if(response.apiResponse.status == API_STATUS.SUCCESS){
      if(response.payload?.success == true){
        Get.back();
        await getAllScript();
      }
    }
    isCreatingNewScript(false);
  }


  List<Scripts> get filteredScripts {
    if (searchQuery.isEmpty) return allScript;
    return allScript.where((script) {
      final title = script.title?.toLowerCase() ?? '';
      final content = script.script?.toLowerCase() ?? '';
      return title.contains(searchQuery.value.toLowerCase()) ||
          content.contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }


}


class ScriptModel{
  String? title;
  String? script;
  ScriptModel({
    this.script,
    this.title
});
}

class DeleteConformation extends StatelessWidget {
  const DeleteConformation({super.key,  this.padding,  this.title,  this.subtitle,  this.btnText, this.isLoading, this.onTap, this.onCancel, this.loaderHeight, this.loaderWidth});
  final EdgeInsets? padding;
  final String? title;
  final String? subtitle;
  final String? btnText;
  final bool? isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final double? loaderHeight;
  final double? loaderWidth;

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Container(
        constraints: BoxConstraints(
          minWidth: 100,
          maxWidth: 350,
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title ?? '',
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    child: Icon(Icons.close, color: Colors.grey),
                    onTap: () {
                      Get.back();
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                subtitle ?? '',
                style: TextStyle(
                  fontSize: 15.0,
                  color: Color(0xFF9D9FA6),
                ),
              ),
              SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ATButtonV3(
                      title: "Cancel",
                      color: Color(0xfffafafa),
                      defaultPadding: true,
                      height: 40,
                      textColor: Color(0xff000000),
                      onTap: onCancel ?? () async {
                        Get.back();
                      },
                    ),
                  ),
                  SizedBox(width: 24.0),
                  Expanded(
                    child: ATButtonV3(
                      title: btnText??'',
                      color: Colors.red,
                      loaderHeight: loaderHeight,
                      loaderWidth: loaderWidth,
                      isLoading: isLoading,
                      defaultPadding: true,
                      radius: 5,
                      height: 40,
                      textColor: Color(0xffffffff),
                      onTap: onTap
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}



