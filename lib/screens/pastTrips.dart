import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/screens/pastTripDetail.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class PastTrips extends StatefulWidget {
  static String routeName = "PastTrips";
  final firebase = FirebaseService();

  @override
  PastTripsState createState() => PastTripsState();
}

class PastTripsState extends State<PastTrips> {
  late List<Trip> pastTrips;
  late Future<Trips> getPastTripsResult;
  late bool isLoading;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    pastTrips = [];
    isLoading = false;

    // create scroll controller that triggers getMorePastTrips once user
    // scrolls all the way down to the bottom of the past trips list
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (!isLoading &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
        setState(() {
          isLoading = true;
        });
        getMorePastTrips();
      }
    });

    getPastTripsResult = getPastTrips();
  }

  Future<Trips> getPastTrips() async {
    try {
      // initially get all partner's trips of the last 24 hours
      int now = DateTime.now().millisecondsSinceEpoch;
      GetPastTripsArguments args = GetPastTripsArguments(
        minRequestTime: now - 24 * 60 * 60 * 1000,
      );
      return await widget.firebase.functions.getPastTrips(args: args);
    } catch (_) {
      // on error, return empty list
      return Future.value(Trips(items: []));
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> getMorePastTrips() async {
    //  least recent trip is the last in chronologically sorted pastTrips
    Trip? leastRecentTrip;
    if (pastTrips.isNotEmpty) {
      leastRecentTrip = pastTrips[pastTrips.length - 1];
    }

    // get 10 trips that happened before least recent trip
    int? maxRequestTime;
    if (leastRecentTrip != null) {
      maxRequestTime = leastRecentTrip.requestTime! - 1;
    }
    GetPastTripsArguments args = GetPastTripsArguments(
      pageSize: 10,
      maxRequestTime: maxRequestTime,
    );
    Trips result = Trips(items: []);
    try {
      result = await widget.firebase.functions.getPastTrips(args: args);
    } catch (_) {}
    setState(() {
      pastTrips.addAll(result.items);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return FutureBuilder(
      future: getPastTripsResult,
      builder: (BuildContext context, AsyncSnapshot<Trips> snapshot) {
        // populate pastTrips as soon as future returns. Do this once, when
        // pastTrips is still empty. Otherwise, we will override trips that were
        // added later to pastTrips by getMorePastTrips
        if (snapshot.hasData && pastTrips.length == 0) {
          pastTrips = snapshot.data!.items;
          // if we have less than 5 pastTrips initially, request more
          if (pastTrips.length < 5) {
            getMorePastTrips();
          }
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: OverallPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: screenHeight / 15),
                Text(
                  "Minhas viagens",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 25),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? Container(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColor.primaryPink),
                          ),
                        )
                      : MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: pastTrips.length == 0
                              ? !connectivity.hasConnection
                                  ? Text(
                                      "Você está offline.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                                  : Text(
                                      "Você ainda não fez nenhuma corrida.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                              : Column(
                                  children: [
                                    SizedBox(height: screenHeight / 50),
                                    Expanded(
                                      child: ListView.separated(
                                        controller: scrollController,
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return buildPastTrip(
                                            context,
                                            pastTrips[index],
                                          );
                                        },
                                        separatorBuilder: (context, index) {
                                          return Divider(
                                              thickness: 0.1,
                                              color: Colors.black);
                                        },
                                        itemCount: pastTrips.length,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                ),
                Container(
                  height: isLoading ? 50.0 : 0,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColor.primaryPink),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPastTrip(
    BuildContext context,
    Trip trip,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          PastTripDetail.routeName,
          arguments: PastTripDetailArguments(
            pastTrip: trip,
          ),
        );
      },
      child: Column(
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
                formatDatetime(trip.requestTime ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Text(
                // if payment was cash, display entire fare price, since partner
                // actually got it. If was credit card, display amount he received
                // after all discounts
                "R\$ " +
                    (trip.paymentMethod == PaymentMethod.cash
                        ? (trip.farePrice / 100).toStringAsFixed(2)
                        : ((trip.payment.partnerAmountReceived ??
                                    trip.farePrice * 0.8) /
                                100)
                            .toStringAsFixed(2)),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
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
                  trip.originAddress,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Spacer(flex: 1),
              Text(
                trip.paymentMethod == PaymentMethod.cash
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
              SvgPicture.asset(
                "images/dropOffIcon.svg",
                width: 8,
              ),
              SizedBox(width: screenWidth / 50),
              Flexible(
                child: Text(
                  trip.destinationAddress,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: screenHeight / 100),
        ],
      ),
    );
  }
}

String formatDatetime(int ms) {
  String appendZero(int val) {
    return val < 10 ? "0" + val.toString() : val.toString();
  }

  DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return appendZero(dt.day) +
      "/" +
      appendZero(dt.month) +
      "/" +
      dt.year.toString() +
      " às " +
      appendZero(dt.hour) +
      ":" +
      appendZero(dt.minute);
}
