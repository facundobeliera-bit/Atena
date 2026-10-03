// lib/routes/atena_boot_gate.dart
//
// Puerta de entrada: resuelve la sesión guardada y abre el inicio que
// corresponde (familia, institución o bienvenida). Los deeplinks web solo se
// aplican dentro de la cuenta con sesión activa.

import 'package:flutter/material.dart';

import '../screens/cuentas/cuenta_home_page.dart';
import '../screens/instituciones/institucion_menu_page.dart';
import '../screens/landing/landing_page.dart';
import '../services/auth_service.dart';
import '../ui/atena_ui.dart';

class AtenaBootGate extends StatefulWidget {
  /// Deeplink web (/calendario?... o /documentos?...) a abrir tras ingresar.
  final String? deeplink;

  const AtenaBootGate({super.key, this.deeplink});

  @override
  State<AtenaBootGate> createState() => _AtenaBootGateState();
}

class _AtenaBootGateState extends State<AtenaBootGate> {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<Widget> _resolve() async {
    final target = await AuthService.resolveHome();
    return switch (target) {
      HomeInstitucion(:final sesion) => InstitucionMenuPage(
        ownerAccountId: sesion.ownerAccountId,
        institucionPerfilId: sesion.institucionPerfilId,
        institucionNombre: sesion.nombre,
      ),
      HomeFamilia(:final cuentaId) => CuentaHomePage(
        cuentaId: cuentaId,
        initialDeeplink: widget.deeplink,
      ),
      HomeLanding() => const LandingPage(),
    };
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    final nav = Navigator.of(context);
    Widget home;
    try {
      home = await _resolve();
    } catch (_) {
      home = const LandingPage();
    }
    if (!mounted) return;

    nav.pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/'),
        transitionDuration: AtenaMotion.slow,
        pageBuilder: (_, _, _) => home,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const AtenaSplash();
}

/// Pantalla de carga con la marca.
class AtenaSplash extends StatelessWidget {
  const AtenaSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtenaScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AtenaAppIcon(size: 96),
            SizedBox(height: 28),
            AtenaWordmark(fontSize: 30),
            SizedBox(height: 36),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
