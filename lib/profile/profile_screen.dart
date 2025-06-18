import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      appBar: AppBar(
        backgroundColor: Color(0xff000000),
        titleSpacing: 2,
        leading: Icon(Icons.arrow_back,color: Color(0xffFFFFFF),),
        title: Text("Profile",style: TextStyle(color: Color(0xffFFFFFF)),),
      ),
      body: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 20,bottom: 10),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Color(0xff000000),
                    borderRadius: BorderRadius.circular(100)
                  ),
                  child: Center(
                    child: Text("ZS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xffFFFFFF),
                      fontSize: 50,
                      fontWeight: FontWeight.w500
                    ),
                    ),
                  ),
                ),
              ),
              Text("Zeeshan Shaikh",
              style: TextStyle(
                fontWeight: FontWeight.w500
              ),
              ),
              Text("zeemed2003@gmail.com",
              style: TextStyle(
                fontWeight: FontWeight.w500
              ),
              )
            ],
          ),
          SizedBox(height: 16,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xff000000))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InnerText(icon: Icons.description_outlined,title: "Script",),
                InnerText(icon: Icons.description_outlined,title: "Script",),
                InnerText(icon: Icons.description_outlined,title: "Script",),
                InnerText(icon: Icons.description_outlined,title: "Script",),
                InnerText(icon: Icons.description_outlined,title: "Script",),
                InnerText(icon: Icons.description_outlined,title: "Script",isLast: true,),
              ],
            ),
          )
        ],
      ),
    );
  }
}


class InnerText extends StatelessWidget {
  InnerText({super.key,this.title,this.icon,this.isLast = false});
  IconData? icon;
  String? title;
  bool? isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 5),
          child: Row(
            children: [
              Icon(icon,size: 24),
              SizedBox(width: 10,),
              Text(title??'',style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16
              ),)
            ],
          ),
        ),
        isLast == true ? SizedBox.shrink() : Divider(thickness: 2,)
      ],
    );
  }
}
