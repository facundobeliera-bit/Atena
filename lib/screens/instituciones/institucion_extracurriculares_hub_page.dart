// lib/screens/instituciones/institucion_extracurriculares_hub_page.dart
//
// ATENA – INSTITUCIÓN – HUB EXTRACURRICULARES (AJUSTE CANÓNICO)
// -----------------------------------------------------------------------------
// Cambio (feb 2026 · solicitado):
// - ❌ El HUB ya NO vuelve a listar/seleccionar bloques.
// - ✅ El bloque extracurricular YA viene seleccionado desde:
//     - Plan (módulos habilitados) + Selector de perfiles (actividadKey/bloque)
// - ✅ Este screen pasa a ser un “router/wrapper” hacia ModuloBase,
//   equivalente al rol de “Gestión Vacantes” en curricular, evitando redundancia.
//
// Reglas canónicas:
// - moduleKey = bloque.key (snake_case estable) como fuente de verdad.
// - institucionId: trim + colapsa whitespace (misma norma que services).
// - Fail-fast: si instId/moduleKey inválidos → UI fatal y NO navega.
//
// i18n + dark mode:
// - Textos vía AppLocalizations (ARB-ready).
// - Colores vía Theme/ColorScheme.
//
// -----------------------------------------------------------------------------
// IMPORTANTE:
// - Este archivo ahora requiere que el bloque seleccionado llegue por parámetro.
// - Si tu caller todavía no lo pasa, hay que actualizar el punto de navegación
//   (InstitucionAreaPage / Selector) para enviar el BloqueExtracurricular correcto.
//

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import 'institucion_extracurricular_modulo_base.dart';

class InstitucionExtracurricularesHubPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;

  /// ✅ Bloque YA elegido upstream (selector/actividad).
  final BloqueExtracurricular bloque;

  const InstitucionExtracurricularesHubPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.bloque,
  });

  // =====================================================
  // Helpers
  // =====================================================

  static String _norm(String v) => v.trim().toLowerCase();

  /// ✅ Alineado con services:
  /// trim + colapsa whitespace interno (elimina).
  static String _normIdCanon(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), '');

  static bool _isValidSnakeCase(String key) {
    final k = _norm(key);
    if (k.isEmpty) return false;
    final re = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
    return re.hasMatch(k);
  }

  static bool _isValidCanonicalModuleKey(String key) {
    final k = _norm(key);
    return BloqueExtracurricularX.isValidKey(k);
  }

  static bool _isValidModuleKey(String key) =>
      _isValidSnakeCase(key) && _isValidCanonicalModuleKey(key);

  Widget _fatalScaffold({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 42,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style:
                      (theme.textTheme.bodyMedium ??
                              const TextStyle(fontSize: 14))
                          .copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.back),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final instName = institucionNombre.trim().isEmpty
        ? l10n.institucionGeneric
        : institucionNombre.trim();

    final instIdCanon = _normIdCanon(institucionId);
    final instIdOk = instIdCanon.isNotEmpty;

    // ✅ Fuente de verdad: bloque.key (snake_case estable)
    final moduleKey = _norm(bloque.key);
    final keyOk = _isValidModuleKey(moduleKey);

    // Fail-fast: no dejamos contaminar flujo si algo viene mal.
    if (!instIdOk) {
      return _fatalScaffold(
        context: context,
        title: l10n.institucionExtracHubTitle,
        message: l10n.institucionExtracHubToastInvalidInstId,
      );
    }

    if (!keyOk) {
      return _fatalScaffold(
        context: context,
        title: l10n.institucionExtracHubTitle,
        message: l10n.institucionExtracHubToastInvalidModuleKey(bloque.label),
      );
    }

    // ✅ Directo al módulo base (sin HUB redundante).
    return InstitucionExtracurricularModuloBase(
      institucionId: instIdCanon,
      institucionNombre: instName,
      bloque: bloque,
      moduleKey: moduleKey,
    );
  }
}
