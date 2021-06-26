import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:provider/provider.dart';

class ShareLocationArguments {
  String push;
  ShareLocationArguments({@required this.push});
}

class ShareLocation extends StatefulWidget {
  static String routeName = "ShareLocation";
  final String push;

  ShareLocation({@required this.push});

  @override
  ShareLocationState createState() => ShareLocationState();
}

class ShareLocationState extends State<ShareLocation> {
  bool reload = false;

  @override
  Widget build(BuildContext context) {
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    return Splash(
      text: "Compartilhe sua localização",
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
                Navigator.pushReplacementNamed(context, widget.push);
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
                await partner.getPosition();
                setState(() {
                  reload = true;
                });
              },
            ),
    );
  }
}
