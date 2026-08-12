// lib/services/storage_service.dart
//
// ATENA – STORAGE SERVICE
// Persistencia local canónica para Web + Mobile.
//
// SharedPreferences es la fuente de verdad persistente.
// El caché en memoria solo sirve como fallback durante la ejecución actual.
// Una escritura NO se considera exitosa si solo quedó en RAM.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsInit;
  final Map<String, Object?> _mem = <String, Object?>{};

  static const Duration _kPrefsInitTimeout = Duration(seconds: 5);
  static const Duration _kOpTimeout = Duration(seconds: 5);

  static String _s(dynamic v) => (v ?? '').toString().trim();

  static String _k(String key) {
    final kk = key.trim();
    if (kk.isEmpty) return '';
    return kk.replaceAll(RegExp(r'\s+'), '');
  }

  T _logAnd<T>(String tag, T fallback, Object e, StackTrace st) {
    debugPrint('[ATENA][StorageService][ERROR] $tag: $e\n$st');
    return fallback;
  }

  void _logTimeout(String tag) {
    debugPrint('[ATENA][StorageService][TIMEOUT] $tag');
  }

  Future<SharedPreferences?> _getPrefsSafe() async {
    final current = _prefs;
    if (current != null) return current;

    final inflight = _prefsInit;
    if (inflight != null) {
      try {
        final p = await inflight.timeout(_kPrefsInitTimeout);
        _prefs = p;
        return p;
      } catch (e, st) {
        _prefsInit = null;
        if (e is TimeoutException) {
          _logTimeout('prefs init inflight');
        } else {
          debugPrint('[ATENA][StorageService][ERROR] prefs init inflight: $e\n$st');
        }
        return null;
      }
    }

    late final Future<SharedPreferences> future;
    try {
      future = SharedPreferences.getInstance();
    } catch (e, st) {
      debugPrint('[ATENA][StorageService][ERROR] getInstance(): $e\n$st');
      return null;
    }

    _prefsInit = future;
    try {
      final p = await future.timeout(_kPrefsInitTimeout);
      _prefs = p;
      return p;
    } catch (e, st) {
      _prefsInit = null;
      if (e is TimeoutException) {
        _logTimeout('prefs init');
      } else {
        debugPrint('[ATENA][StorageService][ERROR] prefs init: $e\n$st');
      }
      return null;
    }
  }

  Future<Set<String>> getKeys() async {
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mem.keys.toSet();
      return prefs.getKeys().map(_k).where((e) => e.isNotEmpty).toSet();
    } on TimeoutException {
      _logTimeout('getKeys');
      return _mem.keys.toSet();
    } catch (e, st) {
      return _logAnd('getKeys', _mem.keys.toSet(), e, st);
    }
  }

  Future<String?> getString(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        final v = _mem[k];
        return v is String ? v : null;
      }
      final v = prefs.getString(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      _logTimeout('getString($k)');
      final v = _mem[k];
      return v is String ? v : null;
    } catch (e, st) {
      final v = _mem[k];
      if (v is String) return v;
      return _logAnd('getString($k)', null, e, st);
    }
  }

  Future<bool> setString(String key, String value) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        _mem[k] = value;
        debugPrint('[ATENA][StorageService][PERSISTENCE_FAILED] setString($k): prefs unavailable');
        return false;
      }
      final written = await prefs.setString(k, value).timeout(_kOpTimeout);
      final persisted = prefs.getString(k);
      if (!written || persisted != value) {
        _mem[k] = value;
        debugPrint('[ATENA][StorageService][PERSISTENCE_FAILED] setString($k)');
        return false;
      }
      _mem[k] = value;
      return true;
    } on TimeoutException {
      _logTimeout('setString($k)');
      _mem[k] = value;
      return false;
    } catch (e, st) {
      _mem[k] = value;
      return _logAnd('setString($k)', false, e, st);
    }
  }

  Future<List<String>> getStringList(String key) async {
    final k = _k(key);
    if (k.isEmpty) return <String>[];
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        final v = _mem[k];
        return v is List ? v.map((e) => e.toString()).toList() : <String>[];
      }
      final v = prefs.getStringList(k) ?? <String>[];
      _mem[k] = List<String>.from(v);
      return v;
    } on TimeoutException {
      _logTimeout('getStringList($k)');
      final v = _mem[k];
      return v is List ? v.map((e) => e.toString()).toList() : <String>[];
    } catch (e, st) {
      return _logAnd('getStringList($k)', <String>[], e, st);
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    final safe = List<String>.from(value);
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        _mem[k] = safe;
        debugPrint('[ATENA][StorageService][PERSISTENCE_FAILED] setStringList($k): prefs unavailable');
        return false;
      }
      final written = await prefs.setStringList(k, safe).timeout(_kOpTimeout);
      final persisted = prefs.getStringList(k);
      if (!written || persisted == null || !_sameStrings(persisted, safe)) {
        _mem[k] = safe;
        debugPrint('[ATENA][StorageService][PERSISTENCE_FAILED] setStringList($k)');
        return false;
      }
      _mem[k] = safe;
      return true;
    } on TimeoutException {
      _logTimeout('setStringList($k)');
      _mem[k] = safe;
      return false;
    } catch (e, st) {
      _mem[k] = safe;
      return _logAnd('setStringList($k)', false, e, st);
    }
  }

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final sanitized = _sanitizeJsonValue(value);
      if (sanitized is! Map) return false;
      return await setString(key, jsonEncode(sanitized));
    } catch (e, st) {
      return _logAnd('setJson(${_k(key)})', false, e, st);
    }
  }

  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    final k = _k(key);
    if (k.isEmpty) return <Map<String, dynamic>>[];
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mapList(_mem[k]);

      final raw = prefs.getString(k);
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final out = _mapList(decoded);
            _mem[k] = out;
            return out;
          }
          if (decoded is Map) {
            final out = <Map<String, dynamic>>[Map<String, dynamic>.from(decoded)];
            _mem[k] = out;
            return out;
          }
        } catch (_) {}
      }

      final legacy = prefs.getStringList(k);
      if (legacy == null || legacy.isEmpty) return <Map<String, dynamic>>[];
      final out = <Map<String, dynamic>>[];
      for (final item in legacy) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
        } catch (_) {}
      }
      _mem[k] = out;
      return out;
    } on TimeoutException {
      _logTimeout('getJsonList($k)');
      return _mapList(_mem[k]);
    } catch (e, st) {
      return _logAnd('getJsonList($k)', <Map<String, dynamic>>[], e, st);
    }
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map) {
        try {
          out.add(Map<String, dynamic>.from(item));
        } catch (_) {}
      } else if (item is String && item.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
        } catch (_) {}
      }
    }
    return out;
  }

  Future<bool> setJsonList(
    String key,
    List<Map<String, dynamic>> value, {
    bool sortStable = false,
  }) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final sanitized = <Map<String, dynamic>>[];
      for (final item in value) {
        final clean = _sanitizeJsonValue(item);
        if (clean is Map) sanitized.add(Map<String, dynamic>.from(clean));
      }
      if (sortStable && sanitized.length > 1) {
        sanitized.sort((a, b) {
          final c = _s(a['id']).compareTo(_s(b['id']));
          return c != 0 ? c : jsonEncode(a).compareTo(jsonEncode(b));
        });
      }
      return await setString(k, jsonEncode(sanitized));
    } catch (e, st) {
      return _logAnd('setJsonList($k)', false, e, st);
    }
  }

  Future<int?> getInt(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mem[k] is int ? _mem[k] as int : null;
      final v = prefs.getInt(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      _logTimeout('getInt($k)');
      return _mem[k] is int ? _mem[k] as int : null;
    } catch (e, st) {
      return _logAnd('getInt($k)', null, e, st);
    }
  }

  Future<bool> setInt(String key, int value) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        _mem[k] = value;
        return false;
      }
      final written = await prefs.setInt(k, value).timeout(_kOpTimeout);
      if (!written || prefs.getInt(k) != value) {
        _mem[k] = value;
        return false;
      }
      _mem[k] = value;
      return true;
    } on TimeoutException {
      _logTimeout('setInt($k)');
      _mem[k] = value;
      return false;
    } catch (e, st) {
      _mem[k] = value;
      return _logAnd('setInt($k)', false, e, st);
    }
  }

  Future<bool?> getBool(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mem[k] is bool ? _mem[k] as bool : null;
      final v = prefs.getBool(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      _logTimeout('getBool($k)');
      return _mem[k] is bool ? _mem[k] as bool : null;
    } catch (e, st) {
      return _logAnd('getBool($k)', null, e, st);
    }
  }

  Future<bool> setBool(String key, bool value) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        _mem[k] = value;
        return false;
      }
      final written = await prefs.setBool(k, value).timeout(_kOpTimeout);
      if (!written || prefs.getBool(k) != value) {
        _mem[k] = value;
        return false;
      }
      _mem[k] = value;
      return true;
    } on TimeoutException {
      _logTimeout('setBool($k)');
      _mem[k] = value;
      return false;
    } catch (e, st) {
      _mem[k] = value;
      return _logAnd('setBool($k)', false, e, st);
    }
  }

  Future<double?> getDouble(String key) async {
    final k = _k(key);
    if (k.isEmpty) return null;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mem[k] is double ? _mem[k] as double : null;
      final v = prefs.getDouble(k);
      if (v != null) _mem[k] = v;
      return v;
    } on TimeoutException {
      _logTimeout('getDouble($k)');
      return _mem[k] is double ? _mem[k] as double : null;
    } catch (e, st) {
      return _logAnd('getDouble($k)', null, e, st);
    }
  }

  Future<bool> setDouble(String key, double value) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) {
        _mem[k] = value;
        return false;
      }
      final written = await prefs.setDouble(k, value).timeout(_kOpTimeout);
      if (!written || prefs.getDouble(k) != value) {
        _mem[k] = value;
        return false;
      }
      _mem[k] = value;
      return true;
    } on TimeoutException {
      _logTimeout('setDouble($k)');
      _mem[k] = value;
      return false;
    } catch (e, st) {
      _mem[k] = value;
      return _logAnd('setDouble($k)', false, e, st);
    }
  }

  Future<bool> remove(String key) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return false;
      final removed = await prefs.remove(k).timeout(_kOpTimeout);
      if (!removed && prefs.containsKey(k)) return false;
      if (prefs.containsKey(k)) return false;
      _mem.remove(k);
      return true;
    } on TimeoutException {
      _logTimeout('remove($k)');
      return false;
    } catch (e, st) {
      return _logAnd('remove($k)', false, e, st);
    }
  }

  Future<bool> containsKey(String key) async {
    final k = _k(key);
    if (k.isEmpty) return false;
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return _mem.containsKey(k);
      return prefs.containsKey(k);
    } on TimeoutException {
      _logTimeout('containsKey($k)');
      return _mem.containsKey(k);
    } catch (e, st) {
      return _logAnd('containsKey($k)', _mem.containsKey(k), e, st);
    }
  }

  Future<bool> clearAll() async {
    try {
      final prefs = await _getPrefsSafe().timeout(_kOpTimeout);
      if (prefs == null) return false;
      final cleared = await prefs.clear().timeout(_kOpTimeout);
      if (!cleared || prefs.getKeys().isNotEmpty) return false;
      _mem.clear();
      return true;
    } on TimeoutException {
      _logTimeout('clearAll');
      return false;
    } catch (e, st) {
      return _logAnd('clearAll', false, e, st);
    }
  }

  void resetCache() {
    _prefs = null;
    _prefsInit = null;
    _mem.clear();
  }

  static dynamic _sanitizeJsonValue(dynamic value, [Set<int>? seen]) {
    seen ??= <int>{};
    if (value == null || value is String || value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();
    final identity = value.hashCode;
    if (seen.contains(identity)) return value.toString();
    final nextSeen = Set<int>.from(seen)..add(identity);
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        final key = _s(k);
        if (key.isNotEmpty) out[key] = _sanitizeJsonValue(v, nextSeen);
      });
      return out;
    }
    if (value is List) {
      return value.map((v) => _sanitizeJsonValue(v, nextSeen)).toList();
    }
    return value.toString();
  }
}
