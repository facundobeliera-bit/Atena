// lib/core/models/documento.dart
//
// Documentación: la institución pide un documento a un alumno, la familia lo
// sube desde la app y la institución lo revisa (aprueba o pide corregirlo).

import 'json_utils.dart';

enum TipoDocumento {
  dni,
  dniResponsable,
  partidaNacimiento,
  certificadoMedico,
  carnetVacunas,
  boletin,
  pase,
  foto,
  constanciaDomicilio,
  otro,
}

enum EstadoPedidoDocumento {
  pendiente,
  entregado,
  aprobado,
  rechazado,
  cancelado,
}

class ArchivoAdjunto {
  final String id;
  final String nombre;
  final String mime;
  final int bytes;
  final DateTime subidoEl;

  const ArchivoAdjunto({
    required this.id,
    required this.nombre,
    required this.mime,
    required this.bytes,
    required this.subidoEl,
  });

  bool get esImagen => mime.startsWith('image/');
  bool get esPdf => mime == 'application/pdf';

  JsonDoc toJson() => {
    'id': id,
    'nombre': nombre,
    'mime': mime,
    'bytes': bytes,
    'subidoEl': subidoEl.toIso8601String(),
  };

  factory ArchivoAdjunto.fromJson(JsonDoc m) => ArchivoAdjunto(
    id: jStr(m['id']),
    nombre: jStr(m['nombre']),
    mime: jStr(m['mime']),
    bytes: jInt(m['bytes']),
    subidoEl: jDate(m['subidoEl']),
  );
}

class PedidoDocumento {
  final String id;
  final String institucionId;
  final String institucionNombre;
  final String cuentaId;
  final String perfilId;
  final String alumnoNombre;
  final TipoDocumento tipo;

  /// Detalle libre ("Fotocopia de ambos lados", nombre si tipo = otro).
  final String detalle;

  final DateTime? fechaLimite;
  final EstadoPedidoDocumento estado;
  final ArchivoAdjunto? archivo;

  /// Comentario de la institución al revisar (motivo de rechazo).
  final String observacion;

  final DateTime creadoEl;
  final DateTime actualizadoEl;

  const PedidoDocumento({
    required this.id,
    required this.institucionId,
    required this.institucionNombre,
    required this.cuentaId,
    required this.perfilId,
    required this.alumnoNombre,
    required this.tipo,
    this.detalle = '',
    this.fechaLimite,
    required this.estado,
    this.archivo,
    this.observacion = '',
    required this.creadoEl,
    required this.actualizadoEl,
  });

  bool get requiereAccionAlumno =>
      estado == EstadoPedidoDocumento.pendiente ||
      estado == EstadoPedidoDocumento.rechazado;

  bool get vencido =>
      fechaLimite != null &&
      requiereAccionAlumno &&
      DateTime.now().isAfter(
        DateTime(
          fechaLimite!.year,
          fechaLimite!.month,
          fechaLimite!.day,
          23,
          59,
        ),
      );

  PedidoDocumento copyWith({
    EstadoPedidoDocumento? estado,
    ArchivoAdjunto? archivo,
    bool quitarArchivo = false,
    String? observacion,
  }) {
    return PedidoDocumento(
      id: id,
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      cuentaId: cuentaId,
      perfilId: perfilId,
      alumnoNombre: alumnoNombre,
      tipo: tipo,
      detalle: detalle,
      fechaLimite: fechaLimite,
      estado: estado ?? this.estado,
      archivo: quitarArchivo ? null : (archivo ?? this.archivo),
      observacion: observacion ?? this.observacion,
      creadoEl: creadoEl,
      actualizadoEl: DateTime.now(),
    );
  }

  JsonDoc toJson() => {
    'id': id,
    'institucionId': institucionId,
    'institucionNombre': institucionNombre,
    'cuentaId': cuentaId,
    'perfilId': perfilId,
    'alumnoNombre': alumnoNombre,
    'tipo': tipo.name,
    'detalle': detalle,
    if (fechaLimite != null) 'fechaLimite': fechaLimite!.toIso8601String(),
    'estado': estado.name,
    if (archivo != null) 'archivo': archivo!.toJson(),
    'observacion': observacion,
    'creadoEl': creadoEl.toIso8601String(),
    'actualizadoEl': actualizadoEl.toIso8601String(),
  };

  factory PedidoDocumento.fromJson(JsonDoc m) {
    final a = m['archivo'];
    return PedidoDocumento(
      id: jStr(m['id']),
      institucionId: jStr(m['institucionId']),
      institucionNombre: jStr(m['institucionNombre']),
      cuentaId: jStr(m['cuentaId']),
      perfilId: jStr(m['perfilId']),
      alumnoNombre: jStr(m['alumnoNombre']),
      tipo: enumByName(TipoDocumento.values, m['tipo'], TipoDocumento.otro),
      detalle: jStr(m['detalle']),
      fechaLimite: jDateOrNull(m['fechaLimite']),
      estado: enumByName(
        EstadoPedidoDocumento.values,
        m['estado'],
        EstadoPedidoDocumento.pendiente,
      ),
      archivo: a is Map
          ? ArchivoAdjunto.fromJson(Map<String, dynamic>.from(a))
          : null,
      observacion: jStr(m['observacion']),
      creadoEl: jDate(m['creadoEl']),
      actualizadoEl: jDate(m['actualizadoEl']),
    );
  }
}
