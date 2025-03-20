import 'package:flutter/material.dart';

class GoBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData? icon;

  GoBackButton({required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Icon(
        icon ?? Icons.arrow_back,
        size: 36,
      ),
      onTap: onPressed,
    );
  }
}
