import 'package:flutter/material.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:provider/provider.dart';
import 'package:system_settings/system_settings.dart';

class ShareLocationArguments {
  String routeToPush;
  Object routeArguments;
  ShareLocationArguments({
    @required this.routeToPush,
    this.routeArguments,
  });
}

class ShareLocation extends StatefulWidget {
  static String routeName = "ShareLocation";
  final String routeToPush;
  final Object routeArguments;
  final String message;

  ShareLocation({
    @required this.routeToPush,
    this.routeArguments,
    this.message,
  });

  @override
  ShareLocationState createState() => ShareLocationState();
}

class ShareLocationState extends State<ShareLocation> {
  bool reload = false;

  @override
  Widget build(BuildContext context) {
    return Splash(
      text: widget.message ?? "Compartilhe sua localização",
      button: reload
          ? AppButton(
              buttonColor: Colors.white,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColor.primaryPink,
              ),
              borderRadius: 10.0,
              textData: "Recarregar Aplicatiavo",
              onTapCallBack: () async {
                Navigator.pushReplacementNamed(
                  context,
                  widget.routeToPush,
                  arguments: widget.routeArguments,
                );
              },
            )
          : AppButton(
              buttonColor: Colors.white,
              textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColor.primaryPink),
              borderRadius: 10.0,
              textData: "Abrir Configurações",
              onTapCallBack: () async {
                setState(() {
                  reload = true;
                });
                await SystemSettings.location();
              },
            ),
    );
  }
}
