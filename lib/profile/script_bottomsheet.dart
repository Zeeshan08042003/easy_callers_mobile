import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScriptBottomSheet {
  static void show({String? title,String? script}) {
    var errorStyle = TextStyle(fontWeight: FontWeight.w400, fontSize: 12);
    Get.bottomSheet(
      SingleChildScrollView(
        child: Column(
          children: [
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
}
