import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class Documents extends StatefulWidget {
  static const routeName = "Documents";
  @override
  DocumentsState createState() => DocumentsState();
}

// TODO: as user sends information, add the under 'Documentos enviados'

class DocumentsState extends State<Documents> with WidgetsBindingObserver {
  bool _hasConnection;

  @override
  Widget build(BuildContext context) {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context);
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
                    onTap: () => _showHelpDialog(context),
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
          OverallPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bem-vindo(a), " + partner.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: screenHeight / 20),
                Text(
                  "Documentos obrigatórios",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: screenHeight / 40),
                Text(
                  "Após o envio dos documentos, analizaremos a sua inscrição em até 48 horas.",
                  style: TextStyle(fontSize: 16, color: AppColor.disabled),
                ),
                SizedBox(height: screenHeight / 40),
                ListBody(
                  children: [
                    ListTile(
                      minLeadingWidth: 0,
                      contentPadding: EdgeInsets.all(0),
                      onTap: () async {},
                      title: Text(
                        "Certificado de Registro e Licensiamento de Veículo (CRLV)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.description, color: Colors.black),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColor.disabled,
                      ),
                    ),
                    Divider(color: Colors.black, thickness: 0.1),
                    ListTile(
                      minLeadingWidth: 0,
                      contentPadding: EdgeInsets.all(0),
                      onTap: () async {},
                      title: Text(
                        "Carteira Nacional de Habilitação com EAR (CNH)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.description, color: Colors.black),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColor.disabled,
                      ),
                    ),
                    Divider(color: Colors.black, thickness: 0.1),
                    ListTile(
                      minLeadingWidth: 0,
                      contentPadding: EdgeInsets.all(0),
                      onTap: () async {},
                      title: Text(
                        "Foto do Rosto com CNH do Lado",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.description, color: Colors.black),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColor.disabled,
                      ),
                    ),
                    Divider(color: Colors.black, thickness: 0.1),
                    ListTile(
                      minLeadingWidth: 0,
                      contentPadding: EdgeInsets.all(0),
                      onTap: () async {},
                      title: Text(
                        "Foto de Perfil",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.description, color: Colors.black),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColor.disabled,
                      ),
                    ),
                    Divider(color: Colors.black, thickness: 0.1),
                    ListTile(
                      minLeadingWidth: 0,
                      contentPadding: EdgeInsets.all(0),
                      onTap: () async {},
                      title: Text(
                        "Informações bancárias",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.description, color: Colors.black),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColor.disabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Future<dynamic> _showHelpDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              ListTile(
                onTap: () async {
                  // TODO: open whatsapp
                },
                title: Text("Chat com o suporte"),
                leading: Icon(
                  Icons.question_answer,
                  color: AppColor.primaryPink,
                ),
              ),
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  // TODO: logout
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
