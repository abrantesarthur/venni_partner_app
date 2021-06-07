import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class SendPhotoWithCnh extends StatefulWidget {
  static const String routeName = "sendPhotoWithCnh";

  @override
  SendPhotoWithCnhState createState() => SendPhotoWithCnhState();
}

class SendPhotoWithCnhState extends State<SendPhotoWithCnh> {
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
                  onTapCallback: () => Navigator.pop(context),
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
                          "3. Se preferir, pode enviar uma foto da CNH digital que você pode obter no site do Denatran ou através do app gov.b",
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
                      onTapCallBack: () {},
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
}
