import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../constants/utils.dart';
import '../webservices/model/leadModel.dart';

class CallLogsDetails extends StatelessWidget {
  CallLogsDetails({super.key, required this.lead});
  final Leads lead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          title: Text("Lead Details"),
        ),
      body: ListView.builder(
        itemCount: lead.callLogs?.length ?? 0,
        itemBuilder: (context, index) {
          var item = lead.callLogs?[index];
          return TimelineTile(
            afterLineStyle: const LineStyle(color: Colors.green),
            beforeLineStyle: const LineStyle(color: Colors.orange),
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.manual,
            lineXY: 0.12, // keeps line left
            isFirst: index == 0,
            isLast: index == (lead.callLogs?.length ?? 0) - 1,
            indicatorStyle: IndicatorStyle(
              indicatorXY: 0.5, // aligns indicator to top of child
              width: 40,
              height: 40,
              indicator: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatDate(item?.createdAt ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatMonth(item?.createdAt ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            endChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Text(
                item?.notes ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      )
    );
  }
}
