import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropDown extends StatelessWidget {
  CustomDropDown({
    super.key,
    this.selectedValue,
    this.text,
    this.title,
    this.onSaved,
    this.onChanged,
    this.items,
    this.validator, this.bgColor,
  });

  String? selectedValue;
  final String? text;
  final String? title;
  final Color? bgColor;
  final void Function(String?)? onSaved;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final List<DropdownMenuItem<String>>? items;

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFFD6D6D6); // Matches styledDisplayField
    final textColor = Colors.black;
    final borderRadius = BorderRadius.circular(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title??'',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        DropdownButtonFormField2<String>(
          isExpanded: true,
          iconStyleData: IconStyleData(
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_drop_down),
            ),
            iconEnabledColor: Colors.transparent,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            filled: true,
            fillColor: bgColor,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: selectedValue?.isNotEmpty == true ? Colors.black : textColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: selectedValue?.isNotEmpty == true ? Colors.black : textColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: selectedValue?.isNotEmpty == true ? Colors.black : textColor),
            ),
          ),
          hint: Text(
            text ?? '',
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          items: items,
          value: selectedValue,
          validator: validator,
          onChanged: onChanged,
          onSaved: onSaved,
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: borderColor),
            ),
            elevation: 2,
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        SizedBox(height: 13,)
      ],
    );
  }
}
