import 'package:flutter/material.dart';

class CircularButton extends StatelessWidget {
  final Color buttonColor;
  final Function onPressedCallback;
  final Widget child;

  CircularButton({
    required this.buttonColor,
    this.onPressedCallback,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressedCallback,
      color: buttonColor,
      shape: CircleBorder(),
      padding: EdgeInsets.all(20),
      child: child,
    );
  }
}
