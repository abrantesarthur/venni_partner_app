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
    if (_userIsRegistered(firebaseAuth.currentUser)) {
      _isRegistered = true;
    } else {
      _isRegistered = false;
    }

    // add listener to track changes in user status
    listenForStatusChanges();
    notifyListeners();
  }

  // listenForStatusChanges responds to changes in user login status
  // by modifying the isRegistered flag and notifying listeners.
  void listenForStatusChanges() {
    _firebaseAuth.authStateChanges().listen((User user) {
      if (this._userIsRegistered(user)) {
        _updateIsRegistered(true);
      } else {
        _updateIsRegistered(false);
      }
    });
  }

  void _updateIsRegistered(bool isRegistered) {
    _isRegistered = isRegistered;
    notifyListeners();
  }

  // returns true if user is logged in and has a displayName
  // i.e., went through the registration process.
  bool _userIsRegistered(User user) {
    return user != null && user.displayName != null;
  }
}
