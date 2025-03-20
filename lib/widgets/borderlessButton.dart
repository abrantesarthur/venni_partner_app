import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:partner_app/styles.dart';

class BorderlessButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? primaryText;
  final String? secondaryText;
  final IconData? iconLeft;
  final double? iconLeftSize;
  final Color? iconLeftColor;
  final IconData? iconRight;
  final double? iconRightSize;
  final Color? iconRightColor;
  final String? primaryTextRight;
  final Color? primaryTextRightColor;
  final double? primaryTextRightSize;
  final double? primaryTextSize;
  final double? secondaryTextSize;
  final String? secondaryTextRight;
  final Color? primaryTextColor;
  final FontWeight? primaryTextWeight;
  final double? paddingTop;
  final double? paddingBottom;
  final String? label;
  final Color? labelColor;
  final String? svgLeftPath; // has lower priority than svg left
  final double? svgLeftWidth;

  BorderlessButton({
    this.primaryTextColor,
    this.iconLeftSize,
    this.iconLeftColor,
    this.iconRightSize,
    this.iconRightColor,
    this.primaryTextSize,
    this.secondaryTextSize,
    this.primaryTextWeight,
    this.primaryText,
    this.onTap,
    this.secondaryText,
    this.primaryTextRight,
    this.primaryTextRightColor,
    this.primaryTextRightSize,
    this.secondaryTextRight,
    this.iconLeft,
    this.iconRight,
    this.paddingBottom,
    this.paddingTop,
    this.label,
    this.labelColor,
    this.svgLeftPath,
    this.svgLeftWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: paddingTop ?? 0,
          bottom: paddingBottom ?? 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconLeft != null
                ? Row(children: [
                    Icon(
                      iconLeft,
                      color: iconLeftColor ?? Colors.black,
                      size: iconLeftSize ?? 18,
                    ),
                    SizedBox(width: screenWidth / 30),
                  ])
                : svgLeftPath != null
                    ? Row(
                        children: [
                          SvgPicture.asset(
                            svgLeftPath!,
                            width: svgLeftWidth ?? 18,
                          ),
                          SizedBox(width: screenWidth / 30),
                        ],
                      )
                    : Container(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: primaryTextColor ?? Colors.black,
                        fontSize: primaryTextSize ?? 16,
                        fontWeight: primaryTextWeight ?? FontWeight.normal),
                  ),
                  secondaryText != null
                      ? Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            secondaryText!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColor.disabled,
                              fontSize: secondaryTextSize ?? 13,
                            ),
                          ),
                        )
                      : Container()
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                label != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          right: screenWidth / 100,
                          left: screenWidth / 100,
                        ),
                        child: Text(
                          label!,
                          style: TextStyle(
                            fontSize: 13,
                            color: labelColor ?? Colors.green,
                          ),
                        ),
                      )
                    : Container(),
                primaryTextRight != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            primaryTextRight!,
                            style: TextStyle(
                              color: primaryTextRightColor ?? Colors.black,
                              fontSize: primaryTextRightSize ?? 16,
                              fontWeight:
                                  primaryTextWeight ?? FontWeight.normal,
                            ),
                          ),
                          secondaryTextRight != null
                              ? Text(
                                  secondaryTextRight!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColor.disabled,
                                    fontSize: secondaryTextSize ?? 13,
                                  ),
                                )
                              : Container(),
                        ],
                      )
                    : Icon(
                        iconRight,
                        color: iconRightColor ?? AppColor.disabled,
                        size: iconRightSize ?? 18,
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
