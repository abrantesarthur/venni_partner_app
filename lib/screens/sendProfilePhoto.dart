import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/imagePicker.dart';
import 'package:partner_app/vendors/firebaseStorage.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class SendProfilePhoto extends StatefulWidget {
  static const String routeName = "sendProfilePhoto";

  @override
  SendProfilePhotoState createState() => SendProfilePhotoState();
}

// TODO: update photo
class SendProfilePhotoState extends State<SendProfilePhoto> {
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
                  onTapCallback: () => Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Tire sua foto de perfil",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Atenção: não é possível alterar a foto depois de enviá-la. Sua foto de perfil ajuda as pessoas a reconhecerem você.",
              style: TextStyle(color: Colors.black, fontSize: 14),
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
                          "1. Fique de frente para a câmera e deixe os olhos e boca visíveis, como na ilustração abaixo",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "2. Não use oculos escuros, bonés, chapéus, tocas ou qualquer acessório que cubra seu rosto",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "3. Não fotografe outra foto, não use filtros nem retoque a image",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "4. Verifique se a foto está nítida, bem iluminada e sem reflexos",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 25),
                        Row(
                          children: [
                            Spacer(),
                            Container(
                              width: screenWidth / 2,
                              height: screenHeight / 4,
                              alignment: Alignment.center,
                              decoration: new BoxDecoration(
                                image: new DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage("images/profilePic.png")),
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
                      buttonColor: AppColor.primaryPink,
                      onTapCallBack: () async {
                        if (!connectivity.hasConnection) {
                          await connectivity.alertWhenOffline(
                            context,
                            message:
                                "Conecte-se à internet para enviar a foto de perfil.",
                          );
                          return;
                        }

                        await sendProfilePhoto(context);
                      },
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

  Future<void> sendProfilePhoto(BuildContext context) async {
    final FirebaseModel firebase = Provider.of<FirebaseModel>(
      context,
      listen: false,
    );

    // get profilePhoto from camera or gallery
    PickedFile profilePhoto = await pickImage(context);

    // send profilePhoto to firebase
    if (profilePhoto != null) {
      try {
        firebase.storage.sendProfilePhoto(
          partnerID: firebase.auth.currentUser.uid,
          profilePhoto: profilePhoto,
        );
      } catch (e) {
        // on error, display warning
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
  }
}
