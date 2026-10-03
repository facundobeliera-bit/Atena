// lib/ui/theme/atena_colors.dart
//
// Paleta de marca de ATENA.
//
// Identidad: la sabiduría clásica (Atenea, laureles, oro) llevada a una
// plataforma educativa moderna. Dos áreas con acento propio que comparten
// la misma estructura visual:
// - Alumnos      → azul (cercano, confiable)
// - Instituciones → violeta (institucional, sólido)
// - Marca        → índigo (punto medio del gradiente azul → violeta)
// El dorado (laurel) se reserva para destacados: planes, logros, avisos.

import 'package:flutter/material.dart';

/// Área de la app. Define el color de acento de cada pantalla.
enum AtenaRole { brand, alumno, institucion }

class AtenaColors {
  const AtenaColors._();

  // ---------------------------------------------------------------------------
  // Marca
  // ---------------------------------------------------------------------------
  static const Color blue = Color(0xFF2563EB);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color violet = Color(0xFF7C3AED);
  static const Color gold = Color(0xFFF5B83D);
  static const Color goldDeep = Color(0xFFA16207);

  /// Gradiente insignia (azul → violeta).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, indigo, violet],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient roleGradient(AtenaRole role) {
    switch (role) {
      case AtenaRole.alumno:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF6366F1)],
          stops: [0.0, 0.55, 1.0],
        );
      case AtenaRole.institucion:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF6366F1)],
          stops: [0.0, 0.55, 1.0],
        );
      case AtenaRole.brand:
        return brandGradient;
    }
  }

  static Color roleAccent(AtenaRole role) {
    switch (role) {
      case AtenaRole.alumno:
        return blue;
      case AtenaRole.institucion:
        return violet;
      case AtenaRole.brand:
        return indigo;
    }
  }

  // ---------------------------------------------------------------------------
  // Semánticos (estado de solicitudes, avisos, etc.)
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
  static const Color neutral = Color(0xFF64748B);

  // ---------------------------------------------------------------------------
  // Esquemas de color por área y brillo
  // ---------------------------------------------------------------------------
  static ColorScheme scheme(AtenaRole role, Brightness brightness) {
    return brightness == Brightness.dark ? _dark(role) : _light(role);
  }

  static ColorScheme _light(AtenaRole role) {
    final (
      primary,
      primaryContainer,
      onPrimaryContainer,
      fixedDim,
    ) = switch (role) {
      AtenaRole.alumno => (
        blue,
        const Color(0xFFDCE7FF),
        const Color(0xFF0B2A6B),
        const Color(0xFFB3CBFF),
      ),
      AtenaRole.institucion => (
        violet,
        const Color(0xFFEDE5FF),
        const Color(0xFF2E0F6B),
        const Color(0xFFD3C1FF),
      ),
      AtenaRole.brand => (
        indigo,
        const Color(0xFFE2E1FF),
        const Color(0xFF1E1A6B),
        const Color(0xFFC4C2FF),
      ),
    };

    return ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      primaryFixed: primaryContainer,
      primaryFixedDim: fixedDim,
      onPrimaryFixed: onPrimaryContainer,
      onPrimaryFixedVariant: primary,
      secondary: const Color(0xFF4B5A7A),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE3E8F3),
      onSecondaryContainer: const Color(0xFF1C2742),
      tertiary: goldDeep,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFF1CC),
      onTertiaryContainer: const Color(0xFF4A3204),
      error: danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF51607A),
      surfaceDim: const Color(0xFFDCE1EC),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF4F6FB),
      surfaceContainer: const Color(0xFFEEF1F8),
      surfaceContainerHigh: const Color(0xFFE7EBF4),
      surfaceContainerHighest: const Color(0xFFE0E5F0),
      outline: const Color(0xFFB9C2D6),
      outlineVariant: const Color(0xFFDFE4EE),
      shadow: const Color(0xFF0B1226),
      scrim: const Color(0xFF0B1226),
      inverseSurface: const Color(0xFF1B2337),
      onInverseSurface: const Color(0xFFEEF1F8),
      inversePrimary: fixedDim,
      surfaceTint: Colors.transparent,
    );
  }

  static ColorScheme _dark(AtenaRole role) {
    final (
      primary,
      onPrimary,
      primaryContainer,
      onPrimaryContainer,
    ) = switch (role) {
      AtenaRole.alumno => (
        const Color(0xFF86AEFF),
        const Color(0xFF07204F),
        const Color(0xFF1C3C86),
        const Color(0xFFDCE7FF),
      ),
      AtenaRole.institucion => (
        const Color(0xFFBDA4FF),
        const Color(0xFF250B5E),
        const Color(0xFF4C2A9E),
        const Color(0xFFEDE5FF),
      ),
      AtenaRole.brand => (
        const Color(0xFFA5A2FF),
        const Color(0xFF17145A),
        const Color(0xFF3730A3),
        const Color(0xFFE2E1FF),
      ),
    };

    return ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      primaryFixed: onPrimaryContainer,
      primaryFixedDim: primary,
      onPrimaryFixed: onPrimary,
      onPrimaryFixedVariant: primaryContainer,
      secondary: const Color(0xFFAEBBD8),
      onSecondary: const Color(0xFF17213A),
      secondaryContainer: const Color(0xFF29344F),
      onSecondaryContainer: const Color(0xFFDCE3F3),
      tertiary: gold,
      onTertiary: const Color(0xFF3D2900),
      tertiaryContainer: const Color(0xFF5A4110),
      onTertiaryContainer: const Color(0xFFFFE7B0),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF5F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
      surface: const Color(0xFF111726),
      onSurface: const Color(0xFFE8EBF4),
      onSurfaceVariant: const Color(0xFFA4AEC4),
      surfaceDim: const Color(0xFF0A0F1C),
      surfaceBright: const Color(0xFF2A3247),
      surfaceContainerLowest: const Color(0xFF0A0F1C),
      surfaceContainerLow: const Color(0xFF151C2D),
      surfaceContainer: const Color(0xFF1A2235),
      surfaceContainerHigh: const Color(0xFF212A3F),
      surfaceContainerHighest: const Color(0xFF29334A),
      outline: const Color(0xFF4A5672),
      outlineVariant: const Color(0xFF2C3650),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFE8EBF4),
      onInverseSurface: const Color(0xFF1B2337),
      inversePrimary: roleAccent(role),
      surfaceTint: Colors.transparent,
    );
  }

  /// Fondo general de la app (un tono por debajo de las tarjetas).
  static Color canvas(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF0B101D) : const Color(0xFFF5F7FC);
}

/// Colores de estado con variantes de fondo/texto para chips y banners.
class AtenaTone {
  final Color color;
  final Color background;
  final Color foreground;

  const AtenaTone(this.color, this.background, this.foreground);

  static AtenaTone of(BuildContext context, Color base) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AtenaTone(
      base,
      base.withValues(alpha: dark ? 0.20 : 0.12),
      dark
          ? Color.lerp(base, Colors.white, 0.45)!
          : Color.lerp(base, Colors.black, 0.25)!,
    );
  }
}
