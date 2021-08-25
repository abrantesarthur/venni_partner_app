import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:system_settings/system_settings.dart';

class FirebaseModel extends ChangeNotifier {
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;
  FirebaseStorage _firebaseStorage;
  FirebaseFunctions _firebaseFunctions;
  FirebaseMessaging _firebaseMessaging;
  FirebaseAnalytics _firebaseAnalytics;
  bool _isRegistered = false;
  bool _notificationDialogOn = false;

  FirebaseAuth get auth => _firebaseAuth;
  FirebaseDatabase get database => _firebaseDatabase;
  FirebaseStorage get storage => _firebaseStorage;
  FirebaseFunctions get functions => _firebaseFunctions;
  FirebaseMessaging get messaging => _firebaseMessaging;
  FirebaseAnalytics get analytics => _firebaseAnalytics;
  bool get isRegistered => _isRegistered;

  FirebaseModel({
    @required FirebaseAuth firebaseAuth,
    @required FirebaseDatabase firebaseDatabase,
    @required FirebaseStorage firebaseStorage,
    @required FirebaseFunctions firebaseFunctions,
    @required FirebaseMessaging firebaseMessaging,
    @required FirebaseAnalytics firebaseAnalytics,
  }) {
    // set firebase instances
    _firebaseAuth = firebaseAuth;
    _firebaseDatabase = firebaseDatabase;
    _firebaseStorage = firebaseStorage;
    _firebaseFunctions = firebaseFunctions;
    _firebaseMessaging = firebaseMessaging;
    _firebaseAnalytics = firebaseAnalytics;
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

  // checks whether notifications are turned on.
  Future<void> requestNotifications(BuildContext context) async {
    // request push notifications
    await _firebaseMessaging.requestPermission();

    // request local notifications
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      if (!_notificationDialogOn) {
        _notificationDialogOn = true;
        // show dialog asking user to share notifications
        await showYesNoDialog(
          context,
          title: "Ative as Notificações",
          content:
              "Assim você é avisado quando receber pedidos. Abrir configurações?",
          onPressedYes: () async {
            Navigator.pop(context);
            await AwesomeNotifications().requestPermissionToSendNotifications();
          },
        );
        _notificationDialogOn = false;
      }
    }
  }
}
