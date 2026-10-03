// lib/routes/atena_nav.dart
//
// Navegación de alto nivel: entrar a un inicio y cerrar sesión.
// Siempre limpia la pila para que "Atrás" no vuelva a pantallas de acceso.

import 'package:flutter/material.dart';

import '../screens/cuentas/cuenta_home_page.dart';
import '../screens/instituciones/institucion_menu_page.dart';
import '../screens/landing/landing_page.dart';
import '../services/auth_service.dart';

class AtenaNav {
  const AtenaNav._();

  static Future<void> _replaceAll(BuildContext context, Widget page) {
    return Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (_) => false,
    );
  }

  static Future<void> toLanding(BuildContext context) =>
      _replaceAll(context, const LandingPage());

  static Future<void> toFamilia(
    BuildContext context,
    String cuentaId, {
    String? deeplink,
  }) => _replaceAll(
    context,
    CuentaHomePage(cuentaId: cuentaId, initialDeeplink: deeplink),
  );

  static Future<void> toInstitucion(
    BuildContext context,
    InstitucionSesion sesion,
  ) => _replaceAll(
    context,
    InstitucionMenuPage(
      ownerAccountId: sesion.ownerAccountId,
      institucionPerfilId: sesion.institucionPerfilId,
      institucionNombre: sesion.nombre,
    ),
  );

  /// Cierra la sesión (ambos roles) y vuelve a la bienvenida.
  static Future<void> logout(BuildContext context) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await AuthService.logout();
    await nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LandingPage()),
      (_) => false,
    );
  }
}
