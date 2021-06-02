import 'package:flutter/material.dart';

class ArrowBackButton extends StatelessWidget {
  final VoidCallback onTapCallback;

  ArrowBackButton({@required this.onTapCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCallback,
      child: Icon(
        Icons.arrow_back,
        size: 38,
      ),
    );
  }
}
