import 'package:flutter/material.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/goBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class TransferDetailArguments {
  final Transfer transfer;

  TransferDetailArguments({required this.transfer});
}

class TransferDetail extends StatefulWidget {
  static String routeName = "TransferDetail";
  final Transfer transfer;

  TransferDetail({required this.transfer});

  @override
  TransferDetailState createState() => TransferDetailState();
}

class TransferDetailState extends State<TransferDetail> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
              "Transferência",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            SizedBox(height: screenHeight / 30),
            RichText(
              text: TextSpan(
                text: "R\$",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: (widget.transfer.amount / 100).toStringAsFixed(2),
                    style: TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight / 50),
            BorderlessButton(
              primaryText: "Taxa",
              secondaryText:
                  "R\$" + (widget.transfer.fee / 100).toStringAsFixed(2),
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            BorderlessButton(
              primaryText: "Status",
              secondaryText: widget.transfer.status.getString(),
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            widget.transfer.status == TransferStatus.transferred
                ? BorderlessButton(
                    primaryText: "Data de depósito",
                    secondaryText: formatDatetime(
                      widget.transfer.fundingDate.millisecondsSinceEpoch,
                    ),
                    primaryTextSize: 16,
                    secondaryTextSize: 18,
                    paddingTop: screenHeight / 150,
                    paddingBottom: screenHeight / 150,
                  )
                : Container(),
            widget.transfer.status == TransferStatus.pendingTransfer ||
                    widget.transfer.status == TransferStatus.processing
                ? BorderlessButton(
                    primaryText: "Previsão de depósito",
                    secondaryText: formatDatetime(
                      widget
                          .transfer.fundingEstimatedDate.millisecondsSinceEpoch,
                    ),
                    primaryTextSize: 16,
                    secondaryTextSize: 18,
                    paddingTop: screenHeight / 150,
                    paddingBottom: screenHeight / 150,
                  )
                : Container(),
            BorderlessButton(
              primaryText: "Banco",
              secondaryText:
                  bankCodeToNameMap[widget.transfer.bankAccount.bankCode],
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            BorderlessButton(
              primaryText: "Agência",
              secondaryText: widget.transfer.bankAccount.agencia +
                  (widget.transfer.bankAccount.agenciaDv != null
                      ? "-" + widget.transfer.bankAccount.agenciaDv
                      : ""),
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            BorderlessButton(
              primaryText: "Conta",
              secondaryText: widget.transfer.bankAccount.conta +
                  (widget.transfer.bankAccount.contaDv != null
                      ? "-" + widget.transfer.bankAccount.contaDv
                      : ""),
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            BorderlessButton(
              primaryText: "Titular",
              secondaryText: widget.transfer.bankAccount.legalName,
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            ),
            BorderlessButton(
              primaryText: "Tipo de conta",
              secondaryText: widget.transfer.bankAccount.type.getString(),
              primaryTextSize: 16,
              secondaryTextSize: 18,
              paddingTop: screenHeight / 150,
              paddingBottom: screenHeight / 150,
            )
          ],
        ),
      ),
    );
  }
}

String formatDatetime(int ms) {
  if (ms == null) {
    return null;
  }
  String appendZero(int val) {
    return val < 10 ? "0" + val.toString() : val.toString();
  }

  DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return appendZero(dt.day) +
      "/" +
      appendZero(dt.month) +
      "/" +
      dt.year.toString();
}
