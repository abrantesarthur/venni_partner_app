import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class SendCrlv extends StatefulWidget {
  static const String routeName = "sendCrlv";

  @override
  SendCrlvNumberState createState() => SendCrlvNumberState();
}

class SendCrlvNumberState extends State<SendCrlv> {
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
              "Envie o seu CRLV",
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
                          "1. O documento do veículo deve estar dentro do prazo de validade",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "2. Envie somente a primeira página. Porém, os dados devem estar legíveis",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "3. Você pode enviar ou uma foto do CRLV físico ou o CRLV digital em formato PDF que você pode obter no site do Detran ou através do app gov.br",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        SizedBox(height: screenHeight / 25),
                        Row(
                          children: [
                            Spacer(),
                            Container(
                              width: screenWidth / 1.3,
                              height: screenHeight / 4,
                              alignment: Alignment.center,
                              decoration: new BoxDecoration(
                                image: new DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage("images/crlv.png")),
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
                      textData: "Enviar CRLV",
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
