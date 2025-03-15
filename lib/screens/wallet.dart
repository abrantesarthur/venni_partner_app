import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/balance.dart';
import 'package:partner_app/screens/transfers.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/horizontalBar.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class WalletArguments {
  final UserModel firebase;
  final PartnerModel partner;

  WalletArguments({
    required this.firebase,
    required this.partner,
  });
}

class Wallet extends StatefulWidget {
  static const routeName = "Wallet";
  final UserModel firebase;
  final PartnerModel partner;

  Wallet({
    required this.firebase,
    required this.partner,
  });

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  Future<void> future;
  Balance balance;
  int cashGainsInPeriod = 0;
  int cardGainsInPeriod = 0;
  int tripCountInPeriod = 0;
  Period period = Period.today;
  Transfers transfers;

  @override
  void initState() {
    super.initState();
    future = downloadData();
  }

  Future<void> downloadData() async {
    await Future.wait([downloadBalance(), getPastTrips(period)]);
  }

  Future<void> downloadBalance() async {
    // download partner data to update amount owed
    await widget.partner.downloadData(widget.firebase);

    balance = await widget.firebase.functions.getBalance(
      widget.partner.pagarmeRecipientID,
    );
  }

  Future<Trips> getPastTrips(Period period) async {
    cashGainsInPeriod = 0;
    cardGainsInPeriod = 0;
    Trips trips;
    try {
      // initially get all partner's trips of according to the period
      // (today, this week, or this month)
      GetPastTripsArguments args = GetPastTripsArguments(
        minRequestTime: period.getTimestamp(),
      );
      trips = await widget.firebase.functions.getPastTrips(args: args);

      // calculate cash and card revenues of the last 24 hours
      trips.items.forEach((trip) {
        if (trip.paymentMethod == PaymentMethod.cash) {
          // for cash, we consider entire fare prace, which is, in fact, what
          // the partner received
          cashGainsInPeriod += trip.farePrice;
        } else {
          // for credit card payments, we consider what the partner received
          // after paying Venni's commissions
          cardGainsInPeriod += trip.payment?.partnerAmountReceived ??
              (0.8 * trip.farePrice).round();
        }
      });

      tripCountInPeriod = trips.items.length;

      return trips;
    } catch (_) {
      // on error, return empty list
      return Future.value(Trips(items: []));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    PartnerModel partner = Provider.of<PartnerModel>(context);
    UserModel firebase = Provider.of<UserModel>(
      context,
      listen: false,
    );
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );

    return FutureBuilder<void>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<void> snapshot,
      ) {
        if (snapshot.hasError) {
          print(snapshot.error.toString());
        }
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
                  "Carteira",
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
                        ? Center(
                            child: Text(
                                "Algo deu errado. Tente novamente mais tarde."),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenHeight / 50),
                                  Text(
                                    "Balanço",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "próximo pagamento",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: AppColor.secondaryGreen,
                                          ),
                                          children: [
                                            TextSpan(
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              text: "R\$",
                                            ),
                                            TextSpan(
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              text: reaisFromCents(
                                                balance.available.amount,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight / 100),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "saldo a receber",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: AppColor.secondaryYellow,
                                          ),
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
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              text: reaisFromCents(
                                                balance.waitingFunds.amount,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight / 100),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "saldo devedor",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: AppColor.secondaryRed,
                                          ),
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
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              text: reaisFromCents(
                                                partner.amountOwed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  BorderlessButton(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      BalanceRoute.routeName,
                                    ),
                                    primaryText: "saber mais",
                                    primaryTextSize: 14,
                                    iconRight: Icons.keyboard_arrow_right,
                                    iconRightColor: Colors.blue,
                                    primaryTextColor: Colors.blue,
                                  ),
                                  SizedBox(height: screenHeight / 40),
                                  Divider(color: Colors.black, thickness: 0.1),
                                  SizedBox(height: screenHeight / 50),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Ganhos",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      DropdownButtonHideUnderline(
                                        child: ButtonTheme(
                                          alignedDropdown: true,
                                          child: DropdownButton(
                                            value: period,
                                            onChanged: (value) async {
                                              await getPastTrips(value);
                                              setState(() {
                                                period = value;
                                              });
                                            },
                                            items: Period.values
                                                .map((tf) => DropdownMenuItem(
                                                      child:
                                                          Text(tf.getString()),
                                                      value: tf,
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight / 100),
                                  Center(
                                    child: RichText(
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
                                            text: ((cashGainsInPeriod +
                                                        cardGainsInPeriod) /
                                                    100)
                                                .toStringAsFixed(2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  HorizontalBar(
                                    leftText: "Dinheiro",
                                    rightText: "R\$" +
                                        (cashGainsInPeriod / 100)
                                            .toStringAsFixed(2),
                                    fill: (cashGainsInPeriod == 0 &&
                                            cardGainsInPeriod == 0)
                                        ? 0
                                        : cashGainsInPeriod /
                                            (cashGainsInPeriod +
                                                cardGainsInPeriod),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  HorizontalBar(
                                    leftText: "Cartão",
                                    rightText: "R\$" +
                                        (cardGainsInPeriod / 100)
                                            .toStringAsFixed(2),
                                    fill: (cashGainsInPeriod == 0 &&
                                            cardGainsInPeriod == 0)
                                        ? 0
                                        : cardGainsInPeriod /
                                            (cashGainsInPeriod +
                                                cardGainsInPeriod),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  HorizontalBar(
                                    leftText: "Corridas",
                                    rightText: tripCountInPeriod.toString() +
                                        (period == Period.today
                                            ? "/20"
                                            : period == Period.thisWeek
                                                ? "/100"
                                                : "/400"),
                                    fill: tripCountInPeriod == 0
                                        ? 0
                                        : tripCountInPeriod /
                                            (period == Period.today
                                                ? 20
                                                : period == Period.thisWeek
                                                    ? 100
                                                    : 400),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  Divider(thickness: 0.1, color: Colors.black),
                                  SizedBox(height: screenHeight / 50),
                                  Center(
                                    child: AppButton(
                                      textData: "ver extrato",
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                      width: screenWidth / 3,
                                      height: screenHeight / 20,
                                      borderRadius: 15,
                                      onTapCallBack: () => Navigator.pushNamed(
                                        context,
                                        TransfersRoute.routeName,
                                        arguments: TransfersRouteArguments(
                                          firebase,
                                          connectivity,
                                        ),
                                      ),
                                    ),
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

enum Period {
  today,
  thisWeek,
  thisMonth,
}

extension PeriodExtension on Period {
  String getString() {
    switch (this) {
      case Period.today:
        return "hoje";
      case Period.thisWeek:
        return "esta semana";
      case Period.thisMonth:
        return "este mês";
      default:
        return "últimas 24 horas";
    }
  }

  int getTimestamp() {
    DateTime now = DateTime.now();
    switch (this) {
      // today at midnigth
      case Period.today:
        return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      // week starts on monday at midnight
      case Period.thisWeek:
        return now.subtract(Duration(days: now.weekday)).millisecondsSinceEpoch;
      case Period.thisMonth:
        return DateTime(now.year, now.month).millisecondsSinceEpoch;
      default:
        return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    }
  }
}
