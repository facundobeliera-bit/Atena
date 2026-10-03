// lib/core/models/croquis.dart
//
// Croquis de aula: distribución de bancos de un curso (filas × columnas) con
// el nombre del alumno asignado a cada lugar.

import 'json_utils.dart';

class Croquis {
  static const int maxFilas = 10;
  static const int maxColumnas = 10;

  final String id;
  final String institucionId;
  final String nombre;

  /// Oferta asociada (opcional) para sugerir alumnos confirmados.
  final String ofertaId;

  final int filas;
  final int columnas;

  /// filas × columnas posiciones; '' = lugar libre.
  final List<String> asientos;

  final DateTime actualizadoEl;

  const Croquis({
    required this.id,
    required this.institucionId,
    required this.nombre,
    this.ofertaId = '',
    required this.filas,
    required this.columnas,
    required this.asientos,
    required this.actualizadoEl,
  });

  factory Croquis.vacio({
    required String id,
    required String institucionId,
    required String nombre,
    String ofertaId = '',
    int filas = 5,
    int columnas = 6,
  }) {
    final f = filas.clamp(1, maxFilas);
    final c = columnas.clamp(1, maxColumnas);
    return Croquis(
      id: id,
      institucionId: institucionId,
      nombre: nombre,
      ofertaId: ofertaId,
      filas: f,
      columnas: c,
      asientos: List<String>.filled(f * c, ''),
      actualizadoEl: DateTime.now(),
    );
  }

  String asiento(int fila, int columna) => asientos[fila * columnas + columna];

  int get ocupados => asientos.where((a) => a.trim().isNotEmpty).length;

  Croquis conAsiento(int fila, int columna, String nombreAlumno) {
    final next = List<String>.from(asientos);
    next[fila * columnas + columna] = nombreAlumno.trim();
    return _copy(asientos: next);
  }

  /// Cambia el tamaño conservando los lugares que siguen existiendo.
  Croquis redimensionado(int nuevasFilas, int nuevasColumnas) {
    final f = nuevasFilas.clamp(1, maxFilas);
    final c = nuevasColumnas.clamp(1, maxColumnas);
    final next = List<String>.filled(f * c, '');
    for (var r = 0; r < f && r < filas; r++) {
      for (var col = 0; col < c && col < columnas; col++) {
        next[r * c + col] = asiento(r, col);
      }
    }
    return Croquis(
      id: id,
      institucionId: institucionId,
      nombre: nombre,
      ofertaId: ofertaId,
      filas: f,
      columnas: c,
      asientos: next,
      actualizadoEl: DateTime.now(),
    );
  }

  Croquis _copy({List<String>? asientos, String? nombre, String? ofertaId}) {
    return Croquis(
      id: id,
      institucionId: institucionId,
      nombre: nombre ?? this.nombre,
      ofertaId: ofertaId ?? this.ofertaId,
      filas: filas,
      columnas: columnas,
      asientos: asientos ?? this.asientos,
      actualizadoEl: DateTime.now(),
    );
  }

  Croquis renombrado(String nuevo) => _copy(nombre: nuevo.trim());

  Croquis conOferta(String nuevaOfertaId) => _copy(ofertaId: nuevaOfertaId);

  JsonDoc toJson() => {
    'id': id,
    'institucionId': institucionId,
    'nombre': nombre,
    'ofertaId': ofertaId,
    'filas': filas,
    'columnas': columnas,
    'asientos': asientos,
    'actualizadoEl': actualizadoEl.toIso8601String(),
  };

  factory Croquis.fromJson(JsonDoc m) {
    final f = jInt(m['filas'], fallback: 5).clamp(1, maxFilas);
    final c = jInt(m['columnas'], fallback: 6).clamp(1, maxColumnas);
    final raw = m['asientos'];
    final asientos = List<String>.filled(f * c, '');
    if (raw is List) {
      for (var i = 0; i < raw.length && i < asientos.length; i++) {
        asientos[i] = jStr(raw[i]);
      }
    }
    return Croquis(
      id: jStr(m['id']),
      institucionId: jStr(m['institucionId']),
      nombre: jStr(m['nombre']),
      ofertaId: jStr(m['ofertaId']),
      filas: f,
      columnas: c,
      asientos: asientos,
      actualizadoEl: jDate(m['actualizadoEl']),
    );
  }
}
