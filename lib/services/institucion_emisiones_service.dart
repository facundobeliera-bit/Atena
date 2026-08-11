// lib/services/institucion_emisiones_service.dart
//
// ATENA – INSTITUCIÓN EMISIONES SERVICE (CANÓNICO)
// Emisión institucional a alumnos (derivado desde SolicitudAlumno confirmada)
// - NO duplica estado.
// - Destinatarios: Solicitudes confirmadas.
// - Evento institucional: locked + no editable/borrable por alumno.
// - Notificación: vía notificarOwner=true en AlumnoService (calendario unificado).
//
import 'dart:math';

import '../models/calendario/evento_calendario.dart';
import '../models/solicitudes/solicitud_alumno.dart';
import 'alumno_service.dart';
import 'solicitudes_service.dart';

class InstitucionEmisionesService {
  InstitucionEmisionesService._();
  static final InstitucionEmisionesService instance =
      InstitucionEmisionesService._();

  // -----------------------------------------------------
  // Helpers
  // -----------------------------------------------------

  static String _n(String? v) => (v ?? '').trim();
  static String _l(String? v) => (v ?? '').trim().toLowerCase();

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${_two(dt.month)}-${_two(dt.day)}';

  static String _timeKey(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  static String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${prefix}_${now}_$rnd';
  }

  // -----------------------------------------------------
  // RAW evento especial (backend-ready)
  // -----------------------------------------------------

  /// Map RAW backend-ready para AlumnoCalendarioInteraccionesService (vía AlumnoService).
  /// Claves alineadas con AlumnoService:
  /// - id, date(YYYY-MM-DD), time(HH:mm), title, note/description
  /// - type: "curricular" / "extracurricular" / "evento_especial"
  /// - source: "institucion"
  /// - locked: true + allowStudentEdit/Delete false
  static Map<String, dynamic> _buildRawEventoEspecial({
    required String eventId,
    required String institucionId,
    required String institucionNombre,
    required bool esCurricular,
    required String? actividadNombre,
    required DateTime inicio,
    DateTime? fin,
    required String titulo,
    required String descripcion,
    required TipoEventoEspecial tipoEspecial,
    SegmentoEventoEspecial? segmento,
    bool requiresRsvp = false,
    String rsvpPolicy =
        'optional', // optional|mandatory_attendance|mandatory_ack
    String rsvpStatus = 'pending', // yes|no|maybe|pending
    List<int> preNotiMinutes = const <int>[1440, 120],

    // ✅ metadata UX (backend-ready): si el sistema quiere duplicar en perfil local
    bool duplicarNotiEnPerfil = true,
  }) {
    final date = _dateKey(inicio);
    final time = _timeKey(inicio);

    // ✅ En el flujo canónico, UI valida título/mensaje.
    // Aun así, evitamos string vacío aquí.
    // (Si querés 100% i18n, el fallback neutro debe venir desde UI.)
    final safeTitle = titulo.trim().isEmpty ? 'Evento' : titulo.trim();

    return <String, dynamic>{
      'id': eventId,
      'date': date,
      'time': time,
      'title': safeTitle,
      'note': descripcion.trim(),
      'type': 'evento_especial',

      // institucional / bloqueo
      'source': 'institucion',
      'locked': true,
      'allowStudentDelete': false,
      'allowStudentEdit': false,

      // vínculo institución/actividad (NO “sanitizar” IDs; solo trim)
      'institucionId': _n(institucionId),
      'institucionNombre': institucionNombre.trim(),
      'actividadNombre': _n(actividadNombre),
      'esCurricular': esCurricular,

      // fin (si aplica)
      if (fin != null) 'endDate': _dateKey(fin),
      if (fin != null) 'endTime': _timeKey(fin),

      // metadata EventoCalendario (para UI futura / backend)
      'cal_tipo': TipoEventoCalendario.eventoEspecial.name,
      'cal_tipoEspecial': tipoEspecial.name,
      if (segmento != null) 'cal_segmentoEspecial': segmento.toMap(),

      // RSVP (backend-ready)
      'requiresRsvp': requiresRsvp,
      'rsvpPolicy': rsvpPolicy,
      'rsvpStatus': rsvpStatus,

      // pre-notificaciones
      'preNotiMinutes': preNotiMinutes,
      'preNotified': <int>[],
      'preNotiLastRunIso': DateTime.now().toIso8601String(),

      // ✅ flag UX backend-ready (hoy puede ignorarse sin romper)
      'notiDuplicateInProfile': duplicarNotiEnPerfil,
    };
  }

  // -----------------------------------------------------
  // ✅ Destinatarios (confirmados) – derivado desde solicitudes
  // -----------------------------------------------------

  Future<List<SolicitudAlumno>> obtenerConfirmados({
    required String institucionId,
    bool? esCurricular,
    String? aula,
    String? turno,
    String? actividadNombre,
    String? moduleKey, // solo para extracurricular (snake_case canónico)
  }) async {
    final inst = _n(institucionId);
    if (inst.isEmpty) return <SolicitudAlumno>[];

    final all = await SolicitudesService.obtenerSolicitudesParaInstitucion(
      institucionId: inst,
    );

    final out = <SolicitudAlumno>[];
    for (final s in all) {
      if (s.estado != EstadoSolicitud.confirmada) continue;

      if (esCurricular != null) {
        if (esCurricular == true && !s.esCurricular) continue;
        if (esCurricular == false && s.esCurricular) continue;
      }

      if (_n(aula).isNotEmpty && _l(s.aula) != _l(aula)) continue;
      if (_n(turno).isNotEmpty && _l(s.turno) != _l(turno)) continue;

      if (_n(actividadNombre).isNotEmpty &&
          _l(s.actividadNombre) != _l(actividadNombre)) {
        continue;
      }

      // moduleKey solo aplica si NO es curricular
      if (_n(moduleKey).isNotEmpty) {
        if (s.esCurricular) continue;
        // ✅ SolicitudAlumno ya valida canónicamente en persistencia;
        // aún así comparamos en minúsculas por robustez.
        if (_l(s.moduleKey) != _l(moduleKey)) continue;
      }

      out.add(s);
    }

    // ✅ sort canónico: más recientes primero
    out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    return out;
  }

  // -----------------------------------------------------
  // ✅ Emisión canónica: Evento Especial institucional → Calendario alumno
  // -----------------------------------------------------

  /// Emite un EventoEspecial institucional a una lista de destinatarios (solicitudes confirmadas).
  ///
  /// - Crea evento LOCKED institucional (no editable/borrable por alumno).
  /// - Usa AlumnoService.upsertCalendarioEvent(actorIsInstitucion=true, notificar=true).
  /// - Devuelve IDs emitidos por alumno: perfilId -> eventId.
  Future<Map<String, String>> emitirEventoEspecialAConfirmados({
    required String institucionId,
    required String institucionNombre,
    required List<SolicitudAlumno> confirmados,
    required bool esCurricular,
    String? actividadNombre,
    required DateTime inicio,
    DateTime? fin,
    required String titulo,
    required String descripcion,
    required TipoEventoEspecial tipoEspecial,
    SegmentoEventoEspecial? segmento,
    bool requiresRsvp = false,
    String rsvpPolicy = 'optional',
    List<int> preNotiMinutes = const <int>[1440, 120],
    bool duplicarNotiEnPerfil =
        true, // (compat) metadata: lo respeta NotificacionesService si se implementa
  }) async {
    final inst = _n(institucionId);
    if (inst.isEmpty) return <String, String>{};
    if (confirmados.isEmpty) return <String, String>{};

    final out = <String, String>{};

    for (final s in confirmados) {
      final owner = _n(s.ownerAccountId);
      final perfil = _n(s.perfilId);
      if (owner.isEmpty || perfil.isEmpty) continue;

      // eventId único por alumno (evita colisiones; backend-ready)
      final eventId = _newId('EVESP');

      final raw = _buildRawEventoEspecial(
        eventId: eventId,
        institucionId: inst,
        institucionNombre: institucionNombre,
        esCurricular: esCurricular,
        actividadNombre: actividadNombre ?? s.actividadNombre,
        inicio: inicio,
        fin: fin,
        titulo: titulo,
        descripcion: descripcion,
        tipoEspecial: tipoEspecial,
        segmento: segmento,
        requiresRsvp: requiresRsvp,
        rsvpPolicy: rsvpPolicy,
        rsvpStatus: 'pending',
        preNotiMinutes: preNotiMinutes,
        duplicarNotiEnPerfil: duplicarNotiEnPerfil,
      );

      // ✅ Timeout por alumno: evita que 1 caso “cuelgue” toda la emisión.
      try {
        await AlumnoService.instance
            .upsertCalendarioEvent(
              ownerAccountId: owner,
              perfilId: perfil,
              event: raw,
              notificar: true,
              actorIsInstitucion: true,
            )
            .timeout(const Duration(seconds: 6));
        out[perfil] = eventId;
      } catch (_) {
        // best-effort: continuar con el siguiente alumno
      }
    }

    return out;
  }

  /// Conveniencia: emite a “AULA completa” (confirmados curricular o extra).
  Future<Map<String, String>> emitirEventoEspecialPorAula({
    required String institucionId,
    required String institucionNombre,
    required String aula,
    String? turno,
    required bool esCurricular,
    String? actividadNombre,
    String? moduleKey,
    required DateTime inicio,
    DateTime? fin,
    required String titulo,
    required String descripcion,
    required TipoEventoEspecial tipoEspecial,
    SegmentoEventoEspecial? segmento,
    bool requiresRsvp = false,
    String rsvpPolicy = 'optional',
    List<int> preNotiMinutes = const <int>[1440, 120],
  }) async {
    final confirmados = await obtenerConfirmados(
      institucionId: institucionId,
      esCurricular: esCurricular,
      aula: aula,
      turno: turno,
      actividadNombre: actividadNombre,
      moduleKey: moduleKey,
    );

    return emitirEventoEspecialAConfirmados(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      confirmados: confirmados,
      esCurricular: esCurricular,
      actividadNombre: actividadNombre,
      inicio: inicio,
      fin: fin,
      titulo: titulo,
      descripcion: descripcion,
      tipoEspecial: tipoEspecial,
      segmento: segmento,
      requiresRsvp: requiresRsvp,
      rsvpPolicy: rsvpPolicy,
      preNotiMinutes: preNotiMinutes,
    );
  }

  /// Conveniencia: emite a “INSTITUCIÓN completa” (todos los confirmados).
  Future<Map<String, String>> emitirEventoEspecialInstitucionCompleta({
    required String institucionId,
    required String institucionNombre,
    bool? esCurricular,
    String? actividadNombre,
    String? moduleKey,
    required DateTime inicio,
    DateTime? fin,
    required String titulo,
    required String descripcion,
    required TipoEventoEspecial tipoEspecial,
    SegmentoEventoEspecial? segmento,
    bool requiresRsvp = false,
    String rsvpPolicy = 'optional',
    List<int> preNotiMinutes = const <int>[1440, 120],
  }) async {
    final confirmados = await obtenerConfirmados(
      institucionId: institucionId,
      esCurricular: esCurricular,
      actividadNombre: actividadNombre,
      moduleKey: moduleKey,
    );

    // si esCurricular=null, lo derivamos por llamado (mixed):
    // para metadata, si es mixto dejamos false (no rompe); si querés separar,
    // lo hacemos desde UI emitiendo dos veces (curricular y extra).
    final ec = esCurricular ?? false;

    return emitirEventoEspecialAConfirmados(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      confirmados: confirmados,
      esCurricular: ec,
      actividadNombre: actividadNombre,
      inicio: inicio,
      fin: fin,
      titulo: titulo,
      descripcion: descripcion,
      tipoEspecial: tipoEspecial,
      segmento: segmento,
      requiresRsvp: requiresRsvp,
      rsvpPolicy: rsvpPolicy,
      preNotiMinutes: preNotiMinutes,
    );
  }
}
