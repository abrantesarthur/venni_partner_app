import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_app/widgets/appInputText.dart';

class InputPhone extends StatelessWidget {
  final Function onSubmittedCallback;
  final TextEditingController controller;
  final bool enabled;
  final FocusNode focusNode;
  final int maxLines;

  InputPhone({
    this.onSubmittedCallback,
    this.controller,
    this.enabled,
    this.focusNode,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return AppInputText(
      maxLines: maxLines,
      enabled: enabled,
      autoFocus: true,
      hintText: "(##) #####-####",
      iconData: Icons.phone,
      onSubmittedCallback: onSubmittedCallback,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [
        LengthLimitingTextInputFormatter(15),
        FilteringTextInputFormatter.digitsOnly,
        _BrNumberTextInputFormatter(),
      ],
    );
  }
}

/// Format incoming numeric text to fit the format of (##) #####-####
/// TODO: use MaskedInputFormatter instead
class _BrNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;
    final StringBuffer newText = StringBuffer();
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1) selectionIndex++;
    }
    if (newTextLength >= 3) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 2) + ') ');
      if (newValue.selection.end >= 3) selectionIndex += 2;
    }
    if (newTextLength >= 8) {
      newText.write(newValue.text.substring(2, usedSubstringIndex = 7) + '-');
      if (newValue.selection.end >= 7) selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex)
      newText.write(newValue.text.substring(usedSubstringIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
