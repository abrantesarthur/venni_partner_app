import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class Warning extends StatelessWidget {
  final String message;
  final Function onTapCallback;
  final Color color;
  final double fontSize;

  Warning(
      {@required this.message, this.onTapCallback, this.color, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTapCallback(context),
      child: Text(
        message,
        style: TextStyle(
          color: color ??
              (onTapCallback != null
                  ? AppColor.secondaryPurple
                  : AppColor.secondaryYellow),
          fontSize: fontSize ?? 14,
        ),
      ),
    );
  }
}
