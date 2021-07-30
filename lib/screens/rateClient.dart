import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/circularImage.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class RateClient extends StatefulWidget {
  static String routeName = "RateClient";

  RateClientState createState() => RateClientState();
}

class RateClientState extends State<RateClient> {
  String _rateDescription;
  int _rate;
  bool _showThankYouMessage;
  bool activateButton;
  bool _lockScreen;

  @override
  void initState() {
    _rateDescription = "nota geral";
    _rate = 0;
    _lockScreen = false;
    activateButton = false;
    _showThankYouMessage = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    PartnerModel partner = Provider.of<PartnerModel>(context);
    TripModel trip = Provider.of<TripModel>(context);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        top: screenHeight / 10,
        bottom: screenHeight / 10,
        child: _showThankYouMessage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Obrigado pela avaliação!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primaryPink,
                    ),
                  ),
                  SizedBox(height: screenHeight / 50),
                  Text(
                    "Até a próxima.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColor.disabled,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "R\$ " + (trip.farePrice / 100).toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: trip.paymentMethod == PaymentMethod.cash
                          ? AppColor.primaryPink
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight / 100),
                  Text(
                    trip.paymentMethod == PaymentMethod.cash
                        ? "Receba o pagamento em dinheiro"
                        : "Corrida paga com cartão",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          trip.paymentMethod == PaymentMethod.cash ? 24 : 18,
                      color: trip.paymentMethod == PaymentMethod.cash
                          ? AppColor.primaryPink
                          : Colors.green,
                      fontWeight: trip.paymentMethod == PaymentMethod.cash
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight / 50),
                  Divider(thickness: 0.1, color: Colors.black),
                  SizedBox(height: screenHeight / 50),
                  Text(
                    "Avalie a sua corrida com " + partner.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight / 25),
                  CircularImage(
                    size: screenHeight / 9,
                    imageFile: trip.profileImage == null
                        ? AssetImage("images/user_icon.png")
                        : trip.profileImage.file,
                  ),
                  SizedBox(height: screenHeight / 25),
                  Column(
                    children: [
                      Text(
                        _rateDescription,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => pickRate(1),
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: screenWidth / 100),
                              child: Icon(
                                _rate >= 1
                                    ? Icons.star_sharp
                                    : Icons.star_border_sharp,
                                size: 50,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => pickRate(2),
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: screenWidth / 100,
                                left: screenWidth / 100,
                              ),
                              child: Icon(
                                _rate >= 2
                                    ? Icons.star_sharp
                                    : Icons.star_border_sharp,
                                size: 50,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => pickRate(3),
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: screenWidth / 100,
                                left: screenWidth / 100,
                              ),
                              child: Icon(
                                _rate >= 3
                                    ? Icons.star_sharp
                                    : Icons.star_border_sharp,
                                size: 50,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => pickRate(4),
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: screenWidth / 100,
                                left: screenWidth / 100,
                              ),
                              child: Icon(
                                _rate >= 4
                                    ? Icons.star_sharp
                                    : Icons.star_border_sharp,
                                size: 50,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => pickRate(5),
                            child: Padding(
                              padding: EdgeInsets.only(left: screenWidth / 100),
                              child: Icon(
                                _rate >= 5
                                    ? Icons.star_sharp
                                    : Icons.star_border_sharp,
                                size: 50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
                  AppButton(
                    textData: "Avaliar",
                    buttonColor: activateButton
                        ? AppColor.primaryPink
                        : AppColor.disabled,
                    onTapCallBack: (!activateButton || _lockScreen)
                        ? () {}
                        : () async => await rateClient(
                              context: context,
                              rate: _rate,
                            ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> rateClient({
    @required BuildContext context,
    @required int rate,
  }) async {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // ensure partner is connected to the internet
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(
        context,
        message: "Conecte-se à internet para avaliar o cliente.",
      );
      return;
    }

    // lock screen and show message
    setState(() {
      _lockScreen = true;
      _showThankYouMessage = true;
    });

    //call completeTrip
    try {
      firebase.functions.completeTrip(rate);
    } catch (e) {
      showOkDialog(
        context: context,
        title: "Algo deu errado",
        content: "Tente novamente mais tarde",
      );
    }

    // on success, increase partner's gains by 80% of fare price to account for
    // venni's 20% stake.
    partner.increaseGainsBy((trip.farePrice * 0.8).round());

    // set partner available locally. completeTrip will have done the same in backend
    partner.updatePartnerStatus(PartnerStatus.available);

    // wait 3 seconds then pop back
    await Future.delayed(Duration(seconds: 3));
    Navigator.pop(context);
  }

  void pickRate(int rate) {
    if (_lockScreen) {
      return;
    }
    switch (rate) {
      case 1:
        _rate = 1;
        _rateDescription = "péssima";
        break;
      case 2:
        _rate = 2;
        _rateDescription = "ruim";
        break;
      case 3:
        _rate = 3;
        _rateDescription = "regular";
        break;
      case 4:
        _rate = 4;
        _rateDescription = "boa";
        break;
      case 5:
        _rate = 5;
        _rateDescription = "excelente";
        break;
      default:
        _rate = 0;
        _rateDescription = "nota geral";
        break;
    }

    if (_rate > 0) {
      activateButton = true;
    }

    setState(() {});
  }
}
