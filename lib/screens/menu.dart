import 'package:flutter/material.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/profile.dart';
import 'package:partner_app/screens/settings.dart';
import 'package:partner_app/screens/wallet.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/circularImage.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';

class Menu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    final PartnerModel partner = Provider.of<PartnerModel>(context);

    return Drawer(
      child: ListView(
        children: [
          Container(
            height: screenHeight / 3.5,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, Profile.routeName),
                child: Column(
                  children: [
                    Spacer(flex: 2),
                    CircularImage(
                      imageFile: partner.profileImage == null
                          ? AssetImage("images/user_icon.png")
                          : partner.profileImage.file,
                    ),
                    Spacer(),
                    Text(
                      firebase.auth.currentUser != null
                          ? firebase.auth.currentUser.displayName
                          : "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    partner.rating != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                partner.rating.toString(),
                                style: TextStyle(fontSize: 15.0),
                              ),
                              SizedBox(width: screenWidth / 80),
                              Icon(Icons.star_rate,
                                  size: 18, color: Colors.black87),
                            ],
                          )
                        : Container(),
                    Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight / 50),
          OverallPadding(
            top: 0,
            child: Column(
              children: [
                BorderlessButton(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Wallet.routeName,
                      arguments: WalletArguments(
                        firebase: firebase,
                        partner: partner,
                      ),
                    );
                  },
                  iconLeft: Icons.trending_up,
                  iconLeftSize: 24,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Carteira",
                  primaryTextSize: 18,
                  paddingBottom: screenHeight / 80,
                ),
                Divider(thickness: 0.1, color: Colors.black),
                BorderlessButton(
                  onTap: () {},
                  iconLeft: Icons.stars,
                  iconLeftSize: 24,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Avaliações",
                  primaryTextSize: 18,
                  paddingTop: screenHeight / 80,
                  paddingBottom: screenHeight / 80,
                ),
                Divider(thickness: 0.1, color: Colors.black),
                BorderlessButton(
                  onTap: () {},
                  iconLeft: Icons.motorcycle,
                  iconLeftSize: 24,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Corridas",
                  primaryTextSize: 18,
                  paddingTop: screenHeight / 80,
                  paddingBottom: screenHeight / 80,
                ),
                Divider(thickness: 0.1, color: Colors.black),
                BorderlessButton(
                  onTap: () => Navigator.pushNamed(context, Settings.routeName),
                  iconLeft: Icons.settings,
                  iconLeftSize: 24,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Configurações",
                  primaryTextSize: 18,
                  paddingTop: screenHeight / 80,
                  paddingBottom: screenHeight / 80,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
