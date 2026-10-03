// lib/routes/atena_router.dart
//
// Rutas con nombre de ATENA.
// - Pantallas de acceso: registro y recuperación de contraseña.
// - Deeplinks web (/calendario, /documentos): siempre pasan por la puerta de
//   sesión; nunca se abren datos solo con los ids de la URL.
// - Cualquier otra ruta vuelve al inicio que corresponda a la sesión.

import 'package:flutter/material.dart';

import '../screens/auth/alumno_forgot_password_page.dart';
import '../screens/auth/alumno_registro_page.dart';
import '../screens/auth/institucion_forgot_password_page.dart';
import 'atena_boot_gate.dart';
import 'atena_deeplink.dart';

class AtenaRouter {
  const AtenaRouter._();

  static String _path(String raw) {
    var n = raw.trim();
    if (n.startsWith('#')) n = n.substring(1);
    if (n.isNotEmpty && !n.startsWith('/')) n = '/$n';
    final q = n.indexOf('?');
    if (q >= 0) n = n.substring(0, q);
    return n.isEmpty ? '/' : n;
  }

  static String? _email(Object? args) {
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final v = (args['initialEmail'] ?? '').toString().trim();
      return v.isEmpty ? null : v;
    }
    return null;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final raw = (settings.name ?? '/').trim();
    final path = _path(raw);

    switch (path) {
      case '/alumno_forgot_password':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AlumnoForgotPasswordPage(
            initialEmail: _email(settings.arguments),
          ),
        );
      case '/institucion_forgot_password':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => InstitucionForgotPasswordPage(
            initialEmail: _email(settings.arguments),
          ),
        );
      case '/alumno_registro':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              AlumnoRegistroPage(initialEmail: _email(settings.arguments)),
        );
    }

    String? deeplink;
    try {
      final dl = AtenaDeeplink.parse(
        raw.startsWith('#') ? raw.substring(1) : raw,
      );
      if (dl.isCalendario || dl.isDocumentos) {
        final out = dl.toRouteString().trim();
        deeplink = out.isEmpty ? null : out;
      }
    } catch (_) {
      deeplink = null;
    }

    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => AtenaBootGate(deeplink: deeplink),
    );
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => const AtenaBootGate(),
    );
  }
}
