import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/menu.dart';
import 'package:partner_app/screens/shareLocation.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class HomeArguments {
  FirebaseModel firebase;
  PartnerModel partner;
  GoogleMapsModel googleMaps;
  HomeArguments({
    @required this.firebase,
    @required this.partner,
    @required this.googleMaps,
  });
}

class Home extends StatefulWidget {
  static const routeName = "home";
  final FirebaseModel firebase;
  final PartnerModel partner;
  final GoogleMapsModel googleMaps;

  Home({
    @required this.firebase,
    @required this.partner,
    @required this.googleMaps,
  });

  @override
  HomeState createState() => HomeState();
}

// TODO: turn it into a future that downloads partner data before and shows
// splash screen before displaying final screen. After doing this, assert that
// wallet screen works correclty because recipientID is set.
class HomeState extends State<Home> with WidgetsBindingObserver {
  Future<Position> partnerPositionFuture;
  bool _hasConnection;
  StreamSubscription partnerStatusSubscription;
  bool lockScreen = false;
  Widget buttonChild;

  var _firebaseListener;

  @override
  void initState() {
    super.initState();

    // HomeState uses WidgetsBindingObserver as a mixin. Thus, we can pass it as
    // argument to WidgetsBinding.addObserver. The didChangeAppLifecycleState that
    // we override, is notified whenever an application even occurs (e.g., system
    // puts app in background).
    WidgetsBinding.instance.addObserver(this);

    // trigger _getPartnerPosition
    partnerPositionFuture = _getPartnerPosition();

    // subscribe to changes in partner_status so UI is updated appropriately
    partnerStatusSubscription = widget.firebase.database.onPartnerStatusUpdate(
      widget.firebase.auth.currentUser.uid,
      (e) {
        PartnerStatus partnerStatus = PartnerStatusExtension.fromString(
          e.snapshot.value,
        );
        // update partner model accordingly. This will trigger a tree rebuild
        if (partnerStatus != null) {
          widget.partner.updatePartnerStatus(partnerStatus);
        }
      },
    );

    // add listeners after tree is built and we have context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // use retrieved position to set maps camera view after finishing _getPartnerPosition,
      partnerPositionFuture.then((position) async {
        if (position != null) {
          widget.googleMaps.initialCameraLatLng = LatLng(
            widget.partner.position?.latitude,
            widget.partner.position?.longitude,
          );
        }
      });

      // add listener to FirebaseModel so user is redirected to Start when logs out
      _firebaseListener = () {
        _signOut(context);
      };
      widget.firebase.addListener(_firebaseListener);
    });
  }

  // didChangeAppLifecycleState is notified whenever the system puts the app in
  // the background or returns the app to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // if user stopped sharing location, _getPartnerPosition asks them to reshare
    await _getPartnerPosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.firebase.removeListener(_firebaseListener);
    widget.partner.cancelPositionChangeSubscription();
    if (partnerStatusSubscription != null) {
      partnerStatusSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(context);
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

    return FutureBuilder(
      initialData: null,
      future: partnerPositionFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<Position> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen while waiting for download to succeed
          return Splash(
              text: "Muito bom ter você de volta, " +
                  firebase.auth.currentUser.displayName.split(" ").first +
                  "!");
        }

        // make sure we successfully got user position
        if (snapshot.data == null) {
          return ShareLocation(push: Home.routeName);
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Menu(),
          body: Stack(
            children: [
              // TODO: replace myLocationButton for another icon
              GoogleMap(
                myLocationButtonEnabled: googleMaps.myLocationButtonEnabled,
                myLocationEnabled: googleMaps.myLocationEnabled,
                trafficEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: googleMaps.initialCameraLatLng ??
                      LatLng(-17.217600, -46.874621),
                  zoom: googleMaps.initialZoom ?? 16.5,
                ),
                padding: EdgeInsets.only(
                  top: googleMaps.googleMapsTopPadding ?? screenHeight / 12,
                  bottom:
                      googleMaps.googleMapsBottomPadding ?? screenHeight / 8.5,
                  left: screenWidth / 20,
                  right: screenWidth / 20,
                ),
                onMapCreated: googleMaps.onMapCreatedCallback,
                polylines: Set<Polyline>.of(googleMaps.polylines.values),
                markers: googleMaps.markers,
              ),
              Positioned(
                child: OverallPadding(
                  child: MenuButton(
                      onPressed: lockScreen
                          ? () {}
                          : () {
                              _scaffoldKey.currentState.openDrawer();
                            }),
                ),
              ),
              partner.partnerStatus == PartnerStatus.unavailable
                  ? OverallPadding(
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: AppButton(
                          textData: "Conectar",
                          child: buttonChild,
                          onTapCallBack: lockScreen
                              ? () {}
                              : () async => await connect(context),
                        ),
                      ),
                    )
                  : Container(),
              partner.partnerStatus == PartnerStatus.available
                  ? SlidingUpPanel(
                      panel: OverallPadding(
                        top: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight / 100),
                            Icon(
                              Icons.maximize,
                              color: Colors.black.withOpacity(0.3),
                              size: 30,
                            ),
                            Spacer(),
                            SizedBox(height: screenHeight / 100),
                            RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                text: "R\$",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: reaisFromCents(partner.gains ?? 0),
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " recebidos",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      color: AppColor.disabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight / 50),
                            AppButton(
                              textData: "Desconectar",
                              onTapCallBack: lockScreen
                                  ? () {}
                                  : () async => disconnect(context),
                            ),
                          ],
                        ),
                      ),
                      collapsed: Column(
                        children: [
                          SizedBox(height: screenHeight / 25),
                          buttonChild == null
                              ? Text(
                                  "VOCÊ ESTÁ ONLINE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColor.primaryPink,
                                  ),
                                )
                              : buttonChild,
                        ],
                      ),
                      color: Colors.white,
                      maxHeight: screenHeight / 2.7,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getPartnerPosition() async {
    // Try getting user position. If it returns null, it's because user stopped
    // sharing location. getPosition() will automatically handle that case, asking
    // the user to share again and preventing them from using the app if they
    // don't.
    Position pos = await widget.partner.getPosition(notify: false);
    if (pos == null) {
      return null;
    }
    // if we could get position, make sure to resubscribe to position changes
    // again, as the subscription may have been cancelled if user stopped
    // sharing location.
    widget.partner.updateGeocodingOnPositionChange();
    return pos;
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

  Future<void> connect(BuildContext context) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    // lock screen and display circularProgressIndicator
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      lockScreen = true;
    });

    // send request to connect, thus updating partner's status to 'available'
    // and setting his position
    try {
      await firebase.functions.connect(
        currentLatitude: partner.position.latitude,
        currentLongitude: partner.position.longitude,
      );
    } catch (e) {
      // warn user about failure
      await showOkDialog(
        context: context,
        title: "Algo deu errado",
        content: "Tente novamente mais tarde",
      );
      // unlock screen and hide circularProgressIndicator
      setState(() {
        buttonChild = null;
        lockScreen = false;
      });
      return;
    }

    // clear gains so we can start counting them again
    partner.updateGains(0, notify: false);

    // update status locally, since the database listener can be flaky sometimes
    partner.updatePartnerStatus(PartnerStatus.available);

    // unlock screen and hide circularProgressIndicator
    setState(() {
      buttonChild = null;
      lockScreen = false;
    });
  }

  Future<void> disconnect(BuildContext context) async {
    // show dialog asking user if the want to disconnect
    await showYesNoDialog(
      context,
      title: "Deseja se desconectar?",
      content: "você irá parar de receber pedidos de corridas",
      onPressedYes: () async {
        // if partner indeed choses to disconnect, pop off dialog
        Navigator.pop(context);

        // lock screen
        setState(() {
          lockScreen = true;
          buttonChild = CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColor.primaryPink,
            ),
          );
        });

        // send request to disconnect partner
        FirebaseModel firebase = Provider.of<FirebaseModel>(
          context,
          listen: false,
        );
        try {
          await firebase.functions.disconnect();
        } catch (e) {
          // warn user about failure
          await showOkDialog(
            context: context,
            title: "Algo deu errado",
            content: "Tente novamente mais tarde",
          );
          // unlock screen
          setState(() {
            lockScreen = false;
            buttonChild = null;
          });
          return;
        }

        // manually update status locally, since the listener can be flaky
        PartnerModel partner = Provider.of<PartnerModel>(
          context,
          listen: false,
        );
        partner.updatePartnerStatus(PartnerStatus.unavailable);

        // unlock screen
        setState(() {
          lockScreen = false;
          buttonChild = null;
        });
      },
    );
  }
}
