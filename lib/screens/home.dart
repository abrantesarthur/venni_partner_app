import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:background_location/background_location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/accountLocked.dart';
import 'package:partner_app/screens/partnerAvailable.dart';
import 'package:partner_app/services/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/awesomeNotifications.dart';
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
import 'package:partner_app/vendors/permissionHandler.dart';
import 'package:partner_app/widgets/menuButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/partnerBusy.dart';
import 'package:partner_app/widgets/partnerRequested.dart';
import 'package:partner_app/widgets/partnerUnavailable.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

class HomeArguments {
  UserModel firebase;
  PartnerModel partner;
  GoogleMapsModel googleMaps;
  TimerModel timer;
  TripModel trip;
  ConnectivityModel connectivity;
  HomeArguments({
    required this.firebase,
    required this.partner,
    required this.googleMaps,
    required this.timer,
    required this.trip,
    required this.connectivity,
  });
}

// FIXME: only need firebaseService
class Home extends StatefulWidget {
  static const routeName = "home";
  final firebase = FirebaseService();


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
  static StreamSubscription tripStatusSubscription;
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
    partnerPositionFuture = _getPartnerPosition(context);

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

      // add listener to UserModel so user is redirected to Start when logs out
      _firebaseListener = () {
        _signOut(context);
      };
      widget.firebase.addListener(_firebaseListener);

      // request notifications
      widget.firebase.requestNotifications(context);
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
    if (didChangeAppLifecycleCallback != null &&
        state == AppLifecycleState.resumed) {
      didChangeAppLifecycleCallback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.firebase.removeListener(_firebaseListener);
    BackgroundLocation.stopLocationService();
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
    UserModel firebase = Provider.of<UserModel>(context);
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
        if (snapshot.hasError || snapshot.data == null) {
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
            message: snapshot.error == "location-service-disabled"
                ? "Ative o acesso à localização"
                : "Compartilhe sua localização",
          );
        }

        // after having waited succesfully, define didChangeAppLifecycleCallback
        // so if user stops sharing location, we will know.
        if (didChangeAppLifecycleCallback == null) {
          didChangeAppLifecycleCallback = () async {
            // make sure user didn't disable location sharing
            await ensureLocationSharingIsOn(context);
            // on android, workaround the google maps issue of not displaying the
            // maps after phone being in background for a while by. See here:
            // https://stackoverflow.com/questions/59374010/flutter-googlemap-is-blank-after-resuming-from-background/59435683#59435683
            if (Platform.isAndroid) {
              widget.googleMaps.rebuild();
            }
          };
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Menu(),
          body: Stack(
            children: [
              // TODO: replace myLocationButton for another icon
              Consumer<GoogleMapsModel>(builder: (context, g, _) {
                return GoogleMap(
                  myLocationButtonEnabled: g.myLocationButtonEnabled,
                  myLocationEnabled: g.myLocationEnabled,
                  trafficEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target:
                        g.initialCameraLatLng ?? LatLng(-17.217600, -46.874621),
                    zoom: g.initialZoom ?? 16.5,
                  ),
                  padding: EdgeInsets.only(
                    top: g.googleMapsTopPadding ?? screenHeight / 12,
                    bottom: g.googleMapsBottomPadding ?? screenHeight / 9,
                    left: screenWidth / 20,
                    right: screenWidth / 20,
                  ),
                  onMapCreated: (c) async {
                    await g.onMapCreatedCallback(c);
                  },
                  polylines: Set<Polyline>.of(g.polylines.values),
                  polygons: g.polygons,
                  markers: g.markers,
                );
              }),
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

  // ensureLocationSharing is on disconnects partner if they are available but
  // stop sharing location
  Future<void> ensureLocationSharingIsOn(BuildContext context) async {
    Position partnerPos;
    try {
      partnerPos = await determineUserPosition(context);
      // if user has not stopped sharing location, call handlePositionUpdates so
      // we are sure we're listening to location updates, just in case the OS
      // decided to kill the process while the app was in the background. However,
      // we only listen to these updates if the partner is connected and we could
      // get partnerPos.
      if (widget.partner.partnerStatus != PartnerStatus.unavailable &&
          partnerPos != null) {
        widget.partner.handlePositionUpdates(
          widget.firebase,
          widget.googleMaps,
          widget.trip,
        );
      }
    } catch (_) {
      partnerPos = await _getPartnerPosition(context);
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

  Future<Position> _getPartnerPosition(BuildContext context) async {
    // Try getting user position. If it returns null, it's because user stopped
    // sharing location. getPosition() will automatically handle that case, asking
    // the user to share again and preventing them from using the app if they
    // don't.
    Position pos = await widget.partner.getPosition(context, notify: false);
    if (pos == null) {
      return null;
    }
    // if we could get position, make sure to resubscribe to position changes
    // again, as the subscription may have been cancelled if user stopped
    // sharing location. However, only do that if partner is connected
    if (widget.partner.partnerStatus != PartnerStatus.unavailable) {
      widget.partner.handlePositionUpdates(
        widget.firebase,
        widget.googleMaps,
        widget.trip,
      );
    }
    return pos;
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    UserModel firebase = Provider.of<UserModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    if (!firebase.isUserSignedIn) {
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
      // if partner has been requested, kick off 15s timer. The TimerModel
      // is passed to the PartnerRequested widget which uses its 'remainingSeconds'
      // property to display how much time the partner has to accept the trip.
      // Once the timer stops, if the partner hasn't accepted
      // the trip request we call 'declineTrip' and udpate their status locally
      if (newPartnerStatus == PartnerStatus.requested) {
        // trigger notifications so user is periodically warned if app is in background
        Notifications().trigger(repeatingPeriod: Duration(seconds: 2));

        // before kicking off timer, set acceptedTrip to false. If partner accepts
        // the trip before the timer goes out, acceptedTrip is set true and the
        // callback won't set the partner available.
        widget.partner.setAcceptedTrip(false, notify: false);
        widget.timer.kickOff(
          durationSeconds: 15,
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
        // stop triggering trip request notifications if user is busy
        Notifications().stopTriggering(NotificationType.tripRequest);

        // download trip data before updating PartnerModel status and thus UI
        await widget.trip.downloadData(widget.firebase, notify: false);
        // cancel any previous trip status subscriptions
        if (tripStatusSubscription != null) {
          await tripStatusSubscription.cancel();
        }
        // listen for trip status updates calling a function that redraws markers
        // whenever a new partner is heard
        tripStatusSubscription = widget.firebase.database.onTripStatusUpdate(
          widget.trip.clientID,
          onTripStatusUpdate,
        );

        // remove demand polygons and stop redrawing them
        widget.googleMaps.stopDrawingPolygons();
        widget.googleMaps.undrawPolygons();
      } else {
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

        // remove demand polygons and stop redrawing them
        widget.googleMaps.stopDrawingPolygons();
        widget.googleMaps.undrawPolygons();
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

      // if partner becomes 'available',
      if (newPartnerStatus == PartnerStatus.available) {
        // stop triggering trip request notifications if user becomes available
        Notifications().stopTriggering(NotificationType.tripRequest);
        // animate maps camera to center on the partner
        if (widget.partner.position != null) {
          widget.googleMaps.animateCameraToPosition(LatLng(
            widget.partner.position.latitude,
            widget.partner.position.longitude,
          ));
        }

        // periodically draw demand polygons
        await widget.googleMaps.kickoffDrawPolygon(widget.firebase);
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
      // cancel trip status subscriptions
      if (tripStatusSubscription != null) {
        await tripStatusSubscription.cancel();
      }
      await showOkDialog(
        context: context,
        title: "O cliente cancelou o pedido",
      );
    } else if (newTripStatus == TripStatus.cancelledByPartner) {
      // cancel trip status subscriptions
      if (tripStatusSubscription != null) {
        await tripStatusSubscription.cancel();
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
