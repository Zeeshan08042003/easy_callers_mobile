import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:get/get.dart';

import '../webservices/webservices.dart';

class DashBoardController extends GetxController{

  RxList<Leads> visitor = <Leads>[].obs;
  RxList<Leads> totalLead = <Leads>[].obs;
  Rx<LeadData?> leadModel = Rx<LeadData?>(null);
  RxList<Leads> dailyFollowUp = <Leads>[].obs;
  RxBool isLoading = false.obs;


  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    isLoading(true);
    await getTotalLeads(status: 'visiting');
    await getTotalLeads(status: 'followup');
    if(visitor.isEmpty && dailyFollowUp.isEmpty){
      double screenHeight = Get.mediaQuery.size.height;
      int estimatedItemHeight = 110; // Adjust based on your actual layout
      int perPage = (screenHeight / estimatedItemHeight).ceil();

      await getTotalLeads(status: 'assigned', perPage: perPage);
      // await getTotalLeads(status: 'assigned',perPage: 10);
    }else{
      await getTotalLeads(status: 'assigned');
    }
    isLoading(false);
  }

  getTotalLeads({String? status,int? perPage}) async {
      final resp = await WebService().getLeadData(
        status: status,
        page: 1,
        perPage: perPage ?? 5,
      );
      final hits = resp.payload?.data?.leads?.toList() ?? [];
      final hit = resp.payload?.data;
      if(status == "assigned"){
        totalLead(hits);
        leadModel(hit);
        print("total leads : ${leadModel.value?.total}");
      }else if(status == "visiting"){
        visitor(hits);
      }else if(status == "followup"){
        dailyFollowUp(hits);
      }
  }


  String formatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString).toLocal();
    return "${dateTime.day} ${_monthAbbreviation(dateTime.month)}";
  }

  String formatTime(String isoString) {
    DateTime dateTime = DateTime.parse(isoString).toLocal();

    int hour = dateTime.hour;
    String period = hour >= 12 ? "PM" : "AM";

    // Convert 24-hour to 12-hour format
    hour = hour % 12;
    if (hour == 0) hour = 12;

    String minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  String _monthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  formattedDateTime(String string){
    return "${formatDate(string)}, ${formatTime(string)}";
  }
}