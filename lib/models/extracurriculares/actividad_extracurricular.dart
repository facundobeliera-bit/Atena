// lib/models/extracurriculares/actividad_extracurricular.dart
//
// ATENA – EXTRACURRICULARES (CANÓNICO)
//
// Fuente de verdad:
// - ActividadExtracurricular.bloque usa BloqueExtracurricular (canónico).
// - SIN legacy: no “mapeos viejos”, no heurísticas de categorías antiguas.
// - Backend-ready: serializamos bloque por .key (snake_case estable).
//
// Parser de bloque (estricto, canónico):
// - Acepta SOLO lo que define BloqueExtracurricularX.tryParse/tryParseAny:
//   key exacta (case-insensitive) OR name exacto OR label exacto.
// - Si viene vacío o inválido: cae a BloqueExtracurricular.otros (sin romper).
//
// ✅ HARDENING / CONSISTENCIA (fase 2):
// - Normaliza strings (trim) y clamps de cupos (0..cupoMaximo).
// - fromMap tolera "bloqueKey" y "moduleKey" (canónico futuro) como ALIAS de lectura.
// - Se agrega moduleKey (canonical) como espejo de bloque.key para UI/servicios
//   sin romper compat; se expone dedupKey semántica.
// - copyWith auto-actualiza updatedAt si no se provee.
//
// Nota:
// - Los getters cupoDisponible / tieneCupos se mantienen como alias de compat
//   para no romper pantallas/servicios existentes, pero no son “legacy de dominio”.

import 'dart:convert';

import 'bloque_extracurricular.dart';

// =====================================================
// HELPERS INTERNOS (parsers seguros)
// =====================================================

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.round();
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

int _clampInt(int v, {required int min, required int max}) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

/// Parser estricto de BloqueExtracurricular (sin legacy).
/// Acepta SOLO: key exacta OR name exacta OR label exacta (case-insensitive).
/// Si inválido => otros (sin romper).
BloqueExtracurricular _parseBloqueStrict(dynamic raw) {
  final parsed = BloqueExtracurricularX.tryParseAny(raw);
  return parsed ?? BloqueExtracurricular.otros;
}

// =====================================================
// MODELO
// =====================================================

/// Estado canónico mínimo de una actividad extracurricular.
/// - Backend-ready (map/json estable).
/// - Se usa para: filtros alumno, preview, y solicitud de vacantes (via SolicitudAlumno).
class ActividadExtracurricular {
  final String id;

  /// Referencia: Institucion.id (en canónico: perfilId institución).
  final String institucionId;

  /// Uno de los bloques canónicos (incluye "otros").
  final BloqueExtracurricular bloque;

  /// Key canónica explícita para UI/servicios (alias de bloque.key).
  /// Puente para futuros servicios que trabajen con "moduleKey".
  String get moduleKey => bloque.key;

  final String nombre;

  /// Permite desactivar sin borrar (historial/consistencia).
  final bool activa;

  /// Informativo (UI).
  final String? descripcion;
  final String? edades;
  final String? horario;
  final String? ubicacion;
  final String? contacto;

  /// Cupos (prototipo): si cupoMaximo = 0 => cupo “no gestionado”.
  final int cupoMaximo;
  final int cupoOcupado;

  /// Precio referencial (string) para prototipo.
  final String? precio;

  /// Auditoría local (prototipo).
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActividadExtracurricular({
    required this.id,
    required this.institucionId,
    required this.bloque,
    required this.nombre,
    required this.activa,
    required this.cupoMaximo,
    required this.cupoOcupado,
    required this.createdAt,
    required this.updatedAt,
    this.descripcion,
    this.edades,
    this.horario,
    this.ubicacion,
    this.contacto,
    this.precio,
  });

  /// ✅ IDs estables en prototipo.
  static String newActividadId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'AX_$now';
  }

  /// Deduplicación semántica (prototipo / índices):
  /// - institucionId + moduleKey + nombre(normalizado).
  String get dedupKey {
    final n = nombre.trim().toLowerCase();
    final inst = institucionId.trim();
    return 'ax|$inst|$moduleKey|$n';
  }

  /// Alias de compat (UI/servicios existentes).
  int get cupoDisponible => cuposDisponibles;

  /// Cupos disponibles calculados.
  /// Si cupoMaximo <= 0 => cupo “no gestionado”.
  int get cuposDisponibles {
    if (cupoMaximo <= 0) return 999999; // “no gestionado”
    final d = cupoMaximo - cupoOcupado;
    return d < 0 ? 0 : d;
  }

  /// Alias de compat (UI/servicios existentes).
  bool get tieneCupos => tieneCuposDisponibles;

  /// Semántica explícita: si está gestionado, requiere disponibles > 0.
  bool get tieneCuposDisponibles {
    if (cupoMaximo <= 0) return true; // no gestionado => permitimos
    return cuposDisponibles > 0;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,

    // ✅ CANÓNICO: key estable (snake_case)
    'bloque': bloque.key,

    // ✅ Alias explícito (fase 2): UI/servicios pueden leer moduleKey.
    'moduleKey': bloque.key,

    'nombre': nombre,
    'activa': activa,
    'descripcion': descripcion,
    'edades': edades,
    'horario': horario,
    'ubicacion': ubicacion,
    'contacto': contacto,
    'cupoMaximo': cupoMaximo,
    'cupoOcupado': cupoOcupado,
    'precio': precio,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ActividadExtracurricular.fromMap(Map<String, dynamic> m) {
    final map = _asMap(m);
    final now = DateTime.now();

    final parsedId = _asString(map['id']).trim();
    final parsedInstitucionId = _asString(map['institucionId']).trim();
    final parsedNombre = _asString(map['nombre']).trim();

    // ✅ Lectura tolerante (pero SIN heurísticas):
    // - prioridad: bloque (key/name/label) → bloqueKey → moduleKey
    final rawBloque = map.containsKey('bloque')
        ? map['bloque']
        : (map.containsKey('bloqueKey') ? map['bloqueKey'] : map['moduleKey']);

    final bloque = _parseBloqueStrict(rawBloque);

    final created = _asDate(map['createdAt'], fallback: now);
    final updated = _asDate(map['updatedAt'], fallback: created);

    int max = _asInt(map['cupoMaximo'], fallback: 0);
    int ocupado = _asInt(map['cupoOcupado'], fallback: 0);

    if (max < 0) max = 0;
    if (ocupado < 0) ocupado = 0;

    // Hard clamp: si está gestionado, cupoOcupado no puede superar cupoMaximo.
    if (max > 0) {
      ocupado = _clampInt(ocupado, min: 0, max: max);
    }

    return ActividadExtracurricular(
      id: parsedId.isEmpty
          ? ActividadExtracurricular.newActividadId()
          : parsedId,
      institucionId: parsedInstitucionId,
      bloque: bloque,
      nombre: parsedNombre,
      activa: _asBool(map['activa'], fallback: true),
      descripcion: map['descripcion']?.toString(),
      edades: map['edades']?.toString(),
      horario: map['horario']?.toString(),
      ubicacion: map['ubicacion']?.toString(),
      contacto: map['contacto']?.toString(),
      cupoMaximo: max,
      cupoOcupado: ocupado,
      precio: map['precio']?.toString(),
      createdAt: created,
      updatedAt: updated,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ActividadExtracurricular.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return ActividadExtracurricular.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    }
    throw FormatException('ActividadExtracurricular.fromJson: JSON inválido');
  }

  ActividadExtracurricular copyWith({
    String? id,
    String? institucionId,
    BloqueExtracurricular? bloque,
    String? nombre,
    bool? activa,
    String? descripcion,
    String? edades,
    String? horario,
    String? ubicacion,
    String? contacto,
    int? cupoMaximo,
    int? cupoOcupado,
    String? precio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();

    // Normalizamos cupos en el resultado final también.
    int max = cupoMaximo ?? this.cupoMaximo;
    int ocupado = cupoOcupado ?? this.cupoOcupado;
    if (max < 0) max = 0;
    if (ocupado < 0) ocupado = 0;
    if (max > 0) {
      ocupado = _clampInt(ocupado, min: 0, max: max);
    }

    final nextCreatedAt = createdAt ?? this.createdAt;

    // ✅ Regla: si no se provee updatedAt, se actualiza a "ahora".
    final nextUpdatedAt = updatedAt ?? now;

    return ActividadExtracurricular(
      id: id ?? this.id,
      institucionId: institucionId ?? this.institucionId,
      bloque: bloque ?? this.bloque,
      nombre: (nombre ?? this.nombre).trim(),
      activa: activa ?? this.activa,
      descripcion: descripcion ?? this.descripcion,
      edades: edades ?? this.edades,
      horario: horario ?? this.horario,
      ubicacion: ubicacion ?? this.ubicacion,
      contacto: contacto ?? this.contacto,
      cupoMaximo: max,
      cupoOcupado: ocupado,
      precio: precio ?? this.precio,
      createdAt: nextCreatedAt,
      updatedAt: nextUpdatedAt,
    );
  }
}
