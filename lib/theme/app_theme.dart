import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3949AB);
  static const primarySoft = Color(0xFFE8EAF6);
  static const background = Color(0xFFF4F5FA);
  static const border = Color(0xFFE3E5EF);
  static const textMuted = Color(0xFF6B7280);
  static const danger = Color(0xFFC62828);
  static const dangerSoft = Color(0xFFFDECEC);
  static const warning = Color(0xFFEF6C00);
  static const warningSoft = Color(0xFFFFF3E0);
  static const success = Color(0xFF2E7D32);
  static const successSoft = Color(0xFFE8F5E9);
}

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24;
}

class AppTheme {
  static final _shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  static const _padding = EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  static const _label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: _padding,
          shape: _shape,
          textStyle: _label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 44),
          padding: _padding,
          shape: _shape,
          textStyle: _label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: _label),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        extendedSizeConstraints: BoxConstraints.tightFor(height: 44),
        extendedPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

/// Decoração padrão dos campos de texto do app.
InputDecoration appInputDecoration({
  required String label,
  IconData? icon,
  Widget? suffix,
  String? hint,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary),
  );
}