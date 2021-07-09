import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class AccountLocked extends StatefulWidget {
  @override
  AccountLockedState createState() => AccountLockedState();
}

class AccountLockedState extends State<AccountLocked> {
  bool lockScreen = false;
  Widget buttonChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SlidingUpPanel(
      panel: OverallPadding(
        top: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight / 100),
            Icon(
              Icons.maximize,
              color: Colors.black.withOpacity(0.3),
              size: 30,
            ),
            Spacer(),
            SizedBox(height: screenHeight / 100),
            Text(
              "Entre em contato conosco para saber mais detalhes. Por enquanto, você não vai receber pedidos de corridas.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
      collapsed: Column(
        children: [
          SizedBox(height: screenHeight / 25),
          buttonChild == null
              ? Text(
                  "CONTA BLOQUEADA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColor.primaryPink,
                  ),
                )
              : buttonChild,
        ],
      ),
      color: Colors.white,
      maxHeight: screenHeight / 2.7,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10.0),
        topRight: Radius.circular(10.0),
      ),
    );
  }
}
