import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseAuth.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';

class InsertEmailArguments {
  final UserCredential userCredential;
  InsertEmailArguments({
    @required this.userCredential,
  });
}

class InsertEmail extends StatefulWidget {
  static const routeName = "InsertEmail";
  final UserCredential userCredential;

  InsertEmail({
    @required this.userCredential,
  });

  @override
  InsertEmailState createState() => InsertEmailState();
}

class InsertEmailState extends State<InsertEmail> {
  Warning warningMessage;
  Color circularButtonColor;
  Function circularButtonCallback;
  Widget _circularButtonChild;
  TextEditingController emailTextEditingController;
  FirebaseAuth _firebaseAuth;

  @override
  void initState() {
    super.initState();
    emailTextEditingController = TextEditingController();
    circularButtonColor = AppColor.disabled;
    _circularButtonChild = Icon(
      Icons.arrow_forward,
      color: Colors.white,
      size: 36,
    );

    emailTextEditingController.addListener(
      () {
        String email = emailTextEditingController.text ?? "";
        if (email != null && email.isValid()) {
          setState(() {
            warningMessage = null;
            circularButtonCallback = buttonCallback;
            circularButtonColor = AppColor.primaryPink;
          });
        } else {
          setState(() {
            circularButtonCallback = null;
            circularButtonColor = AppColor.disabled;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    super.dispose();
  }

  // buttonCallback checks whether email is valid and not already used.
  // it displays warning in case the email is invalid and redirects user
  // to next registration screen in case the email is valid.
  void buttonCallback(BuildContext context) async {
    // display progress while verification happens
    setState(() {
      _circularButtonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    CreateEmailResponse response =
        await _firebaseAuth.createEmail(emailTextEditingController.text);

    // stop progress
    setState(() {
      _circularButtonChild = Icon(
        Icons.arrow_forward,
        color: Colors.white,
        size: 36,
      );
    });

    if (response.message != null) {
      setState(() {
        warningMessage = Warning(message: response.message);
        circularButtonCallback = null;
        circularButtonColor = AppColor.disabled;
      });
    }
    if (response.successful) {
      Navigator.pushNamed(
        context,
        InsertName.routeName,
        arguments: InsertNameArguments(
          userCredential: widget.userCredential,
          userEmail: emailTextEditingController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _firebaseAuth = Provider.of<FirebaseModel>(context, listen: false).auth;

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
                            onTapCallback: () => Navigator.pop(context)),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: screenHeight / 25),
                    Text(
                      "Insira o seu endereço de email",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    SizedBox(height: screenHeight / 40),
                    Warning(
                      color: AppColor.disabled,
                      message:
                          "Usaremos o email para enviar os recibos das suas corridas",
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputText(
                      maxLines: 1,
                      autoFocus: true,
                      hintText: "exemplo@dominio.com",
                      controller: emailTextEditingController,
                      inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    ),
                    SizedBox(height: screenHeight / 40),
                    warningMessage != null ? warningMessage : Container(),
                    SizedBox(height: screenHeight / 40),
                    Spacer(),
                    Row(
                      children: [
                        Spacer(),
                        CircularButton(
                          buttonColor: circularButtonColor,
                          child: _circularButtonChild,
                          onPressedCallback: circularButtonCallback == null
                              ? () {}
                              : () => buttonCallback(context),
                        ),
                      ],
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
