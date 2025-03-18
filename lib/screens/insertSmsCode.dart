import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';
import 'package:partner_app/services/firebase/database/methods.dart';

enum InsertSmsCodeMode {
  insertNewPhone,
  editPhone,
}

class InsertSmsCodeArguments {
  final String verificationId;
  final int resendToken;
  final String phoneNumber;
  final InsertSmsCodeMode mode;

  InsertSmsCodeArguments({
    required this.verificationId,
    required this.resendToken,
    required this.phoneNumber,
    required this.mode,
  });
}

class InsertSmsCode extends StatefulWidget {
  static const String routeName = "InsertSmsCode";

  final String verificationId;
  final String phoneNumber;
  final int resendToken;
  final InsertSmsCodeMode mode;

  InsertSmsCode({
    required this.verificationId,
    required this.resendToken,
    required this.phoneNumber,
    required this.mode,
  });

  @override
  InsertSmsCodeState createState() {
    return InsertSmsCodeState();
  }
}

class InsertSmsCodeState extends State<InsertSmsCode> {
  TextEditingController smsCodeTextEditingController = TextEditingController();
  Color circularButtonColor;
  Function circularButtonCallback;
  String smsCode;
  Widget _circularButtonChild;
  Widget _resendCodeWarning;
  Widget warningMessage;
  Timer timer;
  int remainingSeconds = 15;
  String _verificationId;
  int _resendToken;
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;
  Exception _exception;

  @override
  void initState() {
    super.initState();
    // _verificationId and _resendToken start with values pushed to widget
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    timer = kickOffTimer();
    // button starts off disabled
    circularButtonColor = AppColor.disabled;
    _circularButtonChild = Icon(
      Icons.autorenew_sharp,
      color: Colors.white,
      size: 36,
    );
    // decide to activate button based on entered smsCode
    smsCodeTextEditingController.addListener(() {
      if (smsCodeTextEditingController.text.length == 6) {
        activateButton();
      } else {
        disactivateButton();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    smsCodeTextEditingController.dispose();
    super.dispose();
  }

  // activateButton adds a callback and primary color to the button
  void activateButton() {
    setState(() {
      circularButtonCallback = verifySmsCode;
      circularButtonColor = AppColor.primaryPink;
      smsCode = smsCodeTextEditingController.text;
    });
  }

  // disactivateButton removes callback and primary color from the button
  void disactivateButton() {
    setState(() {
      circularButtonCallback = null;
      circularButtonColor = AppColor.disabled;
      smsCode = null;
    });
  }

  // kickOffTimer decrements remainingSeconds once per second until 0
  Timer kickOffTimer() {
    return Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) {
        if (remainingSeconds == 0) {
          t.cancel();
        } else {
          setState(() {
            remainingSeconds--;
          });
        }
      },
    );
  }

  // codeSentCallback is called when sms code is successfully sent.
  // it resets the state to value similar to initState.
  void codeSentCallback(String verificationId, int resendToken) {
    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      warningMessage = null;
      remainingSeconds = 15;
      timer = kickOffTimer();
    });
  }

  void resendCodeVerificationFailedCallback(FirebaseAuthException e) {
    String errorMsg = _firebaseAuth.verificationFailedCallback(e);
    setState(() {
      // reset timer and resendCodeWarning
      remainingSeconds = 15;
      timer = kickOffTimer();
      warningMessage = Warning(message: errorMsg);
    });
  }

  // verificationCompletedCallback behaves differently depending on mode
  Future<void> verificationCompletedCallback(
    BuildContext context,
    PhoneAuthCredential credential, {
    Function onExceptionCallback,
  }) async {
    UserModel firebase = Provider.of<UserModel>(context, listen: false);

    if (widget.mode == InsertSmsCodeMode.editPhone &&
        firebase.auth.currentUser != null) {
      try {
        await firebase.auth.currentUser.updatePhoneNumber(credential);
      } catch (e) {
        _exception = e;
        return;
      }
      // on success, update phone number on database too
      try {
        await firebase.database.setPhoneNumber(
          partnerID: firebase.auth.currentUser.uid,
          phoneNumber: firebase.auth.currentUser.phoneNumber,
        );
      } catch (_) {}
    } else {
      await _firebaseAuth.verificationCompletedCallback(
        context: context,
        credential: credential,
        firebaseDatabase: _firebaseDatabase,
        firebaseAuth: _firebaseAuth,
        onExceptionCallback: onExceptionCallback ??
            (FirebaseAuthException e) => displayErrorMessage(context, e),
      );
    }
  }

  // resendCode tries to resend the sms code to the same phoneNumber
  Future<void> resendCode(BuildContext context) async {
    // remove warning message
    setState(() {
      timer.cancel();
      warningMessage = null;
    });

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      // verificatoinCompleted fires only in Android phones that automatically
      // create a credential with the SMS code that arrives without the user
      // having to input it.
      verificationCompleted: (PhoneAuthCredential credential) {
        verificationCompletedCallback(
          context,
          credential,
          onExceptionCallback: (FirebaseAuthException e) {
            setState(() {
              // reset timer and resendCodeWarning
              remainingSeconds = 15;
              timer = kickOffTimer();
              warningMessage =
                  Warning(message: "Algo deu errado. Tente novamente");
            });
          },
        );
      },
      verificationFailed: resendCodeVerificationFailedCallback,
      codeSent: codeSentCallback,
      codeAutoRetrievalTimeout: (String verificationId) {},
      forceResendingToken: _resendToken,
    );
  }

  // displayErrorMessage displays warning message depending on received exception
  void displayErrorMessage(BuildContext context, FirebaseAuthException e) {
    if (e.code == "invalid-verification-code") {
      setState(() {
        warningMessage = Warning(message: "Código inválido. Tente outro.");
        circularButtonCallback = verifySmsCode;
        _circularButtonChild = Icon(
          Icons.autorenew_sharp,
          color: Colors.white,
          size: 36,
        );
      });
    } else {
      setState(() {
        warningMessage = Warning(message: "Algo deu errado. Tente mais tarde.");
        circularButtonCallback = verifySmsCode;
        _circularButtonChild = Icon(
          Icons.autorenew_sharp,
          color: Colors.white,
          size: 36,
        );
      });
    }
  }

  // verifySmsCode is called when user taps circular button.
  // it checks if the code entered by the user is valid.
  // During verification, a CircularProgressIndicator widget
  // is displayed. Upon success, user is redirected to another screen.
  Future<void> verifySmsCode(BuildContext context) async {
    // dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    // make sure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertOffline(
        context,
        message: "Conecte-se à internet para fazer login",
      );
      return;
    }

    setState(() {
      warningMessage = null;
      circularButtonCallback = null;
      _circularButtonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    // Create a PhoneAuthCredential with the entered verification code
    PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: smsCode);

    await verificationCompletedCallback(context, phoneCredential);

    setState(() {
      // stop circular Progress indicator
      _circularButtonChild = Icon(
        Icons.autorenew_sharp,
        color: Colors.white,
        size: 36,
      );
    });

    if (widget.mode == InsertSmsCodeMode.editPhone) {
      // pop and return exception to be handled by InsertNewPhone screen
      Navigator.pop(context, _exception);
    }
  }

  Widget displayWarnings(BuildContext context, double padding) {
    Warning editPhoneWarning = Warning(
      message: "Editar o número do meu celular",
      onTapCallback: Navigator.pop,
    );
    if (warningMessage != null && _resendCodeWarning != null) {
      return Expanded(
          flex: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              warningMessage,
              SizedBox(height: padding),
              _resendCodeWarning,
              SizedBox(height: padding),
              editPhoneWarning,
            ],
          ));
    }
    if (warningMessage == null && _resendCodeWarning == null) {
      return Expanded(
        flex: 18,
        child: editPhoneWarning,
      );
    }
    if (warningMessage != null) {
      return Expanded(
        flex: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            warningMessage,
            SizedBox(height: padding),
            editPhoneWarning,
          ],
        ),
      );
    }
    return Expanded(
      flex: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resendCodeWarning,
          SizedBox(height: padding),
          editPhoneWarning,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _firebaseAuth = Provider.of<UserModel>(context).auth;
    _firebaseDatabase = Provider.of<UserModel>(context).database;

    if (remainingSeconds <= 0) {
      // if remainingSeconds reaches 0, allow user to resend sms code.
      _resendCodeWarning = Warning(
        onTapCallback: resendCode,
        message: "Reenviar o código para meu celular",
      );
    } else {
      // otherwise, display countdown message
      _resendCodeWarning = Warning(
          color: AppColor.disabled,
          message: "Reenviar o código em " + remainingSeconds.toString());
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (
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
                              onTapCallback: () => Navigator.pop(context)),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: screenHeight / 25),
                      RichText(
                        text: TextSpan(
                          text: 'Insira o código de 6 digitos enviado para ',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(
                                text: widget.phoneNumber,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight / 40),
                      AppInputText(
                        autoFocus: true,
                        iconData: Icons.lock,
                        controller: smsCodeTextEditingController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: screenHeight / 40),
                      displayWarnings(context, screenHeight / 40),
                      Row(
                        children: [
                          Spacer(),
                          CircularButton(
                            buttonColor: circularButtonColor,
                            child: _circularButtonChild,
                            onPressedCallback: circularButtonCallback == null
                                ? () {}
                                : () => circularButtonCallback(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
