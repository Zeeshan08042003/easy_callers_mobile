import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/sign_up_textfield.dart';
import '../constants/utils.dart';
import 'script_bottomsheet.dart';

class ScriptScreen extends StatelessWidget {
  const ScriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
          margin: EdgeInsets.only(bottom: 20),
          width: 115,
          height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)),
            onPressed: () {
              ScriptBottomSheet.show();
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
                  ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: 5,
                      itemBuilder: (context,index){
                    return Column(
                      children: [
                        scriptCard(
                            title: "Pirmal Group",
                            script: "If the prefix is set to a value such as '' that causes it to read values that were not originally stored by the SharedPreferences, initializing SharedPreferences may fail if any of the values are of types that are not supported by SharedPreferences. In this case, you can set an allowList that contains only preferences of supported types. "
                        ),
                        SizedBox(height: 14,)
                      ],
                    );
                  })
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

  Widget scriptCard({VoidCallback? onTap,String? title,String? script}){
    return GestureDetector(
      onTap: (){
        ScriptBottomSheet.show(title: title,script: script);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
            borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title??'',style: TextStyle(
                fontWeight: FontWeight.w600,fontSize: 16
            ),),
            SizedBox(height: 12,),
            Text(script??"",
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

}
