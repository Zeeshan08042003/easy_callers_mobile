import 'package:easy_callers_mobile/auth/custom_buttons.dart';
import 'package:easy_callers_mobile/profile/call_logs_screen.dart';
import 'package:easy_callers_mobile/profile/script_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      appBar: AppBar(
        titleSpacing: 2,
        backgroundColor: Colors.grey.shade100,
        elevation: 2,
        leading: GestureDetector(
            onTap: (){
              Get.back();
            },
            child: Icon(Icons.arrow_back)),
        title: Text("Profile"),

      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24,),
                  UserDetail(),
                  SizedBox(height: 24,),
                  InnerText(icon: Icons.description_outlined,title: "Script",onTap: (){Get.to(() => ScriptScreen());},),
                  InnerText(icon: Icons.call_made_outlined,title: "Call Logs",onTap: (){Get.to(()=> CallLogsScreen());},),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 30,top: 20),
            child: InnerText(icon: Icons.logout,title: "Logout",isLast: true,
            onTap: (){
              Get.dialog(Padding(
                padding: const EdgeInsets.all(20),
                child: LogoutPrompt(),
              ));
            },
            ),
          )
        ],
      ),
    );
  }
}


class InnerText extends StatelessWidget {
  InnerText({super.key,this.title,this.icon,this.isLast = false,this.onTap});
  IconData? icon;
  String? title;
  bool? isLast;
  VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // 👈 shadow won't show with fully transparent color
          // border: Border.all(color: Color(0xff000000).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(10),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.2),
          //     spreadRadius: 1,
          //     blurRadius: 6,
          //     offset: Offset(0, 3), // moves shadow down
          //   ),
          // ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  SizedBox(width: 10),
                  Text(
                    title ?? '',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              isLast == true ? SizedBox.shrink() :Icon(Icons.arrow_forward_ios_rounded,size: 16,)
            ],
          ),
        ),
      ),
    );
  }
}


class UserDetail extends StatelessWidget {
  const UserDetail({super.key});

  Future<String> getFirstLetters() async {
    var pref = await SharedPreferences.getInstance();
    var fullName = pref.getString("name") ?? "";
    var initials = fullName
        .split(" ")
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return initials;
  }

  Future<String?> getName() async {
    var pref = await SharedPreferences.getInstance();
    return pref.getString("name");
  }

  Future<String?> getEmail() async {
    var pref = await SharedPreferences.getInstance();
    return pref.getString("email");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([getFirstLetters(), getName(), getEmail()]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text("Error loading user details");
        } else {
          String initials = snapshot.data![0] ?? '';
          String name = snapshot.data![1] ?? '';
          String email = snapshot.data![2] ?? '';

          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200, // background color
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), // soft shadow color
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4), // shadow position: slightly downward
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        textAlign: TextAlign.center,
                        style:  TextStyle(
                          color: Color(0xff000000).withOpacity(.8),
                          fontSize: 50,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}




class LogoutPrompt extends StatefulWidget {
  @override
  State<LogoutPrompt> createState() => _LogoutPromptState();
}

class _LogoutPromptState extends State<LogoutPrompt> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
            child: Container(
                constraints: BoxConstraints(
                  minWidth: 300,
                  maxWidth: 500,
                ), // Width is constrained, height will be according to content
                padding:
                EdgeInsets.all(16), // Add padding for a better appearance
                decoration: BoxDecoration(
                  color: Colors.white, // Background color for the dialog
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attention!',
                            style: TextStyle(
                              fontSize: 27.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            child: Icon(Icons.close, color: Colors.grey),
                            onTap: () {
                              Get.back();
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Text(
                        'Do you want to log out?',
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Color(0xFF9D9FA6),
                        ),
                      ),
                      SizedBox(
                        height: 32.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ATButtonV3(
                              title: "Cancel",
                              color: Color(0xfffafafa),
                              defaultPadding: true,
                              height: 40,
                              textColor: Color(0xff000000),
                              onTap: () async {
                                Get.back();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 24.0,
                          ),
                          Expanded(
                            child: ATButtonV3(
                              title: "logout",
                              color: Colors.red,
                              isLoading: isLoading,
                              defaultPadding: true,
                              radius: 5,
                              height: 40,
                              textColor: Color(0xffffffff),
                              onTap: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                                await prefs.clear();
                                Get.offAll(() => LoginScreen());
                                setState(() {
                                  isLoading = false;
                                });
                              },
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ))),
      ],
    );
  }
}
