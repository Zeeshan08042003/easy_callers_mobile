import 'package:easy_callers_mobile/auth/custom_buttons.dart';
import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:easy_callers_mobile/feedback/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';
import 'details_bottom_sheet.dart';

class TotalLeads extends StatelessWidget {
  const TotalLeads({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      {'name': 'Lisa Anderson', 'number': '+1 (555) 678-9012', 'time': '9:15 AM'},
      {'name': 'Robert Taylor', 'number': '+1 (555) 789-0123', 'time': '1:30 PM'},
      {'name': 'Jennifer White', 'number': '+1 (555) 890-1234', 'time': '4:45 PM'},
    ];
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 2,
        backgroundColor: Colors.grey.shade100,
        elevation: 2,
        leading: Icon(Icons.arrow_back),
        title: Text(
          "Total Leads",
          style: TextStyle(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ListView.builder(
              shrinkWrap:true,
              primary: false,
              itemCount: data.length,
              itemBuilder: (context,index){
                var item = data[index];
                return Card(
                  elevation: 0,
                  color: Color(0xffFFFFFF),
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: GestureDetector(
                    onTap: (){
                      Get.dialog(DetailsBottomSheet.show(
                          item["name"]!,item["number"]!));
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item["name"].toString()),
                                SizedBox(height: 5,),
                                Text(item["number"].toString()),
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
                                var controller = Get.find<CallController>();
                                controller.makeCall(phoneNumber: item['number']);
                              },
                            )
                            // Text(item["time"], style: TextStyle(color: Colors.grey,fontSize: 10))
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}

// class LeadsChip extends StatelessWidget {
//   LeadsChip({super.key,this.name,this.number,this.email});
//   String? name;
//   String? email;
//   String? number;
//
//   @override
//   Widget build(BuildContext context) {
//     var controller = Get.find<CallController>();
//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.only(top: 30),
//       padding: EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//               width: 2,
//               color: CustomColors.black
//           )
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: double.infinity,
//             // decoration: BoxDecoration(
//             //     color: CustomColors.black,
//             //     border: Border.all(color: CustomColors.black),
//             //     borderRadius: BorderRadius.vertical(top: Radius.circular(8))
//             // ),
//             padding:EdgeInsets.symmetric(vertical: 10),
//             child: Text("Mrs Joginder",
//               style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                   color: CustomColors.black
//               ),
//             ),
//           ),
//           Row(
//             children: [
//               Icon(Icons.phone,color: CustomColors.black,),
//               SizedBox(width: 3,),
//               Text("9820111083",style: TextStyle(
//                 fontSize: 16,fontWeight: FontWeight.w500
//               ),)
//             ],
//           ),
//           SizedBox(height: 5,),
//           Row(
//             children: [
//               Icon(Icons.mail,color: CustomColors.black,),
//               SizedBox(width: 3,),
//               Text("joginder@gmail.com",style: TextStyle(
//                 fontSize: 16,fontWeight: FontWeight.w500
//               ),)
//             ],
//           ),
//           SizedBox(height: 20,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Expanded(
//                 child: ATButtonV3(
//                   title: "WhatsApp",
//                   padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
//                   height: 35,
//                   containerWidth: 95,
//                   color: Color(0xff2D201C),
//                   textColor: CustomColors.white,
//                   titleSize: 14,
//                   radius: 10,
//                   onTap: () async {
//                     controller.sendWhatsAppMessage(["9920111031"],"Hello");
//                     // controller.sendBulkWhatsAppMessages(["9920111031"],"Hello from easy callers");
//                   },
//                 ),
//               ),
//               SizedBox(width: 10,),
//               Expanded(
//                 child: ATButtonV3(
//                   title: "Call",
//                   padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
//                   height: 35,
//                   containerWidth: 95,
//                   color: Color(0xff2D201C),
//                   textColor: CustomColors.white,
//                   titleSize: 14,
//                   radius: 10,
//                   onTap: () async {
//                     Get.to(() => FeedbackScreen());
//                   },
//                 ),
//               ),
//
//               // ATButtonV3(
//               //   title: "SMS",
//               //   padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
//               //   height: 35,
//               //   containerWidth: 95,
//               //   color: Color(0xff2D201C),
//               //   textColor: CustomColors.white,
//               //   titleSize: 14,
//               //   radius: 10,
//               //   onTap: () async {
//               //
//               //   },
//               // ),
//             ],
//           ),
//           SizedBox(height: 20,)
//         ],
//       ),
//     );
//   }
// }


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