// ─────────────────────────────────────────────
// ATENA – MIGRACIÓN CANÓNICA DE SOLICITUDES (PREFS)
// Archivo: lib/services/solicitudes_migracion_service.dart
// ─────────────────────────────────────────────

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/solicitudes/solicitud_alumno.dart';
import '../services/cuenta_service.dart';
import '../repositories/solicitudes_repository_prefs.dart';

class MigracionSolicitudesReport {
  final int totalLeidas;
  final int migradas;
  final int yaCanonicas;
  final int huerfanas;
  final int instEspejoReparado;
  final List<String> idsHuerfanas;

  const MigracionSolicitudesReport({
    required this.totalLeidas,
    required this.migradas,
    required this.yaCanonicas,
    required this.huerfanas,
    required this.instEspejoReparado,
    required this.idsHuerfanas,
  });

  @override
  String toString() {
    return 'MigracionSolicitudesReport('
        'total=$totalLeidas, migradas=$migradas, yaCanonicas=$yaCanonicas, '
        'huerfanas=$huerfanas, instReparadas=$instEspejoReparado'
        ')';
  }
}

class SolicitudesMigracionService {
  static const String _kSolAlumnoPrefix = 'sol_alumno_';
  static const String _kSolInstPrefix = 'sol_inst_';

  static String _kSolAlumno(String id) => '$_kSolAlumnoPrefix${_normId(id)}';
  static String _kSolInst(String id) => '$_kSolInstPrefix${_normId(id)}';

  static Future<MigracionSolicitudesReport> migrarSolicitudesLegacy({
    bool repararEspejoInstitucion = true,
    bool borrarHuerfanas = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_kSolAlumnoPrefix))
        .toList(growable: false);

    int migradas = 0;
    int yaCanonicas = 0;
    int huerfanas = 0;
    int instReparadas = 0;
    final idsHuerfanas = <String>[];

    final nowIso = DateTime.now().toIso8601String();

    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null || raw.trim().isEmpty) continue;

      SolicitudAlumno? s;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        s = SolicitudAlumno.fromMap(Map<String, dynamic>.from(decoded));
      } catch (_) {
        continue;
      }

      final id = _normId(s.id);
      if (id.isEmpty) continue;

      final owner = _normId(s.ownerAccountId ?? '');
      final perfil = _normId(s.perfilId ?? '');

      // YA CANÓNICA
      if (owner.isNotEmpty && perfil.isNotEmpty) {
        yaCanonicas++;
        if (repararEspejoInstitucion) {
          final repaired = await _repararEspejoInstitucion(prefs: prefs, s: s);
          if (repaired) instReparadas++;
        }
        continue;
      }

      // LEGACY: inferir por DNI
      final dni = _normDigits(s.alumnoDocumento);
      if (dni.isEmpty) {
        huerfanas++;
        idsHuerfanas.add(id);
        if (borrarHuerfanas) {
          await _borrarEntradasSolicitud(prefs: prefs, id: id);
        }
        continue;
      }

      final perfilAlumno = await CuentaService.getPerfilAlumnoByDni(dni);
      if (perfilAlumno == null) {
        huerfanas++;
        idsHuerfanas.add(id);
        if (borrarHuerfanas) {
          await _borrarEntradasSolicitud(prefs: prefs, id: id);
        }
        continue;
      }

      final perfilId = _normId(perfilAlumno.id);
      final ownerCandidate = _normId(perfilAlumno.ownerAccountId ?? '');
      final ownerId = ownerCandidate.isNotEmpty
          ? ownerCandidate
          : _normId(perfilAlumno.cuentaId);

      if (perfilId.isEmpty || ownerId.isEmpty) {
        huerfanas++;
        idsHuerfanas.add(id);
        if (borrarHuerfanas) {
          await _borrarEntradasSolicitud(prefs: prefs, id: id);
        }
        continue;
      }

      // 🔁 REESCRITURA CANÓNICA
      final m = s.toMap();
      m['ownerAccountId'] = ownerId;
      m['perfilId'] = perfilId;
      m['alumnoDocumento'] = _normDigits(perfilAlumno.documento);
      m['fechaUltimoCambio'] = nowIso;

      await prefs.setString(_kSolAlumno(id), jsonEncode(m));
      migradas++;

      if (repararEspejoInstitucion) {
        final repaired = await _repararEspejoInstitucion(prefs: prefs, s: s);
        if (repaired) instReparadas++;
      }
    }

    // ✅ Rebuild índices (INSTANCIA, NO estático)
    try {
      final repo = SolicitudesRepositoryPrefs();
      await repo.rebuildIndexes();
    } catch (_) {}

    return MigracionSolicitudesReport(
      totalLeidas: keys.length,
      migradas: migradas,
      yaCanonicas: yaCanonicas,
      huerfanas: huerfanas,
      instEspejoReparado: instReparadas,
      idsHuerfanas: idsHuerfanas,
    );
  }

  // =====================================================
  // Reparación espejo institución
  // =====================================================
  //
  // CANÓNICO (fix compile + backend-ready):
  // - NO depende de clases que pueden no existir (SolicitudVacanteInstitucion / EstadoSolicitudInstitucion).
  // - Espejo se guarda como Map JSON en prefs bajo sol_inst_<id>.
  // - Estado se guarda como string estable: 'pendiente' (legacy-friendly).
  //
  static Future<bool> _repararEspejoInstitucion({
    required SharedPreferences prefs,
    required SolicitudAlumno s,
  }) async {
    final id = _normId(s.id);
    if (id.isEmpty) return false;

    final rawInst = prefs.getString(_kSolInst(id));
    if (rawInst != null && rawInst.trim().isNotEmpty) return false;

    final aulaTrim = s.aula.trim();
    final grupo = aulaTrim.isEmpty ? null : aulaTrim;

    final instId = _normId(s.institucionId);

    // Si no hay institución, no tiene sentido crear espejo.
    if (instId.isEmpty) return false;

    // Best-effort: fechas pueden ser String/DateTime según tu modelo. Guardamos lo que venga.
    final dynamic fechaSolicitud = s.fechaCreacion;
    final dynamic fechaUltimoCambio = s.fechaUltimoCambio;

    final espejo = <String, dynamic>{
      'id': id,
      'institucionId': instId,
      'actividadNombre': s.actividadNombre.trim(),
      'grupo': grupo,
      'aula': aulaTrim.isEmpty ? null : aulaTrim,
      'turno': s.turno.trim().isEmpty ? null : s.turno.trim(),
      'esCurricular': s.esCurricular,
      'alumnoDocumento': _normDigits(s.alumnoDocumento),
      'ownerAccountId': _normId(s.ownerAccountId ?? ''),
      'perfilId': _normId(s.perfilId ?? ''),
      'fechaSolicitud': fechaSolicitud,
      'fechaUltimoCambio': fechaUltimoCambio,
      // Estado institucional: estable, no depende de enums inexistentes.
      'estado': 'pendiente',
      'notaInstitucion': s.notaInstitucion,
      // Meta (debug/migración)
      'source': 'migracion_solicitudes_v1',
    };

    await prefs.setString(_kSolInst(id), jsonEncode(espejo));
    return true;
  }

  static Future<void> _borrarEntradasSolicitud({
    required SharedPreferences prefs,
    required String id,
  }) async {
    final sid = _normId(id);
    if (sid.isEmpty) return;
    await prefs.remove(_kSolAlumno(sid));
    await prefs.remove(_kSolInst(sid));
  }

  static String _normId(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), '');

  static String _normDigits(String input) =>
      input.replaceAll(RegExp(r'\D+'), '').trim();
}
