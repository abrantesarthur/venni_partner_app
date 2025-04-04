import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class HorizontalBar extends StatelessWidget {
  final String? leftText;
  final Widget? leftWidget;
  final String rightText;
  final double fill;
  final double? centerWidth;
  final int? leftFlex;
  final int? rightFlex;

  HorizontalBar({
    this.leftText,
    required this.rightText,
    required this.fill,
    this.leftWidget,
    this.centerWidth,
    this.leftFlex,
    this.rightFlex,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          flex: leftFlex ?? 1,
          child: leftWidget ?? (leftText != null ? Text(
                leftText!,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ) : Container()),
        ),
        Container(
          height: screenHeight / 100,
          width: fill > 1
              ? (centerWidth ?? screenWidth / 2)
              : fill < 0
                  ? 0
                  : fill * (centerWidth ?? screenWidth / 2),
          color: AppColor.primaryPink,
        ),
        Container(
          height: screenHeight / 100,
          width: fill > 1
              ? 0
              : fill < 0
                  ? (centerWidth ?? screenWidth / 2)
                  : (1 - fill) * (centerWidth ?? screenWidth / 2),
          color: Colors.black.withOpacity(0.15),
        ),
        Expanded(
          flex: rightFlex ?? 1,
          child: Text(
            rightText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
