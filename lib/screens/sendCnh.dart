import 'package:flutter/material.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';

class SendCnh extends StatefulWidget {
  static const String routeName = "sendCnh";

  @override
  SendCnhNumberState createState() => SendCnhNumberState();
}

class SendCnhNumberState extends State<SendCnh> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                              onTapCallback: () => Navigator.pop(context)),
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
                      SizedBox(height: screenHeight / 20),
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
                        "1. A CNH deve ter a observação Exerce Atividade Remunerada (EAR)",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      SizedBox(height: screenHeight / 50),
                      Text(
                        "2. O documento deve estar dentro do prazo de validade",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      SizedBox(height: screenHeight / 50),
                      Text(
                        "3. Os dados do documento devem estar legíveis",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      SizedBox(height: screenHeight / 20),
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
                      SizedBox(height: screenHeight / 20),
                      // TODO: name CRLV correctly based on type (image versus pdf)
                      AppButton(textData: "Enviar CNH", onTapCallBack: () {}),
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
