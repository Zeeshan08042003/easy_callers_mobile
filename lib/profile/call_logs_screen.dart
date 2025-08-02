import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/custom_buttons.dart';
import '../constants/utils.dart';

class CallLogsScreen extends StatelessWidget {
  const CallLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(CallStatusController());
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
        title: Text("Call Logs"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10,10,0,10),
            child: Obx(()=>
              ListView.builder(
                shrinkWrap: true,
                  primary: false,
                  itemCount: controller.callLogs.length,
                  itemBuilder: (context,index){
                return CallLogCard(model: controller.callLogs[index]);
              }),
            )
          ),
        ],
      ),
    );
  }
}



class CallLogCard extends StatelessWidget {
   CallLogCard({super.key, this.model});
  final CallLogStatusModel? model;
  
  @override
  Widget build(BuildContext context) {

    getStatusBgColor(String status) {
      if (status == "Connected") {
        return Colors.green.withOpacity(.1);
      } else if (status == "") {
        return Colors.white;
      } else {
        return Colors.red.withOpacity(.1);
      }
    }

    getLeadStatusBgColor(String status) {
      if (status == "visiting") {
        return Colors.green.withOpacity(.2);
      } else if (status == "followup") {
        return Colors.orange.withOpacity(.2);
      } else {
        return Colors.red.withOpacity(.2);
      }
    }

    getLeadStatusTextColor(String status) {
      if (status == "visiting") {
        return Color(0xff2E8B57);
      } else if (status == "followup") {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    
    
    getCallIcon(String callStatus){
      if(callStatus == "Connected"){
        return Icon(Icons.call_made_outlined,color: Colors.green,);
      }else{
        return Icon(Icons.call_missed_outgoing_outlined,color: Colors.red,);
      }
    }
    
    
    
    return Card(
      elevation: 0,
      color: Color(0xffFFFFFF),
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: GestureDetector(
        onTap: (){
        },
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
              color: getStatusBgColor(model?.callStatus??''),
              border: Border.all(color: Color(0xff000000).withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical:2,horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Row(
                 children: [
                   getCallIcon(model?.callStatus??''),
                   SizedBox(width: 5,),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(model?.name?.capitalizeFirst??'',
                       style: TextStyle(
                         fontSize: 16
                       ),
                       ),
                       // SizedBox(height:,),
                       Row(
                         children: [
                           Text(model?.phoneNo?.capitalizeFirst??'',
                             style: TextStyle(
                                 fontSize: 12
                             ),),
                           SizedBox(width: 5,),
                           Visibility(
                             visible: model?.duration?.isNotEmpty == true,
                             child: Text("(${model?.duration??''})",
                               style: TextStyle(
                                   fontSize: 10
                               ),
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ],
               ),
                ATButtonV3(
                  title: model?.status?.capitalizeFirst??'',
                  padding: EdgeInsets.symmetric(horizontal: 2,vertical: 2),
                  height: 30,
                  containerWidth: 80,
                  color: getLeadStatusBgColor(model?.status??''),
                  textColor: getLeadStatusTextColor(model?.status??''),
                  titleSize: 12,
                  radius: 8,
                  onTap: () async {

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




class CallStatusController extends GetxController{

  RxList<CallLogStatusModel> callLogs = <CallLogStatusModel>[].obs;


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    callLogs.addAll([
      CallLogStatusModel(name: "Gulam Moinuddin",status: "followup",phoneNo: "81771771771",duration: "12 min",callStatus: "Connected"),
      CallLogStatusModel(name: "Zeeshan Shaikh",status: "visiting",phoneNo: "81771771771",duration: "15 min",callStatus: "Connected"),
      CallLogStatusModel(name: "Rehan Ratnagiri",status: "dropped",phoneNo: "81771771771",duration: "",callStatus: "Disconnected")
    ]);
  }


}






class CallLogStatusModel{
  String? status;
  String? name;
  String? phoneNo;
  String? duration;
  String? callStatus;

  CallLogStatusModel({
   this.name,
   this.status,
   this.duration,
    this.callStatus,
    this.phoneNo
});


}