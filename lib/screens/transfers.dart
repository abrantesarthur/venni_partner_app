import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/screens/transferDetail.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class TransfersRouteArguments {
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  TransfersRouteArguments(this.firebase, this.connectivity);
}

class TransfersRoute extends StatefulWidget {
  static String routeName = "TransfersRoute";
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  TransfersRoute({@required this.firebase, @required this.connectivity});

  @override
  TransfersRouteState createState() => TransfersRouteState();
}

class TransfersRouteState extends State<TransfersRoute> {
  Future<Transfers> transfersFuture;
  List<Transfer> transfers;

  @override
  void initState() {
    super.initState();
    transfers = [];
    transfersFuture = getTransfers();
  }

  Future<Transfers> getTransfers() async {
    return widget.firebase.functions.getTransfers(
      GetTransfersArguments(
        count: 10,
        page: 1,
        pagarmeRecipientID: "re_cknuehe3h0jrb0o9th706rvjg",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return FutureBuilder(
      future: transfersFuture,
      builder: (BuildContext context, AsyncSnapshot<Transfers> snapshot) {
        // populate transfers as soon as future returns.
        if (snapshot.hasData && transfers.length == 0) {
          transfers = snapshot.data.items;
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
                SizedBox(height: screenHeight / 30),
                Text(
                  "Extrato",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 30),
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
                          child: transfers.length == 0
                              ? !connectivity.hasConnection
                                  ? Text(
                                      "Você está offline.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                                  : Text(
                                      "Ainda não foram feitas transferências.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return buildTransfer(
                                            context,
                                            transfers[index],
                                          );
                                        },
                                        separatorBuilder: (context, index) {
                                          return Divider(
                                              thickness: 0.1,
                                              color: Colors.black);
                                        },
                                        itemCount: transfers.length,
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

  Widget buildTransfer(
    BuildContext context,
    Transfer transfer,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        TransferDetail.routeName,
        arguments: TransferDetailArguments(transfer: transfer),
      ),
      child: Column(
        children: [
          SizedBox(height: screenHeight / 100),
          Row(
            children: [
              Icon(
                Icons.local_atm,
                size: 26,
              ),
              SizedBox(width: screenWidth / 50),
              Text(
                "transferência",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              RichText(
                text: TextSpan(
                  text: "R\$",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: (transfer.amount / 100).toStringAsFixed(2),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight / 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDatetime(transfer.dateCreated.millisecondsSinceEpoch),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.disabled,
                ),
              ),
              Text(
                transfer.status.getString(),
                style: TextStyle(
                  fontSize: 14,
                  color: transfer.status == TransferStatus.transferred
                      ? AppColor.secondaryGreen
                      : (transfer.status == TransferStatus.pendingTransfer ||
                              transfer.status == TransferStatus.processing
                          ? AppColor.secondaryYellow
                          : AppColor.secondaryRed),
                ),
              ),
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
