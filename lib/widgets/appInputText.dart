import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/styles.dart';

// TODO: add default endIcon that, when tapped, clears input field
class AppInputText extends StatelessWidget {
  final Function onTapCallback;
  final String hintText;
  final Color hintColor;
  final IconData iconData;
  final Color iconDataColor;
  final IconData endIcon;
  final Function onSubmittedCallback;
  final TextEditingController controller;
  final List<TextInputFormatter> inputFormatters;
  final double width;
  final TextInputType keyboardType;
  final Function endIconOnTapCallback;
  final bool obscureText;
  final bool autoFocus;
  final FocusNode focusNode;
  final bool enabled;
  final double fontSize;
  final int maxLines;
  final String title;
  final TextStyle titleStyle;
  final Color backgroundColor;
  final Color fontColor;
  final bool hasBorders;
  final CrossAxisAlignment crossAxisAlignment;

  AppInputText({
    this.maxLines,
    this.enabled,
    this.hintText,
    this.hintColor,
    this.iconData,
    this.iconDataColor,
    this.endIcon,
    this.onTapCallback,
    this.onSubmittedCallback,
    this.inputFormatters,
    this.controller,
    this.width,
    this.keyboardType,
    this.endIconOnTapCallback,
    this.obscureText,
    this.autoFocus,
    this.focusNode,
    this.fontSize,
    this.title,
    this.titleStyle,
    this.backgroundColor,
    this.fontColor,
    this.hasBorders,
    this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        title != null
            ? Text(
                title,
                style: titleStyle ??
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.disabled,
                    ),
              )
            : Container(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: hasBorders == false
                ? null
                : Border.all(color: Colors.black, width: 0.5),
            color: backgroundColor ?? Colors.white,
          ),
          height: 50,
          width: width,
          child: Row(
            children: [
              iconData != null
                  ? Padding(
                      padding: EdgeInsets.only(left: screenWidth / 20),
                      child: Icon(
                        iconData,
                        color: iconDataColor,
                      ),
                    )
                  : Container(),
              Expanded(
                child: TextField(
                  textAlign: crossAxisAlignment != null &&
                          crossAxisAlignment == CrossAxisAlignment.end
                      ? TextAlign.end
                      : TextAlign.start,
                  onTap: onTapCallback,
                  maxLines: maxLines,
                  enabled: enabled,
                  autofocus: autoFocus ?? false,
                  focusNode: focusNode,
                  inputFormatters: inputFormatters,
                  onSubmitted: onSubmittedCallback,
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: fontSize ?? 18,
                    color: fontColor,
                  ),
                  obscureText: obscureText ?? false,
                  decoration: InputDecoration(
                      hintText: this.hintText,
                      hintStyle: TextStyle(
                        fontSize: fontSize ?? 18,
                        color: hintColor ??
                            (onTapCallback != null
                                ? AppColor.secondaryPurple
                                : AppColor.disabled),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                        left: screenWidth / 20,
                        right: screenWidth / 20,
                      )),
                ),
              ),
              endIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: GestureDetector(
                        onTap: endIconOnTapCallback != null
                            ? endIconOnTapCallback
                            : () {},
                        child: Icon(
                          endIcon,
                          color: AppColor.disabled,
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ],
    );
  }
}
