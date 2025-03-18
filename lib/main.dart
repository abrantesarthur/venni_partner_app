import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:partner_app/app.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/vendors/awesomeNotifications.dart';

// FIXME: move these to a dedicated package and properly integrate with firebase
@pragma('vm:entry-point')
void backgroundLocationCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
    (data) async => print(data)
  );
}

Future startLocationTracking() async {
  await BackgroundLocationTrackerManager.startTracking();
}

Future stopLocationTracking() async {
  await BackgroundLocationTrackerManager.stopTracking();
}

// TODO: store sensitive data safely https://medium.com/flutterdevs/secure-storage-in-flutter-660d7cb81bc
void main() async {
  await dotenv.load(fileName: ".env");
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

  // initialize background location tracking
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundLocationTrackerManager.initialize(
    backgroundLocationCallback,
    config: const BackgroundLocationTrackerConfig(
      loggingEnabled: true,
      androidConfig: AndroidConfig(
        notificationIcon: 'explore',
        trackingInterval: Duration(seconds: 4),
        distanceFilterMeters: null,
      ),
      iOSConfig: IOSConfig(
        activityType: ActivityType.FITNESS,
        distanceFilterMeters: null,
        restartAfterKill: true,
      ),
    ),
  );

  runApp(App());
}

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 */
