import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/screens/insertNewPhone.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';

import '../models/firebase.dart';

class EditPhone extends StatefulWidget {
  static const String routeName = "EditPhone";

  @override
  EditPhoneState createState() => EditPhoneState();
}

class EditPhoneState extends State<EditPhone> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GoBackButton(
                  onPressed: () => Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 15),
            Column(children: [
              Text(
                "Atualizar número de telefone",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              SizedBox(height: screenHeight / 30),
            ]),
            Text(
              firebase.auth.currentUser.phoneNumber.withoutCountryCode(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight / 30),
            Text(
              "Mudar seu número de telefone não afetará outras informações da sua conta.",
              style: TextStyle(
                fontSize: 16,
                color: AppColor.disabled,
              ),
            ),
            Spacer(),
            AppButton(
              textData: "Atualizar Telefone",
              onTapCallBack: () async {
                // ensure user is connected to the internet
                if (!connectivity.hasConnection) {
                  await connectivity.alertWhenOffline(
                    context,
                    message: "Conecte-se à internet para deletar o cartão.",
                  );
                  return;
                }
                final _ = await Navigator.pushNamed(
                  context,
                  InsertNewPhone.routeName,
                ) as String;
                // call setState to rebuild tree and display updated phone
                setState(() {});
              },
            )
          ],
        ),
      ),
    );
  }
}
