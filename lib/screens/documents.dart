import 'dart:async';

import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/home.dart';
import 'package:partner_app/screens/sendBankAccount.dart';
import 'package:partner_app/screens/sendCnh.dart';
import 'package:partner_app/screens/sendCrlv.dart';
import 'package:partner_app/screens/sendPhotoWithCnh.dart';
import 'package:partner_app/screens/sendProfilePhoto.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/database/methods.dart';
import 'package:partner_app/vendors/urlLauncher.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class Documents extends StatefulWidget {
  static const routeName = "Documents";
    final FirebaseService firebase = FirebaseService();

  @override
  DocumentsState createState() => DocumentsState();
}

class DocumentsState extends State<Documents> {
  StreamSubscription? accountStatusSubscription;
  StreamSubscription? submittedDocumentsSubscription;
  var _firebaseListener;
  Widget? buttonChild;
  bool lockScreen = false;

  @override
  void initState() {
    super.initState();

    // subscribe to changes in account_status so UI is updated appropriately
    final user = widget.firebase.auth.currentUser;
    if(user != null) {
      accountStatusSubscription =widget.firebase.database.onAccountStatusUpdate(
        user.uid,
          (e) {
          AccountStatus accountStatus = AccountStatusExtension.fromString(
            e.snapshot.value.toString(),
          );
          // update partner model accordingly
          widget.firebase.model.partner.updateAccountStatus(accountStatus);
        },
      );

      // subscribe to changes in submitted_documents so UI is updated appropriately
      submittedDocumentsSubscription =
          widget.firebase.database.onSubmittedDocumentsUpdate(
        user.uid,
        (e) {
          final partner = widget.firebase.model.partner;
          SubmittedDocuments sd = SubmittedDocuments.fromJson(e.snapshot.value as Map);
          partner.updateBankAccountSubmitted(sd.bankAccount);
          partner.updateCnhSubmitted(sd.cnh);
          partner.updateCrlvSubmitted(sd.crlv);
          partner.updatePhotoWithCnhSubmitted(sd.photoWithCnh);
          partner.updateProfilePhotoSubmitted(sd.profilePhoto);
        },
      );
    }



    WidgetsBinding.instance.addPostFrameCallback((_) {
      // add listener to UserModel so user is redirected to Start when logs out
      _firebaseListener = () {
        _signOut(context);
      };
      widget.firebase.model.user.addListener(_firebaseListener);
    });
  }

  @override
  void dispose() {
    widget.firebase.model.user.removeListener(_firebaseListener);
    accountStatusSubscription?.cancel();
    submittedDocumentsSubscription?.cancel();
    super.dispose();
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    if (!widget.firebase.model.user.isUserSignedIn) {
      Navigator.pushNamedAndRemoveUntil(context, Start.routeName, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    PartnerModel partner = Provider.of<PartnerModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: screenHeight / 8,
            color: AppColor.primaryPink,
            child: Padding(
              padding: EdgeInsets.only(
                top: screenHeight / 20,
                right: screenWidth / 15,
                left: screenWidth / 15,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("images/horizontal-white-logo.png"),
                    width: screenWidth * 0.3,
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: lockScreen == true
                        ? () {}
                        : () => _showHelpDialog(context, "5538998601275"),
                    child: Container(
                      width: screenWidth / 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenHeight / 100),
                        child: Row(
                          children: [
                            Text("Ajuda"),
                            Spacer(),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: OverallPadding(
              top: screenHeight / 30,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bem-vindo(a), " + (partner.name ?? ""),
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    partner.accountStatus == AccountStatus.grantedInterview
                        ? Column(
                            children: [
                              SizedBox(height: screenHeight / 20),
                              Text(
                                "Parabéns! Suas informações foram aprovadas. Entraremos em contato pelo telefone e email informados para agendar a sua entrevista presencial.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColor.secondaryGreen,
                                ),
                              ),
                              SizedBox(height: screenHeight / 40),
                            ],
                          )
                        : Container(),
                    partner.accountStatus == AccountStatus.locked
                        ? Column(
                            children: [
                              SizedBox(height: screenHeight / 20),
                              Text(
                                "A sua conta foi bloqueada. Entre em contato conosco para mais detalhes.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColor.secondaryRed,
                                ),
                              ),
                              SizedBox(height: screenHeight / 40),
                            ],
                          )
                        : Container(),
                    partner.accountStatus == AccountStatus.approved
                        ? LayoutBuilder(builder: (
                            BuildContext context,
                            BoxConstraints viewportConstraints,
                          ) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: screenHeight / 1.5,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    SizedBox(height: screenHeight / 20),
                                    Text(
                                      "Parabéns! Você foi aprovado(a) e já pode começar a fazer corridas. Bem-vindo(a) à Venni!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColor.secondaryGreen,
                                      ),
                                    ),
                                    Spacer(),
                                    AppButton(
                                      textData: "Começar",
                                      child: buttonChild,
                                      onTapCallBack: lockScreen == true
                                          ? () {}
                                          : () async => await start(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                        : Container(),
                    partner.accountStatus == AccountStatus.pendingDocuments ||
                            partner.accountStatus ==
                                AccountStatus.deniedApproval
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight / 20),
                              Text(
                                "Documentos obrigatórios",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: screenHeight / 40),
                              Text(
                                "Após o envio dos documentos, analizaremos a sua inscrição em até 48 horas.",
                                style: TextStyle(
                                    fontSize: 16, color: AppColor.disabled),
                              ),
                              SizedBox(height: screenHeight / 40),
                            ],
                          )
                        : Container(),
                    partner.accountStatus == AccountStatus.pendingDocuments ||
                            partner.accountStatus ==
                                AccountStatus.deniedApproval
                        ? ListBody(
                            children: [
                              partner.crlvSubmitted == true
                                  ? Container()
                                  : Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          onTap: () async {
                                            Navigator.pushNamed(
                                                context, SendCrlv.routeName);
                                          },
                                          title: Text(
                                            "Certificado de Registro e Licensiamento de Veículo (CRLV)",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          leading: Icon(Icons.description,
                                              color: Colors.black),
                                          trailing: Icon(
                                            Icons.keyboard_arrow_right,
                                            color: AppColor.disabled,
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    ),
                              partner.cnhSubmitted == true
                                  ? Container()
                                  : Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          onTap: () async {
                                            Navigator.pushNamed(
                                                context, SendCnh.routeName);
                                          },
                                          title: Text(
                                            "Carteira Nacional de Habilitação com EAR (CNH)",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          leading: Icon(Icons.description,
                                              color: Colors.black),
                                          trailing: Icon(
                                            Icons.keyboard_arrow_right,
                                            color: AppColor.disabled,
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    ),
                              partner.photoWithCnhSubmitted == true
                                  ? Container()
                                  : Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          onTap: () async {
                                            Navigator.pushNamed(
                                              context,
                                              SendPhotoWithCnh.routeName,
                                            );
                                          },
                                          title: Text(
                                            "Foto do Rosto com CNH do Lado",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          leading: Icon(Icons.description,
                                              color: Colors.black),
                                          trailing: Icon(
                                            Icons.keyboard_arrow_right,
                                            color: AppColor.disabled,
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    ),
                              partner.profilePhotoSubmitted == true
                                  ? Container()
                                  : Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          onTap: () async {
                                            Navigator.pushNamed(
                                              context,
                                              SendProfilePhoto.routeName,
                                            );
                                          },
                                          title: Text(
                                            "Foto de Perfil",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          leading: Icon(Icons.description,
                                              color: Colors.black),
                                          trailing: Icon(
                                            Icons.keyboard_arrow_right,
                                            color: AppColor.disabled,
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    ),
                              partner.bankAccountSubmitted == true
                                  ? Container()
                                  : Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          onTap: () async {
                                            Navigator.pushNamed(
                                              context,
                                              SendBankAccount.routeName,
                                              arguments:
                                                  SendBankAccountArguments(
                                                mode: SendBankAccountMode.send,
                                              ),
                                            );
                                          },
                                          title: Text(
                                            "Informações bancárias",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          leading: Icon(Icons.description,
                                              color: Colors.black),
                                          trailing: Icon(
                                            Icons.keyboard_arrow_right,
                                            color: AppColor.disabled,
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    ),
                            ],
                          )
                        : Container(),
                    SizedBox(height: screenHeight / 20),
                    partner.accountStatus == AccountStatus.pendingReview ||
                            partner.accountStatus ==
                                AccountStatus.pendingDocuments ||
                            partner.accountStatus ==
                                AccountStatus.deniedApproval
                        ? Text(
                            "Documentos enviados",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          )
                        : Container(),
                    SizedBox(height: screenHeight / 40),
                    partner.accountStatus == AccountStatus.pendingReview
                        ? Column(
                            children: [
                              Text(
                                "Estamos analizando suas informações. Entraremos em contato pelo email e telefone informados em até 48 horas após o envio.",
                                style: TextStyle(
                                    fontSize: 16, color: AppColor.disabled),
                              ),
                              SizedBox(height: screenHeight / 40),
                            ],
                          )
                        : Container(),
                    partner.accountStatus == AccountStatus.pendingReview ||
                            partner.accountStatus ==
                                AccountStatus.pendingDocuments ||
                            partner.accountStatus ==
                                AccountStatus.deniedApproval
                        ? ListBody(
                            children: [
                              partner.crlvSubmitted == true
                                  ? Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            "Certificado de Registro e Licensiamento de Veículo (CRLV)",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: AppColor.secondaryGreen
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    )
                                  : Container(),
                              partner.cnhSubmitted == true
                                  ? Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            "Carteira Nacional de Habilitação com EAR (CNH)",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: AppColor.secondaryGreen
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    )
                                  : Container(),
                              partner.photoWithCnhSubmitted == true
                                  ? Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            "Foto do Rosto com CNH do Lado",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: AppColor.secondaryGreen
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    )
                                  : Container(),
                              partner.profilePhotoSubmitted == true
                                  ? Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            "Foto de Perfil",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: AppColor.secondaryGreen
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Divider(
                                            color: Colors.black,
                                            thickness: 0.1),
                                      ],
                                    )
                                  : Container(),
                              partner.bankAccountSubmitted == true
                                  ? Column(
                                      children: [
                                        ListTile(
                                          minLeadingWidth: 0,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            "Informações bancárias",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: AppColor.secondaryGreen
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> start(BuildContext context) async {
    PartnerModel partner = Provider.of<PartnerModel>(
      context,
      listen: false,
    );
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );

    // make sure user is connected to the internet
    if (!connectivity.hasConnection) {
      await connectivity.alertOffline(
        context,
        message: "Conecte-se à internet para fazer começar",
      );
      return;
    }
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white,
        ),
      );
      lockScreen = true;
    });

    // download partner data
    try {
      await partner.downloadData(notify: false);
    } catch (_) {
      await showOkDialog(
        context: context,
        title: "Algo deu errado",
        content: "Verifique a sua conexão com a internet e tente novamente.",
      );
      return;
    }

    await Future.delayed(Duration(seconds: 2));
    Navigator.pushNamedAndRemoveUntil(
      context,
      Home.routeName,
      (_) => false,
    );
  }
}

Future<dynamic> _showHelpDialog(BuildContext context, String phoneNumber) {
  final firebase = FirebaseService();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              ListTile(
                onTap: () async =>
                    await UrlLauncher.openWhatsapp(context, phoneNumber),
                title: Text("Chat com o suporte"),
                leading: Icon(
                  Icons.question_answer,
                  color: AppColor.primaryPink,
                ),
              ),
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  await showYesNoDialog(
                    context,
                    title: "Deseja sair?",
                    onPressedYes: () async {
                      await firebase.auth.signOut();
                    },
                  );
                },
                title: Text("sair"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
