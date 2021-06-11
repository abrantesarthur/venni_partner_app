import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class SendBankInfo extends StatefulWidget {
  static const String routeName = "sendBankInfo";

  @override
  SendBankInfoState createState() => SendBankInfoState();
}

// TOOD: display warnings if something goes wrong
class SendBankInfoState extends State<SendBankInfo> with RouteAware {
  TextEditingController agencyController = TextEditingController();
  TextEditingController agencyDvController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController accountDvController = TextEditingController();
  bool agencyIsValid = false;
  bool accountIsValid = false;
  bool accountDvIsValid = false;
  bool lockScreen = false;
  Banks selectedBank;
  BankAccountType selectedAccountType;

  @override
  void initState() {
    agencyController.addListener(() {
      setState(() {
        agencyIsValid = agencyController.text.length > 0;
      });
    });
    accountController.addListener(() {
      setState(() {
        accountIsValid = accountController.text.length > 0;
      });
    });
    accountDvController.addListener(() {
      setState(() {
        accountDvIsValid = accountDvController.text.length > 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    agencyController.dispose();
    agencyDvController.dispose();
    accountController.dispose();
    accountDvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final connectivity = Provider.of<ConnectivityModel>(context);
    final firebase = Provider.of<FirebaseModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: OverallPadding(
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () {
                  Navigator.pop(context);
                }),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Adicionar conta bancária",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Usaremos a conta cadastrada para depositar os pagamentos referentes às corridas pagas com cartão de crédito pelos clientes",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            SizedBox(height: screenHeight / 50),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Importante",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "Usaremos o Nome e CPF usados na criação da sua conta na Venni para adicionar uma conta bancária. Portanto, informe dados bancários referentes à sua conta pessoal no banco. Caso o Nome e CPF da conta bancária sejam diferentes dos informados para a Venni, o procedimento irá falhar",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Container(
                          width: screenWidth,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 0.5,
                                color: Colors.black,
                              )),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton(
                                  value: selectedBank,
                                  hint: Text(
                                    "Banco",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColor.disabled,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    FocusScope.of(context)
                                        .requestFocus(new FocusNode());
                                    setState(() {
                                      selectedBank = value;
                                    });
                                  },
                                  items: bankMap.keys
                                      .map((bankName) => DropdownMenuItem(
                                            child: Text(bankMap[bankName]),
                                            value: bankName,
                                          ))
                                      .toList()),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Row(
                          children: [
                            AppInputText(
                              hintText: "Agência",
                              width: screenWidth / 2,
                              maxLines: 1,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  TextInputType.numberWithOptions(signed: true),
                              controller: agencyController,
                              enabled: !lockScreen,
                            ),
                            Spacer(),
                            AppInputText(
                              hintText: "Dígito",
                              width: screenWidth / 3,
                              maxLines: 1,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  TextInputType.numberWithOptions(signed: true),
                              controller: agencyDvController,
                              enabled: !lockScreen,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight / 50),
                        Row(
                          children: [
                            AppInputText(
                              hintText: "Conta",
                              width: screenWidth / 2,
                              maxLines: 1,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(13),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  TextInputType.numberWithOptions(signed: true),
                              controller: accountController,
                              enabled: !lockScreen,
                            ),
                            Spacer(),
                            AppInputText(
                              hintText: "Dígito",
                              width: screenWidth / 3,
                              maxLines: 1,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  TextInputType.numberWithOptions(signed: true),
                              controller: accountDvController,
                              enabled: !lockScreen,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight / 50),
                        Container(
                          width: screenWidth,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 0.5,
                                color: Colors.black,
                              )),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton(
                                  value: selectedAccountType,
                                  hint: Text(
                                    "Tipo de Conta",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColor.disabled,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    FocusScope.of(context)
                                        .requestFocus(new FocusNode());

                                    setState(() {
                                      selectedAccountType = value;
                                    });
                                  },
                                  items: accountTypeMap.keys
                                      .map((key) => DropdownMenuItem(
                                            child: Text(accountTypeMap[key]),
                                            value: key,
                                          ))
                                      .toList()),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight / 5),
                      ],
                    ),
                  ),
                  // only show button when keyboard is hidden
                  MediaQuery.of(context).viewInsets.bottom == 0
                      ? Positioned(
                          bottom: screenHeight / 15,
                          left: 0,
                          right: 0,
                          child: AppButton(
                            textData: "Adicionar Conta",
                            buttonColor: allFieldsAreValid()
                                ? AppColor.primaryPink
                                : AppColor.disabled,
                            onTapCallBack: !lockScreen && allFieldsAreValid()
                                ? () async {
                                    if (!connectivity.hasConnection) {
                                      await connectivity.alertWhenOffline(
                                        context,
                                        message:
                                            "Conecte-se à internet para adicionar as informações bancárias.",
                                      );
                                      return;
                                    }

                                    String bankCode = selectedBank.getCode();

                                    print(bankCode);
                                    print(agencyController.text);
                                    print(agencyDvController.text);
                                    print(accountController.text);
                                    print(accountDvController.text);
                                    print(selectedAccountType.getString());
                                  }
                                : () {},
                          ),
                        )
                      : Container()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  bool allFieldsAreValid() {
    return agencyIsValid &&
        accountIsValid &&
        accountDvIsValid &&
        selectedBank != null &&
        selectedAccountType != null;
  }
}
