import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/services/firebase/database/methods.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/inputPhone.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';

import '../widgets/warning.dart';

class InsertNewPhone extends StatefulWidget {
  static const String routeName = "InsertNewPhone";
  final firebase = FirebaseService();

  @override
  InsertNewPhoneState createState() => InsertNewPhoneState();
}

class InsertNewPhoneState extends State<InsertNewPhone> {
  Function? appButtonCallback;
  late Color buttonColor;
  Widget? buttonChild;
  late TextEditingController phoneController;
  late FocusNode phoneFocusNode;
  bool lockScreen = false;
  String? phoneNumber;
  Warning? warningMessage;
  int? resendToken;

  @override
  void initState() {
    super.initState();

    phoneController = TextEditingController();
    phoneFocusNode = FocusNode();
    lockScreen = false;
    setInactiveState();

    phoneController.addListener(
      () {
        if (phoneController.text.isValidPhoneNumber()) {
          setActiveState(
            message:
                "O seu navegador pode se abrir para efetuar verificações :)",
            phone: "+55 " + phoneController.text,
          );
        } else {
          setInactiveState();
        }
      },
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  void setInactiveState({String? message}) {
    setState(() {
      buttonColor = AppColor.disabled;
      appButtonCallback = null;
      lockScreen = false;
      buttonChild = null;
      warningMessage =
          message != null ? Warning(message: message) : warningMessage;
    });
  }

  void setActiveState({String? message, required String phone}) {
    setState(() {
      buttonColor = AppColor.primaryPink;
      appButtonCallback = buttonCallback;
      warningMessage = message != null ? Warning(message: message) : null;
      phoneNumber = phone;
    });
  }

  void setSuccessState({required String newPhoneNumber}) {
    setState(
      () {
        lockScreen = false;
        buttonChild = null;
        phoneController.text = "";
        warningMessage = Warning(
          message: "Número alterado com sucesso para " + newPhoneNumber,
          color: AppColor.secondaryGreen,
        );
      },
    );
  }

  Future<void> codeSentCallback(
    BuildContext context,
    String verificationId,
    int token,
  ) async {

    setState(() {
      resendToken = token;
    });
    // update the UI for the user to enter the SMS code
    await Navigator.pushNamed(
      context,
      InsertSmsCode.routeName,
      arguments: InsertSmsCodeArguments(
        phoneNumber: phoneNumber!,
        verificationId: verificationId,
        resendToken: token,
        mode: InsertSmsCodeMode.editPhone,
      ),
    ) as FirebaseAuthException;

    // only display success message if phone was altered
    if (widget.firebase.auth.currentUser?.phoneNumber ==
        phoneNumber?.withCountryCode()) {
      setSuccessState(
        newPhoneNumber:
            widget.firebase.auth.currentUser?.phoneNumber?.withoutCountryCode() ?? "",
      );
    } else {
      setInactiveState();
    }
  }

  void verificationCompletedCallback({
    required BuildContext context,
    required PhoneAuthCredential credential,
  }) async {
    try {
      await widget.firebase.auth.currentUser?.updatePhoneNumber(credential);
    } catch (e) {
      handleException(e as FirebaseAuthException);
      return;
    }

    // on success
    if (widget.firebase.auth.currentUser?.phoneNumber ==
        phoneNumber?.withCountryCode()) {
      //update phone number on database too
      try {
        final user = widget.firebase.auth.currentUser;
        if(user != null) {
          await widget.firebase.database.setPhoneNumber(
            partnerID: user.uid,
            phoneNumber: user.phoneNumber ?? "",
          );
        }
      } catch (_) {}

      //  display success message
      setSuccessState(
        newPhoneNumber:
            widget.firebase.auth.currentUser?.phoneNumber?.withoutCountryCode() ?? "",
      );
    }
  }

  // handleException displays warning message depending on received exception
  void handleException(FirebaseAuthException e) {
    // displayErrorMessage displays warning message depending on received exception
    if (e.code == "invalid-verification-code") {
      setInactiveState(message: "Código inválido. Tente novamente.");
    } else if (e.code == "credential-already-in-use") {
      setInactiveState(message: "O número já está sendo usado. Tente outro.");
    } else {
      setInactiveState(message: "Algo deu errado. Tente novamente mais tarde.");
    }
  }

  // appButtonCallback sends request to firebase to verify phone number
  Future<void> buttonCallback(
    BuildContext context,
    FirebaseAuth firebaseAuth,
    FirebaseDatabase firebaseDatabase,
  ) async {
    // ensure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertOffline(
        context,
        message: "Conecte-se à internet para alterar o número de telefone.",
      );
      return;
    }
    if (phoneNumber != null) {
      if (phoneNumber!.withCountryCode() ==
          firebaseAuth.currentUser?.phoneNumber) {
        // only alter phone number if new number is different
        setInactiveState(
            message: "O número inserido é igual ao número atual. Tente outro.");
        return;
      }

      // prevent users from editing phone number and show loading icon
      setState(() {
        lockScreen = true;
        phoneFocusNode.unfocus();
        buttonChild = CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
      });

      await firebaseAuth.verifyPhoneNumber(
        timeout: Duration(seconds: 60),
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          verificationCompletedCallback(
            context: context,
            credential: credential,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMsg = firebaseAuth.verificationFailedCallback(e);
          setInactiveState(message: errorMsg);
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          codeSentCallback(context, verificationId, forceResendingToken ?? 0);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        forceResendingToken: resendToken,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: LayoutBuilder(builder: (
        BuildContext context,
        BoxConstraints viewportConstraints,
      ) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: OverallPadding(
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ArrowBackButton(
                          onTapCallback: lockScreen
                              ? () {}
                              : () {
                                  Navigator.pop(context);
                                },
                        ),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: screenHeight / 30),
                    Text(
                      "Insira o seu novo número",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight / 30),
                    InputPhone(
                      enabled: !lockScreen,
                      maxLines: 1,
                      controller: phoneController,
                      focusNode: phoneFocusNode,
                    ),
                    SizedBox(height: screenHeight / 30),
                    warningMessage == null
                        ? Spacer()
                        : Expanded(child: warningMessage!),
                    AppButton(
                      textData: "Redefinir",
                      buttonColor: buttonColor,
                      child: buttonChild,
                      onTapCallBack: appButtonCallback == null
                          ? () {}
                          : () => appButtonCallback!(
                                context,
                                widget.firebase.auth,
                                widget.firebase.database,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
