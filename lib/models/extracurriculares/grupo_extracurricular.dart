// ─────────────────────────────────────────────
// ATENA – EXTRACURRICULARES (CANÓNICO)
// Archivo: lib/models/extracurriculares/grupo_extracurricular.dart
// ─────────────────────────────────────────────
//
// Fuente de verdad:
// - GrupoExtracurricular.bloque usa BloqueExtracurricular (canónico).
// - SIN legacy: no aceptamos “categorías viejas” ni mapeos históricos.
// - Backend-ready:
//   - Serializamos bloque por .key (snake_case estable) para alinearlo con
//     ActividadExtracurricular y con validación canónica de BloqueExtracurricularX.
//   - Exponemos moduleKey derivada SIEMPRE de bloque.key.
//
// Parser de bloque (estricto, canónico):
// - Acepta SOLO lo que define BloqueExtracurricularX.tryParse/tryParseAny:
//   key exacta OR name exacto OR label exacto (case-insensitive).
// - Si viene vacío o inválido: cae a BloqueExtracurricular.otros (sin romper).
//
// moduleKey (canónico):
// - NO es fuente de verdad: se deriva SIEMPRE de bloque.key.
// - Si en fromMap viene moduleKey y NO coincide con bloque.key, se ignora (fail-safe).
// - En modo debug dejamos un assert informativo si detectamos drift (sin romper release).
//
// HARDENING (fase 2):
// - Normalización de IDs/strings consistente con services.
// - Cupos clamp defensivo (no negativos y ocupado <= max cuando max>0).
// - Orden/igualdad: helper de clave semántica (útil para dedupe/orden en servicios/UI).
// - fromMap tolerante: acepta keys alternativas mínimas sin introducir legacy de dominio
//   (solo tolerancia de storage/serialización: 'institucionID', 'actividad', 'grupo', etc).
//
// ✅ FIX clave para servicio:
// - `turno` y `aula` son campos reales NO-null (String) para evitar null-handling en services/UI.
//   Vacío ('') = “no especificado”.
// ─────────────────────────────────────────────

import 'dart:convert';

import 'bloque_extracurricular.dart';

// =====================================================
// HELPERS INTERNOS (parsers seguros)
// =====================================================

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.round();
  final s = v.toString().trim();
  return int.tryParse(s) ?? fallback;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'si' || s == 'sí') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

String _asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime _asDate(dynamic v, {DateTime? fallback}) {
  final fb = fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (v == null) return fb;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.round());
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.round());
  final s = v.toString().trim();
  if (s.isEmpty) return fb;
  final p = DateTime.tryParse(s);
  if (p != null) return p;
  final asInt = int.tryParse(s);
  if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  return fb;
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

/// Normalización local simple para comparaciones.
String _norm(String v) => v.trim().toLowerCase();

/// Normalización alineada con services para storage keys (sin whitespace interno).
String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

int _clampInt(int v, {required int min, required int max}) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

/// Parser canónico (sin heurísticas):
/// acepta key/name/label exactos (case-insensitive). Si no => otros.
BloqueExtracurricular _parseBloqueCanonico(dynamic raw) {
  final parsed = BloqueExtracurricularX.tryParseAny(raw);
  return parsed ?? BloqueExtracurricular.otros;
}

/// GrupoExtracurricular (modo 2):
/// - El alumno elige un grupo concreto (actividadNombre + nombreGrupo + turno)
///   y solicita vacante.
/// - “cupoMaximo = 0” => cupo no gestionado (siempre disponible).
class GrupoExtracurricular {
  final String id;

  /// Referencia: Institucion.id (en canónico: institucionId = perfilId)
  final String institucionId;

  /// Uno de los bloques canónicos (incluye "otros")
  final BloqueExtracurricular bloque;

  /// Nombre de la actividad (ej: “Fútbol”, “Inglés”, “Programación”)
  final String actividadNombre;

  /// Nombre del grupo (ej: “Infantil A”, “Nivel 1”, “Avanzado”, etc.)
  final String nombreGrupo;

  /// Turno/Horario (ej: “Lun y Mié 18:00”, “Mañana”, etc.)
  /// Vacío ('') = no especificado.
  final String turno;

  /// Aula/Espacio (ej: “Gimnasio”, “Sala 1”, “Laboratorio”, etc.)
  /// Vacío ('') = no especificado.
  final String aula;

  /// Cupos
  final int cupoMaximo;
  final int cupoOcupado;

  /// Permite pausar sin borrar
  final bool activo;

  /// Auditoría local
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrupoExtracurricular({
    required this.id,
    required this.institucionId,
    required this.bloque,
    required this.actividadNombre,
    required this.nombreGrupo,
    required this.cupoMaximo,
    required this.cupoOcupado,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.turno = '',
    this.aula = '',
  });

  /// ✅ moduleKey canónica (snake_case estable) derivada del bloque.
  /// Fuente de verdad: BloqueExtracurricular.key
  String get moduleKey => bloque.key;

  /// ✅ IDs estables en prototipo
  static String newGrupoId() {
    // microseconds reduce colisiones en altas rápidas
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'GX_$now';
  }

  /// Clave semántica (útil para orden/dedupe en UI/servicios).
  /// No incluye id para poder detectar duplicados “reales”.
  String get semanticKey => [
    _norm(institucionId),
    _norm(bloque.key),
    _norm(actividadNombre),
    _norm(nombreGrupo),
    _norm(turno),
    _norm(aula),
  ].join('|');

  /// Deduplicación semántica (si algún servicio lo necesita)
  String get dedupKey => 'gx|$semanticKey';

  int get cuposDisponibles {
    if (cupoMaximo <= 0) return 999999; // “no gestionado”
    final d = cupoMaximo - cupoOcupado;
    return d < 0 ? 0 : d;
  }

  bool get tieneCupos {
    if (!activo) return false;
    if (cupoMaximo <= 0) return true;
    return cuposDisponibles > 0;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,

    // ✅ CANÓNICO: key estable (snake_case)
    'bloque': bloque.key,

    // ✅ Se persiste por compat/filtro/debug, pero NO es fuente de verdad.
    'moduleKey': moduleKey,

    'actividadNombre': actividadNombre,
    'nombreGrupo': nombreGrupo,
    'turno': turno,
    'aula': aula,
    'cupoMaximo': cupoMaximo,
    'cupoOcupado': cupoOcupado,
    'activo': activo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GrupoExtracurricular.fromMap(Map<String, dynamic> m) {
    final map = _asMap(m);

    final parsedId = _asString(map['id']).trim();

    // Tolerancia mínima de storage (no legacy de dominio; solo keys alternativas)
    final parsedInstitucionId = _normIdKey(
      _asString(map['institucionId'] ?? map['institucionID'] ?? map['instId']),
    );

    final parsedActividad = _asString(
      map['actividadNombre'] ?? map['actividad'] ?? map['nombreActividad'],
    ).trim();

    final parsedGrupo = _asString(
      map['nombreGrupo'] ?? map['grupo'] ?? map['nombre_grupo'],
    ).trim();

    final turnoSafe = _asString(map['turno']).trim(); // vacío = no especificado
    final aulaSafe = _asString(
      map['aula'] ?? map['espacio'],
    ).trim(); // vacío = no especificado

    // ✅ Canónico: acepta key/name/label; fallback => otros.
    final bloque = _parseBloqueCanonico(map['bloque']);

    // moduleKey en storage NO es fuente de verdad:
    // si viene, la validamos estrictamente (canónica) y además
    // debe coincidir con bloque.key; si no, se ignora (fail-safe).
    final rawMk = _asString(map['moduleKey']).trim();
    final mk = _norm(rawMk);
    final expectedMk = _norm(bloque.key);

    final mkOk = mk.isEmpty
        ? true
        : (BloqueExtracurricularX.isValidKey(mk) && mk == expectedMk);

    assert(() {
      // Solo debug: si hay drift, lo señalamos sin romper.
      if (!mkOk && rawMk.trim().isNotEmpty) {
        // ignore: avoid_print
        print(
          '[ATENA][GrupoExtracurricular] moduleKey drift ignorado. '
          'storage="$rawMk" esperado="$expectedMk" bloque="${bloque.name}"',
        );
      }
      return true;
    }());

    final createdFallback = DateTime.now();
    final created = _asDate(map['createdAt'], fallback: createdFallback);
    var updated = _asDate(map['updatedAt'], fallback: created);

    // Hardening: updatedAt nunca antes de createdAt (datos corruptos)
    if (updated.isBefore(created)) {
      updated = created;
    }

    int max = _asInt(map['cupoMaximo'], fallback: 0);
    int ocupado = _asInt(map['cupoOcupado'], fallback: 0);

    if (max < 0) max = 0;
    if (ocupado < 0) ocupado = 0;

    // Hard clamp: si está gestionado, cupoOcupado no puede superar cupoMaximo.
    if (max > 0) {
      ocupado = _clampInt(ocupado, min: 0, max: max);
    } else {
      // Si no se gestiona cupo, mantenemos consistencia MVP: ocupado=0
      ocupado = 0;
    }

    return GrupoExtracurricular(
      id: parsedId.isEmpty ? GrupoExtracurricular.newGrupoId() : parsedId,
      institucionId: parsedInstitucionId,
      bloque: bloque,
      actividadNombre: parsedActividad,
      nombreGrupo: parsedGrupo,
      turno: turnoSafe,
      aula: aulaSafe,
      cupoMaximo: max,
      cupoOcupado: ocupado,
      activo: _asBool(map['activo'], fallback: true),
      createdAt: created,
      updatedAt: updated,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GrupoExtracurricular.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return GrupoExtracurricular.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('GrupoExtracurricular.fromJson: JSON inválido');
  }

  GrupoExtracurricular copyWith({
    String? id,
    String? institucionId,
    BloqueExtracurricular? bloque,
    String? actividadNombre,
    String? nombreGrupo,
    String? turno,
    String? aula,
    int? cupoMaximo,
    int? cupoOcupado,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();

    final nextActividad = (actividadNombre ?? this.actividadNombre).trim();
    final nextGrupo = (nombreGrupo ?? this.nombreGrupo).trim();

    final nextTurno = (turno ?? this.turno).trim(); // vacío = no especificado
    final nextAula = (aula ?? this.aula).trim(); // vacío = no especificado

    int max = cupoMaximo ?? this.cupoMaximo;
    int ocupado = cupoOcupado ?? this.cupoOcupado;

    if (max < 0) max = 0;
    if (ocupado < 0) ocupado = 0;

    if (max > 0) {
      ocupado = _clampInt(ocupado, min: 0, max: max);
    } else {
      ocupado = 0;
    }

    final nextCreated = createdAt ?? this.createdAt;
    var nextUpdated = updatedAt ?? now;
    if (nextUpdated.isBefore(nextCreated)) {
      nextUpdated = nextCreated;
    }

    return GrupoExtracurricular(
      id: (id ?? this.id).trim(),
      institucionId: _normIdKey(institucionId ?? this.institucionId),
      bloque: bloque ?? this.bloque,
      actividadNombre: nextActividad,
      nombreGrupo: nextGrupo,
      turno: nextTurno,
      aula: nextAula,
      cupoMaximo: max,
      cupoOcupado: ocupado,
      activo: activo ?? this.activo,
      createdAt: nextCreated,
      updatedAt: nextUpdated,
    );
  }
}
