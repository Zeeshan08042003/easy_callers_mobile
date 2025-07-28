import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:easy_callers_mobile/dashboard/total_leads.dart';
import 'package:easy_callers_mobile/feedback/feedback_screen.dart';
import 'package:easy_callers_mobile/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';
import '../main.dart';
import 'count_widget.dart';
import 'details_bottom_sheet.dart';


class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Text("Easy Callers"),
        backgroundColor: Colors.grey.shade100,
      ),
      body: CallTrackerHomePage(),
      //
      // theme: ThemeData(primarySwatch: Colors.blue),
      // home: CallTrackerHomePage(),
      // debugShowCheckedModeBanner: false,
    );
  }
}

class CallTrackerHomePage extends StatelessWidget {
  final connectedCalls = [
    {'name': 'John Smith', 'number': '+91 7021135299', 'time': '10:30 AM'},
    {'name': 'Sarah Johnson', 'number': '91 7021135299', 'time': '11:15 AM'},
    {'name': 'Mike Davis', 'number': '91 7666611031', 'time': '2:45 PM'},
  ];

  final notConnected = [
    {'name': 'Lisa Anderson', 'number': '+1 (555) 678-9012', 'time': '9:15 AM'},
    {'name': 'Robert Taylor', 'number': '+1 (555) 789-0123', 'time': '1:30 PM'},
    {'name': 'Jennifer White', 'number': '+1 (555) 890-1234', 'time': '4:45 PM'},
  ];

  final followUps = [
    {'name': 'Amanda Garcia', 'number': '+1 (555) 012-3456', 'time': 'Tomorrow 10:00 AM'},
    {'name': 'Christopher Lee', 'number': '+1 (555) 123-4567', 'time': 'Tomorrow 2:00 PM'},
    {'name': 'Michelle Rodriguez', 'number': '+1 (555) 234-5678', 'time': 'Friday 11:00 AM'},
  ];

  Widget buildCard(
      {String? title,
      IconData? icon,
      Color? iconColor,
      int? count,
      required List<Map> data,
      String? buttonText,
      Widget? widget,
      bool? isLead,
      required STATUS status}) {
    return Card(
      elevation: 4,
      color: Color(0xffFFFFFF),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                widget ?? Icon(icon, color: iconColor),
                SizedBox(width: 8),
                Text(title??'', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                CircleAvatar(
                  backgroundColor: iconColor?.withOpacity(0.1),
                  child: Text('$count', style: TextStyle(color: iconColor)),
                ),
              ],
            ),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap:true,
              primary: false,
              itemCount: data.length,
                itemBuilder: (context,index){
              var item = data[index];
              getAllowedStatuses() {
                return STATUS.values.where((e) => e != STATUS.connected).toList();
              }
              return GestureDetector(
                onTap: (){
                  isLead == true ? DetailsBottomSheet.show(
                      item["name"],item["number"],status: STATUS.lead
                  ): DetailsBottomSheet.show(
                      item["name"],item["number"],
                      status: status
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["name"]),
                            SizedBox(height: 5,),
                            Text(item["number"]),
                          ],
                        ),
                        isLead == true ?
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
                            Get.to(() => FeedbackScreen());
                            // controller.makeCall(phoneNumber: item['number']);
                          },
                        ) :
                        Text(item["time"], style: TextStyle(color: Colors.grey,fontSize: 10))
                      ],
                    ),
                  ),
                ),
              );
            }),
            // ...data.map((call) => ListTile(
            //   contentPadding: EdgeInsets.zero,
            //   title: Text(call['name']),
            //   subtitle: Text(call['number']),
            //   trailing: Text(call['time'], style: TextStyle(color: Colors.grey)),
            // )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Get.to(()=> TotalLeads());
                },
                child: Text(buttonText??''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("Today's Activity Overview", style: TextStyle(fontSize: 16)),
          ),
          buildCard(
            title: 'Total leads',
            widget: SvgPicture.asset(AssetUtils.leads),
            iconColor:Color(0xffb3a1ff),
            count:connectedCalls.length,
            data:connectedCalls,
            buttonText: 'View All (${connectedCalls.length})',
            isLead: true,
            status: STATUS.lead
          ),
          buildCard(
            title: 'Connected Calls',
            icon:Icons.call,
            iconColor:Colors.green,
            count:connectedCalls.length,
            data:connectedCalls,
            buttonText: 'View All (${connectedCalls.length})',
            status: STATUS.connected
          ),
          buildCard(
            title:'Not Connected',
            icon:Icons.call_end,
            iconColor:Colors.red,
            count:notConnected.length,
            data:notConnected,
            buttonText:'View All (${notConnected.length})',
            status: STATUS.notConnected
          ),
          buildCard(
            title:'Daily Follow-ups',
            icon:Icons.access_time,
            iconColor:Colors.orange,
            count:followUps.length,
            data:followUps,
            buttonText:'View All (${followUps.length})',
            status: STATUS.flowUp
          ),
        ],
      );
  }
}



// class Dashboard extends StatelessWidget {
//   const Dashboard({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: CustomColors.white,
//       appBar: AppBar(
//         elevation: 1,
//         backgroundColor: CustomColors.black,
//         automaticallyImplyLeading: false,
//         title: Text("Easy Callers",style: TextStyle(fontWeight: FontWeight.w600,color: CustomColors.white),),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 8.0,top: 5),
//             child: GestureDetector(
//                 onTap: (){
//                   Get.to(() => ProfileScreen());
//                 },
//                 child: Icon(Icons.account_circle,color: Color(0xffFFFFFF),size: 30)),
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               children: [
//                 Container(
//                   // height: 100,
//                   width: double.infinity,
//                   margin: EdgeInsets.only(top: 20),
//                   decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black12,
//                             offset: Offset(0, -2),
//                             blurRadius: 29,
//                             spreadRadius: 3,
//                             blurStyle: BlurStyle.normal)
//                       ]),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 20),
//                           child: GridView(
//                             shrinkWrap: true,
//                             primary: false,
//                             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 crossAxisSpacing: 15,
//                                 mainAxisSpacing: 15,
//                                 childAspectRatio: 3 / 2.35),
//                             children: <Widget>[
//                               CountContainer(
//                                 title: "Total Leads",
//                                 days: "10",
//                                 onTap: (){
//                                   Get.to(() => TotalLeads());
//                                 },
//                               ),
//                               CountContainer(
//                                 title: "Connected",
//                                 days: "10",
//                               ),
//                               CountContainer(
//                                 title: "Not Connected",
//                                 days: "10",
//                               ),
//                               CountContainer(
//                                 title: "Average call time",
//                                 days: '-',
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 CustomWidget(title: "Total leads",subtitle: "1 July 2025", count: "10",),
//                 CustomWidget(title: "Connected",subtitle: "1 July 2025", count: "10",),
//                 CustomWidget(title: "Not Connected",subtitle: "1 July 2025", count: "10",),
//                 CustomWidget(),
//                 CustomWidget(title: "Total follow ups",),
//                 CustomWidget(title: "Total follow ups",widget: ClientWidget()),
//                 SizedBox(height: 20,)
//               ],
//             ),
//           ),
//         ),
//       ),
//       // SizedBox(
//       //   height: 20,
//       // ),
//     );
//   }
// }

class CustomWidget extends StatelessWidget {
  CustomWidget({super.key,
  this.title,
  this.subtitle,
  this.count,
    this.onTap,
    this.widget,
  });
  String? title;
  String? subtitle;
  String? count;
  VoidCallback? onTap;
  Widget? widget;

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10),
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
            decoration: BoxDecoration(
                color: CustomColors.black,
                border: Border.all(color: CustomColors.black),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))
            ),
            padding:EdgeInsets.symmetric(vertical: 10,horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title ?? "Daily Follow ups",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CustomColors.white
                  ),
                ),
                Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xffFFFFFF),
                          ),
                        ),
                        SizedBox(height: 0.5), // space between text and underline
                        Container(
                          height: 1,
                          width: 48,
                          color: Color(0xffFFFFFF),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          // SizedBox(height: 10,),
          widget!=null ? widget??SizedBox() :Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(subtitle ?? "19 May 2025",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16
                  ),
                ),
                Text(count ?? "19",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class ClientWidget extends StatelessWidget {
  const ClientWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle),
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mr Joginder",style: Constants.constantStyle),
              Text("joginder@gmail.com",style: Constants.constantStyle),
            ],
          ),
          Spacer(),
          ATButtonV3(
            title: "Call",
            padding: EdgeInsets.symmetric(horizontal: 2,vertical: 2),
            height: 30,
            containerWidth: 60,
            color: Color(0xff2D201C),
            textColor: CustomColors.white,
            titleSize: 12,
            radius: 12,
            onTap: () async {},
          ),
        ],
      ),
    );
  }
}


