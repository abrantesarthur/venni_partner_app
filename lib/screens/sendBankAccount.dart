import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:partner_app/vendors/firebaseFunctions/methods.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

enum SendBankAccountMode { send, edit }

class SendBankAccountArguments {
  final SendBankAccountMode mode;

  SendBankAccountArguments({required this.mode});
}

class SendBankAccount extends StatefulWidget {
  static const String routeName = "SendBankAccount";
  final SendBankAccountMode mode;

  SendBankAccount({required this.mode});

  @override
  SendBankAccountState createState() => SendBankAccountState();
}

// TOOD: display warnings if something goes wrong
class SendBankAccountState extends State<SendBankAccount> with RouteAware {
  TextEditingController agenciaController;
  TextEditingController agenciaDvController;
  TextEditingController contaController;
  TextEditingController contaDvController;
  bool agenciaIsValid = false;
  bool contaIsValid = false;
  bool contaDvIsValid = false;
  bool lockScreen = false;
  Banks selectedBank;
  BankAccountType selectedAccountType;
  Widget buttonChild;

  @override
  void initState() {
    agenciaController = TextEditingController();
    agenciaDvController = TextEditingController();
    contaController = TextEditingController();
    contaDvController = TextEditingController();
    agenciaController.addListener(() {
      setState(() {
        agenciaIsValid = agenciaController.text.length > 0;
      });
    });
    contaController.addListener(() {
      setState(() {
        contaIsValid = contaController.text.length > 0;
      });
    });
    contaDvController.addListener(() {
      setState(() {
        contaDvIsValid = contaDvController.text.length > 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    agenciaController.dispose();
    agenciaDvController.dispose();
    contaController.dispose();
    contaDvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
              widget.mode == SendBankAccountMode.send
                  ? "Adicionar conta bancária"
                  : "Alterar conta bancária",
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
                                  items: bankTypeToNameMap.keys
                                      .map((bankName) => DropdownMenuItem(
                                            child: Text(
                                                bankTypeToNameMap[bankName]),
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
                              controller: agenciaController,
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
                              controller: agenciaDvController,
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
                              controller: contaController,
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
                              controller: contaDvController,
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
                            textData: widget.mode == SendBankAccountMode.send
                                ? "Adicionar Conta"
                                : "Alterar Conta",
                            child: buttonChild,
                            buttonColor: allFieldsAreValid()
                                ? AppColor.primaryPink
                                : AppColor.disabled,
                            onTapCallBack: !lockScreen && allFieldsAreValid()
                                ? () async => await buttonCallback(context)
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

  Future<void> buttonCallback(BuildContext context) async {
    final connectivity = Provider.of<ConnectivityModel>(context, listen: false);
    final partner = Provider.of<PartnerModel>(context, listen: false);
    final firebase = Provider.of<UserModel>(context, listen: false);

    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(
        context,
        message:
            "Conecte-se à internet para adicionar as informações bancárias.",
      );
      return;
    }

    // show progress indicator and lock screen
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white,
        ),
      );
      lockScreen = true;
    });

    try {
      // add bank account to firebase
      BankAccount ba = await firebase.functions.createBankAccount(
        BankAccount(
          bankCode: selectedBank.getCode(),
          agencia: agenciaController.text,
          agenciaDv: agenciaDvController.text,
          conta: contaController.text,
          contaDv: contaDvController.text,
          type: selectedAccountType,
          documentNumber: partner.cpf,
          legalName: partner.name + " " + partner.lastName,
        ),
      );

      // if sending, mark bank account as submitted on firebase and locally
      if (widget.mode == SendBankAccountMode.send) {
        await firebase.database.setSubmittedBankAccount(
          partnerID: firebase.auth.currentUser.uid,
          value: true,
        );
        partner.updateBankAccountSubmitted(true);
      }

      // if editing, update partner model
      if (widget.mode == SendBankAccountMode.edit) {
        partner.updateBankAccount(ba);
      }

      // go back to previous screen screen
      Navigator.pop(context);
    } catch (e) {
      print(e);
      // unlock screen and display warning on error
      setState(() {
        buttonChild = null;
        lockScreen = false;
      });
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Algo deu errado."),
            content: Text(
              "Tente novamente.",
              style: TextStyle(
                color: AppColor.disabled,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "ok",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  }

  bool allFieldsAreValid() {
    return agenciaIsValid &&
        contaIsValid &&
        contaDvIsValid &&
        selectedBank != null &&
        selectedAccountType != null;
  }
}
