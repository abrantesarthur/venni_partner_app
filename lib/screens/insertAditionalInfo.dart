import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/screens/insertPassword.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/overallPadding.dart';
import 'package:partner_app/widgets/warning.dart';

class InsertAditionalInfoArguments {
  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  InsertAditionalInfoArguments({
    @required this.userCredential,
    @required this.name,
    @required this.surname,
    @required this.userEmail,
  });
}

class InsertAditionalInfo extends StatefulWidget {
  static const String routeName = "InsertAditionalInfo";

  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  InsertAditionalInfo({
    @required this.userCredential,
    @required this.userEmail,
    @required this.name,
    @required this.surname,
  });

  @override
  InsertAditionalInfoState createState() => InsertAditionalInfoState();
}

class InsertAditionalInfoState extends State<InsertAditionalInfo> {
  TextEditingController cpfTextEditingController = TextEditingController();
  FocusNode cpfFocusNode = FocusNode();
  String cpf;
  bool cpfIsValid = true;
  Gender selectedGender;

  @override
  void initState() {
    super.initState();
    cpfTextEditingController.addListener(() {
      setState(() {
        cpf = cpfTextEditingController.text.getCleanedCPF();
        cpfIsValid = cpf.isValidCPF();
      });
    });
  }

  @override
  void dispose() {
    cpfTextEditingController.dispose();
    cpfFocusNode.dispose();
    super.dispose();
  }

  // buttonCallback checks whether email is valid and not already used.
  // it displays warning in case the email is invalid and redirects user
  // to next registration screen in case the email is valid.
  void buttonCallback(BuildContext context) async {
    Navigator.pushNamed(
      context,
      InsertPassword.routeName,
      arguments: InsertPasswordArguments(
        userCredential: widget.userCredential,
        name: widget.name,
        surname: widget.surname,
        userEmail: widget.userEmail,
        cpf: cpf,
        gender: selectedGender,
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
                      "Insira o seu cpf e gênero",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputText(
                      title: "CPF",
                      hintText: "000.000.000-00",
                      maxLines: 1,
                      autoFocus: true,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(14),
                        FilteringTextInputFormatter.digitsOnly,
                        MaskedInputFormatter(mask: "xxx.xxx.xxx-xx")
                      ],
                      keyboardType: TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      controller: cpfTextEditingController,
                      focusNode: cpfFocusNode,
                      onSubmittedCallback: (_) {
                        cpfFocusNode.unfocus();
                      },
                    ),
                    buildWarning(
                      fieldIsValid: cpfIsValid,
                      focusNode: cpfFocusNode,
                      controller: cpfTextEditingController,
                      whenEmpty: "insira um número de CPF",
                      whenFail: "CPF inválido",
                    ),
                    SizedBox(height: screenHeight / 40),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.04),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton(
                              value: selectedGender,
                              hint: Text(
                                "Gênero",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColor.disabled,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value;
                                });
                              },
                              items: Gender.values
                                  .map((g) => DropdownMenuItem(
                                        child: Text(g.toString().substring(7)),
                                        value: g,
                                      ))
                                  .toList()),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight / 40),
                    Spacer(),
                    Row(
                      children: [
                        Spacer(),
                        CircularButton(
                          buttonColor: allFieldsAreValid()
                              ? AppColor.primaryPink
                              : AppColor.disabled,
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressedCallback: allFieldsAreValid()
                              ? () => buttonCallback(context)
                              : () {},
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

  bool allFieldsAreValid() {
    return cpfIsValid &&
        cpfTextEditingController.text.isNotEmpty &&
        selectedGender != null;
  }
}

Widget buildWarning({
  @required bool fieldIsValid,
  @required FocusNode focusNode,
  @required TextEditingController controller,
  @required String whenEmpty,
  @required String whenFail,
}) {
  return (!fieldIsValid && !focusNode.hasFocus)
      ? controller.text.length == 0
          ? Warning(
              message: whenEmpty,
              color: AppColor.secondaryYellow,
            )
          : Warning(
              message: whenFail,
              color: AppColor.secondaryYellow,
            )
      : Container();
}
