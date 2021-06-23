import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/menu.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class HomeArguments {
  FirebaseModel firebase;
  HomeArguments({@required this.firebase});
}

class Home extends StatefulWidget {
  static const routeName = "home";
  final FirebaseModel firebase;

  Home({@required this.firebase});

  @override
  HomeState createState() => HomeState();
}

// TODO: turn it into a future that downloads partner data before and shows
// splash screen before displaying final screen. After doing this, assert that
// wallet screen works correclty because recipientID is set.
class HomeState extends State<Home> with WidgetsBindingObserver {
  bool _hasConnection;

  var _firebaseListener;

  @override
  void initState() {
    super.initState();

    // add listeners after tree is built and we have context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // add listener to FirebaseModel so user is redirected to Start when logs out
      _firebaseListener = () {
        _signOut(context);
      };
      widget.firebase.addListener(_firebaseListener);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.firebase.removeListener(_firebaseListener);
    super.dispose();
  }

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

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    if (!firebase.isRegistered) {
      // clear partner model
      partner.clear();
      Navigator.pushNamedAndRemoveUntil(
        context,
        Start.routeName,
        (_) => false,
      );
    }
  }
}
