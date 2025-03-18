import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor { DEV, PROD }

// TODO: add sensitive variables to secure storage package
class ConfigValues {
  final String autocompleteBaseURL;
  final String googleMapsApiKey;
  final bool emulateCloudFunctions;
  final String cloudFunctionsBaseURL;
  final int cloudFunctionsPort;
  final String realtimeDatabaseURL;
  final String directionsBaseURL;

  ConfigValues({
    required this.autocompleteBaseURL,
    required this.googleMapsApiKey,
    required this.emulateCloudFunctions,
    required this.cloudFunctionsBaseURL,
    required this.realtimeDatabaseURL,
    required this.directionsBaseURL,
    required this.cloudFunctionsPort
  });
}

class AppConfig {
  final Flavor flavor;
  final ConfigValues values;

  static late AppConfig _instance;
  static AppConfig get env => _instance;

  AppConfig._internal({
    required this.flavor,
    required this.values,
  });

  factory AppConfig({required Flavor flavor}) {
    // Check for required environment variables
    final autocompleteBaseURL = dotenv.env["AUTOCOMPLETE_BASE_URL"];
    if (autocompleteBaseURL == null || autocompleteBaseURL.isEmpty) {
      throw Exception("Missing required environment variable: AUTOCOMPLETE_BASE_URL");
    }
    
    final directionsBaseURL = dotenv.env["DIRECTIONS_BASE_URL"];
    if (directionsBaseURL == null || directionsBaseURL.isEmpty) {
      throw Exception("Missing required environment variable: DIRECTIONS_BASE_URL");
    }

    final emulateCloudFunctions = dotenv.env["EMULATE_CLOUD_FUNCTIONS"];
    if (emulateCloudFunctions == null || emulateCloudFunctions.isEmpty) {
      throw Exception("Missing required environment variable: EMULATE_CLOUD_FUNCTIONS");
    }
    
    ConfigValues values = ConfigValues(
      autocompleteBaseURL: autocompleteBaseURL,
      googleMapsApiKey: AppConfig._buildGoogleMapsApiKey(flavor),
      emulateCloudFunctions: emulateCloudFunctions == "true",
      cloudFunctionsBaseURL: AppConfig._buildCloudFunctionsBaseURL(),
      cloudFunctionsPort: AppConfig._buildCountFunctionsPort(),
      realtimeDatabaseURL: _buildRealtimeDatabaseURL(flavor),
      directionsBaseURL: directionsBaseURL,
    );
    _instance = AppConfig._internal(flavor: flavor, values: values);
    return _instance;
  }

  static String _buildRealtimeDatabaseURL(Flavor flavor) {
    final envVar = flavor == Flavor.DEV ? "DEV_REALTIME_DATABASE_BASE_URL" : "REALTIME_DATABASE_BASE_URL";
    final realTimeDatabaseUrl = dotenv.env[envVar];
    if (realTimeDatabaseUrl == null || realTimeDatabaseUrl.isEmpty) {
      throw Exception("Missing required environment variable: $envVar");
    }
    return realTimeDatabaseUrl;
  }

  static String _buildGoogleMapsApiKey(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      final envVar = Platform.isAndroid ? "DEV_ANDROID_GOOGLE_MAPS_API_KEY" : "DEV_IOS_GOOGLE_MAPS_API_KEY";
      final apiKey = dotenv.env[envVar];
      if(apiKey == null || apiKey.isEmpty) {
        throw Exception("Missing required environment variable: $envVar");
      }
      return apiKey;
    }
    
    if (flavor == Flavor.PROD) {
      final envVar = Platform.isAndroid ? "ANDROID_GOOGLE_MAPS_API_KEY" : "IOS_GOOGLE_MAPS_API_KEY";
      final apiKey = dotenv.env[envVar];
      if(apiKey == null || apiKey.isEmpty) {
        throw Exception("Missing required environment variable: $envVar");
      }
      return apiKey;
    }
    return "";
  }

  static int _buildCountFunctionsPort() {
    final port = dotenv.env["CLOUD_FUNCTIONS_PORT"];
    if(port == null || port.isEmpty) {
      throw Exception("Missing required environment variable: CLOUD_FUNCTIONS_PORT  ");
    }
    return int.parse(port);
  }


  static String _buildCloudFunctionsBaseURL() {
    final hostIpAddress = dotenv.env["HOST_IP_ADDRESS"];
    if(hostIpAddress == null || hostIpAddress.isEmpty) {
      throw Exception("Missing required environment variable: HOST_IP_ADDRESS");
    }
    final port = _buildCountFunctionsPort();
    return "http://$hostIpAddress:$port";
  }


  static isProduction() => _instance.flavor == Flavor.PROD;
  static isDevelopment() => _instance.flavor == Flavor.DEV;
}
