import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/accountLocked.dart';
import 'package:partner_app/screens/partnerAvailable.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/vendors/firebaseAnalytics.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/menu.dart';
import 'package:partner_app/screens/shareLocation.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/vendors/geolocator.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/partnerBusy.dart';
import 'package:partner_app/widgets/partnerRequested.dart';
import 'package:partner_app/widgets/partnerUnavailable.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

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
  StreamSubscription accountStatusSubscription;
  bool lockScreen = false;
  Widget buttonChild;
  VoidCallback didChangeAppLifecycleCallback;

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
    partnerPositionFuture = _getPartnerPosition();

    // subscribe to changes in partner_status so UI is updated appropriately
    partnerStatusSubscription = widget.firebase.database.onPartnerStatusUpdate(
      widget.firebase.auth.currentUser.uid,
      onPartnerStatusUpdate,
    );

    // subscribe to changes in account_status so we know when partner is blocked
    accountStatusSubscription = widget.firebase.database.onAccountStatusUpdate(
      widget.firebase.auth.currentUser.uid,
      onAccountStatusUpdate,
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

      await ensureNotificationsAreOn();

      try {
        String token = await widget.firebase.messaging.getToken();
        await saveTokenToDatabase(token);

        // Any time the token refreshes, store this in the database too.
        FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
      } catch (_) {}

      // keep app alive
      Wakelock.enable();
    });
  }

  // didChangeAppLifecycleState is notified whenever the system puts the app in
  // the background or returns the app to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // if user stopped sharing location, didChangeAppLifecycleCallback should
    // ask them to reshare. The function is only defined once the tree has been
    // built though, to avoid exceptions of trying to ask for location permission
    // simultaneously. After all, we already ask for them in initState.
    if (didChangeAppLifecycleCallback != null) {
      didChangeAppLifecycleCallback();
    }
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
    if (accountStatusSubscription != null) {
      accountStatusSubscription.cancel();
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

          // save fcm token to database
          firebase.messaging.getToken().then(
                (token) => saveTokenToDatabase(token),
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
          return ShareLocation(
            routeToPush: Home.routeName,
            routeArguments: HomeArguments(
              firebase: firebase,
              partner: widget.partner,
              googleMaps: widget.googleMaps,
              timer: widget.timer,
              trip: widget.trip,
              connectivity: connectivity,
            ),
          );
        }

        // after having waited succesfully, define didChangeAppLifecycleCallback
        // so if user stops sharing location, we will know.
        if (didChangeAppLifecycleCallback == null) {
          didChangeAppLifecycleCallback = () async {
            // make sure user didn't disable location sharing or otifications
            await ensureLocationSharingIsOn();
            await ensureNotificationsAreOn();
          };
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
                builder: (context, p, _) =>
                    p.accountStatus == AccountStatus.locked
                        ? Stack(
                            children: [AccountLocked()],
                          )
                        : Stack(
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

  // ensureNotificationsAreOn enforces that the partner must have notifications.
  // Disconnect partner if notifications are off and partner is not busy.
  // if partner is busy, he will be disconnected as soon as his current trip is over.
  // by onPartnerStatusUpdate
  Future<void> ensureNotificationsAreOn() async {
    bool notificationsOn = await widget.firebase.requestNotifications(context);

    if ((notificationsOn == null || !notificationsOn) &&
        widget.partner.partnerStatus == PartnerStatus.available) {
      try {
        await widget.firebase.functions.disconnect();
      } catch (_) {}
    }
  }

  // ensureLocationSharing is on disconnects partner if they are available and
  // stops sharing location
  Future<void> ensureLocationSharingIsOn() async {
    Position partnerPos;
    try {
      partnerPos = await determineUserPosition();
    } catch (_) {
      partnerPos = await _getPartnerPosition();
    }
    if (partnerPos == null &&
        widget.partner.partnerStatus == PartnerStatus.available) {
      try {
        await widget.firebase.functions.disconnect();
      } catch (e) {}
    }
  }

  // save firebase cloud messaging token on database
  Future<void> saveTokenToDatabase(String token) async {
    await widget.firebase.database.updateFCMToken(
      uid: widget.firebase.auth.currentUser.uid,
      token: token,
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
    widget.partner.handlePositionUpdates(
      widget.firebase,
      widget.googleMaps,
      widget.trip,
    );
    return pos;
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    if (!firebase.isRegistered) {
      // clear relevant models
      partner.clear();
      widget.trip.clear();
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
        // before kicking off timer, set acceptedTrip to false. If partner accepts
        // the trip before the timer goes out, acceptedTrip is set true and the
        // callback won't set the partner available.
        widget.partner.setAcceptedTrip(false, notify: false);
        widget.timer.kickOff(
          durationSeconds: 10,
          callback: () {
            // if partner did not accept trip after 10s
            if (!widget.partner.acceptedTrip) {
              // set partner status to available so that UI is updated and
              // they can no longer accept trip requests. It's ok to do this
              // without sending request to firebase. The trip protocol
              // guarantees that 'confirmTrip' will set a partner
              // available again if they fail to accept a trip.
              widget.partner.updatePartnerStatus(PartnerStatus.available);

              // log event
              try {
                widget.firebase.analytics.logPartnerIgnoreRequest();
              } catch (_) {}
            }
          },
        );
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
        // undraw markers
        widget.googleMaps.undrawMarkers();

        // clear trip model
        widget.trip.clear();
      }

      // if partner is anything but 'unavailable', constantly report his position. We already do
      // this when calling 'connect', but it's important to do here too in case
      // the partner relaunches the app.
      if (newPartnerStatus != PartnerStatus.unavailable) {
        widget.partner.sendPositionToFirebase(true);
      }

      // if partner is 'unavailable',
      if (newPartnerStatus == PartnerStatus.unavailable) {
        // stop reporting his position. We already do this when calling
        // 'disconnect', but it's important to do here too in case the partner
        // relaunches the app.
        widget.partner.sendPositionToFirebase(false);
      }

      // if partner's status was 'requested' but was updated to 'available' it means
      // they were denied a trip, so display a warning
      if (newPartnerStatus == PartnerStatus.available &&
          widget.partner.partnerStatus == PartnerStatus.requested) {
        // cancel timer that was set off when partner was requested then display the warning
        widget.timer.cancel();
        await showOkDialog(
          context: context,
          title: "Corrida indisponível",
          content: "Outro(a) parceiro(a) aceitou a corrida antes de você.",
        );
      }

      // log events
      try {
        await widget.firebase.analytics.logEventOnPartnerStatus(
          context: context,
          newStatus: newPartnerStatus,
          oldStatus: widget.partner.partnerStatus,
        );
      } catch (_) {}

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
    } else if (newTripStatus == TripStatus.cancelledByClient) {
      await showOkDialog(
        context: context,
        title: "O cliente cancelou o pedido",
      );
      // cancel trip status subscriptions
      if (tripStatusSubscription != null) {
        tripStatusSubscription.cancel();
      }
    } else if (newTripStatus == TripStatus.cancelledByPartner) {
      // cancel trip status subscriptions
      if (tripStatusSubscription != null) {
        tripStatusSubscription.cancel();
      }
    }
  }

  void onAccountStatusUpdate(Event e) async {
    AccountStatus newAccountStatus = AccountStatusExtension.fromString(
      e.snapshot.value,
    );
    if (newAccountStatus == AccountStatus.locked) {
      await showOkDialog(
          context: context,
          title: "Conta bloqueada",
          content: "Entre em contato conosco para saber mais detalhes.");
    } else if (newAccountStatus == AccountStatus.approved &&
        widget.partner.accountStatus == AccountStatus.locked) {
      await showOkDialog(
          context: context,
          title: "Conta aprovada",
          content: "Contecte-se e comece a receber pedidos de corrida");
    }

    // update partner's account status
    widget.partner.updateAccountStatus(newAccountStatus);
  }
}
