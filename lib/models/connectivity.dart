import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';

class ConnectivityModel extends ChangeNotifier {
  late FirebaseService firebase;
  late Connectivity _connectivity;
  late StreamSubscription _connectivitySubscription;
  bool _hasConnection = false;
  bool get hasConnection => _hasConnection;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ConnectivityModel(this.firebase) {
    // start listening for connectivity changes
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((e) async => await checkConnection());
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    await _updateHasConnection();
    _isInitialized = true;
  }

  Future<void> _updateHasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _hasConnection = false;
    }

  }

  // checkConnection tests whether there is a connection
  Future<bool> checkConnection() async {
    bool previousHasConnection = _hasConnection;

    await _updateHasConnection();

    // notify listeners if connection status has changed
    if (previousHasConnection != _hasConnection) {
      notifyListeners();
    }

    return _hasConnection;
  }

  Future<void> alertOffline(BuildContext context, {String? message}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // FIXME: move these to a copy file and add translation
          title: Text("Você está offline."),
          content: Text(
            message ?? "Conecte-se à internet",
            style: TextStyle(color: AppColor.disabled),
          ),
          actions: [
            TextButton(
              child: Text(
                "ok",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
