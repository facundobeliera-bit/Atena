// lib/screens/alumno/alumno_menu_page.dart
//
// ATENA – ALUMNO MENU (gateway)
//
// ✅ CIERRE FASE 2 (CANÓNICO):
// - Blindaje de deeplink sin romper el flujo canónico.
// - Evita setState si el widget ya no está montado.
// - Evita underscores/variables confusas en callbacks.
// - ✅ i18n REAL: AppLocalizations.of(context).<key> (sin fallbacks).
// - ✅ Theme/ColorScheme real (sin Colors.* fijo).
//
// Flujo:
// - Si existe sesión de cuenta (ownerAccountId): pushReplacement → CuentaHomePage
//   y luego intenta aplicar deeplink (pushNamed) best-effort.
// - Si NO hay sesión: muestra CTA de login y pasa deeplink al AlumnoLoginPage.

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/cuenta_service.dart';

import '../auth/alumno_login_page.dart';
import '../cuentas/cuenta_home_page.dart';

class AlumnoMenuPage extends StatefulWidget {
  /// ✅ Soporte deeplink canónico (interno).
  /// Ej: "/calendario?perfilId=...&date=...&itemId=..."
  final String? deeplink;

  const AlumnoMenuPage({super.key, this.deeplink});

  @override
  State<AlumnoMenuPage> createState() => _AlumnoMenuPageState();
}

class _AlumnoMenuPageState extends State<AlumnoMenuPage> {
  bool _chequeandoSesion = true;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _autoLoginSiCorresponde();
  }

  String? _sanitizeDeeplink(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return s.startsWith('/') ? s : null;
  }

  Future<void> _autoLoginSiCorresponde() async {
    // ✅ Sesión REAL: cuenta única (ownerAccountId)
    final cuentaId = await CuentaService.getSesionCuentaId();
    if (!mounted) return;

    final owner = (cuentaId ?? '').trim();
    if (owner.isNotEmpty) {
      final dl = _sanitizeDeeplink(widget.deeplink);

      WidgetsBinding.instance.addPostFrameCallback((frameTime) {
        if (!mounted) return;

        // 1) Ir a Home canónico (Cuenta única)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CuentaHomePage(cuentaId: owner),
          ),
        );

        // 2) Intentar aplicar deeplink (si viene). No rompe si la ruta no existe.
        if (dl != null) {
          WidgetsBinding.instance.addPostFrameCallback((frameTime2) {
            if (!mounted) return;
            try {
              Navigator.of(context).pushNamed(dl);
            } catch (_) {
              // Silencioso: si no hay ruta registrada, no forzamos flujos alternativos.
            }
          });
        }
      });

      return;
    }

    if (!mounted) return;
    setState(() => _chequeandoSesion = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_chequeandoSesion) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    final dl = _sanitizeDeeplink(widget.deeplink);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ Deprecated fix: withOpacity -> withValues(alpha: ...)
    final secondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ??
        cs.onSurface.withValues(alpha: 0.75);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoMenuTitle)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    l10n.alumnoMenuHeader,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.alumnoMenuBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondary),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AlumnoLoginPage(deeplink: dl),
                          ),
                        );
                      },
                      child: Text(l10n.alumnoMenuCtaLogin),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
