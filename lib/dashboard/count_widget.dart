import 'package:flutter/material.dart';

class CountContainer extends StatelessWidget {
  const CountContainer({
    super.key,
    required this.title,
    required this.days,
    this.widget, this.onTap,
  });

  final String title;
  final String days;
  final Widget? widget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xff000000),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xff000000)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevents extra vertical space
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              Text(
                days,
                style: TextStyle(
                  color: Color(0xffffffff),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4), // Optional spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: Color(0xffffffff),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
