import 'package:flutter/material.dart';
import 'package:partner_app/screens/insertPhone.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class Start extends StatelessWidget {
  static const String routeName = "login";

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: OverallPadding(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 3),
              Image(
                image: AssetImage("images/horizontal-pink-logo.png"),
                width: width * 0.8,
              ),
              Spacer(flex: 3),
              Text(
                "Bem-vindo(a) ao app de parceiros",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "OpenSans",
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Spacer(flex: 5),
              AppButton(
                textData: "Começar",
                iconRight: Icons.arrow_forward,
                onTapCallBack: () {
                  Navigator.pushNamed(context, InsertPhone.routeName);
                },
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
