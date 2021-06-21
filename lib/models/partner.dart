import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseStorage.dart';

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
  String _pagarmeRecipientID;
  PartnerStatus _partnerStatus;
  AccountStatus _accountStatus;
  String _denialReason;
  String _lockReason;
  Vehicle _vehicle;
  ProfileImage _profileImage;
  bool _crlvSubmitted = false;
  bool _cnhSubmitted = false;
  bool _photoWithCnhSubmitted = false;
  bool _profilePhotoSubmitted = false;
  bool _bankAccountSubmitted = false;
  int _amountOwed;

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
  String get pagarmeRecipientID => _pagarmeRecipientID;
  PartnerStatus get partnerStatus => _partnerStatus;
  AccountStatus get accountStatus => _accountStatus;
  String get denialReason => _denialReason;
  String get lockReason => _lockReason;
  Vehicle get vehicle => _vehicle;
  ProfileImage get profileImage => _profileImage;
  bool get crlvSubmitted => _crlvSubmitted;
  bool get cnhSubmitted => _cnhSubmitted;
  bool get photoWithCnhSubmitted => _photoWithCnhSubmitted;
  bool get profilePhotoSubmitted => _profilePhotoSubmitted;
  bool get bankAccountSubmitted => _bankAccountSubmitted;
  int get amountOwed => _amountOwed;

  void updateAccountStatus(AccountStatus acs) {
    _accountStatus = acs;
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

  void setProfileImage(
    ProfileImage img, {
    bool notify = true,
  }) {
    _profileImage = img;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> downloadData(
    FirebaseModel firebase, {
    bool notify = true,
  }) async {
    // download partner profile photo
    firebase.storage
        .getPartnerProfilePicture(firebase.auth.currentUser.uid)
        .then((value) => this.setProfileImage(value, notify: notify));

    // get partner data
    PartnerInterface partnerInterface =
        await firebase.database.getPartnerFromID(firebase.auth.currentUser.uid);
    this.fromPartnerInterface(partnerInterface, notify: notify);
  }

  void fromPartnerInterface(
    PartnerInterface pi, {
    bool notify = true,
  }) {
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
      if (notify) {
        notifyListeners();
      }
    }
  }
}
