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
  Future<bool> areNotificationsOn() async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // request permission to send notifications. If denied, shows dialog prompting
  // user to open settings and set notifications
  Future<bool> requestNotifications(BuildContext context) async {
    if (await areNotificationsOn()) {
      return true;
    }

    // ask user to activate notifications. We check notificationDialogOn so we
    // don't display stacks of Dialogs in case this function is called multiple
    // successive times
    if (!_notificationDialogOn) {
      _notificationDialogOn = true;
      await showYesNoDialog(
        context,
        title: "Ative as Notificações",
        content:
            "Assim você é avisado quando receber pedidos. Abrir configurações?",
        onPressedYes: () async {
          Navigator.pop(context);
          await SystemSettings.appNotifications();
        },
      );
      _notificationDialogOn = false;
    }

    return await areNotificationsOn();
  }
}
