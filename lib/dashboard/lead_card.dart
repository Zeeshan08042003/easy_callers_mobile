import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';
import '../constants/utils.dart';
import '../main.dart';
import '../webservices/model/leadModel.dart';
import 'details_bottom_sheet.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead});
  final Leads lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Color(0xffFFFFFF),
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: GestureDetector(
        onTap: (){
          Get.dialog(DetailsBottomSheet.show(
              lead.name??'',lead.phone??'',lead.email??'',lead));
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.name.toString().capitalizeFirst??''),
                    SizedBox(height: 5,),
                    Text(lead.phone.toString().capitalizeFirst??''),
                  ],
                ),
                ATButtonV3(
                  title: "Call",
                  padding: EdgeInsets.symmetric(horizontal: 2,vertical: 2),
                  height: 30,
                  containerWidth: 80,
                  color: Color(0xff2D201C),
                  textColor: CustomColors.white,
                  titleSize: 12,
                  radius: 8,
                  onTap: () async {
                    print(lead.phone);
                    var controller = Get.find<CallController>();
                    if(Platform.isIOS){
                      await controller.makeCallForIos(phoneNumber:lead.phone??'',lead: lead);
                    }else{
                      await controller.makeCall(
                          phoneNumber: lead.phone, lead: lead);
                    }
                    // await controller.makeCall(phoneNumber: lead.phone??'',lead: lead);
                  },
                )
                // Text(item["time"], style: TextStyle(color: Colors.grey,fontSize: 10))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
