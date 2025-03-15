import 'package:flutter/material.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class GoBackScaffold extends StatelessWidget {
  static const String routeName = "GoBackScaffold";

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final bool resizeToAvoidBottomInset;
  final String title;
  final IconData goBackIcon;
  final TextStyle titleStyle;
  final VoidCallback onPressed;

  GoBackScaffold({
    required this.children,
    this.crossAxisAlignment,
    this.resizeToAvoidBottomInset,
    this.title,
    this.goBackIcon,
    this.titleStyle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GoBackButton(
                  icon: goBackIcon,
                  onPressed: onPressed ??
                      () {
                        Navigator.pop(context);
                      },
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 15),
            title != null
                ? Column(children: [
                    Text(
                      title,
                      style: titleStyle ??
                          TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                    ),
                    SizedBox(height: screenHeight / 30),
                  ])
                : Container(),
            for (var w in children) w,
          ],
        ),
      ),
    );
  }
}
