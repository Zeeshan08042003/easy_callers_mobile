import 'package:flutter/material.dart';
import '../constants/utils.dart';

class Sign_Up_TextField extends StatefulWidget {
  const Sign_Up_TextField(
      {super.key,
        this.labelTextColor,
        this.enableBorderColor,
        this.focusedBorderColor,
        this.labelText,
        this.cursorColor,
        this.controller,
        this.validationLogic,
        this.suffixIcon,
        required this.errorMessage,
        this.onChanged,
        this.prefixIcon, this.hintText, this.hintLabelStyle, this.keyBoardType});
  final Color? labelTextColor;
  final String errorMessage;
  final String? hintText;
  final TextInputType? keyBoardType;
  final TextStyle? hintLabelStyle;
  final Color? enableBorderColor;
  final Color? cursorColor;
  final Color? focusedBorderColor;
  final String? labelText;
  final TextEditingController? controller;
  final String? Function(String? txt)? validationLogic;
  final void Function(String)? onChanged;
  final bool? suffixIcon;
  final Widget? prefixIcon;

  @override
  State<Sign_Up_TextField> createState() => _Sign_Up_TextFieldState();
}

class _Sign_Up_TextFieldState extends State<Sign_Up_TextField> {
  bool isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    // final registrationController = Get.put(RegistrationController());
    return TextFormField(
      controller: widget.controller,
      cursorColor: widget.cursorColor,
      validator: (value) {
        if (widget.validationLogic != null) {
          // focusNode.requestFocus();
          return widget.validationLogic!(value);
        }
        return null;
      },
      onChanged: widget.onChanged,
      keyboardType: widget.keyBoardType ?? TextInputType.text,
      obscureText: widget.suffixIcon == true ? !isPasswordVisible : false,
      decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText ?? "",
          hintStyle: widget.hintLabelStyle ?? TextStyle(),
          // labelText: "Enter Your Name",
          label: Text(
            widget.labelText ?? "",
            style: TextStyle(
                fontSize: 16,
                color: widget.labelTextColor,
                fontWeight: FontWeight.w400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
                color: widget.focusedBorderColor ?? CustomColors.black),
          ),
          hoverColor: CustomColors.black,
          helperText: widget.errorMessage,
          helperStyle: TextStyle(
              color: Color(0xffFF0000),
              fontWeight: FontWeight.w200,
              fontSize: 12),
          suffixIcon: widget.suffixIcon == true
              ? GestureDetector(
            onTap: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
            child: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: widget.cursorColor,
            ),
          )
              : SizedBox(),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
                color: widget.enableBorderColor ?? CustomColors.black),
          ),
          prefixIcon: widget.prefixIcon),
    );
  }
}

// if (txt == null || txt.isEmpty == true) {
// return "Required";
// }
// return null;
// },

// if (formKey.currentState?.validate() == true) {}