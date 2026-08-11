// lib/routes/deeplink_gateway_page.dart
//
// ATENA – Deeplink Gateway (CANÓNICO)
// Objetivo: soportar "cold start deeplink" (sin RouteSettings.arguments)
// Reglas:
// - NO inventa sesiones: solo usa sesión persistida de CuentaService.
// - Redirige a CuentaHomePage con initialDeeplink para que resuelva perfilId/date/itemId.
// - Si no hay sesión de cuenta, cae a login.
//
// Esto evita flujos paralelos: CuentaHomePage sigue siendo el gateway de alumnos.

import 'package:flutter/material.dart';

import '../services/cuenta_service.dart';
import '../screens/cuentas/cuenta_home_page.dart';
import '../screens/auth/alumno_login_page.dart';

class DeeplinkGatewayPage extends StatefulWidget {
  final String deeplinkRaw;

  const DeeplinkGatewayPage({super.key, required this.deeplinkRaw});

  @override
  State<DeeplinkGatewayPage> createState() => _DeeplinkGatewayPageState();
}

class _DeeplinkGatewayPageState extends State<DeeplinkGatewayPage> {
  bool _booting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final cuentaId = await CuentaService.getSesionCuentaId();
      if (!mounted) return;

      final id = (cuentaId ?? '').trim();
      final deeplink = widget.deeplinkRaw.trim();

      // Navegamos en post-frame para evitar edge cases en initState/cold start.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (id.isEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AlumnoLoginPage()),
          );
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                CuentaHomePage(cuentaId: id, initialDeeplink: deeplink),
          ),
        );
      });

      // Importante: NO cambiamos _booting=false acá porque vamos a navegar.
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _booting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Deeplink')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error ??
              'No se pudo resolver el deeplink.\n\nDeeplink: ${widget.deeplinkRaw}',
        ),
      ),
    );
  }
}
