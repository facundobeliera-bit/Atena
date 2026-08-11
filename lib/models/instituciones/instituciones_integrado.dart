// ─────────────────────────────────────────────
// ATENA – MODELOS INSTITUCIONES (MODERN / CANÓNICO)
// Archivo: lib/models/instituciones/instituciones_integrado.dart
//
// Objetivo de esta versión:
// - Mantener compatibilidad de lectura legacy (tolerancia en fromMap / fromJson).
// - Mantener el proyecto compilable.
// - Evitar escribir/depender de estructuras legacy en nuevos módulos.
// - Preparar el terreno para el flujo canónico (owner → perfiles) sin romper compilación.
//
// ✅ NUEVO (enero 2026) – CROQUIS AULA (10x10):
// - Modelo serializable CroquisAula10x10 (solo nombres, sin DNI).
// - Soporta grupos (rectángulos + título).
// - Integración en Institucion: campo `croquisAula` (además de `croquisLocalPath` legacy).
// - Persistencia “gratis”: si ya guardás Institucion en prefs por toMap/fromMap,
//   el croquis queda persistido dentro de la institución.
//
// ✅ NUEVO (enero 2026) – UBICACIÓN + MODALIDAD (backend-ready):
// - Se agregan campos canónicos: pais, provincia, ciudad.
// - Se agrega modalidad: presencial / remoto / hibrido.
// - toMap incluye los campos.
// - fromMap tolera legacy: country/state/city, localidad, provinciaNombre, etc.
// - Defaults seguros si falta info.
//
// ✅ NUEVO (enero 2026) – EVENTOS ESPECIALES (inicio/fin/vacaciones):
// - TipoEventoInstitucional agrega: inicioClases, finClases, vacaciones.
// - EventoInstitucional soporta rango opcional (fechaFin) para vacaciones.
// - fromMap tolera keys legacy y valores desconocidos.
//
// ✅ HARDENING (feb 2026):
// - Getters de compatibilidad: institucionId/perfilId/institucionPerfilId == id
// - No introduce imports a capas de services/guards (evita dependencias circulares).
// - Lectura tolerante: gruposCurriculares / actividadesExtracurriculares también desde JSON string.
//
// ✅ AJUSTE CANÓNICO (feb 2026 · Extracurriculares):
// - Cuando reconstruimos actividades desde Map por bloque (rawExtra Map),
//   inyectamos bloque por `.key` (snake_case) y también `moduleKey`,
//   evitando persistir `.name` como “default” en nuevos paths.
//
// ✅ CANÓNICO (feb 2026 · solicitudes legacy):
// - Se elimina duplicación de SolicitudVacanteInstitucion y EstadoSolicitudInstitucion.
// - La fuente única legacy/compat vive en: lib/models/solicitudes/solicitud_vacante_institucion.dart
// ─────────────────────────────────────────────

import 'dart:convert';

import 'grupo_curricular.dart';

// ✅ CANÓNICO – EXTRACURRICULARES (dominio separado)
import '../extracurriculares/actividad_extracurricular.dart';
import '../extracurriculares/bloque_extracurricular.dart';

// ✅ LEGACY/COMPAT – Solicitud vacante institución (fuente única, sin duplicados)
import '../solicitudes/solicitud_vacante_institucion.dart';

// =====================================================
// ENUMS
// =====================================================

enum EstadoPlanInstitucion { activo, vencido, suspendido, enPrueba, sinPlan }

extension EstadoPlanInstitucionX on EstadoPlanInstitucion {
  // ⚠️ LEGACY/UI: idealmente la UI debe traducir (i18n). Se mantiene por compat.
  String get label {
    switch (this) {
      case EstadoPlanInstitucion.activo:
        return 'Activo';
      case EstadoPlanInstitucion.vencido:
        return 'Vencido';
      case EstadoPlanInstitucion.suspendido:
        return 'Suspendido';
      case EstadoPlanInstitucion.enPrueba:
        return 'En prueba';
      case EstadoPlanInstitucion.sinPlan:
        return 'Sin plan';
    }
  }

  static EstadoPlanInstitucion fromString(String v) {
    final s = v.trim().toLowerCase();
    return EstadoPlanInstitucion.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => EstadoPlanInstitucion.enPrueba,
    );
  }
}

enum TipoInstitucion {
  jardin,
  primaria,
  secundaria,
  tecnica,
  terciario,
  taller,
  club,
  otra,
}

extension TipoInstitucionX on TipoInstitucion {
  static TipoInstitucion fromString(String v) {
    final s = v.trim().toLowerCase();
    return TipoInstitucion.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => TipoInstitucion.otra,
    );
  }
}

/// Tipos de evento institucional.
/// - Se mantiene compat con valores legacy.
/// - Se agregan tipos “especiales” para calendario escolar/institucional.
enum TipoEventoInstitucional {
  examen,
  reunionPadres,
  actividadCurricular,
  actividadExtracurricular,

  // ✅ NUEVO: eventos institucionales especiales
  inicioClases,
  finClases,
  vacaciones,
}

extension TipoEventoInstitucionalX on TipoEventoInstitucional {
  static TipoEventoInstitucional fromString(String v) {
    final s = v.trim();

    // Compat: aceptar variantes comunes
    final sl = s.toLowerCase();
    if (sl == 'inicio' || sl == 'inicio_clases' || sl == 'inicioclases') {
      return TipoEventoInstitucional.inicioClases;
    }
    if (sl == 'fin' || sl == 'fin_clases' || sl == 'finclases') {
      return TipoEventoInstitucional.finClases;
    }
    if (sl == 'vacacion' || sl == 'vacaciones' || sl == 'receso') {
      return TipoEventoInstitucional.vacaciones;
    }

    return TipoEventoInstitucional.values.firstWhere(
      (e) => e.name.toLowerCase() == sl,
      orElse: () => TipoEventoInstitucional.actividadCurricular,
    );
  }
}

enum TipoBoletin { curricular, extracurricular }

extension TipoBoletinX on TipoBoletin {
  static TipoBoletin fromString(String v) {
    final s = v.trim().toLowerCase();
    return TipoBoletin.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => TipoBoletin.curricular,
    );
  }
}

enum EstadoCupo { disponible, completo, suspendido }

extension EstadoCupoX on EstadoCupo {
  static EstadoCupo fromString(String v) {
    final s = v.trim().toLowerCase();
    return EstadoCupo.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => EstadoCupo.disponible,
    );
  }
}

// =====================================================
// ✅ UBICACIÓN + MODALIDAD (CANÓNICO)
// =====================================================

enum ModalidadCursado { presencial, remoto, hibrido }

extension ModalidadCursadoX on ModalidadCursado {
  /// ✅ CANÓNICO: key estable (sin tildes, backend-ready).
  String get key {
    switch (this) {
      case ModalidadCursado.presencial:
        return 'presencial';
      case ModalidadCursado.remoto:
        return 'remoto';
      case ModalidadCursado.hibrido:
        return 'hibrido';
    }
  }

  // ⚠️ LEGACY/UI: idealmente la UI debe traducir (i18n). Se mantiene por compat.
  String get label {
    switch (this) {
      case ModalidadCursado.presencial:
        return 'Presencial';
      case ModalidadCursado.remoto:
        return 'Remoto';
      case ModalidadCursado.hibrido:
        return 'Híbrido';
    }
  }

  static ModalidadCursado fromString(String v) {
    final s = v.trim().toLowerCase();

    // Aceptamos variantes típicas
    if (s == 'híbrido' || s == 'hibrido' || s == 'mixto') {
      return ModalidadCursado.hibrido;
    }
    if (s == 'remoto' || s == 'online' || s == 'virtual') {
      return ModalidadCursado.remoto;
    }
    if (s == 'presencial') {
      return ModalidadCursado.presencial;
    }

    // default seguro
    return ModalidadCursado.presencial;
  }
}

// =====================================================
// ✅ PLAN CANÓNICO (institución crece dentro del mismo perfil)
// =====================================================

enum NivelCurricular { jardin, primaria, secundaria, tecnica, terciario }

extension NivelCurricularX on NivelCurricular {
  static NivelCurricular fromString(String v) {
    final s = v.trim().toLowerCase();
    return NivelCurricular.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => NivelCurricular.primaria,
    );
  }

  static NivelCurricular fromTipoInstitucion(TipoInstitucion t) {
    switch (t) {
      case TipoInstitucion.jardin:
        return NivelCurricular.jardin;
      case TipoInstitucion.primaria:
        return NivelCurricular.primaria;
      case TipoInstitucion.secundaria:
        return NivelCurricular.secundaria;
      case TipoInstitucion.tecnica:
        return NivelCurricular.tecnica;
      case TipoInstitucion.terciario:
        return NivelCurricular.terciario;
      default:
        return NivelCurricular.primaria;
    }
  }
}

class PlanNivelCurricular {
  final NivelCurricular nivel;
  final bool habilitado;

  final String? nombrePropio;
  final int? maxGrupos;
  final int? maxVacantes;

  const PlanNivelCurricular({
    required this.nivel,
    required this.habilitado,
    this.nombrePropio,
    this.maxGrupos,
    this.maxVacantes,
  });

  PlanNivelCurricular copyWith({
    NivelCurricular? nivel,
    bool? habilitado,
    String? nombrePropio,
    int? maxGrupos,
    int? maxVacantes,
  }) {
    return PlanNivelCurricular(
      nivel: nivel ?? this.nivel,
      habilitado: habilitado ?? this.habilitado,
      nombrePropio: nombrePropio ?? this.nombrePropio,
      maxGrupos: maxGrupos ?? this.maxGrupos,
      maxVacantes: maxVacantes ?? this.maxVacantes,
    );
  }

  Map<String, dynamic> toMap() => {
    'nivel': nivel.name,
    'habilitado': habilitado,
    'nombrePropio': nombrePropio,
    'maxGrupos': maxGrupos,
    'maxVacantes': maxVacantes,
  };

  factory PlanNivelCurricular.fromMap(Map<String, dynamic> m) {
    return PlanNivelCurricular(
      nivel: NivelCurricularX.fromString((m['nivel'] ?? '').toString()),
      habilitado: _asBool(m['habilitado']),
      nombrePropio: m['nombrePropio']?.toString(),
      maxGrupos: m['maxGrupos'] == null ? null : _asInt(m['maxGrupos']),
      maxVacantes: m['maxVacantes'] == null ? null : _asInt(m['maxVacantes']),
    );
  }
}

class PlanModuloExtracurricular {
  final BloqueExtracurricular bloque;
  final bool habilitado;

  final int? maxActividades;
  final int? maxGrupos;

  const PlanModuloExtracurricular({
    required this.bloque,
    required this.habilitado,
    this.maxActividades,
    this.maxGrupos,
  });

  PlanModuloExtracurricular copyWith({
    BloqueExtracurricular? bloque,
    bool? habilitado,
    int? maxActividades,
    int? maxGrupos,
  }) {
    return PlanModuloExtracurricular(
      bloque: bloque ?? this.bloque,
      habilitado: habilitado ?? this.habilitado,
      maxActividades: maxActividades ?? this.maxActividades,
      maxGrupos: maxGrupos ?? this.maxGrupos,
    );
  }

  Map<String, dynamic> toMap() => {
    // ✅ CANÓNICO: bloque por key estable (snake_case)
    'bloque': bloque.key,
    'habilitado': habilitado,
    'maxActividades': maxActividades,
    'maxGrupos': maxGrupos,
  };

  factory PlanModuloExtracurricular.fromMap(Map<String, dynamic> m) {
    final parsed =
        BloqueExtracurricularX.tryParseAny(m['bloque']) ??
        BloqueExtracurricular.otros;

    return PlanModuloExtracurricular(
      bloque: parsed,
      habilitado: _asBool(m['habilitado']),
      maxActividades: m['maxActividades'] == null
          ? null
          : _asInt(m['maxActividades']),
      maxGrupos: m['maxGrupos'] == null ? null : _asInt(m['maxGrupos']),
    );
  }
}

class PlanInstitucionConfig {
  final List<PlanNivelCurricular> niveles;
  final List<PlanModuloExtracurricular> modulos;

  final int? maxAlumnos;
  final int? maxGruposTotales;

  const PlanInstitucionConfig({
    required this.niveles,
    required this.modulos,
    this.maxAlumnos,
    this.maxGruposTotales,
  });

  PlanInstitucionConfig copyWith({
    List<PlanNivelCurricular>? niveles,
    List<PlanModuloExtracurricular>? modulos,
    int? maxAlumnos,
    int? maxGruposTotales,
  }) {
    return PlanInstitucionConfig(
      niveles: niveles ?? this.niveles,
      modulos: modulos ?? this.modulos,
      maxAlumnos: maxAlumnos ?? this.maxAlumnos,
      maxGruposTotales: maxGruposTotales ?? this.maxGruposTotales,
    );
  }

  Map<String, dynamic> toMap() => {
    'niveles': niveles.map((e) => e.toMap()).toList(),
    'modulos': modulos.map((e) => e.toMap()).toList(),
    'maxAlumnos': maxAlumnos,
    'maxGruposTotales': maxGruposTotales,
  };

  factory PlanInstitucionConfig.fromMap(Map<String, dynamic> m) {
    final nivelesRaw = m['niveles'];
    final modulosRaw = m['modulos'];

    final niveles = _asList<PlanNivelCurricular>(
      nivelesRaw,
      (e) => PlanNivelCurricular.fromMap(_asMap(e)),
    );

    final modulos = _asList<PlanModuloExtracurricular>(
      modulosRaw,
      (e) => PlanModuloExtracurricular.fromMap(_asMap(e)),
    );

    return PlanInstitucionConfig(
      niveles: niveles,
      modulos: modulos,
      maxAlumnos: m['maxAlumnos'] == null ? null : _asInt(m['maxAlumnos']),
      maxGruposTotales: m['maxGruposTotales'] == null
          ? null
          : _asInt(m['maxGruposTotales']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PlanInstitucionConfig.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return PlanInstitucionConfig.fromMap(_asMap(decoded));
    }
    throw FormatException('PlanInstitucionConfig.fromJson: JSON inválido');
  }
}

// =====================================================
// ✅ CROQUIS AULA 10x10 (solo nombres, sin DNI)
// =====================================================

class CroquisGrupo {
  final String id;
  final String titulo;

  // rectángulo inclusive: rMin..rMax / cMin..cMax
  final int rMin;
  final int cMin;
  final int rMax;
  final int cMax;

  const CroquisGrupo({
    required this.id,
    required this.titulo,
    required this.rMin,
    required this.cMin,
    required this.rMax,
    required this.cMax,
  });

  CroquisGrupo copyWith({
    String? id,
    String? titulo,
    int? rMin,
    int? cMin,
    int? rMax,
    int? cMax,
  }) {
    return CroquisGrupo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      rMin: rMin ?? this.rMin,
      cMin: cMin ?? this.cMin,
      rMax: rMax ?? this.rMax,
      cMax: cMax ?? this.cMax,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'rMin': rMin,
    'cMin': cMin,
    'rMax': rMax,
    'cMax': cMax,
  };

  factory CroquisGrupo.fromMap(Map<String, dynamic> m) {
    return CroquisGrupo(
      id: _asString(m['id']).trim(),
      titulo: _asString(m['titulo']).trim(),
      rMin: _asInt(m['rMin']),
      cMin: _asInt(m['cMin']),
      rMax: _asInt(m['rMax']),
      cMax: _asInt(m['cMax']),
    );
  }
}

class CroquisAula10x10 {
  static const int rowsDefault = 10;
  static const int colsDefault = 10;
  static const int sizeDefault = rowsDefault * colsDefault;

  final int rows;
  final int cols;

  final String aula;
  final String turno;

  /// 100 posiciones (10x10). Solo nombres (sin DNI).
  final List<String> nombres;

  final List<CroquisGrupo> grupos;

  final DateTime updatedAt;

  const CroquisAula10x10({
    required this.rows,
    required this.cols,
    required this.aula,
    required this.turno,
    required this.nombres,
    required this.grupos,
    required this.updatedAt,
  });

  factory CroquisAula10x10.empty({
    String aula = 'Aula',
    String turno = 'Turno',
    DateTime? updatedAt,
  }) {
    return CroquisAula10x10(
      rows: rowsDefault,
      cols: colsDefault,
      aula: aula,
      turno: turno,
      nombres: List<String>.filled(sizeDefault, ''),
      grupos: const <CroquisGrupo>[],
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  CroquisAula10x10 copyWith({
    int? rows,
    int? cols,
    String? aula,
    String? turno,
    List<String>? nombres,
    List<CroquisGrupo>? grupos,
    DateTime? updatedAt,
  }) {
    return CroquisAula10x10(
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      aula: aula ?? this.aula,
      turno: turno ?? this.turno,
      nombres: nombres ?? this.nombres,
      grupos: grupos ?? this.grupos,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'rows': rows,
    'cols': cols,
    'aula': aula,
    'turno': turno,
    'nombres': nombres,
    'grupos': grupos.map((g) => g.toMap()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CroquisAula10x10.fromMap(Map<String, dynamic> m) {
    final r = _asInt(m['rows'], fallback: rowsDefault);
    final c = _asInt(m['cols'], fallback: colsDefault);

    // ✅ V1: forzamos 10x10 (normalizamos cualquier otra cosa)
    final rows = (r != rowsDefault) ? rowsDefault : r;
    final cols = (c != colsDefault) ? colsDefault : c;
    final expected = rows * cols;

    // nombres tolerante (List<dynamic> / String json, etc.)
    final rawNames = m['nombres'] ?? m['names'] ?? m['alumnos'] ?? m['cells'];
    final parsedNames = <String>[];
    if (rawNames is List) {
      for (final e in rawNames) {
        parsedNames.add(e?.toString() ?? '');
      }
    } else if (rawNames is String) {
      try {
        final decoded = jsonDecode(rawNames);
        if (decoded is List) {
          for (final e in decoded) {
            parsedNames.add(e?.toString() ?? '');
          }
        }
      } catch (_) {
        // ignore
      }
    }

    // Normalizamos longitud
    final nombres = List<String>.filled(expected, '');
    for (int i = 0; i < nombres.length && i < parsedNames.length; i++) {
      nombres[i] = parsedNames[i].toString();
    }

    final grupos = _asList<CroquisGrupo>(
      m['grupos'],
      (e) => CroquisGrupo.fromMap(_asMap(e)),
    );

    final updatedAt = _asDate(m['updatedAt'], fallback: DateTime.now());

    return CroquisAula10x10(
      rows: rows,
      cols: cols,
      aula: _asString(m['aula'], fallback: 'Aula').trim(),
      turno: _asString(m['turno'], fallback: 'Turno').trim(),
      nombres: nombres,
      grupos: grupos,
      updatedAt: updatedAt,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CroquisAula10x10.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return CroquisAula10x10.fromMap(_asMap(decoded));
    }
    throw FormatException('CroquisAula10x10.fromJson: JSON inválido');
  }
}

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

DateTime? _asDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.round());
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  final p = DateTime.tryParse(s);
  if (p != null) return p;
  final asInt = int.tryParse(s);
  if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  return null;
}

List<T> _asList<T>(dynamic v, T Function(dynamic e) mapFn) {
  if (v is! List) return <T>[];
  final out = <T>[];
  for (final e in v) {
    try {
      out.add(mapFn(e));
    } catch (_) {
      // tolerancia legacy
    }
  }
  return out;
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

String _firstNonEmptyString(List<dynamic> candidates, {String fallback = ''}) {
  for (final c in candidates) {
    final s = _asString(c).trim();
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

// =====================================================
// MODELOS BASE (INSTITUCIÓN + USUARIO)
// =====================================================

class Institucion {
  /// ✅ CANÓNICO:
  /// - En el flujo final, el perfilId de institución es el ID operativo.
  /// - En legacy, puede ser CUIT o un UUID.
  final String id; // CUIT o UUID

  // ✅ Compat/alias: evita divergencias con pantallas/servicios legacy
  String get institucionId => id;
  String get perfilId => id;
  String get institucionPerfilId => id;

  String nombre;
  String cuit;
  String direccion;

  // ✅ NUEVO – Ubicación canónica
  String pais;
  String provincia;
  String ciudad;

  // ✅ NUEVO – Modalidad canónica
  ModalidadCursado modalidad;

  String email;
  String telefono;

  bool curricular;
  bool extracurricular;

  TipoInstitucion tipoInstitucion;

  String tipoPlan;
  EstadoPlanInstitucion estadoPlan;
  DateTime planInicio;
  DateTime planFin;

  String? logoLocalPath;

  /// Legacy/compat: path (imagen/pdf) si alguna vez se guardó así.
  String? croquisLocalPath;

  /// ✅ NUEVO: croquis serializable 10x10 (solo nombres).
  CroquisAula10x10? croquisAula;

  // ✅ Sistema nuevo: Lista de grupos curriculares (fuente de verdad para UI)
  List<GrupoCurricular> gruposCurriculares;

  // ✅ CANÓNICO: Catálogo de actividades extracurriculares (fuente de verdad)
  List<ActividadExtracurricular> actividadesExtracurriculares;

  // ✅ PLAN (explícito si existe; derivado si no existe)
  PlanInstitucionConfig? planConfig;

  // Getter opcional (compatibilidad / semántica)
  List<GrupoCurricular> get obtenerGruposCurriculares => gruposCurriculares;

  Institucion({
    required this.id,
    required this.nombre,
    required this.cuit,
    required this.direccion,
    required this.pais,
    required this.provincia,
    required this.ciudad,
    required this.modalidad,
    required this.email,
    required this.telefono,
    required this.curricular,
    required this.extracurricular,
    required this.tipoInstitucion,
    required this.tipoPlan,
    required this.estadoPlan,
    required this.planInicio,
    required this.planFin,
    this.logoLocalPath,
    this.croquisLocalPath,
    this.croquisAula,
    List<GrupoCurricular>? gruposCurriculares,
    List<ActividadExtracurricular>? actividadesExtracurriculares,
    this.planConfig,
  }) : gruposCurriculares = gruposCurriculares ?? <GrupoCurricular>[],
       actividadesExtracurriculares =
           actividadesExtracurriculares ?? <ActividadExtracurricular>[];

  Institucion copyWith({
    String? id,
    String? nombre,
    String? cuit,
    String? direccion,
    String? pais,
    String? provincia,
    String? ciudad,
    ModalidadCursado? modalidad,
    String? email,
    String? telefono,
    bool? curricular,
    bool? extracurricular,
    TipoInstitucion? tipoInstitucion,
    String? tipoPlan,
    EstadoPlanInstitucion? estadoPlan,
    DateTime? planInicio,
    DateTime? planFin,
    String? logoLocalPath,
    String? croquisLocalPath,
    CroquisAula10x10? croquisAula,
    List<GrupoCurricular>? gruposCurriculares,
    List<ActividadExtracurricular>? actividadesExtracurriculares,
    PlanInstitucionConfig? planConfig,
  }) {
    return Institucion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cuit: cuit ?? this.cuit,
      direccion: direccion ?? this.direccion,
      pais: pais ?? this.pais,
      provincia: provincia ?? this.provincia,
      ciudad: ciudad ?? this.ciudad,
      modalidad: modalidad ?? this.modalidad,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      curricular: curricular ?? this.curricular,
      extracurricular: extracurricular ?? this.extracurricular,
      tipoInstitucion: tipoInstitucion ?? this.tipoInstitucion,
      tipoPlan: tipoPlan ?? this.tipoPlan,
      estadoPlan: estadoPlan ?? this.estadoPlan,
      planInicio: planInicio ?? this.planInicio,
      planFin: planFin ?? this.planFin,
      logoLocalPath: logoLocalPath ?? this.logoLocalPath,
      croquisLocalPath: croquisLocalPath ?? this.croquisLocalPath,
      croquisAula: croquisAula ?? this.croquisAula,
      gruposCurriculares: gruposCurriculares ?? this.gruposCurriculares,
      actividadesExtracurriculares:
          actividadesExtracurriculares ?? this.actividadesExtracurriculares,
      planConfig: planConfig ?? this.planConfig,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    // compat: también guardamos el alias más común (sin obligar a leerlo)
    'institucionId': id,
    'nombre': nombre,
    'cuit': cuit,
    'direccion': direccion,

    // ✅ ubicación + modalidad
    'pais': pais,
    'provincia': provincia,
    'ciudad': ciudad,

    // ✅ CANÓNICO: modalidad por key estable (NO .name)
    'modalidad': modalidad.key,

    'email': email,
    'telefono': telefono,
    'curricular': curricular,
    'extracurricular': extracurricular,
    'tipoInstitucion': tipoInstitucion.name,
    'tipoPlan': tipoPlan,
    'estadoPlan': estadoPlan.name,
    'planInicio': planInicio.toIso8601String(),
    'planFin': planFin.toIso8601String(),
    'logoLocalPath': logoLocalPath,
    'croquisLocalPath': croquisLocalPath,

    // ✅ NUEVO croquis
    'croquisAula': croquisAula?.toMap(),

    // ✅ canónico curricular
    'gruposCurriculares': gruposCurriculares.map((g) => g.toMap()).toList(),

    // ✅ canónico extracurricular
    'actividadesExtracurriculares': actividadesExtracurriculares
        .map((a) => a.toMap())
        .toList(),

    // ✅ plan explícito (si existe)
    'planConfig': planConfig?.toMap(),
  };

  factory Institucion.fromMap(Map<String, dynamic> m) {
    String readId() {
      final id1 = _asString(m['id']).trim();
      if (id1.isNotEmpty) return id1;

      final id2 = _asString(m['institucionId']).trim();
      if (id2.isNotEmpty) return id2;

      final cuit = _asString(m['cuit']).trim();
      if (cuit.isNotEmpty) return cuit;

      return 'inst_${DateTime.now().millisecondsSinceEpoch}';
    }

    final id = readId();

    final now = DateTime.now();
    final inicioParsed = _asDate(m['planInicio'], fallback: now);
    final finParsed0 = _asDate(
      m['planFin'],
      fallback: now.add(const Duration(days: 30)),
    );

    final finParsed = finParsed0.isBefore(inicioParsed)
        ? inicioParsed.add(const Duration(days: 30))
        : finParsed0;

    final curricular = m.containsKey('curricular')
        ? _asBool(m['curricular'])
        : true;
    final extracurricular = m.containsKey('extracurricular')
        ? _asBool(m['extracurricular'])
        : true;

    final tipoPlanRaw = _asString(m['tipoPlan']).trim();
    final tipoPlan = tipoPlanRaw.isEmpty ? 'Prueba' : tipoPlanRaw;

    final estadoPlan = EstadoPlanInstitucionX.fromString(
      _asString(m['estadoPlan'], fallback: 'enPrueba'),
    );

    String readPais() => _firstNonEmptyString([
      m['pais'],
      m['country'],
      m['país'],
      m['paisNombre'],
    ], fallback: 'Argentina').trim();

    String readProvincia() => _firstNonEmptyString([
      m['provincia'],
      m['state'],
      m['provinciaNombre'],
      m['prov'],
    ], fallback: '').trim();

    String readCiudad() => _firstNonEmptyString([
      m['ciudad'],
      m['city'],
      m['localidad'],
      m['municipio'],
    ], fallback: '').trim();

    ModalidadCursado readModalidad() {
      final s = _firstNonEmptyString([
        m['modalidad'],
        m['tipoCursado'],
        m['cursado'],
        m['modalidadCursado'],
      ], fallback: '').trim();
      if (s.isNotEmpty) return ModalidadCursadoX.fromString(s);

      final remoto = _asBool(m['remoto'], fallback: false);
      final presencial = _asBool(m['presencial'], fallback: false);
      final hibrido =
          _asBool(m['hibrido'], fallback: false) ||
          _asBool(m['híbrido'], fallback: false);

      if (hibrido) return ModalidadCursado.hibrido;
      if (remoto) return ModalidadCursado.remoto;
      if (presencial) return ModalidadCursado.presencial;

      return ModalidadCursado.presencial;
    }

    CroquisAula10x10? croquis;
    final rawCroquis = m['croquisAula'] ?? m['croquis_aula'] ?? m['croquis'];
    if (rawCroquis != null) {
      try {
        if (rawCroquis is Map) {
          final map = _asMap(rawCroquis);
          if (map.isNotEmpty) {
            croquis = CroquisAula10x10.fromMap(map);
          }
        } else if (rawCroquis is String) {
          final s = rawCroquis.trim();
          if (s.isNotEmpty) {
            croquis = CroquisAula10x10.fromJson(s);
          }
        }
      } catch (_) {
        croquis = null;
      }
    }

    final inst = Institucion(
      id: id,
      nombre: _asString(m['nombre']).trim(),
      cuit: _asString(m['cuit']).trim(),
      direccion: _asString(m['direccion']).trim(),
      pais: readPais(),
      provincia: readProvincia(),
      ciudad: readCiudad(),
      modalidad: readModalidad(),
      email: _asString(m['email']).trim(),
      telefono: _asString(m['telefono']).trim(),
      curricular: curricular,
      extracurricular: extracurricular,
      tipoInstitucion: TipoInstitucionX.fromString(
        _asString(m['tipoInstitucion'], fallback: 'otra'),
      ),
      tipoPlan: tipoPlan,
      estadoPlan: estadoPlan,
      planInicio: inicioParsed,
      planFin: finParsed,
      logoLocalPath: m['logoLocalPath']?.toString(),
      croquisLocalPath: m['croquisLocalPath']?.toString(),
      croquisAula: croquis,
      planConfig: _leerPlanConfigTolerante(m),
    );

    // ✅ Cargar grupos curriculares (tolerante: List / JSON String)
    final rawGrupos =
        m['gruposCurriculares'] ?? m['grupos_curriculares'] ?? m['grupos'];
    final gruposParsed = <GrupoCurricular>[];

    dynamic rawGruposMaybeList = rawGrupos;
    if (rawGrupos is String) {
      final s = rawGrupos.trim();
      if (s.isNotEmpty) {
        try {
          final decoded = jsonDecode(s);
          rawGruposMaybeList = decoded;
        } catch (_) {
          rawGruposMaybeList = null;
        }
      }
    }

    if (rawGruposMaybeList is List) {
      for (final e in rawGruposMaybeList) {
        if (e is Map) {
          try {
            gruposParsed.add(GrupoCurricular.fromMap(_asMap(e)));
          } catch (_) {
            // tolerancia
          }
        }
      }
    }

    if (gruposParsed.isNotEmpty) {
      inst.gruposCurriculares = gruposParsed;
    }

    // ✅ Cargar catálogo extracurriculares (tolerante: List / Map / JSON String)
    final rawExtra =
        m['actividadesExtracurriculares'] ??
        m['extracurriculares'] ??
        m['actividades_extra'];

    dynamic rawExtraResolved = rawExtra;
    if (rawExtra is String) {
      final s = rawExtra.trim();
      if (s.isNotEmpty) {
        try {
          rawExtraResolved = jsonDecode(s);
        } catch (_) {
          rawExtraResolved = null;
        }
      }
    }

    if (rawExtraResolved is List) {
      final parsed = <ActividadExtracurricular>[];
      for (final e in rawExtraResolved) {
        if (e is Map) {
          try {
            parsed.add(ActividadExtracurricular.fromMap(_asMap(e)));
          } catch (_) {
            // tolerancia
          }
        }
      }
      if (parsed.isNotEmpty) {
        inst.actividadesExtracurriculares = parsed;
      }
    } else if (rawExtraResolved is Map) {
      final map = _asMap(rawExtraResolved);
      final parsed = <ActividadExtracurricular>[];
      for (final entry in map.entries) {
        final bloque =
            BloqueExtracurricularX.tryParseAny(entry.key.toString()) ??
            BloqueExtracurricular.otros;

        final v = entry.value;
        if (v is List) {
          for (final e in v) {
            if (e is Map) {
              try {
                parsed.add(_actividadExtraFromMapConBloque(_asMap(e), bloque));
              } catch (_) {
                // tolerancia
              }
            }
          }
        }
      }
      if (parsed.isNotEmpty) {
        inst.actividadesExtracurriculares = parsed;
      }
    }

    return inst;
  }

  static ActividadExtracurricular _actividadExtraFromMapConBloque(
    Map<String, dynamic> base,
    BloqueExtracurricular bloque,
  ) {
    final m = Map<String, dynamic>.from(base);

    // ✅ FIX: Si viene "bloqueExtracurricular" pero NO viene "bloque/bloqueKey/moduleKey",
    // lo normalizamos a la forma que ActividadExtracurricular.fromMap() realmente lee.
    if (!m.containsKey('bloque') &&
        !m.containsKey('bloqueKey') &&
        !m.containsKey('moduleKey') &&
        m.containsKey('bloqueExtracurricular')) {
      final raw = m['bloqueExtracurricular'];
      final parsed = BloqueExtracurricularX.tryParseAny(raw);
      final k = (parsed ?? bloque).key;
      m['bloque'] = k;
      m['moduleKey'] = k;
      m['bloqueKey'] = k;
    }

    // ✅ Si viene sin bloque/moduleKey, inyectamos CANÓNICO (key snake_case).
    final hasBloqueReal =
        m.containsKey('bloque') ||
        m.containsKey('bloqueKey') ||
        m.containsKey('moduleKey');

    if (!hasBloqueReal) {
      final k = bloque.key;
      m['bloque'] = k;
      m['moduleKey'] = k;

      // alias de lectura (si algún legacy lo esperaba)
      m['bloqueKey'] = k;
      m['bloqueExtracurricular'] = k;
    }

    return ActividadExtracurricular.fromMap(m);
  }

  static PlanInstitucionConfig? _leerPlanConfigTolerante(
    Map<String, dynamic> m,
  ) {
    final raw = m['planConfig'] ?? m['plan_config'] ?? m['plan'];
    if (raw == null) return null;

    try {
      if (raw is Map) {
        final map = _asMap(raw);
        if (map.isEmpty) return null;
        return PlanInstitucionConfig.fromMap(map);
      }
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return null;
        return PlanInstitucionConfig.fromJson(s);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String toJson() => jsonEncode(toMap());

  factory Institucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return Institucion.fromMap(_asMap(decoded));
    }
    throw FormatException('Institucion.fromJson: JSON inválido');
  }
}

/// Extensión operativa del plan:
/// - Si planConfig existe: fuente de verdad.
/// - Si no existe: derivamos un plan “safe” a partir de data REAL (grupos/actividades),
///   y recién si eso no alcanza, caemos a flags legacy.
extension InstitucionPlanX on Institucion {
  bool get tienePlanExplicito => planConfig != null;

  Set<NivelCurricular> _inferNivelesDesdeGrupos() {
    final out = <NivelCurricular>{};

    try {
      for (final g in gruposCurriculares) {
        try {
          // ignore: avoid_dynamic_calls
          final dyn = g as dynamic;

          // ignore: avoid_dynamic_calls
          final v1 = dyn.nivel;
          // ignore: avoid_dynamic_calls
          final v2 = dyn.nivelCurricular;
          // ignore: avoid_dynamic_calls
          final v3 = dyn.tipoNivel;
          // ignore: avoid_dynamic_calls
          final v4 = dyn.nivelKey;

          final candidates = <dynamic>[v1, v2, v3, v4];
          for (final c in candidates) {
            if (c == null) continue;
            if (c is NivelCurricular) {
              out.add(c);
              continue;
            }
            final s = c.toString().trim();
            if (s.isEmpty) continue;
            final cleaned = s.contains('.') ? s.split('.').last : s;
            out.add(NivelCurricularX.fromString(cleaned));
          }
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {}

    return out;
  }

  Set<BloqueExtracurricular> _inferBloquesDesdeActividades() {
    final out = <BloqueExtracurricular>{};

    try {
      for (final a in actividadesExtracurriculares) {
        try {
          // ignore: avoid_dynamic_calls
          final dyn = a as dynamic;

          // ignore: avoid_dynamic_calls
          final v1 = dyn.bloque;
          // ignore: avoid_dynamic_calls
          final v2 = dyn.bloqueExtracurricular;
          // ignore: avoid_dynamic_calls
          final v3 = dyn.bloqueKey;

          final candidates = <dynamic>[v1, v2, v3];
          for (final c in candidates) {
            if (c == null) continue;
            if (c is BloqueExtracurricular) {
              out.add(c);
              continue;
            }
            final s = c.toString().trim();
            if (s.isEmpty) continue;
            final cleaned = s.contains('.') ? s.split('.').last : s;
            final parsed =
                BloqueExtracurricularX.tryParseAny(cleaned) ??
                BloqueExtracurricular.otros;
            out.add(parsed);
          }
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {}

    return out;
  }

  PlanInstitucionConfig get planSafe {
    final explicit = planConfig;
    if (explicit != null) return explicit;

    final nivelesDerivados = _inferNivelesDesdeGrupos();
    final bloquesDerivados = _inferBloquesDesdeActividades();

    final niveles = <PlanNivelCurricular>[];
    if (curricular) {
      if (nivelesDerivados.isNotEmpty) {
        for (final n in nivelesDerivados) {
          niveles.add(
            PlanNivelCurricular(
              nivel: n,
              habilitado: true,
              nombrePropio: null,
              maxGrupos: null,
              maxVacantes: null,
            ),
          );
        }
      } else {
        final n = NivelCurricularX.fromTipoInstitucion(tipoInstitucion);
        niveles.add(
          PlanNivelCurricular(
            nivel: n,
            habilitado: true,
            nombrePropio: null,
            maxGrupos: null,
            maxVacantes: null,
          ),
        );
      }
    }

    final modulos = <PlanModuloExtracurricular>[];
    if (extracurricular) {
      if (bloquesDerivados.isNotEmpty) {
        for (final b in bloquesDerivados) {
          modulos.add(
            PlanModuloExtracurricular(
              bloque: b,
              habilitado: true,
              maxActividades: null,
              maxGrupos: null,
            ),
          );
        }
      } else {
        for (final b in BloqueExtracurricular.values) {
          modulos.add(
            PlanModuloExtracurricular(
              bloque: b,
              habilitado: true,
              maxActividades: null,
              maxGrupos: null,
            ),
          );
        }
      }
    }

    return PlanInstitucionConfig(
      niveles: niveles,
      modulos: modulos,
      maxAlumnos: null,
      maxGruposTotales: null,
    );
  }

  bool moduloHabilitado(BloqueExtracurricular bloque) {
    for (final x in planSafe.modulos) {
      if (x.bloque == bloque) return x.habilitado;
    }
    return false;
  }

  bool nivelHabilitado(NivelCurricular nivel) {
    for (final x in planSafe.niveles) {
      if (x.nivel == nivel) return x.habilitado;
    }
    return false;
  }
}

/// ⚠️ LEGACY: se mantiene para compatibilidad/compilación.
class InstitucionUsuario {
  final String institucionId;
  final String email;
  final String passwordHash;

  InstitucionUsuario({
    required this.institucionId,
    required this.email,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'email': email,
    'passwordHash': passwordHash,
  };

  factory InstitucionUsuario.fromMap(Map<String, dynamic> m) =>
      InstitucionUsuario(
        institucionId: _asString(m['institucionId']).trim(),
        email: _asString(m['email']).trim(),
        passwordHash: _asString(m['passwordHash']),
      );
}

// =====================================================
// PERFIL + ACTIVIDADES + GRUPOS (LEGACY)
// =====================================================

class ActividadInstitucional {
  final String id;
  final String institucionId;

  String nombre;
  bool esCurricular;
  bool esExtracurricular;

  String? descripcion;
  String? edades;
  String? horario;
  String? precio;

  ActividadInstitucional({
    required this.id,
    required this.institucionId,
    required this.nombre,
    required this.esCurricular,
    required this.esExtracurricular,
    this.descripcion,
    this.edades,
    this.horario,
    this.precio,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    'nombre': nombre,
    'esCurricular': esCurricular,
    'esExtracurricular': esExtracurricular,
    'descripcion': descripcion,
    'edades': edades,
    'horario': horario,
    'precio': precio,
  };

  factory ActividadInstitucional.fromMap(Map<String, dynamic> m) =>
      ActividadInstitucional(
        id: _asString(m['id']).trim(),
        institucionId: _asString(m['institucionId']).trim(),
        nombre: _asString(m['nombre']).trim(),
        esCurricular: _asBool(m['esCurricular']),
        esExtracurricular: _asBool(m['esExtracurricular']),
        descripcion: m['descripcion']?.toString(),
        edades: m['edades']?.toString(),
        horario: m['horario']?.toString(),
        precio: m['precio']?.toString(),
      );
}

class GrupoInstitucional {
  final String id;
  final String institucionId;

  final String actividadNombre;
  String nombreGrupo;
  String? aula;
  String? turno;

  int cupoMaximo;
  int cupoOcupado;
  EstadoCupo estado;

  GrupoInstitucional({
    required this.id,
    required this.institucionId,
    required this.actividadNombre,
    required this.nombreGrupo,
    required this.cupoMaximo,
    required this.cupoOcupado,
    required this.estado,
    this.aula,
    this.turno,
  });

  int get cupoDisponible => (cupoMaximo - cupoOcupado).clamp(0, 9999);

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    'actividadNombre': actividadNombre,
    'nombreGrupo': nombreGrupo,
    'aula': aula,
    'turno': turno,
    'cupoMaximo': cupoMaximo,
    'cupoOcupado': cupoOcupado,
    'estado': estado.name,
  };

  factory GrupoInstitucional.fromMap(Map<String, dynamic> m) =>
      GrupoInstitucional(
        id: _asString(m['id']).trim(),
        institucionId: _asString(m['institucionId']).trim(),
        actividadNombre: _asString(m['actividadNombre']).trim(),
        nombreGrupo: _asString(m['nombreGrupo']).trim(),
        aula: m['aula']?.toString(),
        turno: m['turno']?.toString(),
        cupoMaximo: _asInt(m['cupoMaximo']),
        cupoOcupado: _asInt(m['cupoOcupado']),
        estado: EstadoCupoX.fromString(
          _asString(m['estado'], fallback: 'disponible'),
        ),
      );
}

/// ⚠️ LEGACY: evitar usar en módulos nuevos.
/// Nota: el nombre colisiona con el PerfilInstitucion canónico (instituciones_integradas.dart)
/// si un archivo importa ambos. En esos casos, usar import prefix.
class PerfilInstitucion {
  final String institucionId;
  final List<ActividadInstitucional> actividades;
  final List<GrupoInstitucional> grupos;
  String? observaciones;

  PerfilInstitucion({
    required this.institucionId,
    required this.actividades,
    required this.grupos,
    this.observaciones,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'actividades': actividades.map((e) => e.toMap()).toList(),
    'grupos': grupos.map((e) => e.toMap()).toList(),
    'observaciones': observaciones,
  };

  factory PerfilInstitucion.fromMap(Map<String, dynamic> m) {
    final acts = _asList<ActividadInstitucional>(
      m['actividades'],
      (e) => ActividadInstitucional.fromMap(_asMap(e)),
    );

    final grps = _asList<GrupoInstitucional>(
      m['grupos'],
      (e) => GrupoInstitucional.fromMap(_asMap(e)),
    );

    return PerfilInstitucion(
      institucionId: _asString(m['institucionId']).trim(),
      actividades: acts,
      grupos: grps,
      observaciones: m['observaciones']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PerfilInstitucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return PerfilInstitucion.fromMap(_asMap(decoded));
    }
    throw FormatException('PerfilInstitucion.fromJson: JSON inválido');
  }
}

// =====================================================
// AGENDA + EVENTOS
// =====================================================

class EventoInstitucional {
  final String id;
  final String institucionId;

  final String titulo;

  /// Fecha inicio (o única).
  final DateTime fecha;

  /// Fecha fin opcional (vacaciones / rangos).
  final DateTime? fechaFin;

  final TipoEventoInstitucional tipo;

  final bool requiereConfirmacion;
  final List<String> alumnosDni;

  EventoInstitucional({
    required this.id,
    required this.institucionId,
    required this.titulo,
    required this.fecha,
    required this.tipo,
    required this.requiereConfirmacion,
    required this.alumnosDni,
    this.fechaFin,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    'titulo': titulo,
    'fecha': fecha.toIso8601String(),
    if (fechaFin != null) 'fechaFin': fechaFin!.toIso8601String(),
    'tipo': tipo.name,
    'requiereConfirmacion': requiereConfirmacion,
    'alumnosDni': alumnosDni,
  };

  factory EventoInstitucional.fromMap(Map<String, dynamic> m) {
    final alumnos = _asList<String>(m['alumnosDni'], (e) => e.toString());

    final fecha = _asDate(
      m['fecha'] ?? m['inicio'] ?? m['start'],
      fallback: DateTime.now(),
    );

    final rawFin = m['fechaFin'] ?? m['fin'] ?? m['end'];
    final fechaFin = _asDateOrNull(rawFin);

    return EventoInstitucional(
      id: _asString(m['id']).trim(),
      institucionId: _asString(m['institucionId']).trim(),
      titulo: _asString(m['titulo']).trim(),
      fecha: fecha,
      fechaFin: fechaFin,
      tipo: TipoEventoInstitucionalX.fromString(
        _asString(m['tipo'], fallback: 'actividadCurricular'),
      ),
      requiereConfirmacion: _asBool(m['requiereConfirmacion']),
      alumnosDni: alumnos,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory EventoInstitucional.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return EventoInstitucional.fromMap(_asMap(decoded));
    }
    throw FormatException('EventoInstitucional.fromJson: JSON inválido');
  }
}

// =====================================================
// BOLETINES + DOCUMENTOS
// =====================================================

class BoletinInstitucional {
  final String alumnoDocumento;
  final String institucionId;
  final TipoBoletin tipo;
  final String periodo;
  final Map<String, double> notas;

  BoletinInstitucional({
    required this.alumnoDocumento,
    required this.institucionId,
    required this.tipo,
    required this.periodo,
    required this.notas,
  });

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucionId': institucionId,
    'tipo': tipo.name,
    'periodo': periodo,
    'notas': notas,
  };

  factory BoletinInstitucional.fromMap(Map<String, dynamic> m) {
    final notasRaw = m['notas'];
    final out = <String, double>{};

    if (notasRaw is Map) {
      for (final entry in notasRaw.entries) {
        final k = entry.key.toString();
        final v = entry.value;
        final d = (v is num)
            ? v.toDouble()
            : double.tryParse(v.toString()) ?? 0.0;
        out[k] = d;
      }
    }

    return BoletinInstitucional(
      alumnoDocumento: _asString(m['alumnoDocumento']).trim(),
      institucionId: _asString(m['institucionId']).trim(),
      tipo: TipoBoletinX.fromString(
        _asString(m['tipo'], fallback: 'curricular'),
      ),
      periodo: _asString(m['periodo']).trim(),
      notas: out,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BoletinInstitucional.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return BoletinInstitucional.fromMap(_asMap(decoded));
    }
    throw FormatException('BoletinInstitucional.fromJson: JSON inválido');
  }
}

class DocumentoRequeridoInstitucion {
  final String alumnoDocumento;
  final String descripcion;
  bool entregado;

  DocumentoRequeridoInstitucion({
    required this.alumnoDocumento,
    required this.descripcion,
    required this.entregado,
  });

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'descripcion': descripcion,
    'entregado': entregado,
  };

  factory DocumentoRequeridoInstitucion.fromMap(Map<String, dynamic> m) {
    return DocumentoRequeridoInstitucion(
      alumnoDocumento: _asString(m['alumnoDocumento']).trim(),
      descripcion: _asString(m['descripcion']).trim(),
      entregado: _asBool(m['entregado']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DocumentoRequeridoInstitucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return DocumentoRequeridoInstitucion.fromMap(_asMap(decoded));
    }
    throw FormatException(
      'DocumentoRequeridoInstitucion.fromJson: JSON inválido',
    );
  }
}

// =====================================================
// TRAYECTORIA INSTITUCIONAL CONSOLIDADA
// =====================================================

class TrayectoriaInstitucional {
  final String institucionId;

  final List<ActividadInstitucional> actividades;
  final List<GrupoInstitucional> grupos;

  // ✅ LEGACY/COMPAT: ahora viene del archivo dedicado (sin duplicados)
  final List<SolicitudVacanteInstitucion> solicitudes;

  final List<EventoInstitucional> eventos;

  TrayectoriaInstitucional({
    required this.institucionId,
    required this.actividades,
    required this.grupos,
    required this.solicitudes,
    required this.eventos,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'actividades': actividades.map((e) => e.toMap()).toList(),
    'grupos': grupos.map((e) => e.toMap()).toList(),
    'solicitudes': solicitudes.map((e) => e.toMap()).toList(),
    'eventos': eventos.map((e) => e.toMap()).toList(),
  };

  factory TrayectoriaInstitucional.fromMap(Map<String, dynamic> m) {
    List<ActividadInstitucional> acts(dynamic v) =>
        _asList<ActividadInstitucional>(
          v,
          (e) => ActividadInstitucional.fromMap(_asMap(e)),
        );

    List<GrupoInstitucional> grps(dynamic v) => _asList<GrupoInstitucional>(
      v,
      (e) => GrupoInstitucional.fromMap(_asMap(e)),
    );

    List<SolicitudVacanteInstitucion> sols(dynamic v) =>
        _asList<SolicitudVacanteInstitucion>(
          v,
          (e) => SolicitudVacanteInstitucion.fromMap(_asMap(e)),
        );

    List<EventoInstitucional> evs(dynamic v) => _asList<EventoInstitucional>(
      v,
      (e) => EventoInstitucional.fromMap(_asMap(e)),
    );

    return TrayectoriaInstitucional(
      institucionId: _asString(m['institucionId']).trim(),
      actividades: acts(m['actividades']),
      grupos: grps(m['grupos']),
      solicitudes: sols(m['solicitudes']),
      eventos: evs(m['eventos']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TrayectoriaInstitucional.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return TrayectoriaInstitucional.fromMap(_asMap(decoded));
    }
    throw FormatException('TrayectoriaInstitucional.fromJson: JSON inválido');
  }
}
