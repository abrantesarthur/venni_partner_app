import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/services/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:provider/provider.dart';

class GoogleMapsModel extends ChangeNotifier {
  final FirebaseService firebase;
  Map<PolylineId, Polyline> _polylines;
  Set<Marker> _markers;
  Set<Polygon> _polygons;
  GoogleMapController _googleMapController;
  bool _myLocationEnabled;
  bool _myLocationButtonEnabled;
  double _googleMapsBottomPadding;
  double _googleMapsTopPadding;
  LatLng _initialCameraLatLng;
  double _initialZoom;
  String _mapStyle;
  Timer _drawPolygonTimer;

  GoogleMapsModel(this.firebase) {
    _polylines = {};
    _markers = {};
    _polygons = {};
    _myLocationEnabled = true;
    _myLocationButtonEnabled = true;
    _initialZoom = 15;
    rootBundle
        .loadString("assets/map_style.txt")
        .then((value) => {_mapStyle = value});
  }
  set initialCameraLatLng(LatLng latlng) {
    _initialCameraLatLng = latlng;
    notifyListeners();
  }

  // getters
  Map<PolylineId, Polyline> get polylines => _polylines;
  Set<Marker> get markers => _markers;
  Set<Polygon> get polygons => _polygons;
  GoogleMapController get googleMapController => _googleMapController;
  bool get myLocationEnabled => _myLocationEnabled;
  bool get myLocationButtonEnabled => _myLocationButtonEnabled;
  double get googleMapsBottomPadding => _googleMapsBottomPadding;
  double get googleMapsTopPadding => _googleMapsTopPadding;
  LatLng get initialCameraLatLng => _initialCameraLatLng;
  double get initialZoom => _initialZoom;
  String get mapStyle => _mapStyle;

  @override
  void dispose() {
    if (_googleMapController != null) {
      _googleMapController.dispose();
    }
    super.dispose();
  }

  Future<void> onMapCreatedCallback(GoogleMapController c) async {
    await c.setMapStyle(_mapStyle);
    _googleMapController = c;
  }

  // kickoffDrawPolygon calls _drawPolygon periodically once per minute
  Future<void> kickoffDrawPolygon() async {
    stopDrawingPolygons();
    // draw polygon once right away then schedule it to run periodically
    await _drawPolygons(firebase);
    _drawPolygonTimer = Timer.periodic(Duration(seconds: 60), (timer) async {
      await _drawPolygons(firebase);
    });
  }

  // stopDrawPolygon stops the periodic calling of _drawPolygon
  void stopDrawingPolygons() {
    if (_drawPolygonTimer != null) {
      _drawPolygonTimer.cancel();
    }
  }

  // _undrawPolygons clears the polygons from the view
  void undrawPolygons() {
    _polygons.clear();
    notifyListeners();
  }

  // _drawPolygons draws polygons on the map whose opacity indicates trip demand
  Future<void> _drawPolygons(UserModel firebase) async {
    DemandByZone demandByZone;
    try {
      demandByZone = await firebase.functions.getDemandByZone();
    } catch (e) {
      // on error, clear polygons so partner doesn't see outdated polygon view
      undrawPolygons();
      return;
    }

    // iterate over zones drawing a polygon for each representing the demand there
    demandByZone.values.entries.forEach((entry) {
      String key = entry.key; // zone name
      ZoneDemand value = entry.value; // nome demand
      // todo: on tap show warning of last trip count in last 5 minutes!
      _polygons.add(
        Polygon(
          polygonId: PolygonId(key),
          // zones with more demand have color with higher opacity
          fillColor: AppColor.primaryPink.withOpacity(
            value.demand == Demand.LOW
                ? 0
                : value.demand == Demand.MEDIUM
                    ? 0.1
                    : value.demand == Demand.HIGH
                        ? 0.27
                        : value.demand == Demand.VERYHIGH
                            ? 0.55
                            : 0,
          ),
          points: [
            LatLng(value.maxLat, value.maxLng),
            LatLng(value.maxLat, value.minLng),
            LatLng(value.minLat, value.minLng),
            LatLng(value.minLat, value.maxLng),
          ],
          strokeColor: AppColor.primaryPink.withOpacity(0.05),
          strokeWidth: 2,
        ),
      );
    });

    notifyListeners();
  }

  Future<void> drawDestinationMarker(
    BuildContext context, {
    bool notify = true,
  }) async {
    // only draw marker if inProgress
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.inProgress) {
      return;
    }

    // remove old markers
    undrawMarkers(notify: false);

    // get trip destination position
    LatLng destinationCoordinates = LatLng(
      trip.destinationLat,
      trip.destinationLng,
    );

    final screenHeight = MediaQuery.of(context).size.height;
    await drawMarkers(
      context: context,
      firstMarkerPosition: destinationCoordinates,
      topPadding: screenHeight / 5,
      bottomPadding: screenHeight / 10,
      notify: notify,
    );
  }

  Future<void> drawOriginMarker(
    BuildContext context, {
    bool notify = true,
  }) async {
    // only draw markers if waitingPartner
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.waitingPartner) {
      return;
    }

    // remove old markers
    undrawMarkers(notify: false);

    // get trip origin position
    LatLng originCoordinates = LatLng(
      trip.originLat,
      trip.originLng,
    );

    final screenHeight = MediaQuery.of(context).size.height;
    await drawMarkers(
      context: context,
      firstMarkerPosition: originCoordinates,
      topPadding: screenHeight / 5,
      bottomPadding: screenHeight / 10,
      notify: notify,
    );
  }

  Future<void> drawMarkers({
    required BuildContext context,
    required LatLng firstMarkerPosition,
    LatLng secondMarkerPosition,
    double topPadding,
    double bottomPadding,
    bool notify = true,
  }) async {
    // hide partners's location details and set maps padding
    setGoogleMapsCameraView(
      locationButtonEnabled: true,
      locationEnabled: true,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      notify: false,
    );

    BitmapDescriptor secondMarkerIcon;
    if (secondMarkerPosition == null) {
      // if second marker is null, it defaults to partner's position
      PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
      secondMarkerPosition = LatLng(
        partner.position.latitude,
        partner.position.longitude,
      );
    } else {
      // otherwise, we pick the dropOffIcon as marker
      secondMarkerIcon = await AppBitmapDescriptor.fromSvg(
        context,
        "images/dropOffIcon.svg",
      );
    }

    // add bounds to map view
    animateCameraToBounds(secondMarkerPosition, firstMarkerPosition);

    // get first marker icon
    BitmapDescriptor firstMarkerIcon = await AppBitmapDescriptor.fromSvg(
      context,
      "images/pickUpIcon.svg",
    );

    Marker firstMarker = Marker(
      markerId: MarkerId("pickUpMarker"),
      position: firstMarkerPosition,
      icon: firstMarkerIcon,
    );

    Marker secondMarker;
    if (secondMarkerIcon != null) {
      secondMarker = Marker(
        markerId: MarkerId("dropOffMakrer"),
        position: secondMarkerPosition,
        icon: secondMarkerIcon,
      );
    }

    // add marker
    _markers.add(firstMarker);
    if (secondMarker != null) {
      _markers.add(secondMarker);
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> animateCameraToBounds(
    LatLng firstCoordinates,
    LatLng secondCoordinates,
  ) {
    return Future.delayed(Duration(milliseconds: 300), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        calculateBounds(firstCoordinates, secondCoordinates),
        50,
      ));
    });
  }

  Future<void> animateCameraToPosition(LatLng position) {
    return Future.delayed(Duration(milliseconds: 300), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngZoom(
        position,
        _initialZoom,
      ));
    });
  }

  void setGoogleMapsCameraView({
    bool locationEnabled = true,
    bool locationButtonEnabled = true,
    required double topPadding,
    required double bottomPadding,
    bool notify = true,
  }) {
    // set user's location details (true by default)
    _myLocationEnabled = locationEnabled;
    _myLocationButtonEnabled = locationButtonEnabled;

    // set paddings (null by default)
    _googleMapsBottomPadding = bottomPadding;
    _googleMapsTopPadding = topPadding;
    if (notify) {
      notifyListeners();
    }
  }

  LatLngBounds calculateBounds(
    LatLng firstLocation,
    LatLng secondLocation,
  ) {
    double highestLat = firstLocation.latitude > secondLocation.latitude
        ? firstLocation.latitude
        : secondLocation.latitude;
    double highestLng = firstLocation.longitude > secondLocation.longitude
        ? firstLocation.longitude
        : secondLocation.longitude;
    double lowestLat = firstLocation.latitude < secondLocation.latitude
        ? firstLocation.latitude
        : secondLocation.latitude;
    double lowestLng = firstLocation.longitude < secondLocation.longitude
        ? firstLocation.longitude
        : secondLocation.longitude;
    return LatLngBounds(
      southwest: LatLng(lowestLat, lowestLng),
      northeast: LatLng(highestLat, highestLng),
    );
  }

  void undrawMarkers({bool notify = true}) {
    _markers.clear();
    if (notify) {
      notifyListeners();
    }
  }

  // rebuild triggers a map rebuild by notifying listeners. This is used as a
  // workaround on an android issue that hides the map from view if the app
  // stays on background for a long time
  void rebuild() {
    if (_googleMapController != null) {
      _googleMapController.setMapStyle('[]');
      notifyListeners();
      _googleMapController.setMapStyle(_mapStyle);
      notifyListeners();
    }
  }
}
