import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseAuth.dart';
import 'package:partner_app/widgets/appInputPassword.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/passwordWarning.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';

import '../models/user.dart';
import '../widgets/appButton.dart';

// TODO: add lockScreen (and wherever else there is a CircularProgressIndicator)
class InsertNewPassword extends StatefulWidget {
  static const String routeName = "InsertNewPassword";

  @override
  InsertNewPasswordState createState() => InsertNewPasswordState();
}

class InsertNewPasswordState extends State<InsertNewPassword> {
  Color appButtonColor;
  Function appButtonCallback;
  TextEditingController newPasswordTextEditingController;
  TextEditingController oldPasswordTextEditingController;
  FocusNode oldPasswordFocusNode;
  FocusNode newPasswordFocusNode;
  List<bool> passwordChecks = [false, false, false];
  bool displayPasswordChecks;
  Widget registrationWarnings;
  bool lockScreen;
  Widget buttonChild;
  var validateOldPasswordCriteria;
  var validateNewPasswordCriteria;
  var listener;

  @override
  void initState() {
    super.initState();
    newPasswordTextEditingController = TextEditingController();
    oldPasswordTextEditingController = TextEditingController();
    oldPasswordFocusNode = FocusNode();
    newPasswordFocusNode = FocusNode();
    appButtonColor = AppColor.disabled;
    lockScreen = false;
    displayPasswordChecks = true;
    validateOldPasswordCriteria = () {
      String password = oldPasswordTextEditingController.text ?? "";
      // user must type some old password
      if (password.length < 8) {
        return false;
      }
      return true;
    };
    validateNewPasswordCriteria = () {
      // check password requirements as user types
      String password = newPasswordTextEditingController.text ?? "";

      if (password.length > 0) {
        // show password warnings and hide registration error warnigns
        displayPasswordChecks = true;
        registrationWarnings = null;
      }
      if (password.length >= 8) {
        setState(() {
          passwordChecks[0] = true;
        });
      } else {
        setState(() {
          passwordChecks[0] = false;
        });
      }
      if (password.containsLetter()) {
        setState(() {
          passwordChecks[1] = true;
        });
      } else {
        setState(() {
          passwordChecks[1] = false;
        });
      }
      if (password.containsDigit()) {
        setState(() {
          passwordChecks[2] = true;
        });
      } else {
        setState(() {
          passwordChecks[2] = false;
        });
      }
      // all checks must pass and user must have typed old password
      String oldPassword = oldPasswordTextEditingController.text ?? "";
      if (passwordChecks[0] &&
          passwordChecks[1] &&
          passwordChecks[2] &&
          oldPassword.length > 0) {
        return true;
      } else {
        return false;
      }
    };

    listener = () {
      bool validOldPassword = validateOldPasswordCriteria();
      bool validNewPassword = validateNewPasswordCriteria();
      if (validOldPassword && validNewPassword) {
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

    oldPasswordTextEditingController.addListener(listener);
    newPasswordTextEditingController.addListener(listener);
  }

  @override
  void dispose() {
    newPasswordTextEditingController.dispose();
    oldPasswordTextEditingController.dispose();
    newPasswordFocusNode.dispose();
    oldPasswordFocusNode.dispose();
    super.dispose();
  }

  // buttonCallback tries signing user up by adding remainig data to its credential
  Future<void> buttonCallback(BuildContext context, String newPassword) async {
    // ensure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(
        context,
        message: "Conecte-se à internet para alterar a senha.",
      );
      return;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final UserModel firebase = Provider.of<UserModel>(
      context,
      listen: false,
    );

    setState(() {
      // lock screen so user can't interact with buttons
      lockScreen = true;
    });

    // check if old password and new password are the same
    String oldPassword = oldPasswordTextEditingController.text;
    if (oldPassword == newPassword) {
      setState(() {
        // unlock screen
        lockScreen = false;
        displayPasswordChecks = false;
        registrationWarnings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 40),
            Warning(message: "A nova senha deve ser diferente da senha atual."),
            SizedBox(height: screenHeight / 80),
          ],
        );
      });
      return;
    }

    setState(() {
      // show loading button and
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      // remove focus
      newPasswordFocusNode.unfocus();
      oldPasswordFocusNode.unfocus();
    });

    UpdatePasswordResponse response =
        await firebase.auth.reauthenticateAndUpdatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    setState(() {
      String message = response.successful
          ? "Senha atualizada com sucesso!"
          : response.message;
      if (message != null) {
        registrationWarnings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 40),
            Warning(
              message: message,
              color: response.successful
                  ? AppColor.secondaryGreen
                  : AppColor.secondaryYellow,
            ),
            SizedBox(height: screenHeight / 80),
          ],
        );
      }
      // remove password warning messages
      displayPasswordChecks = false;
      // remove text field values
      newPasswordTextEditingController.text = "";
      oldPasswordTextEditingController.text = "";
      // remove circular buton progress
      buttonChild = null;
      // unlock screen
      lockScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
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
                              onTapCallback: lockScreen
                                  ? () {}
                                  : () => Navigator.pop(context)),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: screenHeight / 30),
                      Text(
                        "Alterar senha",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenHeight / 40),
                      AppInputPassword(
                        controller: oldPasswordTextEditingController,
                        hintText: "senha atual",
                        focusNode: oldPasswordFocusNode,
                        enabled: !lockScreen,
                        onSubmittedCallback: (String _) {
                          oldPasswordFocusNode.unfocus();
                          FocusScope.of(context)
                              .requestFocus(newPasswordFocusNode);
                        },
                      ),
                      SizedBox(height: screenHeight / 80),
                      AppInputPassword(
                        enabled: !lockScreen,
                        controller: newPasswordTextEditingController,
                        hintText: "nova senha",
                        focusNode: newPasswordFocusNode,
                      ),
                      displayPasswordChecks
                          ? Column(
                              children: [
                                SizedBox(height: screenHeight / 80),
                                PasswordWarning(
                                  isValid: passwordChecks[0],
                                  message: "Precisa ter no mínimo 8 caracteres",
                                ),
                                SizedBox(height: screenHeight / 200),
                                PasswordWarning(
                                  isValid: passwordChecks[1],
                                  message: "Precisa ter pelo menos uma letra",
                                ),
                                SizedBox(height: screenHeight / 200),
                                PasswordWarning(
                                  isValid: passwordChecks[2],
                                  message: "Precisa ter pelo menos um dígito",
                                ),
                                SizedBox(height: screenHeight / 200),
                              ],
                            )
                          : Container(),
                      registrationWarnings != null
                          ? registrationWarnings
                          : Container(),
                      SizedBox(height: screenHeight / 100),
                      Spacer(),
                      AppButton(
                        textData: "Atualizar Senha",
                        child: buttonChild,
                        buttonColor: appButtonColor,
                        onTapCallBack: appButtonCallback == null || lockScreen
                            ? () {}
                            : () => appButtonCallback(
                                  context,
                                  newPasswordTextEditingController.text,
                                ),
                      )
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
