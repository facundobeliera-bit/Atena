// lib/core/models/solicitud.dart
//
// Solicitud de vacante de un alumno a una oferta de una institución.
// Guarda una copia de los datos del alumno y de la oferta al momento de
// enviarla, para que ambas partes vean siempre la misma información.

import 'json_utils.dart';
import 'oferta.dart';

enum EstadoSolicitud {
  pendiente,
  confirmada,
  rechazada,
  canceladaPorAlumno,
  canceladaPorInstitucion,
}

extension EstadoSolicitudInfo on EstadoSolicitud {
  bool get esActiva =>
      this == EstadoSolicitud.pendiente || this == EstadoSolicitud.confirmada;

  bool get esFinal => !esActiva;
}

/// Datos del alumno copiados en la solicitud.
class AlumnoSnapshot {
  final String cuentaId;
  final String perfilId;
  final String nombre;
  final String apellido;
  final String dni;
  final DateTime? fechaNacimiento;
  final String email;
  final String telefono;

  const AlumnoSnapshot({
    required this.cuentaId,
    required this.perfilId,
    required this.nombre,
    required this.apellido,
    required this.dni,
    this.fechaNacimiento,
    this.email = '',
    this.telefono = '',
  });

  String get nombreCompleto => '${nombre.trim()} ${apellido.trim()}'.trim();

  String get apellidoNombre {
    final a = apellido.trim();
    final n = nombre.trim();
    if (a.isEmpty) return n;
    if (n.isEmpty) return a;
    return '$a, $n';
  }

  int? get edad =>
      fechaNacimiento == null ? null : edadEnAnios(fechaNacimiento!);

  JsonDoc toJson() => {
    'cuentaId': cuentaId,
    'perfilId': perfilId,
    'nombre': nombre,
    'apellido': apellido,
    'dni': dni,
    if (fechaNacimiento != null)
      'fechaNacimiento': fechaNacimiento!.toIso8601String(),
    'email': email,
    'telefono': telefono,
  };

  factory AlumnoSnapshot.fromJson(JsonDoc m) => AlumnoSnapshot(
    cuentaId: jStr(m['cuentaId']),
    perfilId: jStr(m['perfilId']),
    nombre: jStr(m['nombre']),
    apellido: jStr(m['apellido']),
    dni: jStr(m['dni']),
    fechaNacimiento: jDateOrNull(m['fechaNacimiento']),
    email: jStr(m['email']),
    telefono: jStr(m['telefono']),
  );
}

/// Cambio de estado registrado en el historial.
class CambioEstado {
  final EstadoSolicitud estado;
  final DateTime fecha;
  final String nota;

  const CambioEstado({
    required this.estado,
    required this.fecha,
    this.nota = '',
  });

  JsonDoc toJson() => {
    'estado': estado.name,
    'fecha': fecha.toIso8601String(),
    if (nota.isNotEmpty) 'nota': nota,
  };

  factory CambioEstado.fromJson(JsonDoc m) => CambioEstado(
    estado: enumByName(
      EstadoSolicitud.values,
      m['estado'],
      EstadoSolicitud.pendiente,
    ),
    fecha: jDate(m['fecha']),
    nota: jStr(m['nota']),
  );
}

class Solicitud {
  final String id;
  final AlumnoSnapshot alumno;
  final String institucionId;
  final String institucionNombre;

  /// Copia de la oferta al momento de enviar la solicitud.
  final Oferta oferta;

  /// Mensaje opcional del alumno o la familia.
  final String mensaje;

  final EstadoSolicitud estado;

  /// Respuesta de la institución (nota de confirmación o motivo de rechazo).
  final String respuesta;

  final DateTime creadaEl;
  final DateTime actualizadaEl;
  final List<CambioEstado> historial;

  const Solicitud({
    required this.id,
    required this.alumno,
    required this.institucionId,
    required this.institucionNombre,
    required this.oferta,
    this.mensaje = '',
    required this.estado,
    this.respuesta = '',
    required this.creadaEl,
    required this.actualizadaEl,
    this.historial = const <CambioEstado>[],
  });

  String get ofertaId => oferta.id;
  TipoOferta get ofertaTipo => oferta.tipo;
  String get ofertaNombre => oferta.nombreCompleto;

  Solicitud conEstado(EstadoSolicitud nuevo, {String nota = ''}) {
    final ahora = DateTime.now();
    final n = nota.trim();
    return Solicitud(
      id: id,
      alumno: alumno,
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      oferta: oferta,
      mensaje: mensaje,
      estado: nuevo,
      respuesta: n.isNotEmpty ? n : respuesta,
      creadaEl: creadaEl,
      actualizadaEl: ahora,
      historial: [
        ...historial,
        CambioEstado(estado: nuevo, fecha: ahora, nota: n),
      ],
    );
  }

  JsonDoc toJson() => {
    'id': id,
    'alumno': alumno.toJson(),
    'institucionId': institucionId,
    'institucionNombre': institucionNombre,
    'oferta': oferta.toJson(),
    'mensaje': mensaje,
    'estado': estado.name,
    'respuesta': respuesta,
    'creadaEl': creadaEl.toIso8601String(),
    'actualizadaEl': actualizadaEl.toIso8601String(),
    'historial': historial.map((h) => h.toJson()).toList(),
    // Campos planos para filtrar rápido.
    'perfilId': alumno.perfilId,
    'cuentaId': alumno.cuentaId,
    'ofertaId': oferta.id,
  };

  factory Solicitud.fromJson(JsonDoc m) {
    final alumnoRaw = m['alumno'];
    final ofertaRaw = m['oferta'];
    final hist = m['historial'];
    return Solicitud(
      id: jStr(m['id']),
      alumno: AlumnoSnapshot.fromJson(
        alumnoRaw is Map ? Map<String, dynamic>.from(alumnoRaw) : const {},
      ),
      institucionId: jStr(m['institucionId']),
      institucionNombre: jStr(m['institucionNombre']),
      oferta: Oferta.fromJson(
        ofertaRaw is Map ? Map<String, dynamic>.from(ofertaRaw) : const {},
      ),
      mensaje: jStr(m['mensaje']),
      estado: enumByName(
        EstadoSolicitud.values,
        m['estado'],
        EstadoSolicitud.pendiente,
      ),
      respuesta: jStr(m['respuesta']),
      creadaEl: jDate(m['creadaEl']),
      actualizadaEl: jDate(m['actualizadaEl']),
      historial: hist is List
          ? hist
                .whereType<Map>()
                .map((e) => CambioEstado.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const <CambioEstado>[],
    );
  }
}
