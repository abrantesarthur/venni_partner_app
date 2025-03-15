import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class WithdrawArguments {
  final int availableAmount;

  WithdrawArguments({required this.availableAmount});
}

class Withdraw extends StatefulWidget {
  static String routeName = "Withdraw";
  final int availableAmount;

  Withdraw({required this.availableAmount});

  @override
  WithdrawState createState() => WithdrawState();
}

class WithdrawState extends State<Withdraw> {
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
                      lockScreen ? () {} : Navigator.pop(context),
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
                    text: reaisFromCents(widget.availableAmount),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "  de saldo disponível",
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
              "Para receber uma transferência no mesmo dia, solicite o saque antes de 15h em dias úteis. Depois desse horário, o saque é realizado no próximo dia útil.  Será cobrada uma taxa de R\$3,67 por saque realizado.",
              style: TextStyle(
                fontSize: 12,
                color: AppColor.disabled,
              ),
            ),
            Spacer(),
            AppButton(
              textData: "Confirmar",
              child: buttonChild,
              onTapCallBack: () async =>
                  lockScreen ? () {} : await confirm(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirm(BuildContext context) async {
    // make sure inserted value is valid
    if (controller.numberValue * 100 <= 500) {
      await showOkDialog(
          context: context,
          title: "Valor inserido inválido",
          content: "Você pode sacar no mínimo R\$5,00");
      return;
    }
    if (controller.numberValue * 100 > widget.availableAmount) {
      await showOkDialog(
        context: context,
        title: "Valor inserido inválido",
        content: "Insira um valor menor que o saldo disponível de R\$" +
            reaisFromCents(widget.availableAmount),
      );
      return;
    }
    if (controller.numberValue * 100 > 999999) {
      await showOkDialog(
        context: context,
        title: "Valor inserido inválido",
        content: "Você pode sacar no máximo R\$9,999.99 por vez",
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

    // request withdraw
    try {
      UserModel firebase = Provider.of<UserModel>(
        context,
        listen: false,
      );
      PartnerModel partner = Provider.of<PartnerModel>(
        context,
        listen: false,
      );
      Transfer transfer = await firebase.functions.createTransfer(
        amount: (controller.numberValue * 100).floor().toString(),
        pagarmeRecipientID: partner.pagarmeRecipientID,
      );
    } catch (e) {
      // displaying warning on failure
      await showOkDialog(
        context: context,
        title: "Algo deu errado",
        content: "Tente novamente mais tarde",
      );
      // unlock screen and hide circular button indicator
      setState(() {
        lockScreen = false;
        buttonChild = null;
      });
      return;
    }

    // unlock screen and hide circular button indicator
    setState(() {
      lockScreen = false;
      buttonChild = null;
    });

    Navigator.pop(context);
  }
}
