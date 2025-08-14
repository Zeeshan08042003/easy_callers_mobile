import 'dart:io';

import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:easy_callers_mobile/dashboard/dashboard_controller.dart';
import 'package:easy_callers_mobile/dashboard/total_leads.dart';
import 'package:easy_callers_mobile/feedback/feedback_screen.dart';
import 'package:easy_callers_mobile/profile/profile_screen.dart';
import 'package:easy_callers_mobile/webservices/model/call_logs_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/custom_buttons.dart';
import '../main.dart';
import '../webservices/model/leadModel.dart';
import 'count_widget.dart';
import 'details_bottom_sheet.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ❗ Recreate controller every time this screen is built
    // if (Get.isRegistered<DashBoardController>()) {
    //   Get.delete<DashBoardController>(); // Clean old one
    // }
     final controller = Get.put(DashBoardController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Align(alignment:Alignment.centerLeft,child: Text("Easy Callers",
        style: TextStyle(fontWeight: FontWeight.w600),
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
                onTap: (){
                  Get.to(() => ProfileScreen());
                },
                child: Icon(Icons.account_circle_outlined,size: 30,)),
          )
        ],
        backgroundColor: Colors.grey.shade100,
      ),
      body: Stack(
        children: [
          Obx(
            () => Visibility(
                visible: controller.isLoading.isFalse,
                child: CallTrackerHomePage(controller: controller)),
          ),
          Obx(
            () => Visibility(
                visible: controller.isLoading.isTrue,
                child: Center(
                    child: CircularProgressIndicator(
                  color: Color(0xff000000),
                ))),
          )
        ],
      ),
    );
  }
}

class CallTrackerHomePage extends StatelessWidget {
  final DashBoardController controller;

  CallTrackerHomePage({required this.controller});

  Widget buildCard(
      {String? title,
      IconData? icon,
      Color? iconColor,
      int? count,
      required List<Leads> data,
      String? buttonText,
      Widget? widget,
      bool? isLead,
      VoidCallback? onViewAll,
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
                Text(title ?? '',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Visibility(
                  visible: count != null,
                  child: CircleAvatar(
                    backgroundColor: iconColor?.withOpacity(0.1),
                    child: Text('$count', style: TextStyle(color: iconColor)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Stack(
              children: [
                Visibility(
                  visible: data.isEmpty,
                  child: Visibility(
                    visible: data.isEmpty,
                    child: Container(
                      height: MediaQuery.of(Get.context!).size.height * 0.64,
                      alignment: Alignment.center,
                      child: Text(
                        "Lead not assigned yet",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var item = data[index];
                      return GestureDetector(
                        onTap: () {
                          isLead == true
                              ? DetailsBottomSheet.show(item.name ?? '',
                                  item.phone ?? '', item.email ?? '',item,
                                  status: STATUS.lead)
                              : DetailsBottomSheet.show(item.name ?? '',
                                  item.phone ?? '', item.email ?? '',item,
                                  status: status);
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
                                    Text(item.name ?? ''),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(item.phone ?? ''),
                                  ],
                                ),
                                isLead == true
                                    ? ATButtonV3(
                                        title: "Call",
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2, vertical: 2),
                                        height: 30,
                                        containerWidth: 80,
                                        color: Color(0xff2D201C),
                                        textColor: CustomColors.white,
                                        titleSize: 12,
                                        radius: 8,
                                        onTap: () async {
                                          var controller =
                                              Get.find<CallController>();
                                          if(Platform.isIOS){
                                            await controller.makeCallForIos(phoneNumber:item.phone??'',lead: item);
                                          }else{
                                            await controller.makeCall(
                                                phoneNumber: item.phone, lead: item);
                                          }
                                          // var pref = await SharedPreferences.getInstance();
                                          // pref.clear();
                                          // controller.makeCall(phoneNumber: item['number']);
                                        },
                                      )
                                    : Text(item.attendedAt??'',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 10))
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              ],
            ),
            Visibility(
              visible: true,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      margin: EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xff2D201C),
                        border: Border.all(color: Color(0xffffffff)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "View All Leads",
                              style: TextStyle(
                                  color: CustomColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Icon(Icons.arrow_forward_sharp,
                                size: 20, color: CustomColors.white)
                          ],
                        ),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<DashBoardController>(() => DashBoardController(), fenix: true);
    var controller = Get.find<DashBoardController>();

    return ListView(
      children: [
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child:
              Text("Today's Activity Overview", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
        ),
        Obx(
          () => buildCard(
              title: 'Total leads',
              widget: SvgPicture.asset(AssetUtils.leads),
              iconColor: Color(0xffb3a1ff),
              count: controller.leadModel.value?.total,
              data: controller.totalLead,
              buttonText: 'View All (${controller.totalLead.length})',
              isLead: true,
              status: STATUS.lead,
              onViewAll: () async {
                await Get.to(() => LeadList(
                    status: 'assigned',
                    title: 'Total Leads',
                ));
              }),
        ),
        Obx(
          () => Visibility(
            visible: controller.visitor.isNotEmpty,
            child: buildCard(
                title: 'Visitors',
                icon: Icons.call,
                iconColor: Colors.green,
                count: controller.visitor.length,
                data: controller.visitor,
                buttonText: 'View All (${controller.visitor.length})',
                status: STATUS.connected,
                onViewAll: () async {
                  await Get.to(() => LeadList(
                      status: 'visiting',
                      title: 'Visitors',
                  ));
                }),
          ),
        ),
        // buildCard(
        //   title:'Not Connected',
        //   icon:Icons.call_end,
        //   iconColor:Colors.red,
        //   count:notConnected.length,
        //   data:notConnected,
        //   buttonText:'View All (${notConnected.length})',
        //   status: STATUS.notConnected
        // ),
        Obx(
          () => Visibility(
            visible: controller.dailyFollowUp.isNotEmpty,
            child: buildCard(
                title: 'Daily Follow-ups',
                icon: Icons.access_time,
                iconColor: Colors.orange,
                count: controller.dailyFollowUp.length,
                data: controller.dailyFollowUp,
                buttonText: 'View All (${controller.dailyFollowUp.length})',
                status: STATUS.flowUp,
                onViewAll: () async {
                  await Get.to(() => LeadList(
                      status: 'followup',
                      title: 'Follow Ups',
                  ));
                }),
          ),
        ),
      ],
    );
  }
}

class CustomWidget extends StatelessWidget {
  CustomWidget({
    super.key,
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
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 2, color: CustomColors.black)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: CustomColors.black,
                border: Border.all(color: CustomColors.black),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? "Daily Follow ups",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CustomColors.white),
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
                        SizedBox(height: 0.5),
                        // space between text and underline
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
          widget != null
              ? widget ?? SizedBox()
              : Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle ?? "19 May 2025",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        count ?? "19",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle),
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mr Joginder", style: Constants.constantStyle),
              Text("joginder@gmail.com", style: Constants.constantStyle),
            ],
          ),
          Spacer(),
          ATButtonV3(
            title: "Call",
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
