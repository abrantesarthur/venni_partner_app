import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class AppButton extends StatelessWidget {
  final String textData;
  final TextStyle textStyle;
  final double height;
  final double width;
  final double borderRadius;
  final IconData iconRight;
  final IconData iconLeft;
  final Color buttonColor;
  final VoidCallback onTapCallBack;
  final Widget child;

  AppButton({
    this.textStyle,
    this.width,
    this.height,
    @required this.textData,
    this.iconRight,
    this.iconLeft,
    this.borderRadius,
    this.buttonColor,
    this.child,
    @required this.onTapCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTapCallBack,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 100.0),
          color: buttonColor ?? AppColor.primaryPink,
          boxShadow: buttonColor != AppColor.disabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(4, 4),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        height: height ?? screenHeight / 12,
        width: width,
        child: Padding(
          padding:
              EdgeInsets.only(left: screenWidth / 30, right: screenWidth / 30),
          child: Stack(
            children: [
              this.iconLeft != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth / 50),
                        child: Icon(iconLeft, color: Colors.white, size: 24),
                      ),
                    )
                  : Container(),
              Center(
                child: child != null
                    ? child
                    : Text(
                        textData,
                        textAlign: TextAlign.center,
                        style: textStyle ??
                            TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.white),
                      ),
              ),
              this.iconRight != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(right: screenWidth / 50),
                          child:
                              Icon(iconRight, color: Colors.white, size: 24)))
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
