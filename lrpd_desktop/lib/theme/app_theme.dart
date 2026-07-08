import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondoOscuro,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.naranja,
        secondary: AppColors.amarillo,
        error: AppColors.error,
        surface: AppColors.fondoCard,
        onSurface: AppColors.textoPri,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoOscuro,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textoPri,
        titleTextStyle: TextStyle(
          color: AppColors.textoPri,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textoPri,
        displayColor: AppColors.textoPri,
      ).copyWith(
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.textoPri,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textoPri,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textoSec,
          height: 1.4,
        ),
        labelSmall: const TextStyle(
          color: AppColors.textoMuted,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fondoField,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.naranja, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textoSec),
        hintStyle: const TextStyle(color: AppColors.textoMuted),
      ),
      // Nota: si tu versión de Flutter da error en "CardThemeData",
      // cámbialo por "CardTheme" (el nombre cambió entre versiones recientes).
      cardTheme: CardThemeData(
        color: AppColors.fondoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      dividerColor: AppColors.borde,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.fondoCard,
        indicatorColor: AppColors.amberBg,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final seleccionado = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            color: seleccionado ? AppColors.amarillo : AppColors.textoSec,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final seleccionado = states.contains(MaterialState.selected);
          return IconThemeData(
            color: seleccionado ? AppColors.amarillo : AppColors.textoSec,
          );
        }),
      ),
    );
  }
}