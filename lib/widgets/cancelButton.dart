import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  CancelButton({@required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
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
          color: AppColor.primaryPink,
          size: 28,
        ),
      ),
    );
  }
}
