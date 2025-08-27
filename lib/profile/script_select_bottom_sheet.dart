import 'package:easy_callers_mobile/profile/script_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/custom_buttons.dart';
import 'script_bottomsheet.dart';
import 'script_controller.dart';

class WhatsAppCustomMessage {
  static show() {
    final ScriptController controller;
    if (!Get.isRegistered<ScriptController>()) {
      controller = Get.put(ScriptController());
    } else {
      controller = Get.find<ScriptController>();
      // controller.getAllScript();
    }

    Widget scriptCard({
      required int index,
      required VoidCallback? onTap,
      required VoidCallback? onIconTap,
      required String? title,
      required String? script,
    }) {
      return GestureDetector(
        onLongPress: () {
          controller.toggleSelection(index);
        },
        onTap: onTap,
        child: Obx(() {
          final isSelected = controller.selectedIndices.contains(index);
          final isInSelection = controller.isInSelectionMode;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.grey.withOpacity(.3) : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? Colors.black
                    : Color(0xff000000).withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          if (isSelected)
                            GestureDetector(
                                onTap: onIconTap,
                                child: Icon(Icons.edit_note, size: 25 , color: Colors.black)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        script ?? "",
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }

    return Get.bottomSheet(
      ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.65,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Scripts",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 24),
                      ),
                      Stack(
                        children: [
                          Obx(()=>
                            Visibility(
                              visible: !controller.selectedIndices.isNotEmpty,
                              child: ATButtonV3(
                                title: "Create New",
                                color: Colors.black,
                                height: 35,
                                textColor: Colors.white,
                                titleSize: 14,
                                onTap: () => ScriptBottomSheet.show(createEditScript: true),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                          Obx(
                            ()=> Visibility(
                              visible: controller.selectedIndices.isNotEmpty,
                              child: GestureDetector(
                                onTap: () async {
                                  final ids = controller.selectedIndices
                                      .map((i) => controller.allScript[i].id)
                                      .toList();
                                  await controller.deleteSelectedScripts(ids);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Obx(() => Visibility(
                            visible: controller.isLoading.isFalse,
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: controller.filteredScripts.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                var item = controller.filteredScripts[index];
                                return Column(
                                  children: [
                                    scriptCard(
                                      title: item.title,
                                      script: item.script,
                                      index: index,
                                      onIconTap: (){
                                        ScriptBottomSheet.show(
                                          title: item.title,
                                          script: item.script,
                                          createEditScript: true,
                                          scriptId: item.id,
                                          editScript: true,
                                        );
                                      },
                                      onTap: () {
                                        if (controller.isInSelectionMode) {
                                          controller.toggleSelection(index);
                                        } else {
                                          Get.back(result: item.script);
                                          // ScriptBottomSheet.show(
                                          //   title: item.title,
                                          //   script: item.script,
                                          //   createEditScript: true,
                                          //   scriptId: item.id,
                                          //   editScript: true,
                                          // );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                );
                              },
                            ),
                          )),
                      Obx(
                        () => Visibility(
                          visible: controller.isLoading.isTrue,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff000000),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
    );
  }
}
