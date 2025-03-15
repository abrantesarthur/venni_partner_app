import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/screens/insertAditionalInfo.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:partner_app/utils/utils.dart';

class InsertNameArguments {
  final UserCredential userCredential;
  final String userEmail;
  InsertNameArguments({
    required this.userCredential,
    required this.userEmail,
  });
}

class InsertName extends StatefulWidget {
  static const routeName = "InsertName";

  final UserCredential userCredential;
  final String userEmail;
  InsertName({
    required this.userCredential,
    required this.userEmail,
  });

  @override
  InsertNameState createState() => InsertNameState();
}

class InsertNameState extends State<InsertName> {
  Color circularButtonColor;
  Function circularButtonCallback;
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController surnameTextEditingController = TextEditingController();
  FocusNode nameFocusNode = FocusNode();
  FocusNode surnameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    circularButtonColor = AppColor.disabled;
    nameTextEditingController.addListener(() {
      controllerListener(
        nameTextEditingController.text ?? "",
        surnameTextEditingController.text ?? "",
      );
    });
    surnameTextEditingController.addListener(() {
      controllerListener(
        nameTextEditingController.text ?? "",
        surnameTextEditingController.text ?? "",
      );
    });
  }

  @override
  void dispose() {
    nameTextEditingController.dispose();
    surnameTextEditingController.dispose();
    nameFocusNode.dispose();
    surnameFocusNode.dispose();
    super.dispose();
  }

  void controllerListener(String name, String surname) {
    if (name.length > 1 && surname.length > 1) {
      setState(() {
        circularButtonCallback = buttonCallback;
        circularButtonColor = AppColor.primaryPink;
      });
    } else {
      setState(() {
        circularButtonCallback = null;
        circularButtonColor = AppColor.disabled;
      });
    }
  }

  // buttonCallback formats the inserted name and redirects user to next registration screen
  void buttonCallback(BuildContext context) async {
    Navigator.pushNamed(
      context,
      InsertAditionalInfo.routeName,
      arguments: InsertAditionalInfoArguments(
        userCredential: widget.userCredential,
        name: nameTextEditingController.text.trim().capitalize,
        surname: surnameTextEditingController.text.trim().capitalize,
        userEmail: widget.userEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: LayoutBuilder(builder: (
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
                      "Insira o seu nome e sobrenome",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    SizedBox(height: screenHeight / 40),
                    Warning(
                      color: AppColor.disabled,
                      message:
                          "Importante: insira o seu nome e sobrenome completo como está nos seus documentos de identificação. Você não poderá alterá-lo depois.",
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputText(
                      autoFocus: true,
                      focusNode: nameFocusNode,
                      onSubmittedCallback: (String name) {
                        nameFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(surnameFocusNode);
                      },
                      hintText: "nome",
                      controller: nameTextEditingController,
                      maxLines: 1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(32),
                        FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z|\s]"))
                      ],
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputText(
                      focusNode: surnameFocusNode,
                      hintText: "sobrenome completo",
                      controller: surnameTextEditingController,
                      maxLines: 1,
                      inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    ),
                    SizedBox(height: screenHeight / 40),
                    Spacer(),
                    Row(
                      children: [
                        Spacer(),
                        CircularButton(
                          buttonColor: circularButtonColor,
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressedCallback: circularButtonCallback == null
                              ? () {}
                              : () => buttonCallback(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
