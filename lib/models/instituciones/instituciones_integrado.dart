// lib/models/instituciones/instituciones_integrado.dart
//
// Institución: datos de registro, ubicación, modalidad y plan contratado
// (niveles curriculares y módulos extracurriculares habilitados).
//
// La lectura es tolerante con datos guardados por versiones anteriores
// (nombres de campo alternativos y valores desconocidos caen a un valor seguro).
// Las vacantes, solicitudes, eventos y croquis viven en `lib/core`.

import 'dart:convert';

import '../extracurriculares/bloque_extracurricular.dart';

// =====================================================
// ENUMS
// =====================================================

enum EstadoPlanInstitucion { activo, vencido, suspendido, enPrueba, sinPlan }

extension EstadoPlanInstitucionX on EstadoPlanInstitucion {
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

enum ModalidadCursado { presencial, remoto, hibrido }

extension ModalidadCursadoX on ModalidadCursado {
  /// Clave estable para guardar (sin tildes).
  String get key => name;

  static ModalidadCursado fromString(String v) {
    final s = v.trim().toLowerCase();
    if (s == 'híbrido' || s == 'hibrido' || s == 'mixto') {
      return ModalidadCursado.hibrido;
    }
    if (s == 'remoto' || s == 'online' || s == 'virtual') {
      return ModalidadCursado.remoto;
    }
    return ModalidadCursado.presencial;
  }
}

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

// =====================================================
// PLAN
// =====================================================

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
    // Bloque por clave estable (snake_case).
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
    return PlanInstitucionConfig(
      niveles: _asList<PlanNivelCurricular>(
        m['niveles'],
        (e) => PlanNivelCurricular.fromMap(_asMap(e)),
      ),
      modulos: _asList<PlanModuloExtracurricular>(
        m['modulos'],
        (e) => PlanModuloExtracurricular.fromMap(_asMap(e)),
      ),
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
    throw const FormatException(
      'PlanInstitucionConfig.fromJson: JSON inválido',
    );
  }
}

// =====================================================
// LECTURA TOLERANTE
// =====================================================

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString().trim()) ?? fallback;
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

List<T> _asList<T>(dynamic v, T Function(dynamic e) mapFn) {
  if (v is! List) return <T>[];
  final out = <T>[];
  for (final e in v) {
    try {
      out.add(mapFn(e));
    } catch (_) {
      // Un elemento ilegible no invalida el resto.
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
// INSTITUCIÓN
// =====================================================

class Institucion {
  /// Identificador de la institución (coincide con su perfil y su cuenta).
  final String id;

  String nombre;
  String cuit;
  String direccion;

  String pais;
  String provincia;
  String ciudad;

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

  /// Plan elegido. Si falta (datos antiguos) se deriva con [planSafe].
  PlanInstitucionConfig? planConfig;

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
    this.planConfig,
  });

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
      planConfig: planConfig ?? this.planConfig,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': id,
    'nombre': nombre,
    'cuit': cuit,
    'direccion': direccion,
    'pais': pais,
    'provincia': provincia,
    'ciudad': ciudad,
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
    'planConfig': planConfig?.toMap(),
  };

  factory Institucion.fromMap(Map<String, dynamic> m) {
    final id = _firstNonEmptyString([
      m['id'],
      m['institucionId'],
      m['cuit'],
    ], fallback: 'inst_${DateTime.now().millisecondsSinceEpoch}').trim();

    final now = DateTime.now();
    final inicio = _asDate(m['planInicio'], fallback: now);
    final finLeido = _asDate(
      m['planFin'],
      fallback: now.add(const Duration(days: 30)),
    );
    final fin = finLeido.isBefore(inicio)
        ? inicio.add(const Duration(days: 30))
        : finLeido;

    final tipoPlan = _asString(m['tipoPlan']).trim();

    ModalidadCursado modalidad() {
      final s = _firstNonEmptyString([
        m['modalidad'],
        m['tipoCursado'],
        m['cursado'],
        m['modalidadCursado'],
      ]).trim();
      if (s.isNotEmpty) return ModalidadCursadoX.fromString(s);
      if (_asBool(m['hibrido']) || _asBool(m['híbrido'])) {
        return ModalidadCursado.hibrido;
      }
      if (_asBool(m['remoto'])) return ModalidadCursado.remoto;
      return ModalidadCursado.presencial;
    }

    return Institucion(
      id: id,
      nombre: _asString(m['nombre']).trim(),
      cuit: _asString(m['cuit']).trim(),
      direccion: _asString(m['direccion']).trim(),
      pais: _firstNonEmptyString([
        m['pais'],
        m['country'],
        m['país'],
        m['paisNombre'],
      ], fallback: 'Argentina').trim(),
      provincia: _firstNonEmptyString([
        m['provincia'],
        m['state'],
        m['provinciaNombre'],
        m['prov'],
      ]).trim(),
      ciudad: _firstNonEmptyString([
        m['ciudad'],
        m['city'],
        m['localidad'],
        m['municipio'],
      ]).trim(),
      modalidad: modalidad(),
      email: _asString(m['email']).trim(),
      telefono: _asString(m['telefono']).trim(),
      curricular: m.containsKey('curricular') ? _asBool(m['curricular']) : true,
      extracurricular: m.containsKey('extracurricular')
          ? _asBool(m['extracurricular'])
          : true,
      tipoInstitucion: TipoInstitucionX.fromString(
        _asString(m['tipoInstitucion'], fallback: 'otra'),
      ),
      tipoPlan: tipoPlan.isEmpty ? 'Prueba' : tipoPlan,
      estadoPlan: EstadoPlanInstitucionX.fromString(
        _asString(m['estadoPlan'], fallback: 'enPrueba'),
      ),
      planInicio: inicio,
      planFin: fin,
      planConfig: _leerPlanConfig(m),
    );
  }

  static PlanInstitucionConfig? _leerPlanConfig(Map<String, dynamic> m) {
    final raw = m['planConfig'] ?? m['plan_config'] ?? m['plan'];
    try {
      if (raw is Map) {
        final map = _asMap(raw);
        return map.isEmpty ? null : PlanInstitucionConfig.fromMap(map);
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return PlanInstitucionConfig.fromJson(raw.trim());
      }
    } catch (_) {}
    return null;
  }

  String toJson() => jsonEncode(toMap());

  factory Institucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return Institucion.fromMap(_asMap(decoded));
    }
    throw const FormatException('Institucion.fromJson: JSON inválido');
  }
}

extension InstitucionPlanX on Institucion {
  /// Plan vigente: el elegido o, en datos antiguos sin plan guardado, uno
  /// derivado del tipo de institución (su nivel) y de todos los módulos.
  PlanInstitucionConfig get planSafe {
    final explicito = planConfig;
    if (explicito != null) return explicito;

    return PlanInstitucionConfig(
      niveles: [
        if (curricular)
          PlanNivelCurricular(
            nivel: NivelCurricularX.fromTipoInstitucion(tipoInstitucion),
            habilitado: true,
          ),
      ],
      modulos: [
        if (extracurricular)
          for (final b in BloqueExtracurricular.values)
            PlanModuloExtracurricular(bloque: b, habilitado: true),
      ],
    );
  }

  bool nivelHabilitado(NivelCurricular nivel) =>
      planSafe.niveles.any((x) => x.nivel == nivel && x.habilitado);

  bool moduloHabilitado(BloqueExtracurricular bloque) =>
      planSafe.modulos.any((x) => x.bloque == bloque && x.habilitado);
}
