// lib/core/repos/calendario_repo.dart
//
// Calendario y comunicaciones:
// - La institución publica eventos (para todos o para ofertas puntuales).
// - Cada alumno ve los eventos de las instituciones donde está confirmado.
// - Los alumnos confirman asistencia cuando el evento lo pide.
// - Notas personales privadas por perfil de alumno.
// - Avisos: mensajes de la institución a sus alumnos.

import '../errors.dart';
import '../models/evento.dart';
import '../models/notificacion.dart';
import '../models/solicitud.dart';
import '../store/atena_store.dart';
import 'notificaciones_repo.dart';
import 'solicitudes_repo.dart';

class CalendarioRepo {
  CalendarioRepo._();
  static final CalendarioRepo instance = CalendarioRepo._();

  final AtenaStore _store = AtenaStore.instance;
  final NotificacionesRepo _noti = NotificacionesRepo.instance;

  String _colEventos(String instId) => 'eventos.$instId';
  String _colRespuestas(String instId) => 'respuestas.$instId';
  String _colNotas(String perfilId) => 'notas.$perfilId';
  String _colAvisos(String instId) => 'avisos.$instId';

  // ---------------------------------------------------------------------------
  // Destinatarios
  // ---------------------------------------------------------------------------

  /// Alumnos confirmados alcanzados por un envío (uno por perfil).
  Future<List<AlumnoSnapshot>> destinatarios(
    String institucionId,
    List<String> ofertaIds,
  ) async {
    final confirmadas = await SolicitudesRepo.instance.confirmadas(
      institucionId,
    );
    final porPerfil = <String, AlumnoSnapshot>{};
    for (final s in confirmadas) {
      if (ofertaIds.isNotEmpty && !ofertaIds.contains(s.ofertaId)) continue;
      porPerfil[s.alumno.perfilId] = s.alumno;
    }
    return porPerfil.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Eventos (institución)
  // ---------------------------------------------------------------------------

  Future<List<Evento>> eventosInstitucion(String institucionId) async {
    final docs = await _store.read(_colEventos(institucionId));
    final list = docs.map(Evento.fromJson).toList();
    list.sort((a, b) => a.inicio.compareTo(b.inicio));
    return list;
  }

  /// Crea o actualiza un evento. Al crearlo, avisa a los destinatarios.
  Future<Evento> guardarEvento(Evento e) async {
    if (e.institucionId.isEmpty || e.titulo.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    if (e.fin != null && e.fin!.isBefore(e.inicio)) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }

    final esNuevo = e.id.isEmpty;
    final evento = esNuevo
        ? Evento(
            id: AtenaIds.next('EV'),
            institucionId: e.institucionId,
            institucionNombre: e.institucionNombre,
            tipo: e.tipo,
            titulo: e.titulo.trim(),
            descripcion: e.descripcion.trim(),
            lugar: e.lugar.trim(),
            inicio: e.inicio,
            fin: e.fin,
            todoElDia: e.todoElDia,
            ofertaIds: e.ofertaIds,
            pideConfirmacion: e.pideConfirmacion,
            creadoEl: DateTime.now(),
          )
        : e;

    await _store.put(_colEventos(evento.institucionId), evento.toJson());

    if (esNuevo) {
      final alumnos = await destinatarios(
        evento.institucionId,
        evento.ofertaIds,
      );
      for (final a in alumnos) {
        await _noti.enviar(
          Notificacion(
            id: '',
            cuentaId: a.cuentaId,
            perfilId: a.perfilId,
            tipo: TipoNotificacion.eventoPublicado,
            datos: {
              'institucion': evento.institucionNombre,
              'evento': evento.titulo,
              'fecha': evento.inicio.toIso8601String(),
            },
            destino: DestinoNotificacion.evento,
            destinoId: evento.id,
            fecha: DateTime.now(),
          ),
        );
      }
    }
    return evento;
  }

  Future<void> eliminarEvento(String institucionId, String eventoId) async {
    await _store.delete(_colEventos(institucionId), eventoId);
    await _store.update<void>(_colRespuestas(institucionId), (docs) {
      docs.removeWhere((d) => d['eventoId'] == eventoId);
    });
  }

  // ---------------------------------------------------------------------------
  // Eventos (alumno)
  // ---------------------------------------------------------------------------

  /// Eventos visibles para un alumno: de las instituciones donde tiene
  /// solicitudes confirmadas, filtrados por sus ofertas.
  Future<List<Evento>> eventosAlumno(String perfilId) async {
    final solicitudes = await SolicitudesRepo.instance.porPerfil(perfilId);
    final ofertasPorInst = <String, Set<String>>{};
    for (final s in solicitudes) {
      if (s.estado != EstadoSolicitud.confirmada) continue;
      ofertasPorInst
          .putIfAbsent(s.institucionId, () => <String>{})
          .add(s.ofertaId);
    }

    final out = <Evento>[];
    for (final entry in ofertasPorInst.entries) {
      final eventos = await eventosInstitucion(entry.key);
      for (final e in eventos) {
        if (e.paraTodos || e.ofertaIds.any(entry.value.contains)) out.add(e);
      }
    }
    out.sort((a, b) => a.inicio.compareTo(b.inicio));
    return out;
  }

  Future<Evento?> evento(String institucionId, String eventoId) async {
    final d = await _store.get(_colEventos(institucionId), eventoId);
    return d == null ? null : Evento.fromJson(d);
  }

  // ---------------------------------------------------------------------------
  // Confirmación de asistencia
  // ---------------------------------------------------------------------------

  Future<void> responder({
    required Evento evento,
    required String perfilId,
    required String alumnoNombre,
    required Asistencia asistencia,
  }) {
    final r = RespuestaEvento(
      id: RespuestaEvento.idPara(evento.id, perfilId),
      eventoId: evento.id,
      perfilId: perfilId,
      alumnoNombre: alumnoNombre,
      asistencia: asistencia,
      fecha: DateTime.now(),
    );
    return _store.put(_colRespuestas(evento.institucionId), r.toJson());
  }

  Future<List<RespuestaEvento>> respuestas(
    String institucionId,
    String eventoId,
  ) async {
    final docs = await _store.read(_colRespuestas(institucionId));
    return docs
        .where((d) => d['eventoId'] == eventoId)
        .map(RespuestaEvento.fromJson)
        .toList();
  }

  Future<RespuestaEvento?> miRespuesta(
    String institucionId,
    String eventoId,
    String perfilId,
  ) async {
    final d = await _store.get(
      _colRespuestas(institucionId),
      RespuestaEvento.idPara(eventoId, perfilId),
    );
    return d == null ? null : RespuestaEvento.fromJson(d);
  }

  // ---------------------------------------------------------------------------
  // Notas personales
  // ---------------------------------------------------------------------------

  Future<List<NotaPersonal>> notas(String perfilId) async {
    final docs = await _store.read(_colNotas(perfilId));
    final list = docs.map(NotaPersonal.fromJson).toList();
    list.sort((a, b) => a.fecha.compareTo(b.fecha));
    return list;
  }

  Future<NotaPersonal> guardarNota(NotaPersonal n) async {
    if (n.perfilId.isEmpty || n.titulo.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    final nota = n.id.isEmpty
        ? NotaPersonal(
            id: AtenaIds.next('NP'),
            perfilId: n.perfilId,
            titulo: n.titulo.trim(),
            detalle: n.detalle.trim(),
            fecha: n.fecha,
            hora: n.hora.trim(),
          )
        : n;
    await _store.put(_colNotas(nota.perfilId), nota.toJson());
    return nota;
  }

  Future<void> eliminarNota(String perfilId, String notaId) =>
      _store.delete(_colNotas(perfilId), notaId);

  // ---------------------------------------------------------------------------
  // Avisos
  // ---------------------------------------------------------------------------

  Future<List<Aviso>> avisos(String institucionId) async {
    final docs = await _store.read(_colAvisos(institucionId));
    final list = docs.map(Aviso.fromJson).toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  /// Envía un aviso y devuelve cuántos alumnos lo recibieron.
  Future<Aviso> enviarAviso({
    required String institucionId,
    required String institucionNombre,
    required String titulo,
    required String mensaje,
    List<String> ofertaIds = const <String>[],
  }) async {
    if (titulo.trim().isEmpty || mensaje.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    final alumnos = await destinatarios(institucionId, ofertaIds);
    final aviso = Aviso(
      id: AtenaIds.next('AV'),
      institucionId: institucionId,
      titulo: titulo.trim(),
      mensaje: mensaje.trim(),
      ofertaIds: ofertaIds,
      destinatarios: alumnos.length,
      fecha: DateTime.now(),
    );

    for (final a in alumnos) {
      await _noti.enviar(
        Notificacion(
          id: '',
          cuentaId: a.cuentaId,
          perfilId: a.perfilId,
          tipo: TipoNotificacion.aviso,
          datos: {'institucion': institucionNombre},
          titulo: aviso.titulo,
          mensaje: aviso.mensaje,
          destino: DestinoNotificacion.aviso,
          destinoId: aviso.id,
          fecha: aviso.fecha,
        ),
      );
    }

    await _store.put(_colAvisos(institucionId), aviso.toJson());
    return aviso;
  }
}
