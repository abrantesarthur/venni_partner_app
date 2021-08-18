import 'dart:io';

import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class PartnerUnavailable extends StatefulWidget {
  @override
  PartnerUnavailableStatus createState() => PartnerUnavailableStatus();
}

class PartnerUnavailableStatus extends State<PartnerUnavailable> {
  Widget buttonChild;
  bool lock = false;

  @override
  Widget build(BuildContext context) {
    return OverallPadding(
      child: Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          textData: "Conectar",
          child: buttonChild,
          onTapCallBack: lock ? () {} : () async => await connect(context),
        ),
      ),
    );
  }

  Future<void> connect(BuildContext context) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    GoogleMapsModel googleMaps =
        Provider.of<GoogleMapsModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // make sure notifications are on
    await firebase.requestNotifications(context);

    // make sure partner has shared his location
    if (partner.position == null) {
      await showOkDialog(
        context: context,
        title: "Compartilhe sua localização",
        content:
            "Abra as configurações do seu celular e compartilhe a sua localização para se conectar.",
      );
      // unlock screen and hide circularProgressIndicator
      setState(() {
        buttonChild = null;
        lock = false;
      });
      return;
    }

    // lock screen and display circularProgressIndicator
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      lock = true;
    });

    // send request to connect, thus updating partner's status to 'available'
    // and setting his position
    try {
      await firebase.functions.connect(
        currentLatitude: partner.position.latitude,
        currentLongitude: partner.position.longitude,
      );
    } catch (e) {
      print(e);
      // warn user about failure
      await showOkDialog(
        context: context,
        title: "Algo deu errado",
        content: "Tente novamente mais tarde",
      );
      // unlock screen and hide circularProgressIndicator
      setState(() {
        buttonChild = null;
        lock = false;
      });
      return;
    }

    // clear gains so we can start counting them again. These gains are increased
    // whenever the partner compeltes a new trip
    partner.updateGains(0, notify: false);

    // start listening for location updates
    partner.handlePositionUpdates(firebase, googleMaps, trip);

    // periodically report their position to firebase
    partner.sendPositionToFirebase(true);

    // update status locally, since the database listener can be flaky sometimes
    partner.updatePartnerStatus(PartnerStatus.available);
  }
}
