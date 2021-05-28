import 'package:flutter/material.dart';

class OverallPadding extends StatelessWidget {
  final Widget child;
  final double bottom;
  final double top;
  final double left;
  final double right;

  OverallPadding({
    @required this.child,
    this.bottom,
    this.top,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        left: left ?? width / 15,
        right: right ?? width / 15,
        top: top ?? height / 15,
        bottom: bottom ?? height / 15,
      ),
      child: child,
    );
  }
}
