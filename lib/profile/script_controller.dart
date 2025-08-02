import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ScriptController extends GetxController{
  var isDeleting  = false.obs;

  RxList<ScriptModel> scripts = <ScriptModel>[].obs;
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

  void deleteSelectedScripts() {
    // Sort descending to avoid index shifting while removing
    final toDelete = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (var index in toDelete) {
      scripts.removeAt(index);
    }
    clearSelection();
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
    // Add sample data
    scripts.addAll([
      ScriptModel(
          title: "Piramal Group",
          script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
       ScriptModel(
          title: "Piramal Group",
          script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
       ScriptModel(
          title: "Piramal Group",
          script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "HDFC", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Reliance", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
      ScriptModel(title: "Infosys", script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "),
    ]);
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