// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ATENA';

  @override
  String get alumnos => 'Students';

  @override
  String get instituciones => 'Institutions';

  @override
  String get institution => 'Institution';

  @override
  String get perfiles => 'Profiles';

  @override
  String get crearPerfil => 'Create profile';

  @override
  String get crearPerfilTitulo => 'Create a new profile';

  @override
  String get tipoAlumno => 'Student';

  @override
  String get tipoInstitucion => 'Institution';

  @override
  String get actualizar => 'Refresh';

  @override
  String get refresh => 'Refresh';

  @override
  String get update => 'Update';

  @override
  String get guardar => 'Save';

  @override
  String get save => 'Save';

  @override
  String get editar => 'Edit';

  @override
  String get edit => 'Edit';

  @override
  String get eliminar => 'Delete';

  @override
  String get delete => 'Delete';

  @override
  String get cancelar => 'Cancel';

  @override
  String get cancel => 'Cancel';

  @override
  String get continuar => 'Continue';

  @override
  String get continuarUltimoPerfil => 'Continue with the last profile';

  @override
  String get accept => 'Accept';

  @override
  String get confirm => 'Confirm';

  @override
  String get reject => 'Reject';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get open => 'Open';

  @override
  String get cuentaLabel => 'Account';

  @override
  String accountLabel(Object ownerId) {
    return 'Account: $ownerId';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInOrRegister => 'Sign in or register';

  @override
  String get accessInstitutionAccount => 'Access institution account';

  @override
  String get signInToEnableInstitutionFeatures =>
      'Sign in to enable institution features';

  @override
  String get errorGenerico => 'Error.';

  @override
  String get invalidSessionForThisAccount =>
      'Invalid session for this account.';

  @override
  String get cannotLoadInstitutionTryAgain =>
      'Could not load the institution. Please try again.';

  @override
  String get noPerfilesTodavia =>
      'No profiles yet.\nCreate one to get started.';

  @override
  String get noPerfilesAlumnoTodavia => 'No student profiles yet.';

  @override
  String get accionAlumnoSinPerfil =>
      'An action for Students was received, but this account has no Student profiles.';

  @override
  String get opcionNoDisponibleBuild =>
      'This option is not available in this build yet.';

  @override
  String get ingresarCrearCuenta => 'Sign in / Create account';

  @override
  String get accesoAlumnos => 'Student access';

  @override
  String get ingresaCuentaEligePerfil =>
      'Sign in with your account and choose a profile.';

  @override
  String get saving => 'Saving…';

  @override
  String get registering => 'Registering…';

  @override
  String get newLabel => 'New';

  @override
  String get modoOscuro => 'Dark mode';

  @override
  String get idioma => 'Language';

  @override
  String get sistema => 'System';

  @override
  String get espanol => 'Spanish';

  @override
  String get ingles => 'English';

  @override
  String get portugues => 'Portuguese';

  @override
  String get landingTitle => 'ATENA';

  @override
  String get landingIngresar => 'Sign in';

  @override
  String get landingStudents => 'Students';

  @override
  String get landingInstitutions => 'Institutions';

  @override
  String get landingHeadingStudents => 'students';

  @override
  String get landingHeadingInstitutions => 'institutions';

  @override
  String get landingThemeSystem => 'Theme: System';

  @override
  String get landingThemeLight => 'Theme: Light';

  @override
  String get landingThemeDark => 'Theme: Dark';

  @override
  String get landingLanguageTooltip => 'Language';

  @override
  String get landingLanguageSystem => 'System';

  @override
  String get landingLanguageEs => 'Spanish';

  @override
  String get landingLanguageEn => 'English';

  @override
  String get landingLanguagePt => 'Portuguese';

  @override
  String landingMissingAsset(Object path) {
    return 'MISSING ASSET:\n$path';
  }

  @override
  String get vacancyManagement => 'Vacancies';

  @override
  String vacancyManagementTitle(Object institucion) {
    return 'Vacancy management – $institucion';
  }

  @override
  String get recalculateOccupiedTooltip => 'Recalculate occupied (confirmed)';

  @override
  String get summaryLabel => 'Summary';

  @override
  String totalCapacityValue(Object valor) {
    return 'Total capacity: $valor';
  }

  @override
  String occupiedValue(Object valor) {
    return 'Occupied: $valor';
  }

  @override
  String availableEstimatedValue(Object valor) {
    return 'Available (estimated): $valor';
  }

  @override
  String get noGroupsLoaded => 'No groups/capacities loaded.';

  @override
  String vacancyGroupSubtitle(
    Object actividad,
    Object total,
    Object ocupados,
    Object disponibles,
  ) {
    return '$actividad · Capacity $total · Occupied $ocupados · Avail $disponibles';
  }

  @override
  String get newGroupTitle => 'New group/capacity';

  @override
  String get editGroupTitle => 'Edit group/capacity';

  @override
  String get available => 'Available';

  @override
  String get availableShort => 'Avail';

  @override
  String get availableLabel => 'Available';

  @override
  String get fullLabel => 'Full';

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
  String get basic => 'Basic';

  @override
  String get standard => 'Standard';

  @override
  String get premium => 'Premium';

  @override
  String get summary => 'Summary';

  @override
  String get plan => 'Plan';

  @override
  String get code => 'Code';

  @override
  String get invalidInstitutionId => 'Invalid institution ID.';

  @override
  String get institucionInvalidGeneric => 'Invalid institution.';

  @override
  String get institutionGeneric => 'Institution';

  @override
  String get institutionNotLoadedYet => 'The institution is not loaded yet.';

  @override
  String get noActiveSessionGoBackToLogin =>
      'No active session. Go back to login.';

  @override
  String get institutionsTitle => 'Institutions';

  @override
  String get backToHome => 'Back to home';

  @override
  String get institutionAccess => 'Institution access';

  @override
  String institutionProfileIdLabel(Object perfilId) {
    return 'Profile ID: $perfilId';
  }

  @override
  String get planPlaceholder => 'Plan management';

  @override
  String get profilePlaceholder => 'Institution profile';

  @override
  String get planUpper => 'PLAN';

  @override
  String get profileUpper => 'PROFILE';

  @override
  String get administrationUpper => 'ADMINISTRATION';

  @override
  String get planCardSubtitle => 'Manage plan and modules';

  @override
  String get profileCardSubtitle => 'Institution details and presentation';

  @override
  String get administrationCardSubtitle => 'Institution operations';

  @override
  String planAndStatusLine(Object plan, Object estado) {
    return 'Plan: $plan · Status: $estado';
  }

  @override
  String get workProfilesUpToPremium => 'Up to 10 work profiles';

  @override
  String get workProfilesUpToStandard => 'Up to 3 work profiles';

  @override
  String get moduleLabelGeneric => 'Module';

  @override
  String invalidModuleKeyShowingAll(Object key) {
    return 'Invalid filter ($key). Showing all modules.';
  }

  @override
  String loadErrorWithDetails(Object error) {
    return 'Error loading: $error';
  }

  @override
  String get confirmRequestTitle => 'Confirm request';

  @override
  String get rejectRequestTitle => 'Reject request';

  @override
  String get updateRequestTitle => 'Update request';

  @override
  String get confirmRequestBody => 'Do you want to confirm this request?';

  @override
  String get rejectRequestBody => 'Do you want to reject this request?';

  @override
  String get updateRequestBody => 'Do you want to update this request?';

  @override
  String activityWithName(Object nombre) {
    return 'Activity: $nombre';
  }

  @override
  String activityWithValue(Object value) {
    return 'Activity: $value';
  }

  @override
  String get rejectionReasonOptionalLabel => 'Reason (optional)';

  @override
  String get noteToStudentOptionalLabel => 'Note to the student (optional)';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get requestStatusConfirmed => 'Confirmed';

  @override
  String get requestStatusRejected => 'Rejected';

  @override
  String get requestStatusCancelledByStudent => 'Cancelled by student';

  @override
  String get requestStatusCancelledByInstitution => 'Cancelled by institution';

  @override
  String get requestConfirmed => 'Request confirmed.';

  @override
  String get requestRejected => 'Request rejected.';

  @override
  String get requestUpdated => 'Request updated.';

  @override
  String get requestIsNoLongerPending => 'This request is no longer pending.';

  @override
  String get noRequestsInSection => 'There are no requests in this section.';

  @override
  String get noPendingRequests => 'There are no pending requests.';

  @override
  String actionErrorWithDetails(Object error) {
    return 'Could not complete the action: $error';
  }

  @override
  String get cannotOpenDocumentsMissingOwnerOrProfile =>
      'Cannot open documents without a valid session.';

  @override
  String requestsTitleWithInstitution(Object institucion, Object subtitle) {
    return 'Requests – $institucion · $subtitle';
  }

  @override
  String pendingWithCount(Object count) {
    return 'Pending ($count)';
  }

  @override
  String confirmedWithCount(Object count) {
    return 'Confirmed ($count)';
  }

  @override
  String rejectedWithCount(Object count) {
    return 'Rejected ($count)';
  }

  @override
  String cancelledWithCount(Object count) {
    return 'Cancelled ($count)';
  }

  @override
  String invalidModuleFilterBanner(Object key) {
    return 'Invalid module filter ($key)';
  }

  @override
  String filteringByModuleBanner(Object module, Object key) {
    return 'Filtering by module: $module ($key)';
  }

  @override
  String studentDocumentLine(Object doc) {
    return 'Document: $doc';
  }

  @override
  String typeLine(Object tipo) {
    return 'Type: $tipo';
  }

  @override
  String moduleLine(Object module) {
    return 'Module: $module';
  }

  @override
  String groupOrClassLine(Object valor) {
    return 'Class/Group: $valor';
  }

  @override
  String shiftLine(Object valor) {
    return 'Shift: $valor';
  }

  @override
  String statusLine(Object estado) {
    return 'Status: $estado';
  }

  @override
  String get requestOrViewDocumentsCta => 'Request or view documents';

  @override
  String get documentsMissingOwnerOrProfileDisabledCta =>
      'Documents not available';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsTitleWithNewCount(Object count) {
    return 'Notifications ($count new)';
  }

  @override
  String get notificationsDeleted => 'Notifications deleted.';

  @override
  String loadNotificationsError(Object error) {
    return 'Error loading notifications: $error';
  }

  @override
  String updateNotificationError(Object error) {
    return 'Error updating notification: $error';
  }

  @override
  String deleteNotificationError(Object error) {
    return 'Error deleting notification: $error';
  }

  @override
  String get markAllReadError => 'Could not mark all as read';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllNotificationsError =>
      'Could not delete all notifications';

  @override
  String get sessionInvalidTitle => 'Invalid session';

  @override
  String get sessionInvalidPleaseLogin => 'Invalid session. Please sign in.';

  @override
  String get notificationsNeedOwnerSubtitle =>
      'An active session is required to view notifications.';

  @override
  String get noNotificationsTitle => 'No notifications';

  @override
  String get noNotificationsSubtitle => 'There are no notifications available.';

  @override
  String get deleteNotificationTitle => 'Delete notification';

  @override
  String get deleteNotificationBody =>
      'Do you want to delete this notification?';

  @override
  String get deleteAllNotificationsTitle => 'Delete all';

  @override
  String get deleteAllNotificationsBody =>
      'Do you want to delete all notifications?';

  @override
  String get deleteAllNotificationsTooltip => 'Delete all';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get markAllAsReadTooltip => 'Mark all as read';

  @override
  String get institucionActividadCurricularGeneral => 'Curricular activity';

  @override
  String get institucionActividadExtracurricularGeneral =>
      'Extracurricular activity';

  @override
  String get institucionActividadExtracurricular => 'Extracurricular';

  @override
  String get institucionWorkProfileFallback => 'Work profile';

  @override
  String get institucionChangeActivityTitle => 'Change activity';

  @override
  String get institucionChangeActivityBody =>
      'Select the activity you want to manage';

  @override
  String get institucionWorkProfileNameTitle => 'Profile name';

  @override
  String get name => 'Name';

  @override
  String get institucionWorkProfileNameHint => 'e.g., Admin, Principal';

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
  String get institucionAreasFree => 'Free areas';

  @override
  String get planFallbackNoStructured => 'Plan without detailed structure';

  @override
  String get idNoSession => 'No session';

  @override
  String idWithValue(Object value) {
    return 'ID: $value';
  }

  @override
  String institucionPlanAndProfilesPerActivity(Object plan, Object max) {
    return 'Plan: $plan · Profiles: $max per activity';
  }

  @override
  String get institucionFirstSelectActivityBody => 'Select an activity first';

  @override
  String get institucionWorkProfilesAreInternalNote =>
      'Work profiles are for internal use';

  @override
  String get institucionNoActivitiesYet => 'No activities configured yet';

  @override
  String get institucionManageCurricularActivity =>
      'Manage curricular activity';

  @override
  String get institucionManageExtracurricularModule =>
      'Manage extracurricular module';

  @override
  String institucionPlanAndAvailableProfiles(Object plan, Object max) {
    return 'Plan: $plan · Available profiles: $max';
  }

  @override
  String get institucionConcurrentProfilesRule =>
      'Concurrent profiles according to plan';

  @override
  String get institucionWorkProfilesTitle => 'Work profiles';

  @override
  String get institucionWorkProfilesDescription =>
      'Select a profile to manage this activity.';

  @override
  String institucionProfileWorkingSubtitle(
    Object area,
    Object who,
    Object ttl,
  ) {
    return '$area · $who · $ttl';
  }

  @override
  String get institucionWorkProfilesRenameTip => 'You can rename this profile';

  @override
  String get institucionSelectActivityTitle => 'Select activity';

  @override
  String get institucionSelectWorkProfileTitle => 'Select work profile';

  @override
  String get institucionChangeActivityTooltip => 'Change activity';

  @override
  String get institucionPlanTitle => 'Institution plan';

  @override
  String get institucionPlanHeader => 'Choose your plan';

  @override
  String get institucionPlanChooseYourPlanTitle => 'Choose your plan';

  @override
  String get institucionPlanChooseYourPlanSubtitle =>
      'Select the plan that fits best';

  @override
  String get institucionPlanNoModulesSelected => 'No modules selected.';

  @override
  String get institucionPlanInvalidInstitutionId => 'Invalid institution.';

  @override
  String get institucionPlanPickAtLeastOneModule => 'Pick at least one module.';

  @override
  String get institucionPlanChooseStandardOrPremium =>
      'Choose Standard or Premium.';

  @override
  String get institucionPlanChooseBasicOrPremium => 'Choose Basic or Premium.';

  @override
  String get institucionPlanPromoCleared => 'Promo code cleared';

  @override
  String get institucionPlanPromoSoldOut => 'Promo code sold out';

  @override
  String get institucionPlanPromoReservedAlready => 'Code already reserved';

  @override
  String get institucionPlanPromoReserved => 'Code reserved';

  @override
  String get institucionPlanPromoInvalid => 'Invalid promo code';

  @override
  String institucionPlanPromoApplied(Object code) {
    return 'Promo applied: $code';
  }

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get institucionPlanCodeRequiredForFreeActivation =>
      'A code is required to activate the free plan';

  @override
  String get argentina => 'Argentina';

  @override
  String get emailAlreadyRegisteredLogin =>
      'Email already registered. Please sign in.';

  @override
  String institucionPlanTierLabel(Object tier, Object price) {
    return 'Plan $tier ($price)';
  }

  @override
  String get usdToArsTitle => 'USD → ARS conversion';

  @override
  String get usdToArsSubtitleBestEffort => 'Reference estimate';

  @override
  String get usdToArsUnavailable => 'Conversion unavailable';

  @override
  String usdToArsValue(Object value) {
    return 'USD → ARS: $value';
  }

  @override
  String get usdToArsManualLabel => 'Manual rate';

  @override
  String get usdToArsUsingManual => 'Using manual rate';

  @override
  String updatedAt(Object date) {
    return 'Updated at $date';
  }

  @override
  String get promoCodeTitle => 'Promo code';

  @override
  String get promoCodeOptionalSubtitle => 'Optional';

  @override
  String get promoCodeLabel => 'Code';

  @override
  String get promoCodeHint => 'Enter the code';

  @override
  String get iHavePromoCode => 'I have a code';

  @override
  String promoAppliedLine(Object code, Object label) {
    return 'Promo applied: $code · $label';
  }

  @override
  String get subtotalUsd => 'Subtotal (USD)';

  @override
  String get promoDiscountUsd => 'Promo discount (USD)';

  @override
  String get totalUsd => 'Total (USD)';

  @override
  String get totalArs => 'Total (ARS)';

  @override
  String get institucionPlanSummarySubtitle => 'Plan summary';

  @override
  String get notAvailable => 'Not available';

  @override
  String get calcDetailsTitle => 'Calculation details';

  @override
  String get calcDetailsSubtitle => 'Pricing breakdown';

  @override
  String get institucionPlanNoteNoPaymentsYet =>
      'Payments are not enabled at this stage';

  @override
  String get institucionGenericName => 'Institution';

  @override
  String get countryArgentina => 'Argentina';

  @override
  String get institucionTitle => 'Institution';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionBackHome => 'Back to home';

  @override
  String get actionLogout => 'Sign out';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionExit => 'Exit';

  @override
  String get actionLoad => 'Load';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaving => 'Saving…';

  @override
  String get statusSaving => 'Saving…';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRequest => 'Request';

  @override
  String get actionList => 'List';

  @override
  String get actionIncrease => 'Increase';

  @override
  String get actionDecrease => 'Decrease';

  @override
  String get valueEmpty => 'Empty';

  @override
  String get valueNone => 'None';

  @override
  String get labelNotProvided => 'Not provided';

  @override
  String get validationTooShort => 'Too short';

  @override
  String get validationCannotBeNegative => 'Cannot be negative';

  @override
  String get institucionAreaErrorLoadFailed =>
      'Could not load the operations area.';

  @override
  String get institucionAreaSnackNoInstitucion => 'No institution loaded.';

  @override
  String get institucionAreaDefaultWorkProfileName => 'Work profile';

  @override
  String get institucionAreaSnackAreaInUse =>
      'This area is in use by another profile.';

  @override
  String get institucionAreaDefaultActivityLabel => 'Activity';

  @override
  String get institucionAreaTitle => 'Operations area';

  @override
  String institucionAreaIdLine(Object id) {
    return 'ID: $id';
  }

  @override
  String institucionAreaLocationLine(Object location) {
    return 'Location: $location';
  }

  @override
  String institucionAreaActivityLine(Object activity) {
    return 'Activity: $activity';
  }

  @override
  String institucionAreaWorkProfileLine(Object profile) {
    return 'Profile: $profile';
  }

  @override
  String institucionAreaAccessLine(Object curricularOk, Object extraOk) {
    return 'Access: curricular $curricularOk · extracurricular $extraOk';
  }

  @override
  String get institucionAreaCardNotificationsTitle => 'Notifications';

  @override
  String get institucionAreaCardNotificationsSubtitle =>
      'View institution notifications';

  @override
  String get institucionAreaSemanticsOpenNotifications => 'Open notifications';

  @override
  String get institucionAreaCardSolicitudesTitle => 'Requests';

  @override
  String get institucionAreaCardSolicitudesSubtitle =>
      'Manage student requests';

  @override
  String get institucionAreaSemanticsOpenSolicitudes => 'Open requests';

  @override
  String get institucionAreaCardVacantesTitle => 'Vacancies';

  @override
  String get institucionAreaCardVacantesSubtitle =>
      'Manage groups and capacities';

  @override
  String get institucionAreaSemanticsOpenVacantes => 'Open vacancies';

  @override
  String get institucionAreaCardVacantesLockedSubtitle =>
      'Not available for this plan';

  @override
  String get institucionAreaSemanticsVacantesLocked =>
      'Vacancies not available';

  @override
  String get institucionAreaCardDocumentacionTitle => 'Documentation';

  @override
  String get institucionAreaCardDocumentacionSubtitle =>
      'Request and review documents';

  @override
  String get institucionAreaSemanticsOpenDocumentacion => 'Open documentation';

  @override
  String get institucionAreaCardExtraHubTitle => 'Extracurricular';

  @override
  String get institucionAreaCardExtraHubSubtitle =>
      'Manage extracurricular modules';

  @override
  String get institucionAreaSemanticsOpenExtraHub => 'Open extracurricular';

  @override
  String get institucionAreaCardExtraHubLockedSubtitle =>
      'Not available for this plan';

  @override
  String get institucionAreaSemanticsExtraHubLocked =>
      'Extracurricular not available';

  @override
  String get institucionAreaCardCroquisTitle => 'Layout';

  @override
  String get institucionAreaCardCroquisSubtitle => 'Manage classroom layout';

  @override
  String get institucionAreaSemanticsOpenCroquis => 'Open layout';

  @override
  String get institucionAreaCardCroquisLockedSubtitle =>
      'Not available for this plan';

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
  String get turnoMorning => 'Morning';

  @override
  String get croquisTitle => 'Classroom layout';

  @override
  String get croquisTurnoMorning => 'Mañana';

  @override
  String get croquisTurnoAfternoon => 'Tarde';

  @override
  String get croquisTurnoNight => 'Noche';

  @override
  String get croquisTurnoFullDay => 'Jornada completa';

  @override
  String get croquisSnackInvalidInstitution => 'Invalid institution.';

  @override
  String get croquisSnackEnterAulaBeforeSave =>
      'Enter a classroom name before saving.';

  @override
  String get croquisSnackSaved => 'Layout saved.';

  @override
  String croquisSnackSaveError(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get croquisDialogClearTitle => 'Clear grid';

  @override
  String get croquisDialogClearBody => 'Do you want to clear the entire grid?';

  @override
  String get croquisDialogCellTitle => 'Cell';

  @override
  String get croquisFieldNameLabel => 'Name';

  @override
  String get croquisDialogNewGroupTitle => 'New group';

  @override
  String get croquisFieldGroupTitleLabel => 'Group name';

  @override
  String get croquisFieldGroupColorLabel => 'Group color';

  @override
  String get croquisFieldGroupColorHint => 'Pick a color';

  @override
  String get croquisFieldRowLabel => 'Row';

  @override
  String get croquisFieldColLabel => 'Column';

  @override
  String get croquisFieldHeightLabel => 'Height';

  @override
  String get croquisFieldWidthLabel => 'Width';

  @override
  String get croquisDialogDeleteGroupTitle => 'Delete group';

  @override
  String get croquisDialogDeleteGroupBody =>
      'Do you want to delete this group?';

  @override
  String get croquisDialogUnsavedTitle => 'Unsaved changes';

  @override
  String get croquisDialogUnsavedBody =>
      'You have unsaved changes. Leave anyway?';

  @override
  String get croquisErrorInit => 'Error initializing the layout.';

  @override
  String get croquisSectionAulaTurno => 'Classroom and shift';

  @override
  String get croquisFieldAulaLabel => 'Classroom';

  @override
  String get croquisFieldAulaHint => 'e.g., Room 1 / 3B';

  @override
  String get croquisFieldTurnoLabel => 'Shift';

  @override
  String get croquisActionClearGrid => 'Clear grid';

  @override
  String get croquisActionAddGroup => 'Add group';

  @override
  String get croquisTipTapCellAutosave => 'Tap a cell to edit. It autosaves.';

  @override
  String get croquisSectionGrid => 'Grid';

  @override
  String croquisGridSizeLine(Object rows, Object cols) {
    return 'Size: $rows×$cols';
  }

  @override
  String get croquisSectionGroups => 'Groups';

  @override
  String get croquisGroupsEmpty => 'No groups created.';

  @override
  String get croquisGroupFallbackTitle => 'Group';

  @override
  String croquisGroupSubtitle(Object count) {
    return 'Members: $count';
  }

  @override
  String get institucionDocsWarnPerfilButNoOwner =>
      'Profile present, but owner missing. Limited view.';

  @override
  String get institucionDocsWarnOwnerButNoPerfil =>
      'Owner present, but profile missing. Limited view.';

  @override
  String get institucionDocsErrorInvalidInstitutionId =>
      'Invalid institution ID.';

  @override
  String get institucionDocsSnackInvalidInstitutionEmptyId =>
      'Empty institution ID.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfil =>
      'Owner and profile are required for this action.';

  @override
  String get institucionDocsSnackNoDocTypes => 'No document types available.';

  @override
  String get institucionDocsSnackSolicitudCreated => 'Request created.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfilToUpload =>
      'Owner and profile are required to simulate upload.';

  @override
  String get institucionDocsSnackMissingRef => 'Missing file reference.';

  @override
  String get institucionDocsSnackTempDocSaved => 'Temporary document saved.';

  @override
  String get institucionDocsSnackNeedPerfilToCleanup =>
      'Profile is required to cleanup expired.';

  @override
  String get institucionDocsSnackNoExpiredToRemove =>
      'No expired items to remove.';

  @override
  String institucionDocsSnackExpiredRemoved(Object count) {
    return 'Removed $count expired.';
  }

  @override
  String get institucionDocsDialogDeleteTitle => 'Delete';

  @override
  String institucionDocsDialogDeleteBody(Object name) {
    return 'Delete this item: $name?';
  }

  @override
  String get institucionDocsSnackExpiredUseCleanup =>
      'Expired. Use cleanup expired.';

  @override
  String get institucionDocsSnackDeleted => 'Deleted.';

  @override
  String get institucionDocsSnackCannotOpenMissingIds =>
      'Cannot open: missing IDs.';

  @override
  String get institucionDocsSnackDeeplinkTooLong => 'Deeplink too long.';

  @override
  String get institucionDocsSnackRouteNotRegistered => 'Route not registered.';

  @override
  String get estadoSolicitudPendiente => 'Pending';

  @override
  String get estadoSolicitudCumplida => 'Completed';

  @override
  String get estadoSolicitudCancelada => 'Cancelled';

  @override
  String get estadoDocumentoExpirado => 'Expired';

  @override
  String get estadoDocumentoActivo => 'Active';

  @override
  String get institucionDocsTooltipOpenAlumno => 'Open student';

  @override
  String get institucionDocsTooltipExpiredUseCleanup => 'Expired (use cleanup)';

  @override
  String get institucionDocsViewAllInstitution => 'View all (institution)';

  @override
  String get institucionDocsViewFilteredOwnerPerfil =>
      'Filtered (owner+profile)';

  @override
  String get institucionDocsViewFilteredPerfil => 'Filtered (profile)';

  @override
  String get institucionDocsViewFilteredOwner => 'Filtered (owner)';

  @override
  String institucionDocsInstitutionIdLine(Object id) {
    return 'Institution: $id';
  }

  @override
  String institucionDocsInstitutionOwnerLine(Object owner) {
    return 'Owner: $owner';
  }

  @override
  String get institucionDocsFieldOwnerAlumnoLabel => 'Student owner';

  @override
  String get institucionDocsFieldPerfilAlumnoLabel => 'Student profile';

  @override
  String get institucionDocsFieldTipoDocumentoLabel => 'Document type';

  @override
  String get institucionDocsFieldMensajeOpcionalLabel => 'Message (optional)';

  @override
  String get institucionDocsFieldRefLabel => 'Reference';

  @override
  String get institucionDocsFieldTtlDaysLabel => 'TTL (days)';

  @override
  String get institucionDocsActionSimulateUpload => 'Simulate upload';

  @override
  String get institucionDocsActionCleanupExpired => 'Cleanup expired';

  @override
  String get institucionDocsEmptySolicitudes => 'No requests.';

  @override
  String get institucionDocsEmptyDocumentos => 'No documents.';

  @override
  String institucionDocsSolicitudTipoLine(Object tipo) {
    return 'Type: $tipo';
  }

  @override
  String institucionDocsSolicitudSubtitle(Object estado, Object fecha) {
    return '$estado · $fecha';
  }

  @override
  String institucionDocsDocumentoTipoLine(Object tipo) {
    return 'Type: $tipo';
  }

  @override
  String institucionDocsDocumentoSubtitle(Object estado, Object vence) {
    return '$estado · $vence';
  }

  @override
  String institucionDocsAppBarTitle(Object institucion) {
    return '$institucion – Documentation';
  }

  @override
  String get tabSolicitudes => 'Requests';

  @override
  String get tabDocumentos => 'Documents';

  @override
  String get institucionDocsErrorTimeout =>
      'Tiempo de espera agotado. Intentá nuevamente.';

  @override
  String get institucionExtracGrupoGuiaBloqueTitle => 'Block guide';

  @override
  String get institucionExtracGrupoInvalidInstitutionId =>
      'Invalid institution.';

  @override
  String institucionExtracGrupoWarnModuleKeyMismatch(Object expected) {
    return 'moduleKey does not match expected: $expected';
  }

  @override
  String institucionExtracGrupoWarnModuleKeyNotCanonical(Object value) {
    return 'moduleKey is not canonical: $value';
  }

  @override
  String institucionExtracGrupoSaveFailed(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get institucionExtracGrupoEditTitle => 'Edit group';

  @override
  String get institucionExtracGrupoCreateTitle => 'Create group';

  @override
  String institucionExtracGrupoHeaderBloqueLine(
    Object bloque,
    Object moduleKey,
  ) {
    return 'Block: $bloque · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracGrupoHeaderNotePrototype =>
      'Prototype (no backend)';

  @override
  String institucionExtracGrupoWarnKeyMismatch(Object expected) {
    return 'Key does not match expected: $expected';
  }

  @override
  String institucionExtracGrupoWarnKeyNotCanonical(Object value) {
    return 'Non-canonical key: $value';
  }

  @override
  String get institucionExtracGrupoFieldActividadLabel => 'Activity';

  @override
  String get institucionExtracGrupoFieldActividadHint => 'e.g., Soccer';

  @override
  String get institucionExtracGrupoValActividadRequired =>
      'Activity is required';

  @override
  String get institucionExtracGrupoFieldGrupoLabel => 'Group';

  @override
  String get institucionExtracGrupoFieldGrupoHint => 'e.g., Group A';

  @override
  String get institucionExtracGrupoValGrupoRequired => 'Group is required';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalLabel =>
      'Shift (optional)';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalHint => 'e.g., Morning';

  @override
  String get institucionExtracGrupoFieldAulaOptionalLabel => 'Room (optional)';

  @override
  String get institucionExtracGrupoFieldAulaOptionalHint => 'e.g., Gym';

  @override
  String get institucionExtracGrupoFieldCupoMaxLabel => 'Max capacity';

  @override
  String get institucionExtracGrupoFieldCupoMaxHint => 'e.g., 25';

  @override
  String get institucionExtracGrupoFieldCupoOcupadoLabel => 'Occupied';

  @override
  String get institucionExtracGrupoValOccExceedsMax =>
      'Occupied cannot exceed max';

  @override
  String get institucionExtracGrupoFieldActivoTitle => 'Active';

  @override
  String get institucionExtracGrupoFieldActivoSubtitle => 'Allows requests';

  @override
  String get institucionExtracBaseErrInvalidInstId => 'Invalid institution.';

  @override
  String get institucionExtracBaseErrInvalidModuleKeySnake =>
      'Invalid moduleKey (snake_case).';

  @override
  String institucionExtracBaseErrModuleKeyMismatch(Object expected) {
    return 'moduleKey does not match expected: $expected';
  }

  @override
  String institucionExtracBaseErrModuleKeyNotCanonical(Object value) {
    return 'Non-canonical moduleKey: $value';
  }

  @override
  String get institucionExtracBaseCuposNotManaged => 'Capacities not managed';

  @override
  String institucionExtracBaseCuposManaged(Object disp, Object max) {
    return 'Available: $disp of $max';
  }

  @override
  String get institucionExtracBaseInvalidDataGeneric => 'Invalid data.';

  @override
  String get institucionExtracBaseInvalidDataForCupos =>
      'Invalid data for capacities.';

  @override
  String get institucionExtracBaseCuposRequireMax =>
      'Max capacity is required.';

  @override
  String get institucionExtracBaseCuposDialogTitle => 'Edit capacities';

  @override
  String institucionExtracBaseCuposDialogActividad(Object actividad) {
    return 'Activity: $actividad';
  }

  @override
  String institucionExtracBaseCuposDialogGrupo(Object grupo) {
    return 'Group: $grupo';
  }

  @override
  String institucionExtracBaseCuposDialogMax(Object max) {
    return 'Max: $max';
  }

  @override
  String institucionExtracBaseCuposDialogOcupado(Object ocupado) {
    return 'Occupied: $ocupado';
  }

  @override
  String institucionExtracBaseCuposDialogDisponibles(Object disp) {
    return 'Available: $disp';
  }

  @override
  String get institucionExtracBaseCuposUpdated => 'Capacities updated.';

  @override
  String institucionExtracBaseCuposSaveFailed(Object error) {
    return 'Could not save capacities: $error';
  }

  @override
  String get institucionExtracBaseInvalidDataForDelete =>
      'Cannot delete: invalid data.';

  @override
  String get institucionExtracBaseDeleteDialogTitle => 'Delete group';

  @override
  String institucionExtracBaseDeleteDialogBody(Object actividad, Object grupo) {
    return 'Delete $actividad ($grupo)?';
  }

  @override
  String get institucionExtracBaseDeletedOk => 'Deleted.';

  @override
  String institucionExtracBaseDeleteFailed(Object error) {
    return 'Could not delete: $error';
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
    return 'Institution: $id';
  }

  @override
  String get institucionExtracBaseHeaderNote => 'Module management (prototype)';

  @override
  String get institucionExtracBaseQuickGuideTitle => 'Quick guide';

  @override
  String get institucionExtracBaseQuickGuideEmpty => 'No guide available.';

  @override
  String get institucionExtracBaseQuickGuideFootnote => 'Texts may change.';

  @override
  String get institucionExtracBaseGroupsTitle => 'Groups';

  @override
  String get institucionExtracBaseInvalidDataToList =>
      'Cannot list: invalid data.';

  @override
  String get institucionExtracBaseLoadFailed => 'Could not load.';

  @override
  String get institucionExtracBaseNoGroupsYet => 'No groups yet.';

  @override
  String get institucionExtracBaseWithCupos => 'With capacities';

  @override
  String get institucionExtracBaseNoCupos => 'No capacities';

  @override
  String institucionExtracBaseGroupLine(Object group) {
    return 'Group: $group';
  }

  @override
  String institucionExtracBaseTurnoLine(Object turno) {
    return 'Shift: $turno';
  }

  @override
  String institucionExtracBaseAulaLine(Object aula) {
    return 'Room: $aula';
  }

  @override
  String get institucionExtracBaseActionCupos => 'Capacities';

  @override
  String get institucionExtracBaseCreateGroupTitle => 'Create group';

  @override
  String get institucionExtracBaseCreateGroupSubtitle => 'Add a new group';

  @override
  String get institucionExtracBaseRulesTitle => 'Rules';

  @override
  String get institucionExtracBaseRulesSubtitle => 'Pending';

  @override
  String institucionExtracBaseRulesPendingToast(Object value) {
    return 'Pending rules: $value';
  }

  @override
  String get institucionExtracBaseSolicitudesTitle => 'Requests';

  @override
  String institucionExtracBaseSolicitudesSubtitle(Object moduleKey) {
    return 'View requests for module: $moduleKey';
  }

  @override
  String get institucionExtracHubTitle => 'Extracurricular';

  @override
  String institucionExtracHubHeaderInstOk(Object instIdCanon) {
    return 'Institution: $instIdCanon';
  }

  @override
  String get institucionExtracHubHeaderInstInvalid => 'Invalid institution.';

  @override
  String get institucionExtracHubIntro => 'Select a module to manage.';

  @override
  String get institucionExtracHubInvalidInstIdHelp =>
      'Go back and retry with a valid institution.';

  @override
  String institucionExtracHubTileSubtitle(
    Object descripcion,
    Object moduleKey,
  ) {
    return '$descripcion · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracHubToastInvalidInstId => 'Invalid institution.';

  @override
  String institucionExtracHubToastInvalidModuleKey(Object bloque) {
    return 'Cannot open module: $bloque';
  }

  @override
  String errorLoadingGroups(Object error) {
    return 'Error loading groups: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get occupiedRecalculatedOk => 'Occupied recalculated.';

  @override
  String errorRecalculating(Object error) {
    return 'Error recalculating: $error';
  }

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get activityLabelShort => 'Activity';

  @override
  String get maxCapacityLabel => 'Max capacity';

  @override
  String get completeRequiredFields => 'Complete required fields.';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonNo => 'No';

  @override
  String get commonNone => 'None';

  @override
  String get commonProfile => 'Profile';

  @override
  String get commonModule => 'Module';

  @override
  String get commonPending => 'Pending';

  @override
  String get commonCompleted => 'Completed';

  @override
  String get commonCancelled => 'Cancelled';

  @override
  String get commonConfirmed => 'Confirmed';

  @override
  String get commonRejected => 'Rejected';

  @override
  String get commonExpired => 'Expired';

  @override
  String get commonActive => 'Active';

  @override
  String get commonCurricular => 'Curricular';

  @override
  String get commonExtracurricular => 'Extracurricular';

  @override
  String get commonInstitution => 'Institution';

  @override
  String get commonType => 'Type';

  @override
  String get commonClassGroup => 'Class/Group';

  @override
  String get commonShift => 'Shift';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonGenerating => 'Generating…';

  @override
  String commonErrorWithDetails(Object error) {
    return 'Error: $error';
  }

  @override
  String get alumnoDocumentosTitle => 'Documents';

  @override
  String get alumnoDocumentosInvalidOwner => 'Invalid owner.';

  @override
  String get alumnoDocumentosInvalidPerfil => 'Invalid profile.';

  @override
  String get alumnoDocumentosOwnerMismatchAutoscrollIgnored =>
      'The deeplink belongs to a different account. Autoscroll ignored.';

  @override
  String get alumnoDocumentosDeeplinkSolicitudNotFound =>
      'Deeplink request not found.';

  @override
  String get alumnoDocumentosDeeplinkDocumentoNotFound =>
      'Deeplink document not found.';

  @override
  String get alumnoDocumentosEmptySolicitudes => 'No requests.';

  @override
  String get alumnoDocumentosEmptyDocumentos => 'No documents.';

  @override
  String get alumnoDocumentosFieldMensaje => 'Message';

  @override
  String get alumnoDocumentosFieldTipo => 'Type';

  @override
  String get alumnoDocumentosFieldId => 'ID';

  @override
  String get alumnoDocumentosFieldEstado => 'Status';

  @override
  String get alumnoDocumentosFieldInstitucion => 'Institution';

  @override
  String get alumnoDocumentosFieldCreada => 'Created';

  @override
  String get alumnoDocumentosFieldOwner => 'Owner';

  @override
  String get alumnoDocumentosFieldPerfil => 'Profile';

  @override
  String get alumnoDocumentosFieldSubido => 'Uploaded';

  @override
  String get alumnoDocumentosFieldExpira => 'Expires';

  @override
  String get alumnoDocumentosExpiredWillBeDeletedOnClean =>
      'will be deleted when cleaning expired';

  @override
  String get alumnoDocumentosFieldSolicitud => 'Request';

  @override
  String get alumnoDocumentosFieldRef => 'Reference';

  @override
  String get alumnoDocumentosNoExpiredToClean => 'No expired items to clean.';

  @override
  String alumnoDocumentosExpiredCleanedCount(Object count) {
    return 'Cleaned $count expired.';
  }

  @override
  String get alumnoDocumentosDocExpiredUseClean =>
      'This document is expired. Use “Clean expired”.';

  @override
  String get alumnoDocumentosExpiredTooltip => 'Expired (use cleanup)';

  @override
  String get alumnoDocumentosDeleteDocTitle => 'Delete document';

  @override
  String alumnoDocumentosDeleteDocBody(Object id) {
    return 'Delete document $id?';
  }

  @override
  String get alumnoDocumentosDocDeleted => 'Document deleted.';

  @override
  String get alumnoDocumentosCleanExpired => 'Clean expired';

  @override
  String get alumnoDocumentosTabSolicitudes => 'Requests';

  @override
  String get alumnoDocumentosTabDocumentos => 'Documents';

  @override
  String get alumnoMisSolicitudesTitleOwner => 'My requests';

  @override
  String alumnoMisSolicitudesTitlePerfil(Object perfil) {
    return 'Requests – $perfil';
  }

  @override
  String get alumnoMisSolicitudesInvalidOwner => 'Invalid owner.';

  @override
  String get alumnoMisSolicitudesInvalidPerfil => 'Invalid profile.';

  @override
  String alumnoMisSolicitudesLoadError(Object error) {
    return 'Error loading: $error';
  }

  @override
  String get alumnoMisSolicitudesStatusCancelledYou => 'Cancelled by you';

  @override
  String get alumnoMisSolicitudesStatusCancelledInstitution =>
      'Cancelled by institution';

  @override
  String get alumnoMisSolicitudesNotPending =>
      'This request is no longer pending.';

  @override
  String get alumnoMisSolicitudesCancelTitle => 'Cancel request';

  @override
  String get alumnoMisSolicitudesCancelBody =>
      'Do you want to cancel this request?';

  @override
  String get alumnoMisSolicitudesCancelCta => 'Cancel';

  @override
  String get alumnoMisSolicitudesCancelledOk => 'Request cancelled.';

  @override
  String alumnoMisSolicitudesCancelError(Object error) {
    return 'Could not cancel: $error';
  }

  @override
  String get alumnoMisSolicitudesDeleteTitle => 'Delete request';

  @override
  String get alumnoMisSolicitudesDeleteBody =>
      'Do you want to delete this request? (pending curricular only)';

  @override
  String get alumnoMisSolicitudesDeletedOk => 'Request deleted.';

  @override
  String get alumnoMisSolicitudesCanonicalContextMissing =>
      'Missing canonical context (owner/profile) to generate the PDF.';

  @override
  String alumnoMisSolicitudesPdfGenerated(Object path) {
    return 'PDF generated: $path';
  }

  @override
  String alumnoMisSolicitudesPdfError(Object error) {
    return 'Could not generate PDF: $error';
  }

  @override
  String get alumnoMisSolicitudesDownloadPdf => 'Download PDF';

  @override
  String alumnoMisSolicitudesTabPendingCount(Object count) {
    return 'Pending ($count)';
  }

  @override
  String alumnoMisSolicitudesTabConfirmedCount(Object count) {
    return 'Confirmed ($count)';
  }

  @override
  String alumnoMisSolicitudesTabRejectedCount(Object count) {
    return 'Rejected ($count)';
  }

  @override
  String alumnoMisSolicitudesTabCancelledCount(Object count) {
    return 'Cancelled ($count)';
  }

  @override
  String get alumnoMisSolicitudesEmptySection =>
      'There are no requests in this section.';

  @override
  String get alumnoMisSolicitudesEmptyPending =>
      'You have no pending requests.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonGenericError => 'Error.';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailRequired => 'Enter your email.';

  @override
  String get commonEmailInvalid => 'Invalid email.';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonNewPassword => 'New password';

  @override
  String get commonConfirmPassword => 'Confirm password';

  @override
  String get commonPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonRememberMe => 'Remember me';

  @override
  String get commonSignIn => 'Sign in';

  @override
  String get commonSigningIn => 'Signing in…';

  @override
  String get commonRegister => 'Register';

  @override
  String get commonPasswordMinLength4 =>
      'Password must be at least 4 characters.';

  @override
  String get commonCreateAccount => 'Create account';

  @override
  String get commonCreating => 'Creating…';

  @override
  String get commonFeatureUnavailablePrototype =>
      'This feature is not available in this prototype.';

  @override
  String get alumnoLoginAppBar => 'Student access';

  @override
  String get alumnoLoginTitle => 'Sign in';

  @override
  String get alumnoLoginForgotPassword => 'Forgot password';

  @override
  String get alumnoLoginRegistroNoDisponible => 'Registration not available.';

  @override
  String get alumnoRegistroAppBar => 'Create account';

  @override
  String get alumnoRegistroTitle => 'Create account';

  @override
  String get alumnoRegistroPasswordRequired => 'Enter a password.';

  @override
  String get alumnoForgotPasswordTitle => 'Reset password';

  @override
  String get alumnoForgotPasswordIntro =>
      'Enter your email and choose a new password.';

  @override
  String get alumnoForgotPasswordEmailLabel => 'Email';

  @override
  String get alumnoForgotPasswordNewPasswordLabel => 'New password';

  @override
  String get alumnoForgotPasswordConfirmPasswordLabel => 'Confirm password';

  @override
  String get alumnoForgotPasswordShowPassword => 'Show password';

  @override
  String get alumnoForgotPasswordHidePassword => 'Hide password';

  @override
  String get alumnoForgotPasswordEnterEmailError => 'Enter your email.';

  @override
  String get alumnoForgotPasswordInvalidEmailError => 'Invalid email.';

  @override
  String get alumnoForgotPasswordEnterPasswordError => 'Enter a password.';

  @override
  String get alumnoForgotPasswordPasswordTooShortError =>
      'Password is too short.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatchError =>
      'Passwords don\'t match.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatch =>
      'Las contraseñas no coinciden.';

  @override
  String get alumnoForgotPasswordAccountNotFound =>
      'No account found for that email.';

  @override
  String get alumnoForgotPasswordPasswordUpdatedPrototype =>
      'Password updated (prototype).';

  @override
  String get institucionForgotPasswordTitle => 'Reset password';

  @override
  String get institucionForgotPasswordIntro =>
      'Enter the institution email and choose a new password.';

  @override
  String get institucionForgotPasswordEnterEmailError => 'Enter the email.';

  @override
  String get institucionForgotPasswordInvalidEmailError => 'Invalid email.';

  @override
  String get institucionForgotPasswordEnterPasswordError => 'Enter a password.';

  @override
  String get institucionForgotPasswordPasswordTooShortError =>
      'Password is too short.';

  @override
  String get institucionForgotPasswordPasswordsDontMatchError =>
      'Passwords don\'t match.';

  @override
  String get institucionForgotPasswordAccountNotFound =>
      'No institution found for that email.';

  @override
  String get institucionForgotPasswordPasswordUpdatedPrototype =>
      'Password updated (prototype).';

  @override
  String get invalidOwner => 'Invalid owner.';

  @override
  String get noNotifications => 'No notifications.';

  @override
  String get onlyUnread => 'Only unread';

  @override
  String get showAll => 'Show all';

  @override
  String get allProfiles => 'All profiles';

  @override
  String get filterByProfile => 'Filter by profile';

  @override
  String get filterForcedByCaller =>
      'Filtro forzado por la pantalla de origen (no modificable desde aquí).';

  @override
  String get clearPerfilFilter => 'Clear profile filter';

  @override
  String get noResultsForFilter => 'No results for that filter.';

  @override
  String get notificationDeleted => 'Notification deleted.';

  @override
  String get notificationNoDestination =>
      'This notification has no destination.';

  @override
  String get invalidDeeplink => 'Invalid deeplink.';

  @override
  String get deeplinkOwnerMismatch =>
      'This deeplink belongs to a different account.';

  @override
  String get missingPerfilIdForOpen =>
      'Missing perfilId to open this destination.';

  @override
  String deeplinkNotSupported(Object path) {
    return 'Deeplink not supported: $path';
  }

  @override
  String notificationPerfilLine(Object perfil) {
    return 'Profile: $perfil';
  }

  @override
  String get institucionAreaErrorEmptyId => 'Empty institution ID.';

  @override
  String get alumnoGrupoExtraInvalidInstitution => 'Invalid institution.';

  @override
  String get alumnoGrupoExtraMissingOwnerPerfil =>
      'Missing session context (owner/profile).';

  @override
  String get alumnoGrupoExtraTitle => 'Extracurricular groups';

  @override
  String get alumnoGrupoExtraLoadErrorTitle => 'Could not load';

  @override
  String get alumnoGrupoExtraSearchHint => 'Search activity or institution…';

  @override
  String get alumnoGrupoExtraBlockOptionalLabel => 'Block (optional)';

  @override
  String get alumnoGrupoExtraEmptyFiltered =>
      'No groups found for that filter.';

  @override
  String get alumnoGrupoExtraCupoUnmanaged => 'Capacities not managed';

  @override
  String alumnoGrupoExtraOpenSolicitudError(Object error) {
    return 'Could not open Requests: $error';
  }

  @override
  String alumnoGrupoExtraCupoManaged(Object disp, Object max) {
    return 'Available: $disp of $max';
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
  String get commonSearchHint => 'Search…';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRequired => 'Obligatorio';

  @override
  String get commonDeletePhotoTitle => 'Eliminar foto';

  @override
  String get commonDeletePhotoConfirm => '¿Querés eliminar esta foto?';

  @override
  String get commonNotificationsTooltip => 'View notifications';

  @override
  String get commonBackToProfiles => 'Back to profiles';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonPhoneLabel => 'Phone';

  @override
  String get commonChangePhoto => 'Change photo';

  @override
  String get commonDeletePhoto => 'Delete photo';

  @override
  String get commonCalendar => 'Calendar';

  @override
  String get commonDocumentsPdf => 'Documents (PDF)';

  @override
  String get commonStudentPdfSub => 'Student record';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonLogout => 'Sign out';

  @override
  String get commonPendingConnect => 'Pending connection';

  @override
  String get commonPasteRealScreenHint =>
      'Paste this screen into a real device';

  @override
  String get commonSelectDate => 'Select date';

  @override
  String get commonInvalidSessionAccountId => 'Invalid session (accountId)';

  @override
  String get commonNameLabel => 'Name';

  @override
  String get commonEnterName => 'Enter the name';

  @override
  String get commonLastNameLabel => 'Last name';

  @override
  String get commonEnterLastName => 'Enter the last name';

  @override
  String get commonEmailOptionalLabel => 'Email (optional)';

  @override
  String get commonInvalidEmail => 'Invalid email';

  @override
  String get commonPhoneOptionalLabel => 'Phone (optional)';

  @override
  String get commonSaveProfile => 'Save profile';

  @override
  String get commonClear => 'Limpiar';

  @override
  String get commonAll => 'All';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonEndOfResults => 'End of results';

  @override
  String get commonOwnerInvalid => 'Invalid owner';

  @override
  String get commonPerfilInvalid => 'Invalid profile';

  @override
  String get commonDeleteTitle => 'Delete';

  @override
  String get commonEvent => 'Event';

  @override
  String get commonPersonal => 'Personal';

  @override
  String get commonDate => 'Date';

  @override
  String get commonSpecialEvent => 'Special event';

  @override
  String get commonId => 'ID';

  @override
  String get commonMandatory => 'Required';

  @override
  String get commonDetail => 'Detail';

  @override
  String get commonAttendance => 'Attendance';

  @override
  String get commonAttendancePending => 'Pending';

  @override
  String get commonAttendanceYes => 'Attending';

  @override
  String get commonAttendanceMaybe => 'Maybe';

  @override
  String get commonAttendanceNo => 'Not attending';

  @override
  String get commonPolicy => 'Policy';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonMaybe => 'Maybe';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonPrevMonth => 'Previous month';

  @override
  String get commonNextMonth => 'Next month';

  @override
  String get commonEvents => 'Events';

  @override
  String get commonAlarm => 'Alarm';

  @override
  String get commonNoTime => 'No time';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonNew => 'New';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonNoteOptional => 'Note (optional)';

  @override
  String get commonTime => 'Time';

  @override
  String get commonChoose => 'Choose';

  @override
  String get commonView => 'View';

  @override
  String get commonShare => 'Share';

  @override
  String get commonGroup => 'Group';

  @override
  String get commonInstitutionUnavailable => 'Institution unavailable';

  @override
  String get commonRequestCreated => 'Request created';

  @override
  String commonScheduleLabel(Object value) {
    return 'Schedule: $value';
  }

  @override
  String commonAgeLabel(Object value) {
    return 'Age: $value';
  }

  @override
  String commonSlotsLabel(Object value) {
    return 'Slots: $value';
  }

  @override
  String commonProfileLabel(Object value) {
    return 'Profile: $value';
  }

  @override
  String commonInstitutionLabel(Object value) {
    return 'Institution: $value';
  }

  @override
  String commonActivityLabel(Object value) {
    return 'Activity: $value';
  }

  @override
  String commonTypeLabel(Object value) {
    return 'Type: $value';
  }

  @override
  String commonModuleKeyLabel(Object value) {
    return 'moduleKey: $value';
  }

  @override
  String commonAulaGrupoLabel(Object value) {
    return 'Room / Group: $value';
  }

  @override
  String commonShiftOrScheduleLabel(Object value) {
    return 'Shift or schedule: $value';
  }

  @override
  String get commonSend => 'Send';

  @override
  String get commonSending => 'Sending…';

  @override
  String get commonRequestSentOk => 'Request sent successfully';

  @override
  String get commonError => 'Error';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonFieldRequired => 'Required field';

  @override
  String get commonTooShort => 'Too short';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonPhoneInvalid => 'Invalid phone';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonContinuing => 'Continuing…';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonContinueToPlan => 'Continue to plan';

  @override
  String get commonPasswordRequired => 'Password required';

  @override
  String get commonForgotPassword => 'Forgot password';

  @override
  String get commonLoggingIn => 'Signing in…';

  @override
  String get commonLogin => 'Sign in';

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
  String get institucionAreaSemanticsCroquisLocked => 'Layout not available';

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
    return 'Emit card as notification';
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
  String get actionSelectAll => 'Select all';

  @override
  String get actionSelectNone => 'Select none';

  @override
  String get actionEmit => 'Emit';

  @override
  String institucionExtracBaseEmitirFichaDefaultTitle(Object module) {
    return 'Card';
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
    return 'Could not emit the card: $error';
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
  String get send => 'Send';
}
