import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:provider/provider.dart';

// TODO: write tests
class GoogleMapsModel extends ChangeNotifier {
  Map<PolylineId, Polyline> _polylines;
  Set<Marker> _markers;
  GoogleMapController _googleMapController;
  bool _myLocationEnabled;
  bool _myLocationButtonEnabled;
  double _googleMapsBottomPadding;
  double _googleMapsTopPadding;
  LatLng _initialCameraLatLng;
  double _initialZoom;
  String _mapStyle;

  GoogleMapsModel() {
    _polylines = {};
    _markers = {};
    _myLocationEnabled = true;
    _myLocationButtonEnabled = true;
    _initialZoom = 16.5;
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

  void onMapCreatedCallback(GoogleMapController c) async {
    await c.setMapStyle(_mapStyle);
    _googleMapController = c;
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
    print("drawOriginMarker");
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
    @required BuildContext context,
    @required LatLng firstMarkerPosition,
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
    animateCamera(secondMarkerPosition, firstMarkerPosition);

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

  Future<void> animateCamera(
    LatLng firstCoordinates,
    LatLng secondCoordinates,
  ) {
    print("animateCamera");
    return Future.delayed(Duration(milliseconds: 1000), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        calculateBounds(firstCoordinates, secondCoordinates),
        50,
      ));
    });
  }

  void setGoogleMapsCameraView({
    bool locationEnabled = true,
    bool locationButtonEnabled = true,
    double topPadding,
    double bottomPadding,
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
}
