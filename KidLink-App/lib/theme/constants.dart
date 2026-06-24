import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2563EB);
  static const Color navy = Color(0xFF0F172A);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color hintText = Color(0xFF94A3B8);

  static const double inputRadius = 16;
  static const double cardRadius = 20;
  static const double buttonHeight = 56;

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: inputFill,
      labelStyle: const TextStyle(color: navy, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: hintText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static ButtonStyle primaryButton() {
    return FilledButton.styleFrom(
      backgroundColor: primary,
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle outlineButton() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: const BorderSide(color: primary),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
