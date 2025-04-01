import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/pastTrips.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class PastTripDetailArguments {
  final Trip pastTrip;

  PastTripDetailArguments({
    required this.pastTrip,
  });
}

class PastTripDetail extends StatefulWidget {
  static String routeName = "PastTripDetail";
  final Trip pastTrip;
  final firebase = FirebaseService();

  PastTripDetail({
    required this.pastTrip,
  });

  @override
  PastTripDetailState createState() => PastTripDetailState();
}

class PastTripDetailState extends State<PastTripDetail> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    PartnerModel partner = widget.firebase.model.partner;
    GoogleMapsModel googleMaps = widget.firebase.model.googleMaps;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            trafficEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                partner.position?.latitude ?? 0,
                partner.position?.longitude ?? 0,
              ),
              zoom: widget.firebase.model.googleMaps.initialZoom,
            ),
            padding: EdgeInsets.only(
              top: screenHeight / 12,
              bottom: widget.pastTrip.paymentMethod == PaymentMethod.creditCard
                  ? screenHeight / 3
                  : screenHeight / 3.8,
              left: screenWidth / 20,
              right: screenWidth / 20,
            ),
            onMapCreated: (GoogleMapController c) async {
              googleMaps.onMapCreatedCallback(c);
              await googleMaps.drawMarkers(
                context: context,
                // FIXME: guarantee that originLat and originLng are not null
                firstMarkerPosition: LatLng(
                  widget.pastTrip.originLat ?? 0,
                  widget.pastTrip.originLng ?? 0,
                ),
                secondMarkerPosition: LatLng(
                  widget.pastTrip.destinationLat ?? 0,
                  widget.pastTrip.destinationLng ?? 0,
                ),
                topPadding: screenHeight / 5,
                bottomPadding: screenHeight / 10,
              );
              setState(() {});
            },
            polylines: Set<Polyline>.of(googleMaps.polylines.values),
            markers: googleMaps.markers,
          ),
          OverallPadding(
            child: Column(
              children: [
                Row(
                  children: [
                    GoBackButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
          _buildFloatingCard(
            context: context,
            pastTrip: widget.pastTrip,
          ),
        ],
      ),
    );
  }
}

Widget _buildFloatingCard({
  required BuildContext context,
  required Trip pastTrip,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  return Column(
    children: [
      Spacer(),
      FloatingCard(
        leftMargin: screenWidth / 50,
        rightMargin: screenWidth / 50,
        child: Column(
          children: [
            SizedBox(height: screenHeight / 200),
            Column(
              children: [
                SizedBox(height: screenHeight / 100),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 10,
                    ),
                    SizedBox(width: screenWidth / 50),
                    Text(
                      // FIXME: guarantee that requestTime is not null
                      formatDatetime(pastTrip.requestTime ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                Row(
                  children: [
                    SvgPicture.asset(
                      "images/pickUpIcon.svg",
                      width: 8,
                    ),
                    SizedBox(width: screenWidth / 50),
                    Flexible(
                      flex: 3,
                      child: Text(
                        pastTrip.originAddress,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                Row(
                  children: [
                    SvgPicture.asset(
                      "images/dropOffIcon.svg",
                      width: 8,
                    ),
                    SizedBox(width: screenWidth / 50),
                    Flexible(
                      flex: 3,
                      child: Text(
                        pastTrip.destinationAddress,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                SizedBox(height: screenHeight / 100),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        "Receita",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      pastTrip.paymentMethod == PaymentMethod.cash
                          ? "Dinheiro"
                          : "Cartão de Crédito",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.disabled,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                Row(
                  children: [
                    Text(
                      "Tarifa",
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "R\$ " + (pastTrip.farePrice / 100).toStringAsFixed(2),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                pastTrip.paymentMethod == PaymentMethod.cash
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Saldo devedor (+)",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "R\$ " +
                                    (pastTrip.farePrice * 0.15 / 100)
                                        .toStringAsFixed(2),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight / 100),
                        ],
                      )
                    : Container(),
                pastTrip.paymentMethod == PaymentMethod.creditCard
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Comissão da Venni",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "R\$ " +
                                    (pastTrip.payment.venniCommission / 100)
                                        .toStringAsFixed(2),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight / 100),
                        ],
                      )
                    : Container(),
                pastTrip.paymentMethod == PaymentMethod.creditCard
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Saldo devedor pago",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "R\$ " +
                                    (pastTrip.payment.paidOwedCommission / 100)
                                        .toStringAsFixed(2),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight / 100),
                        ],
                      )
                    : Container(),
                Row(
                  children: [
                    Text(
                      "Valor recebido",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "R\$ " +
                          ((pastTrip.paymentMethod == PaymentMethod.creditCard
                                      ? pastTrip.payment.partnerAmountReceived
                                      : pastTrip.farePrice) ?? 0 / 100)
                              .toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight / 75),
          ],
        ),
      ),
      SizedBox(height: screenHeight / 20),
    ],
  );
}