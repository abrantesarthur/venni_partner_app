import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputPassword.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';

import '../models/user.dart';
import '../widgets/warning.dart';

class InsertNewEmail extends StatefulWidget {
  static const String routeName = "InsertNewEmail";
  final firebase = FirebaseService();

  @override
  InsertNewEmailState createState() => InsertNewEmailState();
}

class InsertNewEmailState extends State<InsertNewEmail> {
  Function? appButtonCallback;
  late Color appButtonColor;
  Widget? appButtonChild;
  late TextEditingController emailTextEditingController;
  late TextEditingController passwordTextEditingController;
  Warning? warningMessage;
  late FocusNode emailFocusNode;
  late FocusNode passwordFocusNode;
  late bool lockScreen;
  var listener;

  @override
  void initState() {
    super.initState();

    emailTextEditingController = TextEditingController();
    passwordTextEditingController = TextEditingController();
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    appButtonColor = AppColor.disabled;
    lockScreen = false;

    listener = () {
      String email = emailTextEditingController.text ?? "";
      String password = passwordTextEditingController.text ?? "";

      if (email.isValid() && password.length >= 8) {
        setState(() {
          appButtonCallback = buttonCallback;
          appButtonColor = AppColor.primaryPink;
        });
      } else {
        setState(() {
          appButtonCallback = null;
          appButtonColor = AppColor.disabled;
        });
      }
    };

    emailTextEditingController.addListener(listener);
    passwordTextEditingController.addListener(listener);
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> buttonCallback(BuildContext context) async {
    // ensure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertOffline(
        context,
        message: "Conecte-se à internet para redefinir o email.",
      );
      return;
    }

    // remove email and password focus and lock screen
    setState(() {
      emailFocusNode.unfocus();
      passwordFocusNode.unfocus();
      lockScreen = true;
    });

    if (emailTextEditingController.text == widget.firebase.model.user.email) {
      setState(() {
        warningMessage = Warning(
          message: "O email inserido é idêntico ao email atual. Tente outro.",
        );
        appButtonColor = AppColor.disabled;
        appButtonCallback = null;
        lockScreen = false;
      });
      return;
    }

    // display progress while verification happens
    setState(() {
      appButtonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    UpdateEmailResponse response =
        await widget.firebase.auth.reauthenticateAndUpdateEmail(
      email: emailTextEditingController.text,
      password: passwordTextEditingController.text,
    );

    setState(() {
      appButtonChild = null;
    });

    if (!response.successful) {
      setState(() {
        warningMessage = response.message != null ? Warning(
          message: response.message!,
        ) : null;
        appButtonColor = AppColor.disabled;
        appButtonCallback = null;
        lockScreen = false;
      });
    } else {
      Navigator.pop(context, response);
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
                                : () => Navigator.pop(context)),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: screenHeight / 30),
                    Text(
                      "Insira o seu novo email e atual senha",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputText(
                      autoFocus: true,
                      enabled: !lockScreen,
                      focusNode: emailFocusNode,
                      maxLines: 1,
                      hintText: "exemplo@dominio.com",
                      controller: emailTextEditingController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                      ],
                      onSubmittedCallback: (String _) {
                        emailFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(passwordFocusNode);
                      },
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputPassword(
                      enabled: !lockScreen,
                      controller: passwordTextEditingController,
                      focusNode: passwordFocusNode,
                    ),
                    SizedBox(height: screenHeight / 40),
                    warningMessage == null
                        ? Spacer()
                        : Expanded(child: warningMessage!),
                    AppButton(
                      textData: "Redefinir",
                      buttonColor: appButtonColor,
                      child: appButtonChild,
                      onTapCallBack: appButtonCallback == null || lockScreen
                          ? () {}
                          : () => appButtonCallback!(context),
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
