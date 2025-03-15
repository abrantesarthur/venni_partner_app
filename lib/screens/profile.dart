import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/editEmail.dart';
import 'package:partner_app/screens/editPhone.dart';
import 'package:partner_app/screens/insertNewPassword.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';

import '../models/user.dart';

class ProfileArguments {
  final PartnerModel partner;
  final UserModel firebase;

  ProfileArguments({
    required this.partner,
    required this.firebase,
  });
}

class Profile extends StatefulWidget {
  static const String routeName = "Profile";
  final PartnerModel partner;
  final UserModel firebase;

  Profile({
    required this.partner,
    required this.firebase,
  });

  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  Future<bool> downloadedPartnerData;

  @override
  void initState() {
    // download partner data so we always display updated total trip count
    downloadedPartnerData = downloadPartnerData();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // reload firebase so we get update info about email confirmation
      UserModel firebase = Provider.of<UserModel>(
        context,
        listen: false,
      );
      firebase.auth.currentUser.reload();
    });

    super.initState();
  }

  Future<bool> downloadPartnerData() async {
    try {
      await widget.partner.downloadData(widget.firebase);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final UserModel firebase = Provider.of<UserModel>(context);
    final PartnerModel partner = Provider.of<PartnerModel>(context);

    return FutureBuilder(
        future: downloadedPartnerData,
        builder: (
          BuildContext context,
          AsyncSnapshot<bool> snapshot,
        ) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: OverallPadding(
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
                  SizedBox(height: screenHeight / 30),
                  Text(
                    "Perfil",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  SizedBox(height: screenHeight / 30),
                  snapshot.connectionState == ConnectionState.waiting
                      ? Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColor.primaryPink),
                            ),
                          ),
                        )
                      : (snapshot.data == null || !snapshot.data)
                          ? Text(
                              "Algo deu errado. Cheque asua conexão com a internet e tente novamente.",
                              style: TextStyle(fontSize: 16),
                            )
                          : Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Spacer(),
                                      Stack(
                                        children: [
                                          Container(
                                            width: screenHeight / 7,
                                            height: screenHeight / 7,
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: new DecorationImage(
                                                fit: BoxFit.cover,
                                                image: partner.profileImage ==
                                                        null
                                                    ? AssetImage(
                                                        "images/user_icon.png")
                                                    : partner.profileImage.file,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight / 30),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          BorderlessButton(
                                            primaryText: "Nome",
                                            secondaryText: firebase.auth
                                                    .currentUser?.displayName ??
                                                "",
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            primaryText: "Corridas Realizadas",
                                            secondaryText: partner.totalTrips
                                                    ?.toString() ??
                                                "",
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            primaryText: "Parceiro(a) desde",
                                            secondaryText: partner.memberSince
                                                    ?.getFormatedDate() ??
                                                "",
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            primaryText: "Moto",
                                            secondaryText: (partner
                                                        .vehicle?.brand ??
                                                    "") +
                                                " " +
                                                (partner.vehicle?.model ?? "") +
                                                " - " +
                                                (partner.vehicle?.plate ?? ""),
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            onTap: () async {
                                              await Navigator.pushNamed(
                                                context,
                                                EditPhone.routeName,
                                              );
                                              // call setState to rebuild tree and display updated phone
                                              setState(() {});
                                            },
                                            primaryText: "Alterar Telefone",
                                            secondaryText: firebase
                                                .auth.currentUser?.phoneNumber
                                                ?.withoutCountryCode(),
                                            label: "Confirmado",
                                            labelColor: Colors.green,
                                            iconRight:
                                                Icons.keyboard_arrow_right,
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            onTap: () async {
                                              await Navigator.pushNamed(
                                                context,
                                                EditEmail.routeName,
                                              );
                                              // call setState to rebuild tree and display updated email
                                              setState(() {});
                                            },
                                            primaryText: "Alterar email",
                                            secondaryText: firebase
                                                .auth.currentUser?.email,
                                            label: firebase.auth.currentUser
                                                    .emailVerified
                                                ? "Confirmado"
                                                : "Não confirmado",
                                            labelColor: firebase.auth
                                                    .currentUser.emailVerified
                                                ? Colors.green
                                                : AppColor.secondaryRed,
                                            iconRight:
                                                Icons.keyboard_arrow_right,
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                          Divider(
                                              thickness: 0.1,
                                              color: Colors.black),
                                          BorderlessButton(
                                            onTap: () async {
                                              await Navigator.pushNamed(
                                                context,
                                                InsertNewPassword.routeName,
                                              );
                                            },
                                            primaryText: "Alterar senha",
                                            secondaryText: "••••••••",
                                            iconRight:
                                                Icons.keyboard_arrow_right,
                                            primaryTextSize: 16,
                                            secondaryTextSize: 18,
                                            paddingTop: screenHeight / 150,
                                            paddingBottom: screenHeight / 150,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ],
              ),
            ),
          );
        });
  }
}
