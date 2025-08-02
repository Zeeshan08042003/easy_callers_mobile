import 'dart:ffi';

import 'package:easy_callers_mobile/profile/script_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/sign_up_textfield.dart';
import '../constants/utils.dart';
import 'script_bottomsheet.dart';

class ScriptScreen extends StatelessWidget {
  const ScriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(ScriptController());
    return Scaffold(
      floatingActionButton: Container(
          margin: EdgeInsets.only(bottom: 20),
          width: 115,
          height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Color(0xff2D201C),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)),
            onPressed: () {
              ScriptBottomSheet.show(createEditScript: true);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add",
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Icon(
                    Icons.add_circle_rounded,
                    color: Colors.white,
                    // size: 25,
                  ),
                ],
              ),
            ),
          )),
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 2,
        backgroundColor: Colors.grey.shade100,
        elevation: 2,
        leading: GestureDetector(
            onTap: (){
              Get.back();
            },
            child: Icon(Icons.arrow_back)),
        title: Text("Script"),
        actions: [
          GestureDetector(
              onTap: (){
                controller.deleteSelectedScripts();
              },
              child: Obx(
                ()=>Visibility(
                  visible: controller.selectedIndices.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete,color: Colors.red,),
                  ),
                ),
              ))
        ],

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
          child: Column(
            children: [
              feedbackTextField(title: "Search"),
              SizedBox(height: 14,),
              Column(
                children: [
                  Obx(()=>
                     ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        reverse: true,
                        itemCount: controller.scripts.length,
                        itemBuilder: (context,index){
                          var item = controller.scripts[index];
                      return Column(
                        children: [
                          scriptCard(
                              title: item.title,
                              script: item.script, index: index,
                              onTap: () {
                                if (controller.isInSelectionMode) {
                                  controller.toggleSelection(index);
                                } else{
                                  ScriptBottomSheet.show(title: item.title,script: item.script,createEditScript: true);
                                }
                              }
                          ),
                          SizedBox(height: 14,)
                        ],
                      );
                    }),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }


  Widget feedbackTextField(
      {required String title,
        bool isFeedback = false,
        String? initialValue,
        TextEditingController? textEditingController}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(,
        //     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: title,
            hintStyle: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.4),
            ),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),  borderSide: BorderSide(
                color: CustomColors.black),),
          ),
          controller: textEditingController,
          minLines: isFeedback ? 1 : 1,
          maxLines: isFeedback ? 4 : 1,
          keyboardType: isFeedback ? TextInputType.multiline : TextInputType.text,
          textInputAction: isFeedback ? TextInputAction.newline : TextInputAction.done,
        )
      ],
    );
  }

  Widget scriptCard({
    required int index,
    required VoidCallback? onTap,
    required String? title,
    required String? script,
  }) {
    final controller = Get.find<ScriptController>();

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
            color: isSelected ? Colors.grey.withOpacity(.3) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.black : Color(0xff000000).withOpacity(0.1),
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
                          maxLines:1,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16
                          ),
                        ),
                        // if (isSelected)
                        //   Icon(Icons.cir, color: Colors.red),
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


}
