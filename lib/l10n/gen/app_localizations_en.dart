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
  String get instituciones => 'Institutions';

  @override
  String get retry => 'Retry';

  @override
  String get curricular => 'Curricular';

  @override
  String get extracurricular => 'Extracurricular';

  @override
  String get code => 'Code';

  @override
  String get name => 'Name';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonInstitution => 'Institution';

  @override
  String get commonGenerating => 'Generating…';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailRequired => 'Enter your email.';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonNewPassword => 'New password';

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
  String get commonCreateAccount => 'Create account';

  @override
  String get commonCreating => 'Creating…';

  @override
  String get commonLogout => 'Sign out';

  @override
  String get commonNameLabel => 'Name';

  @override
  String get commonLastNameLabel => 'Last name';

  @override
  String get commonEmailOptionalLabel => 'Email (optional)';

  @override
  String get commonPhoneOptionalLabel => 'Phone (optional)';

  @override
  String get commonDate => 'Date';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonPrevMonth => 'Previous month';

  @override
  String get commonNextMonth => 'Next month';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonView => 'View';

  @override
  String get commonSending => 'Sending…';

  @override
  String get commonFieldRequired => 'Required field';

  @override
  String get commonTooShort => 'Too short';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonPhoneInvalid => 'Invalid phone';

  @override
  String get commonContinuing => 'Continuing…';

  @override
  String get commonContinueToPlan => 'Continue to plan';

  @override
  String get commonPasswordRequired => 'Password required';

  @override
  String get institucionRegistroSectionBasics => 'Basic details';

  @override
  String get institucionRegistroInstitutionName => 'Institution name';

  @override
  String get institucionRegistroCuit => 'CUIT (tax ID)';

  @override
  String get institucionRegistroCuitInvalid => 'Invalid CUIT.';

  @override
  String get institucionRegistroAddress => 'Address';

  @override
  String get institucionRegistroSectionLocation => 'Location';

  @override
  String get institucionRegistroCountry => 'Country';

  @override
  String get institucionRegistroProvince => 'Province / State';

  @override
  String get institucionRegistroCity => 'City';

  @override
  String get institucionRegistroSectionAccessContact => 'Access and contact';

  @override
  String get commonRequiredField => 'Required field.';

  @override
  String get uiSomethingWentWrong => 'Something went wrong';

  @override
  String get landingTagline => 'Connected education';

  @override
  String get landingHeadline => 'Students and institutions, in one place.';

  @override
  String get landingSubtitle =>
      'Enrollments, openings, documents and calendar — no paperwork, no back-and-forth.';

  @override
  String get landingStudentTitle => 'I\'m a student or family';

  @override
  String get landingStudentSubtitle =>
      'Find institutions, request a spot and track every step.';

  @override
  String get landingInstitutionTitle => 'I\'m an institution';

  @override
  String get landingInstitutionSubtitle =>
      'Manage openings, requests, groups and communications.';

  @override
  String get landingChooseHowToEnter => 'How would you like to sign in?';

  @override
  String get landingChooseHowToEnterSubtitle =>
      'Choose your profile to continue.';

  @override
  String get landingBulletRequests => 'Online enrollment requests';

  @override
  String get landingBulletDocuments => 'Records and documents as PDF';

  @override
  String get landingBulletCalendar => 'Calendar and instant notices';

  @override
  String landingFooter(Object year) {
    return '© $year ATENA · Education platform';
  }

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsTheme => 'Appearance';

  @override
  String get prefsThemeSystem => 'Automatic';

  @override
  String get prefsThemeLight => 'Light';

  @override
  String get prefsThemeDark => 'Dark';

  @override
  String get prefsLanguage => 'Language';

  @override
  String get prefsLanguageSystem => 'Automatic (device language)';

  @override
  String get authFamiliaLoginTitle => 'Sign in to your account';

  @override
  String get authFamiliaLoginSubtitle => 'Students and families';

  @override
  String get authInstitucionLoginTitle => 'Institution sign in';

  @override
  String get authInstitucionLoginSubtitle =>
      'Manage openings, requests and communications.';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authNoAccount => 'Don\'t have an account yet?';

  @override
  String get authNoInstitution => 'Is your institution not on ATENA yet?';

  @override
  String get authRegisterInstitution => 'Register institution';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authFamiliaRegisterTitle => 'Create your account';

  @override
  String get authFamiliaRegisterSubtitle =>
      'In two minutes you\'ll be able to find institutions and request a spot.';

  @override
  String get authStudentSection => 'Student details';

  @override
  String get authStudentSectionHelp =>
      'If you\'re a parent or guardian, enter the student\'s details. You can add more students to the same account later.';

  @override
  String get authAccessSection => 'Sign-in details';

  @override
  String get authBirthDate => 'Date of birth';

  @override
  String get authBirthDateRequired => 'Choose the date of birth.';

  @override
  String get authDniLabel => 'ID number (DNI)';

  @override
  String get authDniHelper => 'Numbers only, no dots.';

  @override
  String get authPasswordHelper => 'At least 8 characters.';

  @override
  String get authPasswordConfirm => 'Repeat the password';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetFamiliaSubtitle =>
      'Confirm your identity with the ID number of a student in the account and choose a new password.';

  @override
  String get authResetInstitucionSubtitle =>
      'Confirm your identity with the registered CUIT and choose a new password.';

  @override
  String get authResetDniLabel => 'ID number of a student in the account';

  @override
  String get authCuitHelper => '11 digits, no dashes.';

  @override
  String get authResetCta => 'Save new password';

  @override
  String get authResetDone =>
      'Done. You can now sign in with your new password.';

  @override
  String get authInstRegisterTitle => 'Register your institution';

  @override
  String get authInstRegisterSubtitle =>
      'Fill in the details and choose your plan\'s modules in the next step.';

  @override
  String authStepOf(Object step, Object total) {
    return 'Step $step of $total';
  }

  @override
  String get authErrInvalidEmail => 'The email is not valid.';

  @override
  String get authErrWeakPassword =>
      'The password must be at least 8 characters long.';

  @override
  String get authErrEmailInUse => 'An account with that email already exists.';

  @override
  String get authErrAccountNotFound =>
      'We couldn\'t find an account with those details.';

  @override
  String get authErrWrongCredentials => 'Incorrect email or password.';

  @override
  String get authErrInvalidDni => 'The ID number must have 7 to 9 digits.';

  @override
  String get authErrDuplicateDni =>
      'There\'s already a student with that ID number in your account.';

  @override
  String get authErrIdentityMismatch => 'The details don\'t match the account.';

  @override
  String get authErrInvalidName => 'Enter first and last name.';

  @override
  String get authErrInvalidAccount =>
      'The session is not valid. Please sign in again.';

  @override
  String get lblNivelJardin => 'Early childhood';

  @override
  String get lblNivelPrimaria => 'Primary';

  @override
  String get lblNivelSecundaria => 'Secondary';

  @override
  String get lblNivelTecnica => 'Technical';

  @override
  String get lblNivelTerciario => 'Higher education';

  @override
  String get lblBloqueDeporte => 'Sports & movement';

  @override
  String get lblBloqueArte => 'Arts & expression';

  @override
  String get lblBloqueIdiomas => 'Languages & communication';

  @override
  String get lblBloqueCiencia => 'Science, technology & robotics';

  @override
  String get lblBloqueApoyo => 'Academic support';

  @override
  String get lblBloqueBienestar => 'Personal growth & wellbeing';

  @override
  String get lblBloqueOtros => 'Other activities';

  @override
  String get lblTurnoManana => 'Morning';

  @override
  String get lblTurnoTarde => 'Afternoon';

  @override
  String get lblTurnoNoche => 'Evening';

  @override
  String get lblTurnoCompleto => 'Full day';

  @override
  String get lblModalidadPresencial => 'In person';

  @override
  String get lblModalidadRemoto => 'Online';

  @override
  String get lblModalidadHibrido => 'Hybrid';

  @override
  String get lblTipoInstJardin => 'Kindergarten';

  @override
  String get lblTipoInstPrimaria => 'Primary school';

  @override
  String get lblTipoInstSecundaria => 'Secondary school';

  @override
  String get lblTipoInstTecnica => 'Technical school';

  @override
  String get lblTipoInstTerciario => 'College';

  @override
  String get lblTipoInstTaller => 'Workshop or academy';

  @override
  String get lblTipoInstClub => 'Club';

  @override
  String get lblTipoInstOtra => 'Other institution';

  @override
  String get lblCurricular => 'Curricular';

  @override
  String get lblExtracurricular => 'Extracurricular';

  @override
  String get lblEstadoPendiente => 'Pending';

  @override
  String get lblEstadoConfirmada => 'Confirmed';

  @override
  String get lblEstadoRechazada => 'Declined';

  @override
  String get lblEstadoCanceladaAlumno => 'Cancelled';

  @override
  String get lblEstadoCanceladaInstitucion => 'Withdrawn';

  @override
  String get lblDocDni => 'Student ID (DNI)';

  @override
  String get lblDocDniResponsable => 'Guardian ID (DNI)';

  @override
  String get lblDocPartida => 'Birth certificate';

  @override
  String get lblDocCertMedico => 'Medical certificate';

  @override
  String get lblDocVacunas => 'Vaccination record';

  @override
  String get lblDocBoletin => 'Report card';

  @override
  String get lblDocPase => 'Transfer certificate';

  @override
  String get lblDocFoto => 'ID photo';

  @override
  String get lblDocDomicilio => 'Proof of address';

  @override
  String get lblDocOtro => 'Other document';

  @override
  String get lblDocEstadoPendiente => 'To submit';

  @override
  String get lblDocEstadoEntregado => 'Under review';

  @override
  String get lblDocEstadoAprobado => 'Approved';

  @override
  String get lblDocEstadoRechazado => 'Needs changes';

  @override
  String get lblDocEstadoCancelado => 'Cancelled';

  @override
  String get lblDocVencido => 'Overdue';

  @override
  String get lblEvGeneral => 'Event';

  @override
  String get lblEvReunion => 'Meeting';

  @override
  String get lblEvExamen => 'Exam';

  @override
  String get lblEvActo => 'School ceremony';

  @override
  String get lblEvSalida => 'Field trip';

  @override
  String get lblEvInicioClases => 'First day of classes';

  @override
  String get lblEvFinClases => 'Last day of classes';

  @override
  String get lblEvVacaciones => 'Holidays';

  @override
  String get lblEvFeriado => 'Public holiday';

  @override
  String get lblAsisSi => 'I\'ll attend';

  @override
  String get lblAsisTalVez => 'Maybe';

  @override
  String get lblAsisNo => 'I won\'t attend';

  @override
  String lblEdadAnios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years old',
      one: '1 year old',
    );
    return '$_temp0';
  }

  @override
  String lblRangoEdad(Object min, Object max) {
    return 'Ages $min to $max';
  }

  @override
  String lblEdadDesde(Object min) {
    return 'Ages $min+';
  }

  @override
  String lblEdadHasta(Object max) {
    return 'Up to age $max';
  }

  @override
  String lblCupos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n openings',
      one: '1 opening',
      zero: 'No openings',
    );
    return '$_temp0';
  }

  @override
  String lblCuposDeTotal(int libres, int total) {
    return '$libres of $total available';
  }

  @override
  String get notiBienvenidaTitle => 'Welcome to ATENA!';

  @override
  String get notiBienvenidaBody =>
      'You can now find institutions and request a spot.';

  @override
  String get notiSolicitudEnviadaTitle => 'Request sent';

  @override
  String notiSolicitudEnviadaBody(
    Object alumno,
    Object oferta,
    Object institucion,
  ) {
    return '$alumno · $oferta at $institucion. We\'ll let you know when they reply.';
  }

  @override
  String get notiSolicitudRecibidaTitle => 'New request';

  @override
  String notiSolicitudRecibidaBody(Object alumno, Object oferta) {
    return '$alumno requested a spot in $oferta.';
  }

  @override
  String get notiSolicitudConfirmadaTitle => 'Spot confirmed!';

  @override
  String notiSolicitudConfirmadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion confirmed $alumno in $oferta.';
  }

  @override
  String get notiSolicitudRechazadaTitle => 'Request declined';

  @override
  String notiSolicitudRechazadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion couldn\'t accept $alumno\'s request for $oferta.';
  }

  @override
  String get notiSolicitudCanceladaTitle => 'Request cancelled';

  @override
  String notiSolicitudCanceladaBody(Object alumno, Object oferta) {
    return '$alumno cancelled their request for $oferta.';
  }

  @override
  String get notiSolicitudBajaTitle => 'Spot withdrawn';

  @override
  String notiSolicitudBajaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  ) {
    return '$institucion withdrew $alumno from $oferta.';
  }

  @override
  String get notiDocSolicitadoTitle => 'A document was requested';

  @override
  String notiDocSolicitadoBody(Object institucion, Object documento) {
    return '$institucion needs: $documento.';
  }

  @override
  String get notiDocEntregadoTitle => 'Document received';

  @override
  String notiDocEntregadoBody(Object alumno, Object documento) {
    return '$alumno submitted: $documento.';
  }

  @override
  String get notiDocAprobadoTitle => 'Document approved';

  @override
  String notiDocAprobadoBody(Object institucion, Object documento) {
    return '$institucion approved: $documento.';
  }

  @override
  String get notiDocRechazadoTitle => 'Document needs changes';

  @override
  String notiDocRechazadoBody(Object institucion, Object documento) {
    return '$institucion asked to fix: $documento.';
  }

  @override
  String get notiEventoTitle => 'New calendar event';

  @override
  String notiEventoBody(Object institucion, Object evento, Object fecha) {
    return '$institucion: $evento, on $fecha.';
  }

  @override
  String notiAvisoDe(Object institucion) {
    return 'Notice from $institucion';
  }

  @override
  String notiNota(Object nota) {
    return 'Message: $nota';
  }

  @override
  String get errNoEncontrado =>
      'We couldn\'t find it. It may have been deleted.';

  @override
  String get errNoAutorizado => 'You don\'t have permission to do this.';

  @override
  String get errDatosInvalidos => 'Please check the information you entered.';

  @override
  String get errOfertaInactiva =>
      'This opening isn\'t taking requests right now.';

  @override
  String get errSinCupo => 'There are no openings left.';

  @override
  String get errSolicitudDuplicada =>
      'There\'s already an active request for this opening.';

  @override
  String get errEstadoInvalido => 'This action is no longer available.';

  @override
  String get errOfertaConSolicitudes =>
      'It can\'t be deleted because it has active requests. You can pause it instead.';

  @override
  String get errArchivoMuyGrande => 'The file is too large.';

  @override
  String get errFormatoNoSoportado =>
      'Unsupported format. Use a PDF or an image.';

  @override
  String get errSinEspacio =>
      'There isn\'t enough storage space on this device.';

  @override
  String get uiJustNow => 'Just now';

  @override
  String uiMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String uiHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String get uiYesterday => 'Yesterday';

  @override
  String get uiToday => 'Today';

  @override
  String get uiTomorrow => 'Tomorrow';

  @override
  String get uiUndo => 'Undo';

  @override
  String get uiMoreOptions => 'More options';

  @override
  String get uiSeeAll => 'See all';

  @override
  String get uiClose => 'Close';

  @override
  String get uiLogoutConfirm => 'Do you want to sign out?';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifMarkAllRead => 'Mark all as read';

  @override
  String get notifDeleteAll => 'Delete all';

  @override
  String get notifDeleteAllConfirm => 'Delete all notifications?';

  @override
  String get notifEmptyTitle => 'You\'re all caught up';

  @override
  String get notifEmptyBody =>
      'Updates about requests, documents and events will show up here.';

  @override
  String get notifFilterAll => 'All';

  @override
  String get notifFilterUnread => 'Unread';

  @override
  String get notifDeleted => 'Notification deleted';

  @override
  String get notifMarkRead => 'Mark as read';

  @override
  String get notifMarkUnread => 'Mark as unread';

  @override
  String get notifDelete => 'Delete';

  @override
  String notifUnreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String homeHello(Object nombre) {
    return 'Hi, $nombre';
  }

  @override
  String get homeStudentSubtitle => 'What would you like to do today?';

  @override
  String get homeSwitchStudent => 'Switch student';

  @override
  String get homeStatActiveRequests => 'Active requests';

  @override
  String get homeStatUpcomingEvents => 'Upcoming events';

  @override
  String get homeStatPendingDocs => 'Documents to submit';

  @override
  String get homeActionExplore => 'Explore institutions';

  @override
  String get homeActionExploreSub => 'Search and request a spot';

  @override
  String get homeActionRequests => 'My requests';

  @override
  String get homeActionRequestsSub => 'Track every request';

  @override
  String get homeActionCalendar => 'Calendar';

  @override
  String get homeActionCalendarSub => 'Events and reminders';

  @override
  String get homeActionDocuments => 'Documents';

  @override
  String get homeActionDocumentsSub => 'What institutions ask you for';

  @override
  String get homeActionNotificationsSub => 'News and notices';

  @override
  String get homeActionProfile => 'Student record';

  @override
  String get homeActionProfileSub => 'Personal details and PDF';

  @override
  String get homeRecentRequests => 'Your requests';

  @override
  String get homeNoRequestsTitle => 'You haven\'t requested a spot yet';

  @override
  String get homeNoRequestsBody =>
      'Explore institutions and send your first request in a few steps.';

  @override
  String get homeNoEvents => 'No upcoming events.';

  @override
  String get hubTitle => 'Which student do you want to continue with?';

  @override
  String get hubSubtitle =>
      'You can manage several students from the same account.';

  @override
  String get hubAddStudent => 'Add student';

  @override
  String get hubAddStudentSub => 'Add another child to your account';

  @override
  String get hubEmptyTitle => 'Add your first student';

  @override
  String get hubEmptyBody =>
      'Enter the student\'s details to start looking for institutions.';

  @override
  String get hubLastUsed => 'Last used';

  @override
  String hubAccountLine(Object email) {
    return 'Account: $email';
  }

  @override
  String get studentFormTitleNew => 'New student';

  @override
  String get studentFormTitleEdit => 'Edit details';

  @override
  String get studentFormSaved => 'Details saved.';

  @override
  String get studentFormCreated => 'Student added.';

  @override
  String get instHomeSubtitle => 'Institution dashboard';

  @override
  String instPlanTrialUntil(Object fecha) {
    return 'Trial until $fecha';
  }

  @override
  String get instPlanTrialEnded => 'Trial ended';

  @override
  String get instPlanActive => 'Active plan';

  @override
  String get instPlanSuspended => 'Plan suspended';

  @override
  String get instPlanNone => 'No plan';

  @override
  String get instStatPending => 'Pending requests';

  @override
  String get instStatStudents => 'Confirmed students';

  @override
  String get instStatFreeSpots => 'Available spots';

  @override
  String get instStatOffers => 'Active offerings';

  @override
  String get instActionRequests => 'Requests';

  @override
  String get instActionRequestsSub => 'Review and answer spot requests';

  @override
  String get instActionOffers => 'Openings';

  @override
  String get instActionOffersSub => 'Courses, groups and capacity';

  @override
  String get instActionStudents => 'Students';

  @override
  String get instActionStudentsSub => 'Enrolled by course and group';

  @override
  String get instActionComms => 'Communications';

  @override
  String get instActionCommsSub => 'Calendar and notices';

  @override
  String get instActionDocs => 'Documents';

  @override
  String get instActionDocsSub => 'Request and review documents';

  @override
  String get instActionCroquis => 'Seating plans';

  @override
  String get instActionCroquisSub => 'Classroom layouts';

  @override
  String get instActionProfile => 'Public profile';

  @override
  String get instActionProfileSub => 'How families see you';

  @override
  String get instActionPlan => 'Plan';

  @override
  String get instActionPlanSub => 'Levels, modules and price';

  @override
  String get instGettingStarted => 'Getting started';

  @override
  String get instGettingStartedSub =>
      'Complete these steps to start receiving students.';

  @override
  String get instStepProfile => 'Complete your public profile';

  @override
  String get instStepOffer => 'Publish your first opening';

  @override
  String get instStepRequest => 'Get your first request';

  @override
  String get instToReview => 'To review';

  @override
  String get instNoPending => 'No pending requests. All caught up!';

  @override
  String get instLoadError => 'We couldn\'t load the institution\'s data.';

  @override
  String get instSignInAgain => 'Sign in again';

  @override
  String get notifOlder => 'Earlier';

  @override
  String get prefsAbout => 'About ATENA';

  @override
  String prefsVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get prefsPrivacyTitle => 'Privacy and data';

  @override
  String get prefsPrivacyBody =>
      'In this version, ATENA stores all information (accounts, students, requests, documents and photos) only on this device. Nothing is sent to servers or third parties. Passwords are stored protected with a secure hash. You can delete your account at any time from the “More options” menu on your home screen.';

  @override
  String get prefsDeleteData => 'Delete all data on this device';

  @override
  String get prefsDeleteDataConfirmTitle => 'Delete all data?';

  @override
  String get prefsDeleteDataConfirm =>
      'All accounts, students, institutions, requests and documents stored on this device will be deleted. This can\'t be undone.';

  @override
  String get prefsDeleteDataCta => 'Delete everything';

  @override
  String get prefsDeleteDataDone => 'All data was deleted.';

  @override
  String get demoLink => 'Try it with sample data';

  @override
  String get demoConfirmTitle => 'Load sample data?';

  @override
  String get demoConfirmBody =>
      'We\'ll create three sample institutions and a sample family on this device so you can explore ATENA. You can delete them anytime from Preferences.';

  @override
  String get demoConfirmCta => 'Load sample';

  @override
  String get demoLoading => 'Preparing sample data…';

  @override
  String get demoReadyTitle => 'All set! You can now explore ATENA';

  @override
  String demoReadyBody(Object password) {
    return 'Use these sample accounts. The password for all of them is $password.';
  }

  @override
  String get demoFamilyLabel => 'Family with two students';

  @override
  String get demoInstitutionsLabel => 'Institutions';

  @override
  String get demoEnterFamily => 'Sign in as the family';

  @override
  String get demoEnterInstitution => 'Sign in as the school';

  @override
  String get demoAlreadyLoaded => 'The sample data was already loaded.';

  @override
  String get calAlTitulo => 'Calendar';

  @override
  String get calAlNuevaNota => 'New note';

  @override
  String get calAlEditarNota => 'Edit note';

  @override
  String get calAlEliminarNota => 'Delete note';

  @override
  String get calAlEliminarNotaConfirm => 'Delete this note?';

  @override
  String calAlEliminarNotaMensaje(String titulo) {
    return '“$titulo” will be removed from your calendar.';
  }

  @override
  String get calAlNotaGuardada => 'Note saved.';

  @override
  String get calAlNotaEliminada => 'Note deleted.';

  @override
  String get calAlNotaTituloHint => 'E.g. Bring the signed permission slip';

  @override
  String get calAlNotaHora => 'Time (optional)';

  @override
  String get calAlNotaQuitarHora => 'Clear time';

  @override
  String get calAlNotaDetalle => 'Details (optional)';

  @override
  String get calAlNotaPersonal => 'Personal note';

  @override
  String get calAlNotaAyuda => 'Your notes are private: only you can see them.';

  @override
  String get calAlTodoElDia => 'All day';

  @override
  String calAlRango(String desde, String hasta) {
    return 'From $desde to $hasta';
  }

  @override
  String get calAlCuando => 'When';

  @override
  String get calAlLugar => 'Where';

  @override
  String get calAlAsistenciaTitulo => 'Will you attend?';

  @override
  String get calAlAsistenciaAyuda =>
      'The institution is asking you to confirm your attendance.';

  @override
  String get calAlAsistenciaPasado => 'This event has already taken place.';

  @override
  String calAlAsistenciaGuardada(String respuesta) {
    return 'Response sent: $respuesta.';
  }

  @override
  String get calAlResponder => 'Please RSVP';

  @override
  String get calAlNadaEsteDia => 'Nothing scheduled for this day.';

  @override
  String get calAlAgregarNota => 'Add a note';

  @override
  String get calAlProximos => 'Coming up';

  @override
  String get calAlVacioTitulo => 'Your calendar is ready';

  @override
  String get calAlVacioMensaje =>
      'This is where you\'ll see the events posted by the institutions where your spot is confirmed: meetings, ceremonies, field trips and more. You can also add your own notes and reminders.';

  @override
  String get calAlSinEventos =>
      'Events from your institutions will appear here once a spot is confirmed.';

  @override
  String calAlDiaItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries',
      one: '1 entry',
      zero: 'Nothing scheduled',
    );
    return '$_temp0';
  }

  @override
  String get calAlEventoNoDisponible => 'This event is no longer available.';

  @override
  String get docAlTitulo => 'Documents';

  @override
  String docAlHeroPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'You have $n documents to submit',
      one: 'You have 1 document to submit',
    );
    return '$_temp0';
  }

  @override
  String get docAlHeroPendientesSub =>
      'Upload them right here: take a photo or choose a file.';

  @override
  String get docAlHeroAlDia => 'You\'re all set!';

  @override
  String get docAlHeroAlDiaSub =>
      'We\'ll let you know if an institution asks for something new.';

  @override
  String get docAlSeccionEntregar => 'To submit';

  @override
  String get docAlSeccionEntregarSub =>
      'Upload them to complete the enrollment.';

  @override
  String get docAlSeccionRevision => 'Under review';

  @override
  String get docAlSeccionRevisionSub =>
      'The institution is reviewing them. We\'ll let you know when they reply.';

  @override
  String get docAlSeccionAprobados => 'Approved';

  @override
  String get docAlSeccionHistorial => 'History';

  @override
  String get docAlSeccionHistorialSub =>
      'Requests cancelled by the institution';

  @override
  String get docAlNadaParaEntregar => 'You have no documents to submit.';

  @override
  String get docAlVacioTitulo => 'No pending documents';

  @override
  String get docAlVacioMensaje =>
      'When an institution asks you for a document, such as an ID or a medical certificate, you\'ll see it here and can upload it in a couple of steps.';

  @override
  String get docAlSubirArchivo => 'Upload file';

  @override
  String get docAlReemplazarArchivo => 'Replace file';

  @override
  String get docAlVerArchivo => 'View file';

  @override
  String get docAlSubiendo => 'Uploading…';

  @override
  String get docAlEntregado =>
      'Done! The document was sent to the institution.';

  @override
  String get docAlMotivo => 'Reason';

  @override
  String get docAlRechazadoSinMotivo =>
      'The institution asked you to upload it again.';

  @override
  String docAlEntregarHasta(String fecha) {
    return 'Due by $fecha';
  }

  @override
  String docAlVencio(String fecha) {
    return 'Was due on $fecha';
  }

  @override
  String get docAlVenceHoy => 'Due today';

  @override
  String get docAlVenceManiana => 'Due tomorrow';

  @override
  String docAlPedidoEl(String fecha) {
    return 'Requested on $fecha';
  }

  @override
  String docAlEntregadoEl(String fecha) {
    return 'Submitted on $fecha';
  }

  @override
  String docAlAprobadoEl(String fecha) {
    return 'Approved on $fecha';
  }

  @override
  String docAlCanceladoEl(String fecha) {
    return 'Cancelled on $fecha';
  }

  @override
  String get docAlIndicaciones => 'Instructions';

  @override
  String get docAlFechaPedido => 'Request date';

  @override
  String get docAlFechaLimite => 'Deadline';

  @override
  String get docAlArchivoEntregado => 'Submitted file';

  @override
  String get docAlAyudaPendiente =>
      'Upload the file so the institution can review it.';

  @override
  String get docAlAyudaVencido =>
      'The deadline has passed. Please upload it as soon as possible.';

  @override
  String get docAlAyudaRevision =>
      'The institution is reviewing it. If you uploaded the wrong file, you can replace it.';

  @override
  String get docAlAyudaAprobado =>
      'The institution approved this document. There\'s nothing else to do.';

  @override
  String get docAlAyudaCancelado =>
      'The institution cancelled this request. You no longer need to submit it.';

  @override
  String get docAlFuenteTitulo => 'How would you like to upload it?';

  @override
  String get docAlFuenteArchivo => 'Choose a file';

  @override
  String get docAlFuenteArchivoSub =>
      'PDF or image (JPG, PNG, WEBP or HEIC), up to 3 MB';

  @override
  String get docAlFuenteCamara => 'Take a photo';

  @override
  String get docAlFuenteCamaraSub => 'Photograph the document with your camera';

  @override
  String get docAlFuenteGaleria => 'Choose a photo';

  @override
  String get docAlFuenteGaleriaSub => 'From the images saved on your device';

  @override
  String get docAlFuenteTip =>
      'Tip: take the photo in good light and make sure the whole document is legible.';

  @override
  String get docAlErrorSeleccion =>
      'We couldn\'t open the file or the camera. Check the permissions and try again.';

  @override
  String get docAlErrorArchivo => 'We couldn\'t find the submitted file.';

  @override
  String get docAlErrorPdf =>
      'We couldn\'t open the PDF. Please try again in a few minutes.';

  @override
  String get docAlSinVistaPrevia =>
      'A preview isn\'t available for this image.';

  @override
  String get docAlNoDisponible => 'This request is no longer available.';

  @override
  String get fichaAlTitulo => 'Student record';

  @override
  String fichaAlDni(String dni) {
    return 'ID $dni';
  }

  @override
  String get fichaAlAgregarFoto => 'Add photo';

  @override
  String get fichaAlCambiarFoto => 'Change photo';

  @override
  String get fichaAlFotoCamara => 'Take a photo';

  @override
  String get fichaAlFotoGaleria => 'Choose from gallery';

  @override
  String get fichaAlFotoArchivo => 'Choose an image';

  @override
  String get fichaAlQuitarFoto => 'Remove photo';

  @override
  String get fichaAlQuitarFotoConfirm => 'Remove the photo?';

  @override
  String get fichaAlQuitarFotoMensaje =>
      'The student\'s initials will be shown instead.';

  @override
  String get fichaAlFotoGuardada => 'Photo updated.';

  @override
  String get fichaAlFotoEliminada => 'Photo removed.';

  @override
  String get fichaAlFotoError =>
      'We couldn\'t open the camera or the gallery. Check the permissions and try again.';

  @override
  String get fichaAlDatosPersonales => 'Personal details';

  @override
  String get fichaAlEditarDatos => 'Edit details';

  @override
  String get fichaAlInstituciones => 'Institutions';

  @override
  String get fichaAlInstitucionesSub =>
      'Where the student\'s spot is confirmed';

  @override
  String get fichaAlSinInstituciones =>
      'No confirmed spots yet. When an institution confirms a request, you\'ll see it here.';

  @override
  String fichaAlConfirmadaEl(String fecha) {
    return 'Confirmed on $fecha';
  }

  @override
  String get fichaAlPdf => 'PDF record';

  @override
  String get fichaAlPdfSub => 'To hand in to an institution or keep a copy';

  @override
  String get fichaAlDescargarPdf => 'Download record as PDF';

  @override
  String get fichaAlDescargarPdfSub =>
      'With personal details, photo and institutions';

  @override
  String get fichaAlImprimir => 'Print';

  @override
  String get fichaAlImprimirSub => 'Open the preview to print the record';

  @override
  String get fichaAlGenerando => 'Generating PDF…';

  @override
  String get fichaAlPdfError =>
      'We couldn\'t generate the PDF. Please try again in a few minutes.';

  @override
  String get ofertasNueva => 'New opening';

  @override
  String get ofertasErrorCarga => 'We couldn\'t load the openings.';

  @override
  String get ofertasSinPlanTitulo =>
      'Your plan doesn\'t include any levels or activities yet';

  @override
  String get ofertasSinPlanMensaje =>
      'To publish openings, enable curricular levels or extracurricular activities under Plan, in your institution dashboard.';

  @override
  String get ofertasVolverPanel => 'Back to dashboard';

  @override
  String get ofertasTipoFueraDelPlan =>
      'Your current plan doesn\'t include this type of opening. You can still edit, pause or delete the ones you\'ve published.';

  @override
  String get ofertasFueraDelPlan => 'Not in your plan';

  @override
  String get ofertasVacioCurricularTitulo =>
      'You haven\'t published any curricular openings yet';

  @override
  String get ofertasVacioCurricularMensaje =>
      'Create your grades, years or classes with their capacity so families can request a spot.';

  @override
  String get ofertasVacioExtraTitulo =>
      'You haven\'t published any extracurricular activities yet';

  @override
  String get ofertasVacioExtraMensaje =>
      'Add workshops, sports or languages with their capacity and schedule so families can sign up.';

  @override
  String ofertasNOfertas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n offerings',
      one: '1 offering',
    );
    return '$_temp0';
  }

  @override
  String ofertasNLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n spots left',
      one: '1 spot left',
      zero: 'No spots left',
    );
    return '$_temp0';
  }

  @override
  String ofertasAgregarEn(Object categoria) {
    return 'Add opening in $categoria';
  }

  @override
  String get ofertasActiva => 'Active';

  @override
  String get ofertasPausada => 'Paused';

  @override
  String get ofertasCompleta => 'Full';

  @override
  String ofertasConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n confirmed',
      one: '1 confirmed',
      zero: 'None confirmed',
    );
    return '$_temp0';
  }

  @override
  String ofertasPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pending',
      one: '1 pending',
    );
    return '$_temp0';
  }

  @override
  String ofertasOcupacion(int confirmados, int total) {
    return '$confirmados of $total spots taken';
  }

  @override
  String get ofertasPausar => 'Pause';

  @override
  String get ofertasReanudar => 'Resume';

  @override
  String get ofertasDuplicar => 'Duplicate';

  @override
  String get ofertasVerSolicitudes => 'View requests';

  @override
  String get ofertasPausadaOk =>
      'Opening paused: it won\'t receive new requests.';

  @override
  String get ofertasReanudadaOk =>
      'Opening resumed: it\'s accepting requests again.';

  @override
  String ofertasEliminarTitulo(Object nombre) {
    return 'Delete “$nombre”?';
  }

  @override
  String get ofertasEliminarMensaje =>
      'Families won\'t see it anymore. This can\'t be undone.';

  @override
  String get ofertasEliminadaOk => 'Opening deleted.';

  @override
  String get ofertasFormEditar => 'Edit opening';

  @override
  String get ofertasFormDuplicar => 'Duplicate opening';

  @override
  String ofertasFormCopiaAviso(Object nombre) {
    return 'You\'re creating a copy of “$nombre”. Change what you need (the group, for example) and save it.';
  }

  @override
  String ofertasFormConfirmadosAviso(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'This opening has $n confirmed students. Requests already sent keep the original details.',
      one:
          'This opening has 1 confirmed student. Requests already sent keep the original details.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasSeccionTipo => 'Opening type';

  @override
  String get ofertasTipoCurricularDesc => 'Grades, years and classes';

  @override
  String get ofertasTipoExtraDesc => 'Workshops, sports and activities';

  @override
  String get ofertasSeccionNivel => 'Level';

  @override
  String get ofertasSeccionCategoria => 'Category';

  @override
  String get ofertasElegiNivel => 'Choose a level.';

  @override
  String get ofertasElegiCategoria => 'Choose a category.';

  @override
  String get ofertasSeccionDatos => 'Opening details';

  @override
  String get ofertasTituloCurricularLabel => 'Grade, year or class';

  @override
  String get ofertasTituloExtraLabel => 'Activity';

  @override
  String get ofertasSugerenciasAyuda => 'Tap a suggestion or type your own.';

  @override
  String ofertasSugSala(int n) {
    return 'Age $n class';
  }

  @override
  String ofertasSugGrado(int n) {
    return 'Grade $n';
  }

  @override
  String ofertasSugAnio(int n) {
    return 'Year $n';
  }

  @override
  String get ofertasEjemplosGeneral => 'E.g., Soccer, English, Robotics';

  @override
  String get ofertasEjemplosDeporte => 'E.g., Soccer, Volleyball, Swimming';

  @override
  String get ofertasEjemplosArte => 'E.g., Drama, Choir, Painting';

  @override
  String get ofertasEjemplosIdiomas =>
      'E.g., Beginner English, Portuguese, Public speaking';

  @override
  String get ofertasEjemplosCiencia => 'E.g., Robotics, Coding, Science club';

  @override
  String get ofertasEjemplosApoyo => 'E.g., Homework help, Study skills';

  @override
  String get ofertasEjemplosBienestar =>
      'E.g., Yoga, Emotions workshop, Career guidance';

  @override
  String get ofertasEjemplosOtros => 'E.g., Chess, Cooking, Gardening';

  @override
  String get ofertasGrupoLabel => 'Section or group (optional)';

  @override
  String get ofertasGrupoHelper => 'E.g., A, B, Saturday group';

  @override
  String get ofertasSeccionHorario => 'Shift and schedule';

  @override
  String get ofertasTurnoLabel => 'Shift';

  @override
  String get ofertasHoraDesde => 'From';

  @override
  String get ofertasHoraHasta => 'To';

  @override
  String ofertasHorarioRango(Object desde, Object hasta) {
    return '$desde to $hasta';
  }

  @override
  String get ofertasHorarioInvalido =>
      'The end time must be later than the start time.';

  @override
  String get ofertasHorarioIncompleto =>
      'Fill in both times or leave both empty.';

  @override
  String ofertasHorarioActual(Object horario) {
    return 'Current schedule: $horario. Pick the times to replace it.';
  }

  @override
  String get ofertasQuitarHorario => 'Clear schedule';

  @override
  String get ofertasDiasLabel => 'Days';

  @override
  String get ofertasDiaLun => 'Mon';

  @override
  String get ofertasDiaMar => 'Tue';

  @override
  String get ofertasDiaMie => 'Wed';

  @override
  String get ofertasDiaJue => 'Thu';

  @override
  String get ofertasDiaVie => 'Fri';

  @override
  String get ofertasDiaSab => 'Sat';

  @override
  String get ofertasDiaDom => 'Sun';

  @override
  String ofertasDiasRango(Object desde, Object hasta) {
    return '$desde to $hasta';
  }

  @override
  String ofertasDiasLista(Object lista, Object ultimo) {
    return '$lista and $ultimo';
  }

  @override
  String get ofertasDiasTodos => 'Every day';

  @override
  String ofertasDiasActual(Object dias) {
    return 'Current days: $dias. Select them to replace them.';
  }

  @override
  String get ofertasSeccionCupo => 'Capacity and requirements';

  @override
  String get ofertasCupoLabel => 'Total capacity';

  @override
  String get ofertasCupoHelper => 'How many students can enroll.';

  @override
  String ofertasCupoConfirmadosHelper(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students are confirmed.',
      one: '1 student is confirmed.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasCupoMinimo => 'Capacity must be at least 1.';

  @override
  String ofertasCupoMenorConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students are already confirmed: capacity can\'t be lower.',
      one: '1 student is already confirmed: capacity can\'t be lower.',
    );
    return '$_temp0';
  }

  @override
  String get ofertasRestarUno => 'Decrease';

  @override
  String get ofertasSumarUno => 'Increase';

  @override
  String get ofertasEdadMinLabel => 'Minimum age';

  @override
  String get ofertasEdadMaxLabel => 'Maximum age';

  @override
  String get ofertasAniosSufijo => 'years';

  @override
  String get ofertasEdadHelper =>
      'Optional: leave them empty if there\'s no age limit.';

  @override
  String get ofertasEdadRangoInvalido =>
      'Must be equal to or greater than the minimum age.';

  @override
  String get ofertasArancelLabel => 'Fee (optional)';

  @override
  String get ofertasArancelHelper =>
      'E.g., \$150 per month. Leave it empty if it\'s free.';

  @override
  String get ofertasDescripcionLabel => 'Description (optional)';

  @override
  String get ofertasDescripcionHelper =>
      'Tell families what\'s included, requirements or materials.';

  @override
  String get ofertasSeccionPublicacion => 'Visibility';

  @override
  String get ofertasActivaLabel => 'Accepting requests';

  @override
  String get ofertasActivaOn => 'Active: families can request a spot.';

  @override
  String get ofertasActivaOff =>
      'Paused: families can\'t request a spot for now.';

  @override
  String get ofertasCrear => 'Create opening';

  @override
  String get ofertasCreadaOk => 'Opening created.';

  @override
  String get ofertasGuardadaOk => 'Changes saved.';

  @override
  String get ofertasDescartarTitulo => 'Discard changes?';

  @override
  String get ofertasDescartarMensaje => 'The changes you made won\'t be saved.';

  @override
  String get ofertasDescartar => 'Discard';

  @override
  String get ofertasRevisaCampos => 'Please check the highlighted fields.';

  @override
  String get crqNuevo => 'New seating plan';

  @override
  String get crqErrorCarga => 'We couldn\'t load the seating plans.';

  @override
  String get crqVacioTitulo => 'You haven\'t created any seating plans yet';

  @override
  String get crqVacioMensaje =>
      'Lay out the desks in each classroom and seat your students. You can export it as a PDF later.';

  @override
  String crqFilasColumnas(int filas, int columnas) {
    return '$filas × $columnas desks';
  }

  @override
  String crqOcupados(int ocupados, int total) {
    return '$ocupados of $total seats taken';
  }

  @override
  String get crqSinVacante => 'No linked opening';

  @override
  String get crqVacanteAsociada => 'Linked opening';

  @override
  String get crqVacanteAsociadaHelper =>
      'We\'ll suggest its confirmed students when you assign desks.';

  @override
  String get crqVacanteNoDisponible => 'The linked opening no longer exists';

  @override
  String get crqCambiarVacante => 'Change linked opening';

  @override
  String get crqAsociarVacante => 'Link an opening';

  @override
  String get crqVacanteActualizada => 'Linked opening updated.';

  @override
  String get crqNombreLabel => 'Seating plan name';

  @override
  String get crqNombreHelper => 'E.g., Grade 1 A, Room 3, Lab';

  @override
  String get crqFilas => 'Rows';

  @override
  String get crqColumnas => 'Columns';

  @override
  String get crqQuitarUno => 'Remove one';

  @override
  String get crqAgregarUno => 'Add one';

  @override
  String get crqCrear => 'Create seating plan';

  @override
  String get crqVistaPrevia => 'Preview';

  @override
  String get crqFrente => 'Front of the classroom · Board';

  @override
  String crqBanco(int n) {
    return 'Desk $n';
  }

  @override
  String get crqBancoLibre => 'Empty';

  @override
  String get crqAyuda =>
      'Tap a desk to seat a student. Press and hold, then drag to move them.';

  @override
  String get crqAyudaScroll => 'Swipe sideways to see the whole classroom.';

  @override
  String crqOcupadoPor(Object nombre) {
    return 'Taken by $nombre';
  }

  @override
  String get crqBuscarAlumno => 'Search student';

  @override
  String crqAlumnosDeVacante(Object oferta) {
    return 'Confirmed students in $oferta';
  }

  @override
  String get crqAlumnosInstitucion => 'Confirmed students at the institution';

  @override
  String get crqTodosSentados => 'All confirmed students already have a desk.';

  @override
  String get crqSinConfirmados =>
      'There are no confirmed students yet. You can type a name.';

  @override
  String get crqSinResultados => 'No students match your search.';

  @override
  String get crqErrorAlumnos =>
      'We couldn\'t load the confirmed students. You can type a name.';

  @override
  String get crqNombreLibre => 'Or type a name';

  @override
  String get crqNombreLibreLabel => 'Full name';

  @override
  String get crqAsignar => 'Seat';

  @override
  String get crqDejarLibre => 'Leave empty';

  @override
  String crqMovidoDesde(Object nombre, int desde, int hasta) {
    return '$nombre moved from desk $desde to desk $hasta.';
  }

  @override
  String get crqGuardado => 'Saved';

  @override
  String get crqSinGuardar => 'Not saved';

  @override
  String get crqErrorGuardar =>
      'We couldn\'t save the last change. Tap “Not saved” to try again.';

  @override
  String get crqRenombrar => 'Rename';

  @override
  String get crqRenombrarTitulo => 'Rename seating plan';

  @override
  String get crqTamanoCorto => 'Size';

  @override
  String get crqTamanoTitulo => 'Classroom size';

  @override
  String get crqTamanoAyuda =>
      'Rows go from the board to the back; columns go from left to right.';

  @override
  String crqTamanoPierde(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n students would end up outside the classroom and be removed from the plan.',
      one:
          '1 student would end up outside the classroom and be removed from the plan.',
    );
    return '$_temp0';
  }

  @override
  String get crqTamanoConfirmarTitulo => 'Make the classroom smaller?';

  @override
  String get crqAplicar => 'Apply';

  @override
  String get crqVaciar => 'Clear';

  @override
  String get crqVaciarTitulo => 'Clear the seating plan?';

  @override
  String crqVaciarMensaje(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n taken seats will be freed. The desk layout stays the same.',
      one: '1 taken seat will be freed. The desk layout stays the same.',
    );
    return '$_temp0';
  }

  @override
  String get crqVaciadoOk => 'Seating plan cleared.';

  @override
  String get crqYaVacio => 'The seating plan is already empty.';

  @override
  String get crqPdfCorto => 'PDF';

  @override
  String get crqExportarPdf => 'Export PDF';

  @override
  String get crqPdfError =>
      'We couldn\'t generate the PDF. Please try again in a moment.';

  @override
  String crqPdfArchivo(Object nombre) {
    return 'seating_plan_$nombre';
  }

  @override
  String crqEliminarTitulo(Object nombre) {
    return 'Delete “$nombre”?';
  }

  @override
  String get crqEliminarMensaje =>
      'The desk layout will be deleted. This can\'t be undone.';

  @override
  String get crqEliminadoOk => 'Seating plan deleted.';

  @override
  String get comInstTitle => 'Communications';

  @override
  String get comInstTabCalendario => 'Calendar';

  @override
  String get comInstTabAvisos => 'Notices';

  @override
  String get comInstLoadError => 'We couldn\'t load your communications.';

  @override
  String get comInstProximos => 'Upcoming';

  @override
  String get comInstPasados => 'Past';

  @override
  String get comInstNuevoEvento => 'New event';

  @override
  String get comInstEditarEvento => 'Edit event';

  @override
  String get comInstEliminarEvento => 'Delete event';

  @override
  String get comInstTodoElDia => 'All day';

  @override
  String comInstRangoFechas(Object desde, Object hasta) {
    return 'From $desde to $hasta';
  }

  @override
  String get comInstParaTodos => 'All students';

  @override
  String get comInstEnCurso => 'Happening now';

  @override
  String get comInstOfertaEliminada => 'Deleted class or group';

  @override
  String comInstYMas(Object nombres, int n) {
    return '$nombres and $n more';
  }

  @override
  String comInstAsistiran(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n attending',
      one: '1 attending',
    );
    return '$_temp0';
  }

  @override
  String comInstTalVez(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n maybe',
      one: '1 maybe',
    );
    return '$_temp0';
  }

  @override
  String comInstNoAsistiran(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n not attending',
      one: '1 not attending',
    );
    return '$_temp0';
  }

  @override
  String get comInstSinRespuestas => 'No replies yet';

  @override
  String get comInstSinProximosTitulo => 'No upcoming events';

  @override
  String get comInstSinProximosMensaje =>
      'Publish meetings, ceremonies, exams or holidays: they appear in each family\'s calendar and families get notified.';

  @override
  String get comInstSinPasadosTitulo => 'No past events yet';

  @override
  String get comInstSinPasadosMensaje =>
      'Events that have already taken place will appear here.';

  @override
  String get comInstSeccionTipo => 'Event type';

  @override
  String get comInstSeccionTipoAyuda =>
      'It helps families recognize it at a glance.';

  @override
  String get comInstSeccionDatos => 'Event details';

  @override
  String get comInstCampoTitulo => 'Title';

  @override
  String get comInstCampoTituloAyuda => 'E.g.: 1st grade family meeting';

  @override
  String get comInstCampoDescripcion => 'Description (optional)';

  @override
  String get comInstCampoDescripcionAyuda =>
      'What families need to know: what to bring, how to get there, times.';

  @override
  String get comInstCampoLugar => 'Place (optional)';

  @override
  String get comInstSeccionCuando => 'When';

  @override
  String get comInstCampoFecha => 'Date';

  @override
  String get comInstCampoFechaFin => 'End date (optional)';

  @override
  String get comInstCampoFechaFinAyuda =>
      'For events lasting several days, like holidays.';

  @override
  String get comInstQuitarFechaFin => 'Remove end date';

  @override
  String get comInstErrorFecha => 'Choose a date.';

  @override
  String get comInstErrorFechaFin => 'It must be after the start date.';

  @override
  String get comInstTodoElDiaAyuda => 'Turn it off to set a start time.';

  @override
  String get comInstCampoHora => 'Start time';

  @override
  String get comInstErrorHora => 'Choose a start time.';

  @override
  String get comInstSeccionDestinatarios => 'Recipients';

  @override
  String get comInstSeccionDestinatariosAyuda =>
      'Families of confirmed students receive it.';

  @override
  String get comInstDestOfertas => 'Classes or groups';

  @override
  String get comInstDestElegirAyuda => 'Choose one or more classes or groups.';

  @override
  String get comInstDestErrorVacio => 'Choose at least one class or group.';

  @override
  String get comInstDestSinOfertas =>
      'Once you publish openings, you\'ll be able to pick specific classes or groups.';

  @override
  String comInstAlumnosConfirmados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n confirmed students',
      one: '1 confirmed student',
      zero: 'No confirmed students',
    );
    return '$_temp0';
  }

  @override
  String get comInstPedirConfirmacion => 'Ask families to RSVP';

  @override
  String get comInstPedirConfirmacionAyuda =>
      'Families can reply whether they\'ll attend, and you\'ll see the replies here.';

  @override
  String comInstSeAvisaraA(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students will be notified',
      one: '1 student will be notified',
    );
    return '$_temp0';
  }

  @override
  String get comInstSeAvisaraAyuda =>
      'They\'ll get a notification and the event will appear in their calendar.';

  @override
  String get comInstCalculando => 'Counting recipients…';

  @override
  String get comInstSinDestinatariosEvento =>
      'There are no confirmed students in this selection yet. Nobody will be notified now, but the event will appear in the calendar of anyone who joins later.';

  @override
  String get comInstEditarSinAviso =>
      'Changes are saved without sending a new notification.';

  @override
  String get comInstPublicar => 'Publish event';

  @override
  String get comInstPublicando => 'Publishing…';

  @override
  String get comInstGuardarCambios => 'Save changes';

  @override
  String comInstEventoPublicado(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Event published. We notified $n students.',
      one: 'Event published. We notified 1 student.',
      zero: 'Event published.',
    );
    return '$_temp0';
  }

  @override
  String get comInstEventoActualizado => 'Changes saved.';

  @override
  String get comInstEventoEliminado => 'Event deleted.';

  @override
  String get comInstEliminarEventoTitulo => 'Delete this event?';

  @override
  String get comInstEliminarEventoMensaje =>
      'It will be removed from families\' calendars along with its replies. This can\'t be undone.';

  @override
  String get comInstDescartarTitulo => 'Discard changes?';

  @override
  String get comInstDescartarMensaje => 'What you\'ve entered won\'t be saved.';

  @override
  String get comInstDescartar => 'Discard';

  @override
  String get comInstSeguirEditando => 'Keep editing';

  @override
  String get comInstDetalleTitulo => 'Event details';

  @override
  String get comInstInfoFecha => 'Date';

  @override
  String get comInstInfoHorario => 'Time';

  @override
  String get comInstInfoLugar => 'Place';

  @override
  String get comInstInfoAlcance => 'Students reached';

  @override
  String get comInstInfoDescripcion => 'Description';

  @override
  String comInstPublicadoEl(Object fecha) {
    return 'Published on $fecha';
  }

  @override
  String get comInstRespuestasTitulo => 'Attendance replies';

  @override
  String comInstRespuestasConteo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n replies',
      one: '1 reply',
      zero: 'No replies yet',
    );
    return '$_temp0';
  }

  @override
  String get comInstStatAsistiran => 'Attending';

  @override
  String get comInstStatTalVez => 'Maybe';

  @override
  String get comInstStatNoAsistiran => 'Not attending';

  @override
  String get comInstStatSinResponder => 'No reply yet';

  @override
  String get comInstSinRespuestasDetalle =>
      'No one has replied yet. Replies will show up here as families respond.';

  @override
  String get comInstNoPideConfirmacion =>
      'This event doesn\'t ask for an RSVP. You can turn it on by editing the event.';

  @override
  String get comInstNuevoAviso => 'New notice';

  @override
  String get comInstNuevoAvisoAyuda =>
      'It reaches the families of your confirmed students as a notification.';

  @override
  String get comInstAvisoCampoTituloAyuda => 'E.g.: Change in pick-up time';

  @override
  String get comInstAvisoCampoMensaje => 'Message';

  @override
  String comInstLlegaraA(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'It will reach $n students',
      one: 'It will reach 1 student',
    );
    return '$_temp0';
  }

  @override
  String get comInstSinDestinatariosAviso =>
      'There are no confirmed students in this selection yet. Once you confirm requests, you\'ll be able to send them notices.';

  @override
  String get comInstEnviarAviso => 'Send notice';

  @override
  String comInstConfirmarEnvio(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Send to $n students?',
      one: 'Send to 1 student?',
    );
    return '$_temp0';
  }

  @override
  String get comInstConfirmarEnvioMensaje =>
      'Families get it as a notification. Once sent, it can\'t be edited or deleted.';

  @override
  String comInstAvisoEnviado(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Notice sent to $n students.',
      one: 'Notice sent to 1 student.',
    );
    return '$_temp0';
  }

  @override
  String get comInstAvisosVacioTitulo => 'You haven\'t sent any notices yet';

  @override
  String get comInstAvisosVacioMensaje =>
      'Notices reach the families of confirmed students as notifications. Use them for reminders, schedule changes or news.';

  @override
  String get comInstAvisosEnviados => 'Sent notices';

  @override
  String comInstAvisoAlcance(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Reached $n students',
      one: 'Reached 1 student',
      zero: 'Didn\'t reach any students',
    );
    return '$_temp0';
  }

  @override
  String comInstEnviadoEl(Object fecha) {
    return 'Sent on $fecha';
  }

  @override
  String get docInstTitle => 'Documents';

  @override
  String get docInstTabRevisar => 'To review';

  @override
  String get docInstTabPendientes => 'Pending';

  @override
  String get docInstTabAprobados => 'Approved';

  @override
  String get docInstTabCancelados => 'Cancelled';

  @override
  String get docInstLoadError => 'We couldn\'t load the documents.';

  @override
  String get docInstPedirDocumento => 'Request document';

  @override
  String docInstPedidoEl(Object fecha) {
    return 'Requested on $fecha';
  }

  @override
  String docInstLimite(Object fecha) {
    return 'Due: $fecha';
  }

  @override
  String docInstEntregadoEl(Object fecha) {
    return 'Submitted on $fecha';
  }

  @override
  String get docInstVacioRevisarTitulo => 'Nothing to review';

  @override
  String get docInstVacioRevisarMensaje =>
      'When a family uploads a document you requested, it will show up here.';

  @override
  String get docInstVacioPendientesTitulo => 'No pending requests';

  @override
  String get docInstVacioPendientesMensaje =>
      'Ask for IDs, birth certificates, medical forms and more. The family gets notified and uploads it from the app.';

  @override
  String get docInstVacioAprobadosTitulo => 'No approved documents yet';

  @override
  String get docInstVacioAprobadosMensaje =>
      'Documents you approve are kept here.';

  @override
  String get docInstVacioCanceladosTitulo => 'No cancelled requests';

  @override
  String get docInstVacioCanceladosMensaje =>
      'If you cancel a request you no longer need, it will show up here.';

  @override
  String get docInstPedirTitulo => 'Request a document';

  @override
  String get docInstPedirAyuda =>
      'We\'ll notify the family so they can upload it from the app.';

  @override
  String get docInstElegirAlumno => 'Which student?';

  @override
  String get docInstBuscarAlumno => 'Search by name or ID number';

  @override
  String get docInstLimpiarBusqueda => 'Clear search';

  @override
  String get docInstSinResultados => 'No students match your search.';

  @override
  String get docInstSinAlumnosTitulo => 'You don\'t have any students yet';

  @override
  String get docInstSinAlumnosMensaje =>
      'You can request documents from students with pending or confirmed requests. Once you receive your first request, you\'ll be able to do it from here.';

  @override
  String get docInstSolicitudPendiente => 'Pending request';

  @override
  String get docInstCambiarAlumno => 'Change';

  @override
  String get docInstQueDocumento => 'Which document do you need?';

  @override
  String get docInstIndicacionesLabel => 'Instructions (optional)';

  @override
  String get docInstIndicacionesAyuda => 'E.g.: Copy of both sides';

  @override
  String get docInstNombreOtroLabel => 'Document name';

  @override
  String get docInstNombreOtroAyuda => 'E.g.: Field trip permission slip';

  @override
  String get docInstFechaLimiteLabel => 'Due date (optional)';

  @override
  String get docInstQuitarFechaLimite => 'Remove due date';

  @override
  String docInstPedidoEnviado(Object documento, Object alumno) {
    return 'Request sent: $documento · $alumno';
  }

  @override
  String get docInstDetalleTitulo => 'Document request';

  @override
  String get docInstAlumno => 'Student';

  @override
  String get docInstFechaPedido => 'Requested on';

  @override
  String get docInstFechaLimite => 'Due date';

  @override
  String get docInstSinFechaLimite => 'No due date';

  @override
  String get docInstIndicaciones => 'Instructions';

  @override
  String get docInstEsperandoArchivo =>
      'Waiting for the family to upload the file.';

  @override
  String get docInstRevisarAyuda =>
      'Check the file, then approve it or request changes.';

  @override
  String get docInstMotivoCorreccion => 'You requested changes';

  @override
  String docInstAprobadoInfo(Object fecha) {
    return 'Approved on $fecha.';
  }

  @override
  String docInstCanceladoInfo(Object fecha) {
    return 'You cancelled this request on $fecha.';
  }

  @override
  String get docInstArchivoEntregado => 'Submitted file';

  @override
  String get docInstArchivoAnterior => 'Last submitted file';

  @override
  String docInstSubidoEl(Object fecha) {
    return 'Uploaded on $fecha';
  }

  @override
  String get docInstTipoPdf => 'PDF document';

  @override
  String get docInstTipoImagen => 'Image';

  @override
  String get docInstTipoArchivo => 'File';

  @override
  String docInstTamanoKb(Object n) {
    return '$n KB';
  }

  @override
  String docInstTamanoMb(Object n) {
    return '$n MB';
  }

  @override
  String get docInstVerArchivo => 'View file';

  @override
  String get docInstDescargar => 'Download';

  @override
  String get docInstArchivoError =>
      'We couldn\'t open the file. Please try again in a moment.';

  @override
  String get docInstSinVistaPrevia =>
      'There\'s no preview for this format. Download it to view it.';

  @override
  String get docInstAprobar => 'Approve';

  @override
  String get docInstPedirCorreccion => 'Request changes';

  @override
  String get docInstAprobarTitulo => 'Approve this document?';

  @override
  String docInstAprobarMensaje(Object alumno) {
    return 'We\'ll let $alumno\'s family know.';
  }

  @override
  String get docInstAprobado => 'Document approved.';

  @override
  String get docInstCorreccionAyuda =>
      'Tell the family what needs to be fixed. They\'ll be able to upload a new file.';

  @override
  String get docInstMotivoLabel => 'Reason';

  @override
  String get docInstMotivoAyuda =>
      'E.g.: The photo is blurry and the number can\'t be read.';

  @override
  String get docInstMotivoRequerido => 'Tell them what needs fixing.';

  @override
  String get docInstCorreccionEnviada => 'We asked the family for changes.';

  @override
  String get docInstCancelarPedido => 'Cancel request';

  @override
  String get docInstCancelarTitulo => 'Cancel this request?';

  @override
  String get docInstCancelarMensaje =>
      'The family won\'t need to submit it anymore. This can\'t be undone.';

  @override
  String get docInstMantener => 'Keep it';

  @override
  String get docInstPedidoCancelado => 'Request cancelled.';

  @override
  String pdfGeneradoCon(String fecha) {
    return 'Generated with ATENA · $fecha';
  }

  @override
  String pdfPagina(int actual, int total) {
    return 'Page $actual of $total';
  }

  @override
  String get pdfNombre => 'First name';

  @override
  String get pdfApellido => 'Last name';

  @override
  String get pdfApellidoNombre => 'Last name, first name';

  @override
  String get pdfDni => 'ID number';

  @override
  String pdfDniValor(String dni) {
    return 'ID $dni';
  }

  @override
  String get pdfFechaNacimiento => 'Date of birth';

  @override
  String get pdfEdad => 'Age';

  @override
  String get pdfEmail => 'Email';

  @override
  String get pdfTelefono => 'Phone';

  @override
  String get pdfContacto => 'Contact';

  @override
  String get pdfInstitucion => 'Institution';

  @override
  String get pdfOferta => 'Offering';

  @override
  String get pdfCategoria => 'Category';

  @override
  String get pdfTurno => 'Shift';

  @override
  String get pdfHorario => 'Schedule';

  @override
  String get pdfDias => 'Days';

  @override
  String get pdfEdades => 'Ages';

  @override
  String get pdfEstado => 'Status';

  @override
  String get pdfFecha => 'Date';

  @override
  String get pdfNota => 'Note';

  @override
  String get pdfFichaTitulo => 'Student record';

  @override
  String get pdfDatosPersonales => 'Personal details';

  @override
  String get pdfSolicitudes => 'Requests';

  @override
  String pdfSolicitudesCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n requests',
      one: '1 request',
      zero: 'No requests',
    );
    return '$_temp0';
  }

  @override
  String get pdfSinSolicitudes => 'There are no requests yet.';

  @override
  String get pdfComprobanteTitulo => 'Request receipt';

  @override
  String get pdfCodigo => 'Reference';

  @override
  String get pdfEnviadaEl => 'Submitted on';

  @override
  String get pdfEmitidoEl => 'Issued on';

  @override
  String get pdfEstadoActual => 'Current status';

  @override
  String get pdfVacanteSolicitada => 'Requested spot';

  @override
  String get pdfAlumno => 'Student';

  @override
  String get pdfMensajeAlumno => 'Message from the student';

  @override
  String get pdfRespuestaInstitucion => 'Response from the institution';

  @override
  String get pdfHistorial => 'History';

  @override
  String get pdfComprobanteAclaracion =>
      'This receipt reflects the status of the request at the time it was issued.';

  @override
  String get pdfEstadoDescPendiente =>
      'The institution hasn\'t responded to this request yet.';

  @override
  String get pdfEstadoDescConfirmada => 'The institution confirmed the spot.';

  @override
  String get pdfEstadoDescRechazada => 'The institution declined the request.';

  @override
  String get pdfEstadoDescCanceladaAlumno =>
      'The request was cancelled by the student or their family.';

  @override
  String get pdfEstadoDescCanceladaInstitucion =>
      'The institution withdrew the spot.';

  @override
  String get pdfListadoTitulo => 'Confirmed students';

  @override
  String get pdfTotal => 'Total';

  @override
  String pdfAlumnosCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students',
      one: '1 student',
      zero: 'No students',
    );
    return '$_temp0';
  }

  @override
  String get pdfListadoVacio => 'There are no confirmed students to show.';

  @override
  String get pdfCroquisTitulo => 'Classroom seating chart';

  @override
  String get pdfFrenteAula => 'Front of the classroom';

  @override
  String get pdfLugares => 'Seats';

  @override
  String get pdfOcupados => 'Occupied';

  @override
  String get pdfLibres => 'Available';

  @override
  String get pdfLugarOcupado => 'Occupied';

  @override
  String get pdfLugarLibre => 'Available';

  @override
  String get solInstTabPendientes => 'Pending';

  @override
  String get solInstTabConfirmadas => 'Confirmed';

  @override
  String get solInstTabNoAceptadas => 'Declined';

  @override
  String get solInstTabCanceladas => 'Cancelled';

  @override
  String get solInstBuscarHint => 'Search by name or ID number';

  @override
  String get solInstLimpiarBusqueda => 'Clear search';

  @override
  String get solInstFiltrarVacante => 'Filter by opening';

  @override
  String get solInstVacanteFiltro => 'Opening';

  @override
  String get solInstTodasLasVacantes => 'All openings';

  @override
  String get solInstQuitarFiltro => 'Remove filter';

  @override
  String get solInstOrdenLlegada => 'In order of arrival: oldest first.';

  @override
  String solInstDni(Object dni) {
    return 'ID $dni';
  }

  @override
  String get solInstConMensaje => 'The family left a message';

  @override
  String get solInstConfirmar => 'Confirm';

  @override
  String get solInstNoAceptar => 'Decline';

  @override
  String get solInstConfirmarVacante => 'Confirm spot';

  @override
  String get solInstDarDeBaja => 'Withdraw student';

  @override
  String get solInstPedirDocumento => 'Request a document';

  @override
  String get solInstDescargarComprobante => 'Download receipt';

  @override
  String get solInstPdfError =>
      'We couldn\'t create the PDF. Please try again in a few minutes.';

  @override
  String get solInstArchivoComprobante => 'receipt';

  @override
  String get solInstVacioInicialTitulo => 'No requests yet';

  @override
  String get solInstVacioInicialMsg =>
      'Families send you requests from your public page on ATENA. Publish your openings and complete your public profile so they can find you more easily.';

  @override
  String get solInstIrAVacantes => 'Go to Openings';

  @override
  String get solInstVacioPendientesTitulo => 'No pending requests';

  @override
  String get solInstVacioPendientesMsg =>
      'You\'re all caught up! New requests will show up here for you to review.';

  @override
  String get solInstVacioConfirmadasTitulo => 'No confirmed spots yet';

  @override
  String get solInstVacioConfirmadasMsg =>
      'When you confirm a request, it will show up here and the student will be listed in Students.';

  @override
  String get solInstVacioNoAceptadasTitulo => 'No declined requests';

  @override
  String get solInstVacioNoAceptadasMsg =>
      'Requests you decline will show up here, along with the reason you gave the family.';

  @override
  String get solInstVacioCanceladasTitulo => 'No cancelled requests';

  @override
  String get solInstVacioCanceladasMsg =>
      'Requests cancelled by families and students you withdrew will show up here.';

  @override
  String get solInstSinResultadosTitulo => 'No results';

  @override
  String get solInstSinResultadosMsg => 'No requests match these filters.';

  @override
  String get solInstLimpiarFiltros => 'Clear filters';

  @override
  String solInstRecibidaEl(Object fecha, Object hora) {
    return 'Received on $fecha at $hora';
  }

  @override
  String solInstConfirmadaEl(Object fecha, Object hora) {
    return 'Confirmed on $fecha at $hora';
  }

  @override
  String solInstRechazadaEl(Object fecha, Object hora) {
    return 'Declined on $fecha at $hora';
  }

  @override
  String solInstCanceladaEl(Object fecha, Object hora) {
    return 'Cancelled by the family on $fecha at $hora';
  }

  @override
  String solInstBajaEl(Object fecha, Object hora) {
    return 'Withdrawn on $fecha at $hora';
  }

  @override
  String get solInstSecContacto => 'Contact';

  @override
  String get solInstSecVacante => 'Requested opening';

  @override
  String get solInstSecMensaje => 'Message from the family';

  @override
  String get solInstSecHistorial => 'History';

  @override
  String get solInstSinContacto =>
      'The family didn\'t leave an email or phone number.';

  @override
  String get solInstLlamar => 'Call';

  @override
  String get solInstWhatsapp => 'WhatsApp';

  @override
  String get solInstEscribirEmail => 'Send email';

  @override
  String get solInstCopiar => 'Copy';

  @override
  String get solInstCopiado => 'Copied to clipboard.';

  @override
  String get solInstNoSePudoAbrir =>
      'We couldn\'t open that app on this device. You can copy the details and use them elsewhere.';

  @override
  String get solInstOcupacion => 'Occupancy';

  @override
  String solInstPendientesOferta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pending requests for this opening',
      one: '1 pending request for this opening',
    );
    return '$_temp0';
  }

  @override
  String get solInstVacanteNoDisponible =>
      'This opening is no longer published.';

  @override
  String get solInstVacantePausada => 'Paused';

  @override
  String get solInstVacanteCompleta => 'Full';

  @override
  String get solInstSinCupoAviso =>
      'There are no spots left in this opening. To confirm, increase its capacity in Openings.';

  @override
  String solInstEdadFueraDeRango(Object edad, Object rango) {
    return 'The student\'s age ($edad) is outside this opening\'s range ($rango).';
  }

  @override
  String get solInstHistRecibida => 'Request received';

  @override
  String get solInstHistConfirmada => 'Spot confirmed';

  @override
  String get solInstHistRechazada => 'Request declined';

  @override
  String get solInstHistCanceladaFamilia => 'Cancelled by the family';

  @override
  String get solInstHistBaja => 'Spot withdrawn';

  @override
  String solInstOkConfirmada(Object alumno) {
    return '$alumno\'s spot is confirmed. We let the family know.';
  }

  @override
  String solInstOkRechazada(Object alumno) {
    return '$alumno\'s request was declined. We let the family know.';
  }

  @override
  String solInstOkBaja(Object alumno) {
    return '$alumno was withdrawn. We let the family know.';
  }

  @override
  String solInstOkDocumento(Object documento) {
    return 'Request sent: $documento. We let the family know.';
  }

  @override
  String get solInstConfirmarTitulo => 'Confirm this spot?';

  @override
  String solInstConfirmarMsg(Object alumno, Object oferta) {
    return 'You\'re confirming $alumno for $oferta. The family will be notified right away.';
  }

  @override
  String get solInstNotaFamiliaLabel => 'Message for the family (optional)';

  @override
  String get solInstNotaConfirmarHelper =>
      'For example: interview date or what to bring on the first day.';

  @override
  String get solInstRechazarTitulo => 'Decline this request?';

  @override
  String solInstRechazarMsg(Object alumno) {
    return 'Let $alumno\'s family know why you can\'t accept the request. They\'ll receive this message.';
  }

  @override
  String get solInstMotivosFrecuentes => 'Common reasons';

  @override
  String get solInstMotivoSinVacantes => 'No spots left';

  @override
  String get solInstMotivoSinVacantesTexto =>
      'There are no spots left in this opening.';

  @override
  String get solInstMotivoEdad => 'Age out of range';

  @override
  String get solInstMotivoEdadTexto =>
      'The student\'s age doesn\'t match the age range for this opening.';

  @override
  String get solInstMotivoDocumentacion => 'Incomplete documents';

  @override
  String get solInstMotivoDocumentacionTexto =>
      'The documents submitted are incomplete.';

  @override
  String get solInstMotivoOtro => 'Other';

  @override
  String get solInstMotivoLabel => 'Reason for the family';

  @override
  String get solInstMotivoRequerido => 'Please write a reason for the family.';

  @override
  String solInstBajaTitulo(Object alumno) {
    return 'Withdraw $alumno?';
  }

  @override
  String solInstBajaMsg(Object oferta) {
    return 'Their spot in $oferta will be freed and the family will be notified. This can\'t be undone.';
  }

  @override
  String get solInstNotaBajaHelper =>
      'For example: the reason for the withdrawal.';

  @override
  String get solInstSinCupoTitulo => 'No spots left';

  @override
  String solInstSinCupoMsg(Object oferta) {
    return '$oferta is already full. To confirm this request, increase its capacity in Openings.';
  }

  @override
  String solInstDocPara(Object alumno) {
    return 'For $alumno';
  }

  @override
  String get solInstDocAyuda =>
      'The family is notified right away and can upload the file from the app.';

  @override
  String get solInstDocTipoLabel => 'Which document do you need?';

  @override
  String get solInstDocTipoRequerido => 'Choose a document.';

  @override
  String get solInstDocNombreLabel => 'Document name';

  @override
  String get solInstDocNombreRequerido =>
      'Tell the family which document you need.';

  @override
  String get solInstDocDetalleLabel => 'Instructions (optional)';

  @override
  String get solInstDocDetalleHelper => 'For example: a copy of both sides.';

  @override
  String get solInstDocFechaLimite => 'Due date (optional)';

  @override
  String get solInstDocQuitarFecha => 'Remove date';

  @override
  String get solInstDocEnviar => 'Send request';

  @override
  String alumInstSubtitulo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n confirmed students',
      one: '1 confirmed student',
      zero: 'No confirmed students',
    );
    return '$_temp0';
  }

  @override
  String get alumInstExportarPdf => 'Export list (PDF)';

  @override
  String alumInstExportarSeccion(Object oferta) {
    return 'Export $oferta list (PDF)';
  }

  @override
  String alumInstCantidad(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get alumInstVacioTitulo => 'No confirmed students yet';

  @override
  String get alumInstVacioMsg =>
      'Students show up here, grouped by opening, as you confirm their requests.';

  @override
  String alumInstRevisarSolicitudes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Review $n pending requests',
      one: 'Review 1 pending request',
    );
    return '$_temp0';
  }

  @override
  String get alumInstSinResultadosMsg =>
      'No students match that name or ID number.';

  @override
  String get alumInstArchivoListado => 'students';

  @override
  String get notiCuentaEliminadaTitle => 'A family deleted their account';

  @override
  String notiCuentaEliminadaBody(Object alumno, Object oferta) {
    return '$alumno is no longer in $oferta: their family deleted the account and the spot is free again.';
  }

  @override
  String notiInstitucionEliminadaTitle(Object institucion) {
    return '$institucion left ATENA';
  }

  @override
  String notiInstitucionEliminadaBody(Object alumno, Object oferta) {
    return '$alumno\'s request for $oferta was closed because the institution deleted its account.';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete the account?';

  @override
  String get deleteAccountFamilyBody =>
      'The account, its students and their requests, documents, notes and notifications will be deleted. Institutions will be notified and confirmed spots will be released.';

  @override
  String get deleteAccountInstitutionBody =>
      'The institution, its openings, events, announcements, seating plans, document requests and public profile will be deleted. Families with active requests will be notified.';

  @override
  String get deleteAccountIrreversible => 'This action cannot be undone.';

  @override
  String get deleteAccountPasswordHelper => 'Enter your password to confirm.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get deleteAccountDone => 'The account was deleted.';

  @override
  String get deleteAccountWrongPassword => 'The password is not correct.';

  @override
  String get perfInstTitulo => 'Institution profile';

  @override
  String get perfInstTabDatos => 'Details';

  @override
  String get perfInstTabPublico => 'Public profile';

  @override
  String get perfInstTabVista => 'Preview';

  @override
  String get perfInstErrorCarga => 'We couldn\'t load the institution profile.';

  @override
  String get perfInstSecIdentidad => 'Identification';

  @override
  String get perfInstSecIdentidadAyuda =>
      'This is how your institution appears on ATENA and in the family search.';

  @override
  String get perfInstNombre => 'Institution name';

  @override
  String get perfInstNombreCorto =>
      'The name must be at least 3 characters long.';

  @override
  String get perfInstCuit => 'Tax ID (CUIT)';

  @override
  String get perfInstCuitAyuda =>
      '11 digits, no dashes. We use it to verify your identity if you forget your password.';

  @override
  String get perfInstTipo => 'Type of institution';

  @override
  String get perfInstModalidad => 'Learning format';

  @override
  String get perfInstSecUbicacion => 'Location';

  @override
  String get perfInstDireccion => 'Address';

  @override
  String get perfInstCiudad => 'City';

  @override
  String get perfInstProvincia => 'State or province';

  @override
  String get perfInstPais => 'Country';

  @override
  String get perfInstSecAdmin => 'Administrative contact';

  @override
  String get perfInstSecAdminAyuda =>
      'We use it to get in touch with your institution. It doesn\'t change your sign-in email; contact details for families go in your Public profile.';

  @override
  String get perfInstEmailAdmin => 'Contact email';

  @override
  String get perfInstTelefonoInvalido =>
      'Check the number: it must have between 8 and 15 digits.';

  @override
  String perfInstCompleto(int pct) {
    return 'Your profile is $pct% complete';
  }

  @override
  String get perfInstCompletoListo => 'Your profile is complete!';

  @override
  String get perfInstCompletoAyuda =>
      'A complete profile helps families get to know you and choose you.';

  @override
  String get perfInstCompletoListoAyuda =>
      'Families can now see everything you offer.';

  @override
  String perfInstPorcentaje(int pct) {
    return '$pct%';
  }

  @override
  String get perfInstConsejoLogo => 'Upload your institution\'s logo.';

  @override
  String perfInstConsejoDescripcion(int min) {
    return 'Write a description of at least $min characters.';
  }

  @override
  String perfInstConsejoFotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n more photos of your spaces.',
      one: 'Add 1 more photo of your spaces.',
    );
    return '$_temp0';
  }

  @override
  String get perfInstConsejoAtencion => 'Add your office hours.';

  @override
  String get perfInstConsejoClases => 'Tell families when classes take place.';

  @override
  String get perfInstConsejoTelefono =>
      'Add a phone or WhatsApp number so families can reach you.';

  @override
  String get perfInstConsejoEmailWeb => 'Add an email address or your website.';

  @override
  String get perfInstConsejoRedes => 'Link at least one social network.';

  @override
  String get perfInstConsejoServicios => 'List the services you offer.';

  @override
  String get perfInstSecImagenes => 'Logo and photos';

  @override
  String get perfInstLogo => 'Logo';

  @override
  String get perfInstLogoAyuda =>
      'Square JPG or PNG image, up to 1.5 MB. It shows in search results and on your page.';

  @override
  String get perfInstLogoSubir => 'Upload logo';

  @override
  String get perfInstLogoCambiar => 'Change logo';

  @override
  String get perfInstLogoQuitar => 'Remove logo';

  @override
  String get perfInstLogoQuitarTitulo => 'Remove the logo?';

  @override
  String get perfInstLogoQuitarMensaje =>
      'Families will see your institution\'s initials instead.';

  @override
  String get perfInstLogoListo => 'Logo updated.';

  @override
  String get perfInstLogoQuitado => 'Logo removed.';

  @override
  String get perfInstFotos => 'Photos';

  @override
  String perfInstFotosCantidad(int n, int max) {
    return '$n of $max';
  }

  @override
  String perfInstFotosAyuda(int max) {
    return 'Show your spaces: classrooms, playground, labs and activities. Up to $max photos of 1.5 MB.';
  }

  @override
  String get perfInstFotoAgregar => 'Add photo';

  @override
  String get perfInstFotoQuitar => 'Remove photo';

  @override
  String get perfInstFotoQuitarTitulo => 'Remove this photo?';

  @override
  String get perfInstFotoQuitarMensaje =>
      'The photo will be deleted from your public profile.';

  @override
  String get perfInstFotoAgregada => 'Photo added.';

  @override
  String get perfInstFotoQuitada => 'Photo deleted.';

  @override
  String perfInstFotoVer(int n) {
    return 'View photo $n';
  }

  @override
  String get perfInstFotoNoDisponible => 'Photo unavailable';

  @override
  String get perfInstGaleriaError =>
      'We couldn\'t open your images. Check the permissions and try again.';

  @override
  String get perfInstSecSobre => 'About the institution';

  @override
  String get perfInstDescripcion => 'Description';

  @override
  String get perfInstDescripcionHint =>
      'Describe your educational approach, your values and what makes your institution unique.';

  @override
  String get perfInstSecHorarios => 'Hours';

  @override
  String get perfInstHorarioAtencion => 'Office hours';

  @override
  String get perfInstHorarioAtencionHint =>
      'E.g. Monday to Friday, 8 am to 4 pm';

  @override
  String get perfInstHorarioClases => 'Class hours';

  @override
  String get perfInstHorarioClasesHint =>
      'E.g. morning shift, 7:30 am to 12:30 pm';

  @override
  String get perfInstSecContacto => 'Contact for families';

  @override
  String get perfInstSecContactoAyuda =>
      'Families see this on your page. Add at least one way to reach you.';

  @override
  String get perfInstWhatsapp => 'WhatsApp';

  @override
  String get perfInstWhatsappAyuda => 'Include the area code.';

  @override
  String get perfInstEmailFamilias => 'Email for families';

  @override
  String get perfInstWeb => 'Website';

  @override
  String get perfInstWebHint => 'yourschool.edu';

  @override
  String get perfInstWebInvalida => 'Enter a valid web address.';

  @override
  String get perfInstSecRedes => 'Social media';

  @override
  String get perfInstSecRedesAyuda =>
      'Type your @username or paste the link to your page.';

  @override
  String get perfInstInstagram => 'Instagram';

  @override
  String get perfInstFacebook => 'Facebook';

  @override
  String get perfInstYoutube => 'YouTube';

  @override
  String get perfInstRedInvalida => 'Enter a valid @username or link.';

  @override
  String get perfInstSecServicios => 'Services';

  @override
  String get perfInstSecServiciosAyuda =>
      'Tell families what you offer beyond classes.';

  @override
  String get perfInstServicioAgregar => 'Add service';

  @override
  String get perfInstServicioHint => 'E.g. school garden';

  @override
  String perfInstServicioQuitar(Object servicio) {
    return 'Remove $servicio';
  }

  @override
  String get perfInstServiciosSugeridos => 'Suggestions';

  @override
  String perfInstServiciosMax(int max) {
    return 'You can add up to $max services.';
  }

  @override
  String get perfInstServicioRepetido => 'That service is already on the list.';

  @override
  String get perfInstSrvComedor => 'Cafeteria';

  @override
  String get perfInstSrvTransporte => 'School bus';

  @override
  String get perfInstSrvGabinete => 'Educational psychology team';

  @override
  String get perfInstSrvJornadaExtendida => 'Extended school day';

  @override
  String get perfInstSrvBilingue => 'Bilingual education';

  @override
  String get perfInstSrvDeportes => 'Sports';

  @override
  String get perfInstSrvBecas => 'Scholarships';

  @override
  String get perfInstSrvLaboratorio => 'Laboratory';

  @override
  String get perfInstSrvBiblioteca => 'Library';

  @override
  String get perfInstSrvAccesibilidad => 'Accessibility';

  @override
  String get perfInstCambiosPendientes => 'You have unsaved changes';

  @override
  String get perfInstDescartar => 'Discard';

  @override
  String get perfInstDescartarTitulo => 'Discard changes?';

  @override
  String get perfInstDescartarMensaje =>
      'You\'ll lose everything you changed since you last saved.';

  @override
  String get perfInstGuardado => 'Changes saved.';

  @override
  String get perfInstRevisarCampos => 'Please check the highlighted fields.';

  @override
  String get perfInstSalirTitulo => 'Leave without saving?';

  @override
  String get perfInstSalirMensaje =>
      'You have unsaved changes. If you leave now, they\'ll be lost.';

  @override
  String get perfInstSalir => 'Leave without saving';

  @override
  String get perfInstVistaTitulo => 'This is how families see you';

  @override
  String get perfInstVistaAyuda =>
      'It\'s the page they see when they find you on ATENA.';

  @override
  String get perfInstVistaSinGuardar =>
      'It includes changes you haven\'t saved yet.';

  @override
  String get perfInstVistaCompletar => 'Complete profile';

  @override
  String get perfInstVistaSinDescripcion => 'No description yet.';

  @override
  String get perfInstVistaContacto => 'Contact';

  @override
  String get perfInstVistaSinContacto => 'No contact details yet.';

  @override
  String get perfInstSinNombre => 'Your institution';

  @override
  String get plnTitulo => 'Choose your plan';

  @override
  String get plnHeroTitulo => 'Build a plan that fits you';

  @override
  String get plnHeroAyuda =>
      'You only pay for the levels and modules you use, and you can change them anytime.';

  @override
  String plnPrueba(int dias) {
    return '$dias-day free trial';
  }

  @override
  String get plnSinPagos => 'No payments for now';

  @override
  String get plnFlexible => 'Change it anytime';

  @override
  String get plnNiveles => 'Curricular levels';

  @override
  String plnNivelesAyuda(Object precio) {
    return 'Classes and grades of your official curriculum · $precio per level per month';
  }

  @override
  String get plnModulos => 'Extracurricular modules';

  @override
  String plnModulosAyuda(Object precio) {
    return 'Workshops and after-school activities · $precio per module per month';
  }

  @override
  String plnPorMes(Object precio) {
    return '$precio / month';
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
      'Soccer, swimming, gymnastics, martial arts and more.';

  @override
  String get plnBloqueArte => 'Music, theater, dance and visual arts.';

  @override
  String get plnBloqueIdiomas =>
      'Languages, conversation, speaking and writing.';

  @override
  String get plnBloqueCiencia => 'Robotics, coding and STEAM projects.';

  @override
  String get plnBloqueApoyo => 'Tutoring, study skills and exam prep.';

  @override
  String get plnBloqueBienestar =>
      'Well-being, social-emotional skills and career guidance.';

  @override
  String get plnBloqueOtros => 'Programs that don\'t fit the other categories.';

  @override
  String plnVacantesActivas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n published openings',
      one: '1 published opening',
    );
    return '$_temp0';
  }

  @override
  String plnSePausan(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n openings will be paused',
      one: '1 opening will be paused',
    );
    return '$_temp0';
  }

  @override
  String get plnPromoTitulo => 'Do you have a promo code?';

  @override
  String get plnPromoCampo => 'Code';

  @override
  String get plnPromoHint => 'Enter your code';

  @override
  String get plnPromoAplicar => 'Apply';

  @override
  String get plnPromoVacio => 'Enter a code.';

  @override
  String get plnPromoInvalido =>
      'That code isn\'t valid. Check it and try again.';

  @override
  String get plnPromoAgotado => 'This code has reached its usage limit.';

  @override
  String plnPromoValido(int pct) {
    return 'Code applied! You get $pct% off.';
  }

  @override
  String plnPromoActivo(int pct) {
    return 'You have an active promo code: $pct% off.';
  }

  @override
  String get plnPromoQuitar => 'Remove code';

  @override
  String get plnResumen => 'Summary';

  @override
  String plnResumenNiveles(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n curricular levels',
      one: '1 curricular level',
    );
    return '$_temp0';
  }

  @override
  String plnResumenModulos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n extracurricular modules',
      one: '1 extracurricular module',
    );
    return '$_temp0';
  }

  @override
  String get plnSubtotal => 'Subtotal';

  @override
  String plnDescuentoVolumen(int min, int pct) {
    return 'Discount for $min or more items ($pct%)';
  }

  @override
  String plnDescuentoPromo(int pct) {
    return 'Promo code ($pct%)';
  }

  @override
  String get plnTotalMes => 'Monthly total';

  @override
  String plnFaltanItems(int n, int pct) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n more items and get $pct% off.',
      one: 'Add 1 more item and get $pct% off.',
    );
    return '$_temp0';
  }

  @override
  String get plnElegiAlMenosUno =>
      'Choose at least one level or module to build your plan.';

  @override
  String get plnElegiAlMenosUnoCorto => 'Choose at least one level or module';

  @override
  String get plnPruebaTexto =>
      'Nothing is charged during the trial; we\'ll let you know before enabling payments.';

  @override
  String plnPruebaEmpieza(int dias) {
    return 'Your $dias-day free trial starts when you save your changes.';
  }

  @override
  String plnPruebaTerminada(Object fecha) {
    return 'Your trial ended on $fecha. Payments aren\'t enabled yet: we\'ll let you know before charging anything.';
  }

  @override
  String get plnSinCobros =>
      'Payments aren\'t enabled on ATENA yet: you won\'t be charged anything without prior notice.';

  @override
  String get plnGratisTitulo => 'No-cost plan';

  @override
  String get plnGratisTexto =>
      'With your promo code, your plan is active at no cost.';

  @override
  String plnDiasRestantes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days of trial left.',
      one: '1 day of trial left.',
      zero: 'Today is the last day of your trial.',
    );
    return '$_temp0';
  }

  @override
  String get plnCrear => 'Create institution';

  @override
  String get plnCreando => 'Creating…';

  @override
  String get plnGuardar => 'Save changes';

  @override
  String get plnCreada => 'All set! Your institution is now on ATENA.';

  @override
  String get plnGuardado => 'Plan updated.';

  @override
  String plnPausadas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Plan updated. $n openings were paused.',
      one: 'Plan updated. 1 opening was paused.',
    );
    return '$_temp0';
  }

  @override
  String get plnCorregirDatos => 'Edit my details';

  @override
  String get plnPausarTitulo => 'Pause published openings?';

  @override
  String plnPausarMensaje(Object categorias, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'We\'ll pause $n published openings so families no longer see them.',
      one: 'We\'ll pause 1 published opening so families no longer see it.',
    );
    return 'You removed $categorias from your plan. $_temp0 You can reactivate them when you add the category back.';
  }

  @override
  String get plnPausarAccion => 'Save and pause';

  @override
  String get plnErrorCarga => 'We couldn\'t load your plan.';

  @override
  String get plnTuPlan => 'Your plan';

  @override
  String plnPlanActual(Object precio) {
    return 'Current plan: $precio per month';
  }

  @override
  String get explorarTitulo => 'Explore institutions';

  @override
  String explorarPara(Object nombre) {
    return 'For $nombre';
  }

  @override
  String get explorarBuscarHint => 'Search by name, city or province';

  @override
  String get explorarBorrarBusqueda => 'Clear search';

  @override
  String get explorarFiltros => 'Filters';

  @override
  String get explorarFiltroNivel => 'Level';

  @override
  String get explorarFiltroActividad => 'Activities';

  @override
  String get explorarFiltroModalidad => 'Format';

  @override
  String get explorarCualquierNivel => 'Any level';

  @override
  String get explorarCualquierActividad => 'Any activity';

  @override
  String get explorarCualquierModalidad => 'Any format';

  @override
  String explorarConLugarPara(Object nombre) {
    return 'With openings for $nombre';
  }

  @override
  String explorarConLugarAyuda(Object nombre, Object edad) {
    return 'Only institutions with openings for $nombre\'s age ($edad).';
  }

  @override
  String get explorarLimpiarFiltros => 'Clear filters';

  @override
  String explorarResultados(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n institutions',
      one: '1 institution',
    );
    return '$_temp0';
  }

  @override
  String get explorarVacioTitulo => 'No institutions published yet';

  @override
  String get explorarVacioMensaje =>
      'Institutions show up here as they join ATENA. Check back soon.';

  @override
  String get explorarSinResultadosTitulo => 'No institutions found';

  @override
  String get explorarSinResultadosMensaje =>
      'Try different words or remove a filter to see more options.';

  @override
  String get explorarVerInstitucion => 'View institution';

  @override
  String explorarFotoDe(int n, int total) {
    return 'Photo $n of $total';
  }

  @override
  String get explorarVerFotos => 'View photos full screen';

  @override
  String get explorarFotoAnterior => 'Previous photo';

  @override
  String get explorarFotoSiguiente => 'Next photo';

  @override
  String get explorarSobre => 'About the institution';

  @override
  String get explorarLeerMas => 'Read more';

  @override
  String get explorarLeerMenos => 'Show less';

  @override
  String get explorarHorarios => 'Hours';

  @override
  String get explorarHorarioAtencion => 'Office hours';

  @override
  String get explorarHorarioClases => 'Classes';

  @override
  String get explorarServicios => 'Services';

  @override
  String get explorarContacto => 'Contact';

  @override
  String get explorarLlamar => 'Call';

  @override
  String get explorarWhatsapp => 'WhatsApp';

  @override
  String get explorarSitioWeb => 'Website';

  @override
  String get explorarInstagram => 'Instagram';

  @override
  String get explorarFacebook => 'Facebook';

  @override
  String get explorarYoutube => 'YouTube';

  @override
  String get explorarComoLlegar => 'Get directions';

  @override
  String get explorarNoSePudoAbrir =>
      'We couldn\'t open this on your device. Please try again later.';

  @override
  String get explorarVacantes => 'Openings';

  @override
  String explorarPropuestas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n programs',
      one: '1 program',
    );
    return '$_temp0';
  }

  @override
  String get explorarSinVacantesTitulo => 'No openings published yet';

  @override
  String get explorarSinVacantesMensaje =>
      'This institution hasn\'t published any courses or activities yet. You can contact them to ask.';

  @override
  String get explorarPedirVacante => 'Request a spot';

  @override
  String get explorarVerSolicitud => 'View request';

  @override
  String get explorarCompleto => 'Full';

  @override
  String get explorarUltimasVacantes => 'Few spots left';

  @override
  String explorarArancel(Object valor) {
    return 'Fee: $valor';
  }

  @override
  String explorarFueraDeEdad(Object nombre) {
    return 'Doesn\'t match $nombre\'s age';
  }

  @override
  String get explorarOcupacion => 'Occupancy';

  @override
  String get explorarInstNoEncontradaTitulo =>
      'We couldn\'t find this institution';

  @override
  String get explorarInstNoEncontradaMensaje =>
      'It may no longer be listed on ATENA.';

  @override
  String get solAlPedirTitulo => 'Request a spot';

  @override
  String get solAlAlumno => 'Student';

  @override
  String get solAlFueraDeEdadTitulo => 'Age doesn\'t match';

  @override
  String solAlFueraDeEdadMensaje(Object nombre, Object edad) {
    return '$nombre is $edad and this spot is meant for a different age. You can still send the request; the institution will decide.';
  }

  @override
  String get solAlMensajeLabel => 'Message for the institution (optional)';

  @override
  String get solAlMensajeAyuda =>
      'Tell them about the student or ask a question.';

  @override
  String get solAlComoSigue =>
      'The institution will review your request, and we\'ll notify you as soon as they reply.';

  @override
  String get solAlEnviar => 'Send request';

  @override
  String get solAlEnviadaOk =>
      'Request sent! We\'ll let you know when the institution replies.';

  @override
  String get solAlTitulo => 'My requests';

  @override
  String get solAlTabActivas => 'Active';

  @override
  String get solAlTabHistorial => 'History';

  @override
  String get solAlActivasVacioTitulo => 'You have no active requests';

  @override
  String get solAlActivasVacioMensaje =>
      'Once you request a spot, you can follow every step from here.';

  @override
  String get solAlHistorialVacioTitulo => 'Your history is empty';

  @override
  String get solAlHistorialVacioMensaje =>
      'Requests that are closed (declined, cancelled or withdrawn) will appear here.';

  @override
  String solAlRespuestaDe(Object institucion) {
    return 'Reply from $institucion';
  }

  @override
  String get solAlDetalleTitulo => 'Request details';

  @override
  String get solAlNoEncontradaTitulo => 'We couldn\'t find this request';

  @override
  String get solAlNoEncontradaMensaje =>
      'It may have been deleted or belong to another student.';

  @override
  String get solAlEstadoPendienteTitulo => 'Your request is under review';

  @override
  String solAlEstadoPendienteMensaje(Object institucion) {
    return '$institucion is reviewing it. We\'ll notify you as soon as they reply.';
  }

  @override
  String get solAlEstadoConfirmadaTitulo => 'You got the spot!';

  @override
  String solAlEstadoConfirmadaMensaje(Object institucion) {
    return '$institucion confirmed your spot. Next steps: check Documents in case they ask for paperwork, and keep track of key dates in the Calendar.';
  }

  @override
  String get solAlEstadoRechazadaTitulo => 'Not this time';

  @override
  String solAlEstadoRechazadaMensaje(Object institucion) {
    return '$institucion couldn\'t accept the request. Don\'t give up: other institutions have openings.';
  }

  @override
  String get solAlEstadoCanceladaTitulo => 'You cancelled this request';

  @override
  String get solAlEstadoCanceladaMensaje =>
      'If you change your mind, you can request the spot again while there\'s room.';

  @override
  String get solAlEstadoBajaTitulo => 'Your spot was withdrawn';

  @override
  String solAlEstadoBajaMensaje(Object institucion) {
    return '$institucion withdrew this spot. If you have questions, get in touch with them.';
  }

  @override
  String get solAlLaVacante => 'The spot';

  @override
  String get solAlTurnoHorario => 'Shift and schedule';

  @override
  String get solAlDias => 'Days';

  @override
  String get solAlEdad => 'Age';

  @override
  String solAlEdadAlumno(Object nombre, Object edad) {
    return '$nombre is $edad';
  }

  @override
  String get solAlArancel => 'Fee';

  @override
  String get solAlTuMensaje => 'Your message';

  @override
  String get solAlSeguimiento => 'Progress';

  @override
  String get solAlHitoEnviada => 'Request sent';

  @override
  String get solAlHitoConfirmada => 'Spot confirmed';

  @override
  String get solAlHitoRechazada => 'Request declined';

  @override
  String get solAlHitoCancelada => 'You cancelled the request';

  @override
  String get solAlHitoBaja => 'Spot withdrawn';

  @override
  String get solAlCancelar => 'Cancel request';

  @override
  String get solAlCancelarTitulo => 'Cancel this request?';

  @override
  String solAlCancelarMsgPendiente(Object oferta, Object institucion) {
    return 'You\'ll withdraw your request for $oferta at $institucion. If you change your mind, you can request it again while there\'s room.';
  }

  @override
  String solAlCancelarMsgConfirmada(Object oferta, Object institucion) {
    return 'You\'ll give up your confirmed spot in $oferta ($institucion), and another family will be able to take it.';
  }

  @override
  String get solAlCancelarConfirmar => 'Yes, cancel';

  @override
  String get solAlMantener => 'No, keep it';

  @override
  String get solAlCanceladaOk => 'Request cancelled.';

  @override
  String get solAlComprobante => 'Download receipt';

  @override
  String get solAlComprobanteError =>
      'We couldn\'t create the receipt. Please try again in a few minutes.';

  @override
  String get comInstAvisosEnviadosAyuda =>
      'They reach the families of confirmed students as notifications.';

  @override
  String get comInstEventoNoDisponible => 'This event is no longer available';

  @override
  String get comInstEventoNoDisponibleMensaje =>
      'It may have been deleted. Go back to the calendar to see current events.';

  @override
  String get docInstErrorTipo => 'Choose which document you need.';

  @override
  String get docInstPedidoNoDisponible => 'This request is no longer available';

  @override
  String get docInstPedidoNoDisponibleMensaje =>
      'The family may have deleted their account, or the request may have been removed.';

  @override
  String get solInstYaNoExisteTitulo => 'This request no longer exists';

  @override
  String get solInstYaNoExisteMsg =>
      'The family may have deleted their account. If the student had a confirmed spot, it\'s free again.';

  @override
  String get solInstYaNoExiste =>
      'That request no longer exists. The family may have deleted their account.';

  @override
  String get solAlLaInstitucion => 'the institution';

  @override
  String get solAlInstNoDisponible => 'No longer on ATENA';

  @override
  String solAlEstadoBajaSinInstMensaje(Object institucion) {
    return '$institucion is no longer on ATENA, so this spot was withdrawn. You can look for other institutions with openings.';
  }

  @override
  String get plnVerResumen => 'View summary';

  @override
  String perfInstConsejoFotosPrimeras(int n) {
    return 'Upload at least $n photos of your spaces.';
  }

  @override
  String homeStatActiveRequestsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Active requests',
      one: 'Active request',
    );
    return '$_temp0';
  }

  @override
  String homeStatUpcomingEventsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Upcoming events',
      one: 'Upcoming event',
    );
    return '$_temp0';
  }

  @override
  String homeStatPendingDocsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Documents to submit',
      one: 'Document to submit',
    );
    return '$_temp0';
  }

  @override
  String instStatPendingN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Pending requests',
      one: 'Pending request',
    );
    return '$_temp0';
  }

  @override
  String instStatStudentsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Confirmed students',
      one: 'Confirmed student',
    );
    return '$_temp0';
  }

  @override
  String instStatFreeSpotsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Available spots',
      one: 'Available spot',
    );
    return '$_temp0';
  }

  @override
  String instStatOffersN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Active offerings',
      one: 'Active offering',
    );
    return '$_temp0';
  }
}
