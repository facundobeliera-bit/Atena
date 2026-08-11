// lib/screens/instituciones/institucion_notificaciones_page.dart
//
// ATENA – NOTIFICACIONES (INSTITUCIÓN)
// CANÓNICO (OWNER / PERFIL) – SIN LEGACY
//
// Objetivo:
// - Leer SIEMPRE desde inbox OWNER (NotificacionesService.listarOwner*).
// - Filtrar por perfilId de institución (el que llega por widget).
// - Mutaciones: setLeida (owner + opcional perfil).
// - Tap inteligente: si la notificación es "Nueva solicitud" (solicitudCreada),
//   navega a InstitucionMisSolicitudesPage y aplica filtro por moduleKey si existe.
// - UI estable, sin imports ni helpers que no se usan.
//
// Nota:
// - Este screen NO asume borrado porque NotificacionesService no expone borrar().
//
// FIX (Feb 2026) – cierre analyzer:
// - ✅ NO await a PlanHabilitacionGuard.ensureOperativo (es void).
// - ✅ NO await/timeout a NotificacionesService.instance.setLeida (tu API devuelve void).
// - ✅ Evita use_of_void_result / await_only_futures.
// - ✅ Reduce use_build_context_synchronously: capturas antes de awaits + mounted checks.
// - ✅ _withOpacitySafe usa withValues(alpha: ...) (sin .red/.green/.blue deprecated).
// - ✅ FIX canónico (alineado a InstitucionAreaPage):
//    * PlanStatus REAL: preferir inst.estadoPlan.
//    * En prototipo Fase 2: NO bloquear ni redirigir por “enPrueba/trial” o status null/raro.

import 'dart:async';

import 'package:flutter/material.dart';

// ✅ L10N REAL
import '../../l10n/gen/app_localizations.dart';

// ✅ Sesión canónica
import '../../services/cuenta_service.dart';

// ✅ Fuente de verdad de notificaciones
import '../../services/notificaciones_service.dart';

// ✅ Navegación a solicitudes (tap inteligente)
import 'institucion_mis_solicitudes_page.dart';

// ✅ Helpers/modelo para PlanGuard best-effort
import '../../services/instituciones_helpers.dart' as ih;
import '../../models/instituciones/instituciones_integrado.dart';

// ✅ PLAN – Guard canónico (habilitación operativa)
import '../../guards/plan_habilitacion_guard.dart';

// ✅ PLAN – Service (normalize + regla operativa) + enum PlanStatus
import '../../services/plan_habilitacion_service.dart';

Color _withOpacitySafe(Color c, double opacity01) {
  final o = opacity01.clamp(0.0, 1.0);
  return c.withValues(alpha: o);
}

class InstitucionNotificacionesPage extends StatefulWidget {
  // En el flujo canónico: institucionId == perfilId
  final String institucionId;
  final String institucionNombre;

  const InstitucionNotificacionesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  State<InstitucionNotificacionesPage> createState() =>
      _InstitucionNotificacionesPageState();
}

class _InstitucionNotificacionesPageState
    extends State<InstitucionNotificacionesPage> {
  bool _loading = true;
  String? _error;
  String _ownerAccountId = '';

  // Lista filtrada por perfilId (institución)
  List<dynamic> _items = const [];

  // Guardia UX: evitar doble tap / doble navegación
  bool _navegando = false;

  // Hardening: evitar dobles boots/cargas
  bool _booting = false;
  int _loadSeq = 0;

  String get _perfilId => widget.institucionId.trim();

  @override
  void initState() {
    super.initState();

    // ✅ post-frame (evita l10n/theme en initState + edge cases web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _bootstrapSafe();
    });
  }

  // ─────────────────────────────────────────────
  // Bootstrap SAFE (timeout + finally)
  // ─────────────────────────────────────────────

  Future<void> _bootstrapSafe() async {
    if (!mounted) return;
    if (_booting) return;
    _booting = true;

    // Capturar textos antes de awaits (evita lint).
    final l10n = AppLocalizations.of(context);
    final msgTimeout = _snackFallbackFromL10n(l10n, 'Timeout al iniciar');
    final msgError = _snackFallbackFromL10n(l10n, 'Error al iniciar');
    final msgState = _snackFallbackFromL10n(l10n, 'Estado inválido');

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await _bootstrap().timeout(const Duration(seconds: 8));
    } on TimeoutException catch (e, st) {
      debugPrint('[ATENA][NOTI][BOOT][TIMEOUT] $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = const [];
        _error = msgTimeout;
      });
    } catch (e, st) {
      debugPrint('[ATENA][NOTI][BOOT][ERROR] $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = const [];
        _error = msgError;
      });
    } finally {
      _booting = false;

      // ✅ Último candado anti-spinner (solo si quedó en estado inconsistente)
      if (mounted && _loading && ((_error ?? '').trim().isEmpty)) {
        setState(() {
          _loading = false;
          _error = msgState;
        });
      }
    }
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    debugPrint(
      '[ATENA][NOTI] bootstrap start perfilId="$_perfilId" instNombre="${widget.institucionNombre.trim()}"',
    );

    final owner = (await _getOwnerAccountIdSafe().timeout(
      const Duration(seconds: 3),
    )).trim();

    if (!mounted) return;

    if (owner.isEmpty) {
      setState(() {
        _ownerAccountId = '';
        _items = const [];
        _error = 'Sesión no disponible'; // fallback
        _loading = false;
      });
      return;
    }

    _ownerAccountId = owner;

    if (_perfilId.isEmpty) {
      setState(() {
        _items = const [];
        _error = 'ID de institución vacío'; // fallback
        _loading = false;
      });
      return;
    }

    // 🔐 PLAN GUARD (CANÓNICO) – best-effort
    // Alineado a InstitucionAreaPage:
    // - status real: inst.estadoPlan (preferido)
    // - prototipo Fase 2: NO bloquear por trial/enPrueba/unknown/null
    try {
      final inst = await ih
          .cargarInstitucionPorId(_perfilId)
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (inst != null) {
        final PlanStatus? psNullable = _planStatusForGuard(inst);

        if (!_shouldSkipPlanGuard(psNullable)) {
          final PlanStatus psNormalized = PlanHabilitacionService.normalize(
            psNullable,
          );

          // ✅ NO await (guard es void)
          PlanHabilitacionGuard.ensureOperativo(
            context: context,
            plan: psNullable,
            institucionPerfilId: _perfilId,
            institucionNombre: widget.institucionNombre,
          );

          // Si NO está activo, el guard navega. Cortamos para evitar cargas “por atrás”.
          if (!PlanHabilitacionService.isInstitucionOperativa(psNormalized)) {
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
            return;
          }
        } else {
          debugPrint(
            '[ATENA][NOTI] plan guard skipped (proto/trial/unknown) status=${_enumNameBestEffort(psNullable)}',
          );
        }
      } else {
        debugPrint('[ATENA][NOTI] plan guard skipped: inst null');
      }
    } on TimeoutException catch (_) {
      debugPrint('[ATENA][NOTI] plan guard TIMEOUT (inst load)');
    } catch (e, st) {
      debugPrint('[ATENA][NOTI] plan guard ERROR $e\n$st');
    }

    await _cargar();
  }

  Future<String> _getOwnerAccountIdSafe() async {
    try {
      final v = await CuentaService.getSesionCuentaId();
      return (v ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  // ─────────────────────────────────────────────
  // Plan guard helpers (alineado a AreaPage)
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
    // ✅ Si no hay planStatus, NO forzamos redirección desde Notificaciones.
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

  // ✅ Extraer PlanStatus REAL (best-effort)
  // Preferido (proyecto actual): inst.estadoPlan.
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

  // ─────────────────────────────────────────────
  // Load (token + timeout + finally)
  // ─────────────────────────────────────────────

  Future<void> _cargar() async {
    final int token = ++_loadSeq;

    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final owner = _ownerAccountId.trim();
    final perfilId = _perfilId.trim();

    debugPrint(
      '[ATENA][NOTI] load start token=$token owner="$owner" perfilId="$perfilId"',
    );

    try {
      if (owner.isEmpty) {
        throw Exception('owner vacío');
      }
      if (perfilId.isEmpty) {
        throw Exception('perfilId vacío');
      }

      final list = await NotificacionesService.listarOwnerFiltradoPorPerfil(
        ownerAccountId: owner,
        perfilId: perfilId,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (token != _loadSeq) return;

      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });

      debugPrint('[ATENA][NOTI] load done token=$token items=${list.length}');
    } on TimeoutException catch (_) {
      debugPrint('[ATENA][NOTI] load TIMEOUT token=$token');
      if (!mounted) return;
      if (token != _loadSeq) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error =
            'No se pudieron cargar las notificaciones (timeout)'; // fallback
      });
    } catch (e, st) {
      debugPrint('[ATENA][NOTI] load ERROR token=$token $e\n$st');
      if (!mounted) return;
      if (token != _loadSeq) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = 'No se pudieron cargar las notificaciones'; // fallback
      });
    } finally {
      // ✅ Último candado anti-spinner si token vigente
      if (mounted && token == _loadSeq && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Mutaciones
  // ─────────────────────────────────────────────

  Future<void> _marcarLeida(dynamic noti, bool leida) async {
    if (!mounted) return;

    final owner = _ownerAccountId.trim();
    if (owner.isEmpty) return;

    final id = _readString(noti, const ['id', 'notificacionId']).trim();
    if (id.isEmpty) return;

    // Capturamos messenger y textos antes de awaits
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final msgError = _snackFallbackFromL10n(l10n, 'No se pudo actualizar');

    try {
      // ✅ FIX: tu API devuelve void → NO await / NO timeout.
      // (La mutación es best-effort.)
      NotificacionesService.instance.setLeida(
        ownerAccountId: owner,
        notificacionId: id,
        leida: leida,
        perfilId: _perfilId,
      );

      if (!mounted) return;
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      try {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(msgError)));
      } catch (_) {
        // NO-OP
      }
    }
  }

  Future<void> _onTap(dynamic noti) async {
    if (_navegando) return;
    _navegando = true;

    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final instNombre = widget.institucionNombre.trim().isEmpty
        ? _titleFallbackFromL10n(l10n, 'Institución')
        : widget.institucionNombre.trim();

    try {
      // Auto-marcar como leída al abrir (best-effort)
      try {
        await _marcarLeida(noti, true);
      } catch (_) {}

      if (!mounted) return;

      // Tap inteligente: si es solicitudCreada, ir a Mis Solicitudes con filtro moduleKey
      final tipo = _readString(noti, const ['tipo', 'type', 'evento']).trim();
      final action = _readString(noti, const ['action', 'accion']).trim();
      final esSolicitudCreada =
          tipo == 'solicitudCreada' || action == 'solicitudCreada';

      if (!esSolicitudCreada) return;

      final moduleKey = _readString(noti, const [
        'moduleKey',
        'moduloKey',
      ]).trim();

      if (!mounted) return;

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => InstitucionMisSolicitudesPage(
            institucionId: _perfilId,
            institucionNombre: instNombre,
            moduleKey: moduleKey.isEmpty ? null : moduleKey,
          ),
        ),
      );
    } catch (_) {
      // NO-OP
    } finally {
      _navegando = false;
    }
  }

  // ─────────────────────────────────────────────
  // UI helpers (theme + safe reads)
  // ─────────────────────────────────────────────

  String _titleFallbackFromL10n(AppLocalizations l10n, String fallback) {
    try {
      // ignore: avoid_dynamic_calls
      final dyn = l10n as dynamic;
      // ignore: avoid_dynamic_calls
      final v = dyn.institucionTitle;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Function) {
        final out = v();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    } catch (_) {}
    return fallback;
  }

  String _snackFallbackFromL10n(AppLocalizations l10n, String fallback) {
    try {
      // ignore: avoid_dynamic_calls
      final dyn = l10n as dynamic;
      // ignore: avoid_dynamic_calls
      final v = dyn.genericError;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Function) {
        final out = v();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    } catch (_) {}
    return fallback;
  }

  Color _cardColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _withOpacitySafe(cs.surface, isDark ? 0.70 : 0.94);
  }

  Color _chipColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _withOpacitySafe(cs.primary, isDark ? 0.20 : 0.14);
  }

  static String _readString(dynamic obj, List<String> keys) {
    try {
      if (obj is Map) {
        for (final k in keys) {
          final v = obj[k];
          if (v is String) return v;
          if (v != null) return v.toString();
        }
      }

      // Best-effort: intenta toJson() si existe
      // ignore: avoid_dynamic_calls
      final dyn = obj as dynamic;

      try {
        // ignore: avoid_dynamic_calls
        final j = dyn.toJson?.call();
        if (j is Map) {
          for (final k in keys) {
            final v = j[k];
            if (v is String) return v;
            if (v != null) return v.toString();
          }
        }
      } catch (_) {
        // NO-OP
      }
    } catch (_) {}
    return '';
  }

  static bool _readBool(dynamic obj, List<String> keys) {
    try {
      if (obj is Map) {
        for (final k in keys) {
          final v = obj[k];

          if (v is bool) return v;

          if (v is String) {
            final t = v.toLowerCase().trim();
            if (t == 'true' || t == '1' || t == 'yes' || t == 'si') return true;
            if (t == 'false' || t == '0' || t == 'no') return false;
          }

          if (v is num) return v != 0;
        }
      }

      // ignore: avoid_dynamic_calls
      final dyn = obj as dynamic;
      try {
        // ignore: avoid_dynamic_calls
        final v = dyn.leida;
        if (v is bool) return v;
      } catch (_) {}
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final titulo = (() {
      try {
        // ignore: avoid_dynamic_calls
        final dyn = l10n as dynamic;
        // ignore: avoid_dynamic_calls
        final v = dyn.institucionNotificacionesTitle;
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Function) {
          final out = v();
          if (out is String && out.trim().isNotEmpty) return out.trim();
        }
      } catch (_) {}
      return 'Notificaciones';
    })();

    final tooltipRefresh = (() {
      try {
        // ignore: avoid_dynamic_calls
        final dyn = l10n as dynamic;
        // ignore: avoid_dynamic_calls
        final v = dyn.actionRefresh;
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Function) {
          final out = v();
          if (out is String && out.trim().isNotEmpty) return out.trim();
        }
      } catch (_) {}
      return 'Actualizar';
    })();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          actions: [
            IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              tooltip: tooltipRefresh,
            ),
          ],
        ),
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final err = (_error ?? '').trim();
    if (err.isNotEmpty) {
      final labelRetry = (() {
        try {
          // ignore: avoid_dynamic_calls
          final dyn = l10n as dynamic;
          // ignore: avoid_dynamic_calls
          final v = dyn.retry;
          if (v is String && v.trim().isNotEmpty) return v.trim();
          if (v is Function) {
            final out = v();
            if (out is String && out.trim().isNotEmpty) return out.trim();
          }
        } catch (_) {}
        return 'Reintentar';
      })();

      return Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          actions: [
            IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              tooltip: tooltipRefresh,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(err, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh),
                    label: Text(labelRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final items = _items;

    final emptyText = (() {
      try {
        // ignore: avoid_dynamic_calls
        final dyn = l10n as dynamic;
        // ignore: avoid_dynamic_calls
        final v = dyn.institucionNotificacionesEmpty;
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Function) {
          final out = v();
          if (out is String && out.trim().isNotEmpty) return out.trim();
        }
      } catch (_) {}
      return 'No hay notificaciones';
    })();

    final tooltipOptions = (() {
      try {
        // ignore: avoid_dynamic_calls
        final dyn = l10n as dynamic;
        // ignore: avoid_dynamic_calls
        final v = dyn.options;
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Function) {
          final out = v();
          if (out is String && out.trim().isNotEmpty) return out.trim();
        }
      } catch (_) {}
      return 'Opciones';
    })();

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: tooltipRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: Text(
                  emptyText,
                  style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = items[index];

                  final tituloN = (() {
                    final t = _readString(n, const ['titulo', 'title']).trim();
                    return t.isNotEmpty ? t : 'Notificación';
                  })();

                  final cuerpoN = (() {
                    final t = _readString(n, const [
                      'cuerpo',
                      'body',
                      'mensaje',
                      'message',
                    ]).trim();
                    return t;
                  })();

                  final leida = _readBool(n, const ['leida', 'read', 'isRead']);

                  final moduleKey = _readString(n, const [
                    'moduleKey',
                    'moduloKey',
                  ]).trim();

                  final labelToggle = leida
                      ? 'Marcar como no leída'
                      : 'Marcar como leída';

                  return Card(
                    elevation: 0,
                    color: _cardColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onTap(n),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _chipColor(context),
                              ),
                              child: Icon(
                                leida
                                    ? Icons.notifications_none
                                    : Icons.notifications,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tituloN,
                                    style: (tt.titleSmall ?? const TextStyle())
                                        .copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: cs.onSurface,
                                        ),
                                  ),
                                  if (cuerpoN.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      cuerpoN,
                                      style:
                                          (tt.bodyMedium ?? const TextStyle())
                                              .copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                    ),
                                  ],
                                  if (moduleKey.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _chipColor(context),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          moduleKey,
                                          style:
                                              (tt.labelMedium ??
                                                      const TextStyle())
                                                  .copyWith(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: tooltipOptions,
                              onSelected: (v) async {
                                if (v == 'toggle') {
                                  await _marcarLeida(n, !leida);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(labelToggle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
