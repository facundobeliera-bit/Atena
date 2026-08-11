// lib/screens/instituciones/institucion_plan_page.dart
//
// ATENA – INSTITUCIÓN / PLAN (FASE 2, LOCAL, SIN PAGOS REALES)
// -----------------------------------------------------------------------------
// Objetivo Fase 2:
// - MODO REGISTRO: recibe un “draft” del registro (datos + módulos seleccionados)
//   y crea cuenta + perfil + plan (tipoPlan/estadoPlan/planInicio/planFin).
// - MODO GESTIÓN: permite VER / CAMBIAR PLAN de una institución existente.
//
// CANÓNICO (CIERRE COMERCIAL):
// - Este archivo NO decide si la institución es operativa.
// - SOLO persiste: tipoPlan + estadoPlan + planInicio + planFin.
// - La habilitación real vive en PlanHabilitacionService (afuera de este archivo).
//
// i18n + Theme:
// - Strings via AppLocalizations (ARB) BUT: L10N SAFE (best-effort, sin inventar keys).
// - Colores via Theme/ColorScheme.
//
// ✅ FIX CRÍTICO (feb 2026):
// - CANÓNICO: Institucion.id == institucionPerfilId (perfil institución).
//
// ✅ FIX (feb 2026 · ROUTER):
// - La ruta /institucion/plan puede entrar sin constructor con args (pushNamed).
//   Esta pantalla tolera: widget params OR ModalRoute.arguments (best-effort).
//
// ✅ HARDENING (feb 2026):
// - Si entra sin draft y sin args suficientes para modo gestión, NO crashea:
//   muestra error simple y permite volver.
//
// ✅ CAMBIO FUNCIONAL (feb 2026 · CIERRE DE ACTIVIDADES EN PLAN):
// - La selección de ACTIVIDADES (niveles curriculares + módulos extracurriculares)
//   se gestiona ACÁ (PlanPage), para poder “cambiar o extender” actividades junto al plan.
// - El selector de actividad (Administración) debe LEER lo habilitado desde planConfig.
//
// ✅ CAMBIO (feb 2026 · UX CANÓNICA):
// - Se elimina “Recordarme” del REGISTRO. El “Recordarme” vive solo en LOGIN.
//   Por eso el draft ya NO trae recordarme.
//
// ✅ CAMBIO (feb 2026 · PRICING POR MÓDULO + DESCUENTO + PROMO):
// - Curricular: cada NIVEL seleccionado suma USD 10.
// - Extracurricular: cada MÓDULO seleccionado suma USD 15.
// - Descuento: 5% sobre el TOTAL de módulos si cantidad total >= 3 (aplica a Standard y Premium).
// - Promo: “ATHENA2026” = 1 mes gratis (100% off), cupo 100 instituciones.
//
// ✅ ESTÉTICA CANÓNICA (feb 2026 · fondo institucional):
// - Fondo consistente: base (asset) + scrim por ColorScheme + glow sutil.
// - Dark mode: alpha/contraste ajustado SIN withOpacity deprecated (usa withValues).
// - Stack expand + Positioned.fill para evitar fondos “cortados”.
// - Superficie neutralizada (scrim-blend) para evitar “amarillos saturados” por theme.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/cuenta_service.dart';
import '../../services/institucion_service.dart';
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';
import 'institucion_menu_page.dart';

// =============================================================================
// PROMO (TOP-LEVEL) – necesario para const map + scopes fuera del State
// =============================================================================

const String kPromoCodeAthena2026 = 'ATHENA2026';
const String kPromoUsedCounterAthena2026 = 'promo_used_ATHENA2026';
const String kPromoUsedOwnersAthena2026 = 'promo_owners_ATHENA2026';
const int kPromoMaxCuposAthena2026 = 100;

// =============================================================================
// Draft (de InstitucionRegistroPage)
// =============================================================================

class InstitucionRegistroDraft {
  final String nombre;
  final String cuit;
  final String direccion;

  final String pais;
  final String provincia;
  final String ciudad;

  final ModalidadCursado modalidad;

  final String email;
  final String telefono;
  final String pass;

  final TipoInstitucion tipo;

  final List<NivelCurricular> nivelesSeleccionados;
  final List<BloqueExtracurricular> bloquesSeleccionados;

  const InstitucionRegistroDraft({
    required this.nombre,
    required this.cuit,
    required this.direccion,
    required this.pais,
    required this.provincia,
    required this.ciudad,
    required this.modalidad,
    required this.email,
    required this.telefono,
    required this.pass,
    required this.tipo,
    required this.nivelesSeleccionados,
    required this.bloquesSeleccionados,
  });

  bool get tieneCurricular => nivelesSeleccionados.isNotEmpty;
  bool get tieneExtracurricular => bloquesSeleccionados.isNotEmpty;
}

// =============================================================================
// Plan tiers
// =============================================================================

enum _TierCurricular { standard, premium }

enum _TierExtracurricular { basico, premium }

// =============================================================================
// Helpers estética (theme-driven, neutralización)
// =============================================================================

Color _alpha(Color c, double opacity01) {
  final o = opacity01.clamp(0.0, 1.0);
  final a = (o * 255.0).round().clamp(0, 255);
  return c.withAlpha(a);
}

Color _neutralSurface(ColorScheme cs, {required bool isDark}) {
  final overlay = _alpha(cs.scrim, isDark ? 0.26 : 0.10);
  return Color.alphaBlend(overlay, cs.surface);
}

// =============================================================================
// Page
// =============================================================================

class InstitucionPlanPage extends StatefulWidget {
  /// Registro (si viene desde registro)
  final InstitucionRegistroDraft? draft;

  /// Gestión (si viene por router / menú)
  final String? ownerAccountId;
  final String? institucionPerfilId;
  final String? institucionNombre;

  /// ✅ Constructor tolerante a router: permite entrar SIN draft (modo gestión por args).
  const InstitucionPlanPage({
    super.key,
    this.draft,
    this.ownerAccountId,
    this.institucionPerfilId,
    this.institucionNombre,
  });

  // ✅ Limpieza analyzer: prefer_initializing_formals
  const InstitucionPlanPage.manage({
    super.key,
    required this.ownerAccountId,
    required this.institucionPerfilId,
    this.institucionNombre,
  }) : draft = null;

  /// ✅ CANÓNICO (hardening):
  /// - Para modo gestión, el mínimo real para poder operar datos es institucionPerfilId.
  /// - ownerAccountId es "recomendado" (PlanHabilitacionGuard puede no mandarlo).
  bool get isManageMode =>
      draft == null && (institucionPerfilId ?? '').trim().isNotEmpty;

  @override
  State<InstitucionPlanPage> createState() => _InstitucionPlanPageState();
}

class _InstitucionPlanPageState extends State<InstitucionPlanPage> {
  bool _cargando = false;

  final _codigoCtrl = TextEditingController();
  _PromoResult? _promo;
  bool _mostrarCodigo = false;

  _TierCurricular _tierCur = _TierCurricular.standard;
  _TierExtracurricular _tierExt = _TierExtracurricular.basico;

  _PlanCalculo _calc = _PlanCalculo.zero();

  Institucion? _instActual;

  // Args por ruta nombrada (PlanHabilitacionGuard / InstitucionMenuPage)
  String _routeOwnerId = '';
  String _routeInstPerfilId = '';
  String _routeNombre = '';
  String _routeTipoPlan = '';

  // ✅ Guard puede mandar PlanStatus tipado (capturamos y logueamos para evitar unused_field).
  Object? _routePlanStatus;

  // HARDENING: si entra sin data suficiente (sin draft y sin args mínimos), evitamos crash.
  bool _missingEntryData = false;

  // ✅ Selecciones EDITABLES (fuente de verdad del planConfig a persistir)
  final List<NivelCurricular> _nivelesSel = <NivelCurricular>[];
  final List<BloqueExtracurricular> _bloquesSel = <BloqueExtracurricular>[];

  bool _selectionsSeeded = false;

  // ✅ HARDENING ROUTER: ModalRoute.arguments se lee en didChangeDependencies
  bool _routeArgsRead = false;
  bool _manageLoadRequested = false;

  // Assets
  String get _bg => AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome);
  String get _glow => AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow);

  @override
  void initState() {
    super.initState();

    // Registro: seed inmediato desde draft (no depende de route args).
    final d = widget.draft;
    if (d != null) {
      _seedSelectionsFromDraft(d);
      _recompute(); // ✅ puro (sin context)
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Precaches best-effort
    try {
      // ignore: discarded_futures
      precacheImage(AssetImage(_bg), context);
      // ignore: discarded_futures
      precacheImage(AssetImage(_glow), context);
    } catch (_) {}

    if (!_routeArgsRead) {
      _routeArgsRead = true;
      _readRouteArgumentsBestEffort();

      if (_routePlanStatus != null) {
        debugPrint('[ATENA][PLAN] routePlanStatus=$_routePlanStatus');
      }

      if (widget.draft == null) {
        if (_isManageEffective) {
          if (!_manageLoadRequested) {
            _manageLoadRequested = true;
            // ignore: discarded_futures
            _loadManageInstitution();
          }
        } else {
          if (!_missingEntryData) {
            setState(() {
              _missingEntryData = true;
              _cargando = false;
              _instActual = null;
            });
          }
        }
      } else {
        // Registro: por si un router mete tipoPlan, seed tiers best-effort
        if (_routeTipoPlan.isNotEmpty) {
          _seedTiersFromTipoPlan(_routeTipoPlan);
          _recompute();
        }
      }
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  // =============================================================================
  // FIX COMPILACIÓN: cargar institución por ID (best-effort, sin acoplar API)
  // =============================================================================

  Future<Institucion?> _cargarInstitucionPorIdBestEffort(
    String institucionId,
  ) async {
    final id = institucionId.trim();
    if (id.isEmpty) return null;

    // Intentamos varias APIs posibles del InstitucionService sin romper compilación.
    try {
      final dyn = InstitucionService as dynamic;

      try {
        final r = await dyn.cargarInstitucionPorId(id);
        if (r is Institucion?) return r;
      } catch (_) {}

      try {
        final r = await dyn.getInstitucionPorId(id);
        if (r is Institucion?) return r;
      } catch (_) {}

      try {
        final r = await dyn.getById(id);
        if (r is Institucion?) return r;
      } catch (_) {}

      try {
        final r = await dyn.read(id);
        if (r is Institucion?) return r;
      } catch (_) {}

      try {
        final r = await dyn.cargarInstitucion(id);
        if (r is Institucion?) return r;
      } catch (_) {}
    } catch (_) {}

    return null;
  }

  // =============================================================================
  // L10N SAFE (best-effort, sin inventar keys)
  // =============================================================================

  // IMPORTANTE: usar un tipo de función explícito evita que el compilador web
  // tenga que emitir una invocación de dart:core Function() dinámica. El código
  // anterior usaba `m is Function` + `m()`, que podía generar InvalidType(<invalid>)
  // durante la compilación DDC. No cambia la lógica de selección de traducciones.
  String _l10nTxt(
    AppLocalizations l10n,
    List<String Function()> cands,
    String fallback,
  ) {
    try {
      for (final candidate in cands) {
        final out = candidate();
        if (out.trim().isNotEmpty) return out.trim();
      }
    } catch (_) {}
    return fallback;
  }

  String _tPlanUpper(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).planUpper,
    () => (l10n as dynamic).planTitle,
  ], 'PLAN');

  String _tSummaryLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).summaryLabel,
    () => (l10n as dynamic).summary,
  ], 'Resumen');

  String _tCurricularLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).curricularLabel,
    () => (l10n as dynamic).curricular,
  ], 'Curricular');

  String _tExtracurricularLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).extracurricularLabel,
    () => (l10n as dynamic).extracurricular,
  ], 'Extracurricular');

  String _tInstitutionGeneric(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).institutionGeneric,
    () => (l10n as dynamic).institucionGenericName,
  ], 'Institución');

  String _tCommonError(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).commonError,
    () => (l10n as dynamic).error,
  ], 'Error');

  String _tRefresh(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionRefresh,
    () => (l10n as dynamic).refresh,
  ], 'Refrescar');

  String _tBack(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionBack,
    () => (l10n as dynamic).back,
    () => (l10n as dynamic).commonBack,
  ], 'Volver');

  String _tClear(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionClear,
    () => (l10n as dynamic).clear,
    () => (l10n as dynamic).commonClear,
  ], 'Limpiar');

  String _tApply(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionApply,
    () => (l10n as dynamic).apply,
  ], 'Aplicar');

  String _tSave(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionSave,
    () => (l10n as dynamic).save,
    () => (l10n as dynamic).commonSave,
  ], 'Guardar');

  String _tConfirm(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionConfirm,
    () => (l10n as dynamic).confirm,
  ], 'Confirmar');

  String _tPlanCardSubtitle(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).planCardSubtitle,
  ], 'Seleccioná el plan para las actividades habilitadas.');

  String _tAccountLabel(AppLocalizations l10n, String ownerId) => _l10nTxt(
    l10n,
    [() => (l10n as dynamic).accountLabel?.call(ownerId)],
    'Cuenta: $ownerId',
  );

  String _tInstitutionProfileIdLabel(AppLocalizations l10n, String perfilId) =>
      _l10nTxt(l10n, [
        () => (l10n as dynamic).institutionProfileIdLabel?.call(perfilId),
      ], 'Perfil: $perfilId');

  String _tAtLeastOne(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).atLeastOneActivityRequired,
  ], 'Seleccioná al menos 1 actividad.');

  // Etiqueta “Código promo” sin inventar keys (best-effort)
  String _tPromoCodeLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).promoCodeLabel,
    () => (l10n as dynamic).couponCodeLabel,
  ], 'Código promo');

  // =============================================================================
  // Labels (ARB-ready, sin inventar keys acá) – best-effort
  // =============================================================================

  String _labelTierStandard(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).planTierStandard,
    () => (l10n as dynamic).standard,
  ], 'Standard');

  String _labelTierPremium(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).planTierPremium,
    () => (l10n as dynamic).premium,
  ], 'Premium');

  String _labelTierBasico(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).planTierBasic,
    () => (l10n as dynamic).basic,
  ], 'Básico');

  String _labelActividades(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).activitiesLabel,
    () => (l10n as dynamic).actividadesLabel,
  ], 'Actividades');

  String _labelNiveles(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).levelsLabel,
    () => (l10n as dynamic).nivelesLabel,
  ], 'Niveles');

  String _labelModulos(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).modulesLabel,
    () => (l10n as dynamic).modulosLabel,
  ], 'Módulos');

  String _labelPlanKey(AppLocalizations l10n) =>
      _l10nTxt(l10n, [() => (l10n as dynamic).planKeyLabel], 'PlanKey');

  // =============================================================================
  // Args por ruta (best-effort)
  // =============================================================================

  static String _n(String? v) => (v ?? '').trim();
  static String _safeStr(Object? v) => v == null ? '' : v.toString();

  static bool _lowerEq(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  static String? _pickArgString(Map<dynamic, dynamic> args, List<String> keys) {
    for (final k in keys) {
      for (final e in args.entries) {
        final kk = _n(_safeStr(e.key));
        if (kk.isEmpty) continue;
        if (_lowerEq(kk, k)) {
          final vv = _n(_safeStr(e.value));
          if (vv.isNotEmpty) return vv;
        }
      }
    }
    return null;
  }

  static Object? _pickArgAny(Map<dynamic, dynamic> args, List<String> keys) {
    for (final k in keys) {
      for (final e in args.entries) {
        final kk = _n(_safeStr(e.key));
        if (kk.isEmpty) continue;
        if (_lowerEq(kk, k)) return e.value;
      }
    }
    return null;
  }

  void _readRouteArgumentsBestEffort() {
    final settings = ModalRoute.of(context)?.settings;
    final args = settings?.arguments;

    if (args is Map) {
      final map = Map<dynamic, dynamic>.from(args);

      final owner = _pickArgString(map, const <String>[
        'ownerAccountId',
        'ownerId',
        'cuentaId',
        'accountId',
      ]);

      final perf = _pickArgString(map, const <String>[
        'institucionPerfilId',
        'perfilId',
        'institucionId',
        'pid',
        'id',
      ]);

      final nombre = _pickArgString(map, const <String>[
        'institucionNombre',
        'nombre',
        'name',
      ]);

      final tipoPlan = _pickArgString(map, const <String>[
        'tipoPlan',
        'planKey',
      ]);

      _routePlanStatus = _pickArgAny(map, const <String>[
        'planStatus',
        'status',
      ]);

      _routeOwnerId = _n(owner);
      _routeInstPerfilId = _n(perf);
      _routeNombre = _n(nombre);
      _routeTipoPlan = _n(tipoPlan);

      if (_routeTipoPlan.isNotEmpty) {
        _seedTiersFromTipoPlan(_routeTipoPlan);
      }
    }
  }

  // =============================================================================
  // Load / compute
  // =============================================================================

  bool get _isManageEffective {
    if (widget.isManageMode) return true;
    return _routeInstPerfilId.isNotEmpty ||
        _n(widget.institucionPerfilId).isNotEmpty;
  }

  String get _ownerIdManage => _n(widget.ownerAccountId).isNotEmpty
      ? _n(widget.ownerAccountId)
      : _routeOwnerId;

  String get _perfilIdManage => _n(widget.institucionPerfilId).isNotEmpty
      ? _n(widget.institucionPerfilId)
      : _routeInstPerfilId;

  String get _nombreManage => _n(widget.institucionNombre).isNotEmpty
      ? _n(widget.institucionNombre)
      : _routeNombre;

  void _seedSelectionsFromDraft(InstitucionRegistroDraft d) {
    _nivelesSel
      ..clear()
      ..addAll(d.nivelesSeleccionados);
    _bloquesSel
      ..clear()
      ..addAll(d.bloquesSeleccionados);
    _selectionsSeeded = true;
  }

  void _seedSelectionsFromInstitution(Institucion inst) {
    final pc = inst.planSafe;

    final niveles = <NivelCurricular>[];
    final modulos = <BloqueExtracurricular>[];

    for (final n in pc.niveles) {
      if (n.habilitado == true) niveles.add(n.nivel);
    }
    for (final m in pc.modulos) {
      if (m.habilitado == true) modulos.add(m.bloque);
    }

    _nivelesSel
      ..clear()
      ..addAll(niveles);
    _bloquesSel
      ..clear()
      ..addAll(modulos);
    _selectionsSeeded = true;
  }

  Future<void> _loadManageInstitution() async {
    if (_cargando || !mounted) return;

    setState(() {
      _cargando = true;
      _instActual = null;
      _missingEntryData = false;
    });

    final idPerfil = _perfilIdManage;
    if (idPerfil.isEmpty) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _missingEntryData = true;
        });
      }
      return;
    }

    try {
      final inst = await _cargarInstitucionPorIdBestEffort(
        idPerfil,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      _instActual = inst;

      if (inst != null) {
        _seedTiersFromTipoPlan(inst.tipoPlan);
        _seedSelectionsFromInstitution(inst);
      } else {
        if (_routeTipoPlan.isNotEmpty) {
          _seedTiersFromTipoPlan(_routeTipoPlan);
        }
        if (!_selectionsSeeded) {
          _nivelesSel.clear();
          _bloquesSel.clear();
          _selectionsSeeded = true;
        }
      }

      _recompute();
      if (mounted) setState(() {});
    } catch (_) {
      _instActual = null;
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _seedTiersFromTipoPlan(String? tipoPlanRaw) {
    final tp = (tipoPlanRaw ?? '').toLowerCase();
    _tierCur = tp.contains('cur-prem')
        ? _TierCurricular.premium
        : _TierCurricular.standard;
    _tierExt = tp.contains('ext-prem')
        ? _TierExtracurricular.premium
        : _TierExtracurricular.basico;
  }

  bool get _hasAnyActividadSelected =>
      _nivelesSel.isNotEmpty || _bloquesSel.isNotEmpty;

  InstitucionRegistroDraft _effectiveDraftForCalc({
    required InstitucionRegistroDraft baseDraft,
  }) {
    return InstitucionRegistroDraft(
      nombre: baseDraft.nombre,
      cuit: baseDraft.cuit,
      direccion: baseDraft.direccion,
      pais: baseDraft.pais,
      provincia: baseDraft.provincia,
      ciudad: baseDraft.ciudad,
      modalidad: baseDraft.modalidad,
      email: baseDraft.email,
      telefono: baseDraft.telefono,
      pass: baseDraft.pass,
      tipo: baseDraft.tipo,
      nivelesSeleccionados: List<NivelCurricular>.from(_nivelesSel),
      bloquesSeleccionados: List<BloqueExtracurricular>.from(_bloquesSel),
    );
  }

  void _recompute() {
    if (_missingEntryData) {
      _calc = _PlanCalculo.zero();
      return;
    }

    final effectiveManage = _isManageEffective;

    final baseDraft = effectiveManage
        ? _draftFromInstitution(_instActual)
        : (widget.draft ??
              const InstitucionRegistroDraft(
                nombre: '',
                cuit: '',
                direccion: '',
                pais: '',
                provincia: '',
                ciudad: '',
                modalidad: ModalidadCursado.presencial,
                email: '',
                telefono: '',
                pass: '',
                tipo: TipoInstitucion.otra,
                nivelesSeleccionados: <NivelCurricular>[],
                bloquesSeleccionados: <BloqueExtracurricular>[],
              ));

    if (!_selectionsSeeded) {
      _seedSelectionsFromDraft(baseDraft);
    }

    final draft = _effectiveDraftForCalc(baseDraft: baseDraft);

    _calc = _PlanCalculo.compute(
      draft: draft,
      tierCur: _tierCur,
      tierExt: _tierExt,
      promo: _promo,
    );
  }

  InstitucionRegistroDraft _draftFromInstitution(Institucion? inst) {
    final niveles = <NivelCurricular>[];
    final modulos = <BloqueExtracurricular>[];

    try {
      final pc = inst?.planSafe;
      for (final n in pc?.niveles ?? <PlanNivelCurricular>[]) {
        if (n.habilitado == true) niveles.add(n.nivel);
      }
      for (final m in pc?.modulos ?? <PlanModuloExtracurricular>[]) {
        if (m.habilitado == true) modulos.add(m.bloque);
      }
    } catch (_) {
      final pc = inst?.planConfig;
      for (final n in pc?.niveles ?? <PlanNivelCurricular>[]) {
        if (n.habilitado == true) niveles.add(n.nivel);
      }
      for (final m in pc?.modulos ?? <PlanModuloExtracurricular>[]) {
        if (m.habilitado == true) modulos.add(m.bloque);
      }
    }

    return InstitucionRegistroDraft(
      nombre: inst?.nombre ?? _nombreManage,
      cuit: inst?.cuit ?? '',
      direccion: inst?.direccion ?? '',
      pais: inst?.pais ?? '',
      provincia: inst?.provincia ?? '',
      ciudad: inst?.ciudad ?? '',
      modalidad: inst?.modalidad ?? ModalidadCursado.presencial,
      email: inst?.email ?? '',
      telefono: inst?.telefono ?? '',
      pass: '****',
      tipo: inst?.tipoInstitucion ?? TipoInstitucion.otra,
      nivelesSeleccionados: niveles,
      bloquesSeleccionados: modulos,
    );
  }

  // =============================================================================
  // Promo / Código
  // =============================================================================

  Future<void> _aplicarCodigo() async {
    if (_cargando) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final raw = _codigoCtrl.text.trim();
    if (raw.isEmpty) {
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    final promo = _PromoCodes.tryResolve(raw);
    if (promo == null) {
      _promo = null;
      _recompute();
      if (mounted) setState(() {});
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );

      final used = prefs.getInt(kPromoUsedCounterAthena2026) ?? 0;
      if (used >= kPromoMaxCuposAthena2026) {
        _snack(messenger, _tCommonError(l10n));
        return;
      }

      final owner = _ownerIdManage;
      if (owner.isNotEmpty) {
        final owners =
            prefs.getStringList(kPromoUsedOwnersAthena2026) ?? <String>[];
        if (owners.contains(owner)) {
          _snack(messenger, _tCommonError(l10n));
          return;
        }
      }

      _promo = promo;
      _recompute();

      if (!mounted) return;
      setState(() {});

      _snack(messenger, _tApply(l10n));
    } catch (_) {
      _promo = promo;
      _recompute();
      if (mounted) setState(() {});
    }
  }

  void _limpiarCodigo() {
    _codigoCtrl.text = '';
    _promo = null;
    _recompute();
    if (mounted) setState(() {});
  }

  void _snack(ScaffoldMessengerState messenger, String msg) {
    final clean = msg.trim();
    if (clean.isEmpty) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {}
  }

  // =============================================================================
  // Persistencia: tipoPlan/estadoPlan/planInicio/planFin (+ planConfig)
  // =============================================================================

  PlanInstitucionConfig _buildPlanConfigFromSelections() {
    return PlanInstitucionConfig(
      niveles: _nivelesSel
          .map((n) => PlanNivelCurricular(nivel: n, habilitado: true))
          .toList(),
      modulos: _bloquesSel
          .map((b) => PlanModuloExtracurricular(bloque: b, habilitado: true))
          .toList(),
    );
  }

  EstadoPlanInstitucion _estadoPlanForSelection() {
    final bool free = (_promo?.percentOff ?? 0) >= 100 || _calc.totalUsd <= 0.0;
    return free ? EstadoPlanInstitucion.activo : EstadoPlanInstitucion.enPrueba;
  }

  String _tipoPlanForSelection() => _calc.planKey;

  DateTime _planInicioNow() => DateTime.now();
  DateTime _planFinDefault(DateTime inicio) =>
      inicio.add(const Duration(days: 30));

  Future<void> _trySetInstOwnerBestEffort(String ownerAccountId) async {
    final o = ownerAccountId.trim();
    if (o.isEmpty) return;

    try {
      SessionService.setInstitucionOwnerAccountId(o);
      return;
    } catch (_) {}

    try {
      final dyn = SessionService as dynamic;
      dyn.setInstitucionOwnerAccountId(ownerAccountId: o);
    } catch (_) {}
  }

  Future<String> _resolveOwnerBestEffort() async {
    final direct = _ownerIdManage.trim();
    if (direct.isNotEmpty) return direct;

    try {
      final dyn = SessionService as dynamic;
      final v = dyn.getInstitucionOwnerAccountId?.call();
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}

    try {
      final dyn = CuentaService as dynamic;
      final v = dyn.getSesionCuentaId?.call();
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}

    return '';
  }

  Future<void> _confirmarYRegistrar() async {
    if (_cargando) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!_hasAnyActividadSelected) {
      _snack(messenger, _tAtLeastOne(l10n));
      return;
    }

    final base = widget.draft;
    if (base == null) {
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    final d = _effectiveDraftForCalc(baseDraft: base);

    if (d.email.trim().isEmpty || d.pass.trim().length < 4) {
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    setState(() => _cargando = true);

    try {
      await CuentaService.logoutCuenta().timeout(const Duration(seconds: 3));

      final auth = await InstitucionService.registrarInstitucion(
        email: d.email.trim().toLowerCase(),
        passwordHash: d.pass,
        nombre: d.nombre,
      ).timeout(const Duration(seconds: 10));

      final ownerId = auth.institucionId;

      final perfil = await CuentaService.crearPerfilInstitucion(
        cuentaId: ownerId,
        nombre: d.nombre,
        emailContacto: d.email,
        telefonoContacto: d.telefono,
      ).timeout(const Duration(seconds: 10));

      final inicio = _planInicioNow();
      final fin = _planFinDefault(inicio);

      final inst = Institucion(
        id: perfil.id,
        nombre: d.nombre,
        cuit: d.cuit,
        direccion: d.direccion,
        pais: d.pais,
        provincia: d.provincia,
        ciudad: d.ciudad,
        modalidad: d.modalidad,
        email: d.email,
        telefono: d.telefono,
        curricular: d.tieneCurricular,
        extracurricular: d.tieneExtracurricular,
        tipoInstitucion: d.tipo,
        tipoPlan: _tipoPlanForSelection(),
        estadoPlan: _estadoPlanForSelection(),
        planInicio: inicio,
        planFin: fin,
        planConfig: _buildPlanConfigFromSelections(),
      );

      await InstitucionService.upsertInstitucion(inst)
          .timeout(const Duration(seconds: 10));

      await CuentaService.setSesionCuentaId(ownerId, recordarme: true)
          .timeout(const Duration(seconds: 4));

      await SessionService.setSession(
        userId: perfil.id,
        role: SessionRole.institucion,
        rememberMe: true,
      ).timeout(const Duration(seconds: 4));

      await _trySetInstOwnerBestEffort(ownerId);

      if ((_promo?.code ?? '').isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance().timeout(
            const Duration(seconds: 3),
          );
          final used = prefs.getInt(kPromoUsedCounterAthena2026) ?? 0;
          await prefs.setInt(kPromoUsedCounterAthena2026, used + 1);
          final owners =
              prefs.getStringList(kPromoUsedOwnersAthena2026) ?? <String>[];
          if (!owners.contains(ownerId)) {
            owners.add(ownerId);
            await prefs.setStringList(kPromoUsedOwnersAthena2026, owners);
          }
        } catch (_) {}
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => InstitucionMenuPage(
            ownerAccountId: ownerId,
            institucionPerfilId: perfil.id,
            institucionNombre: inst.nombre,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      _snack(messenger, '${_tCommonError(l10n)}: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambiosManage() async {
    if (_cargando) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final perfilId = _perfilIdManage;
    if (perfilId.isEmpty) {
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    if (!_hasAnyActividadSelected) {
      _snack(messenger, _tAtLeastOne(l10n));
      return;
    }

    final ownerId = await _resolveOwnerBestEffort();
    if (ownerId.isEmpty) {
      _snack(messenger, _tCommonError(l10n));
      return;
    }

    setState(() => _cargando = true);

    try {
      Institucion? inst = _instActual;
      inst ??= await _cargarInstitucionPorIdBestEffort(
        perfilId,
      ).timeout(const Duration(seconds: 8));

      if (inst == null) {
        _snack(messenger, _tCommonError(l10n));
        return;
      }

      final base = _draftFromInstitution(inst);
      final d = _effectiveDraftForCalc(baseDraft: base);

      final inicio = _planInicioNow();
      final fin = _planFinDefault(inicio);

      final updated = Institucion(
        id: inst.id,
        nombre: inst.nombre,
        cuit: inst.cuit,
        direccion: inst.direccion,
        pais: inst.pais,
        provincia: inst.provincia,
        ciudad: inst.ciudad,
        modalidad: inst.modalidad,
        email: inst.email,
        telefono: inst.telefono,
        curricular: d.tieneCurricular,
        extracurricular: d.tieneExtracurricular,
        tipoInstitucion: inst.tipoInstitucion,
        tipoPlan: _tipoPlanForSelection(),
        estadoPlan: _estadoPlanForSelection(),
        planInicio: inicio,
        planFin: fin,
        planConfig: _buildPlanConfigFromSelections(),
        logoLocalPath: inst.logoLocalPath,
        croquisLocalPath: inst.croquisLocalPath,
        croquisAula: inst.croquisAula,
        gruposCurriculares: inst.gruposCurriculares,
        actividadesExtracurriculares: inst.actividadesExtracurriculares,
      );

      await InstitucionService.upsertInstitucion(updated)
          .timeout(const Duration(seconds: 10));

      _instActual = updated;
      _recompute();

      await _trySetInstOwnerBestEffort(ownerId);

      if (!mounted) return;
      setState(() {});

      _snack(messenger, _tSave(l10n));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => InstitucionMenuPage(
            ownerAccountId: ownerId,
            institucionPerfilId: perfilId,
            institucionNombre: _nombreManage.isNotEmpty
                ? _nombreManage
                : updated.nombre,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      _snack(messenger, '${_tCommonError(l10n)}: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // =============================================================================
  // UI helpers (estética institucional canónica)
  // =============================================================================

  Color _overlayScrim(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _alpha(cs.scrim, isDark ? 0.60 : 0.14);
  }

  Color _cardColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = _neutralSurface(cs, isDark: isDark);
    return _alpha(base, isDark ? 0.78 : 0.92);
  }

  double _glowOpacity(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark ? 0.16 : 0.08;
  }

  Widget _withBackground(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            _bg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stack) => bgFallback(),
          ),
        ),
        Positioned.fill(child: Container(color: _overlayScrim(context))),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: _glowOpacity(context),
              child: Image.asset(
                _glow,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _missingDataView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_tPlanUpper(l10n))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_tCommonError(l10n), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(_tBack(l10n)),
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

  String _nivelLabel(NivelCurricular n) {
    final raw = n.toString();
    final part = raw.contains('.') ? raw.split('.').last : raw;
    final s = part.replaceAll('_', ' ').trim();
    if (s.isEmpty) return raw;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String _bloqueLabel(BloqueExtracurricular b) {
    try {
      final lbl = b.label.trim();
      if (lbl.isNotEmpty) return lbl;
    } catch (_) {}

    final raw = b.toString();
    final part = raw.contains('.') ? raw.split('.').last : raw;
    final s = part.replaceAll('_', ' ').trim();
    if (s.isEmpty) return raw;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Widget _actividadesSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    ChoiceChip chip({
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(label),
        selectedColor: cs.primary.withValues(alpha: 0.18),
      );
    }

    final niveles = NivelCurricular.values;
    final bloques = BloqueExtracurricular.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelNiveles(l10n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: niveles.map((n) {
            final selected = _nivelesSel.contains(n);
            return chip(
              selected: selected,
              label: _nivelLabel(n),
              onTap: () {
                setState(() {
                  if (selected) {
                    _nivelesSel.remove(n);
                  } else {
                    _nivelesSel.add(n);
                  }
                  _recompute();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          _labelModulos(l10n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: bloques.map((b) {
            final selected = _bloquesSel.contains(b);
            return chip(
              selected: selected,
              label: _bloqueLabel(b),
              onTap: () {
                setState(() {
                  if (selected) {
                    _bloquesSel.remove(b);
                  } else {
                    _bloquesSel.add(b);
                  }
                  _recompute();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        if (!_hasAnyActividadSelected)
          Text(
            _tAtLeastOne(l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  // =============================================================================
  // build
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final effectiveManage = _isManageEffective;

    if (widget.draft == null && !effectiveManage) {
      return _missingDataView(context);
    }
    if (_missingEntryData) {
      return _missingDataView(context);
    }

    final baseDraft = effectiveManage
        ? _draftFromInstitution(_instActual)
        : widget.draft!;
    final draft = _effectiveDraftForCalc(baseDraft: baseDraft);

    final hasCur = draft.tieneCurricular;
    final hasExt = draft.tieneExtracurricular;

    final nombre = effectiveManage
        ? (_n(_instActual?.nombre).isNotEmpty
              ? _n(_instActual?.nombre)
              : (_nombreManage.isNotEmpty
                    ? _nombreManage
                    : _tInstitutionGeneric(l10n)))
        : (_n(widget.draft?.nombre).isNotEmpty
              ? _n(widget.draft?.nombre)
              : _tInstitutionGeneric(l10n));

    final title = _tPlanUpper(l10n);
    final transparentSurface = cs.surface.withValues(alpha: 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: transparentSurface,
        surfaceTintColor: transparentSurface,
        actions: [
          if (effectiveManage)
            IconButton(
              onPressed: _cargando ? null : _loadManageInstitution,
              icon: const Icon(Icons.refresh),
              tooltip: _tRefresh(l10n),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    const SizedBox(height: 44),
                    Card(
                      elevation: 0,
                      color: _cardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (effectiveManage && _perfilIdManage.isNotEmpty)
                              Text(
                                _tInstitutionProfileIdLabel(
                                  l10n,
                                  _perfilIdManage,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            if (effectiveManage && _ownerIdManage.isNotEmpty)
                              Text(
                                _tAccountLabel(l10n, _ownerIdManage),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              hasCur && hasExt
                                  ? '${_tCurricularLabel(l10n)} + ${_tExtracurricularLabel(l10n)}'
                                  : (hasCur
                                        ? _tCurricularLabel(l10n)
                                        : (hasExt
                                              ? _tExtracurricularLabel(l10n)
                                              : _tCommonError(l10n))),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      context,
                      title: _labelActividades(l10n),
                      child: _actividadesSelector(context),
                    ),
                    const SizedBox(height: 12),
                    if (_nivelesSel.isNotEmpty) ...[
                      _sectionCard(
                        context,
                        title: _tCurricularLabel(l10n),
                        child: _tierSelectorCurricular(context),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_bloquesSel.isNotEmpty) ...[
                      _sectionCard(
                        context,
                        title: _tExtracurricularLabel(l10n),
                        child: _tierSelectorExtracurricular(context),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _sectionCard(
                      context,
                      title: _tPromoCodeLabel(l10n),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_tPromoCodeLabel(l10n)),
                            value: _mostrarCodigo,
                            onChanged: (v) =>
                                setState(() => _mostrarCodigo = v),
                          ),
                          if (_mostrarCodigo) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codigoCtrl,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: kPromoCodeAthena2026,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: _cargando ? null : _limpiarCodigo,
                                  child: Text(_tClear(l10n)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _cargando ? null : _aplicarCodigo,
                                  child: Text(_tApply(l10n)),
                                ),
                              ],
                            ),
                            if (_promo != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_promo!.code} • ${_promo!.label}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      context,
                      title: _tSummaryLabel(l10n),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kvLine(context, _labelPlanKey(l10n), _calc.planKey),
                          const SizedBox(height: 6),
                          _moneyLine(context, 'USD', _calc.subtotalUsd),
                          if (_calc.descuentoModulosUsd > 0) ...[
                            const SizedBox(height: 4),
                            _moneyLine(
                              context,
                              'USD',
                              -_calc.descuentoModulosUsd,
                            ),
                          ],
                          if (_calc.descuentoCodigoUsd > 0) ...[
                            const SizedBox(height: 4),
                            _moneyLine(
                              context,
                              'USD',
                              -_calc.descuentoCodigoUsd,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                          const SizedBox(height: 8),
                          _moneyLine(
                            context,
                            'USD',
                            _calc.totalUsd,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(_tBack(l10n)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cargando || !_hasAnyActividadSelected
                                ? null
                                : (effectiveManage
                                      ? _guardarCambiosManage
                                      : _confirmarYRegistrar),
                            icon: const Icon(Icons.check),
                            label: Text(
                              effectiveManage ? _tSave(l10n) : _tConfirm(l10n),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: _cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _tierSelectorCurricular(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget chip({
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(label),
        selectedColor: cs.primary.withValues(alpha: 0.18),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip(
              selected: _tierCur == _TierCurricular.standard,
              label: _labelTierStandard(l10n),
              onTap: () {
                setState(() {
                  _tierCur = _TierCurricular.standard;
                  _recompute();
                });
              },
            ),
            chip(
              selected: _tierCur == _TierCurricular.premium,
              label: _labelTierPremium(l10n),
              onTap: () {
                setState(() {
                  _tierCur = _TierCurricular.premium;
                  _recompute();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _tPlanCardSubtitle(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _tierSelectorExtracurricular(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget chip({
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(label),
        selectedColor: cs.primary.withValues(alpha: 0.18),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip(
              selected: _tierExt == _TierExtracurricular.basico,
              label: _labelTierBasico(l10n),
              onTap: () {
                setState(() {
                  _tierExt = _TierExtracurricular.basico;
                  _recompute();
                });
              },
            ),
            chip(
              selected: _tierExt == _TierExtracurricular.premium,
              label: _labelTierPremium(l10n),
              onTap: () {
                setState(() {
                  _tierExt = _TierExtracurricular.premium;
                  _recompute();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _tPlanCardSubtitle(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _kvLine(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final kk = k.trim().isEmpty ? 'PlanKey' : k.trim();
    return Row(
      children: [
        Expanded(
          child: Text(
            kk,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          v,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _moneyLine(
    BuildContext context,
    String currency,
    double value, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();

    return Row(
      children: [
        Expanded(
          child: Text(
            currency,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$sign\$${abs.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Promos / Códigos
// =============================================================================

class _PromoResult {
  final String code;
  final String label;
  final int percentOff;
  final int fixedOffUsd;

  const _PromoResult({
    required this.code,
    required this.label,
    required this.percentOff,
    required this.fixedOffUsd,
  });
}

class _PromoCodes {
  static const Map<String, _PromoResult> _allow = <String, _PromoResult>{
    kPromoCodeAthena2026: _PromoResult(
      code: kPromoCodeAthena2026,
      label: '1 mes gratis (límite 100)',
      percentOff: 100,
      fixedOffUsd: 0,
    ),
  };

  static _PromoResult? tryResolve(String raw) {
    final key = raw.trim().toUpperCase();
    if (key.isEmpty) return null;
    return _allow[key];
  }
}

// =============================================================================
// Plan cálculo
// =============================================================================

class _PlanCalculo {
  final String planKey;
  final double subtotalUsd;
  final double descuentoModulosUsd;
  final double descuentoCodigoUsd;
  final double totalUsd;
  final List<String> explicaciones;

  const _PlanCalculo({
    required this.planKey,
    required this.subtotalUsd,
    required this.descuentoModulosUsd,
    required this.descuentoCodigoUsd,
    required this.totalUsd,
    required this.explicaciones,
  });

  static _PlanCalculo zero() => const _PlanCalculo(
    planKey: '',
    subtotalUsd: 0,
    descuentoModulosUsd: 0,
    descuentoCodigoUsd: 0,
    totalUsd: 0,
    explicaciones: [],
  );

  static _PlanCalculo compute({
    required InstitucionRegistroDraft draft,
    required _TierCurricular tierCur,
    required _TierExtracurricular tierExt,
    required _PromoResult? promo,
  }) {
    const usdCurPorNivel = _InstitucionPlanPricing.usdCurPorNivel;
    const usdExtPorModulo = _InstitucionPlanPricing.usdExtPorModulo;
    const descuentoPctDesde3 = _InstitucionPlanPricing.descuentoPctDesde3;

    final nivelesCount = draft.nivelesSeleccionados.length;
    final modulosCount = draft.bloquesSeleccionados.length;
    final totalModulos = nivelesCount + modulosCount;

    final subtotal =
        (nivelesCount * usdCurPorNivel) + (modulosCount * usdExtPorModulo);

    final double descModulos = totalModulos >= 3
        ? (subtotal * descuentoPctDesde3)
        : 0.0;

    final double afterModulesDiscount = (subtotal - descModulos).clamp(
      0.0,
      double.infinity,
    );

    final double descCodigo = promo == null
        ? 0.0
        : (afterModulesDiscount * (promo.percentOff / 100.0)) +
              promo.fixedOffUsd.toDouble();

    final double total = (afterModulesDiscount - descCodigo).clamp(
      0.0,
      double.infinity,
    );

    final parts = <String>['FASE2'];
    parts.add(tierCur == _TierCurricular.premium ? 'CUR-PREM' : 'CUR-STD');
    parts.add(tierExt == _TierExtracurricular.premium ? 'EXT-PREM' : 'EXT-BAS');
    parts.add('N$nivelesCount');
    parts.add('M$modulosCount');

    return _PlanCalculo(
      planKey: parts.join('-'),
      subtotalUsd: subtotal,
      descuentoModulosUsd: descModulos,
      descuentoCodigoUsd: descCodigo,
      totalUsd: total,
      explicaciones: const <String>[],
    );
  }
}

// =============================================================================
// Pricing constants
// =============================================================================

class _InstitucionPlanPricing {
  static const double usdCurPorNivel = 10.0;
  static const double usdExtPorModulo = 15.0;
  static const double descuentoPctDesde3 = 0.05;
}
