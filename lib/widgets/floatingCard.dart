import 'package:flutter/material.dart';

class FloatingCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPadding;
  final double rightPadding;
  final double borderRadius;
  final double topPadding;
  final double bottomPadding;
  final double elevation;
  final Color color;

  FloatingCard({
    this.width,
    @required this.child,
    this.leftMargin,
    this.rightMargin,
    this.topMargin,
    this.borderRadius,
    this.leftPadding,
    this.rightPadding,
    this.topPadding,
    this.bottomPadding,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: width ?? screenWidth,
      padding: EdgeInsets.only(
        left: leftMargin ?? screenWidth / 15,
        right: rightMargin ?? screenWidth / 15,
        top: topMargin ?? 0,
      ),
      child: Material(
        type: MaterialType.card,
        color: color ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
        ),
        elevation: elevation ?? 10.0,
        child: Padding(
          padding: EdgeInsets.only(
            left: leftPadding ?? screenWidth / 30,
            right: rightPadding ?? screenWidth / 30,
            top: topPadding ?? screenHeight / 80,
            bottom: bottomPadding ?? screenHeight / 80,
          ),
          child: child,
        ),
      ),
    );
  }
}
