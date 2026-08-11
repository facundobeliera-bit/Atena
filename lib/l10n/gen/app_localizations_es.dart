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
  String get alumnos => 'Alumnos';

  @override
  String get instituciones => 'Instituciones';

  @override
  String get institution => 'Institución';

  @override
  String get perfiles => 'Perfiles';

  @override
  String get crearPerfil => 'Crear perfil';

  @override
  String get crearPerfilTitulo => 'Crear un nuevo perfil';

  @override
  String get tipoAlumno => 'Alumno';

  @override
  String get tipoInstitucion => 'Institución';

  @override
  String get actualizar => 'Actualizar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get update => 'Actualizar';

  @override
  String get guardar => 'Guardar';

  @override
  String get save => 'Guardar';

  @override
  String get editar => 'Editar';

  @override
  String get edit => 'Editar';

  @override
  String get eliminar => 'Eliminar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continuar => 'Continuar';

  @override
  String get continuarUltimoPerfil => 'Continuar con el último perfil';

  @override
  String get accept => 'Aceptar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Rechazar';

  @override
  String get apply => 'Aplicar';

  @override
  String get clear => 'Limpiar';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Volver';

  @override
  String get open => 'Abrir';

  @override
  String get cuentaLabel => 'Cuenta';

  @override
  String accountLabel(Object ownerId) {
    return 'Cuenta: $ownerId';
  }

  @override
  String get signIn => 'Ingresar';

  @override
  String get signOut => 'Salir';

  @override
  String get signInOrRegister => 'Ingresar o registrarse';

  @override
  String get accessInstitutionAccount => 'Acceder a cuenta de institución';

  @override
  String get signInToEnableInstitutionFeatures =>
      'Ingresá para habilitar funciones de institución';

  @override
  String get errorGenerico => 'Error.';

  @override
  String get invalidSessionForThisAccount =>
      'Sesión inválida para esta cuenta.';

  @override
  String get cannotLoadInstitutionTryAgain =>
      'No se pudo cargar la institución. Intentá nuevamente.';

  @override
  String get noPerfilesTodavia =>
      'Todavía no hay perfiles.\nCreá uno para comenzar.';

  @override
  String get noPerfilesAlumnoTodavia => 'Todavía no hay perfiles de alumno.';

  @override
  String get accionAlumnoSinPerfil =>
      'Se recibió una acción para Alumnos, pero esta cuenta no tiene perfiles de Alumno.';

  @override
  String get opcionNoDisponibleBuild =>
      'Esta opción todavía no está disponible en esta versión.';

  @override
  String get ingresarCrearCuenta => 'Ingresar / Crear cuenta';

  @override
  String get accesoAlumnos => 'Acceso de alumnos';

  @override
  String get ingresaCuentaEligePerfil =>
      'Ingresá con tu cuenta y elegí el perfil.';

  @override
  String get saving => 'Guardando…';

  @override
  String get registering => 'Registrando…';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get modoOscuro => 'Modo oscuro';

  @override
  String get idioma => 'Idioma';

  @override
  String get sistema => 'Sistema';

  @override
  String get espanol => 'Español';

  @override
  String get ingles => 'Inglés';

  @override
  String get portugues => 'Portugués';

  @override
  String get landingTitle => 'ATENA';

  @override
  String get landingIngresar => 'Ingresar';

  @override
  String get landingStudents => 'Alumnos';

  @override
  String get landingInstitutions => 'Instituciones';

  @override
  String get landingHeadingStudents => 'alumnos';

  @override
  String get landingHeadingInstitutions => 'instituciones';

  @override
  String get landingThemeSystem => 'Tema: Sistema';

  @override
  String get landingThemeLight => 'Tema: Claro';

  @override
  String get landingThemeDark => 'Tema: Oscuro';

  @override
  String get landingLanguageTooltip => 'Idioma';

  @override
  String get landingLanguageSystem => 'Sistema';

  @override
  String get landingLanguageEs => 'Español';

  @override
  String get landingLanguageEn => 'Inglés';

  @override
  String get landingLanguagePt => 'Portugués';

  @override
  String landingMissingAsset(Object path) {
    return 'ARCHIVO AUSENTE:\n$path';
  }

  @override
  String get vacancyManagement => 'Vacantes';

  @override
  String vacancyManagementTitle(Object institucion) {
    return 'Gestión de vacantes – $institucion';
  }

  @override
  String get recalculateOccupiedTooltip => 'Recalcular ocupadas (confirmadas)';

  @override
  String get summaryLabel => 'Resumen';

  @override
  String totalCapacityValue(Object valor) {
    return 'Capacidad total: $valor';
  }

  @override
  String occupiedValue(Object valor) {
    return 'Ocupadas: $valor';
  }

  @override
  String availableEstimatedValue(Object valor) {
    return 'Disponibles (estimado): $valor';
  }

  @override
  String get noGroupsLoaded => 'No se cargó ningún grupo/vacante.';

  @override
  String vacancyGroupSubtitle(
    Object actividad,
    Object total,
    Object ocupados,
    Object disponibles,
  ) {
    return '$actividad · Capacidad $total · Ocupadas $ocupados · Disp $disponibles';
  }

  @override
  String get newGroupTitle => 'Nuevo grupo/vacante';

  @override
  String get editGroupTitle => 'Editar grupo/vacante';

  @override
  String get available => 'Disponible';

  @override
  String get availableShort => 'Disp';

  @override
  String get availableLabel => 'Disponibles';

  @override
  String get fullLabel => 'Completo';

  @override
  String get curricular => 'Curricular';

  @override
  String get curricularLabel => 'Curricular';

  @override
  String get curricularPlural => 'Curricular';

  @override
  String get extracurricular => 'Extracurricular';

  @override
  String get extracurricularLabel => 'Extracurricular';

  @override
  String get extracurricularPlural => 'Extracurricular';

  @override
  String get basic => 'Básico';

  @override
  String get standard => 'Estándar';

  @override
  String get premium => 'Premium';

  @override
  String get summary => 'Resumen';

  @override
  String get plan => 'Plan';

  @override
  String get code => 'Código';

  @override
  String get invalidInstitutionId => 'ID de institución inválido.';

  @override
  String get institucionInvalidGeneric => 'Institución inválida.';

  @override
  String get institutionGeneric => 'Institución';

  @override
  String get institutionNotLoadedYet => 'La institución todavía no se cargó.';

  @override
  String get noActiveSessionGoBackToLogin =>
      'No hay sesión activa. Volvé al login.';

  @override
  String get institutionsTitle => 'Instituciones';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get institutionAccess => 'Acceso de institución';

  @override
  String institutionProfileIdLabel(Object perfilId) {
    return 'ID de perfil: $perfilId';
  }

  @override
  String get planPlaceholder => 'Gestión de plan';

  @override
  String get profilePlaceholder => 'Perfil de institución';

  @override
  String get planUpper => 'PLAN';

  @override
  String get profileUpper => 'PERFIL';

  @override
  String get administrationUpper => 'ADMINISTRACIÓN';

  @override
  String get planCardSubtitle => 'Gestionar plan y módulos';

  @override
  String get profileCardSubtitle => 'Detalles y presentación de la institución';

  @override
  String get administrationCardSubtitle => 'Operación de la institución';

  @override
  String planAndStatusLine(Object plan, Object estado) {
    return 'Plan: $plan · Estado: $estado';
  }

  @override
  String get workProfilesUpToPremium => 'Hasta 10 perfiles de trabajo';

  @override
  String get workProfilesUpToStandard => 'Hasta 3 perfiles de trabajo';

  @override
  String get moduleLabelGeneric => 'Módulo';

  @override
  String invalidModuleKeyShowingAll(Object key) {
    return 'Filtro inválido ($key). Mostrando todos los módulos.';
  }

  @override
  String loadErrorWithDetails(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String get confirmRequestTitle => 'Confirmar solicitud';

  @override
  String get rejectRequestTitle => 'Rechazar solicitud';

  @override
  String get updateRequestTitle => 'Actualizar solicitud';

  @override
  String get confirmRequestBody => '¿Querés confirmar esta solicitud?';

  @override
  String get rejectRequestBody => '¿Querés rechazar esta solicitud?';

  @override
  String get updateRequestBody => '¿Querés actualizar esta solicitud?';

  @override
  String activityWithName(Object nombre) {
    return 'Actividad: $nombre';
  }

  @override
  String activityWithValue(Object value) {
    return 'Actividad: $value';
  }

  @override
  String get rejectionReasonOptionalLabel => 'Motivo (opcional)';

  @override
  String get noteToStudentOptionalLabel => 'Nota al alumno (opcional)';

  @override
  String get requestStatusPending => 'Pendiente';

  @override
  String get requestStatusConfirmed => 'Confirmada';

  @override
  String get requestStatusRejected => 'Rechazada';

  @override
  String get requestStatusCancelledByStudent => 'Cancelada por el alumno';

  @override
  String get requestStatusCancelledByInstitution =>
      'Cancelada por la institución';

  @override
  String get requestConfirmed => 'Solicitud confirmada.';

  @override
  String get requestRejected => 'Solicitud rechazada.';

  @override
  String get requestUpdated => 'Solicitud actualizada.';

  @override
  String get requestIsNoLongerPending => 'Esta solicitud ya no está pendiente.';

  @override
  String get noRequestsInSection => 'No hay solicitudes en esta sección.';

  @override
  String get noPendingRequests => 'No hay solicitudes pendientes.';

  @override
  String actionErrorWithDetails(Object error) {
    return 'No se pudo completar la acción: $error';
  }

  @override
  String get cannotOpenDocumentsMissingOwnerOrProfile =>
      'No se puede abrir Documentación sin una sesión válida.';

  @override
  String requestsTitleWithInstitution(Object institucion, Object subtitle) {
    return 'Solicitudes – $institucion · $subtitle';
  }

  @override
  String pendingWithCount(Object count) {
    return 'Pendientes ($count)';
  }

  @override
  String confirmedWithCount(Object count) {
    return 'Confirmadas ($count)';
  }

  @override
  String rejectedWithCount(Object count) {
    return 'Rechazadas ($count)';
  }

  @override
  String cancelledWithCount(Object count) {
    return 'Canceladas ($count)';
  }

  @override
  String invalidModuleFilterBanner(Object key) {
    return 'Filtro de módulo inválido ($key)';
  }

  @override
  String filteringByModuleBanner(Object module, Object key) {
    return 'Filtrando por módulo: $module ($key)';
  }

  @override
  String studentDocumentLine(Object doc) {
    return 'Documento: $doc';
  }

  @override
  String typeLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String moduleLine(Object module) {
    return 'Módulo: $module';
  }

  @override
  String groupOrClassLine(Object valor) {
    return 'Curso/Grupo: $valor';
  }

  @override
  String shiftLine(Object valor) {
    return 'Turno: $valor';
  }

  @override
  String statusLine(Object estado) {
    return 'Estado: $estado';
  }

  @override
  String get requestOrViewDocumentsCta => 'Solicitar o ver documentación';

  @override
  String get documentsMissingOwnerOrProfileDisabledCta =>
      'Documentación no disponible';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notificationsTitleWithNewCount(Object count) {
    return 'Notificaciones ($count nuevas)';
  }

  @override
  String get notificationsDeleted => 'Notificaciones eliminadas.';

  @override
  String loadNotificationsError(Object error) {
    return 'Error al cargar notificaciones: $error';
  }

  @override
  String updateNotificationError(Object error) {
    return 'Error al actualizar notificación: $error';
  }

  @override
  String deleteNotificationError(Object error) {
    return 'Error al eliminar notificación: $error';
  }

  @override
  String get markAllReadError => 'No se pudo marcar todo como leído';

  @override
  String get deleteAll => 'Eliminar todas';

  @override
  String get deleteAllNotificationsError => 'No se pudo eliminar todo';

  @override
  String get sessionInvalidTitle => 'Sesión inválida';

  @override
  String get sessionInvalidPleaseLogin => 'Sesión inválida. Iniciá sesión.';

  @override
  String get notificationsNeedOwnerSubtitle =>
      'Se requiere una sesión activa para ver notificaciones.';

  @override
  String get noNotificationsTitle => 'Sin notificaciones';

  @override
  String get noNotificationsSubtitle => 'No hay notificaciones disponibles.';

  @override
  String get deleteNotificationTitle => 'Eliminar notificación';

  @override
  String get deleteNotificationBody => '¿Querés eliminar esta notificación?';

  @override
  String get deleteAllNotificationsTitle => 'Eliminar todas';

  @override
  String get deleteAllNotificationsBody =>
      '¿Querés eliminar todas las notificaciones?';

  @override
  String get deleteAllNotificationsTooltip => 'Eliminar todas';

  @override
  String get markAsRead => 'Marcar como leída';

  @override
  String get markAsUnread => 'Marcar como no leída';

  @override
  String get markAllAsReadTooltip => 'Marcar todas como leídas';

  @override
  String get institucionActividadCurricularGeneral => 'Actividad curricular';

  @override
  String get institucionActividadExtracurricularGeneral =>
      'Actividad extracurricular';

  @override
  String get institucionActividadExtracurricular => 'Extracurricular';

  @override
  String get institucionWorkProfileFallback => 'Perfil de trabajo';

  @override
  String get institucionChangeActivityTitle => 'Cambiar actividad';

  @override
  String get institucionChangeActivityBody =>
      'Seleccioná la actividad que querés gestionar';

  @override
  String get institucionWorkProfileNameTitle => 'Nombre del perfil';

  @override
  String get name => 'Nombre';

  @override
  String get institucionWorkProfileNameHint => 'ej.: Administración, Dirección';

  @override
  String get institucionWorkProfileNameInvalid => 'Nombre inválido.';

  @override
  String institucionAreaChip(Object area, Object who) {
    return '$area · $who';
  }

  @override
  String institucionAreaChipWithTtl(Object area, Object who, Object ttl) {
    return '$area · $who · $ttl';
  }

  @override
  String get institucionAreasFree => 'Áreas libres';

  @override
  String get planFallbackNoStructured => 'Plan sin estructura detallada';

  @override
  String get idNoSession => 'Sin sesión';

  @override
  String idWithValue(Object value) {
    return 'ID: $value';
  }

  @override
  String institucionPlanAndProfilesPerActivity(Object plan, Object max) {
    return 'Plan: $plan · Perfiles: $max por actividad';
  }

  @override
  String get institucionFirstSelectActivityBody =>
      'Primero seleccioná una actividad';

  @override
  String get institucionWorkProfilesAreInternalNote =>
      'Los perfiles de trabajo son internos';

  @override
  String get institucionNoActivitiesYet =>
      'Todavía no hay actividades configuradas';

  @override
  String get institucionManageCurricularActivity =>
      'Gestionar actividad curricular';

  @override
  String get institucionManageExtracurricularModule =>
      'Gestionar módulo extracurricular';

  @override
  String institucionPlanAndAvailableProfiles(Object plan, Object max) {
    return 'Plan: $plan · Perfiles disponibles: $max';
  }

  @override
  String get institucionConcurrentProfilesRule =>
      'Perfiles simultáneos según el plan';

  @override
  String get institucionWorkProfilesTitle => 'Perfiles de trabajo';

  @override
  String get institucionWorkProfilesDescription =>
      'Gestión de perfiles internos';

  @override
  String institucionProfileWorkingSubtitle(
    Object area,
    Object who,
    Object ttl,
  ) {
    return '$area · $who$ttl';
  }

  @override
  String get institucionWorkProfilesRenameTip => 'Podés renombrar este perfil';

  @override
  String get institucionSelectActivityTitle => 'Seleccionar actividad';

  @override
  String get institucionSelectWorkProfileTitle =>
      'Seleccionar perfil de trabajo';

  @override
  String get institucionChangeActivityTooltip => 'Cambiar actividad';

  @override
  String get institucionPlanTitle => 'Plan de institución';

  @override
  String get institucionPlanHeader => 'Elegí tu plan';

  @override
  String get institucionPlanChooseYourPlanTitle => 'Elegí tu plan';

  @override
  String get institucionPlanChooseYourPlanSubtitle =>
      'Seleccioná el plan más adecuado';

  @override
  String get institucionPlanNoModulesSelected =>
      'No se seleccionó ningún módulo.';

  @override
  String get institucionPlanInvalidInstitutionId => 'Institución inválida.';

  @override
  String get institucionPlanPickAtLeastOneModule =>
      'Seleccioná al menos un módulo.';

  @override
  String get institucionPlanChooseStandardOrPremium =>
      'Elegí Estándar o Premium.';

  @override
  String get institucionPlanChooseBasicOrPremium => 'Elegí Básico o Premium.';

  @override
  String get institucionPlanPromoCleared => 'Código quitado';

  @override
  String get institucionPlanPromoSoldOut => 'Código agotado';

  @override
  String get institucionPlanPromoReservedAlready => 'Código ya reservado';

  @override
  String get institucionPlanPromoReserved => 'Código reservado';

  @override
  String get institucionPlanPromoInvalid => 'Código inválido';

  @override
  String institucionPlanPromoApplied(Object code) {
    return 'Promo aplicada: $code';
  }

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get invalidPassword => 'Contraseña inválida';

  @override
  String get institucionPlanCodeRequiredForFreeActivation =>
      'Se requiere un código para activar el plan gratuito';

  @override
  String get argentina => 'Argentina';

  @override
  String get emailAlreadyRegisteredLogin =>
      'Email ya registrado. Iniciá sesión.';

  @override
  String institucionPlanTierLabel(Object tier, Object price) {
    return 'Plan $tier ($price)';
  }

  @override
  String get usdToArsTitle => 'Conversión USD → ARS';

  @override
  String get usdToArsSubtitleBestEffort => 'Estimación de referencia';

  @override
  String get usdToArsUnavailable => 'Conversión no disponible';

  @override
  String usdToArsValue(Object value) {
    return 'USD → ARS: $value';
  }

  @override
  String get usdToArsManualLabel => 'Cotización manual';

  @override
  String get usdToArsUsingManual => 'Usando cotización manual';

  @override
  String updatedAt(Object date) {
    return 'Actualizado el $date';
  }

  @override
  String get promoCodeTitle => 'Código promocional';

  @override
  String get promoCodeOptionalSubtitle => 'Opcional';

  @override
  String get promoCodeLabel => 'Código';

  @override
  String get promoCodeHint => 'Ingresá el código';

  @override
  String get iHavePromoCode => 'Tengo un código';

  @override
  String promoAppliedLine(Object code, Object label) {
    return 'Promo aplicada: $code · $label';
  }

  @override
  String get subtotalUsd => 'Subtotal (USD)';

  @override
  String get promoDiscountUsd => 'Descuento (USD)';

  @override
  String get totalUsd => 'Total (USD)';

  @override
  String get totalArs => 'Total (ARS)';

  @override
  String get institucionPlanSummarySubtitle => 'Resumen del plan';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get calcDetailsTitle => 'Detalles del cálculo';

  @override
  String get calcDetailsSubtitle => 'Desglose de precios';

  @override
  String get institucionPlanNoteNoPaymentsYet =>
      'Los pagos todavía no están habilitados en esta fase';

  @override
  String get institucionGenericName => 'Institución';

  @override
  String get countryArgentina => 'Argentina';

  @override
  String get institucionTitle => 'Institución';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionBackHome => 'Volver al inicio';

  @override
  String get actionLogout => 'Salir';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String get actionExit => 'Salir';

  @override
  String get actionLoad => 'Cargar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionSaving => 'Guardando…';

  @override
  String get statusSaving => 'Guardando…';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRequest => 'Solicitar';

  @override
  String get actionList => 'Listar';

  @override
  String get actionIncrease => 'Aumentar';

  @override
  String get actionDecrease => 'Disminuir';

  @override
  String get valueEmpty => 'Vacío';

  @override
  String get valueNone => 'Ninguno';

  @override
  String get labelNotProvided => 'No informado';

  @override
  String get validationTooShort => 'Muy corto';

  @override
  String get validationCannotBeNegative => 'No puede ser negativo';

  @override
  String get institucionAreaErrorLoadFailed =>
      'No se pudo cargar el área operativa.';

  @override
  String get institucionAreaSnackNoInstitucion => 'No hay institución cargada.';

  @override
  String get institucionAreaDefaultWorkProfileName => 'Perfil de trabajo';

  @override
  String get institucionAreaSnackAreaInUse =>
      'Esta área está siendo usada por otro perfil.';

  @override
  String get institucionAreaDefaultActivityLabel => 'Actividad';

  @override
  String get institucionAreaTitle => 'Área operativa';

  @override
  String institucionAreaIdLine(Object id) {
    return 'ID: $id';
  }

  @override
  String institucionAreaLocationLine(Object location) {
    return 'Ubicación: $location';
  }

  @override
  String institucionAreaActivityLine(Object activity) {
    return 'Actividad: $activity';
  }

  @override
  String institucionAreaWorkProfileLine(Object profile) {
    return 'Perfil: $profile';
  }

  @override
  String institucionAreaAccessLine(Object curricularOk, Object extraOk) {
    return 'Acceso: curricular $curricularOk · extracurricular $extraOk';
  }

  @override
  String get institucionAreaCardNotificationsTitle => 'Notificaciones';

  @override
  String get institucionAreaCardNotificationsSubtitle =>
      'Ver notificaciones de la institución';

  @override
  String get institucionAreaSemanticsOpenNotifications =>
      'Abrir notificaciones';

  @override
  String get institucionAreaCardSolicitudesTitle => 'Solicitudes';

  @override
  String get institucionAreaCardSolicitudesSubtitle =>
      'Gestionar solicitudes de alumnos';

  @override
  String get institucionAreaSemanticsOpenSolicitudes => 'Abrir solicitudes';

  @override
  String get institucionAreaCardVacantesTitle => 'Vacantes';

  @override
  String get institucionAreaCardVacantesSubtitle =>
      'Gestionar grupos y capacidades';

  @override
  String get institucionAreaSemanticsOpenVacantes => 'Abrir vacantes';

  @override
  String get institucionAreaCardVacantesLockedSubtitle =>
      'No disponible en este plan';

  @override
  String get institucionAreaSemanticsVacantesLocked =>
      'Vacantes no disponibles';

  @override
  String get institucionAreaCardDocumentacionTitle => 'Documentación';

  @override
  String get institucionAreaCardDocumentacionSubtitle =>
      'Solicitar y revisar documentos';

  @override
  String get institucionAreaSemanticsOpenDocumentacion => 'Abrir documentación';

  @override
  String get institucionAreaCardExtraHubTitle => 'Extracurricular';

  @override
  String get institucionAreaCardExtraHubSubtitle =>
      'Gestionar módulos extracurriculares';

  @override
  String get institucionAreaSemanticsOpenExtraHub => 'Abrir extracurricular';

  @override
  String get institucionAreaCardExtraHubLockedSubtitle =>
      'No disponible en este plan';

  @override
  String get institucionAreaSemanticsExtraHubLocked =>
      'Extracurricular no disponible';

  @override
  String get institucionAreaCardCroquisTitle => 'Croquis';

  @override
  String get institucionAreaCardCroquisSubtitle => 'Gestionar croquis del aula';

  @override
  String get institucionAreaSemanticsOpenCroquis => 'Abrir croquis';

  @override
  String get institucionAreaCardCroquisLockedSubtitle =>
      'No disponible en este plan';

  @override
  String get institucionAreaSemanticsOpenCroquisLocked =>
      'Croquis no disponible';

  @override
  String get institucionAreaSnackMissingActivityScope =>
      'Primero seleccioná una actividad para operar.';

  @override
  String get institucionAreaMissingActivityHint =>
      'Falta seleccionar una actividad. Volvé y elegí una para habilitar las acciones.';

  @override
  String get turnoMorning => 'Mañana';

  @override
  String get croquisTitle => 'Croquis del aula';

  @override
  String get croquisTurnoMorning => 'Mañana';

  @override
  String get croquisTurnoAfternoon => 'Tarde';

  @override
  String get croquisTurnoNight => 'Noche';

  @override
  String get croquisTurnoFullDay => 'Jornada completa';

  @override
  String get croquisSnackInvalidInstitution => 'Institución inválida.';

  @override
  String get croquisSnackEnterAulaBeforeSave =>
      'Ingresá el nombre del aula antes de guardar.';

  @override
  String get croquisSnackSaved => 'Croquis guardado.';

  @override
  String croquisSnackSaveError(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get croquisDialogClearTitle => 'Limpiar grilla';

  @override
  String get croquisDialogClearBody => '¿Querés limpiar toda la grilla?';

  @override
  String get croquisDialogCellTitle => 'Celda';

  @override
  String get croquisFieldNameLabel => 'Nombre';

  @override
  String get croquisDialogNewGroupTitle => 'Nuevo grupo';

  @override
  String get croquisFieldGroupTitleLabel => 'Nombre del grupo';

  @override
  String get croquisFieldGroupColorLabel => 'Color del grupo';

  @override
  String get croquisFieldGroupColorHint => 'Elegí un color';

  @override
  String get croquisFieldRowLabel => 'Fila';

  @override
  String get croquisFieldColLabel => 'Columna';

  @override
  String get croquisFieldHeightLabel => 'Alto';

  @override
  String get croquisFieldWidthLabel => 'Ancho';

  @override
  String get croquisDialogDeleteGroupTitle => 'Eliminar grupo';

  @override
  String get croquisDialogDeleteGroupBody => '¿Querés eliminar este grupo?';

  @override
  String get croquisDialogUnsavedTitle => 'Cambios sin guardar';

  @override
  String get croquisDialogUnsavedBody =>
      'Tenés cambios sin guardar. ¿Salir igual?';

  @override
  String get croquisErrorInit => 'Error al inicializar el croquis.';

  @override
  String get croquisSectionAulaTurno => 'Aula y turno';

  @override
  String get croquisFieldAulaLabel => 'Aula';

  @override
  String get croquisFieldAulaHint => 'ej.: Aula 1 / 3B';

  @override
  String get croquisFieldTurnoLabel => 'Turno';

  @override
  String get croquisActionClearGrid => 'Limpiar grilla';

  @override
  String get croquisActionAddGroup => 'Agregar grupo';

  @override
  String get croquisTipTapCellAutosave =>
      'Tocá una celda para editar. Se guarda automáticamente.';

  @override
  String get croquisSectionGrid => 'Grilla';

  @override
  String croquisGridSizeLine(Object rows, Object cols) {
    return 'Tamaño: $rows×$cols';
  }

  @override
  String get croquisSectionGroups => 'Grupos';

  @override
  String get croquisGroupsEmpty => 'No hay grupos creados.';

  @override
  String get croquisGroupFallbackTitle => 'Grupo';

  @override
  String croquisGroupSubtitle(Object count) {
    return 'Miembros: $count';
  }

  @override
  String get institucionDocsWarnPerfilButNoOwner =>
      'Hay perfil, pero falta owner. Vista limitada.';

  @override
  String get institucionDocsWarnOwnerButNoPerfil =>
      'Hay owner, pero falta perfil. Vista limitada.';

  @override
  String get institucionDocsErrorInvalidInstitutionId =>
      'ID de institución inválido.';

  @override
  String get institucionDocsSnackInvalidInstitutionEmptyId =>
      'ID de institución vacío.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfil =>
      'Owner y perfil son obligatorios para esta acción.';

  @override
  String get institucionDocsSnackNoDocTypes =>
      'No hay tipos de documento disponibles.';

  @override
  String get institucionDocsSnackSolicitudCreated => 'Solicitud creada.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfilToUpload =>
      'Owner y perfil son obligatorios para simular subida.';

  @override
  String get institucionDocsSnackMissingRef =>
      'Falta la referencia del archivo.';

  @override
  String get institucionDocsSnackTempDocSaved => 'Documento temporal guardado.';

  @override
  String get institucionDocsSnackNeedPerfilToCleanup =>
      'Perfil es obligatorio para limpiar expirados.';

  @override
  String get institucionDocsSnackNoExpiredToRemove =>
      'No hay expirados para eliminar.';

  @override
  String institucionDocsSnackExpiredRemoved(Object count) {
    return 'Se eliminaron $count expirados.';
  }

  @override
  String get institucionDocsDialogDeleteTitle => 'Eliminar';

  @override
  String institucionDocsDialogDeleteBody(Object name) {
    return '¿Eliminar este ítem: $name?';
  }

  @override
  String get institucionDocsSnackExpiredUseCleanup =>
      'Expirado. Usá limpiar expirados.';

  @override
  String get institucionDocsSnackDeleted => 'Eliminado.';

  @override
  String get institucionDocsSnackCannotOpenMissingIds =>
      'No se puede abrir: faltan IDs.';

  @override
  String get institucionDocsSnackDeeplinkTooLong => 'Deeplink demasiado largo.';

  @override
  String get institucionDocsSnackRouteNotRegistered => 'Ruta no registrada.';

  @override
  String get estadoSolicitudPendiente => 'Pendiente';

  @override
  String get estadoSolicitudCumplida => 'Cumplida';

  @override
  String get estadoSolicitudCancelada => 'Cancelada';

  @override
  String get estadoDocumentoExpirado => 'Expirado';

  @override
  String get estadoDocumentoActivo => 'Activo';

  @override
  String get institucionDocsTooltipOpenAlumno => 'Abrir alumno';

  @override
  String get institucionDocsTooltipExpiredUseCleanup =>
      'Expirado (usar limpieza)';

  @override
  String get institucionDocsViewAllInstitution => 'Ver todo (institución)';

  @override
  String get institucionDocsViewFilteredOwnerPerfil =>
      'Filtrado (owner+perfil)';

  @override
  String get institucionDocsViewFilteredPerfil => 'Filtrado (perfil)';

  @override
  String get institucionDocsViewFilteredOwner => 'Filtrado (owner)';

  @override
  String institucionDocsInstitutionIdLine(Object id) {
    return 'Institución: $id';
  }

  @override
  String institucionDocsInstitutionOwnerLine(Object owner) {
    return 'Owner: $owner';
  }

  @override
  String get institucionDocsFieldOwnerAlumnoLabel => 'Owner del alumno';

  @override
  String get institucionDocsFieldPerfilAlumnoLabel => 'Perfil del alumno';

  @override
  String get institucionDocsFieldTipoDocumentoLabel => 'Tipo de documento';

  @override
  String get institucionDocsFieldMensajeOpcionalLabel => 'Mensaje (opcional)';

  @override
  String get institucionDocsFieldRefLabel => 'Referencia';

  @override
  String get institucionDocsFieldTtlDaysLabel => 'TTL (días)';

  @override
  String get institucionDocsActionSimulateUpload => 'Simular subida';

  @override
  String get institucionDocsActionCleanupExpired => 'Limpiar expirados';

  @override
  String get institucionDocsEmptySolicitudes => 'Sin solicitudes.';

  @override
  String get institucionDocsEmptyDocumentos => 'Sin documentos.';

  @override
  String institucionDocsSolicitudTipoLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String institucionDocsSolicitudSubtitle(Object estado, Object fecha) {
    return '$estado · $fecha';
  }

  @override
  String institucionDocsDocumentoTipoLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String institucionDocsDocumentoSubtitle(Object estado, Object vence) {
    return '$estado · $vence';
  }

  @override
  String institucionDocsAppBarTitle(Object institucion) {
    return '$institucion – Documentación';
  }

  @override
  String get tabSolicitudes => 'Solicitudes';

  @override
  String get tabDocumentos => 'Documentos';

  @override
  String get institucionDocsErrorTimeout =>
      'Tiempo de espera agotado. Intentá nuevamente.';

  @override
  String get institucionExtracGrupoGuiaBloqueTitle => 'Guía del bloque';

  @override
  String get institucionExtracGrupoInvalidInstitutionId =>
      'Institución inválida.';

  @override
  String institucionExtracGrupoWarnModuleKeyMismatch(Object expected) {
    return 'moduleKey no coincide con la esperada: $expected';
  }

  @override
  String institucionExtracGrupoWarnModuleKeyNotCanonical(Object value) {
    return 'moduleKey no canónica: $value';
  }

  @override
  String institucionExtracGrupoSaveFailed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get institucionExtracGrupoEditTitle => 'Editar grupo';

  @override
  String get institucionExtracGrupoCreateTitle => 'Crear grupo';

  @override
  String institucionExtracGrupoHeaderBloqueLine(
    Object bloque,
    Object moduleKey,
  ) {
    return 'Bloque: $bloque · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracGrupoHeaderNotePrototype =>
      'Prototipo (sin backend)';

  @override
  String institucionExtracGrupoWarnKeyMismatch(Object expected) {
    return 'Clave no coincide con la esperada: $expected';
  }

  @override
  String institucionExtracGrupoWarnKeyNotCanonical(Object value) {
    return 'Clave no canónica: $value';
  }

  @override
  String get institucionExtracGrupoFieldActividadLabel => 'Actividad';

  @override
  String get institucionExtracGrupoFieldActividadHint => 'ej.: Fútbol';

  @override
  String get institucionExtracGrupoValActividadRequired =>
      'Actividad es obligatoria';

  @override
  String get institucionExtracGrupoFieldGrupoLabel => 'Grupo';

  @override
  String get institucionExtracGrupoFieldGrupoHint => 'ej.: Grupo A';

  @override
  String get institucionExtracGrupoValGrupoRequired => 'Grupo es obligatorio';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalLabel =>
      'Turno (opcional)';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalHint => 'ej.: Mañana';

  @override
  String get institucionExtracGrupoFieldAulaOptionalLabel => 'Aula (opcional)';

  @override
  String get institucionExtracGrupoFieldAulaOptionalHint => 'ej.: Gimnasio';

  @override
  String get institucionExtracGrupoFieldCupoMaxLabel => 'Capacidad máxima';

  @override
  String get institucionExtracGrupoFieldCupoMaxHint => 'ej.: 25';

  @override
  String get institucionExtracGrupoFieldCupoOcupadoLabel => 'Ocupadas';

  @override
  String get institucionExtracGrupoValOccExceedsMax =>
      'Ocupadas no puede exceder el máximo';

  @override
  String get institucionExtracGrupoFieldActivoTitle => 'Activo';

  @override
  String get institucionExtracGrupoFieldActivoSubtitle => 'Permite solicitudes';

  @override
  String get institucionExtracBaseErrInvalidInstId => 'Institución inválida.';

  @override
  String get institucionExtracBaseErrInvalidModuleKeySnake =>
      'moduleKey inválida (snake_case).';

  @override
  String institucionExtracBaseErrModuleKeyMismatch(Object expected) {
    return 'moduleKey no coincide con la esperada: $expected';
  }

  @override
  String institucionExtracBaseErrModuleKeyNotCanonical(Object value) {
    return 'moduleKey no canónica: $value';
  }

  @override
  String get institucionExtracBaseCuposNotManaged =>
      'Capacidades no gestionadas';

  @override
  String institucionExtracBaseCuposManaged(Object disp, Object max) {
    return 'Disponibles: $disp de $max';
  }

  @override
  String get institucionExtracBaseInvalidDataGeneric => 'Datos inválidos.';

  @override
  String get institucionExtracBaseInvalidDataForCupos =>
      'Datos inválidos para capacidades.';

  @override
  String get institucionExtracBaseCuposRequireMax =>
      'Capacidad máxima es obligatoria.';

  @override
  String get institucionExtracBaseCuposDialogTitle => 'Editar capacidades';

  @override
  String institucionExtracBaseCuposDialogActividad(Object actividad) {
    return 'Actividad: $actividad';
  }

  @override
  String institucionExtracBaseCuposDialogGrupo(Object grupo) {
    return 'Grupo: $grupo';
  }

  @override
  String institucionExtracBaseCuposDialogMax(Object max) {
    return 'Máx: $max';
  }

  @override
  String institucionExtracBaseCuposDialogOcupado(Object ocupado) {
    return 'Ocupadas: $ocupado';
  }

  @override
  String institucionExtracBaseCuposDialogDisponibles(Object disp) {
    return 'Disponibles: $disp';
  }

  @override
  String get institucionExtracBaseCuposUpdated => 'Capacidades actualizadas.';

  @override
  String institucionExtracBaseCuposSaveFailed(Object error) {
    return 'No se pudo guardar capacidades: $error';
  }

  @override
  String get institucionExtracBaseInvalidDataForDelete =>
      'No se puede eliminar: datos inválidos.';

  @override
  String get institucionExtracBaseDeleteDialogTitle => 'Eliminar grupo';

  @override
  String institucionExtracBaseDeleteDialogBody(Object actividad, Object grupo) {
    return '¿Eliminar $actividad ($grupo)?';
  }

  @override
  String get institucionExtracBaseDeletedOk => 'Eliminado.';

  @override
  String institucionExtracBaseDeleteFailed(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String institucionExtracBaseAppBarTitle(Object module) {
    return '$module';
  }

  @override
  String institucionExtracBaseChipModuleKey(Object key) {
    return 'moduleKey: $key';
  }

  @override
  String institucionExtracBaseChipInstId(Object id) {
    return 'Institución: $id';
  }

  @override
  String get institucionExtracBaseHeaderNote =>
      'Gestión del módulo (prototipo)';

  @override
  String get institucionExtracBaseQuickGuideTitle => 'Guía rápida';

  @override
  String get institucionExtracBaseQuickGuideEmpty => 'No hay guía disponible.';

  @override
  String get institucionExtracBaseQuickGuideFootnote =>
      'Los textos pueden cambiar.';

  @override
  String get institucionExtracBaseGroupsTitle => 'Grupos';

  @override
  String get institucionExtracBaseInvalidDataToList =>
      'No se puede listar: datos inválidos.';

  @override
  String get institucionExtracBaseLoadFailed => 'No se pudo cargar.';

  @override
  String get institucionExtracBaseNoGroupsYet => 'Todavía no hay grupos.';

  @override
  String get institucionExtracBaseWithCupos => 'Con capacidades';

  @override
  String get institucionExtracBaseNoCupos => 'Sin capacidades';

  @override
  String institucionExtracBaseGroupLine(Object group) {
    return 'Grupo: $group';
  }

  @override
  String institucionExtracBaseTurnoLine(Object turno) {
    return 'Turno: $turno';
  }

  @override
  String institucionExtracBaseAulaLine(Object aula) {
    return 'Aula: $aula';
  }

  @override
  String get institucionExtracBaseActionCupos => 'Capacidades';

  @override
  String get institucionExtracBaseCreateGroupTitle => 'Crear grupo';

  @override
  String get institucionExtracBaseCreateGroupSubtitle =>
      'Agregar un nuevo grupo';

  @override
  String get institucionExtracBaseRulesTitle => 'Reglas';

  @override
  String get institucionExtracBaseRulesSubtitle => 'Pendiente';

  @override
  String institucionExtracBaseRulesPendingToast(Object value) {
    return 'Reglas pendientes: $value';
  }

  @override
  String get institucionExtracBaseSolicitudesTitle => 'Solicitudes';

  @override
  String institucionExtracBaseSolicitudesSubtitle(Object moduleKey) {
    return 'Ver solicitudes del módulo: $moduleKey';
  }

  @override
  String get institucionExtracHubTitle => 'Extracurricular';

  @override
  String institucionExtracHubHeaderInstOk(Object instIdCanon) {
    return 'Institución: $instIdCanon';
  }

  @override
  String get institucionExtracHubHeaderInstInvalid => 'Institución inválida.';

  @override
  String get institucionExtracHubIntro =>
      'Seleccioná un módulo para gestionar.';

  @override
  String get institucionExtracHubInvalidInstIdHelp =>
      'Volvé y reintentá con una institución válida.';

  @override
  String institucionExtracHubTileSubtitle(
    Object descripcion,
    Object moduleKey,
  ) {
    return '$descripcion · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracHubToastInvalidInstId => 'Institución inválida.';

  @override
  String institucionExtracHubToastInvalidModuleKey(Object bloque) {
    return 'No se pudo abrir el módulo: $bloque';
  }

  @override
  String errorLoadingGroups(Object error) {
    return 'Error al cargar grupos: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get occupiedRecalculatedOk => 'Ocupadas recalculadas.';

  @override
  String errorRecalculating(Object error) {
    return 'Error al recalcular: $error';
  }

  @override
  String get groupNameLabel => 'Nombre del grupo';

  @override
  String get activityLabelShort => 'Actividad';

  @override
  String get maxCapacityLabel => 'Capacidad máxima';

  @override
  String get completeRequiredFields => 'Completá los campos obligatorios.';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonNo => 'No';

  @override
  String get commonNone => 'Ninguno';

  @override
  String get commonProfile => 'Perfil';

  @override
  String get commonModule => 'Módulo';

  @override
  String get commonPending => 'Pendiente';

  @override
  String get commonCompleted => 'Cumplida';

  @override
  String get commonCancelled => 'Cancelada';

  @override
  String get commonConfirmed => 'Confirmada';

  @override
  String get commonRejected => 'Rechazada';

  @override
  String get commonExpired => 'Expirado';

  @override
  String get commonActive => 'Activo';

  @override
  String get commonCurricular => 'Curricular';

  @override
  String get commonExtracurricular => 'Extracurricular';

  @override
  String get commonInstitution => 'Institución';

  @override
  String get commonType => 'Tipo';

  @override
  String get commonClassGroup => 'Curso/Grupo';

  @override
  String get commonShift => 'Turno';

  @override
  String get commonStatus => 'Estado';

  @override
  String get commonGenerating => 'Generando…';

  @override
  String commonErrorWithDetails(Object error) {
    return 'Error: $error';
  }

  @override
  String get alumnoDocumentosTitle => 'Documentación';

  @override
  String get alumnoDocumentosInvalidOwner => 'Owner inválido.';

  @override
  String get alumnoDocumentosInvalidPerfil => 'Perfil inválido.';

  @override
  String get alumnoDocumentosOwnerMismatchAutoscrollIgnored =>
      'Este deeplink pertenece a otra cuenta. Autoscroll ignorado.';

  @override
  String get alumnoDocumentosDeeplinkSolicitudNotFound =>
      'No se encontró la solicitud del deeplink.';

  @override
  String get alumnoDocumentosDeeplinkDocumentoNotFound =>
      'No se encontró el documento del deeplink.';

  @override
  String get alumnoDocumentosEmptySolicitudes => 'Sin solicitudes.';

  @override
  String get alumnoDocumentosEmptyDocumentos => 'Sin documentos.';

  @override
  String get alumnoDocumentosFieldMensaje => 'Mensaje';

  @override
  String get alumnoDocumentosFieldTipo => 'Tipo';

  @override
  String get alumnoDocumentosFieldId => 'ID';

  @override
  String get alumnoDocumentosFieldEstado => 'Estado';

  @override
  String get alumnoDocumentosFieldInstitucion => 'Institución';

  @override
  String get alumnoDocumentosFieldCreada => 'Creada';

  @override
  String get alumnoDocumentosFieldOwner => 'Owner';

  @override
  String get alumnoDocumentosFieldPerfil => 'Perfil';

  @override
  String get alumnoDocumentosFieldSubido => 'Subido';

  @override
  String get alumnoDocumentosFieldExpira => 'Expira';

  @override
  String get alumnoDocumentosExpiredWillBeDeletedOnClean =>
      'será eliminado al limpiar expirados';

  @override
  String get alumnoDocumentosFieldSolicitud => 'Solicitud';

  @override
  String get alumnoDocumentosFieldRef => 'Referencia';

  @override
  String get alumnoDocumentosNoExpiredToClean =>
      'No hay expirados para limpiar.';

  @override
  String alumnoDocumentosExpiredCleanedCount(Object count) {
    return 'Se limpiaron $count expirados.';
  }

  @override
  String get alumnoDocumentosDocExpiredUseClean =>
      'Este documento está expirado. Usá “Limpiar expirados”.';

  @override
  String get alumnoDocumentosExpiredTooltip => 'Expirado (usar limpieza)';

  @override
  String get alumnoDocumentosDeleteDocTitle => 'Eliminar documento';

  @override
  String alumnoDocumentosDeleteDocBody(Object id) {
    return '¿Eliminar documento $id?';
  }

  @override
  String get alumnoDocumentosDocDeleted => 'Documento eliminado.';

  @override
  String get alumnoDocumentosCleanExpired => 'Limpiar expirados';

  @override
  String get alumnoDocumentosTabSolicitudes => 'Solicitudes';

  @override
  String get alumnoDocumentosTabDocumentos => 'Documentos';

  @override
  String get alumnoMisSolicitudesTitleOwner => 'Mis solicitudes';

  @override
  String alumnoMisSolicitudesTitlePerfil(Object perfil) {
    return 'Solicitudes – $perfil';
  }

  @override
  String get alumnoMisSolicitudesInvalidOwner => 'Owner inválido.';

  @override
  String get alumnoMisSolicitudesInvalidPerfil => 'Perfil inválido.';

  @override
  String alumnoMisSolicitudesLoadError(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String get alumnoMisSolicitudesStatusCancelledYou => 'Cancelada por vos';

  @override
  String get alumnoMisSolicitudesStatusCancelledInstitution =>
      'Cancelada por la institución';

  @override
  String get alumnoMisSolicitudesNotPending =>
      'Esta solicitud ya no está pendiente.';

  @override
  String get alumnoMisSolicitudesCancelTitle => 'Cancelar solicitud';

  @override
  String get alumnoMisSolicitudesCancelBody =>
      '¿Querés cancelar esta solicitud?';

  @override
  String get alumnoMisSolicitudesCancelCta => 'Cancelar';

  @override
  String get alumnoMisSolicitudesCancelledOk => 'Solicitud cancelada.';

  @override
  String alumnoMisSolicitudesCancelError(Object error) {
    return 'No se pudo cancelar: $error';
  }

  @override
  String get alumnoMisSolicitudesDeleteTitle => 'Eliminar solicitud';

  @override
  String get alumnoMisSolicitudesDeleteBody =>
      '¿Querés eliminar esta solicitud? (solo curricular pendiente)';

  @override
  String get alumnoMisSolicitudesDeletedOk => 'Solicitud eliminada.';

  @override
  String get alumnoMisSolicitudesCanonicalContextMissing =>
      'Falta contexto canónico (owner/perfil) para generar el PDF.';

  @override
  String alumnoMisSolicitudesPdfGenerated(Object path) {
    return 'PDF generado: $path';
  }

  @override
  String alumnoMisSolicitudesPdfError(Object error) {
    return 'No se pudo generar el PDF: $error';
  }

  @override
  String get alumnoMisSolicitudesDownloadPdf => 'Descargar PDF';

  @override
  String alumnoMisSolicitudesTabPendingCount(Object count) {
    return 'Pendientes ($count)';
  }

  @override
  String alumnoMisSolicitudesTabConfirmedCount(Object count) {
    return 'Confirmadas ($count)';
  }

  @override
  String alumnoMisSolicitudesTabRejectedCount(Object count) {
    return 'Rechazadas ($count)';
  }

  @override
  String alumnoMisSolicitudesTabCancelledCount(Object count) {
    return 'Canceladas ($count)';
  }

  @override
  String get alumnoMisSolicitudesEmptySection =>
      'No hay solicitudes en esta sección.';

  @override
  String get alumnoMisSolicitudesEmptyPending =>
      'No tenés solicitudes pendientes.';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonGenericError => 'Error.';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailRequired => 'Ingresá tu email.';

  @override
  String get commonEmailInvalid => 'Email inválido.';

  @override
  String get commonPassword => 'Contraseña';

  @override
  String get commonNewPassword => 'Nueva contraseña';

  @override
  String get commonConfirmPassword => 'Confirmar contraseña';

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
  String get commonRegister => 'Registrarse';

  @override
  String get commonPasswordMinLength4 =>
      'La contraseña debe tener al menos 4 caracteres.';

  @override
  String get commonCreateAccount => 'Crear cuenta';

  @override
  String get commonCreating => 'Creando…';

  @override
  String get commonFeatureUnavailablePrototype =>
      'Esta función no está disponible en este prototipo.';

  @override
  String get alumnoLoginAppBar => 'Acceso de alumnos';

  @override
  String get alumnoLoginTitle => 'Ingresar';

  @override
  String get alumnoLoginForgotPassword => 'Olvidé mi contraseña';

  @override
  String get alumnoLoginRegistroNoDisponible => 'Registro no disponible.';

  @override
  String get alumnoRegistroAppBar => 'Crear cuenta';

  @override
  String get alumnoRegistroTitle => 'Crear cuenta';

  @override
  String get alumnoRegistroPasswordRequired => 'Ingresá una contraseña.';

  @override
  String get alumnoForgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get alumnoForgotPasswordIntro =>
      'Ingresá tu email y elegí una nueva contraseña.';

  @override
  String get alumnoForgotPasswordEmailLabel => 'Email';

  @override
  String get alumnoForgotPasswordNewPasswordLabel => 'Nueva contraseña';

  @override
  String get alumnoForgotPasswordConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get alumnoForgotPasswordShowPassword => 'Mostrar contraseña';

  @override
  String get alumnoForgotPasswordHidePassword => 'Ocultar contraseña';

  @override
  String get alumnoForgotPasswordEnterEmailError => 'Ingresá tu email.';

  @override
  String get alumnoForgotPasswordInvalidEmailError => 'Email inválido.';

  @override
  String get alumnoForgotPasswordEnterPasswordError =>
      'Ingresá una contraseña.';

  @override
  String get alumnoForgotPasswordPasswordTooShortError =>
      'Contraseña muy corta.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatchError =>
      'Las contraseñas no coinciden.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatch =>
      'Las contraseñas no coinciden.';

  @override
  String get alumnoForgotPasswordAccountNotFound =>
      'No se encontró ninguna cuenta para este email.';

  @override
  String get alumnoForgotPasswordPasswordUpdatedPrototype =>
      'Contraseña actualizada (prototipo).';

  @override
  String get institucionForgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get institucionForgotPasswordIntro =>
      'Ingresá el email de la institución y elegí una nueva contraseña.';

  @override
  String get institucionForgotPasswordEnterEmailError => 'Ingresá el email.';

  @override
  String get institucionForgotPasswordInvalidEmailError => 'Email inválido.';

  @override
  String get institucionForgotPasswordEnterPasswordError =>
      'Ingresá una contraseña.';

  @override
  String get institucionForgotPasswordPasswordTooShortError =>
      'Contraseña muy corta.';

  @override
  String get institucionForgotPasswordPasswordsDontMatchError =>
      'Las contraseñas no coinciden.';

  @override
  String get institucionForgotPasswordAccountNotFound =>
      'No se encontró ninguna institución para este email.';

  @override
  String get institucionForgotPasswordPasswordUpdatedPrototype =>
      'Contraseña actualizada (prototipo).';

  @override
  String get invalidOwner => 'Owner inválido.';

  @override
  String get noNotifications => 'Sin notificaciones.';

  @override
  String get onlyUnread => 'Solo no leídas';

  @override
  String get showAll => 'Mostrar todas';

  @override
  String get allProfiles => 'Todos los perfiles';

  @override
  String get filterByProfile => 'Filtrar por perfil';

  @override
  String get filterForcedByCaller =>
      'Filtro forzado por la pantalla de origen (no modificable desde aquí).';

  @override
  String get clearPerfilFilter => 'Limpiar filtro de perfil';

  @override
  String get noResultsForFilter => 'Sin resultados para este filtro.';

  @override
  String get notificationDeleted => 'Notificación eliminada.';

  @override
  String get notificationNoDestination => 'Esta notificación no tiene destino.';

  @override
  String get invalidDeeplink => 'Deeplink inválido.';

  @override
  String get deeplinkOwnerMismatch => 'Este deeplink pertenece a otra cuenta.';

  @override
  String get missingPerfilIdForOpen =>
      'Falta perfilId para abrir este destino.';

  @override
  String deeplinkNotSupported(Object path) {
    return 'Deeplink no soportado: $path';
  }

  @override
  String notificationPerfilLine(Object perfil) {
    return 'Perfil: $perfil';
  }

  @override
  String get institucionAreaErrorEmptyId => 'ID de institución vacío.';

  @override
  String get alumnoGrupoExtraInvalidInstitution => 'Institución inválida.';

  @override
  String get alumnoGrupoExtraMissingOwnerPerfil =>
      'Falta contexto de sesión (owner/perfil).';

  @override
  String get alumnoGrupoExtraTitle => 'Grupos extracurriculares';

  @override
  String get alumnoGrupoExtraLoadErrorTitle => 'No se pudo cargar';

  @override
  String get alumnoGrupoExtraSearchHint => 'Buscar actividad o institución…';

  @override
  String get alumnoGrupoExtraBlockOptionalLabel => 'Bloque (opcional)';

  @override
  String get alumnoGrupoExtraEmptyFiltered =>
      'No se encontró ningún grupo para este filtro.';

  @override
  String get alumnoGrupoExtraCupoUnmanaged => 'Capacidades no gestionadas';

  @override
  String alumnoGrupoExtraOpenSolicitudError(Object error) {
    return 'No se pudo abrir Solicitudes: $error';
  }

  @override
  String alumnoGrupoExtraCupoManaged(Object disp, Object max) {
    return 'Disponibles: $disp de $max';
  }

  @override
  String alumnoGrupoExtraSemanticsItem(
    Object actividad,
    Object institucion,
    Object cupo,
  ) {
    return '$actividad · $institucion · $cupo';
  }

  @override
  String get commonYes => 'Sí';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonSearchHint => 'Buscar…';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRequired => 'Obligatorio';

  @override
  String get commonDeletePhotoTitle => 'Eliminar foto';

  @override
  String get commonDeletePhotoConfirm => '¿Querés eliminar esta foto?';

  @override
  String get commonNotificationsTooltip => 'Notificaciones';

  @override
  String get commonBackToProfiles => 'Volver a perfiles';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonPhoneLabel => 'Teléfono';

  @override
  String get commonChangePhoto => 'Cambiar foto';

  @override
  String get commonDeletePhoto => 'Eliminar foto';

  @override
  String get commonCalendar => 'Calendario';

  @override
  String get commonDocumentsPdf => 'Documentos (PDF)';

  @override
  String get commonStudentPdfSub => 'Ficha del alumno (PDF)';

  @override
  String get commonNotifications => 'Notificaciones';

  @override
  String get commonLogout => 'Cerrar sesión';

  @override
  String get commonPendingConnect => 'Pendiente de conexión';

  @override
  String get commonPasteRealScreenHint => 'Pegá la screen real aquí.';

  @override
  String get commonSelectDate => 'Seleccionar fecha';

  @override
  String get commonInvalidSessionAccountId =>
      'Sesión inválida para esta cuenta.';

  @override
  String get commonNameLabel => 'Nombre';

  @override
  String get commonEnterName => 'Ingresá tu nombre.';

  @override
  String get commonLastNameLabel => 'Apellido';

  @override
  String get commonEnterLastName => 'Ingresá tu apellido.';

  @override
  String get commonEmailOptionalLabel => 'Email (opcional)';

  @override
  String get commonInvalidEmail => 'Email inválido.';

  @override
  String get commonPhoneOptionalLabel => 'Teléfono (opcional)';

  @override
  String get commonSaveProfile => 'Guardar perfil';

  @override
  String get commonClear => 'Limpiar';

  @override
  String get commonAll => 'Todos';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonLoadMore => 'Cargar más';

  @override
  String get commonEndOfResults => 'Fin de resultados.';

  @override
  String get commonOwnerInvalid => 'Owner inválido.';

  @override
  String get commonPerfilInvalid => 'Perfil inválido.';

  @override
  String get commonDeleteTitle => 'Eliminar';

  @override
  String get commonEvent => 'Evento';

  @override
  String get commonPersonal => 'Personal';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonSpecialEvent => 'Evento especial';

  @override
  String get commonId => 'ID';

  @override
  String get commonMandatory => 'Obligatorio';

  @override
  String get commonDetail => 'Detalle';

  @override
  String get commonAttendance => 'Asistencia';

  @override
  String get commonAttendancePending => 'Pendiente';

  @override
  String get commonAttendanceYes => 'Sí';

  @override
  String get commonAttendanceMaybe => 'Quizás';

  @override
  String get commonAttendanceNo => 'No';

  @override
  String get commonPolicy => 'Política';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonMaybe => 'Quizás';

  @override
  String get commonDecline => 'Declinar';

  @override
  String get commonPrevMonth => 'Mes anterior';

  @override
  String get commonNextMonth => 'Mes siguiente';

  @override
  String get commonEvents => 'Eventos';

  @override
  String get commonAlarm => 'Alarma';

  @override
  String get commonNoTime => 'Sin horario';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonNew => 'Nuevo';

  @override
  String get commonTitle => 'Título';

  @override
  String get commonNoteOptional => 'Nota (opcional)';

  @override
  String get commonTime => 'Hora';

  @override
  String get commonChoose => 'Elegir';

  @override
  String get commonView => 'Ver';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonGroup => 'Grupo';

  @override
  String get commonInstitutionUnavailable => 'Institución no disponible.';

  @override
  String get commonRequestCreated => 'Solicitud creada.';

  @override
  String commonScheduleLabel(Object value) {
    return 'Horario: $value';
  }

  @override
  String commonAgeLabel(Object value) {
    return 'Edad: $value';
  }

  @override
  String commonSlotsLabel(Object value) {
    return 'Cupos: $value';
  }

  @override
  String commonProfileLabel(Object value) {
    return 'Perfil: $value';
  }

  @override
  String commonInstitutionLabel(Object value) {
    return 'Institución: $value';
  }

  @override
  String commonActivityLabel(Object value) {
    return 'Actividad: $value';
  }

  @override
  String commonTypeLabel(Object value) {
    return 'Tipo: $value';
  }

  @override
  String commonModuleKeyLabel(Object value) {
    return 'moduleKey: $value';
  }

  @override
  String commonAulaGrupoLabel(Object value) {
    return 'Aula/Grupo: $value';
  }

  @override
  String commonShiftOrScheduleLabel(Object value) {
    return 'Turno/Horario: $value';
  }

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonSending => 'Enviando…';

  @override
  String get commonRequestSentOk => 'Solicitud enviada.';

  @override
  String get commonError => 'Error.';

  @override
  String get commonCreate => 'Crear';

  @override
  String get commonFieldRequired => 'Campo obligatorio.';

  @override
  String get commonTooShort => 'Muy corto.';

  @override
  String get commonPhone => 'Teléfono';

  @override
  String get commonPhoneInvalid => 'Teléfono inválido.';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonContinuing => 'Continuando…';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonContinueToPlan => 'Continuar al plan';

  @override
  String get commonPasswordRequired => 'Ingresá una contraseña.';

  @override
  String get commonForgotPassword => 'Olvidé mi contraseña';

  @override
  String get commonLoggingIn => 'Ingresando…';

  @override
  String get commonLogin => 'Ingresar';

  @override
  String get commonDash => '—';

  @override
  String get alumnoAreaTitle => 'Área de alumno';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get alumnoPerfilInvalido => 'Perfil inválido.';

  @override
  String get alumnoBuscarInstituciones => 'Buscar instituciones';

  @override
  String get alumnoBuscarInstitucionesSub =>
      'Encontrá instituciones y actividades.';

  @override
  String get alumnoBuscarInstitucionesPlaceholderTitle => 'Búsqueda';

  @override
  String get alumnoBuscarPlaceholderEmpty => 'No hay resultados.';

  @override
  String alumnoBuscarPlaceholderQuery(Object query) {
    return 'Búsqueda: $query';
  }

  @override
  String get alumnoDashboardTitle => 'Inicio';

  @override
  String get alumnoDashboardMiDni => 'Mi DNI';

  @override
  String get alumnoDashboardMisSolicitudes => 'Mis solicitudes';

  @override
  String get alumnoDashboardMisSolicitudesSub =>
      'Ver el estado de tus solicitudes';

  @override
  String get alumnoDashboardBuscarInstituciones => 'Buscar instituciones';

  @override
  String get alumnoDashboardBuscarInstitucionesSub =>
      'Encontrá instituciones y actividades';

  @override
  String get alumnoDashboardCerrarSesionSub => 'Cerrar tu sesión actual';

  @override
  String get alumnoMisSolicitudesTitle => 'Mis solicitudes';

  @override
  String get alumnoBuscarInstitucionesTitle => 'Buscar instituciones';

  @override
  String get alumnoBuscarPlaceholderTitle => 'Buscar';

  @override
  String get alumnoMenuTitle => 'Menú';

  @override
  String get alumnoMenuHeader => 'ATENA';

  @override
  String get alumnoMenuBody => 'Elegí una opción para continuar.';

  @override
  String get alumnoMenuCtaLogin => 'Ingresar';

  @override
  String get alumnoFechaNacimientoNoFutura =>
      'La fecha de nacimiento no puede ser futura.';

  @override
  String get alumnoSeleccionaFechaNacimiento =>
      'Seleccioná tu fecha de nacimiento.';

  @override
  String get alumnoNoSePudoCrearPerfilPerfilIdVacio =>
      'No se pudo crear el perfil: perfilId vacío.';

  @override
  String get alumnoPerfilRegistroTitle => 'Registro de alumno';

  @override
  String get alumnoDocumentoDniLabel => 'DNI';

  @override
  String get alumnoIngresaDni => 'Ingresá tu DNI.';

  @override
  String get alumnoDniInvalidoRango => 'DNI inválido (rango).';

  @override
  String get alumnoFechaNacimientoPrefix => 'Fecha de nacimiento';

  @override
  String get alumnoBuscarExtracurricularesTitle => 'Buscar extracurriculares';

  @override
  String get alumnoBuscarExtracurricularesHint =>
      'Buscar actividad, institución o grupo…';

  @override
  String get alumnoBuscarExtracurricularesBloqueOpcional => 'Bloque (opcional)';

  @override
  String get alumnoBuscarExtracurricularesEmpty =>
      'No hay extracurriculares disponibles.';

  @override
  String alumnoBuscarExtracurricularesGruposConCupo(Object count) {
    return 'Grupos con cupo: $count';
  }

  @override
  String alumnoBuscarExtracurricularesErrorCargar(Object error) {
    return 'Error al cargar extracurriculares: $error';
  }

  @override
  String alumnoBuscarInstitucionesErrorCargar(Object error) {
    return 'Error al cargar instituciones: $error';
  }

  @override
  String alumnoBuscarInstitucionesErrorCargarMas(Object error) {
    return 'Error al cargar más: $error';
  }

  @override
  String get alumnoBuscarInstitucionesExtraEnConstruccion =>
      'Extracurriculares (en construcción)';

  @override
  String get alumnoBuscarInstitucionesExtraAll => 'Todos';

  @override
  String alumnoBuscarInstitucionesExtraSelected(Object value) {
    return 'Seleccionado: $value';
  }

  @override
  String get alumnoBuscarInstitucionesFiltroExtraTitle =>
      'Filtro extracurricular';

  @override
  String get alumnoBuscarInstitucionesNoHayInstituciones =>
      'No hay instituciones registradas.';

  @override
  String get alumnoBuscarInstitucionesNoResultadosConFiltro =>
      'No hay resultados para este filtro.';

  @override
  String get alumnoBuscarInstitucionesCurricularDisponible =>
      'Curricular disponible';

  @override
  String get alumnoBuscarInstitucionesCurricularNoDisponible =>
      'Curricular no disponible';

  @override
  String get alumnoBuscarInstitucionesExtraSinModulos =>
      'Sin módulos extracurriculares';

  @override
  String alumnoBuscarInstitucionesExtraConModulos(Object count) {
    return 'Módulos: $count';
  }

  @override
  String get alumnoBuscarInstitucionesExtraNoDisponible =>
      'Extracurricular no disponible';

  @override
  String get alumnoBuscarInstitucionesBtnCurricular => 'Curricular';

  @override
  String get alumnoBuscarInstitucionesBtnExtracurricular => 'Extracurricular';

  @override
  String get alumnoCalendarioEspecialInicioClases => 'Inicio de clases';

  @override
  String get alumnoCalendarioEspecialFinClases => 'Fin de clases';

  @override
  String get alumnoCalendarioEspecialReceso => 'Receso';

  @override
  String get alumnoCalendarioEspecialInicioCiclo => 'Inicio de ciclo';

  @override
  String get alumnoCalendarioEspecialFinCiclo => 'Fin de ciclo';

  @override
  String get alumnoCalendarioSnackNoDeclinar =>
      'No se puede declinar este evento.';

  @override
  String get alumnoCalendarioSnackAsistenciaConfirmada =>
      'Asistencia confirmada.';

  @override
  String get alumnoCalendarioSnackAsistenciaQuizas => 'Asistencia: quizás.';

  @override
  String get alumnoCalendarioSnackAsistenciaDeclinada =>
      'Asistencia declinada.';

  @override
  String alumnoCalendarioSnackNoGuardarRsvp(Object error) {
    return 'No se pudo guardar asistencia: $error';
  }

  @override
  String alumnoCalendarioSnackNoGuardarNota(Object error) {
    return 'No se pudo guardar nota: $error';
  }

  @override
  String alumnoCalendarioSnackNoActualizarNota(Object error) {
    return 'No se pudo actualizar nota: $error';
  }

  @override
  String get alumnoCalendarioEliminarConfirm => '¿Querés eliminar este evento?';

  @override
  String alumnoCalendarioSnackNoEliminarNota(Object error) {
    return 'No se pudo eliminar nota: $error';
  }

  @override
  String get alumnoCalendarioNoRequiereAsistencia =>
      'Este evento no requiere asistencia.';

  @override
  String get alumnoCalendarioNotaCanonica => 'Nota canónica';

  @override
  String get alumnoCalendarioTitle => 'Calendario';

  @override
  String get alumnoCalendarioFabNotaAlarma => 'Nota / Alarma';

  @override
  String get alumnoCalendarioNoEventosDia => 'No hay eventos para este día.';

  @override
  String get alumnoCalendarioConfirmarAsistencia => 'Confirmar asistencia';

  @override
  String get alumnoCalendarioDialogNotaAlarma => 'Nota y alarma';

  @override
  String get alumnoCalendarioDialogIngresarTitulo => 'Ingresá un título';

  @override
  String get alumnoCalendarioDialogAlarmaLocal => 'Alarma local';

  @override
  String get alumnoCalendarioDialogAlarmaLocalDesc =>
      'Se guardará solo en este dispositivo.';

  @override
  String get alumnoCalendarioDialogAvisoNotificacion => 'Aviso: notificación';

  @override
  String get alumnoNotificacionesDeleteOneTitle => 'Eliminar notificación';

  @override
  String get alumnoNotificacionesDeleteOneBody =>
      '¿Querés eliminar esta notificación?';

  @override
  String get alumnoNotificacionesDeleteAllTitle => 'Eliminar todas';

  @override
  String get alumnoNotificacionesDeleteAllBody =>
      '¿Querés eliminar todas las notificaciones?';

  @override
  String get alumnoNotificacionesDeleteAllCta => 'Eliminar todas';

  @override
  String get alumnoNotificacionesDeleteAllFailed => 'No se pudo eliminar todo.';

  @override
  String get alumnoNotificacionesActionOpenDocumentos => 'Abrir Documentación';

  @override
  String get alumnoNotificacionesActionOpenCalendario => 'Abrir Calendario';

  @override
  String get alumnoNotificacionesActionOpenBoletines => 'Abrir Boletines';

  @override
  String get alumnoNotificacionesActionOpenBecas => 'Abrir Becas';

  @override
  String get alumnoNotificacionesActionOpenConvivencia => 'Abrir Convivencia';

  @override
  String get alumnoNotificacionesActionOpenEquivalencias =>
      'Abrir Equivalencias';

  @override
  String get alumnoNotificacionesActionViewDetail => 'Ver detalle';

  @override
  String get alumnoNotificacionesSectionNotReady =>
      'Sección no disponible todavía.';

  @override
  String alumnoNotificacionesDialogActionLine(Object value) {
    return 'Acción: $value';
  }

  @override
  String alumnoNotificacionesDialogProfileLine(Object value) {
    return 'Perfil: $value';
  }

  @override
  String alumnoNotificacionesDialogDateLine(Object value) {
    return 'Fecha: $value';
  }

  @override
  String alumnoNotificacionesDialogDeeplinkLine(Object value) {
    return 'Deeplink: $value';
  }

  @override
  String get alumnoNotificacionesTitle => 'Notificaciones';

  @override
  String alumnoNotificacionesTitleWithUnread(Object count) {
    return 'Notificaciones ($count sin leer)';
  }

  @override
  String get alumnoNotificacionesDeleteAllTooltip => 'Eliminar todas';

  @override
  String get alumnoNotificacionesNoOwnerBody =>
      'Se requiere sesión activa para ver notificaciones.';

  @override
  String get alumnoNotificacionesEmptyTitle => 'Sin notificaciones';

  @override
  String get alumnoNotificacionesEmptyBody =>
      'No hay notificaciones disponibles.';

  @override
  String get alumnoNotificacionesMarkRead => 'Marcar como leída';

  @override
  String get alumnoNotificacionesMarkUnread => 'Marcar como no leída';

  @override
  String get alumnoNotificacionesFilterStatusLabel => 'Estado';

  @override
  String get alumnoNotificacionesFilterTypeLabel => 'Tipo';

  @override
  String alumnoNotificacionesShowingCount(Object count) {
    return 'Mostrando: $count';
  }

  @override
  String alumnoNotificacionesShowingCountWithPerfil(
    Object count,
    Object perfil,
  ) {
    return 'Mostrando: $count · Perfil: $perfil';
  }

  @override
  String get alumnoPdfsInvalidPerfil => 'Perfil inválido.';

  @override
  String alumnoPdfsSavedPath(Object path) {
    return 'Guardado en: $path';
  }

  @override
  String get alumnoPdfsTitle => 'PDFs';

  @override
  String get alumnoPdfsFichaTitle => 'Ficha';

  @override
  String alumnoPdfsPerfilId(Object perfilId) {
    return 'Perfil: $perfilId';
  }

  @override
  String get alumnoPdfsCroquisTitle => 'Croquis';

  @override
  String get alumnoPdfsCroquisPlaceholder => 'Croquis no disponible.';

  @override
  String get alumnoSeleccionGrupoInstitutionLoadFailed =>
      'No se pudo cargar la institución.';

  @override
  String alumnoSeleccionGrupoLoadError(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String alumnoSeleccionGrupoExtraLoadError(Object error) {
    return 'Error al cargar extracurriculares: $error';
  }

  @override
  String get alumnoSeleccionGrupoPickCourseAndShift =>
      'Elegí curso/grupo y turno.';

  @override
  String get alumnoSeleccionGrupoPickExtraActivity =>
      'Elegí una actividad extracurricular.';

  @override
  String get alumnoSeleccionGrupoExtraNoSlots => 'No hay cupos disponibles.';

  @override
  String get alumnoSeleccionGrupoNoSlotsShort => 'Sin cupos';

  @override
  String get alumnoSeleccionGrupoNoSlots => 'No hay cupos disponibles.';

  @override
  String get alumnoSeleccionGrupoExtraFilterByBlock => 'Filtrar por bloque';

  @override
  String get alumnoSeleccionGrupoExtraEmpty =>
      'No hay resultados para este filtro.';

  @override
  String get alumnoSeleccionGrupoModeCurricular => 'Curricular';

  @override
  String get alumnoSeleccionGrupoModeExtracurricular => 'Extracurricular';

  @override
  String alumnoSeleccionGrupoTitle(Object mode) {
    return 'Seleccionar grupo – $mode';
  }

  @override
  String get alumnoSeleccionGrupoExtraRefresh => 'Actualizar';

  @override
  String get alumnoSeleccionGrupoCtaCurricular => 'Continuar (curricular)';

  @override
  String get alumnoSeleccionGrupoCtaExtracurricular =>
      'Continuar (extracurricular)';

  @override
  String get alumnoSolicitarVacanteMissingOwnerPerfil =>
      'Falta contexto de sesión (owner/perfil).';

  @override
  String get alumnoSolicitarVacanteInvalidInstitution =>
      'Institución inválida.';

  @override
  String get alumnoSolicitarVacanteInvalidActivity => 'Actividad inválida.';

  @override
  String get alumnoSolicitarVacanteCurricularRequiresAula =>
      'Curricular requiere aula/grupo.';

  @override
  String get alumnoSolicitarVacanteConfirmTitle => 'Confirmar solicitud';

  @override
  String get alumnoSolicitarVacanteTypeCurricular => 'Curricular';

  @override
  String get alumnoSolicitarVacanteTypeExtracurricular => 'Extracurricular';

  @override
  String get alumnoSolicitarVacanteTitle => 'Solicitar vacante';

  @override
  String alumnoSolicitarVacanteSummarySemantics(Object value) {
    return 'Resumen: $value';
  }

  @override
  String get alumnoSolicitarVacanteSendCta => 'Enviar solicitud';

  @override
  String get institucionLoginBadCredentials => 'Credenciales incorrectas.';

  @override
  String get institucionLoginInvalidInstitutionId =>
      'ID de institución inválido.';

  @override
  String get institucionLoginTitle => 'Ingresar';

  @override
  String get institucionLoginAppBar => 'Acceso de institución';

  @override
  String get institucionRegistroPickAtLeastOneModule =>
      'Seleccioná al menos un módulo.';

  @override
  String get institucionRegistroAppBar => 'Registro de institución';

  @override
  String get institucionRegistroIntro =>
      'Completá los datos para registrar la institución.';

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
  String get institucionRegistroSectionConfig => 'Configuración';

  @override
  String get institucionRegistroInstitutionType => 'Tipo de institución';

  @override
  String get institucionRegistroModality => 'Modalidad';

  @override
  String get institucionRegistroSectionModules => 'Módulos';

  @override
  String get institucionRegistroCurricularSubtitle =>
      'Seleccioná niveles curriculares';

  @override
  String institucionRegistroCurricularChipSemantics(Object value) {
    return 'Nivel curricular: $value';
  }

  @override
  String get institucionRegistroExtracurricularSubtitle =>
      'Seleccioná bloques extracurriculares';

  @override
  String institucionRegistroExtracurricularChipSemantics(Object value) {
    return 'Bloque extracurricular: $value';
  }

  @override
  String get cuentaHomeDeeplinkOwnerMismatch =>
      'Este deeplink pertenece a otra cuenta.';

  @override
  String get cuentaHomeDeeplinkAlumnoRequired =>
      'Se requiere un perfil de alumno para este deeplink.';

  @override
  String get cuentaHomeDestinoCalendario => 'Calendario';

  @override
  String get cuentaHomeDestinoDocumentos => 'Documentación';

  @override
  String cuentaHomeDeeplinkMissingPerfilId(Object path) {
    return 'Falta perfilId para abrir este deeplink: $path';
  }

  @override
  String get cuentaHomeCrearInstitucionTitle => 'Crear institución';

  @override
  String get cuentaHomeCrearInstitucionNombreLabel => 'Nombre';

  @override
  String get cuentaHomeCrearInstitucionNombreRequired => 'Ingresá el nombre.';

  @override
  String get cuentaHomeCrearInstitucionEmailLabel => 'Email';

  @override
  String get cuentaHomeCrearInstitucionEmailRequired => 'Ingresá el email.';

  @override
  String get cuentaHomeCrearInstitucionTelefonoLabel => 'Teléfono';

  @override
  String get cuentaHomeCrearInstitucionTelefonoRequired =>
      'Ingresá el teléfono.';

  @override
  String get cuentaHomeCrearPerfilTitle => 'Crear perfil';

  @override
  String get cuentaHomeTipoAlumno => 'Alumno';

  @override
  String get cuentaHomeTipoInstitucion => 'Institución';

  @override
  String get cuentaHomeContinuarUltimoPerfil =>
      'Continuar con el último perfil';

  @override
  String get cuentaHomeTitle => 'Cuenta';

  @override
  String get cuentaHomeRedirectingInstitution => 'Redirigiendo a institución…';

  @override
  String get cuentaHomePreparingInstitution => 'Preparando institución…';

  @override
  String get cuentaHomeCreateProfileCta => 'Crear perfil';

  @override
  String cuentaHomeAccountLine(Object ownerId) {
    return 'Cuenta: $ownerId';
  }

  @override
  String get cuentaHomeNoProfiles => 'Todavía no hay perfiles.';

  @override
  String get cuentaHomeInstitutionsSection => 'Instituciones';

  @override
  String cuentaHomeInstitutionIdLine(Object id) {
    return 'Institución: $id';
  }

  @override
  String get cuentaHomeStudentsSection => 'Alumnos';

  @override
  String get cuentaHomeNoStudents => 'Todavía no hay alumnos.';

  @override
  String cuentaHomeStudentDniLine(Object dni) {
    return 'DNI: $dni';
  }

  @override
  String get commonPreview => 'Vista previa';

  @override
  String get alumnoBuscarInstitucionesHint => 'Buscar institución o actividad…';

  @override
  String get commonMon => 'Lun';

  @override
  String get commonTue => 'Mar';

  @override
  String get commonWed => 'Mié';

  @override
  String get commonThu => 'Jue';

  @override
  String get commonFri => 'Vie';

  @override
  String get commonSat => 'Sáb';

  @override
  String get commonSun => 'Dom';

  @override
  String get commonInvalidSession => 'Sesión inválida.';

  @override
  String get commonUnread => 'No leída';

  @override
  String get commonRead => 'Leída';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonShiftMorning => 'Mañana';

  @override
  String get commonShiftAfternoon => 'Tarde';

  @override
  String get commonShiftNight => 'Noche';

  @override
  String alumnoSeleccionGrupoOpenSolicitudError(Object error) {
    return 'No se pudo abrir Solicitudes: $error';
  }

  @override
  String alumnoSeleccionGrupoSlotsAvailable(Object count) {
    return 'Cupos disponibles: $count';
  }

  @override
  String get institucionAreaSemanticsCroquisLocked => 'Croquis no disponible';

  @override
  String get institucionPlanBillingTitle => 'Facturación y cobro';

  @override
  String get institucionPlanBillingSubtitle =>
      'Cómo funciona el cobro en ATENA (fase 2)';

  @override
  String get institucionPlanBillingIntro =>
      'Antes de confirmar, tené en cuenta lo siguiente:';

  @override
  String get institucionPlanBillingPoint1 =>
      'ATENA solo cobra a instituciones (no a alumnos).';

  @override
  String get institucionPlanBillingPoint2 =>
      'En fase 2 no hay cobros reales: la confirmación es local/prototipo.';

  @override
  String get institucionPlanBillingPoint3 =>
      'El plan habilita niveles y módulos; podés cambiarlo más adelante.';

  @override
  String get institucionPlanBillingPoint4 =>
      'Las instituciones pueden administrar sus perfiles de trabajo por actividad sin compartir credenciales.';

  @override
  String get institucionPlanBillingPoint5 =>
      'Cuando integremos pagos reales, se aplicarán términos, facturación y políticas de reembolso según la configuración final.';

  @override
  String institutionProfileTitle(Object name) {
    return 'Perfil de institución – $name';
  }

  @override
  String institutionProfileLoadError(Object error) {
    return 'No se pudo cargar el perfil: $error';
  }

  @override
  String institutionProfileSaveError(Object error) {
    return 'No se pudo guardar el perfil: $error';
  }

  @override
  String get institutionProfileSectionIdentity => 'Identidad';

  @override
  String get institutionProfileSectionContact => 'Contacto';

  @override
  String get institutionProfileSectionLocation => 'Ubicación';

  @override
  String get institutionProfileSectionSettings => 'Configuración';

  @override
  String get institutionProfileFieldName => 'Nombre';

  @override
  String get institutionProfileFieldCuit => 'CUIT';

  @override
  String get institutionProfileFieldEmail => 'Email';

  @override
  String get institutionProfileFieldPhone => 'Teléfono';

  @override
  String get institutionProfileFieldAddress => 'Dirección';

  @override
  String get institutionProfileFieldCountry => 'País';

  @override
  String get institutionProfileFieldProvince => 'Provincia';

  @override
  String get institutionProfileFieldCity => 'Ciudad';

  @override
  String get institutionProfileFieldModalidad => 'Modalidad';

  @override
  String get institutionProfileFieldType => 'Tipo de institución';

  @override
  String get institutionProfileFieldCurricular => 'Curricular';

  @override
  String get institutionProfileFieldExtracurricular => 'Extracurricular';

  @override
  String institutionProfileModalidadLabel(Object key) {
    return '$key';
  }

  @override
  String institutionProfileTipoLabel(Object key) {
    return '$key';
  }

  @override
  String get commonFixErrors => 'Corregí los errores del formulario.';

  @override
  String get commonRequiredField => 'Campo obligatorio.';

  @override
  String get commonSaved => 'Guardado.';

  @override
  String get saved => 'Guardado.';

  @override
  String get primeroSeleccionaUnaActividad =>
      'Primero seleccioná una actividad';

  @override
  String get losPerfilesDeTrabajoSonInternos =>
      'Los perfiles de trabajo son internos';

  @override
  String get perfilesDeTrabajo => 'Perfiles de trabajo';

  @override
  String get entrar => 'Entrar';

  @override
  String get bloqueadoPorVos => 'Bloqueado por vos';

  @override
  String get bloqueado => 'Bloqueado';

  @override
  String bloqueadoPor(Object who) {
    return 'Bloqueado por $who';
  }

  @override
  String get seleccionarActividad => 'Seleccionar actividad';

  @override
  String get noHayActividadesHabilitadas =>
      'Todavía no hay actividades configuradas';

  @override
  String institutionPublicProfileTitle(Object name) {
    return 'Perfil público – $name';
  }

  @override
  String get institutionPublicProfileSectionOverview => 'Presentación';

  @override
  String get institutionPublicProfileSectionServices => 'Servicios';

  @override
  String get institutionPublicProfileSectionCourses => 'Cursos';

  @override
  String get institutionPublicProfileSectionAdminHours =>
      'Horarios de atención';

  @override
  String get institutionPublicProfileSectionOnline => 'Web y redes';

  @override
  String get institutionPublicProfileSectionPhotos => 'Fotos';

  @override
  String get institutionPublicProfileAboutLabel => 'Descripción';

  @override
  String get institutionPublicProfileAboutHint =>
      'Contá brevemente qué ofrece la institución (máx. 500 caracteres).';

  @override
  String get institutionPublicProfileServicesLabel => 'Servicios';

  @override
  String get institutionPublicProfileServicesHint =>
      'ej.: apoyo escolar, talleres, comedor, transporte…';

  @override
  String get institutionPublicProfileAddService => 'Agregar servicio';

  @override
  String get institutionPublicProfileServiceNameLabel => 'Servicio';

  @override
  String get institutionPublicProfileServiceNameHint => 'ej.: Apoyo escolar';

  @override
  String get institutionPublicProfileServiceInvalid => 'Servicio inválido.';

  @override
  String get institutionPublicProfileShortCoursesLabel =>
      'Ofrece cursos cortos';

  @override
  String get institutionPublicProfileCourseDurationLabel =>
      'Duración (opcional)';

  @override
  String get institutionPublicProfileCourseDurationHint =>
      'ej.: 4 semanas / 2 meses';

  @override
  String get institutionPublicProfileCourseDurationInvalid =>
      'Duración inválida.';

  @override
  String get institutionPublicProfileTeachingModeLabel => 'Tipo de cursado';

  @override
  String get institutionPublicProfileTeachingModePresencial => 'Presencial';

  @override
  String get institutionPublicProfileTeachingModeRemoto => 'A distancia';

  @override
  String get institutionPublicProfileTeachingModeHibrido => 'Híbrido';

  @override
  String get institutionPublicProfileAdminHoursLabel =>
      'Horario de atención administrativa';

  @override
  String get institutionPublicProfileAdminHoursHint =>
      'ej.: Lun a Vie 9:00 a 17:00';

  @override
  String get institutionPublicProfilePhoneOptionalLabel =>
      'Teléfono (opcional)';

  @override
  String get institutionPublicProfileWebsiteLabel => 'Página web (opcional)';

  @override
  String get institutionPublicProfileWebsiteHint => 'https://…';

  @override
  String get institutionPublicProfileWebsiteInvalid => 'URL inválida.';

  @override
  String get institutionPublicProfileInstagramLabel => 'Instagram (opcional)';

  @override
  String get institutionPublicProfileFacebookLabel => 'Facebook (opcional)';

  @override
  String get institutionPublicProfileXLabel => 'X / Twitter (opcional)';

  @override
  String get institutionPublicProfileYoutubeLabel => 'YouTube (opcional)';

  @override
  String get institutionPublicProfileTiktokLabel => 'TikTok (opcional)';

  @override
  String get institutionPublicProfileLinkedinLabel => 'LinkedIn (opcional)';

  @override
  String get institutionPublicProfileOtherLinkLabel => 'Otro link (opcional)';

  @override
  String get institutionPublicProfilePricesLabel => 'Precios (opcional)';

  @override
  String get institutionPublicProfilePricesHint =>
      'ej.: desde \$… / rango / consultar';

  @override
  String get institutionPublicProfilePricesTooLong => 'Texto demasiado largo.';

  @override
  String institutionPublicProfilePhotosLabel(Object max) {
    return 'Galería (hasta $max)';
  }

  @override
  String get institutionPublicProfileAddPhoto => 'Agregar foto';

  @override
  String get institutionPublicProfileChangePhoto => 'Cambiar foto';

  @override
  String get institutionPublicProfileRemovePhoto => 'Eliminar foto';

  @override
  String institutionPublicProfilePhotoLimitReached(Object max) {
    return 'Ya cargaste el máximo de fotos ($max).';
  }

  @override
  String get institutionPublicProfileNoPhotosYet => 'Todavía no hay fotos.';

  @override
  String institutionPublicProfilePickPhotoError(Object error) {
    return 'No se pudo cargar la foto: $error';
  }

  @override
  String get institutionPublicProfileSaveOk => 'Perfil guardado.';

  @override
  String institutionPublicProfileSaveFailed(Object error) {
    return 'No se pudo guardar el perfil: $error';
  }

  @override
  String get institucionGeneric => 'Institución';

  @override
  String get institucionExtracBaseEmitirFichaTitle => 'Emitir ficha';

  @override
  String institucionExtracBaseEmitirFichaSubtitle(Object group) {
    return 'Crear una ficha para $group y enviarla a alumnos/solicitudes.';
  }

  @override
  String get institucionExtracBaseEmitirFichaGrupoLabel => 'Grupo';

  @override
  String get institucionExtracBaseEmitirFichaTituloLabel => 'Título';

  @override
  String get institucionExtracBaseEmitirFichaTituloHint =>
      'ej.: Reunión informativa';

  @override
  String get institucionExtracBaseEmitirFichaContenidoLabel => 'Contenido';

  @override
  String get institucionExtracBaseEmitirFichaContenidoHint =>
      'Escribí el detalle de la ficha…';

  @override
  String get institucionExtracBaseEmitirFichaAddToCalendar =>
      'Agregar al calendario';

  @override
  String get institucionExtracBaseEmitirFichaAddToCalendarHelp =>
      'Si está activado, se crea un evento en el calendario del alumno.';

  @override
  String get institucionExtracBaseEmitirFichaRequireRsvp =>
      'Requiere confirmación';

  @override
  String get institucionExtracBaseEmitirFichaRequireRsvpHelp =>
      'Si está activado, el alumno podrá confirmar asistencia (sí / quizás / no).';

  @override
  String get institucionExtracBaseEmitirFichaDestinatariosTitle =>
      'Destinatarios';

  @override
  String get institucionExtracBaseEmitirFichaDestinatariosEmptyHelp =>
      'No hay destinatarios disponibles para este grupo.';

  @override
  String get institucionExtracBaseEmitirFichaManualLabel =>
      'Destinatarios manuales';

  @override
  String get institucionExtracBaseEmitirFichaManualHint =>
      'Ingresá uno o más documentos/IDs, separados por coma';

  @override
  String get actionSelectAll => 'Seleccionar todo';

  @override
  String get actionSelectNone => 'Seleccionar ninguno';

  @override
  String get actionEmit => 'Emitir';

  @override
  String institucionExtracBaseEmitirFichaDefaultTitle(Object module) {
    return 'Ficha – $module';
  }

  @override
  String get institucionExtracBaseEmitirFichaDefaultBody =>
      'Se generó una ficha para compartir información del grupo.';

  @override
  String get institucionExtracBaseEmitirFichaNoRecipients =>
      'No hay destinatarios seleccionados.';

  @override
  String get institucionExtracBaseEmitirFichaOk => 'Ficha emitida.';

  @override
  String get institucionExtracBaseEmitirFichaServiceMissing =>
      'Servicio no disponible.';

  @override
  String institucionExtracBaseEmitirFichaFailed(Object error) {
    return 'No se pudo emitir la ficha: $error';
  }

  @override
  String get institucionExtracBaseEmitirFichaBanner =>
      'Emití fichas como notificación y, opcionalmente, como evento de calendario.';

  @override
  String get institucionExtracBaseEmitirFichaCardTitle => 'Emitir ficha';

  @override
  String get institucionExtracBaseEmitirFichaCardSubtitle =>
      'Crear una ficha informativa para el grupo seleccionado';

  @override
  String get institucionExtracBaseOpenInboxCta => 'Abrir notificaciones';

  @override
  String get institucionExtracBaseEmitirFichaCardFootnote =>
      'Las fichas se guardan como notificación (prototipo).';

  @override
  String get send => 'Enviar';
}
