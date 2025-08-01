import 'dart:io';

import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:easy_callers_mobile/main.dart';
import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';

class DetailsBottomSheet {
  static show(
      String name,
      String phoneNumber,
      String email,
      Leads leads,
      {STATUS? status}) {
    var controller = Get.find<CallController>();
   return Get.bottomSheet(
        backgroundColor: Colors.white,
        enableDrag: true,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        Wrap(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lead Details",style: TextStyle(fontSize: 18),),
                  SizedBox(height: 20,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xff000000)),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(AssetUtils.singleLead,height: 20,width: 20,),
                            SizedBox(width: 5),
                            Text(name,style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500
                            ),)
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            SvgPicture.asset(AssetUtils.phone,height: 20,width: 20),
                            SizedBox(width: 5),
                            Text(phoneNumber),
                          ],
                        ),
                        SizedBox(height: 6),
                        Visibility(
                          visible: email.isNotEmpty,
                          child: Row(
                            children: [
                              SvgPicture.asset(AssetUtils.email,height: 20,width: 20),
                              SizedBox(width: 5),
                              Text(email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis
                              ),),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ATButtonV3(
                          title: "WhatsApp",
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                          height: 35,
                          containerWidth: 95,
                          color: Color(0xff2D201C),
                          textColor: CustomColors.white,
                          titleSize: 14,
                          radius: 10,
                          onTap: () async {
                            // controller.sendWhatsAppMessage(["9920111031"],"Hello");
                            // controller.sendBulkWhatsAppMessages(["9920111031"],"Hello from easy callers");
                          },
                        ),
                      ),
                      SizedBox(width: 10,),
                      Expanded(
                        child: ATButtonV3(
                          title: status == STATUS.lead ? "Call" : "Call again" ,
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                          height: 35,
                          containerWidth: 95,
                          color: Color(0xff2D201C),
                          textColor: CustomColors.white,
                          titleSize: 14,
                          radius: 10,
                          onTap: () async {
                            if(Platform.isIOS){
                              await controller.makeCallForIos(phoneNumber:phoneNumber??'',lead: leads);
                            }else{
                              await controller.makeCall(
                                  phoneNumber: phoneNumber, lead: leads);
                            }
                            // await controller.makeCall(lead: leads,phoneNumber: phoneNumber);
                            // Get.to(() => FeedbackScreen());
                          },
                        ),
                      ),

                      // ATButtonV3(
                      //   title: "SMS",
                      //   padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                      //   height: 35,
                      //   containerWidth: 95,
                      //   color: Color(0xff2D201C),
                      //   textColor: CustomColors.white,
                      //   titleSize: 14,
                      //   radius: 10,
                      //   onTap: () async {
                      //
                      //   },
                      // ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

enum STATUS{
  connected,notConnected,flowUp,lead
}
