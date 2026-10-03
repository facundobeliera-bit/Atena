// lib/core/models/oferta.dart
//
// Oferta educativa publicada por una institución: un curso, sala o grupo al
// que los alumnos pueden pedir vacante.
// - Curricular: pertenece a un nivel (jardín, primaria, secundaria…).
// - Extracurricular: pertenece a un bloque (deporte, arte, idiomas…).
//
// El cupo ocupado no se guarda: se calcula con las solicitudes confirmadas.

import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import 'json_utils.dart';

enum TipoOferta { curricular, extracurricular }

enum Turno { manana, tarde, noche, completo }

class Oferta {
  final String id;
  final String institucionId;
  final TipoOferta tipo;

  /// Solo curricular.
  final NivelCurricular? nivel;

  /// Solo extracurricular.
  final BloqueExtracurricular? bloque;

  /// Curricular: año/sala ("1° grado", "Sala de 4").
  /// Extracurricular: actividad ("Fútbol", "Robótica").
  final String titulo;

  /// División o grupo ("A", "Turno sábado", "Inicial").
  final String grupo;

  final Turno turno;
  final String horario;
  final String dias;
  final int cupoTotal;
  final int? edadMinima;
  final int? edadMaxima;
  final String descripcion;
  final String arancel;
  final bool activa;
  final DateTime creadaEl;
  final DateTime actualizadaEl;

  const Oferta({
    required this.id,
    required this.institucionId,
    required this.tipo,
    this.nivel,
    this.bloque,
    required this.titulo,
    this.grupo = '',
    this.turno = Turno.manana,
    this.horario = '',
    this.dias = '',
    required this.cupoTotal,
    this.edadMinima,
    this.edadMaxima,
    this.descripcion = '',
    this.arancel = '',
    this.activa = true,
    required this.creadaEl,
    required this.actualizadaEl,
  });

  bool get esCurricular => tipo == TipoOferta.curricular;

  /// Nombre completo para listas: "1° grado · A".
  String get nombreCompleto {
    final g = grupo.trim();
    return g.isEmpty ? titulo.trim() : '${titulo.trim()} · $g';
  }

  /// true si la edad (en años) es aceptada por la oferta.
  bool aceptaEdad(int? edad) {
    if (edad == null) return true;
    if (edadMinima != null && edad < edadMinima!) return false;
    if (edadMaxima != null && edad > edadMaxima!) return false;
    return true;
  }

  Oferta copyWith({
    TipoOferta? tipo,
    NivelCurricular? nivel,
    BloqueExtracurricular? bloque,
    String? titulo,
    String? grupo,
    Turno? turno,
    String? horario,
    String? dias,
    int? cupoTotal,
    int? edadMinima,
    int? edadMaxima,
    bool clearEdades = false,
    String? descripcion,
    String? arancel,
    bool? activa,
    DateTime? actualizadaEl,
  }) {
    return Oferta(
      id: id,
      institucionId: institucionId,
      tipo: tipo ?? this.tipo,
      nivel: nivel ?? this.nivel,
      bloque: bloque ?? this.bloque,
      titulo: titulo ?? this.titulo,
      grupo: grupo ?? this.grupo,
      turno: turno ?? this.turno,
      horario: horario ?? this.horario,
      dias: dias ?? this.dias,
      cupoTotal: cupoTotal ?? this.cupoTotal,
      edadMinima: clearEdades ? null : (edadMinima ?? this.edadMinima),
      edadMaxima: clearEdades ? null : (edadMaxima ?? this.edadMaxima),
      descripcion: descripcion ?? this.descripcion,
      arancel: arancel ?? this.arancel,
      activa: activa ?? this.activa,
      creadaEl: creadaEl,
      actualizadaEl: actualizadaEl ?? DateTime.now(),
    );
  }

  JsonDoc toJson() => {
    'id': id,
    'institucionId': institucionId,
    'tipo': tipo.name,
    if (nivel != null) 'nivel': nivel!.name,
    if (bloque != null) 'bloque': bloque!.key,
    'titulo': titulo,
    'grupo': grupo,
    'turno': turno.name,
    'horario': horario,
    'dias': dias,
    'cupoTotal': cupoTotal,
    if (edadMinima != null) 'edadMinima': edadMinima,
    if (edadMaxima != null) 'edadMaxima': edadMaxima,
    'descripcion': descripcion,
    'arancel': arancel,
    'activa': activa,
    'creadaEl': creadaEl.toIso8601String(),
    'actualizadaEl': actualizadaEl.toIso8601String(),
  };

  factory Oferta.fromJson(JsonDoc m) {
    final tipo = enumByName(
      TipoOferta.values,
      m['tipo'],
      TipoOferta.curricular,
    );
    final nivelRaw = jStr(m['nivel']);
    return Oferta(
      id: jStr(m['id']),
      institucionId: jStr(m['institucionId']),
      tipo: tipo,
      nivel: nivelRaw.isEmpty
          ? null
          : enumByName(
              NivelCurricular.values,
              nivelRaw,
              NivelCurricular.primaria,
            ),
      bloque: BloqueExtracurricularX.tryParseAny(m['bloque']),
      titulo: jStr(m['titulo']),
      grupo: jStr(m['grupo']),
      turno: enumByName(Turno.values, m['turno'], Turno.manana),
      horario: jStr(m['horario']),
      dias: jStr(m['dias']),
      cupoTotal: jInt(m['cupoTotal'], fallback: 1),
      edadMinima: jIntOrNull(m['edadMinima']),
      edadMaxima: jIntOrNull(m['edadMaxima']),
      descripcion: jStr(m['descripcion']),
      arancel: jStr(m['arancel']),
      activa: jBool(m['activa'], fallback: true),
      creadaEl: jDate(m['creadaEl']),
      actualizadaEl: jDate(m['actualizadaEl']),
    );
  }
}

/// Oferta con su ocupación calculada.
class OfertaConCupo {
  final Oferta oferta;
  final int confirmados;
  final int pendientes;

  const OfertaConCupo({
    required this.oferta,
    required this.confirmados,
    required this.pendientes,
  });

  int get disponibles =>
      (oferta.cupoTotal - confirmados).clamp(0, oferta.cupoTotal);

  bool get completa => disponibles <= 0;

  double get ocupacion =>
      oferta.cupoTotal <= 0 ? 1 : (confirmados / oferta.cupoTotal).clamp(0, 1);
}
