import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class Splash extends StatelessWidget {
  final String? text;
  final Widget? button;
  final Widget? child;
  final VoidCallback? onTap;

  Splash({
    this.text,
    this.button,
    this.onTap,
    this.child
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            return Container(
              color: AppColor.primaryPink,
              alignment: Alignment.center,
              child: OverallPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    Image(
                      image: AssetImage("images/icon-white.png"),
                      width: 0.25 * width,
                    ),
                    text != null
                        ? Column(
                            children: [
                              SizedBox(height: height / 40),
                              Text(text!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: "OpenSans",
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ))
                            ],
                          )
                        : Container(),
                    SizedBox(height: height / 20),
                    button != null ? button! : Container(),
                    Spacer(),
                    child != null ? child! : Container(),
                    SizedBox(height: height / 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
