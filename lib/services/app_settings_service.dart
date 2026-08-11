// lib/services/app_settings_service.dart
//
// ATENA – AppSettingsService (local prototipo)
// - Persistencia de preferencias simples (Locale / ThemeMode)
// - Hardening: nunca lanzar excepción al leer prefs (fallback seguro)
//
// NOTA:
// - Guardamos SOLO languageCode (es/en/pt) para evitar inconsistencias tipo es_AR.
// - Si el valor guardado no es válido, se ignora y se vuelve a fallback.
//
// HARDENING (fase 2):
// - API utilitaria: serialize/parse ThemeMode (single source of truth).
// - Método de soporte: isSupportedLanguageCode.
// - Writes idempotentes (evita escrituras innecesarias).
// - Nunca persiste valores fuera del set canónico.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  const AppSettingsService._();

  static const String _kLocale = 'atena_locale';
  static const String _kThemeMode = 'atena_theme_mode'; // system/light/dark

  // Fuente de verdad (debe coincidir con main.dart + AppLocalizations.supportedLocales)
  static const Set<String> supportedLanguageCodes = <String>{'es', 'en', 'pt'};

  static bool isSupportedLanguageCode(String? code) {
    final c = (code ?? '').trim().toLowerCase();
    return c.isNotEmpty && supportedLanguageCodes.contains(c);
  }

  static String? _normalizeLanguageCode(String? code) {
    final c = (code ?? '').trim().toLowerCase();
    if (c.isEmpty) return null;
    if (!supportedLanguageCodes.contains(c)) return null;
    return c;
  }

  // ---------------------------
  // Locale
  // ---------------------------

  static Future<Locale?> loadLocale() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = (sp.getString(_kLocale) ?? '').trim();
      if (raw.isEmpty) return null;

      final code = _normalizeLanguageCode(raw);
      if (code == null) return null;

      return Locale(code);
    } catch (_) {
      // Hardening: nunca romper arranque por prefs
      return null;
    }
  }

  static Future<void> saveLocale(Locale? locale) async {
    try {
      final sp = await SharedPreferences.getInstance();

      // Null => limpiar preferencia
      if (locale == null) {
        if (sp.containsKey(_kLocale)) {
          await sp.remove(_kLocale);
        }
        return;
      }

      // Normalizar y validar
      final code = _normalizeLanguageCode(locale.languageCode);
      if (code == null) {
        // Si viene algo raro, limpiamos (no persistimos basura)
        if (sp.containsKey(_kLocale)) {
          await sp.remove(_kLocale);
        }
        return;
      }

      // Idempotencia: no reescribir si ya está
      final current = (sp.getString(_kLocale) ?? '').trim().toLowerCase();
      if (current == code) return;

      await sp.setString(_kLocale, code);
    } catch (_) {
      // Hardening: no-op
    }
  }

  // ---------------------------
  // ThemeMode
  // ---------------------------

  static String themeModeToStorage(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
  }

  static ThemeMode themeModeFromStorage(String? raw) {
    final v = (raw ?? 'system').trim().toLowerCase();
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<ThemeMode> loadThemeMode() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kThemeMode);
      return themeModeFromStorage(raw);
    } catch (_) {
      // Hardening: fallback seguro
      return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = themeModeToStorage(mode);

      // Idempotencia: no reescribir si ya está
      final current = (sp.getString(_kThemeMode) ?? '').trim().toLowerCase();
      if (current == v) return;

      await sp.setString(_kThemeMode, v);
    } catch (_) {
      // Hardening: no-op
    }
  }
}
