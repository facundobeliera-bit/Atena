// lib/services/alumno_service.dart
//
// ATENA – ALUMNO SERVICE (CANÓNICO)
// Fuente de verdad:
// ownerAccountId → perfiles → perfilId
//
// ❌ NO DNI como key de dominio (solo login prototipo)
// ❌ NO flujos paralelos
// ✅ Notificaciones siempre al owner (y opcional duplicado en perfil para UX)
//
// ✅ Calendario unificado (curricular + extracurricular)
// ✅ Agenda personal (personal) SIEMPRE genera Notificación (owner) con deeplinks consistente
// ✅ Deeplink canónico calendario: /calendario?perfilId=...&date=YYYY-MM-DD&itemId=...
// ✅ Normalización de estructura (backend-ready)
//
// Opción A aplicada:
// - Toda notificación relacionada a calendario SIEMPRE incluye perfilId.
// - Para agenda personal: deeplink SIEMPRE incluye date + itemId.
// - Para setCalendarioRaw / setAgendaPersonalRaw (bulk): deeplink incluye perfilId (y date/itemId solo si aplica).
// - Validación estricta owner → perfil (ya existente) antes de operar.
//
// EXTENSIÓN (BACKEND-READY) – Instituciones:
// ✅ Eventos institucionales pueden venir con:
//   - source: "institucion"
//   - lock / locked: true  (no editable / no borrable por alumno)
//   - allowStudentDelete / allowStudentEdit: false
// ✅ RSVP (confirmar / declinar / quizás):
//   - requiresRsvp: true
//   - rsvpPolicy: "optional" | "mandatory_attendance" | "mandatory_ack"
//   - rsvpStatus: "yes" | "no" | "maybe" | "pending"
// ✅ Pre-notificaciones (preventos):
//   - preNotiMinutes: [1440, 120] (minutos antes)
//   - preNotified: [1440] (minutos ya notificados)
//   - preNotiLastRunIso (debug/telemetría)
//
// Nota importante:
// - Este servicio mantiene agenda personal y el resto del dominio del alumno.
// - Para calendario institucional (listar + upsert + delete + RSVP + outbox), delega en
//   AlumnoCalendarioInteraccionesService (backend-ready) como fuente única.
//
// ignore_for_file: unnecessary_type_check

import 'dart:math';

import 'storage_service.dart';

import '../models/alumnos/alumnos_integrados.dart';

import 'cuenta_service.dart';
import 'notificaciones_service.dart';
import '../models/notificaciones/notificacion_atena.dart';

import 'alumno_calendario_interacciones_service.dart';

class AlumnoService {
  AlumnoService._();
  static final AlumnoService instance = AlumnoService._();

  final StorageService _storage = StorageService.instance;

  // =====================================================
  // KEYS (CANÓNICO)
  // =====================================================

  // Login prototipo (compat)
  static const String _kAlumnoUsuarios = 'v2_alumno_usuarios';

  // Perfiles / dominio por perfilId (CANÓNICO)
  static const String _kPerfilAlumnoPrefix = 'v3_perfil_alumno_';
  static const String _kBoletinesPrefix = 'v3_alumno_boletines_';
  static const String _kTitulosPrefix = 'v3_alumno_titulos_';
  static const String _kDocumentosPrefix = 'v3_alumno_documentos_';
  static const String _kPendientesPrefix = 'v3_alumno_pendientes_';
  static const String _kProgresosPrefix = 'v3_alumno_progresos_';
  static const String _kBecasPrefix = 'v3_alumno_becas_';
  static const String _kSancionesPrefix = 'v3_alumno_sanciones_';
  static const String _kEquivalenciasPrefix = 'v3_alumno_equivalencias_';

  // ✅ AGENDA PERSONAL (owner + perfil)
  static const String _kAgendaPersonalPrefix = 'v3_alumno_agenda_personal_';

  // =====================================================
  // Normalizadores
  // =====================================================

  String _normEmail(String v) => v.trim().toLowerCase();
  String _normId(String v) => v.trim();

  String _kPerfilAlumno(String perfilId) =>
      '$_kPerfilAlumnoPrefix${_normId(perfilId)}';
  String _kBoletines(String perfilId) =>
      '$_kBoletinesPrefix${_normId(perfilId)}';
  String _kTitulos(String perfilId) => '$_kTitulosPrefix${_normId(perfilId)}';
  String _kDocumentos(String perfilId) =>
      '$_kDocumentosPrefix${_normId(perfilId)}';
  String _kPendientes(String perfilId) =>
      '$_kPendientesPrefix${_normId(perfilId)}';
  String _kProgresos(String perfilId) =>
      '$_kProgresosPrefix${_normId(perfilId)}';
  String _kBecas(String perfilId) => '$_kBecasPrefix${_normId(perfilId)}';
  String _kSanciones(String perfilId) =>
      '$_kSancionesPrefix${_normId(perfilId)}';
  String _kEquivalencias(String perfilId) =>
      '$_kEquivalenciasPrefix${_normId(perfilId)}';

  // ✅ Keys agenda personal canónicas (owner + perfil)
  String _kAgendaPersonal({
    required String ownerAccountId,
    required String perfilId,
  }) =>
      '$_kAgendaPersonalPrefix${_normId(ownerAccountId)}__${_normId(perfilId)}';

  // ⚠️ Keys legacy (solo para migración / compat) – agenda
  String _kAgendaPersonalLegacy(String perfilId) =>
      '$_kAgendaPersonalPrefix${_normId(perfilId)}';

  // =====================================================
  // Helpers: IDs / Fechas / Normalización RAW
  // =====================================================

  String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${prefix}_${now}_$rnd';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  bool _b(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;

    final s = (v ?? '').toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  int _i(dynamic v, int fb) {
    if (v == null) return fb;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? fb;
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  String _normDateKey(dynamic v) {
    if (v == null) return '1970-01-01';

    if (v is DateTime) {
      return '${v.year.toString().padLeft(4, '0')}-${_two(v.month)}-${_two(v.day)}';
    }

    if (v is int) {
      try {
        final dt = DateTime.fromMillisecondsSinceEpoch(v);
        return '${dt.year.toString().padLeft(4, '0')}-${_two(dt.month)}-${_two(dt.day)}';
      } catch (_) {
        return '1970-01-01';
      }
    }

    final s = v.toString().trim();
    if (s.isEmpty) return '1970-01-01';

    if (s.length >= 10 && s[4] == '-' && s[7] == '-') {
      final head = s.substring(0, 10);
      final parts = head.split('-');
      if (parts.length == 3 &&
          int.tryParse(parts[0]) != null &&
          int.tryParse(parts[1]) != null &&
          int.tryParse(parts[2]) != null) {
        final y = int.tryParse(parts[0]) ?? 1970;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        return '${y.toString().padLeft(4, '0')}-${_two(m)}-${_two(d)}';
      }
    }

    final dt = DateTime.tryParse(s);
    if (dt != null) {
      return '${dt.year.toString().padLeft(4, '0')}-${_two(dt.month)}-${_two(dt.day)}';
    }

    return '1970-01-01';
  }

  String _normNonEmptyString(dynamic v, String fallback) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _normTipoPersonal() => 'personal';

  String _normTime(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return '';
    if (!s.contains(':')) return '';
    final p = s.split(':');
    if (p.length != 2) return '';
    final h = int.tryParse(p[0]) ?? -1;
    final m = int.tryParse(p[1]) ?? -1;
    if (h < 0 || h > 23 || m < 0 || m > 59) return '';
    return '${_two(h)}:${_two(m)}';
  }

  DateTime _dateTimeFromDateKeyAndTime({
    required String dateKey,
    String timeHHmm = '',
    int fallbackHour = 8,
    int fallbackMinute = 0,
  }) {
    final dk = _normDateKey(dateKey);
    final parts = dk.split('-');
    final y = int.tryParse(parts[0]) ?? 1970;
    final mo = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;

    var hh = fallbackHour;
    var mm = fallbackMinute;

    final t = _normTime(timeHHmm);
    if (t.isNotEmpty) {
      final p = t.split(':');
      hh = int.tryParse(p[0]) ?? fallbackHour;
      mm = int.tryParse(p[1]) ?? fallbackMinute;
    }

    return DateTime(y, mo, d, hh, mm);
  }

  /// Deeplink consistente para calendario.
  /// Puede incluir date y/o itemId.
  /// Opción A: perfilId siempre presente.
  String _deeplinkCalendario({
    required String perfilId,
    String? dateKey,
    String? itemId,
  }) {
    final qp = <String, String>{
      'perfilId': _normId(perfilId),
      if ((dateKey ?? '').trim().isNotEmpty) 'date': (dateKey ?? '').trim(),
      if ((itemId ?? '').trim().isNotEmpty) 'itemId': (itemId ?? '').trim(),
    };
    return Uri(path: '/calendario', queryParameters: qp).toString();
  }

  Future<void> _persistNormalizedListIfPossible({
    required String key,
    required List<Map<String, dynamic>> list,
  }) async {
    await _storage.setJsonList(key, list);
  }

  /// ✅ Garantiza una lista de mapas String→dynamic (evita errores de generics/casts)
  Future<List<Map<String, dynamic>>> _loadJsonListMaps(String key) async {
    final raw = await _storage.getJsonList(key);
    final out = <Map<String, dynamic>>[];

    for (final e in raw) {
      if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  /// Sanitiza item de agenda personal para backend-ready.
  Map<String, dynamic> _sanitizeAgendaItem(
    Map<String, dynamic> item, {
    required String nowIso,
    bool forceUpdatedNow = false,
  }) {
    final src = Map<String, dynamic>.from(item);

    final id = _normNonEmptyString(src['id'], _newId('AP'));
    final dateKey = _normDateKey(src['date'] ?? src['fecha']);

    final title = _normNonEmptyString(src['title'] ?? src['titulo'], 'Nota');
    final note = (src['note'] ?? src['nota'] ?? '').toString().trim();

    final alarmEnabled = _b(src['alarmEnabled'], fallback: false);

    final alarmTimeRaw = (src['alarmTime'] ?? '').toString().trim();
    final alarmTime = alarmEnabled ? _normTime(alarmTimeRaw) : '';

    final createdAtIsoRaw = (src['createdAtIso'] ?? '').toString().trim();
    final updatedAtIsoRaw = (src['updatedAtIso'] ?? '').toString().trim();

    final out = <String, dynamic>{
      'id': id,
      'date': dateKey,
      'title': title,
      'note': note,
      'type': _normTipoPersonal(),
      'alarmEnabled': alarmEnabled,
      'alarmTime': alarmTime,
      'createdAtIso': createdAtIsoRaw.isNotEmpty ? createdAtIsoRaw : nowIso,
      'updatedAtIso': forceUpdatedNow
          ? nowIso
          : (updatedAtIsoRaw.isNotEmpty ? updatedAtIsoRaw : nowIso),
    };

    return out;
  }

  // =====================================================
  // CONTEXTO CUENTA / PERFIL
  // =====================================================

  Future<void> _assertPerfilPerteneceAOwner({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final ownerN = _normId(ownerAccountId);
    final perfilN = _normId(perfilId);

    if (ownerN.isEmpty || perfilN.isEmpty) {
      throw StateError('Sesión inválida (owner/perfil vacío).');
    }

    final ok = await CuentaService.ownerTienePerfil(
      ownerAccountId: ownerN,
      perfilId: perfilN,
    );

    if (!ok) {
      throw StateError(
        'El perfil ($perfilN) no pertenece a la cuenta ($ownerN).',
      );
    }
  }

  // =====================================================
  // NOTIFICACIONES (CANÓNICO)
  // =====================================================

  Future<void> _pushNotiOwner({
    required String ownerAccountId,
    required String perfilId,
    required TipoNotificacionAtena tipo,
    required String titulo,
    required String mensaje,
    bool duplicarEnPerfil = true,
    String? deeplink,
    Map<String, dynamic>? data,
  }) async {
    final ownerN = _normId(ownerAccountId);
    final perfilN = _normId(perfilId);
    if (ownerN.isEmpty || perfilN.isEmpty) return;

    final safeTitle = titulo.trim().isEmpty ? 'ATENA' : titulo.trim();
    final safeMsg = mensaje.trim();

    final safeData = <String, dynamic>{
      ...(data ?? <String, dynamic>{}),
      if ((data?['perfilId'] ?? '').toString().trim().isEmpty)
        'perfilId': perfilN,
    };

    final dl = (deeplink ?? '').trim();
    final safeDeeplink =
        (tipo == TipoNotificacionAtena.calendario && dl.isEmpty)
        ? _deeplinkCalendario(perfilId: perfilN)
        : (dl.isEmpty ? null : dl);

    final noti = NotificacionAtena(
      id: NotificacionesService.newId(),
      ownerAccountId: ownerN,
      perfilId: perfilN,
      tipo: tipo,
      scope: NotificacionScopeAtena.owner,
      titulo: safeTitle,
      mensaje: safeMsg,
      fecha: DateTime.now(),
      leida: false,
      deeplink: safeDeeplink,
      data: safeData,
    );

    await NotificacionesService.instance.pushToOwner(
      ownerAccountId: ownerN,
      notificacion: noti,
      duplicarEnPerfil: duplicarEnPerfil,
    );
  }

  // =====================================================
  // USUARIOS (LOGIN PROTOTIPO)
  // =====================================================

  Future<List<AlumnoUsuario>> _getUsuarios() async {
    final list = await _storage.getJsonList(_kAlumnoUsuarios);
    return list
        .whereType<Map>()
        .map((m) => AlumnoUsuario.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _saveUsuarios(List<AlumnoUsuario> users) async {
    await _storage.setJsonList(
      _kAlumnoUsuarios,
      users.map((u) => u.toMap()).toList(),
    );
  }

  Future<bool> registrarAlumnoUsuario({
    required String dni,
    required String email,
    required String passwordHash,
  }) async {
    final dniN = dni.trim();
    final emailN = _normEmail(email);

    final users = await _getUsuarios();
    final exists = users.any(
      (u) => u.documento.trim() == dniN || _normEmail(u.email) == emailN,
    );
    if (exists) return false;

    users.add(
      AlumnoUsuario(documento: dniN, email: emailN, passwordHash: passwordHash),
    );

    await _saveUsuarios(users);
    return true;
  }

  Future<AlumnoUsuario?> loginAlumno({
    required String email,
    required String passwordHash,
  }) async {
    final emailN = _normEmail(email);
    final users = await _getUsuarios();

    try {
      return users.firstWhere(
        (u) => _normEmail(u.email) == emailN && u.passwordHash == passwordHash,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> resetPasswordPorEmailPrototipo(String email) async {
    final emailN = _normEmail(email);
    final users = await _getUsuarios();

    final idx = users.indexWhere((u) => _normEmail(u.email) == emailN);
    if (idx == -1) return null;

    final nueva = 'ATENA${Random().nextInt(900000) + 100000}';
    final actual = users[idx];

    users[idx] = AlumnoUsuario(
      documento: actual.documento,
      email: actual.email,
      passwordHash: nueva,
    );

    await _saveUsuarios(users);
    return nueva;
  }

  // =====================================================
  // PERFIL / FICHA (CANÓNICO por perfilId)
  // =====================================================

  Future<void> upsertPerfilAlumnoByPerfilId({
    required String ownerAccountId,
    required String perfilId,
    required Alumno alumno,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);

    await _storage.setJson(_kPerfilAlumno(pid), alumno.toMap());

    await _pushNotiOwner(
      ownerAccountId: ownerAccountId,
      perfilId: pid,
      tipo: TipoNotificacionAtena.perfilActualizado,
      titulo: 'Perfil actualizado',
      mensaje: 'Se actualizó la ficha del alumno.',
      deeplink: Uri(
        path: '/perfil',
        queryParameters: {'perfilId': pid},
      ).toString(),
      data: {'perfilId': pid},
    );
  }

  Future<Alumno?> getPerfilAlumnoByPerfilId({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    final raw = await _storage.getJson(_kPerfilAlumno(pid));
    return raw == null ? null : Alumno.fromMap(raw);
  }

  // =====================================================
  // BOLETINES (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getBoletinesRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kBoletines(pid));
  }

  Future<void> setBoletinesRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> boletines,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kBoletines(pid),
      boletines.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.boletinActualizado,
        titulo: 'Boletines actualizados',
        mensaje: 'Se actualizaron los boletines del perfil.',
        deeplink: Uri(
          path: '/boletines',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // TÍTULOS (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getTitulosRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kTitulos(pid));
  }

  Future<void> setTitulosRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> titulos,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kTitulos(pid),
      titulos.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.tituloEmitido,
        titulo: 'Títulos actualizados',
        mensaje: 'Se actualizaron los títulos del perfil.',
        deeplink: Uri(
          path: '/titulos',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // DOCUMENTOS (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getDocumentosRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kDocumentos(pid));
  }

  Future<void> setDocumentosRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> documentos,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kDocumentos(pid),
      documentos.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.documentacionActualizada,
        titulo: 'Documentación actualizada',
        mensaje: 'Se actualizó la documentación del perfil.',
        deeplink: Uri(
          path: '/documentos',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // PENDIENTES (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getPendientesRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kPendientes(pid));
  }

  Future<void> setPendientesRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> pendientes,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kPendientes(pid),
      pendientes.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.documentos,
        titulo: 'Pendientes actualizados',
        mensaje: 'Se actualizaron los pendientes del perfil.',
        deeplink: Uri(
          path: '/pendientes',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // PROGRESOS (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getProgresosRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kProgresos(pid));
  }

  Future<void> setProgresosRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> progresos,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kProgresos(pid),
      progresos.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.info,
        titulo: 'Progreso actualizado',
        mensaje: 'Se actualizó el progreso del perfil.',
        deeplink: Uri(
          path: '/progreso',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // BECAS (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getBecasRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kBecas(pid));
  }

  Future<void> setBecasRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> becas,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kBecas(pid),
      becas.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.info,
        titulo: 'Becas actualizadas',
        mensaje: 'Se actualizaron las becas del perfil.',
        deeplink: Uri(
          path: '/becas',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // SANCIONES / CONVIVENCIA (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getSancionesRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kSanciones(pid));
  }

  Future<void> setSancionesRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> sanciones,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kSanciones(pid),
      sanciones.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.info,
        titulo: 'Convivencia actualizada',
        mensaje: 'Se actualizaron sanciones/convivencia del perfil.',
        deeplink: Uri(
          path: '/convivencia',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // EQUIVALENCIAS / CONVALIDACIONES (RAW)
  // =====================================================

  Future<List<Map<String, dynamic>>> getEquivalenciasRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    return _loadJsonListMaps(_kEquivalencias(pid));
  }

  Future<void> setEquivalenciasRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> equivalencias,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final pid = _normId(perfilId);
    await _storage.setJsonList(
      _kEquivalencias(pid),
      equivalencias.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: pid,
        tipo: TipoNotificacionAtena.info,
        titulo: 'Equivalencias actualizadas',
        mensaje: 'Se actualizaron equivalencias/convalidaciones del perfil.',
        deeplink: Uri(
          path: '/equivalencias',
          queryParameters: {'perfilId': pid},
        ).toString(),
        data: {'perfilId': pid},
      );
    }
  }

  // =====================================================
  // ✅ CALENDARIO (RAW) – Curricular + Extracurricular
  // ✅ Fuente única: AlumnoCalendarioInteraccionesService
  // =====================================================

  Future<List<Map<String, dynamic>>> getCalendarioRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    return AlumnoCalendarioInteraccionesService.instance.listarEventos(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
  }

  Future<void> setCalendarioRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> eventos,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    await AlumnoCalendarioInteraccionesService.instance.setEventosBulk(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      eventos: eventos,
      notificarOwner: notificar,
      emitOutboxForInstitution: false,
    );
  }

  Future<Map<String, dynamic>> upsertCalendarioEvent({
    required String ownerAccountId,
    required String perfilId,
    required Map<String, dynamic> event,
    bool notificar = false,
    bool actorIsInstitucion = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final ownerN = _normId(ownerAccountId);
    final perfilN = _normId(perfilId);

    final normalized = <String, dynamic>{
      ...event,
      // ✅ backend-ready: mantener contexto en el evento (no rompe si se ignora)
      'ownerAccountId': ownerN,
      'perfilId': perfilN,
      if (actorIsInstitucion) 'source': 'institucion',
      if (!actorIsInstitucion && !event.containsKey('source'))
        'source': 'owner',
    };

    return (await AlumnoCalendarioInteraccionesService.instance
        .upsertEvento(
          ownerAccountId: ownerN,
          perfilId: perfilN,
          evento: normalized,
          notificarOwner: notificar,
        )
        .timeout(const Duration(seconds: 6)));
  }

  Future<void> deleteCalendarioEvent({
    required String ownerAccountId,
    required String perfilId,
    required String eventId,
    bool notificar = false,
    bool actorIsInstitucion = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    await AlumnoCalendarioInteraccionesService.instance.deleteEvento(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      eventId: eventId,
      notificarOwner: notificar,
      actorIsInstitucion: actorIsInstitucion,
    );
  }

  Future<Map<String, dynamic>> setRsvpCalendarioEvent({
    required String ownerAccountId,
    required String perfilId,
    required String eventId,
    required String rsvp, // yes|no|maybe
    bool notificar = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final id = _s(eventId);
    final v = rsvp.trim().toLowerCase();
    if (id.isEmpty || (v != 'yes' && v != 'no' && v != 'maybe')) {
      throw StateError('RSVP inválido.');
    }

    final status = v == 'yes'
        ? RsvpStatusAtena.yes
        : (v == 'no' ? RsvpStatusAtena.no : RsvpStatusAtena.maybe);

    final updated = await AlumnoCalendarioInteraccionesService.instance.setRsvp(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      eventId: id,
      status: status,
      notificarOwner: notificar,
    );

    if (updated == null) throw StateError('Evento no encontrado.');
    return updated;
  }

  Future<void> emitPreEventosDue({
    required String ownerAccountId,
    required String perfilId,
    int gracePastMinutes = 30,
    int graceEarlyMinutes = 10,
    bool duplicarEnPerfil = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final list = await AlumnoCalendarioInteraccionesService.instance
        .listarEventos(ownerAccountId: ownerAccountId, perfilId: perfilId);

    if (list.isEmpty) return;

    final now = DateTime.now();
    var changed = false;

    for (var i = 0; i < list.length; i++) {
      final e = Map<String, dynamic>.from(list[i]);

      final preNotiMinutes = (e['preNotiMinutes'] is List)
          ? (e['preNotiMinutes'] as List)
                .map((x) => _i(x, -1))
                .where((x) => x > 0)
                .toList()
          : <int>[];

      if (preNotiMinutes.isEmpty) continue;

      final dateKey = _s(e['date']);
      final timeHHmm = _s(e['time']);
      final eventDt = _dateTimeFromDateKeyAndTime(
        dateKey: dateKey,
        timeHHmm: timeHHmm,
      );

      final minutesUntil = eventDt.difference(now).inMinutes;

      final preNotified = (e['preNotified'] is List)
          ? (e['preNotified'] as List)
                .map((x) => _i(x, -1))
                .where((x) => x > 0)
                .toSet()
          : <int>{};

      for (final lead in preNotiMinutes) {
        if (preNotified.contains(lead)) continue;

        final should =
            (minutesUntil <= (lead + graceEarlyMinutes)) &&
            (minutesUntil >= (-gracePastMinutes));

        if (!should) continue;

        final id = _s(e['id']);
        final tituloEvento = _s(e['title']).isEmpty ? 'Evento' : _s(e['title']);
        final tipo = _s(e['type']).toLowerCase() == 'extracurricular'
            ? 'Extracurricular'
            : 'Curricular';

        final fromInst = (_s(e['source']).toLowerCase() == 'institucion');
        final instTxt = fromInst ? ' (Institución)' : '';

        final msg = 'Se acerca: $tituloEvento [$tipo]$instTxt.';

        await _pushNotiOwner(
          ownerAccountId: ownerAccountId,
          perfilId: perfilId,
          tipo: TipoNotificacionAtena.calendario,
          titulo: 'Recordatorio (${lead}m antes)',
          mensaje: msg,
          duplicarEnPerfil: duplicarEnPerfil,
          deeplink: _deeplinkCalendario(
            perfilId: perfilId,
            dateKey: dateKey,
            itemId: id,
          ),
          data: {
            'perfilId': perfilId,
            'date': dateKey,
            'itemId': id,
            'leadMinutes': lead,
            'kind': 'pre_event',
          },
        );

        preNotified.add(lead);
        e['preNotified'] = preNotified.toList()..sort((a, b) => b.compareTo(a));
        e['preNotiLastRunIso'] = now.toIso8601String();

        list[i] = e;
        changed = true;
      }
    }

    if (changed) {
      await AlumnoCalendarioInteraccionesService.instance.setEventosBulk(
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
        eventos: list,
        notificarOwner: false,
        emitOutboxForInstitution: false,
      );
    }
  }

  // =====================================================
  // ✅ AGENDA PERSONAL (RAW) – canónico (owner+perfil + migración)
  // =====================================================

  Future<List<Map<String, dynamic>>> getAgendaPersonalRaw({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final nowIso = DateTime.now().toIso8601String();
    final key = _kAgendaPersonal(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    var raw = await _loadJsonListMaps(key);

    if (raw.isEmpty) {
      final legacy = await _loadJsonListMaps(_kAgendaPersonalLegacy(perfilId));
      if (legacy.isNotEmpty) {
        raw = legacy;
        await _storage.setJsonList(key, legacy);
      }
    }

    final normalized = raw
        .map((m) => _sanitizeAgendaItem(m, nowIso: nowIso))
        .toList();

    await _persistNormalizedListIfPossible(key: key, list: normalized);

    return normalized;
  }

  Future<void> setAgendaPersonalRaw({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> items,
    bool notificar = false,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final nowIso = DateTime.now().toIso8601String();
    final normalized = items
        .map((m) => _sanitizeAgendaItem(m, nowIso: nowIso))
        .toList();

    final key = _kAgendaPersonal(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    await _storage.setJsonList(key, normalized);

    if (notificar) {
      await _pushNotiOwner(
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
        tipo: TipoNotificacionAtena.calendario,
        titulo: 'Agenda personal actualizada',
        mensaje: 'Se actualizaron notas/recordatorios del alumno.',
        deeplink: _deeplinkCalendario(perfilId: perfilId),
        data: {'perfilId': perfilId},
      );
    }
  }

  Future<Map<String, dynamic>> upsertAgendaPersonalItem({
    required String ownerAccountId,
    required String perfilId,
    required Map<String, dynamic> item,
    bool notificar = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final key = _kAgendaPersonal(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final nowIso = DateTime.now().toIso8601String();

    final raw = await _loadJsonListMaps(key);
    final list = raw
        .map((m) => _sanitizeAgendaItem(m, nowIso: nowIso))
        .toList();

    final normalized = _sanitizeAgendaItem(
      item,
      nowIso: nowIso,
      forceUpdatedNow: true,
    );

    final id = normalized['id'].toString().trim();
    final idx = list.indexWhere((e) => (e['id'] ?? '').toString().trim() == id);

    final isUpdate = idx >= 0;

    if (idx >= 0) {
      final createdPrev = (list[idx]['createdAtIso'] ?? '').toString().trim();
      if (createdPrev.isNotEmpty) {
        normalized['createdAtIso'] = createdPrev;
      }
      list[idx] = normalized;
    } else {
      list.add(normalized);
    }

    await _storage.setJsonList(key, list);

    final dateKey = (normalized['date'] ?? '').toString().trim();

    await _pushNotiOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      tipo: TipoNotificacionAtena.calendario,
      titulo: isUpdate ? 'Recordatorio actualizado' : 'Recordatorio guardado',
      mensaje: isUpdate
          ? 'Se actualizó una nota/alarma personal en el calendario.'
          : 'Se guardó una nota/alarma personal en el calendario.',
      deeplink: _deeplinkCalendario(
        perfilId: perfilId,
        dateKey: dateKey,
        itemId: id,
      ),
      data: {'perfilId': perfilId, 'date': dateKey, 'itemId': id},
    );

    return normalized;
  }

  Future<void> deleteAgendaPersonalItem({
    required String ownerAccountId,
    required String perfilId,
    required String itemId,
    bool notificar = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final id = itemId.trim();
    if (id.isEmpty) return;

    final key = _kAgendaPersonal(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final nowIso = DateTime.now().toIso8601String();
    final raw = await _loadJsonListMaps(key);
    final list = raw
        .map((m) => _sanitizeAgendaItem(m, nowIso: nowIso))
        .toList();

    String dateKey = '';
    for (final e in list) {
      if ((e['id'] ?? '').toString().trim() == id) {
        dateKey = _normDateKey(e['date'] ?? e['fecha']);
        break;
      }
    }

    list.removeWhere((e) => (e['id'] ?? '').toString().trim() == id);
    await _storage.setJsonList(key, list);

    await _pushNotiOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      tipo: TipoNotificacionAtena.calendario,
      titulo: 'Recordatorio eliminado',
      mensaje: 'Se eliminó una nota/alarma personal del calendario.',
      deeplink: _deeplinkCalendario(
        perfilId: perfilId,
        dateKey: dateKey.isEmpty ? null : dateKey,
        itemId: id,
      ),
      data: {
        'perfilId': perfilId,
        if (dateKey.isNotEmpty) 'date': dateKey,
        'itemId': id,
      },
    );
  }
}
