import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class ConnectivityModel extends ChangeNotifier {
  bool _hasConnection;
  Connectivity _connectivity;
  StreamSubscription _connectivitySubscription;

  bool get hasConnection => _hasConnection;

  ConnectivityModel() {
    // start listening for connectivity changes
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((e) async => await checkConnection());
    checkConnection();
  }

  @override
  void dispose() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription.cancel();
    }
    super.dispose();
  }

  // checkConnection tests whether there is a connection
  Future<bool> checkConnection() async {
    bool previousHasConnection = _hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _hasConnection = true;
      } else {
        _hasConnection = false;
      }
    } on SocketException catch (_) {
      _hasConnection = false;
    }

    // notify listeners if connection status has changed
    if (previousHasConnection != _hasConnection) {
      notifyListeners();
    }

    return _hasConnection;
  }

  Future<void> alertWhenOffline(BuildContext context, {String message}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
