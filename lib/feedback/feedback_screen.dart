import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../auth/custom_buttons.dart';
import '../auth/sign_up_textfield.dart';
import '../constants/utils.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 2,
        backgroundColor: Colors.grey.shade100,
        elevation: 2,
        leading: Icon(Icons.arrow_back),
        title: Text(
          "Feedback",
          style: TextStyle(),
        ),
      ),
      body: SafeArea(
          child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      SizedBox(height: 20),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            border: Border.all(color: Color(0xff000000)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  AssetUtils.singleLead,
                                  height: 20,
                                  width: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Zeeshan",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                )
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                SvgPicture.asset(AssetUtils.phone,
                                    height: 20, width: 20),
                                SizedBox(width: 5),
                                Text("7666611031"),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                SvgPicture.asset(AssetUtils.email,
                                    height: 20, width: 20),
                                SizedBox(width: 5),
                                Text(
                                  "zeeshan@gmail.com",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ATButtonV3(
                                    title: "WhatsApp",
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    height: 35,
                                    containerWidth: 95,
                                    color: Color(0xff2D201C),
                                    textColor: CustomColors.white,
                                    titleSize: 14,
                                    radius: 10,
                                    onTap: () async {
                                      // controller.sendWhatsAppMessage(["9920111031"],"Hello");
                                      // controller.sendBulkWhatsAppMessages(["9920111031"],"Hello from easy callers");
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: ATButtonV3(
                                    title: "Call again",
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    height: 35,
                                    containerWidth: 95,
                                    color: Color(0xff2D201C),
                                    textColor: CustomColors.white,
                                    titleSize: 14,
                                    radius: 10,
                                    onTap: () async {
                                      // Get.to(() => FeedbackScreen());
                                    },
                                  ),
                                ),

                                // ATButtonV3(
                                //   title: "SMS",
                                //   padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                                //   height: 35,
                                //   containerWidth: 95,
                                //   color: Color(0xff2D201C),
                                //   textColor: CustomColors.white,
                                //   titleSize: 14,
                                //   radius: 10,
                                //   onTap: () async {
                                //
                                //   },
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      feedbackTextField(title: "Call Status"),
                      feedbackTextField(title: "Call Duration"),
                      feedbackTextField(title: "Lead Status"),
                      feedbackTextField(title: "Feedback", isFeedback: true),
                    ]),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
            child: ATButtonV3(
              title: "Submit",
              padding:
              EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              color: Color(0xff2D201C),
              textColor: CustomColors.white,
              titleSize: 16,
              radius: 8,
              onTap: () async {},
            ),
          )
        ],
      )),
    );
  }

  Widget feedbackTextField({
    required String title,
    bool isFeedback = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5),
        Sign_Up_TextField(
          errorMessage: "",
          radius: BorderRadius.circular(5),
          enableBorderColor: Color(0xffD6D6D6),
          focusedBorderColor: CustomColors.black,
          labelTextColor: CustomColors.black,
          cursorColor: CustomColors.black,
          maxLines: isFeedback ? null : 1,
          // allow unlimited growth only for feedback
          minLines: isFeedback ? 4 : 1,
          // default visible height: 4 lines vs 1
          expands: false,
          // keep false for proper size control
          textInputAction:
              isFeedback ? TextInputAction.newline : TextInputAction.done,
          keyBoardType:
              isFeedback ? TextInputType.multiline : TextInputType.text,
          onChanged: (txt) {
            // controller.feedback(txt);
          },
        ),
      ],
    );
  }
}
