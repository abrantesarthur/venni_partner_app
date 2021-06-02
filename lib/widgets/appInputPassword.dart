import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/widgets/appInputText.dart';

// TODO: test changes
class AppInputPassword extends StatefulWidget {
  final bool enabled;
  final bool obscurePassword;
  final TextEditingController controller;
  final bool autoFocus;
  final String hintText;
  final FocusNode focusNode;
  final Function onSubmittedCallback;

  AppInputPassword({
    @required this.controller,
    this.enabled,
    this.obscurePassword,
    this.autoFocus,
    this.hintText,
    this.focusNode,
    this.onSubmittedCallback,
  });

  AppInputPasswordState createState() => AppInputPasswordState();
}

class AppInputPasswordState extends State<AppInputPassword> {
  bool obscurePassword;
  TextEditingController controller;
  IconData _endIconData;

  @override
  void initState() {
    obscurePassword = widget.obscurePassword ?? true;
    controller = widget.controller;
    _endIconData = (obscurePassword != null)
        ? Icons.remove_red_eye_outlined
        : Icons.remove_red_eye;

    super.initState();
  }

  void _toggleObscurePassword() {
    setState(() {
      if (obscurePassword) {
        _endIconData = Icons.remove_red_eye;
        obscurePassword = false;
      } else {
        _endIconData = Icons.remove_red_eye_outlined;
        obscurePassword = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppInputText(
      autoFocus: widget.autoFocus ?? false,
      enabled: widget.enabled,
      iconData: Icons.lock,
      endIcon: _endIconData,
      endIconOnTapCallback: _toggleObscurePassword,
      focusNode: widget.focusNode,
      hintText: widget.hintText ?? "senha",
      controller: controller,
      obscureText: obscurePassword,
      maxLines: 1,
      inputFormatters: [LengthLimitingTextInputFormatter(28)],
      onSubmittedCallback: widget.onSubmittedCallback,
    );
  }
}
