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
  bool _crlvSubmitted;
  bool _cnhSubmitted;
  bool _photoWithCnhSubmitted;
  bool _profilePhotoSubmitted;
  bool _bankInfoSubmitted;

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
  bool get crlvSubmitted => _crlvSubmitted;
  bool get cnhSubmitted => _cnhSubmitted;
  bool get photoWithCnhSubmitted => _photoWithCnhSubmitted;
  bool get profilePhotoSubmitted => _profilePhotoSubmitted;
  bool get bankInfoSubmitted => _bankInfoSubmitted;

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

  void updateBankInfoSubmitted(bool value) {
    _bankInfoSubmitted = value;
    notifyListeners();
  }

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
      _bankInfoSubmitted = pi.submittedDocuments == null
          ? false
          : pi.submittedDocuments.bankInfo;

      notifyListeners();
    }
  }
}
