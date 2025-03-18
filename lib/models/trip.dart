import 'package:flutter/material.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/services/firebase/firebaseStorage.dart';

class TripModel extends ChangeNotifier {
  late FirebaseService firebase;
  String? _clientID;
  TripStatus? _tripStatus;
  String? _originPlaceID;
  String? _destinationPlaceID;
  int? _farePrice;
  int? _distanceMeters;
  String? _distanceText;
  int? _durationSeconds;
  String? _durationText;
  String? _clientToDestinationEncodedPoints;
  int? _requestTime;
  String? _originAddress;
  String? _destinationAddress;
  PaymentMethod? _paymentMethod;
  String? _clientName;
  String? _clientPhone;
  ProfileImage? _profileImage;
  double? _originLat;
  double? _originLng;
  double? _destinationLat;
  double? _destinationLng;


  String? get clientID => _clientID;
  TripStatus? get tripStatus => _tripStatus;
  String? get originPlaceID => _originPlaceID;
  String? get destinationPlaceID => _destinationPlaceID;
  double? get originLat => _originLat;
  double? get originLng => _originLng;
  double? get destinationLat => _destinationLat;
  double? get destinationLng => _destinationLng;
  int? get farePrice => _farePrice;
  int? get distanceMeters => _distanceMeters;
  String? get distanceText => _distanceText;
  int? get durationSeconds => _durationSeconds;
  String? get durationText => _durationText;
  String? get clientToDestinationEncodedPoints =>
      _clientToDestinationEncodedPoints;
  int? get requestTime => _requestTime;
  String? get originAddress => _originAddress;
  String? get destinationAddress => _destinationAddress;
  PaymentMethod? get paymentMethod => _paymentMethod;
  String get clientName => _clientName?.split(" ")[0] ?? "";
  String? get clientFullName => _clientName;
  String? get clientPhone => _clientPhone;
  ProfileImage? get profileImage => _profileImage;

  TripModel(this.firebase);

  Future<void> initialize() async {
    await downloadData(notify: false);
  }

  void fromTripInterface(Trip trip, {bool notify = true}) {
    _clientID = trip.clientID;
    _tripStatus = trip.tripStatus;
    _originPlaceID = trip.originPlaceID;
    _destinationPlaceID = trip.destinationPlaceID;
    _originLat = trip.originLat;
    _originLng = trip.originLng;
    _destinationLat = trip.destinationLat;
    _destinationLng = trip.destinationLng;
    _farePrice = trip.farePrice;
    _distanceMeters = trip.distanceMeters;
    _distanceText = trip.distanceText;
    _durationSeconds = trip.durationSeconds;
    _durationText = trip.durationText;
    _clientToDestinationEncodedPoints = trip.clientToDestinationEncodedPoints;
    _requestTime = trip.requestTime;
    _originAddress = trip.originAddress;
    _destinationAddress = trip.destinationAddress;
    _paymentMethod = trip.paymentMethod;
    _clientName = trip.clientName;
    _clientPhone = trip.clientPhone;
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
    _tripStatus = ts;
    if (notify) {
      notifyListeners();
    }
  }

  // downloadData sends a request to download partner's current trip
  Future<void> downloadData({
    bool notify = true,
  }) async {
    Trip? trip = await firebase.functions.getCurrentTrip();
    if(trip != null) {
      fromTripInterface(trip , notify: notify);
      // get client profile image
      ProfileImage pi = await firebase.storage.getClientProfilePicture(trip.clientID);
      updateProfileImage(pi, notify: notify);
    } else {
      clear();
    }
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
