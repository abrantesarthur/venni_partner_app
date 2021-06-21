import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/anticipate.dart';
import 'package:partner_app/screens/withdraw.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class WalletArguments {
  final FirebaseModel firebase;
  final PartnerModel partner;

  WalletArguments({
    @required this.firebase,
    @required this.partner,
  });
}

class Wallet extends StatefulWidget {
  static const routeName = "Wallet";
  final FirebaseModel firebase;
  final PartnerModel partner;

  Wallet({
    @required this.firebase,
    @required this.partner,
  });

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  Future<Balance> balance;

  @override
  void initState() {
    super.initState();
    balance = downloadBalance();
  }

  Future<Balance> downloadBalance() {
    return widget.firebase.functions.getBalance(
      widget.partner.pagarmeRecipientID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    PartnerModel partner = Provider.of<PartnerModel>(context);

    return FutureBuilder<Balance>(
      future: balance,
      builder: (
        BuildContext context,
        AsyncSnapshot<Balance> balance,
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
                  "Carteira",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 25),
                balance.connectionState == ConnectionState.waiting
                    ? Expanded(
                        child: Center(
                            child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.primaryPink),
                        )),
                      )
                    : balance.hasError ||
                            (balance.hasData && balance.data == null)
                        ? Center(
                            child: Text(
                                "Algo deu errado. Tente novamente mais tarde."),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "Saldo",
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
                                          text: reaisFromCents(
                                            balance.data.available.amount,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 200),
                                  Text(
                                    "referente a pagamentos via cartão de crédito",
                                    style: TextStyle(
                                        color: AppColor.disabled, fontSize: 14),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  AppButton(
                                    textData: "sacar",
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                    width: screenWidth / 3,
                                    height: screenHeight / 20,
                                    borderRadius: 15,
                                    onTapCallBack: () async => await withdraw(
                                      context,
                                      balance.data.available.amount,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  Divider(color: Colors.black, thickness: 0.1),
                                  SizedBox(height: screenHeight / 50),
                                  Center(
                                    child: Text(
                                      "A Receber",
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
                                          text: reaisFromCents(
                                            balance.data.waitingFunds.amount,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 200),
                                  Text(
                                    "referente a valores pagos há menos de 15 dias",
                                    style: TextStyle(
                                        color: AppColor.disabled, fontSize: 14),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  AppButton(
                                    textData: "antecipar",
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                    width: screenWidth / 3,
                                    height: screenHeight / 20,
                                    borderRadius: 15,
                                    onTapCallBack: () async => await anticipate(
                                      context,
                                      balance.data.waitingFunds.amount,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
                                  Divider(color: Colors.black, thickness: 0.1),
                                  SizedBox(height: screenHeight / 50),
                                  Center(
                                    child: Text(
                                      "Saldo Devedor",
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
                                          text: reaisFromCents(
                                            partner.amountOwed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 200),
                                  Text(
                                    "referente à taxa cobrada pela Venni sobre pagamentos recebidos em dinheiro",
                                    style: TextStyle(
                                      color: AppColor.disabled,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight / 50),
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

  Future<void> withdraw(
    BuildContext context,
    int availableAmount,
  ) async {
    if (availableAmount <= 0) {
      await showOkDialog(
        context: context,
        title: "Sem saldo disponível",
        content:
            "Faça algumas corridas ou aguarde alguns dias para seu saldo a receber ficar disponível.",
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      Withdraw.routeName,
      arguments: WithdrawArguments(
        availableAmount: availableAmount,
      ),
    );
  }

  Future<void> anticipate(
    BuildContext context,
    int waitingAmount,
  ) async {
    if (waitingAmount <= 0) {
      await showOkDialog(
        context: context,
        title: "Sem saldo a receber",
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      Anticipate.routeName,
      arguments: AnticipateArguments(
        waitingAmount: waitingAmount,
      ),
    );
  }
}
