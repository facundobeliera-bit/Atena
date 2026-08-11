// lib/services/notificaciones_service.dart
// ─────────────────────────────────────────────
// ATENA – NOTIFICACIONES SERVICE
// CANÓNICO (OWNER / PERFIL) + COMPAT LEGACY (READ-ONLY)
// ─────────────────────────────────────────────
//
// Fuente de verdad:
// - Inbox OWNER:   `noti_owner_{ownerAccountId}`
// - Inbox PERFIL:  `noti_perfil_{ownerAccountId}_{perfilId}`   (duplicado opcional para UX)
//
// Reglas:
// - ✅ Siempre escribir en OWNER (pushToOwner).
// - ✅ Duplicado en perfil solo si se pide (duplicarEnPerfil).
// - ✅ Lectura canónica: OWNER-first.
// - ✅ Legacy: solo lectura best-effort (sin writes).
//
// API usada por UI (compat + canónico):
// - listarOwner(ownerId)
// - listarOwnerFiltradoPorPerfil(ownerId, perfilId)
// - listarPerfil(ownerId, perfilId) (duplicado UX)
// - instance.setLeida(ownerId, notificacionId, leida, perfilId?)
// - instance.borrarOwner(ownerId, notificacionId, perfilId?)
// - instance.borrarPerfil(ownerId, perfilId, notificacionId)
// - instance.borrarTodasPerfil(ownerId, perfilId)
// - instance.borrarTodasOwnerYPerfiles(ownerId)
//
// ✅ HARDENING (enero 2026):
// - Mantiene wrappers static para compat.
// - Métodos de instancia con misma firma que usa la UI (posicional + named).
// - Deeplink: se canoniza siempre con owner/perfil cuando estén disponibles.
// - Lecturas: se normaliza y se deduplica por id (best-effort).
// - NO depende de copyWith en NotificacionAtena (compat inmutable).
//
// ✅ REGISTRY OWNER↔PERFIL (enero 2026):
// - Para notificar a perfiles “institución” desde otros módulos,
//   guardamos un mapping best-effort: perfilId → ownerAccountId.
// - Se actualiza automáticamente en pushToOwner/pushToPerfil si hay perfilId.
// - API pública:
//   - resolveOwnerForPerfil(perfilId)
//   - resolveOwnerForPerfilFallbackPrefs(perfilId)  (alias compat)
//
// ✅ FIX (feb 2026):
// - Manejo de TimeoutException explícito (import dart:async)
//
// ✅ FIX CANÓNICO (feb 2026):
// - _normalize() NO debe inferir scope=perfil solo porque exista perfilId.
//   Canon: notificaciones pueden tener perfilId y seguir siendo scope=owner.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import '../models/notificaciones/notificacion_atena.dart';
import '../routes/atena_deeplink.dart';
import 'storage_service.dart';

class NotificacionesService {
  NotificacionesService._();
  static final NotificacionesService instance = NotificacionesService._();

  final StorageService _storage = StorageService.instance;

  // =====================================================
  // HARDENING IO (evitar “await colgado” si storage se traba)
  // =====================================================

  static const Duration _ioTimeout = Duration(seconds: 3);

  Future<String?> _safeGetString(String key) async {
    try {
      return await _storage.getString(key).timeout(_ioTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeSetString(String key, String value) async {
    try {
      await _storage.setString(key, value).timeout(_ioTimeout);
    } on TimeoutException {
      // NO-OP
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _safeRemove(String key) async {
    try {
      await _storage.remove(key).timeout(_ioTimeout);
    } on TimeoutException {
      // NO-OP
    } catch (_) {
      // NO-OP
    }
  }

  Future<List<dynamic>> _safeGetKeysRaw() async {
    try {
      final keys = await _storage.getKeys().timeout(_ioTimeout);
      return keys.toList();
    } on TimeoutException {
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  // =====================================================
  // NORMALIZACIÓN
  // =====================================================

  static String _s(dynamic v) => (v ?? '').toString().trim();

  /// IDs: trim + elimina whitespace interno (key/lookup estable).
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  static bool _b(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v.toInt() != 0;

    final s = _s(v).toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  // =====================================================
  // TIPO (fallback local) — evita undefined function
  // =====================================================

  static TipoNotificacionAtena tipoNotiFromString(String raw) {
    final s = _s(raw).toLowerCase();
    if (s.isEmpty) return TipoNotificacionAtena.calendario;

    // match por .name
    for (final v in TipoNotificacionAtena.values) {
      if (v.name.toLowerCase() == s) return v;
    }

    // aliases comunes (compat)
    if (s == 'calendar' || s == 'calendario') {
      return TipoNotificacionAtena.calendario;
    }

    // fallback seguro
    return TipoNotificacionAtena.calendario;
  }

  // =====================================================
  // KEYS
  // =====================================================

  static String _kOwner(String ownerId) => 'noti_owner_${_normIdKey(ownerId)}';

  static String _kPerfil(String ownerId, String perfilId) =>
      'noti_perfil_${_normIdKey(ownerId)}_${_normIdKey(perfilId)}';

  static bool _isKeyPerfilForOwner(String key, String ownerId) {
    final o = _normIdKey(ownerId);
    if (o.isEmpty) return false;
    return _s(key).startsWith('noti_perfil_${o}_');
  }

  // =====================================================
  // REGISTRY OWNER↔PERFIL (BEST-EFFORT)
  // =====================================================

  static String _kPerfilOwner(String perfilId) =>
      'noti_reg_perfil_owner_${_normIdKey(perfilId)}';

  Future<void> _registerPerfilOwner({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final p = _normIdKey(perfilId);
    if (o.isEmpty || p.isEmpty) return;

    try {
      await _safeSetString(_kPerfilOwner(p), o);
    } catch (_) {}
  }

  /// 🔎 Resuelve ownerAccountId a partir de perfilId (best-effort).
  Future<String?> resolveOwnerForPerfil(String perfilId) async {
    final p = _normIdKey(perfilId);
    if (p.isEmpty) return null;

    try {
      final raw = await _safeGetString(_kPerfilOwner(p));
      final o = _normIdKey(_s(raw));
      return o.isEmpty ? null : o;
    } catch (_) {
      return null;
    }
  }

  /// Alias compat para callers viejos (o para módulos que esperan “fallback prefs”).
  Future<String?> resolveOwnerForPerfilFallbackPrefs(String perfilId) =>
      resolveOwnerForPerfil(perfilId);

  // =====================================================
  // RETENCIÓN
  // =====================================================

  static const int _maxNotisPorInbox = 500;

  static List<Map<String, dynamic>> _capRemoveOldest(
    List<Map<String, dynamic>> list,
  ) {
    if (list.length <= _maxNotisPorInbox) return list;

    final indexed = <({int idx, DateTime fecha})>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final dt =
          DateTime.tryParse(_s(m['fechaIso'])) ??
          DateTime.tryParse(_s(m['fecha'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      indexed.add((idx: i, fecha: dt));
    }

    // más viejo primero (para remover)
    indexed.sort((a, b) {
      final c = a.fecha.compareTo(b.fecha);
      return c != 0 ? c : a.idx.compareTo(b.idx);
    });

    final removeCount = list.length - _maxNotisPorInbox;
    final removeIdx = <int>{};
    for (var i = 0; i < removeCount && i < indexed.length; i++) {
      removeIdx.add(indexed[i].idx);
    }

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < list.length; i++) {
      if (!removeIdx.contains(i)) out.add(list[i]);
    }
    return out;
  }

  // =====================================================
  // ID
  // =====================================================

  static int _seq = 0;

  static String newId({String prefix = 'N'}) {
    _seq = (_seq + 1) % 1000000;
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${now}_${_seq.toString().padLeft(6, '0')}';
  }

  // =====================================================
  // HELPERS JSON / MAPS
  // =====================================================

  static Map<String, dynamic> _mapToStringKeyMap(Map m) {
    final out = <String, dynamic>{};
    m.forEach((k, v) {
      out[_s(k)] = v;
    });
    return out;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v == null) return null;

    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) return _mapToStringKeyMap(v);

    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      try {
        final d = jsonDecode(s);
        if (d is Map) return _mapToStringKeyMap(d);
      } catch (_) {}
    }
    return null;
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];

      final out = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(_mapToStringKeyMap(e));
          continue;
        }
        if (e is String && e.trim().isNotEmpty) {
          try {
            final d = jsonDecode(e);
            if (d is Map) out.add(_mapToStringKeyMap(d));
          } catch (_) {}
        }
      }
      return out;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static String _encodeList(List<Map<String, dynamic>> list) =>
      jsonEncode(list);

  static String _normIsoDate(dynamic v) {
    final raw = _s(v);
    if (raw.isEmpty) return DateTime.now().toIso8601String();
    final dt = DateTime.tryParse(raw);
    return (dt ?? DateTime.now()).toIso8601String();
  }

  static DateTime _safeParseDate(dynamic v) {
    final raw = _s(v);
    final dt = DateTime.tryParse(raw);
    return dt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  // =====================================================
  // NORMALIZE MAP (CANÓNICO)
  // =====================================================

  static Map<String, dynamic> _normalize(
    Map<String, dynamic> m, {
    String? forceScope,
    String? ownerId,
    String? perfilId,
  }) {
    final out = Map<String, dynamic>.from(m);

    // ID
    final id = _s(out['id']);
    out['id'] = id.isEmpty ? newId() : _normIdKey(id);

    // Owner / Perfil (preferir params)
    final owner = _normIdKey(
      _s(ownerId).isNotEmpty ? ownerId! : _s(out['ownerAccountId']),
    );
    if (owner.isNotEmpty) out['ownerAccountId'] = owner;

    final pid = _normIdKey(
      _s(perfilId).isNotEmpty ? perfilId! : _s(out['perfilId']),
    );
    if (pid.isNotEmpty) out['perfilId'] = pid;

    // Fecha / Leída
    out['fechaIso'] = _normIsoDate(out['fechaIso'] ?? out['fecha']);
    out['leida'] = _b(out['leida']);

    // Payload/Data (compat)
    final payload = _asMap(out['payload']);
    final data = _asMap(out['data']);
    if (payload != null && data == null) out['data'] = payload;
    if (data != null && payload == null) out['payload'] = data;

    // Deeplink (hardening canónico)
    final deeplink = _s(out['deeplink']);
    if (deeplink.isNotEmpty) {
      try {
        out['deeplink'] = AtenaDeeplink.ensureCanonicoString(
          deeplink,
          ownerAccountId: owner.isEmpty ? null : owner,
          perfilId: pid.isEmpty ? null : pid,
        );
      } catch (_) {
        out['deeplink'] = deeplink;
      }
    }

    // Tipo (hardening)
    final tipoRaw = _s(out['tipo']).isNotEmpty ? out['tipo'] : out['type'];
    out['tipo'] = tipoNotiFromString(_s(tipoRaw)).name;

    // Contenido
    if (_s(out['titulo']).isEmpty) out['titulo'] = 'Notificación';
    out['mensaje'] = _s(out['mensaje']);

    // Canon adicional: completar owner/perfil desde deeplink si faltan (best-effort)
    final dl = _s(out['deeplink']);
    if (dl.isNotEmpty) {
      try {
        final d = AtenaDeeplink.parse(dl);
        final o2 = _normIdKey(_s(d.ownerAccountId));
        if (_s(out['ownerAccountId']).isEmpty && o2.isNotEmpty) {
          out['ownerAccountId'] = o2;
        }
        final p2 = _normIdKey(_s(d.perfilId));
        if (_s(out['perfilId']).isEmpty && p2.isNotEmpty) out['perfilId'] = p2;
      } catch (_) {}
    }

    // ✅ Scope (canónico):
    // - Si viene forceScope, se respeta SIEMPRE.
    // - Si NO viene forceScope, NO inferimos scope=perfil por tener perfilId.
    //   Canon: en owner inbox puede existir perfilId y el scope sigue siendo owner.
    final scopeForced = _s(forceScope);
    if (scopeForced.isNotEmpty) {
      out['scope'] = scopeForced;
    } else {
      final existing = _s(out['scope']);
      out['scope'] = existing.isNotEmpty ? existing : 'owner';
    }

    return out;
  }

  static List<Map<String, dynamic>> _upsertById(
    List<Map<String, dynamic>> list,
    Map<String, dynamic> normalized,
  ) {
    final id = _normIdKey(_s(normalized['id']));
    if (id.isEmpty) return list;

    final idx = list.indexWhere((e) => _normIdKey(_s(e['id'])) == id);
    if (idx < 0) {
      list.add(normalized);
    } else {
      list[idx] = normalized;
    }
    return list;
  }

  static bool _removeByIdMutate(List<Map<String, dynamic>> list, String id) {
    final target = _normIdKey(id);
    if (target.isEmpty) return false;

    final before = list.length;
    list.removeWhere((e) => _normIdKey(_s(e['id'])) == target);
    return list.length != before;
  }

  static bool _setLeidaByIdMutate(
    List<Map<String, dynamic>> list,
    String id,
    bool leida,
  ) {
    final target = _normIdKey(id);
    if (target.isEmpty) return false;

    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (_normIdKey(_s(e['id'])) == target) {
        final m = Map<String, dynamic>.from(e);
        m['leida'] = leida;
        list[i] = m;
        return true;
      }
    }
    return false;
  }

  static List<Map<String, dynamic>> _dedupByIdKeepNewest(
    List<Map<String, dynamic>> list,
  ) {
    if (list.length <= 1) return list;

    final byId = <String, Map<String, dynamic>>{};
    for (final m in list) {
      final id = _normIdKey(_s(m['id']));
      if (id.isEmpty) continue;

      final prev = byId[id];
      if (prev == null) {
        byId[id] = m;
        continue;
      }

      final dtPrev = _safeParseDate(prev['fechaIso'] ?? prev['fecha']);
      final dtNow = _safeParseDate(m['fechaIso'] ?? m['fecha']);
      if (dtNow.isAfter(dtPrev)) byId[id] = m;
    }

    return byId.values.toList();
  }

  static NotificacionAtena _ensureOwnerPerfilInNoti(
    NotificacionAtena n, {
    required String ownerId,
    String? perfilId,
  }) {
    // No dependemos de copyWith. Reconstruimos por map.
    try {
      final m = Map<String, dynamic>.from(n.toMap());
      if (_s(m['ownerAccountId']).isEmpty && ownerId.trim().isNotEmpty) {
        m['ownerAccountId'] = _normIdKey(ownerId);
      }
      if (perfilId != null &&
          perfilId.trim().isNotEmpty &&
          _s(m['perfilId']).isEmpty) {
        m['perfilId'] = _normIdKey(perfilId);
      }
      return NotificacionAtena.fromMap(m);
    } catch (_) {
      return n;
    }
  }

  // =====================================================
  // KEYS (por StorageService real)
  // =====================================================

  Future<List<String>> _listAllKeys() async {
    try {
      final keys = await _safeGetKeysRaw();
      return keys.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return <String>[];
    }
  }

  // =====================================================
  // LEGACY READ-ONLY (hook futuro)
  // =====================================================

  Future<List<Map<String, dynamic>>> _readLegacyOwnerBestEffort(
    String ownerId,
  ) async {
    // Hook: si existiera storage legacy, se lee acá (solo lectura).
    return <Map<String, dynamic>>[];
  }

  // =====================================================
  // WRITE
  // =====================================================

  Future<void> pushToOwner({
    required String ownerAccountId,
    required NotificacionAtena notificacion,
    bool duplicarEnPerfil = false,
  }) async {
    final o = _normIdKey(ownerAccountId);
    if (o.isEmpty) return;

    final fixedNoti = _ensureOwnerPerfilInNoti(notificacion, ownerId: o);

    final m = _normalize(
      fixedNoti.toMap(),
      forceScope: 'owner',
      ownerId: o,
      // Nota: perfilId NO se fuerza acá; si la noti trae perfilId, se conserva.
    );

    // ✅ registry owner↔perfil (si existe perfilId)
    final pid = _normIdKey(_s(m['perfilId']));
    if (pid.isNotEmpty) {
      try {
        await _registerPerfilOwner(ownerAccountId: o, perfilId: pid);
      } catch (_) {}
    }

    final list = _decodeList(await _safeGetString(_kOwner(o)));
    _upsertById(list, m);

    final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
    await _safeSetString(_kOwner(o), _encodeList(fixed));

    if (duplicarEnPerfil && pid.isNotEmpty) {
      try {
        // Duplicar usando la noti original “asegurada”, no reparseada desde m.
        await pushToPerfil(
          ownerAccountId: o,
          perfilId: pid,
          notificacion: fixedNoti,
        );
      } catch (_) {}
    }
  }

  Future<void> pushToPerfil({
    required String ownerAccountId,
    required String perfilId,
    required NotificacionAtena notificacion,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return;

    // ✅ registry owner↔perfil (siempre)
    try {
      await _registerPerfilOwner(ownerAccountId: o, perfilId: pid);
    } catch (_) {}

    final fixedNoti = _ensureOwnerPerfilInNoti(
      notificacion,
      ownerId: o,
      perfilId: pid,
    );

    final m = _normalize(
      fixedNoti.toMap(),
      forceScope: 'perfil',
      ownerId: o,
      perfilId: pid,
    );

    final list = _decodeList(await _safeGetString(_kPerfil(o, pid)));
    _upsertById(list, m);

    final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
    await _safeSetString(_kPerfil(o, pid), _encodeList(fixed));
  }

  // Static wrappers (compat) para writes
  static Future<void> pushToOwnerStatic({
    required String ownerAccountId,
    required NotificacionAtena notificacion,
    bool duplicarEnPerfil = false,
  }) => instance.pushToOwner(
    ownerAccountId: ownerAccountId,
    notificacion: notificacion,
    duplicarEnPerfil: duplicarEnPerfil,
  );

  static Future<void> pushToPerfilStatic({
    required String ownerAccountId,
    required String perfilId,
    required NotificacionAtena notificacion,
  }) => instance.pushToPerfil(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
    notificacion: notificacion,
  );

  // =====================================================
  // READ – CANÓNICO
  // =====================================================

  Future<List<Map<String, dynamic>>> _readOwnerMaps(String ownerId) async {
    final o = _normIdKey(ownerId);
    if (o.isEmpty) return <Map<String, dynamic>>[];

    final raw = await _safeGetString(_kOwner(o));
    final list = _decodeList(raw);

    final out = <Map<String, dynamic>>[];
    for (final m in list) {
      out.add(_normalize(m, forceScope: 'owner', ownerId: o));
    }
    return _dedupByIdKeepNewest(out);
  }

  Future<List<Map<String, dynamic>>> _readPerfilMaps(
    String ownerId,
    String perfilId,
  ) async {
    final o = _normIdKey(ownerId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return <Map<String, dynamic>>[];

    final raw = await _safeGetString(_kPerfil(o, pid));
    final list = _decodeList(raw);

    final out = <Map<String, dynamic>>[];
    for (final m in list) {
      out.add(_normalize(m, forceScope: 'perfil', ownerId: o, perfilId: pid));
    }
    return _dedupByIdKeepNewest(out);
  }

  // =====================================================
  // PUBLIC API – READ (static wrappers)
  // =====================================================

  static Future<List<NotificacionAtena>> listarOwner(String ownerAccountId) =>
      instance._listarOwner(ownerAccountId);

  static Future<List<NotificacionAtena>> listarOwnerFiltradoPorPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) => instance._listarOwnerFiltradoPorPerfil(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  /// ✅ Compat posicional (algunos builds viejos)
  static Future<List<NotificacionAtena>> listarOwnerFiltradoPorPerfilPos(
    String ownerAccountId,
    String perfilId,
  ) => instance._listarOwnerFiltradoPorPerfil(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  static Future<List<NotificacionAtena>> listarPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) => instance._listarPerfil(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  /// ✅ Compat posicional (algunos builds viejos)
  static Future<List<NotificacionAtena>> listarPerfilPos(
    String ownerAccountId,
    String perfilId,
  ) => instance._listarPerfil(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  // =====================================================
  // PUBLIC API – MUTACIONES (instance + static wrappers)
  // =====================================================

  // ✅ FIRMA CANÓNICA (named)
  Future<void> setLeida({
    required String ownerAccountId,
    required String notificacionId,
    required bool leida,
    String? perfilId,
  }) => _setLeidaImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    leida: leida,
    perfilId: perfilId,
  );

  // ✅ FIRMA COMPAT (posicional)
  Future<void> setLeidaPos(
    String ownerAccountId,
    String notificacionId,
    bool leida, [
    String? perfilId,
  ]) => _setLeidaImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    leida: leida,
    perfilId: perfilId,
  );

  /// ✅ Wrapper static (compat)
  static Future<void> setLeidaStatic({
    required String ownerAccountId,
    required String notificacionId,
    required bool leida,
    String? perfilId,
  }) => instance._setLeidaImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    leida: leida,
    perfilId: perfilId,
  );

  // ✅ FIRMA CANÓNICA (named)
  Future<void> borrarOwner({
    required String ownerAccountId,
    required String notificacionId,
    String? perfilId,
  }) => _borrarOwnerImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    perfilId: perfilId,
  );

  // ✅ FIRMA COMPAT (posicional)
  Future<void> borrarOwnerPos(
    String ownerAccountId,
    String notificacionId, [
    String? perfilId,
  ]) => _borrarOwnerImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    perfilId: perfilId,
  );

  /// ✅ Wrapper static (compat)
  static Future<void> borrarOwnerStatic({
    required String ownerAccountId,
    required String notificacionId,
    String? perfilId,
  }) => instance._borrarOwnerImpl(
    ownerAccountId: ownerAccountId,
    notificacionId: notificacionId,
    perfilId: perfilId,
  );

  // ✅ FIRMA CANÓNICA (named)
  Future<void> borrarPerfil({
    required String ownerAccountId,
    required String perfilId,
    required String notificacionId,
  }) => _borrarPerfilImpl(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
    notificacionId: notificacionId,
  );

  // ✅ FIRMA COMPAT (posicional)
  Future<void> borrarPerfilPos(
    String ownerAccountId,
    String perfilId,
    String notificacionId,
  ) => _borrarPerfilImpl(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
    notificacionId: notificacionId,
  );

  /// ✅ Wrapper static (compat)
  static Future<void> borrarPerfilStatic({
    required String ownerAccountId,
    required String perfilId,
    required String notificacionId,
  }) => instance._borrarPerfilImpl(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
    notificacionId: notificacionId,
  );

  // ✅ FIRMA CANÓNICA (named)
  Future<void> borrarTodasPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) => _borrarTodasPerfilImpl(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  // ✅ FIRMA COMPAT (posicional)
  Future<void> borrarTodasPerfilPos(String ownerAccountId, String perfilId) =>
      _borrarTodasPerfilImpl(
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
      );

  /// ✅ Wrapper static (compat)
  static Future<void> borrarTodasPerfilStatic({
    required String ownerAccountId,
    required String perfilId,
  }) => instance._borrarTodasPerfilImpl(
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
  );

  // ✅ FIRMA CANÓNICA (posicional)
  Future<void> borrarTodasOwnerYPerfiles(String ownerAccountId) =>
      _borrarTodasOwnerYPerfilesImpl(ownerAccountId);

  /// ✅ Wrapper static (compat)
  static Future<void> borrarTodasOwnerYPerfilesStatic(String ownerAccountId) =>
      instance._borrarTodasOwnerYPerfilesImpl(ownerAccountId);

  // =====================================================
  // READ IMPLEMENTATIONS
  // =====================================================

  Future<List<NotificacionAtena>> _listarOwner(String ownerAccountId) async {
    final o = _normIdKey(ownerAccountId);
    if (o.isEmpty) return <NotificacionAtena>[];

    final maps = await _readOwnerMaps(o);

    final legacy = await _readLegacyOwnerBestEffort(o);
    if (legacy.isNotEmpty) {
      for (final m in legacy) {
        maps.add(_normalize(m, forceScope: 'owner', ownerId: o));
      }
    }

    final normalized = _dedupByIdKeepNewest(maps);

    final out = <NotificacionAtena>[];
    for (final m in normalized) {
      try {
        final n = NotificacionAtena.fromMap(m);
        out.add(_ensureOwnerPerfilInNoti(n, ownerId: o));
      } catch (_) {}
    }

    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  Future<List<NotificacionAtena>> _listarOwnerFiltradoPorPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return <NotificacionAtena>[];

    final owner = await _listarOwner(o);
    final out = owner.where((n) => _normIdKey(_s(n.perfilId)) == pid).toList();
    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  Future<List<NotificacionAtena>> _listarPerfil({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return <NotificacionAtena>[];

    final maps = await _readPerfilMaps(o, pid);

    final out = <NotificacionAtena>[];
    for (final m in maps) {
      try {
        final n = NotificacionAtena.fromMap(m);
        out.add(_ensureOwnerPerfilInNoti(n, ownerId: o, perfilId: pid));
      } catch (_) {}
    }

    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  // =====================================================
  // MUTACIONES (CANÓNICO) – IMPLEMENTACIÓN PRIVADA
  // =====================================================

  Future<void> _setLeidaImpl({
    required String ownerAccountId,
    required String notificacionId,
    required bool leida,
    String? perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final id = _normIdKey(notificacionId);
    if (o.isEmpty || id.isEmpty) return;

    // 1) Owner inbox (siempre)
    try {
      final list = _decodeList(await _safeGetString(_kOwner(o)));
      final touched = _setLeidaByIdMutate(list, id, leida);
      if (touched) {
        final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
        await _safeSetString(_kOwner(o), _encodeList(fixed));
      }
    } catch (_) {}

    final pid = _normIdKey(_s(perfilId));

    // 2) Perfil inbox (si se pasó)
    if (pid.isNotEmpty) {
      try {
        final list = _decodeList(await _safeGetString(_kPerfil(o, pid)));
        final touched = _setLeidaByIdMutate(list, id, leida);
        if (touched) {
          final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
          await _safeSetString(_kPerfil(o, pid), _encodeList(fixed));
        }
      } catch (_) {}
      return;
    }

    // 3) Best-effort: barrer perfiles del owner
    try {
      final keys = await _listAllKeys();
      for (final k in keys) {
        if (!_isKeyPerfilForOwner(k, o)) continue;
        final list = _decodeList(await _safeGetString(k));
        final touched = _setLeidaByIdMutate(list, id, leida);
        if (!touched) continue;
        final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
        await _safeSetString(k, _encodeList(fixed));
      }
    } catch (_) {}
  }

  Future<void> _borrarOwnerImpl({
    required String ownerAccountId,
    required String notificacionId,
    String? perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final id = _normIdKey(notificacionId);
    if (o.isEmpty || id.isEmpty) return;

    // 1) Owner
    try {
      final list = _decodeList(await _safeGetString(_kOwner(o)));
      final touched = _removeByIdMutate(list, id);
      if (touched) {
        final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
        await _safeSetString(_kOwner(o), _encodeList(fixed));
      }
    } catch (_) {}

    // 2) Perfil específico si se pasó
    final pid = _normIdKey(_s(perfilId));
    if (pid.isNotEmpty) {
      try {
        final list = _decodeList(await _safeGetString(_kPerfil(o, pid)));
        final touched = _removeByIdMutate(list, id);
        if (touched) {
          final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
          await _safeSetString(_kPerfil(o, pid), _encodeList(fixed));
        }
      } catch (_) {}
      return;
    }

    // 3) Best-effort: barrer perfiles del owner
    try {
      final keys = await _listAllKeys();
      for (final k in keys) {
        if (!_isKeyPerfilForOwner(k, o)) continue;
        final list = _decodeList(await _safeGetString(k));
        final touched = _removeByIdMutate(list, id);
        if (!touched) continue;
        final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
        await _safeSetString(k, _encodeList(fixed));
      }
    } catch (_) {}
  }

  Future<void> _borrarPerfilImpl({
    required String ownerAccountId,
    required String perfilId,
    required String notificacionId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    final id = _normIdKey(notificacionId);
    if (o.isEmpty || pid.isEmpty || id.isEmpty) return;

    final list = _decodeList(await _safeGetString(_kPerfil(o, pid)));
    final touched = _removeByIdMutate(list, id);
    if (!touched) return;

    final fixed = _capRemoveOldest(_dedupByIdKeepNewest(list));
    await _safeSetString(_kPerfil(o, pid), _encodeList(fixed));
  }

  Future<void> _borrarTodasPerfilImpl({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return;

    try {
      await _safeRemove(_kPerfil(o, pid));
      return;
    } catch (_) {}

    // fallback: dejar inbox vacío
    try {
      await _safeSetString(
        _kPerfil(o, pid),
        _encodeList(<Map<String, dynamic>>[]),
      );
    } catch (_) {}
  }

  Future<void> _borrarTodasOwnerYPerfilesImpl(String ownerAccountId) async {
    final o = _normIdKey(ownerAccountId);
    if (o.isEmpty) return;

    // 1) Borrar owner
    try {
      await _safeRemove(_kOwner(o));
    } catch (_) {
      try {
        await _safeSetString(_kOwner(o), _encodeList(<Map<String, dynamic>>[]));
      } catch (_) {}
    }

    // 2) Borrar perfiles del owner
    final keys = await _listAllKeys();
    if (keys.isEmpty) return;

    for (final k in keys) {
      if (!_isKeyPerfilForOwner(k, o)) continue;
      try {
        await _safeRemove(k);
      } catch (_) {
        try {
          await _safeSetString(k, _encodeList(<Map<String, dynamic>>[]));
        } catch (_) {}
      }
    }
  }
}
