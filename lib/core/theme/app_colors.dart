import 'package:flutter/material.dart';

/// Paleta de la aplicación: negro + naranja con acentos neón.
///
/// Todas las constantes son `const` para que el motor de Flutter pueda
/// reutilizar las instancias sin asignar memoria en cada `build`.
abstract final class AppColors {
  // ── Fondos ──────────────────────────────────────────────────────────────
  /// Negro base de la app.
  static const Color background = Color(0xFF08080A);

  /// Superficie de tarjetas y campos.
  static const Color surface = Color(0xFF121216);

  /// Superficie elevada (diálogos, campos enfocados).
  static const Color surfaceHigh = Color(0xFF1B1B21);

  /// Bordes sutiles sobre fondo negro.
  static const Color border = Color(0xFF26262E);

  // ── Naranja / neón ──────────────────────────────────────────────────────
  /// Naranja principal de marca.
  static const Color orange = Color(0xFFFF6B1A);

  /// Naranja profundo, para degradados.
  static const Color orangeDeep = Color(0xFFE1490B);

  /// Naranja neón, para brillos y estados activos.
  static const Color orangeNeon = Color(0xFFFF9E2C);

  /// Acento neón frío, usado con moderación (métricas, badges).
  static const Color cyanNeon = Color(0xFF22E0D6);

  // ── Semánticos ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2BE08C);
  static const Color warning = Color(0xFFFFC531);
  static const Color danger = Color(0xFFFF3B5C);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA0A0AD);
  static const Color textDisabled = Color(0xFF5E5E6B);

  /// Degradado de marca usado en botones y encabezados.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[orangeNeon, orange, orangeDeep],
  );

  /// Resplandor neón reutilizable. [opacity] controla la intensidad.
  static List<BoxShadow> glow(
    Color color, {
    double blur = 24,
    double spread = 0,
    double opacity = 0.45,
  }) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: spread,
    ),
  ];
}
