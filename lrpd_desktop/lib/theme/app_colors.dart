import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Acento
  static const amarillo = Color(0xFFF9D423);
  static const naranja  = Color(0xFFF5A623);
  static const rojo     = Color(0xFFE94F37);

  // Superficies
  static const fondoOscuro  = Color(0xFF1C1008);
  static const fondoCard    = Color(0xFF2A1A0A);
  static const fondoField   = Color(0xFF3A2510);
  static const fondoHi      = Color(0xFF331A08);
  static const blancoCalido = Color(0xFFFFFBF0);

  // Bordes
  static const borde   = Color(0xFF4A2E10);
  static const bordeHi = Color(0xFF6A3E18);

  // Texto
  static const textoPri   = Color(0xFFFFFBF0);
  static const textoSec   = Color(0xFFAA8866);
  static const textoMuted = Color(0xFF6A4A28);

  // Semánticos
  static const exito   = Color(0xFF34C27B);
  static const exitoBg = Color(0x1A34C27B);
  static const error   = Color(0xFFE94F37);
  static const errorBg = Color(0x1AE94F37);
  static const amberBg = Color(0x1AF5A623);

  static const gradienteAccent = LinearGradient(
    colors: [amarillo, naranja, rojo],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const dFast = Duration(milliseconds: 150);
  static const dMed  = Duration(milliseconds: 280);
}