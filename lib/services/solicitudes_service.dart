// ─────────────────────────────────────────────
// ATENA – SOLICITUDES SERVICE (CANÓNICO)
// Orquestación Alumno ↔ Institución
// Fuente de verdad: SolicitudAlumno
// Archivo: lib/services/solicitudes_service.dart
//
// CANÓNICO:
// - ownerAccountId + perfilId (fuente de verdad del lado alumno)
// - Institución opera por institucionId = perfilId (perfil institución)
// - Sin legacy (sin wrappers, sin compat a categorías viejas)
//
// ✅ EXTENSIÓN (enero 2026) – Extracurriculares por MÓDULO (HUB Institución):
// - moduleKey (snake_case canónico) validado contra BloqueExtracurricularX.
// - NO normalizamos agresivamente moduleKey (solo trim+lower).
// - Fail-fast: si moduleKey inválida, devolvemos [] en filtros.
// - Compat: si una solicitud vieja no tiene moduleKey persistida, hacemos best-effort
//   por catálogo/grupos SOLO para filtrar (sin “arreglar” keys malas).
//
// ✅ Alineación con SolicitudAlumno (enero 2026):
// - SolicitudAlumno expone `moduleKey` (String no-null, '' para curricular).
// - La dedupKey pública contempla moduleKey para extracurriculares.
//
// ✅ CANÓNICO (enero 2026) – Cupos extracurriculares:
// - Ocupación persistida: total; confirmadas: control de consistencia.
// - Confirmación y cancelación actualizan el total sin sumar dos veces confirmadas.
// - Evitamos incrementos manuales (+1) al confirmar para prevenir doble conteo.
//
// Ajuste (enero 2026):
// - _cargarCatalogoExtraCompleto intenta obtener el catálogo COMPLETO desde:
//   1) prefs (si existe)
//   2) institución hidratada (activas e inactivas si están persistidas)
//   3) helper (activas) como último recurso
//
// ✅ FIX CANÓNICO (enero 2026) – Notificaciones:
// - Fuente de verdad: INBOX OWNER => scope SIEMPRE owner.
// - Duplicado en perfil: solo UX (lo maneja NotificacionesService).
//
// ✅ HARDENING (enero 2026):
// - NO requiere copyWith() en modelos de extracurriculares:
//   * actualiza cupoOcupado/updatedAt via toMap/fromMap (conservador)
// - No depende de CuentaService: best-effort desde NotificacionesService/Registry
//
// ✅ FIX (Feb 2026) – Persistencia canónica:
// - SolicitudAlumno.institucionId se persiste CANONIZADO (trim + sin whitespace)
//   para evitar solicitudes “huérfanas” al consultar por institución.
//
// ✅ FIX (Feb 2026) – CANÓNICO CURRICULAR E2E:
// - grupoCurricularId (ID estable del grupo publicado por Gestión Vacantes)
//   se incluye en dedupKey (prioridad curricular) y se persiste en la solicitud.
//
// ✅ HARDENING (Feb 2026) – CANÓNICO CURRICULAR E2E (ESTE ARCHIVO):
// - Valida grupoCurricularId contra los grupos reales de la institución.
// - Best-effort: si falta grupoCurricularId, intenta inferirlo por aula/turno.
// - Snapshot canónico: si hay grupo, completa aula/turno desde fuente de verdad.
//
// HARDENING (Feb 2026):
// - Fix bug: _cargarCatalogoExtraCompleto usaba doble-normalización en key prefs.
// - Notificaciones: textos quedan sin i18n a propósito (service), pero IDs/datos canónicos.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/extracurriculares/actividad_extracurricular.dart';
import '../models/extracurriculares/bloque_extracurricular.dart';
import '../models/instituciones/grupo_curricular.dart';
import '../models/notificaciones/notificacion_atena.dart';
import '../models/solicitudes/solicitud_alumno.dart';
import '../repositories/solicitudes_repository.dart';
import '../repositories/solicitudes_repository_prefs.dart';
import '../services/notificaciones_service.dart' as noti;

import 'extracurriculares_service.dart';
import 'storage_service.dart';
import 'instituciones_helpers.dart' as ih;

class SolicitudesException implements Exception {
  final String code;
  final String message;
  SolicitudesException(this.code, this.message);

  @override
  String toString() => 'SolicitudesException($code): $message';
}

class SolicitudesService {
  static final SolicitudesRepository _repo = SolicitudesRepositoryPrefs();

  // =====================================================
  // NORMALIZADORES
  // =====================================================

  static String _n(String? v) => (v ?? '').trim();
  static String _l(String? v) => (v ?? '').trim().toLowerCase();

  /// IDs para keys de prefs / repos (evita duplicados por whitespace invisible).
  /// CANÓNICO: trim + elimina whitespace interno.
  static String _kid(String? v) => _n(v).replaceAll(RegExp(r'\s+'), '');

  static bool _eqName(String a, String b) => _l(a) == _l(b);

  /// Helper para “usar” parámetros opcionales y evitar warnings de unused-parameter.
  static void _touch(Object? _) {}

  /// moduleKey canónica mínima:
  /// - trim
  /// - lower
  /// No transliteramos, no camelCase->snake_case.
  static String _normalizeModuleKeyCanonical(String raw) =>
      raw.trim().toLowerCase();

  static bool _isSnakeCaseStable(String key) {
    final k = _normalizeModuleKeyCanonical(key);
    if (k.isEmpty) return false;
    return RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$').hasMatch(k);
  }

  static bool _isValidModuleKey(String key) {
    final k = _normalizeModuleKeyCanonical(key);
    if (k.isEmpty) return false;

    // ✅ Regla canónica (alineado a UI):
    // snake_case estable + pertenece al set.
    if (!_isSnakeCaseStable(k)) return false;
    return BloqueExtracurricularX.isValidKey(k);
  }

  static String _moduleLabelFromKey(String key) {
    final k = _normalizeModuleKeyCanonical(key);
    final b = BloqueExtracurricularX.fromKey(k);
    return b?.label ?? BloqueExtracurricular.otros.label;
  }

  // =====================================================
  // ✅ COERCIÓN CANÓNICA – GRUPOS CURRICULARES (E2E)
  // =====================================================

  // =====================================================
  // ✅ CURRICULAR – RESOLUCIÓN/VALIDACIÓN DE grupoCurricularId (E2E)
  // =====================================================

  static GrupoCurricular? _findGrupoById(
    List<GrupoCurricular> grupos,
    String grupoId,
  ) {
    final gid = _kid(grupoId);
    if (gid.isEmpty) return null;
    for (final g in grupos) {
      if (_kid(g.id) == gid) return g;
    }
    return null;
  }

  static TurnoCurricular? _turnoFromSnapshot(String raw) {
    final t = _l(raw);
    if (t.isEmpty) return null;

    // Best-effort multi-idioma (sin i18n en service).
    if (t.contains('mañ') || t.contains('manana') || t.contains('morning')) {
      return TurnoCurricular.manana;
    }
    if (t.contains('tarde') || t.contains('afternoon')) {
      return TurnoCurricular.tarde;
    }
    if (t.contains('noche') || t.contains('night')) {
      return TurnoCurricular.noche;
    }
    return null;
  }

  static ({String hi, String hf}) _parseHorarioFromSnapshot(String raw) {
    // Esperado: "<Turno> • <HH:MM>-<HH:MM>" o "<Turno>•<HH:MM>-<HH:MM>".
    final txt = raw.trim();
    if (txt.isEmpty) return (hi: '', hf: '');

    final parts = txt.split('•').map((e) => e.trim()).toList();
    final rhs = parts.length >= 2 ? parts.last : txt;

    final dash = rhs.split('-').map((e) => e.trim()).toList();
    if (dash.length != 2) return (hi: '', hf: '');

    final hi = dash[0];
    final hf = dash[1];

    final re = RegExp(r'^\d{1,2}:\d{2}$');
    if (!re.hasMatch(hi) || !re.hasMatch(hf)) return (hi: '', hf: '');
    return (hi: hi, hf: hf);
  }

  static String _buildTurnoSnapshotFromGrupo(GrupoCurricular g) {
    // Sin i18n (service). Mantiene formato estable tipo:
    // "mañana • 08:00-12:00" (best-effort)
    final turnoBase = () {
      switch (g.turno) {
        case TurnoCurricular.manana:
          return 'mañana';
        case TurnoCurricular.tarde:
          return 'tarde';
        case TurnoCurricular.noche:
          return 'noche';
      }
    }();

    final hi = _n(g.horaInicio);
    final hf = _n(g.horaFin);
    if (hi.isEmpty && hf.isEmpty) return turnoBase;

    final rango =
        '${hi.isNotEmpty ? hi : '--:--'}-${hf.isNotEmpty ? hf : '--:--'}';
    return '$turnoBase • $rango';
  }

  /// Best-effort: si falta grupoCurricularId, intenta inferirlo por snapshot aula/turno.
  static String _inferGrupoIdFromSnapshot({
    required List<GrupoCurricular> grupos,
    required String aulaSnapshot,
    required String turnoSnapshot,
  }) {
    final aula = _n(aulaSnapshot);
    final turnoRaw = _n(turnoSnapshot);

    if (aula.isEmpty) return '';

    final turnoParsed = _turnoFromSnapshot(turnoRaw);
    final hor = _parseHorarioFromSnapshot(turnoRaw);
    final hasHorario = hor.hi.isNotEmpty && hor.hf.isNotEmpty;

    final matches = <GrupoCurricular>[];

    for (final g in grupos) {
      final nombre = _n(g.nombreCurso);

      if (turnoRaw.isEmpty) {
        if (_eqName(nombre, aula)) matches.add(g);
        continue;
      }

      if (!_eqName(nombre, aula)) continue;

      // si no pudimos parsear turno, no forzamos por turno.
      if (turnoParsed != null && g.turno != turnoParsed) continue;

      if (hasHorario) {
        final ghi = _n(g.horaInicio);
        final ghf = _n(g.horaFin);

        // Match de horario solo si el grupo tiene horario persistido.
        if (ghi.isNotEmpty && ghf.isNotEmpty) {
          if (ghi != hor.hi || ghf != hor.hf) continue;
        }
      }

      matches.add(g);
    }

    if (matches.length == 1) return _n(matches.first.id);
    return '';
  }

  // =====================================================
  // ✅ DEEPLINKS (backend-ready / router-friendly)
  // =====================================================

  /// Deeplink para la institución: abre "Mis Solicitudes" (opcionalmente filtrado).
  /// ✅ Fix: NO pre-encodear valores; Uri(...) ya encodea queryParameters.
  static String _buildDeeplinkSolicitudesInstitucion({
    required String institucionId,
    String? moduleKey,
    String? solicitudId,
  }) {
    final inst = _n(institucionId);
    final mk = _normalizeModuleKeyCanonical(moduleKey ?? '');
    final sid = _n(solicitudId);

    final params = <String, String>{
      'institucionId': inst,
      if (mk.isNotEmpty && _isValidModuleKey(mk)) 'moduleKey': mk,
      if (sid.isNotEmpty) 'solicitudId': sid,
    };

    final uri = Uri(path: '/institucion/solicitudes', queryParameters: params);
    return uri.toString();
  }

  /// Deeplink para alumno: abre pantalla de solicitudes/documentos.
  /// ✅ Fix: NO pre-encodear valores; Uri(...) ya encodea queryParameters.
  static String _buildDeeplinkSolicitudAlumno({
    required String ownerAccountId,
    required String perfilId,
    String? solicitudId,
    String? moduleKey,
  }) {
    final o = _n(ownerAccountId);
    final p = _n(perfilId);
    final sid = _n(solicitudId);
    final mk = _normalizeModuleKeyCanonical(moduleKey ?? '');

    final params = <String, String>{
      'ownerAccountId': o,
      'perfilId': p,
      if (sid.isNotEmpty) 'solicitudId': sid,
      if (mk.isNotEmpty && _isValidModuleKey(mk)) 'moduleKey': mk,
    };

    final uri = Uri(path: '/alumno/solicitudes', queryParameters: params);
    return uri.toString();
  }

  /// Best-effort: fuerza rebuild de índices (migraciones/emancipación).
  static Future<void> _rebuildIfPossible() async {
    try {
      await _repo.rebuildIndexes();
    } catch (_) {
      // NO-OP seguro
    }
  }

  // =====================================================
  // ✅ PROTOTIPO – EXTRACURRICULARES (CATÁLOGO PREFS)
  // (Mantenemos key compat: extra_acts_inst_<institucionId>)
  // =====================================================

  static String _kActsByInst(String institucionId) =>
      'extra_acts_inst_${_kid(institucionId)}';

  static Future<List<ActividadExtracurricular>> _cargarCatalogoExtraCompleto(
    String institucionId,
  ) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return const <ActividadExtracurricular>[];

    // 1) Prefs directas
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ FIX: no pasar un id ya-normalizado al generador de key para evitar
      // re-normalizaciones confusas en builds viejos. Se usa el input original.
      final raw = prefs.getString(_kActsByInst(institucionId));

      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map(
                (m) => ActividadExtracurricular.fromMap(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList();

          list.sort(
            (a, b) => a.nombre.trim().toLowerCase().compareTo(
              b.nombre.trim().toLowerCase(),
            ),
          );
          return list;
        }
      }
    } catch (_) {
      // seguimos
    }

    // 2) Institución hidratada
    try {
      final inst = await ih.cargarInstitucionPorId(id);
      if (inst != null) {
        final hydrated = await ih.hidratarInstitucionConExtracurriculares(
          inst,
          migrateIfLegacy: false,
        );
        final list = List<ActividadExtracurricular>.from(
          hydrated.actividadesExtracurriculares,
        );

        if (list.isNotEmpty) {
          list.sort(
            (a, b) => a.nombre.trim().toLowerCase().compareTo(
              b.nombre.trim().toLowerCase(),
            ),
          );
          return list;
        }
      }
    } catch (_) {
      // seguimos
    }

    // 3) Helper (puede ser solo activas)
    try {
      final fromHelpers = await ih
          .cargarActividadesExtracurricularesPorInstitucion(id);
      if (fromHelpers.isNotEmpty) {
        final list = List<ActividadExtracurricular>.from(fromHelpers);
        list.sort(
          (a, b) => a.nombre.trim().toLowerCase().compareTo(
            b.nombre.trim().toLowerCase(),
          ),
        );
        return list;
      }
    } catch (_) {}

    return const <ActividadExtracurricular>[];
  }

  // =====================================================
  // ✅ EXTRACURRICULARES – RESOLUCIÓN DE moduleKey (BEST-EFFORT)
  // =====================================================

  static Future<String?> _tryResolveModuleKeyFromGrupos(
    SolicitudAlumno s,
  ) async {
    if (s.esCurricular) return null;

    final instId = _kid(s.institucionId);
    final actName = _n(s.actividadNombre);
    if (instId.isEmpty || actName.isEmpty) return null;

    try {
      final grupos = await ExtracurricularesService.instance.cargarGrupos(
        instId,
      );
      if (grupos.isEmpty) return null;

      for (final g in grupos) {
        if (_eqName(_n(g.actividadNombre), actName)) {
          final mk = _normalizeModuleKeyCanonical(g.bloque.key);
          return _isValidModuleKey(mk) ? mk : BloqueExtracurricular.otros.key;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _resolveModuleKeyFromCatalogo(SolicitudAlumno s) async {
    if (s.esCurricular) return '';

    final instId = _kid(s.institucionId);
    final actName = _n(s.actividadNombre);
    if (instId.isEmpty || actName.isEmpty) {
      return BloqueExtracurricular.otros.key;
    }

    try {
      final catalogo = await _cargarCatalogoExtraCompleto(instId);
      if (catalogo.isEmpty) return BloqueExtracurricular.otros.key;

      final idx = catalogo.indexWhere((a) => _eqName(a.nombre, actName));
      if (idx < 0) return BloqueExtracurricular.otros.key;

      final act = catalogo[idx];
      final mk = _normalizeModuleKeyCanonical(act.bloque.key);
      return _isValidModuleKey(mk) ? mk : BloqueExtracurricular.otros.key;
    } catch (_) {
      return BloqueExtracurricular.otros.key;
    }
  }

  static Future<String> _resolveModuleKeyForSolicitud(SolicitudAlumno s) async {
    if (s.esCurricular) return '';

    final mkStored = _normalizeModuleKeyCanonical(s.moduleKey);
    if (_isValidModuleKey(mkStored)) return mkStored;

    final fromGrupos = await _tryResolveModuleKeyFromGrupos(s);
    if (fromGrupos != null && fromGrupos.trim().isNotEmpty) {
      final mk = _normalizeModuleKeyCanonical(fromGrupos);
      return _isValidModuleKey(mk) ? mk : BloqueExtracurricular.otros.key;
    }

    final mk2 = await _resolveModuleKeyFromCatalogo(s);
    final mk = _normalizeModuleKeyCanonical(mk2);
    return _isValidModuleKey(mk) ? mk : BloqueExtracurricular.otros.key;
  }

  static Future<Map<String, String>> _buildActividadToModuleKeyMap(
    String institucionId,
  ) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return <String, String>{};

    // 1) Preferimos grupos
    try {
      final grupos = await ExtracurricularesService.instance.cargarGrupos(id);
      if (grupos.isNotEmpty) {
        final map = <String, String>{};
        for (final g in grupos) {
          final nameKey = _l(g.actividadNombre);
          if (nameKey.isEmpty) continue;

          final mk = _normalizeModuleKeyCanonical(g.bloque.key);
          map[nameKey] = _isValidModuleKey(mk)
              ? mk
              : BloqueExtracurricular.otros.key;
        }
        return map;
      }
    } catch (_) {
      // seguimos
    }

    // 2) Fallback catálogo
    try {
      final catalogo = await _cargarCatalogoExtraCompleto(id);
      if (catalogo.isEmpty) return <String, String>{};

      final map = <String, String>{};
      for (final a in catalogo) {
        final nameKey = _l(a.nombre);
        if (nameKey.isEmpty) continue;

        final mk = _normalizeModuleKeyCanonical(a.bloque.key);
        map[nameKey] = _isValidModuleKey(mk)
            ? mk
            : BloqueExtracurricular.otros.key;
      }
      return map;
    } catch (_) {
      return <String, String>{};
    }
  }

  static String _resolveModuleKeyFromMap({
    required SolicitudAlumno s,
    required Map<String, String> actividadToModuleKey,
  }) {
    if (s.esCurricular) return '';

    // 1) respetar moduleKey persistida válida
    final mkStored = _normalizeModuleKeyCanonical(s.moduleKey);
    if (_isValidModuleKey(mkStored)) return mkStored;

    // 2) fallback por actividad
    final k = _l(s.actividadNombre);
    if (k.isEmpty) return BloqueExtracurricular.otros.key;

    final mk = _normalizeModuleKeyCanonical(
      actividadToModuleKey[k] ?? BloqueExtracurricular.otros.key,
    );
    return _isValidModuleKey(mk) ? mk : BloqueExtracurricular.otros.key;
  }

  // =====================================================
  // ✅ EXTRACURRICULARES – CUPOS DERIVADOS DESDE SOLICITUDES (CANÓNICO)
  // =====================================================

  static String _kMatchGrupo({
    required String actividadNombre,
    required String nombreGrupo, // aula/grupo en SolicitudAlumno
    required String turno,
    required String moduleKey,
  }) {
    return [
      _l(actividadNombre),
      _l(nombreGrupo),
      _l(turno),
      _normalizeModuleKeyCanonical(moduleKey),
    ].join('|');
  }

  // =====================================================
  // 🔔 NOTIFICACIÓN A INSTITUCIÓN (CANÓNICO)
  // =====================================================

  static String _notiNewId({String? prefix}) {
    try {
      final svc = noti.NotificacionesService.instance as dynamic;
      final p = (prefix ?? '').trim();
      if (p.isNotEmpty) {
        return (svc.newId(prefix: p) as String?) ??
            'N${DateTime.now().millisecondsSinceEpoch}';
      }
      return (svc.newId() as String?) ??
          'N${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      final p = (prefix ?? '').trim();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return p.isEmpty ? 'N$ts' : '${p}_$ts';
    }
  }

  static Future<String?> _resolveOwnerForInstitucionPerfilBestEffort(
    String institucionPerfilId,
  ) async {
    final pid = _kid(institucionPerfilId);
    if (pid.isEmpty) return null;

    try {
      final svc = noti.NotificacionesService.instance as dynamic;
      final v = await svc.resolveOwnerForPerfil(pid);
      final vv = _kid(v as String?);
      if (vv.isNotEmpty) return vv;
    } catch (_) {}

    try {
      final svc = noti.NotificacionesService.instance as dynamic;
      final v = await svc.resolveOwnerForPerfilFallbackPrefs(pid);
      final vv = _kid(v as String?);
      if (vv.isNotEmpty) return vv;
    } catch (_) {}

    return null;
  }

  static Future<void> _notificarInstitucionNuevaSolicitud({
    required SolicitudAlumno s,
    bool duplicarNotiEnPerfil = true,
    String? moduleKeyOverride,
  }) async {
    final instPerfilId = _kid(s.institucionId);
    if (instPerfilId.isEmpty) return;

    final ownerResolved = await _resolveOwnerForInstitucionPerfilBestEffort(
      instPerfilId,
    );
    final owner = _kid(ownerResolved);
    if (owner.isEmpty) return;

    final instNombre = s.institucionNombre.trim().isNotEmpty
        ? s.institucionNombre.trim()
        : 'Institución';

    final tipo = s.esCurricular ? 'Curricular' : 'Extracurricular';

    String? moduleKey;
    if (!s.esCurricular) {
      final mkResolved = _normalizeModuleKeyCanonical(
        moduleKeyOverride ?? await _resolveModuleKeyForSolicitud(s),
      );
      moduleKey = _isValidModuleKey(mkResolved)
          ? mkResolved
          : BloqueExtracurricular.otros.key;
    }

    final parts = <String>[
      'Nueva solicitud recibida.',
      'Institución: $instNombre',
      'Actividad: ${s.actividadNombre}',
      'Tipo: $tipo',
      if (!s.esCurricular && moduleKey != null)
        'Módulo: ${_moduleLabelFromKey(moduleKey)}',
      if ((_n(s.grupoCurricularIdCanonico)).isNotEmpty)
        'GrupoId: ${s.grupoCurricularIdCanonico}',
      if ((_n(s.aula)).isNotEmpty) 'Aula/Grupo: ${s.aula}',
      if ((_n(s.turno)).isNotEmpty) 'Turno: ${s.turno}',
    ];

    final deeplink = _buildDeeplinkSolicitudesInstitucion(
      institucionId: instPerfilId,
      moduleKey: moduleKey,
      solicitudId: s.id,
    );

    final data = <String, dynamic>{
      'solicitudId': s.id,
      'institucionId': instPerfilId,
      'actividadNombre': s.actividadNombre,
      'esCurricular': s.esCurricular,
      'alumnoPerfilId': s.perfilId,
      'alumnoOwnerAccountId': s.ownerAccountId,
      'deeplink': deeplink,
      if ((_n(s.grupoCurricularIdCanonico)).isNotEmpty)
        'grupoCurricularId': s.grupoCurricularIdCanonico,
      if ((_n(s.aula)).isNotEmpty) 'aula': s.aula,
      if ((_n(s.turno)).isNotEmpty) 'turno': s.turno,
      if (!s.esCurricular && moduleKey != null) 'moduleKey': moduleKey,
    };

    final n = NotificacionAtena(
      id: _notiNewId(prefix: 'N'),
      ownerAccountId: owner,
      perfilId: instPerfilId,
      tipo: TipoNotificacionAtena.solicitudCreada,
      scope: NotificacionScopeAtena.owner,
      titulo: 'Nueva solicitud',
      mensaje: parts.join('\n'),
      fecha: DateTime.now(),
      leida: false,
      data: data,
    );

    await noti.NotificacionesService.instance.pushToOwner(
      ownerAccountId: owner,
      notificacion: n,
      duplicarEnPerfil: duplicarNotiEnPerfil,
    );
  }

  // =====================================================
  // 🟦 LECTURA – ALUMNO
  // =====================================================

  static Future<List<SolicitudAlumno>> cargarSolicitudesPorPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _kid(ownerAccountId);
    final p = _kid(perfilId);
    if (o.isEmpty || p.isEmpty) return <SolicitudAlumno>[];

    final list = await _repo.getSolicitudesPerfil(p);

    return list
        .where((s) => _kid(s.ownerAccountId) == o && _kid(s.perfilId) == p)
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  static Future<List<SolicitudAlumno>> cargarSolicitudesPorOwner({
    required String ownerAccountId,
  }) async {
    final o = _kid(ownerAccountId);
    if (o.isEmpty) return <SolicitudAlumno>[];

    final list = await _repo.getSolicitudesOwner(o);
    return list..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  // =====================================================
  // 🟦 WRITE – ALUMNO
  // =====================================================

  static Future<void> crearSolicitudDesdePerfil({
    required String ownerAccountId,
    required String perfilId,
    required SolicitudAlumno solicitudAlumno,
    bool duplicarNotiEnPerfil = true,
  }) async {
    final o = _kid(ownerAccountId);
    final p = _kid(perfilId);

    if (o.isEmpty || p.isEmpty) {
      throw SolicitudesException('invalid_context', 'Owner o perfil inválido');
    }

    // ✅ CANÓNICO: persistimos institucionId ya canonizado para evitar huérfanas.
    final instId = _kid(solicitudAlumno.institucionId);
    final instNombre = _n(solicitudAlumno.institucionNombre);
    final actNombre = _n(solicitudAlumno.actividadNombre);
    final alumnoDoc = _n(solicitudAlumno.alumnoDocumento);

    if (instId.isEmpty || actNombre.isEmpty) {
      throw SolicitudesException(
        'invalid_payload',
        'Institución o actividad inválida para crear solicitud.',
      );
    }

    // =====================================================
    // ✅ CANÓNICO CURRICULAR E2E:
    // - Valida grupoCurricularId contra fuente de verdad (Gestión Vacantes).
    // - Best-effort: si falta grupoId, intenta inferirlo por aula/turno.
    // - Snapshot canónico: si hay grupo, completa aula/turno desde grupo.
    // - ✅ End-to-end: si curricular y no hay grupoCurricularId resoluble => FAIL (no legacy).
    // =====================================================
    String grupoCurricularId = '';
    String aulaSnapshot = _n(solicitudAlumno.aula);
    String turnoSnapshot = _n(solicitudAlumno.turno);

    if (solicitudAlumno.esCurricular) {
      final grupos = await obtenerGruposCurricularesInstitucion(instId);

      if (grupos.isEmpty) {
        throw SolicitudesException(
          'invalid_state',
          'La institución no tiene grupos curriculares publicados.',
        );
      }

      final gidIn = _n(solicitudAlumno.grupoCurricularIdCanonico);

      if (gidIn.isNotEmpty) {
        final g = _findGrupoById(grupos, gidIn);
        if (g == null) {
          throw SolicitudesException(
            'invalid_payload',
            'Grupo curricular inválido (no existe en Gestión Vacantes).',
          );
        }
        grupoCurricularId = _n(g.id);

        // Snapshot canónico desde fuente de verdad (solo si falta).
        if (aulaSnapshot.isEmpty) aulaSnapshot = _n(g.nombreCurso);
        if (turnoSnapshot.isEmpty) {
          turnoSnapshot = _buildTurnoSnapshotFromGrupo(g);
        }
      } else {
        // Best-effort: inferir por aula/turno (compat)
        final inferred = _inferGrupoIdFromSnapshot(
          grupos: grupos,
          aulaSnapshot: aulaSnapshot,
          turnoSnapshot: turnoSnapshot,
        );
        if (inferred.isNotEmpty) {
          grupoCurricularId = inferred;
          final g = _findGrupoById(grupos, inferred);
          if (g != null) {
            if (aulaSnapshot.isEmpty) aulaSnapshot = _n(g.nombreCurso);
            if (turnoSnapshot.isEmpty) {
              turnoSnapshot = _buildTurnoSnapshotFromGrupo(g);
            }
          }
        }
      }

      // ✅ CANÓNICO: curricular requiere grupoCurricularId sí o sí.
      if (grupoCurricularId.isEmpty) {
        throw SolicitudesException(
          'invalid_payload',
          'Falta grupoCurricularId (no se pudo resolver).',
        );
      }

      // Snapshot mínimo (si por algún motivo quedó vacío)
      if (aulaSnapshot.isEmpty) aulaSnapshot = _n(solicitudAlumno.aula);
      if (turnoSnapshot.isEmpty) turnoSnapshot = _n(solicitudAlumno.turno);
    }

    // ✅ moduleKey: fuente de verdad = payload (si válida) o resolve best-effort.
    String moduleKey = '';
    if (!solicitudAlumno.esCurricular) {
      final mkIn = _normalizeModuleKeyCanonical(solicitudAlumno.moduleKey);
      if (_isValidModuleKey(mkIn)) {
        moduleKey = mkIn;
      } else {
        final mkResolved = _normalizeModuleKeyCanonical(
          await _resolveModuleKeyForSolicitud(solicitudAlumno),
        );
        moduleKey = _isValidModuleKey(mkResolved)
            ? mkResolved
            : BloqueExtracurricular.otros.key;
      }
    }

    // ✅ DEDUP KEY (E2E):
    // - Curricular: prioriza grupoCurricularId si existe
    // - Extracurricular: incluye moduleKey
    final dedup = SolicitudAlumno.buildDedupKeyPublic(
      ownerAccountId: o,
      perfilId: p,
      alumnoDocumento: alumnoDoc,
      institucionId: instId,
      actividadNombre: actNombre,
      esCurricular: solicitudAlumno.esCurricular,
      grupoCurricularId: grupoCurricularId,
      aula: aulaSnapshot,
      turno: turnoSnapshot,
      moduleKey: moduleKey,
    );

    try {
      final existentes = await _repo.getSolicitudesPerfil(p);
      final yaExiste = existentes.any(
        (x) =>
            _kid(x.ownerAccountId) == o &&
            _kid(x.perfilId) == p &&
            _n(x.dedupKey) == dedup &&
            x.estado == EstadoSolicitud.pendiente,
      );
      if (yaExiste) {
        throw SolicitudesException(
          'duplicate',
          'Ya existe una solicitud pendiente igual para esta institución/actividad.',
        );
      }
    } catch (e) {
      if (e is SolicitudesException) rethrow;
    }

    // ✅ FIX CRÍTICO:
    // SolicitudAlumno.copyWith NO permite cambiar el id.
    final idIn = _n(solicitudAlumno.id);
    final safeId = idIn.isNotEmpty ? idIn : SolicitudAlumno.newSolicitudId();

    final estadoInicial = EstadoSolicitud.pendiente;

    final fc = solicitudAlumno.fechaCreacion;
    final fechaCreacionSafe = (fc.millisecondsSinceEpoch <= 0)
        ? DateTime.now()
        : fc;

    // ✅ Persistimos grupoCurricularId en el registro guardado (curricular).
    // ✅ Persistimos aula/turno snapshot (curricular y extra).
    final base = SolicitudAlumno(
      id: safeId,
      ownerAccountId: o,
      perfilId: p,
      alumnoDocumento: alumnoDoc,
      institucionId: instId,
      institucionNombre: instNombre,
      actividadNombre: actNombre,
      grupoCurricularId: solicitudAlumno.esCurricular ? grupoCurricularId : '',
      aula: aulaSnapshot,
      turno: turnoSnapshot,
      moduleKey: moduleKey,
      esCurricular: solicitudAlumno.esCurricular,
      estado: estadoInicial,
      notaInstitucion: null,
      motivoRechazo: null,
      fechaCreacion: fechaCreacionSafe,
      fechaUltimoCambio: DateTime.now(),
      dedupKey: dedup,
    );

    await _repo.saveSolicitudAlumno(base);
    await _rebuildIfPossible();

    final deeplinkAlumno = _buildDeeplinkSolicitudAlumno(
      ownerAccountId: o,
      perfilId: p,
      solicitudId: base.id,
      moduleKey: moduleKey,
    );

    final nAlumnoData = <String, dynamic>{
      'solicitudId': base.id,
      'institucionId': base.institucionId,
      'deeplink': deeplinkAlumno,
      if ((_n(base.grupoCurricularIdCanonico)).isNotEmpty)
        'grupoCurricularId': base.grupoCurricularIdCanonico,
      if ((_n(base.aula)).isNotEmpty) 'aula': base.aula,
      if ((_n(base.turno)).isNotEmpty) 'turno': base.turno,
      if (!base.esCurricular && moduleKey.isNotEmpty) 'moduleKey': moduleKey,
    };

    final nAlumno = NotificacionAtena(
      id: _notiNewId(),
      ownerAccountId: o,
      perfilId: p,
      tipo: TipoNotificacionAtena.solicitudCreada,
      scope: NotificacionScopeAtena.owner,
      titulo: 'Solicitud enviada',
      mensaje: 'Solicitud enviada a ${base.institucionNombre}',
      fecha: DateTime.now(),
      leida: false,
      data: nAlumnoData,
    );

    await noti.NotificacionesService.instance.pushToOwner(
      ownerAccountId: o,
      notificacion: nAlumno,
      duplicarEnPerfil: duplicarNotiEnPerfil,
    );

    try {
      await _notificarInstitucionNuevaSolicitud(
        s: base,
        duplicarNotiEnPerfil: true,
        moduleKeyOverride: (!base.esCurricular && moduleKey.isNotEmpty)
            ? moduleKey
            : null,
      );
    } catch (_) {}
  }

  static Future<void> cancelarSolicitudDesdePerfil({
    required String ownerAccountId,
    required String perfilId,
    required String solicitudId,
    required String institucionId,
    required String institucionNombre,
    required String actividadNombre,
    String? aula,
    String? turno,
    bool duplicarNotiEnPerfil = true,
  }) async {
    // Compat: estos params pueden venir de llamadas viejas
    _touch(institucionId);
    _touch(institucionNombre);
    _touch(actividadNombre);
    _touch(aula);
    _touch(turno);

    final s = await _repo.getSolicitudAlumnoById(solicitudId);
    if (s == null) return;

    final o = _kid(ownerAccountId);
    final p = _kid(perfilId);

    if ((_kid(s.ownerAccountId) != o) || (_kid(s.perfilId) != p)) {
      throw SolicitudesException(
        'forbidden',
        'No podés cancelar una solicitud ajena.',
      );
    }

    final cancelada = s.copyWith(
      estado: EstadoSolicitud.canceladaPorAlumno,
      fechaUltimoCambio: DateTime.now(),
    );

    if (s.estado == EstadoSolicitud.canceladaPorAlumno) return;
    final writes = s.estado == EstadoSolicitud.confirmada
        ? await _prepararCupos(s, -1)
        : <String, String>{};
    await _guardarCambioConCupos(s, cancelada, writes);

    String? moduleKey;
    if (!cancelada.esCurricular) {
      final mkResolved = _normalizeModuleKeyCanonical(
        await _resolveModuleKeyForSolicitud(cancelada),
      );
      moduleKey = _isValidModuleKey(mkResolved)
          ? mkResolved
          : BloqueExtracurricular.otros.key;
    }

    final data = <String, dynamic>{
      'solicitudId': solicitudId,
      'institucionId': cancelada.institucionId,
      if ((_n(cancelada.grupoCurricularIdCanonico)).isNotEmpty)
        'grupoCurricularId': cancelada.grupoCurricularIdCanonico,
      if ((_n(cancelada.aula)).isNotEmpty) 'aula': cancelada.aula,
      if ((_n(cancelada.turno)).isNotEmpty) 'turno': cancelada.turno,
      if (!cancelada.esCurricular && moduleKey != null) 'moduleKey': moduleKey,
    };

    final n = NotificacionAtena(
      id: _notiNewId(),
      ownerAccountId: o,
      perfilId: p,
      tipo: TipoNotificacionAtena.solicitudCancelada,
      scope: NotificacionScopeAtena.owner,
      titulo: 'Solicitud cancelada',
      mensaje: 'Cancelaste la solicitud a ${cancelada.institucionNombre}',
      fecha: DateTime.now(),
      leida: false,
      data: data,
    );

    await noti.NotificacionesService.instance.pushToOwner(
      ownerAccountId: o,
      notificacion: n,
      duplicarEnPerfil: duplicarNotiEnPerfil,
    );
  }

  static Future<void> borrarSolicitudPorId({
    required String solicitudId,
  }) async {
    final id = _n(solicitudId);
    if (id.isEmpty) return;
    await _repo.deleteSolicitudAlumnoById(id);
    await _rebuildIfPossible();
  }

  // =====================================================
  // 🟦 INSTITUCIÓN
  // =====================================================

  static Future<List<SolicitudAlumno>> obtenerSolicitudesParaInstitucion({
    required String institucionId,
  }) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return <SolicitudAlumno>[];

    final list = await _repo.getSolicitudesInstitucion(id);
    return list..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  static Future<List<SolicitudAlumno>> obtenerPendientesParaInstitucion({
    required String institucionId,
  }) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return <SolicitudAlumno>[];

    final list = await _repo.getSolicitudesInstitucionPendientes(id);
    return list..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  static Future<List<SolicitudAlumno>>
  obtenerSolicitudesParaInstitucionPorModuloKey({
    required String institucionId,
    required String moduleKey,
  }) async {
    final id = _kid(institucionId);
    final mk = _normalizeModuleKeyCanonical(moduleKey);

    if (id.isEmpty || mk.isEmpty) return <SolicitudAlumno>[];
    if (!_isValidModuleKey(mk)) return <SolicitudAlumno>[];

    final base = await obtenerSolicitudesParaInstitucion(institucionId: id);
    if (base.isEmpty) return <SolicitudAlumno>[];

    final map = await _buildActividadToModuleKeyMap(id);

    final out = <SolicitudAlumno>[];
    for (final s in base) {
      if (s.esCurricular) continue;
      final k = _resolveModuleKeyFromMap(s: s, actividadToModuleKey: map);
      if (k == mk) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  static Future<List<SolicitudAlumno>>
  obtenerPendientesParaInstitucionPorModuloKey({
    required String institucionId,
    required String moduleKey,
  }) async {
    final id = _kid(institucionId);
    final mk = _normalizeModuleKeyCanonical(moduleKey);

    if (id.isEmpty || mk.isEmpty) return <SolicitudAlumno>[];
    if (!_isValidModuleKey(mk)) return <SolicitudAlumno>[];

    final base = await obtenerPendientesParaInstitucion(institucionId: id);
    if (base.isEmpty) return <SolicitudAlumno>[];

    final map = await _buildActividadToModuleKeyMap(id);

    final out = <SolicitudAlumno>[];
    for (final s in base) {
      if (s.esCurricular) continue;
      final k = _resolveModuleKeyFromMap(s: s, actividadToModuleKey: map);
      if (k == mk) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  // =====================================================
  // ✅ RESPUESTA INSTITUCIÓN → NOTIFICACIÓN AL ALUMNO (CANÓNICO)
  // + Cupos extracurriculares derivados desde solicitudes (best-effort)
  // =====================================================

  // Persisted occupation is total occupation, not an additive request counter.
  static int _ocupacionTrasCambio(
    int occupied,
    int confirmed,
    int capacity,
    int delta, {
    bool unlimited = false,
  }) {
    if (occupied < 0 || capacity < 0) {
      throw SolicitudesException(
        'invalid_capacity',
        'Capacidad inconsistente.',
      );
    }
    final current = occupied > confirmed ? occupied : confirmed;
    if (delta > 0 && !unlimited && current >= capacity) {
      throw SolicitudesException('no_capacity', 'El grupo ya no tiene cupo.');
    }
    final next = current + delta;
    return next < 0 ? 0 : next;
  }

  static Future<Map<String, String>> _prepararCupos(
    SolicitudAlumno s,
    int delta,
  ) async {
    final inst = _kid(s.institucionId);
    final confirmed = (await obtenerSolicitudesParaInstitucion(
      institucionId: inst,
    )).where((x) => x.estado == EstadoSolicitud.confirmada).toList();
    if (s.esCurricular) {
      // Same P0 #1 resolver as Management; retain its full representation.
      final groups = await ih.cargarGruposInstitucion(inst);
      final matches = groups
          .where((g) => g.id == s.grupoCurricularIdCanonico)
          .toList();
      if (matches.length != 1 || _kid(matches.single.institucionId) != inst) {
        throw SolicitudesException(
          'invalid_group',
          'Grupo curricular inexistente o ajeno.',
        );
      }
      final g = matches.single;
      if (delta > 0 &&
          (g.estado.name != 'disponible' ||
              (_n(s.aula).isNotEmpty &&
                  _n(s.aula) !=
                      (_n(g.aula).isEmpty ? _n(g.nombreGrupo) : _n(g.aula))) ||
              (_n(s.turno).isNotEmpty && _n(s.turno) != _n(g.turno)))) {
        throw SolicitudesException(
          'incompatible_group',
          'La configuración del grupo cambió.',
        );
      }

      final count = confirmed
          .where((x) => x.esCurricular && x.grupoCurricularIdCanonico == g.id)
          .length;
      final next = _ocupacionTrasCambio(
        g.cupoOcupado,
        count,
        g.cupoMaximo,
        delta,
      );
      final data = groups.map((x) {
        final m = x.toMap();
        if (x.id == g.id) {
          m['cupoOcupado'] = next;
          if (x.estado.name != 'suspendido') {
            m['estado'] = next >= x.cupoMaximo ? 'completo' : 'disponible';
          }
        }
        return m;
      }).toList();
      return {ih.kGruposInstitucion(inst): jsonEncode(data)};
    }
    final mk = _normalizeModuleKeyCanonical(s.moduleKey);
    if (!_isValidModuleKey(mk) ||
        _n(s.aula).isEmpty ||
        _n(s.actividadNombre).isEmpty) {
      throw SolicitudesException(
        'ambiguous_group',
        'Falta identificación extracurricular inequívoca.',
      );
    }
    final key = _kMatchGrupo(
      actividadNombre: s.actividadNombre,
      nombreGrupo: s.aula,
      turno: s.turno,
      moduleKey: mk,
    );
    final groups = await ExtracurricularesService.instance.cargarGrupos(inst);
    final matches = groups
        .where(
          (g) =>
              _kMatchGrupo(
                actividadNombre: g.actividadNombre,
                nombreGrupo: g.nombreGrupo,
                turno: g.turno,
                moduleKey: g.bloque.key,
              ) ==
              key,
        )
        .toList();
    if (matches.length != 1 ||
        _kid(matches.single.institucionId) != inst ||
        (delta > 0 && !matches.single.activo)) {
      throw SolicitudesException(
        'invalid_group',
        'Grupo extracurricular inexistente, ambiguo o inactivo.',
      );
    }
    final g = matches.single;
    final count = confirmed
        .where(
          (x) =>
              !x.esCurricular &&
              _kMatchGrupo(
                    actividadNombre: x.actividadNombre,
                    nombreGrupo: x.aula,
                    turno: x.turno,
                    moduleKey: x.moduleKey,
                  ) ==
                  key,
        )
        .length;
    final next = _ocupacionTrasCambio(
      g.cupoOcupado,
      count,
      g.cupoMaximo,
      delta,
      unlimited: g.cupoMaximo == 0,
    );
    final data = groups.map((x) {
      final m = x.toMap();
      if (x.id == g.id) m['cupoOcupado'] = next;
      return m;
    }).toList();
    final writes = {
      ExtracurricularesService.kGruposExtracurriculares(inst): jsonEncode(data),
    };
    // Respect activity-wide capacity as well, if a catalog entry exists.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActsByInst(inst));
    final catalog = raw == null
        ? await _cargarCatalogoExtraCompleto(inst)
        : (jsonDecode(raw) as List)
              .map(
                (m) => ActividadExtracurricular.fromMap(
                  Map<String, dynamic>.from(m as Map),
                ),
              )
              .toList();
    final acts = catalog
        .where(
          (a) => _l(a.nombre) == _l(s.actividadNombre) && a.bloque.key == mk,
        )
        .toList();
    if (acts.length > 1 ||
        (acts.isNotEmpty && delta > 0 && !acts.single.activa)) {
      throw SolicitudesException(
        'invalid_activity',
        'Actividad ambigua o inactiva.',
      );
    }
    if (acts.isNotEmpty) {
      final a = acts.single;
      if (_kid(a.institucionId) != inst) {
        throw SolicitudesException(
          'invalid_activity',
          'Actividad ajena a la institución.',
        );
      }
      final actCount = confirmed
          .where(
            (x) =>
                !x.esCurricular &&
                _l(x.actividadNombre) == _l(a.nombre) &&
                x.moduleKey == mk,
          )
          .length;
      final actNext = _ocupacionTrasCambio(
        a.cupoOcupado,
        actCount,
        a.cupoMaximo,
        delta,
        unlimited: a.cupoMaximo == 0,
      );
      writes[_kActsByInst(inst)] = jsonEncode(
        catalog.map((x) {
          final m = x.toMap();
          if (identical(x, a)) m['cupoOcupado'] = actNext;
          return m;
        }).toList(),
      );
    }
    return writes;
  }

  // Compensate failed writes before notifying. SharedPreferences has no transaction.
  static Future<void> _guardarCambioConCupos(
    SolicitudAlumno before,
    SolicitudAlumno after,
    Map<String, String> writes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final requestKey = 'sol_alumno_${_kid(before.id)}';
    final pendingKey = 'sol_idx_inst_${_kid(before.institucionId)}_pend';
    final keys = {...writes.keys, requestKey, pendingKey};
    final snapshots = {for (final key in keys) key: prefs.get(key)};
    try {
      // Persist capacity first so a failed capacity write never confirms a request.
      for (final entry in writes.entries) {
        if (!await prefs.setString(entry.key, entry.value)) {
          throw StateError('No se pudo guardar la ocupación.');
        }
      }
      await _repo.saveSolicitudAlumno(after);
      await prefs.reload();
      if ((await _repo.getSolicitudAlumnoById(after.id))?.estado !=
              after.estado ||
          writes.entries.any((e) => prefs.getString(e.key) != e.value)) {
        throw StateError('No se pudo verificar el cambio de solicitud y cupo.');
      }
      await _repo.rebuildIndexes();
      final pending = prefs.getStringList(pendingKey) ?? <String>[];
      pending.remove(_kid(after.id));
      if (after.estado == EstadoSolicitud.pendiente) {
        pending.add(_kid(after.id));
      }
      if (!await prefs.setStringList(pendingKey, pending)) {
        throw StateError('No se pudo guardar el índice de pendientes.');
      }
    } catch (error) {
      for (final entry in snapshots.entries) {
        final value = entry.value;
        final bool restored;
        if (value == null) {
          restored = await prefs.remove(entry.key);
        } else if (value is String) {
          restored = await prefs.setString(entry.key, value);
        } else {
          restored = await prefs.setStringList(
            entry.key,
            List<String>.from(value as List),
          );
        }
        if (!restored) {
          throw StateError('Falló la escritura y su recuperación: $error');
        }
      }
      rethrow;
    } finally {
      StorageService.instance.resetCache();
    }
  }

  static Future<void> responderSolicitud({
    required String solicitudId,
    required EstadoSolicitud nuevoEstado,
    String? notaInstitucion,
    String? motivoRechazo,
    bool duplicarNotiEnPerfil = true,
  }) async {
    final s = await _repo.getSolicitudAlumnoById(solicitudId);
    if (s == null) return;

    if (nuevoEstado != EstadoSolicitud.confirmada &&
        nuevoEstado != EstadoSolicitud.rechazada) {
      throw SolicitudesException(
        'invalid_transition',
        'Respuesta no permitida.',
      );
    }
    if (s.estado == nuevoEstado) return;
    if (s.estado != EstadoSolicitud.pendiente) {
      throw SolicitudesException(
        'invalid_transition',
        'La solicitud ya no está pendiente.',
      );
    }
    final writes = nuevoEstado == EstadoSolicitud.confirmada
        ? await _prepararCupos(s, 1)
        : <String, String>{};

    final nota = (notaInstitucion ?? '').trim();
    final mr = (motivoRechazo ?? '').trim();

    var editada = s.copyWith(
      estado: nuevoEstado,
      notaInstitucion: nota.isEmpty ? null : nota,
      fechaUltimoCambio: DateTime.now(),
    );

    if (motivoRechazo != null) {
      editada = editada.copyWith(motivoRechazo: mr.isEmpty ? null : mr);
    }

    await _guardarCambioConCupos(s, editada, writes);

    final owner = _kid(editada.ownerAccountId);
    final perfil = _kid(editada.perfilId);
    if (owner.isEmpty || perfil.isEmpty) return;

    String? moduleKey;
    if (!editada.esCurricular) {
      final mkResolved = _normalizeModuleKeyCanonical(
        await _resolveModuleKeyForSolicitud(editada),
      );
      moduleKey = _isValidModuleKey(mkResolved)
          ? mkResolved
          : BloqueExtracurricular.otros.key;
    }

    TipoNotificacionAtena tipoNoti;
    String titulo;

    final instName = editada.institucionNombre.trim().isNotEmpty
        ? editada.institucionNombre.trim()
        : 'la institución';

    switch (nuevoEstado) {
      case EstadoSolicitud.confirmada:
        tipoNoti = TipoNotificacionAtena.confirmada;
        titulo = 'Solicitud confirmada';
        break;
      case EstadoSolicitud.rechazada:
        tipoNoti = TipoNotificacionAtena.rechazada;
        titulo = 'Solicitud rechazada';
        break;
      default:
        tipoNoti = TipoNotificacionAtena.info;
        titulo = 'Actualización de solicitud';
        break;
    }

    final parts = <String>[];
    if (nuevoEstado == EstadoSolicitud.confirmada) {
      parts.add('Tu solicitud en $instName fue confirmada.');
    } else if (nuevoEstado == EstadoSolicitud.rechazada) {
      parts.add('Tu solicitud en $instName fue rechazada.');
    } else {
      parts.add('Tu solicitud en $instName fue actualizada.');
    }

    if (!editada.esCurricular && moduleKey != null) {
      parts.add('Módulo: ${_moduleLabelFromKey(moduleKey)}');
    }
    if ((_n(editada.grupoCurricularIdCanonico)).isNotEmpty) {
      parts.add('GrupoId: ${editada.grupoCurricularIdCanonico}');
    }
    if ((_n(editada.aula)).isNotEmpty) parts.add('Aula/Grupo: ${editada.aula}');
    if ((_n(editada.turno)).isNotEmpty) parts.add('Turno: ${editada.turno}');
    if (mr.isNotEmpty) parts.add('Motivo: $mr');
    if (nota.isNotEmpty) parts.add('Nota: $nota');

    final deeplinkAlumno = _buildDeeplinkSolicitudAlumno(
      ownerAccountId: owner,
      perfilId: perfil,
      solicitudId: editada.id,
      moduleKey: moduleKey,
    );

    final data = <String, dynamic>{
      'solicitudId': editada.id,
      'institucionId': editada.institucionId,
      'nuevoEstado': nuevoEstado.name,
      'deeplink': deeplinkAlumno,
      if ((_n(editada.grupoCurricularIdCanonico)).isNotEmpty)
        'grupoCurricularId': editada.grupoCurricularIdCanonico,
      if ((_n(editada.aula)).isNotEmpty) 'aula': editada.aula,
      if ((_n(editada.turno)).isNotEmpty) 'turno': editada.turno,
      if (mr.isNotEmpty) 'motivoRechazo': mr,
      if (nota.isNotEmpty) 'notaInstitucion': nota,
      if (!editada.esCurricular && moduleKey != null) 'moduleKey': moduleKey,
    };

    final n = NotificacionAtena(
      id: _notiNewId(),
      ownerAccountId: owner,
      perfilId: perfil,
      tipo: tipoNoti,
      scope: NotificacionScopeAtena.owner,
      titulo: titulo,
      mensaje: parts.join('\n'),
      fecha: DateTime.now(),
      leida: false,
      data: data,
    );

    await noti.NotificacionesService.instance.pushToOwner(
      ownerAccountId: owner,
      notificacion: n,
      duplicarEnPerfil: duplicarNotiEnPerfil,
    );
  }

  static Future<void> editarNotaInstitucion({
    required String solicitudId,
    required String nota,
  }) async {
    final s = await _repo.getSolicitudAlumnoById(solicitudId);
    if (s == null) return;

    final clean = nota.trim();

    await _repo.saveSolicitudAlumno(
      s.copyWith(
        notaInstitucion: clean.isEmpty ? null : clean,
        fechaUltimoCambio: DateTime.now(),
      ),
    );

    await _rebuildIfPossible();
  }

  // =====================================================
  // 🟩 EXTRACURRICULARES (CATÁLOGO – PROTOTIPO)
  // =====================================================

  static Future<List<ActividadExtracurricular>>
  obtenerActividadesExtracurricularesInstitucion({
    required String institucionId,
  }) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return const <ActividadExtracurricular>[];

    try {
      final list = await ih.cargarActividadesExtracurricularesPorInstitucion(
        id,
      );
      if (list.isNotEmpty) return List<ActividadExtracurricular>.from(list);
    } catch (_) {}

    final all = await _cargarCatalogoExtraCompleto(id);
    return List<ActividadExtracurricular>.from(all);
  }

  static Future<List<ActividadExtracurricular>>
  obtenerActividadesExtracurricularesPorBloque({
    required String institucionId,
    required BloqueExtracurricular bloque,
  }) async {
    final all = await obtenerActividadesExtracurricularesInstitucion(
      institucionId: institucionId,
    );
    if (all.isEmpty) return const <ActividadExtracurricular>[];

    return all.where((a) => a.bloque == bloque && a.activa == true).toList();
  }

  // =====================================================
  // 🟦 GRUPOS CURRICULARES (HELPERS)
  // =====================================================

  static Future<List<GrupoCurricular>> obtenerGruposCurricularesInstitucion(
    String institucionId,
  ) async {
    final id = _kid(institucionId);
    if (id.isEmpty) return <GrupoCurricular>[];

    // La misma resolución que usa el alumno y Gestión, incluido vacío explícito.
    // No ocultar corrupción como ausencia de grupos.
    return ih.cargarGruposCurricularesInstitucion(id);
  }

  static Future<List<GrupoCurricular>>
  obtenerGruposCurricularesInstitucionNamed({required String institucionId}) {
    return obtenerGruposCurricularesInstitucion(institucionId);
  }

  // =====================================================
  // ✅ UTILIDAD – Curricular pendiente: hard-delete
  // =====================================================

  static Future<void> eliminarSolicitudCurricularPendiente({
    required String ownerAccountId,
    required String perfilId,
    required String solicitudId,
  }) async {
    final s = await _repo.getSolicitudAlumnoById(solicitudId);
    if (s == null) return;

    final o = _kid(ownerAccountId);
    final p = _kid(perfilId);

    if ((_kid(s.ownerAccountId) != o) || (_kid(s.perfilId) != p)) {
      throw SolicitudesException(
        'forbidden',
        'No podés eliminar una solicitud ajena.',
      );
    }

    if (!(s.esCurricular && s.estado == EstadoSolicitud.pendiente)) {
      throw SolicitudesException(
        'invalid_state',
        'Solo se puede eliminar hard una solicitud curricular pendiente.',
      );
    }

    await _repo.deleteSolicitudAlumnoById(solicitudId);
    await _rebuildIfPossible();
  }

  static Future<void> editarMotivoRechazo({
    required String solicitudId,
    String? motivoRechazo,
  }) async {
    final s = await _repo.getSolicitudAlumnoById(solicitudId);
    if (s == null) return;

    final mr = (motivoRechazo ?? '').trim();

    await _repo.saveSolicitudAlumno(
      s.copyWith(
        motivoRechazo: mr.isEmpty ? null : mr,
        fechaUltimoCambio: DateTime.now(),
      ),
    );

    await _rebuildIfPossible();
  }
}
