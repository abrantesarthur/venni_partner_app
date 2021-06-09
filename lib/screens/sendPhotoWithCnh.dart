import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/imagePicker.dart';
import 'package:partner_app/vendors/firebaseStorage.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class SendPhotoWithCnh extends StatefulWidget {
  static const String routeName = "sendPhotoWithCnh";

  @override
  SendPhotoWithCnhState createState() => SendPhotoWithCnhState();
}

// TODO: update photo
class SendPhotoWithCnhState extends State<SendPhotoWithCnh> {
  Widget buttonChild;
  bool lockScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
              "Envie uma foto de você segurando sua CNH",
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
                          "1. A CNH deve estar próxima do seu rosto, como na ilustração abaixo",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "2. O documento deve estar legível",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "3. Se você possui a CNH digital, recomendamos que abra o documento em um outro aparelho e aproxime ao seu rosto",
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
                      textData: "Enviar Foto",
                      child: buttonChild,
                      buttonColor: AppColor.primaryPink,
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
    final FirebaseModel firebase = Provider.of<FirebaseModel>(
      context,
      listen: false,
    );
    final PartnerModel partner = Provider.of<PartnerModel>(
      context,
      listen: false,
    );

    // make sure user is connected to the internet
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(
        context,
        message: "Conecte-se à internet para enviar o CRLV.",
      );
      return;
    }

    // get crlv from camera or gallery
    Future<PickedFile> futurePhotoWithCnh = await pickImage(context);

    // show progress indicator and lock screen
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      lockScreen = true;
    });

    PickedFile photoWithCnh = await futurePhotoWithCnh;

    if (photoWithCnh != null) {
      try {
        // send photoWithCnh to firebase
        await firebase.storage.sendPhotoWithCnh(
          partnerID: firebase.auth.currentUser.uid,
          photoWithCnh: photoWithCnh,
        );
        // on success, make photoWithCnh as submitted and go back to Documents screen
        partner.updatePhotoWithCnhSubmitted(true);
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
