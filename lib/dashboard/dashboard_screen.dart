import 'package:easy_callers_mobile/constants/utils.dart';
import 'package:easy_callers_mobile/dashboard/total_leads.dart';
import 'package:easy_callers_mobile/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'count_widget.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: CustomColors.black,
        automaticallyImplyLeading: false,
        title: Text("Easy Callers",style: TextStyle(fontWeight: FontWeight.w600,color: CustomColors.white),),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0,top: 5),
            child: GestureDetector(
                onTap: (){
                  Get.to(() => ProfileScreen());
                },
                child: Icon(Icons.account_circle,color: Color(0xffFFFFFF),size: 30)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              // height: 100,
              width: double.infinity,
              margin: EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, -2),
                        blurRadius: 29,
                        spreadRadius: 3,
                        blurStyle: BlurStyle.normal)
                  ]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: GridView(
                        shrinkWrap: true,
                        primary: false,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 3 / 2.35),
                        children: <Widget>[
                          CountContainer(
                            title: "Total Leads",
                            days: "10",
                            onTap: (){
                              Get.to(() => TotalLeads());
                            },
                          ),
                          CountContainer(
                            title: "Connected",
                            days: "10",
                          ),
                          CountContainer(
                            title: "Not Connected",
                            days: "10",
                          ),
                          CountContainer(
                            title: "Average call time",
                            days: '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FlowUp()
          ],
        ),
      ),
      // SizedBox(
      //   height: 20,
      // ),
    );
  }
}

class FlowUp extends StatelessWidget {
  const FlowUp({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
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
                Text("Daily Follow ups",
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
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("19 May 2025",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16
                  ),
                ),
                Text("19",
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
