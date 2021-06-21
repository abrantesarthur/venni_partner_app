import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class HorizontalBar extends StatelessWidget {
  final String title;
  final String value;
  final double fill;

  HorizontalBar({
    @required this.title,
    @required this.value,
    @required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Container(
          width: screenWidth / 6,
          child: Text(
            title,
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
              ? screenWidth / 2
              : fill < 0
                  ? 0
                  : fill * screenWidth / 2,
          color: AppColor.primaryPink,
        ),
        Container(
          height: screenHeight / 100,
          width: fill > 1
              ? 0
              : fill < 0
                  ? screenWidth / 2
                  : (1 - fill) * screenWidth / 2,
          color: Colors.black.withOpacity(0.15),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
