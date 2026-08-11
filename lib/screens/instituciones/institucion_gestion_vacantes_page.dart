// lib/screens/instituciones/institucion_gestion_vacantes_page.dart
//
// ATENA – INSTITUCIÓN / GESTIÓN VACANTES (CORAZÓN OPERATIVO CURRICULAR)
//
// FIX (Feb 2026) – “queda cargando”:
// - ✅ NO depende de l10n en initState (post-frame bootstrap).
// - ✅ _cargarSafe con timeout + finally => SIEMPRE corta el loading.
// - ✅ Diagnóstico por logs [ATENA][VACANTES] para ubicar el await colgado.
// - ✅ NO normaliza institucionId para DATA (solo trim). (Evita mismatch silencioso.)
// - ✅ Timeouts cortos en helpers/servicios (prototipo local).
//
// ✅ CANÓNICO (FASE 2):
// - NO duplica locks dentro de esta pantalla.
//   El lock de concurrencia ya se toma desde InstitucionAreaPage vía InstitucionAreaGuard.
//
// 🔐 PLAN / HABILITACIÓN (FASE 2):
// - Este screen es OPERATIVO (edita cupos/grupos).
// - Se ejecuta PlanHabilitacionGuard.ensureOperativo() al entrar (en _cargarSafe).
// - Si el plan NO está activo → redirección a PlanPage (según guard), sin loops.
//
// ✅ FIX CANÓNICO (Feb 2026) – redirección correcta a PlanPage:
// - Esta pantalla ahora RESUELVE y CONSERVA ownerAccountId + institucionPerfilId
//   (por constructor o RouteSettings.arguments) y los pasa al Guard.
// - Esto evita fallback al menú por falta de args en /institucion/plan.
//
// ✅ FIX (Feb 2026) – evita redirección falsa a PlanPage:
// - Solo ejecuta el Guard si hay ownerAccountId RESUELTO y planForGuard NO es null.
// - Si faltan args/plan, se loguea y se continúa sin forzar navegación.
//
// ✅ EXTENSIÓN (Feb 2026) – Operativa “Institución ↔ Alumnos”:
// - Agrega vista “Alumnos” (lista operativa) derivada best-effort desde Solicitudes.
// - Filtros: nombre/doc (best-effort), actividad/área, aula/clase, edad (si existe DOB).
// - Selección múltiple + acción “Notificar/Emitir” con alcances:
//   * seleccionados / aula completa / institución completa
// - Canónico Notificaciones:
//   * write SIEMPRE a inbox OWNER (NotificacionesService.pushToOwner)
//   * duplicado opcional al PERFIL (para UX) usando perfilId en el payload
// - ✅ “Emitir” (calendario) INTEGRADO (Feb 2026):
//   * Evento Especial institucional LOCKED + Inbox via AlumnoService (notificar=true)
//   * Destinatarios: Solicitudes confirmadas
//   * Service: InstitucionEmisionesService (canónico, backend-ready)
//
// ✅ HARDENING CANÓNICO (Feb 2026) – FUENTE ÚNICA DE VERDAD (grupos):
// - Esta pantalla PERSISTE y LEE únicamente mediante ih.cargar/guardarGruposInstitucion.
// - Se elimina la sincronización paralela a "grupos curriculares" dentro de Institucion,
//   para evitar fuentes duplicadas de verdad (backend-ready).
//
// ✅ FIX (Feb 2026) – DropdownButtonFormField:
// - Flutter (>= v3.35): `value` deprecated → usar `initialValue`. :contentReference[oaicite:0]{index=0}
// - Para mantener comportamiento “controlado”, se fuerza re-init con ValueKey.
//
// ✅ FIX (Feb 2026) – onPressed async:
// - onPressed requiere void Function()? → se usa unawaited(...) para Futures.
//
// ✅ EXT (Feb 2026) – Focus desde “Mis Solicitudes”:
// - Soporta RouteSettings.arguments con:
//   focusTab, focusActividad, focusAula, focusTurno, focusAlumnoPerfilId
// - Al cargar: abre tab Alumnos, aplica filtros, selecciona alumno y scrollea.
//
// ✅ CANÓNICO CURRICULAR (Feb 2026):
// - Recalcular ocupados prioriza SolicitudAlumno.grupoCurricularId (si está disponible).
// - Esto alinea “Grupos ↔ Solicitudes” por ID estable (backend-ready),
//   manteniendo fallback legacy por actividad+aula+turno.
//
// ✅ AJUSTE (Feb 2026) – CURSO CANÓNICO (NIVEL + GRADO/SALA/AÑO + TURNO/HORARIO):
// - UI de alta/edición de grupos incorpora:
//   * Nivel (Jardín/Primaria/Secundaria)
//   * Grado/Sala/Año (texto)
//   * Turno (Mañana/Tarde/Noche u otro)
//   * Horario (HH:MM a HH:MM)
// - Persistencia backend-ready sin duplicar fuentes:
//   * Mantiene fuente única: grupos (ih.cargar/guardarGruposInstitucion).
//   * Para compat con Solicitudes actuales (match por strings), se serializa de forma
//     estable y legible dentro de `aula` y `turno` (sin romper modelo existente).
//   * Si a futuro el modelo expone campos estructurados (nivel/grado/horario), se migra
//     sin cambiar este flujo (E2E canónico ya queda alineado por representación estable).
//
// ✅ FIX NUEVO (Feb 2026) – ID DETERMINÍSTICO PARA GRUPOS NUEVOS:
// - Cuando se crea un grupo NUEVO, el id se genera de forma determinística en base a:
//   aulaSerializada + turnoSerializado + horario (si existe).
// - Esto permite que Solicitudes guarde grupoCurricularId y quede alineado sin random IDs.
// - IMPORTANTE: si el grupo YA EXISTE (edición), se preserva el id para no romper referencias.
//
// ✅ FIX (Feb 2026) – Focus tab REAL (TabController):
// - Antes: _tabIndex cambiaba pero DefaultTabController NO se actualizaba => focus no abría tab.
// - Ahora: TabController propio + animateTo en _applyFocusAfterLoad() (E2E funcional).
//

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

import '../../models/instituciones/instituciones_integrado.dart';

import '../../models/solicitudes/solicitud_alumno.dart'
    show SolicitudAlumno, EstadoSolicitud;

import '../../services/solicitudes_service.dart';
import '../../services/instituciones_helpers.dart' as ih;

import '../../guards/plan_habilitacion_guard.dart';

import '../../services/notificaciones_service.dart';
import '../../models/notificaciones/notificacion_atena.dart';

import '../../models/calendario/evento_calendario.dart';
import '../../services/institucion_emisiones_service.dart';

class InstitucionGestionVacantesPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  final String? ownerAccountId;
  final String? institucionPerfilId;

  final String? actividadKey;
  final String? actividadLabel;
  final String? workProfileId;
  final String? workProfileName;

  const InstitucionGestionVacantesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.ownerAccountId,
    this.institucionPerfilId,
    this.actividadKey,
    this.actividadLabel,
    this.workProfileId,
    this.workProfileName,
  });

  @override
  State<InstitucionGestionVacantesPage> createState() =>
      _InstitucionGestionVacantesPageState();
}

class _InstitucionGestionVacantesPageState
    extends State<InstitucionGestionVacantesPage>
    with SingleTickerProviderStateMixin {
  bool _cargando = true;
  bool _guardando = false;

  bool _booting = false;
  String? _fatalError;

  List<GrupoInstitucional> _grupos = <GrupoInstitucional>[];

  final List<_AlumnoOperativo> _alumnos = <_AlumnoOperativo>[];
  final Set<String> _selectedAlumnoKeys = <String>{};

  final TextEditingController _qCtrl = TextEditingController();
  String _fActividad = '';
  String _fAula = '';
  int? _fEdadMin;
  int? _fEdadMax;

  int _tabIndex = 0;
  late final TabController _tabCtrl;

  final ScrollController _alumnosScrollCtrl = ScrollController();

  String get _instIdData => widget.institucionId.trim();

  bool _routeArgsResolved = false;
  String _ownerAccountIdResolved = '';
  String _institucionPerfilIdResolved = '';
  String _actividadKeyResolved = '';
  String _actividadLabelResolved = '';
  String _workProfileIdResolved = '';
  String _workProfileNameResolved = '';

  // Focus args (best-effort)
  bool _focusResolved = false;
  bool _hasFocus = false;

  int? _focusTabIndex; // 0 grupos / 1 alumnos
  String _focusActividad = '';
  String _focusAula = '';
  String _focusTurno = '';
  String _focusAlumnoPerfilId = '';

  bool _focusApplied = false;
  String _pendingScrollAlumnoKey = '';

  int _clampTabIndex([int? v]) {
    final x = v ?? _tabIndex;
    if (x < 0) return 0;
    if (x > 1) return 1;
    return x;
  }

  static String _n(String? v) => (v ?? '').trim();

  // L10N SAFE: por ahora devuelve fallback (no inventa keys).
  // Se dejan parámetros como nombres explícitos para evitar unnecessary_underscores.
  // ignore: unused_parameter
  String _t(AppLocalizations l10n, String key, String fallback) => fallback;

  // ────────────────────────────────────────────────────────────────────────────
  // CURRICULAR (NIVEL / GRADO-SALA-AÑO / TURNO-HORARIO) – Serialización estable
  // ────────────────────────────────────────────────────────────────────────────

  static const String _sepDot = '•';

  static String _joinParts(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.isEmpty && y.isEmpty) return '';
    if (x.isEmpty) return y;
    if (y.isEmpty) return x;
    return '$x $_sepDot $y';
  }

  static String _fmtHorario(String ini, String fin) {
    final a = ini.trim();
    final b = fin.trim();
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a-$b';
  }

  static bool _looksLikeHorario(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    // best-effort: "HH:MM-HH:MM" or "HH:MM"
    final re = RegExp(r'^\d{1,2}:\d{2}(\-\d{1,2}:\d{2})?$');
    return re.hasMatch(v);
  }

  static String _normalizeSpaces(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // ────────────────────────────────────────────────────────────────────────────
  // ✅ ID determinístico (para grupos NUEVOS)
  // ────────────────────────────────────────────────────────────────────────────

  static String _idNormKey(String s) {
    final t = s.trim().toLowerCase();
    if (t.isEmpty) return '';
    final buf = StringBuffer();
    for (final r in t.runes) {
      final isAz = (r >= 97 && r <= 122);
      final is09 = (r >= 48 && r <= 57);
      final c = String.fromCharCode(r);
      if (isAz || is09) {
        buf.write(c);
      } else if (c == ' ' || c == '-' || c == '_' || c == '•' || c == '/') {
        buf.write('_');
      }
      // otros chars se omiten (best-effort)
    }
    var out = buf.toString().replaceAll(RegExp(r'_+'), '_');
    out = out.replaceAll(RegExp(r'^_+'), '').replaceAll(RegExp(r'_+$'), '');
    return out;
  }

  static String _idNormTimeDigits(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    return t.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _makeGrupoIdDeterministic({
    required String aulaSerialized,
    required String turnoSerialized,
    required String nombreGrupoFallback,
    required String horarioInicio,
    required String horarioFin,
  }) {
    final aulaBase = _normalizeSpaces(aulaSerialized).trim();
    final turnoBase = _normalizeSpaces(turnoSerialized).trim();
    final fallback = _normalizeSpaces(nombreGrupoFallback).trim();

    final a = _idNormKey(aulaBase.isNotEmpty ? aulaBase : fallback);
    final t = _idNormKey(turnoBase.isNotEmpty ? turnoBase : 'turno');

    final hi = _idNormTimeDigits(horarioInicio);
    final hf = _idNormTimeDigits(horarioFin);
    final hasHorario = hi.isNotEmpty || hf.isNotEmpty;

    final horarioPart = hasHorario ? '__${hi}_${hf}' : '';
    final base = 'grp__${t}__${a.isNotEmpty ? a : 'curso'}$horarioPart';
    return base;
  }

  static _GrupoCursoUI _parseCursoFromGrupo(GrupoInstitucional g) {
    final aulaRaw = _normalizeSpaces(_n(g.aula));
    final turnoRaw = _normalizeSpaces(_n(g.turno));

    String nivel = '';
    String grado = '';

    if (aulaRaw.contains(_sepDot)) {
      final parts = aulaRaw.split(_sepDot).map((e) => e.trim()).toList();
      if (parts.isNotEmpty) nivel = parts.first;
      if (parts.length >= 2) grado = parts.sublist(1).join(' $_sepDot ').trim();
    } else {
      final low = aulaRaw.toLowerCase();
      if (low.startsWith('jard')) {
        nivel = 'Jardín';
        grado = aulaRaw;
      } else if (low.startsWith('prim')) {
        nivel = 'Primaria';
        grado = aulaRaw;
      } else if (low.startsWith('sec')) {
        nivel = 'Secundaria';
        grado = aulaRaw;
      } else {
        grado = aulaRaw;
      }
    }

    String turno = '';
    String hIni = '';
    String hFin = '';

    if (turnoRaw.contains(_sepDot)) {
      final parts = turnoRaw.split(_sepDot).map((e) => e.trim()).toList();
      if (parts.isNotEmpty) turno = parts.first;
      if (parts.length >= 2) {
        final horario = parts.sublist(1).join(' $_sepDot ').trim();
        if (_looksLikeHorario(horario)) {
          final hf = horario.split('-').map((e) => e.trim()).toList();
          if (hf.isNotEmpty) hIni = hf.first;
          if (hf.length >= 2) hFin = hf[1];
        } else {
          turno = _normalizeSpaces(turnoRaw);
        }
      }
    } else {
      final low = turnoRaw.toLowerCase();
      if (low.contains('mañ') || low.contains('man')) {
        turno = 'Mañana';
      } else if (low.contains('tard')) {
        turno = 'Tarde';
      } else if (low.contains('noch')) {
        turno = 'Noche';
      } else {
        turno = turnoRaw;
      }

      final m = RegExp(
        r'(\d{1,2}:\d{2})\s*\-\s*(\d{1,2}:\d{2})',
      ).firstMatch(turnoRaw);
      if (m != null) {
        hIni = (m.group(1) ?? '').trim();
        hFin = (m.group(2) ?? '').trim();
        if (turnoRaw.contains(RegExp(r'\d{1,2}:\d{2}'))) {
          if (turno != 'Mañana' && turno != 'Tarde' && turno != 'Noche') {
            final before = turnoRaw.split(m.group(0) ?? '').first.trim();
            if (before.isNotEmpty) turno = before;
          }
        }
      }
    }

    return _GrupoCursoUI(
      nivel: _normalizeSpaces(nivel),
      gradoSalaAnio: _normalizeSpaces(grado),
      turno: _normalizeSpaces(turno),
      horarioInicio: _normalizeSpaces(hIni),
      horarioFin: _normalizeSpaces(hFin),
    );
  }

  static String _composeAula({
    required String nivel,
    required String gradoSalaAnio,
  }) {
    return _normalizeSpaces(_joinParts(nivel, gradoSalaAnio));
  }

  static String _composeTurno({
    required String turno,
    required String horarioInicio,
    required String horarioFin,
  }) {
    final horario = _fmtHorario(horarioInicio, horarioFin);
    return _normalizeSpaces(_joinParts(turno, horario));
  }

  String _enumNameBestEffort(Object? e) {
    if (e == null) return '';
    try {
      // ignore: avoid_dynamic_calls
      final n = (e as dynamic).name;
      if (n is String) return n.trim();
    } catch (_) {}
    return e.toString().trim();
  }

  String _labelBestEffort(Object? e, {String fallback = ''}) {
    if (e == null) return fallback;
    try {
      // ignore: avoid_dynamic_calls
      final v = (e as dynamic).label;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    final s = e.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _safeValueInOptions(String value, List<String> options) {
    final v = value.trim();
    if (v.isEmpty) return '';
    return options.contains(v) ? v : '';
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

  String _readStringFromArgs(Map args, List<String> keys) {
    for (final k in keys) {
      final v = args[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  int? _readTabIndexFromArgs(Map args) {
    final raw = _readStringFromArgs(args, const [
      'focusTab',
      'tab',
      'tabFocus',
    ]);
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;

    if (v == '1' || v == 'alumnos' || v == 'students' || v == 'student') {
      return 1;
    }
    if (v == '0' || v == 'grupos' || v == 'groups' || v == 'group') {
      return 0;
    }
    final parsed = int.tryParse(v);
    if (parsed == null) return null;
    if (parsed <= 0) return 0;
    if (parsed >= 1) return 1;
    return parsed;
  }

  void _resolveRouteArgsOnce() {
    if (_routeArgsResolved) return;

    _ownerAccountIdResolved = (widget.ownerAccountId ?? '').trim();
    _institucionPerfilIdResolved =
        (widget.institucionPerfilId ?? '').trim().isNotEmpty
        ? (widget.institucionPerfilId ?? '').trim()
        : _instIdData;

    _actividadKeyResolved = (widget.actividadKey ?? '').trim();
    _actividadLabelResolved = (widget.actividadLabel ?? '').trim();
    _workProfileIdResolved = (widget.workProfileId ?? '').trim();
    _workProfileNameResolved = (widget.workProfileName ?? '').trim();

    try {
      final route = ModalRoute.of(context);
      final args = route?.settings.arguments;
      if (args is Map) {
        String readString(List<String> keys) => _readStringFromArgs(args, keys);

        if (_ownerAccountIdResolved.isEmpty) {
          _ownerAccountIdResolved = readString(const [
            'ownerAccountId',
            'ownerId',
          ]);
        }

        if (_institucionPerfilIdResolved.isEmpty ||
            _institucionPerfilIdResolved == _instIdData) {
          final p = readString(const [
            'institucionPerfilId',
            'perfilId',
            'institucionId',
          ]);
          if (p.isNotEmpty) _institucionPerfilIdResolved = p;
        }

        if (_actividadKeyResolved.isEmpty) {
          _actividadKeyResolved = readString(const [
            'actividadKey',
            'actividadKeyScope',
            'activityKey',
          ]);
        }
        if (_actividadLabelResolved.isEmpty) {
          _actividadLabelResolved = readString(const [
            'actividadLabel',
            'activityLabel',
            'actividadNombre',
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

        if (!_focusResolved) {
          _focusTabIndex = _readTabIndexFromArgs(args);

          _focusActividad = readString(const [
            'focusActividad',
            'focusActivity',
            'actividadNombreFocus',
            'actividadNombre',
            'actividad',
          ]);

          _focusAula = readString(const [
            'focusAula',
            'focusClassroom',
            'aulaFocus',
            'aula',
            'grupo',
          ]);

          _focusTurno = readString(const [
            'focusTurno',
            'focusShift',
            'turnoFocus',
            'turno',
          ]);

          _focusAlumnoPerfilId = readString(const [
            'focusAlumnoPerfilId',
            'focusPerfilId',
            'alumnoPerfilId',
            'perfilId',
            'alumnoId',
          ]);

          _hasFocus =
              (_focusTabIndex != null) ||
              _focusActividad.isNotEmpty ||
              _focusAula.isNotEmpty ||
              _focusTurno.isNotEmpty ||
              _focusAlumnoPerfilId.isNotEmpty;

          _focusResolved = true;
        }
      }
    } catch (_) {}

    if (_institucionPerfilIdResolved.isEmpty) {
      _institucionPerfilIdResolved = _instIdData;
    }

    _routeArgsResolved = true;
  }

  void _applyFocusAfterLoad() {
    if (!_hasFocus) return;
    if (_focusApplied) return;

    final targetTab = _focusTabIndex;
    if (targetTab != null) {
      _tabIndex = targetTab;
    } else {
      if (_focusAlumnoPerfilId.isNotEmpty ||
          _focusActividad.isNotEmpty ||
          _focusAula.isNotEmpty) {
        _tabIndex = 1;
      }
    }
    _tabIndex = _clampTabIndex(_tabIndex);

    if (_tabIndex == 1) {
      if (_focusActividad.isNotEmpty) _fActividad = _focusActividad.trim();
      if (_focusAula.isNotEmpty) _fAula = _focusAula.trim();

      final pid = _focusAlumnoPerfilId.trim();
      if (pid.isNotEmpty) {
        final found = _alumnos.firstWhere(
          (a) => a.perfilId.trim() == pid || a.key.trim() == pid,
          orElse: () => const _AlumnoOperativo(
            key: '',
            perfilId: '',
            ownerAccountId: '',
            nombreUI: '',
            actividad: '',
            aula: '',
            turno: '',
            edad: null,
          ),
        );

        if (found.key.isNotEmpty) {
          _selectedAlumnoKeys
            ..clear()
            ..add(found.key);
          _pendingScrollAlumnoKey = found.key;
        } else {
          _qCtrl.text = pid;
          _pendingScrollAlumnoKey = pid;
        }
      } else {
        final act = _focusActividad.trim().toLowerCase();
        final aula = _focusAula.trim().toLowerCase();
        final turno = _focusTurno.trim().toLowerCase();

        if (act.isNotEmpty || aula.isNotEmpty || turno.isNotEmpty) {
          final match = _alumnos.firstWhere(
            (a) {
              if (act.isNotEmpty && a.actividad.trim().toLowerCase() != act) {
                return false;
              }
              if (aula.isNotEmpty && a.aula.trim().toLowerCase() != aula) {
                return false;
              }
              if (turno.isNotEmpty && a.turno.trim().toLowerCase() != turno) {
                return false;
              }
              return true;
            },
            orElse: () => const _AlumnoOperativo(
              key: '',
              perfilId: '',
              ownerAccountId: '',
              nombreUI: '',
              actividad: '',
              aula: '',
              turno: '',
              edad: null,
            ),
          );

          if (match.key.isNotEmpty) {
            _pendingScrollAlumnoKey = match.key;
          }
        }
      }
    }

    _focusApplied = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (_tabCtrl.index != _tabIndex) {
          _tabCtrl.animateTo(_tabIndex);
        }
      } catch (_) {}
      unawaited(_scrollToPendingAlumnoIfAny());
    });
  }

  Future<void> _scrollToPendingAlumnoIfAny() async {
    final key = _pendingScrollAlumnoKey.trim();
    if (key.isEmpty) return;
    if (!_alumnosScrollCtrl.hasClients) return;

    final visible = _alumnosFiltrados();

    int idx = visible.indexWhere((a) => a.key == key || a.perfilId == key);
    if (idx < 0) {
      final pid = key;
      final full = _alumnos;
      final found = full.firstWhere(
        (a) => a.perfilId == pid || a.key == pid,
        orElse: () => const _AlumnoOperativo(
          key: '',
          perfilId: '',
          ownerAccountId: '',
          nombreUI: '',
          actividad: '',
          aula: '',
          turno: '',
          edad: null,
        ),
      );
      if (found.key.isNotEmpty) {
        idx = visible.indexWhere((a) => a.key == found.key);
      }
    }

    if (idx < 0) return;

    final targetOffset = math.max(0.0, idx * 88.0);

    try {
      await _alumnosScrollCtrl.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: _clampTabIndex(),
    );
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging && mounted) {
        final i = _tabCtrl.index;
        if (i != _tabIndex) setState(() => _tabIndex = i);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_cargarSafe());
    });

    _qCtrl.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveRouteArgsOnce();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _qCtrl.dispose();
    _alumnosScrollCtrl.dispose();
    super.dispose();
  }

  bool _isPlanStatus(Object? v) {
    if (v == null) return false;
    try {
      return v.runtimeType.toString() == 'PlanStatus';
    } catch (_) {
      return false;
    }
  }

  dynamic _planStatusForGuard(Institucion inst) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (inst as dynamic).planStatus;
      if (_isPlanStatus(v)) return v;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final ps = (inst as dynamic).planSafe;
      // ignore: avoid_dynamic_calls
      final v = ps?.status;
      if (_isPlanStatus(v)) return v;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final ps = (inst as dynamic).planSafe;
      if (_isPlanStatus(ps)) return ps;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final p = (inst as dynamic).plan;
      // ignore: avoid_dynamic_calls
      final v = p?.status;
      if (_isPlanStatus(v)) return v;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final p = (inst as dynamic).plan;
      // ignore: avoid_dynamic_calls
      final v = p?.planStatus;
      if (_isPlanStatus(v)) return v;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final v = (inst as dynamic).estadoPlan;
      if (v != null) return v;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final p = (inst as dynamic).plan;
      // ignore: avoid_dynamic_calls
      final v = p?.estadoPlan;
      if (v != null) return v;
    } catch (_) {}

    return null;
  }

  bool _canRunPlanGuard({required dynamic plan}) {
    final owner = _ownerAccountIdResolved.trim();
    if (owner.isEmpty) return false;
    if (plan == null) return false;
    if (_isPlanStatus(plan)) return true;
    return false;
  }

  void _ensureOperativoGuard({required dynamic plan}) {
    final owner = _ownerAccountIdResolved.trim();
    final perfilId = _institucionPerfilIdResolved.trim().isNotEmpty
        ? _institucionPerfilIdResolved.trim()
        : _instIdData;

    if (!_canRunPlanGuard(plan: plan)) {
      debugPrint(
        '[ATENA][VACANTES] plan guard SKIP (owner="${owner.isEmpty ? '(empty)' : owner}" planType="${plan?.runtimeType}" plan="$plan")',
      );
      return;
    }

    try {
      PlanHabilitacionGuard.ensureOperativo(
        context: context,
        plan: plan,
        ownerAccountId: owner,
        institucionPerfilId: perfilId,
        institucionNombre: widget.institucionNombre.trim(),
      );
      return;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final dyn = PlanHabilitacionGuard as dynamic;
      dyn.ensureOperativo(
        context: context,
        plan: plan,
        ownerAccountId: owner,
        institucionPerfilId: perfilId,
        institucionNombre: widget.institucionNombre.trim(),
      );
    } catch (_) {
      try {
        PlanHabilitacionGuard.ensureOperativo(context: context, plan: plan);
      } catch (_) {}
    }
  }

  Future<void> _cargarSafe() async {
    if (!mounted) return;
    if (_booting) return;
    _booting = true;

    _resolveRouteArgsOnce();

    setState(() {
      _cargando = true;
      _fatalError = null;
    });

    final l10n = AppLocalizations.of(context);
    final instId = _instIdData;

    debugPrint(
      '[ATENA][VACANTES] load start instIdData="$instId" owner="${_ownerAccountIdResolved.trim()}" perfilInst="${_institucionPerfilIdResolved.trim()}" '
      'actKey="${_actividadKeyResolved.trim()}" actLabel="${_actividadLabelResolved.trim()}" '
      'wpId="${_workProfileIdResolved.trim()}" wpName="${_workProfileNameResolved.trim()}" '
      'focusApplied=$_focusApplied hasFocus=$_hasFocus',
    );

    if (instId.isEmpty) {
      debugPrint('[ATENA][VACANTES] abort: empty instIdData');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _fatalError = l10n.institucionInvalidGeneric;
      });
      _booting = false;
      return;
    }

    try {
      try {
        final inst = await ih
            .cargarInstitucionPorId(instId)
            .timeout(const Duration(seconds: 4));

        if (inst != null) {
          if (!mounted) return;

          final planForGuard = _planStatusForGuard(inst);
          debugPrint(
            '[ATENA][VACANTES] planForGuard="${planForGuard?.runtimeType}" value="$planForGuard" owner="${_ownerAccountIdResolved.trim()}"',
          );

          _ensureOperativoGuard(plan: planForGuard);

          if (!mounted) return;
        } else {
          debugPrint('[ATENA][VACANTES] plan guard skipped: inst null');
        }
      } on TimeoutException catch (_) {
        debugPrint('[ATENA][VACANTES] plan guard TIMEOUT (inst load)');
      } catch (e, st) {
        debugPrint('[ATENA][VACANTES] plan guard ERROR $e\n$st');
      }

      final outGrupos = await ih
          .cargarGruposInstitucion(instId)
          .timeout(const Duration(seconds: 4));

      final gruposCopy = List<GrupoInstitucional>.of(outGrupos);
      gruposCopy.sort(
        (a, b) =>
            a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
      );

      final alumnos = await _cargarAlumnosOperativos(instId);

      if (!mounted) return;
      setState(() {
        _grupos = gruposCopy;
        _alumnos
          ..clear()
          ..addAll(alumnos);
        _cargando = false;
        _fatalError = null;
      });

      _applyFocusAfterLoad();
      if (mounted) setState(() {});

      debugPrint(
        '[ATENA][VACANTES] load done grupos=${gruposCopy.length} alumnos=${alumnos.length} instIdData="$instId" tab=$_tabIndex focusApplied=$_focusApplied',
      );
    } on TimeoutException catch (_) {
      debugPrint('[ATENA][VACANTES] load TIMEOUT instIdData="$instId"');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _fatalError = l10n.errorLoadingGroups('timeout');
      });
      _snack(l10n.errorLoadingGroups('timeout'));
    } catch (e, st) {
      debugPrint('[ATENA][VACANTES] load ERROR $e\n$st');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _fatalError = l10n.errorLoadingGroups(e.toString());
      });
      _snack(l10n.errorLoadingGroups(e.toString()));
    } finally {
      _booting = false;

      if (mounted && _cargando) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<List<_AlumnoOperativo>> _cargarAlumnosOperativos(String instId) async {
    try {
      final list = await SolicitudesService.obtenerSolicitudesParaInstitucion(
        institucionId: instId,
      ).timeout(const Duration(seconds: 6));

      final out = <_AlumnoOperativo>[];
      final seen = <String>{};

      for (final SolicitudAlumno s in list) {
        if (s.estado != EstadoSolicitud.confirmada) continue;

        final a = _AlumnoOperativo.fromSolicitudBestEffort(s);
        if (a.key.isEmpty) continue;

        if (seen.add(a.key)) out.add(a);
      }

      out.sort((a, b) => a.nombreComparable.compareTo(b.nombreComparable));
      return out;
    } catch (_) {
      return <_AlumnoOperativo>[];
    }
  }

  Future<void> _guardarInternal(List<GrupoInstitucional> grupos) async {
    final instId = _instIdData;
    if (instId.isEmpty) return;

    await ih
        .guardarGruposInstitucion(instId, grupos)
        .timeout(const Duration(seconds: 4));
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!mounted) return;

    setState(() => _guardando = true);

    final l10n = AppLocalizations.of(context);

    try {
      await _guardarInternal(_grupos);
    } on TimeoutException catch (_) {
      _snack(l10n.errorSaving('timeout'));
    } catch (e) {
      _snack(l10n.errorSaving(e.toString()));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  static String _normKey(String? s) => (s ?? '').trim().toLowerCase();

  static String _keyMatch(String actividad, String aulaOrGrupo, String turno) =>
      '${_normKey(actividad)}|${_normKey(aulaOrGrupo)}|${_normKey(turno)}';

  static String _keyGid(String gid) => 'gid|${_normKey(gid)}';

  int _clamp(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  String _solicitudGrupoCurricularIdBestEffort(SolicitudAlumno s) {
    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;
      final v = (d.grupoCurricularId ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;
      final v = (d.grupoId ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}

    return '';
  }

  bool _solicitudEsCurricularDirect(SolicitudAlumno s) {
    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;
      final v = d.esCurricular;
      if (v is bool) return v;
    } catch (_) {}
    try {
      return s.esCurricular;
    } catch (_) {
      return false;
    }
  }

  Future<void> _recalcularOcupadosDesdeSolicitudes() async {
    if (_guardando) return;
    if (!mounted) return;

    setState(() => _guardando = true);

    final l10n = AppLocalizations.of(context);

    try {
      final instId = _instIdData;
      if (instId.isEmpty) {
        _snack(l10n.institucionInvalidGeneric);
        return;
      }

      final list = await SolicitudesService.obtenerSolicitudesParaInstitucion(
        institucionId: instId,
      ).timeout(const Duration(seconds: 6));

      final contadorByGid = <String, int>{};
      final contadorLegacy = <String, int>{};

      for (final SolicitudAlumno s in list) {
        if (s.estado != EstadoSolicitud.confirmada) continue;

        final esCurr = _solicitudEsCurricularDirect(s);
        final gid = esCurr ? _solicitudGrupoCurricularIdBestEffort(s) : '';

        if (esCurr && gid.trim().isNotEmpty) {
          final k = _keyGid(gid);
          contadorByGid[k] = (contadorByGid[k] ?? 0) + 1;
          continue;
        }

        final aula = s.aula.trim();
        if (aula.isEmpty) continue;

        final turno = s.turno.trim();
        final k = _keyMatch(s.actividadNombre, aula, turno);
        contadorLegacy[k] = (contadorLegacy[k] ?? 0) + 1;
      }

      final nuevos = _grupos.map((g) {
        final gid = _n(g.id);
        int raw = 0;

        if (gid.isNotEmpty) {
          raw = contadorByGid[_keyGid(gid)] ?? 0;
        } else {
          final aulaKey = _n(g.aula).isNotEmpty
              ? _n(g.aula)
              : g.nombreGrupo.trim();
          final turnoKey = _n(g.turno);
          final k = _keyMatch(g.actividadNombre, aulaKey, turnoKey);
          raw = contadorLegacy[k] ?? 0;
        }

        final occ = g.cupoMaximo <= 0 ? 0 : _clamp(raw, 0, g.cupoMaximo);

        final disponible = (g.cupoMaximo - occ) > 0;

        return GrupoInstitucional(
          id: g.id,
          institucionId: g.institucionId,
          actividadNombre: g.actividadNombre,
          nombreGrupo: g.nombreGrupo,
          aula: g.aula,
          turno: g.turno,
          cupoMaximo: g.cupoMaximo,
          cupoOcupado: occ,
          estado: disponible ? EstadoCupo.disponible : EstadoCupo.completo,
        );
      }).toList();

      nuevos.sort(
        (a, b) =>
            a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
      );

      if (!mounted) return;
      setState(() => _grupos = nuevos);

      await _guardarInternal(nuevos).timeout(const Duration(seconds: 6));
      _snack(l10n.occupiedRecalculatedOk);

      final alumnos = await _cargarAlumnosOperativos(_instIdData);
      if (mounted) {
        setState(() {
          _alumnos
            ..clear()
            ..addAll(alumnos);
          _selectedAlumnoKeys.removeWhere(
            (k) => !_alumnos.any((a) => a.key == k),
          );
        });
      }
    } on TimeoutException catch (_) {
      _snack(l10n.errorRecalculating('timeout'));
    } catch (e) {
      _snack(l10n.errorRecalculating(e.toString()));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  int _parseIntSafe(String v, {int fallback = 0}) {
    final t = v.trim();
    if (t.isEmpty) return fallback;
    final onlyDigits = t.replaceAll(RegExp(r'[^0-9\-]'), '');
    final parsed = int.tryParse(onlyDigits);
    return parsed ?? fallback;
  }

  List<String> _nivelOptions() => const ['Jardín', 'Primaria', 'Secundaria'];

  List<String> _turnoOptions() => const ['Mañana', 'Tarde', 'Noche', 'Otro'];

  String _resolveTurnoFromUI(String base, String otherText) {
    final b = base.trim();
    if (b.isEmpty) return '';
    if (b.toLowerCase() == 'otro') return otherText.trim();
    return b;
  }

  Future<void> _crearOEditar({GrupoInstitucional? existente}) async {
    if (_guardando) return;

    final curso = existente == null
        ? const _GrupoCursoUI()
        : _parseCursoFromGrupo(existente);

    String nivelSel = curso.nivel.trim();
    String turnoSel = curso.turno.trim();

    if (existente == null) {
      nivelSel = nivelSel.isNotEmpty ? nivelSel : 'Primaria';
      turnoSel = turnoSel.isNotEmpty ? turnoSel : 'Mañana';
    }

    final nombreCtrl = TextEditingController(
      text: existente?.nombreGrupo ?? '',
    );
    final actividadCtrl = TextEditingController(
      text: existente?.actividadNombre ?? '',
    );

    final gradoCtrl = TextEditingController(text: curso.gradoSalaAnio);
    final horarioIniCtrl = TextEditingController(text: curso.horarioInicio);
    final horarioFinCtrl = TextEditingController(text: curso.horarioFin);

    final turnoOtroCtrl = TextEditingController(
      text: (_turnoOptions().contains(turnoSel) ? '' : turnoSel),
    );
    if (_turnoOptions().contains(turnoSel) == false && turnoSel.isNotEmpty) {
      turnoSel = 'Otro';
    }

    final cupoCtrl = TextEditingController(
      text: (existente?.cupoMaximo ?? 0).toString(),
    );

    final l10n = AppLocalizations.of(context);

    try {
      final res = await showDialog<GrupoInstitucional?>(
        context: context,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (dialogCtx2, setLocal) {
              void localSnack(String msg) {
                try {
                  final messenger = ScaffoldMessenger.of(dialogCtx2);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(SnackBar(content: Text(msg)));
                } catch (_) {}
              }

              final theme = Theme.of(dialogCtx2);
              final cs = theme.colorScheme;

              Widget dd({
                required String label,
                required String value,
                required List<String> options,
                required ValueChanged<String> onChanged,
                required String keyPrefix,
              }) {
                final safe = _safeValueInOptions(value, options);
                return DropdownButtonFormField<String>(
                  key: ValueKey<String>('$keyPrefix|$safe|${options.length}'),
                  initialValue: safe.isNotEmpty ? safe : options.first,
                  items: options
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => onChanged((v ?? '').trim()),
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                );
              }

              String? validateHorario(String v) {
                final t = v.trim();
                if (t.isEmpty) return null;
                final re = RegExp(r'^\d{1,2}:\d{2}$');
                return re.hasMatch(t)
                    ? null
                    : _t(l10n, 'invalidTimeFormat', 'Formato inválido (HH:MM)');
              }

              final e1 = validateHorario(horarioIniCtrl.text);
              final e2 = validateHorario(horarioFinCtrl.text);

              return AlertDialog(
                title: Text(
                  existente == null ? l10n.newGroupTitle : l10n.editGroupTitle,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.groupNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: actividadCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.activityLabelShort,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _t(l10n, 'curricularCourseLabel', 'Curso (canónico)'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      dd(
                        keyPrefix: 'nivel',
                        label: _t(l10n, 'levelLabel', 'Nivel'),
                        value: nivelSel.isEmpty ? 'Primaria' : nivelSel,
                        options: _nivelOptions(),
                        onChanged: (v) => setLocal(() => nivelSel = v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: gradoCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _t(
                            l10n,
                            'gradeSalaYearLabel',
                            'Grado / Sala / Año',
                          ),
                          hintText: _t(
                            l10n,
                            'gradeSalaYearHint',
                            'Ej: 3° A · Sala 4 · 2° año',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 10),
                      dd(
                        keyPrefix: 'turno',
                        label: _t(l10n, 'turnLabel', 'Turno'),
                        value: turnoSel.isEmpty ? 'Mañana' : turnoSel,
                        options: _turnoOptions(),
                        onChanged: (v) {
                          setLocal(() {
                            turnoSel = v;
                            if (turnoSel.toLowerCase() != 'otro') {
                              // opcional: limpiar campo “otro” cuando ya no aplica
                              // turnoOtroCtrl.clear();
                            }
                          });
                        },
                      ),
                      if (turnoSel.toLowerCase() == 'otro') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: turnoOtroCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _t(
                              l10n,
                              'turnOtherLabel',
                              'Turno (otro)',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setLocal(() {}),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: horarioIniCtrl,
                              keyboardType: TextInputType.datetime,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: _t(
                                  l10n,
                                  'timeStartLabel',
                                  'Horario inicio',
                                ),
                                hintText: '08:00',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setLocal(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: horarioFinCtrl,
                              keyboardType: TextInputType.datetime,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: _t(
                                  l10n,
                                  'timeEndLabel',
                                  'Horario fin',
                                ),
                                hintText: '12:00',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setLocal(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _t(
                            l10n,
                            'courseSerializeHint',
                            'Se guarda como Aula = Nivel • Grado/Sala/Año y Turno = Turno • HH:MM-HH:MM (backend-ready, migrable).',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cupoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.maxCapacityLabel,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 6),
                      if (e1 != null || e2 != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              [e1, e2].whereType<String>().join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx2).pop(null),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final nombre = nombreCtrl.text.trim();
                      final act = actividadCtrl.text.trim();
                      final gradoSala = gradoCtrl.text.trim();
                      final baseTurno = turnoSel.trim();
                      final turnoReal = _resolveTurnoFromUI(
                        baseTurno,
                        turnoOtroCtrl.text,
                      );

                      final hIni = horarioIniCtrl.text.trim();
                      final hFin = horarioFinCtrl.text.trim();

                      final cupo = _parseIntSafe(cupoCtrl.text, fallback: 0);

                      if (nombre.isEmpty || act.isEmpty || cupo <= 0) {
                        localSnack(l10n.completeRequiredFields);
                        return;
                      }

                      final nivel = nivelSel.trim();
                      if (nivel.isEmpty) {
                        localSnack(
                          _t(
                            l10n,
                            'completeRequiredFields',
                            'Completá los campos requeridos.',
                          ),
                        );
                        return;
                      }

                      if (hIni.isNotEmpty || hFin.isNotEmpty) {
                        final re = RegExp(r'^\d{1,2}:\d{2}$');
                        if (hIni.isEmpty ||
                            hFin.isEmpty ||
                            !re.hasMatch(hIni) ||
                            !re.hasMatch(hFin)) {
                          localSnack(
                            _t(
                              l10n,
                              'invalidTimeFormat',
                              'Formato inválido (HH:MM)',
                            ),
                          );
                          return;
                        }
                      }

                      final prevOcc = existente?.cupoOcupado ?? 0;
                      final occ = math.min(math.max(prevOcc, 0), cupo);

                      final instId = _instIdData;
                      if (instId.isEmpty) {
                        localSnack(l10n.institucionInvalidGeneric);
                        return;
                      }

                      final aulaSerialized = _composeAula(
                        nivel: nivel,
                        gradoSalaAnio: gradoSala,
                      );

                      final turnoSerialized = _composeTurno(
                        turno: turnoReal,
                        horarioInicio: hIni,
                        horarioFin: hFin,
                      );

                      final disponible = (cupo - occ) > 0;

                      final newDeterministicId = _makeGrupoIdDeterministic(
                        aulaSerialized: aulaSerialized,
                        turnoSerialized: turnoSerialized,
                        nombreGrupoFallback: nombre,
                        horarioInicio: hIni,
                        horarioFin: hFin,
                      );

                      final g = GrupoInstitucional(
                        id: (existente?.id ?? '').trim().isNotEmpty
                            ? existente!.id
                            : newDeterministicId,
                        institucionId: instId,
                        actividadNombre: act,
                        nombreGrupo: nombre,
                        aula: aulaSerialized.isEmpty ? null : aulaSerialized,
                        turno: turnoSerialized.isEmpty ? null : turnoSerialized,
                        cupoMaximo: cupo,
                        cupoOcupado: occ,
                        estado: disponible
                            ? EstadoCupo.disponible
                            : EstadoCupo.completo,
                      );

                      Navigator.of(dialogCtx2).pop(g);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              );
            },
          );
        },
      );

      if (res == null) return;

      if (!mounted) return;
      setState(() {
        final next = List<GrupoInstitucional>.of(_grupos);
        if (existente == null) {
          next.add(res);
        } else {
          final idx = next.indexWhere((e) => e.id == existente.id);
          if (idx >= 0) next[idx] = res;
        }
        next.sort(
          (a, b) => a.nombreGrupo.toLowerCase().compareTo(
            b.nombreGrupo.toLowerCase(),
          ),
        );
        _grupos = next;
      });

      await _guardar();
    } finally {
      nombreCtrl.dispose();
      actividadCtrl.dispose();
      gradoCtrl.dispose();
      horarioIniCtrl.dispose();
      horarioFinCtrl.dispose();
      turnoOtroCtrl.dispose();
      cupoCtrl.dispose();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // RESTO DEL ARCHIVO: SIN CAMBIOS (tal como lo pegaste)
  // ────────────────────────────────────────────────────────────────────────────

  List<String> _actividadOptions() {
    final set = <String>{};
    for (final a in _alumnos) {
      final v = a.actividad.trim();
      if (v.isNotEmpty) set.add(v);
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  List<String> _aulaOptions() {
    final set = <String>{};
    for (final a in _alumnos) {
      final v = a.aula.trim();
      if (v.isNotEmpty) set.add(v);
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  List<_AlumnoOperativo> _alumnosFiltrados() {
    final q = _qCtrl.text.trim().toLowerCase();
    final act = _fActividad.trim().toLowerCase();
    final aula = _fAula.trim().toLowerCase();

    bool matchEdad(_AlumnoOperativo a) {
      final edad = a.edad;
      if (edad == null) {
        if (_fEdadMin != null || _fEdadMax != null) return false;
        return true;
      }
      if (_fEdadMin != null && edad < _fEdadMin!) return false;
      if (_fEdadMax != null && edad > _fEdadMax!) return false;
      return true;
    }

    return _alumnos.where((a) {
      if (act.isNotEmpty && a.actividad.toLowerCase() != act) return false;
      if (aula.isNotEmpty && a.aula.toLowerCase() != aula) return false;
      if (!matchEdad(a)) return false;

      if (q.isEmpty) return true;
      final blob = a.searchBlob;
      return blob.contains(q);
    }).toList();
  }

  void _toggleAlumno(String key, bool v) {
    if (!mounted) return;
    setState(() {
      if (v) {
        _selectedAlumnoKeys.add(key);
      } else {
        _selectedAlumnoKeys.remove(key);
      }
    });
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() => _selectedAlumnoKeys.clear());
  }

  Future<String?> _resolveOwnerForAlumno(_AlumnoOperativo a) async {
    final raw = a.ownerAccountId.trim();
    if (raw.isNotEmpty) return raw;

    final pid = a.perfilId.trim();
    if (pid.isNotEmpty) {
      try {
        final resolved = await NotificacionesService.instance
            .resolveOwnerForPerfil(pid)
            .timeout(const Duration(seconds: 3));
        if (_n(resolved).isNotEmpty) return resolved;
      } catch (_) {}
    }

    return null;
  }

  DateTime _applyTime(DateTime date, TimeOfDay t) {
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  SegmentoEventoEspecial? _buildSegmentoOrNull({
    required NivelEducativo? nivel,
    required TurnoInstitucion? turno,
    required String grupoKey,
    required String grupoLabel,
  }) {
    final gk = grupoKey.trim();
    final gl = grupoLabel.trim();

    if (nivel == null && turno == null && gk.isEmpty && gl.isEmpty) {
      return null;
    }

    return SegmentoEventoEspecial(
      nivel: nivel,
      turno: turno,
      grupoKey: gk.isEmpty ? null : gk,
      grupoLabel: gl.isEmpty ? null : gl,
    );
  }

  String _solicitudPerfilIdBestEffort(SolicitudAlumno s) {
    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;
      final v1 = (d.perfilId ?? '').toString().trim();
      if (v1.isNotEmpty) return v1;
      final v2 = (d.alumnoId ?? '').toString().trim();
      if (v2.isNotEmpty) return v2;
      final v3 = (d.alumnoPerfilId ?? '').toString().trim();
      if (v3.isNotEmpty) return v3;
    } catch (_) {}
    return '';
  }

  bool? _solicitudEsCurricularBestEffort(SolicitudAlumno s) {
    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;
      final v = d.esCurricular;
      if (v is bool) return v;
    } catch (_) {}
    return null;
  }

  Future<void> _emitirDialog() async {
    // (sin cambios)
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    if (_tabIndex != 1) {
      _snack(
        _t(
          l10n,
          'selectAlumnosTabFirst',
          'Abrí la pestaña de Alumnos para emitir.',
        ),
      );
      return;
    }

    final totalAlumnos = _alumnos.length;
    if (totalAlumnos <= 0) {
      _snack(_t(l10n, 'noAlumnosToNotify', 'No hay alumnos para notificar.'));
      return;
    }

    final selected = _selectedAlumnoKeys.toList();
    final hasSelected = selected.isNotEmpty;

    final aulaOptions = _aulaOptions();
    final actividadOptions = _actividadOptions();

    _EmisionAlcance alcance = hasSelected
        ? _EmisionAlcance.seleccionados
        : _EmisionAlcance.aula;

    String aulaScope = _safeValueInOptions(_fAula, aulaOptions);
    String actividadScope = _safeValueInOptions(_fActividad, actividadOptions);

    _EmisionTipo tipo = _EmisionTipo.notificar;

    TipoEventoEspecial tipoEspecial = TipoEventoEspecial.otro;
    DateTime inicio = DateTime.now();
    DateTime? fin;
    bool usarFin = false;

    NivelEducativo? segNivel;
    TurnoInstitucion? segTurno;
    final segGrupoKeyCtrl = TextEditingController();
    final segGrupoLabelCtrl = TextEditingController();

    final tituloCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          Widget dd<T>({
            required T value,
            required List<DropdownMenuItem<T>> items,
            required ValueChanged<T?> onChanged,
          }) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            );
          }

          Widget ddNullable<T>({
            required T? value,
            required List<DropdownMenuItem<T?>> items,
            required ValueChanged<T?> onChanged,
          }) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T?>(
                  value: value,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            );
          }

          String fmtDate(DateTime d) =>
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          String fmtTime(DateTime d) =>
              '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

          Future<void> pickInicioDate(StateSetter setLocal) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: inicio,
              firstDate: DateTime(DateTime.now().year - 1),
              lastDate: DateTime(DateTime.now().year + 3),
            );
            if (picked == null) return;
            final oldTime = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
            setLocal(() {
              inicio = _applyTime(picked, oldTime);
              if (usarFin && fin != null && fin!.isBefore(inicio)) {
                fin = inicio.add(const Duration(hours: 1));
              }
            });
          }

          Future<void> pickInicioTime(StateSetter setLocal) async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay(hour: inicio.hour, minute: inicio.minute),
            );
            if (picked == null) return;
            setLocal(() {
              inicio = _applyTime(inicio, picked);
              if (usarFin && fin != null && fin!.isBefore(inicio)) {
                fin = inicio.add(const Duration(hours: 1));
              }
            });
          }

          Future<void> pickFinDate(StateSetter setLocal) async {
            final base = fin ?? inicio.add(const Duration(hours: 1));
            final picked = await showDatePicker(
              context: ctx,
              initialDate: base,
              firstDate: DateTime(DateTime.now().year - 1),
              lastDate: DateTime(DateTime.now().year + 3),
            );
            if (picked == null) return;
            final oldTime = TimeOfDay(hour: base.hour, minute: base.minute);
            setLocal(() {
              fin = _applyTime(picked, oldTime);
              if (fin != null && fin!.isBefore(inicio)) {
                fin = inicio.add(const Duration(hours: 1));
              }
            });
          }

          Future<void> pickFinTime(StateSetter setLocal) async {
            final base = fin ?? inicio.add(const Duration(hours: 1));
            final picked = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
            );
            if (picked == null) return;
            setLocal(() {
              fin = _applyTime(base, picked);
              if (fin != null && fin!.isBefore(inicio)) {
                fin = inicio.add(const Duration(hours: 1));
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx2, setLocal) {
                final aulaScopeSafe = _safeValueInOptions(
                  aulaScope,
                  aulaOptions,
                );
                final actividadScopeSafe = _safeValueInOptions(
                  actividadScope,
                  actividadOptions,
                );

                if (aulaScopeSafe != aulaScope) aulaScope = aulaScopeSafe;
                if (actividadScopeSafe != actividadScope) {
                  actividadScope = actividadScopeSafe;
                }

                final titleLabel = _t(l10n, 'emisionTitle', 'Emisión');
                final alcanceLabel = _t(l10n, 'emisionScope', 'Alcance');
                final tipoLabel = _t(l10n, 'emisionType', 'Acción');
                final tTitulo = _t(l10n, 'titleLabel', 'Título');
                final tMensaje = _t(l10n, 'messageLabel', 'Mensaje');
                final btnCancel = l10n.cancel;
                final btnOk = _guardando ? l10n.saving : l10n.send;

                final hintSelected = _t(l10n, 'selectedCount', 'Seleccionados');
                final hintAula = _t(l10n, 'scopeAula', 'Aula');
                final hintInst = _t(l10n, 'scopeInstitucion', 'Institución');

                final canSelected = hasSelected;
                final canAula =
                    aulaOptions.isNotEmpty || _alumnosFiltrados().isNotEmpty;
                final canInst = totalAlumnos > 0;

                final alcanceItems = <DropdownMenuItem<_EmisionAlcance>>[
                  DropdownMenuItem(
                    value: _EmisionAlcance.seleccionados,
                    enabled: canSelected,
                    child: Text('$hintSelected (${selected.length})'),
                  ),
                  DropdownMenuItem(
                    value: _EmisionAlcance.aula,
                    enabled: canAula,
                    child: Text(hintAula),
                  ),
                  DropdownMenuItem(
                    value: _EmisionAlcance.institucion,
                    enabled: canInst,
                    child: Text(hintInst),
                  ),
                ];

                final tipoItems = <DropdownMenuItem<_EmisionTipo>>[
                  DropdownMenuItem(
                    value: _EmisionTipo.notificar,
                    child: Text(
                      _t(l10n, 'actionNotifyOnly', 'Notificar (Inbox)'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: _EmisionTipo.emitir,
                    child: Text(
                      _t(
                        l10n,
                        'actionEmitCalendar',
                        'Emitir (Inbox + Calendario)',
                      ),
                    ),
                  ),
                ];

                final aulaItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: '', child: Text('—')),
                  ...aulaOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ];

                final actividadItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: '', child: Text('—')),
                  ...actividadOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ];

                final tipoEspecialItems = TipoEventoEspecial.values
                    .map(
                      (e) => DropdownMenuItem<TipoEventoEspecial>(
                        value: e,
                        child: Text(
                          _labelBestEffort(e, fallback: _enumNameBestEffort(e)),
                        ),
                      ),
                    )
                    .toList();

                final nivelItems = <DropdownMenuItem<NivelEducativo?>>[
                  DropdownMenuItem(
                    value: null,
                    child: Text(_t(l10n, 'segmentNone', '— (sin segmento) —')),
                  ),
                  ...NivelEducativo.values.map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        _labelBestEffort(e, fallback: _enumNameBestEffort(e)),
                      ),
                    ),
                  ),
                ];

                final turnoItems = <DropdownMenuItem<TurnoInstitucion?>>[
                  DropdownMenuItem(
                    value: null,
                    child: Text(_t(l10n, 'segmentNone', '— (sin segmento) —')),
                  ),
                  ...TurnoInstitucion.values.map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        _labelBestEffort(e, fallback: _enumNameBestEffort(e)),
                      ),
                    ),
                  ),
                ];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(alcanceLabel, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    dd<_EmisionAlcance>(
                      value: alcance,
                      items: alcanceItems,
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => alcance = v);
                      },
                    ),
                    if (alcance == _EmisionAlcance.aula) ...[
                      const SizedBox(height: 10),
                      Text(
                        _t(l10n, 'filtersLabel', 'Filtros'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: dd<String>(
                              value: actividadScope,
                              items: actividadItems,
                              onChanged: (v) => setLocal(
                                () => actividadScope = (v ?? '').trim(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: dd<String>(
                              value: aulaScope,
                              items: aulaItems,
                              onChanged: (v) =>
                                  setLocal(() => aulaScope = (v ?? '').trim()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          l10n,
                          'scopeAulaHint',
                          'Se enviará a alumnos confirmados que coincidan con los filtros.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(tipoLabel, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    dd<_EmisionTipo>(
                      value: tipo,
                      items: tipoItems,
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() {
                          tipo = v;
                          if (tipo == _EmisionTipo.emitir) {
                            fin ??= inicio.add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tituloCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: tTitulo,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: tMensaje,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (tipo == _EmisionTipo.emitir) ...[
                      const SizedBox(height: 14),
                      Text(
                        _t(l10n, 'eventSpecialLabel', 'Evento especial'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      dd<TipoEventoEspecial>(
                        value: tipoEspecial,
                        items: tipoEspecialItems,
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() => tipoEspecial = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  unawaited(pickInicioDate(setLocal)),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                '${_t(l10n, 'startDate', 'Inicio')}: ${fmtDate(inicio)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  unawaited(pickInicioTime(setLocal)),
                              icon: const Icon(Icons.schedule),
                              label: Text(fmtTime(inicio)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: usarFin,
                        onChanged: (v) {
                          setLocal(() {
                            usarFin = v;
                            if (usarFin) {
                              fin ??= inicio.add(const Duration(hours: 1));
                              if (fin != null && fin!.isBefore(inicio)) {
                                fin = inicio.add(const Duration(hours: 1));
                              }
                            } else {
                              fin = null;
                            }
                          });
                        },
                        title: Text(_t(l10n, 'useEnd', 'Agregar fin')),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (usarFin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    unawaited(pickFinDate(setLocal)),
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  '${_t(l10n, 'endDate', 'Fin')}: ${fmtDate(fin ?? inicio)}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    unawaited(pickFinTime(setLocal)),
                                icon: const Icon(Icons.schedule),
                                label: Text(fmtTime(fin ?? inicio)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t(
                            l10n,
                            'endHint',
                            'El fin es opcional. Si queda antes del inicio, se corrige automáticamente.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _t(l10n, 'segmentLabel', 'Segmentación (opcional)'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ddNullable<NivelEducativo>(
                              value: segNivel,
                              items: nivelItems,
                              onChanged: (v) => setLocal(() => segNivel = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ddNullable<TurnoInstitucion>(
                              value: segTurno,
                              items: turnoItems,
                              onChanged: (v) => setLocal(() => segTurno = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: segGrupoKeyCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _t(
                            l10n,
                            'segmentGroupKey',
                            'Grupo key (opcional)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: segGrupoLabelCtrl,
                        decoration: InputDecoration(
                          labelText: _t(
                            l10n,
                            'segmentGroupLabel',
                            'Grupo label (opcional)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(btnCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final t = tituloCtrl.text.trim();
                              final m = msgCtrl.text.trim();
                              if (t.isEmpty || m.isEmpty) {
                                _snack(
                                  _t(
                                    l10n,
                                    'completeRequiredFields',
                                    'Completá título y mensaje.',
                                  ),
                                );
                                return;
                              }
                              if (tipo == _EmisionTipo.emitir) {
                                if (usarFin &&
                                    fin != null &&
                                    fin!.isBefore(inicio)) {
                                  setLocal(() {
                                    fin = inicio.add(const Duration(hours: 1));
                                  });
                                }
                              }
                              Navigator.of(ctx).pop(true);
                            },
                            icon: const Icon(Icons.send),
                            label: Text(btnOk),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (ok != true) return;

      final segmento = _buildSegmentoOrNull(
        nivel: segNivel,
        turno: segTurno,
        grupoKey: segGrupoKeyCtrl.text,
        grupoLabel: segGrupoLabelCtrl.text,
      );

      await _ejecutarEmision(
        alcance: alcance,
        tipo: tipo,
        titulo: tituloCtrl.text.trim(),
        mensaje: msgCtrl.text.trim(),
        actividadScope: actividadScope,
        aulaScope: aulaScope,
        inicio: inicio,
        fin: fin,
        tipoEspecial: tipoEspecial,
        segmento: segmento,
      );
    } finally {
      tituloCtrl.dispose();
      msgCtrl.dispose();
      segGrupoKeyCtrl.dispose();
      segGrupoLabelCtrl.dispose();
    }
  }

  Future<void> _ejecutarEmision({
    required _EmisionAlcance alcance,
    required _EmisionTipo tipo,
    required String titulo,
    required String mensaje,
    required String actividadScope,
    required String aulaScope,
    required DateTime inicio,
    required DateTime? fin,
    required TipoEventoEspecial tipoEspecial,
    required SegmentoEventoEspecial? segmento,
  }) async {
    // (sin cambios)
    if (!mounted) return;
    if (_guardando) return;

    final l10n = AppLocalizations.of(context);

    setState(() => _guardando = true);

    try {
      final targets = _resolverTargets(
        alcance: alcance,
        actividadScope: actividadScope,
        aulaScope: aulaScope,
      );

      if (targets.isEmpty) {
        _snack(_t(l10n, 'noTargetsFound', 'No se encontraron destinatarios.'));
        return;
      }

      if (tipo == _EmisionTipo.emitir) {
        final instId = _instIdData;
        if (instId.isEmpty) {
          _snack(l10n.institucionInvalidGeneric);
          return;
        }

        List<SolicitudAlumno> confirmados = <SolicitudAlumno>[];

        if (alcance == _EmisionAlcance.seleccionados) {
          final selectedPids = targets
              .map((a) => a.perfilId.trim())
              .where((p) => p.isNotEmpty)
              .toSet();

          if (selectedPids.isEmpty) {
            _snack(
              _t(l10n, 'noTargetsFound', 'No se encontraron destinatarios.'),
            );
            return;
          }

          final all = await InstitucionEmisionesService.instance
              .obtenerConfirmados(institucionId: instId)
              .timeout(const Duration(seconds: 6));

          confirmados = all.where((s) {
            final pid = _solicitudPerfilIdBestEffort(s);
            return pid.isNotEmpty && selectedPids.contains(pid);
          }).toList();
        } else if (alcance == _EmisionAlcance.aula) {
          confirmados = await InstitucionEmisionesService.instance
              .obtenerConfirmados(
                institucionId: instId,
                actividadNombre: actividadScope.trim().isEmpty
                    ? null
                    : actividadScope.trim(),
                aula: aulaScope.trim().isEmpty ? null : aulaScope.trim(),
              )
              .timeout(const Duration(seconds: 6));
        } else {
          confirmados = await InstitucionEmisionesService.instance
              .obtenerConfirmados(institucionId: instId)
              .timeout(const Duration(seconds: 6));
        }

        if (confirmados.isEmpty) {
          _snack(
            _t(l10n, 'noTargetsFound', 'No se encontraron destinatarios.'),
          );
          return;
        }

        bool hasCurr = false;
        bool hasExtra = false;
        for (final s in confirmados) {
          final v = _solicitudEsCurricularBestEffort(s);
          if (v == true) hasCurr = true;
          if (v == false) hasExtra = true;
        }
        final esCurricular = hasCurr && !hasExtra;

        final emitted = await InstitucionEmisionesService.instance
            .emitirEventoEspecialAConfirmados(
              institucionId: instId,
              institucionNombre: widget.institucionNombre.trim(),
              confirmados: confirmados,
              esCurricular: esCurricular,
              actividadNombre: actividadScope.trim().isEmpty
                  ? null
                  : actividadScope.trim(),
              inicio: inicio,
              fin: fin,
              titulo: titulo,
              descripcion: mensaje,
              tipoEspecial: tipoEspecial,
              segmento: segmento,
            )
            .timeout(const Duration(seconds: 20));

        final count = emitted.length;
        if (count <= 0) {
          _snack(
            _t(
              l10n,
              'emisionNoDelivered',
              'No se pudo emitir (sin destinatarios válidos).',
            ),
          );
          return;
        }

        _snack(_t(l10n, 'emisionOkCalendarDone', 'Emitido: $count alumno(s).'));
        return;
      }

      int okCount = 0;

      for (final a in targets) {
        final ownerResolved = await _resolveOwnerForAlumno(a);
        final ownerAccountId = (ownerResolved ?? '').trim();
        final perfilId = a.perfilId.trim();

        if (ownerAccountId.isEmpty) continue;

        final payload = <String, dynamic>{
          'source': 'institucion_gestion_vacantes',
          'institucionId': _instIdData,
          'institucionPerfilId': _institucionPerfilIdResolved.trim().isEmpty
              ? null
              : _institucionPerfilIdResolved.trim(),
          'institucionWorkProfileId': _workProfileIdResolved.trim().isEmpty
              ? null
              : _workProfileIdResolved.trim(),
          'institucionWorkProfileName': _workProfileNameResolved.trim().isEmpty
              ? null
              : _workProfileNameResolved.trim(),
          'actividadKeyScope': _actividadKeyResolved.trim().isEmpty
              ? null
              : _actividadKeyResolved.trim(),
          'actividadLabelScope': _actividadLabelResolved.trim().isEmpty
              ? null
              : _actividadLabelResolved.trim(),
          'actividad': a.actividad,
          'aula': a.aula,
          'turno': a.turno,
          'emitToCalendar': false,
          'scope': _enumNameBestEffort(alcance),
        };

        final map = <String, dynamic>{
          'id': NotificacionesService.newId(prefix: 'EMI'),
          'ownerAccountId': ownerAccountId,
          'perfilId': perfilId.isEmpty ? null : perfilId,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': 'info',
          'leida': false,
          'fechaIso': DateTime.now().toIso8601String(),
          'data': payload,
        };

        NotificacionAtena noti;
        try {
          noti = NotificacionAtena.fromMap(map);
        } catch (_) {
          continue;
        }

        try {
          await NotificacionesService.instance
              .pushToOwner(
                ownerAccountId: ownerAccountId,
                notificacion: noti,
                duplicarEnPerfil: perfilId.isNotEmpty,
              )
              .timeout(const Duration(seconds: 6));
          okCount++;
        } catch (_) {}
      }

      if (okCount <= 0) {
        _snack(
          _t(
            l10n,
            'emisionNoDelivered',
            'No se pudo enviar (no se resolvió owner de los destinatarios).',
          ),
        );
        return;
      }

      _snack(_t(l10n, 'notifyOk', 'Notificación enviada.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  List<_AlumnoOperativo> _resolverTargets({
    required _EmisionAlcance alcance,
    required String actividadScope,
    required String aulaScope,
  }) {
    final act = actividadScope.trim().toLowerCase();
    final aula = aulaScope.trim().toLowerCase();

    if (alcance == _EmisionAlcance.institucion) {
      return List<_AlumnoOperativo>.of(_alumnos);
    }

    if (alcance == _EmisionAlcance.aula) {
      return _alumnos.where((a) {
        if (act.isNotEmpty && a.actividad.toLowerCase() != act) return false;
        if (aula.isNotEmpty && a.aula.toLowerCase() != aula) return false;
        return true;
      }).toList();
    }

    final set = _selectedAlumnoKeys;
    return _alumnos.where((a) => set.contains(a.key)).toList();
  }

  Widget _fatalView(BuildContext context, String msg) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _guardando ? null : () => unawaited(_cargarSafe()),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.actionRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabGrupos(AppLocalizations l10n) {
    final totCap = _grupos.fold<int>(0, (a, b) => a + b.cupoMaximo);
    final totOcc = _grupos.fold<int>(0, (a, b) => a + b.cupoOcupado);
    final totDisp = math.max(0, totCap - totOcc);

    final summaryTitleStyle =
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800) ??
        const TextStyle(fontWeight: FontWeight.w800);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.summaryLabel, style: summaryTitleStyle),
                  const SizedBox(height: 8),
                  Text(l10n.totalCapacityValue(totCap)),
                  Text(l10n.occupiedValue(totOcc)),
                  Text(l10n.availableEstimatedValue(totDisp)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _grupos.isEmpty
              ? Center(child: Text(l10n.noGroupsLoaded))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                  itemCount: _grupos.length,
                  itemBuilder: (context, i) {
                    final g = _grupos[i];
                    final disp = g.cupoDisponible;

                    final curso = _parseCursoFromGrupo(g);
                    final nivel = curso.nivel.trim();
                    final grado = curso.gradoSalaAnio.trim();
                    final turno = curso.turno.trim();
                    final horario = _fmtHorario(
                      curso.horarioInicio,
                      curso.horarioFin,
                    ).trim();

                    final subtitleExtras = <String>[
                      if (nivel.isNotEmpty)
                        '${_t(l10n, 'levelLabel', 'Nivel')}: $nivel',
                      if (grado.isNotEmpty)
                        '${_t(l10n, 'gradeSalaYearLabel', 'Grado/Sala/Año')}: $grado',
                      if (turno.isNotEmpty)
                        '${_t(l10n, 'turnLabel', 'Turno')}: $turno',
                      if (horario.isNotEmpty)
                        '${_t(l10n, 'scheduleLabel', 'Horario')}: $horario',
                      if (_n(g.id).isNotEmpty) 'ID: ${_n(g.id)}',
                    ];

                    return Card(
                      child: ListTile(
                        title: Text(g.nombreGrupo),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.vacancyGroupSubtitle(
                                g.actividadNombre,
                                g.cupoMaximo,
                                g.cupoOcupado,
                                disp,
                              ),
                            ),
                            if (subtitleExtras.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitleExtras.join(' • '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: l10n.edit,
                          icon: const Icon(Icons.edit),
                          onPressed: _guardando
                              ? null
                              : () => unawaited(_crearOEditar(existente: g)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabAlumnos(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = _alumnosFiltrados();

    final actOptions = _actividadOptions();
    final aulaOptions = _aulaOptions();

    final actValueSafe = _safeValueInOptions(_fActividad, actOptions);
    final aulaValueSafe = _safeValueInOptions(_fAula, aulaOptions);
    if (actValueSafe != _fActividad || aulaValueSafe != _fAula) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _fActividad = actValueSafe;
          _fAula = aulaValueSafe;
        });
      });
    }

    final selectedCount = _selectedAlumnoKeys.length;

    Widget dd({
      required String value,
      required List<String> options,
      required ValueChanged<String> onChanged,
      required String label,
      required String keyPrefix,
    }) {
      final safeValue = _safeValueInOptions(value, options);

      return Expanded(
        child: DropdownButtonFormField<String>(
          key: ValueKey<String>('$keyPrefix|$safeValue|${options.length}'),
          initialValue: safeValue,
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(value: '', child: Text('— $label —')),
            ...options.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: (v) => onChanged(v ?? ''),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                controller: _qCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: _t(l10n, 'searchLabel', 'Buscar'),
                  hintText: _t(l10n, 'searchHint', 'Nombre / documento / id'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _qCtrl.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _qCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  dd(
                    keyPrefix: 'fActividad',
                    value: actValueSafe,
                    options: actOptions,
                    onChanged: (v) => setState(() => _fActividad = v),
                    label: _t(l10n, 'activityLabelShort', 'Actividad'),
                  ),
                  const SizedBox(width: 10),
                  dd(
                    keyPrefix: 'fAula',
                    value: aulaValueSafe,
                    options: aulaOptions,
                    onChanged: (v) => setState(() => _fAula = v),
                    label: _t(l10n, 'classroomLabel', 'Aula'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: _fEdadMin?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: _t(l10n, 'ageMinLabel', 'Edad mín'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {
                        _fEdadMin = int.tryParse(v.trim());
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: _fEdadMax?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: _t(l10n, 'ageMaxLabel', 'Edad máx'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {
                        _fEdadMax = int.tryParse(v.trim());
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: _t(l10n, 'clearFilters', 'Limpiar filtros'),
                    onPressed: () {
                      setState(() {
                        _fActividad = '';
                        _fAula = '';
                        _fEdadMin = null;
                        _fEdadMax = null;
                        _qCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_t(l10n, 'resultsLabel', 'Resultados')}: ${items.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (selectedCount > 0)
                    Text(
                      '${_t(l10n, 'selectedLabel', 'Seleccionados')}: $selectedCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _t(l10n, 'noAlumnosToShow', 'No hay alumnos para mostrar.'),
                  ),
                )
              : ListView.builder(
                  controller: _alumnosScrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final a = items[i];
                    final selected = _selectedAlumnoKeys.contains(a.key);

                    final subtitleParts = <String>[
                      if (a.actividad.trim().isNotEmpty) a.actividad.trim(),
                      if (a.aula.trim().isNotEmpty) a.aula.trim(),
                      if (a.turno.trim().isNotEmpty) a.turno.trim(),
                      if (a.edad != null)
                        '${a.edad} ${_t(l10n, 'yearsShort', 'años')}',
                    ];

                    return Card(
                      child: CheckboxListTile(
                        value: selected,
                        onChanged: (_guardando || _cargando)
                            ? null
                            : (v) => _toggleAlumno(a.key, v == true),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(a.nombreUI),
                        subtitle: subtitleParts.isEmpty
                            ? null
                            : Text(subtitleParts.join(' • ')),
                        secondary: IconButton(
                          tooltip: _t(l10n, 'notify', 'Notificar'),
                          onPressed: (_guardando || _cargando)
                              ? null
                              : () async {
                                  setState(() {
                                    _selectedAlumnoKeys
                                      ..clear()
                                      ..add(a.key);
                                  });
                                  await _emitirDialog();
                                },
                          icon: const Icon(Icons.notifications_active),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final instName = widget.institucionNombre.trim().isNotEmpty
        ? widget.institucionNombre.trim()
        : l10n.institucionGeneric;

    final title = l10n.vacancyManagementTitle(instName);

    final fatal = (_fatalError ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: _t(l10n, 'tabGroups', 'Grupos')),
            Tab(text: _t(l10n, 'tabStudents', 'Alumnos')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_cargando || _guardando)
                ? null
                : () => unawaited(_cargarSafe()),
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: (_cargando || _guardando)
                ? null
                : () => unawaited(_recalcularOcupadosDesdeSolicitudes()),
            tooltip: l10n.recalculateOccupiedTooltip,
          ),
          const SizedBox(width: 6),
          if (_tabIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: _t(l10n, 'emitOrNotify', 'Notificar / Emitir'),
              onPressed: (_cargando || _guardando)
                  ? null
                  : () => unawaited(_emitirDialog()),
            ),
            if (_selectedAlumnoKeys.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: _t(l10n, 'clearSelection', 'Limpiar selección'),
                onPressed: (_cargando || _guardando) ? null : _clearSelection,
              ),
          ],
        ],
      ),
      floatingActionButton: (_tabIndex == 0)
          ? FloatingActionButton.extended(
              onPressed: (_cargando || _guardando)
                  ? null
                  : () => unawaited(_crearOEditar()),
              icon: const Icon(Icons.add),
              label: Text(_guardando ? l10n.saving : l10n.newLabel),
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : (fatal.isNotEmpty)
          ? _fatalView(context, fatal)
          : TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildTabGrupos(l10n), _buildTabAlumnos(l10n)],
            ),
    );
  }
}

enum _EmisionAlcance { seleccionados, aula, institucion }

enum _EmisionTipo { notificar, emitir }

class _GrupoCursoUI {
  final String nivel;
  final String gradoSalaAnio;
  final String turno;
  final String horarioInicio;
  final String horarioFin;

  const _GrupoCursoUI({
    this.nivel = '',
    this.gradoSalaAnio = '',
    this.turno = '',
    this.horarioInicio = '',
    this.horarioFin = '',
  });
}

class _AlumnoOperativo {
  final String key;
  final String perfilId;
  final String ownerAccountId;
  final String nombreUI;
  final String actividad;
  final String aula;
  final String turno;
  final int? edad;

  const _AlumnoOperativo({
    required this.key,
    required this.perfilId,
    required this.ownerAccountId,
    required this.nombreUI,
    required this.actividad,
    required this.aula,
    required this.turno,
    required this.edad,
  });

  String get nombreComparable => nombreUI.trim().toLowerCase();

  String get searchBlob {
    final parts = <String>[
      nombreUI,
      perfilId,
      ownerAccountId,
      actividad,
      aula,
      turno,
      if (edad != null) edad.toString(),
    ];
    return parts.join(' ').toLowerCase();
  }

  static int? _calcEdadFromIso(String? iso) {
    final s = (iso ?? '').trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;

    final now = DateTime.now();
    var age = now.year - dt.year;
    final hadBirthdayThisYear =
        (now.month > dt.month) || (now.month == dt.month && now.day >= dt.day);
    if (!hadBirthdayThisYear) age--;
    if (age < 0 || age > 120) return null;
    return age;
  }

  static String _safeStr(dynamic v) => (v ?? '').toString().trim();

  static _AlumnoOperativo fromSolicitudBestEffort(SolicitudAlumno s) {
    String alumnoPerfilId = '';
    String ownerId = '';
    String nombre = '';
    String actividad = '';
    String aula = '';
    String turno = '';
    int? edad;

    try {
      // ignore: avoid_dynamic_calls
      final d = s as dynamic;

      alumnoPerfilId = _safeStr(d.perfilId);
      if (alumnoPerfilId.isEmpty) alumnoPerfilId = _safeStr(d.alumnoId);
      if (alumnoPerfilId.isEmpty) alumnoPerfilId = _safeStr(d.alumnoPerfilId);

      ownerId = _safeStr(d.ownerAccountId);
      if (ownerId.isEmpty) ownerId = _safeStr(d.ownerId);
      if (ownerId.isEmpty) ownerId = _safeStr(d.cuentaOwnerId);

      final n1 = _safeStr(d.alumnoNombre);
      final n2 = _safeStr(d.alumnoApellido);
      final n3 = _safeStr(d.alumnoNombreCompleto);
      final n4 = _safeStr(d.nombreAlumno);
      final n5 = _safeStr(d.nombreCompleto);

      if (n3.isNotEmpty) {
        nombre = n3;
      } else if (n5.isNotEmpty) {
        nombre = n5;
      } else if (n1.isNotEmpty || n2.isNotEmpty) {
        nombre = [n1, n2].where((x) => x.isNotEmpty).join(' ');
      } else if (n4.isNotEmpty) {
        nombre = n4;
      } else {
        nombre = alumnoPerfilId.isNotEmpty
            ? 'Alumno $alumnoPerfilId'
            : 'Alumno';
      }

      actividad = _safeStr(d.actividadNombre);
      aula = _safeStr(d.aula);
      turno = _safeStr(d.turno);

      final dob = _safeStr(d.fechaNacimientoIso);
      if (dob.isNotEmpty) {
        edad = _calcEdadFromIso(dob);
      } else {
        final dob2 = _safeStr(d.fechaNacimiento);
        edad = _calcEdadFromIso(dob2);
      }
    } catch (_) {
      actividad = s.actividadNombre.trim();
      aula = s.aula.trim();
      turno = s.turno.trim();
      nombre = 'Alumno';
    }

    final key = alumnoPerfilId.isNotEmpty
        ? alumnoPerfilId
        : (ownerId.isNotEmpty ? 'owner:$ownerId' : 's:${s.hashCode}');

    return _AlumnoOperativo(
      key: key,
      perfilId: alumnoPerfilId,
      ownerAccountId: ownerId,
      nombreUI: nombre,
      actividad: actividad,
      aula: aula,
      turno: turno,
      edad: edad,
    );
  }
}
