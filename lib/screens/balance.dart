import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class BalanceRoute extends StatefulWidget {
  static const routeName = "BalanceRoute";
  @override
  BalanceRouteState createState() => BalanceRouteState();
}

class BalanceRouteState extends State<BalanceRoute> {
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
                ArrowBackButton(onTapCallback: () => Navigator.pop(context)),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Balanço",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            SizedBox(height: screenHeight / 25),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "próximo pagamento",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight / 100),
                    Text(
                      "Corresponde às corridas pagas via cartão de crédito há mais de 15 dias. Este valor é acrescido ao longo dos dias, conforme o 'Saldo a Receber' vai ficando disponível. Semanalmente, no dia do pagamento, ele é transferido automaticamente para a sua conta bancária. ",
                      style: TextStyle(
                        color: AppColor.disabled,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: screenHeight / 30),
                    Text(
                      "saldo a receber",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight / 100),
                    Text(
                      "Corresponde às corridas pagas via cartão de crédito há menos de 15 dias. Portanto, quando você faz corridas pagas com cartão, o 'Saldo a Receber' aumenta. De maneira oposta, conforme os dias passam, ele diminui, já que parte dele vai ficando disponível para ser pago no 'Próximo Pagamento'.",
                      style: TextStyle(
                        color: AppColor.disabled,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: screenHeight / 30),
                    Text(
                      "saldo devedor",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight / 100),
                    Text(
                      "Quando você faz corridas pagas em dinheiro, o seu 'Saldo Devedor' aumenta em um valor correspondente à comissão da Venni. De maneira oposta, quando você faz corridas pagas em cartão de crédito, caso haja 'Saldo Devedor', ele é descontado da sua parte do pagamento e, portanto, o 'Saldo Devedor' diminui.",
                      style: TextStyle(
                        color: AppColor.disabled,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: screenHeight / 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
