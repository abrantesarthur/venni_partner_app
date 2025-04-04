import 'package:flutter/material.dart';
import 'package:partner_app/screens/bankAccountDetail.dart';
import 'package:partner_app/screens/privacy.dart';
import 'package:partner_app/screens/profile.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/services/firebase/firebaseAnalytics.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/goBackScaffold.dart';
import 'package:partner_app/widgets/yesNoDialog.dart';

class Settings extends StatefulWidget {
  static const String routeName = "Settings";
  final firebase = FirebaseService();

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool lockScreen = false;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final partner = widget.firebase.model.partner;

    return GoBackScaffold(
      title: "Configurações",
      onPressed: lockScreen ? () {} : () => Navigator.pop(context),
      children: [
        BorderlessButton(
          onTap: lockScreen
              ? () {}
              : () => Navigator.pushNamed(
                    context,
                    Profile.routeName,
                  ),
          iconLeft: Icons.account_circle_rounded,
          iconLeftSize: 26,
          primaryText: "Perfil",
          primaryTextSize: 18,
          paddingTop: screenHeight / 80,
          paddingBottom: screenHeight / 80,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: lockScreen
              ? () {}
              : () => Navigator.pushNamed(
                    context,
                    BankAccountDetail.routeName,
                  ),
          iconLeft: Icons.account_balance,
          iconLeftSize: 26,
          primaryText: "Informações Bancárias",
          primaryTextSize: 18,
          paddingTop: screenHeight / 80,
          paddingBottom: screenHeight / 80,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: lockScreen
              ? () {}
              : () => Navigator.pushNamed(context, Privacy.routeName),
          iconLeft: Icons.lock_rounded,
          iconLeftSize: 26,
          primaryText: "Privacidade",
          primaryTextSize: 18,
          paddingBottom: screenHeight / 80,
          paddingTop: screenHeight / 80,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 80),
          child: GestureDetector(
            onTap: lockScreen
                ? () {}
                : () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return YesNoDialog(
                          title: "Deseja sair?",
                          onPressedYes: () async {
                            setState(() {
                              lockScreen = true;
                            });
                            Navigator.pop(context);

                            // try disconnecting partner if connected
                            if (partner.status ==
                                PartnerStatus.available) {
                              try {
                                await widget.firebase.functions.disconnect();
                              } catch (_) {}
                            }

                            // log logout event
                            try {
                              await widget.firebase.analytics.logLogout();
                            } catch (_) {}
                            await widget.firebase.auth.signOut();

                            setState(() {
                              lockScreen = false;
                            });
                          },
                        );
                      },
                    );
                  },
            child: Text(
              "Sair",
              style: TextStyle(
                fontSize: 18,
                color: AppColor.secondaryRed,
              ),
            ),
          ),
        ),
        Spacer(),
        Center(
          child: Text("versão 1.2.0+10",
              style: TextStyle(
                fontSize: 12,
                color: AppColor.disabled,
              )),
        )
      ],
    );
  }
}
