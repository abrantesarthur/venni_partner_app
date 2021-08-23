import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:partner_app/app.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/vendors/awesomeNotifications.dart';

// TODO: store sensitive data safely https://medium.com/flutterdevs/secure-storage-in-flutter-660d7cb81bc
void main() async {
  await DotEnv.load(fileName: ".env");
  AppConfig(flavor: Flavor.PROD);

  // disable landscape mode
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  // initialize trip request local notifications
  Notifications().init(
    channelKey: "trip_request_channel",
    channelName: "Venni Pedidos de Viagens",
    channelDescription: "Notificações quando receber pedidos de viagens",
  );

  runApp(App());
}

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 */
