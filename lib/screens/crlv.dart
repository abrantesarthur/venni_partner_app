import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class SendCrlv extends StatefulWidget {
  static const String routeName = "sendCrlv";

  @override
  SendCrlvNumberState createState() => SendCrlvNumberState();
}

class SendCrlvNumberState extends State<SendCrlv> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final firebaseModel = Provider.of<FirebaseModel>(context);

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
                        "Insira seu nº de celular",
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                      SizedBox(height: screenHeight / 40),
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
