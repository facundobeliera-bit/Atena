// lib/core/models/evento.dart
//
// Calendario:
// - Evento: lo publica la institución para todos sus alumnos o para ofertas
//   puntuales (reuniones, actos, exámenes, vacaciones…).
// - RespuestaEvento: confirmación de asistencia de un alumno.
// - NotaPersonal: recordatorio privado del alumno o la familia.

import 'json_utils.dart';

enum TipoEvento {
  general,
  reunion,
  examen,
  acto,
  salida,
  inicioClases,
  finClases,
  vacaciones,
  feriado,
}

enum Asistencia { asistire, talVez, noAsistire }

class Evento {
  final String id;
  final String institucionId;
  final String institucionNombre;
  final TipoEvento tipo;
  final String titulo;
  final String descripcion;
  final String lugar;
  final DateTime inicio;

  /// Fin opcional (eventos de varios días, como vacaciones).
  final DateTime? fin;

  final bool todoElDia;

  /// Ofertas destinatarias. Vacío = todos los alumnos de la institución.
  final List<String> ofertaIds;

  final bool pideConfirmacion;
  final DateTime creadoEl;

  const Evento({
    required this.id,
    required this.institucionId,
    required this.institucionNombre,
    required this.tipo,
    required this.titulo,
    this.descripcion = '',
    this.lugar = '',
    required this.inicio,
    this.fin,
    this.todoElDia = true,
    this.ofertaIds = const <String>[],
    this.pideConfirmacion = false,
    required this.creadoEl,
  });

  bool get paraTodos => ofertaIds.isEmpty;

  DateTime get finEfectivo => fin ?? inicio;

  /// true si el evento ocurre (total o parcialmente) en el día indicado.
  bool ocurreEl(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    final a = DateTime(inicio.year, inicio.month, inicio.day);
    final b = DateTime(finEfectivo.year, finEfectivo.month, finEfectivo.day);
    return !d.isBefore(a) && !d.isAfter(b);
  }

  JsonDoc toJson() => {
    'id': id,
    'institucionId': institucionId,
    'institucionNombre': institucionNombre,
    'tipo': tipo.name,
    'titulo': titulo,
    'descripcion': descripcion,
    'lugar': lugar,
    'inicio': inicio.toIso8601String(),
    if (fin != null) 'fin': fin!.toIso8601String(),
    'todoElDia': todoElDia,
    'ofertaIds': ofertaIds,
    'pideConfirmacion': pideConfirmacion,
    'creadoEl': creadoEl.toIso8601String(),
  };

  factory Evento.fromJson(JsonDoc m) => Evento(
    id: jStr(m['id']),
    institucionId: jStr(m['institucionId']),
    institucionNombre: jStr(m['institucionNombre']),
    tipo: enumByName(TipoEvento.values, m['tipo'], TipoEvento.general),
    titulo: jStr(m['titulo']),
    descripcion: jStr(m['descripcion']),
    lugar: jStr(m['lugar']),
    inicio: jDate(m['inicio']),
    fin: jDateOrNull(m['fin']),
    todoElDia: jBool(m['todoElDia'], fallback: true),
    ofertaIds: jStrList(m['ofertaIds']),
    pideConfirmacion: jBool(m['pideConfirmacion']),
    creadoEl: jDate(m['creadoEl']),
  );
}

class RespuestaEvento {
  final String id; // "<eventoId>|<perfilId>"
  final String eventoId;
  final String perfilId;
  final String alumnoNombre;
  final Asistencia asistencia;
  final DateTime fecha;

  const RespuestaEvento({
    required this.id,
    required this.eventoId,
    required this.perfilId,
    required this.alumnoNombre,
    required this.asistencia,
    required this.fecha,
  });

  static String idPara(String eventoId, String perfilId) =>
      '$eventoId|$perfilId';

  JsonDoc toJson() => {
    'id': id,
    'eventoId': eventoId,
    'perfilId': perfilId,
    'alumnoNombre': alumnoNombre,
    'asistencia': asistencia.name,
    'fecha': fecha.toIso8601String(),
  };

  factory RespuestaEvento.fromJson(JsonDoc m) => RespuestaEvento(
    id: jStr(m['id']),
    eventoId: jStr(m['eventoId']),
    perfilId: jStr(m['perfilId']),
    alumnoNombre: jStr(m['alumnoNombre']),
    asistencia: enumByName(
      Asistencia.values,
      m['asistencia'],
      Asistencia.asistire,
    ),
    fecha: jDate(m['fecha']),
  );
}

class NotaPersonal {
  final String id;
  final String perfilId;
  final String titulo;
  final String detalle;
  final DateTime fecha;

  /// Hora opcional "HH:MM".
  final String hora;

  const NotaPersonal({
    required this.id,
    required this.perfilId,
    required this.titulo,
    this.detalle = '',
    required this.fecha,
    this.hora = '',
  });

  JsonDoc toJson() => {
    'id': id,
    'perfilId': perfilId,
    'titulo': titulo,
    'detalle': detalle,
    'fecha': fecha.toIso8601String(),
    'hora': hora,
  };

  factory NotaPersonal.fromJson(JsonDoc m) => NotaPersonal(
    id: jStr(m['id']),
    perfilId: jStr(m['perfilId']),
    titulo: jStr(m['titulo']),
    detalle: jStr(m['detalle']),
    fecha: jDate(m['fecha']),
    hora: jStr(m['hora']),
  );
}

/// Aviso enviado por la institución (historial).
class Aviso {
  final String id;
  final String institucionId;
  final String titulo;
  final String mensaje;
  final List<String> ofertaIds;
  final int destinatarios;
  final DateTime fecha;

  const Aviso({
    required this.id,
    required this.institucionId,
    required this.titulo,
    required this.mensaje,
    this.ofertaIds = const <String>[],
    required this.destinatarios,
    required this.fecha,
  });

  JsonDoc toJson() => {
    'id': id,
    'institucionId': institucionId,
    'titulo': titulo,
    'mensaje': mensaje,
    'ofertaIds': ofertaIds,
    'destinatarios': destinatarios,
    'fecha': fecha.toIso8601String(),
  };

  factory Aviso.fromJson(JsonDoc m) => Aviso(
    id: jStr(m['id']),
    institucionId: jStr(m['institucionId']),
    titulo: jStr(m['titulo']),
    mensaje: jStr(m['mensaje']),
    ofertaIds: jStrList(m['ofertaIds']),
    destinatarios: jInt(m['destinatarios']),
    fecha: jDate(m['fecha']),
  );
}
