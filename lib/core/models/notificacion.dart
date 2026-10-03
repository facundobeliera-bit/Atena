// lib/core/models/notificacion.dart
//
// Notificación para una cuenta (familia o institución).
// Se guarda el tipo y sus datos; la interfaz arma el texto en el idioma del
// usuario. Los avisos de la institución traen título y mensaje propios.

import 'json_utils.dart';

enum TipoNotificacion {
  bienvenida,
  solicitudEnviada,
  solicitudRecibida,
  solicitudConfirmada,
  solicitudRechazada,
  solicitudCancelada,
  solicitudBaja,
  documentoSolicitado,
  documentoEntregado,
  documentoAprobado,
  documentoRechazado,
  eventoPublicado,
  aviso,

  /// Una familia eliminó su cuenta (para la institución).
  cuentaEliminada,

  /// La institución eliminó su cuenta (para la familia).
  institucionEliminada,
}

/// A qué entidad lleva la notificación al tocarla.
enum DestinoNotificacion { ninguno, solicitud, documento, evento, aviso }

class Notificacion {
  final String id;

  /// Cuenta que la recibe.
  final String cuentaId;

  /// Perfil involucrado (alumno o institución). Vacío = toda la cuenta.
  final String perfilId;

  final TipoNotificacion tipo;
  final Map<String, String> datos;

  /// Solo para avisos: texto escrito por la institución.
  final String titulo;
  final String mensaje;

  final DestinoNotificacion destino;
  final String destinoId;

  final DateTime fecha;
  final bool leida;

  const Notificacion({
    required this.id,
    required this.cuentaId,
    this.perfilId = '',
    required this.tipo,
    this.datos = const <String, String>{},
    this.titulo = '',
    this.mensaje = '',
    this.destino = DestinoNotificacion.ninguno,
    this.destinoId = '',
    required this.fecha,
    this.leida = false,
  });

  String dato(String key) => datos[key] ?? '';

  Notificacion marcada(bool valor) => Notificacion(
    id: id,
    cuentaId: cuentaId,
    perfilId: perfilId,
    tipo: tipo,
    datos: datos,
    titulo: titulo,
    mensaje: mensaje,
    destino: destino,
    destinoId: destinoId,
    fecha: fecha,
    leida: valor,
  );

  JsonDoc toJson() => {
    'id': id,
    'cuentaId': cuentaId,
    'perfilId': perfilId,
    'tipo': tipo.name,
    'datos': datos,
    'titulo': titulo,
    'mensaje': mensaje,
    'destino': destino.name,
    'destinoId': destinoId,
    'fecha': fecha.toIso8601String(),
    'leida': leida,
  };

  factory Notificacion.fromJson(JsonDoc m) => Notificacion(
    id: jStr(m['id']),
    cuentaId: jStr(m['cuentaId']),
    perfilId: jStr(m['perfilId']),
    tipo: enumByName(
      TipoNotificacion.values,
      m['tipo'],
      TipoNotificacion.aviso,
    ),
    datos: jStrMap(m['datos']),
    titulo: jStr(m['titulo']),
    mensaje: jStr(m['mensaje']),
    destino: enumByName(
      DestinoNotificacion.values,
      m['destino'],
      DestinoNotificacion.ninguno,
    ),
    destinoId: jStr(m['destinoId']),
    fecha: jDate(m['fecha']),
    leida: jBool(m['leida']),
  );
}
