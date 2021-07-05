import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:provider/provider.dart';

class PartnerRequested extends StatefulWidget {
  @override
  PartnerRequestedState createState() => PartnerRequestedState();
}

class PartnerRequestedState extends State<PartnerRequested> {
  Widget buttonChild;
  bool lock = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Spacer(),
        FloatingCard(
            width: screenWidth,
            leftMargin: 0,
            rightMargin: 0,
            color: AppColor.primaryPink,
            child: Column(
              children: [
                SizedBox(height: screenHeight / 40),
                Text(
                  "NOVO PEDIDO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                SizedBox(height: screenHeight / 40),
                Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Colors.white,
                ),
                SizedBox(height: screenHeight / 40),
                AppButton(
                  textData: "ACEITAR",
                  child: buttonChild,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                    color: Colors.white,
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                  hasShadow: false,
                  // only display seconds if we are not displaying circular progress indicator
                  widgetRight: buttonChild == null
                      ? Consumer<TimerModel>(
                          builder: (context, timer, _) => Text(
                            timer.remainingSeconds.toString() + "s",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                            ),
                          ),
                        )
                      : null,
                  onTapCallBack:
                      lock ? () {} : () async => await accept(context),
                ),
                SizedBox(height: screenHeight / 20),
              ],
            )),
      ],
    );
  }

  Future<void> accept(BuildContext context) async {
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

    // mark the pilot as having accepted trip, so if 10s timeout
    // finishes, we don't send a declineTrip request and don't update
    // the UI disposing this PartnerRequested widget
    print("partner acepted the trip");
    partner.setAcceptedTrip(true, notify: false);

    // lock this widget and display circular progress indicator
    setState(() {
      lock = true;
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    // send request to accept the trip
    try {
      await firebase.functions.acceptTrip();
    } catch (e) {
      // TODO: personalize warninig in case the reason acceptTrip faile is
      // because another partner was quicker
      // warn user
      await showOkDialog(
        context: context,
        title: "Algo deu errado",
      );
      // reset partner status so they can no longer accept the trip.
      // it's ok doing this without sending a request to firebase
      // since, if a partner fails to accept a trip, his status
      // is reset to available
      partner.updatePartnerStatus(
        PartnerStatus.available,
      );
      return;
    }

    // block until partner is granted or denied the trip
    // so that circular progress indicator continues
    // being displayed
    while (partner.partnerStatus != PartnerStatus.busy &&
        partner.partnerStatus != PartnerStatus.available) {
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
