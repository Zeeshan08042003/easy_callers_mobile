import 'dart:math';

import 'package:easy_callers_mobile/feedback/custom_dropdown.dart';
import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/custom_buttons.dart';
import '../auth/sign_up_textfield.dart';
import '../constants/utils.dart';
import '../main.dart';
import '../webservices/model/call_logs_model.dart';
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

  final controller = Get.find<CallController>();

  var selectedLeadStatus = "";
  var selectedData = "Select Date";
  TimeOfDay? selectedTime;
  TextEditingController feedbackController = TextEditingController();

  getStatusColor(String status) {
    if (status == "Connected") {
      return Colors.green.withOpacity(.2);
    } else if (status == "") {
      return Colors.white;
    } else {
      return Colors.red.withOpacity(.2);
    }
  }

  getStatusTextColor() {
    if (controller.callLog.value?.status == "Connected") {
      return Color(0xff2E8B57);
    } else {
      return Colors.red;
    }
  }

  getLeadStatusColor(String status) {
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
    if (selectedLeadStatus.isEmpty) {
      showAnimatedTopToast(
        context,
        title: "Select lead status",
        textColor: Colors.red,
      );
      return false;
    }

    // Skip other checks if status is dropped
    if (selectedLeadStatus == "dropped") {
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
    return Stack(
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
                          Obx(
                            () => styledDisplayField(
                                title: 'Call Status',
                                color: getStatusColor(
                                    controller.callLog.value?.status ?? ''),
                                textColor: getStatusTextColor(),
                                text: controller.callLog.value?.status ?? ''),
                          ),
                          Obx(
                            () => styledDisplayField(
                                title: "Call Duration",
                                text: controller.callLog.value?.duration?.toString() ??
                                    ''),
                          ),
                          CustomDropDown(
                            title: "Lead Status",
                            bgColor: selectedLeadStatus.isNotEmpty
                                ? getLeadStatusColor(selectedLeadStatus)
                                : Colors.white,
                            items: leadStatusList
                                .map((item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item.toString().capitalizeFirst ?? '',
                                        style: TextStyle(
                                            color: getLeadStatusTextColor(item),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
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
                                selectedLeadStatus = value ?? '';
                              });
                              // controller.selectedCategory.value = value.toString();
                              // // Find the selected item and set its id to categoryId
                              // final selectedItem = controller.category.firstWhere(
                              //       (item) => item.name == value,
                              // );
                              // controller.categoryId.value = selectedItem.id ?? 0;
                            },
                          ),
                          Visibility(
                            visible: selectedLeadStatus == "visiting" ||
                                selectedLeadStatus == "followup",
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 5,
                                ),
                                styledDisplayField(
                                    title: "${selectedLeadStatus.capitalizeFirst} Date",
                                    text: selectedData.isEmpty
                                        ? "Select Date"
                                        : selectedData,
                                    onTap: () {
                                      selectDate(context);
                                    }),
                                styledDisplayField(
                                    title: "${selectedLeadStatus.capitalizeFirst} Time",
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
                              textEditingController: feedbackController),
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
                                status: selectedLeadStatus,
                                leadId: widget.lead?.id ?? '',
                                callDuration: controller
                                    .convertDurationToSeconds(controller
                                            .callLog.value?.duration
                                            ?.toString() ??
                                        '')
                                    .toString(),
                                notes: feedbackController.text);
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
                    await controller.makeCall(phoneNumber: controller.callLog.value?.number,lead: widget.lead,fromFeedbackScreen: true);
                    print(controller.callLog.value?.number);
                    print(controller.callLog.value?.time);
                    print(controller.callLog.value?.duration);
                    print(controller.callLog.value?.type);
                    print(controller.callLog.value?.status);
                    // await controller.makeCall(phoneNumber: log?.number ?? "");
                    // No need to navigate — data is reactive and will update UI
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
