import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';

class OkDialog extends StatelessWidget {
  final String title;
  final String content;

  OkDialog({
    @required this.title,
    @required this.content,
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
              "ok",
              style: TextStyle(fontSize: 18),
            ),
            onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
