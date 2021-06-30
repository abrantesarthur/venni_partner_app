import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PartnerAvailable extends StatefulWidget {
  @override
  PartnerAvailableState createState() => PartnerAvailableState();
}

class PartnerAvailableState extends State<PartnerAvailable> {
  bool lockScreen = false;
  Widget buttonChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    PartnerModel partner = Provider.of<PartnerModel>(context);

    return SlidingUpPanel(
      panel: OverallPadding(
        top: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight / 100),
            Icon(
              Icons.maximize,
              color: Colors.black.withOpacity(0.3),
              size: 30,
            ),
            Spacer(),
            SizedBox(height: screenHeight / 100),
            RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                text: "R\$",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: reaisFromCents(partner.gains ?? 0),
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: " recebidos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: AppColor.disabled,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight / 50),
            AppButton(
              textData: "Desconectar",
              onTapCallBack:
                  lockScreen ? () {} : () async => disconnect(context),
            ),
          ],
        ),
      ),
      collapsed: Column(
        children: [
          SizedBox(height: screenHeight / 25),
          buttonChild == null
              ? Text(
                  "VOCÊ ESTÁ ONLINE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColor.primaryPink,
                  ),
                )
              : buttonChild,
        ],
      ),
      color: Colors.white,
      maxHeight: screenHeight / 2.7,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10.0),
        topRight: Radius.circular(10.0),
      ),
    );
  }

  Future<void> disconnect(BuildContext context) async {
    // show dialog asking user if the want to disconnect
    await showYesNoDialog(
      context,
      title: "Deseja se desconectar?",
      content: "você irá parar de receber pedidos de corridas",
      onPressedYes: () async {
        // if partner indeed choses to disconnect, pop off dialog
        Navigator.pop(context);

        // lock screen
        setState(() {
          lockScreen = true;
          buttonChild = CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColor.primaryPink,
            ),
          );
        });

        // send request to disconnect partner
        FirebaseModel firebase = Provider.of<FirebaseModel>(
          context,
          listen: false,
        );
        try {
          await firebase.functions.disconnect();
        } catch (e) {
          // warn user about failure
          await showOkDialog(
            context: context,
            title: "Algo deu errado",
            content: "Tente novamente mais tarde",
          );
          // unlock screen
          setState(() {
            lockScreen = false;
            buttonChild = null;
          });
          return;
        }

        // manually update status locally, since the listener can be flaky
        PartnerModel partner = Provider.of<PartnerModel>(
          context,
          listen: false,
        );
        partner.updatePartnerStatus(PartnerStatus.unavailable);

        // unlock screen
        setState(() {
          lockScreen = false;
          buttonChild = null;
        });
      },
    );
  }
}
