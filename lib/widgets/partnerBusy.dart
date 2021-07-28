import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/rateClient.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/urlLauncher.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/cancelButton.dart';
import 'package:partner_app/widgets/circularImage.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:slider_button/slider_button.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PartnerBusy extends StatefulWidget {
  final TripModel trip;
  final PartnerModel partner;
  PartnerBusy({@required this.trip, @required this.partner});

  @override
  PartnerBusyState createState() => PartnerBusyState();
}

class PartnerBusyState extends State<PartnerBusy> {
  bool lockScreen = false;
  Widget buttonChild;
  bool isDraggable = true;
  bool partnerIsFar;

  @override
  void initState() {
    partnerIsFar = getDistanceBetweenCoordinates(
          LatLng(
            widget.partner.position.latitude,
            widget.partner.position.longitude,
          ),
          LatLng(
            widget.trip.originLat,
            widget.trip.originLng,
          ),
        ) >
        150;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // listen for PartnerModel changes in case the partner approaches the client
    PartnerModel partner = Provider.of<PartnerModel>(context);
    // listen for TripModel changes in case the status changes
    TripModel trip = Provider.of<TripModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

    // whenever we rebuild, it may be because PartnerModel notified listeners about
    // the partner's udpated position. if partner is going to pick up the client,
    // use that position to recalculate how far he is from the pick up point.
    // This distance will be used to decide whether to display  a "Cancel Trip"
    // (when far) or "Start Trip" button (when near).
    if (trip.tripStatus == TripStatus.waitingPartner) {
      bool _partnerIsFar = getDistanceBetweenCoordinates(
            LatLng(toFixed(partner.position.latitude, 6),
                toFixed(partner.position.longitude, 6)),
            LatLng(trip.originLat, trip.originLng),
          ) >
          150;

      if (!_partnerIsFar && partnerIsFar) {
        // if partner just got close, set him as nearby in database so client is notified
        firebase.database.setPartnerIsNear(trip.clientID, true);
      } else if (_partnerIsFar && !partnerIsFar) {
        // if partner just got far, set him as not nearby in database so client is notified
        firebase.database.setPartnerIsNear(trip.clientID, false);
      }
      partnerIsFar = _partnerIsFar;
    }

    return Column(
      children: [
        InkWell(
          onTap: () async => showDirections(context),
          child: FloatingCard(
            leftMargin: 0,
            rightMargin: 0,
            topPadding: screenHeight / 15,
            borderRadius: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 0.8 * screenWidth,
                  child: Text(
                    trip.tripStatus == TripStatus.waitingPartner
                        ? trip.originAddress
                        : trip.destinationAddress,
                    style: TextStyle(
                      color: AppColor.primaryPink,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.navigation,
                      color: AppColor.primaryPink,
                      size: 40,
                    ),
                    SizedBox(height: screenHeight / 100),
                    Text(
                      "IR",
                      style: TextStyle(
                        color: AppColor.primaryPink,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: screenHeight / 25),
        !partnerIsFar
            ? AppButton(
                textData: "cancelar",
                width: screenWidth / 1.5,
                height: 60,
                onTapCallBack: () async {
                  await showYesNoDialog(
                    context,
                    title: "Cancelar corrida?",
                    onPressedYes: () async {
                      Navigator.pop(context);
                      setState(() {
                        lockScreen = true;
                      });
                      await firebase.functions.cancelTrip();
                    },
                  );
                },
                iconRight: Icons.clear,
              )
            : Container(),
        Spacer(),
        trip.tripStatus == TripStatus.inProgress
            ? buildTripInProgressPanel(context)
            : buildTripWaitingPartnerPanel(context)
      ],
    );
  }

  Widget buildTripInProgressPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight / 20),
      child: SliderButton(
        action: () async {
          try {
            await Navigator.pushNamed(context, RateClient.routeName);
          } catch (_) {
            showOkDialog(
              context: context,
              title: "Falha ao finalizar a corrida",
              content: "Verifique sua conexão e tente novamente",
            );
          }
        },
        label: Text(
          "FINALIZAR CORRIDA",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(
            Icons.double_arrow_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
        width: screenWidth,
        radius: 0,
        baseColor: Colors.white,
        highlightedColor: AppColor.primaryPink,
        backgroundColor: AppColor.primaryPink,
        dismissThresholds: 0.8,
      ),
    );
  }

  Widget buildTripWaitingPartnerPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    return SlidingUpPanel(
      color: AppColor.primaryPink,
      maxHeight: screenHeight / 2,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10.0),
        topRight: Radius.circular(10.0),
      ),
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight / 100),
          Icon(
            Icons.maximize,
            color: Colors.white.withOpacity(0.55),
            size: 30,
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SliderButton(
                action: lockScreen
                    ? () {}
                    : () async {
                        try {
                          if (partnerIsFar) {
                            await firebase.functions.cancelTrip();
                          } else {
                            await firebase.functions.startTrip();
                          }
                        } catch (e) {
                          showOkDialog(
                            context: context,
                            title: "Falha ao " +
                                (partnerIsFar ? "cancelar" : "iniciar") +
                                " a corrida",
                            content: partnerIsFar
                                ? "Busque o cliente ou entre em contato com ele para que cancele a corrida"
                                : "Tente novamente",
                          );
                        }
                      },
                label: Text(
                  partnerIsFar ? "CANCELAR CORRIDA" : "INICIAR CORRIDA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.double_arrow_rounded,
                    color: AppColor.primaryPink,
                    size: 50,
                  ),
                ),
                width: screenWidth,
                radius: 0,
                baseColor: AppColor.primaryPink,
                dismissThresholds: 0.8,
              ),
              OverallPadding(
                top: screenHeight / 20,
                bottom: screenHeight / 20,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          child: Icon(
                            Icons.message,
                            size: 50,
                            color: Colors.white,
                          ),
                          onTap: () async => await messageClient(
                            context,
                            trip.clientPhone,
                          ),
                        ),
                        CircularImage(
                          imageFile: trip.profileImage == null
                              ? AssetImage("images/user_icon.png")
                              : trip.profileImage.file,
                        ),
                        GestureDetector(
                          child: Icon(
                            Icons.phone_in_talk,
                            size: 50,
                            color: Colors.white,
                          ),
                          onTap: () async => await UrlLauncher.openPhone(
                            context,
                            trip.clientPhone,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight / 50),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      collapsed: Column(
        children: [
          SizedBox(height: screenHeight / 25),
          buttonChild == null
              ? Text(
                  (partnerIsFar ? "Busque " : "Aguarde ") + trip?.clientName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                )
              : buttonChild,
        ],
      ),
    );
  }

  Future<dynamic> messageClient(BuildContext context, String phoneNumber) {
    return showYesNoDialog(
      context,
      title: "Contatar o cliente por whatsapp?",
      onPressedYes: () async => {
        // dismiss dialog
        Navigator.pop(context),
        await UrlLauncher.openWhatsapp(
          context,
          phoneNumber,
        ),
      },
    );
  }

  Future<void> showDirections(BuildContext context) async {
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // get list of installed maps on user's phone
    final availableMaps = await MapLauncher.installedMaps;

    // display warning if user has no map application installed
    if (availableMaps.isEmpty) {
      showOkDialog(
        context: context,
        title: "Falha ao navegar.",
        content: "Instale o aplicativo Google Maps no seu celular.",
      );
      return;
    }

    // give preference to opening Google Maps
    AvailableMap chosenMap;
    availableMaps.forEach((map) {
      // give preference to Google Maps
      if (map.mapName == "Google Maps") {
        chosenMap = map;
      }
    });
    chosenMap = chosenMap == null ? availableMaps[0] : chosenMap;

    if (trip.tripStatus == TripStatus.waitingPartner) {
      // if client is waiting partner, show directions to client
      await chosenMap.showDirections(
        destination: Coords(
          trip.originLat,
          trip.originLng,
        ),
      );
    } else if (trip.tripStatus == TripStatus.inProgress) {
      // if trip is in progress, show directions to destination
      await chosenMap.showDirections(
        destination: Coords(
          trip.destinationLat,
          trip.destinationLng,
        ),
      );
    }
  }
}
