import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/warning.dart';

class PasswordWarning extends StatelessWidget {
  final bool isValid;
  final String message;

  PasswordWarning({@required this.isValid, @required this.message});

  @override
  Widget build(BuildContext context) {
    Color color = isValid ? AppColor.secondaryGreen : Colors.black;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Icon(
          isValid ? Icons.stop : Icons.crop_square_sharp,
          size: 16,
          color: color,
        ),
      ),
      Warning(
        message: message,
        color: color,
      ),
    ]);
  }
}
