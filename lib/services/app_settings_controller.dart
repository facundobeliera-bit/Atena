// lib/services/app_settings_controller.dart
//
// Estado global de preferencias de la app (idioma y tema).
// Cualquier pantalla puede cambiarlas; MaterialApp escucha este controlador.

import 'package:flutter/material.dart';

import 'app_settings_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();
  static final AppSettingsController instance = AppSettingsController._();

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  /// null = idioma del sistema.
  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  void init({Locale? locale, ThemeMode themeMode = ThemeMode.system}) {
    _locale = locale;
    _themeMode = themeMode;
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    await AppSettingsService.saveLocale(locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await AppSettingsService.saveThemeMode(mode);
  }
}
