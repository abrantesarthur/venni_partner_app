import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:partner_app/app.dart';
import 'package:partner_app/config/config.dart';

void main() async {
  await DotEnv.load(fileName: ".env");
  AppConfig(flavor: Flavor.STAG);

  // disable landscape mode
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  runApp(App());
}
