import 'dart:ui';
import 'package:flutter/material.dart';

void showAnimatedTopToast(
    BuildContext context, {
      required String title,
      String? subtitle,
      Color? textColor,
      Duration duration = const Duration(seconds: 2),
    }) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry; // Use `late` instead of referencing before assignment

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _TopToastWidget(
        title: title,
        textColor: textColor ?? Colors.black87,
        subtitle: subtitle??'',
        duration: duration,
        onDismissed: () {
          overlayEntry.remove(); // Now valid, since overlayEntry is declared
        },
      );
    },
  );

  overlay.insert(overlayEntry);
}

class _TopToastWidget extends StatefulWidget {
  final String title;
  final Color textColor;
  final String subtitle;
  final VoidCallback onDismissed;
  final Duration duration;

  const _TopToastWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onDismissed,
    required this.duration, required this.textColor,
  }) : super(key: key);

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animation = Tween<Offset>(
      begin: Offset(0, -1), // Off-screen above
      end: Offset(0, 0),    // Slide to top
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      await _controller.reverse(); // Slide up to hide
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _animation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10)
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black54, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.textColor ?? Colors.black87,
                              ),
                            ),
                            Visibility(
                              visible:widget.subtitle.isNotEmpty,
                              child: Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:widget.textColor ?? Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
