import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/screens/documents.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/services/firebase/database/methods.dart';
import 'package:partner_app/widgets/appInputPassword.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/passwordWarning.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InsertPasswordArguments {
  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  final String cpf;
  final Gender gender;
  InsertPasswordArguments({
    required this.userCredential,
    required this.name,
    required this.surname,
    required this.userEmail,
    required this.cpf,
    required this.gender,
  });
}

class InsertPassword extends StatefulWidget {
  static const String routeName = "insertPassword";
  final firebase = FirebaseService();

  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  final String cpf;
  final Gender gender;
  InsertPassword({
    required this.userCredential,
    required this.userEmail,
    required this.name,
    required this.surname,
    required this.cpf,
    required this.gender,
  });

  @override
  InsertPasswordState createState() => InsertPasswordState();
}

class InsertPasswordState extends State<InsertPassword> {
  Future<bool>? successfullyRegisteredUser;
  late double screenHeight;
  late Color circularButtonColor;
  Function? circularButtonCallback;
  late bool obscurePassword;
  TextEditingController passwordTextEditingController = TextEditingController();
  List<bool> passwordChecks = [false, false, false];
  late bool displayPasswordWarnings;
  Widget? registrationErrorWarnings;
  late bool passwordTextFieldEnabled;
  late bool preventNavigateBack;

  @override
  void initState() {
    super.initState();
    circularButtonColor = AppColor.disabled;
    passwordTextFieldEnabled = true;
    preventNavigateBack = false;
    obscurePassword = true;
    displayPasswordWarnings = true;
    passwordTextEditingController.addListener(() {
      // check password requirements as user types
      String password = passwordTextEditingController.text;

      if (password.length > 0) {
        // show password warnings and hide registration error warnigns
        displayPasswordWarnings = true;
        registrationErrorWarnings = null;
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
      if (passwordChecks[0] && passwordChecks[1] && passwordChecks[2]) {
        setState(() {
          circularButtonCallback = buttonCallback;
          circularButtonColor = AppColor.primaryPink;
        });
      } else {
        setState(() {
          circularButtonCallback = null;
          circularButtonColor = AppColor.disabled;
        });
      }
    });
  }

  @override
  void dispose() {
    passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> handleRegistrationFailure(
    FirebaseAuthException e,
  ) async {
    // desactivate CircularButton callback
    setState(() {
      circularButtonCallback = null;
      circularButtonColor = AppColor.disabled;
    });

    if (e.code == "weak-password") {
      // this should never happen
      setState(() {
        // remove password warning messages
        displayPasswordWarnings = false;

        // display warning for user to try again
        registrationErrorWarnings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 40),
            Warning(
              message: "Senha muito fraca. Tente outra.",
            ),
            SizedBox(height: screenHeight / 80),
          ],
        );
      });
    } else {
      // delete partner entry in database
      final user = widget.userCredential.user;
      if(user != null) {
        await widget.firebase.database.deletePartner(user.uid);

        // if user did not already have a client account
        if (!widget.firebase.model.user.isUserSignedIn) {
          // rollback and delete user
          await user.delete();
        }
      }

      String firstWarningMessage;
      if (e.code == "requires-recent-login") {
        firstWarningMessage =
            "Infelizmente a sua sessão expirou devido à demora.";
      } else {
        print(e.code);
        print(e);
        firstWarningMessage = "Algo deu errado.";
      }

      setState(() {
        // remove password warnings
        displayPasswordWarnings = false;

        // remove typed password from text field
        passwordTextEditingController.text = "";

        // prevent users from typing a new password
        passwordTextFieldEnabled = false;

        // prevent users from navigating back
        preventNavigateBack = true;

        // display warnings for user to login again
        registrationErrorWarnings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 40),
            Warning(
              color: Colors.black,
              message: firstWarningMessage,
            ),
            SizedBox(height: screenHeight / 80),
            Warning(
              onTapCallback: (TapUpDetails details) {
                Navigator.pushNamedAndRemoveUntil(
                    context, Start.routeName, (_) => false);
              },
              message: "Clique aqui para recomeçar o cadastro.",
            ),
            SizedBox(height: screenHeight / 80),
          ],
        );
      });
    }
  }

  // If the user already has a client account, registerUser makes sure they enter
  // a correct password. If so, it updates their name and other entered information.
  // If the user is registering for the first time, it just creates their account
  Future<bool> registerUser() async {
    print("registerUser");
    // dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    // if the user already has a client account
    if (widget.firebase.model.user.isUserSignedIn) {
      print("firebase.isUserSignedIn");

      // make sure they've entered a valid password
      CheckPasswordResponse cpr = await widget.firebase.auth.checkPassword(
        passwordTextEditingController.text.trim(),
      );
      if (!cpr.successful) {
        // if not, display appropriate warning and return false
        setState(() {
          registrationErrorWarnings = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight / 40),
              Warning(
                message: cpr.message ?? "", 
              ),
              SizedBox(height: screenHeight / 80),
            ],
          );
        });
        return false;
      }

      // if yes, finish registration by updating user's display name and inserting
      // their cpf, gender and other relevant information in the database
      try {
        await widget.firebase.auth.createPartner(
          widget.userCredential,
          displayName: widget.name + " " + widget.surname,
          cpf: widget.cpf,
          gender: widget.gender,
        );
        // we enforce a variant that, by the time Documents is pushed, PartnerModel
        // must have been updated with the user information
        // try getting partner credentials
        await widget.firebase.model.partner.downloadData();
        return true;
      } on FirebaseAuthException catch (e) {
        await handleRegistrationFailure(e);
        return false;
      }
    } else {
      print("firebase.isNotRegistered");

      // if the user does not already have a client account
      try {
        // finish registration by updating user's credentials and inserting
        // their cpf, gender and other relevant information in the database
        await widget.firebase.auth.createPartner(
          widget.userCredential,
          displayName: widget.name + " " + widget.surname,
          cpf: widget.cpf,
          gender: widget.gender,
          email: widget.userEmail,
          password: passwordTextEditingController.text.trim(),
        );

        // we enforce a variant that, by the time Documents is pushed, PartnerModel
        // must have been updated with the user information
        // try getting partner credentials
        final user = widget.firebase.auth.currentUser;
        if(user != null) {  
          PartnerInterface? partnerInterface =
            await widget.firebase.database.getPartnerFromID(
          user.uid,
          );
          if(partnerInterface != null) {
            widget.firebase.model.partner.fromPartnerInterface(partnerInterface);
          }
          return true;
        }
        return false;
      } on FirebaseAuthException catch (e) {
        await handleRegistrationFailure(e);
        return false;
      }
    }
  }

  // buttonCallback tries signing user up by adding remainig data to its credential
  void buttonCallback(BuildContext context) async {
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

    // ask user to abide by privacy terms
    await showYesNoDialog(
      context,
      title: "Termos de Uso",
      child: RichText(
        text: TextSpan(
          text: "Você precisa aceitar os nossos ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          children: [
            TextSpan(
                text: "termos de uso",
                style: TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    String _url = "https://venni.app/termos/parceiros";
                    if (await canLaunch(_url)) {
                      try {
                        await launch(_url);
                      } catch (_) {}
                    }
                  }),
            TextSpan(
              text: " para criar a sua conta. Deseja aceitar os termos?",
            ),
          ],
        ),
      ),
      onPressedYes: () {
        // dismiss dialog
        Navigator.pop(context);
        setState(() {
          successfullyRegisteredUser = registerUser();
        });
      },
    );
  }
    
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    UserModel firebase = Provider.of<UserModel>(context, listen: false);

    return FutureBuilder(
      future: successfullyRegisteredUser,
      builder: (
        BuildContext context,
        AsyncSnapshot<bool> snapshot,
      ) {
        // user has tapped to register, and registration has finished succesfully
        if (snapshot.hasData && snapshot.data == true) {
          // future builder must return Widget, but we want to push a route.
          // thus, schedule pushing for right afer returning a Container.

          // push pending documents screen. After all, user has just created
          // a partner account and thus has 'pending_documents' accountStatus
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context,
              Documents.routeName,
            );
          });
          return Container();
        }

        // user has tapped to register, and we are waiting for registration to finish
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen
          return Splash(
              text: "Criando conta de parceiro(a)",
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ));
        }

        // error cases and default: show password screen
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
                                  onTapCallback: preventNavigateBack
                                      ? () {}
                                      : () => Navigator.pop(context)),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: screenHeight / 25),
                          Text(
                            firebase.isUserSignedIn
                                ? "Insira sua senha"
                                : "Insira uma senha",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                          SizedBox(height: screenHeight / 40),
                          firebase.isUserSignedIn
                              ? Column(
                                  children: [
                                    Text(
                                      "Já existe uma conta na Venni com telefone " +
                                          (widget.firebase.auth.currentUser?.phoneNumber?.withoutCountryCode() ?? "") +
                                          ". Insira sua senha para completar o cadastro",
                                      style: TextStyle(
                                        color: AppColor.disabled,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                          SizedBox(height: screenHeight / 40),
                          AppInputPassword(
                            controller: passwordTextEditingController,
                            autoFocus: true,
                          ),
                          // Don't display password warnings if user already
                          // has a client account. In that case, he should be
                          // inserting his actual client password, instead of
                          // trying to create a new one.
                          displayPasswordWarnings && !firebase.isUserSignedIn
                              ? Column(
                                  children: [
                                    SizedBox(height: screenHeight / 40),
                                    PasswordWarning(
                                      isValid: passwordChecks[0],
                                      message:
                                          "Precisa ter no mínimo 8 caracteres",
                                    ),
                                    SizedBox(height: screenHeight / 80),
                                    PasswordWarning(
                                      isValid: passwordChecks[1],
                                      message:
                                          "Precisa ter pelo menos uma letra",
                                    ),
                                    SizedBox(height: screenHeight / 80),
                                    PasswordWarning(
                                      isValid: passwordChecks[2],
                                      message:
                                          "Precisa ter pelo menos um dígito",
                                    ),
                                    SizedBox(height: screenHeight / 80),
                                  ],
                                )
                              : Container(),
                          registrationErrorWarnings != null
                              ? registrationErrorWarnings!
                              : Container(),
                          Spacer(),
                          Row(
                            children: [
                              Spacer(),
                              CircularButton(
                                buttonColor: circularButtonColor,
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressedCallback:
                                    circularButtonCallback == null
                                        ? () {}
                                        : () => circularButtonCallback!(context),
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
      },
    );
  }
}
