import 'package:flutter/material.dart';

class CustomColors{
  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

class Constants{
  static const EMAIL_REGEX =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  static const PASS_REGEX1 = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{7,}$';

  static const TextStyle constantStyle = TextStyle(
    fontSize: 12,
  );
}

class AssetUtils{
  static const String imageDir = "resources/images";

  static const String leads = "$imageDir/leads.svg";
  static const String phone = "$imageDir/phone.svg";
  static const String email = "$imageDir/email.svg";
  static const String singleLead = "$imageDir/single_lead.svg";
}