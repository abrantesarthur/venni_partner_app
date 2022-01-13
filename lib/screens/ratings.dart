import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/floatingCard.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/horizontalBar.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class RatingsArguments {
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;
  final PartnerModel partner;

  RatingsArguments(
    this.firebase,
    this.connectivity,
    this.partner,
  );
}

class Ratings extends StatefulWidget {
  static String routeName = "Ratings";
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;
  final PartnerModel partner;

  Ratings({
    @required this.firebase,
    @required this.connectivity,
    @required this.partner,
  });

  @override
  RatingsState createState() => RatingsState();
}

class RatingsState extends State<Ratings> {
  List<Trip> pastTrips = [];
  Future<Trips> getPastTripsResult;
  bool isLoading = false;
  int fiveStarsCount = 0;
  int fourStarsCount = 0;
  int threeStarsCount = 0;
  int twoStarsCount = 0;
  int oneStarCount = 0;
  int ratingsCount = 0;
  Map<String, int> feedbackRatingMap = {};

  @override
  void initState() {
    super.initState();
    getPastTripsResult = getPastTrips();
  }

  Future<Trips> getPastTrips() async {
    Trips trips;
    try {
      // get at most 200 past trips
      GetPastTripsArguments args = GetPastTripsArguments(pageSize: 200);
      trips = await widget.firebase.functions.getPastTrips(args: args);

      // downlaod partner data so ratings is updated
      await widget.partner.downloadData(widget.firebase);

      trips.items.forEach((trip) {
        // save feedback if it exists
        if (trip.partnerRating?.feedback != null) {
          feedbackRatingMap[trip.partnerRating.feedback] =
              trip.partnerRating.score;
        }

        // increase rating if exists
        if (trip.partnerRating != null) {
          ratingsCount++;
        }

        // calculate start counts
        switch (trip.partnerRating?.score) {
          case 1:
            oneStarCount += 1;
            break;
          case 2:
            twoStarsCount += 1;
            break;
          case 3:
            threeStarsCount += 1;
            break;
          case 4:
            fourStarsCount += 1;
            break;
          case 5:
            fiveStarsCount += 1;
            break;
        }
      });

      return trips;
    } catch (_) {
      // on error, return empty list
      return Future.value(Trips(items: []));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);

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
          backgroundColor: Colors.white,
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
                SizedBox(height: screenHeight / 25),
                Text(
                  "Avaliações",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (partner.rating ?? 5.00).toString(),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: screenWidth / 50),
                    Icon(Icons.star_sharp),
                  ],
                ),
                SizedBox(height: screenHeight / 100),
                Center(
                  child: Text(
                    (partner.rating ?? 5) > 4.5
                        ? "Excelente"
                        : partner.rating > 4.0
                            ? "Bom"
                            : partner.rating > 3.5
                                ? "Regular"
                                : "Ruim",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (partner.rating ?? 5) > 4.5
                          ? Colors.green
                          : partner.rating > 4
                              ? AppColor.secondaryYellow
                              : AppColor.secondaryRed,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight / 50),
                Center(
                  child: Text(
                    "Últimas " + ratingsCount.toString() + " avaliações",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.disabled,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight / 50),
                HorizontalBar(
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "5",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.star_sharp, size: 14),
                    ],
                  ),
                  centerWidth: screenWidth / 1.7,
                  rightText: fiveStarsCount.toString(),
                  fill: ratingsCount == 0 ? 0 : (fiveStarsCount / ratingsCount),
                ),
                SizedBox(height: screenHeight / 100),
                HorizontalBar(
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "4",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.star_sharp, size: 14),
                    ],
                  ),
                  centerWidth: screenWidth / 1.7,
                  rightText: fourStarsCount.toString(),
                  fill: ratingsCount == 0 ? 0 : (fourStarsCount / ratingsCount),
                ),
                SizedBox(height: screenHeight / 100),
                HorizontalBar(
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "3",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.star_sharp, size: 14),
                    ],
                  ),
                  centerWidth: screenWidth / 1.75,
                  rightText: threeStarsCount.toString(),
                  fill:
                      ratingsCount == 0 ? 0 : (threeStarsCount / ratingsCount),
                ),
                SizedBox(height: screenHeight / 100),
                HorizontalBar(
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "2",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.star_sharp, size: 14),
                    ],
                  ),
                  centerWidth: screenWidth / 1.7,
                  rightText: twoStarsCount.toString(),
                  fill: ratingsCount == 0 ? 0 : (twoStarsCount / ratingsCount),
                ),
                SizedBox(height: screenHeight / 100),
                HorizontalBar(
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "1",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.star_sharp, size: 14),
                    ],
                  ),
                  centerWidth: screenWidth / 1.7,
                  rightText: oneStarCount.toString(),
                  fill: ratingsCount == 0 ? 0 : (oneStarCount / ratingsCount),
                ),
                SizedBox(height: screenHeight / 50),
                Divider(thickness: 0.1, color: Colors.black),
                SizedBox(height: screenHeight / 50),
                Center(
                  child: Text(
                    "Comentários Recentes",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColor.disabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight / 50),
                feedbackRatingMap.isEmpty
                    ? Center(
                        child: Text(
                          "Você ainda não recebeu comentários",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColor.disabled,
                          ),
                        ),
                      )
                    : MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeBottom: true,
                        child: Expanded(
                          child: ListView.separated(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return buildComment(
                                context: context,
                                feedback: feedbackRatingMap.entries
                                    .elementAt(index)
                                    .key,
                                rating: feedbackRatingMap.entries
                                    .elementAt(index)
                                    .value,
                              );
                            },
                            separatorBuilder: (context, index) {
                              return SizedBox(height: screenHeight / 25);
                            },
                            itemCount: feedbackRatingMap.entries.length,
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

  Widget buildComment({
    @required BuildContext context,
    @required String feedback,
    @required int rating,
  }) {
    return FloatingCard(
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              feedback,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Spacer(),
          Text(
            rating.toString(),
            style: TextStyle(
              color: rating > 4
                  ? Colors.green
                  : rating == 4
                      ? AppColor.secondaryYellow
                      : AppColor.secondaryRed,
            ),
          ),
          Icon(
            Icons.star,
            size: 14,
            color: rating == 5
                ? Colors.green
                : rating == 4
                    ? AppColor.secondaryYellow
                    : AppColor.secondaryRed,
          )
        ],
      ),
      borderRadius: 0,
      leftMargin: 0,
      rightMargin: 0,
      elevation: 2,
    );
  }
}
