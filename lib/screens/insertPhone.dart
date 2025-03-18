import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/inputPhone.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';

// TODO: allow user to sign in with email, specially if limit of phone verifications was reached

class InsertPhone extends StatefulWidget {
  static const String routeName = "insertPhone";

  @override
  InsertPhoneNumberState createState() => InsertPhoneNumberState();
}

class InsertPhoneNumberState extends State<InsertPhone> {
  Color _circularButtonColor;
  Function circularButtonCallback;
  Widget _warningMessage;
  String phoneNumber;
  int _resendToken;
  bool enabled;
  TextEditingController phoneTextEditingController;
  Widget _circularButtonChild;
  var _controllerListener;

  @override
  void initState() {
    super.initState();
    enabled = true;
    phoneTextEditingController = TextEditingController();
    _circularButtonColor = AppColor.disabled;
    _circularButtonChild = Icon(
      Icons.arrow_forward,
      color: Colors.white,
      size: 36,
    );
    circularButtonCallback = null;

    // as user inputs phone, check for its validity and update UI accordingly
    _controllerListener = () {
      if (phoneTextEditingController.text.isValidPhoneNumber()) {
        setActiveState(
          message: "O seu navegador pode se abrir para efetuar verificações :)",
          phone: "+55 " + phoneTextEditingController.text,
        );
      } else {
        setInactiveState();
      }
    };
    phoneTextEditingController.addListener(_controllerListener);
  }

  @override
  void dispose() {
    phoneTextEditingController.removeListener(_controllerListener);
    phoneTextEditingController.dispose();
    super.dispose();
  }

  void setInactiveState({String message}) {
    setState(() {
      _circularButtonColor = AppColor.disabled;
      circularButtonCallback = null;
      _circularButtonChild = Icon(
        Icons.arrow_forward,
        color: Colors.white,
        size: 36,
      );
      enabled = true;
      _warningMessage = message != null ? Warning(message: message) : null;
      phoneNumber = null;
    });
  }

  void setActiveState({String message, required String phone}) {
    setState(() {
      _circularButtonColor = AppColor.primaryPink;
      circularButtonCallback = buttonCallback;
      _warningMessage = message != null ? Warning(message: message) : null;
      phoneNumber = phone;
    });
  }

  void codeSentCallback(
    BuildContext context,
    String verificationId,
    int resendToken,
  ) async {
    setState(() {
      _resendToken = resendToken;
    });
    // update the UI for the user to enter the SMS code
    await Navigator.pushNamed(
      context,
      InsertSmsCode.routeName,
      arguments: InsertSmsCodeArguments(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
        resendToken: resendToken,
        mode: InsertSmsCodeMode.insertNewPhone,
      ),
    );

    setState(() {
      enabled = true;
      _circularButtonChild = Icon(
        Icons.arrow_forward,
        color: Colors.white,
        size: 36,
      );
    });
  }

  // circularButtonCallback sends request to firebase to verify phone number
  Future<void> buttonCallback(
    BuildContext context,
    FirebaseAuth firebaseAuth,
    FirebaseDatabase firebaseDatabase,
  ) async {
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

    if (phoneNumber != null) {
      // prevent users from editing phone number and show loading icon
      setState(() {
        enabled = false;
        _circularButtonChild = CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
      });

      await firebaseAuth.verifyPhoneNumber(
          timeout: Duration(seconds: 60),
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) {
            firebaseAuth.verificationCompletedCallback(
                context: context,
                credential: credential,
                firebaseDatabase: firebaseDatabase,
                firebaseAuth: firebaseAuth,
                onExceptionCallback: (FirebaseAuthException e) {
                  setInactiveState(
                    message: "Algo deu errado. Tente novamente.",
                  );
                });
          },
          verificationFailed: (FirebaseAuthException e) {
            String errorMsg = firebaseAuth.verificationFailedCallback(e);
            setInactiveState(message: errorMsg);
          },
          codeSent: (String verificationId, int resendToken) {
            codeSentCallback(context, verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          forceResendingToken: _resendToken);
    }
  }

  // TODO: inform users that sms rates may apply (https://firebase.google.com/docs/auth/android/phone-auth)

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final firebaseModel = Provider.of<UserModel>(context);

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
                      Text(
                        "Insira seu nº de celular",
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                      SizedBox(height: screenHeight / 40),
                      InputPhone(
                        maxLines: 1,
                        enabled: enabled,
                        controller: phoneTextEditingController,
                      ),
                      SizedBox(height: screenHeight / 40),
                      _warningMessage == null
                          ? Spacer(flex: 18)
                          : Expanded(flex: 18, child: _warningMessage),
                      Row(
                        children: [
                          Spacer(),
                          CircularButton(
                            buttonColor: _circularButtonColor,
                            child: _circularButtonChild,
                            onPressedCallback: circularButtonCallback == null
                                ? () {}
                                : () => circularButtonCallback(
                                      context,
                                      firebaseModel.auth,
                                      firebaseModel.database,
                                    ),
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
