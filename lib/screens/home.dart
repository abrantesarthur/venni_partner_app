import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  static const routeName = "home";
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with WidgetsBindingObserver {
  bool _hasConnection;

  @override
  Widget build(BuildContext context) {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    // if connectivity has changed
    if (_hasConnection != connectivity.hasConnection) {
      // update _hasConnectivity
      _hasConnection = connectivity.hasConnection;
      // if connectivity changed from offline to online
      if (connectivity.hasConnection) {
        // download user data
        //  user.downloadData(firebase);
      }
    }

    return Scaffold(
      body: Stack(
        children: [Center(child: Text("home"))],
      ),
    );
  }
}
