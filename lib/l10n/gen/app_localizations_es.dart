// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ATENA';

  @override
  String get instituciones => 'Instituciones';

  @override
  String get retry => 'Reintentar';

  @override
  String get curricular => 'Curricular';

  @override
  String get extracurricular => 'Extracurricular';

  @override
  String get code => 'Código';

  @override
  String get name => 'Nombre';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonInstitution => 'Institución';

  @override
  String get commonGenerating => 'Generando…';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailRequired => 'Ingresá tu email.';

  @override
  String get commonPassword => 'Contraseña';

  @override
  String get commonNewPassword => 'Nueva contraseña';

  @override
  String get commonPasswordsDontMatch => 'Las contraseñas no coinciden.';

  @override
  String get commonShowPassword => 'Mostrar contraseña';

  @override
  String get commonHidePassword => 'Ocultar contraseña';

  @override
  String get commonRememberMe => 'Recordarme';

  @override
  String get commonSignIn => 'Ingresar';

  @override
  String get commonSigningIn => 'Ingresando…';

  @override
  String get commonCreateAccount => 'Crear cuenta';

  @override
  String get commonCreating => 'Creando…';

  @override
  String get commonLogout => 'Cerrar sesión';

  @override
  String get commonNameLabel => 'Nombre';

  @override
  String get commonLastNameLabel => 'Apellido';

  @override
  String get commonEmailOptionalLabel => 'Email (opcional)';

  @override
  String get commonPhoneOptionalLabel => 'Teléfono (opcional)';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonPrevMonth => 'Mes anterior';

  @override
  String get commonNextMonth => 'Mes siguiente';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonTitle => 'Título';

  @override
  String get commonView => 'Ver';

  @override
  String get commonSending => 'Enviando…';

  @override
  String get commonFieldRequired => 'Campo obligatorio.';

  @override
  String get commonTooShort => 'Muy corto.';

  @override
  String get commonPhone => 'Teléfono';

  @override
  String get commonPhoneInvalid => 'Teléfono inválido.';

  @override
  String get commonContinuing => 'Continuando…';

  @override
  String get commonContinueToPlan => 'Continuar al plan';

  @override
  String get commonPasswordRequired => 'Ingresá una contraseña.';

  @override
  String get institucionRegistroSectionBasics => 'Datos básicos';

  @override
  String get institucionRegistroInstitutionName => 'Nombre de la institución';

  @override
  String get institucionRegistroCuit => 'CUIT';

  @override
  String get institucionRegistroCuitInvalid => 'CUIT inválido.';

  @override
  String get institucionRegistroAddress => 'Dirección';

  @override
  String get institucionRegistroSectionLocation => 'Ubicación';

  @override
  String get institucionRegistroCountry => 'País';

  @override
  String get institucionRegistroProvince => 'Provincia';

  @override
  String get institucionRegistroCity => 'Ciudad';

  @override
  String get institucionRegistroSectionAccessContact => 'Acceso y contacto';

  @override
  String get commonRequiredField => 'Campo obligatorio.';

  @override
  String get uiSomethingWentWrong => 'Algo salió mal';

  @override
  String get landingTagline => 'Educación conectada';

  @override
  String get landingHeadline => 'Alumnos e instituciones, en un mismo lugar.';

  @override
  String get landingSubtitle =>
      'Inscripciones, vacantes, documentos y calendario, sin papeles ni idas y vueltas.';

  @override
  String get landingStudentTitle => 'Soy alumno o familia';

  @override
  String get landingStudentSubtitle =>
      'Buscá instituciones, pedí tu vacante y seguí cada trámite.';

  @override
  String get landingInstitutionTitle => 'Soy una institución';

  @override
  String get landingInstitutionSubtitle =>
      'Gestioná vacantes, solicitudes, grupos y comunicaciones.';

  @override
  String get landingChooseHowToEnter => '¿Cómo querés ingresar?';

  @override
  String get landingChooseHowToEnterSubtitle =>
      'Elegí tu perfil para continuar.';

  @override
  String get landingBulletRequests => 'Solicitudes de vacantes en línea';

  @override
  String get landingBulletDocuments => 'Fichas y documentos en PDF';

  @override
  String get landingBulletCalendar => 'Calendario y avisos al instante';

  @override
  String landingFooter(Object year) {
    return '© $year ATENA · Plataforma educativa';
  }

  @override
  String get prefsTitle => 'Preferencias';

  @override
  String get prefsTheme => 'Apariencia';

  @override
  String get prefsThemeSystem => 'Automático';

  @override
  String get prefsThemeLight => 'Claro';

  @override
  String get prefsThemeDark => 'Oscuro';

  @override
  String get prefsLanguage => 'Idioma';

  @override
  String get prefsLanguageSystem => 'Automático (idioma del dispositivo)';

  @override
  String get authFamiliaLoginTitle => 'Ingresá a tu cuenta';

  @override
  String get authFamiliaLoginSubtitle => 'Alumnos y familias';

  @override
  String get authInstitucionLoginTitle => 'Ingreso de instituciones';

  @override
  String get authInstitucionLoginSubtitle =>
      'Gestioná vacantes, solicitudes y comunicaciones.';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authNoAccount => '¿Todavía no tenés cuenta?';

  @override
  String get authNoInstitution => '¿Tu institución todavía no está en ATENA?';

  @override
  String get authRegisterInstitution => 'Registrar institución';

  @override
  String get authHaveAccount => '¿Ya tenés cuenta?';

  @override
  String get authFamiliaRegisterTitle => 'Creá tu cuenta';

  @override
  String get authFamiliaRegisterSubtitle =>
      'En dos minutos vas a poder buscar instituciones y pedir vacantes.';

  @override
  String get authStudentSection => 'Datos del alumno';

  @override
  String get authStudentSectionHelp =>
      'Si sos madre, padre o tutor, cargá los datos del alumno. Después podés sumar más alumnos a la misma cuenta.';

  @override
  String get authAccessSection => 'Datos de acceso';

  @override
  String get authBirthDate => 'Fecha de nacimiento';

  @override
  String get authBirthDateRequired => 'Elegí la fecha de nacimiento.';

  @override
  String get authDniLabel => 'DNI';

  @override
  String get authDniHelper => 'Solo números, sin puntos.';

  @override
  String get authPasswordHelper => 'Mínimo 8 caracteres.';

  @override
  String get authPasswordConfirm => 'Repetí la contraseña';

  @override
  String get authResetTitle => 'Restablecer contraseña';

  @override
  String get authResetFamiliaSubtitle =>
      'Confirmá tu identidad con el DNI de un alumno de la cuenta y elegí una contraseña nueva.';

  @override
  String get authResetInstitucionSubtitle =>
      'Confirmá tu identidad con el CUIT registrado y elegí una contraseña nueva.';

  @override
  String get authResetDniLabel => 'DNI de un alumno de la cuenta';

  @override
  String get authCuitHelper => '11 dígitos, sin guiones.';

  @override
  String get authResetCta => 'Guardar contraseña nueva';

  @override
  String get authResetDone =>
      'Listo. Ya podés ingresar con tu contraseña nueva.';

  @override
  String get authInstRegisterTitle => 'Registrá tu institución';

  @override
  String get authInstRegisterSubtitle =>
      'Completá los datos y en el siguiente paso elegí los módulos de tu plan.';

  @override
  String authStepOf(Object step, Object total) {
    return 'Paso $step de $total';
  }

  @override
  String get authErrInvalidEmail => 'El email no es válido.';

  @override
  String get authErrWeakPassword =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get authErrEmailInUse => 'Ya existe una cuenta con ese email.';

  @override
  String get authErrAccountNotFound =>
      'No encontramos una cuenta con esos datos.';

  @override
  String get authErrWrongCredentials => 'Email o contraseña incorrectos.';

  @override
  String get authErrInvalidDni => 'El DNI debe tener entre 7 y 9 dígitos.';

  @override
  String get authErrDuplicateDni =>
      'Ya hay un alumno con ese DNI en tu cuenta.';

  @override
  String get authErrIdentityMismatch =>
      'Los datos no coinciden con los de la cuenta.';

  @override
  String get authErrInvalidName => 'Completá nombre y apellido.';

  @override
  String get authErrInvalidAccount =>
      'La sesión no es válida. Volvé a ingresar.';

  @override
  String get lblNivelJardin => 'Nivel inicial';

  @override
  String get lblNivelPrimaria => 'Primaria';

  @override
  String get lblNivelSecundaria => 'Secundaria';

  @override
  String get lblNivelTecnica => 'Técnica';

  @override
  String get lblNivelTerciario => 'Terciario';

  @override
  String get lblBloqueDeporte => 'Deporte y movimiento';

  @override
  String get lblBloqueArte => 'Arte y expresión';

  @override
  String get lblBloqueIdiomas => 'Idiomas y comunicación';

  @override
  String get lblBloqueCiencia => 'Ciencia, tecnología y robótica';

  @override
  String get lblBloqueApoyo => 'Apoyo académico';

  @override
  String get lblBloqueBienestar => 'Desarrollo personal y bienestar';

  @override
  String get lblBloqueOtros => 'Otras actividades';

  @override
  String get lblTurnoManana => 'Mañana';

  @override
  String get lblTurnoTarde => 'Tarde';

  @override
  String get lblTurnoNoche => 'Noche';

  @override
  String get lblTurnoCompleto => 'Jornada completa';

  @override
  String get lblModalidadPresencial => 'Presencial';

  @override
  String get lblModalidadRemoto => 'A distancia';

  @override
  String get lblModalidadHibrido => 'Híbrida';

  @override
  String get lblTipoInstJardin => 'Jardín de infantes';

  @override
  String get lblTipoInstPrimaria => 'Escuela primaria';

  @override
  String get lblTipoInstSecundaria => 'Escuela secundaria';

  @override
  String get lblTipoInstTecnica => 'Escuela técnica';

  @override
  String get lblTipoInstTerciario => 'Instituto terciario';

  @override
  String get lblTipoInstTaller => 'Taller o academia';

  @override
  String get lblTipoInstClub => 'Club';

  @override
  String get lblTipoInstOtra => 'Otra institución';

  @override
  String get lblCurricular => 'Curricular';

  @override
  String get lblExtracurricular => 'Extracurricular';

  @override
  String get lblEstadoPendiente => 'Pendiente';

  @override
  String get lblEstadoConfirmada => 'Confirmada';

  @override
  String get lblEstadoRechazada => 'No aceptada';

  @override
  String get lblEstadoCanceladaAlumno => 'Cancelada';

  @override
  String get lblEstadoCanceladaInstitucion => 'Dada de baja';

  @override
  String get lblDocDni => 'DNI del alumno';

  @override
  String get lblDocDniResponsable => 'DNI del adulto responsable';

  @override
  String get lblDocPartida => 'Partida de nacimiento';

  @override
  String get lblDocCertMedico => 'Certificado médico';

  @override
  String get lblDocVacunas => 'Carnet de vacunas';

  @override
  String get lblDocBoletin => 'Boletín de calificaciones';

  @override
  String get lblDocPase => 'Constancia de pase';

  @override
  String get lblDocFoto => 'Foto carnet';

  @override
  String get lblDocDomicilio => 'Constancia de domicilio';

  @override
  String get lblDocOtro => 'Otro documento';

  @override
  String get lblDocEstadoPendiente => 'Por entregar';

  @override
  String get lblDocEstadoEntregado => 'En revisión';

  @override
  String get lblDocEstadoAprobado => 'Aprobado';

  @override
  String get lblDocEstadoRechazado => 'Para corregir';

  @override
  String get lblDocEstadoCancelado => 'Cancelado';

  @override
  String get lblDocVencido => 'Vencido';

  @override
  String get lblEvGeneral => 'Evento';

  @override
  String get lblEvReunion => 'Reunión';

  @override
  String get lblEvExamen => 'Evaluación';

  @override
  String get lblEvActo => 'Acto escolar';

  @override
  String get lblEvSalida => 'Salida educativa';

  @override
  String get lblEvInicioClases => 'Inicio de clases';

  @override
  String get lblEvFinClases => 'Fin de clases';

  @override
  String get lblEvVacaciones => 'Vacaciones';

  @override
  String get lblEvFeriado => 'Feriado';

  @override
  String get lblAsisSi => 'Asistiré';

  @override
  String get lblAsisTalVez => 'Tal vez';

  @override
  String get lblAsisNo => 'No asistiré';

  @override
  String lblEdadAnios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n años',
      one: '1 año',
    );
    return '$_temp0';
  }

  @override
  String lblRangoEdad(Object min, Object max) {
    return 'De $min a $max años';
  }

  @override
  String lblEdadDesde(Object min) {
    return 'Desde $min años';
  }

  @override
  String lblEdadHasta(Object max) {
    return 'Hasta $max años';
  }

  @override
  String lblCupos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vacantes',
      one: '1 vacante',
      zero: 'Sin vacantes',
    );
    return '$_temp0';
  }

  @override
  String lblCuposDeTotal(int libres, int total) {
    return '$libres de $total libres';
  }

  @override
  String get notiBienvenidaTitle => '¡Te damos la bienvenida a ATENA!';

  @override
  String get notiBienvenidaBody =>
      'Ya podés buscar instituciones y pedir vacantes.';

  @override
  String get notiSolicitudEnviadaTitle => 'Solicitud enviada';

  @override
  String notiSolicitudEnviadaBody(
    Object alumno,
    Object oferta,
    Object institucion,
  ) {
    return '$alumno · $oferta en $institucion. Te avisamos cuando respondan.';
  }

  @override
  String get notiSolicitudRecibidaTitle => 'Nueva solicitud';

  @override
  String notiSolicitudRecibidaBody(Object alumno, Object oferta) {
    return '$alumno pidió vacante en $oferta.';
  }

  @override
  String get notiSolicitudConfirmadaTitle => '¡Vacante confirmada!';

  @override
  String notiSolicitudConfirmadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion confirmó a $alumno en $oferta.';
  }

  @override
  String get notiSolicitudRechazadaTitle => 'Solicitud no aceptada';

  @override
  String notiSolicitudRechazadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion no pudo aceptar la solicitud de $alumno para $oferta.';
  }

  @override
  String get notiSolicitudCanceladaTitle => 'Solicitud cancelada';

  @override
  String notiSolicitudCanceladaBody(Object alumno, Object oferta) {
    return '$alumno canceló su solicitud para $oferta.';
  }

  @override
  String get notiSolicitudBajaTitle => 'Baja de vacante';

  @override
  String notiSolicitudBajaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion dio de baja a $alumno de $oferta.';
  }

  @override
  String get notiDocSolicitadoTitle => 'Te pidieron un documento';

  @override
  String notiDocSolicitadoBody(Object institucion, Object documento) {
    return '$institucion necesita: $documento.';
  }

  @override
  String get notiDocEntregadoTitle => 'Documento recibido';

  @override
  String notiDocEntregadoBody(Object alumno, Object documento) {
    return '$alumno entregó: $documento.';
  }

  @override
  String get notiDocAprobadoTitle => 'Documento aprobado';

  @override
  String notiDocAprobadoBody(Object institucion, Object documento) {
    return '$institucion aprobó: $documento.';
  }

  @override
  String get notiDocRechazadoTitle => 'Documento para corregir';

  @override
  String notiDocRechazadoBody(Object institucion, Object documento) {
    return '$institucion pidió corregir: $documento.';
  }

  @override
  String get notiEventoTitle => 'Nuevo evento en el calendario';

  @override
  String notiEventoBody(Object institucion, Object evento, Object fecha) {
    return '$institucion: $evento, el $fecha.';
  }

  @override
  String notiAvisoDe(Object institucion) {
    return 'Aviso de $institucion';
  }

  @override
  String notiNota(Object nota) {
    return 'Mensaje: $nota';
  }

  @override
  String get errNoEncontrado =>
      'No encontramos lo que buscabas. Puede que se haya eliminado.';

  @override
  String get errNoAutorizado => 'No tenés permiso para hacer esto.';

  @override
  String get errDatosInvalidos => 'Revisá los datos ingresados.';

  @override
  String get errOfertaInactiva =>
      'Esta vacante no está recibiendo solicitudes por ahora.';

  @override
  String get errSinCupo => 'No quedan vacantes disponibles.';

  @override
  String get errSolicitudDuplicada =>
      'Ya hay una solicitud activa para esta vacante.';

  @override
  String get errEstadoInvalido => 'Esta acción ya no está disponible.';

  @override
  String get errOfertaConSolicitudes =>
      'No se puede eliminar porque tiene solicitudes activas. Podés pausarla.';

  @override
  String get errArchivoMuyGrande => 'El archivo es demasiado grande.';

  @override
  String get errFormatoNoSoportado =>
      'Formato no admitido. Usá PDF o una imagen.';

  @override
  String get errSinEspacio => 'No hay espacio suficiente en el dispositivo.';

  @override
  String get uiJustNow => 'Recién';

  @override
  String uiMinutesAgo(int n) {
    return 'Hace $n min';
  }

  @override
  String uiHoursAgo(int n) {
    return 'Hace $n h';
  }

  @override
  String get uiYesterday => 'Ayer';

  @override
  String get uiToday => 'Hoy';

  @override
  String get uiTomorrow => 'Mañana';

  @override
  String get uiUndo => 'Deshacer';

  @override
  String get uiMoreOptions => 'Más opciones';

  @override
  String get uiSeeAll => 'Ver todas';

  @override
  String get uiClose => 'Cerrar';

  @override
  String get uiLogoutConfirm => '¿Querés cerrar la sesión?';

  @override
  String get notifTitle => 'Notificaciones';

  @override
  String get notifMarkAllRead => 'Marcar todas como leídas';

  @override
  String get notifDeleteAll => 'Eliminar todas';

  @override
  String get notifDeleteAllConfirm => '¿Eliminar todas las notificaciones?';

  @override
  String get notifEmptyTitle => 'Estás al día';

  @override
  String get notifEmptyBody =>
      'Acá vas a ver las novedades de solicitudes, documentos y eventos.';

  @override
  String get notifFilterAll => 'Todas';

  @override
  String get notifFilterUnread => 'No leídas';

  @override
  String get notifDeleted => 'Notificación eliminada';

  @override
  String get notifMarkRead => 'Marcar como leída';

  @override
  String get notifMarkUnread => 'Marcar como no leída';

  @override
  String get notifDelete => 'Eliminar';

  @override
  String notifUnreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sin leer',
      one: '1 sin leer',
    );
    return '$_temp0';
  }

  @override
  String homeHello(Object nombre) {
    return 'Hola, $nombre';
  }

  @override
  String get homeStudentSubtitle => '¿Qué querés hacer hoy?';

  @override
  String get homeSwitchStudent => 'Cambiar alumno';

  @override
  String get homeStatActiveRequests => 'Solicitudes activas';

  @override
  String get homeStatUpcomingEvents => 'Próximos eventos';

  @override
  String get homeStatPendingDocs => 'Documentos por entregar';

  @override
  String get homeActionExplore => 'Explorar instituciones';

  @override
  String get homeActionExploreSub => 'Buscá y pedí tu vacante';

  @override
  String get homeActionRequests => 'Mis solicitudes';

  @override
  String get homeActionRequestsSub => 'Seguí el estado de cada trámite';

  @override
  String get homeActionCalendar => 'Calendario';

  @override
  String get homeActionCalendarSub => 'Eventos y recordatorios';

  @override
  String get homeActionDocuments => 'Documentos';

  @override
  String get homeActionDocumentsSub => 'Lo que te piden las instituciones';

  @override
  String get homeActionNotificationsSub => 'Novedades y avisos';

  @override
  String get homeActionProfile => 'Ficha del alumno';

  @override
  String get homeActionProfileSub => 'Datos personales y PDF';

  @override
  String get homeRecentRequests => 'Tus solicitudes';

  @override
  String get homeNoRequestsTitle => 'Todavía no pediste vacantes';

  @override
  String get homeNoRequestsBody =>
      'Explorá instituciones y enviá tu primera solicitud en pocos pasos.';

  @override
  String get homeNoEvents => 'No hay eventos próximos.';

  @override
  String get hubTitle => '¿Con qué alumno querés continuar?';

  @override
  String get hubSubtitle =>
      'Podés gestionar a varios alumnos desde la misma cuenta.';

  @override
  String get hubAddStudent => 'Agregar alumno';

  @override
  String get hubAddStudentSub => 'Sumá a otro hijo o hija a tu cuenta';

  @override
  String get hubEmptyTitle => 'Agregá el primer alumno';

  @override
  String get hubEmptyBody =>
      'Cargá los datos del alumno para empezar a buscar instituciones.';

  @override
  String get hubLastUsed => 'Último usado';

  @override
  String hubAccountLine(Object email) {
    return 'Cuenta: $email';
  }

  @override
  String get studentFormTitleNew => 'Nuevo alumno';

  @override
  String get studentFormTitleEdit => 'Editar datos';

  @override
  String get studentFormSaved => 'Datos guardados.';

  @override
  String get studentFormCreated => 'Alumno agregado.';

  @override
  String get instHomeSubtitle => 'Panel de la institución';

  @override
  String instPlanTrialUntil(Object fecha) {
    return 'Prueba hasta el $fecha';
  }

  @override
  String get instPlanTrialEnded => 'Prueba vencida';

  @override
  String get instPlanActive => 'Plan activo';

  @override
  String get instPlanSuspended => 'Plan suspendido';

  @override
  String get instPlanNone => 'Sin plan';

  @override
  String get instStatPending => 'Solicitudes pendientes';

  @override
  String get instStatStudents => 'Alumnos confirmados';

  @override
  String get instStatFreeSpots => 'Vacantes libres';

  @override
  String get instStatOffers => 'Ofertas activas';

  @override
  String get instActionRequests => 'Solicitudes';

  @override
  String get instActionRequestsSub => 'Revisá y respondé pedidos de vacante';

  @override
  String get instActionOffers => 'Vacantes';

  @override
  String get instActionOffersSub => 'Cursos, grupos y cupos';

  @override
  String get instActionStudents => 'Alumnos';

  @override
  String get instActionStudentsSub => 'Inscriptos por curso y grupo';

  @override
  String get instActionComms => 'Comunicaciones';

  @override
  String get instActionCommsSub => 'Calendario y avisos';

  @override
  String get instActionDocs => 'Documentación';

  @override
  String get instActionDocsSub => 'Pedidos y revisión de documentos';

  @override
  String get instActionCroquis => 'Croquis de aula';

  @override
  String get instActionCroquisSub => 'Distribución de bancos';

  @override
  String get instActionProfile => 'Perfil público';

  @override
  String get instActionProfileSub => 'Cómo te ven las familias';

  @override
  String get instActionPlan => 'Plan';

  @override
  String get instActionPlanSub => 'Niveles, módulos y costo';

  @override
  String get instGettingStarted => 'Primeros pasos';

  @override
  String get instGettingStartedSub =>
      'Completá estos pasos para empezar a recibir alumnos.';

  @override
  String get instStepProfile => 'Completá tu perfil público';

  @override
  String get instStepOffer => 'Publicá tu primera vacante';

  @override
  String get instStepRequest => 'Recibí tu primera solicitud';

  @override
  String get instToReview => 'Para revisar';

  @override
  String get instNoPending => 'No hay solicitudes pendientes. ¡Todo al día!';

  @override
  String get instLoadError => 'No pudimos cargar los datos de la institución.';

  @override
  String get instSignInAgain => 'Volver a ingresar';

  @override
  String get notifOlder => 'Anteriores';

  @override
  String get prefsAbout => 'Acerca de ATENA';

  @override
  String prefsVersion(Object version) {
    return 'Versión $version';
  }

  @override
  String get prefsPrivacyTitle => 'Privacidad y datos';

  @override
  String get prefsPrivacyBody =>
      'En esta versión, ATENA guarda toda la información (cuentas, alumnos, solicitudes, documentos y fotos) únicamente en este dispositivo. No se envía a servidores ni a terceros. Las contraseñas se guardan protegidas con un hash seguro. Podés eliminar tu cuenta cuando quieras desde el menú «Más opciones» de tu inicio.';

  @override
  String get prefsDeleteData => 'Borrar todos los datos de este dispositivo';

  @override
  String get prefsDeleteDataConfirmTitle => '¿Borrar todos los datos?';

  @override
  String get prefsDeleteDataConfirm =>
      'Se eliminarán todas las cuentas, alumnos, instituciones, solicitudes y documentos guardados en este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get prefsDeleteDataCta => 'Borrar todo';

  @override
  String get prefsDeleteDataDone => 'Se borraron todos los datos.';

  @override
  String get demoLink => 'Probar con datos de ejemplo';

  @override
  String get demoConfirmTitle => '¿Cargar datos de ejemplo?';

  @override
  String get demoConfirmBody =>
      'Vamos a crear en este dispositivo tres instituciones y una familia de ejemplo para que recorras ATENA. Podés borrarlos cuando quieras desde Preferencias.';

  @override
  String get demoConfirmCta => 'Cargar ejemplo';

  @override
  String get demoLoading => 'Preparando los datos de ejemplo…';

  @override
  String get demoReadyTitle => '¡Listo! Ya podés recorrer ATENA';

  @override
  String demoReadyBody(Object password) {
    return 'Usá estas cuentas de ejemplo. La contraseña de todas es $password.';
  }

  @override
  String get demoFamilyLabel => 'Familia con dos alumnos';

  @override
  String get demoInstitutionsLabel => 'Instituciones';

  @override
  String get demoEnterFamily => 'Entrar como familia';

  @override
  String get demoEnterInstitution => 'Entrar como el colegio';

  @override
  String get demoAlreadyLoaded => 'Los datos de ejemplo ya estaban cargados.';

  @override
  String get calAlTitulo => 'Calendario';

  @override
  String get calAlNuevaNota => 'Nueva nota';

  @override
  String get calAlEditarNota => 'Editar nota';

  @override
  String get calAlEliminarNota => 'Eliminar nota';

  @override
  String get calAlEliminarNotaConfirm => '¿Eliminar la nota?';

  @override
  String calAlEliminarNotaMensaje(String titulo) {
    return '«$titulo» se va a quitar de tu calendario.';
  }

  @override
  String get calAlNotaGuardada => 'Nota guardada.';

  @override
  String get calAlNotaEliminada => 'Nota eliminada.';

  @override
  String get calAlNotaTituloHint => 'Ej.: Llevar la autorización firmada';

  @override
  String get calAlNotaHora => 'Hora (opcional)';

  @override
  String get calAlNotaQuitarHora => 'Quitar hora';

  @override
  String get calAlNotaDetalle => 'Detalle (opcional)';

  @override
  String get calAlNotaPersonal => 'Nota personal';

  @override
  String get calAlNotaAyuda => 'Tus notas son privadas: solo las ves vos.';

  @override
  String get calAlTodoElDia => 'Todo el día';

  @override
  String calAlRango(String desde, String hasta) {
    return 'Del $desde al $hasta';
  }

  @override
  String get calAlCuando => 'Cuándo';

  @override
  String get calAlLugar => 'Lugar';

  @override
  String get calAlAsistenciaTitulo => '¿Vas a asistir?';

  @override
  String get calAlAsistenciaAyuda =>
      'La institución te pide que confirmes tu asistencia.';

  @override
  String get calAlAsistenciaPasado => 'Este evento ya pasó.';

  @override
  String calAlAsistenciaGuardada(String respuesta) {
    return 'Respuesta enviada: $respuesta.';
  }

  @override
  String get calAlResponder => 'Confirmá tu asistencia';

  @override
  String get calAlNadaEsteDia => 'No tenés nada agendado para este día.';

  @override
  String get calAlAgregarNota => 'Agregar una nota';

  @override
  String get calAlProximos => 'Próximos';

  @override
  String get calAlVacioTitulo => 'Tu calendario está listo';

  @override
  String get calAlVacioMensaje =>
      'Acá vas a ver los eventos que publiquen las instituciones donde tengas la vacante confirmada: reuniones, actos, salidas y más. También podés agregar tus propias notas y recordatorios.';

  @override
  String get calAlSinEventos =>
      'Los eventos de tus instituciones van a aparecer acá cuando tengas una vacante confirmada.';

  @override
  String calAlDiaItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n actividades',
      one: '1 actividad',
      zero: 'Nada agendado',
    );
    return '$_temp0';
  }

  @override
  String get calAlEventoNoDisponible => 'Este evento ya no está disponible.';

  @override
  String get docAlTitulo => 'Documentos';

  @override
  String docAlHeroPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tenés $n documentos para entregar',
      one: 'Tenés 1 documento para entregar',
    );
    return '$_temp0';
  }

  @override
  String get docAlHeroPendientesSub =>
      'Subilos desde acá: podés sacar una foto o elegir un archivo.';

  @override
  String get docAlHeroAlDia => '¡Todo al día!';

  @override
  String get docAlHeroAlDiaSub =>
      'Te avisamos si una institución te pide algo nuevo.';

  @override
  String get docAlSeccionEntregar => 'Para entregar';

  @override
  String get docAlSeccionEntregarSub =>
      'Subilos para completar la inscripción.';

  @override
  String get docAlSeccionRevision => 'En revisión';

  @override
  String get docAlSeccionRevisionSub =>
      'La institución los está revisando. Te avisamos cuando responda.';

  @override
  String get docAlSeccionAprobados => 'Aprobados';

  @override
  String get docAlSeccionHistorial => 'Historial';

  @override
  String get docAlSeccionHistorialSub => 'Pedidos que la institución canceló';

  @override
  String get docAlNadaParaEntregar => 'No tenés documentos para entregar.';

  @override
  String get docAlVacioTitulo => 'No tenés documentos pendientes';

  @override
  String get docAlVacioMensaje =>
      'Cuando una institución te pida un documento, como el DNI o un certificado médico, lo vas a ver acá y vas a poder subirlo en un par de pasos.';

  @override
  String get docAlSubirArchivo => 'Subir archivo';

  @override
  String get docAlReemplazarArchivo => 'Reemplazar archivo';

  @override
  String get docAlVerArchivo => 'Ver archivo';

  @override
  String get docAlSubiendo => 'Subiendo…';

  @override
  String get docAlEntregado =>
      '¡Listo! Enviamos el documento a la institución.';

  @override
  String get docAlMotivo => 'Motivo';

  @override
  String get docAlRechazadoSinMotivo =>
      'La institución pidió que vuelvas a subirlo.';

  @override
  String docAlEntregarHasta(String fecha) {
    return 'Entregar hasta el $fecha';
  }

  @override
  String docAlVencio(String fecha) {
    return 'Venció el $fecha';
  }

  @override
  String get docAlVenceHoy => 'Vence hoy';

  @override
  String get docAlVenceManiana => 'Vence mañana';

  @override
  String docAlPedidoEl(String fecha) {
    return 'Pedido el $fecha';
  }

  @override
  String docAlEntregadoEl(String fecha) {
    return 'Entregado el $fecha';
  }

  @override
  String docAlAprobadoEl(String fecha) {
    return 'Aprobado el $fecha';
  }

  @override
  String docAlCanceladoEl(String fecha) {
    return 'Cancelado el $fecha';
  }

  @override
  String get docAlIndicaciones => 'Indicaciones';

  @override
  String get docAlFechaPedido => 'Fecha del pedido';

  @override
  String get docAlFechaLimite => 'Fecha límite';

  @override
  String get docAlArchivoEntregado => 'Archivo entregado';

  @override
  String get docAlAyudaPendiente =>
      'Subí el archivo para que la institución pueda revisarlo.';

  @override
  String get docAlAyudaVencido =>
      'La fecha límite ya pasó. Subilo lo antes posible.';

  @override
  String get docAlAyudaRevision =>
      'La institución lo está revisando. Si te equivocaste de archivo, podés reemplazarlo.';

  @override
  String get docAlAyudaAprobado =>
      'La institución aprobó este documento. No tenés que hacer nada más.';

  @override
  String get docAlAyudaCancelado =>
      'La institución canceló este pedido. Ya no hace falta entregarlo.';

  @override
  String get docAlFuenteTitulo => '¿Cómo querés subirlo?';

  @override
  String get docAlFuenteArchivo => 'Elegir un archivo';

  @override
  String get docAlFuenteArchivoSub =>
      'PDF o imagen (JPG, PNG, WEBP o HEIC) de hasta 3 MB';

  @override
  String get docAlFuenteCamara => 'Sacar una foto';

  @override
  String get docAlFuenteCamaraSub => 'Fotografiá el documento con la cámara';

  @override
  String get docAlFuenteGaleria => 'Elegir una foto';

  @override
  String get docAlFuenteGaleriaSub =>
      'De las imágenes guardadas en tu dispositivo';

  @override
  String get docAlFuenteTip =>
      'Consejo: sacá la foto con buena luz y asegurate de que se lea todo el documento.';

  @override
  String get docAlErrorSeleccion =>
      'No pudimos abrir el archivo ni la cámara. Revisá los permisos e intentá de nuevo.';

  @override
  String get docAlErrorArchivo => 'No encontramos el archivo entregado.';

  @override
  String get docAlErrorPdf =>
      'No pudimos abrir el PDF. Probá de nuevo en unos minutos.';

  @override
  String get docAlSinVistaPrevia =>
      'No se puede mostrar la vista previa de esta imagen.';

  @override
  String get docAlNoDisponible => 'Este pedido ya no está disponible.';

  @override
  String get fichaAlTitulo => 'Ficha del alumno';

  @override
  String fichaAlDni(String dni) {
    return 'DNI $dni';
  }

  @override
  String get fichaAlAgregarFoto => 'Agregar foto';

  @override
  String get fichaAlCambiarFoto => 'Cambiar foto';

  @override
  String get fichaAlFotoCamara => 'Sacar una foto';

  @override
  String get fichaAlFotoGaleria => 'Elegir de la galería';

  @override
  String get fichaAlFotoArchivo => 'Elegir una imagen';

  @override
  String get fichaAlQuitarFoto => 'Quitar foto';

  @override
  String get fichaAlQuitarFotoConfirm => '¿Quitar la foto?';

  @override
  String get fichaAlQuitarFotoMensaje =>
      'En su lugar se van a mostrar las iniciales del alumno.';

  @override
  String get fichaAlFotoGuardada => 'Foto actualizada.';

  @override
  String get fichaAlFotoEliminada => 'Foto eliminada.';

  @override
  String get fichaAlFotoError =>
      'No pudimos abrir la cámara ni la galería. Revisá los permisos e intentá de nuevo.';

  @override
  String get fichaAlDatosPersonales => 'Datos personales';

  @override
  String get fichaAlEditarDatos => 'Editar datos';

  @override
  String get fichaAlInstituciones => 'Instituciones';

  @override
  String get fichaAlInstitucionesSub => 'Donde tiene la vacante confirmada';

  @override
  String get fichaAlSinInstituciones =>
      'Todavía no hay vacantes confirmadas. Cuando una institución confirme una solicitud, la vas a ver acá.';

  @override
  String fichaAlConfirmadaEl(String fecha) {
    return 'Confirmada el $fecha';
  }

  @override
  String get fichaAlPdf => 'Ficha en PDF';

  @override
  String get fichaAlPdfSub =>
      'Para presentar en una institución o guardar una copia';

  @override
  String get fichaAlDescargarPdf => 'Descargar ficha en PDF';

  @override
  String get fichaAlDescargarPdfSub =>
      'Con los datos personales, la foto y las instituciones';

  @override
  String get fichaAlImprimir => 'Imprimir';

  @override
  String get fichaAlImprimirSub =>
      'Abrí la vista previa para imprimir la ficha';

  @override
  String get fichaAlGenerando => 'Generando PDF…';

  @override
  String get fichaAlPdfError =>
      'No pudimos generar el PDF. Probá de nuevo en unos minutos.';

  @override
  String get ofertasNueva => 'Nueva vacante';

  @override
  String get ofertasErrorCarga => 'No pudimos cargar las vacantes.';

  @override
  String get ofertasSinPlanTitulo =>
      'Tu plan todavía no incluye niveles ni actividades';

  @override
  String get ofertasSinPlanMensaje =>
      'Para publicar vacantes, habilitá niveles curriculares o actividades extracurriculares en Plan, desde el panel de la institución.';

  @override
  String get ofertasVolverPanel => 'Volver al panel';

  @override
  String get ofertasTipoFueraDelPlan =>
      'Tu plan actual no incluye este tipo de vacantes. Podés editar, pausar o eliminar las que ya publicaste.';

  @override
  String get ofertasFueraDelPlan => 'Fuera de tu plan';

  @override
  String get ofertasVacioCurricularTitulo =>
      'Todavía no publicaste vacantes curriculares';

  @override
  String get ofertasVacioCurricularMensaje =>
      'Creá los grados, años o salas con su cupo para que las familias puedan pedir vacante.';

  @override
  String get ofertasVacioExtraTitulo =>
      'Todavía no publicaste actividades extracurriculares';

  @override
  String get ofertasVacioExtraMensaje =>
      'Sumá talleres, deportes o idiomas con su cupo y horario para que las familias puedan inscribirse.';

  @override
  String ofertasNOfertas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ofertas',
      one: '1 oferta',
    );
    return '$_temp0';
  }

  @override
  String ofertasNLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vacantes libres',
      one: '1 vacante libre',
      zero: 'Sin vacantes libres',
    );
    return '$_temp0';
  }

  @override
  String ofertasAgregarEn(Object categoria) {
    return 'Agregar vacante en $categoria';
  }

  @override
  String get ofertasActiva => 'Activa';

  @override
  String get ofertasPausada => 'Pausada';

  @override
  String get ofertasCompleta => 'Completa';

  @override
  String ofertasConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n confirmados',
      one: '1 confirmado',
      zero: 'Sin confirmados',
    );
    return '$_temp0';
  }

  @override
  String ofertasPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pendientes',
      one: '1 pendiente',
    );
    return '$_temp0';
  }

  @override
  String ofertasOcupacion(int confirmados, int total) {
    return '$confirmados de $total lugares ocupados';
  }

  @override
  String get ofertasPausar => 'Pausar';

  @override
  String get ofertasReanudar => 'Reanudar';

  @override
  String get ofertasDuplicar => 'Duplicar';

  @override
  String get ofertasVerSolicitudes => 'Ver solicitudes';

  @override
  String get ofertasPausadaOk =>
      'Vacante pausada: no recibe nuevas solicitudes.';

  @override
  String get ofertasReanudadaOk => 'Vacante reanudada: ya recibe solicitudes.';

  @override
  String ofertasEliminarTitulo(Object nombre) {
    return '¿Eliminar «$nombre»?';
  }

  @override
  String get ofertasEliminarMensaje =>
      'Las familias ya no la van a ver. Esta acción no se puede deshacer.';

  @override
  String get ofertasEliminadaOk => 'Vacante eliminada.';

  @override
  String get ofertasFormEditar => 'Editar vacante';

  @override
  String get ofertasFormDuplicar => 'Duplicar vacante';

  @override
  String ofertasFormCopiaAviso(Object nombre) {
    return 'Estás creando una copia de «$nombre». Cambiá lo que necesites (por ejemplo, el grupo) y guardala.';
  }

  @override
  String ofertasFormConfirmadosAviso(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Esta vacante tiene $n alumnos confirmados. Las solicitudes ya enviadas conservan los datos originales.',
      one:
          'Esta vacante tiene 1 alumno confirmado. Las solicitudes ya enviadas conservan los datos originales.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasSeccionTipo => 'Tipo de vacante';

  @override
  String get ofertasTipoCurricularDesc => 'Grados, años y salas';

  @override
  String get ofertasTipoExtraDesc => 'Talleres, deportes y actividades';

  @override
  String get ofertasSeccionNivel => 'Nivel';

  @override
  String get ofertasSeccionCategoria => 'Categoría';

  @override
  String get ofertasElegiNivel => 'Elegí un nivel.';

  @override
  String get ofertasElegiCategoria => 'Elegí una categoría.';

  @override
  String get ofertasSeccionDatos => 'Datos de la vacante';

  @override
  String get ofertasTituloCurricularLabel => 'Grado, año o sala';

  @override
  String get ofertasTituloExtraLabel => 'Actividad';

  @override
  String get ofertasSugerenciasAyuda =>
      'Tocá una sugerencia o escribilo a tu manera.';

  @override
  String ofertasSugSala(int n) {
    return 'Sala de $n';
  }

  @override
  String ofertasSugGrado(int n) {
    return '$n° grado';
  }

  @override
  String ofertasSugAnio(int n) {
    return '$n° año';
  }

  @override
  String get ofertasEjemplosGeneral => 'Ej.: Fútbol, Inglés, Robótica';

  @override
  String get ofertasEjemplosDeporte => 'Ej.: Fútbol, Vóley, Natación';

  @override
  String get ofertasEjemplosArte => 'Ej.: Teatro, Coro, Pintura';

  @override
  String get ofertasEjemplosIdiomas =>
      'Ej.: Inglés inicial, Portugués, Oratoria';

  @override
  String get ofertasEjemplosCiencia =>
      'Ej.: Robótica, Programación, Club de ciencias';

  @override
  String get ofertasEjemplosApoyo => 'Ej.: Apoyo escolar, Técnicas de estudio';

  @override
  String get ofertasEjemplosBienestar =>
      'Ej.: Yoga, Taller de emociones, Orientación vocacional';

  @override
  String get ofertasEjemplosOtros => 'Ej.: Ajedrez, Cocina, Huerta';

  @override
  String get ofertasGrupoLabel => 'División o grupo (opcional)';

  @override
  String get ofertasGrupoHelper => 'Ej.: A, B, Grupo sábados';

  @override
  String get ofertasSeccionHorario => 'Turno y horario';

  @override
  String get ofertasTurnoLabel => 'Turno';

  @override
  String get ofertasHoraDesde => 'Desde';

  @override
  String get ofertasHoraHasta => 'Hasta';

  @override
  String ofertasHorarioRango(Object desde, Object hasta) {
    return '$desde a $hasta';
  }

  @override
  String get ofertasHorarioInvalido =>
      'La hora de fin tiene que ser posterior a la de inicio.';

  @override
  String get ofertasHorarioIncompleto =>
      'Completá las dos horas o dejá ambas vacías.';

  @override
  String ofertasHorarioActual(Object horario) {
    return 'Horario actual: $horario. Elegí las horas para reemplazarlo.';
  }

  @override
  String get ofertasQuitarHorario => 'Quitar horario';

  @override
  String get ofertasDiasLabel => 'Días';

  @override
  String get ofertasDiaLun => 'Lun';

  @override
  String get ofertasDiaMar => 'Mar';

  @override
  String get ofertasDiaMie => 'Mié';

  @override
  String get ofertasDiaJue => 'Jue';

  @override
  String get ofertasDiaVie => 'Vie';

  @override
  String get ofertasDiaSab => 'Sáb';

  @override
  String get ofertasDiaDom => 'Dom';

  @override
  String ofertasDiasRango(Object desde, Object hasta) {
    return '$desde a $hasta';
  }

  @override
  String ofertasDiasLista(Object lista, Object ultimo) {
    return '$lista y $ultimo';
  }

  @override
  String get ofertasDiasTodos => 'Todos los días';

  @override
  String ofertasDiasActual(Object dias) {
    return 'Días actuales: $dias. Elegilos para reemplazarlos.';
  }

  @override
  String get ofertasSeccionCupo => 'Cupo y requisitos';

  @override
  String get ofertasCupoLabel => 'Cupo total';

  @override
  String get ofertasCupoHelper => 'Cantidad de alumnos que pueden inscribirse.';

  @override
  String ofertasCupoConfirmadosHelper(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hay $n alumnos confirmados.',
      one: 'Hay 1 alumno confirmado.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasCupoMinimo => 'El cupo tiene que ser de al menos 1.';

  @override
  String ofertasCupoMenorConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ya hay $n alumnos confirmados: el cupo no puede ser menor.',
      one: 'Ya hay 1 alumno confirmado: el cupo no puede ser menor.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasRestarUno => 'Restar uno';

  @override
  String get ofertasSumarUno => 'Sumar uno';

  @override
  String get ofertasEdadMinLabel => 'Edad mínima';

  @override
  String get ofertasEdadMaxLabel => 'Edad máxima';

  @override
  String get ofertasAniosSufijo => 'años';

  @override
  String get ofertasEdadHelper =>
      'Opcional: dejalas vacías si no hay límite de edad.';

  @override
  String get ofertasEdadRangoInvalido =>
      'Tiene que ser igual o mayor que la edad mínima.';

  @override
  String get ofertasArancelLabel => 'Arancel (opcional)';

  @override
  String get ofertasArancelHelper =>
      'Ej.: \$ 15.000 por mes. Dejalo vacío si es gratuita.';

  @override
  String get ofertasDescripcionLabel => 'Descripción (opcional)';

  @override
  String get ofertasDescripcionHelper =>
      'Contales a las familias qué incluye, requisitos o materiales.';

  @override
  String get ofertasSeccionPublicacion => 'Publicación';

  @override
  String get ofertasActivaLabel => 'Recibe solicitudes';

  @override
  String get ofertasActivaOn => 'Activa: las familias pueden pedir vacante.';

  @override
  String get ofertasActivaOff =>
      'Pausada: las familias no pueden pedir vacante por ahora.';

  @override
  String get ofertasCrear => 'Crear vacante';

  @override
  String get ofertasCreadaOk => 'Vacante creada.';

  @override
  String get ofertasGuardadaOk => 'Cambios guardados.';

  @override
  String get ofertasDescartarTitulo => '¿Descartar los cambios?';

  @override
  String get ofertasDescartarMensaje =>
      'Los cambios que hiciste no se van a guardar.';

  @override
  String get ofertasDescartar => 'Descartar';

  @override
  String get ofertasRevisaCampos => 'Revisá los campos marcados.';

  @override
  String get crqNuevo => 'Nuevo croquis';

  @override
  String get crqErrorCarga => 'No pudimos cargar los croquis.';

  @override
  String get crqVacioTitulo => 'Todavía no armaste ningún croquis';

  @override
  String get crqVacioMensaje =>
      'Diseñá la distribución de bancos de cada aula y ubicá a tus alumnos. Después podés exportarla en PDF.';

  @override
  String crqFilasColumnas(int filas, int columnas) {
    return '$filas × $columnas bancos';
  }

  @override
  String crqOcupados(int ocupados, int total) {
    return '$ocupados de $total lugares ocupados';
  }

  @override
  String get crqSinVacante => 'Sin vacante asociada';

  @override
  String get crqVacanteAsociada => 'Vacante asociada';

  @override
  String get crqVacanteAsociadaHelper =>
      'Te vamos a sugerir sus alumnos confirmados al ubicar los bancos.';

  @override
  String get crqVacanteNoDisponible => 'La vacante asociada ya no existe';

  @override
  String get crqCambiarVacante => 'Cambiar vacante asociada';

  @override
  String get crqAsociarVacante => 'Asociar una vacante';

  @override
  String get crqVacanteActualizada => 'Vacante asociada actualizada.';

  @override
  String get crqNombreLabel => 'Nombre del croquis';

  @override
  String get crqNombreHelper => 'Ej.: 1° grado A, Aula 3, Laboratorio';

  @override
  String get crqFilas => 'Filas';

  @override
  String get crqColumnas => 'Columnas';

  @override
  String get crqQuitarUno => 'Quitar uno';

  @override
  String get crqAgregarUno => 'Agregar uno';

  @override
  String get crqCrear => 'Crear croquis';

  @override
  String get crqVistaPrevia => 'Vista previa';

  @override
  String get crqFrente => 'Frente del aula · Pizarrón';

  @override
  String crqBanco(int n) {
    return 'Banco $n';
  }

  @override
  String get crqBancoLibre => 'Libre';

  @override
  String get crqAyuda =>
      'Tocá un banco para ubicar a un alumno. Mantenelo presionado y arrastralo para cambiarlo de lugar.';

  @override
  String get crqAyudaScroll =>
      'Deslizá hacia los costados para ver toda el aula.';

  @override
  String crqOcupadoPor(Object nombre) {
    return 'Ocupado por $nombre';
  }

  @override
  String get crqBuscarAlumno => 'Buscar alumno';

  @override
  String crqAlumnosDeVacante(Object oferta) {
    return 'Alumnos confirmados en $oferta';
  }

  @override
  String get crqAlumnosInstitucion => 'Alumnos confirmados de la institución';

  @override
  String get crqTodosSentados =>
      'Todos los alumnos confirmados ya tienen banco.';

  @override
  String get crqSinConfirmados =>
      'Todavía no hay alumnos confirmados. Podés escribir un nombre.';

  @override
  String get crqSinResultados =>
      'No hay alumnos que coincidan con la búsqueda.';

  @override
  String get crqErrorAlumnos =>
      'No pudimos cargar los alumnos confirmados. Podés escribir un nombre.';

  @override
  String get crqNombreLibre => 'O escribí un nombre';

  @override
  String get crqNombreLibreLabel => 'Nombre y apellido';

  @override
  String get crqAsignar => 'Ubicar';

  @override
  String get crqDejarLibre => 'Dejar libre';

  @override
  String crqMovidoDesde(Object nombre, int desde, int hasta) {
    return '$nombre pasó del banco $desde al $hasta.';
  }

  @override
  String get crqGuardado => 'Guardado';

  @override
  String get crqSinGuardar => 'Sin guardar';

  @override
  String get crqErrorGuardar =>
      'No pudimos guardar el último cambio. Tocá «Sin guardar» para reintentar.';

  @override
  String get crqRenombrar => 'Renombrar';

  @override
  String get crqRenombrarTitulo => 'Renombrar croquis';

  @override
  String get crqTamanoCorto => 'Tamaño';

  @override
  String get crqTamanoTitulo => 'Tamaño del aula';

  @override
  String get crqTamanoAyuda =>
      'Las filas van del pizarrón hacia el fondo; las columnas, de izquierda a derecha.';

  @override
  String crqTamanoPierde(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alumnos quedarían fuera del aula y se quitarían del croquis.',
      one: '1 alumno quedaría fuera del aula y se quitaría del croquis.',
    );
    return '$_temp0';
  }

  @override
  String get crqTamanoConfirmarTitulo => '¿Achicar el aula?';

  @override
  String get crqAplicar => 'Aplicar';

  @override
  String get crqVaciar => 'Vaciar';

  @override
  String get crqVaciarTitulo => '¿Vaciar el croquis?';

  @override
  String crqVaciarMensaje(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Se van a liberar $n lugares ocupados. La distribución de bancos se mantiene.',
      one:
          'Se va a liberar 1 lugar ocupado. La distribución de bancos se mantiene.',
    );
    return '$_temp0';
  }

  @override
  String get crqVaciadoOk => 'Croquis vaciado.';

  @override
  String get crqYaVacio => 'El croquis ya está vacío.';

  @override
  String get crqPdfCorto => 'PDF';

  @override
  String get crqExportarPdf => 'Exportar PDF';

  @override
  String get crqPdfError =>
      'No pudimos generar el PDF. Probá de nuevo en un momento.';

  @override
  String crqPdfArchivo(Object nombre) {
    return 'croquis_$nombre';
  }

  @override
  String crqEliminarTitulo(Object nombre) {
    return '¿Eliminar «$nombre»?';
  }

  @override
  String get crqEliminarMensaje =>
      'Se va a borrar la distribución de bancos. Esta acción no se puede deshacer.';

  @override
  String get crqEliminadoOk => 'Croquis eliminado.';

  @override
  String get comInstTitle => 'Comunicaciones';

  @override
  String get comInstTabCalendario => 'Calendario';

  @override
  String get comInstTabAvisos => 'Avisos';

  @override
  String get comInstLoadError => 'No pudimos cargar las comunicaciones.';

  @override
  String get comInstProximos => 'Próximos';

  @override
  String get comInstPasados => 'Pasados';

  @override
  String get comInstNuevoEvento => 'Nuevo evento';

  @override
  String get comInstEditarEvento => 'Editar evento';

  @override
  String get comInstEliminarEvento => 'Eliminar evento';

  @override
  String get comInstTodoElDia => 'Todo el día';

  @override
  String comInstRangoFechas(Object desde, Object hasta) {
    return 'Del $desde al $hasta';
  }

  @override
  String get comInstParaTodos => 'Todos los alumnos';

  @override
  String get comInstEnCurso => 'En curso';

  @override
  String get comInstOfertaEliminada => 'Curso o grupo eliminado';

  @override
  String comInstYMas(Object nombres, int n) {
    return '$nombres y $n más';
  }

  @override
  String comInstAsistiran(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n asistirán',
      one: '1 asistirá',
    );
    return '$_temp0';
  }

  @override
  String comInstTalVez(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tal vez',
      one: '1 tal vez',
    );
    return '$_temp0';
  }

  @override
  String comInstNoAsistiran(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n no asistirán',
      one: '1 no asistirá',
    );
    return '$_temp0';
  }

  @override
  String get comInstSinRespuestas => 'Sin respuestas todavía';

  @override
  String get comInstSinProximosTitulo => 'No hay eventos próximos';

  @override
  String get comInstSinProximosMensaje =>
      'Publicá reuniones, actos, evaluaciones o vacaciones: aparecen en el calendario de cada familia y les llega un aviso.';

  @override
  String get comInstSinPasadosTitulo => 'Todavía no hay eventos pasados';

  @override
  String get comInstSinPasadosMensaje =>
      'Acá vas a ver los eventos que ya ocurrieron.';

  @override
  String get comInstSeccionTipo => 'Tipo de evento';

  @override
  String get comInstSeccionTipoAyuda =>
      'Ayuda a las familias a reconocerlo de un vistazo.';

  @override
  String get comInstSeccionDatos => 'Datos del evento';

  @override
  String get comInstCampoTitulo => 'Título';

  @override
  String get comInstCampoTituloAyuda =>
      'Ej.: Reunión de familias de 1.er grado';

  @override
  String get comInstCampoDescripcion => 'Descripción (opcional)';

  @override
  String get comInstCampoDescripcionAyuda =>
      'Lo que las familias necesitan saber: qué llevar, cómo llegar, horarios.';

  @override
  String get comInstCampoLugar => 'Lugar (opcional)';

  @override
  String get comInstSeccionCuando => 'Cuándo';

  @override
  String get comInstCampoFecha => 'Fecha';

  @override
  String get comInstCampoFechaFin => 'Fecha de fin (opcional)';

  @override
  String get comInstCampoFechaFinAyuda =>
      'Para eventos de varios días, como vacaciones.';

  @override
  String get comInstQuitarFechaFin => 'Quitar fecha de fin';

  @override
  String get comInstErrorFecha => 'Elegí la fecha.';

  @override
  String get comInstErrorFechaFin =>
      'Tiene que ser posterior a la fecha de inicio.';

  @override
  String get comInstTodoElDiaAyuda =>
      'Desactivalo para indicar la hora de inicio.';

  @override
  String get comInstCampoHora => 'Hora de inicio';

  @override
  String get comInstErrorHora => 'Elegí la hora de inicio.';

  @override
  String get comInstSeccionDestinatarios => 'Destinatarios';

  @override
  String get comInstSeccionDestinatariosAyuda =>
      'Lo reciben las familias de los alumnos confirmados.';

  @override
  String get comInstDestOfertas => 'Cursos o grupos';

  @override
  String get comInstDestElegirAyuda => 'Elegí uno o más cursos o grupos.';

  @override
  String get comInstDestErrorVacio => 'Elegí al menos un curso o grupo.';

  @override
  String get comInstDestSinOfertas =>
      'Cuando publiques vacantes vas a poder elegir cursos o grupos puntuales.';

  @override
  String comInstAlumnosConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alumnos confirmados',
      one: '1 alumno confirmado',
      zero: 'Sin alumnos confirmados',
    );
    return '$_temp0';
  }

  @override
  String get comInstPedirConfirmacion => 'Pedir confirmación de asistencia';

  @override
  String get comInstPedirConfirmacionAyuda =>
      'Las familias podrán responder si asisten y vas a ver las respuestas acá.';

  @override
  String comInstSeAvisaraA(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se avisará a $n alumnos',
      one: 'Se avisará a 1 alumno',
    );
    return '$_temp0';
  }

  @override
  String get comInstSeAvisaraAyuda =>
      'Les llega una notificación y el evento aparece en su calendario.';

  @override
  String get comInstCalculando => 'Calculando destinatarios…';

  @override
  String get comInstSinDestinatariosEvento =>
      'Todavía no hay alumnos confirmados en esta selección. Nadie recibirá el aviso ahora, pero el evento va a aparecer en el calendario de quienes se sumen.';

  @override
  String get comInstEditarSinAviso =>
      'Los cambios se guardan sin enviar una notificación nueva.';

  @override
  String get comInstPublicar => 'Publicar evento';

  @override
  String get comInstPublicando => 'Publicando…';

  @override
  String get comInstGuardarCambios => 'Guardar cambios';

  @override
  String comInstEventoPublicado(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Evento publicado. Les avisamos a $n alumnos.',
      one: 'Evento publicado. Le avisamos a 1 alumno.',
      zero: 'Evento publicado.',
    );
    return '$_temp0';
  }

  @override
  String get comInstEventoActualizado => 'Cambios guardados.';

  @override
  String get comInstEventoEliminado => 'Evento eliminado.';

  @override
  String get comInstEliminarEventoTitulo => '¿Eliminar este evento?';

  @override
  String get comInstEliminarEventoMensaje =>
      'Se quita del calendario de las familias junto con sus respuestas. No se puede deshacer.';

  @override
  String get comInstDescartarTitulo => '¿Descartar los cambios?';

  @override
  String get comInstDescartarMensaje =>
      'Lo que completaste no se va a guardar.';

  @override
  String get comInstDescartar => 'Descartar';

  @override
  String get comInstSeguirEditando => 'Seguir editando';

  @override
  String get comInstDetalleTitulo => 'Detalle del evento';

  @override
  String get comInstInfoFecha => 'Fecha';

  @override
  String get comInstInfoHorario => 'Horario';

  @override
  String get comInstInfoLugar => 'Lugar';

  @override
  String get comInstInfoAlcance => 'Alumnos alcanzados';

  @override
  String get comInstInfoDescripcion => 'Descripción';

  @override
  String comInstPublicadoEl(Object fecha) {
    return 'Publicado el $fecha';
  }

  @override
  String get comInstRespuestasTitulo => 'Confirmaciones de asistencia';

  @override
  String comInstRespuestasConteo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas',
      one: '1 respuesta',
      zero: 'Nadie respondió todavía',
    );
    return '$_temp0';
  }

  @override
  String get comInstStatAsistiran => 'Asistirán';

  @override
  String get comInstStatTalVez => 'Tal vez';

  @override
  String get comInstStatNoAsistiran => 'No asistirán';

  @override
  String get comInstStatSinResponder => 'Sin responder';

  @override
  String get comInstSinRespuestasDetalle =>
      'Todavía nadie respondió. Las respuestas aparecen acá a medida que las familias confirman.';

  @override
  String get comInstNoPideConfirmacion =>
      'Este evento no pide confirmación de asistencia. Podés activarla editándolo.';

  @override
  String get comInstNuevoAviso => 'Nuevo aviso';

  @override
  String get comInstNuevoAvisoAyuda =>
      'Llega como notificación a las familias de tus alumnos confirmados.';

  @override
  String get comInstAvisoCampoTituloAyuda => 'Ej.: Cambio de horario de salida';

  @override
  String get comInstAvisoCampoMensaje => 'Mensaje';

  @override
  String comInstLlegaraA(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Llegará a $n alumnos',
      one: 'Llegará a 1 alumno',
    );
    return '$_temp0';
  }

  @override
  String get comInstSinDestinatariosAviso =>
      'Todavía no hay alumnos confirmados en esta selección. Cuando confirmes solicitudes vas a poder enviarles avisos.';

  @override
  String get comInstEnviarAviso => 'Enviar aviso';

  @override
  String comInstConfirmarEnvio(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '¿Enviar a $n alumnos?',
      one: '¿Enviar a 1 alumno?',
    );
    return '$_temp0';
  }

  @override
  String get comInstConfirmarEnvioMensaje =>
      'Las familias lo reciben como notificación. Una vez enviado, no se puede editar ni borrar.';

  @override
  String comInstAvisoEnviado(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Aviso enviado a $n alumnos.',
      one: 'Aviso enviado a 1 alumno.',
    );
    return '$_temp0';
  }

  @override
  String get comInstAvisosVacioTitulo => 'Todavía no enviaste avisos';

  @override
  String get comInstAvisosVacioMensaje =>
      'Los avisos llegan como notificación a las familias de los alumnos confirmados. Usalos para recordatorios, cambios de horario o novedades.';

  @override
  String get comInstAvisosEnviados => 'Avisos enviados';

  @override
  String comInstAvisoAlcance(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Llegó a $n alumnos',
      one: 'Llegó a 1 alumno',
      zero: 'No llegó a ningún alumno',
    );
    return '$_temp0';
  }

  @override
  String comInstEnviadoEl(Object fecha) {
    return 'Enviado el $fecha';
  }

  @override
  String get docInstTitle => 'Documentación';

  @override
  String get docInstTabRevisar => 'Para revisar';

  @override
  String get docInstTabPendientes => 'Pendientes';

  @override
  String get docInstTabAprobados => 'Aprobados';

  @override
  String get docInstTabCancelados => 'Cancelados';

  @override
  String get docInstLoadError => 'No pudimos cargar la documentación.';

  @override
  String get docInstPedirDocumento => 'Pedir documento';

  @override
  String docInstPedidoEl(Object fecha) {
    return 'Pedido el $fecha';
  }

  @override
  String docInstLimite(Object fecha) {
    return 'Límite: $fecha';
  }

  @override
  String docInstEntregadoEl(Object fecha) {
    return 'Entregado el $fecha';
  }

  @override
  String get docInstVacioRevisarTitulo => 'No hay documentos para revisar';

  @override
  String get docInstVacioRevisarMensaje =>
      'Cuando una familia suba un documento que pediste, lo vas a ver acá.';

  @override
  String get docInstVacioPendientesTitulo => 'No hay pedidos pendientes';

  @override
  String get docInstVacioPendientesMensaje =>
      'Pedí DNI, partida de nacimiento, certificados y más. A la familia le llega un aviso y lo sube desde la app.';

  @override
  String get docInstVacioAprobadosTitulo => 'Todavía no aprobaste documentos';

  @override
  String get docInstVacioAprobadosMensaje =>
      'Los documentos que apruebes quedan guardados acá.';

  @override
  String get docInstVacioCanceladosTitulo => 'No hay pedidos cancelados';

  @override
  String get docInstVacioCanceladosMensaje =>
      'Si cancelás un pedido que ya no necesitás, aparece acá.';

  @override
  String get docInstPedirTitulo => 'Pedir un documento';

  @override
  String get docInstPedirAyuda =>
      'Le avisamos a la familia y lo sube desde la app.';

  @override
  String get docInstElegirAlumno => '¿A qué alumno?';

  @override
  String get docInstBuscarAlumno => 'Buscar por nombre o DNI';

  @override
  String get docInstLimpiarBusqueda => 'Limpiar búsqueda';

  @override
  String get docInstSinResultados => 'No encontramos alumnos con esa búsqueda.';

  @override
  String get docInstSinAlumnosTitulo => 'Todavía no tenés alumnos';

  @override
  String get docInstSinAlumnosMensaje =>
      'Podés pedir documentos a los alumnos con solicitudes pendientes o confirmadas. Cuando recibas la primera solicitud, vas a poder hacerlo desde acá.';

  @override
  String get docInstSolicitudPendiente => 'Solicitud pendiente';

  @override
  String get docInstCambiarAlumno => 'Cambiar';

  @override
  String get docInstQueDocumento => '¿Qué documento necesitás?';

  @override
  String get docInstIndicacionesLabel => 'Indicaciones (opcional)';

  @override
  String get docInstIndicacionesAyuda => 'Ej.: Fotocopia de ambos lados';

  @override
  String get docInstNombreOtroLabel => 'Nombre del documento';

  @override
  String get docInstNombreOtroAyuda =>
      'Ej.: Autorización para salidas educativas';

  @override
  String get docInstFechaLimiteLabel => 'Fecha límite (opcional)';

  @override
  String get docInstQuitarFechaLimite => 'Quitar fecha límite';

  @override
  String docInstPedidoEnviado(Object documento, Object alumno) {
    return 'Pedido enviado: $documento · $alumno';
  }

  @override
  String get docInstDetalleTitulo => 'Pedido de documento';

  @override
  String get docInstAlumno => 'Alumno';

  @override
  String get docInstFechaPedido => 'Fecha del pedido';

  @override
  String get docInstFechaLimite => 'Fecha límite';

  @override
  String get docInstSinFechaLimite => 'Sin fecha límite';

  @override
  String get docInstIndicaciones => 'Indicaciones';

  @override
  String get docInstEsperandoArchivo =>
      'Esperando que la familia suba el archivo.';

  @override
  String get docInstRevisarAyuda =>
      'Revisá el archivo y aprobalo o pedí una corrección.';

  @override
  String get docInstMotivoCorreccion => 'Pediste una corrección';

  @override
  String docInstAprobadoInfo(Object fecha) {
    return 'Aprobado el $fecha.';
  }

  @override
  String docInstCanceladoInfo(Object fecha) {
    return 'Cancelaste este pedido el $fecha.';
  }

  @override
  String get docInstArchivoEntregado => 'Archivo entregado';

  @override
  String get docInstArchivoAnterior => 'Último archivo entregado';

  @override
  String docInstSubidoEl(Object fecha) {
    return 'Subido el $fecha';
  }

  @override
  String get docInstTipoPdf => 'Documento PDF';

  @override
  String get docInstTipoImagen => 'Imagen';

  @override
  String get docInstTipoArchivo => 'Archivo';

  @override
  String docInstTamanoKb(Object n) {
    return '$n KB';
  }

  @override
  String docInstTamanoMb(Object n) {
    return '$n MB';
  }

  @override
  String get docInstVerArchivo => 'Ver archivo';

  @override
  String get docInstDescargar => 'Descargar';

  @override
  String get docInstArchivoError =>
      'No pudimos abrir el archivo. Probá de nuevo en un rato.';

  @override
  String get docInstSinVistaPrevia =>
      'No hay vista previa para este formato. Descargalo para verlo.';

  @override
  String get docInstAprobar => 'Aprobar';

  @override
  String get docInstPedirCorreccion => 'Pedir corrección';

  @override
  String get docInstAprobarTitulo => '¿Aprobar el documento?';

  @override
  String docInstAprobarMensaje(Object alumno) {
    return 'Le avisaremos a la familia de $alumno.';
  }

  @override
  String get docInstAprobado => 'Documento aprobado.';

  @override
  String get docInstCorreccionAyuda =>
      'Contale a la familia qué tiene que corregir. Va a poder subir un archivo nuevo.';

  @override
  String get docInstMotivoLabel => 'Motivo';

  @override
  String get docInstMotivoAyuda =>
      'Ej.: La foto está borrosa y no se lee el número.';

  @override
  String get docInstMotivoRequerido => 'Contanos qué hay que corregir.';

  @override
  String get docInstCorreccionEnviada =>
      'Le pedimos la corrección a la familia.';

  @override
  String get docInstCancelarPedido => 'Cancelar pedido';

  @override
  String get docInstCancelarTitulo => '¿Cancelar este pedido?';

  @override
  String get docInstCancelarMensaje =>
      'La familia ya no va a tener que entregarlo. No se puede deshacer.';

  @override
  String get docInstMantener => 'Mantener';

  @override
  String get docInstPedidoCancelado => 'Pedido cancelado.';

  @override
  String pdfGeneradoCon(String fecha) {
    return 'Generado con ATENA · $fecha';
  }

  @override
  String pdfPagina(int actual, int total) {
    return 'Página $actual de $total';
  }

  @override
  String get pdfNombre => 'Nombre';

  @override
  String get pdfApellido => 'Apellido';

  @override
  String get pdfApellidoNombre => 'Apellido y nombre';

  @override
  String get pdfDni => 'DNI';

  @override
  String pdfDniValor(String dni) {
    return 'DNI $dni';
  }

  @override
  String get pdfFechaNacimiento => 'Fecha de nacimiento';

  @override
  String get pdfEdad => 'Edad';

  @override
  String get pdfEmail => 'Email';

  @override
  String get pdfTelefono => 'Teléfono';

  @override
  String get pdfContacto => 'Contacto';

  @override
  String get pdfInstitucion => 'Institución';

  @override
  String get pdfOferta => 'Oferta';

  @override
  String get pdfCategoria => 'Categoría';

  @override
  String get pdfTurno => 'Turno';

  @override
  String get pdfHorario => 'Horario';

  @override
  String get pdfDias => 'Días';

  @override
  String get pdfEdades => 'Edades';

  @override
  String get pdfEstado => 'Estado';

  @override
  String get pdfFecha => 'Fecha';

  @override
  String get pdfNota => 'Nota';

  @override
  String get pdfFichaTitulo => 'Ficha del alumno';

  @override
  String get pdfDatosPersonales => 'Datos personales';

  @override
  String get pdfSolicitudes => 'Solicitudes';

  @override
  String pdfSolicitudesCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n solicitudes',
      one: '1 solicitud',
      zero: 'Sin solicitudes',
    );
    return '$_temp0';
  }

  @override
  String get pdfSinSolicitudes => 'Todavía no hay solicitudes registradas.';

  @override
  String get pdfComprobanteTitulo => 'Comprobante de solicitud';

  @override
  String get pdfCodigo => 'Código';

  @override
  String get pdfEnviadaEl => 'Enviada el';

  @override
  String get pdfEmitidoEl => 'Emitido el';

  @override
  String get pdfEstadoActual => 'Estado actual';

  @override
  String get pdfVacanteSolicitada => 'Vacante solicitada';

  @override
  String get pdfAlumno => 'Alumno';

  @override
  String get pdfMensajeAlumno => 'Mensaje del alumno';

  @override
  String get pdfRespuestaInstitucion => 'Respuesta de la institución';

  @override
  String get pdfHistorial => 'Historial';

  @override
  String get pdfComprobanteAclaracion =>
      'Este comprobante refleja el estado de la solicitud al momento de su emisión.';

  @override
  String get pdfEstadoDescPendiente =>
      'La institución todavía no respondió esta solicitud.';

  @override
  String get pdfEstadoDescConfirmada => 'La institución confirmó la vacante.';

  @override
  String get pdfEstadoDescRechazada => 'La institución no aceptó la solicitud.';

  @override
  String get pdfEstadoDescCanceladaAlumno =>
      'La solicitud fue cancelada por el alumno o la familia.';

  @override
  String get pdfEstadoDescCanceladaInstitucion =>
      'La institución dio de baja la vacante.';

  @override
  String get pdfListadoTitulo => 'Alumnos confirmados';

  @override
  String get pdfTotal => 'Total';

  @override
  String pdfAlumnosCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alumnos',
      one: '1 alumno',
      zero: 'Sin alumnos',
    );
    return '$_temp0';
  }

  @override
  String get pdfListadoVacio => 'No hay alumnos confirmados para mostrar.';

  @override
  String get pdfCroquisTitulo => 'Croquis del aula';

  @override
  String get pdfFrenteAula => 'Frente del aula';

  @override
  String get pdfLugares => 'Lugares';

  @override
  String get pdfOcupados => 'Ocupados';

  @override
  String get pdfLibres => 'Libres';

  @override
  String get pdfLugarOcupado => 'Ocupado';

  @override
  String get pdfLugarLibre => 'Libre';

  @override
  String get solInstTabPendientes => 'Pendientes';

  @override
  String get solInstTabConfirmadas => 'Confirmadas';

  @override
  String get solInstTabNoAceptadas => 'No aceptadas';

  @override
  String get solInstTabCanceladas => 'Canceladas';

  @override
  String get solInstBuscarHint => 'Buscar por nombre o DNI';

  @override
  String get solInstLimpiarBusqueda => 'Limpiar búsqueda';

  @override
  String get solInstFiltrarVacante => 'Filtrar por vacante';

  @override
  String get solInstVacanteFiltro => 'Vacante';

  @override
  String get solInstTodasLasVacantes => 'Todas las vacantes';

  @override
  String get solInstQuitarFiltro => 'Quitar filtro';

  @override
  String get solInstOrdenLlegada =>
      'Por orden de llegada: las más antiguas primero.';

  @override
  String solInstDni(Object dni) {
    return 'DNI $dni';
  }

  @override
  String get solInstConMensaje => 'La familia dejó un mensaje';

  @override
  String get solInstConfirmar => 'Confirmar';

  @override
  String get solInstNoAceptar => 'No aceptar';

  @override
  String get solInstConfirmarVacante => 'Confirmar vacante';

  @override
  String get solInstDarDeBaja => 'Dar de baja';

  @override
  String get solInstPedirDocumento => 'Pedir documento';

  @override
  String get solInstDescargarComprobante => 'Descargar comprobante';

  @override
  String get solInstPdfError =>
      'No pudimos generar el PDF. Probá de nuevo en unos minutos.';

  @override
  String get solInstArchivoComprobante => 'comprobante';

  @override
  String get solInstVacioInicialTitulo => 'Todavía no recibiste solicitudes';

  @override
  String get solInstVacioInicialMsg =>
      'Las familias te envían solicitudes desde tu ficha pública en ATENA. Publicá tus vacantes y completá tu perfil público para que te encuentren más fácil.';

  @override
  String get solInstIrAVacantes => 'Ir a Vacantes';

  @override
  String get solInstVacioPendientesTitulo => 'No hay solicitudes pendientes';

  @override
  String get solInstVacioPendientesMsg =>
      '¡Todo al día! Las nuevas solicitudes van a aparecer acá para que las revises.';

  @override
  String get solInstVacioConfirmadasTitulo => 'Todavía no confirmaste vacantes';

  @override
  String get solInstVacioConfirmadasMsg =>
      'Cuando confirmes una solicitud, la vas a ver acá y el alumno va a aparecer en Alumnos.';

  @override
  String get solInstVacioNoAceptadasTitulo => 'No hay solicitudes no aceptadas';

  @override
  String get solInstVacioNoAceptadasMsg =>
      'Acá vas a ver las solicitudes que no aceptaste, con el motivo que le diste a la familia.';

  @override
  String get solInstVacioCanceladasTitulo => 'No hay solicitudes canceladas';

  @override
  String get solInstVacioCanceladasMsg =>
      'Acá aparecen las solicitudes que cancelaron las familias y las bajas que diste.';

  @override
  String get solInstSinResultadosTitulo => 'Sin resultados';

  @override
  String get solInstSinResultadosMsg =>
      'No encontramos solicitudes con esos filtros.';

  @override
  String get solInstLimpiarFiltros => 'Limpiar filtros';

  @override
  String solInstRecibidaEl(Object fecha, Object hora) {
    return 'Recibida el $fecha a las $hora';
  }

  @override
  String solInstConfirmadaEl(Object fecha, Object hora) {
    return 'Confirmada el $fecha a las $hora';
  }

  @override
  String solInstRechazadaEl(Object fecha, Object hora) {
    return 'No aceptada el $fecha a las $hora';
  }

  @override
  String solInstCanceladaEl(Object fecha, Object hora) {
    return 'Cancelada por la familia el $fecha a las $hora';
  }

  @override
  String solInstBajaEl(Object fecha, Object hora) {
    return 'Dada de baja el $fecha a las $hora';
  }

  @override
  String get solInstSecContacto => 'Contacto';

  @override
  String get solInstSecVacante => 'Vacante solicitada';

  @override
  String get solInstSecMensaje => 'Mensaje de la familia';

  @override
  String get solInstSecHistorial => 'Historial';

  @override
  String get solInstSinContacto => 'La familia no dejó email ni teléfono.';

  @override
  String get solInstLlamar => 'Llamar';

  @override
  String get solInstWhatsapp => 'WhatsApp';

  @override
  String get solInstEscribirEmail => 'Enviar email';

  @override
  String get solInstCopiar => 'Copiar';

  @override
  String get solInstCopiado => 'Copiado al portapapeles.';

  @override
  String get solInstNoSePudoAbrir =>
      'No pudimos abrir esa aplicación en este dispositivo. Podés copiar el dato y usarlo desde otro.';

  @override
  String get solInstOcupacion => 'Ocupación';

  @override
  String solInstPendientesOferta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n solicitudes pendientes en esta vacante',
      one: '1 solicitud pendiente en esta vacante',
    );
    return '$_temp0';
  }

  @override
  String get solInstVacanteNoDisponible => 'Esta vacante ya no está publicada.';

  @override
  String get solInstVacantePausada => 'Pausada';

  @override
  String get solInstVacanteCompleta => 'Completa';

  @override
  String get solInstSinCupoAviso =>
      'No quedan lugares libres en esta vacante. Para confirmar, ampliá el cupo en Vacantes.';

  @override
  String solInstEdadFueraDeRango(Object edad, Object rango) {
    return 'La edad del alumno ($edad) está fuera del rango de la vacante ($rango).';
  }

  @override
  String get solInstHistRecibida => 'Solicitud recibida';

  @override
  String get solInstHistConfirmada => 'Vacante confirmada';

  @override
  String get solInstHistRechazada => 'Solicitud no aceptada';

  @override
  String get solInstHistCanceladaFamilia => 'Cancelada por la familia';

  @override
  String get solInstHistBaja => 'Baja de la vacante';

  @override
  String solInstOkConfirmada(Object alumno) {
    return 'Confirmaste la vacante de $alumno. Le avisamos a la familia.';
  }

  @override
  String solInstOkRechazada(Object alumno) {
    return 'La solicitud de $alumno no fue aceptada. Le avisamos a la familia.';
  }

  @override
  String solInstOkBaja(Object alumno) {
    return 'Diste de baja a $alumno. Le avisamos a la familia.';
  }

  @override
  String solInstOkDocumento(Object documento) {
    return 'Pedido enviado: $documento. Le avisamos a la familia.';
  }

  @override
  String get solInstConfirmarTitulo => '¿Confirmar la vacante?';

  @override
  String solInstConfirmarMsg(Object alumno, Object oferta) {
    return 'Vas a confirmar a $alumno en $oferta. Le avisamos a la familia al instante.';
  }

  @override
  String get solInstNotaFamiliaLabel => 'Mensaje para la familia (opcional)';

  @override
  String get solInstNotaConfirmarHelper =>
      'Por ejemplo: fecha de la entrevista o qué traer el primer día.';

  @override
  String get solInstRechazarTitulo => '¿No aceptar la solicitud?';

  @override
  String solInstRechazarMsg(Object alumno) {
    return 'Contale a la familia de $alumno por qué no podés aceptar la solicitud. Va a recibir este mensaje.';
  }

  @override
  String get solInstMotivosFrecuentes => 'Motivos frecuentes';

  @override
  String get solInstMotivoSinVacantes => 'Sin vacantes';

  @override
  String get solInstMotivoSinVacantesTexto =>
      'No quedan vacantes disponibles en esta oferta.';

  @override
  String get solInstMotivoEdad => 'Edad fuera de rango';

  @override
  String get solInstMotivoEdadTexto =>
      'La edad del alumno no corresponde al rango de esta oferta.';

  @override
  String get solInstMotivoDocumentacion => 'Documentación incompleta';

  @override
  String get solInstMotivoDocumentacionTexto =>
      'La documentación presentada está incompleta.';

  @override
  String get solInstMotivoOtro => 'Otro';

  @override
  String get solInstMotivoLabel => 'Motivo para la familia';

  @override
  String get solInstMotivoRequerido => 'Escribí el motivo para la familia.';

  @override
  String solInstBajaTitulo(Object alumno) {
    return '¿Dar de baja a $alumno?';
  }

  @override
  String solInstBajaMsg(Object oferta) {
    return 'Se libera su lugar en $oferta y le avisamos a la familia. Esta acción no se puede deshacer.';
  }

  @override
  String get solInstNotaBajaHelper => 'Por ejemplo: el motivo de la baja.';

  @override
  String get solInstSinCupoTitulo => 'No quedan vacantes';

  @override
  String solInstSinCupoMsg(Object oferta) {
    return '$oferta ya tiene todos sus lugares ocupados. Para confirmar esta solicitud, ampliá el cupo en Vacantes.';
  }

  @override
  String solInstDocPara(Object alumno) {
    return 'Para $alumno';
  }

  @override
  String get solInstDocAyuda =>
      'La familia recibe el aviso al instante y puede subir el archivo desde la app.';

  @override
  String get solInstDocTipoLabel => '¿Qué documento necesitás?';

  @override
  String get solInstDocTipoRequerido => 'Elegí un documento.';

  @override
  String get solInstDocNombreLabel => 'Nombre del documento';

  @override
  String get solInstDocNombreRequerido => 'Indicá qué documento necesitás.';

  @override
  String get solInstDocDetalleLabel => 'Indicaciones (opcional)';

  @override
  String get solInstDocDetalleHelper =>
      'Por ejemplo: fotocopia de ambos lados.';

  @override
  String get solInstDocFechaLimite => 'Fecha límite (opcional)';

  @override
  String get solInstDocQuitarFecha => 'Quitar fecha';

  @override
  String get solInstDocEnviar => 'Enviar pedido';

  @override
  String alumInstSubtitulo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alumnos confirmados',
      one: '1 alumno confirmado',
      zero: 'Sin alumnos confirmados',
    );
    return '$_temp0';
  }

  @override
  String get alumInstExportarPdf => 'Exportar listado (PDF)';

  @override
  String alumInstExportarSeccion(Object oferta) {
    return 'Exportar listado de $oferta (PDF)';
  }

  @override
  String alumInstCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alumnos',
      one: '1 alumno',
    );
    return '$_temp0';
  }

  @override
  String get alumInstVacioTitulo => 'Todavía no hay alumnos confirmados';

  @override
  String get alumInstVacioMsg =>
      'Acá aparecen los alumnos a medida que confirmás sus solicitudes, agrupados por vacante.';

  @override
  String alumInstRevisarSolicitudes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Revisar $n solicitudes pendientes',
      one: 'Revisar 1 solicitud pendiente',
    );
    return '$_temp0';
  }

  @override
  String get alumInstSinResultadosMsg =>
      'No encontramos alumnos con ese nombre o DNI.';

  @override
  String get alumInstArchivoListado => 'alumnos';

  @override
  String get notiCuentaEliminadaTitle => 'Una familia eliminó su cuenta';

  @override
  String notiCuentaEliminadaBody(Object alumno, Object oferta) {
    return '$alumno ya no figura en $oferta: su familia eliminó la cuenta y el lugar quedó libre.';
  }

  @override
  String notiInstitucionEliminadaTitle(Object institucion) {
    return '$institucion dejó ATENA';
  }

  @override
  String notiInstitucionEliminadaBody(Object alumno, Object oferta) {
    return 'La solicitud de $alumno para $oferta quedó sin efecto porque la institución eliminó su cuenta.';
  }

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountFamilyBody =>
      'Se borrarán la cuenta, los alumnos y sus solicitudes, documentos, notas y notificaciones. Las instituciones serán avisadas y se liberarán los lugares confirmados.';

  @override
  String get deleteAccountInstitutionBody =>
      'Se borrarán la institución, sus vacantes, eventos, avisos, croquis, pedidos de documentos y el perfil público. Las familias con solicitudes activas serán avisadas.';

  @override
  String get deleteAccountIrreversible => 'Esta acción no se puede deshacer.';

  @override
  String get deleteAccountPasswordHelper =>
      'Ingresá tu contraseña para confirmar.';

  @override
  String get deleteAccountConfirm => 'Eliminar definitivamente';

  @override
  String get deleteAccountDone => 'La cuenta fue eliminada.';

  @override
  String get deleteAccountWrongPassword => 'La contraseña no es correcta.';

  @override
  String get perfInstTitulo => 'Perfil de la institución';

  @override
  String get perfInstTabDatos => 'Datos';

  @override
  String get perfInstTabPublico => 'Perfil público';

  @override
  String get perfInstTabVista => 'Vista previa';

  @override
  String get perfInstErrorCarga =>
      'No pudimos cargar el perfil de la institución.';

  @override
  String get perfInstSecIdentidad => 'Identificación';

  @override
  String get perfInstSecIdentidadAyuda =>
      'Así aparece tu institución en ATENA y en el buscador de las familias.';

  @override
  String get perfInstNombre => 'Nombre de la institución';

  @override
  String get perfInstNombreCorto =>
      'El nombre debe tener al menos 3 caracteres.';

  @override
  String get perfInstCuit => 'CUIT';

  @override
  String get perfInstCuitAyuda =>
      '11 dígitos, sin guiones. Lo usamos para verificar tu identidad si olvidás la contraseña.';

  @override
  String get perfInstTipo => 'Tipo de institución';

  @override
  String get perfInstModalidad => 'Modalidad';

  @override
  String get perfInstSecUbicacion => 'Ubicación';

  @override
  String get perfInstDireccion => 'Dirección';

  @override
  String get perfInstCiudad => 'Ciudad';

  @override
  String get perfInstProvincia => 'Provincia';

  @override
  String get perfInstPais => 'País';

  @override
  String get perfInstSecAdmin => 'Contacto administrativo';

  @override
  String get perfInstSecAdminAyuda =>
      'Lo usamos para comunicarnos con tu institución. No cambia el email con el que ingresás; los datos para las familias se cargan en Perfil público.';

  @override
  String get perfInstEmailAdmin => 'Email de contacto';

  @override
  String get perfInstTelefonoInvalido =>
      'Revisá el número: debe tener entre 8 y 15 dígitos.';

  @override
  String perfInstCompleto(int pct) {
    return 'Tu perfil está completo al $pct%';
  }

  @override
  String get perfInstCompletoListo => '¡Tu perfil está completo!';

  @override
  String get perfInstCompletoAyuda =>
      'Un perfil completo ayuda a las familias a conocerte y elegirte.';

  @override
  String get perfInstCompletoListoAyuda =>
      'Las familias ya pueden conocer todo lo que ofrecés.';

  @override
  String perfInstPorcentaje(int pct) {
    return '$pct%';
  }

  @override
  String get perfInstConsejoLogo => 'Subí el logo de tu institución.';

  @override
  String perfInstConsejoDescripcion(int min) {
    return 'Escribí una descripción de al menos $min caracteres.';
  }

  @override
  String perfInstConsejoFotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sumá $n fotos más de tus espacios.',
      one: 'Sumá 1 foto más de tus espacios.',
    );
    return '$_temp0';
  }

  @override
  String get perfInstConsejoAtencion => 'Indicá tu horario de atención.';

  @override
  String get perfInstConsejoClases =>
      'Contá en qué horario se dictan las clases.';

  @override
  String get perfInstConsejoTelefono =>
      'Agregá un teléfono o WhatsApp para que las familias te contacten.';

  @override
  String get perfInstConsejoEmailWeb => 'Sumá un email o tu sitio web.';

  @override
  String get perfInstConsejoRedes => 'Vinculá al menos una red social.';

  @override
  String get perfInstConsejoServicios => 'Contá qué servicios ofrecés.';

  @override
  String get perfInstSecImagenes => 'Logo y fotos';

  @override
  String get perfInstLogo => 'Logo';

  @override
  String get perfInstLogoAyuda =>
      'Imagen cuadrada en JPG o PNG, de hasta 1,5 MB. Se ve en el buscador y en tu ficha.';

  @override
  String get perfInstLogoSubir => 'Subir logo';

  @override
  String get perfInstLogoCambiar => 'Cambiar logo';

  @override
  String get perfInstLogoQuitar => 'Quitar logo';

  @override
  String get perfInstLogoQuitarTitulo => '¿Quitar el logo?';

  @override
  String get perfInstLogoQuitarMensaje =>
      'Las familias van a ver las iniciales de tu institución en su lugar.';

  @override
  String get perfInstLogoListo => 'Logo actualizado.';

  @override
  String get perfInstLogoQuitado => 'Quitamos el logo.';

  @override
  String get perfInstFotos => 'Fotos';

  @override
  String perfInstFotosCantidad(int n, int max) {
    return '$n de $max';
  }

  @override
  String perfInstFotosAyuda(int max) {
    return 'Mostrá tus espacios: aulas, patio, laboratorio, actividades. Hasta $max fotos de 1,5 MB.';
  }

  @override
  String get perfInstFotoAgregar => 'Agregar foto';

  @override
  String get perfInstFotoQuitar => 'Quitar foto';

  @override
  String get perfInstFotoQuitarTitulo => '¿Quitar esta foto?';

  @override
  String get perfInstFotoQuitarMensaje =>
      'La foto se va a eliminar de tu perfil público.';

  @override
  String get perfInstFotoAgregada => 'Foto agregada.';

  @override
  String get perfInstFotoQuitada => 'Foto eliminada.';

  @override
  String perfInstFotoVer(int n) {
    return 'Ver foto $n';
  }

  @override
  String get perfInstFotoNoDisponible => 'Foto no disponible';

  @override
  String get perfInstGaleriaError =>
      'No pudimos abrir tus imágenes. Revisá los permisos e intentá de nuevo.';

  @override
  String get perfInstSecSobre => 'Sobre la institución';

  @override
  String get perfInstDescripcion => 'Descripción';

  @override
  String get perfInstDescripcionHint =>
      'Contá tu propuesta educativa, tus valores y lo que hace única a tu institución.';

  @override
  String get perfInstSecHorarios => 'Horarios';

  @override
  String get perfInstHorarioAtencion => 'Horario de atención';

  @override
  String get perfInstHorarioAtencionHint => 'Ej.: lunes a viernes de 8 a 16 h';

  @override
  String get perfInstHorarioClases => 'Horario de clases';

  @override
  String get perfInstHorarioClasesHint => 'Ej.: turno mañana de 7:30 a 12:30';

  @override
  String get perfInstSecContacto => 'Contacto para familias';

  @override
  String get perfInstSecContactoAyuda =>
      'Lo ven las familias en tu ficha. Completá al menos un medio de contacto.';

  @override
  String get perfInstWhatsapp => 'WhatsApp';

  @override
  String get perfInstWhatsappAyuda => 'Incluí el código de área.';

  @override
  String get perfInstEmailFamilias => 'Email para familias';

  @override
  String get perfInstWeb => 'Sitio web';

  @override
  String get perfInstWebHint => 'tuescuela.edu.ar';

  @override
  String get perfInstWebInvalida => 'Ingresá una dirección web válida.';

  @override
  String get perfInstSecRedes => 'Redes sociales';

  @override
  String get perfInstSecRedesAyuda =>
      'Escribí tu @usuario o pegá el enlace de tu página.';

  @override
  String get perfInstInstagram => 'Instagram';

  @override
  String get perfInstFacebook => 'Facebook';

  @override
  String get perfInstYoutube => 'YouTube';

  @override
  String get perfInstRedInvalida => 'Ingresá un @usuario o un enlace válido.';

  @override
  String get perfInstSecServicios => 'Servicios';

  @override
  String get perfInstSecServiciosAyuda =>
      'Contá qué ofrecés además de las clases.';

  @override
  String get perfInstServicioAgregar => 'Agregar servicio';

  @override
  String get perfInstServicioHint => 'Ej.: huerta escolar';

  @override
  String perfInstServicioQuitar(Object servicio) {
    return 'Quitar $servicio';
  }

  @override
  String get perfInstServiciosSugeridos => 'Sugerencias';

  @override
  String perfInstServiciosMax(int max) {
    return 'Podés cargar hasta $max servicios.';
  }

  @override
  String get perfInstServicioRepetido => 'Ese servicio ya está en la lista.';

  @override
  String get perfInstSrvComedor => 'Comedor';

  @override
  String get perfInstSrvTransporte => 'Transporte escolar';

  @override
  String get perfInstSrvGabinete => 'Gabinete psicopedagógico';

  @override
  String get perfInstSrvJornadaExtendida => 'Jornada extendida';

  @override
  String get perfInstSrvBilingue => 'Educación bilingüe';

  @override
  String get perfInstSrvDeportes => 'Deportes';

  @override
  String get perfInstSrvBecas => 'Becas';

  @override
  String get perfInstSrvLaboratorio => 'Laboratorio';

  @override
  String get perfInstSrvBiblioteca => 'Biblioteca';

  @override
  String get perfInstSrvAccesibilidad => 'Accesibilidad';

  @override
  String get perfInstCambiosPendientes => 'Tenés cambios sin guardar';

  @override
  String get perfInstDescartar => 'Descartar';

  @override
  String get perfInstDescartarTitulo => '¿Descartar los cambios?';

  @override
  String get perfInstDescartarMensaje =>
      'Vas a perder lo que modificaste desde la última vez que guardaste.';

  @override
  String get perfInstGuardado => 'Cambios guardados.';

  @override
  String get perfInstRevisarCampos => 'Revisá los campos marcados.';

  @override
  String get perfInstSalirTitulo => '¿Salir sin guardar?';

  @override
  String get perfInstSalirMensaje =>
      'Tenés cambios sin guardar. Si salís ahora, se van a perder.';

  @override
  String get perfInstSalir => 'Salir sin guardar';

  @override
  String get perfInstVistaTitulo => 'Así te ven las familias';

  @override
  String get perfInstVistaAyuda =>
      'Es la ficha que aparece cuando te encuentran en ATENA.';

  @override
  String get perfInstVistaSinGuardar =>
      'Incluye cambios que todavía no guardaste.';

  @override
  String get perfInstVistaCompletar => 'Completar perfil';

  @override
  String get perfInstVistaSinDescripcion => 'Todavía no hay una descripción.';

  @override
  String get perfInstVistaContacto => 'Contacto';

  @override
  String get perfInstVistaSinContacto => 'Todavía no hay datos de contacto.';

  @override
  String get perfInstSinNombre => 'Tu institución';

  @override
  String get plnTitulo => 'Elegí tu plan';

  @override
  String get plnHeroTitulo => 'Armá tu plan a medida';

  @override
  String get plnHeroAyuda =>
      'Pagás solo por los niveles y módulos que usás, y podés cambiarlos cuando quieras.';

  @override
  String plnPrueba(int dias) {
    return '$dias días de prueba gratis';
  }

  @override
  String get plnSinPagos => 'Sin pagos por ahora';

  @override
  String get plnFlexible => 'Cambialo cuando quieras';

  @override
  String get plnNiveles => 'Niveles curriculares';

  @override
  String plnNivelesAyuda(Object precio) {
    return 'Salas, grados y años de tu propuesta oficial · $precio por nivel al mes';
  }

  @override
  String get plnModulos => 'Módulos extracurriculares';

  @override
  String plnModulosAyuda(Object precio) {
    return 'Talleres y actividades fuera del horario escolar · $precio por módulo al mes';
  }

  @override
  String plnPorMes(Object precio) {
    return '$precio / mes';
  }

  @override
  String plnUsd(int monto) {
    final intl.NumberFormat montoNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String montoString = montoNumberFormat.format(monto);

    return 'USD $montoString';
  }

  @override
  String plnUsdDecimal(double monto) {
    final intl.NumberFormat montoNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String montoString = montoNumberFormat.format(monto);

    return 'USD $montoString';
  }

  @override
  String get plnBloqueDeporte =>
      'Fútbol, natación, gimnasia, artes marciales y más.';

  @override
  String get plnBloqueArte => 'Música, teatro, danza y artes visuales.';

  @override
  String get plnBloqueIdiomas =>
      'Idiomas, conversación y comunicación oral y escrita.';

  @override
  String get plnBloqueCiencia => 'Robótica, programación y proyectos STEAM.';

  @override
  String get plnBloqueApoyo =>
      'Apoyo escolar, tutorías y preparación de exámenes.';

  @override
  String get plnBloqueBienestar =>
      'Bienestar, habilidades socioemocionales y orientación vocacional.';

  @override
  String get plnBloqueOtros =>
      'Propuestas que no entran en las otras categorías.';

  @override
  String plnVacantesActivas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vacantes publicadas',
      one: '1 vacante publicada',
    );
    return '$_temp0';
  }

  @override
  String plnSePausan(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se van a pausar $n vacantes',
      one: 'Se va a pausar 1 vacante',
    );
    return '$_temp0';
  }

  @override
  String get plnPromoTitulo => '¿Tenés un código promocional?';

  @override
  String get plnPromoCampo => 'Código';

  @override
  String get plnPromoHint => 'Ingresá tu código';

  @override
  String get plnPromoAplicar => 'Aplicar';

  @override
  String get plnPromoVacio => 'Ingresá un código.';

  @override
  String get plnPromoInvalido =>
      'Ese código no es válido. Revisalo e intentá de nuevo.';

  @override
  String get plnPromoAgotado => 'Este código ya alcanzó su límite de usos.';

  @override
  String plnPromoValido(int pct) {
    return '¡Código aplicado! Tenés un $pct% de descuento.';
  }

  @override
  String plnPromoActivo(int pct) {
    return 'Tenés un código promocional activo: $pct% de descuento.';
  }

  @override
  String get plnPromoQuitar => 'Quitar código';

  @override
  String get plnResumen => 'Resumen';

  @override
  String plnResumenNiveles(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n niveles curriculares',
      one: '1 nivel curricular',
    );
    return '$_temp0';
  }

  @override
  String plnResumenModulos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n módulos extracurriculares',
      one: '1 módulo extracurricular',
    );
    return '$_temp0';
  }

  @override
  String get plnSubtotal => 'Subtotal';

  @override
  String plnDescuentoVolumen(int min, int pct) {
    return 'Descuento por $min o más ítems ($pct%)';
  }

  @override
  String plnDescuentoPromo(int pct) {
    return 'Código promocional ($pct%)';
  }

  @override
  String get plnTotalMes => 'Total por mes';

  @override
  String plnFaltanItems(int n, int pct) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sumá $n ítems más y obtené un $pct% de descuento.',
      one: 'Sumá 1 ítem más y obtené un $pct% de descuento.',
    );
    return '$_temp0';
  }

  @override
  String get plnElegiAlMenosUno =>
      'Elegí al menos un nivel o un módulo para armar tu plan.';

  @override
  String get plnElegiAlMenosUnoCorto => 'Elegí al menos un nivel o módulo';

  @override
  String get plnPruebaTexto =>
      'Durante la prueba no se cobra nada; te vamos a avisar antes de habilitar el pago.';

  @override
  String plnPruebaEmpieza(int dias) {
    return 'Tu prueba gratis de $dias días empieza cuando guardás los cambios.';
  }

  @override
  String plnPruebaTerminada(Object fecha) {
    return 'Tu prueba terminó el $fecha. Todavía no hay pagos habilitados: te vamos a avisar antes de cobrar.';
  }

  @override
  String get plnSinCobros =>
      'Todavía no hay pagos habilitados en ATENA: no se te va a cobrar nada sin avisarte antes.';

  @override
  String get plnGratisTitulo => 'Plan sin costo';

  @override
  String get plnGratisTexto =>
      'Con tu código promocional, el plan queda activo sin costo.';

  @override
  String plnDiasRestantes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Quedan $n días de prueba.',
      one: 'Queda 1 día de prueba.',
      zero: 'Hoy es el último día de prueba.',
    );
    return '$_temp0';
  }

  @override
  String get plnCrear => 'Crear institución';

  @override
  String get plnCreando => 'Creando…';

  @override
  String get plnGuardar => 'Guardar cambios';

  @override
  String get plnCreada => '¡Listo! Tu institución ya está en ATENA.';

  @override
  String get plnGuardado => 'Plan actualizado.';

  @override
  String plnPausadas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Plan actualizado. Pausamos $n vacantes.',
      one: 'Plan actualizado. Pausamos 1 vacante.',
    );
    return '$_temp0';
  }

  @override
  String get plnCorregirDatos => 'Corregir mis datos';

  @override
  String get plnPausarTitulo => '¿Pausar vacantes publicadas?';

  @override
  String plnPausarMensaje(Object categorias, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Vamos a pausar $n vacantes publicadas para que las familias dejen de verlas.',
      one:
          'Vamos a pausar 1 vacante publicada para que las familias dejen de verla.',
    );
    return 'Quitaste $categorias de tu plan. $_temp0 Podés reactivarlas cuando vuelvas a sumar la categoría.';
  }

  @override
  String get plnPausarAccion => 'Guardar y pausar';

  @override
  String get plnErrorCarga => 'No pudimos cargar tu plan.';

  @override
  String get plnTuPlan => 'Tu plan';

  @override
  String plnPlanActual(Object precio) {
    return 'Plan actual: $precio por mes';
  }

  @override
  String get explorarTitulo => 'Explorar instituciones';

  @override
  String explorarPara(Object nombre) {
    return 'Para $nombre';
  }

  @override
  String get explorarBuscarHint => 'Buscá por nombre, ciudad o provincia';

  @override
  String get explorarBorrarBusqueda => 'Borrar búsqueda';

  @override
  String get explorarFiltros => 'Filtros';

  @override
  String get explorarFiltroNivel => 'Nivel';

  @override
  String get explorarFiltroActividad => 'Actividades';

  @override
  String get explorarFiltroModalidad => 'Modalidad';

  @override
  String get explorarCualquierNivel => 'Cualquier nivel';

  @override
  String get explorarCualquierActividad => 'Cualquier actividad';

  @override
  String get explorarCualquierModalidad => 'Cualquier modalidad';

  @override
  String explorarConLugarPara(Object nombre) {
    return 'Con vacantes para $nombre';
  }

  @override
  String explorarConLugarAyuda(Object nombre, Object edad) {
    return 'Solo instituciones con lugar disponible para la edad de $nombre ($edad).';
  }

  @override
  String get explorarLimpiarFiltros => 'Limpiar filtros';

  @override
  String explorarResultados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n instituciones',
      one: '1 institución',
    );
    return '$_temp0';
  }

  @override
  String get explorarVacioTitulo => 'Todavía no hay instituciones publicadas';

  @override
  String get explorarVacioMensaje =>
      'Las instituciones aparecen acá a medida que se registran en ATENA. Volvé a mirar pronto.';

  @override
  String get explorarSinResultadosTitulo => 'No encontramos instituciones';

  @override
  String get explorarSinResultadosMensaje =>
      'Probá con otras palabras o quitá algún filtro para ver más opciones.';

  @override
  String get explorarVerInstitucion => 'Ver institución';

  @override
  String explorarFotoDe(int n, int total) {
    return 'Foto $n de $total';
  }

  @override
  String get explorarVerFotos => 'Ver fotos en pantalla completa';

  @override
  String get explorarFotoAnterior => 'Foto anterior';

  @override
  String get explorarFotoSiguiente => 'Foto siguiente';

  @override
  String get explorarSobre => 'Sobre la institución';

  @override
  String get explorarLeerMas => 'Leer más';

  @override
  String get explorarLeerMenos => 'Leer menos';

  @override
  String get explorarHorarios => 'Horarios';

  @override
  String get explorarHorarioAtencion => 'Atención al público';

  @override
  String get explorarHorarioClases => 'Clases';

  @override
  String get explorarServicios => 'Servicios';

  @override
  String get explorarContacto => 'Contacto';

  @override
  String get explorarLlamar => 'Llamar';

  @override
  String get explorarWhatsapp => 'WhatsApp';

  @override
  String get explorarSitioWeb => 'Sitio web';

  @override
  String get explorarInstagram => 'Instagram';

  @override
  String get explorarFacebook => 'Facebook';

  @override
  String get explorarYoutube => 'YouTube';

  @override
  String get explorarComoLlegar => 'Cómo llegar';

  @override
  String get explorarNoSePudoAbrir =>
      'No pudimos abrirlo desde este dispositivo. Probá de nuevo en un rato.';

  @override
  String get explorarVacantes => 'Vacantes';

  @override
  String explorarPropuestas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n propuestas',
      one: '1 propuesta',
    );
    return '$_temp0';
  }

  @override
  String get explorarSinVacantesTitulo => 'Todavía no hay vacantes publicadas';

  @override
  String get explorarSinVacantesMensaje =>
      'Esta institución aún no publicó cursos ni actividades. Podés contactarla para consultar.';

  @override
  String get explorarPedirVacante => 'Pedir vacante';

  @override
  String get explorarVerSolicitud => 'Ver solicitud';

  @override
  String get explorarCompleto => 'Completo';

  @override
  String get explorarUltimasVacantes => 'Últimas vacantes';

  @override
  String explorarArancel(Object valor) {
    return 'Arancel: $valor';
  }

  @override
  String explorarFueraDeEdad(Object nombre) {
    return 'No coincide con la edad de $nombre';
  }

  @override
  String get explorarOcupacion => 'Ocupación';

  @override
  String get explorarInstNoEncontradaTitulo =>
      'No encontramos esta institución';

  @override
  String get explorarInstNoEncontradaMensaje =>
      'Puede que haya dejado de publicar su perfil en ATENA.';

  @override
  String get solAlPedirTitulo => 'Pedir vacante';

  @override
  String get solAlAlumno => 'Alumno';

  @override
  String get solAlFueraDeEdadTitulo => 'La edad no coincide';

  @override
  String solAlFueraDeEdadMensaje(Object nombre, Object edad) {
    return '$nombre tiene $edad y esta vacante es para otra edad. Podés enviar la solicitud igual: la institución va a decidir.';
  }

  @override
  String get solAlMensajeLabel => 'Mensaje para la institución (opcional)';

  @override
  String get solAlMensajeAyuda =>
      'Contales algo del alumno o hacé una consulta.';

  @override
  String get solAlComoSigue =>
      'La institución revisa tu pedido y te avisamos por notificación apenas responda.';

  @override
  String get solAlEnviar => 'Enviar solicitud';

  @override
  String get solAlEnviadaOk =>
      '¡Solicitud enviada! Te avisamos cuando la institución responda.';

  @override
  String get solAlTitulo => 'Mis solicitudes';

  @override
  String get solAlTabActivas => 'Activas';

  @override
  String get solAlTabHistorial => 'Historial';

  @override
  String get solAlActivasVacioTitulo => 'No tenés solicitudes activas';

  @override
  String get solAlActivasVacioMensaje =>
      'Cuando pidas una vacante, vas a poder seguir cada paso desde acá.';

  @override
  String get solAlHistorialVacioTitulo => 'Tu historial está vacío';

  @override
  String get solAlHistorialVacioMensaje =>
      'Acá vas a ver las solicitudes que ya se cerraron: no aceptadas, canceladas o dadas de baja.';

  @override
  String solAlRespuestaDe(Object institucion) {
    return 'Respuesta de $institucion';
  }

  @override
  String get solAlDetalleTitulo => 'Detalle de la solicitud';

  @override
  String get solAlNoEncontradaTitulo => 'No encontramos esta solicitud';

  @override
  String get solAlNoEncontradaMensaje =>
      'Puede que se haya eliminado o que corresponda a otro alumno.';

  @override
  String get solAlEstadoPendienteTitulo => 'Tu solicitud está en revisión';

  @override
  String solAlEstadoPendienteMensaje(Object institucion) {
    return '$institucion la está revisando. Te vamos a avisar por notificación apenas responda.';
  }

  @override
  String get solAlEstadoConfirmadaTitulo => '¡Tenés la vacante!';

  @override
  String solAlEstadoConfirmadaMensaje(Object institucion) {
    return '$institucion confirmó tu lugar. Próximos pasos: revisá Documentos por si te piden papeles y seguí las fechas importantes en el Calendario.';
  }

  @override
  String get solAlEstadoRechazadaTitulo => 'Esta vez no fue posible';

  @override
  String solAlEstadoRechazadaMensaje(Object institucion) {
    return '$institucion no pudo aceptar la solicitud. No te desanimes: hay otras instituciones con vacantes disponibles.';
  }

  @override
  String get solAlEstadoCanceladaTitulo => 'Cancelaste esta solicitud';

  @override
  String get solAlEstadoCanceladaMensaje =>
      'Si cambiás de opinión, podés volver a pedir la vacante mientras haya lugar.';

  @override
  String get solAlEstadoBajaTitulo => 'La institución dio de baja la vacante';

  @override
  String solAlEstadoBajaMensaje(Object institucion) {
    return '$institucion dio de baja esta vacante. Si tenés dudas, comunicate con la institución.';
  }

  @override
  String get solAlLaVacante => 'La vacante';

  @override
  String get solAlTurnoHorario => 'Turno y horario';

  @override
  String get solAlDias => 'Días';

  @override
  String get solAlEdad => 'Edad';

  @override
  String solAlEdadAlumno(Object nombre, Object edad) {
    return '$nombre tiene $edad';
  }

  @override
  String get solAlArancel => 'Arancel';

  @override
  String get solAlTuMensaje => 'Tu mensaje';

  @override
  String get solAlSeguimiento => 'Seguimiento';

  @override
  String get solAlHitoEnviada => 'Solicitud enviada';

  @override
  String get solAlHitoConfirmada => 'Vacante confirmada';

  @override
  String get solAlHitoRechazada => 'Solicitud no aceptada';

  @override
  String get solAlHitoCancelada => 'Cancelaste la solicitud';

  @override
  String get solAlHitoBaja => 'Baja de la vacante';

  @override
  String get solAlCancelar => 'Cancelar solicitud';

  @override
  String get solAlCancelarTitulo => '¿Cancelar esta solicitud?';

  @override
  String solAlCancelarMsgPendiente(Object oferta, Object institucion) {
    return 'Vas a retirar tu pedido para $oferta en $institucion. Si cambiás de opinión, podés volver a pedirla mientras haya lugar.';
  }

  @override
  String solAlCancelarMsgConfirmada(Object oferta, Object institucion) {
    return 'Vas a liberar tu vacante confirmada en $oferta ($institucion) y otra familia podrá ocupar ese lugar.';
  }

  @override
  String get solAlCancelarConfirmar => 'Sí, cancelar';

  @override
  String get solAlMantener => 'No, mantenerla';

  @override
  String get solAlCanceladaOk => 'Cancelaste la solicitud.';

  @override
  String get solAlComprobante => 'Descargar comprobante';

  @override
  String get solAlComprobanteError =>
      'No pudimos generar el comprobante. Probá de nuevo en unos minutos.';

  @override
  String get comInstAvisosEnviadosAyuda =>
      'Llegan como notificación a las familias de los alumnos confirmados.';

  @override
  String get comInstEventoNoDisponible => 'Este evento ya no está disponible';

  @override
  String get comInstEventoNoDisponibleMensaje =>
      'Puede que se haya eliminado. Volvé al calendario para ver los eventos vigentes.';

  @override
  String get docInstErrorTipo => 'Elegí qué documento necesitás.';

  @override
  String get docInstPedidoNoDisponible => 'Este pedido ya no está disponible';

  @override
  String get docInstPedidoNoDisponibleMensaje =>
      'Puede que la familia haya eliminado su cuenta o que el pedido se haya borrado.';

  @override
  String get solInstYaNoExisteTitulo => 'Esta solicitud ya no existe';

  @override
  String get solInstYaNoExisteMsg =>
      'Es posible que la familia haya eliminado su cuenta. Si tenía un lugar confirmado, ya quedó libre.';

  @override
  String get solInstYaNoExiste =>
      'Esa solicitud ya no existe. Es posible que la familia haya eliminado su cuenta.';

  @override
  String get solAlLaInstitucion => 'la institución';

  @override
  String get solAlInstNoDisponible => 'Ya no está en ATENA';

  @override
  String solAlEstadoBajaSinInstMensaje(Object institucion) {
    return '$institucion ya no forma parte de ATENA, por eso esta vacante se dio de baja. Podés buscar otras instituciones con lugar.';
  }

  @override
  String get plnVerResumen => 'Ver resumen';

  @override
  String perfInstConsejoFotosPrimeras(int n) {
    return 'Subí al menos $n fotos de tus espacios.';
  }

  @override
  String homeStatActiveRequestsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Solicitudes activas',
      one: 'Solicitud activa',
    );
    return '$_temp0';
  }

  @override
  String homeStatUpcomingEventsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Próximos eventos',
      one: 'Próximo evento',
    );
    return '$_temp0';
  }

  @override
  String homeStatPendingDocsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Documentos por entregar',
      one: 'Documento por entregar',
    );
    return '$_temp0';
  }

  @override
  String instStatPendingN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Solicitudes pendientes',
      one: 'Solicitud pendiente',
    );
    return '$_temp0';
  }

  @override
  String instStatStudentsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Alumnos confirmados',
      one: 'Alumno confirmado',
    );
    return '$_temp0';
  }

  @override
  String instStatFreeSpotsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vacantes libres',
      one: 'Vacante libre',
    );
    return '$_temp0';
  }

  @override
  String instStatOffersN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ofertas activas',
      one: 'Oferta activa',
    );
    return '$_temp0';
  }
}
