import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/pastTrips.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class PastTripDetailArguments {
  final Trip pastTrip;
  final UserModel firebase;

  PastTripDetailArguments({
    required this.pastTrip,
    required this.firebase,
  });
}

class PastTripDetail extends StatefulWidget {
  static String routeName = "PastTripDetail";
  final Trip pastTrip;
  final UserModel firebase;

  PastTripDetail({
    required this.pastTrip,
    required this.firebase,
  });

  @override
  PastTripDetailState createState() => PastTripDetailState();
}

class PastTripDetailState extends State<PastTripDetail> {
  GoogleMapsModel googleMaps = GoogleMapsModel();

  @override
  void dispose() {
    googleMaps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);

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
                partner.position?.latitude,
                partner.position?.longitude,
              ),
              zoom: googleMaps.initialZoom,
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
                firstMarkerPosition: LatLng(
                  widget.pastTrip.originLat,
                  widget.pastTrip.originLng,
                ),
                secondMarkerPosition: LatLng(
                  widget.pastTrip.destinationLat,
                  widget.pastTrip.destinationLng,
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
                      formatDatetime(pastTrip.requestTime),
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
                                      : pastTrip.farePrice) /
                                  100)
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

String getRateDescription(int rate) {
  if (rate == null) {
    return "sem avaliação";
  }
  switch (rate) {
    case 1:
      return "péssima";
    case 2:
      return "ruim";
    case 3:
      return "regular";
    case 4:
      return "boa";
    case 5:
      return "excelente";
    default:
      return "";
  }
}
