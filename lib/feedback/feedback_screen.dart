import 'dart:io';
import 'package:easy_callers_mobile/feedback/custom_dropdown.dart';
import 'package:easy_callers_mobile/profile/script_controller.dart';
import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../auth/custom_buttons.dart';
import '../auth/sign_up_textfield.dart';
import '../constants/utils.dart';
import '../controller/call_controller.dart';
import '../widget/toast_widget.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.lead,
  });

  final Leads lead;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<String> leadStatusList = ["dropped", "followup", "visiting"];
  List<String> callStatusList = ["Connected", "Decline or Failed"];

  final controller = Get.find<CallController>();
  String callStatus = "";
  var isCallStatusUpdated = false;

  var leadStatus = "";
  var selectedData = "Select Date";
  TimeOfDay? selectedTime;
  TextEditingController feedbackController = TextEditingController();

  getStatusColor(String status) {
    print(status);
    if (status == "Connected") {
      return Colors.green.withOpacity(.2);
    } else if (status == "") {
      return Colors.white;
    } else {
      return Colors.red.withOpacity(.2);
    }
  }

  @override
  void initState() {
    super.initState();
    updateDateTime();
    final status = widget.lead.status ?? '';
    if (status != 'assigned') {
      leadStatus = status;
    } else {
      leadStatus = ''; // keep it empty
    }


  }

  updateDateTime() {
    final updatedAtStr = widget.lead.meetDatetime;

    // ✅ Check if callLogs is not null AND not empty before accessing elements
    final hasCallLogs = widget.lead.callLogs != null && widget.lead.callLogs!.isNotEmpty;

    if (updatedAtStr != null && updatedAtStr.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(updatedAtStr).toLocal();

        setState(() {
          selectedData = formatDate(parsedDate);
          selectedTime = TimeOfDay(hour: parsedDate.hour, minute: parsedDate.minute);

          if (hasCallLogs) {
            final existingFeedback = widget.lead.callLogs!.last.notes;
            if (existingFeedback != null && existingFeedback.isNotEmpty) {
              feedbackController.text = existingFeedback;
            }
          }
        });
      } catch (e) {
        print("Invalid updatedAt format: $updatedAtStr");
      }
    }
  }

  getStatusTextColor(String? status) {
    if (status == "Connected") {
      return Color(0xff2E8B57);
    } else {
      return Colors.red;
    }
  }

  Color getLeadStatusColor(String? status) {
    if (status == "visiting") {
      return Colors.green.withOpacity(.2);
    } else if (status == "followup") {
      return Colors.orange.withOpacity(.2);
    } else if (status == "dropped"){
      return Colors.red.withOpacity(.2);
    }else{
      return Colors.white;
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.black,
            colorScheme: ColorScheme.light(
              primary: Colors.black, // header, selected date
              onPrimary: Colors.white, // text color on primary
              onSurface: Colors.black, // text color
              surface: Colors.white, // background
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Use picked date
      print("Selected date: $picked");
      setState(() {
        var formatedPicked = formatDate(picked);
        selectedData = formatedPicked;
      });
    }
  }

  pickTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black,
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Colors.black, // Selected field background
              hourMinuteTextColor: Colors.white, // Selected field text color
              dialHandColor: Colors.black, // Hand of the clock
              dialBackgroundColor: Colors.grey.shade200, // Clock face
              entryModeIconColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {

        selectedTime = time;
        print(selectedTime);
      });
    }
  }

  String formatToSimpleTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime); // e.g. 5 PM, 2 PM
  }

  bool checkData() {
    if (leadStatus.isEmpty) {
      showAnimatedTopToast(
        context,
        title: "Select lead status",
        textColor: Colors.red,
      );
      return false;
    }

    // Skip other checks if status is dropped
    if (leadStatus == "dropped") {
      return true;
    }

    if (selectedData.isEmpty || selectedTime == null) {
      showAnimatedTopToast(
        context,
        title: "Select date and time",
        textColor: Colors.red,
      );
      return false;
    }

    if (feedbackController.text.isEmpty) {
      showAnimatedTopToast(
        context,
        title: "Enter feedback",
        textColor: Colors.red,
      );
      return false;
    }

    return true; // All checks passed
  }

  String formatDate(DateTime date) {
    return DateFormat('d MMMM y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
       onWillPop: () async {
         Get.dialog(
           DeleteConformation(
             title: "Are you sure you want to go back?",
             titleFontSize: 20,
             subtitle: "Getting back you will loose your lead data.",
             onCancel: (){
               Get.back();
             },
             onTap: (){
              Get.back();
              Get.back();
             },
             loaderHeight: 20,
             loaderWidth: 20,
             bgColor: Colors.black,
             isLoading: false,
             textColor: Colors.white,
             btnText: "Yes",
             padding: EdgeInsets.symmetric(vertical: 20,horizontal: 16),
           )
         );
         return true;
       },
    child: Stack(
        children: [
          Obx(
          ()=> Visibility(
              visible: controller.isLoading.isFalse,
              child: Scaffold(
                backgroundColor: Colors.grey.shade100,
                appBar: AppBar(
                  titleSpacing: 2,
                  backgroundColor: Colors.grey.shade100,
                  elevation: 2,
                  leading: BackButton(),
                  title: const Text("Feedback"),
                ),
                body: SafeArea(
                    child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildLeadInfoCard(),
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                if (Platform.isIOS && !isCallStatusUpdated)
                                  CustomDropDown(
                              title: "Call Status",
                              isAutoFocus: true,
                              bgColor: callStatus.isNotEmpty == true
                                  ? getStatusColor(callStatus ?? "")
                                  : Colors.white,
                              items: callStatusList
                                  .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item.toString().capitalizeFirst ?? '',
                                  style: TextStyle(
                                    color: getStatusTextColor(item),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                                  .toList(),
                              text: "",
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select category';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  callStatus = value ?? '';
                                  isCallStatusUpdated = true;
                                });
                              },
                            ) else GestureDetector(
                                  onTap: (){
                                    showAnimatedTopToast(context, title: "Call Status Updated", subtitle: "You can only update call status once.");
                                  },
                              child: styledDisplayField(
                                      title: 'Call Status',
                                      color: getStatusColor(callStatus ??''),
                                      textColor: getStatusTextColor(callStatus),
                                      text: callStatus ??''),
                            ),
                                Visibility(
                                  visible: Platform.isAndroid,
                                  child: Obx(
                                        () => styledDisplayField(
                                        title: 'Call Status',
                                        color: getStatusColor(
                                            controller.callLog.value?.status ?? ''),
                                        textColor: getStatusTextColor(controller.callLog.value?.status ?? ''),
                                        text: controller.callLog.value?.status ?? ''),
                                  ),
                                ),
                              ],
                            ),

                            Stack(
                              children: [
                                if (Platform.isIOS)
                                  styledDisplayField(
                                    title: "Call Duration",
                                    text: callStatus.isEmpty
                                        ? ''
                                        : callStatus == "Connected"
                                        ? controller.callLog.value?.duration?.toString() ?? ''
                                        : "00:00:00",
                                  )
                                else
                                  Obx(
                                        () => styledDisplayField(
                                      title: "Call Duration",
                                      text: controller.callLog.value?.duration?.toString() ?? '',
                                    ),
                                  ),
                              ],
                            ),

                            CustomDropDown(
                              title: "Lead Status",
                              bgColor: getLeadStatusColor(leadStatus),
                              selectedValue: leadStatus.isNotEmpty ? leadStatus : null, // ✅ null means no selection
                              items: leadStatusList
                                  .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item.capitalizeFirst ?? '',
                                  style: TextStyle(
                                    color: getLeadStatusTextColor(item),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                                  .toList(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select category';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  leadStatus = value ?? '';
                                });
                              },
                            ),
                            Visibility(
                              visible: leadStatus == "visiting" ||
                                  leadStatus == "followup",
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 5,
                                  ),
                                  styledDisplayField(
                                      title: "${leadStatus.capitalizeFirst} Date",
                                      text: selectedData.isEmpty
                                          ? "Select Date"
                                          : selectedData,
                                      onTap: () {
                                        selectDate(context);
                                      }),
                                  styledDisplayField(
                                      title: "${leadStatus.capitalizeFirst} Time",
                                      text: selectedTime != null
                                          ? formatToSimpleTime(selectedTime!)
                                          : "Select Time",
                                      onTap: () {
                                        pickTime(context);
                                      }),
                                ],
                              ),
                            ),
                            feedbackTextField(
                                title: "Feedback",
                                isFeedback: true,
                                initialValue: feedbackController.text,
                                textEditingController: feedbackController
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Obx(
                        () => ATButtonV3(
                          title: "Submit",
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          color: const Color(0xff2D201C),
                          textColor: CustomColors.white,
                          titleSize: 16,
                          isLoading: controller.isSubmittingData.value,
                          loaderWidth: 20,
                          loaderHeight: 20,
                          radius: 8,
                          onTap: () async {
                            print(controller.callLog.value?.duration ?? '');
                            var status = await checkData();
                            if (status == true) {
                              await controller.submitData(
                                  leadStatus: leadStatus,
                                  status: widget.lead.status??'',
                                  leadId: widget.lead?.id ?? '',
                                  callDuration: controller
                                      .convertDurationToSeconds(controller
                                              .callLog.value?.duration
                                              ?.toString() ??
                                          '')
                                      .toString(),
                                  notes: feedbackController.text,
                                  callStatus: callStatus == "Connected" ? "connected" : "not_connected",
                                  date: selectedData,
                                time: selectedTime??TimeOfDay(hour: 0, minute: 0)
                              );
                            }
                          },
                        ),
                      ),
                    )
                  ],
                )),
              ),
            ),
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

  Widget _buildLeadInfoCard() {
    var controller = Get.find<CallController>();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff000000)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetUtils.singleLead, height: 20, width: 20),
              const SizedBox(width: 5),
              Text(widget.lead?.name??'',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset(AssetUtils.phone, height: 20, width: 20),
              const SizedBox(width: 5),
              Text(widget.lead?.phone??'' ?? "Not available"),
            ],
          ),
          const SizedBox(height: 6),
          Visibility(
            visible: widget.lead?.email?.isNotEmpty == true,
            child: Row(
              children: [
                SvgPicture.asset(AssetUtils.email, height: 20, width: 20),
                const SizedBox(width: 5),
                Text(widget.lead?.email??'', overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ATButtonV3(
                  title: "WhatsApp",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  height: 35,
                  containerWidth: 95,
                  color: const Color(0xff2D201C),
                  textColor: CustomColors.white,
                  titleSize: 14,
                  radius: 10,
                  onTap: () {
                    controller.sendWhatsAppMessage([widget.lead?.phone??''], "msg");
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ATButtonV3(
                  title: "Call again",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  height: 35,
                  containerWidth: 95,
                  color: const Color(0xff2D201C),
                  textColor: CustomColors.white,
                  titleSize: 14,
                  radius: 10,
                  onTap: () async {
                    // await controller.makeCall(phoneNumber: controller.callLog.value?.number,lead: widget.lead,fromFeedbackScreen: true);
                    if(Platform.isIOS){
                      setState(() {
                        callStatus = "";
                        isCallStatusUpdated = false;
                      });

                      print(isCallStatusUpdated);
                      print(callStatus);
                      await controller.makeCallForIos(phoneNumber:controller.callLog.value?.number??'',lead: widget.lead,fromFeedbackScreen: true);
                    }else{
                      await controller.makeCall(
                          phoneNumber: controller.callLog.value?.number, lead: widget.lead,fromFeedbackScreen: true);
                    }
                    print(controller.callLog.value?.number);
                    print(controller.callLog.value?.time);
                    print(controller.callLog.value?.duration);
                    print(controller.callLog.value?.type);
                    print(controller.callLog.value?.status);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  final focusNode = FocusNode();

  Widget feedbackTextField(
      {required String title,
      bool isFeedback = false,
      String? initialValue,
      TextEditingController? textEditingController}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Sign_Up_TextField(
          initialValue:
              textEditingController == null ? (initialValue ?? "") : null,
          errorMessage: "",
          fillColor: focusNode.hasFocus == true ? Colors.white : Colors.transparent,
          controller: textEditingController,
          radius: BorderRadius.circular(5),
          enableBorderColor: const Color(0xffD6D6D6),
          focusedBorderColor: CustomColors.black,
          labelTextColor: CustomColors.black,
          cursorColor: CustomColors.black,
          maxLines: isFeedback ? null : 1,
          minLines: isFeedback ? 4 : 1,
          expands: false,
          textInputAction:
              isFeedback ? TextInputAction.newline : TextInputAction.done,
          keyBoardType:
              isFeedback ? TextInputType.multiline : TextInputType.text,
          onChanged: (txt) {},
        ),
        const SizedBox(height: 0),
      ],
    );
  }

  Widget styledDisplayField({
    required String title,
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: color ?? Colors.white,
              border: Border.all(
                  color:
                      text.isNotEmpty ? Color(0xff000000) : Color(0xffD6D6D6)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: TextStyle(
                      color: textColor ?? CustomColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 15,
        )
      ],
    );
  }
}



class FeedbackController extends GetxController {
  // Dependencies
  final callController = Get.find<CallController>();

  // Dropdown lists
  final leadStatusList = ["dropped", "followup", "visiting"];
  final callStatusList = ["Connected", "Decline or Failed"];

  // Reactive variables
  var callStatus = "".obs;
  var isCallStatusUpdated = false.obs;
  var leadStatus = "".obs;
  var selectedDate = "Select Date".obs;
  var selectedTime = Rxn<TimeOfDay>();
  var feedbackText = "".obs;

  // Colors & helpers
  Color getStatusColor(String status) {
    if (status == "Connected") {
      return Colors.green.withOpacity(.2);
    } else if (status == "") {
      return Colors.white;
    } else {
      return Colors.red.withOpacity(.2);
    }
  }

  Color getStatusTextColor(String? status) {
    if (status == "Connected") {
      return const Color(0xff2E8B57);
    } else {
      return Colors.red;
    }
  }

  Color getLeadStatusColor(String status) {
    if (status == "visiting") {
      return Colors.green.withOpacity(.2);
    } else if (status == "followup") {
      return Colors.orange.withOpacity(.2);
    } else {
      return Colors.red.withOpacity(.2);
    }
  }

  Color getLeadStatusTextColor(String status) {
    if (status == "visiting") {
      return const Color(0xff2E8B57);
    } else if (status == "followup") {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('d MMMM y').format(date);
  }

  String formatToSimpleTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
    DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      selectedDate.value = formatDate(picked);
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
    );

    if (time != null) {
      selectedTime.value = time;
    }
  }

  bool validateData(BuildContext context) {
    if (leadStatus.value.isEmpty) {
      showAnimatedTopToast(context, title: "Select lead status", textColor: Colors.red);
      return false;
    }
    if (leadStatus.value == "dropped") return true;
    if (selectedDate.value.isEmpty || selectedTime.value == null) {
      showAnimatedTopToast(context, title: "Select date and time", textColor: Colors.red);
      return false;
    }
    if (feedbackText.value.isEmpty) {
      showAnimatedTopToast(context, title: "Enter feedback", textColor: Colors.red);
      return false;
    }
    return true;
  }
}
