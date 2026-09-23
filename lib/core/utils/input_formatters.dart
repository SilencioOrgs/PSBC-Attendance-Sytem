import 'package:flutter/services.dart';

class UppercaseSingleSpaceFormatter extends TextInputFormatter {
  const UppercaseSingleSpaceFormatter();

  String _format(String input) =>
      input.toUpperCase().replaceAll(RegExp(r' {2,}'), ' ');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _format(newValue.text);
    if (formatted == newValue.text) return newValue;
    final basePrefix = newValue.text.substring(
      0,
      newValue.selection.baseOffset.clamp(0, newValue.text.length),
    );
    final extentPrefix = newValue.text.substring(
      0,
      newValue.selection.extentOffset.clamp(0, newValue.text.length),
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: _format(basePrefix).length,
        extentOffset: _format(extentPrefix).length,
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}

class DigitsOnlyPinFormatter extends TextInputFormatter {
  const DigitsOnlyPinFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final offset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final cursor = newValue.text
        .substring(0, offset)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
