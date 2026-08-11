// lib/repositories/croquis_repository_prefs.dart
//
// ATENA – CROQUIS REPOSITORY (SharedPreferences)
// Implementación CANÓNICA – NULL SAFE
//
// Fuente de verdad (Opción A):
// - El croquis NO vive embebido en Institucion.
// - Se persiste separado por (institucionId + aula + turnoKey).
//
// Compatibilidad:
// - Mantiene la MISMA clave base que usa la UI V1 (InstitucionCroquisAulaPage):
//   croquis_aula_v1_<instId>_<aula>_<turnoKey>
//
// Índices:
// - croquis_idx_inst_<instId>  -> lista de keys completas del croquis para esa institución
//
// Backend-ready:
// - CroquisAula serializable (toMap/fromMap).
// - Índices rebuildables (best-effort).
//
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/croquis/croquis_aula.dart';

class CroquisRepositoryPrefs {
  // =====================================================
  // Prefix / Index keys
  // =====================================================

  static const String _prefix = 'croquis_aula_v1_';
  static const String _idxPrefix = 'croquis_idx_inst_';

  static String _kIdxInst(String institucionId) =>
      '$_idxPrefix${_kid(institucionId)}';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // =====================================================
  // Utils (sin depender de `unawaited`)
  // =====================================================

  static void _fireAndForget(Future<void> f) {
    // ignore: discarded_futures
    f.then((_) {}).catchError((_) {});
  }

  static String _s(dynamic v) => (v ?? '').toString();

  /// Normaliza "humano": trim + colapso whitespace.
  static String _norm(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return parts.join(' ');
  }

  /// Normaliza ID / tokens para keys e índices (sin espacios).
  static String _kid(dynamic v) {
    final t = _s(v).trim();
    if (t.isEmpty) return '';
    return t.replaceAll(RegExp(r'\s+'), '');
  }

  /// Key-safe: lowercase + underscore + solo [a-z0-9_.-]
  static String _kpart(String v, String fallback) {
    final h = _norm(v);
    if (h.isEmpty) return fallback;
    final s = h
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-\.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return s.isEmpty ? fallback : s;
  }

  // =====================================================
  // Keys (v2 key-safe + v1 compat)
  // =====================================================

  /// ✅ Key canónica actual (key-safe).
  /// Mantiene el mismo prefix y orden de partes.
  static String key({
    required String institucionId,
    required String aula,
    required String turno,
  }) {
    final inst = _kpart(institucionId, 'inst');
    final aulaFinal = _kpart(aula, 'aula');
    final turnoFinal = _kpart(turno, 'turno');

    return '$_prefix$inst'
        '_'
        '$aulaFinal'
        '_'
        '$turnoFinal';
  }

  /// Compat v1: key "humana" (con espacios/acentos potenciales).
  /// Se usa solo para leer/migrar si existiera data previa.
  static String _keyV1Human({
    required String institucionId,
    required String aula,
    required String turno,
  }) {
    final inst = _norm(institucionId);
    final aulaNorm = _norm(aula);
    final turnoNorm = _norm(turno);

    final aulaFinal = aulaNorm.isEmpty ? 'aula' : aulaNorm;
    final turnoFinal = turnoNorm.isEmpty ? 'turno' : turnoNorm;

    return '$_prefix$inst'
        '_'
        '$aulaFinal'
        '_'
        '$turnoFinal';
  }

  // =====================================================
  // Índices (helpers)
  // =====================================================

  static List<String> _getIdx(SharedPreferences p, String key) {
    final raw = p.getStringList(key) ?? const <String>[];
    if (raw.isEmpty) return const <String>[];

    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final v = e.trim();
      if (v.isNotEmpty && seen.add(v)) out.add(v);
    }
    return out;
  }

  static Future<void> _idxAdd(
    SharedPreferences p,
    String key,
    String value,
  ) async {
    final v = value.trim();
    if (v.isEmpty) return;

    final list = _getIdx(p, key);
    if (list.isEmpty) {
      await p.setStringList(key, <String>[v]);
      return;
    }

    if (list.contains(v)) return;

    final next = List<String>.from(list)..add(v);
    await p.setStringList(key, next);
  }

  static Future<void> _idxRemove(
    SharedPreferences p,
    String key,
    String value,
  ) async {
    final v = value.trim();
    if (v.isEmpty) return;

    final list = _getIdx(p, key);
    if (list.isEmpty) return;

    final next = List<String>.from(list)..removeWhere((e) => e.trim() == v);

    if (next.isEmpty) {
      await p.remove(key);
      return;
    }

    if (next.length == list.length) return;

    await p.setStringList(key, next);
  }

  // =====================================================
  // CRUD (CANÓNICO)
  // =====================================================

  Future<CroquisAula?> load({
    required String institucionId,
    required String aula,
    required String turno,
  }) async {
    final p = await _prefs;

    final instHuman = _norm(institucionId);
    if (instHuman.isEmpty) return null;

    final k = key(institucionId: instHuman, aula: aula, turno: turno);
    final raw = (p.getString(k) ?? '').trim();
    if (raw.isNotEmpty) {
      return _decodeOrHeal(p, k, instHuman, raw);
    }

    // v1 compat: si existe la key vieja "humana", la migramos a la key actual.
    final k1 = _keyV1Human(institucionId: instHuman, aula: aula, turno: turno);
    final raw1 = (p.getString(k1) ?? '').trim();
    if (raw1.isEmpty) return null;

    final c = await _decodeOrHeal(p, k1, instHuman, raw1);
    if (c == null) return null;

    // Migración best-effort (no fallar si algo explota).
    try {
      final fixed = c.copyWith(
        institucionId: _norm(c.institucionId),
        aula: _norm(c.aula),
        turno: _norm(c.turno),
      );
      final k2 = key(
        institucionId: fixed.institucionId,
        aula: fixed.aula,
        turno: fixed.turno,
      );

      await p.setString(k2, jsonEncode(fixed.toMap()));
      await _idxAdd(p, _kIdxInst(instHuman), k2);

      await p.remove(k1);
      await _idxRemove(p, _kIdxInst(instHuman), k1);
    } catch (_) {
      // NO-OP
    }

    return c;
  }

  Future<CroquisAula?> _decodeOrHeal(
    SharedPreferences p,
    String keyToUse,
    String instHuman,
    String raw,
  ) async {
    try {
      final obj = jsonDecode(raw);

      if (obj is Map<String, dynamic>) {
        return CroquisAula.fromMap(obj);
      }
      if (obj is Map) {
        return CroquisAula.fromMap(Map<String, dynamic>.from(obj));
      }

      // Tipo inválido: auto-heal.
      await p.remove(keyToUse);
      await _idxRemove(p, _kIdxInst(instHuman), keyToUse);
      return null;
    } catch (_) {
      // JSON corrupto: auto-heal.
      await p.remove(keyToUse);
      await _idxRemove(p, _kIdxInst(instHuman), keyToUse);
      return null;
    }
  }

  Future<void> save(CroquisAula croquis) async {
    final p = await _prefs;

    final inst = _norm(croquis.institucionId);
    final aula = _norm(croquis.aula);
    final turno = _norm(croquis.turno);

    if (inst.isEmpty) return;
    if (aula.isEmpty) return; // regla V1: no persistimos sin aula definida

    // ✅ CANÓNICO: turnoKey estable (no labels)
    final fixed = croquis.copyWith(
      institucionId: inst,
      aula: aula,
      turno: turno.isEmpty ? 'morning' : turno,
    );

    final k = key(
      institucionId: fixed.institucionId,
      aula: fixed.aula,
      turno: fixed.turno,
    );

    await p.setString(k, jsonEncode(fixed.toMap()));
    await _idxAdd(p, _kIdxInst(inst), k);
  }

  Future<void> delete({
    required String institucionId,
    required String aula,
    required String turno,
  }) async {
    final p = await _prefs;

    final inst = _norm(institucionId);
    if (inst.isEmpty) return;

    final k = key(institucionId: inst, aula: aula, turno: turno);

    await p.remove(k);
    await _idxRemove(p, _kIdxInst(inst), k);

    // Limpieza compat v1 (best-effort)
    final k1 = _keyV1Human(institucionId: inst, aula: aula, turno: turno);
    if (k1 != k) {
      await p.remove(k1);
      await _idxRemove(p, _kIdxInst(inst), k1);
    }
  }

  Future<void> deleteByKey(String rawKey) async {
    final p = await _prefs;
    final k = rawKey.trim();
    if (k.isEmpty) return;

    // Best-effort: descubrir instId para limpiar índice.
    // Formato: croquis_aula_v1_<instId>_<aula>_<turno>
    String inst = '';
    if (k.startsWith(_prefix)) {
      final rest = k.substring(_prefix.length);
      final firstUnderscore = rest.indexOf('_');
      if (firstUnderscore > 0) {
        inst = _norm(rest.substring(0, firstUnderscore));
      }
    }

    await p.remove(k);
    if (inst.isNotEmpty) {
      await _idxRemove(p, _kIdxInst(inst), k);
    }
  }

  // =====================================================
  // Queries
  // =====================================================

  Future<List<String>> listKeysByInstitucion(String institucionId) async {
    final p = await _prefs;

    final inst = _norm(institucionId);
    if (inst.isEmpty) return const <String>[];

    final keys = _getIdx(p, _kIdxInst(inst));
    if (keys.isEmpty) return const <String>[];

    // Limpieza best-effort: si una key no existe, la removemos del índice.
    final out = <String>[];
    for (final k in keys) {
      if (p.containsKey(k)) {
        out.add(k);
      } else {
        _fireAndForget(_idxRemove(p, _kIdxInst(inst), k));
      }
    }
    return out;
  }

  Future<List<CroquisAula>> listByInstitucion(String institucionId) async {
    final p = await _prefs;

    final inst = _norm(institucionId);
    if (inst.isEmpty) return const <CroquisAula>[];

    final keys = await listKeysByInstitucion(inst);
    if (keys.isEmpty) return const <CroquisAula>[];

    final out = <CroquisAula>[];
    for (final k in keys) {
      final raw = (p.getString(k) ?? '').trim();
      if (raw.isEmpty) continue;

      try {
        final obj = jsonDecode(raw);
        if (obj is Map<String, dynamic>) {
          out.add(CroquisAula.fromMap(obj));
        } else if (obj is Map) {
          out.add(CroquisAula.fromMap(Map<String, dynamic>.from(obj)));
        } else {
          _fireAndForget(deleteByKey(k));
        }
      } catch (_) {
        // auto-heal de corrupto
        _fireAndForget(deleteByKey(k));
      }
    }

    // Orden estable: aula, turno (alfabético)
    out.sort((a, b) {
      final aa = a.aula.toLowerCase();
      final ba = b.aula.toLowerCase();
      final c1 = aa.compareTo(ba);
      if (c1 != 0) return c1;

      final at = a.turno.toLowerCase();
      final bt = b.turno.toLowerCase();
      return at.compareTo(bt);
    });

    return out;
  }

  // =====================================================
  // Rebuild (best-effort)
  // =====================================================

  Future<void> rebuildIndexes() async {
    final p = await _prefs;

    final keysSnapshot = p.getKeys().toList(growable: false);

    // 1) borrar índices
    for (final k in keysSnapshot) {
      if (k.startsWith(_idxPrefix)) {
        await p.remove(k);
      }
    }

    // 2) recorrer croquis guardados y reindexar por inst
    final croquisKeys = keysSnapshot.where((k) => k.startsWith(_prefix));
    for (final k in croquisKeys) {
      final raw = (p.getString(k) ?? '').trim();
      if (raw.isEmpty) continue;

      try {
        final obj = jsonDecode(raw);
        if (obj is! Map) continue;

        final c = CroquisAula.fromMap(Map<String, dynamic>.from(obj));
        final inst = _norm(c.institucionId);
        if (inst.isEmpty) continue;

        await _idxAdd(p, _kIdxInst(inst), k);
      } catch (_) {
        // corrupto: lo limpiamos para no contaminar
        await p.remove(k);
      }
    }
  }
}
