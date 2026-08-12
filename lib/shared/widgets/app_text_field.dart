import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Themed TextField wrapper with label/hint/error support, plus optional
/// prefix icon, input formatters, and capitalization.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.keyboardType,
    this.prefixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
