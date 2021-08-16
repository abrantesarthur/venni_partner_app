// find user's current latitude longitude
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';

Position userPosition;

bool dialogShown = false;

// Determine the current position of the device
Future<Position> determineUserPosition(BuildContext context) async {
  if (Platform.isAndroid) {
    return await _determineUserPositionAndroid(context);
  }
  return await _determineUserPositionIOS(context);
}

Future<Position> _determineUserPositionIOS(BuildContext context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error("location-service-disabled");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    // ask user to update permission in App settings and return null
    await Geolocator.openLocationSettings();
    return null;
  }

  // if permission is still denied (i.e., on iOS user tapped "ask next time")
  if (permission == LocationPermission.denied) {
    // ask for permission
    permission = await Geolocator.requestPermission();

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return Future.error("location-not-granted");
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<Position> _determineUserPositionAndroid(BuildContext context) async {
  if (await Permission.location.serviceStatus.isDisabled) {
    return Future.error("location-service-disabled");
  }

  // if permission is permanently denied, no dialog will be shown to the user,
  // so we must manually redirect them to the settings page
  if (await Permission.location.isPermanentlyDenied) {
    // ask user to update permission in App settings and try again
    await _openAppSettings(context);
    return determineUserPosition(context);
  }

  // if user is not sharing location always
  PermissionStatus permission;
  if (!await Permission.locationAlways.isGranted) {
    // for android users, we must warn them about tracking location in background
    // check variable to avoid showing dialog multiple times
    if (!dialogShown) {
      dialogShown = true;
      permission = await requestAndroidPermission(context);
      dialogShown = false;
    }

    if (!permission.isGranted) {
      return Future.error("location-not-granted");
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

// requestAndroidPermission displays the necessary warnings and requests location
// when in use and always, in this order.
Future<PermissionStatus> requestAndroidPermission(BuildContext context) async {
  // if user has not already shared location when in use
  if (!await Permission.locationWhenInUse.isGranted) {
    // display warning required by Google before requesting permissions
    await showOkDialog(
      context: context,
      title: "Atenção",
      content:
          "Este app coleta dados de sua localização mesmo se o app estiver fechado ou não sendo utilizado. Fazemos isso para encontrar pedidos próximos a você e para compartilhar a sua localização com os clientes durante a corrida.",
    );
  }

  // first, ask for permission when in use
  PermissionStatus permissionWhenInuse = await Permission.location.request();

  if (permissionWhenInuse.isGranted) {
    // if granted, we ask for permission always
    bool permissionAlwaysNotGranted = true;
    do {
      // if location always is not already shared
      if (!await Permission.locationAlways.isGranted) {
        // instruct users to accept sharing location always
        await showOkDialog(
          context: context,
          title: "Permita o tempo todo",
          content:
              "Para que o aplicativo consiga encontrar as corridas mais próximas de você, selecione 'PERMITIR O TEMPO TODO'",
        );
      }

      // request permission always
      PermissionStatus permissionAlways =
          await Permission.locationAlways.request();
      if (permissionAlways.isGranted) {
        // if granted, break out of the loop
        permissionAlwaysNotGranted = false;
      } else if (permissionAlways.isPermanentlyDenied) {
        // if permanently denied, instruct user to manually share location
        // through app settings and try again
        await _openAppSettings(context);
        return await requestAndroidPermission(context);
      } else if (permissionAlways.isDenied) {
        // if simply denied, run loop again
        permissionAlwaysNotGranted = true;
      }
    } while (permissionAlwaysNotGranted);
  } else if (permissionWhenInuse.isPermanentlyDenied) {
    // if permission when in use is permanently denied, instruct user to manually
    // share location through app settings and try again
    await _openAppSettings(context);
    return await requestAndroidPermission(context);
  } else {
    // otherwise, we try again
    return await requestAndroidPermission(context);
  }

  return permissionWhenInuse;
}

Future<void> _openAppSettings(BuildContext context) async {
  bool settingsOpened;
  if (Platform.isAndroid) {
    // display warning that the settings will be opened
    await showOkDialog(
      context: context,
      title: "Atenção",
      content:
          "Para conseguir acessar o app, abra as 'Permissões do app' e compartilhe a localização manualmente selecionando 'PERMITIR O TEMPO TODO'",
    );
    settingsOpened = await openAppSettings();
  } else if (Platform.isIOS) {
    settingsOpened = await Geolocator.openLocationSettings();
  }

  if (!settingsOpened) {
    // if the user did not open settings, return error
    return Future.error("location-permanently-denied");
  }
}
