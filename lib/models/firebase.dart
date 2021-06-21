import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseModel extends ChangeNotifier {
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;
  FirebaseStorage _firebaseStorage;
  FirebaseFunctions _firebaseFunctions;
  bool _isRegistered = false;
  // bool _isRegisteredAsPartner = false;

  FirebaseAuth get auth => _firebaseAuth;
  FirebaseDatabase get database => _firebaseDatabase;
  FirebaseStorage get storage => _firebaseStorage;
  FirebaseFunctions get functions => _firebaseFunctions;
  bool get isRegistered => _isRegistered;

  FirebaseModel({
    @required FirebaseAuth firebaseAuth,
    @required FirebaseDatabase firebaseDatabase,
    @required FirebaseStorage firebaseStorage,
    @required FirebaseFunctions firebaseFunctions,
  }) {
    // set firebase instances
    _firebaseAuth = firebaseAuth;
    _firebaseDatabase = firebaseDatabase;
    _firebaseStorage = firebaseStorage;
    _firebaseFunctions = firebaseFunctions;
    _isRegistered = _userIsRegistered(firebaseAuth.currentUser);
    // _userIsRegisteredAsPartner(firebaseAuth.currentUser)
    //     .then((value) => _isRegisteredAsPartner = value);
    // add listener to track changes in user status
    listenForStatusChanges();
    notifyListeners();
  }

  // listenForStatusChanges sets a listener that responds to changes in user
  // login status by modifying the isRegistered and isRegisteredAsAPartner flags
  // and notifying listeners.
  void listenForStatusChanges() {
    _firebaseAuth.authStateChanges().listen((User user) async {
      if (this._userIsRegistered(user)) {
        _updateIsRegistered(true);
      } else {
        _updateIsRegistered(false);
      }
      // if (await this._userIsRegisteredAsPartner(user)) {
      //   _updateIsRegisteredAsPartner(true);
      // } else {
      //   _updateIsRegisteredAsPartner(false);
      // }
    });
  }

  void _updateIsRegistered(bool ir) {
    _isRegistered = ir;
    notifyListeners();
  }

  // returns true if user is logged in and has a displayName
  // i.e., either created an account through the user app or
  // here.
  bool _userIsRegistered(User user) {
    return user != null && user.displayName != null;
  }
}
