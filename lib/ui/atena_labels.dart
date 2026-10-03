// lib/ui/atena_labels.dart
//
// Textos traducidos para los valores del dominio (niveles, turnos, estados…),
// y presentación de notificaciones y errores.
//
// Uso: `t.nivel(NivelCurricular.primaria)`, `coreErrorText(t, e)`.

import 'package:flutter/material.dart';

import '../core/atena_core.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/extracurriculares/bloque_extracurricular.dart';
import '../models/instituciones/instituciones_integrado.dart';
import '../services/auth_errors.dart';
import 'theme/atena_colors.dart';
import 'widgets/atena_feedback.dart';

extension AtenaLabels on AppLocalizations {
  String nivel(NivelCurricular n) => switch (n) {
    NivelCurricular.jardin => lblNivelJardin,
    NivelCurricular.primaria => lblNivelPrimaria,
    NivelCurricular.secundaria => lblNivelSecundaria,
    NivelCurricular.tecnica => lblNivelTecnica,
    NivelCurricular.terciario => lblNivelTerciario,
  };

  String bloque(BloqueExtracurricular b) => switch (b) {
    BloqueExtracurricular.deporteYMovimiento => lblBloqueDeporte,
    BloqueExtracurricular.arteYExpresion => lblBloqueArte,
    BloqueExtracurricular.idiomasYComunicacion => lblBloqueIdiomas,
    BloqueExtracurricular.cienciaTecnologiaYRobotica => lblBloqueCiencia,
    BloqueExtracurricular.apoyoAcademico => lblBloqueApoyo,
    BloqueExtracurricular.desarrolloPersonalYBienestar => lblBloqueBienestar,
    BloqueExtracurricular.otros => lblBloqueOtros,
  };

  String turno(Turno x) => switch (x) {
    Turno.manana => lblTurnoManana,
    Turno.tarde => lblTurnoTarde,
    Turno.noche => lblTurnoNoche,
    Turno.completo => lblTurnoCompleto,
  };

  String modalidad(ModalidadCursado m) => switch (m) {
    ModalidadCursado.presencial => lblModalidadPresencial,
    ModalidadCursado.remoto => lblModalidadRemoto,
    ModalidadCursado.hibrido => lblModalidadHibrido,
  };

  String tipoInstitucion(TipoInstitucion x) => switch (x) {
    TipoInstitucion.jardin => lblTipoInstJardin,
    TipoInstitucion.primaria => lblTipoInstPrimaria,
    TipoInstitucion.secundaria => lblTipoInstSecundaria,
    TipoInstitucion.tecnica => lblTipoInstTecnica,
    TipoInstitucion.terciario => lblTipoInstTerciario,
    TipoInstitucion.taller => lblTipoInstTaller,
    TipoInstitucion.club => lblTipoInstClub,
    TipoInstitucion.otra => lblTipoInstOtra,
  };

  String tipoOferta(TipoOferta x) => switch (x) {
    TipoOferta.curricular => lblCurricular,
    TipoOferta.extracurricular => lblExtracurricular,
  };

  /// Categoría de la oferta: nivel (curricular) o bloque (extracurricular).
  String categoriaOferta(Oferta o) {
    if (o.esCurricular) {
      return o.nivel == null ? lblCurricular : nivel(o.nivel!);
    }
    return o.bloque == null ? lblExtracurricular : bloque(o.bloque!);
  }

  String estadoSolicitud(EstadoSolicitud e) => switch (e) {
    EstadoSolicitud.pendiente => lblEstadoPendiente,
    EstadoSolicitud.confirmada => lblEstadoConfirmada,
    EstadoSolicitud.rechazada => lblEstadoRechazada,
    EstadoSolicitud.canceladaPorAlumno => lblEstadoCanceladaAlumno,
    EstadoSolicitud.canceladaPorInstitucion => lblEstadoCanceladaInstitucion,
  };

  String tipoDocumento(TipoDocumento x) => switch (x) {
    TipoDocumento.dni => lblDocDni,
    TipoDocumento.dniResponsable => lblDocDniResponsable,
    TipoDocumento.partidaNacimiento => lblDocPartida,
    TipoDocumento.certificadoMedico => lblDocCertMedico,
    TipoDocumento.carnetVacunas => lblDocVacunas,
    TipoDocumento.boletin => lblDocBoletin,
    TipoDocumento.pase => lblDocPase,
    TipoDocumento.foto => lblDocFoto,
    TipoDocumento.constanciaDomicilio => lblDocDomicilio,
    TipoDocumento.otro => lblDocOtro,
  };

  /// Nombre del documento pedido (usa el detalle si es "otro").
  String nombreDocumento(TipoDocumento tipo, String detalle) {
    if (tipo == TipoDocumento.otro && detalle.trim().isNotEmpty) {
      return detalle.trim();
    }
    return tipoDocumento(tipo);
  }

  String estadoDocumento(EstadoPedidoDocumento e) => switch (e) {
    EstadoPedidoDocumento.pendiente => lblDocEstadoPendiente,
    EstadoPedidoDocumento.entregado => lblDocEstadoEntregado,
    EstadoPedidoDocumento.aprobado => lblDocEstadoAprobado,
    EstadoPedidoDocumento.rechazado => lblDocEstadoRechazado,
    EstadoPedidoDocumento.cancelado => lblDocEstadoCancelado,
  };

  String tipoEvento(TipoEvento x) => switch (x) {
    TipoEvento.general => lblEvGeneral,
    TipoEvento.reunion => lblEvReunion,
    TipoEvento.examen => lblEvExamen,
    TipoEvento.acto => lblEvActo,
    TipoEvento.salida => lblEvSalida,
    TipoEvento.inicioClases => lblEvInicioClases,
    TipoEvento.finClases => lblEvFinClases,
    TipoEvento.vacaciones => lblEvVacaciones,
    TipoEvento.feriado => lblEvFeriado,
  };

  String asistencia(Asistencia a) => switch (a) {
    Asistencia.asistire => lblAsisSi,
    Asistencia.talVez => lblAsisTalVez,
    Asistencia.noAsistire => lblAsisNo,
  };

  /// "De 6 a 8 años", "5 años", "Desde 4 años"… o '' si no hay límites.
  String rangoEdad(int? min, int? max) {
    if (min != null && min == max) return lblEdadAnios(min);
    if (min != null && max != null) return lblRangoEdad('$min', '$max');
    if (min != null) return lblEdadDesde('$min');
    if (max != null) return lblEdadHasta('$max');
    return '';
  }
}

// -----------------------------------------------------------------------------
// Colores e íconos de estados
// -----------------------------------------------------------------------------

Color colorEstadoSolicitud(EstadoSolicitud e) => switch (e) {
  EstadoSolicitud.pendiente => AtenaStatusColors.pending,
  EstadoSolicitud.confirmada => AtenaStatusColors.approved,
  EstadoSolicitud.rechazada => AtenaStatusColors.rejected,
  EstadoSolicitud.canceladaPorAlumno => AtenaStatusColors.cancelled,
  EstadoSolicitud.canceladaPorInstitucion => AtenaStatusColors.cancelled,
};

IconData iconoEstadoSolicitud(EstadoSolicitud e) => switch (e) {
  EstadoSolicitud.pendiente => Icons.hourglass_top_rounded,
  EstadoSolicitud.confirmada => Icons.check_circle_rounded,
  EstadoSolicitud.rechazada => Icons.cancel_rounded,
  EstadoSolicitud.canceladaPorAlumno => Icons.block_rounded,
  EstadoSolicitud.canceladaPorInstitucion => Icons.person_remove_rounded,
};

Color colorEstadoDocumento(EstadoPedidoDocumento e) => switch (e) {
  EstadoPedidoDocumento.pendiente => AtenaStatusColors.pending,
  EstadoPedidoDocumento.entregado => AtenaStatusColors.inReview,
  EstadoPedidoDocumento.aprobado => AtenaStatusColors.approved,
  EstadoPedidoDocumento.rechazado => AtenaStatusColors.rejected,
  EstadoPedidoDocumento.cancelado => AtenaStatusColors.cancelled,
};

IconData iconoTipoEvento(TipoEvento x) => switch (x) {
  TipoEvento.general => Icons.event_rounded,
  TipoEvento.reunion => Icons.groups_rounded,
  TipoEvento.examen => Icons.edit_note_rounded,
  TipoEvento.acto => Icons.emoji_events_rounded,
  TipoEvento.salida => Icons.directions_bus_rounded,
  TipoEvento.inicioClases => Icons.school_rounded,
  TipoEvento.finClases => Icons.celebration_rounded,
  TipoEvento.vacaciones => Icons.beach_access_rounded,
  TipoEvento.feriado => Icons.flag_rounded,
};

Color colorTipoEvento(TipoEvento x) => switch (x) {
  TipoEvento.general => AtenaColors.indigo,
  TipoEvento.reunion => AtenaColors.blue,
  TipoEvento.examen => AtenaColors.danger,
  TipoEvento.acto => AtenaColors.goldDeep,
  TipoEvento.salida => AtenaColors.success,
  TipoEvento.inicioClases => AtenaColors.violet,
  TipoEvento.finClases => AtenaColors.violet,
  TipoEvento.vacaciones => AtenaColors.info,
  TipoEvento.feriado => AtenaColors.warning,
};

IconData iconoNivel(NivelCurricular n) => switch (n) {
  NivelCurricular.jardin => Icons.toys_rounded,
  NivelCurricular.primaria => Icons.backpack_rounded,
  NivelCurricular.secundaria => Icons.menu_book_rounded,
  NivelCurricular.tecnica => Icons.precision_manufacturing_rounded,
  NivelCurricular.terciario => Icons.school_rounded,
};

IconData iconoBloque(BloqueExtracurricular b) => switch (b) {
  BloqueExtracurricular.deporteYMovimiento => Icons.sports_soccer_rounded,
  BloqueExtracurricular.arteYExpresion => Icons.palette_rounded,
  BloqueExtracurricular.idiomasYComunicacion => Icons.translate_rounded,
  BloqueExtracurricular.cienciaTecnologiaYRobotica => Icons.smart_toy_rounded,
  BloqueExtracurricular.apoyoAcademico => Icons.lightbulb_rounded,
  BloqueExtracurricular.desarrolloPersonalYBienestar =>
    Icons.self_improvement_rounded,
  BloqueExtracurricular.otros => Icons.interests_rounded,
};

IconData iconoOferta(Oferta o) {
  if (o.esCurricular) {
    return o.nivel == null ? Icons.school_rounded : iconoNivel(o.nivel!);
  }
  return o.bloque == null ? Icons.interests_rounded : iconoBloque(o.bloque!);
}

IconData iconoDocumento(TipoDocumento x) => switch (x) {
  TipoDocumento.dni || TipoDocumento.dniResponsable => Icons.badge_rounded,
  TipoDocumento.partidaNacimiento => Icons.description_rounded,
  TipoDocumento.certificadoMedico => Icons.medical_services_rounded,
  TipoDocumento.carnetVacunas => Icons.vaccines_rounded,
  TipoDocumento.boletin => Icons.grading_rounded,
  TipoDocumento.pase => Icons.swap_horiz_rounded,
  TipoDocumento.foto => Icons.portrait_rounded,
  TipoDocumento.constanciaDomicilio => Icons.home_work_rounded,
  TipoDocumento.otro => Icons.attach_file_rounded,
};

// -----------------------------------------------------------------------------
// Notificaciones
// -----------------------------------------------------------------------------

class NotificacionVista {
  final String titulo;
  final String cuerpo;
  final IconData icono;
  final Color color;

  const NotificacionVista(this.titulo, this.cuerpo, this.icono, this.color);
}

NotificacionVista vistaNotificacion(BuildContext context, Notificacion n) {
  final t = AppLocalizations.of(context);
  final loc = MaterialLocalizations.of(context);
  String d(String k) => n.dato(k);
  String doc() => t.nombreDocumento(
    TipoDocumento.values.firstWhere(
      (x) => x.name == d('documento'),
      orElse: () => TipoDocumento.otro,
    ),
    d('detalle'),
  );
  String conNota(String base) =>
      d('nota').isEmpty ? base : '$base\n${t.notiNota(d('nota'))}';

  switch (n.tipo) {
    case TipoNotificacion.bienvenida:
      return NotificacionVista(
        t.notiBienvenidaTitle,
        t.notiBienvenidaBody,
        Icons.waving_hand_rounded,
        AtenaColors.indigo,
      );
    case TipoNotificacion.solicitudEnviada:
      return NotificacionVista(
        t.notiSolicitudEnviadaTitle,
        t.notiSolicitudEnviadaBody(d('alumno'), d('oferta'), d('institucion')),
        Icons.send_rounded,
        AtenaColors.info,
      );
    case TipoNotificacion.solicitudRecibida:
      return NotificacionVista(
        t.notiSolicitudRecibidaTitle,
        t.notiSolicitudRecibidaBody(d('alumno'), d('oferta')),
        Icons.move_to_inbox_rounded,
        AtenaColors.violet,
      );
    case TipoNotificacion.solicitudConfirmada:
      return NotificacionVista(
        t.notiSolicitudConfirmadaTitle,
        conNota(
          t.notiSolicitudConfirmadaBody(
            d('institucion'),
            d('alumno'),
            d('oferta'),
          ),
        ),
        Icons.check_circle_rounded,
        AtenaColors.success,
      );
    case TipoNotificacion.solicitudRechazada:
      return NotificacionVista(
        t.notiSolicitudRechazadaTitle,
        conNota(
          t.notiSolicitudRechazadaBody(
            d('institucion'),
            d('alumno'),
            d('oferta'),
          ),
        ),
        Icons.cancel_rounded,
        AtenaColors.danger,
      );
    case TipoNotificacion.solicitudCancelada:
      return NotificacionVista(
        t.notiSolicitudCanceladaTitle,
        t.notiSolicitudCanceladaBody(d('alumno'), d('oferta')),
        Icons.block_rounded,
        AtenaColors.neutral,
      );
    case TipoNotificacion.solicitudBaja:
      return NotificacionVista(
        t.notiSolicitudBajaTitle,
        conNota(
          t.notiSolicitudBajaBody(d('institucion'), d('alumno'), d('oferta')),
        ),
        Icons.person_remove_rounded,
        AtenaColors.warning,
      );
    case TipoNotificacion.documentoSolicitado:
      return NotificacionVista(
        t.notiDocSolicitadoTitle,
        t.notiDocSolicitadoBody(d('institucion'), doc()),
        Icons.upload_file_rounded,
        AtenaColors.warning,
      );
    case TipoNotificacion.documentoEntregado:
      return NotificacionVista(
        t.notiDocEntregadoTitle,
        t.notiDocEntregadoBody(d('alumno'), doc()),
        Icons.file_present_rounded,
        AtenaColors.info,
      );
    case TipoNotificacion.documentoAprobado:
      return NotificacionVista(
        t.notiDocAprobadoTitle,
        t.notiDocAprobadoBody(d('institucion'), doc()),
        Icons.task_alt_rounded,
        AtenaColors.success,
      );
    case TipoNotificacion.documentoRechazado:
      return NotificacionVista(
        t.notiDocRechazadoTitle,
        conNota(t.notiDocRechazadoBody(d('institucion'), doc())),
        Icons.report_rounded,
        AtenaColors.danger,
      );
    case TipoNotificacion.eventoPublicado:
      final fecha = DateTime.tryParse(d('fecha'));
      return NotificacionVista(
        t.notiEventoTitle,
        t.notiEventoBody(
          d('institucion'),
          d('evento'),
          fecha == null ? '' : loc.formatMediumDate(fecha),
        ),
        Icons.event_available_rounded,
        AtenaColors.indigo,
      );
    case TipoNotificacion.aviso:
      final titulo = n.titulo.isEmpty
          ? t.notiAvisoDe(d('institucion'))
          : n.titulo;
      return NotificacionVista(
        titulo,
        n.mensaje,
        Icons.campaign_rounded,
        AtenaColors.goldDeep,
      );
    case TipoNotificacion.cuentaEliminada:
      return NotificacionVista(
        t.notiCuentaEliminadaTitle,
        t.notiCuentaEliminadaBody(d('alumno'), d('oferta')),
        Icons.person_off_rounded,
        AtenaColors.neutral,
      );
    case TipoNotificacion.institucionEliminada:
      return NotificacionVista(
        t.notiInstitucionEliminadaTitle(d('institucion')),
        t.notiInstitucionEliminadaBody(d('alumno'), d('oferta')),
        Icons.domain_disabled_rounded,
        AtenaColors.warning,
      );
  }
}

// -----------------------------------------------------------------------------
// Errores
// -----------------------------------------------------------------------------

/// Mensaje para mostrar ante cualquier error de la capa de datos o de acceso.
String coreErrorText(AppLocalizations t, Object error) {
  if (error is AtenaException) {
    return switch (error.error) {
      AtenaError.noEncontrado => t.errNoEncontrado,
      AtenaError.noAutorizado => t.errNoAutorizado,
      AtenaError.datosInvalidos => t.errDatosInvalidos,
      AtenaError.ofertaInactiva => t.errOfertaInactiva,
      AtenaError.sinCupo => t.errSinCupo,
      AtenaError.solicitudDuplicada => t.errSolicitudDuplicada,
      AtenaError.estadoInvalido => t.errEstadoInvalido,
      AtenaError.ofertaConSolicitudes => t.errOfertaConSolicitudes,
      AtenaError.archivoMuyGrande => t.errArchivoMuyGrande,
      AtenaError.formatoNoSoportado => t.errFormatoNoSoportado,
      AtenaError.sinEspacio => t.errSinEspacio,
    };
  }
  if (error is AuthException) {
    return switch (error.code) {
      AuthErrorCode.invalidEmail => t.authErrInvalidEmail,
      AuthErrorCode.weakPassword => t.authErrWeakPassword,
      AuthErrorCode.emailInUse => t.authErrEmailInUse,
      AuthErrorCode.accountNotFound => t.authErrAccountNotFound,
      AuthErrorCode.wrongCredentials => t.authErrWrongCredentials,
      AuthErrorCode.invalidDni => t.authErrInvalidDni,
      AuthErrorCode.duplicateDni => t.authErrDuplicateDni,
      AuthErrorCode.identityMismatch => t.authErrIdentityMismatch,
      AuthErrorCode.invalidName => t.authErrInvalidName,
      AuthErrorCode.invalidAccount => t.authErrInvalidAccount,
      AuthErrorCode.unknown => t.uiSomethingWentWrong,
    };
  }
  return t.uiSomethingWentWrong;
}
