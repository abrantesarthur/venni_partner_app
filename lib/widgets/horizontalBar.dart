import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class HorizontalBar extends StatelessWidget {
  final String leftText;
  final Widget leftWidget;
  final String rightText;
  final double fill;
  final double centerWidth;

  HorizontalBar({
    this.leftText,
    @required this.rightText,
    @required this.fill,
    this.leftWidget,
    this.centerWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: leftWidget ??
              Text(
                leftText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
