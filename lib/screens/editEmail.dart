import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/screens/insertNewEmail.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/services/firebase/firebaseAuth.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/goBackScaffold.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

class EditEmail extends StatefulWidget {
  static const String routeName = "EditEmail";

  @override
  EditEmailState createState() => EditEmailState();
}

class EditEmailState extends State<EditEmail> {
  late bool codeSent;
  Widget? warning;

  @override
  void initState() {
    codeSent = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final UserModel user = Provider.of<UserModel>(context);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return GoBackScaffold(
      title: "Alterar Email",
      children: [
        Text(
          user.email ?? "",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: screenHeight / 30),
        warning != null
            ? Column(children: [
                warning!,
                SizedBox(height: screenHeight / 30),
              ])
            : (user.emailVerified == true
                ? Text(
                    "Email verificado!",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColor.disabled,
                    ),
                  )
                : (codeSent == false
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Seu email ainda não foi verificado. Não recebeu o link de verificação?",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColor.disabled,
                            ),
                          ),
                          SizedBox(height: screenHeight / 30),
                          Warning(
                            message: "Reenviar email de verificação",
                            color: AppColor.secondaryPurple,
                            onTapCallback: (_context) async {
                              // ensure user is connected to the internet
                              if (!connectivity.hasConnection) {
                                await connectivity.alertOffline(
                                  context,
                                  message:
                                      "Conecte-se à internet para reenviar o email.",
                                );
                                return;
                              }
                              try {
                                await user.sendEmailVerification();
                                setState(() {
                                  codeSent = true;
                                });
                              } catch (e) {
                                // display warning on failure
                                setState(() {
                                  warning = Warning(
                                    message:
                                        "Falha ao enviar email. Altere o email ou tente novamente mais tarde.",
                                    color: AppColor.secondaryRed,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      )
                    : Text(
                        "Email enviado. Cheque o seu email.",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColor.disabled,
                        ),
                      ))),
        Spacer(),
        AppButton(
            textData: "Alterar Email",
            onTapCallBack: () async {
              // ensure user is connected to the internet
              if (!connectivity.hasConnection) {
                await connectivity.alertOffline(
                  context,
                  message: "Conecte-se à internet para alterar o email.",
                );
                return;
              }
              final response = await Navigator.pushNamed(
                context,
                InsertNewEmail.routeName,
              ) as UpdateEmailResponse?;
              if (response != null && response.successful) {
                setState(() {
                  warning = Warning(
                    message: "Email alterado com sucesso para " +
                        (user.email ?? ""),
                    color: AppColor.secondaryGreen,
                  );
                });
              }
            })
      ],
    );
  }
}
