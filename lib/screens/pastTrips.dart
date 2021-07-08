import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/screens/pastTripDetail.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/horizontalBar.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class PastTripsArguments {
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  PastTripsArguments(this.firebase, this.connectivity);
}

class PastTrips extends StatefulWidget {
  static String routeName = "PastTrips";
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  PastTrips({@required this.firebase, @required this.connectivity});

  @override
  PastTripsState createState() => PastTripsState();
}

class PastTripsState extends State<PastTrips> {
  List<Trip> pastTrips;
  Future<Trips> getPastTripsResult;
  bool isLoading;
  ScrollController scrollController;
  bool _hasConnection;
  int lastDayCashRevenue;
  int lastDayCardRevenue;
  int lastDayTripAmount;

  @override
  void initState() {
    super.initState();
    pastTrips = [];
    isLoading = false;
    _hasConnection = widget.connectivity.hasConnection;
    lastDayCashRevenue = 0;
    lastDayCardRevenue = 0;

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
    Trips trips;
    try {
      // initially get all partner's trips of the last 24 hours
      int now = DateTime.now().millisecondsSinceEpoch;
      GetPastTripsArguments args = GetPastTripsArguments(
        minRequestTime: now - 24 * 60 * 60 * 1000,
      );
      trips = await widget.firebase.functions.getPastTrips(args: args);

      // calculate cash and card revenues of the last 24 hours
      trips.items.forEach((trip) {
        if (trip.paymentMethod == PaymentMethod.cash) {
          // for cash, we consider entire fare prace, which is, in fact, what
          // the partner received
          lastDayCashRevenue += trip.farePrice;
        } else {
          // for credit card payments, we consider what the partner received
          // after paying Venni's commissions
          lastDayCardRevenue += trip.payment?.partnerAmountReceived ??
              (0.8 * trip.farePrice).round();
        }
      });

      lastDayTripAmount = trips.items.length;

      return trips;
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
    Trip leastRecentTrip;
    if (pastTrips.isNotEmpty) {
      leastRecentTrip = pastTrips[pastTrips.length - 1];
    }

    // get 10 trips that happened before least recent trip
    int maxRequestTime;
    if (leastRecentTrip != null) {
      maxRequestTime = leastRecentTrip.requestTime - 1;
    }
    GetPastTripsArguments args = GetPastTripsArguments(
      pageSize: 10,
      maxRequestTime: maxRequestTime,
    );
    Trips result;
    try {
      result = await widget.firebase.functions.getPastTrips(args: args);
    } catch (_) {}
    setState(() {
      if (result != null) {
        pastTrips.addAll(result.items);
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    // get more past trips whenever connection changes from offline to online
    if (_hasConnection != connectivity.hasConnection) {
      _hasConnection = connectivity.hasConnection;
      if (connectivity.hasConnection) {
        getMorePastTrips();
      }
    }

    return FutureBuilder(
      future: getPastTripsResult,
      builder: (BuildContext context, AsyncSnapshot<Trips> snapshot) {
        // populate pastTrips as soon as future returns. Do this once, when
        // pastTrips is still empty. Otherwise, we will override trips that were
        // added later to pastTrips by getMorePastTrips
        if (snapshot.hasData && pastTrips.length == 0) {
          pastTrips = snapshot.data.items;
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
                                    Center(
                                      child: Text(
                                        "Ganhos Nas Últimas 24h",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight / 50),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            text: "R\$",
                                          ),
                                          TextSpan(
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            text: ((lastDayCashRevenue +
                                                        lastDayCardRevenue) /
                                                    100)
                                                .toStringAsFixed(2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: screenHeight / 50),
                                    HorizontalBar(
                                      leftText: "Dinheiro",
                                      rightText: "R\$" +
                                          (lastDayCashRevenue / 100)
                                              .toStringAsFixed(2),
                                      fill: (lastDayCashRevenue == 0 &&
                                              lastDayCashRevenue == 0)
                                          ? 0
                                          : lastDayCashRevenue /
                                              (lastDayCashRevenue +
                                                  lastDayCardRevenue),
                                    ),
                                    SizedBox(height: screenHeight / 50),
                                    HorizontalBar(
                                      leftText: "Cartão",
                                      rightText: "R\$" +
                                          (lastDayCardRevenue / 100)
                                              .toStringAsFixed(2),
                                      fill: (lastDayCashRevenue == 0 &&
                                              lastDayCashRevenue == 0)
                                          ? 0
                                          : lastDayCardRevenue /
                                              (lastDayCashRevenue +
                                                  lastDayCardRevenue),
                                    ),
                                    SizedBox(height: screenHeight / 50),
                                    Row(
                                      children: [
                                        Text(
                                          "Corridas Realizadas",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          lastDayTripAmount.toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight / 50),
                                    Divider(
                                        thickness: 0.1, color: Colors.black),
                                    SizedBox(height: screenHeight / 50),
                                    Center(
                                      child: Text(
                                        "Corridas",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
            firebase: widget.firebase,
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
                formatDatetime(trip.requestTime),
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
                        : ((trip.payment?.partnerAmountReceived ??
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
