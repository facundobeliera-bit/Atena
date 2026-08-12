// lib/main.dart
//
// ATENA – APP ROOT (CANÓNICO)
//
// FIX PERSISTENCIA (agosto 2026):
// - Inicializa el bootstrap de persistencia local antes del routing.
// - No cambia el contrato de sesión ni el routing por rol.
// - La rehidratación es best-effort y no bloquea el arranque si Storage falla.
//
// Boot canónico por rol:
//   * role=institucion -> InstitucionMenuPage (directo)
//   * role=cuenta      -> CuentaHomePage (hub de perfiles)
//   * sin sesión       -> LandingPage
//
// Los deeplinks (/calendario, /documentos) siguen entrando por Router.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';

import 'services/app_settings_service.dart';
import 'services/atena_data_bootstrap_service.dart';
import 'services/cuenta_service.dart';
import 'services/session_service.dart';

import 'screens/landing/landing_page.dart';
import 'screens/cuentas/cuenta_home_page.dart';
import 'screens/instituciones/institucion_menu_page.dart';

import 'routes/atena_router.dart';
import 'routes/atena_deeplink.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistencia local: preparar/reconstruir índices antes del primer consumo
  // de datos de la UI. Es best-effort y no impide iniciar Atena ante un fallo.
  try {
    await AtenaDataBootstrapService.instance.initialize();
  } catch (_) {}

  Locale? initialLocale;
  ThemeMode initialThemeMode = ThemeMode.system;

  try {
    initialLocale = await AppSettingsService.loadLocale();
  } catch (_) {
    initialLocale = null;
  }

  try {
    initialThemeMode = await AppSettingsService.loadThemeMode();
  } catch (_) {
    initialThemeMode = ThemeMode.system;
  }

  runApp(
    AtenaApp(initialLocale: initialLocale, initialThemeMode: initialThemeMode),
  );
}

class AtenaApp extends StatefulWidget {
  final Locale? initialLocale;
  final ThemeMode initialThemeMode;

  const AtenaApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  @override
  State<AtenaApp> createState() => _AtenaAppState();
}

class _AtenaAppState extends State<AtenaApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  String? _initialDeeplink;

  static const Color _seedLight = Color(0xFF3B82F6);
  static const Color _seedDark = Color(0xFF7C3AED);

  static final List<Locale> _supportedLocales = AppLocalizations
      .supportedLocales
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;
    _initialDeeplink = _readInitialDeeplinkBestEffort();
  }

  String? _readInitialDeeplinkBestEffort() {
    try {
      final u = Uri.base;
      String candidate = '';

      if (u.fragment.trim().isNotEmpty) {
        candidate = u.fragment.startsWith('/') ? u.fragment : '/${u.fragment}';
        candidate = candidate.trim();
      } else {
        final path = u.path.trim();
        if (path != '/calendario' &&
            path != '/documentos' &&
            !path.startsWith('/calendario/') &&
            !path.startsWith('/documentos/')) {
          return null;
        }

        candidate = path + (u.hasQuery ? '?${u.query}' : '');
      }

      if (candidate.isEmpty) return null;

      final dl = AtenaDeeplink.parse(candidate);
      if (!(dl.isCalendario || dl.isDocumentos)) return null;

      final out = dl.toRouteString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Route<dynamic> _routeBootRoot() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => _AtenaBootGate(
        locale: _locale,
        themeMode: _themeMode,
        onLocaleChanged: _onLocaleChanged,
        onThemeModeChanged: _onThemeModeChanged,
      ),
    );
  }

  Route<dynamic> _safeRouteForName(String name) {
    final n = name.trim();
    if (n.isEmpty || n == '/') {
      return _routeBootRoot();
    }
    return AtenaRouter.onGenerateRoute(RouteSettings(name: n));
  }

  Future<void> _onLocaleChanged(Locale? l) async {
    if (mounted) setState(() => _locale = l);
    try {
      await AppSettingsService.saveLocale(l);
    } catch (_) {}
  }

  Future<void> _onThemeModeChanged(ThemeMode m) async {
    if (mounted) setState(() => _themeMode = m);
    try {
      await AppSettingsService.saveThemeMode(m);
    } catch (_) {}
  }

  ThemeData _buildTheme({required Brightness brightness, required Color seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ATENA',

      themeMode: _themeMode,
      theme: _buildTheme(brightness: Brightness.light, seed: _seedLight),
      darkTheme: _buildTheme(brightness: Brightness.dark, seed: _seedDark),

      locale: _locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // Deeplink “duro” (web): si la URL es /calendario o /documentos,
      // respetamos Router. Si no hay deeplink, arrancamos en BootGate.
      onGenerateInitialRoutes: (initialRoute) {
        final dl = (_initialDeeplink ?? '').trim();
        if (dl.isNotEmpty && dl != '/') {
          return <Route<dynamic>>[_safeRouteForName(dl)];
        }
        return <Route<dynamic>>[_routeBootRoot()];
      },

      onGenerateRoute: AtenaRouter.onGenerateRoute,
      onUnknownRoute: AtenaRouter.onUnknownRoute,
    );
  }
}

// =====================================================
// BOOT GATE (CANÓNICO)
// - Decide pantalla inicial según sesión + rol.
// - Institución NUNCA entra a CuentaHomePage.
// =====================================================
class _AtenaBootGate extends StatefulWidget {
  final Locale? locale;
  final ThemeMode themeMode;
  final Future<void> Function(Locale?) onLocaleChanged;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  const _AtenaBootGate({
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  @override
  State<_AtenaBootGate> createState() => _AtenaBootGateState();
}

class _AtenaBootGateState extends State<_AtenaBootGate> {
  bool _running = false;

  static String _s(String? v) => (v ?? '').trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _run();
    });
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    final nav = Navigator.of(context);

    try {
      // Session v2 (userId + role) – fuente real para perfil en modo institución.
      SessionData? session;
      try {
        session = await SessionService.getSession();
      } catch (_) {
        session = null;
      }

      if (session == null) {
        if (!mounted) return;
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => LandingPage(
              locale: widget.locale,
              themeMode: widget.themeMode,
              onLocaleChanged: widget.onLocaleChanged,
              onThemeModeChanged: widget.onThemeModeChanged,
              deeplink: null,
            ),
          ),
        );
        return;
      }

      final role = session.role;
      final userId = _s(session.userId);

      // Sesión canónica de cuenta (CuentaService: sesion_cuenta).
      String? cuentaId;
      try {
        cuentaId = await CuentaService.getSesionCuentaId();
      } catch (_) {
        cuentaId = null;
      }
      var ownerAccountId = _s(cuentaId);

      if (role == SessionRole.institucion) {
        // Institución:
        // - institucionPerfilId = SessionService.userId
        // - ownerAccountId = sesion_cuenta (si falta, instOwner best-effort)
        if (ownerAccountId.isEmpty) {
          try {
            ownerAccountId = _s(
              await SessionService.getInstitucionOwnerAccountIdLogueado(),
            );
          } catch (_) {
            ownerAccountId = '';
          }
        }

        // Sin datos mínimos, no inventamos: volvemos a Landing (login).
        if (!mounted) return;
        if (userId.isEmpty || ownerAccountId.isEmpty) {
          nav.pushReplacement(
            MaterialPageRoute(
              builder: (_) => LandingPage(
                locale: widget.locale,
                themeMode: widget.themeMode,
                onLocaleChanged: widget.onLocaleChanged,
                onThemeModeChanged: widget.onThemeModeChanged,
                deeplink: null,
              ),
            ),
          );
          return;
        }

        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => InstitucionMenuPage(
              ownerAccountId: ownerAccountId,
              institucionPerfilId: userId,
              institucionNombre: null,
            ),
          ),
        );
        return;
      }

      // Cuenta: si no hay ownerAccountId, no podemos operar como cuenta.
      if (ownerAccountId.isEmpty) {
        if (!mounted) return;
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => LandingPage(
              locale: widget.locale,
              themeMode: widget.themeMode,
              onLocaleChanged: widget.onLocaleChanged,
              onThemeModeChanged: widget.onThemeModeChanged,
              deeplink: null,
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              CuentaHomePage(cuentaId: ownerAccountId, initialDeeplink: null),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => LandingPage(
            locale: widget.locale,
            themeMode: widget.themeMode,
            onLocaleChanged: widget.onLocaleChanged,
            onThemeModeChanged: widget.onThemeModeChanged,
            deeplink: null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
