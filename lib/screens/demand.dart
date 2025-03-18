import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/horizontalBar.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:provider/provider.dart';


class Demand extends StatefulWidget {
  static const routeName = "Demand";
  final FirebaseService firebase = FirebaseService();

  @override
  DemandState createState() => DemandState();
}

class DemandState extends State<Demand> {
  late Future<void> future;
  int approvedPartnersCount = 0;
  int connectedPartnersCount = 0;
  int busyPartnersCount = 0;

  @override
  void initState() {
    super.initState();
    future = downloadData();
  }

  Future<void> downloadData() async {
    ApprovedPartners approvedPartners =
        await widget.firebase.functions.getApprovedPartners();
    approvedPartnersCount = approvedPartners.items.length;
    approvedPartners.items.forEach((partner) {
      if (partner.status == PartnerStatus.available) {
        connectedPartnersCount++;
      } else if (partner.status == PartnerStatus.busy) {
        busyPartnersCount++;
        connectedPartnersCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return FutureBuilder<void>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<void> snapshot,
      ) {
        return Scaffold(
          body: OverallPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ArrowBackButton(
                        onTapCallback: () => Navigator.pop(context)),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 25),
                Text(
                  "Demanda",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 30),
                snapshot.connectionState == ConnectionState.waiting
                    ? Expanded(
                        child: Center(
                            child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.primaryPink),
                        )),
                      )
                    : snapshot.hasError
                        ? Text(
                            !connectivity.hasConnection
                                ? "Você está offline. Verifique sua conexão e tente novamente."
                                : "Algo deu errado. Tente novamente mais tarde.",
                            style: TextStyle(color: AppColor.disabled),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "Parceiros",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  HorizontalBar(
                                    leftText: "Conectados",
                                    leftFlex: 3,
                                    rightFlex: 2,
                                    centerWidth: screenWidth / 1.9,
                                    rightText:
                                        connectedPartnersCount.toString() +
                                            "/" +
                                            approvedPartnersCount.toString(),
                                    fill: approvedPartnersCount == 0
                                        ? 0
                                        : connectedPartnersCount /
                                            approvedPartnersCount,
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  HorizontalBar(
                                    leftText: "Ocupados",
                                    leftFlex: 3,
                                    rightFlex: 2,
                                    centerWidth: screenWidth / 1.9,
                                    rightText: busyPartnersCount.toString() +
                                        "/" +
                                        connectedPartnersCount.toString(),
                                    fill: connectedPartnersCount == 0
                                        ? 0
                                        : busyPartnersCount /
                                            connectedPartnersCount,
                                  ),
                                ],
                              ),
                            ),
                          ),
              ],
            ),
          ),
        );
      },
    );
  }
}
