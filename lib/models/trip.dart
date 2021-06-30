import 'package:flutter/material.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';

class TripModel extends ChangeNotifier {
  String _clientID;
  TripStatus _tripStatus;
  String _originPlaceID;
  String _destinationPlaceID;
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

  String get clientID => _clientID;
  TripStatus get tripStatus => _tripStatus;
  String get originPlaceID => _originPlaceID;
  String get destinationPlaceID => _destinationPlaceID;
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

  void fromTripInterface(Trip t) {
    if (t != null) {
      _clientID = t.clientID;
      _tripStatus = t.tripStatus;
      _originPlaceID = t.originPlaceID;
      _destinationPlaceID = t.destinationPlaceID;
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
    } else {
      clear();
    }
    notifyListeners();
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
    notifyListeners();
  }
}
