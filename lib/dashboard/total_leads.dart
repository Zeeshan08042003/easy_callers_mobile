import 'dart:io';

import 'package:easy_callers_mobile/auth/custom_buttons.dart';
import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../main.dart';

class TotalLeads extends StatelessWidget {
  const TotalLeads({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.white,
      appBar: AppBar(
        backgroundColor: CustomColors.black,
        titleSpacing: 2,
        leading: Icon(Icons.arrow_back,color: Color(0xffFFFFFF),),
        title: Text(
          "Total Leads",
          style: TextStyle(color: CustomColors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            LeadsChip(),
            LeadsChip(),
          ],
        ),
      ),
    );
  }
}

class LeadsChip extends StatelessWidget {
  LeadsChip({super.key,this.name,this.number,this.email});
  String? name;
  String? email;
  String? number;

  @override
  Widget build(BuildContext context) {
    var controller = Get.find<CallController>();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              width: 2,
              color: CustomColors.black
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            // decoration: BoxDecoration(
            //     color: CustomColors.black,
            //     border: Border.all(color: CustomColors.black),
            //     borderRadius: BorderRadius.vertical(top: Radius.circular(8))
            // ),
            padding:EdgeInsets.symmetric(vertical: 10),
            child: Text("Mrs Joginder",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CustomColors.black
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.phone,color: CustomColors.black,),
              SizedBox(width: 3,),
              Text("9820111083",style: TextStyle(
                fontSize: 16,fontWeight: FontWeight.w500
              ),)
            ],
          ),
          SizedBox(height: 5,),
          Row(
            children: [
              Icon(Icons.mail,color: CustomColors.black,),
              SizedBox(width: 3,),
              Text("joginder@gmail.com",style: TextStyle(
                fontSize: 16,fontWeight: FontWeight.w500
              ),)
            ],
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
                    if(Platform.isIOS){
                      await controller.launchWhatsAppChatForIos("7666611031");
                    }else{
                      await controller.sendWhatsAppMessage(["9920111031"],"Hello");
                    }
                    // controller.sendBulkWhatsAppMessages(["9920111031"],"Hello from easy callers");
                  },
                ),
              ),
              SizedBox(width: 10,),
              Expanded(
                child: ATButtonV3(
                  title: "Call",
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                  height: 35,
                  containerWidth: 95,
                  color: Color(0xff2D201C),
                  textColor: CustomColors.white,
                  titleSize: 14,
                  radius: 10,
                  onTap: () async {
                    if(Platform.isIOS){
                      // await controller.makeCallForIos("9029695116");
                      await controller.makeCallForIos("7666611031");
                    }else{
                      await controller.makeCall();
                    }
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
          SizedBox(height: 20,)
        ],
      ),
    );
  }
}


class LeadController extends GetxController{
  static const String numberRegx = "(?:(?:\+|00)\d{1,3})?[\s.-]?\(?\d{1,4}\)?([\s.-]?\d{1,4}){1,4}";

  getNumberValidate(String? number){
    if (number == null) return;

    final regExp = RegExp(numberRegx);

    if(regExp.hasMatch(number)){
      print("number is valid $number");
    }
  }
}