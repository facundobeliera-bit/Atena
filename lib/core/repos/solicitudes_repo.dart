// lib/core/repos/solicitudes_repo.dart
//
// Solicitudes de vacante: creación, cancelación y respuesta.
//
// Reglas:
// - Una oferta inactiva no recibe solicitudes.
// - Un alumno no puede tener dos solicitudes activas para la misma oferta.
// - No se confirma por encima del cupo.
// - Solo se responden solicitudes pendientes; solo se dan de baja confirmadas.
// - Cada cambio avisa a la otra parte.

import '../errors.dart';
import '../models/notificacion.dart';
import '../models/oferta.dart';
import '../models/solicitud.dart';
import '../store/atena_store.dart';
import 'notificaciones_repo.dart';
import 'ofertas_repo.dart';

class SolicitudesRepo {
  SolicitudesRepo._();
  static final SolicitudesRepo instance = SolicitudesRepo._();

  static const String _col = 'solicitudes';

  final AtenaStore _store = AtenaStore.instance;
  final NotificacionesRepo _noti = NotificacionesRepo.instance;

  static int _recientesPrimero(Solicitud a, Solicitud b) =>
      b.creadaEl.compareTo(a.creadaEl);

  Future<List<Solicitud>> _where(bool Function(JsonDoc d) test) async {
    final docs = await _store.read(_col);
    final list = docs.where(test).map(Solicitud.fromJson).toList();
    list.sort(_recientesPrimero);
    return list;
  }

  Future<List<Solicitud>> porPerfil(String perfilId) =>
      _where((d) => d['perfilId'] == perfilId);

  Future<List<Solicitud>> porCuenta(String cuentaId) =>
      _where((d) => d['cuentaId'] == cuentaId);

  Future<List<Solicitud>> porInstitucion(String institucionId) =>
      _where((d) => d['institucionId'] == institucionId);

  Future<Solicitud?> obtener(String id) async {
    final d = await _store.get(_col, id);
    return d == null ? null : Solicitud.fromJson(d);
  }

  /// Alumnos confirmados de una institución (opcionalmente de una oferta).
  Future<List<Solicitud>> confirmadas(
    String institucionId, {
    String? ofertaId,
  }) async {
    final list = await porInstitucion(institucionId);
    return list
        .where(
          (s) =>
              s.estado == EstadoSolicitud.confirmada &&
              (ofertaId == null || s.ofertaId == ofertaId),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Alumno
  // ---------------------------------------------------------------------------

  Future<Solicitud> crear({
    required AlumnoSnapshot alumno,
    required String institucionNombre,
    required Oferta oferta,
    String mensaje = '',
  }) async {
    if (alumno.perfilId.isEmpty || alumno.cuentaId.isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }

    // La oferta vigente manda (pudo cambiar o eliminarse desde que se mostró).
    final vigente = await OfertasRepo.instance.obtener(
      oferta.institucionId,
      oferta.id,
    );
    if (vigente == null || !vigente.activa) {
      throw const AtenaException(AtenaError.ofertaInactiva);
    }

    final ahora = DateTime.now();
    final solicitud = Solicitud(
      id: AtenaIds.next('SOL'),
      alumno: alumno,
      institucionId: vigente.institucionId,
      institucionNombre: institucionNombre.trim(),
      oferta: vigente,
      mensaje: mensaje.trim(),
      estado: EstadoSolicitud.pendiente,
      creadaEl: ahora,
      actualizadaEl: ahora,
      historial: [
        CambioEstado(estado: EstadoSolicitud.pendiente, fecha: ahora),
      ],
    );

    await _store.update<void>(_col, (docs) {
      final propias = docs.where(
        (d) => d['perfilId'] == alumno.perfilId && d['ofertaId'] == vigente.id,
      );
      final duplicada = propias.any(
        (d) => Solicitud.fromJson(d).estado.esActiva,
      );
      if (duplicada) {
        throw const AtenaException(AtenaError.solicitudDuplicada);
      }

      final confirmados = docs
          .where(
            (d) =>
                d['ofertaId'] == vigente.id &&
                d['estado'] == EstadoSolicitud.confirmada.name,
          )
          .length;
      if (confirmados >= vigente.cupoTotal) {
        throw const AtenaException(AtenaError.sinCupo);
      }

      docs.add(solicitud.toJson());
    });

    final datos = <String, String>{
      'institucion': solicitud.institucionNombre,
      'oferta': vigente.nombreCompleto,
      'alumno': alumno.nombreCompleto,
    };

    await _noti.enviar(
      Notificacion(
        id: '',
        cuentaId: alumno.cuentaId,
        perfilId: alumno.perfilId,
        tipo: TipoNotificacion.solicitudEnviada,
        datos: datos,
        destino: DestinoNotificacion.solicitud,
        destinoId: solicitud.id,
        fecha: ahora,
      ),
    );

    await _noti.enviarAInstitucion(
      solicitud.institucionId,
      (cuenta) => Notificacion(
        id: '',
        cuentaId: cuenta,
        perfilId: solicitud.institucionId,
        tipo: TipoNotificacion.solicitudRecibida,
        datos: datos,
        destino: DestinoNotificacion.solicitud,
        destinoId: solicitud.id,
        fecha: ahora,
      ),
    );

    return solicitud;
  }

  Future<Solicitud> cancelar(String id, {required String perfilId}) async {
    final actualizada = await _transicion(id, (s) {
      if (s.alumno.perfilId != perfilId) {
        throw const AtenaException(AtenaError.noAutorizado);
      }
      if (!s.estado.esActiva) {
        throw const AtenaException(AtenaError.estadoInvalido);
      }
      return s.conEstado(EstadoSolicitud.canceladaPorAlumno);
    });

    await _noti.enviarAInstitucion(
      actualizada.institucionId,
      (cuenta) => Notificacion(
        id: '',
        cuentaId: cuenta,
        perfilId: actualizada.institucionId,
        tipo: TipoNotificacion.solicitudCancelada,
        datos: {
          'alumno': actualizada.alumno.nombreCompleto,
          'oferta': actualizada.ofertaNombre,
        },
        destino: DestinoNotificacion.solicitud,
        destinoId: actualizada.id,
        fecha: DateTime.now(),
      ),
    );
    return actualizada;
  }

  // ---------------------------------------------------------------------------
  // Institución
  // ---------------------------------------------------------------------------

  Future<Solicitud> responder(
    String id, {
    required String institucionId,
    required bool aceptar,
    String nota = '',
  }) async {
    final actual = await obtener(id);
    if (actual == null) throw const AtenaException(AtenaError.noEncontrado);
    final oferta = await OfertasRepo.instance.obtener(
      institucionId,
      actual.ofertaId,
    );
    final cupo = oferta?.cupoTotal ?? actual.oferta.cupoTotal;

    final actualizada = await _transicion(
      id,
      (s) {
        if (s.institucionId != institucionId) {
          throw const AtenaException(AtenaError.noAutorizado);
        }
        if (s.estado != EstadoSolicitud.pendiente) {
          throw const AtenaException(AtenaError.estadoInvalido);
        }
        return s.conEstado(
          aceptar ? EstadoSolicitud.confirmada : EstadoSolicitud.rechazada,
          nota: nota,
        );
      },
      validarConTodas: aceptar
          ? (docs) {
              final confirmados = docs
                  .where(
                    (d) =>
                        d['ofertaId'] == actual.ofertaId &&
                        d['estado'] == EstadoSolicitud.confirmada.name,
                  )
                  .length;
              if (confirmados >= cupo) {
                throw const AtenaException(AtenaError.sinCupo);
              }
            }
          : null,
    );

    await _noti.enviar(
      Notificacion(
        id: '',
        cuentaId: actualizada.alumno.cuentaId,
        perfilId: actualizada.alumno.perfilId,
        tipo: aceptar
            ? TipoNotificacion.solicitudConfirmada
            : TipoNotificacion.solicitudRechazada,
        datos: {
          'institucion': actualizada.institucionNombre,
          'oferta': actualizada.ofertaNombre,
          'alumno': actualizada.alumno.nombreCompleto,
          if (nota.trim().isNotEmpty) 'nota': nota.trim(),
        },
        destino: DestinoNotificacion.solicitud,
        destinoId: actualizada.id,
        fecha: DateTime.now(),
      ),
    );
    return actualizada;
  }

  /// La institución da de baja a un alumno confirmado.
  Future<Solicitud> darDeBaja(
    String id, {
    required String institucionId,
    String nota = '',
  }) async {
    final actualizada = await _transicion(id, (s) {
      if (s.institucionId != institucionId) {
        throw const AtenaException(AtenaError.noAutorizado);
      }
      if (s.estado != EstadoSolicitud.confirmada) {
        throw const AtenaException(AtenaError.estadoInvalido);
      }
      return s.conEstado(EstadoSolicitud.canceladaPorInstitucion, nota: nota);
    });

    await _noti.enviar(
      Notificacion(
        id: '',
        cuentaId: actualizada.alumno.cuentaId,
        perfilId: actualizada.alumno.perfilId,
        tipo: TipoNotificacion.solicitudBaja,
        datos: {
          'institucion': actualizada.institucionNombre,
          'oferta': actualizada.ofertaNombre,
          'alumno': actualizada.alumno.nombreCompleto,
          if (nota.trim().isNotEmpty) 'nota': nota.trim(),
        },
        destino: DestinoNotificacion.solicitud,
        destinoId: actualizada.id,
        fecha: DateTime.now(),
      ),
    );
    return actualizada;
  }

  // ---------------------------------------------------------------------------

  Future<Solicitud> _transicion(
    String id,
    Solicitud Function(Solicitud actual) cambio, {
    void Function(List<JsonDoc> docs)? validarConTodas,
  }) {
    return _store.update<Solicitud>(_col, (docs) {
      final i = docs.indexWhere((d) => d['id'] == id);
      if (i < 0) throw const AtenaException(AtenaError.noEncontrado);
      final nueva = cambio(Solicitud.fromJson(docs[i]));
      validarConTodas?.call(docs);
      docs[i] = nueva.toJson();
      return nueva;
    });
  }
}
