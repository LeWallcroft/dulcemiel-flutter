import 'package:flutter/material.dart';

abstract final class DulceMielColors {
  static const miel = Color(0xFF8A620C);
  static const mielProfunda = Color(0xFF634500);
  static const dorado = Color(0xFFE2B64B);
  static const crema = Color(0xFFFFF8EE);
  static const superficie = Color(0xFFFFFFFF);
  static const tinta = Color(0xFF302B24);
  static const secundaria = Color(0xFF766F65);
  static const hoja = Color(0xFF4F7753);
  static const borde = Color(0xFFE9DFD0);
}

ThemeData buildDulceMielTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DulceMielColors.miel,
    brightness: Brightness.light,
    primary: DulceMielColors.miel,
    secondary: DulceMielColors.dorado,
    surface: DulceMielColors.superficie,
    error: const Color(0xFFB3261E),
  );
  final text = ThemeData.light().textTheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DulceMielColors.crema,
    appBarTheme: const AppBarTheme(
      backgroundColor: DulceMielColors.crema,
      foregroundColor: DulceMielColors.tinta,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: DulceMielColors.tinta,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.25,
      ),
      iconTheme: IconThemeData(color: DulceMielColors.mielProfunda),
    ),
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
        color: DulceMielColors.tinta,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
      titleLarge: text.titleLarge?.copyWith(
        color: DulceMielColors.tinta,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: text.titleMedium?.copyWith(
        color: DulceMielColors.tinta,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        color: DulceMielColors.tinta,
        height: 1.4,
      ),
      bodyMedium: text.bodyMedium?.copyWith(
        color: DulceMielColors.secundaria,
        height: 1.4,
      ),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: DulceMielColors.superficie,
      elevation: 1.5,
      shadowColor: DulceMielColors.mielProfunda.withValues(alpha: .08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DulceMielColors.borde),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: DulceMielColors.miel,
        foregroundColor: Colors.white,
        disabledBackgroundColor: DulceMielColors.miel.withValues(alpha: .35),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: DulceMielColors.mielProfunda,
        side: const BorderSide(color: DulceMielColors.borde),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: DulceMielColors.secundaria),
      hintStyle: TextStyle(
        color: DulceMielColors.secundaria.withValues(alpha: .75),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DulceMielColors.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DulceMielColors.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DulceMielColors.miel, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.6),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFFF1CE),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(
        color: DulceMielColors.mielProfunda,
        fontWeight: FontWeight.w700,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: DulceMielColors.tinta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(
      color: DulceMielColors.borde,
      thickness: 1,
    ),
  );
}
