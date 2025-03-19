import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/utils/utils.dart';

class UserModel extends ChangeNotifier {
  late FirebaseService firebase;
  late FirebaseAuth _auth;
  bool _notificationDialogOn = false;
  bool _isUserSignedIn = false;
  bool get isUserSignedIn => _isUserSignedIn;
  String? get email => firebase.auth.currentUser?.email;
  bool? get emailVerified => firebase.auth.currentUser?.emailVerified;
  String? get phoneNumber => firebase.auth.currentUser?.phoneNumber;
  FirebaseAuth get auth => _auth;

  Future<void> sendEmailVerification() async {
    await firebase.auth.currentUser?.sendEmailVerification();
  }

  UserModel(this.firebase) {
    // set user signed in status and listen to their auth state changes
    _isUserSignedIn = _userIsRegistered(firebase.auth.currentUser);
    listenForUserAuthStateChanges();
    _auth = firebase.auth;
    notifyListeners();
  }

  /// Sets a listener that responds to changes in user login status
  /// by updating the isUserSignedIn flag and notifying listeners.
  void listenForUserAuthStateChanges() {
    firebase.auth.authStateChanges().listen((User? user) {
      _setIsUserSignedIn(_userIsRegistered(user));
    });
  }

  void _setIsUserSignedIn(bool ir) {
    _isUserSignedIn = ir;
    notifyListeners();
  }

  // whether the user is signed has an account
  bool _userIsRegistered(User? user) {
    return user != null && user.displayName != null;
  }

  // checks whether notifications are turned on.
  Future<void> requestNotifications(BuildContext context) async {
    // Prompts the user for notification permissions.
    await firebase.messaging.requestPermission();

    // request local notifications
    bool isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationAllowed) {
      if (!_notificationDialogOn) {
        _notificationDialogOn = true;
        // show dialog asking user to share notifications
        await showYesNoDialog(
          context,
          // FIXME: move all copy to a single file or folder and implement translations
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
