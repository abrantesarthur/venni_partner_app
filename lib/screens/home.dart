import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/menu.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  static const routeName = "home";
  @override
  HomeState createState() => HomeState();
}

// TODO: turn it into a future that downloads partner data before and shows
// splash screen before displaying final screen. After doing this, assert that
// wallet screen works correclty because recipientID is set.
class HomeState extends State<Home> with WidgetsBindingObserver {
  bool _hasConnection;

  @override
  Widget build(BuildContext context) {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    PartnerModel partner = Provider.of<PartnerModel>(context);
    GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    // if connectivity has changed
    if (_hasConnection != connectivity.hasConnection) {
      // update _hasConnectivity
      _hasConnection = connectivity.hasConnection;
      // if connectivity changed from offline to online
      if (connectivity.hasConnection) {
        // download partner data
        try {
          partner.downloadData(firebase, notify: false);
        } catch (_) {}
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Menu(),
      body: Stack(
        children: [
          Container(
            color: AppColor.primaryPink,
            child: Center(
              child: Text(
                "home",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            child: OverallPadding(
              child: MenuButton(onPressed: () {
                _scaffoldKey.currentState.openDrawer();
              }),
            ),
          ),
        ],
      ),
    );
  }
}
