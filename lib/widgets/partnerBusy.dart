import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/rateClient.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/services/firebase/database/methods.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/urlLauncher.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/circularImage.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:provider/provider.dart';
import 'package:slider_button/slider_button.dart';

class PartnerBusy extends StatefulWidget {
  final TripModel trip;
  final PartnerModel partner;
  PartnerBusy({required this.trip, required this.partner});

  @override
  PartnerBusyState createState() => PartnerBusyState();
}

class PartnerBusyState extends State<PartnerBusy> {
  bool lockScreen = false;
  Widget buttonChild;
  bool isDraggable = true;
  bool partnerIsNear;

  @override
  void initState() {
    partnerIsNear = getDistanceBetweenCoordinates(
          LatLng(
            widget.partner.position.latitude,
            widget.partner.position.longitude,
          ),
          LatLng(
            widget.trip.originLat,
            widget.trip.originLng,
          ),
        ) <
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
    UserModel firebase = Provider.of<UserModel>(context, listen: false);

    // whenever we rebuild, it may be because PartnerModel notified listeners about
    // the partner's udpated position. if partner is going to pick up the client,
    // use that position to recalculate how far he is from the pick up point.
    // This distance will be used to decide when to display a "Start Trip" button
    if (trip.tripStatus == TripStatus.waitingPartner) {
      bool _partnerIsNear = getDistanceBetweenCoordinates(
            LatLng(toFixed(partner.position.latitude, 6),
                toFixed(partner.position.longitude, 6)),
            LatLng(trip.originLat, trip.originLng),
          ) <
          150;
      if (!partnerIsNear && _partnerIsNear) {
        // if partner just got close, set him as nearby in database so client is notified
        firebase.database.setPartnerIsNear(trip.clientID, true);
      } else if (partnerIsNear && !_partnerIsNear) {
        // if partner just got far, set him as not nearby in database so client is notified
        firebase.database.setPartnerIsNear(trip.clientID, false);
      }
      partnerIsNear = _partnerIsNear;
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
                    (trip.tripStatus == TripStatus.waitingPartner
                            ? trip.originAddress
                            : trip.destinationAddress) ??
                        "",
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
        Spacer(),
        trip.tripStatus == TripStatus.inProgress
            ? buildTripInProgressPanel(context)
            : trip.tripStatus == TripStatus.waitingPartner
                ? buildTripWaitingPartnerPanel(context)
                : Container(),
        SizedBox(height: screenHeight / 25),
      ],
    );
  }

  Widget buildTripInProgressPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight / 50),
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
            color: Colors.white,
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
    UserModel firebase = Provider.of<UserModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    return FloatingCard(
      leftMargin: 0,
      rightMargin: 0,
      child: Column(
        children: [
          Column(
            children: [
              partnerIsNear
                  ? SliderButton(
                      action: lockScreen
                          ? () {}
                          : () async {
                              try {
                                await firebase.functions.startTrip(context);
                              } catch (e) {
                                showOkDialog(
                                  context: context,
                                  title: "Falha ao iniciar a corrida",
                                  content: "Tente novamente",
                                );
                              }
                            },
                      label: Text(
                        "INICIAR CORRIDA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
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
                    )
                  : Container(),
              SizedBox(height: screenHeight / 50),
            ],
          ),
          // TODO: display user score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              trip.profileImage == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.black,
                    )
                  : CircularImage(
                      size: 60,
                      imageFile: trip.profileImage.file,
                    ),
              Text(
                (partnerIsNear ? "Aguarde " : "Busque ") + trip?.clientName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: AppColor.primaryPink,
                ),
              ),
              trip.tripStatus != TripStatus.inProgress
                  ? GestureDetector(
                      child: Icon(
                        Icons.list,
                        size: 50,
                        color: Colors.black,
                      ),
                      onTap: () => showMoreOptions(context),
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }

  Future<dynamic> showMoreOptions(BuildContext context) async {
    final screenHeight = MediaQuery.of(context).size.height;

    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            height: screenHeight / 3,
            child: Column(
              children: [
                Divider(thickness: 0.1, color: Colors.black),
                SizedBox(height: screenHeight / 100),
                BorderlessButton(
                  primaryText: "MENSAGEM",
                  primaryTextSize: 20,
                  primaryTextWeight: FontWeight.w600,
                  iconRight: Icons.message,
                  iconRightColor: Colors.black,
                  iconRightSize: 25,
                  onTap: () async => await messageClient(
                    context,
                    widget.trip.clientPhone,
                  ),
                ),
                SizedBox(height: screenHeight / 100),
                Divider(thickness: 0.1, color: Colors.black),
                SizedBox(height: screenHeight / 100),
                BorderlessButton(
                  primaryText: "LIGAÇÃO",
                  primaryTextSize: 20,
                  primaryTextWeight: FontWeight.w600,
                  iconRight: Icons.phone_in_talk,
                  iconRightColor: Colors.black,
                  iconRightSize: 25,
                  onTap: () async => await UrlLauncher.openPhone(
                    context,
                    widget.trip.clientPhone,
                  ),
                ),
                SizedBox(height: screenHeight / 100),
                Divider(thickness: 0.1, color: Colors.black),
                Spacer(),
                Divider(thickness: 0.1, color: Colors.black),
                SizedBox(height: screenHeight / 100),
                BorderlessButton(
                  primaryText: "CANCELAR CORRIDA",
                  primaryTextColor: AppColor.primaryPink,
                  primaryTextSize: 20,
                  primaryTextWeight: FontWeight.w600,
                  onTap: () async {
                    await cancelTrip(context);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: screenHeight / 100),
                Divider(thickness: 0.1, color: Colors.black),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> cancelTrip(BuildContext context) async {
    UserModel firebase = Provider.of<UserModel>(context, listen: false);

    await showYesNoDialog(
      context,
      title: "Cancelar corrida?",
      onPressedYes: () async {
        Navigator.pop(context);
        setState(() {
          lockScreen = true;
        });
        try {
          await firebase.functions.cancelTrip();
        } catch (_) {}
      },
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
