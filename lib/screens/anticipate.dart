import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class AnticipateArguments {
  final int waitingAmount;

  AnticipateArguments({@required this.waitingAmount});
}

class Anticipate extends StatefulWidget {
  static String routeName = "Anticipate";
  final int waitingAmount;

  Anticipate({@required this.waitingAmount});

  @override
  AnticipateState createState() => AnticipateState();
}

class AnticipateState extends State<Anticipate> {
  MoneyMaskedTextController controller = MoneyMaskedTextController(
    decimalSeparator: ".",
    thousandSeparator: ",",
  );
  bool lockScreen = false;
  Widget buttonChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(
                  onTapCallback: () =>
                      lockScreen == true ? () {} : Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 30),
            Text(
              "Saque",
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
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: reaisFromCents(widget.waitingAmount),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "  pass??vel de antecipa????o",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColor.disabled,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight / 25),
            // TODO: insert input formatters
            AppInputText(
              hintText: "digite o valor em reais",
              keyboardType: TextInputType.numberWithOptions(
                signed: true,
              ),
              controller: controller,
              inputFormatters: [
                LengthLimitingTextInputFormatter(8),
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmittedCallback: (String _) {
                // hide keyboard
                FocusScope.of(context).requestFocus(new FocusNode());
              },
            ),
            SizedBox(height: screenHeight / 50),
            Text(
              "Para receber uma transfer??ncia no mesmo dia, a antecipa????o deve ser solicitada antes das 11h em dias ??teis. Depois desse hor??rio, a antecipa????o ?? realizada no pr??ximo dia ??til.  Ser?? cobrada uma taxa de R\$3,67 por saque realizado. Al??m disso, h?? uma taxa de 1.59% sobre o valores antecipados. Esses s??o referentes a corridas realizadas h?? menos de 15 dias. Para n??o pagar essa taxa, aguarde at?? os valores ficarem dispon??veis e efetue um ???saque??? em vez de uma ???antecipa????o???.",
              style: TextStyle(
                fontSize: 12,
                color: AppColor.disabled,
              ),
            ),
            Spacer(),
            // TODO: lockScreen and show circular progress indicator
            AppButton(
              textData: "Confirmar",
              child: buttonChild,
              onTapCallBack: () async =>
                  lockScreen == true ? () {} : await confirm(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirm(BuildContext context) async {
    // make sure inserted value is valid
    // partner must anticipate at least R$10 because the minimum anticipation
    // accepted by pagarme is based on the minimum unique sale. R$10 should cover
    // most cases here
    if (controller.numberValue * 100 <= 1000) {
      await showOkDialog(
          context: context,
          title: "Valor inserido inv??lido",
          content: "Voc?? pode antecipar no m??nimo R\$10,00");
      return;
    }
    if (controller.numberValue * 100 > widget.waitingAmount) {
      await showOkDialog(
        context: context,
        title: "Valor inserido inv??lido",
        content: "Insira um valor menor que o saldo a receber de R\$" +
            reaisFromCents(widget.waitingAmount),
      );
      return;
    }

    // lock screen and show circular button indicator
    setState(() {
      lockScreen = true;
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    // request anticipation, displaying warning on failure and pushing detail screen
    // TODO: complete this
    await Future.delayed(Duration(seconds: 1));

    // unlock screen and hide circular button indicator
    setState(() {
      lockScreen = false;
      buttonChild = null;
    });
  }
}
