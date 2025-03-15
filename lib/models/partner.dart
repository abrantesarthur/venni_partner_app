import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/services/firebase.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseStorage.dart';
import 'package:partner_app/vendors/permissionHandler.dart';

class ProfileImage {
  late ImageProvider<Object> file;
  late String name;

  ProfileImage({ required this.file,required this.name});
}

class PartnerModel extends ChangeNotifier {
  late FirebaseService firebase;
  String? _id;
  String? _name;
  String? _lastName;
  String? _cpf;
  Gender? _gender;
  int? _memberSince;
  String? _phoneNumber;
  double? _rating;
  int? _totalTrips;
  String? _pagarmeRecipientID;
  PartnerStatus? _partnerStatus;
  AccountStatus? _accountStatus;
  String? _denialReason;
  String? _lockReason;
  Vehicle? _vehicle;
  ProfileImage? _profileImage;
  bool? _crlvSubmitted = false;
  bool? _cnhSubmitted = false;
  bool? _photoWithCnhSubmitted = false;
  bool? _profilePhotoSubmitted = false;
  bool? _bankAccountSubmitted = false;
  int? _amountOwed;
  BankAccount? _bankAccount;
  Position? _position;
  int? _gains;
  bool _acceptedTrip = false;
  bool _sendPositionToFirebase = false;


  // getters
  String? get id => _id;
  String? get name => _name;
  String? get lastName => _lastName;
  String? get cpf => _cpf;
  Gender? get gender => _gender;
  int? get memberSince => _memberSince;
  String? get phoneNumber => _phoneNumber;
  double? get rating => _rating;
  int? get totalTrips => _totalTrips;
  String? get pagarmeRecipientID => _pagarmeRecipientID;
  PartnerStatus? get partnerStatus => _partnerStatus;
  AccountStatus? get accountStatus => _accountStatus;
  String? get denialReason => _denialReason;
  String? get lockReason => _lockReason;
  Vehicle? get vehicle => _vehicle;
  ProfileImage? get profileImage => _profileImage;
  bool? get crlvSubmitted => _crlvSubmitted;
  bool? get cnhSubmitted => _cnhSubmitted;
  bool? get photoWithCnhSubmitted => _photoWithCnhSubmitted;
  bool? get profilePhotoSubmitted => _profilePhotoSubmitted;
  bool? get bankAccountSubmitted => _bankAccountSubmitted;
  int? get amountOwed => _amountOwed;
  BankAccount? get bankAccount => _bankAccount;
  Position? get position => _position;
  int? get gains => _gains;
  bool get acceptedTrip => _acceptedTrip;
  int availableSince = DateTime.now().millisecondsSinceEpoch;
  int busySince = DateTime.now().millisecondsSinceEpoch;

  PartnerModel(this.firebase);

  void sendPositionToFirebase(bool v) {
    _sendPositionToFirebase = v;
  }

  void setAcceptedTrip(bool v, {bool notify = true}) {
    _acceptedTrip = v;
    if (notify) {
      notifyListeners();
    }
  }

  void updateAccountStatus(AccountStatus acs) {
    _accountStatus = acs;
    notifyListeners();
  }

  void updatePartnerStatus(PartnerStatus ps) {
    _partnerStatus = ps;
    notifyListeners();
  }

  void updateCrlvSubmitted(bool value) {
    _crlvSubmitted = value;
    notifyListeners();
  }

  void updateCnhSubmitted(bool value) {
    _cnhSubmitted = value;
    notifyListeners();
  }

  void updatePhotoWithCnhSubmitted(bool value) {
    _photoWithCnhSubmitted = value;
    notifyListeners();
  }

  void updateProfilePhotoSubmitted(bool value) {
    _profilePhotoSubmitted = value;
    notifyListeners();
  }

  void updateBankAccountSubmitted(bool value) {
    _bankAccountSubmitted = value;
    notifyListeners();
  }

  void updateBankAccount(BankAccount ba) {
    _bankAccount = ba;
    notifyListeners();
  }

  void updateGains(int g, {bool notify = true}) {
    _gains = g;
    if (notify) {
      notifyListeners();
    }
  }

  void increaseGainsBy(int v) {
    _gains = (_gains ?? 0) + v;
    notifyListeners();
  }

  void setProfileImage(
    ProfileImage img, {
    bool notify = true,
  }) {
    _profileImage = img;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> downloadData({
    bool notify = true,
  }) async {
    // download partner profile photo
    firebase.storage
        .getPartnerProfilePicture(firebase.auth.currentUser?.uid)
        .then((value) => this.setProfileImage(value, notify: notify));

    // get partner data
    PartnerInterface? partnerInterface =
        await firebase.database.getPartnerFromID(
      firebase.auth.currentUser?.uid,
    );

    this.fromPartnerInterface(partnerInterface, notify: notify);
  }

  Future<Position?> getPosition(
    BuildContext context, {
    bool notify = true,
  }) async {
    Position? partnerPos;
    // determineUserPosition may throw an error which should be handled by the caller
    partnerPos = await determineUserPosition(context);

    _position = partnerPos;
    if (notify) {
      notifyListeners();
    }

    return _position;
  }

  void resetLocationService() {
    BackgroundLocation.stopLocationService();
    BackgroundLocation.startLocationService(distanceFilter: 10);
  }

  // handlePositionUpdates starts listener that gets triggered whenever partner
  // moves at least 20 meters. This listener, in turn, updates PartnerModel position,
  // reports it to firebase if _sendPositionToFirebase flag is set, and animates
  // google maps camera if _animateMapsCamera flag is set. THis is to better
  // display partner position in relation to either trip's origin or destination
  // depending on whether there is a trip with 'waitingPartner' or 'inProgress'
  // status.
  void handlePositionUpdates(
    GoogleMapsModel googleMaps,
    TripModel trip,
  ) {
    try {
      // reset location service to flush out any previous listeners set by "getLocationUpdates"
      // if partner is near client, we update location at higher rights so client
      // can view partner arriving better
      resetLocationService();
      // subscribe to changes in position, updating position and geocoding on changes
      BackgroundLocation.getLocationUpdates((p) async {
        final position = Position(
          longitude: p.longitude,
          latitude: p.latitude,
          timestamp: DateTime.now(),
          accuracy: p.accuracy,
          altitude: p.altitude,
          heading: 0.0,
          speed: p.speed,
          speedAccuracy: 0.0,
          headingAccuracy: 0.0,
          altitudeAccuracy: 0.0,
        );
        _position = position;

        // if sendPosition flag is set, report partner position to firebase. This
        // flag is set when partner becomes 'available' so that we always know where
        // they are located and matching algorithm can function properly
        // FIXME: ensure that position and user are not null!
        if (_sendPositionToFirebase && firebase.auth.currentUser != null) {
          await firebase.database.updatePartnerPosition(
            partnerID: firebase.auth.currentUser!.uid,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
        // update the maps camera view to center on the partner, from the partner
        // to origin, or from partner to destination, depending on partner's
        // status and on whether trip is 'waitingPartner' or 'inProgress'.
        // first, we get the partner position
        LatLng partnerPosition = LatLng(
          position.latitude,
          position.longitude,
        );
        LatLng? secondCoordinates;
        // if partner is going to pick the client, redraw bounds between partner and origin
        if (trip.tripStatus == TripStatus.waitingPartner) {
          secondCoordinates = LatLng(trip.originLat, trip.originLng);
          // if partner is driving the client, redraw bonds between partner and destination
        } else if (trip.tripStatus == TripStatus.inProgress) {
          secondCoordinates = LatLng(trip.destinationLat, trip.destinationLng);
        }

        if (secondCoordinates != null) {
          googleMaps.animateCameraToBounds(partnerPosition, secondCoordinates);
        } else {
          // if partner is not handling a trip, redraw view centered on his position
          googleMaps.animateCameraToPosition(partnerPosition);
        }

        // notifyListeners triggers a rebuild in PartnerBusy, which uses the
        // new partner position to decide whether to display a "cancel trip" or
        // a "start trip" button.
        notifyListeners();
      });
    } catch (_) {}
  }

  void fromPartnerInterface(
    PartnerInterface? pi, {
    bool notify = true,
  }) {
    if (pi == null) {
      clear();
    } else {
      _id = pi.id;
      _name = pi.name;
      _lastName = pi.lastName;
      _cpf = pi.cpf;
      _gender = pi.gender;
      _memberSince = pi.memberSince;
      _phoneNumber = pi.phoneNumber;
      _rating = pi.rating;
      _totalTrips = pi.totalTrips;
      _pagarmeRecipientID = pi.pagarmeRecipientID;
      _partnerStatus = pi.partnerStatus;
      _accountStatus = pi.accountStatus;
      _denialReason = pi.denialReason;
      _lockReason = pi.lockReason;
      _vehicle = pi.vehicle;
      _cnhSubmitted =
          pi.submittedDocuments == null ? false : pi.submittedDocuments.cnh;
      _crlvSubmitted =
          pi.submittedDocuments == null ? false : pi.submittedDocuments.crlv;
      _photoWithCnhSubmitted = pi.submittedDocuments == null
          ? false
          : pi.submittedDocuments.photoWithCnh;
      _profilePhotoSubmitted = pi.submittedDocuments == null
          ? false
          : pi.submittedDocuments.profilePhoto;
      _bankAccountSubmitted = pi.submittedDocuments == null
          ? false
          : pi.submittedDocuments.bankAccount;
      _amountOwed = pi.amountOwed;
      _bankAccount = pi.bankAccount;
      _gains = (_gains ?? 0) > 0 ? _gains : 0;
    }
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  void clear() {
    _id = null;
    _name = null;
    _lastName = null;
    _cpf = null;
    _gender = null;
    _memberSince = null;
    _phoneNumber = null;
    _rating = null;
    _totalTrips = null;
    _pagarmeRecipientID = null;
    _partnerStatus = null;
    _accountStatus = null;
    _denialReason = null;
    _lockReason = null;
    _vehicle = null;
    _profileImage = null;
    _crlvSubmitted = null;
    _cnhSubmitted = null;
    _photoWithCnhSubmitted = null;
    _profilePhotoSubmitted = null;
    _bankAccountSubmitted = null;
    _amountOwed = null;
    _bankAccount = null;
  }
}
