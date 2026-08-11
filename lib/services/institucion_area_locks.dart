// lib/services/institucion_area_locks.dart
//
// ATENA – INSTITUCIÓN · LOCKS CANÓNICOS POR ÁREA (FASE 2)
// ✅ Archivo SUELTO (sin subcarpetas).
//
// Objetivo:
// - Permitir trabajo simultáneo por “perfiles de trabajo”
// - Bloqueo por ÁREA + POR ACTIVIDAD (no se pisan Jardín vs Primaria, etc.)
// - Prototipo local backend-ready: SharedPreferences + deviceId + JSON + TTL.
//
// ✅ FIX CANÓNICO (feb 2026 · compat perfiles por actividad):
// - Soporta profileId legacy (wp_1..wp_N) y lo convierte a:
//      wp_(actividadKeySafe)_(n)
//   Ej: wp_1 + actividadKey=corr_primaria -> wp_curricular_primaria_1
// - Esto evita que “Administración” no cargue cuando alguna pantalla aún usa wp_1.
//
// ✅ MICRO-HARDENING (feb 2026 · instId):
// - Contrato RECOMENDADO: los callers pasan instId “DATA/humano”.
// - El service SIEMPRE normaliza internamente a KEY-SAFE dentro de lockKey/_lockKeyV1.
// - El Guard solo valida que el normalizado no quede vacío (para evitar “inst” compartido),
//   pero NO pre-normaliza lo que le pasa al service (evita confusión y mismatches entre pantallas).
//
// ✅ FIX CRÍTICO (feb 2026 · evita “await colgado”):
// - SharedPreferences.getInstance / reads/writes envueltos en timeouts cortos.
// - openWithAreaLock: valida instId/actividadKey antes de intentar lock.
// - tryAcquire/getStatus/refresh/release: timeouts + logs diagnósticos.
// - release en finally con timeout (no puede colgar y dejar lock vivo).
//
// ✅ FIX MIGRACIÓN (feb 2026 · “v1 bloquea v2”):
// - Si existe un lock v1 (sin actividad) MÍO pero con profileId distinto (wp_1 vs wp_act_1),
//   lo limpiamos automáticamente para evitar bloqueo fantasma.
// - En release: v1 se elimina si el deviceId coincide (sin exigir profileId exacto),
//   porque v1 es solo compat y suele ser el origen del “queda cargando”.
//
// ✅ FIX adicional (feb 2026 · auto-heal v2 mine mismatch):
// - Si existe lock v2 MÍO pero con profileId distinto, lo limpiamos y re-adquirimos.
//   (Esto evita deadlocks locales por cambios de normalización o crashes en la navegación).
//
// ✅ FIX COMPAT FIRMA (feb 2026 · PERDURABLE):
// - getStatus() quedó con firma estable:
//     getStatus({instId, actividadKey, area, deviceId?, mine=false})
//   => Compila tanto si algún caller pasa deviceId/mine como si NO los pasa.
// - getStatusStable() queda como alias explícito “API congelada” para el futuro.
// - mine=true filtra: si el lock NO es mío, devuelve libre (para pantallas que solo
//   quieren “mi estado” sin revelar el lock de otro).
//
// HARDENING (enero 2026):
// - Normalización estable (trim + colapso whitespace).
// - Parser tolerante (expiresAtMs como int/double/string).
// - Limpieza/auto-heal de locks corruptos o vencidos.
// - refresh no escribe si el lock no es “mío”.
// - Helpers: lockKey, dump, forceClear (dev) y guard con lock extendido opcional.
// - Guard: capturas de Navigator sin depender del context luego de awaits.
//
// ✅ FIX (feb 2026 · RESCOPE DE PERFIL):
// - Si llega un profileId scopeado de OTRA actividad (wp_otro_1) para la actividad actual,
//   se re-scopea al actSafe actual manteniendo el índice (wp_actActual_1).
//   Esto evita deadlocks y mismatches por navegación/args legacy.
//
// ✅ MEJORA CANÓNICA (feb 2026 · requested):
// - Guard ahora puede inyectar MÁS contexto en RouteSettings.arguments (sin romper compat):
//   ownerAccountId, actividadLabel, workProfileId/workProfileName, institucionId/institucionNombre.
//   Esto hace los botones “backend-ready” aunque una pantalla destino aún lea args en vez de ctor.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// ÁREAS OPERATIVAS (LOCK POR ÁREA)
// =====================================================

enum InstitucionAreaKey {
  notificaciones,
  solicitudes,
  vacantes,
  documentacion,
  extracurriculares,
  croquis,
}

/// ✅ NO i18n aquí: devolvemos un label técnico estable (la UI decide traducción).
String institucionAreaKeyLabel(InstitucionAreaKey k) => k.name;

String _areaKeyName(InstitucionAreaKey k) => k.name;

InstitucionAreaKey? parseAreaKey(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;

  final lower = v.toLowerCase();
  for (final k in InstitucionAreaKey.values) {
    if (k.name.toLowerCase() == lower) return k;
  }
  return null;
}

// =====================================================
// PREFS SAFE GET (timeout)
// =====================================================

class _PrefsSafe {
  static const Duration _timeout = Duration(seconds: 2);

  static Future<SharedPreferences> get() {
    return SharedPreferences.getInstance().timeout(_timeout);
  }

  static Future<String?> getString(SharedPreferences prefs, String key) async {
    return Future<String?>(() {
      try {
        return prefs.getString(key);
      } catch (_) {
        return null;
      }
    }).timeout(_timeout);
  }

  static Future<bool> setString(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    return Future<bool>(() {
      try {
        return prefs.setString(key, value);
      } catch (_) {
        return false;
      }
    }).timeout(_timeout);
  }

  static Future<bool> remove(SharedPreferences prefs, String key) async {
    return Future<bool>(() {
      try {
        return prefs.remove(key);
      } catch (_) {
        return false;
      }
    }).timeout(_timeout);
  }
}

// =====================================================
// DEVICE ID (canónico)
// =====================================================

class AtenaDeviceId {
  static const String _kDeviceId = 'atena_device_id_v1';

  static Future<String> getOrCreate() async {
    final prefs = await _PrefsSafe.get();

    final existing = ((await _PrefsSafe.getString(prefs, _kDeviceId)) ?? '')
        .trim();
    if (existing.isNotEmpty) return existing;

    final now = DateTime.now().microsecondsSinceEpoch;
    final id = 'dev_${now}_${(now ^ now.hashCode) & 0x7fffffff}';

    try {
      await _PrefsSafe.setString(prefs, _kDeviceId, id);
    } catch (_) {
      // best-effort
    }

    return id;
  }
}

// =====================================================
// LOCK STATUS
// =====================================================

class InstitucionAreaLockStatus {
  final bool locked;
  final bool mine;
  final String? deviceId;
  final String? profileId;
  final String? profileName;
  final DateTime? expiresAt;

  const InstitucionAreaLockStatus({
    required this.locked,
    required this.mine,
    required this.deviceId,
    required this.profileId,
    required this.profileName,
    required this.expiresAt,
  });

  bool get expired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

const _freeStatus = InstitucionAreaLockStatus(
  locked: false,
  mine: false,
  deviceId: null,
  profileId: null,
  profileName: null,
  expiresAt: null,
);

// =====================================================
// LOCK SERVICE (SharedPreferences, backend-ready) – POR ACTIVIDAD
// =====================================================

class InstitucionAreaLockService {
  static const Duration ttl = Duration(minutes: 10);

  // Normalización “humana” (preserva espacios single-space)
  static String _normHuman(String v, String fallback) {
    final t = v.trim();
    if (t.isEmpty) return fallback;
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final out = parts.join(' ');
    return out.isEmpty ? fallback : out;
  }

  // Normalización para KEYS (sin espacios, estable)
  static String _normKey(String v, String fallback) {
    final h = _normHuman(v, fallback);
    final s = h
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-\.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return s.isEmpty ? fallback : s;
  }

  /// Para mostrar/guardar metadata humana (no scope).
  static String normalizeActividadKey(String actividadKey) =>
      _normHuman(actividadKey, 'actividad_default');

  /// ✅ Para scope técnico estable (locks/prefs/route).
  static String normalizeActividadKeyForScope(String actividadKey) =>
      _normKey(actividadKey, 'actividad_default');

  /// ✅ ID “humano” (solo para UI/logs/args); si viene vacío, queda vacío.
  static String normalizeInstId(String instId) => _normHuman(instId, '');

  /// ✅ ID KEY-SAFE para locks/prefs: si viene vacío, queda vacío (caller decide abort).
  static String normalizeInstIdForLocks(String instId) {
    final h = _normHuman(instId, '');
    if (h.isEmpty) return '';
    return _normKey(h, '');
  }

  /// Legacy: wp_1
  /// Nuevo:  wp_(actividadKeySafe)_(n)
  static String normalizeProfileId(String profileId) =>
      _normHuman(profileId, 'wp_1');

  static String normalizeProfileName(String profileName, String fallback) =>
      _normHuman(profileName, fallback);

  // =====================================================
  // ✅ COMPAT: wp_1 -> wp_(actividadKeySafe)_1
  // =====================================================

  static int? _extractLegacyWpIndex(String pidHuman) {
    final t = pidHuman.trim().toLowerCase();
    final m = RegExp(r'^wp_(\d+)$').firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  static ({String act, int n})? _extractScopedWp(String pidHuman) {
    final t = pidHuman.trim().toLowerCase();
    final m = RegExp(r'^wp_([a-z0-9_\-\.]+)_(\d+)$').firstMatch(t);
    if (m == null) return null;
    final act = (m.group(1) ?? '').trim();
    final n = int.tryParse((m.group(2) ?? '').trim());
    if (act.isEmpty || n == null || n <= 0) return null;
    return (act: act, n: n);
  }

  static bool _isScopedWp(String pidHuman) =>
      _extractScopedWp(pidHuman) != null;

  /// Normaliza profileId teniendo en cuenta actividadKey.
  /// - Si viene wp_1 (legacy): lo scopea por actividadKey => wp_(actSafe)_1
  /// - Si ya viene scopeado:
  ///     * si es de la misma actividad: se deja (key-safe)
  ///     * si es de otra actividad: se RE-scopea al actSafe actual manteniendo el índice
  /// - Si viene vacío: fallback al perfil 1 scopeado por actividad.
  static String normalizeProfileIdForActividad({
    required String profileId,
    required String actividadKey,
  }) {
    final actSafe = _normKey(actividadKey, 'actividad_default');

    final pidHuman = _normHuman(profileId, '');
    if (pidHuman.isEmpty) {
      return 'wp_${actSafe}_1';
    }

    final scoped = _extractScopedWp(pidHuman);
    if (scoped != null) {
      if (scoped.act != actSafe) {
        return 'wp_${actSafe}_${scoped.n}';
      }
      return 'wp_${actSafe}_${scoped.n}';
    }

    final legacyN = _extractLegacyWpIndex(pidHuman);
    if (legacyN != null && legacyN > 0) {
      return 'wp_${actSafe}_$legacyN';
    }

    final safe = _normKey(pidHuman, 'wp_${actSafe}_1').trim();
    if (safe.isEmpty) return 'wp_${actSafe}_1';

    if (!safe.startsWith('wp_')) return 'wp_${actSafe}_1';
    if (!_isScopedWp(safe)) return 'wp_${actSafe}_1';

    return safe;
  }

  // v2: scoping por actividad (KEY SAFE)
  // ✅ Contrato: recibir instId DATA/humano; acá lo convertimos a KEY-SAFE.
  static String lockKey(
    String instId,
    String actividadKey,
    InstitucionAreaKey area,
  ) {
    final i = normalizeInstIdForLocks(instId);
    final a = _normKey(actividadKey, 'actividad_default');
    final ii = i.isEmpty ? 'inst' : i;
    return 'inst_area_lock_v2_${ii}_${a}_${_areaKeyName(area)}';
  }

  // v1 compat
  static String _lockKeyV1(String instId, InstitucionAreaKey area) {
    final i = normalizeInstIdForLocks(instId);
    final ii = i.isEmpty ? 'inst' : i;
    return 'inst_area_lock_v1_${ii}_${_areaKeyName(area)}';
  }

  static int? _intAny(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  static Future<Map<String, dynamic>?> _readLockObj(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = (await _PrefsSafe.getString(prefs, key)) ?? '';
    if (raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await _PrefsSafe.remove(prefs, key);
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      await _PrefsSafe.remove(prefs, key);
      return null;
    }
  }

  static Future<InstitucionAreaLockStatus> _statusFromObj({
    required SharedPreferences prefs,
    required String key,
    required String deviceId,
    required Map<String, dynamic> obj,
  }) async {
    final lockDeviceId = (obj['deviceId'] ?? '').toString().trim();
    final lockProfileId = (obj['profileId'] ?? '').toString().trim();
    final lockProfileName = (obj['profileName'] ?? '').toString().trim();
    final expiresAtMs = _intAny(obj['expiresAtMs']);

    if (expiresAtMs == null) {
      await _PrefsSafe.remove(prefs, key);
      return _freeStatus;
    }

    final exp = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
    if (DateTime.now().isAfter(exp)) {
      await _PrefsSafe.remove(prefs, key);
      return _freeStatus;
    }

    final isMine = lockDeviceId == deviceId;

    return InstitucionAreaLockStatus(
      locked: true,
      mine: isMine,
      deviceId: lockDeviceId.isEmpty ? null : lockDeviceId,
      profileId: lockProfileId.isEmpty ? null : lockProfileId,
      profileName: lockProfileName.isEmpty ? null : lockProfileName,
      expiresAt: exp,
    );
  }

  // =====================================================
  // ✅ API ESTABLE (perdura): getStatusStable / getStatus
  // =====================================================

  static Future<InstitucionAreaLockStatus> getStatusStable({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
    String? deviceId,
    bool mine = false,
  }) async {
    try {
      final prefs = await _PrefsSafe.get();

      // ✅ FIX: evitar `.trim()` sobre nullable (analyzer strict).
      final providedDeviceId = (deviceId ?? '').trim();
      final did = providedDeviceId.isNotEmpty
          ? providedDeviceId
          : await AtenaDeviceId.getOrCreate();

      // v2 primero (canónico)
      final k = lockKey(instId, actividadKey, area);
      final obj = await _readLockObj(prefs, k);
      if (obj != null) {
        final st = await _statusFromObj(
          prefs: prefs,
          key: k,
          deviceId: did,
          obj: obj,
        );
        if (mine && st.locked && !st.mine) return _freeStatus;
        return st;
      }

      // v1 compat (solo lectura)
      final k1 = _lockKeyV1(instId, area);
      final obj1 = await _readLockObj(prefs, k1);
      if (obj1 != null) {
        final st = await _statusFromObj(
          prefs: prefs,
          key: k1,
          deviceId: did,
          obj: obj1,
        );
        if (mine && st.locked && !st.mine) return _freeStatus;
        return st;
      }

      return _freeStatus;
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][getStatusStable][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
      return _freeStatus;
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][getStatusStable][ERROR] $e\n$st');
      return _freeStatus;
    }
  }

  static Future<InstitucionAreaLockStatus> getStatus({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
    String? deviceId,
    bool mine = false,
  }) {
    return getStatusStable(
      instId: instId,
      actividadKey: actividadKey,
      area: area,
      deviceId: deviceId,
      mine: mine,
    );
  }

  static Future<bool> tryAcquire({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
    required String profileId,
    required String profileName,
  }) async {
    try {
      // ✅ Evitar locks compartidos (“inst”) por instId vacío.
      if (normalizeInstIdForLocks(instId).isEmpty) return false;

      // ✅ Scope SIEMPRE se calcula dentro del service (caller pasa raw o scope).
      final actScope = normalizeActividadKeyForScope(actividadKey);
      if (actScope.isEmpty) return false;

      final prefs = await _PrefsSafe.get();
      final deviceId = await AtenaDeviceId.getOrCreate();

      // ✅ AJUSTE: normalizeProfileIdForActividad recibe el RAW original.
      final pid = normalizeProfileIdForActividad(
        profileId: profileId,
        actividadKey: actividadKey, // <- RAW (no actScope)
      );
      final pname = normalizeProfileName(profileName, pid);

      // ✅ Guardar “human”
      final actKeyHuman = normalizeActividadKey(actividadKey);

      final k2 = lockKey(instId, actScope, area);
      final k1 = _lockKeyV1(instId, area);

      // 1) Chequear v2
      final obj2 = await _readLockObj(prefs, k2);
      if (obj2 != null) {
        final st2 = await _statusFromObj(
          prefs: prefs,
          key: k2,
          deviceId: deviceId,
          obj: obj2,
        );

        if (st2.locked && !st2.mine) {
          return false;
        }

        if (st2.locked && st2.mine && (st2.profileId ?? '') != pid) {
          debugPrint(
            '[ATENA][LOCKS][tryAcquire] auto-clear v2 mine mismatch: '
            'oldPid=${st2.profileId} newPid=$pid instId=$instId act=$actScope area=${_areaKeyName(area)}',
          );
          await _PrefsSafe.remove(prefs, k2);
        }
      }

      // 2) Chequear v1 compat
      final obj1 = await _readLockObj(prefs, k1);
      if (obj1 != null) {
        final lockDeviceId = (obj1['deviceId'] ?? '').toString().trim();
        final lockProfileId = (obj1['profileId'] ?? '').toString().trim();
        final expiresAtMs = _intAny(obj1['expiresAtMs']);
        final exp = expiresAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(expiresAtMs);

        final isExpired = exp != null && DateTime.now().isAfter(exp);
        if (isExpired) {
          await _PrefsSafe.remove(prefs, k1);
        } else {
          final mineV1 = lockDeviceId == deviceId;

          if (mineV1 && lockProfileId.isNotEmpty && lockProfileId != pid) {
            debugPrint(
              '[ATENA][LOCKS][tryAcquire] auto-clear v1 mine mismatch: '
              'oldPid=$lockProfileId newPid=$pid instId=$instId area=${_areaKeyName(area)}',
            );
            await _PrefsSafe.remove(prefs, k1);
          } else {
            if (!mineV1) {
              return false;
            }
          }
        }
      }

      // 3) Escribir v2
      final exp = DateTime.now().add(ttl);

      final obj = <String, dynamic>{
        'deviceId': deviceId,
        'profileId': pid,
        'profileName': pname,
        'actividadKey': actKeyHuman,
        'area': _areaKeyName(area),
        'expiresAtMs': exp.millisecondsSinceEpoch,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        'v': 2,
      };

      await _PrefsSafe.setString(prefs, k2, jsonEncode(obj));

      // Re-check best-effort
      try {
        final obj2b = await _readLockObj(prefs, k2);
        if (obj2b == null) return false;
        final lockDeviceId = (obj2b['deviceId'] ?? '').toString().trim();
        final lockProfileId = (obj2b['profileId'] ?? '').toString().trim();
        final ok = lockDeviceId == deviceId && lockProfileId == pid;
        if (!ok) return false;
      } catch (_) {
        // ok
      }

      return true;
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][tryAcquire][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
      return false;
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][tryAcquire][ERROR] $e\n$st');
      return false;
    }
  }

  static Future<void> refresh({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
    required String profileId,
    required String profileName,
  }) async {
    try {
      if (normalizeInstIdForLocks(instId).isEmpty) return;

      final prefs = await _PrefsSafe.get();
      final deviceId = await AtenaDeviceId.getOrCreate();

      // ✅ Scope SIEMPRE se calcula dentro del service.
      final actScope = normalizeActividadKeyForScope(actividadKey);
      if (actScope.isEmpty) return;

      final st = await getStatusStable(
        instId: instId,
        actividadKey: actScope,
        area: area,
        deviceId: deviceId,
        mine: true,
      );

      if (!st.locked) return;
      if (!st.mine) return;

      final pid = normalizeProfileIdForActividad(
        profileId: profileId,
        actividadKey: actScope,
      );
      final pname = normalizeProfileName(profileName, pid);

      if ((st.profileId ?? '') != pid) return;

      final k2 = lockKey(instId, actScope, area);
      final existing = await _readLockObj(prefs, k2);
      if (existing == null) return;

      final v = _intAny(existing['v']) ?? 2;
      if (v != 2) return;

      final exp = DateTime.now().add(ttl);

      final obj = <String, dynamic>{...existing};
      obj['deviceId'] = deviceId;
      obj['profileId'] = pid;
      obj['profileName'] = pname;
      obj['actividadKey'] = normalizeActividadKey(actividadKey);
      obj['area'] = _areaKeyName(area);
      obj['expiresAtMs'] = exp.millisecondsSinceEpoch;
      obj['updatedAtMs'] = DateTime.now().millisecondsSinceEpoch;
      obj['v'] = 2;

      await _PrefsSafe.setString(prefs, k2, jsonEncode(obj));
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][refresh][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][refresh][ERROR] $e\n$st');
    }
  }

  static Future<void> release({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
    required String profileId,
  }) async {
    try {
      if (normalizeInstIdForLocks(instId).isEmpty) return;

      final prefs = await _PrefsSafe.get();
      final deviceId = await AtenaDeviceId.getOrCreate();

      // ✅ Scope SIEMPRE se calcula dentro del service.
      final actScope = normalizeActividadKeyForScope(actividadKey);
      if (actScope.isEmpty) {
        // En release, si no hay actividad, limpiamos v1 si es mío.
        final k1 = _lockKeyV1(instId, area);
        final obj1 = await _readLockObj(prefs, k1);
        if (obj1 != null) {
          final lockDeviceId = (obj1['deviceId'] ?? '').toString().trim();
          if (lockDeviceId == deviceId) {
            await _PrefsSafe.remove(prefs, k1);
          }
        }
        return;
      }

      final pid = normalizeProfileIdForActividad(
        profileId: profileId,
        actividadKey: actScope,
      );

      // v2: remover si es mío
      final k2 = lockKey(instId, actScope, area);
      final obj2 = await _readLockObj(prefs, k2);
      if (obj2 != null) {
        final lockDeviceId = (obj2['deviceId'] ?? '').toString().trim();
        final lockProfileId = (obj2['profileId'] ?? '').toString().trim();
        final mineDevice = lockDeviceId == deviceId;

        if (mineDevice) {
          if (lockProfileId.isNotEmpty && lockProfileId != pid) {
            debugPrint(
              '[ATENA][LOCKS][release] v2 mine pid mismatch (auto-remove): oldPid=$lockProfileId newPid=$pid '
              'instId=$instId act=$actScope area=${_areaKeyName(area)}',
            );
          }
          await _PrefsSafe.remove(prefs, k2);
        }
      }

      // v1 compat: limpieza si el deviceId coincide (sin exigir profileId exacto)
      final k1 = _lockKeyV1(instId, area);
      final obj1 = await _readLockObj(prefs, k1);
      if (obj1 != null) {
        final lockDeviceId = (obj1['deviceId'] ?? '').toString().trim();
        if (lockDeviceId == deviceId) {
          await _PrefsSafe.remove(prefs, k1);
        }
      }
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][release][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][release][ERROR] $e\n$st');
    }
  }

  static Future<Map<String, dynamic>?> dump({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
  }) async {
    try {
      final prefs = await _PrefsSafe.get();

      final actScope = normalizeActividadKeyForScope(actividadKey);

      final raw2 =
          (await _PrefsSafe.getString(
            prefs,
            lockKey(instId, actScope, area),
          )) ??
          '';
      if (raw2.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw2);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }

      final raw1 =
          (await _PrefsSafe.getString(prefs, _lockKeyV1(instId, area))) ?? '';
      if (raw1.trim().isEmpty) return null;

      try {
        final decoded = jsonDecode(raw1);
        if (decoded is! Map) return null;
        return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][dump][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
      return null;
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][dump][ERROR] $e\n$st');
      return null;
    }
  }

  static Future<void> forceClear({
    required String instId,
    required String actividadKey,
    required InstitucionAreaKey area,
  }) async {
    try {
      final prefs = await _PrefsSafe.get();
      final actScope = normalizeActividadKeyForScope(actividadKey);
      await _PrefsSafe.remove(prefs, lockKey(instId, actScope, area));
      await _PrefsSafe.remove(prefs, _lockKeyV1(instId, area));
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][LOCKS][forceClear][TIMEOUT] instId=$instId act=$actividadKey area=${_areaKeyName(area)}',
      );
    } catch (e, st) {
      debugPrint('[ATENA][LOCKS][forceClear][ERROR] $e\n$st');
    }
  }
}

// =====================================================
// GUARD: abrir una sección con lock por área (reusable)
// =====================================================

class InstitucionAreaGuard {
  static void _fireAndForget(Future<void> f) {
    // ignore: discarded_futures
    f.then((_) {}).catchError((_) {});
  }

  static Future<bool> openWithAreaLock({
    required BuildContext context,
    required String instId,

    // Extras canónicos (RouteSettings.args)
    Object? institucion,
    String? institucionNombre,

    // ✅ CANÓNICO: nombre de perfil requerido por UI
    required String profileName,

    required String actividadKey,
    required String profileId,
    required InstitucionAreaKey area,
    required WidgetBuilder builder,

    // Refresh lock
    bool enableAutoRefresh = false,
    Duration refreshEvery = const Duration(seconds: 20),

    // ✅ NUEVO (compat): más contexto para pantallas que leen args
    String? ownerAccountId,
    String? actividadLabel,
    String? workProfileId,
    String? workProfileName,
  }) async {
    final nav = Navigator.of(context);

    final instIdData = instId.trim();
    final actKeyRaw = actividadKey.trim();

    if (instIdData.isEmpty) {
      debugPrint('[ATENA][GUARD] abort: empty instId (DATA)');
      return false;
    }
    if (actKeyRaw.isEmpty) {
      debugPrint('[ATENA][GUARD] abort: empty actividadKey');
      return false;
    }

    // ✅ Para locks/rutas: scope key-safe estable.
    final actKeyScope =
        InstitucionAreaLockService.normalizeActividadKeyForScope(actKeyRaw);
    if (actKeyScope.trim().isEmpty) {
      debugPrint(
        '[ATENA][GUARD] abort: empty actividadKey scope (from "$actKeyRaw")',
      );
      return false;
    }

    final resolvedProfileName = profileName.trim().isNotEmpty
        ? profileName.trim()
        : profileId;

    // ✅ Scopear profileId por actividad (estable).
    final resolvedProfileId =
        InstitucionAreaLockService.normalizeProfileIdForActividad(
          profileId: profileId,
          actividadKey: actKeyScope,
        );

    // ✅ Aliases “work profile” (sin non-null assertion)
    final wpIdRaw = workProfileId?.trim() ?? '';
    final wpNameRaw = workProfileName?.trim() ?? '';

    final wpId = wpIdRaw.isNotEmpty ? wpIdRaw : resolvedProfileId;
    final wpName = wpNameRaw.isNotEmpty ? wpNameRaw : resolvedProfileName;

    // ✅ Normalizamos opcionales UNA sola vez (evita `!` y warnings).
    final actLabel = (actividadLabel ?? '').trim();
    final ownerIdArg = (ownerAccountId ?? '').trim();
    final instNombreArg = (institucionNombre ?? '').trim();

    // ✅ Validación anti “inst compartido”.
    final instIdForLocks = InstitucionAreaLockService.normalizeInstIdForLocks(
      instIdData,
    );
    if (instIdForLocks.trim().isEmpty) {
      debugPrint(
        '[ATENA][GUARD] abort: empty instIdForLocks (from "$instIdData")',
      );
      return false;
    }

    debugPrint(
      '[ATENA][GUARD] acquire instIdData=$instIdData instIdForLocks=$instIdForLocks '
      'actRaw=$actKeyRaw actScope=$actKeyScope area=${_areaKeyName(area)} '
      'pid=$resolvedProfileId pname=$resolvedProfileName wpId=$wpId wpName=$wpName',
    );

    bool acquired = false;
    try {
      // ✅ IMPORTANTE: al service le pasamos actKeyRaw (contrato más claro).
      acquired = await InstitucionAreaLockService.tryAcquire(
        instId: instIdData,
        actividadKey: actKeyRaw,
        area: area,
        profileId: resolvedProfileId,
        profileName: resolvedProfileName,
      ).timeout(const Duration(seconds: 3));
    } on TimeoutException catch (_) {
      debugPrint(
        '[ATENA][GUARD] acquire TIMEOUT instIdData=$instIdData act=$actKeyScope area=${_areaKeyName(area)}',
      );
      acquired = false;
    } catch (e, st) {
      debugPrint('[ATENA][GUARD] acquire ERROR $e\n$st');
      acquired = false;
    }

    if (!acquired) {
      debugPrint('[ATENA][GUARD] acquire FAILED area=${_areaKeyName(area)}');
      return false;
    }

    Timer? t;

    Future<void> safeRefresh() async {
      try {
        await InstitucionAreaLockService.refresh(
          instId: instIdData,
          actividadKey: actKeyRaw,
          area: area,
          profileId: resolvedProfileId,
          profileName: resolvedProfileName,
        );
      } catch (_) {}
    }

    if (enableAutoRefresh) {
      _fireAndForget(safeRefresh());
      if (refreshEvery > Duration.zero) {
        t = Timer.periodic(refreshEvery, (_) => _fireAndForget(safeRefresh()));
      }
    }

    try {
      await nav.push(
        MaterialPageRoute(
          builder: builder,
          settings: RouteSettings(
            arguments: <String, Object?>{
              // IDs base
              'instId': instIdData,
              'institucionId': instIdData,

              // Scope estable
              'actividadKey': actKeyScope,
              if (actLabel.isNotEmpty) 'actividadLabel': actLabel,

              // Área / perfil
              'area': _areaKeyName(area),
              'profileId': resolvedProfileId,
              'profileName': resolvedProfileName,

              // Work-profile aliases (para pantallas que separan profile vs workProfile)
              'workProfileId': wpId,
              'workProfileName': wpName,

              // Owner (backend-ready)
              if (ownerIdArg.isNotEmpty) 'ownerAccountId': ownerIdArg,

              // Institución extra
              if (institucion != null) 'institucion': institucion,
              if (instNombreArg.isNotEmpty) ...{
                'institucionNombre': instNombreArg,
                // alias frecuente en pantallas
                'institucionName': instNombreArg,
              },
            },
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('[ATENA][GUARD][PUSH-ERROR] $e\n$st');
    } finally {
      t?.cancel();

      try {
        await InstitucionAreaLockService.release(
          instId: instIdData,
          actividadKey: actKeyRaw,
          area: area,
          profileId: resolvedProfileId,
        ).timeout(const Duration(seconds: 2));
      } on TimeoutException catch (_) {
        debugPrint(
          '[ATENA][GUARD] release TIMEOUT instIdData=$instIdData act=$actKeyScope area=${_areaKeyName(area)}',
        );
      } catch (e, st) {
        debugPrint('[ATENA][GUARD] release ERROR $e\n$st');
      }
    }

    return true;
  }
}
