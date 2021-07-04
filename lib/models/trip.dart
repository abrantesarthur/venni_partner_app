import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/vendors/firebaseStorage.dart';

class TripModel extends ChangeNotifier {
  String _clientID;
  TripStatus _tripStatus;
  String _originPlaceID;
  String _destinationPlaceID;
  double _originLat;
  double _originLng;
  double _destinationLat;
  double _destinationLng;
  int _farePrice;
  int _distanceMeters;
  String _distanceText;
  int _durationSeconds;
  String _durationText;
  String _clientToDestinationEncodedPoints;
  int _requestTime;
  String _originAddress;
  String _destinationAddress;
  PaymentMethod _paymentMethod;
  String _clientName;
  String _clientPhone;
  ProfileImage _profileImage;

  String get clientID => _clientID;
  TripStatus get tripStatus => _tripStatus;
  String get originPlaceID => _originPlaceID;
  String get destinationPlaceID => _destinationPlaceID;
  double get originLat => _originLat;
  double get originLng => _originLng;
  double get destinationLat => _destinationLat;
  double get destinationLng => _destinationLng;
  int get farePrice => _farePrice;
  int get distanceMeters => _distanceMeters;
  String get distanceText => _distanceText;
  int get durationSeconds => _durationSeconds;
  String get durationText => _durationText;
  String get clientToDestinationEncodedPoints =>
      _clientToDestinationEncodedPoints;
  int get requestTime => _requestTime;
  String get originAddress => _originAddress;
  String get destinationAddress => _destinationAddress;
  PaymentMethod get paymentMethod => _paymentMethod;
  String get clientName => _clientName != null ? _clientName.split(" ")[0] : "";
  String get clientFullName => _clientName;
  String get clientPhone => _clientPhone;
  ProfileImage get profileImage => _profileImage;

  void fromTripInterface(Trip t, {bool notify = true}) {
    if (t != null) {
      _clientID = t.clientID;
      _tripStatus = t.tripStatus;
      _originPlaceID = t.originPlaceID;
      _destinationPlaceID = t.destinationPlaceID;
      _originLat = t.originLat;
      _originLng = t.originLng;
      _destinationLat = t.destinationLat;
      _destinationLng = t.destinationLng;
      _farePrice = t.farePrice;
      _distanceMeters = t.distanceMeters;
      _distanceText = t.distanceText;
      _durationSeconds = t.durationSeconds;
      _durationText = t.durationText;
      _clientToDestinationEncodedPoints = t.clientToDestinationEncodedPoints;
      _requestTime = t.requestTime;
      _originAddress = t.originAddress;
      _destinationAddress = t.destinationAddress;
      _paymentMethod = t.paymentMethod;
      _clientName = t.clientName;
      _clientPhone = t.clientPhone;
    } else {
      clear();
    }
    if (notify) {
      notifyListeners();
    }
  }

  void updateProfileImage(ProfileImage pi, {bool notify = true}) {
    _profileImage = pi;
    if (notify) {
      notifyListeners();
    }
  }

  void updateTripStatus(TripStatus ts, {bool notify = true}) {
    print("updateTripStatus to " + ts.toString());
    _tripStatus = ts;
    if (notify) {
      notifyListeners();
    }
  }

  // downloadData sends a request to download partner's current trip
  Future<void> downloadData(
    FirebaseModel firebase, {
    bool notify = true,
  }) async {
    Trip t = await firebase.functions.getCurrentTrip();
    fromTripInterface(t, notify: notify);

    // get client profile image
    ProfileImage pi = await firebase.storage.getClientProfilePicture(clientID);
    updateProfileImage(pi, notify: notify);
  }

  void clear() {
    _clientID = null;
    _tripStatus = null;
    _originPlaceID = null;
    _destinationPlaceID = null;
    _farePrice = null;
    _distanceMeters = null;
    _distanceText = null;
    _durationSeconds = null;
    _durationText = null;
    _clientToDestinationEncodedPoints = null;
    _requestTime = null;
    _originAddress = null;
    _destinationAddress = null;
    _paymentMethod = null;
    _clientName = null;
    _clientPhone = null;
    _profileImage = null;
    notifyListeners();
  }
}
