// lib/screens/instituciones/institucion_mis_solicitudes_page.dart
//
// ATENA – INSTITUCIÓN / MIS SOLICITUDES
// CANÓNICO (owner → perfiles) – UI institución
//
// Objetivos de esta versión:
// - UI estable y simple.
// - Sin imports/métodos muertos.
// - Recarga robusta + clasificación por estado.
// - Mantener consistencia de estado + recarga.
// - Mantener el flujo canónico: institucionId = perfilId.
//
// EXTENSIÓN (enero 2026):
// - Soporte opcional de filtro por MÓDULO extracurricular (moduleKey):
//   Si viene moduleKey, el screen filtra solicitudes a ese módulo usando
//   SolicitudesService.obtenerSolicitudesParaInstitucionPorModuloKey(...)
//
// Decisión CANÓNICA (actual):
// - Sin legacy.
// - La “fuente de verdad” de nombres/guía es BloqueExtracurricular (lado Alumno).
// - moduleKey es snake_case estable y se valida SOLO contra el set canónico.
// - NO se “corrige” una moduleKey mala con normalizaciones agresivas:
//   si es inválida, se bloquea el filtrado (fail-fast) y se muestra banner,
//   PERO se muestran TODAS las solicitudes (fallback controlado).
//
// Fix analyzer (enero 2026):
// - Elimina use_build_context_synchronously en flujos async:
//   * Captura messenger ANTES de awaits (cuando mounted==true).
//   * Tras await: usa mounted y referencias capturadas (no re-lee context).
// - Mantiene robustez de recarga con token (_loadSeq).
//
// Hardening (enero 2026):
// - Dialog controllers: dispose seguro (evita leaks).
// - En cards: si NO hay filtro aplicado, igualmente mostramos el módulo
//   de la solicitud (si es extracurricular y moduleKey válida).
//
// ✅ NUEVO (enero 2026):
// - Acción canónica “Solicitar / Ver documentación” desde una SolicitudAlumno:
//   navega a InstitucionDocumentosPage y pasa ownerAccountId + perfilId vía
//   RouteSettings.arguments (no rompe constructor actual).
//   * Si faltan (nullable o vacío), muestra snack y no navega.
//
// ✅ FIX (Feb 2026) – “no depender de l10n en initState” + “no quedar cargando”:
// - initState: bootstrap post-frame.
// - _cargar: timeout + finally (siempre corta loading si token vigente).
// - Diagnóstico por logs [ATENA][SOL].
// - PlanHabilitacionGuard.ensureOperativo() al entrar (screen operativo).
//
// ✅ FIX (Feb 2026) – alineado a InstitucionAreaPage:
// - PlanStatus REAL: preferir inst.estadoPlan.
// - En prototipo Fase 2: NO bloquear ni redirigir por “enPrueba/trial” o status null/raro.
//
// ✅ FIX CANÓNICO (Feb 2026) – redirección correcta a PlanPage:
// - Este screen ahora RESUELVE y CONSERVA ownerAccountId + institucionPerfilId
//   (por constructor o RouteSettings.arguments) y los pasa al Guard.
// - Si falta ownerAccountId, el Guard se SKIP (evita fallback/loops).
//
// ✅ FIX CANÓNICO (Feb 2026) – instituciónId consistente:
// - Para cargar solicitudes / institución / docs, usar SIEMPRE el perfilId resuelto
//   (institucionPerfilIdResolved) como institucionId canónico (fallback a widget.institucionId).
//
// Fix analyzer (cierre):
// - unnecessary_underscores: separatorBuilder usa (context, index).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

// ✅ Modelo (fuente de verdad)
import '../../models/solicitudes/solicitud_alumno.dart';

// ✅ Fuente de verdad UI (labels completos + guía) + SET canónico de keys
import '../../models/extracurriculares/bloque_extracurricular.dart';

// ✅ Service
import '../../services/solicitudes_service.dart';

// ✅ Helpers (para cargar institución y extraer planStatus best-effort)
import '../../services/instituciones_helpers.dart' as ih;
import '../../models/instituciones/instituciones_integrado.dart';

// ✅ PLAN – Guard canónico (habilitación operativa)
import '../../guards/plan_habilitacion_guard.dart';

// ✅ PLAN – Regla canónica (para decidir si cortamos el flujo)
import '../../services/plan_habilitacion_service.dart';

// ✅ Documentación (prototipo)
import 'institucion_documentos_page.dart';

class InstitucionMisSolicitudesPage extends StatefulWidget {
  /// En flujo owner→perfiles, este id debe ser el perfilId de institución.
  final String institucionId;
  final String institucionNombre;

  /// ✅ Opcional: filtra por módulo extracurricular (snake_case canónico).
  /// Ej: "deporte_y_movimiento"
  /// Si está vacío o null, muestra todas.
  final String? moduleKey;

  /// ✅ NUEVO (canónico para redirect Plan):
  /// Debe existir para que el guard pueda navegar a /institucion/plan sin fallback.
  /// Si no viene por constructor, se intenta resolver desde RouteSettings.arguments.
  final String? ownerAccountId;

  /// ✅ NUEVO (canónico): perfilId de institución.
  /// Si no viene, fallback = institucionId (canónico: institucionId = perfilId).
  final String? institucionPerfilId;

  const InstitucionMisSolicitudesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.moduleKey,
    this.ownerAccountId,
    this.institucionPerfilId,
  });

  @override
  State<InstitucionMisSolicitudesPage> createState() =>
      _InstitucionMisSolicitudesPageState();
}

class _InstitucionMisSolicitudesPageState
    extends State<InstitucionMisSolicitudesPage> {
  bool _cargando = true;

  List<SolicitudAlumno> _pendientes = <SolicitudAlumno>[];
  List<SolicitudAlumno> _confirmadas = <SolicitudAlumno>[];
  List<SolicitudAlumno> _rechazadas = <SolicitudAlumno>[];
  List<SolicitudAlumno> _canceladas = <SolicitudAlumno>[];

  /// ✅ Fuente de verdad UI: indica si se pidió filtro pero es inválido.
  bool _moduleKeyInvalida = false;

  // ✅ Anti-doble carga concurrente (prototipo local)
  bool _booting = false;

  // =====================================================
  // CANÓNICO (DATA IDs): SOLO trim (sin “normalizar” agresivo)
  // =====================================================
  static String _idData(String v) => v.trim();
  static String _n(String? v) => (v ?? '').trim();

  // =====================================================
  // NORMALIZACIÓN CANÓNICA (estables) – moduleKey
  // =====================================================
  static String _normalizeModuleKeyCanonical(String raw) =>
      raw.trim().toLowerCase();

  static bool _isSnakeCaseStable(String key) {
    final k = _normalizeModuleKeyCanonical(key);
    if (k.isEmpty) return false;
    return RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$').hasMatch(k);
  }

  /// Fallback de widget.institucionId (solo por si no resolvimos aún args).
  String get _instIdFromWidget => _idData(widget.institucionId);

  String get _moduleKeyRaw => widget.moduleKey ?? '';
  String get _moduleKey => _normalizeModuleKeyCanonical(_moduleKeyRaw);

  bool get _filtraPorModulo => _moduleKey.isNotEmpty;

  /// ✅ Validación 100% canónica contra el SET canónico (fail-fast).
  bool _isValidModuleKey(String key) {
    final k = _normalizeModuleKeyCanonical(key);
    if (k.isEmpty) return false;

    // Regla canónica: snake_case estable + pertenece al set.
    if (!_isSnakeCaseStable(k)) return false;
    return BloqueExtracurricularX.isValidKey(k);
  }

  /// ✅ Filtro realmente aplicado (solo si se pidió filtro y no es inválido).
  bool get _filtroAplicado => _filtraPorModulo && !_moduleKeyInvalida;

  String _moduleLabel(String key, AppLocalizations l10n) {
    final k = _normalizeModuleKeyCanonical(key);
    final b = BloqueExtracurricularX.fromKey(k);
    return b?.label ?? l10n.moduleLabelGeneric;
  }

  String _moduleLabelFromSolicitud(SolicitudAlumno s, AppLocalizations l10n) {
    if (s.esCurricular) return '';
    final mk = _normalizeModuleKeyCanonical(s.moduleKey);
    if (mk.isEmpty) return '';
    if (!_isSnakeCaseStable(mk)) return '';
    if (!BloqueExtracurricularX.isValidKey(mk)) return '';
    return _moduleLabel(mk, l10n);
  }

  String _estadoLabel(EstadoSolicitud e, AppLocalizations l10n) {
    switch (e) {
      case EstadoSolicitud.pendiente:
        return l10n.requestStatusPending;
      case EstadoSolicitud.confirmada:
        return l10n.requestStatusConfirmed;
      case EstadoSolicitud.rechazada:
        return l10n.requestStatusRejected;
      case EstadoSolicitud.canceladaPorAlumno:
        return l10n.requestStatusCancelledByStudent;
      case EstadoSolicitud.canceladaPorInstitucion:
        return l10n.requestStatusCancelledByInstitution;
    }
  }

  // -------------------------
  // Robustez de recarga
  // -------------------------
  int _loadSeq = 0;

  // =====================================================
  // ✅ Args canónicos resueltos (para Guard / redirects / ID institución)
  // =====================================================
  bool _routeArgsResolved = false;
  String _ownerAccountIdResolved = '';
  String _institucionPerfilIdResolved = '';

  /// ✅ Institución CANÓNICA: SIEMPRE el perfilId resuelto (fallback widget.institucionId)
  String get _institucionIdCanon {
    final p = _idData(_institucionPerfilIdResolved);
    if (p.isNotEmpty) return p;
    return _instIdFromWidget;
  }

  void _resolveRouteArgsOnce() {
    if (_routeArgsResolved) return;

    // 1) Prefer constructor
    _ownerAccountIdResolved = _n(widget.ownerAccountId);
    final ctorPerfil = _n(widget.institucionPerfilId);

    _institucionPerfilIdResolved = ctorPerfil.isNotEmpty
        ? _idData(ctorPerfil)
        : _instIdFromWidget;

    // 2) Completar desde RouteSettings.arguments (best-effort)
    try {
      final route = ModalRoute.of(context);
      final args = route?.settings.arguments;
      if (args is Map) {
        String readString(List<String> keys) {
          for (final k in keys) {
            final v = args[k];
            if (v == null) continue;
            final s = v.toString().trim();
            if (s.isNotEmpty) return s;
          }
          return '';
        }

        if (_ownerAccountIdResolved.isEmpty) {
          _ownerAccountIdResolved = readString(const [
            'ownerAccountId',
            'ownerId',
            'cuentaId',
          ]);
        }

        // Perfil institución (canónico) - si no vino por ctor o quedó igual al widget
        if (_institucionPerfilIdResolved.isEmpty ||
            _institucionPerfilIdResolved == _instIdFromWidget) {
          final p = readString(const [
            'institucionPerfilId',
            'perfilId',
            'institucionId',
          ]);
          if (p.isNotEmpty) {
            _institucionPerfilIdResolved = _idData(p);
          }
        }
      }
    } catch (_) {}

    // 3) Defaults seguros
    if (_institucionPerfilIdResolved.isEmpty) {
      _institucionPerfilIdResolved = _instIdFromWidget;
    } else {
      _institucionPerfilIdResolved = _idData(_institucionPerfilIdResolved);
    }

    _ownerAccountIdResolved = _idData(_ownerAccountIdResolved);

    _routeArgsResolved = true;
  }

  @override
  void initState() {
    super.initState();

    // ✅ post-frame (evita l10n/theme en initState + edge cases web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_cargar());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveRouteArgsOnce();
  }

  void _snack(ScaffoldMessengerState messenger, String msg) {
    final clean = msg.trim();
    if (clean.isEmpty) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {
      // NO-OP
    }
  }

  // ─────────────────────────────────────────────
  // Plan guard helpers (alineado a InstitucionAreaPage)
  // ─────────────────────────────────────────────

  String _enumNameBestEffort(Object? e) {
    if (e == null) return '';
    try {
      // ignore: avoid_dynamic_calls
      final n = (e as dynamic).name;
      if (n is String) return n.trim();
    } catch (_) {}
    return e.toString().trim();
  }

  bool _shouldSkipPlanGuard(PlanStatus? planStatus) {
    // ✅ Si no hay planStatus, NO forzamos redirección desde este screen.
    if (planStatus == null) return true;

    final s = _enumNameBestEffort(planStatus).toLowerCase();

    // ✅ Prototipo / prueba / trial -> permitir operar (Fase 2).
    if (s.contains('enprueba') || s.contains('prueba') || s.contains('trial')) {
      return true;
    }

    // ✅ Si viene “raro” o vacío, preferimos NO redirigir desde aquí.
    if (s.isEmpty) return true;

    return false;
  }

  // ✅ PlanStatus REAL: preferir estadoPlan.
  PlanStatus? _planStatusForGuard(Institucion inst) {
    // 0) inst.estadoPlan (preferido)
    try {
      // ignore: avoid_dynamic_calls
      final v = (inst as dynamic).estadoPlan;
      if (v is PlanStatus) return v;
    } catch (_) {}

    // 1) inst.planStatus (compat)
    try {
      // ignore: avoid_dynamic_calls
      final v = (inst as dynamic).planStatus;
      if (v is PlanStatus) return v;
    } catch (_) {}

    // 2) inst.planSafe.status (compat)
    try {
      // ignore: avoid_dynamic_calls
      final ps = (inst as dynamic).planSafe;
      // ignore: avoid_dynamic_calls
      final v = ps?.status;
      if (v is PlanStatus) return v;
    } catch (_) {}

    // 3) inst.planSafe como status (compat extrema)
    try {
      // ignore: avoid_dynamic_calls
      final ps = (inst as dynamic).planSafe;
      if (ps is PlanStatus) return ps;
    } catch (_) {}

    return null;
  }

  bool _canRunPlanGuard(PlanStatus? planStatus) {
    final owner = _ownerAccountIdResolved.trim();
    if (owner.isEmpty) return false;
    if (planStatus == null) return false;
    return true;
  }

  void _ensureOperativoGuard(PlanStatus? planStatus) {
    final owner = _ownerAccountIdResolved.trim();
    final perfilId = _institucionIdCanon;

    if (!_canRunPlanGuard(planStatus)) {
      debugPrint(
        '[ATENA][SOL] plan guard SKIP (owner="${owner.isEmpty ? '(empty)' : owner}" plan="${_enumNameBestEffort(planStatus)}")',
      );
      return;
    }

    // best-effort: soportar firma moderna con owner/perfil y fallback a firma corta
    try {
      PlanHabilitacionGuard.ensureOperativo(
        context: context,
        plan: planStatus,
        ownerAccountId: owner,
        institucionPerfilId: perfilId,
        institucionNombre: widget.institucionNombre,
      );
      return;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final dyn = PlanHabilitacionGuard as dynamic;
      dyn.ensureOperativo(
        context: context,
        plan: planStatus,
        ownerAccountId: owner,
        institucionPerfilId: perfilId,
        institucionNombre: widget.institucionNombre,
      );
      return;
    } catch (_) {}

    try {
      PlanHabilitacionGuard.ensureOperativo(context: context, plan: planStatus);
    } catch (_) {}
  }

  Future<void> _cargar() async {
    final int token = ++_loadSeq;

    if (!mounted) return;
    if (_booting) return;
    _booting = true;

    _resolveRouteArgsOnce();

    // ✅ Capturar referencias antes de awaits
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Capturas estables para este ciclo de carga.
    final instId = _institucionIdCanon;

    // ✅ Canon: usar _moduleKey ya normalizada (evita dobles rutas raw/canon).
    final normalizedModuleKey = _moduleKey;
    final wantsFilter = normalizedModuleKey.isNotEmpty;

    debugPrint(
      '[ATENA][SOL] load start token=$token instId="$instId" owner="${_ownerAccountIdResolved.trim()}" perfilInst="${_institucionPerfilIdResolved.trim()}" wantsFilter=$wantsFilter moduleKey="$normalizedModuleKey"',
    );

    if (mounted) setState(() => _cargando = true);

    try {
      if (instId.isEmpty) {
        debugPrint('[ATENA][SOL] abort: empty instId');
        if (!mounted) return;
        if (token != _loadSeq) return;
        setState(() => _cargando = false);
        _snack(messenger, l10n.invalidInstitutionId);
        return;
      }

      // 🔐 PLAN GUARD (CANÓNICO) – screen operativo
      // Best-effort: cargar institución para obtener planStatus.
      try {
        final inst = await ih
            .cargarInstitucionPorId(instId)
            .timeout(const Duration(seconds: 4));

        if (!mounted) return;
        if (token != _loadSeq) return;

        if (inst != null) {
          final PlanStatus? psNullable = _planStatusForGuard(inst);

          if (!_shouldSkipPlanGuard(psNullable)) {
            final PlanStatus psNormalized = PlanHabilitacionService.normalize(
              psNullable!,
            );

            final bool operativo =
                PlanHabilitacionService.isInstitucionOperativa(psNormalized);

            if (!operativo) {
              if (mounted && token == _loadSeq) {
                setState(() => _cargando = false);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _ensureOperativoGuard(psNullable);
                });
              }
              return;
            }
          } else {
            debugPrint(
              '[ATENA][SOL] plan guard skipped (proto/trial/unknown) status=${_enumNameBestEffort(psNullable)}',
            );
          }
        } else {
          debugPrint('[ATENA][SOL] plan guard skipped: inst null');
        }
      } on TimeoutException catch (_) {
        debugPrint('[ATENA][SOL] plan guard TIMEOUT (inst load)');
      } catch (e, st) {
        debugPrint('[ATENA][SOL] plan guard ERROR $e\n$st');
      }

      final filterOk = !wantsFilter || _isValidModuleKey(normalizedModuleKey);

      if (!mounted) return;
      if (token != _loadSeq) return;
      setState(() => _moduleKeyInvalida = wantsFilter && !filterOk);

      final List<SolicitudAlumno> list;

      if (wantsFilter && filterOk) {
        list =
            await SolicitudesService.obtenerSolicitudesParaInstitucionPorModuloKey(
              institucionId: instId,
              moduleKey: normalizedModuleKey,
            ).timeout(const Duration(seconds: 8));
      } else {
        list = await SolicitudesService.obtenerSolicitudesParaInstitucion(
          institucionId: instId,
        ).timeout(const Duration(seconds: 8));
      }

      if (!mounted) return;
      if (token != _loadSeq) return;

      final pend = <SolicitudAlumno>[];
      final conf = <SolicitudAlumno>[];
      final rech = <SolicitudAlumno>[];
      final canc = <SolicitudAlumno>[];

      for (final s in list) {
        switch (s.estado) {
          case EstadoSolicitud.pendiente:
            pend.add(s);
            break;
          case EstadoSolicitud.confirmada:
            conf.add(s);
            break;
          case EstadoSolicitud.rechazada:
            rech.add(s);
            break;
          case EstadoSolicitud.canceladaPorAlumno:
          case EstadoSolicitud.canceladaPorInstitucion:
            canc.add(s);
            break;
        }
      }

      int byFechaDesc(SolicitudAlumno a, SolicitudAlumno b) =>
          b.fechaCreacion.compareTo(a.fechaCreacion);

      pend.sort(byFechaDesc);
      conf.sort(byFechaDesc);
      rech.sort(byFechaDesc);
      canc.sort(byFechaDesc);

      setState(() {
        _pendientes = pend;
        _confirmadas = conf;
        _rechazadas = rech;
        _canceladas = canc;
        _cargando = false;
      });

      debugPrint(
        '[ATENA][SOL] load done token=$token pend=${pend.length} conf=${conf.length} rech=${rech.length} canc=${canc.length}',
      );

      if (wantsFilter && !filterOk) {
        _snack(messenger, l10n.invalidModuleKeyShowingAll(normalizedModuleKey));
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      if (token != _loadSeq) return;
      setState(() => _cargando = false);
      _snack(messenger, l10n.loadErrorWithDetails('timeout'));
      debugPrint('[ATENA][SOL] load TIMEOUT token=$token');
    } catch (e) {
      if (!mounted) return;
      if (token != _loadSeq) return;

      setState(() => _cargando = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack(messenger, l10n.loadErrorWithDetails(msg));
      debugPrint('[ATENA][SOL] load ERROR token=$token $e');
    } finally {
      _booting = false;

      // ✅ Último candado anti-spinner (solo si token vigente)
      if (mounted && token == _loadSeq && _cargando) {
        setState(() => _cargando = false);
      }
    }
  }

  // =====================================================
  // Dialog responder
  // =====================================================

  Future<_RespuestaDialogResult?> _dialogResponder(
    SolicitudAlumno s, {
    required EstadoSolicitud nuevoEstado,
  }) async {
    if (!mounted) return null;

    // ✅ Capturar l10n/material ANTES del async gap (showDialog).
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);

    final isConfirm = nuevoEstado == EstadoSolicitud.confirmada;
    final isReject = nuevoEstado == EstadoSolicitud.rechazada;

    final notaCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

    final titulo = isConfirm
        ? l10n.confirmRequestTitle
        : isReject
        ? l10n.rejectRequestTitle
        : l10n.updateRequestTitle;

    final msg = isConfirm
        ? l10n.confirmRequestBody
        : isReject
        ? l10n.rejectRequestBody
        : l10n.updateRequestBody;

    try {
      final res = await showDialog<_RespuestaDialogResult>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(titulo),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg),
                  const SizedBox(height: 12),
                  Text(
                    l10n.activityWithName(s.actividadNombre),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (isReject) ...[
                    TextField(
                      controller: motivoCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.rejectionReasonOptionalLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: notaCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.noteToStudentOptionalLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: Text(material.cancelButtonLabel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    _RespuestaDialogResult(
                      nota: notaCtrl.text.trim(),
                      motivoRechazo: motivoCtrl.text.trim(),
                    ),
                  );
                },
                child: Text(l10n.accept),
              ),
            ],
          );
        },
      );
      return res;
    } finally {
      notaCtrl.dispose();
      motivoCtrl.dispose();
    }
  }

  Future<void> _responder(
    SolicitudAlumno s, {
    required EstadoSolicitud nuevoEstado,
  }) async {
    if (!mounted) return;

    // ✅ Capturar referencias antes de awaits
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (s.estado != EstadoSolicitud.pendiente) {
      _snack(messenger, l10n.requestIsNoLongerPending);
      return;
    }

    final r = await _dialogResponder(s, nuevoEstado: nuevoEstado);
    if (!mounted) return;
    if (r == null) return;

    final nota = r.nota.trim();
    final motivo = r.motivoRechazo.trim();

    try {
      await SolicitudesService.responderSolicitud(
        solicitudId: s.id,
        nuevoEstado: nuevoEstado,
        notaInstitucion: nota.isEmpty ? null : nota,
        motivoRechazo: (nuevoEstado == EstadoSolicitud.rechazada)
            ? (motivo.isEmpty ? null : motivo)
            : null,
      ).timeout(const Duration(seconds: 8));

      await _cargar();
      if (!mounted) return;

      final msg = (nuevoEstado == EstadoSolicitud.confirmada)
          ? l10n.requestConfirmed
          : (nuevoEstado == EstadoSolicitud.rechazada)
          ? l10n.requestRejected
          : l10n.requestUpdated;

      _snack(messenger, msg);
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _snack(messenger, l10n.actionErrorWithDetails('timeout'));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack(messenger, l10n.actionErrorWithDetails(msg));
    }
  }

  // =====================================================
  // ✅ DOCUMENTACIÓN desde SolicitudAlumno (owner/perfil nullable)
  // =====================================================

  static String _safeStr(String? v) => (v ?? '').trim();

  void _abrirDocumentacionDesdeSolicitud(SolicitudAlumno s) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final owner = _safeStr(s.ownerAccountId);
    final alumnoPerfilId = _safeStr(s.perfilId);

    if (owner.isEmpty || alumnoPerfilId.isEmpty) {
      _snack(messenger, l10n.cannotOpenDocumentsMissingOwnerOrProfile);
      return;
    }

    nav.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/documentos',
          arguments: <String, String>{
            // ✅ CANÓNICO: owner + perfil alumno explícitos (evita cruces).
            'ownerAccountId': owner,
            'perfilId': alumnoPerfilId, // compat (si alguien la usa)
            'alumnoPerfilId': alumnoPerfilId, // canónico explícito
            // ✅ CANÓNICO: institución explícita
            'institucionPerfilId': _institucionIdCanon,
            'institucionId': _institucionIdCanon, // compat

            'source': 'solicitud',
            'solicitudId': s.id,
          },
        ),
        builder: (_) => InstitucionDocumentosPage(
          institucionId: _institucionIdCanon,
          institucionNombre: widget.institucionNombre,
        ),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  Color _cardTint(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.colorScheme.surface;
    final alpha = (isDark ? 0.70 : 0.94);
    final a = (alpha * 255).round().clamp(0, 255);
    return base.withAlpha(a);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final nombre = widget.institucionNombre.trim().isEmpty
        ? l10n.institutionGeneric
        : widget.institucionNombre.trim();

    final subtitle = _filtroAplicado ? _moduleLabel(_moduleKey, l10n) : '';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.requestsTitleWithInstitution(nombre, subtitle)),
          actions: [
            IconButton(
              onPressed: _cargando ? null : () => unawaited(_cargar()),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.pendingWithCount(_pendientes.length)),
              Tab(text: l10n.confirmedWithCount(_confirmadas.length)),
              Tab(text: l10n.rejectedWithCount(_rechazadas.length)),
              Tab(text: l10n.cancelledWithCount(_canceladas.length)),
            ],
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_filtraPorModulo) _bannerFiltroModulo(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _cargar,
                      child: TabBarView(
                        children: [
                          _listaPendientes(_pendientes),
                          _listaReadOnly(_confirmadas),
                          _listaReadOnly(_rechazadas),
                          _listaReadOnly(_canceladas),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _bannerFiltroModulo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_moduleKeyInvalida) {
      return Material(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.invalidModuleFilterBanner(_moduleKey),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.filter_alt,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.filteringByModuleBanner(
                  _moduleLabel(_moduleKey, l10n),
                  _moduleKey,
                ),
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyList(String msg) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(child: Text(msg)),
      ],
    );
  }

  Widget _listaReadOnly(List<SolicitudAlumno> list) {
    final l10n = AppLocalizations.of(context);

    if (list.isEmpty) {
      return _emptyList(l10n.noRequestsInSection);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = list[i];
        return Card(
          color: _cardTint(context),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _cardBody(s, showActions: false),
          ),
        );
      },
    );
  }

  Widget _listaPendientes(List<SolicitudAlumno> list) {
    final l10n = AppLocalizations.of(context);

    if (list.isEmpty) {
      return _emptyList(l10n.noPendingRequests);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = list[i];
        return Card(
          color: _cardTint(context),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _cardBody(s, showActions: true),
          ),
        );
      },
    );
  }

  Widget _cardBody(SolicitudAlumno s, {required bool showActions}) {
    final l10n = AppLocalizations.of(context);

    final tipo = s.esCurricular
        ? l10n.curricularLabel
        : l10n.extracurricularLabel;

    // ✅ Curricular: grupoCurricularId es referencia primaria si existe.
    final grupoId = s.esCurricular ? s.grupoCurricularId.trim() : '';

    // Snapshot/UI/compat
    final aula = s.aula.trim();
    final turno = s.turno.trim();

    final modulo = _filtroAplicado
        ? _moduleLabel(_moduleKey, l10n)
        : _moduleLabelFromSolicitud(s, l10n);

    final owner = _safeStr(s.ownerAccountId);
    final perfil = _safeStr(s.perfilId);
    final tieneOwnerPerfil = owner.isNotEmpty && perfil.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.actividadNombre,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(l10n.studentDocumentLine(s.alumnoDocumento)),
        Text(l10n.typeLine(tipo)),

        // ✅ Extracurricular: módulo visible si corresponde.
        if (!s.esCurricular && modulo.isNotEmpty) Text(l10n.moduleLine(modulo)),

        // ✅ Curricular: referencia estable del grupo/cupo (primaria).
        // FIX analyzer: no existe curricularGroupIdLine en l10n, usamos key existente.
        if (s.esCurricular && grupoId.isNotEmpty)
          Text(l10n.groupOrClassLine(grupoId)),

        // Snapshot/UI/compat
        if (aula.isNotEmpty) Text(l10n.groupOrClassLine(aula)),
        if (turno.isNotEmpty) Text(l10n.shiftLine(turno)),

        const SizedBox(height: 6),
        Text(l10n.statusLine(_estadoLabel(s.estado, l10n))),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: tieneOwnerPerfil
              ? () => _abrirDocumentacionDesdeSolicitud(s)
              : null,
          icon: const Icon(Icons.folder_shared),
          label: Text(
            tieneOwnerPerfil
                ? l10n.requestOrViewDocumentsCta
                : l10n.documentsMissingOwnerOrProfileDisabledCta,
          ),
        ),
        if (showActions) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _responder(s, nuevoEstado: EstadoSolicitud.rechazada),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.reject),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _responder(s, nuevoEstado: EstadoSolicitud.confirmada),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.confirm),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RespuestaDialogResult {
  final String nota;
  final String motivoRechazo;

  const _RespuestaDialogResult({
    required this.nota,
    required this.motivoRechazo,
  });
}
