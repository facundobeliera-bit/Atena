// lib/ui/atena_assets.dart
//
// ATENA – ASSETS (rutas centralizadas)
//
// Regla de oro:
// - Todo lo que figure acá DEBE existir exactamente igual en /assets/visual
// - Nunca concatenar "assets/" a mano en la UI
// - Usar SIEMPRE estas constantes
//
// HARDENING:
// - ensureCanonical(...) evita casos de "assets/assets/..."
// - Normaliza "\" -> "/"
// - Colapsa duplicaciones
// - Corrige paths relativos comunes
//
// Web fullscreen:
// - backgroundForRole fuerza cover + infinity
// - errorBuilder con fallback a color surface

import 'package:flutter/material.dart';

enum AtenaBackgroundRole {
  alumno,
  institucion,
  landing,
  institucionSelector,

  /// Reutiliza fondo institucional (NO crea uno nuevo)
  institucionPerfil,
}

class AtenaAssets {
  const AtenaAssets._();

  // =====================================================
  // ROOT
  // =====================================================

  static const String _root = 'assets/visual';

  static bool _hasKnownExt(String p) {
    final s = p.toLowerCase();
    return s.endsWith('.png') ||
        s.endsWith('.jpg') ||
        s.endsWith('.jpeg') ||
        s.endsWith('.webp') ||
        s.endsWith('.gif') ||
        s.endsWith('.json') ||
        s.endsWith('.svg');
  }

  static String ensureCanonical(String path) {
    var p = path.trim();
    if (p.isEmpty) return p;

    // Windows -> POSIX
    p = p.replaceAll('\\', '/');

    while (p.startsWith('/')) {
      p = p.substring(1);
    }

    while (p.contains('//')) {
      p = p.replaceAll('//', '/');
    }

    while (p.startsWith('assets/assets/')) {
      p = p.substring('assets/'.length);
    }

    if (p.startsWith('visual/')) {
      p = 'assets/$p';
    }

    if (p == _root) {
      p = '$_root/';
    }

    while (p.startsWith('assets/visual/visual/')) {
      p = p.replaceFirst('assets/visual/visual/', 'assets/visual/');
    }

    if (p.startsWith('assets/') || p.startsWith('packages/')) {
      return p;
    }

    final looksRelativeToVisual =
        p.startsWith('backgrounds/') ||
        p.startsWith('logos/') ||
        p.startsWith('splash/') ||
        p.startsWith('states/') ||
        p.startsWith('ui/') ||
        p.startsWith('illustrations/') ||
        p.startsWith('icons/') ||
        p.startsWith('overlays/') ||
        p.startsWith('panels/');

    if (looksRelativeToVisual) {
      return '$_root/$p';
    }

    final looksExternal =
        p.contains('://') || p.startsWith('data:') || p.startsWith('file:');

    if (!looksExternal && _hasKnownExt(p)) {
      return '$_root/$p';
    }

    return p;
  }

  // =====================================================
  // SPLASH
  // =====================================================

  static const String splashBg = '$_root/splash/splash_bg.png';

  static const String splashIcon = '$_root/splash/splash_icon.png';

  // =====================================================
  // BACKGROUNDS
  // =====================================================

  static const String bgAlumnoHome = '$_root/backgrounds/bg_alumno_home.png';

  static const String bgInstitucionHome =
      '$_root/backgrounds/bg_institucion_home.png';

  static const String bgLandingAtena =
      '$_root/backgrounds/bg_landing_atena.png';

  static const String bgInstitucionSelector =
      '$_root/backgrounds/bg_institucion_selector.png';

  // =====================================================
  // LOGOS / ICONS
  // =====================================================

  static const String logoPrimary = '$_root/logos/logo_atena_primary.png';

  static const String logoWhite = '$_root/logos/logo_atena_white.png';

  static const String logoDark = '$_root/logos/logo_atena_dark.png';

  static const String iconWhite = '$_root/logos/icon_atena_white.png';

  static const String iconDark = '$_root/logos/icon_atena_dark.png';

  // =====================================================
  // STATES
  // =====================================================

  static const String stateEmpty = '$_root/states/state_empty.png';

  static const String stateLoading = '$_root/states/state_loading.png';

  static const String stateSuccess = '$_root/states/state_success.png';

  static const String stateError = '$_root/states/state_error.png';

  // =====================================================
  // UI
  // =====================================================

  static const String dividerWaveBlue = '$_root/ui/divider_wave_blue.png';

  static const String dividerWavePurple = '$_root/ui/divider_wave_purple.png';

  static const String cardShadowSoft = '$_root/ui/card_shadow_soft.png';

  static const String highlightGlow = '$_root/ui/highlight_glow.png';

  // =====================================================
  // ILLUSTRATIONS
  // =====================================================

  static const String illEmptyGeneric =
      '$_root/illustrations/empty_generic.png';

  static const String illEmptySearch = '$_root/illustrations/empty_search.png';

  static const String illMaintenance = '$_root/illustrations/maintenance.png';

  // =====================================================
  // BACKGROUND HELPERS (CANÓNICO)
  // =====================================================

  static String backgroundPathForRole(AtenaBackgroundRole role) {
    switch (role) {
      case AtenaBackgroundRole.alumno:
        return bgAlumnoHome;

      case AtenaBackgroundRole.institucion:
        return bgInstitucionHome;

      case AtenaBackgroundRole.landing:
        return bgLandingAtena;

      case AtenaBackgroundRole.institucionSelector:
        return bgInstitucionSelector;

      case AtenaBackgroundRole.institucionPerfil:
        // ✅ Reutiliza fondo institucional
        return bgInstitucionHome;
    }
  }

  static Widget backgroundForRole(
    BuildContext context, {
    required AtenaBackgroundRole role,
  }) {
    final cs = Theme.of(context).colorScheme;
    final path = ensureCanonical(backgroundPathForRole(role));

    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return SizedBox.expand(child: ColoredBox(color: cs.surface));
          },
    );
  }
}
