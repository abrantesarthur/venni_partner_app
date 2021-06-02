import 'package:flutter/material.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

class ProfileImage {
  final ImageProvider<Object> file;
  final String name;

  ProfileImage({@required this.file, @required this.name});
}

class PartnerModel extends ChangeNotifier {
  String _id;
  String _name;
  String _lastName;
  String _cpf;
  Gender _gender;
  int _memberSince;
  String _phoneNumber;
  double _rating;
  int _totalTrips;
  String _pagarmeReceiverID;
  PartnerStatus _partnerStatus;
  AccountStatus _accountStatus;
  String _denialReason;
  String _lockReason;
  Vehicle _vehicle;

  // getters
  String get id => _id;
  String get name => _name;
  String get lastName => _lastName;
  String get cpf => _cpf;
  Gender get gender => _gender;
  int get memberSince => _memberSince;
  String get phoneNumber => _phoneNumber;
  double get rating => _rating;
  int get totalTrips => _totalTrips;
  String get pagarmeReceiverID => _pagarmeReceiverID;
  PartnerStatus get partnerStatus => _partnerStatus;
  AccountStatus get accountStatus => _accountStatus;
  String get denialReason => _denialReason;
  String get lockReason => _lockReason;
  Vehicle get vehicle => _vehicle;

  void fromPartnerInterface(PartnerInterface pi) {
    if (pi != null) {
      _id = pi.id;
      _name = pi.name;
      _lastName = pi.lastName;
      _cpf = pi.cpf;
      _gender = pi.gender;
      _memberSince = pi.memberSince;
      _phoneNumber = pi.phoneNumber;
      _rating = pi.rating;
      _totalTrips = pi.totalTrips;
      _pagarmeReceiverID = pi.pagarmeReceiverID;
      _partnerStatus = pi.partnerStatus;
      _accountStatus = pi.accountStatus;
      _denialReason = pi.denialReason;
      _lockReason = pi.lockReason;
      _vehicle = pi.vehicle;
      notifyListeners();
    }
  }
}
