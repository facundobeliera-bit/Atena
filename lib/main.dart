// lib/main.dart
//
// ATENA – raíz de la aplicación.
//
// 1) Carga preferencias (idioma y tema).
// 2) Abre la puerta de sesión (AtenaBootGate), que decide el inicio:
//    familia, institución o bienvenida.
// En web, una URL /calendario o /documentos se aplica después de validar la
// sesión.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'routes/atena_boot_gate.dart';
import 'routes/atena_router.dart';
import 'services/app_settings_controller.dart';
import 'services/app_settings_service.dart';
import 'ui/atena_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Locale? initialLocale;
  var initialThemeMode = ThemeMode.system;
  try {
    initialLocale = await AppSettingsService.loadLocale();
  } catch (_) {}
  try {
    initialThemeMode = await AppSettingsService.loadThemeMode();
  } catch (_) {}

  AppSettingsController.instance.init(
    locale: initialLocale,
    themeMode: initialThemeMode,
  );

  runApp(const AtenaApp());
}

class AtenaApp extends StatelessWidget {
  const AtenaApp({super.key});

  /// Ruta inicial pedida por la URL (solo web).
  static String? _initialRoute() {
    if (!kIsWeb) return null;
    try {
      final u = Uri.base;
      if (u.fragment.trim().isNotEmpty) return u.fragment.trim();
      final path = u.path.trim();
      if (path.isEmpty || path == '/') return null;
      return path + (u.hasQuery ? '?${u.query}' : '');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ATENA',
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          themeMode: settings.themeMode,
          theme: AtenaTheme.light(),
          darkTheme: AtenaTheme.dark(),
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          onGenerateInitialRoutes: (_) {
            final route = _initialRoute();
            if (route != null) {
              return [AtenaRouter.onGenerateRoute(RouteSettings(name: route))];
            }
            return [
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/'),
                builder: (_) => const AtenaBootGate(),
              ),
            ];
          },
          onGenerateRoute: AtenaRouter.onGenerateRoute,
          onUnknownRoute: AtenaRouter.onUnknownRoute,
        );
      },
    );
  }
}
