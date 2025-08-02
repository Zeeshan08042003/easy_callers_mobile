import 'package:easy_callers_mobile/auth/sign_up_textfield.dart';
import 'package:easy_callers_mobile/profile/script_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';
import '../constants/utils.dart';

class ScriptBottomSheet {
  static void show({String? title,String? script,bool? createEditScript}) {
    var errorStyle = TextStyle(fontWeight: FontWeight.w400, fontSize: 12);
    var controller = Get.find<ScriptController>();

    Get.bottomSheet(
      SingleChildScrollView(
        child: Column(
          children: [
            if(createEditScript == true)
              Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16,vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20
                      )
                  ),
                  child: createOrEditScript(title: title,script: script))
            else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 20),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(20
                    )
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title??''),
                    SizedBox(height: 12,),
                    Text(script??''),

                  ],
                ),
              )
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    ).whenComplete(() {
    });
  }


 static Widget createOrEditScript({String? title,String? script}){
    var controller = Get.find<ScriptController>();
    TextEditingController titleController = TextEditingController(text: title);
    TextEditingController scriptController = TextEditingController(text: script);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10,),
        Text("New Script",style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600
        ),),
        SizedBox(height: 20,),
        // Obx(()=>
            feedbackTextField(title: "Title",textEditingController: titleController,initialValue:title),
   // ),
        // SizedBox(height: 1  0,),
        // Obx(()=>
            feedbackTextField(title: "Script",isFeedback: true,textEditingController: scriptController,initialValue:script),
   // ),
   //      Obx(()=>
          ATButtonV3(
            title: "Create",
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            color: const Color(0xff2D201C),
            textColor: CustomColors.white,
            titleSize: 16,
            isLoading: controller.isCreatingNewScript.value,
            loaderWidth: 20,
            loaderHeight: 20,
            radius: 8,
            onTap: () async {
              print("hello");
              await controller.createNewScript(titleController.text, scriptController.text);
            }
          ),
        // ),
      ],
    );
  }

  static Widget feedbackTextField(
      {required String title,
        bool isFeedback = false,
        String? initialValue,
        TextEditingController? textEditingController}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Sign_Up_TextField(
          initialValue:
          textEditingController == null ? (initialValue ?? "") : null,
          errorMessage: "",
          controller: textEditingController,
          radius: BorderRadius.circular(5),
          enableBorderColor: const Color(0xffD6D6D6),
          focusedBorderColor: CustomColors.black,
          labelTextColor: CustomColors.black,
          cursorColor: CustomColors.black,
          maxLines: isFeedback ? null : 1,
          minLines: isFeedback ? 4 : 1,
          expands: false,
          textInputAction:
          isFeedback ? TextInputAction.newline : TextInputAction.done,
          keyBoardType:
          isFeedback ? TextInputType.multiline : TextInputType.text,
          onChanged: (txt) {},
        ),
        const SizedBox(height: 0),
      ],
    );
  }
  

}


