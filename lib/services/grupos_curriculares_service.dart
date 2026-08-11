import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/instituciones/grupo_curricular.dart';

/// ─────────────────────────────────────────────
/// ATENA – GRUPOS CURRICULARES SERVICE (LEGACY)
///
/// ESTADO:
/// - Service en modo COMPATIBILIDAD.
/// - Fuente de verdad CANÓNICA:
///     Institucion.gruposCurriculares
///   (ver Institucion.fromMap + instituciones_helpers).
///
/// RESPONSABILIDADES:
/// - Mantener compilación y estabilidad.
/// - Permitir lectura/escritura legacy controlada.
/// - Evitar corrupción, duplicados y desorden.
/// - NO crear flujos paralelos nuevos.
/// ─────────────────────────────────────────────
class GruposCurricularesService {
  GruposCurricularesService._();
  static final GruposCurricularesService instance =
      GruposCurricularesService._();

  // =====================================================
  // Normalización mínima (legacy-safe)
  // =====================================================

  String _norm(String v) => v.trim();

  String _normLower(String v) => v.trim().toLowerCase();

  // =====================================================
  // Keys
  // =====================================================

  String _key(String institucionId) =>
      'grupos_curriculares_${_norm(institucionId)}';

  // =====================================================
  // Load
  // =====================================================

  Future<List<GrupoCurricular>> getGrupos(String institucionId) async {
    final id = _norm(institucionId);
    if (id.isEmpty) return <GrupoCurricular>[];

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(id));

    if (raw == null || raw.trim().isEmpty) {
      return <GrupoCurricular>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <GrupoCurricular>[];

      final out = <GrupoCurricular>[];
      for (final e in decoded) {
        if (e is Map) {
          try {
            out.add(GrupoCurricular.fromMap(Map<String, dynamic>.from(e)));
          } catch (_) {
            // item legacy corrupto → ignorar
          }
        }
      }

      // Orden estable por nombreCurso (legacy UI-friendly)
      out.sort(
        (a, b) =>
            _normLower(a.nombreCurso).compareTo(_normLower(b.nombreCurso)),
      );

      return out;
    } catch (_) {
      return <GrupoCurricular>[];
    }
  }

  // =====================================================
  // Save (lista completa – legacy)
  // =====================================================

  Future<void> saveGrupos(
    String institucionId,
    List<GrupoCurricular> grupos,
  ) async {
    final id = _norm(institucionId);
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    if (grupos.isEmpty) {
      await prefs.setString(_key(id), '[]');
      return;
    }

    // Deduplicación defensiva por nombreCurso (case-insensitive)
    final mapByNombre = <String, GrupoCurricular>{};
    for (final g in grupos) {
      final key = _normLower(g.nombreCurso);
      if (key.isNotEmpty) {
        mapByNombre[key] = g; // último gana
      }
    }

    final data = mapByNombre.values
        .map((g) => g.toMap())
        .toList(growable: false);

    await prefs.setString(_key(id), jsonEncode(data));
  }

  // =====================================================
  // Add / Update / Remove
  // =====================================================

  Future<void> addGrupo(String institucionId, GrupoCurricular grupo) async {
    final nombreKey = _normLower(grupo.nombreCurso);
    if (nombreKey.isEmpty) return;

    final current = await getGrupos(institucionId);

    final exists = current.any((g) => _normLower(g.nombreCurso) == nombreKey);
    if (exists) return;

    current.add(grupo);
    await saveGrupos(institucionId, current);
  }

  Future<void> updateGrupo(String institucionId, GrupoCurricular grupo) async {
    final nombreKey = _normLower(grupo.nombreCurso);
    if (nombreKey.isEmpty) return;

    final current = await getGrupos(institucionId);

    final idx = current.indexWhere(
      (g) => _normLower(g.nombreCurso) == nombreKey,
    );

    if (idx >= 0) {
      current[idx] = grupo;
    } else {
      current.add(grupo);
    }

    await saveGrupos(institucionId, current);
  }

  Future<void> removeGrupo(String institucionId, String nombreCurso) async {
    final nombreKey = _normLower(nombreCurso);
    if (nombreKey.isEmpty) return;

    final current = await getGrupos(institucionId)
      ..removeWhere((g) => _normLower(g.nombreCurso) == nombreKey);

    await saveGrupos(institucionId, current);
  }

  // =====================================================
  // Cupos (legacy-safe)
  // =====================================================

  Future<void> ocuparCupo({
    required String institucionId,
    required String nombreCurso,
    required int delta, // +1 / -1
  }) async {
    if (delta == 0) return;

    final nombreKey = _normLower(nombreCurso);
    if (nombreKey.isEmpty) return;

    final current = await getGrupos(institucionId);

    final idx = current.indexWhere(
      (g) => _normLower(g.nombreCurso) == nombreKey,
    );
    if (idx == -1) return;

    final g = current[idx];
    final nuevoOcupado = (g.cuposOcupados + delta).clamp(0, g.cuposTotales);

    current[idx] = g.copyWith(cuposOcupados: nuevoOcupado);

    await saveGrupos(institucionId, current);
  }
}
