// lib/screens/instituciones/institucion_area_page.dart
//
// ATENA – INSTITUCIÓN · ÁREA OPERATIVA (CANÓNICO)
//
// Control de flujo / cierre:
// - Entrada operativa post-selector (actividadKey + workProfileId).
// - Institución: institucionId === perfilId.
// - Locks por área: InstitucionAreaGuard.openWithAreaLock (SIN locks duplicados en pages).
//
// Nota importante (riesgo controlado):
// - actividadKey es obligatoria para operar (evita colisiones de locks).
//   NO se hace fallback silencioso.
//
// ─────────────────────────────────────────────
// ESPECIFICACIÓN INCORPORADA (VACANTES v2 y emisión canónica)
// - Gestión de Vacantes evoluciona a incluir: filtros de alumnos + emitir/notificar.
// - Emisión canónica:
//    * Write SIEMPRE a inbox OWNER.
//    * Duplicado opcional a inbox PERFIL.
//    * “Emitir” además agrega evento al calendario del alumno.
// - Alcances: alumnos seleccionados / aula completa / institución.
// (Implementación: en screens/services dedicados; aquí solo se garantiza acceso correcto.)
// ─────────────────────────────────────────────────────────────────────────────
//
// ✅ FIX (feb 2026 · “no quedar cargando”):
// - Bootstrap con timeout total + timeouts por carga de institución.
// - Fallback final: si por cualquier razón quedamos en _loading=true sin error,
//   convertimos a fatalError (evita spinner infinito).
// - Validación explícita de scope (actividadKey) antes de operar (sin fallback silencioso).
//
// ✅ FIX (feb 2026 · args):
// - _resolveRouteArgsOnce() evalúa los valores RESUELTOS (no los del widget),
//   evitando loops/early-returns cuando la pantalla llega por RouteSettings.arguments.
// - HARDENING: soporta varias claves de args (workProfileId/workProfileName/profileId/profileName,
//   actividadKey/actividadKeyScope/actividadKeyResolved, actividadLabel/activityLabel).
//
// ✅ FIX (feb 2026 · bug silencioso owner institucional):
// - Si viene ownerAccountId desde el selector, lo setea en SessionService como
//   owner institucional BEST-EFFORT (sin inferir). Además soporta ownerAccountId en route args.
//
// ✅ UX CLAVE (feb 2026 · claridad):
// - AppBar muestra explícito: “<Actividad> — Administración”
//
// ✅ FIX CRÍTICO (feb 2026 · “vuelve al menú / no entra al área”):
// - PlanHabilitacionGuard debe recibir un STATUS real (PlanStatus).
// - STATUS real: inst.estadoPlan (raw) => normalize() => PlanStatus.
// - En Fase 2 (prototipo) NO bloquear por “enPrueba/trial”.
// - Unknown/null => NO operativo (comercial): redirige a Plan.
//
// ✅ REGLA NUEVA (feb 2026 · solicitada):
// - Si el scope es CURRICULAR: NO mostrar botón Extracurricular.
// - Si el scope es EXTRACURRICULAR: el botón “Vacantes” abre la gestión del área extra.
//   (Menu contextual por actividadKey; el page sigue siendo ÚNICO y canónico.)
// ─────────────────────────────────────────────────────────────────────────────
//
// ✅ AJUSTE ESTÉTICO (feb 2026 · solicitado):
// - Cards/botones “monocromáticos” y sobrios (sin amarillo saturado).
// - Solución: superficie neutralizada con Color.alphaBlend usando scrim (theme-driven).
// - Icon chip también neutral (no depende de primary).
//

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

// Modelos
import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';

// Helpers / compat (resolver institución)
import '../../services/instituciones_helpers.dart';

// ✅ Sesión canónica (logout)
import '../../services/cuenta_service.dart';

// ✅ Session v2 (owner institucional best-effort)
import '../../services/session_service.dart';

// ✅ Assets
import '../../ui/atena_assets.dart';

// ✅ Páginas operativas
import 'institucion_documentos_page.dart' as docs;
import 'institucion_extracurriculares_hub_page.dart' as extra;
import 'institucion_gestion_vacantes_page.dart' as vac;
import 'institucion_mis_solicitudes_page.dart' as sol;
import 'institucion_notificaciones_page.dart' as noti;

// ✅ Croquis
import 'institucion_croquis_aula_page.dart' as croquis;

// ✅ Locks canónicos por área
import '../../services/institucion_area_locks.dart';

// ✅ PLAN – Guard canónico
import '../../guards/plan_habilitacion_guard.dart';

// ✅ PLAN – Fuente de verdad (normalize + regla operativa)
import '../../services/plan_habilitacion_service.dart';

Color _alpha(Color c, double opacity01) {
  final o = opacity01.clamp(0.0, 1.0);
  final a = (o * 255.0).round().clamp(0, 255);
  return c.withAlpha(a);
}

/// ✅ Superficie neutralizada (tema-driven) para apagar saturación accidental.
/// Si tu cs.surface/containers están “amarillos” por theme, esto los vuelve sobrios
/// sin hardcodear colores.
Color _neutralSurface(ColorScheme cs, {required bool isDark}) {
  // En dark, más scrim; en light, apenas.
  final overlay = _alpha(cs.scrim, isDark ? 0.26 : 0.10);
  return Color.alphaBlend(overlay, cs.surface);
}

Color _neutralContainer(ColorScheme cs, {required bool isDark}) {
  // Container neutro para chips/íconos.
  final base = cs.surfaceContainerHighest;
  final overlay = _alpha(cs.scrim, isDark ? 0.18 : 0.08);
  return Color.alphaBlend(overlay, base);
}

class InstitucionAreaPage extends StatefulWidget {
  final String? ownerAccountId;

  // Canónico
  final String institucionId;
  final String institucionNombre;

  // Preferido: viene del selector (evita re-load)
  final Institucion? institucion;

  // Scope de actividad (viene del selector)
  final String? actividadKey;
  final String? actividadLabel;

  // Perfil de trabajo
  final String? workProfileId;
  final String? workProfileName;

  // Compat legacy
  final String pais;
  final String provincia;
  final String ciudad;
  final ModalidadCursado modalidad;

  const InstitucionAreaPage({
    super.key,
    this.ownerAccountId,
    required this.institucionId,
    required this.institucionNombre,
    this.institucion,
    this.actividadKey,
    this.actividadLabel,
    this.workProfileId,
    this.workProfileName,
    this.pais = 'Argentina',
    this.provincia = '',
    this.ciudad = '',
    this.modalidad = ModalidadCursado.presencial,
  });

  @override
  State<InstitucionAreaPage> createState() => _InstitucionAreaPageState();
}

class _InstitucionAreaPageState extends State<InstitucionAreaPage> {
  static const Duration _kBootstrapTimeout = Duration(seconds: 8);
  static const Duration _kLoadInstTimeout = Duration(seconds: 6);

  bool _loading = true;

  Institucion? _inst;
  String _nombreUI = '';

  String? _fatalError;

  bool _booting = false;
  bool _depsBootstrapped = false;

  bool _routeArgsResolved = false;

  // Valores resueltos
  String _actividadKeyResolved = '';
  String _actividadLabelResolved = '';
  String _workProfileIdResolved = '';
  String _workProfileNameResolved = '';

  // Owner institucional best-effort
  String _ownerAccountIdResolved = '';

  // ✅ NUEVO: scope explícito (best-effort via args)
  String _scopeTypeResolved = ''; // 'curricular' | 'extracurricular' | ''
  bool? _isExtracurricularResolved; // si viene en args

  // ID CANÓNICO (DATA)
  String get _instIdData => widget.institucionId.trim();

  String get _instIdForLocksDiag {
    try {
      final v = _instIdData;
      if (v.isEmpty) return '';
      return InstitucionAreaLockService.normalizeInstIdForLocks(v);
    } catch (_) {
      return '';
    }
  }

  bool get _hasActividadScope => _actividadKeyResolved.trim().isNotEmpty;

  bool _missingCriticalArgsResolved() {
    final a = _actividadKeyResolved.trim();
    final wp = _workProfileIdResolved.trim();
    return a.isEmpty || wp.isEmpty;
  }

  // Assets
  String get _bg => AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome);
  String get _glow => AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow);

  // ─────────────────────────────────────────────
  // Helpers
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

  // ✅ En Fase 2 (prototipo) “trial/enPrueba” NO bloquea.
  bool _isTrialPlanStatusRaw(dynamic planRaw) {
    if (planRaw == null) return false;
    final s = _enumNameBestEffort(planRaw).toLowerCase();
    if (s.isEmpty) return false;
    return s.contains('enprueba') ||
        s.contains('prueba') ||
        s.contains('trial');
  }

  // ✅ Determinar scope (CURRICULAR vs EXTRACURRICULAR) sin romper canónico.
  // Regla:
  // - Si viene explícito por args (scopeType / isExtracurricular) => eso manda.
  // - Si no, best-effort por actividadKey/label.
  bool get _isExtracurricularScope {
    // 1) explícito por args
    final st = _scopeTypeResolved.trim().toLowerCase();
    if (st == 'extracurricular' || st == 'extra') return true;
    if (st == 'curricular' || st == 'curr') return false;

    final b = _isExtracurricularResolved;
    if (b != null) return b;

    // 2) best-effort por key/label
    final k = _actividadKeyResolved.trim().toLowerCase();
    final l = _actividadLabelResolved.trim().toLowerCase();

    if (k.contains('extracurricular') ||
        k.contains('extra_') ||
        k.contains('extra|') ||
        k.contains('bloque') ||
        k.contains('modulo')) {
      return true;
    }
    if (l.contains('extracurricular') || l.startsWith('extra')) return true;

    if (k.contains('nivelcurricular') || l.contains('nivelcurricular')) {
      return false;
    }

    // Default seguro: curricular
    return false;
  }

  // ✅ Resolver BloqueExtracurricular canónicamente desde el scope actual.
  // Regla canónica del HUB: moduleKey = bloque.key (snake_case estable).
  // Por ende, el match principal es bloque.key == actividadKeyResolved (normalizado).
  BloqueExtracurricular _resolveBloqueExtracurricularForScope() {
    final key = _actividadKeyResolved.trim().toLowerCase();
    final label = _actividadLabelResolved.trim().toLowerCase();

    // 1) Match exacto por key (canónico)
    for (final b in BloqueExtracurricular.values) {
      final k = b.key.trim().toLowerCase();
      if (k.isNotEmpty && k == key) return b;
    }

    // 2) Match best-effort por label (si el selector manda label “humano”)
    if (label.isNotEmpty) {
      for (final b in BloqueExtracurricular.values) {
        final l = b.label.trim().toLowerCase();
        if (l.isNotEmpty &&
            (l == label || l.contains(label) || label.contains(l))) {
          return b;
        }
      }
    }

    // 3) Fallback estable: 'otros' si existe; si no, el primero.
    for (final b in BloqueExtracurricular.values) {
      final k = b.key.trim().toLowerCase();
      if (k == 'otros' || k == 'otro') return b;
    }

    return BloqueExtracurricular.values.first;
  }

  // ✅ FIX: NO depender de una key de l10n que puede no existir (institucionAreaAdminTitle).
  // Construimos título canónico “<Actividad> — Administración” usando keys existentes.
  String _adminTitleForActividad(AppLocalizations l10n, String actividadLabel) {
    final a = actividadLabel.trim();
    if (a.isEmpty) return l10n.institucionAreaTitle;

    // Usamos una key estable ya existente en tu app (la del menú):
    final admin = l10n.administrationUpper.trim();
    if (admin.isEmpty) return a;

    // Separador canónico (sin hardcodear traducciones):
    return '$a — $admin';
  }

  String _l10nCommonError(AppLocalizations l10n) => l10n.commonError;

  // ─────────────────────────────────────────────
  // ✅ BUILDERS CANÓNICOS (best-effort multi-firma)
  // ─────────────────────────────────────────────

  Widget _buildNotificacionesPage({required AppLocalizations l10n}) {
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;

    try {
      final ctor = noti.InstitucionNotificacionesPage.new;
      return Function.apply(ctor, const [], <Symbol, dynamic>{
            #institucionId: _instIdData,
            #institucionNombre: instNombre,
            #ownerAccountId: _ownerAccountIdResolved.trim(),
            #actividadKey: _actividadKeyResolved.trim(),
            #actividadLabel: _actividadLabelResolved.trim(),
            #workProfileId: _workProfileIdResolved.trim(),
            #workProfileName: _workProfileNameResolved.trim(),
          })
          as Widget;
    } catch (_) {}

    return noti.InstitucionNotificacionesPage(
      institucionId: _instIdData,
      institucionNombre: instNombre,
    );
  }

  Widget _buildSolicitudesPage({required AppLocalizations l10n}) {
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;

    try {
      final ctor = sol.InstitucionMisSolicitudesPage.new;
      return Function.apply(ctor, const [], <Symbol, dynamic>{
            #institucionId: _instIdData,
            #institucionNombre: instNombre,
            #ownerAccountId: _ownerAccountIdResolved.trim(),
            #actividadKey: _actividadKeyResolved.trim(),
            #actividadLabel: _actividadLabelResolved.trim(),
            #workProfileId: _workProfileIdResolved.trim(),
            #workProfileName: _workProfileNameResolved.trim(),
          })
          as Widget;
    } catch (_) {}

    return sol.InstitucionMisSolicitudesPage(
      institucionId: _instIdData,
      institucionNombre: instNombre,
    );
  }

  Widget _buildDocumentosPage({required AppLocalizations l10n}) {
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;

    try {
      final ctor = docs.InstitucionDocumentosPage.new;
      return Function.apply(ctor, const [], <Symbol, dynamic>{
            #institucionId: _instIdData,
            #institucionNombre: instNombre,
            #ownerAccountId: _ownerAccountIdResolved.trim(),
            #actividadKey: _actividadKeyResolved.trim(),
            #actividadLabel: _actividadLabelResolved.trim(),
            #workProfileId: _workProfileIdResolved.trim(),
            #workProfileName: _workProfileNameResolved.trim(),
          })
          as Widget;
    } catch (_) {}

    return docs.InstitucionDocumentosPage(
      institucionId: _instIdData,
      institucionNombre: instNombre,
    );
  }

  Widget _buildCroquisPage({required AppLocalizations l10n}) {
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;

    try {
      final ctor = croquis.InstitucionCroquisAulaPage.new;
      return Function.apply(ctor, const [], <Symbol, dynamic>{
            #institucionId: _instIdData,
            #institucionNombre: instNombre,
            #ownerAccountId: _ownerAccountIdResolved.trim(),
            #actividadKey: _actividadKeyResolved.trim(),
            #actividadLabel: _actividadLabelResolved.trim(),
            #workProfileId: _workProfileIdResolved.trim(),
            #workProfileName: _workProfileNameResolved.trim(),
            #aulaInicial: '',
            #turnoInicial: '',
          })
          as Widget;
    } catch (_) {}

    return croquis.InstitucionCroquisAulaPage(
      institucionId: _instIdData,
      institucionNombre: instNombre,
      aulaInicial: '',
      turnoInicial: '',
    );
  }

  // ✅ Helper: intentar construir una page con múltiples firmas sin caer a “mínimo”
  // (porque ese fallback suele terminar en redirects internos por args faltantes).
  Widget? _tryBuildWithNamedArgSets(
    String debugTag,
    Function ctor,
    List<Map<Symbol, dynamic>> candidates,
  ) {
    for (var i = 0; i < candidates.length; i++) {
      final m = candidates[i];
      try {
        final w = Function.apply(ctor, const [], m) as Widget;
        debugPrint(
          '[ATENA][AREA][$debugTag] ctor candidate#$i OK keys=${m.keys.toList()}',
        );
        return w;
      } catch (e) {
        debugPrint('[ATENA][AREA][$debugTag] ctor candidate#$i FAIL $e');
      }
    }
    return null;
  }

  Widget _buildVacantesPage({required AppLocalizations l10n}) {
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;

    // ✅ CANÓNICO: estos 3 SIEMPRE deben llegar a Gestión Vacantes Curricular.
    final owner = _ownerAccountIdResolved.trim();
    final actKey = _actividadKeyResolved.trim();
    final wpId = _workProfileIdResolved.trim();
    final wpName = _workProfileNameResolved.trim();

    // Hard guard (UI): si esto falta, es un bug upstream. No abrimos una screen “incompleta”.
    if (actKey.isEmpty || wpId.isEmpty) {
      debugPrint(
        '[ATENA][AREA][VACANTES] BLOCK missing args actKey="$actKey" wpId="$wpId"',
      );
      return _fatalView(context, l10n.institucionAreaSnackMissingActivityScope);
    }

    // Intentar firmas conocidas de la pantalla de vacantes, pero SIN caer a un constructor
    // mínimo que después se auto-redirige por falta de scope/workProfile.
    final ctor = vac.InstitucionGestionVacantesPage.new;

    final built = _tryBuildWithNamedArgSets('VACANTES', ctor, <
      Map<Symbol, dynamic>
    >[
      // 1) Firma “más común” (institucionId + scope + wp + owner)
      <Symbol, dynamic>{
        #institucionId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #actividadLabel: _actividadLabelResolved.trim(),
        #workProfileId: wpId,
        #workProfileName: wpName,
      },

      // 2) Variante: institucionPerfilId (en lugar de institucionId)
      <Symbol, dynamic>{
        #institucionPerfilId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #actividadLabel: _actividadLabelResolved.trim(),
        #workProfileId: wpId,
        #workProfileName: wpName,
      },

      // 3) Variante: profileId/profileName (en lugar de workProfileId/workProfileName)
      <Symbol, dynamic>{
        #institucionId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #actividadLabel: _actividadLabelResolved.trim(),
        #profileId: wpId,
        #profileName: wpName,
      },

      // 4) Variante: institucionPerfilId + profileId/profileName
      <Symbol, dynamic>{
        #institucionPerfilId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #actividadLabel: _actividadLabelResolved.trim(),
        #profileId: wpId,
        #profileName: wpName,
      },

      // 5) Variante mínima “pero CANÓNICA” (si el page solo exige IDs)
      <Symbol, dynamic>{
        #institucionId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #workProfileId: wpId,
      },

      // 6) Variante mínima “pero CANÓNICA” con institucionPerfilId
      <Symbol, dynamic>{
        #institucionPerfilId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #workProfileId: wpId,
      },

      // 7) Variante mínima “pero CANÓNICA” con profileId
      <Symbol, dynamic>{
        #institucionId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #profileId: wpId,
      },

      // 8) Variante mínima “pero CANÓNICA” con institucionPerfilId + profileId
      <Symbol, dynamic>{
        #institucionPerfilId: _instIdData,
        #institucionNombre: instNombre,
        #ownerAccountId: owner,
        #actividadKey: actKey,
        #profileId: wpId,
      },
    ]);

    if (built != null) return built;

    // Si no podemos construir la screen con scope canónico, NO abrimos algo que luego redirige.
    debugPrint(
      '[ATENA][AREA][VACANTES] FAIL build page with canonical args. '
      'Need vacantes page constructor alignment.',
    );

    return _fatalView(
      context,
      '${_l10nCommonError(l10n)}: Vacantes ctor mismatch',
    );
  }

  Widget _buildExtraHubPage({required AppLocalizations l10n}) {
    final inst = _inst;
    final instNombre = _nombreUI.isEmpty
        ? l10n.institucionGenericName
        : _nombreUI;
    final bloque = _resolveBloqueExtracurricularForScope();

    try {
      final ctor = extra.InstitucionExtracurricularesHubPage.new;
      return Function.apply(ctor, const [], <Symbol, dynamic>{
            #institucionId: _instIdData,
            #institucionNombre: instNombre,
            #institucion: inst,
            #ownerAccountId: _ownerAccountIdResolved.trim(),
            #actividadKey: _actividadKeyResolved.trim(),
            #actividadLabel: _actividadLabelResolved.trim(),
            #workProfileId: _workProfileIdResolved.trim(),
            #workProfileName: _workProfileNameResolved.trim(),
            #bloque: bloque,
          })
          as Widget;
    } catch (_) {}

    return extra.InstitucionExtracurricularesHubPage(
      institucionId: _instIdData,
      institucionNombre: instNombre,
      bloque: bloque,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _bootstrapSafe();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_depsBootstrapped) {
      _depsBootstrapped = true;

      _resolveRouteArgsOnce();

      try {
        // ignore: discarded_futures
        precacheImage(AssetImage(_bg), context);
        // ignore: discarded_futures
        precacheImage(AssetImage(_glow), context);
      } catch (_) {}
    } else {
      _resolveRouteArgsOnce();
    }

    if (_loading && !_booting) {
      // ignore: discarded_futures
      _bootstrapSafe();
    }
  }

  void _resolveRouteArgsOnce() {
    if (_routeArgsResolved && !_missingCriticalArgsResolved()) return;

    // 1) Preferir constructor
    _actividadKeyResolved = (widget.actividadKey ?? '').trim();
    _actividadLabelResolved = (widget.actividadLabel ?? '').trim();
    _workProfileIdResolved = (widget.workProfileId ?? '').trim();
    _workProfileNameResolved = (widget.workProfileName ?? '').trim();
    _ownerAccountIdResolved = (widget.ownerAccountId ?? '').trim();

    // 2) Completar desde RouteSettings.arguments
    try {
      final route = ModalRoute.of(context);
      if (route == null && _missingCriticalArgsResolved()) return;

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

        bool? readBool(List<String> keys) {
          for (final k in keys) {
            final v = args[k];
            if (v == null) continue;
            if (v is bool) return v;
            if (v is num) return v != 0;
            final s = v.toString().trim().toLowerCase();
            if (s == 'true' ||
                s == '1' ||
                s == 'si' ||
                s == 'sí' ||
                s == 'yes') {
              return true;
            }
            if (s == 'false' || s == '0' || s == 'no') return false;
          }
          return null;
        }

        if (_actividadKeyResolved.isEmpty) {
          _actividadKeyResolved = readString(const [
            'actividadKey',
            'actividadKeyScope',
            'actividadKeyResolved',
            'activityKey',
            'activityKeyScope',
          ]);
        }

        if (_actividadLabelResolved.isEmpty) {
          _actividadLabelResolved = readString(const [
            'actividadLabel',
            'activityLabel',
            'actividadNombre',
            'activityName',
          ]);
        }

        if (_workProfileIdResolved.isEmpty) {
          _workProfileIdResolved = readString(const [
            'workProfileId',
            'profileId',
            'wpId',
          ]);
        }

        if (_workProfileNameResolved.isEmpty) {
          _workProfileNameResolved = readString(const [
            'workProfileName',
            'profileName',
            'wpName',
          ]);
        }

        if (_ownerAccountIdResolved.isEmpty) {
          _ownerAccountIdResolved = readString(const [
            'ownerAccountId',
            'ownerId',
          ]);
        }

        // ✅ scope explícito (si el selector lo manda)
        _scopeTypeResolved = readString(const [
          'scopeType',
          'actividadScopeType',
        ]);

        _isExtracurricularResolved = readBool(const [
          'isExtracurricular',
          'extracurricularScope',
        ]);
      }
    } catch (_) {}

    // Fallback legacy SOLO para WP (NO para actividadKey)
    if (_workProfileIdResolved.isEmpty) _workProfileIdResolved = 'wp_1';

    // CANÓNICO: actividadKey normalizada para scope (key-safe)
    if (_actividadKeyResolved.trim().isNotEmpty) {
      try {
        _actividadKeyResolved =
            InstitucionAreaLockService.normalizeActividadKeyForScope(
              _actividadKeyResolved,
            ).trim();
      } catch (_) {}
    }

    // Normalizar WP por actividad SI hay scope
    if (_actividadKeyResolved.trim().isNotEmpty) {
      try {
        _workProfileIdResolved =
            InstitucionAreaLockService.normalizeProfileIdForActividad(
              profileId: _workProfileIdResolved,
              actividadKey: _actividadKeyResolved,
            );
      } catch (_) {}
    }

    _routeArgsResolved = true;
  }

  Future<void> _setInstOwnerBestEffort(String ownerAccountId) async {
    final o = ownerAccountId.trim();
    if (o.isEmpty) return;

    try {
      await SessionService.setInstitucionOwnerAccountId(
        o,
      ).timeout(const Duration(seconds: 3));
      return;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final dyn = SessionService as dynamic;
      await (dyn.setInstitucionOwnerAccountId(ownerAccountId: o) as Future)
          .timeout(const Duration(seconds: 3));
      return;
    } catch (_) {}
  }

  dynamic _planRawForGuard(Institucion inst) {
    try {
      return inst.estadoPlan;
    } catch (_) {
      return null;
    }
  }

  void _applyPlanGuardIfNeeded(Institucion inst) {
    if (!mounted) return;

    final raw = _planRawForGuard(inst);

    // ✅ En prueba/trial: NO bloquear (Fase 2)
    if (_isTrialPlanStatusRaw(raw)) {
      debugPrint(
        '[ATENA][AREA][PLAN-GUARD] allow trial raw=${_enumNameBestEffort(raw)}',
      );
      return;
    }

    // ✅ CANÓNICO: siempre normalizar => PlanStatus tipado
    final PlanStatus normalized = PlanHabilitacionService.normalize(raw);

    debugPrint(
      '[ATENA][AREA][PLAN-GUARD] raw=${_enumNameBestEffort(raw)} normalized=$normalized '
      'owner=${_ownerAccountIdResolved.trim()} instId=$_instIdData',
    );

    try {
      PlanHabilitacionGuard.ensureOperativo(
        context: context,
        plan: normalized,
        ownerAccountId: _ownerAccountIdResolved.trim(),
        institucionPerfilId: _instIdData,
        institucionNombre: _nombreUI.isEmpty
            ? widget.institucionNombre
            : _nombreUI,
      );
    } catch (_) {}
  }

  Future<void> _bootstrapSafe() async {
    if (!mounted) return;
    if (_booting) return;

    _booting = true;

    if (mounted) {
      setState(() {
        _loading = true;
        _fatalError = null;
      });
    }

    try {
      _resolveRouteArgsOnce();
    } catch (_) {}

    try {
      final owner = _ownerAccountIdResolved.trim();
      if (owner.isNotEmpty) {
        await _setInstOwnerBestEffort(owner);
      }
    } catch (_) {}

    try {
      await _bootstrap().timeout(_kBootstrapTimeout);
    } on TimeoutException catch (e, st) {
      debugPrint('[ATENA][AREA][BOOT][TIMEOUT] $e\n$st');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _fatalError = '${_l10nCommonError(l10n)}: timeout';
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[ATENA][AREA][BOOT][ERROR] $e\n$st');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _fatalError = '${_l10nCommonError(l10n)}: $e';
        _loading = false;
      });
    } finally {
      _booting = false;

      if (mounted && _loading && ((_fatalError ?? '').trim().isEmpty)) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _fatalError = '${_l10nCommonError(l10n)}: state';
          _loading = false;
        });
      }
    }
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    _resolveRouteArgsOnce();

    debugPrint(
      '[ATENA][AREA] open instIdData=$_instIdData instIdForLocksDiag=$_instIdForLocksDiag '
      'actividadKey=$_actividadKeyResolved actividadLabel=$_actividadLabelResolved '
      'workProfileId=$_workProfileIdResolved workProfileName=$_workProfileNameResolved '
      'ownerAccountId=$_ownerAccountIdResolved '
      'scopeType=$_scopeTypeResolved isExtra=$_isExtracurricularResolved '
      'hasInstitucionFromSelector=${widget.institucion != null}',
    );

    final l10n = AppLocalizations.of(context);

    if (_instIdData.isEmpty) {
      if (!mounted) return;
      setState(() {
        _fatalError = l10n.institucionAreaErrorEmptyId;
        _loading = false;
      });
      return;
    }

    if (!_hasActividadScope) {
      if (!mounted) return;
      setState(() {
        _fatalError = l10n.institucionAreaMissingActivityHint;
        _loading = false;
      });
      return;
    }

    final instFromSelector = widget.institucion;
    if (instFromSelector != null) {
      _inst = instFromSelector;
      _nombreUI = _resolveNombreUI(instFromSelector);

      _applyPlanGuardIfNeeded(instFromSelector);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _fatalError = null;
      });
      return;
    }

    Institucion? perfil;
    try {
      debugPrint(
        '[ATENA][AREA] resolving institucion via helpers by instIdData=$_instIdData',
      );

      perfil = await cargarInstitucionCachePorId(
        _instIdData,
      ).timeout(_kLoadInstTimeout);

      perfil ??= await cargarInstitucionPorId(
        _instIdData,
      ).timeout(_kLoadInstTimeout);
    } on TimeoutException catch (e, st) {
      debugPrint('[ATENA][AREA][LOAD-INST][TIMEOUT] $e\n$st');
      perfil = null;
    } catch (e, st) {
      debugPrint('[ATENA][AREA][LOAD-INST][ERROR] $e\n$st');
      perfil = null;
    }

    if (perfil == null) {
      if (!mounted) return;
      setState(() {
        _fatalError = l10n.institucionAreaErrorLoadFailed;
        _loading = false;
      });
      return;
    }

    _inst = perfil;
    _nombreUI = _resolveNombreUI(perfil);

    _applyPlanGuardIfNeeded(perfil);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _fatalError = null;
    });
  }

  String _resolveNombreUI(Institucion? inst) {
    final n1 = (inst?.nombre ?? '').trim();
    if (n1.isNotEmpty) return n1;

    final n2 = widget.institucionNombre.trim();
    if (n2.isNotEmpty) return n2;

    return AppLocalizations.of(context).institucionGenericName;
  }

  Future<void> _irAHomeHardReset() async {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _logout() async {
    try {
      await CuentaService.logoutCuenta();
    } catch (_) {}
    await _irAHomeHardReset();
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _fatalError = null;
    });
    await _bootstrapSafe();
  }

  bool _curricularHabilitado(Institucion inst) {
    try {
      return inst.planSafe.niveles.any((n) => n.habilitado == true);
    } catch (_) {
      return false;
    }
  }

  bool _extracurricularHabilitado(Institucion inst) {
    try {
      return inst.planSafe.modulos.any((m) => m.habilitado == true);
    } catch (_) {
      return false;
    }
  }

  bool _croquisHabilitado(Institucion inst) => true;

  // ✅ Cards “botón” sobrias
  Color _cardColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = _neutralSurface(cs, isDark: isDark);
    return _alpha(base, isDark ? 0.78 : 0.92);
  }

  // ✅ Icon-chip neutro (no depende de primary)
  Color _chipColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = _neutralContainer(cs, isDark: isDark);
    return _alpha(base, isDark ? 0.92 : 0.98);
  }

  Widget _withBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlay = _alpha(cs.scrim, isDark ? 0.30 : 0.08);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _bg,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) =>
              ColoredBox(color: cs.surface),
        ),
        ColoredBox(color: overlay),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
              child: Image.asset(
                _glow,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _opCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool locked = false,
    String? semanticsLabel,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel ?? title,
      hint: subtitle,
      child: Card(
        color: _cardColor(context),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _chipColor(context),
                    border: Border.all(color: _alpha(cs.outlineVariant, 0.35)),
                  ),
                  child: Icon(icon, color: cs.onSurface),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: (tt.titleMedium ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWithLock({
    required InstitucionAreaKey area,
    required WidgetBuilder builder,
  }) async {
    final inst = _inst;
    final l10n = AppLocalizations.of(context);

    if (_instIdData.isEmpty) {
      _snack(l10n.institucionAreaErrorEmptyId);
      return;
    }

    if (!_hasActividadScope) {
      _snack(l10n.institucionAreaSnackMissingActivityScope);
      return;
    }

    if (inst == null) {
      _snack(l10n.institucionAreaSnackNoInstitucion);
      return;
    }

    final resolvedWorkProfileName = _workProfileNameResolved.trim().isNotEmpty
        ? _workProfileNameResolved.trim()
        : l10n.institucionAreaDefaultWorkProfileName;

    final profileIdScoped =
        InstitucionAreaLockService.normalizeProfileIdForActividad(
          profileId: _workProfileIdResolved,
          actividadKey: _actividadKeyResolved,
        );

    final messenger = ScaffoldMessenger.of(context);

    final ok = await InstitucionAreaGuard.openWithAreaLock(
      context: context,
      instId: _instIdData,
      actividadKey: _actividadKeyResolved,
      profileId: profileIdScoped,
      profileName: resolvedWorkProfileName,
      area: area,
      builder: builder,
      enableAutoRefresh: true,
      refreshEvery: const Duration(seconds: 20),
      institucion: inst,
      institucionNombre: _nombreUI,
    );

    if (!mounted) return;

    if (!ok) {
      final msg = l10n.institucionAreaSnackAreaInUse;
      try {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      } catch (_) {
        _snack(msg);
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    final clean = msg.trim();
    if (clean.isEmpty) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {}
  }

  Widget _fatalView(BuildContext context, String msg) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.institucionAreaTitle),
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.actionRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _irAHomeHardReset,
                      icon: const Icon(Icons.home),
                      label: Text(l10n.actionBackHome),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _logout,
                      child: Text(l10n.actionLogout),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      debugPrint('[ATENA][AREA] build -> loading=true');
      return Scaffold(
        appBar: AppBar(title: Text(l10n.institucionAreaTitle)),
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final fatal = (_fatalError ?? '').trim();
    if (fatal.isNotEmpty) return _fatalView(context, fatal);

    final inst = _inst;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final actividadLabel = _actividadLabelResolved.trim().isEmpty
        ? l10n.institucionAreaDefaultActivityLabel
        : _actividadLabelResolved.trim();

    final workProfileName = _workProfileNameResolved.trim().isEmpty
        ? l10n.institucionAreaDefaultWorkProfileName
        : _workProfileNameResolved.trim();

    final ubicacion = (inst == null)
        ? ''
        : <String>[
            inst.pais.trim(),
            inst.provincia.trim(),
            inst.ciudad.trim(),
          ].where((x) => x.isNotEmpty).join(' • ');

    final curricularOk = inst == null ? false : _curricularHabilitado(inst);
    final extraOk = inst == null ? false : _extracurricularHabilitado(inst);
    final croquisOk = inst == null ? false : _croquisHabilitado(inst);

    final canOperate = _instIdData.isNotEmpty && _hasActividadScope;

    final isExtraScope = _isExtracurricularScope;

    final appBarBase = _neutralSurface(
      cs,
      isDark: theme.brightness == Brightness.dark,
    );
    final appBarBg = _alpha(
      appBarBase,
      theme.brightness == Brightness.dark ? 0.22 : 0.10,
    );

    final appBarTitle = _adminTitleForActividad(l10n, actividadLabel);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: appBarBg,
        surfaceTintColor: _alpha(cs.surfaceTint, 0.0),
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.actionRefresh,
          ),
          TextButton(onPressed: _logout, child: Text(l10n.actionLogout)),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const SizedBox(height: 44),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: _cardColor(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreUI.isEmpty
                            ? l10n.institucionGenericName
                            : _nombreUI,
                        style: (tt.titleMedium ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.institucionAreaIdLine(_instIdData),
                        style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (ubicacion.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.institucionAreaLocationLine(ubicacion),
                          style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        l10n.institucionAreaActivityLine(appBarTitle),
                        style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.institucionAreaWorkProfileLine(workProfileName),
                        style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.institucionAreaAccessLine(curricularOk, extraOk),
                        style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (!canOperate) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.institucionAreaMissingActivityHint,
                          style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _opCard(
                icon: Icons.notifications,
                title: l10n.institucionAreaCardNotificationsTitle,
                subtitle: l10n.institucionAreaCardNotificationsSubtitle,
                semanticsLabel: l10n.institucionAreaSemanticsOpenNotifications,
                onTap: !canOperate
                    ? null
                    : () => _openWithLock(
                        area: InstitucionAreaKey.notificaciones,
                        builder: (_) => _buildNotificacionesPage(l10n: l10n),
                      ),
              ),
              _opCard(
                icon: Icons.inbox,
                title: l10n.institucionAreaCardSolicitudesTitle,
                subtitle: l10n.institucionAreaCardSolicitudesSubtitle,
                semanticsLabel: l10n.institucionAreaSemanticsOpenSolicitudes,
                onTap: !canOperate
                    ? null
                    : () => _openWithLock(
                        area: InstitucionAreaKey.solicitudes,
                        builder: (_) => _buildSolicitudesPage(l10n: l10n),
                      ),
              ),

              // ✅ BOTÓN CONTEXTUAL “VACANTES”
              if (isExtraScope)
                (extraOk
                    ? _opCard(
                        icon: Icons.extension,
                        title: l10n.institucionAreaCardVacantesTitle,
                        subtitle: l10n.institucionAreaCardExtraHubSubtitle,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsOpenExtraHub,
                        onTap: !canOperate
                            ? null
                            : () => _openWithLock(
                                area: InstitucionAreaKey.extracurriculares,
                                builder: (_) => _buildExtraHubPage(l10n: l10n),
                              ),
                      )
                    : _opCard(
                        icon: Icons.extension,
                        title: l10n.institucionAreaCardVacantesTitle,
                        subtitle:
                            l10n.institucionAreaCardExtraHubLockedSubtitle,
                        locked: true,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsExtraHubLocked,
                        onTap: null,
                      ))
              else
                (!curricularOk
                    ? _opCard(
                        icon: Icons.school,
                        title: l10n.institucionAreaCardVacantesTitle,
                        subtitle:
                            l10n.institucionAreaCardVacantesLockedSubtitle,
                        locked: true,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsVacantesLocked,
                        onTap: null,
                      )
                    : _opCard(
                        icon: Icons.school,
                        title: l10n.institucionAreaCardVacantesTitle,
                        subtitle: l10n.institucionAreaCardVacantesSubtitle,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsOpenVacantes,
                        onTap: !canOperate
                            ? null
                            : () => _openWithLock(
                                area: InstitucionAreaKey.vacantes,
                                builder: (_) => _buildVacantesPage(l10n: l10n),
                              ),
                      )),

              _opCard(
                icon: Icons.folder_shared,
                title: l10n.institucionAreaCardDocumentacionTitle,
                subtitle: l10n.institucionAreaCardDocumentacionSubtitle,
                semanticsLabel: l10n.institucionAreaSemanticsOpenDocumentacion,
                onTap: !canOperate
                    ? null
                    : () => _openWithLock(
                        area: InstitucionAreaKey.documentacion,
                        builder: (_) => _buildDocumentosPage(l10n: l10n),
                      ),
              ),

              const SizedBox(height: 10),
              const Divider(),

              // ✅ Croquis solo en scope curricular
              if (!isExtraScope)
                (croquisOk
                    ? _opCard(
                        icon: Icons.grid_on,
                        title: l10n.institucionAreaCardCroquisTitle,
                        subtitle: l10n.institucionAreaCardCroquisSubtitle,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsOpenCroquis,
                        onTap: !canOperate
                            ? null
                            : () => _openWithLock(
                                area: InstitucionAreaKey.croquis,
                                builder: (_) => _buildCroquisPage(l10n: l10n),
                              ),
                      )
                    : _opCard(
                        icon: Icons.grid_on,
                        title: l10n.institucionAreaCardCroquisTitle,
                        subtitle: l10n.institucionAreaCardCroquisLockedSubtitle,
                        locked: true,
                        semanticsLabel:
                            l10n.institucionAreaSemanticsCroquisLocked,
                        onTap: null,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
