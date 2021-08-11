// find user's current latitude longitude
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partner_app/utils/utils.dart';

Position userPosition;

bool dialogShown = false;

// Determine the current position of the device
Future<Position> determineUserPosition(BuildContext context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error("Location services are disabled.");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    // ask user to update permission in App settings
    bool settingsOpened = await Geolocator.openLocationSettings();
    if (!settingsOpened) {
      // if the user did not open settings, return error
      return Future.error(
          "Location permissions permantly denied, we couldn't change settings.");
    } else {
      // try again
      return determineUserPosition(context);
    }
  }

  // if permission is still denied (i.e., on iOS user tapped "ask next time")
  if (permission == LocationPermission.denied) {
    if (Platform.isAndroid) {
      // for android users, we must warn them about tracking location in background
      // check variable to avoid showing dialog multiple times
      if (!dialogShown) {
        dialogShown = true;
        await showOkDialog(
          context: context,
          title: "Atenção",
          content:
              "Este app coleta dados de sua localização mesmo se o app estiver fechado ou não sendo utilizado. Fazemos isso para encontrar pedidos próximos a você e para compartilhar a sua localização com os clientes durante a corrida.",
        );
        permission = await Geolocator.requestPermission();
        dialogShown = false;
      }
    } else if (Platform.isIOS) {
      // for ios, we just ask for permission
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return Future.error(
          "Location permissions denied (actual value: $permission).");
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
