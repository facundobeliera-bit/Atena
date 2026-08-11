// lib/services/storage_service.dart
//
// Wrapper liviano sobre SharedPreferences.
// WEB + MOBILE SAFE
//
// HARDENING (enero 2026):
// - Normaliza keys (trim) para evitar espacios accidentales.
// - Best-effort: TODAS las operaciones capturan excepciones y devuelven fallback seguro.
// - setJsonList: siempre guarda String JSON único (web-safe) y evita tipos mixtos.
// - getJsonList: tolera listas mixtas (Map o String JSON) y filtra entradas corruptas.
// - Sanitización robusta: evita exceptions al sanear keys/valores.
//
// AJUSTES APLICADOS AHORA (FASE 2):
// - getKeys(): devuelve Set<String> normalizado (trim) y sin vacíos.
// - _k(): elimina saltos de línea/whitespace interno accidental en keys (estabiliza índices).
// - setJsonList(): permite optional sort estable (por id/fecha) sin imponerlo por defecto.
//   (NO cambia el orden existente si no se pide).
// - getJsonList(): si el String guardado no es List pero es Map, devuelve [Map] (compat extra).
// - Sanitizer: evita recursión infinita por estructuras cíclicas (best-effort).
//
// ✅ EXTRA FIX (feb 2026):
// - TIMEOUTS internos (anti “await infinito” en web/prefs):
//   _getPrefs() y TODAS las operaciones de I/O tienen timeout corto.
// - Fallback de memoria (in-memory) best-effort:
//   si SharedPreferences falla/cuelga, la app sigue operando con valores en RAM.
//   (Esto evita spinners infinitos por lecturas que nunca vuelven).
// - Logs de diagnóstico (debugPrint) cuando hay timeout/error.
//
// ✅ FIX CRÍTICO (feb 2026):
// - Evita “pref init hang” permanente:
//   Si un _prefsInit (Future inflight) timeoutea o falla, se libera _prefsInit=null
//   para permitir reintentos posteriores (si no, quedaba pegado para siempre).
//
// ✅ FIX (feb 2026 · best-effort real):
// - Las operaciones SET/REMOVE/CLEAR devuelven true si al menos se aplicó el cambio en RAM,
//   aunque SharedPreferences falle/timeoutee. (La app “sigue operando” en memoria).
//
// ✅ FIX EXTRA (feb 2026 · runtime types):
// - En Dart, chequear `v is List<Map<String,dynamic>>` suele FALLAR por type erasure.
//   Se reemplaza por checks robustos: `v is List` + cast/filtrado best-effort.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsInit;

  // Fallback en memoria (best-effort) para evitar bloquear UI cuando prefs se cuelga.
  final Map<String, Object?> _mem = <String, Object?>{};

  // Timeouts internos (cortos, para NO congelar navegación).
  static const Duration _kPrefsInitTimeout = Duration(seconds: 2);
  static const Duration _kOpTimeout = Duration(seconds: 2);

  // -----------------------------
  // Small helpers
  // -----------------------------
  static String _s(dynamic v) => (v ?? '').toString().trim();

  T _logAnd<T>(String tag, T fallback, Object e, StackTrace st) {
    debugPrint('[ATENA][StorageService][ERROR] $tag: $e\n$st');
    return fallback;
  }

  T _logTimeout<T>(String tag, T fallback) {
    debugPrint('[ATENA][StorageService][TIMEOUT] $tag');
    return fallback;
  }

  // -----------------------------
  // Key normalization
  // -----------------------------
  static String _k(String key) {
    final kk = key.trim();
    if (kk.isEmpty) return '';
    // ✅ estabilidad sin espacios (incluye saltos de línea accidentales).
    // ⚠️ Ojo: esto puede colisionar keys si alguien usa espacios como parte del nombre.
    return kk.replaceAll(RegExp(r'\s+'), '');
  }

  // -----------------------------
  // Runtime-safe readers from _mem
  // -----------------------------
  static String? _memString(Object? v) => v is String ? v : null;

  static List<String> _memStringList(Object? v) {
    if (v is List) {
      final out = <String>[];
      for (final e in v) {
        final s = e?.toString();
        if (s != null) out.add(s);
      }
      return out;
    }
    return <String>[];
  }

  static List<Map<String, dynamic>> _memJsonMapList(Object? v) {
    if (v is List) {
      final out = <Map<String, dynamic>>[];
      for (final e in v) {
        if (e is Map) {
          try {
            out.add(Map<String, dynamic>.from(e));
          } catch (_) {}
          continue;
        }
        if (e is String && e.trim().isNotEmpty) {
          try {
            final d = jsonDecode(e);
            if (d is Map) out.add(Map<String, dynamic>.from(d));
          } catch (_) {}
        }
      }
      return out;
    }
    return <Map<String, dynamic>>[];
  }

  // -----------------------------
  // Prefs init (safe)
  // -----------------------------
  Future<SharedPreferences?> _getPrefsSafe() async {
    final current = _prefs;
    if (current != null) return current;

    // Si ya hay inicialización en curso, la reusamos (evita race/múltiples awaits).
    final inflight = _prefsInit;
    if (inflight != null) {
      try {
        final p = await inflight.timeout(_kPrefsInitTimeout);
        _prefs = p;
        return p;
      } on TimeoutException {
        // ✅ FIX: si timeoutea, liberamos para reintentar más adelante.
        debugPrint('[ATENA][StorageService][TIMEOUT] prefs init inflight');
        if (_prefs == null) _prefsInit = null;
        return null;
      } catch (e, st) {
        debugPrint(
          '[ATENA][StorageService][ERROR] prefs init inflight: $e\n$st',
        );
        if (_prefs == null) _prefsInit = null;
        return null;
      }
    }

    // Nuevo intento de init.
    Future<SharedPreferences> future;
    try {
      future = SharedPreferences.getInstance();
    } catch (e, st) {
      debugPrint('[ATENA][StorageService][ERROR] getInstance() threw: $e\n$st');
      _prefsInit = null;
      return null;
    }

    _prefsInit = future;

    try {
      final created = await future.timeout(_kPrefsInitTimeout);
      _prefs = created;
      return created;
    } on TimeoutException {
      debugPrint('[ATENA][StorageService][TIMEOUT] prefs init new');
      _prefsInit = null; // ✅ permitir reintento
      return null;
    } catch (e, st) {
      debugPrint('[ATENA][StorageService][ERROR] prefs init new: $e\n$st');
      _prefsInit = null; // ✅ permitir reintento
      return null;
    }
  }

  // -----------------------------
  // Keys (debug)
  // -----------------------------
  Future<Set<String>> getKeys() async {
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        // Fallback: devolvemos lo que haya en memoria.
        return _mem.keys.toSet();
      }
      final raw = prefs.getKeys();
      final out = <String>{};
      for (final k in raw) {
        final kk = _k(k);
        if (kk.isNotEmpty) out.add(kk);
      }
      return out;
    } on TimeoutException {
      return _mem.keys.toSet();
    } catch (e, st) {
      return _logAnd('getKeys', _mem.keys.toSet(), e, st);
    }
  }

  // -----------------------------
  // String
  // -----------------------------
  Future<String?> getString(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        return _memString(_mem[k]);
      }
      final v = prefs.getString(k);
      // Mirror best-effort en memoria (solo si hay valor).
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      return _memString(_mem[k]);
    } catch (e, st) {
      final memV = _memString(_mem[k]);
      if (memV != null) return memV;
      return _logAnd('getString($k)', null, e, st);
    }
  }

  Future<bool> setString(String key, String value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    // ✅ siempre aplicamos en RAM (best-effort)
    _mem[k] = value;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.setString(k, value).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setString($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setString($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // StringList (legacy support)
  // -----------------------------
  Future<List<String>> getStringList(String key) async {
    final k = _k(key);
    if (k.isEmpty) return <String>[];

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        return _memStringList(_mem[k]);
      }
      final v = prefs.getStringList(k) ?? <String>[];
      _mem[k] = List<String>.from(v);
      return v;
    } on TimeoutException {
      return _memStringList(_mem[k]);
    } catch (e, st) {
      final fallback = _memStringList(_mem[k]);
      if (fallback.isNotEmpty) return fallback;
      return _logAnd('getStringList($k)', <String>[], e, st);
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    // ✅ RAM primero
    _mem[k] = List<String>.from(value);

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.setStringList(k, value).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setStringList($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setStringList($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // JSON (Map) => String
  // -----------------------------
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    try {
      final sanitized = _sanitizeJsonValue(value);
      if (sanitized is! Map) return false;
      // setString ya es best-effort en RAM
      return setString(k, jsonEncode(sanitized));
    } catch (_) {
      return false;
    }
  }

  // -----------------------------
  // JSON LIST  ✅ WEB SAFE + COMPAT
  // -----------------------------

  /// Obtiene una lista de Map guardada como:
  /// 1) JSON String único (preferido, web-safe)
  /// 2) StringList legacy (fallback)
  ///
  /// HARDENING:
  /// - tolera lista mixta: [Map, String(json), ...]
  /// - filtra entradas corruptas sin romper.
  ///
  /// Compat extra:
  /// - si el String JSON contiene Map (no List), devuelve [Map].
  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    final k = _k(key);
    if (k.isEmpty) return <Map<String, dynamic>>[];

    List<Map<String, dynamic>> fromMem() => _memJsonMapList(_mem[k]);

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return fromMem();

      // 1️⃣ Intentar formato nuevo (String JSON)
      final raw = prefs.getString(k);
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);

          if (decoded is List) {
            final out = <Map<String, dynamic>>[];

            for (final e in decoded) {
              if (e is Map) {
                out.add(Map<String, dynamic>.from(e));
                continue;
              }
              if (e is String && e.trim().isNotEmpty) {
                try {
                  final d2 = jsonDecode(e);
                  if (d2 is Map) out.add(Map<String, dynamic>.from(d2));
                } catch (_) {}
              }
            }

            _mem[k] = out;
            return out;
          }

          if (decoded is Map) {
            final out = <Map<String, dynamic>>[
              Map<String, dynamic>.from(decoded),
            ];
            _mem[k] = out;
            return out;
          }
        } catch (_) {
          // continúa a fallback legacy
        }
      }

      // 2️⃣ Fallback legacy: StringList
      final legacy = prefs.getStringList(k);
      if (legacy == null || legacy.isEmpty) return fromMem();

      final out = <Map<String, dynamic>>[];
      for (final s in legacy) {
        final ss = s.trim();
        if (ss.isEmpty) continue;
        try {
          final decoded = jsonDecode(ss);
          if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
        } catch (_) {}
      }

      _mem[k] = out;
      return out;
    } on TimeoutException {
      return fromMem();
    } catch (e, st) {
      final fallback = fromMem();
      if (fallback.isNotEmpty) return fallback;
      return _logAnd('getJsonList($k)', <Map<String, dynamic>>[], e, st);
    }
  }

  /// Guarda SIEMPRE como JSON String único (web-safe).
  ///
  /// Opcional:
  /// - sortStable: si true, ordena de manera estable por `id` y/o `fechaIso/fecha`
  ///   (solo si existen) para reducir ruido de diffs entre ejecuciones.
  Future<bool> setJsonList(
    String key,
    List<Map<String, dynamic>> value, {
    bool sortStable = false,
  }) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    try {
      final sanitized = <Map<String, dynamic>>[];
      for (final m in value) {
        try {
          final s = _sanitizeJsonValue(m);
          if (s is Map) sanitized.add(Map<String, dynamic>.from(s));
        } catch (_) {}
      }

      if (sortStable && sanitized.length > 1) {
        int cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
          final ida = _s(a['id']).replaceAll(RegExp(r'\s+'), '');
          final idb = _s(b['id']).replaceAll(RegExp(r'\s+'), '');
          if (ida.isNotEmpty && idb.isNotEmpty) {
            final c = ida.compareTo(idb);
            if (c != 0) return c;
          }

          DateTime dt(Map<String, dynamic> m) {
            final raw = _s(m['fechaIso']).isNotEmpty
                ? _s(m['fechaIso'])
                : _s(m['fecha']);
            return DateTime.tryParse(raw) ??
                DateTime.fromMillisecondsSinceEpoch(0);
          }

          final da = dt(a);
          final db = dt(b);
          final c2 = da.compareTo(db);
          if (c2 != 0) return c2;

          return jsonEncode(a).compareTo(jsonEncode(b));
        }

        sanitized.sort(cmp);
      }

      // ✅ Mirror memoria siempre (para que lecturas posteriores no bloqueen aunque prefs muera).
      _mem[k] = sanitized;

      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok

      return await prefs
          .setString(k, jsonEncode(sanitized))
          .timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setJsonList($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setJsonList($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // Int
  // -----------------------------
  Future<int?> getInt(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        final v = _mem[k];
        return v is int ? v : null;
      }
      final v = prefs.getInt(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      final v = _mem[k];
      return v is int ? v : null;
    } catch (e, st) {
      final v = _mem[k];
      if (v is int) return v;
      return _logAnd('getInt($k)', null, e, st);
    }
  }

  Future<bool> setInt(String key, int value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    _mem[k] = value;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.setInt(k, value).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setInt($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setInt($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // Bool
  // -----------------------------
  Future<bool?> getBool(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        final v = _mem[k];
        return v is bool ? v : null;
      }
      final v = prefs.getBool(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      final v = _mem[k];
      return v is bool ? v : null;
    } catch (e, st) {
      final v = _mem[k];
      if (v is bool) return v;
      return _logAnd('getBool($k)', null, e, st);
    }
  }

  Future<bool> setBool(String key, bool value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    _mem[k] = value;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.setBool(k, value).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setBool($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setBool($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // Double
  // -----------------------------
  Future<double?> getDouble(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        final v = _mem[k];
        return v is double ? v : null;
      }
      final v = prefs.getDouble(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      final v = _mem[k];
      return v is double ? v : null;
    } catch (e, st) {
      final v = _mem[k];
      if (v is double) return v;
      return _logAnd('getDouble($k)', null, e, st);
    }
  }

  Future<bool> setDouble(String key, double value) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    _mem[k] = value;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.setDouble(k, value).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('setDouble($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('setDouble($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  // -----------------------------
  // Remove / Clear
  // -----------------------------
  Future<bool> remove(String key) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    _mem.remove(k);

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.remove(k).timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('remove($k)', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('remove($k)', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  Future<bool> containsKey(String key) async {
    final k = _k(key);
    if (k.isEmpty) return false;

    // Si lo tenemos en memoria, ya cuenta como existente (best-effort).
    if (_mem.containsKey(k)) return true;

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return false;
      return prefs.containsKey(k);
    } on TimeoutException {
      _logTimeout('containsKey($k)', false);
      return false;
    } catch (e, st) {
      return _logAnd('containsKey($k)', false, e, st);
    }
  }

  Future<bool> clearAll() async {
    _mem.clear();

    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return true; // ✅ RAM ok
      return await prefs.clear().timeout(_kOpTimeout);
    } on TimeoutException {
      _logTimeout('clearAll', false);
      return true; // ✅ RAM ok
    } catch (e, st) {
      _logAnd('clearAll', false, e, st);
      return true; // ✅ RAM ok
    }
  }

  void resetCache() {
    _prefs = null;
    _prefsInit = null;
    _mem.clear();
  }

  // =====================================================
  // JSON SANITIZER (internal)
  // =====================================================

  /// Convierte el objeto a algo JSON-serializable:
  /// - Map: keys a String + sanitize valores
  /// - List: sanitize elementos
  /// - num/bool/String/null: ok
  /// - DateTime: ISO8601
  /// - otros: toString()
  ///
  /// Hardening:
  /// - evita loops por estructuras cíclicas (best-effort).
  ///
  /// ✅ Nota: para cortar ciclos usamos `hashCode` best-effort.
  static dynamic _sanitizeJsonValue(dynamic v, [Set<int>? seen]) {
    seen ??= <int>{};

    if (v == null) return null;
    if (v is String || v is num || v is bool) return v;
    if (v is DateTime) return v.toIso8601String();

    // Best-effort “id” para cortar ciclos.
    final id = v.hashCode;
    if (seen.contains(id)) {
      return v.toString();
    }
    seen.add(id);

    if (v is Map) {
      final out = <String, dynamic>{};
      try {
        v.forEach((k, vv) {
          final kk = _s(k);
          if (kk.isEmpty) return;
          out[kk] = _sanitizeJsonValue(vv, seen);
        });
      } catch (_) {}
      return out;
    }

    if (v is List) {
      try {
        // ✅ clonar seen por rama reduce falsos positivos entre hermanos.
        return v
            .map((e) => _sanitizeJsonValue(e, Set<int>.from(seen!)))
            .toList();
      } catch (_) {
        return <dynamic>[];
      }
    }

    return v.toString();
  }
}
