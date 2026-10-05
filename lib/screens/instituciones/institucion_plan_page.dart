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
// Free/Premium V1: selección institucional local, sin precios ni pagos.
// Los códigos, estados y fechas históricos se conservan, no son una suscripción.
// La política comercial vive exclusivamente en PlanHabilitacionService.
//
// ✅ ESTÉTICA CANÓNICA (feb 2026 · fondo institucional):
// - Fondo consistente: base (asset) + scrim por ColorScheme + glow sutil.
// - Dark mode: alpha/contraste ajustado SIN withOpacity deprecated (usa withValues).
// - Stack expand + Positioned.fill para evitar fondos “cortados”.
// - Superficie neutralizada (scrim-blend) para evitar “amarillos saturados” por theme.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../services/plan_habilitacion_service.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/cuenta_service.dart';
import '../../services/institucion_service.dart';
import '../../services/instituciones_helpers.dart' as instituciones;
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';
import 'institucion_menu_page.dart';

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

  // null preserves an unclassified historical value until an explicit choice.
  PlanComercial? _planSeleccionado;

  Institucion? _instActual;

  // Args por ruta nombrada (PlanHabilitacionGuard / InstitucionMenuPage)
  String _routeOwnerId = '';
  String _routeInstPerfilId = '';
  String _routeNombre = '';

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
      _planSeleccionado = PlanComercial.free;
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
      }
    }
  }

  // =============================================================================
  // FIX COMPILACIÓN: cargar institución por ID (best-effort, sin acoplar API)
  // =============================================================================

  Future<Institucion?> _cargarInstitucionPorIdBestEffort(
    String institucionId,
  ) async {
    final id = institucionId.trim();
    if (id.isEmpty) return null;
    return InstitucionService.getInstitucionById(id);
  }

  String _savedPlanDescription(Institucion inst) {
    final commercial = PlanHabilitacionService.planComercial(inst.tipoPlan);
    if (commercial != PlanComercial.desconocido) {
      return 'Plan Atena: ${PlanHabilitacionService.nombreComercial(commercial)}';
    }
    final config = inst.planConfig;
    if (config == null) return 'Referencia local: ${inst.tipoPlan}';
    final levels = config.niveles.where((entry) => entry.habilitado).length;
    final modules = config.modulos.where((entry) => entry.habilitado).length;
    final code = inst.tipoPlan.toUpperCase();
    final curricularTier = code.contains('CUR-PREM') ? 'Premium' : 'Standard';
    final extraTier = code.contains('EXT-PREM') ? 'Premium' : 'Básico';
    return 'Referencia histórica · Curricular: $levels ${levels == 1 ? 'nivel' : 'niveles'} ($curricularTier) · '
        'Extracurricular: $modules ${modules == 1 ? 'módulo' : 'módulos'} ($extraTier)';
  }

  String _savedPlanStatus(EstadoPlanInstitucion status) => switch (status) {
    EstadoPlanInstitucion.activo => 'Activo en Atena',
    EstadoPlanInstitucion.enPrueba => 'En prueba',
    EstadoPlanInstitucion.vencido => 'Vencido',
    EstadoPlanInstitucion.suspendido => 'Suspendido',
    EstadoPlanInstitucion.sinPlan => 'Sin plan',
  };

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

  String _tSave(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionSave,
    () => (l10n as dynamic).save,
    () => (l10n as dynamic).commonSave,
  ], 'Guardar');

  String _tConfirm(AppLocalizations l10n) => _l10nTxt(l10n, [
    () => (l10n as dynamic).actionConfirm,
    () => (l10n as dynamic).confirm,
  ], 'Confirmar');

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

  // =============================================================================
  // Labels (ARB-ready, sin inventar keys acá) – best-effort
  // =============================================================================

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

      _routePlanStatus = _pickArgAny(map, const <String>[
        'planStatus',
        'status',
      ]);

      _routeOwnerId = _n(owner);
      _routeInstPerfilId = _n(perf);
      _routeNombre = _n(nombre);
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
        final saved = PlanHabilitacionService.planComercial(inst.tipoPlan);
        _planSeleccionado = saved == PlanComercial.desconocido ? null : saved;
        _seedSelectionsFromInstitution(inst);
      } else {
        if (!_selectionsSeeded) {
          _nivelesSel.clear();
          _bloquesSel.clear();
          _selectionsSeeded = true;
        }
      }

      if (mounted) setState(() {});
    } catch (_) {
      _instActual = null;
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
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

  // Operational local state, never a paid subscription assertion.
  EstadoPlanInstitucion _estadoPlanForSelection() =>
      EstadoPlanInstitucion.activo;

  String _tipoPlanForSelection() => _planSeleccionado == null
      ? (_instActual?.tipoPlan ?? 'Free')
      : PlanHabilitacionService.nombreComercial(_planSeleccionado!);

  // Required legacy date fields retain their previous registration defaults.
  // They do not establish a Free/Premium subscription duration.
  DateTime _planInicioNow() => DateTime.now();
  DateTime _planFinDefault(DateTime inicio) =>
      inicio.add(const Duration(days: 30));

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
      final previousOwner = await CuentaService.getSesionCuentaId();
      final previousAccount = previousOwner == null
          ? null
          : await CuentaService.getCuentaById(previousOwner);
      final remember = previousAccount?.recordarme ?? false;
      await CuentaService.logoutCuenta();

      // A timed-out local write keeps running. Retrying after that used to
      // encounter an auth record without its institutional profile.
      final email = d.email.trim().toLowerCase();
      final existingId = await InstitucionService.getInstitucionIdByEmail(
        email,
      );
      final String ownerId;
      if (existingId == null) {
        final auth = await InstitucionService.registrarInstitucion(
          email: email,
          passwordHash: d.pass,
          nombre: d.nombre,
        );
        ownerId = auth.institucionId;
      } else {
        final auth = await InstitucionService.loginInstitucion(
          email: email,
          passwordHash: d.pass,
        );
        if (auth == null ||
            auth.institucionId != existingId ||
            (await InstitucionService.getNombreInstitucionById(
                  existingId,
                ))?.trim() !=
                d.nombre.trim()) {
          throw StateError(
            'El registro existente no corresponde a esta identidad.',
          );
        }
        ownerId = existingId;
      }

      final owner = await CuentaService.getCuentaById(ownerId);
      final indexedOwner = await CuentaService.getCuentaByEmail(email);
      if (owner == null ||
          indexedOwner?.id != ownerId ||
          owner.email.trim().toLowerCase() != email ||
          owner.perfilesAlumnoIds.isNotEmpty) {
        throw StateError(
          'La cuenta propietaria no coincide con la institución.',
        );
      }
      if (existingId != null) {
        // The institutional and owner credentials may legitimately diverge.
        // Recover only when BOTH identities are independently authenticated.
        final authenticatedOwner = await CuentaService.loginCuenta(
          email: email,
          password: d.pass,
          recordarme: false,
        );
        if (authenticatedOwner.id != ownerId) {
          throw StateError(
            'La cuenta propietaria no coincide con la institución.',
          );
        }
      }

      final existingProfile = await CuentaService.getPerfilInstitucionById(
        ownerId,
      );
      if (await InstitucionService.getInstitucionById(ownerId) != null ||
          (existingProfile == null &&
              owner.perfilesInstitucionIds.isNotEmpty) ||
          (existingProfile != null &&
              !owner.perfilesInstitucionIds.contains(ownerId)) ||
          owner.perfilesInstitucionIds.any((id) => id != ownerId) ||
          (existingProfile != null &&
              (existingProfile.cuentaId != ownerId ||
                  existingProfile.ownerAccountId != ownerId ||
                  existingProfile.emailContacto.trim().toLowerCase() != email ||
                  existingProfile.nombre.trim() != d.nombre.trim()))) {
        throw StateError('La institución ya está registrada.');
      }

      final perfil =
          existingProfile ??
          await CuentaService.crearPerfilInstitucion(
            cuentaId: ownerId,
            nombre: d.nombre,
            emailContacto: d.email,
            telefonoContacto: d.telefono,
          );

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

      await InstitucionService.upsertInstitucion(inst);

      await CuentaService.iniciarSesionAutenticada(
        ownerId,
        recordarme: remember,
      );
      await CuentaService.activarContextoInstitucion(ownerId, perfil.id);

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
      // Reload before saving: keep data changed since this form was opened.
      final inst = await _cargarInstitucionPorIdBestEffort(
        perfilId,
      ).timeout(const Duration(seconds: 8));

      if (inst == null) {
        _snack(messenger, _tCommonError(l10n));
        return;
      }

      final base = _draftFromInstitution(inst);
      final d = _effectiveDraftForCalc(baseDraft: base);

      final updated = inst.copyWith(
        curricular: d.tieneCurricular,
        extracurricular: d.tieneExtracurricular,
        tipoPlan: _tipoPlanForSelection(),
        planConfig: _buildPlanConfigFromSelections(),
      );

      await InstitucionService.upsertInstitucion(
        updated,
      ).timeout(const Duration(seconds: 10));

      // Menus/editors read this cache. Do not leave an old plan that a later
      // unrelated edit could copy back into the canonical institutional record.
      await instituciones.guardarInstitucionCachePorId(perfilId, updated);
      _instActual = updated;

      await CuentaService.activarContextoInstitucion(ownerId, perfilId);

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
                                              : _tAtLeastOne(l10n))),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (effectiveManage) ...[
                      const SizedBox(height: 12),
                      _sectionCard(
                        context,
                        title: 'Plan institucional guardado',
                        child:
                            _instActual == null ||
                                (_instActual?.tipoPlan ?? '').trim().isEmpty
                            ? const Text(
                                'No hay un plan local guardado para este perfil institucional.',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_savedPlanDescription(_instActual!)),
                                  Text(
                                    'Estado local: ${_savedPlanStatus(_instActual!.estadoPlan)}',
                                  ),
                                  const Text(
                                    'Este dato local no acredita una suscripción o pago verificado.',
                                  ),
                                ],
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _sectionCard(
                      context,
                      title: _labelActividades(l10n),
                      child: _actividadesSelector(context),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      context,
                      title: 'Plan Atena · configuración local',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            children: [
                              for (final plan in [
                                PlanComercial.free,
                                PlanComercial.premium,
                              ])
                                ChoiceChip(
                                  label: Text(
                                    PlanHabilitacionService.nombreComercial(
                                      plan,
                                    ),
                                  ),
                                  selected: _planSeleccionado == plan,
                                  onSelected: _cargando
                                      ? null
                                      : (_) => setState(
                                          () => _planSeleccionado = plan,
                                        ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Free: presencia pública y descubrimiento.',
                          ),
                          const Text(
                            'Premium: presencia pública y nuevas solicitudes digitales.',
                          ),
                          const Text(
                            'El plan pertenece a la institución completa. El costo de cada oferta es independiente.',
                          ),
                          if (_planSeleccionado == null)
                            const Text(
                              'Plan histórico sin clasificar. Se conserva salvo selección explícita; no concede Premium automáticamente.',
                            ),
                          const SizedBox(height: 12),
                          Text(
                            PlanHabilitacionService.commercialEnforcementEnabled
                                ? 'Restricción comercial activada en esta compilación.'
                                : 'Modo de pruebas: restricción comercial desactivada. Free y Premium permiten probar solicitudes.',
                          ),
                          const Text(
                            'Precios y condiciones comerciales no definidos. Esta selección local no acredita una suscripción o pago verificado.',
                          ),
                          if (_instActual != null)
                            const Text(
                              'Se conservan el estado operativo y las fechas históricas. Elegir Premium no reactiva un registro vencido o suspendido.',
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
}
