// ─────────────────────────────────────────────
// ATENA – UI ALUMNO: SOLICITAR VACANTE (OWNER-ONLY)
// Archivo: lib/screens/alumnos/alumno_solicitar_vacante_page.dart
//
// CANÓNICO:
// - ownerAccountId + perfilId (fuente de verdad)
// - alumnoDocumento NO es key lógica (solo compat / display)
// - curricular requiere aula/grupo
// - extracurricular NO requiere aula/turno (opcionales)
//
// EXT (enero 2026):
// - Soporte moduleKey (extracurriculares) para que la solicitud quede bien
//   trazada al bloque (deportes/idiomas/etc.) sin depender del nombre.
// - No rompemos curricular (moduleKey queda '').
//
// Fix (enero 2026):
// - Si tu modelo SolicitudAlumno ya endureció aula/turno como String NO-null,
//   este screen normaliza a '' (string vacío) antes de construir SolicitudAlumno.
//
// HARDENING (feb 2026):
// - Captura messenger/navigator antes de awaits.
// - Timeout en creación de solicitud (prototipo local).
// - Unfocus antes de dialog / envío.
//
// AJUSTE (feb 2026 · compat “curso canónico”):
// - Si aula/turno vienen serializados como:
//     aula  = "<Nivel> • <Grado/Sala/Año>"
//     turno = "<Turno> • <HH:MM>-<HH:MM>"
//   se muestran en UI en 2 líneas (best-effort) sin romper legacy.
//
// ✅ CANÓNICO CURRICULAR (feb 2026):
// - grupoCurricularId: ID estable del grupo emitido por Gestión Vacantes.
// - aula/turno quedan como snapshot/UI/compat.
// ─────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/solicitudes/solicitud_alumno.dart';
import '../../services/solicitudes_service.dart';

class AlumnoSolicitarVacantePage extends StatefulWidget {
  /// ⚠️ LEGACY/COMPAT: no usar como key lógica.
  final String alumnoDocumento;

  final String institucionId;
  final String institucionNombre;

  /// En curricular puede ser el nombre del curso/sala.
  /// En extracurricular puede ser el nombre de la actividad.
  final String actividadNombre;

  final bool esCurricular;

  /// ✅ CANÓNICO CURRICULAR:
  /// ID estable del grupo/cupo publicado por Gestión Vacantes.
  /// - Curricular: requerido (Fase 2).
  /// - Extracurricular: null/''.
  final String? grupoCurricularId;

  /// Curricular: suele ser requerido (curso/sala).
  /// Extracurricular: opcional.
  final String? aula;

  /// Opcional. En curricular puede venir inferido.
  /// En extracurricular puede venir como horario/turno.
  final String? turno;

  /// ✅ owner-only: requerido
  final String ownerAccountId;

  /// ✅ perfil origen: requerido
  final String perfilId;

  /// ✅ EXTRACURRICULAR: moduleKey canónica (snake_case).
  /// - Curricular: se puede omitir (queda '').
  /// - Extracurricular: recomendable enviarla desde AlumnoSeleccionGrupoPage.
  final String? moduleKey;

  const AlumnoSolicitarVacantePage({
    super.key,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.institucionNombre,
    required this.actividadNombre,
    required this.esCurricular,
    required this.ownerAccountId,
    required this.perfilId,
    this.grupoCurricularId,
    this.aula,
    this.turno,
    this.moduleKey,
  });

  @override
  State<AlumnoSolicitarVacantePage> createState() =>
      _AlumnoSolicitarVacantePageState();
}

class _AlumnoSolicitarVacantePageState
    extends State<AlumnoSolicitarVacantePage> {
  bool _enviando = false;

  static const String _sepDot = '•';

  String _n(String v) => v.trim();

  String? _nullSiVacio(String? v) {
    final t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// ✅ Para modelos endurecidos (String no-null):
  /// normaliza a string vacío seguro.
  String _s(String? v) => (v ?? '').trim();

  void _snack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final m = msg.trim();
    if (m.isEmpty) return;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(m)));
    } catch (_) {
      // NO-OP
    }
  }

  /// ✅ Valida moduleKey contra set canónico del enum/extension.
  /// Curricular => '' siempre.
  String _normalizeModuleKey(String? raw, {required bool esCurricular}) {
    if (esCurricular) return '';

    final candidate = _s(raw).toLowerCase();
    if (candidate.isEmpty) return '';

    // Canónico: validación por catálogo (no por nombre)
    return BloqueExtracurricularX.isValidKey(candidate) ? candidate : '';
  }

  String _normalizeGrupoCurricularId(
    String? raw, {
    required bool esCurricular,
  }) {
    if (!esCurricular) return '';
    return _s(raw);
  }

  List<String> _splitSerializedParts(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return const <String>[];
    if (!t.contains(_sepDot)) return <String>[t];
    return t
        .split(_sepDot)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _buildAulaUiLines(String? aulaUi) {
    final parts = _splitSerializedParts(aulaUi);
    if (parts.isEmpty) return const <String>[];
    // aula canónica: "<Nivel> • <Grado/Sala/Año>" → 2 líneas si aplica
    return parts.length <= 2
        ? parts
        : <String>[parts.first, parts.sublist(1).join(' $_sepDot ')];
  }

  List<String> _buildTurnoUiLines(String? turnoUi) {
    final parts = _splitSerializedParts(turnoUi);
    if (parts.isEmpty) return const <String>[];
    // turno canónico: "<Turno> • <HH:MM>-<HH:MM>" → 2 líneas si aplica
    return parts.length <= 2
        ? parts
        : <String>[parts.first, parts.sublist(1).join(' $_sepDot ')];
  }

  String _buildSemanticsSummaryLabel({
    required AppLocalizations l,
    required String institucionNombre,
    required String actividadNombre,
    required bool esCurricular,
    required String moduleKey,
    String? aulaUi,
    String? turnoUi,
  }) {
    final typeLabel = esCurricular
        ? l.alumnoSolicitarVacanteTypeCurricular
        : l.alumnoSolicitarVacanteTypeExtracurricular;

    final parts = <String>[
      l.alumnoSolicitarVacanteTitle,
      institucionNombre.trim(),
      actividadNombre.trim(),
      typeLabel.trim(),
    ];

    if (!esCurricular && moduleKey.trim().isNotEmpty) {
      parts.add(moduleKey.trim());
    }

    for (final line in _buildAulaUiLines(aulaUi)) {
      if (line.trim().isNotEmpty) parts.add(line.trim());
    }
    for (final line in _buildTurnoUiLines(turnoUi)) {
      if (line.trim().isNotEmpty) parts.add(line.trim());
    }

    return parts.where((e) => e.trim().isNotEmpty).join('. ');
  }

  Future<void> _confirmarYEnviar() async {
    if (_enviando) return;
    if (!mounted) return;

    final l = AppLocalizations.of(context);

    // ✅ Normalización previa
    final alumnoDoc = _n(widget.alumnoDocumento); // compat (no key)
    final instId = _n(widget.institucionId);
    final instNombre = _n(widget.institucionNombre);
    final actividad = _n(widget.actividadNombre);

    final owner = _n(widget.ownerAccountId);
    final perfil = _n(widget.perfilId);

    // UI-friendly (null si vacío)
    final aulaUi = _nullSiVacio(widget.aula);
    final turnoUi = _nullSiVacio(widget.turno);

    // ✅ Modelo-friendly (NO-null)
    final aulaModel = _s(widget.aula);
    final turnoModel = _s(widget.turno);

    // ✅ moduleKey canónica (solo extracurricular y válida)
    final moduleKey = _normalizeModuleKey(
      widget.moduleKey,
      esCurricular: widget.esCurricular,
    );

    // ✅ grupoCurricularId canónico (solo curricular)
    final grupoCurricularId = _normalizeGrupoCurricularId(
      widget.grupoCurricularId,
      esCurricular: widget.esCurricular,
    );

    // Guardrails canónicos
    if (owner.isEmpty || perfil.isEmpty) {
      _snack(l.alumnoSolicitarVacanteMissingOwnerPerfil);
      return;
    }

    if (instId.isEmpty || instNombre.isEmpty) {
      _snack(l.alumnoSolicitarVacanteInvalidInstitution);
      return;
    }

    if (actividad.isEmpty) {
      _snack(l.alumnoSolicitarVacanteInvalidActivity);
      return;
    }

    // ✅ Curricular: aula/grupo debe existir sí o sí (snapshot mínimo + canónico)
    if (widget.esCurricular && aulaModel.isEmpty) {
      _snack(l.alumnoSolicitarVacanteCurricularRequiresAula);
      return;
    }
    if (widget.esCurricular && grupoCurricularId.isEmpty) {
      _snack('${l.commonGenericError}: grupoCurricularId');
      return;
    }

    // ✅ Capturar messenger/navigator antes de await
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    // Unfocus antes de abrir dialog / enviar
    try {
      FocusScope.of(context).unfocus();
    } catch (_) {}

    // Confirmación
    bool? ok;
    try {
      final aulaLines = _buildAulaUiLines(aulaUi);
      final turnoLines = _buildTurnoUiLines(turnoUi);

      ok = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l.alumnoSolicitarVacanteConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(instNombre),
              Text(actividad),
              Text(
                widget.esCurricular
                    ? l.alumnoSolicitarVacanteTypeCurricular
                    : l.alumnoSolicitarVacanteTypeExtracurricular,
              ),
              if (!widget.esCurricular && moduleKey.isNotEmpty) Text(moduleKey),
              ...aulaLines.map(Text.new),
              ...turnoLines.map(Text.new),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l.commonSend),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final msg = '${l.commonGenericError}: $e';

      if (messenger != null) {
        try {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(msg)));
        } catch (_) {
          _snack(msg);
        }
      } else {
        _snack(msg);
      }
      return;
    }

    if (!mounted) return;
    if (ok != true) return;

    setState(() => _enviando = true);

    try {
      final ahora = DateTime.now();

      final solicitud = SolicitudAlumno(
        id: SolicitudAlumno.newSolicitudId(),
        ownerAccountId: owner,
        perfilId: perfil,

        // ⚠️ compat / auditoría: no usar como key lógica
        alumnoDocumento: alumnoDoc,

        institucionId: instId,
        institucionNombre: instNombre,
        actividadNombre: actividad,
        esCurricular: widget.esCurricular,

        // ✅ CANÓNICO CURRICULAR:
        grupoCurricularId: widget.esCurricular ? grupoCurricularId : '',

        // ✅ EXTRACURRICULAR: trazabilidad por bloque
        // Curricular: queda ''
        moduleKey: widget.esCurricular ? '' : moduleKey,

        // Estado inicial
        estado: EstadoSolicitud.pendiente,

        // Se recalcula en el service; dejamos placeholder seguro.
        dedupKey: '',

        fechaCreacion: ahora,
        fechaUltimoCambio: ahora,

        // ✅ aula/turno se pasan como String NO-null ('' si no aplica)
        aula: aulaModel,
        turno: turnoModel,
      );

      await SolicitudesService.crearSolicitudDesdePerfil(
        ownerAccountId: owner,
        perfilId: perfil,
        solicitudAlumno: solicitud,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _snack(l.commonRequestSentOk);

      if (nav.canPop()) {
        nav.pop(true);
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _snack('${l.commonGenericError}: timeout');
    } catch (e) {
      if (!mounted) return;

      final msg = '${l.commonGenericError}: $e';

      if (messenger != null) {
        try {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(msg)));
        } catch (_) {
          _snack(msg);
        }
      } else {
        _snack(msg);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final isDark = t.brightness == Brightness.dark;

    final aulaUi = _nullSiVacio(widget.aula);
    final turnoUi = _nullSiVacio(widget.turno);

    final aulaLines = _buildAulaUiLines(aulaUi);
    final turnoLines = _buildTurnoUiLines(turnoUi);

    final moduleKey = _normalizeModuleKey(
      widget.moduleKey,
      esCurricular: widget.esCurricular,
    );

    final semanticsLabel = _buildSemanticsSummaryLabel(
      l: l,
      institucionNombre: widget.institucionNombre.trim(),
      actividadNombre: widget.actividadNombre.trim(),
      esCurricular: widget.esCurricular,
      moduleKey: moduleKey,
      aulaUi: aulaUi,
      turnoUi: turnoUi,
    );

    final typeLabel = widget.esCurricular
        ? l.alumnoSolicitarVacanteTypeCurricular
        : l.alumnoSolicitarVacanteTypeExtracurricular;

    final cardBg = cs.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.55 : 0.65,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.alumnoSolicitarVacanteTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Semantics(
              container: true,
              label: semanticsLabel,
              child: Card(
                elevation: 0,
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.institucionNombre.trim().isEmpty
                            ? l.commonInstitution
                            : widget.institucionNombre.trim(),
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.actividadNombre.trim()),
                      Text(typeLabel),
                      if (!widget.esCurricular && moduleKey.isNotEmpty)
                        Text(moduleKey),
                      ...aulaLines.map(Text.new),
                      ...turnoLines.map(Text.new),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _confirmarYEnviar,
                icon: _enviando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _enviando ? l.commonSending : l.alumnoSolicitarVacanteSendCta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
