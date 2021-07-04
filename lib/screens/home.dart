import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/partnerAvailable.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/menu.dart';
import 'package:partner_app/screens/shareLocation.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/partnerBusy.dart';
import 'package:partner_app/widgets/partnerRequested.dart';
import 'package:partner_app/widgets/partnerUnavailable.dart';
import 'package:provider/provider.dart';

class HomeArguments {
  FirebaseModel firebase;
  PartnerModel partner;
  GoogleMapsModel googleMaps;
  TimerModel timer;
  TripModel trip;
  ConnectivityModel connectivity;
  HomeArguments({
    @required this.firebase,
    @required this.partner,
    @required this.googleMaps,
    @required this.timer,
    @required this.trip,
    @required this.connectivity,
  });
}

class Home extends StatefulWidget {
  static const routeName = "home";
  final FirebaseModel firebase;
  final PartnerModel partner;
  final GoogleMapsModel googleMaps;
  final TimerModel timer;
  final TripModel trip;
  final ConnectivityModel connectivity;

  Home({
    @required this.firebase,
    @required this.partner,
    @required this.googleMaps,
    @required this.timer,
    @required this.trip,
    @required this.connectivity,
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
  StreamSubscription tripStatusSubscription;
  bool lockScreen = false;
  Widget buttonChild;

  var _firebaseListener;

  @override
  void initState() {
    super.initState();

    _hasConnection = widget.connectivity.hasConnection;

    // HomeState uses WidgetsBindingObserver as a mixin. Thus, we can pass it as
    // argument to WidgetsBinding.addObserver. The didChangeAppLifecycleState that
    // we override, is notified whenever an application even occurs (e.g., system
    // puts app in background).
    WidgetsBinding.instance.addObserver(this);

    // trigger _getPartnerPosition
    partnerPositionFuture = _getPartnerPosition(
      widget.firebase,
      widget.googleMaps,
      widget.trip,
    );

    // subscribe to changes in partner_status so UI is updated appropriately
    partnerStatusSubscription = widget.firebase.database.onPartnerStatusUpdate(
      widget.firebase.auth.currentUser.uid,
      onPartnerStatusUpdate,
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
    await _getPartnerPosition(
      widget.firebase,
      widget.googleMaps,
      widget.trip,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.firebase.removeListener(_firebaseListener);
    widget.partner.cancelPositionChangeSubscription();
    if (partnerStatusSubscription != null) {
      partnerStatusSubscription.cancel();
    }
    if (tripStatusSubscription != null) {
      tripStatusSubscription.cancel();
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
    // very important not listen for PartnerModel! We already have a Consumer
    // for that and so that GoogleMaps doesn't get rebuilt every tiem there is a
    // change to partners. This would delete markers, and reset the view, and just
    // do a mess.
    GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    // if connectivity has changed
    if (_hasConnection != connectivity.hasConnection) {
      // update _hasConnectivity
      _hasConnection = connectivity.hasConnection;
      // if connectivity changed from offline to online
      if (connectivity.hasConnection) {
        try {
          // download partner data
          widget.partner.downloadData(firebase, notify: false);
          // subscribe to changes in partner_status so UI is updated appropriately
          // this will also download trip information if partner is busy
          if (partnerStatusSubscription != null) {
            partnerStatusSubscription.cancel();
          }
          partnerStatusSubscription =
              widget.firebase.database.onPartnerStatusUpdate(
            widget.firebase.auth.currentUser.uid,
            onPartnerStatusUpdate,
          );
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
                      googleMaps.googleMapsBottomPadding ?? screenHeight / 10,
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
              Consumer<PartnerModel>(
                builder: (context, p, _) => Stack(
                  children: [
                    p.partnerStatus == PartnerStatus.unavailable
                        ? PartnerUnavailable()
                        : Container(),
                    p.partnerStatus == PartnerStatus.available
                        ? PartnerAvailable()
                        : Container(),
                    // TODO: play a sound
                    // TODO: retrieve client informatin later
                    p.partnerStatus == PartnerStatus.requested
                        ? PartnerRequested()
                        : Container(),
                    // TODO: PartnerBusy should return a Future that only resolves
                    // once we retrieve the client information. Also, I should start thinking
                    // or at least researching about how firebase deals with connectivity issues.
                    p.partnerStatus == PartnerStatus.busy
                        ? PartnerBusy(
                            trip: widget.trip,
                            partner: widget.partner,
                          )
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getPartnerPosition(
    FirebaseModel firebase,
    GoogleMapsModel googleMaps,
    TripModel trip,
  ) async {
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
    widget.partner.handlePositionUpdates(
      firebase,
      googleMaps,
      trip,
    );
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

  void onPartnerStatusUpdate(Event e) async {
    PartnerStatus newPartnerStatus = PartnerStatusExtension.fromString(
      e.snapshot.value,
    );
    if (newPartnerStatus != null) {
      // if partner has been requested, kick off 10s timer. The TimerModel
      // is passed to the PartnerRequested widget which uses its 'remainingSeconds'
      // property to display how much time the partner has to accept the trip.
      // Once the timer stops, if the partner hasn't accepted
      // the trip request we call 'declineTrip' and udpate their status locally
      if (newPartnerStatus == PartnerStatus.requested) {
        widget.timer.kickOff(
            durationSeconds: 10,
            callback: () {
              // TODO: adjust google maps height depending on partner status
              // and thus on new UI configuration

              // if partner did not accept trip after 10s
              if (!widget.partner.acceptedTrip) {
                // set partner status to available so that UI is updated and
                // they can no longer accept trip requests. It's ok to do this
                // without sending request to firebase. The trip protocol
                // guarantees that 'confirmTrip' will set a partner
                // available again if they fail to accept a trip.
                widget.partner.updatePartnerStatus(PartnerStatus.available);
              } else {
                // if partner accepted trip, set acceptedTrip to false so next time
                // this method is called, it is to set partner available.
                widget.partner.setAcceptedTrip(false);
              }
            });
      }
      if (newPartnerStatus == PartnerStatus.busy) {
        // download trip data before updating PartnerModel status and thus UI
        await widget.trip.downloadData(widget.firebase, notify: false);
        // cancel any previous trip status subscriptions
        if (tripStatusSubscription != null) {
          tripStatusSubscription.cancel();
        }
        // listen for trip status updates calling a function that redraws markers
        // whenever a new partner is heard
        tripStatusSubscription = widget.firebase.database.onTripStatusUpdate(
          widget.trip.clientID,
          onTripStatusUpdate,
        );

        // constantly update maps camera view as partner moves close to origin or destination
        widget.partner.animateMapsCameraView(true);
      } else {
        // if partner is not busy, stop animating maps camera view
        widget.partner.animateMapsCameraView(false);
        // undraw polylines
        widget.googleMaps.undrawMarkers();
        // cancel any previous trip status subscriptions
        if (tripStatusSubscription != null) {
          tripStatusSubscription.cancel();
        }
        // clear trip model
        widget.trip.clear();
      }

      // if partner is anything but 'unavailable', constantly report his position. We already do
      // this when calling 'connect', but it's important to do here too in case
      // the partner relaunches the app.
      if (newPartnerStatus != PartnerStatus.unavailable) {
        widget.partner.sendPositionToFirebase(true);
      }

      // if partner is 'unavailable', stop reporting his position. We already do
      // this when calling 'dissconnect', but it's important to do here too in case
      // the partner relaunches the app.
      if (newPartnerStatus == PartnerStatus.unavailable) {
        widget.partner.sendPositionToFirebase(false);
      }

      // update partner model accordingly. This will trigger a tree rebuild
      widget.partner.updatePartnerStatus(newPartnerStatus);
    }
  }

  void onTripStatusUpdate(Event e) async {
    TripStatus newTripStatus = TripStatusExtension.fromString(
      e.snapshot.value,
    );
    widget.trip.updateTripStatus(newTripStatus);

    // update trip status
    // draw markers
    if (newTripStatus == TripStatus.waitingPartner) {
      // if trip is 'waitingPartner', draw origin marker so partner knows
      // where to pick up the client
      await widget.googleMaps.drawOriginMarker(context);
    } else if (newTripStatus == TripStatus.inProgress) {
      // if trip is 'inProgress', draw destination marker so partner
      // knows where to drop off the client
      await widget.googleMaps.drawDestinationMarker(context);
    }
  }
}
