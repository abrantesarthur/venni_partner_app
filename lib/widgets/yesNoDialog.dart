import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class YesNoDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onPressedNo; // defaults to Navigator.pop(context)
  final VoidCallback onPressedYes;

  YesNoDialog({
    @required this.title,
    this.content,
    @required this.onPressedYes,
    this.onPressedNo,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content != null
          ? Text(
              content,
              style: TextStyle(color: AppColor.disabled),
            )
          : null,
      actions: [
        TextButton(
          child: Text(
            "não",
            style: TextStyle(fontSize: 18),
          ),
          onPressed: onPressedNo ??
              () {
                Navigator.pop(context);
              },
        ),
        TextButton(
          child: Text(
            "sim",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
          ),
          onPressed: onPressedYes,
        ),
      ],
    );
  }
}
