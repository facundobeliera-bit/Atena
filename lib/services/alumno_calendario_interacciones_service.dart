// lib/services/alumno_calendario_interacciones_service.dart
//
// ATENA – ALUMNO CALENDARIO INTERACCIONES (CANÓNICO)
// ownerAccountId → perfiles → perfilId
//
// Objetivo:
// - Crear/actualizar eventos curriculares/extracurriculares con notificación POR EVENTO
// - Soportar RSVP (sí/no/tal vez/pendiente) para eventos creados por institución
// - Preparar “envío a institución” mediante OUTBOX (backend-ready)
//
// ❌ Sin DNI como key
// ❌ Sin legacy / flujos paralelos
// ✅ Notificaciones al owner + outbox para institución
//
// FIX (feb 2026):
// - ✅ analyzer: instance_access_to_static_member
//   CuentaService.ownerTienePerfil es estático → acceder como CuentaService.ownerTienePerfil
//   (NO vía CuentaService.instance)
// - Mantiene el resto del comportamiento sin tocar flujo canónico.
//
// ✅ CIERRE DEEPLINK (feb 2026 · canónico):
// - Preserva `deeplink` en eventos (si viene del emisor).
// - Si no viene, auto-genera deeplink canónico a /calendario?perfilId=...&date=...&itemId=...
// - Mantiene extras (evento especial / segmentación) sin romper sanitize.
//
// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'dart:math';

import 'storage_service.dart';

// ✅ FIX: estamos en lib/services, no usar ../services/...
import 'cuenta_service.dart';
import 'notificaciones_service.dart';

import '../models/notificaciones/notificacion_atena.dart';

enum RsvpStatusAtena { pending, yes, no, maybe }

class AlumnoCalendarioInteraccionesService {
  AlumnoCalendarioInteraccionesService._();
  static final AlumnoCalendarioInteraccionesService instance =
      AlumnoCalendarioInteraccionesService._();

  final StorageService _storage = StorageService.instance;

  // =========================
  // KEYS
  // =========================

  static const String _kCalendarioPrefix = 'v3_alumno_calendario_';
  static const String _kInstOutboxPrefix = 'v3_inst_outbox_';

  // Legacy (solo perfil) – para migración
  // Nota: se mantiene el mismo prefijo base por compat histórica;
  // la diferencia real es la forma:
  // - legacy: v3_alumno_calendario_{perfilId}
  // - canónico: v3_alumno_calendario_{ownerId}__{perfilId}
  static const String _kCalendarioLegacyPrefix = 'v3_alumno_calendario_';

  // ✅ Canónico: aislamos por owner + perfil
  String _kCalendario({
    required String ownerAccountId,
    required String perfilId,
  }) {
    final o = _normIdKey(ownerAccountId);
    final p = _normIdKey(perfilId);

    // ✅ FIX analyzer: ${o} necesario por "__" inmediato; $p no necesita llaves.
    return '$_kCalendarioPrefix${o}__$p';
  }

  // ⚠️ Legacy: solo perfil (para migración)
  String _kCalendarioLegacy(String perfilId) =>
      '$_kCalendarioLegacyPrefix${_normIdKey(perfilId)}';

  String _kInstOutbox(String institucionId) =>
      '$_kInstOutboxPrefix${_normIdKey(institucionId)}';

  // =========================
  // Normalizadores
  // =========================

  /// IDs: trim + elimina whitespace interno (key/lookup estable) – consistente con deeplink parser/services.
  String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  String _two(int v) => v.toString().padLeft(2, '0');

  String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(999999).toString().padLeft(6, '0');

    // ✅ ${prefix} y ${now} necesarios por "_" inmediato.
    return '${prefix}_${now}_$rnd';
  }

  bool _boolFromAny(dynamic v, {bool fallback = false}) {
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

  String _str(dynamic v) => (v ?? '').toString().trim();

  /// DateTime / ISO / YYYY-MM-DD → YYYY-MM-DD
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

    // ISO con hora: tomamos head YYYY-MM-DD si corresponde
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

  String _normTipoCalendario(dynamic v) {
    final t = (v ?? '').toString().trim().toLowerCase();
    if (t == 'curricular') return 'curricular';
    if (t == 'extracurricular') return 'extracurricular';
    return '';
  }

  /// Normaliza source/origen (CANÓNICO): owner | institucion | sistema
  String _normSource(dynamic v) {
    final s = (v ?? '').toString().trim().toLowerCase();
    if (s == 'institucion' || s == 'institution' || s == 'inst') {
      return 'institucion';
    }
    if (s == 'sistema' || s == 'system') return 'sistema';
    return 'owner';
  }

  /// Normaliza política RSVP: optional | mandatory_attendance | mandatory_ack
  String _normRsvpPolicy(dynamic v) {
    final s = (v ?? '').toString().trim().toLowerCase();
    if (s == 'mandatory_attendance') return 'mandatory_attendance';
    if (s == 'mandatory_ack') return 'mandatory_ack';
    if (s == 'optional') return 'optional';
    return 'optional';
  }

  /// Normaliza time "HH:MM" (opcional)
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

  String _deeplinkCalendario({
    required String perfilId,
    required String dateKey,
    required String eventId,
  }) {
    final uri = Uri(
      path: '/calendario',
      queryParameters: <String, String>{
        'perfilId': _normIdKey(perfilId),
        'date': dateKey.trim(),
        'itemId': eventId.trim(),
      },
    );
    return uri.toString();
  }

  /// Preferimos deeplink que venga del emisor (p.ej. /documentos?...),
  /// pero si está vacío, generamos el canónico a /calendario.
  String _ensureDeeplinkForEvent({
    required String perfilId,
    required Map<String, dynamic> sanitizedEvent,
  }) {
    final raw = _str(
      sanitizedEvent['deeplink'] ??
          sanitizedEvent['deepLink'] ??
          sanitizedEvent['route'] ??
          sanitizedEvent['ruta'] ??
          sanitizedEvent['url'] ??
          sanitizedEvent['link'],
    );

    if (raw.isNotEmpty) return raw;

    final id = _str(sanitizedEvent['id']).trim();
    final dateKey = _str(sanitizedEvent['date']).trim();
    if (id.isEmpty || dateKey.isEmpty) return '';

    return _deeplinkCalendario(
      perfilId: perfilId,
      dateKey: dateKey,
      eventId: id,
    );
  }

  // =========================
  // Hash estable (idempotencia)
  // =========================

  dynamic _normalizeForHash(dynamic v) {
    if (v == null) return null;

    if (v is DateTime) return v.toIso8601String();

    if (v is Map) {
      final keys = v.keys.map((e) => e.toString()).toList()..sort();
      final out = <String, dynamic>{};
      for (final k in keys) {
        out[k] = _normalizeForHash(v[k]);
      }
      return out;
    }

    if (v is List) return v.map(_normalizeForHash).toList();

    // Fallback para valores no-JSON puros: stringify estable
    if (v is String || v is num || v is bool) return v;

    return v.toString();
  }

  String _stableHash(Map<String, dynamic> m) {
    final norm = _normalizeForHash(m);
    return jsonEncode(norm);
  }

  // =========================
  // Validación canónica
  // =========================

  Future<void> _assertPerfilPerteneceAOwner({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final ownerN = _normIdKey(ownerAccountId);
    final perfilN = _normIdKey(perfilId);

    if (ownerN.isEmpty || perfilN.isEmpty) {
      throw StateError('Sesión inválida (owner/perfil vacío).');
    }

    // ✅ FIX: ownerTienePerfil es static → NO via instance
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

  // =========================
  // Notificación canónica (owner)
  // =========================

  Future<void> _pushNotiOwner({
    required String ownerAccountId,
    required String perfilId,
    required String titulo,
    required String mensaje,
    required String deeplink,
    Map<String, dynamic>? data,
    bool duplicarEnPerfil = true,
  }) async {
    final ownerN = _normIdKey(ownerAccountId);
    final perfilN = _normIdKey(perfilId);
    if (ownerN.isEmpty || perfilN.isEmpty) return;

    final safeTitle = titulo.trim().isEmpty ? 'ATENA' : titulo.trim();
    final safeMsg = mensaje.trim();

    final safeData = <String, dynamic>{
      ...(data ?? <String, dynamic>{}),
      if ((_str(data?['perfilId'])).isEmpty) 'perfilId': perfilN,
      if ((_str(data?['ownerAccountId'])).isEmpty) 'ownerAccountId': ownerN,
    };

    final noti = NotificacionAtena(
      id: NotificacionesService.newId(),
      ownerAccountId: ownerN,
      perfilId: perfilN,
      tipo: TipoNotificacionAtena.calendario,
      scope: NotificacionScopeAtena.owner,
      titulo: safeTitle,
      mensaje: safeMsg,
      fecha: DateTime.now(),
      leida: false,
      deeplink: deeplink,
      data: safeData,
    );

    await NotificacionesService.instance.pushToOwner(
      ownerAccountId: ownerN,
      notificacion: noti,
      duplicarEnPerfil: duplicarEnPerfil,
    );
  }

  // =========================
  // OUTBOX institución (backend-ready)
  // =========================

  Future<void> _pushOutboxInstitucion({
    required String institucionId,
    required String kind,
    required String ownerAccountId,
    required String perfilId,
    required String eventId,
    required String dateKey,
    Map<String, dynamic>? payload,
  }) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return;

    final eid = eventId.trim();
    final dk = dateKey.trim();
    if (eid.isEmpty || dk.isEmpty) return;

    final nowIso = DateTime.now().toIso8601String();

    final payloadNorm = payload != null
        ? Map<String, dynamic>.from(payload)
        : null;
    final payloadHash = _stableHash(payloadNorm ?? <String, dynamic>{});

    final msg = <String, dynamic>{
      'id': _newId('OBX'),
      'kind': kind,
      'institucionId': inst,
      'ownerAccountId': _normIdKey(ownerAccountId),
      'perfilId': _normIdKey(perfilId),
      'eventId': eid,
      'date': dk,
      'createdAtIso': nowIso,
      'payloadHash': payloadHash,
      if (payloadNorm != null) 'payload': payloadNorm,
    };

    final rawDyn = await _storage.getJsonList(_kInstOutbox(inst));
    final raw = <Map<String, dynamic>>[];
    for (final e in rawDyn) {
      if (e is Map) raw.add(Map<String, dynamic>.from(e));
    }

    var already = false;
    for (var i = raw.length - 1; i >= 0; i--) {
      final m = raw[i];
      if ((m['kind'] ?? '').toString() != kind) continue;
      if ((m['eventId'] ?? '').toString().trim() != eid) continue;
      if ((m['payloadHash'] ?? '').toString() != payloadHash) continue;
      already = true;
      break;
    }
    if (already) return;

    raw.add(msg);
    await _storage.setJsonList(_kInstOutbox(inst), raw);
  }

  // =========================
  // Sanitización evento (alineada)
  // =========================

  List<int> _normIntList(dynamic v) {
    if (v is List) {
      final out = <int>[];
      for (final x in v) {
        final n = int.tryParse((x ?? '').toString()) ?? -1;
        if (n > 0) out.add(n);
      }
      final uniq = out.toSet().toList();
      uniq.sort((a, b) => b.compareTo(a));
      return uniq;
    }
    return <int>[];
  }

  Map<String, dynamic> _sanitizeEvent(Map<String, dynamic> e) {
    final src = Map<String, dynamic>.from(e);
    final nowIso = DateTime.now().toIso8601String();

    final id = _normNonEmptyString(src['id'], _newId('CE'));

    final dateKey = _normDateKey(src['date'] ?? src['fecha'] ?? src['dia']);
    final type = _normTipoCalendario(src['type'] ?? src['tipo']);
    final title = _normNonEmptyString(src['title'] ?? src['titulo'], 'Evento');

    final sourceNorm = _normSource(
      src['source'] ?? src['origen'] ?? src['createdBy'],
    );

    final instId = _str(src['institucionId'] ?? src['institutionId']);

    final lock = _boolFromAny(src['lock']) || _boolFromAny(src['locked']);

    final hasAllowDel = src.containsKey('allowStudentDelete');
    final hasAllowEdit = src.containsKey('allowStudentEdit');

    final allowStudentDelete = hasAllowDel
        ? _boolFromAny(src['allowStudentDelete'])
        : (sourceNorm == 'institucion' ? false : true);

    final allowStudentEdit = hasAllowEdit
        ? _boolFromAny(src['allowStudentEdit'])
        : (sourceNorm == 'institucion' ? false : true);

    final rsvpPolicy = _normRsvpPolicy(src['rsvpPolicy']);
    final requiresRsvp =
        _boolFromAny(src['requiresRsvp'] ?? src['requiresRSVP']) ||
        (_str(src['rsvpPolicy']).isNotEmpty);

    final rsvpRaw = _str(
      src['rsvpStatus'] ?? src['rsvp'] ?? src['rsvpStatusAtena'],
    ).toLowerCase();
    final rsvp = _parseRsvp(rsvpRaw);

    final createdAtIsoRaw = _str(src['createdAtIso']);
    final updatedAtIsoRaw = _str(src['updatedAtIso']);

    final out = <String, dynamic>{
      'id': id,
      'date': dateKey,
      'title': title,
      'type': type.isEmpty ? 'curricular' : type,
      'source': sourceNorm,
      if (instId.isNotEmpty) 'institucionId': instId,
      'lock': lock,
      'allowStudentDelete': allowStudentDelete,
      'allowStudentEdit': allowStudentEdit,
      'requiresRsvp': requiresRsvp,
      'rsvpPolicy': rsvpPolicy,
      'rsvpStatus': _rsvpToStr(rsvp),
      'createdAtIso': createdAtIsoRaw.isNotEmpty ? createdAtIsoRaw : nowIso,
      'updatedAtIso': updatedAtIsoRaw.isNotEmpty ? updatedAtIsoRaw : nowIso,
    };

    final time = _normTime(src['time'] ?? src['hora'] ?? src['startTime']);
    if (time.isNotEmpty) out['time'] = time;

    final note = _str(src['note'] ?? src['nota']);
    if (note.isNotEmpty) out['note'] = note;

    final colorHint = _str(src['colorHint'] ?? src['color'] ?? src['uiColor']);
    if (colorHint.isNotEmpty) out['colorHint'] = colorHint;

    final preNotiMinutes = _normIntList(src['preNotiMinutes']);
    final preNotified = _normIntList(src['preNotified']);
    if (preNotiMinutes.isNotEmpty) out['preNotiMinutes'] = preNotiMinutes;
    if (preNotified.isNotEmpty) out['preNotified'] = preNotified;

    final preNotiLastRunIso = _str(src['preNotiLastRunIso']);
    if (preNotiLastRunIso.isNotEmpty) {
      out['preNotiLastRunIso'] = preNotiLastRunIso;
    }

    // ✅ Preservar `deeplink` si existe (clave para tap→abrir ruta real desde el calendario)
    final deeplink = _str(
      src['deeplink'] ??
          src['deepLink'] ??
          src['route'] ??
          src['ruta'] ??
          src['url'] ??
          src['link'],
    );
    if (deeplink.isNotEmpty) out['deeplink'] = deeplink;

    // ✅ Preservar campos "Evento Especial" / segmentación si vienen al tope (tolerante)
    void keepIfNonEmpty(String key) {
      if (!src.containsKey(key)) return;
      final v = src[key];
      if (v == null) return;
      if (v is Map) {
        if (v.isNotEmpty) out[key] = Map<String, dynamic>.from(v);
        return;
      }
      final s = _str(v);
      if (s.isNotEmpty) out[key] = v;
    }

    keepIfNonEmpty('tipoEspecial');
    keepIfNonEmpty('specialType');
    keepIfNonEmpty('eventoEspecialTipo');
    keepIfNonEmpty('segmentoEspecial');
    keepIfNonEmpty('nivel');
    keepIfNonEmpty('turno');
    keepIfNonEmpty('grupo');
    keepIfNonEmpty('curso');
    keepIfNonEmpty('sala');
    keepIfNonEmpty('grupoKey');
    keepIfNonEmpty('grupoLabel');
    keepIfNonEmpty('isSpecial');
    keepIfNonEmpty('category');
    keepIfNonEmpty('eventType');
    keepIfNonEmpty('tipoEventoCalendario');
    keepIfNonEmpty('tipoCalendario');
    keepIfNonEmpty('tipoEvento');

    final data = src['data'];
    if (data is Map) out['data'] = Map<String, dynamic>.from(data);

    if (sourceNorm == 'institucion' && requiresRsvp) {
      final s = _str(out['rsvpStatus']);
      if (s.isEmpty) out['rsvpStatus'] = 'pending';
    }

    final rsvpUpdatedAtIso = _str(src['rsvpUpdatedAtIso']);
    if (rsvpUpdatedAtIso.isNotEmpty) out['rsvpUpdatedAtIso'] = rsvpUpdatedAtIso;

    return out;
  }

  bool _isLocked(Map<String, dynamic> e) {
    final src = Map<String, dynamic>.from(e);
    final lock = _boolFromAny(src['lock']) || _boolFromAny(src['locked']);
    final allowDel = src.containsKey('allowStudentDelete')
        ? _boolFromAny(src['allowStudentDelete'])
        : (_normSource(src['source'] ?? src['origen'] ?? src['createdBy']) ==
                  'institucion'
              ? false
              : true);
    final allowEdit = src.containsKey('allowStudentEdit')
        ? _boolFromAny(src['allowStudentEdit'])
        : (_normSource(src['source'] ?? src['origen'] ?? src['createdBy']) ==
                  'institucion'
              ? false
              : true);
    if (lock) return true;
    if (!allowDel && !allowEdit) return true;
    return false;
  }

  bool _allowStudentDelete(Map<String, dynamic> e) {
    if (e.containsKey('allowStudentDelete')) {
      return _boolFromAny(e['allowStudentDelete']);
    }
    return _normSource(e['source'] ?? e['origen'] ?? e['createdBy']) !=
        'institucion';
  }

  RsvpStatusAtena _parseRsvp(String v) {
    switch (v) {
      case 'yes':
        return RsvpStatusAtena.yes;
      case 'no':
        return RsvpStatusAtena.no;
      case 'maybe':
        return RsvpStatusAtena.maybe;
      case 'pending':
      default:
        return RsvpStatusAtena.pending;
    }
  }

  String _rsvpToStr(RsvpStatusAtena s) {
    switch (s) {
      case RsvpStatusAtena.yes:
        return 'yes';
      case RsvpStatusAtena.no:
        return 'no';
      case RsvpStatusAtena.maybe:
        return 'maybe';
      case RsvpStatusAtena.pending:
        return 'pending';
    }
  }

  bool _sameEventIdentityAndPayload(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    return _stableHash(a) == _stableHash(b);
  }

  Future<List<Map<String, dynamic>>> _loadSanitizedListAndFixIfNeeded({
    required String key,
    required String? legacyKeyIfEmpty,
  }) async {
    var rawDyn = await _storage.getJsonList(key);

    final legacyKey = (legacyKeyIfEmpty ?? '').trim();
    if (rawDyn.isEmpty && legacyKey.isNotEmpty) {
      final legacyDyn = await _storage.getJsonList(legacyKey);
      if (legacyDyn.isNotEmpty) {
        rawDyn = legacyDyn;
        await _storage.setJsonList(key, legacyDyn);
      }
    }

    final raw = <Map<String, dynamic>>[];
    for (final e in rawDyn) {
      if (e is Map) raw.add(Map<String, dynamic>.from(e));
    }

    final sanitized = raw.map(_sanitizeEvent).toList();

    var differs = raw.length != sanitized.length;
    if (!differs) {
      for (var i = 0; i < raw.length; i++) {
        final aSan = _sanitizeEvent(raw[i]);
        final b = sanitized[i];
        if (!_sameEventIdentityAndPayload(aSan, b)) {
          differs = true;
          break;
        }
      }
    }

    if (differs) {
      await _storage.setJsonList(key, sanitized);
    }

    return sanitized;
  }

  // =========================
  // API PÚBLICA
  // =========================

  Future<List<Map<String, dynamic>>> listarEventos({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final key = _kCalendario(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
    final legacyKey = _kCalendarioLegacy(perfilId);

    final list = await _loadSanitizedListAndFixIfNeeded(
      key: key,
      legacyKeyIfEmpty: legacyKey,
    );

    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> setEventosBulk({
    required String ownerAccountId,
    required String perfilId,
    required List<Map<String, dynamic>> eventos,
    bool notificarOwner = false,
    bool emitOutboxForInstitution = false,
    bool duplicarEnPerfil = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final ownerN = _normIdKey(ownerAccountId);
    final perfilN = _normIdKey(perfilId);

    final key = _kCalendario(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final sanitized = eventos.map(_sanitizeEvent).toList();

    // ✅ backend-ready: inyectamos contexto consistente (sin confiar en input)
    for (final e in sanitized) {
      e['ownerAccountId'] = ownerN;
      e['perfilId'] = perfilN;

      // ✅ CIERRE: asegurar deeplink por evento si no viene (canónico)
      final dl = _ensureDeeplinkForEvent(perfilId: perfilN, sanitizedEvent: e);
      if (dl.isNotEmpty) {
        e['deeplink'] = dl;
      }
    }

    await _storage.setJsonList(key, sanitized);

    if (emitOutboxForInstitution) {
      for (final e in sanitized) {
        final src = _str(e['source']).toLowerCase();
        final instId = _str(e['institucionId']);
        if (src == 'institucion' && instId.isNotEmpty) {
          await _pushOutboxInstitucion(
            institucionId: instId,
            kind: 'event_bulk_upsert',
            ownerAccountId: ownerN,
            perfilId: perfilN,
            eventId: _str(e['id']),
            dateKey: _str(e['date']),
            payload: {
              'type': _str(e['type']),
              'title': _str(e['title']),
              'requiresRsvp': _boolFromAny(e['requiresRsvp'], fallback: false),
              'rsvpPolicy': _str(e['rsvpPolicy']),
              'deeplink': _str(e['deeplink']),
            },
          );
        }
      }
    }

    if (notificarOwner) {
      final dl = Uri(
        path: '/calendario',
        queryParameters: {'perfilId': _normIdKey(perfilId)},
      ).toString();

      await _pushNotiOwner(
        ownerAccountId: ownerN,
        perfilId: perfilN,
        titulo: 'Calendario actualizado',
        mensaje: 'Se actualizó el calendario del perfil.',
        deeplink: dl,
        duplicarEnPerfil: duplicarEnPerfil,
        data: {
          'perfilId': _normIdKey(perfilId),
          'count': sanitized.length,
          'kind': 'bulk_set',
        },
      );
    }
  }

  Future<Map<String, dynamic>> upsertEvento({
    required String ownerAccountId,
    required String perfilId,
    required Map<String, dynamic> evento,
    bool notificarOwner = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final ownerN = _normIdKey(ownerAccountId);
    final perfilN = _normIdKey(perfilId);

    final key = _kCalendario(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
    final legacyKey = _kCalendarioLegacy(perfilId);

    final list = await _loadSanitizedListAndFixIfNeeded(
      key: key,
      legacyKeyIfEmpty: legacyKey,
    );

    final normalized = _sanitizeEvent(evento);

    // ✅ backend-ready: inyectamos contexto consistente (sin confiar en input)
    normalized['ownerAccountId'] = ownerN;
    normalized['perfilId'] = perfilN;

    final id = _str(normalized['id']).trim();
    final dateKey = _str(normalized['date']).trim();

    // ✅ CIERRE: asegurar deeplink en el evento persistido
    final deeplink = _ensureDeeplinkForEvent(
      perfilId: perfilN,
      sanitizedEvent: normalized,
    );
    if (deeplink.isNotEmpty) {
      normalized['deeplink'] = deeplink;
    }

    final idx = list.indexWhere((e) => _str(e['id']) == id);
    final isUpdate = idx >= 0;

    if (isUpdate) {
      final prev = Map<String, dynamic>.from(list[idx]);
      if (_stableHash(prev) == _stableHash(normalized)) {
        return normalized;
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    if (isUpdate) {
      final prev = Map<String, dynamic>.from(list[idx]);
      final createdPrev = _str(prev['createdAtIso']);
      if (createdPrev.isNotEmpty) {
        normalized['createdAtIso'] = createdPrev;
      }
    }
    normalized['updatedAtIso'] = nowIso;

    if (isUpdate) {
      list[idx] = normalized;
    } else {
      list.add(normalized);
    }

    await _storage.setJsonList(key, list);

    if (notificarOwner) {
      // ✅ preferimos deeplink del evento (si vino custom), si no, el canónico
      final dl = (deeplink.isNotEmpty)
          ? deeplink
          : _deeplinkCalendario(
              perfilId: perfilN,
              dateKey: dateKey,
              eventId: id,
            );

      await _pushNotiOwner(
        ownerAccountId: ownerN,
        perfilId: perfilN,
        titulo: isUpdate ? 'Evento actualizado' : 'Evento agendado',
        mensaje: isUpdate
            ? 'Se actualizó un evento en el calendario.'
            : 'Se agregó un evento al calendario.',
        deeplink: dl,
        data: {
          'perfilId': _normIdKey(perfilId),
          'itemId': id,
          'eventId': id,
          'date': dateKey,
          'type': _str(normalized['type']),
          'source': _str(normalized['source']),
          'institucionId': _str(normalized['institucionId']),
          'requiresRsvp': _boolFromAny(
            normalized['requiresRsvp'],
            fallback: false,
          ),
          'rsvpStatus': _str(normalized['rsvpStatus']),
          'deeplink': dl,
        },
      );
    }

    final source = _str(normalized['source']).toLowerCase();
    final instId = _str(normalized['institucionId']);
    if (source == 'institucion' && instId.isNotEmpty) {
      await _pushOutboxInstitucion(
        institucionId: instId,
        kind: isUpdate ? 'event_updated' : 'event_created',
        ownerAccountId: ownerN,
        perfilId: perfilN,
        eventId: id,
        dateKey: dateKey,
        payload: {
          'type': _str(normalized['type']),
          'title': _str(normalized['title']),
          'requiresRsvp': _boolFromAny(
            normalized['requiresRsvp'],
            fallback: false,
          ),
          'rsvpPolicy': _str(normalized['rsvpPolicy']),
          'deeplink': _str(normalized['deeplink']),
        },
      );
    }

    return normalized;
  }

  Future<void> deleteEvento({
    required String ownerAccountId,
    required String perfilId,
    required String eventId,
    bool notificarOwner = false,
    bool actorIsInstitucion = false,
    bool duplicarEnPerfil = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final id = eventId.trim();
    if (id.isEmpty) return;

    final key = _kCalendario(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
    final legacyKey = _kCalendarioLegacy(perfilId);

    final list = await _loadSanitizedListAndFixIfNeeded(
      key: key,
      legacyKeyIfEmpty: legacyKey,
    );

    final idx = list.indexWhere((e) => _str(e['id']) == id);
    if (idx < 0) return;

    final prev = Map<String, dynamic>.from(list[idx]);

    if (!actorIsInstitucion) {
      if (_isLocked(prev)) {
        throw StateError('Este evento es obligatorio y no puede eliminarse.');
      }
      if (!_allowStudentDelete(prev)) {
        throw StateError('Este evento no puede eliminarse desde alumno.');
      }
    }

    final dateKey = _str(prev['date']);
    final source = _str(prev['source']).toLowerCase();
    final instId = _str(prev['institucionId']);

    list.removeAt(idx);
    await _storage.setJsonList(key, list);

    if (notificarOwner) {
      final dl = _deeplinkCalendario(
        perfilId: _normIdKey(perfilId),
        dateKey: dateKey,
        eventId: id,
      );

      await _pushNotiOwner(
        ownerAccountId: _normIdKey(ownerAccountId),
        perfilId: _normIdKey(perfilId),
        titulo: 'Evento eliminado',
        mensaje: 'Se eliminó un evento del calendario.',
        deeplink: dl,
        duplicarEnPerfil: duplicarEnPerfil,
        data: {
          'perfilId': _normIdKey(perfilId),
          'itemId': id,
          'eventId': id,
          'date': dateKey,
          'kind': 'event_deleted',
        },
      );
    }

    if (source == 'institucion' && instId.isNotEmpty) {
      await _pushOutboxInstitucion(
        institucionId: instId,
        kind: 'event_deleted',
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
        eventId: id,
        dateKey: dateKey,
        payload: {
          'type': _str(prev['type']),
          'title': _str(prev['title']),
          'deletedAtIso': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<Map<String, dynamic>?> setRsvp({
    required String ownerAccountId,
    required String perfilId,
    required String eventId,
    required RsvpStatusAtena status,
    bool notificarOwner = true,
  }) async {
    await _assertPerfilPerteneceAOwner(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );

    final id = eventId.trim();
    if (id.isEmpty) return null;

    final ownerN = _normIdKey(ownerAccountId);
    final perfilN = _normIdKey(perfilId);

    final key = _kCalendario(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
    final legacyKey = _kCalendarioLegacy(perfilId);

    final list = await _loadSanitizedListAndFixIfNeeded(
      key: key,
      legacyKeyIfEmpty: legacyKey,
    );

    final idx = list.indexWhere((e) => _str(e['id']) == id);
    if (idx < 0) return null;

    final e = Map<String, dynamic>.from(list[idx]);

    // ✅ backend-ready: reforzamos contexto consistente
    e['ownerAccountId'] = ownerN;
    e['perfilId'] = perfilN;

    final prev = _str(e['rsvpStatus'] ?? e['rsvp']).toLowerCase();
    final next = _rsvpToStr(status);

    if (prev == next) return e;

    final source = _str(e['source']).toLowerCase();
    final instId = _str(e['institucionId']);
    final requires = _boolFromAny(e['requiresRsvp'], fallback: false);

    e['rsvpStatus'] = next;
    final nowIso = DateTime.now().toIso8601String();
    e['rsvpUpdatedAtIso'] = nowIso;
    e['updatedAtIso'] = nowIso;

    // ✅ asegurar deeplink persistido si faltaba
    final dl = _ensureDeeplinkForEvent(perfilId: perfilN, sanitizedEvent: e);
    if (dl.isNotEmpty) e['deeplink'] = dl;

    list[idx] = e;
    await _storage.setJsonList(key, list);

    final dateKey = _str(e['date']);

    if (notificarOwner) {
      final deeplink = dl.isNotEmpty
          ? dl
          : _deeplinkCalendario(
              perfilId: perfilN,
              dateKey: dateKey,
              eventId: id,
            );

      await _pushNotiOwner(
        ownerAccountId: ownerN,
        perfilId: perfilN,
        titulo: 'Asistencia actualizada',
        mensaje: 'Tu respuesta para un evento fue registrada: $next.',
        deeplink: deeplink,
        data: {
          'perfilId': _normIdKey(perfilId),
          'itemId': id,
          'eventId': id,
          'date': dateKey,
          'rsvpStatus': next,
          'institucionId': instId,
          'deeplink': deeplink,
        },
      );
    }

    if (source == 'institucion' && instId.isNotEmpty && requires) {
      await _pushOutboxInstitucion(
        institucionId: instId,
        kind: 'rsvp_changed',
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
        eventId: id,
        dateKey: dateKey,
        payload: {
          'rsvpStatus': next,
          'updatedAtIso': _str(e['rsvpUpdatedAtIso']),
        },
      );
    }

    return e;
  }

  // =========================
  // DEBUG / SOPORTE PROTOTIPO
  // =========================

  Future<List<Map<String, dynamic>>> listarOutboxInstitucion(
    String institucionId,
  ) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return [];
    final rawDyn = await _storage.getJsonList(_kInstOutbox(inst));

    final out = <Map<String, dynamic>>[];
    for (final m in rawDyn) {
      if (m is Map) out.add(Map<String, dynamic>.from(m));
    }
    return out;
  }

  Future<void> clearOutboxInstitucion(String institucionId) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return;
    await _storage.setJsonList(_kInstOutbox(inst), <Map<String, dynamic>>[]);
  }
}
