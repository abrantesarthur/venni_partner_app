import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

enum Flavor { DEV, STAG, PROD }

// TODO: add sensitive variables to secure storage package
class ConfigValues {
  final String autocompleteBaseURL;
  final String googleMapsApiKey;
  final bool emulateCloudFunctions;
  final String cloudFunctionsBaseURL;
  final String realtimeDatabaseURL;
  final String directionsBaseURL;

  ConfigValues({
    @required this.autocompleteBaseURL,
    @required this.googleMapsApiKey,
    @required this.emulateCloudFunctions,
    @required this.cloudFunctionsBaseURL,
    @required this.realtimeDatabaseURL,
    @required this.directionsBaseURL,
  });
}

class AppConfig {
  final Flavor flavor;
  final ConfigValues values;

  static AppConfig _instance;
  static AppConfig get env => _instance;

  AppConfig._internal({
    @required this.flavor,
    @required this.values,
  });

  factory AppConfig({@required Flavor flavor}) {
    ConfigValues values = ConfigValues(
      autocompleteBaseURL: DotEnv.env["AUTOCOMPLETE_BASE_URL"],
      googleMapsApiKey: AppConfig._buildGoogleMapsApiKey(flavor),
      emulateCloudFunctions: DotEnv.env["EMULATE_CLOUD_FUNCTIONS"] == "true",
      cloudFunctionsBaseURL: AppConfig._buildCloudFunctionsBaseURL(),
      realtimeDatabaseURL: _buildRealtimeDatabaseURL(flavor),
      directionsBaseURL: DotEnv.env["DIRECTIONS_BASE_URL"],
    );
    _instance ??= AppConfig._internal(flavor: flavor, values: values);
    return _instance;
  }

  static String _buildRealtimeDatabaseURL(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      return DotEnv.env["DEV_REALTIME_DATABASE_BASE_URL"];
    }
    if (flavor == Flavor.STAG) {
      return DotEnv.env["STAG_REALTIME_DATABASE_BASE_URL"];
    }
    if (flavor == Flavor.PROD) {
      return DotEnv.env["REALTIME_DATABASE_BASE_URL"];
    }
    return "";
  }

  static String _buildGoogleMapsApiKey(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      return DotEnv.env["DEV_GOOGLE_MAPS_API_KEY"];
    }
    if (flavor == Flavor.STAG) {
      return DotEnv.env["STAG_GOOGLE_MAPS_API_KEY"];
    }
    if (flavor == Flavor.PROD) {
      if (Platform.isAndroid) {
        return DotEnv.env["ANDROID_GOOGLE_MAPS_API_KEY"];
      } else if (Platform.isIOS) {
        return DotEnv.env["IOS_GOOGLE_MAPS_API_KEY"];
      }
    }
    return "";
  }

  static String _buildCloudFunctionsBaseURL() {
    return "http://" +
        DotEnv.env["HOST_IP_ADDRESS"] +
        ":" +
        DotEnv.env["CLOUD_FUNCTIONS_PORT"];
  }

  static isProduction() => _instance.flavor == Flavor.PROD;
  static isDevelopment() => _instance.flavor == Flavor.DEV;
}
