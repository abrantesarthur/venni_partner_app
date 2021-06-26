// find user's current latitude longitude
import 'package:geolocator/geolocator.dart';

Position userPosition;

// Determine the current position of the device
Future<Position> determineUserPosition() async {
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
      return determineUserPosition();
    }
  }

  // if permission is still denied (i.e., on iOS user tapped "ask next time")
  if (permission == LocationPermission.denied) {
    // ask for permission
    permission = await Geolocator.requestPermission();
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
