// lib/repositories/solicitudes_repository_prefs.dart
//
// ATENA – SOLICITUDES REPOSITORY (SharedPreferences)
// Implementación CANÓNICA – NULL SAFE
//
// Fuente de verdad: SolicitudAlumno (sol_alumno_<id>)
// Índices: sol_idx_*
//
// ✅ FIX CANÓNICO (Feb 2026):
// - saveSolicitudAlumno() ahora limpia índices viejos si la solicitud ya existía
//   y cambió owner/perfil/institucion/estado, evitando “pendientes fantasma” y cruces.
//
// ✅ HARDENING (Feb 2026):
// - rebuildIndexes() reindexa de manera determinística (no depende de old/cleanup),
//   usando un indexer interno idempotente (más cercano a backend-ready).
//

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/solicitudes/solicitud_alumno.dart';
import '../models/solicitudes/solicitud_vacante_institucion.dart';
import 'solicitudes_repository.dart';

class SolicitudesRepositoryPrefs implements SolicitudesRepository {
  // =====================================================
  // KEYS
  // =====================================================

  static String _kSolAlumno(String id) => 'sol_alumno_${_kid(id)}';
  static String _kSolInst(String id) => 'sol_inst_${_kid(id)}';

  static const String _kIdxAllAlumno = 'sol_idx_all_alumno';
  static String _kIdxOwner(String id) => 'sol_idx_owner_${_kid(id)}';
  static String _kIdxPerfil(String id) => 'sol_idx_perfil_${_kid(id)}';
  static String _kIdxInstitucion(String id) => 'sol_idx_inst_${_kid(id)}';
  static String _kIdxInstPend(String id) => 'sol_idx_inst_${_kid(id)}_pend';

  // =====================================================
  // Utils
  // =====================================================

  static String _s(dynamic v) => (v ?? '').toString().trim();

  /// Canon para IDs / keys: trim + elimina whitespace interno
  static String _kid(dynamic v) {
    final t = _s(v);
    if (t.isEmpty) return '';
    return t.replaceAll(RegExp(r'\s+'), '');
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  List<String> _getIdx(SharedPreferences p, String key) {
    final raw = p.getStringList(key) ?? const <String>[];
    if (raw.isEmpty) return const <String>[];

    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final v = _kid(e);
      if (v.isNotEmpty && seen.add(v)) out.add(v);
    }
    return out;
  }

  Future<void> _idxAdd(SharedPreferences p, String key, String id) async {
    final sid = _kid(id);
    if (sid.isEmpty) return;

    final list = _getIdx(p, key);
    if (list.isEmpty) {
      await p.setStringList(key, <String>[sid]);
      return;
    }

    if (list.contains(sid)) return;

    final next = List<String>.from(list)..add(sid);
    await p.setStringList(key, next);
  }

  Future<void> _idxRemove(SharedPreferences p, String key, String id) async {
    final sid = _kid(id);
    if (sid.isEmpty) return;

    final list = _getIdx(p, key);
    if (list.isEmpty) return;

    final next = List<String>.from(list)..removeWhere((e) => _kid(e) == sid);

    if (next.isEmpty) {
      await p.remove(key);
      return;
    }

    if (next.length == list.length) return;

    await p.setStringList(key, next);
  }

  Future<SolicitudAlumno?> _loadAlumno(SharedPreferences p, String id) async {
    final sid = _kid(id);
    if (sid.isEmpty) return null;

    final raw = p.getString(_kSolAlumno(sid));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      return SolicitudAlumno.fromMap(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }

  /// Indexación idempotente (backend-ready mindset):
  /// - La fuente de verdad de "pendientes" es el estado actual de la solicitud.
  Future<void> _indexSolicitud({
    required SharedPreferences p,
    required String sid,
    required SolicitudAlumno s,
  }) async {
    await _idxAdd(p, _kIdxAllAlumno, sid);

    final owner = _kid(s.ownerAccountId);
    final perfil = _kid(s.perfilId);
    final inst = _kid(s.institucionId);

    if (owner.isNotEmpty) await _idxAdd(p, _kIdxOwner(owner), sid);
    if (perfil.isNotEmpty) await _idxAdd(p, _kIdxPerfil(perfil), sid);

    if (inst.isNotEmpty) {
      await _idxAdd(p, _kIdxInstitucion(inst), sid);

      if (s.estado == EstadoSolicitud.pendiente) {
        await _idxAdd(p, _kIdxInstPend(inst), sid);
      } else {
        await _idxRemove(p, _kIdxInstPend(inst), sid);
      }
    }
  }

  Future<void> _cleanupOldIndexesIfNeeded({
    required SharedPreferences p,
    required String sid,
    required SolicitudAlumno? oldS,
    required SolicitudAlumno newS,
  }) async {
    if (oldS == null) return;

    final oldOwner = _kid(oldS.ownerAccountId);
    final oldPerfil = _kid(oldS.perfilId);
    final oldInst = _kid(oldS.institucionId);

    final newOwner = _kid(newS.ownerAccountId);
    final newPerfil = _kid(newS.perfilId);
    final newInst = _kid(newS.institucionId);

    // Owner index
    if (oldOwner.isNotEmpty && oldOwner != newOwner) {
      await _idxRemove(p, _kIdxOwner(oldOwner), sid);
    }

    // Perfil index
    if (oldPerfil.isNotEmpty && oldPerfil != newPerfil) {
      await _idxRemove(p, _kIdxPerfil(oldPerfil), sid);
    }

    // Institución index
    if (oldInst.isNotEmpty && oldInst != newInst) {
      await _idxRemove(p, _kIdxInstitucion(oldInst), sid);
      await _idxRemove(p, _kIdxInstPend(oldInst), sid); // siempre limpiamos pend
    } else if (oldInst.isNotEmpty) {
      // misma institución, pero el estado puede cambiar: limpiamos pend y luego reindexamos
      await _idxRemove(p, _kIdxInstPend(oldInst), sid);
    }
  }

  // =====================================================
  // Alumno (CANÓNICO)
  // =====================================================

  @override
  Future<void> saveSolicitudAlumno(SolicitudAlumno s) async {
    final p = await _prefs;

    final sid = _kid(s.id);
    if (sid.isEmpty) return;

    // ✅ FIX CANÓNICO: si ya existía, limpiamos índices anteriores antes de reindexar
    final old = await _loadAlumno(p, sid);
    await _cleanupOldIndexesIfNeeded(p: p, sid: sid, oldS: old, newS: s);

    await p.setString(_kSolAlumno(sid), jsonEncode(s.toMap()));

    // Indexación final (idempotente)
    await _indexSolicitud(p: p, sid: sid, s: s);
  }

  @override
  Future<SolicitudAlumno?> getSolicitudAlumnoById(String id) async {
    final p = await _prefs;
    return _loadAlumno(p, id);
  }

  @override
  Future<void> deleteSolicitudAlumnoById(String id) async {
    final p = await _prefs;

    final sid = _kid(id);
    if (sid.isEmpty) return;

    final s = await _loadAlumno(p, sid);

    await p.remove(_kSolAlumno(sid));
    await _idxRemove(p, _kIdxAllAlumno, sid);

    if (s == null) return;

    final owner = _kid(s.ownerAccountId);
    final perfil = _kid(s.perfilId);
    final inst = _kid(s.institucionId);

    if (owner.isNotEmpty) await _idxRemove(p, _kIdxOwner(owner), sid);
    if (perfil.isNotEmpty) await _idxRemove(p, _kIdxPerfil(perfil), sid);

    if (inst.isNotEmpty) {
      await _idxRemove(p, _kIdxInstitucion(inst), sid);
      await _idxRemove(p, _kIdxInstPend(inst), sid);
    }
  }

  // =====================================================
  // Queries
  // =====================================================

  @override
  Future<List<SolicitudAlumno>> getAllSolicitudesAlumno() async {
    final p = await _prefs;

    final ids = _getIdx(p, _kIdxAllAlumno);
    if (ids.isEmpty) return const <SolicitudAlumno>[];

    final out = <SolicitudAlumno>[];
    for (final id in ids) {
      final s = await _loadAlumno(p, id);
      if (s != null) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  @override
  Future<List<SolicitudAlumno>> getSolicitudesPerfil(String perfilId) async {
    final pid = _kid(perfilId);
    if (pid.isEmpty) return const <SolicitudAlumno>[];

    final p = await _prefs;

    final ids = _getIdx(p, _kIdxPerfil(pid));
    if (ids.isEmpty) return const <SolicitudAlumno>[];

    final out = <SolicitudAlumno>[];
    for (final id in ids) {
      final s = await _loadAlumno(p, id);
      if (s != null && _kid(s.perfilId) == pid) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  @override
  Future<List<SolicitudAlumno>> getSolicitudesOwner(
    String ownerAccountId,
  ) async {
    final oid = _kid(ownerAccountId);
    if (oid.isEmpty) return const <SolicitudAlumno>[];

    final p = await _prefs;

    final ids = _getIdx(p, _kIdxOwner(oid));
    if (ids.isEmpty) return const <SolicitudAlumno>[];

    final out = <SolicitudAlumno>[];
    for (final id in ids) {
      final s = await _loadAlumno(p, id);
      if (s != null && _kid(s.ownerAccountId) == oid) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  @override
  Future<List<SolicitudAlumno>> getSolicitudesInstitucion(
    String institucionId,
  ) async {
    final iid = _kid(institucionId);
    if (iid.isEmpty) return const <SolicitudAlumno>[];

    final p = await _prefs;

    final ids = _getIdx(p, _kIdxInstitucion(iid));
    if (ids.isEmpty) return const <SolicitudAlumno>[];

    final out = <SolicitudAlumno>[];
    for (final id in ids) {
      final s = await _loadAlumno(p, id);
      if (s != null && _kid(s.institucionId) == iid) out.add(s);
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  @override
  Future<List<SolicitudAlumno>> getSolicitudesInstitucionPendientes(
    String institucionId,
  ) async {
    final iid = _kid(institucionId);
    if (iid.isEmpty) return const <SolicitudAlumno>[];

    final p = await _prefs;

    final ids = _getIdx(p, _kIdxInstPend(iid));
    if (ids.isEmpty) return const <SolicitudAlumno>[];

    final out = <SolicitudAlumno>[];
    for (final id in ids) {
      final s = await _loadAlumno(p, id);
      if (s != null &&
          _kid(s.institucionId) == iid &&
          s.estado == EstadoSolicitud.pendiente) {
        out.add(s);
      }
    }

    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return out;
  }

  // =====================================================
  // Legacy (persistencia simple; sin índices)
  // =====================================================

  @override
  Future<void> saveSolicitudInstitucion(SolicitudVacanteInstitucion s) async {
    final p = await _prefs;

    final sid = _kid(s.id);
    if (sid.isEmpty) return;

    await p.setString(_kSolInst(sid), jsonEncode(s.toMap()));
  }

  @override
  Future<SolicitudVacanteInstitucion?> getSolicitudInstitucionById(
    String id,
  ) async {
    final p = await _prefs;

    final sid = _kid(id);
    if (sid.isEmpty) return null;

    final raw = p.getString(_kSolInst(sid));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      return SolicitudVacanteInstitucion.fromMap(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteSolicitudInstitucionById(String id) async {
    final p = await _prefs;

    final sid = _kid(id);
    if (sid.isEmpty) return;

    await p.remove(_kSolInst(sid));
  }

  // =====================================================
  // Rebuild
  // =====================================================

  @override
  Future<void> rebuildIndexes() async {
    final p = await _prefs;

    final keysSnapshot = p.getKeys().toList(growable: false);

    // Borra solo índices (no toca datos)
    for (final k in keysSnapshot) {
      if (k.startsWith('sol_idx_')) {
        await p.remove(k);
      }
    }

    // Re-indexa todas las solicitudes guardadas (determinístico; sin cleanup old)
    final alumnoKeys = keysSnapshot.where((k) => k.startsWith('sol_alumno_'));
    for (final k in alumnoKeys) {
      final raw = p.getString(k);
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final m = jsonDecode(raw);
        if (m is! Map) continue;

        final s = SolicitudAlumno.fromMap(Map<String, dynamic>.from(m));
        final sid = _kid(s.id);
        if (sid.isEmpty) continue;

        await _indexSolicitud(p: p, sid: sid, s: s);
      } catch (_) {
        // NO-OP (best-effort)
      }
    }
  }
}