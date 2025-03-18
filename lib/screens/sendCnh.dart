import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/imagePicker.dart';
import 'package:partner_app/services/firebase/firebaseStorage.dart';
import 'package:partner_app/services/firebase/database/methods.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class SendCnh extends StatefulWidget {
  static const String routeName = "sendCnh";

  @override
  SendCnhState createState() => SendCnhState();
}

class SendCnhState extends State<SendCnh> {
  Widget buttonChild;
  bool lockScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final connectivity = Provider.of<ConnectivityModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: OverallPadding(
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(
                  onTapCallback:
                      lockScreen ? () {} : () => Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Envie uma foto da sua Carteira Nacional de Habilitação (CNH) com EAR",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight / 25),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Requisitos de envio",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "1. A CNH deve ter a observação Exerce Atividade Remunerada (EAR), estar legível e dentro do prazo de validade.",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "2. A foto deve ser tirada do documento aberto e fora do plástico, como na ilustração abaixo",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "3. Se preferir, pode enviar uma foto da CNH digital que você pode obter no site do Denatran ou através do app gov.br",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 25),
                        Row(
                          children: [
                            Spacer(),
                            Container(
                              width: screenWidth / 1.3,
                              height: screenHeight / 2,
                              alignment: Alignment.center,
                              decoration: new BoxDecoration(
                                image: new DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage("images/cnh.png")),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        SizedBox(height: screenHeight / 5),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight / 15,
                    left: 0,
                    right: 0,
                    child: AppButton(
                      textData: "Enviar CNH",
                      buttonColor: AppColor.primaryPink,
                      child: buttonChild,
                      onTapCallBack: lockScreen
                          ? () {}
                          : () async => await buttonCallback(context),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> buttonCallback(BuildContext context) async {
    // get relevant models
    final connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    final UserModel firebase = Provider.of<UserModel>(
      context,
      listen: false,
    );
    final PartnerModel partner = Provider.of<PartnerModel>(
      context,
      listen: false,
    );

    // make sure user is connected to the internet
    if (!connectivity.hasConnection) {
      await connectivity.alertOffline(
        context,
        message: "Conecte-se à internet para enviar o CRLV.",
      );
      return;
    }

    // get cnh from camera or gallery
    Future<PickedFile> futureCnh = await pickImage(context);

    // show progress indicator and lock screen
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      lockScreen = true;
    });

    PickedFile cnh = await futureCnh;

    if (cnh != null) {
      try {
        // store cnh in firebase storage
        await firebase.storage.pushCnh(
          partnerID: firebase.auth.currentUser.uid,
          cnh: cnh,
        );

        // on success, make cnh as submitted both on firebase database and locally
        await firebase.database.setSubmittedCnh(
          partnerID: firebase.auth.currentUser.uid,
          value: true,
        );
        partner.updateCnhSubmitted(true);

        // finally,  go back to Documents screen
        Navigator.pop(context);
      } catch (e) {
        // on failure, display warning
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Algo deu errado."),
              content: Text(
                "Tente novamente mais tarde.",
                style: TextStyle(color: AppColor.disabled),
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

    // hide progress indicator
    setState(() {
      buttonChild = null;
      lockScreen = false;
    });
  }
}
