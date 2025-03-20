import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  CancelButton({
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(3, 3),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.clear,
          color: iconColor ?? AppColor.primaryPink,
          size: 28,
        ),
      ),
    );
  }
}
