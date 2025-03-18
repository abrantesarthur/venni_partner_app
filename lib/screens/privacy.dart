import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/screens/deleteAccount.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/goBackScaffold.dart';
import 'package:provider/provider.dart';

class Privacy extends StatefulWidget {
  static const String routeName = "Privacy";

  PrivacyState createState() => PrivacyState();
}

class PrivacyState extends State<Privacy> {
  @override
  Widget build(BuildContext context) {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);
    return GoBackScaffold(
      resizeToAvoidBottomInset: false,
      title: "Privacidade",
      children: [
        BorderlessButton(
          onTap: () async {
            // ensure user is connected to the internet
            if (!connectivity.hasConnection) {
              await connectivity.alertOffline(
                context,
                message: "Conecte-se à internet para excluir a sua conta.",
              );
              return;
            }
            Navigator.pushNamed(context, DeleteAccount.routeName);
          },
          primaryText: "Excluir minha conta",
          iconRight: Icons.keyboard_arrow_right,
          iconRightSize: 20,
          primaryTextColor: AppColor.secondaryRed,
          primaryTextSize: 18,
        ),
      ],
    );
  }
}
