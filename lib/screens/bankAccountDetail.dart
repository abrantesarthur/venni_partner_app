import 'package:flutter/material.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/sendBankAccount.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/goBackScaffold.dart';
import 'package:provider/provider.dart';

class BankAccountDetail extends StatefulWidget {
  static const String routeName = "BankAccountDetail";

  BankAccountDetailState createState() => BankAccountDetailState();
}

class BankAccountDetailState extends State<BankAccountDetail> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final PartnerModel partner = Provider.of<PartnerModel>(context);

    return GoBackScaffold(title: "Informações Bancárias", children: [
      BorderlessButton(
        primaryText: "Agência",
        primaryTextWeight: FontWeight.w600,
        secondaryText: partner.bankAccount.agencia +
            (partner.bankAccount.agenciaDv == null
                ? ""
                : ("-" + partner.bankAccount.agenciaDv)),
        primaryTextSize: 14,
        secondaryTextSize: 16,
        paddingTop: screenHeight / 150,
        paddingBottom: screenHeight / 150,
      ),
      Divider(thickness: 0.1, color: Colors.black),
      BorderlessButton(
        primaryText: "Conta",
        primaryTextWeight: FontWeight.w600,
        secondaryText: partner.bankAccount.conta +
            (partner.bankAccount.contaDv == null
                ? ""
                : ("-" + partner.bankAccount.contaDv)),
        primaryTextSize: 14,
        secondaryTextSize: 16,
        paddingTop: screenHeight / 150,
        paddingBottom: screenHeight / 150,
      ),
      Divider(thickness: 0.1, color: Colors.black),
      BorderlessButton(
        primaryText: "Banco",
        primaryTextWeight: FontWeight.w600,
        secondaryText: bankCodeToNameMap[partner.bankAccount.bankCode],
        primaryTextSize: 14,
        secondaryTextSize: 16,
        paddingTop: screenHeight / 150,
        paddingBottom: screenHeight / 150,
      ),
      Divider(thickness: 0.1, color: Colors.black),
      BorderlessButton(
        primaryText: "Tipo de Conta",
        primaryTextWeight: FontWeight.w600,
        secondaryText: partner.bankAccount.type.getString(format: true),
        primaryTextSize: 14,
        secondaryTextSize: 16,
        paddingTop: screenHeight / 150,
        paddingBottom: screenHeight / 150,
      ),
      Spacer(),
      AppButton(
        textData: "Alterar",
        onTapCallBack: () {
          Navigator.pushNamed(
            context,
            SendBankAccount.routeName,
            arguments: SendBankAccountArguments(
              mode: SendBankAccountMode.edit,
            ),
          );
          // call set state to display update bank account info
          setState(() {});
        },
      ),
    ]);
  }
}
