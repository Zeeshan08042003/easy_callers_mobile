import 'package:flutter/material.dart';
class ATButtonV3 extends StatelessWidget {
  ATButtonV3(
      {required this.title,
        this.onTap,
        this.height = 48.0,
        this.color = const Color(0xFF009000),
        this.borderColor,
        this.icon,
        this.defaultPadding,
        this.textColor,
        this.firstIcon,
        this.containerPadding,
        this.radius,
        this.width,
        this.enabled = true,
        this.titleSize,
        this.containerWidth, this.isLoading = false, this.loaderColor, this.padding});

  final double? width;
  final double? titleSize;
  final String title;
  final bool? isLoading;
  final VoidCallback? onTap;
  final double? height;
  final Color? color;
  final Color? loaderColor;
  final Color? borderColor;
  final Widget? icon;
  final Widget? firstIcon;
  final bool? defaultPadding;
  final bool? containerPadding;
  final Color? textColor;
  final double? radius;
  final bool enabled;
  final double? containerWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (enabled && onTap != null) onTap!();
      },
      child: Container(
        width: containerWidth,
        padding:padding ?? EdgeInsets.symmetric(
            horizontal: containerPadding == true ? 30 : 0),
        height: height,
        decoration: BoxDecoration(
          // color: widget.color ?? Color(0xFFA1A3AA),
            color: enabled ? color : Color(0xFFA1A3AA),
            borderRadius: BorderRadius.circular(radius ?? 4.0),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: borderColor == null ? 0.0 : 1,
            )),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (firstIcon != null) firstIcon!,
              Container(
                padding: EdgeInsets.only(
                    right:
                    defaultPadding == true ? width ?? 14 : 0,
                    left: defaultPadding == true ? 10 : 0),
                child: isLoading == false ? Text(
                  title,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize ?? 18.0,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Color.fromRGBO(109, 109, 109, 1),
                  ),
                ) : Center(child: CircularProgressIndicator(color: loaderColor ?? Color(0xffFFFFFFF),),),
              ),
              if (icon != null) icon!,
            ],
          ),
        ),
      ),
    );
  }
}