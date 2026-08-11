import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'ATENA'**
  String get appTitle;

  /// No description provided for @alumnos.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get alumnos;

  /// No description provided for @instituciones.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get instituciones;

  /// No description provided for @institution.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get institution;

  /// No description provided for @perfiles.
  ///
  /// In es, this message translates to:
  /// **'Perfiles'**
  String get perfiles;

  /// No description provided for @crearPerfil.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil'**
  String get crearPerfil;

  /// No description provided for @crearPerfilTitulo.
  ///
  /// In es, this message translates to:
  /// **'Crear un nuevo perfil'**
  String get crearPerfilTitulo;

  /// No description provided for @tipoAlumno.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get tipoAlumno;

  /// No description provided for @tipoInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get tipoInstitucion;

  /// No description provided for @actualizar.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get actualizar;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get update;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @editar.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editar;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @eliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get eliminar;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @continuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @continuarUltimoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Continuar con el último perfil'**
  String get continuarUltimoPerfil;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get reject;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @open.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get open;

  /// No description provided for @cuentaLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get cuentaLabel;

  /// No description provided for @accountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta: {ownerId}'**
  String accountLabel(Object ownerId);

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get signOut;

  /// No description provided for @signInOrRegister.
  ///
  /// In es, this message translates to:
  /// **'Ingresar o registrarse'**
  String get signInOrRegister;

  /// No description provided for @accessInstitutionAccount.
  ///
  /// In es, this message translates to:
  /// **'Acceder a cuenta de institución'**
  String get accessInstitutionAccount;

  /// No description provided for @signInToEnableInstitutionFeatures.
  ///
  /// In es, this message translates to:
  /// **'Ingresá para habilitar funciones de institución'**
  String get signInToEnableInstitutionFeatures;

  /// No description provided for @errorGenerico.
  ///
  /// In es, this message translates to:
  /// **'Error.'**
  String get errorGenerico;

  /// No description provided for @invalidSessionForThisAccount.
  ///
  /// In es, this message translates to:
  /// **'Sesión inválida para esta cuenta.'**
  String get invalidSessionForThisAccount;

  /// No description provided for @cannotLoadInstitutionTryAgain.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la institución. Intentá nuevamente.'**
  String get cannotLoadInstitutionTryAgain;

  /// No description provided for @noPerfilesTodavia.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay perfiles.\nCreá uno para comenzar.'**
  String get noPerfilesTodavia;

  /// No description provided for @noPerfilesAlumnoTodavia.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay perfiles de alumno.'**
  String get noPerfilesAlumnoTodavia;

  /// No description provided for @accionAlumnoSinPerfil.
  ///
  /// In es, this message translates to:
  /// **'Se recibió una acción para Alumnos, pero esta cuenta no tiene perfiles de Alumno.'**
  String get accionAlumnoSinPerfil;

  /// No description provided for @opcionNoDisponibleBuild.
  ///
  /// In es, this message translates to:
  /// **'Esta opción todavía no está disponible en esta versión.'**
  String get opcionNoDisponibleBuild;

  /// No description provided for @ingresarCrearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ingresar / Crear cuenta'**
  String get ingresarCrearCuenta;

  /// No description provided for @accesoAlumnos.
  ///
  /// In es, this message translates to:
  /// **'Acceso de alumnos'**
  String get accesoAlumnos;

  /// No description provided for @ingresaCuentaEligePerfil.
  ///
  /// In es, this message translates to:
  /// **'Ingresá con tu cuenta y elegí el perfil.'**
  String get ingresaCuentaEligePerfil;

  /// No description provided for @saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get saving;

  /// No description provided for @registering.
  ///
  /// In es, this message translates to:
  /// **'Registrando…'**
  String get registering;

  /// No description provided for @newLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newLabel;

  /// No description provided for @modoOscuro.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get modoOscuro;

  /// No description provided for @idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idioma;

  /// No description provided for @sistema.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get sistema;

  /// No description provided for @espanol.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get espanol;

  /// No description provided for @ingles.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get ingles;

  /// No description provided for @portugues.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get portugues;

  /// No description provided for @landingTitle.
  ///
  /// In es, this message translates to:
  /// **'ATENA'**
  String get landingTitle;

  /// No description provided for @landingIngresar.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get landingIngresar;

  /// No description provided for @landingStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get landingStudents;

  /// No description provided for @landingInstitutions.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get landingInstitutions;

  /// No description provided for @landingHeadingStudents.
  ///
  /// In es, this message translates to:
  /// **'alumnos'**
  String get landingHeadingStudents;

  /// No description provided for @landingHeadingInstitutions.
  ///
  /// In es, this message translates to:
  /// **'instituciones'**
  String get landingHeadingInstitutions;

  /// No description provided for @landingThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Tema: Sistema'**
  String get landingThemeSystem;

  /// No description provided for @landingThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Tema: Claro'**
  String get landingThemeLight;

  /// No description provided for @landingThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Tema: Oscuro'**
  String get landingThemeDark;

  /// No description provided for @landingLanguageTooltip.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get landingLanguageTooltip;

  /// No description provided for @landingLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get landingLanguageSystem;

  /// No description provided for @landingLanguageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get landingLanguageEs;

  /// No description provided for @landingLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get landingLanguageEn;

  /// No description provided for @landingLanguagePt.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get landingLanguagePt;

  /// No description provided for @landingMissingAsset.
  ///
  /// In es, this message translates to:
  /// **'ARCHIVO AUSENTE:\n{path}'**
  String landingMissingAsset(Object path);

  /// No description provided for @vacancyManagement.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get vacancyManagement;

  /// No description provided for @vacancyManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de vacantes – {institucion}'**
  String vacancyManagementTitle(Object institucion);

  /// No description provided for @recalculateOccupiedTooltip.
  ///
  /// In es, this message translates to:
  /// **'Recalcular ocupadas (confirmadas)'**
  String get recalculateOccupiedTooltip;

  /// No description provided for @summaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summaryLabel;

  /// No description provided for @totalCapacityValue.
  ///
  /// In es, this message translates to:
  /// **'Capacidad total: {valor}'**
  String totalCapacityValue(Object valor);

  /// No description provided for @occupiedValue.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas: {valor}'**
  String occupiedValue(Object valor);

  /// No description provided for @availableEstimatedValue.
  ///
  /// In es, this message translates to:
  /// **'Disponibles (estimado): {valor}'**
  String availableEstimatedValue(Object valor);

  /// No description provided for @noGroupsLoaded.
  ///
  /// In es, this message translates to:
  /// **'No se cargó ningún grupo/vacante.'**
  String get noGroupsLoaded;

  /// No description provided for @vacancyGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{actividad} · Capacidad {total} · Ocupadas {ocupados} · Disp {disponibles}'**
  String vacancyGroupSubtitle(
    Object actividad,
    Object total,
    Object ocupados,
    Object disponibles,
  );

  /// No description provided for @newGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo grupo/vacante'**
  String get newGroupTitle;

  /// No description provided for @editGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar grupo/vacante'**
  String get editGroupTitle;

  /// No description provided for @available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @availableShort.
  ///
  /// In es, this message translates to:
  /// **'Disp'**
  String get availableShort;

  /// No description provided for @availableLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get availableLabel;

  /// No description provided for @fullLabel.
  ///
  /// In es, this message translates to:
  /// **'Completo'**
  String get fullLabel;

  /// No description provided for @curricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get curricular;

  /// No description provided for @curricularLabel.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get curricularLabel;

  /// No description provided for @curricularPlural.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get curricularPlural;

  /// No description provided for @extracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get extracurricular;

  /// No description provided for @extracurricularLabel.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get extracurricularLabel;

  /// No description provided for @extracurricularPlural.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get extracurricularPlural;

  /// No description provided for @basic.
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get basic;

  /// No description provided for @standard.
  ///
  /// In es, this message translates to:
  /// **'Estándar'**
  String get standard;

  /// No description provided for @premium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summary;

  /// No description provided for @plan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @code.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get code;

  /// No description provided for @invalidInstitutionId.
  ///
  /// In es, this message translates to:
  /// **'ID de institución inválido.'**
  String get invalidInstitutionId;

  /// No description provided for @institucionInvalidGeneric.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionInvalidGeneric;

  /// No description provided for @institutionGeneric.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get institutionGeneric;

  /// No description provided for @institutionNotLoadedYet.
  ///
  /// In es, this message translates to:
  /// **'La institución todavía no se cargó.'**
  String get institutionNotLoadedYet;

  /// No description provided for @noActiveSessionGoBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'No hay sesión activa. Volvé al login.'**
  String get noActiveSessionGoBackToLogin;

  /// No description provided for @institutionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get institutionsTitle;

  /// No description provided for @backToHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get backToHome;

  /// No description provided for @institutionAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso de institución'**
  String get institutionAccess;

  /// No description provided for @institutionProfileIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID de perfil: {perfilId}'**
  String institutionProfileIdLabel(Object perfilId);

  /// No description provided for @planPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Gestión de plan'**
  String get planPlaceholder;

  /// No description provided for @profilePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Perfil de institución'**
  String get profilePlaceholder;

  /// No description provided for @planUpper.
  ///
  /// In es, this message translates to:
  /// **'PLAN'**
  String get planUpper;

  /// No description provided for @profileUpper.
  ///
  /// In es, this message translates to:
  /// **'PERFIL'**
  String get profileUpper;

  /// No description provided for @administrationUpper.
  ///
  /// In es, this message translates to:
  /// **'ADMINISTRACIÓN'**
  String get administrationUpper;

  /// No description provided for @planCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar plan y módulos'**
  String get planCardSubtitle;

  /// No description provided for @profileCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles y presentación de la institución'**
  String get profileCardSubtitle;

  /// No description provided for @administrationCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Operación de la institución'**
  String get administrationCardSubtitle;

  /// No description provided for @planAndStatusLine.
  ///
  /// In es, this message translates to:
  /// **'Plan: {plan} · Estado: {estado}'**
  String planAndStatusLine(Object plan, Object estado);

  /// No description provided for @workProfilesUpToPremium.
  ///
  /// In es, this message translates to:
  /// **'Hasta 10 perfiles de trabajo'**
  String get workProfilesUpToPremium;

  /// No description provided for @workProfilesUpToStandard.
  ///
  /// In es, this message translates to:
  /// **'Hasta 3 perfiles de trabajo'**
  String get workProfilesUpToStandard;

  /// No description provided for @moduleLabelGeneric.
  ///
  /// In es, this message translates to:
  /// **'Módulo'**
  String get moduleLabelGeneric;

  /// No description provided for @invalidModuleKeyShowingAll.
  ///
  /// In es, this message translates to:
  /// **'Filtro inválido ({key}). Mostrando todos los módulos.'**
  String invalidModuleKeyShowingAll(Object key);

  /// No description provided for @loadErrorWithDetails.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar: {error}'**
  String loadErrorWithDetails(Object error);

  /// No description provided for @confirmRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar solicitud'**
  String get confirmRequestTitle;

  /// No description provided for @rejectRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar solicitud'**
  String get rejectRequestTitle;

  /// No description provided for @updateRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizar solicitud'**
  String get updateRequestTitle;

  /// No description provided for @confirmRequestBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés confirmar esta solicitud?'**
  String get confirmRequestBody;

  /// No description provided for @rejectRequestBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés rechazar esta solicitud?'**
  String get rejectRequestBody;

  /// No description provided for @updateRequestBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés actualizar esta solicitud?'**
  String get updateRequestBody;

  /// No description provided for @activityWithName.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {nombre}'**
  String activityWithName(Object nombre);

  /// No description provided for @activityWithValue.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {value}'**
  String activityWithValue(Object value);

  /// No description provided for @rejectionReasonOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get rejectionReasonOptionalLabel;

  /// No description provided for @noteToStudentOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota al alumno (opcional)'**
  String get noteToStudentOptionalLabel;

  /// No description provided for @requestStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get requestStatusPending;

  /// No description provided for @requestStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get requestStatusConfirmed;

  /// No description provided for @requestStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get requestStatusRejected;

  /// No description provided for @requestStatusCancelledByStudent.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por el alumno'**
  String get requestStatusCancelledByStudent;

  /// No description provided for @requestStatusCancelledByInstitution.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por la institución'**
  String get requestStatusCancelledByInstitution;

  /// No description provided for @requestConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Solicitud confirmada.'**
  String get requestConfirmed;

  /// No description provided for @requestRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada.'**
  String get requestRejected;

  /// No description provided for @requestUpdated.
  ///
  /// In es, this message translates to:
  /// **'Solicitud actualizada.'**
  String get requestUpdated;

  /// No description provided for @requestIsNoLongerPending.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no está pendiente.'**
  String get requestIsNoLongerPending;

  /// No description provided for @noRequestsInSection.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes en esta sección.'**
  String get noRequestsInSection;

  /// No description provided for @noPendingRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes.'**
  String get noPendingRequests;

  /// No description provided for @actionErrorWithDetails.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción: {error}'**
  String actionErrorWithDetails(Object error);

  /// No description provided for @cannotOpenDocumentsMissingOwnerOrProfile.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir Documentación sin una sesión válida.'**
  String get cannotOpenDocumentsMissingOwnerOrProfile;

  /// No description provided for @requestsTitleWithInstitution.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes – {institucion} · {subtitle}'**
  String requestsTitleWithInstitution(Object institucion, Object subtitle);

  /// No description provided for @pendingWithCount.
  ///
  /// In es, this message translates to:
  /// **'Pendientes ({count})'**
  String pendingWithCount(Object count);

  /// No description provided for @confirmedWithCount.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas ({count})'**
  String confirmedWithCount(Object count);

  /// No description provided for @rejectedWithCount.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas ({count})'**
  String rejectedWithCount(Object count);

  /// No description provided for @cancelledWithCount.
  ///
  /// In es, this message translates to:
  /// **'Canceladas ({count})'**
  String cancelledWithCount(Object count);

  /// No description provided for @invalidModuleFilterBanner.
  ///
  /// In es, this message translates to:
  /// **'Filtro de módulo inválido ({key})'**
  String invalidModuleFilterBanner(Object key);

  /// No description provided for @filteringByModuleBanner.
  ///
  /// In es, this message translates to:
  /// **'Filtrando por módulo: {module} ({key})'**
  String filteringByModuleBanner(Object module, Object key);

  /// No description provided for @studentDocumentLine.
  ///
  /// In es, this message translates to:
  /// **'Documento: {doc}'**
  String studentDocumentLine(Object doc);

  /// No description provided for @typeLine.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {tipo}'**
  String typeLine(Object tipo);

  /// No description provided for @moduleLine.
  ///
  /// In es, this message translates to:
  /// **'Módulo: {module}'**
  String moduleLine(Object module);

  /// No description provided for @groupOrClassLine.
  ///
  /// In es, this message translates to:
  /// **'Curso/Grupo: {valor}'**
  String groupOrClassLine(Object valor);

  /// No description provided for @shiftLine.
  ///
  /// In es, this message translates to:
  /// **'Turno: {valor}'**
  String shiftLine(Object valor);

  /// No description provided for @statusLine.
  ///
  /// In es, this message translates to:
  /// **'Estado: {estado}'**
  String statusLine(Object estado);

  /// No description provided for @requestOrViewDocumentsCta.
  ///
  /// In es, this message translates to:
  /// **'Solicitar o ver documentación'**
  String get requestOrViewDocumentsCta;

  /// No description provided for @documentsMissingOwnerOrProfileDisabledCta.
  ///
  /// In es, this message translates to:
  /// **'Documentación no disponible'**
  String get documentsMissingOwnerOrProfileDisabledCta;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsTitleWithNewCount.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones ({count} nuevas)'**
  String notificationsTitleWithNewCount(Object count);

  /// No description provided for @notificationsDeleted.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones eliminadas.'**
  String get notificationsDeleted;

  /// No description provided for @loadNotificationsError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar notificaciones: {error}'**
  String loadNotificationsError(Object error);

  /// No description provided for @updateNotificationError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar notificación: {error}'**
  String updateNotificationError(Object error);

  /// No description provided for @deleteNotificationError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar notificación: {error}'**
  String deleteNotificationError(Object error);

  /// No description provided for @markAllReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo marcar todo como leído'**
  String get markAllReadError;

  /// No description provided for @deleteAll.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get deleteAll;

  /// No description provided for @deleteAllNotificationsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar todo'**
  String get deleteAllNotificationsError;

  /// No description provided for @sessionInvalidTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión inválida'**
  String get sessionInvalidTitle;

  /// No description provided for @sessionInvalidPleaseLogin.
  ///
  /// In es, this message translates to:
  /// **'Sesión inválida. Iniciá sesión.'**
  String get sessionInvalidPleaseLogin;

  /// No description provided for @notificationsNeedOwnerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se requiere una sesión activa para ver notificaciones.'**
  String get notificationsNeedOwnerSubtitle;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones disponibles.'**
  String get noNotificationsSubtitle;

  /// No description provided for @deleteNotificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar notificación'**
  String get deleteNotificationTitle;

  /// No description provided for @deleteNotificationBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar esta notificación?'**
  String get deleteNotificationBody;

  /// No description provided for @deleteAllNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get deleteAllNotificationsTitle;

  /// No description provided for @deleteAllNotificationsBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar todas las notificaciones?'**
  String get deleteAllNotificationsBody;

  /// No description provided for @deleteAllNotificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get deleteAllNotificationsTooltip;

  /// No description provided for @markAsRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leída'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In es, this message translates to:
  /// **'Marcar como no leída'**
  String get markAsUnread;

  /// No description provided for @markAllAsReadTooltip.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get markAllAsReadTooltip;

  /// No description provided for @institucionActividadCurricularGeneral.
  ///
  /// In es, this message translates to:
  /// **'Actividad curricular'**
  String get institucionActividadCurricularGeneral;

  /// No description provided for @institucionActividadExtracurricularGeneral.
  ///
  /// In es, this message translates to:
  /// **'Actividad extracurricular'**
  String get institucionActividadExtracurricularGeneral;

  /// No description provided for @institucionActividadExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get institucionActividadExtracurricular;

  /// No description provided for @institucionWorkProfileFallback.
  ///
  /// In es, this message translates to:
  /// **'Perfil de trabajo'**
  String get institucionWorkProfileFallback;

  /// No description provided for @institucionChangeActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar actividad'**
  String get institucionChangeActivityTitle;

  /// No description provided for @institucionChangeActivityBody.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná la actividad que querés gestionar'**
  String get institucionChangeActivityBody;

  /// No description provided for @institucionWorkProfileNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre del perfil'**
  String get institucionWorkProfileNameTitle;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @institucionWorkProfileNameHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Administración, Dirección'**
  String get institucionWorkProfileNameHint;

  /// No description provided for @institucionWorkProfileNameInvalid.
  ///
  /// In es, this message translates to:
  /// **'Nombre inválido.'**
  String get institucionWorkProfileNameInvalid;

  /// No description provided for @institucionAreaChip.
  ///
  /// In es, this message translates to:
  /// **'{area} · {who}'**
  String institucionAreaChip(Object area, Object who);

  /// No description provided for @institucionAreaChipWithTtl.
  ///
  /// In es, this message translates to:
  /// **'{area} · {who} · {ttl}'**
  String institucionAreaChipWithTtl(Object area, Object who, Object ttl);

  /// No description provided for @institucionAreasFree.
  ///
  /// In es, this message translates to:
  /// **'Áreas libres'**
  String get institucionAreasFree;

  /// No description provided for @planFallbackNoStructured.
  ///
  /// In es, this message translates to:
  /// **'Plan sin estructura detallada'**
  String get planFallbackNoStructured;

  /// No description provided for @idNoSession.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión'**
  String get idNoSession;

  /// No description provided for @idWithValue.
  ///
  /// In es, this message translates to:
  /// **'ID: {value}'**
  String idWithValue(Object value);

  /// No description provided for @institucionPlanAndProfilesPerActivity.
  ///
  /// In es, this message translates to:
  /// **'Plan: {plan} · Perfiles: {max} por actividad'**
  String institucionPlanAndProfilesPerActivity(Object plan, Object max);

  /// No description provided for @institucionFirstSelectActivityBody.
  ///
  /// In es, this message translates to:
  /// **'Primero seleccioná una actividad'**
  String get institucionFirstSelectActivityBody;

  /// No description provided for @institucionWorkProfilesAreInternalNote.
  ///
  /// In es, this message translates to:
  /// **'Los perfiles de trabajo son internos'**
  String get institucionWorkProfilesAreInternalNote;

  /// No description provided for @institucionNoActivitiesYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay actividades configuradas'**
  String get institucionNoActivitiesYet;

  /// No description provided for @institucionManageCurricularActivity.
  ///
  /// In es, this message translates to:
  /// **'Gestionar actividad curricular'**
  String get institucionManageCurricularActivity;

  /// No description provided for @institucionManageExtracurricularModule.
  ///
  /// In es, this message translates to:
  /// **'Gestionar módulo extracurricular'**
  String get institucionManageExtracurricularModule;

  /// No description provided for @institucionPlanAndAvailableProfiles.
  ///
  /// In es, this message translates to:
  /// **'Plan: {plan} · Perfiles disponibles: {max}'**
  String institucionPlanAndAvailableProfiles(Object plan, Object max);

  /// No description provided for @institucionConcurrentProfilesRule.
  ///
  /// In es, this message translates to:
  /// **'Perfiles simultáneos según el plan'**
  String get institucionConcurrentProfilesRule;

  /// No description provided for @institucionWorkProfilesTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfiles de trabajo'**
  String get institucionWorkProfilesTitle;

  /// No description provided for @institucionWorkProfilesDescription.
  ///
  /// In es, this message translates to:
  /// **'Gestión de perfiles internos'**
  String get institucionWorkProfilesDescription;

  /// No description provided for @institucionProfileWorkingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{area} · {who}{ttl}'**
  String institucionProfileWorkingSubtitle(Object area, Object who, Object ttl);

  /// No description provided for @institucionWorkProfilesRenameTip.
  ///
  /// In es, this message translates to:
  /// **'Podés renombrar este perfil'**
  String get institucionWorkProfilesRenameTip;

  /// No description provided for @institucionSelectActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar actividad'**
  String get institucionSelectActivityTitle;

  /// No description provided for @institucionSelectWorkProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar perfil de trabajo'**
  String get institucionSelectWorkProfileTitle;

  /// No description provided for @institucionChangeActivityTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar actividad'**
  String get institucionChangeActivityTooltip;

  /// No description provided for @institucionPlanTitle.
  ///
  /// In es, this message translates to:
  /// **'Plan de institución'**
  String get institucionPlanTitle;

  /// No description provided for @institucionPlanHeader.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu plan'**
  String get institucionPlanHeader;

  /// No description provided for @institucionPlanChooseYourPlanTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu plan'**
  String get institucionPlanChooseYourPlanTitle;

  /// No description provided for @institucionPlanChooseYourPlanSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná el plan más adecuado'**
  String get institucionPlanChooseYourPlanSubtitle;

  /// No description provided for @institucionPlanNoModulesSelected.
  ///
  /// In es, this message translates to:
  /// **'No se seleccionó ningún módulo.'**
  String get institucionPlanNoModulesSelected;

  /// No description provided for @institucionPlanInvalidInstitutionId.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionPlanInvalidInstitutionId;

  /// No description provided for @institucionPlanPickAtLeastOneModule.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná al menos un módulo.'**
  String get institucionPlanPickAtLeastOneModule;

  /// No description provided for @institucionPlanChooseStandardOrPremium.
  ///
  /// In es, this message translates to:
  /// **'Elegí Estándar o Premium.'**
  String get institucionPlanChooseStandardOrPremium;

  /// No description provided for @institucionPlanChooseBasicOrPremium.
  ///
  /// In es, this message translates to:
  /// **'Elegí Básico o Premium.'**
  String get institucionPlanChooseBasicOrPremium;

  /// No description provided for @institucionPlanPromoCleared.
  ///
  /// In es, this message translates to:
  /// **'Código quitado'**
  String get institucionPlanPromoCleared;

  /// No description provided for @institucionPlanPromoSoldOut.
  ///
  /// In es, this message translates to:
  /// **'Código agotado'**
  String get institucionPlanPromoSoldOut;

  /// No description provided for @institucionPlanPromoReservedAlready.
  ///
  /// In es, this message translates to:
  /// **'Código ya reservado'**
  String get institucionPlanPromoReservedAlready;

  /// No description provided for @institucionPlanPromoReserved.
  ///
  /// In es, this message translates to:
  /// **'Código reservado'**
  String get institucionPlanPromoReserved;

  /// No description provided for @institucionPlanPromoInvalid.
  ///
  /// In es, this message translates to:
  /// **'Código inválido'**
  String get institucionPlanPromoInvalid;

  /// No description provided for @institucionPlanPromoApplied.
  ///
  /// In es, this message translates to:
  /// **'Promo aplicada: {code}'**
  String institucionPlanPromoApplied(Object code);

  /// No description provided for @invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña inválida'**
  String get invalidPassword;

  /// No description provided for @institucionPlanCodeRequiredForFreeActivation.
  ///
  /// In es, this message translates to:
  /// **'Se requiere un código para activar el plan gratuito'**
  String get institucionPlanCodeRequiredForFreeActivation;

  /// No description provided for @argentina.
  ///
  /// In es, this message translates to:
  /// **'Argentina'**
  String get argentina;

  /// No description provided for @emailAlreadyRegisteredLogin.
  ///
  /// In es, this message translates to:
  /// **'Email ya registrado. Iniciá sesión.'**
  String get emailAlreadyRegisteredLogin;

  /// No description provided for @institucionPlanTierLabel.
  ///
  /// In es, this message translates to:
  /// **'Plan {tier} ({price})'**
  String institucionPlanTierLabel(Object tier, Object price);

  /// No description provided for @usdToArsTitle.
  ///
  /// In es, this message translates to:
  /// **'Conversión USD → ARS'**
  String get usdToArsTitle;

  /// No description provided for @usdToArsSubtitleBestEffort.
  ///
  /// In es, this message translates to:
  /// **'Estimación de referencia'**
  String get usdToArsSubtitleBestEffort;

  /// No description provided for @usdToArsUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Conversión no disponible'**
  String get usdToArsUnavailable;

  /// No description provided for @usdToArsValue.
  ///
  /// In es, this message translates to:
  /// **'USD → ARS: {value}'**
  String usdToArsValue(Object value);

  /// No description provided for @usdToArsManualLabel.
  ///
  /// In es, this message translates to:
  /// **'Cotización manual'**
  String get usdToArsManualLabel;

  /// No description provided for @usdToArsUsingManual.
  ///
  /// In es, this message translates to:
  /// **'Usando cotización manual'**
  String get usdToArsUsingManual;

  /// No description provided for @updatedAt.
  ///
  /// In es, this message translates to:
  /// **'Actualizado el {date}'**
  String updatedAt(Object date);

  /// No description provided for @promoCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Código promocional'**
  String get promoCodeTitle;

  /// No description provided for @promoCodeOptionalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get promoCodeOptionalSubtitle;

  /// No description provided for @promoCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get promoCodeLabel;

  /// No description provided for @promoCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el código'**
  String get promoCodeHint;

  /// No description provided for @iHavePromoCode.
  ///
  /// In es, this message translates to:
  /// **'Tengo un código'**
  String get iHavePromoCode;

  /// No description provided for @promoAppliedLine.
  ///
  /// In es, this message translates to:
  /// **'Promo aplicada: {code} · {label}'**
  String promoAppliedLine(Object code, Object label);

  /// No description provided for @subtotalUsd.
  ///
  /// In es, this message translates to:
  /// **'Subtotal (USD)'**
  String get subtotalUsd;

  /// No description provided for @promoDiscountUsd.
  ///
  /// In es, this message translates to:
  /// **'Descuento (USD)'**
  String get promoDiscountUsd;

  /// No description provided for @totalUsd.
  ///
  /// In es, this message translates to:
  /// **'Total (USD)'**
  String get totalUsd;

  /// No description provided for @totalArs.
  ///
  /// In es, this message translates to:
  /// **'Total (ARS)'**
  String get totalArs;

  /// No description provided for @institucionPlanSummarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen del plan'**
  String get institucionPlanSummarySubtitle;

  /// No description provided for @notAvailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get notAvailable;

  /// No description provided for @calcDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles del cálculo'**
  String get calcDetailsTitle;

  /// No description provided for @calcDetailsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Desglose de precios'**
  String get calcDetailsSubtitle;

  /// No description provided for @institucionPlanNoteNoPaymentsYet.
  ///
  /// In es, this message translates to:
  /// **'Los pagos todavía no están habilitados en esta fase'**
  String get institucionPlanNoteNoPaymentsYet;

  /// No description provided for @institucionGenericName.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get institucionGenericName;

  /// No description provided for @countryArgentina.
  ///
  /// In es, this message translates to:
  /// **'Argentina'**
  String get countryArgentina;

  /// No description provided for @institucionTitle.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get institucionTitle;

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// No description provided for @actionBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get actionBackHome;

  /// No description provided for @actionLogout.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get actionLogout;

  /// No description provided for @actionRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get actionRefresh;

  /// No description provided for @actionExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get actionExit;

  /// No description provided for @actionLoad.
  ///
  /// In es, this message translates to:
  /// **'Cargar'**
  String get actionLoad;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get actionSaving;

  /// No description provided for @statusSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get statusSaving;

  /// No description provided for @actionDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitar'**
  String get actionRequest;

  /// No description provided for @actionList.
  ///
  /// In es, this message translates to:
  /// **'Listar'**
  String get actionList;

  /// No description provided for @actionIncrease.
  ///
  /// In es, this message translates to:
  /// **'Aumentar'**
  String get actionIncrease;

  /// No description provided for @actionDecrease.
  ///
  /// In es, this message translates to:
  /// **'Disminuir'**
  String get actionDecrease;

  /// No description provided for @valueEmpty.
  ///
  /// In es, this message translates to:
  /// **'Vacío'**
  String get valueEmpty;

  /// No description provided for @valueNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get valueNone;

  /// No description provided for @labelNotProvided.
  ///
  /// In es, this message translates to:
  /// **'No informado'**
  String get labelNotProvided;

  /// No description provided for @validationTooShort.
  ///
  /// In es, this message translates to:
  /// **'Muy corto'**
  String get validationTooShort;

  /// No description provided for @validationCannotBeNegative.
  ///
  /// In es, this message translates to:
  /// **'No puede ser negativo'**
  String get validationCannotBeNegative;

  /// No description provided for @institucionAreaErrorLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el área operativa.'**
  String get institucionAreaErrorLoadFailed;

  /// No description provided for @institucionAreaSnackNoInstitucion.
  ///
  /// In es, this message translates to:
  /// **'No hay institución cargada.'**
  String get institucionAreaSnackNoInstitucion;

  /// No description provided for @institucionAreaDefaultWorkProfileName.
  ///
  /// In es, this message translates to:
  /// **'Perfil de trabajo'**
  String get institucionAreaDefaultWorkProfileName;

  /// No description provided for @institucionAreaSnackAreaInUse.
  ///
  /// In es, this message translates to:
  /// **'Esta área está siendo usada por otro perfil.'**
  String get institucionAreaSnackAreaInUse;

  /// No description provided for @institucionAreaDefaultActivityLabel.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get institucionAreaDefaultActivityLabel;

  /// No description provided for @institucionAreaTitle.
  ///
  /// In es, this message translates to:
  /// **'Área operativa'**
  String get institucionAreaTitle;

  /// No description provided for @institucionAreaIdLine.
  ///
  /// In es, this message translates to:
  /// **'ID: {id}'**
  String institucionAreaIdLine(Object id);

  /// No description provided for @institucionAreaLocationLine.
  ///
  /// In es, this message translates to:
  /// **'Ubicación: {location}'**
  String institucionAreaLocationLine(Object location);

  /// No description provided for @institucionAreaActivityLine.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {activity}'**
  String institucionAreaActivityLine(Object activity);

  /// No description provided for @institucionAreaWorkProfileLine.
  ///
  /// In es, this message translates to:
  /// **'Perfil: {profile}'**
  String institucionAreaWorkProfileLine(Object profile);

  /// No description provided for @institucionAreaAccessLine.
  ///
  /// In es, this message translates to:
  /// **'Acceso: curricular {curricularOk} · extracurricular {extraOk}'**
  String institucionAreaAccessLine(Object curricularOk, Object extraOk);

  /// No description provided for @institucionAreaCardNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get institucionAreaCardNotificationsTitle;

  /// No description provided for @institucionAreaCardNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver notificaciones de la institución'**
  String get institucionAreaCardNotificationsSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenNotifications.
  ///
  /// In es, this message translates to:
  /// **'Abrir notificaciones'**
  String get institucionAreaSemanticsOpenNotifications;

  /// No description provided for @institucionAreaCardSolicitudesTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get institucionAreaCardSolicitudesTitle;

  /// No description provided for @institucionAreaCardSolicitudesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar solicitudes de alumnos'**
  String get institucionAreaCardSolicitudesSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Abrir solicitudes'**
  String get institucionAreaSemanticsOpenSolicitudes;

  /// No description provided for @institucionAreaCardVacantesTitle.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get institucionAreaCardVacantesTitle;

  /// No description provided for @institucionAreaCardVacantesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar grupos y capacidades'**
  String get institucionAreaCardVacantesSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenVacantes.
  ///
  /// In es, this message translates to:
  /// **'Abrir vacantes'**
  String get institucionAreaSemanticsOpenVacantes;

  /// No description provided for @institucionAreaCardVacantesLockedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No disponible en este plan'**
  String get institucionAreaCardVacantesLockedSubtitle;

  /// No description provided for @institucionAreaSemanticsVacantesLocked.
  ///
  /// In es, this message translates to:
  /// **'Vacantes no disponibles'**
  String get institucionAreaSemanticsVacantesLocked;

  /// No description provided for @institucionAreaCardDocumentacionTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get institucionAreaCardDocumentacionTitle;

  /// No description provided for @institucionAreaCardDocumentacionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitar y revisar documentos'**
  String get institucionAreaCardDocumentacionSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenDocumentacion.
  ///
  /// In es, this message translates to:
  /// **'Abrir documentación'**
  String get institucionAreaSemanticsOpenDocumentacion;

  /// No description provided for @institucionAreaCardExtraHubTitle.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get institucionAreaCardExtraHubTitle;

  /// No description provided for @institucionAreaCardExtraHubSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar módulos extracurriculares'**
  String get institucionAreaCardExtraHubSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenExtraHub.
  ///
  /// In es, this message translates to:
  /// **'Abrir extracurricular'**
  String get institucionAreaSemanticsOpenExtraHub;

  /// No description provided for @institucionAreaCardExtraHubLockedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No disponible en este plan'**
  String get institucionAreaCardExtraHubLockedSubtitle;

  /// No description provided for @institucionAreaSemanticsExtraHubLocked.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular no disponible'**
  String get institucionAreaSemanticsExtraHubLocked;

  /// No description provided for @institucionAreaCardCroquisTitle.
  ///
  /// In es, this message translates to:
  /// **'Croquis'**
  String get institucionAreaCardCroquisTitle;

  /// No description provided for @institucionAreaCardCroquisSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar croquis del aula'**
  String get institucionAreaCardCroquisSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenCroquis.
  ///
  /// In es, this message translates to:
  /// **'Abrir croquis'**
  String get institucionAreaSemanticsOpenCroquis;

  /// No description provided for @institucionAreaCardCroquisLockedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No disponible en este plan'**
  String get institucionAreaCardCroquisLockedSubtitle;

  /// No description provided for @institucionAreaSemanticsOpenCroquisLocked.
  ///
  /// In es, this message translates to:
  /// **'Croquis no disponible'**
  String get institucionAreaSemanticsOpenCroquisLocked;

  /// No description provided for @institucionAreaSnackMissingActivityScope.
  ///
  /// In es, this message translates to:
  /// **'Primero seleccioná una actividad para operar.'**
  String get institucionAreaSnackMissingActivityScope;

  /// No description provided for @institucionAreaMissingActivityHint.
  ///
  /// In es, this message translates to:
  /// **'Falta seleccionar una actividad. Volvé y elegí una para habilitar las acciones.'**
  String get institucionAreaMissingActivityHint;

  /// No description provided for @turnoMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get turnoMorning;

  /// No description provided for @croquisTitle.
  ///
  /// In es, this message translates to:
  /// **'Croquis del aula'**
  String get croquisTitle;

  /// No description provided for @croquisTurnoMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get croquisTurnoMorning;

  /// No description provided for @croquisTurnoAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get croquisTurnoAfternoon;

  /// No description provided for @croquisTurnoNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get croquisTurnoNight;

  /// No description provided for @croquisTurnoFullDay.
  ///
  /// In es, this message translates to:
  /// **'Jornada completa'**
  String get croquisTurnoFullDay;

  /// No description provided for @croquisSnackInvalidInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get croquisSnackInvalidInstitution;

  /// No description provided for @croquisSnackEnterAulaBeforeSave.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el nombre del aula antes de guardar.'**
  String get croquisSnackEnterAulaBeforeSave;

  /// No description provided for @croquisSnackSaved.
  ///
  /// In es, this message translates to:
  /// **'Croquis guardado.'**
  String get croquisSnackSaved;

  /// No description provided for @croquisSnackSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String croquisSnackSaveError(Object error);

  /// No description provided for @croquisDialogClearTitle.
  ///
  /// In es, this message translates to:
  /// **'Limpiar grilla'**
  String get croquisDialogClearTitle;

  /// No description provided for @croquisDialogClearBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés limpiar toda la grilla?'**
  String get croquisDialogClearBody;

  /// No description provided for @croquisDialogCellTitle.
  ///
  /// In es, this message translates to:
  /// **'Celda'**
  String get croquisDialogCellTitle;

  /// No description provided for @croquisFieldNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get croquisFieldNameLabel;

  /// No description provided for @croquisDialogNewGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo grupo'**
  String get croquisDialogNewGroupTitle;

  /// No description provided for @croquisFieldGroupTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del grupo'**
  String get croquisFieldGroupTitleLabel;

  /// No description provided for @croquisFieldGroupColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color del grupo'**
  String get croquisFieldGroupColorLabel;

  /// No description provided for @croquisFieldGroupColorHint.
  ///
  /// In es, this message translates to:
  /// **'Elegí un color'**
  String get croquisFieldGroupColorHint;

  /// No description provided for @croquisFieldRowLabel.
  ///
  /// In es, this message translates to:
  /// **'Fila'**
  String get croquisFieldRowLabel;

  /// No description provided for @croquisFieldColLabel.
  ///
  /// In es, this message translates to:
  /// **'Columna'**
  String get croquisFieldColLabel;

  /// No description provided for @croquisFieldHeightLabel.
  ///
  /// In es, this message translates to:
  /// **'Alto'**
  String get croquisFieldHeightLabel;

  /// No description provided for @croquisFieldWidthLabel.
  ///
  /// In es, this message translates to:
  /// **'Ancho'**
  String get croquisFieldWidthLabel;

  /// No description provided for @croquisDialogDeleteGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
  String get croquisDialogDeleteGroupTitle;

  /// No description provided for @croquisDialogDeleteGroupBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar este grupo?'**
  String get croquisDialogDeleteGroupBody;

  /// No description provided for @croquisDialogUnsavedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambios sin guardar'**
  String get croquisDialogUnsavedTitle;

  /// No description provided for @croquisDialogUnsavedBody.
  ///
  /// In es, this message translates to:
  /// **'Tenés cambios sin guardar. ¿Salir igual?'**
  String get croquisDialogUnsavedBody;

  /// No description provided for @croquisErrorInit.
  ///
  /// In es, this message translates to:
  /// **'Error al inicializar el croquis.'**
  String get croquisErrorInit;

  /// No description provided for @croquisSectionAulaTurno.
  ///
  /// In es, this message translates to:
  /// **'Aula y turno'**
  String get croquisSectionAulaTurno;

  /// No description provided for @croquisFieldAulaLabel.
  ///
  /// In es, this message translates to:
  /// **'Aula'**
  String get croquisFieldAulaLabel;

  /// No description provided for @croquisFieldAulaHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Aula 1 / 3B'**
  String get croquisFieldAulaHint;

  /// No description provided for @croquisFieldTurnoLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get croquisFieldTurnoLabel;

  /// No description provided for @croquisActionClearGrid.
  ///
  /// In es, this message translates to:
  /// **'Limpiar grilla'**
  String get croquisActionClearGrid;

  /// No description provided for @croquisActionAddGroup.
  ///
  /// In es, this message translates to:
  /// **'Agregar grupo'**
  String get croquisActionAddGroup;

  /// No description provided for @croquisTipTapCellAutosave.
  ///
  /// In es, this message translates to:
  /// **'Tocá una celda para editar. Se guarda automáticamente.'**
  String get croquisTipTapCellAutosave;

  /// No description provided for @croquisSectionGrid.
  ///
  /// In es, this message translates to:
  /// **'Grilla'**
  String get croquisSectionGrid;

  /// No description provided for @croquisGridSizeLine.
  ///
  /// In es, this message translates to:
  /// **'Tamaño: {rows}×{cols}'**
  String croquisGridSizeLine(Object rows, Object cols);

  /// No description provided for @croquisSectionGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get croquisSectionGroups;

  /// No description provided for @croquisGroupsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay grupos creados.'**
  String get croquisGroupsEmpty;

  /// No description provided for @croquisGroupFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get croquisGroupFallbackTitle;

  /// No description provided for @croquisGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Miembros: {count}'**
  String croquisGroupSubtitle(Object count);

  /// No description provided for @institucionDocsWarnPerfilButNoOwner.
  ///
  /// In es, this message translates to:
  /// **'Hay perfil, pero falta owner. Vista limitada.'**
  String get institucionDocsWarnPerfilButNoOwner;

  /// No description provided for @institucionDocsWarnOwnerButNoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Hay owner, pero falta perfil. Vista limitada.'**
  String get institucionDocsWarnOwnerButNoPerfil;

  /// No description provided for @institucionDocsErrorInvalidInstitutionId.
  ///
  /// In es, this message translates to:
  /// **'ID de institución inválido.'**
  String get institucionDocsErrorInvalidInstitutionId;

  /// No description provided for @institucionDocsSnackInvalidInstitutionEmptyId.
  ///
  /// In es, this message translates to:
  /// **'ID de institución vacío.'**
  String get institucionDocsSnackInvalidInstitutionEmptyId;

  /// No description provided for @institucionDocsSnackNeedOwnerAndPerfil.
  ///
  /// In es, this message translates to:
  /// **'Owner y perfil son obligatorios para esta acción.'**
  String get institucionDocsSnackNeedOwnerAndPerfil;

  /// No description provided for @institucionDocsSnackNoDocTypes.
  ///
  /// In es, this message translates to:
  /// **'No hay tipos de documento disponibles.'**
  String get institucionDocsSnackNoDocTypes;

  /// No description provided for @institucionDocsSnackSolicitudCreated.
  ///
  /// In es, this message translates to:
  /// **'Solicitud creada.'**
  String get institucionDocsSnackSolicitudCreated;

  /// No description provided for @institucionDocsSnackNeedOwnerAndPerfilToUpload.
  ///
  /// In es, this message translates to:
  /// **'Owner y perfil son obligatorios para simular subida.'**
  String get institucionDocsSnackNeedOwnerAndPerfilToUpload;

  /// No description provided for @institucionDocsSnackMissingRef.
  ///
  /// In es, this message translates to:
  /// **'Falta la referencia del archivo.'**
  String get institucionDocsSnackMissingRef;

  /// No description provided for @institucionDocsSnackTempDocSaved.
  ///
  /// In es, this message translates to:
  /// **'Documento temporal guardado.'**
  String get institucionDocsSnackTempDocSaved;

  /// No description provided for @institucionDocsSnackNeedPerfilToCleanup.
  ///
  /// In es, this message translates to:
  /// **'Perfil es obligatorio para limpiar expirados.'**
  String get institucionDocsSnackNeedPerfilToCleanup;

  /// No description provided for @institucionDocsSnackNoExpiredToRemove.
  ///
  /// In es, this message translates to:
  /// **'No hay expirados para eliminar.'**
  String get institucionDocsSnackNoExpiredToRemove;

  /// No description provided for @institucionDocsSnackExpiredRemoved.
  ///
  /// In es, this message translates to:
  /// **'Se eliminaron {count} expirados.'**
  String institucionDocsSnackExpiredRemoved(Object count);

  /// No description provided for @institucionDocsDialogDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get institucionDocsDialogDeleteTitle;

  /// No description provided for @institucionDocsDialogDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este ítem: {name}?'**
  String institucionDocsDialogDeleteBody(Object name);

  /// No description provided for @institucionDocsSnackExpiredUseCleanup.
  ///
  /// In es, this message translates to:
  /// **'Expirado. Usá limpiar expirados.'**
  String get institucionDocsSnackExpiredUseCleanup;

  /// No description provided for @institucionDocsSnackDeleted.
  ///
  /// In es, this message translates to:
  /// **'Eliminado.'**
  String get institucionDocsSnackDeleted;

  /// No description provided for @institucionDocsSnackCannotOpenMissingIds.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir: faltan IDs.'**
  String get institucionDocsSnackCannotOpenMissingIds;

  /// No description provided for @institucionDocsSnackDeeplinkTooLong.
  ///
  /// In es, this message translates to:
  /// **'Deeplink demasiado largo.'**
  String get institucionDocsSnackDeeplinkTooLong;

  /// No description provided for @institucionDocsSnackRouteNotRegistered.
  ///
  /// In es, this message translates to:
  /// **'Ruta no registrada.'**
  String get institucionDocsSnackRouteNotRegistered;

  /// No description provided for @estadoSolicitudPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get estadoSolicitudPendiente;

  /// No description provided for @estadoSolicitudCumplida.
  ///
  /// In es, this message translates to:
  /// **'Cumplida'**
  String get estadoSolicitudCumplida;

  /// No description provided for @estadoSolicitudCancelada.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get estadoSolicitudCancelada;

  /// No description provided for @estadoDocumentoExpirado.
  ///
  /// In es, this message translates to:
  /// **'Expirado'**
  String get estadoDocumentoExpirado;

  /// No description provided for @estadoDocumentoActivo.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get estadoDocumentoActivo;

  /// No description provided for @institucionDocsTooltipOpenAlumno.
  ///
  /// In es, this message translates to:
  /// **'Abrir alumno'**
  String get institucionDocsTooltipOpenAlumno;

  /// No description provided for @institucionDocsTooltipExpiredUseCleanup.
  ///
  /// In es, this message translates to:
  /// **'Expirado (usar limpieza)'**
  String get institucionDocsTooltipExpiredUseCleanup;

  /// No description provided for @institucionDocsViewAllInstitution.
  ///
  /// In es, this message translates to:
  /// **'Ver todo (institución)'**
  String get institucionDocsViewAllInstitution;

  /// No description provided for @institucionDocsViewFilteredOwnerPerfil.
  ///
  /// In es, this message translates to:
  /// **'Filtrado (owner+perfil)'**
  String get institucionDocsViewFilteredOwnerPerfil;

  /// No description provided for @institucionDocsViewFilteredPerfil.
  ///
  /// In es, this message translates to:
  /// **'Filtrado (perfil)'**
  String get institucionDocsViewFilteredPerfil;

  /// No description provided for @institucionDocsViewFilteredOwner.
  ///
  /// In es, this message translates to:
  /// **'Filtrado (owner)'**
  String get institucionDocsViewFilteredOwner;

  /// No description provided for @institucionDocsInstitutionIdLine.
  ///
  /// In es, this message translates to:
  /// **'Institución: {id}'**
  String institucionDocsInstitutionIdLine(Object id);

  /// No description provided for @institucionDocsInstitutionOwnerLine.
  ///
  /// In es, this message translates to:
  /// **'Owner: {owner}'**
  String institucionDocsInstitutionOwnerLine(Object owner);

  /// No description provided for @institucionDocsFieldOwnerAlumnoLabel.
  ///
  /// In es, this message translates to:
  /// **'Owner del alumno'**
  String get institucionDocsFieldOwnerAlumnoLabel;

  /// No description provided for @institucionDocsFieldPerfilAlumnoLabel.
  ///
  /// In es, this message translates to:
  /// **'Perfil del alumno'**
  String get institucionDocsFieldPerfilAlumnoLabel;

  /// No description provided for @institucionDocsFieldTipoDocumentoLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de documento'**
  String get institucionDocsFieldTipoDocumentoLabel;

  /// No description provided for @institucionDocsFieldMensajeOpcionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje (opcional)'**
  String get institucionDocsFieldMensajeOpcionalLabel;

  /// No description provided for @institucionDocsFieldRefLabel.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get institucionDocsFieldRefLabel;

  /// No description provided for @institucionDocsFieldTtlDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'TTL (días)'**
  String get institucionDocsFieldTtlDaysLabel;

  /// No description provided for @institucionDocsActionSimulateUpload.
  ///
  /// In es, this message translates to:
  /// **'Simular subida'**
  String get institucionDocsActionSimulateUpload;

  /// No description provided for @institucionDocsActionCleanupExpired.
  ///
  /// In es, this message translates to:
  /// **'Limpiar expirados'**
  String get institucionDocsActionCleanupExpired;

  /// No description provided for @institucionDocsEmptySolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes.'**
  String get institucionDocsEmptySolicitudes;

  /// No description provided for @institucionDocsEmptyDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Sin documentos.'**
  String get institucionDocsEmptyDocumentos;

  /// No description provided for @institucionDocsSolicitudTipoLine.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {tipo}'**
  String institucionDocsSolicitudTipoLine(Object tipo);

  /// No description provided for @institucionDocsSolicitudSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{estado} · {fecha}'**
  String institucionDocsSolicitudSubtitle(Object estado, Object fecha);

  /// No description provided for @institucionDocsDocumentoTipoLine.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {tipo}'**
  String institucionDocsDocumentoTipoLine(Object tipo);

  /// No description provided for @institucionDocsDocumentoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{estado} · {vence}'**
  String institucionDocsDocumentoSubtitle(Object estado, Object vence);

  /// No description provided for @institucionDocsAppBarTitle.
  ///
  /// In es, this message translates to:
  /// **'{institucion} – Documentación'**
  String institucionDocsAppBarTitle(Object institucion);

  /// No description provided for @tabSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get tabSolicitudes;

  /// No description provided for @tabDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get tabDocumentos;

  /// No description provided for @institucionDocsErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de espera agotado. Intentá nuevamente.'**
  String get institucionDocsErrorTimeout;

  /// No description provided for @institucionExtracGrupoGuiaBloqueTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía del bloque'**
  String get institucionExtracGrupoGuiaBloqueTitle;

  /// No description provided for @institucionExtracGrupoInvalidInstitutionId.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionExtracGrupoInvalidInstitutionId;

  /// No description provided for @institucionExtracGrupoWarnModuleKeyMismatch.
  ///
  /// In es, this message translates to:
  /// **'moduleKey no coincide con la esperada: {expected}'**
  String institucionExtracGrupoWarnModuleKeyMismatch(Object expected);

  /// No description provided for @institucionExtracGrupoWarnModuleKeyNotCanonical.
  ///
  /// In es, this message translates to:
  /// **'moduleKey no canónica: {value}'**
  String institucionExtracGrupoWarnModuleKeyNotCanonical(Object value);

  /// No description provided for @institucionExtracGrupoSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String institucionExtracGrupoSaveFailed(Object error);

  /// No description provided for @institucionExtracGrupoEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar grupo'**
  String get institucionExtracGrupoEditTitle;

  /// No description provided for @institucionExtracGrupoCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear grupo'**
  String get institucionExtracGrupoCreateTitle;

  /// No description provided for @institucionExtracGrupoHeaderBloqueLine.
  ///
  /// In es, this message translates to:
  /// **'Bloque: {bloque} · moduleKey: {moduleKey}'**
  String institucionExtracGrupoHeaderBloqueLine(
    Object bloque,
    Object moduleKey,
  );

  /// No description provided for @institucionExtracGrupoHeaderNotePrototype.
  ///
  /// In es, this message translates to:
  /// **'Prototipo (sin backend)'**
  String get institucionExtracGrupoHeaderNotePrototype;

  /// No description provided for @institucionExtracGrupoWarnKeyMismatch.
  ///
  /// In es, this message translates to:
  /// **'Clave no coincide con la esperada: {expected}'**
  String institucionExtracGrupoWarnKeyMismatch(Object expected);

  /// No description provided for @institucionExtracGrupoWarnKeyNotCanonical.
  ///
  /// In es, this message translates to:
  /// **'Clave no canónica: {value}'**
  String institucionExtracGrupoWarnKeyNotCanonical(Object value);

  /// No description provided for @institucionExtracGrupoFieldActividadLabel.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get institucionExtracGrupoFieldActividadLabel;

  /// No description provided for @institucionExtracGrupoFieldActividadHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Fútbol'**
  String get institucionExtracGrupoFieldActividadHint;

  /// No description provided for @institucionExtracGrupoValActividadRequired.
  ///
  /// In es, this message translates to:
  /// **'Actividad es obligatoria'**
  String get institucionExtracGrupoValActividadRequired;

  /// No description provided for @institucionExtracGrupoFieldGrupoLabel.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get institucionExtracGrupoFieldGrupoLabel;

  /// No description provided for @institucionExtracGrupoFieldGrupoHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Grupo A'**
  String get institucionExtracGrupoFieldGrupoHint;

  /// No description provided for @institucionExtracGrupoValGrupoRequired.
  ///
  /// In es, this message translates to:
  /// **'Grupo es obligatorio'**
  String get institucionExtracGrupoValGrupoRequired;

  /// No description provided for @institucionExtracGrupoFieldTurnoOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno (opcional)'**
  String get institucionExtracGrupoFieldTurnoOptionalLabel;

  /// No description provided for @institucionExtracGrupoFieldTurnoOptionalHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Mañana'**
  String get institucionExtracGrupoFieldTurnoOptionalHint;

  /// No description provided for @institucionExtracGrupoFieldAulaOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Aula (opcional)'**
  String get institucionExtracGrupoFieldAulaOptionalLabel;

  /// No description provided for @institucionExtracGrupoFieldAulaOptionalHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Gimnasio'**
  String get institucionExtracGrupoFieldAulaOptionalHint;

  /// No description provided for @institucionExtracGrupoFieldCupoMaxLabel.
  ///
  /// In es, this message translates to:
  /// **'Capacidad máxima'**
  String get institucionExtracGrupoFieldCupoMaxLabel;

  /// No description provided for @institucionExtracGrupoFieldCupoMaxHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: 25'**
  String get institucionExtracGrupoFieldCupoMaxHint;

  /// No description provided for @institucionExtracGrupoFieldCupoOcupadoLabel.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas'**
  String get institucionExtracGrupoFieldCupoOcupadoLabel;

  /// No description provided for @institucionExtracGrupoValOccExceedsMax.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas no puede exceder el máximo'**
  String get institucionExtracGrupoValOccExceedsMax;

  /// No description provided for @institucionExtracGrupoFieldActivoTitle.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get institucionExtracGrupoFieldActivoTitle;

  /// No description provided for @institucionExtracGrupoFieldActivoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Permite solicitudes'**
  String get institucionExtracGrupoFieldActivoSubtitle;

  /// No description provided for @institucionExtracBaseErrInvalidInstId.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionExtracBaseErrInvalidInstId;

  /// No description provided for @institucionExtracBaseErrInvalidModuleKeySnake.
  ///
  /// In es, this message translates to:
  /// **'moduleKey inválida (snake_case).'**
  String get institucionExtracBaseErrInvalidModuleKeySnake;

  /// No description provided for @institucionExtracBaseErrModuleKeyMismatch.
  ///
  /// In es, this message translates to:
  /// **'moduleKey no coincide con la esperada: {expected}'**
  String institucionExtracBaseErrModuleKeyMismatch(Object expected);

  /// No description provided for @institucionExtracBaseErrModuleKeyNotCanonical.
  ///
  /// In es, this message translates to:
  /// **'moduleKey no canónica: {value}'**
  String institucionExtracBaseErrModuleKeyNotCanonical(Object value);

  /// No description provided for @institucionExtracBaseCuposNotManaged.
  ///
  /// In es, this message translates to:
  /// **'Capacidades no gestionadas'**
  String get institucionExtracBaseCuposNotManaged;

  /// No description provided for @institucionExtracBaseCuposManaged.
  ///
  /// In es, this message translates to:
  /// **'Disponibles: {disp} de {max}'**
  String institucionExtracBaseCuposManaged(Object disp, Object max);

  /// No description provided for @institucionExtracBaseInvalidDataGeneric.
  ///
  /// In es, this message translates to:
  /// **'Datos inválidos.'**
  String get institucionExtracBaseInvalidDataGeneric;

  /// No description provided for @institucionExtracBaseInvalidDataForCupos.
  ///
  /// In es, this message translates to:
  /// **'Datos inválidos para capacidades.'**
  String get institucionExtracBaseInvalidDataForCupos;

  /// No description provided for @institucionExtracBaseCuposRequireMax.
  ///
  /// In es, this message translates to:
  /// **'Capacidad máxima es obligatoria.'**
  String get institucionExtracBaseCuposRequireMax;

  /// No description provided for @institucionExtracBaseCuposDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar capacidades'**
  String get institucionExtracBaseCuposDialogTitle;

  /// No description provided for @institucionExtracBaseCuposDialogActividad.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {actividad}'**
  String institucionExtracBaseCuposDialogActividad(Object actividad);

  /// No description provided for @institucionExtracBaseCuposDialogGrupo.
  ///
  /// In es, this message translates to:
  /// **'Grupo: {grupo}'**
  String institucionExtracBaseCuposDialogGrupo(Object grupo);

  /// No description provided for @institucionExtracBaseCuposDialogMax.
  ///
  /// In es, this message translates to:
  /// **'Máx: {max}'**
  String institucionExtracBaseCuposDialogMax(Object max);

  /// No description provided for @institucionExtracBaseCuposDialogOcupado.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas: {ocupado}'**
  String institucionExtracBaseCuposDialogOcupado(Object ocupado);

  /// No description provided for @institucionExtracBaseCuposDialogDisponibles.
  ///
  /// In es, this message translates to:
  /// **'Disponibles: {disp}'**
  String institucionExtracBaseCuposDialogDisponibles(Object disp);

  /// No description provided for @institucionExtracBaseCuposUpdated.
  ///
  /// In es, this message translates to:
  /// **'Capacidades actualizadas.'**
  String get institucionExtracBaseCuposUpdated;

  /// No description provided for @institucionExtracBaseCuposSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar capacidades: {error}'**
  String institucionExtracBaseCuposSaveFailed(Object error);

  /// No description provided for @institucionExtracBaseInvalidDataForDelete.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar: datos inválidos.'**
  String get institucionExtracBaseInvalidDataForDelete;

  /// No description provided for @institucionExtracBaseDeleteDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
  String get institucionExtracBaseDeleteDialogTitle;

  /// No description provided for @institucionExtracBaseDeleteDialogBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {actividad} ({grupo})?'**
  String institucionExtracBaseDeleteDialogBody(Object actividad, Object grupo);

  /// No description provided for @institucionExtracBaseDeletedOk.
  ///
  /// In es, this message translates to:
  /// **'Eliminado.'**
  String get institucionExtracBaseDeletedOk;

  /// No description provided for @institucionExtracBaseDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar: {error}'**
  String institucionExtracBaseDeleteFailed(Object error);

  /// No description provided for @institucionExtracBaseAppBarTitle.
  ///
  /// In es, this message translates to:
  /// **'{module}'**
  String institucionExtracBaseAppBarTitle(Object module);

  /// No description provided for @institucionExtracBaseChipModuleKey.
  ///
  /// In es, this message translates to:
  /// **'moduleKey: {key}'**
  String institucionExtracBaseChipModuleKey(Object key);

  /// No description provided for @institucionExtracBaseChipInstId.
  ///
  /// In es, this message translates to:
  /// **'Institución: {id}'**
  String institucionExtracBaseChipInstId(Object id);

  /// No description provided for @institucionExtracBaseHeaderNote.
  ///
  /// In es, this message translates to:
  /// **'Gestión del módulo (prototipo)'**
  String get institucionExtracBaseHeaderNote;

  /// No description provided for @institucionExtracBaseQuickGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía rápida'**
  String get institucionExtracBaseQuickGuideTitle;

  /// No description provided for @institucionExtracBaseQuickGuideEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay guía disponible.'**
  String get institucionExtracBaseQuickGuideEmpty;

  /// No description provided for @institucionExtracBaseQuickGuideFootnote.
  ///
  /// In es, this message translates to:
  /// **'Los textos pueden cambiar.'**
  String get institucionExtracBaseQuickGuideFootnote;

  /// No description provided for @institucionExtracBaseGroupsTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get institucionExtracBaseGroupsTitle;

  /// No description provided for @institucionExtracBaseInvalidDataToList.
  ///
  /// In es, this message translates to:
  /// **'No se puede listar: datos inválidos.'**
  String get institucionExtracBaseInvalidDataToList;

  /// No description provided for @institucionExtracBaseLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar.'**
  String get institucionExtracBaseLoadFailed;

  /// No description provided for @institucionExtracBaseNoGroupsYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay grupos.'**
  String get institucionExtracBaseNoGroupsYet;

  /// No description provided for @institucionExtracBaseWithCupos.
  ///
  /// In es, this message translates to:
  /// **'Con capacidades'**
  String get institucionExtracBaseWithCupos;

  /// No description provided for @institucionExtracBaseNoCupos.
  ///
  /// In es, this message translates to:
  /// **'Sin capacidades'**
  String get institucionExtracBaseNoCupos;

  /// No description provided for @institucionExtracBaseGroupLine.
  ///
  /// In es, this message translates to:
  /// **'Grupo: {group}'**
  String institucionExtracBaseGroupLine(Object group);

  /// No description provided for @institucionExtracBaseTurnoLine.
  ///
  /// In es, this message translates to:
  /// **'Turno: {turno}'**
  String institucionExtracBaseTurnoLine(Object turno);

  /// No description provided for @institucionExtracBaseAulaLine.
  ///
  /// In es, this message translates to:
  /// **'Aula: {aula}'**
  String institucionExtracBaseAulaLine(Object aula);

  /// No description provided for @institucionExtracBaseActionCupos.
  ///
  /// In es, this message translates to:
  /// **'Capacidades'**
  String get institucionExtracBaseActionCupos;

  /// No description provided for @institucionExtracBaseCreateGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear grupo'**
  String get institucionExtracBaseCreateGroupTitle;

  /// No description provided for @institucionExtracBaseCreateGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar un nuevo grupo'**
  String get institucionExtracBaseCreateGroupSubtitle;

  /// No description provided for @institucionExtracBaseRulesTitle.
  ///
  /// In es, this message translates to:
  /// **'Reglas'**
  String get institucionExtracBaseRulesTitle;

  /// No description provided for @institucionExtracBaseRulesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get institucionExtracBaseRulesSubtitle;

  /// No description provided for @institucionExtracBaseRulesPendingToast.
  ///
  /// In es, this message translates to:
  /// **'Reglas pendientes: {value}'**
  String institucionExtracBaseRulesPendingToast(Object value);

  /// No description provided for @institucionExtracBaseSolicitudesTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get institucionExtracBaseSolicitudesTitle;

  /// No description provided for @institucionExtracBaseSolicitudesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver solicitudes del módulo: {moduleKey}'**
  String institucionExtracBaseSolicitudesSubtitle(Object moduleKey);

  /// No description provided for @institucionExtracHubTitle.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get institucionExtracHubTitle;

  /// No description provided for @institucionExtracHubHeaderInstOk.
  ///
  /// In es, this message translates to:
  /// **'Institución: {instIdCanon}'**
  String institucionExtracHubHeaderInstOk(Object instIdCanon);

  /// No description provided for @institucionExtracHubHeaderInstInvalid.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionExtracHubHeaderInstInvalid;

  /// No description provided for @institucionExtracHubIntro.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná un módulo para gestionar.'**
  String get institucionExtracHubIntro;

  /// No description provided for @institucionExtracHubInvalidInstIdHelp.
  ///
  /// In es, this message translates to:
  /// **'Volvé y reintentá con una institución válida.'**
  String get institucionExtracHubInvalidInstIdHelp;

  /// No description provided for @institucionExtracHubTileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{descripcion} · moduleKey: {moduleKey}'**
  String institucionExtracHubTileSubtitle(Object descripcion, Object moduleKey);

  /// No description provided for @institucionExtracHubToastInvalidInstId.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get institucionExtracHubToastInvalidInstId;

  /// No description provided for @institucionExtracHubToastInvalidModuleKey.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el módulo: {bloque}'**
  String institucionExtracHubToastInvalidModuleKey(Object bloque);

  /// No description provided for @errorLoadingGroups.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar grupos: {error}'**
  String errorLoadingGroups(Object error);

  /// No description provided for @errorSaving.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String errorSaving(Object error);

  /// No description provided for @occupiedRecalculatedOk.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas recalculadas.'**
  String get occupiedRecalculatedOk;

  /// No description provided for @errorRecalculating.
  ///
  /// In es, this message translates to:
  /// **'Error al recalcular: {error}'**
  String errorRecalculating(Object error);

  /// No description provided for @groupNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del grupo'**
  String get groupNameLabel;

  /// No description provided for @activityLabelShort.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get activityLabelShort;

  /// No description provided for @maxCapacityLabel.
  ///
  /// In es, this message translates to:
  /// **'Capacidad máxima'**
  String get maxCapacityLabel;

  /// No description provided for @completeRequiredFields.
  ///
  /// In es, this message translates to:
  /// **'Completá los campos obligatorios.'**
  String get completeRequiredFields;

  /// No description provided for @commonRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get commonRefresh;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get commonNone;

  /// No description provided for @commonProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get commonProfile;

  /// No description provided for @commonModule.
  ///
  /// In es, this message translates to:
  /// **'Módulo'**
  String get commonModule;

  /// No description provided for @commonPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get commonPending;

  /// No description provided for @commonCompleted.
  ///
  /// In es, this message translates to:
  /// **'Cumplida'**
  String get commonCompleted;

  /// No description provided for @commonCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get commonCancelled;

  /// No description provided for @commonConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get commonConfirmed;

  /// No description provided for @commonRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get commonRejected;

  /// No description provided for @commonExpired.
  ///
  /// In es, this message translates to:
  /// **'Expirado'**
  String get commonExpired;

  /// No description provided for @commonActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get commonActive;

  /// No description provided for @commonCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get commonCurricular;

  /// No description provided for @commonExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get commonExtracurricular;

  /// No description provided for @commonInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get commonInstitution;

  /// No description provided for @commonType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get commonType;

  /// No description provided for @commonClassGroup.
  ///
  /// In es, this message translates to:
  /// **'Curso/Grupo'**
  String get commonClassGroup;

  /// No description provided for @commonShift.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get commonShift;

  /// No description provided for @commonStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get commonStatus;

  /// No description provided for @commonGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando…'**
  String get commonGenerating;

  /// No description provided for @commonErrorWithDetails.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String commonErrorWithDetails(Object error);

  /// No description provided for @alumnoDocumentosTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get alumnoDocumentosTitle;

  /// No description provided for @alumnoDocumentosInvalidOwner.
  ///
  /// In es, this message translates to:
  /// **'Owner inválido.'**
  String get alumnoDocumentosInvalidOwner;

  /// No description provided for @alumnoDocumentosInvalidPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil inválido.'**
  String get alumnoDocumentosInvalidPerfil;

  /// No description provided for @alumnoDocumentosOwnerMismatchAutoscrollIgnored.
  ///
  /// In es, this message translates to:
  /// **'Este deeplink pertenece a otra cuenta. Autoscroll ignorado.'**
  String get alumnoDocumentosOwnerMismatchAutoscrollIgnored;

  /// No description provided for @alumnoDocumentosDeeplinkSolicitudNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la solicitud del deeplink.'**
  String get alumnoDocumentosDeeplinkSolicitudNotFound;

  /// No description provided for @alumnoDocumentosDeeplinkDocumentoNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el documento del deeplink.'**
  String get alumnoDocumentosDeeplinkDocumentoNotFound;

  /// No description provided for @alumnoDocumentosEmptySolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes.'**
  String get alumnoDocumentosEmptySolicitudes;

  /// No description provided for @alumnoDocumentosEmptyDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Sin documentos.'**
  String get alumnoDocumentosEmptyDocumentos;

  /// No description provided for @alumnoDocumentosFieldMensaje.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get alumnoDocumentosFieldMensaje;

  /// No description provided for @alumnoDocumentosFieldTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get alumnoDocumentosFieldTipo;

  /// No description provided for @alumnoDocumentosFieldId.
  ///
  /// In es, this message translates to:
  /// **'ID'**
  String get alumnoDocumentosFieldId;

  /// No description provided for @alumnoDocumentosFieldEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get alumnoDocumentosFieldEstado;

  /// No description provided for @alumnoDocumentosFieldInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get alumnoDocumentosFieldInstitucion;

  /// No description provided for @alumnoDocumentosFieldCreada.
  ///
  /// In es, this message translates to:
  /// **'Creada'**
  String get alumnoDocumentosFieldCreada;

  /// No description provided for @alumnoDocumentosFieldOwner.
  ///
  /// In es, this message translates to:
  /// **'Owner'**
  String get alumnoDocumentosFieldOwner;

  /// No description provided for @alumnoDocumentosFieldPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get alumnoDocumentosFieldPerfil;

  /// No description provided for @alumnoDocumentosFieldSubido.
  ///
  /// In es, this message translates to:
  /// **'Subido'**
  String get alumnoDocumentosFieldSubido;

  /// No description provided for @alumnoDocumentosFieldExpira.
  ///
  /// In es, this message translates to:
  /// **'Expira'**
  String get alumnoDocumentosFieldExpira;

  /// No description provided for @alumnoDocumentosExpiredWillBeDeletedOnClean.
  ///
  /// In es, this message translates to:
  /// **'será eliminado al limpiar expirados'**
  String get alumnoDocumentosExpiredWillBeDeletedOnClean;

  /// No description provided for @alumnoDocumentosFieldSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get alumnoDocumentosFieldSolicitud;

  /// No description provided for @alumnoDocumentosFieldRef.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get alumnoDocumentosFieldRef;

  /// No description provided for @alumnoDocumentosNoExpiredToClean.
  ///
  /// In es, this message translates to:
  /// **'No hay expirados para limpiar.'**
  String get alumnoDocumentosNoExpiredToClean;

  /// No description provided for @alumnoDocumentosExpiredCleanedCount.
  ///
  /// In es, this message translates to:
  /// **'Se limpiaron {count} expirados.'**
  String alumnoDocumentosExpiredCleanedCount(Object count);

  /// No description provided for @alumnoDocumentosDocExpiredUseClean.
  ///
  /// In es, this message translates to:
  /// **'Este documento está expirado. Usá “Limpiar expirados”.'**
  String get alumnoDocumentosDocExpiredUseClean;

  /// No description provided for @alumnoDocumentosExpiredTooltip.
  ///
  /// In es, this message translates to:
  /// **'Expirado (usar limpieza)'**
  String get alumnoDocumentosExpiredTooltip;

  /// No description provided for @alumnoDocumentosDeleteDocTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar documento'**
  String get alumnoDocumentosDeleteDocTitle;

  /// No description provided for @alumnoDocumentosDeleteDocBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar documento {id}?'**
  String alumnoDocumentosDeleteDocBody(Object id);

  /// No description provided for @alumnoDocumentosDocDeleted.
  ///
  /// In es, this message translates to:
  /// **'Documento eliminado.'**
  String get alumnoDocumentosDocDeleted;

  /// No description provided for @alumnoDocumentosCleanExpired.
  ///
  /// In es, this message translates to:
  /// **'Limpiar expirados'**
  String get alumnoDocumentosCleanExpired;

  /// No description provided for @alumnoDocumentosTabSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get alumnoDocumentosTabSolicitudes;

  /// No description provided for @alumnoDocumentosTabDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get alumnoDocumentosTabDocumentos;

  /// No description provided for @alumnoMisSolicitudesTitleOwner.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get alumnoMisSolicitudesTitleOwner;

  /// No description provided for @alumnoMisSolicitudesTitlePerfil.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes – {perfil}'**
  String alumnoMisSolicitudesTitlePerfil(Object perfil);

  /// No description provided for @alumnoMisSolicitudesInvalidOwner.
  ///
  /// In es, this message translates to:
  /// **'Owner inválido.'**
  String get alumnoMisSolicitudesInvalidOwner;

  /// No description provided for @alumnoMisSolicitudesInvalidPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil inválido.'**
  String get alumnoMisSolicitudesInvalidPerfil;

  /// No description provided for @alumnoMisSolicitudesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar: {error}'**
  String alumnoMisSolicitudesLoadError(Object error);

  /// No description provided for @alumnoMisSolicitudesStatusCancelledYou.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por vos'**
  String get alumnoMisSolicitudesStatusCancelledYou;

  /// No description provided for @alumnoMisSolicitudesStatusCancelledInstitution.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por la institución'**
  String get alumnoMisSolicitudesStatusCancelledInstitution;

  /// No description provided for @alumnoMisSolicitudesNotPending.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no está pendiente.'**
  String get alumnoMisSolicitudesNotPending;

  /// No description provided for @alumnoMisSolicitudesCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get alumnoMisSolicitudesCancelTitle;

  /// No description provided for @alumnoMisSolicitudesCancelBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés cancelar esta solicitud?'**
  String get alumnoMisSolicitudesCancelBody;

  /// No description provided for @alumnoMisSolicitudesCancelCta.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get alumnoMisSolicitudesCancelCta;

  /// No description provided for @alumnoMisSolicitudesCancelledOk.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada.'**
  String get alumnoMisSolicitudesCancelledOk;

  /// No description provided for @alumnoMisSolicitudesCancelError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar: {error}'**
  String alumnoMisSolicitudesCancelError(Object error);

  /// No description provided for @alumnoMisSolicitudesDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar solicitud'**
  String get alumnoMisSolicitudesDeleteTitle;

  /// No description provided for @alumnoMisSolicitudesDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar esta solicitud? (solo curricular pendiente)'**
  String get alumnoMisSolicitudesDeleteBody;

  /// No description provided for @alumnoMisSolicitudesDeletedOk.
  ///
  /// In es, this message translates to:
  /// **'Solicitud eliminada.'**
  String get alumnoMisSolicitudesDeletedOk;

  /// No description provided for @alumnoMisSolicitudesCanonicalContextMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta contexto canónico (owner/perfil) para generar el PDF.'**
  String get alumnoMisSolicitudesCanonicalContextMissing;

  /// No description provided for @alumnoMisSolicitudesPdfGenerated.
  ///
  /// In es, this message translates to:
  /// **'PDF generado: {path}'**
  String alumnoMisSolicitudesPdfGenerated(Object path);

  /// No description provided for @alumnoMisSolicitudesPdfError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el PDF: {error}'**
  String alumnoMisSolicitudesPdfError(Object error);

  /// No description provided for @alumnoMisSolicitudesDownloadPdf.
  ///
  /// In es, this message translates to:
  /// **'Descargar PDF'**
  String get alumnoMisSolicitudesDownloadPdf;

  /// No description provided for @alumnoMisSolicitudesTabPendingCount.
  ///
  /// In es, this message translates to:
  /// **'Pendientes ({count})'**
  String alumnoMisSolicitudesTabPendingCount(Object count);

  /// No description provided for @alumnoMisSolicitudesTabConfirmedCount.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas ({count})'**
  String alumnoMisSolicitudesTabConfirmedCount(Object count);

  /// No description provided for @alumnoMisSolicitudesTabRejectedCount.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas ({count})'**
  String alumnoMisSolicitudesTabRejectedCount(Object count);

  /// No description provided for @alumnoMisSolicitudesTabCancelledCount.
  ///
  /// In es, this message translates to:
  /// **'Canceladas ({count})'**
  String alumnoMisSolicitudesTabCancelledCount(Object count);

  /// No description provided for @alumnoMisSolicitudesEmptySection.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes en esta sección.'**
  String get alumnoMisSolicitudesEmptySection;

  /// No description provided for @alumnoMisSolicitudesEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No tenés solicitudes pendientes.'**
  String get alumnoMisSolicitudesEmptyPending;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get commonSaving;

  /// No description provided for @commonGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error.'**
  String get commonGenericError;

  /// No description provided for @commonEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu email.'**
  String get commonEmailRequired;

  /// No description provided for @commonEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Email inválido.'**
  String get commonEmailInvalid;

  /// No description provided for @commonPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get commonPassword;

  /// No description provided for @commonNewPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get commonNewPassword;

  /// No description provided for @commonConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get commonConfirmPassword;

  /// No description provided for @commonPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get commonPasswordsDontMatch;

  /// No description provided for @commonShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get commonHidePassword;

  /// No description provided for @commonRememberMe.
  ///
  /// In es, this message translates to:
  /// **'Recordarme'**
  String get commonRememberMe;

  /// No description provided for @commonSignIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get commonSignIn;

  /// No description provided for @commonSigningIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresando…'**
  String get commonSigningIn;

  /// No description provided for @commonRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get commonRegister;

  /// No description provided for @commonPasswordMinLength4.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 4 caracteres.'**
  String get commonPasswordMinLength4;

  /// No description provided for @commonCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get commonCreateAccount;

  /// No description provided for @commonCreating.
  ///
  /// In es, this message translates to:
  /// **'Creando…'**
  String get commonCreating;

  /// No description provided for @commonFeatureUnavailablePrototype.
  ///
  /// In es, this message translates to:
  /// **'Esta función no está disponible en este prototipo.'**
  String get commonFeatureUnavailablePrototype;

  /// No description provided for @alumnoLoginAppBar.
  ///
  /// In es, this message translates to:
  /// **'Acceso de alumnos'**
  String get alumnoLoginAppBar;

  /// No description provided for @alumnoLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get alumnoLoginTitle;

  /// No description provided for @alumnoLoginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi contraseña'**
  String get alumnoLoginForgotPassword;

  /// No description provided for @alumnoLoginRegistroNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Registro no disponible.'**
  String get alumnoLoginRegistroNoDisponible;

  /// No description provided for @alumnoRegistroAppBar.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get alumnoRegistroAppBar;

  /// No description provided for @alumnoRegistroTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get alumnoRegistroTitle;

  /// No description provided for @alumnoRegistroPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una contraseña.'**
  String get alumnoRegistroPasswordRequired;

  /// No description provided for @alumnoForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get alumnoForgotPasswordTitle;

  /// No description provided for @alumnoForgotPasswordIntro.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu email y elegí una nueva contraseña.'**
  String get alumnoForgotPasswordIntro;

  /// No description provided for @alumnoForgotPasswordEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get alumnoForgotPasswordEmailLabel;

  /// No description provided for @alumnoForgotPasswordNewPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get alumnoForgotPasswordNewPasswordLabel;

  /// No description provided for @alumnoForgotPasswordConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get alumnoForgotPasswordConfirmPasswordLabel;

  /// No description provided for @alumnoForgotPasswordShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get alumnoForgotPasswordShowPassword;

  /// No description provided for @alumnoForgotPasswordHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get alumnoForgotPasswordHidePassword;

  /// No description provided for @alumnoForgotPasswordEnterEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu email.'**
  String get alumnoForgotPasswordEnterEmailError;

  /// No description provided for @alumnoForgotPasswordInvalidEmailError.
  ///
  /// In es, this message translates to:
  /// **'Email inválido.'**
  String get alumnoForgotPasswordInvalidEmailError;

  /// No description provided for @alumnoForgotPasswordEnterPasswordError.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una contraseña.'**
  String get alumnoForgotPasswordEnterPasswordError;

  /// No description provided for @alumnoForgotPasswordPasswordTooShortError.
  ///
  /// In es, this message translates to:
  /// **'Contraseña muy corta.'**
  String get alumnoForgotPasswordPasswordTooShortError;

  /// No description provided for @alumnoForgotPasswordPasswordsDontMatchError.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get alumnoForgotPasswordPasswordsDontMatchError;

  /// No description provided for @alumnoForgotPasswordPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get alumnoForgotPasswordPasswordsDontMatch;

  /// No description provided for @alumnoForgotPasswordAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró ninguna cuenta para este email.'**
  String get alumnoForgotPasswordAccountNotFound;

  /// No description provided for @alumnoForgotPasswordPasswordUpdatedPrototype.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada (prototipo).'**
  String get alumnoForgotPasswordPasswordUpdatedPrototype;

  /// No description provided for @institucionForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get institucionForgotPasswordTitle;

  /// No description provided for @institucionForgotPasswordIntro.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el email de la institución y elegí una nueva contraseña.'**
  String get institucionForgotPasswordIntro;

  /// No description provided for @institucionForgotPasswordEnterEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el email.'**
  String get institucionForgotPasswordEnterEmailError;

  /// No description provided for @institucionForgotPasswordInvalidEmailError.
  ///
  /// In es, this message translates to:
  /// **'Email inválido.'**
  String get institucionForgotPasswordInvalidEmailError;

  /// No description provided for @institucionForgotPasswordEnterPasswordError.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una contraseña.'**
  String get institucionForgotPasswordEnterPasswordError;

  /// No description provided for @institucionForgotPasswordPasswordTooShortError.
  ///
  /// In es, this message translates to:
  /// **'Contraseña muy corta.'**
  String get institucionForgotPasswordPasswordTooShortError;

  /// No description provided for @institucionForgotPasswordPasswordsDontMatchError.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get institucionForgotPasswordPasswordsDontMatchError;

  /// No description provided for @institucionForgotPasswordAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró ninguna institución para este email.'**
  String get institucionForgotPasswordAccountNotFound;

  /// No description provided for @institucionForgotPasswordPasswordUpdatedPrototype.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada (prototipo).'**
  String get institucionForgotPasswordPasswordUpdatedPrototype;

  /// No description provided for @invalidOwner.
  ///
  /// In es, this message translates to:
  /// **'Owner inválido.'**
  String get invalidOwner;

  /// No description provided for @noNotifications.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones.'**
  String get noNotifications;

  /// No description provided for @onlyUnread.
  ///
  /// In es, this message translates to:
  /// **'Solo no leídas'**
  String get onlyUnread;

  /// No description provided for @showAll.
  ///
  /// In es, this message translates to:
  /// **'Mostrar todas'**
  String get showAll;

  /// No description provided for @allProfiles.
  ///
  /// In es, this message translates to:
  /// **'Todos los perfiles'**
  String get allProfiles;

  /// No description provided for @filterByProfile.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por perfil'**
  String get filterByProfile;

  /// No description provided for @filterForcedByCaller.
  ///
  /// In es, this message translates to:
  /// **'Filtro forzado por la pantalla de origen (no modificable desde aquí).'**
  String get filterForcedByCaller;

  /// No description provided for @clearPerfilFilter.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtro de perfil'**
  String get clearPerfilFilter;

  /// No description provided for @noResultsForFilter.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para este filtro.'**
  String get noResultsForFilter;

  /// No description provided for @notificationDeleted.
  ///
  /// In es, this message translates to:
  /// **'Notificación eliminada.'**
  String get notificationDeleted;

  /// No description provided for @notificationNoDestination.
  ///
  /// In es, this message translates to:
  /// **'Esta notificación no tiene destino.'**
  String get notificationNoDestination;

  /// No description provided for @invalidDeeplink.
  ///
  /// In es, this message translates to:
  /// **'Deeplink inválido.'**
  String get invalidDeeplink;

  /// No description provided for @deeplinkOwnerMismatch.
  ///
  /// In es, this message translates to:
  /// **'Este deeplink pertenece a otra cuenta.'**
  String get deeplinkOwnerMismatch;

  /// No description provided for @missingPerfilIdForOpen.
  ///
  /// In es, this message translates to:
  /// **'Falta perfilId para abrir este destino.'**
  String get missingPerfilIdForOpen;

  /// No description provided for @deeplinkNotSupported.
  ///
  /// In es, this message translates to:
  /// **'Deeplink no soportado: {path}'**
  String deeplinkNotSupported(Object path);

  /// No description provided for @notificationPerfilLine.
  ///
  /// In es, this message translates to:
  /// **'Perfil: {perfil}'**
  String notificationPerfilLine(Object perfil);

  /// No description provided for @institucionAreaErrorEmptyId.
  ///
  /// In es, this message translates to:
  /// **'ID de institución vacío.'**
  String get institucionAreaErrorEmptyId;

  /// No description provided for @alumnoGrupoExtraInvalidInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get alumnoGrupoExtraInvalidInstitution;

  /// No description provided for @alumnoGrupoExtraMissingOwnerPerfil.
  ///
  /// In es, this message translates to:
  /// **'Falta contexto de sesión (owner/perfil).'**
  String get alumnoGrupoExtraMissingOwnerPerfil;

  /// No description provided for @alumnoGrupoExtraTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupos extracurriculares'**
  String get alumnoGrupoExtraTitle;

  /// No description provided for @alumnoGrupoExtraLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar'**
  String get alumnoGrupoExtraLoadErrorTitle;

  /// No description provided for @alumnoGrupoExtraSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar actividad o institución…'**
  String get alumnoGrupoExtraSearchHint;

  /// No description provided for @alumnoGrupoExtraBlockOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Bloque (opcional)'**
  String get alumnoGrupoExtraBlockOptionalLabel;

  /// No description provided for @alumnoGrupoExtraEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'No se encontró ningún grupo para este filtro.'**
  String get alumnoGrupoExtraEmptyFiltered;

  /// No description provided for @alumnoGrupoExtraCupoUnmanaged.
  ///
  /// In es, this message translates to:
  /// **'Capacidades no gestionadas'**
  String get alumnoGrupoExtraCupoUnmanaged;

  /// No description provided for @alumnoGrupoExtraOpenSolicitudError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Solicitudes: {error}'**
  String alumnoGrupoExtraOpenSolicitudError(Object error);

  /// No description provided for @alumnoGrupoExtraCupoManaged.
  ///
  /// In es, this message translates to:
  /// **'Disponibles: {disp} de {max}'**
  String alumnoGrupoExtraCupoManaged(Object disp, Object max);

  /// No description provided for @alumnoGrupoExtraSemanticsItem.
  ///
  /// In es, this message translates to:
  /// **'{actividad} · {institucion} · {cupo}'**
  String alumnoGrupoExtraSemanticsItem(
    Object actividad,
    Object institucion,
    Object cupo,
  );

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @commonOk.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get commonSearch;

  /// No description provided for @commonSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar…'**
  String get commonSearchHint;

  /// No description provided for @commonOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get commonOptional;

  /// No description provided for @commonRequired.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get commonRequired;

  /// No description provided for @commonDeletePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get commonDeletePhotoTitle;

  /// No description provided for @commonDeletePhotoConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar esta foto?'**
  String get commonDeletePhotoConfirm;

  /// No description provided for @commonNotificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get commonNotificationsTooltip;

  /// No description provided for @commonBackToProfiles.
  ///
  /// In es, this message translates to:
  /// **'Volver a perfiles'**
  String get commonBackToProfiles;

  /// No description provided for @commonEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get commonEmailLabel;

  /// No description provided for @commonPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get commonPhoneLabel;

  /// No description provided for @commonChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get commonChangePhoto;

  /// No description provided for @commonDeletePhoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get commonDeletePhoto;

  /// No description provided for @commonCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get commonCalendar;

  /// No description provided for @commonDocumentsPdf.
  ///
  /// In es, this message translates to:
  /// **'Documentos (PDF)'**
  String get commonDocumentsPdf;

  /// No description provided for @commonStudentPdfSub.
  ///
  /// In es, this message translates to:
  /// **'Ficha del alumno (PDF)'**
  String get commonStudentPdfSub;

  /// No description provided for @commonNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get commonNotifications;

  /// No description provided for @commonLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonLogout;

  /// No description provided for @commonPendingConnect.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de conexión'**
  String get commonPendingConnect;

  /// No description provided for @commonPasteRealScreenHint.
  ///
  /// In es, this message translates to:
  /// **'Pegá la screen real aquí.'**
  String get commonPasteRealScreenHint;

  /// No description provided for @commonSelectDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get commonSelectDate;

  /// No description provided for @commonInvalidSessionAccountId.
  ///
  /// In es, this message translates to:
  /// **'Sesión inválida para esta cuenta.'**
  String get commonInvalidSessionAccountId;

  /// No description provided for @commonNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get commonNameLabel;

  /// No description provided for @commonEnterName.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu nombre.'**
  String get commonEnterName;

  /// No description provided for @commonLastNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get commonLastNameLabel;

  /// No description provided for @commonEnterLastName.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu apellido.'**
  String get commonEnterLastName;

  /// No description provided for @commonEmailOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Email (opcional)'**
  String get commonEmailOptionalLabel;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email inválido.'**
  String get commonInvalidEmail;

  /// No description provided for @commonPhoneOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get commonPhoneOptionalLabel;

  /// No description provided for @commonSaveProfile.
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get commonSaveProfile;

  /// No description provided for @commonClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get commonClear;

  /// No description provided for @commonAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get commonAll;

  /// No description provided for @commonApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get commonApply;

  /// No description provided for @commonLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get commonLoadMore;

  /// No description provided for @commonEndOfResults.
  ///
  /// In es, this message translates to:
  /// **'Fin de resultados.'**
  String get commonEndOfResults;

  /// No description provided for @commonOwnerInvalid.
  ///
  /// In es, this message translates to:
  /// **'Owner inválido.'**
  String get commonOwnerInvalid;

  /// No description provided for @commonPerfilInvalid.
  ///
  /// In es, this message translates to:
  /// **'Perfil inválido.'**
  String get commonPerfilInvalid;

  /// No description provided for @commonDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDeleteTitle;

  /// No description provided for @commonEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get commonEvent;

  /// No description provided for @commonPersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get commonPersonal;

  /// No description provided for @commonDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get commonDate;

  /// No description provided for @commonSpecialEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento especial'**
  String get commonSpecialEvent;

  /// No description provided for @commonId.
  ///
  /// In es, this message translates to:
  /// **'ID'**
  String get commonId;

  /// No description provided for @commonMandatory.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get commonMandatory;

  /// No description provided for @commonDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get commonDetail;

  /// No description provided for @commonAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get commonAttendance;

  /// No description provided for @commonAttendancePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get commonAttendancePending;

  /// No description provided for @commonAttendanceYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonAttendanceYes;

  /// No description provided for @commonAttendanceMaybe.
  ///
  /// In es, this message translates to:
  /// **'Quizás'**
  String get commonAttendanceMaybe;

  /// No description provided for @commonAttendanceNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonAttendanceNo;

  /// No description provided for @commonPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política'**
  String get commonPolicy;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonMaybe.
  ///
  /// In es, this message translates to:
  /// **'Quizás'**
  String get commonMaybe;

  /// No description provided for @commonDecline.
  ///
  /// In es, this message translates to:
  /// **'Declinar'**
  String get commonDecline;

  /// No description provided for @commonPrevMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get commonPrevMonth;

  /// No description provided for @commonNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get commonNextMonth;

  /// No description provided for @commonEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get commonEvents;

  /// No description provided for @commonAlarm.
  ///
  /// In es, this message translates to:
  /// **'Alarma'**
  String get commonAlarm;

  /// No description provided for @commonNoTime.
  ///
  /// In es, this message translates to:
  /// **'Sin horario'**
  String get commonNoTime;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get commonNew;

  /// No description provided for @commonTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get commonTitle;

  /// No description provided for @commonNoteOptional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get commonNoteOptional;

  /// No description provided for @commonTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get commonTime;

  /// No description provided for @commonChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get commonChoose;

  /// No description provided for @commonView.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get commonView;

  /// No description provided for @commonShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get commonShare;

  /// No description provided for @commonGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get commonGroup;

  /// No description provided for @commonInstitutionUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Institución no disponible.'**
  String get commonInstitutionUnavailable;

  /// No description provided for @commonRequestCreated.
  ///
  /// In es, this message translates to:
  /// **'Solicitud creada.'**
  String get commonRequestCreated;

  /// No description provided for @commonScheduleLabel.
  ///
  /// In es, this message translates to:
  /// **'Horario: {value}'**
  String commonScheduleLabel(Object value);

  /// No description provided for @commonAgeLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad: {value}'**
  String commonAgeLabel(Object value);

  /// No description provided for @commonSlotsLabel.
  ///
  /// In es, this message translates to:
  /// **'Cupos: {value}'**
  String commonSlotsLabel(Object value);

  /// No description provided for @commonProfileLabel.
  ///
  /// In es, this message translates to:
  /// **'Perfil: {value}'**
  String commonProfileLabel(Object value);

  /// No description provided for @commonInstitutionLabel.
  ///
  /// In es, this message translates to:
  /// **'Institución: {value}'**
  String commonInstitutionLabel(Object value);

  /// No description provided for @commonActivityLabel.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {value}'**
  String commonActivityLabel(Object value);

  /// No description provided for @commonTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {value}'**
  String commonTypeLabel(Object value);

  /// No description provided for @commonModuleKeyLabel.
  ///
  /// In es, this message translates to:
  /// **'moduleKey: {value}'**
  String commonModuleKeyLabel(Object value);

  /// No description provided for @commonAulaGrupoLabel.
  ///
  /// In es, this message translates to:
  /// **'Aula/Grupo: {value}'**
  String commonAulaGrupoLabel(Object value);

  /// No description provided for @commonShiftOrScheduleLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno/Horario: {value}'**
  String commonShiftOrScheduleLabel(Object value);

  /// No description provided for @commonSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get commonSend;

  /// No description provided for @commonSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando…'**
  String get commonSending;

  /// No description provided for @commonRequestSentOk.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada.'**
  String get commonRequestSentOk;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Error.'**
  String get commonError;

  /// No description provided for @commonCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get commonCreate;

  /// No description provided for @commonFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio.'**
  String get commonFieldRequired;

  /// No description provided for @commonTooShort.
  ///
  /// In es, this message translates to:
  /// **'Muy corto.'**
  String get commonTooShort;

  /// No description provided for @commonPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get commonPhone;

  /// No description provided for @commonPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'Teléfono inválido.'**
  String get commonPhoneInvalid;

  /// No description provided for @commonRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get commonRemove;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get commonAdd;

  /// No description provided for @commonContinuing.
  ///
  /// In es, this message translates to:
  /// **'Continuando…'**
  String get commonContinuing;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonContinueToPlan.
  ///
  /// In es, this message translates to:
  /// **'Continuar al plan'**
  String get commonContinueToPlan;

  /// No description provided for @commonPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una contraseña.'**
  String get commonPasswordRequired;

  /// No description provided for @commonForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi contraseña'**
  String get commonForgotPassword;

  /// No description provided for @commonLoggingIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresando…'**
  String get commonLoggingIn;

  /// No description provided for @commonLogin.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get commonLogin;

  /// No description provided for @commonDash.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get commonDash;

  /// No description provided for @alumnoAreaTitle.
  ///
  /// In es, this message translates to:
  /// **'Área de alumno'**
  String get alumnoAreaTitle;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesion;

  /// No description provided for @alumnoPerfilInvalido.
  ///
  /// In es, this message translates to:
  /// **'Perfil inválido.'**
  String get alumnoPerfilInvalido;

  /// No description provided for @alumnoBuscarInstituciones.
  ///
  /// In es, this message translates to:
  /// **'Buscar instituciones'**
  String get alumnoBuscarInstituciones;

  /// No description provided for @alumnoBuscarInstitucionesSub.
  ///
  /// In es, this message translates to:
  /// **'Encontrá instituciones y actividades.'**
  String get alumnoBuscarInstitucionesSub;

  /// No description provided for @alumnoBuscarInstitucionesPlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get alumnoBuscarInstitucionesPlaceholderTitle;

  /// No description provided for @alumnoBuscarPlaceholderEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados.'**
  String get alumnoBuscarPlaceholderEmpty;

  /// No description provided for @alumnoBuscarPlaceholderQuery.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda: {query}'**
  String alumnoBuscarPlaceholderQuery(Object query);

  /// No description provided for @alumnoDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get alumnoDashboardTitle;

  /// No description provided for @alumnoDashboardMiDni.
  ///
  /// In es, this message translates to:
  /// **'Mi DNI'**
  String get alumnoDashboardMiDni;

  /// No description provided for @alumnoDashboardMisSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get alumnoDashboardMisSolicitudes;

  /// No description provided for @alumnoDashboardMisSolicitudesSub.
  ///
  /// In es, this message translates to:
  /// **'Ver el estado de tus solicitudes'**
  String get alumnoDashboardMisSolicitudesSub;

  /// No description provided for @alumnoDashboardBuscarInstituciones.
  ///
  /// In es, this message translates to:
  /// **'Buscar instituciones'**
  String get alumnoDashboardBuscarInstituciones;

  /// No description provided for @alumnoDashboardBuscarInstitucionesSub.
  ///
  /// In es, this message translates to:
  /// **'Encontrá instituciones y actividades'**
  String get alumnoDashboardBuscarInstitucionesSub;

  /// No description provided for @alumnoDashboardCerrarSesionSub.
  ///
  /// In es, this message translates to:
  /// **'Cerrar tu sesión actual'**
  String get alumnoDashboardCerrarSesionSub;

  /// No description provided for @alumnoMisSolicitudesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get alumnoMisSolicitudesTitle;

  /// No description provided for @alumnoBuscarInstitucionesTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar instituciones'**
  String get alumnoBuscarInstitucionesTitle;

  /// No description provided for @alumnoBuscarPlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get alumnoBuscarPlaceholderTitle;

  /// No description provided for @alumnoMenuTitle.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get alumnoMenuTitle;

  /// No description provided for @alumnoMenuHeader.
  ///
  /// In es, this message translates to:
  /// **'ATENA'**
  String get alumnoMenuHeader;

  /// No description provided for @alumnoMenuBody.
  ///
  /// In es, this message translates to:
  /// **'Elegí una opción para continuar.'**
  String get alumnoMenuBody;

  /// No description provided for @alumnoMenuCtaLogin.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get alumnoMenuCtaLogin;

  /// No description provided for @alumnoFechaNacimientoNoFutura.
  ///
  /// In es, this message translates to:
  /// **'La fecha de nacimiento no puede ser futura.'**
  String get alumnoFechaNacimientoNoFutura;

  /// No description provided for @alumnoSeleccionaFechaNacimiento.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná tu fecha de nacimiento.'**
  String get alumnoSeleccionaFechaNacimiento;

  /// No description provided for @alumnoNoSePudoCrearPerfilPerfilIdVacio.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el perfil: perfilId vacío.'**
  String get alumnoNoSePudoCrearPerfilPerfilIdVacio;

  /// No description provided for @alumnoPerfilRegistroTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro de alumno'**
  String get alumnoPerfilRegistroTitle;

  /// No description provided for @alumnoDocumentoDniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get alumnoDocumentoDniLabel;

  /// No description provided for @alumnoIngresaDni.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu DNI.'**
  String get alumnoIngresaDni;

  /// No description provided for @alumnoDniInvalidoRango.
  ///
  /// In es, this message translates to:
  /// **'DNI inválido (rango).'**
  String get alumnoDniInvalidoRango;

  /// No description provided for @alumnoFechaNacimientoPrefix.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get alumnoFechaNacimientoPrefix;

  /// No description provided for @alumnoBuscarExtracurricularesTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar extracurriculares'**
  String get alumnoBuscarExtracurricularesTitle;

  /// No description provided for @alumnoBuscarExtracurricularesHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar actividad, institución o grupo…'**
  String get alumnoBuscarExtracurricularesHint;

  /// No description provided for @alumnoBuscarExtracurricularesBloqueOpcional.
  ///
  /// In es, this message translates to:
  /// **'Bloque (opcional)'**
  String get alumnoBuscarExtracurricularesBloqueOpcional;

  /// No description provided for @alumnoBuscarExtracurricularesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay extracurriculares disponibles.'**
  String get alumnoBuscarExtracurricularesEmpty;

  /// No description provided for @alumnoBuscarExtracurricularesGruposConCupo.
  ///
  /// In es, this message translates to:
  /// **'Grupos con cupo: {count}'**
  String alumnoBuscarExtracurricularesGruposConCupo(Object count);

  /// No description provided for @alumnoBuscarExtracurricularesErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar extracurriculares: {error}'**
  String alumnoBuscarExtracurricularesErrorCargar(Object error);

  /// No description provided for @alumnoBuscarInstitucionesErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar instituciones: {error}'**
  String alumnoBuscarInstitucionesErrorCargar(Object error);

  /// No description provided for @alumnoBuscarInstitucionesErrorCargarMas.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar más: {error}'**
  String alumnoBuscarInstitucionesErrorCargarMas(Object error);

  /// No description provided for @alumnoBuscarInstitucionesExtraEnConstruccion.
  ///
  /// In es, this message translates to:
  /// **'Extracurriculares (en construcción)'**
  String get alumnoBuscarInstitucionesExtraEnConstruccion;

  /// No description provided for @alumnoBuscarInstitucionesExtraAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get alumnoBuscarInstitucionesExtraAll;

  /// No description provided for @alumnoBuscarInstitucionesExtraSelected.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado: {value}'**
  String alumnoBuscarInstitucionesExtraSelected(Object value);

  /// No description provided for @alumnoBuscarInstitucionesFiltroExtraTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtro extracurricular'**
  String get alumnoBuscarInstitucionesFiltroExtraTitle;

  /// No description provided for @alumnoBuscarInstitucionesNoHayInstituciones.
  ///
  /// In es, this message translates to:
  /// **'No hay instituciones registradas.'**
  String get alumnoBuscarInstitucionesNoHayInstituciones;

  /// No description provided for @alumnoBuscarInstitucionesNoResultadosConFiltro.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados para este filtro.'**
  String get alumnoBuscarInstitucionesNoResultadosConFiltro;

  /// No description provided for @alumnoBuscarInstitucionesCurricularDisponible.
  ///
  /// In es, this message translates to:
  /// **'Curricular disponible'**
  String get alumnoBuscarInstitucionesCurricularDisponible;

  /// No description provided for @alumnoBuscarInstitucionesCurricularNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Curricular no disponible'**
  String get alumnoBuscarInstitucionesCurricularNoDisponible;

  /// No description provided for @alumnoBuscarInstitucionesExtraSinModulos.
  ///
  /// In es, this message translates to:
  /// **'Sin módulos extracurriculares'**
  String get alumnoBuscarInstitucionesExtraSinModulos;

  /// No description provided for @alumnoBuscarInstitucionesExtraConModulos.
  ///
  /// In es, this message translates to:
  /// **'Módulos: {count}'**
  String alumnoBuscarInstitucionesExtraConModulos(Object count);

  /// No description provided for @alumnoBuscarInstitucionesExtraNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular no disponible'**
  String get alumnoBuscarInstitucionesExtraNoDisponible;

  /// No description provided for @alumnoBuscarInstitucionesBtnCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get alumnoBuscarInstitucionesBtnCurricular;

  /// No description provided for @alumnoBuscarInstitucionesBtnExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get alumnoBuscarInstitucionesBtnExtracurricular;

  /// No description provided for @alumnoCalendarioEspecialInicioClases.
  ///
  /// In es, this message translates to:
  /// **'Inicio de clases'**
  String get alumnoCalendarioEspecialInicioClases;

  /// No description provided for @alumnoCalendarioEspecialFinClases.
  ///
  /// In es, this message translates to:
  /// **'Fin de clases'**
  String get alumnoCalendarioEspecialFinClases;

  /// No description provided for @alumnoCalendarioEspecialReceso.
  ///
  /// In es, this message translates to:
  /// **'Receso'**
  String get alumnoCalendarioEspecialReceso;

  /// No description provided for @alumnoCalendarioEspecialInicioCiclo.
  ///
  /// In es, this message translates to:
  /// **'Inicio de ciclo'**
  String get alumnoCalendarioEspecialInicioCiclo;

  /// No description provided for @alumnoCalendarioEspecialFinCiclo.
  ///
  /// In es, this message translates to:
  /// **'Fin de ciclo'**
  String get alumnoCalendarioEspecialFinCiclo;

  /// No description provided for @alumnoCalendarioSnackNoDeclinar.
  ///
  /// In es, this message translates to:
  /// **'No se puede declinar este evento.'**
  String get alumnoCalendarioSnackNoDeclinar;

  /// No description provided for @alumnoCalendarioSnackAsistenciaConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Asistencia confirmada.'**
  String get alumnoCalendarioSnackAsistenciaConfirmada;

  /// No description provided for @alumnoCalendarioSnackAsistenciaQuizas.
  ///
  /// In es, this message translates to:
  /// **'Asistencia: quizás.'**
  String get alumnoCalendarioSnackAsistenciaQuizas;

  /// No description provided for @alumnoCalendarioSnackAsistenciaDeclinada.
  ///
  /// In es, this message translates to:
  /// **'Asistencia declinada.'**
  String get alumnoCalendarioSnackAsistenciaDeclinada;

  /// No description provided for @alumnoCalendarioSnackNoGuardarRsvp.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar asistencia: {error}'**
  String alumnoCalendarioSnackNoGuardarRsvp(Object error);

  /// No description provided for @alumnoCalendarioSnackNoGuardarNota.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar nota: {error}'**
  String alumnoCalendarioSnackNoGuardarNota(Object error);

  /// No description provided for @alumnoCalendarioSnackNoActualizarNota.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar nota: {error}'**
  String alumnoCalendarioSnackNoActualizarNota(Object error);

  /// No description provided for @alumnoCalendarioEliminarConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar este evento?'**
  String get alumnoCalendarioEliminarConfirm;

  /// No description provided for @alumnoCalendarioSnackNoEliminarNota.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar nota: {error}'**
  String alumnoCalendarioSnackNoEliminarNota(Object error);

  /// No description provided for @alumnoCalendarioNoRequiereAsistencia.
  ///
  /// In es, this message translates to:
  /// **'Este evento no requiere asistencia.'**
  String get alumnoCalendarioNoRequiereAsistencia;

  /// No description provided for @alumnoCalendarioNotaCanonica.
  ///
  /// In es, this message translates to:
  /// **'Nota canónica'**
  String get alumnoCalendarioNotaCanonica;

  /// No description provided for @alumnoCalendarioTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get alumnoCalendarioTitle;

  /// No description provided for @alumnoCalendarioFabNotaAlarma.
  ///
  /// In es, this message translates to:
  /// **'Nota / Alarma'**
  String get alumnoCalendarioFabNotaAlarma;

  /// No description provided for @alumnoCalendarioNoEventosDia.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos para este día.'**
  String get alumnoCalendarioNoEventosDia;

  /// No description provided for @alumnoCalendarioConfirmarAsistencia.
  ///
  /// In es, this message translates to:
  /// **'Confirmar asistencia'**
  String get alumnoCalendarioConfirmarAsistencia;

  /// No description provided for @alumnoCalendarioDialogNotaAlarma.
  ///
  /// In es, this message translates to:
  /// **'Nota y alarma'**
  String get alumnoCalendarioDialogNotaAlarma;

  /// No description provided for @alumnoCalendarioDialogIngresarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un título'**
  String get alumnoCalendarioDialogIngresarTitulo;

  /// No description provided for @alumnoCalendarioDialogAlarmaLocal.
  ///
  /// In es, this message translates to:
  /// **'Alarma local'**
  String get alumnoCalendarioDialogAlarmaLocal;

  /// No description provided for @alumnoCalendarioDialogAlarmaLocalDesc.
  ///
  /// In es, this message translates to:
  /// **'Se guardará solo en este dispositivo.'**
  String get alumnoCalendarioDialogAlarmaLocalDesc;

  /// No description provided for @alumnoCalendarioDialogAvisoNotificacion.
  ///
  /// In es, this message translates to:
  /// **'Aviso: notificación'**
  String get alumnoCalendarioDialogAvisoNotificacion;

  /// No description provided for @alumnoNotificacionesDeleteOneTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar notificación'**
  String get alumnoNotificacionesDeleteOneTitle;

  /// No description provided for @alumnoNotificacionesDeleteOneBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar esta notificación?'**
  String get alumnoNotificacionesDeleteOneBody;

  /// No description provided for @alumnoNotificacionesDeleteAllTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get alumnoNotificacionesDeleteAllTitle;

  /// No description provided for @alumnoNotificacionesDeleteAllBody.
  ///
  /// In es, this message translates to:
  /// **'¿Querés eliminar todas las notificaciones?'**
  String get alumnoNotificacionesDeleteAllBody;

  /// No description provided for @alumnoNotificacionesDeleteAllCta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get alumnoNotificacionesDeleteAllCta;

  /// No description provided for @alumnoNotificacionesDeleteAllFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar todo.'**
  String get alumnoNotificacionesDeleteAllFailed;

  /// No description provided for @alumnoNotificacionesActionOpenDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Abrir Documentación'**
  String get alumnoNotificacionesActionOpenDocumentos;

  /// No description provided for @alumnoNotificacionesActionOpenCalendario.
  ///
  /// In es, this message translates to:
  /// **'Abrir Calendario'**
  String get alumnoNotificacionesActionOpenCalendario;

  /// No description provided for @alumnoNotificacionesActionOpenBoletines.
  ///
  /// In es, this message translates to:
  /// **'Abrir Boletines'**
  String get alumnoNotificacionesActionOpenBoletines;

  /// No description provided for @alumnoNotificacionesActionOpenBecas.
  ///
  /// In es, this message translates to:
  /// **'Abrir Becas'**
  String get alumnoNotificacionesActionOpenBecas;

  /// No description provided for @alumnoNotificacionesActionOpenConvivencia.
  ///
  /// In es, this message translates to:
  /// **'Abrir Convivencia'**
  String get alumnoNotificacionesActionOpenConvivencia;

  /// No description provided for @alumnoNotificacionesActionOpenEquivalencias.
  ///
  /// In es, this message translates to:
  /// **'Abrir Equivalencias'**
  String get alumnoNotificacionesActionOpenEquivalencias;

  /// No description provided for @alumnoNotificacionesActionViewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get alumnoNotificacionesActionViewDetail;

  /// No description provided for @alumnoNotificacionesSectionNotReady.
  ///
  /// In es, this message translates to:
  /// **'Sección no disponible todavía.'**
  String get alumnoNotificacionesSectionNotReady;

  /// No description provided for @alumnoNotificacionesDialogActionLine.
  ///
  /// In es, this message translates to:
  /// **'Acción: {value}'**
  String alumnoNotificacionesDialogActionLine(Object value);

  /// No description provided for @alumnoNotificacionesDialogProfileLine.
  ///
  /// In es, this message translates to:
  /// **'Perfil: {value}'**
  String alumnoNotificacionesDialogProfileLine(Object value);

  /// No description provided for @alumnoNotificacionesDialogDateLine.
  ///
  /// In es, this message translates to:
  /// **'Fecha: {value}'**
  String alumnoNotificacionesDialogDateLine(Object value);

  /// No description provided for @alumnoNotificacionesDialogDeeplinkLine.
  ///
  /// In es, this message translates to:
  /// **'Deeplink: {value}'**
  String alumnoNotificacionesDialogDeeplinkLine(Object value);

  /// No description provided for @alumnoNotificacionesTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get alumnoNotificacionesTitle;

  /// No description provided for @alumnoNotificacionesTitleWithUnread.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones ({count} sin leer)'**
  String alumnoNotificacionesTitleWithUnread(Object count);

  /// No description provided for @alumnoNotificacionesDeleteAllTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get alumnoNotificacionesDeleteAllTooltip;

  /// No description provided for @alumnoNotificacionesNoOwnerBody.
  ///
  /// In es, this message translates to:
  /// **'Se requiere sesión activa para ver notificaciones.'**
  String get alumnoNotificacionesNoOwnerBody;

  /// No description provided for @alumnoNotificacionesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get alumnoNotificacionesEmptyTitle;

  /// No description provided for @alumnoNotificacionesEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones disponibles.'**
  String get alumnoNotificacionesEmptyBody;

  /// No description provided for @alumnoNotificacionesMarkRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leída'**
  String get alumnoNotificacionesMarkRead;

  /// No description provided for @alumnoNotificacionesMarkUnread.
  ///
  /// In es, this message translates to:
  /// **'Marcar como no leída'**
  String get alumnoNotificacionesMarkUnread;

  /// No description provided for @alumnoNotificacionesFilterStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get alumnoNotificacionesFilterStatusLabel;

  /// No description provided for @alumnoNotificacionesFilterTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get alumnoNotificacionesFilterTypeLabel;

  /// No description provided for @alumnoNotificacionesShowingCount.
  ///
  /// In es, this message translates to:
  /// **'Mostrando: {count}'**
  String alumnoNotificacionesShowingCount(Object count);

  /// No description provided for @alumnoNotificacionesShowingCountWithPerfil.
  ///
  /// In es, this message translates to:
  /// **'Mostrando: {count} · Perfil: {perfil}'**
  String alumnoNotificacionesShowingCountWithPerfil(
    Object count,
    Object perfil,
  );

  /// No description provided for @alumnoPdfsInvalidPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil inválido.'**
  String get alumnoPdfsInvalidPerfil;

  /// No description provided for @alumnoPdfsSavedPath.
  ///
  /// In es, this message translates to:
  /// **'Guardado en: {path}'**
  String alumnoPdfsSavedPath(Object path);

  /// No description provided for @alumnoPdfsTitle.
  ///
  /// In es, this message translates to:
  /// **'PDFs'**
  String get alumnoPdfsTitle;

  /// No description provided for @alumnoPdfsFichaTitle.
  ///
  /// In es, this message translates to:
  /// **'Ficha'**
  String get alumnoPdfsFichaTitle;

  /// No description provided for @alumnoPdfsPerfilId.
  ///
  /// In es, this message translates to:
  /// **'Perfil: {perfilId}'**
  String alumnoPdfsPerfilId(Object perfilId);

  /// No description provided for @alumnoPdfsCroquisTitle.
  ///
  /// In es, this message translates to:
  /// **'Croquis'**
  String get alumnoPdfsCroquisTitle;

  /// No description provided for @alumnoPdfsCroquisPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Croquis no disponible.'**
  String get alumnoPdfsCroquisPlaceholder;

  /// No description provided for @alumnoSeleccionGrupoInstitutionLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la institución.'**
  String get alumnoSeleccionGrupoInstitutionLoadFailed;

  /// No description provided for @alumnoSeleccionGrupoLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar: {error}'**
  String alumnoSeleccionGrupoLoadError(Object error);

  /// No description provided for @alumnoSeleccionGrupoExtraLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar extracurriculares: {error}'**
  String alumnoSeleccionGrupoExtraLoadError(Object error);

  /// No description provided for @alumnoSeleccionGrupoPickCourseAndShift.
  ///
  /// In es, this message translates to:
  /// **'Elegí curso/grupo y turno.'**
  String get alumnoSeleccionGrupoPickCourseAndShift;

  /// No description provided for @alumnoSeleccionGrupoPickExtraActivity.
  ///
  /// In es, this message translates to:
  /// **'Elegí una actividad extracurricular.'**
  String get alumnoSeleccionGrupoPickExtraActivity;

  /// No description provided for @alumnoSeleccionGrupoExtraNoSlots.
  ///
  /// In es, this message translates to:
  /// **'No hay cupos disponibles.'**
  String get alumnoSeleccionGrupoExtraNoSlots;

  /// No description provided for @alumnoSeleccionGrupoNoSlotsShort.
  ///
  /// In es, this message translates to:
  /// **'Sin cupos'**
  String get alumnoSeleccionGrupoNoSlotsShort;

  /// No description provided for @alumnoSeleccionGrupoNoSlots.
  ///
  /// In es, this message translates to:
  /// **'No hay cupos disponibles.'**
  String get alumnoSeleccionGrupoNoSlots;

  /// No description provided for @alumnoSeleccionGrupoExtraFilterByBlock.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por bloque'**
  String get alumnoSeleccionGrupoExtraFilterByBlock;

  /// No description provided for @alumnoSeleccionGrupoExtraEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados para este filtro.'**
  String get alumnoSeleccionGrupoExtraEmpty;

  /// No description provided for @alumnoSeleccionGrupoModeCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get alumnoSeleccionGrupoModeCurricular;

  /// No description provided for @alumnoSeleccionGrupoModeExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get alumnoSeleccionGrupoModeExtracurricular;

  /// No description provided for @alumnoSeleccionGrupoTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar grupo – {mode}'**
  String alumnoSeleccionGrupoTitle(Object mode);

  /// No description provided for @alumnoSeleccionGrupoExtraRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get alumnoSeleccionGrupoExtraRefresh;

  /// No description provided for @alumnoSeleccionGrupoCtaCurricular.
  ///
  /// In es, this message translates to:
  /// **'Continuar (curricular)'**
  String get alumnoSeleccionGrupoCtaCurricular;

  /// No description provided for @alumnoSeleccionGrupoCtaExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Continuar (extracurricular)'**
  String get alumnoSeleccionGrupoCtaExtracurricular;

  /// No description provided for @alumnoSolicitarVacanteMissingOwnerPerfil.
  ///
  /// In es, this message translates to:
  /// **'Falta contexto de sesión (owner/perfil).'**
  String get alumnoSolicitarVacanteMissingOwnerPerfil;

  /// No description provided for @alumnoSolicitarVacanteInvalidInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución inválida.'**
  String get alumnoSolicitarVacanteInvalidInstitution;

  /// No description provided for @alumnoSolicitarVacanteInvalidActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad inválida.'**
  String get alumnoSolicitarVacanteInvalidActivity;

  /// No description provided for @alumnoSolicitarVacanteCurricularRequiresAula.
  ///
  /// In es, this message translates to:
  /// **'Curricular requiere aula/grupo.'**
  String get alumnoSolicitarVacanteCurricularRequiresAula;

  /// No description provided for @alumnoSolicitarVacanteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar solicitud'**
  String get alumnoSolicitarVacanteConfirmTitle;

  /// No description provided for @alumnoSolicitarVacanteTypeCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get alumnoSolicitarVacanteTypeCurricular;

  /// No description provided for @alumnoSolicitarVacanteTypeExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get alumnoSolicitarVacanteTypeExtracurricular;

  /// No description provided for @alumnoSolicitarVacanteTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitar vacante'**
  String get alumnoSolicitarVacanteTitle;

  /// No description provided for @alumnoSolicitarVacanteSummarySemantics.
  ///
  /// In es, this message translates to:
  /// **'Resumen: {value}'**
  String alumnoSolicitarVacanteSummarySemantics(Object value);

  /// No description provided for @alumnoSolicitarVacanteSendCta.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get alumnoSolicitarVacanteSendCta;

  /// No description provided for @institucionLoginBadCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales incorrectas.'**
  String get institucionLoginBadCredentials;

  /// No description provided for @institucionLoginInvalidInstitutionId.
  ///
  /// In es, this message translates to:
  /// **'ID de institución inválido.'**
  String get institucionLoginInvalidInstitutionId;

  /// No description provided for @institucionLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get institucionLoginTitle;

  /// No description provided for @institucionLoginAppBar.
  ///
  /// In es, this message translates to:
  /// **'Acceso de institución'**
  String get institucionLoginAppBar;

  /// No description provided for @institucionRegistroPickAtLeastOneModule.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná al menos un módulo.'**
  String get institucionRegistroPickAtLeastOneModule;

  /// No description provided for @institucionRegistroAppBar.
  ///
  /// In es, this message translates to:
  /// **'Registro de institución'**
  String get institucionRegistroAppBar;

  /// No description provided for @institucionRegistroIntro.
  ///
  /// In es, this message translates to:
  /// **'Completá los datos para registrar la institución.'**
  String get institucionRegistroIntro;

  /// No description provided for @institucionRegistroSectionBasics.
  ///
  /// In es, this message translates to:
  /// **'Datos básicos'**
  String get institucionRegistroSectionBasics;

  /// No description provided for @institucionRegistroInstitutionName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la institución'**
  String get institucionRegistroInstitutionName;

  /// No description provided for @institucionRegistroCuit.
  ///
  /// In es, this message translates to:
  /// **'CUIT'**
  String get institucionRegistroCuit;

  /// No description provided for @institucionRegistroCuitInvalid.
  ///
  /// In es, this message translates to:
  /// **'CUIT inválido.'**
  String get institucionRegistroCuitInvalid;

  /// No description provided for @institucionRegistroAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get institucionRegistroAddress;

  /// No description provided for @institucionRegistroSectionLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get institucionRegistroSectionLocation;

  /// No description provided for @institucionRegistroCountry.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get institucionRegistroCountry;

  /// No description provided for @institucionRegistroProvince.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get institucionRegistroProvince;

  /// No description provided for @institucionRegistroCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get institucionRegistroCity;

  /// No description provided for @institucionRegistroSectionAccessContact.
  ///
  /// In es, this message translates to:
  /// **'Acceso y contacto'**
  String get institucionRegistroSectionAccessContact;

  /// No description provided for @institucionRegistroSectionConfig.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get institucionRegistroSectionConfig;

  /// No description provided for @institucionRegistroInstitutionType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de institución'**
  String get institucionRegistroInstitutionType;

  /// No description provided for @institucionRegistroModality.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get institucionRegistroModality;

  /// No description provided for @institucionRegistroSectionModules.
  ///
  /// In es, this message translates to:
  /// **'Módulos'**
  String get institucionRegistroSectionModules;

  /// No description provided for @institucionRegistroCurricularSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná niveles curriculares'**
  String get institucionRegistroCurricularSubtitle;

  /// No description provided for @institucionRegistroCurricularChipSemantics.
  ///
  /// In es, this message translates to:
  /// **'Nivel curricular: {value}'**
  String institucionRegistroCurricularChipSemantics(Object value);

  /// No description provided for @institucionRegistroExtracurricularSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná bloques extracurriculares'**
  String get institucionRegistroExtracurricularSubtitle;

  /// No description provided for @institucionRegistroExtracurricularChipSemantics.
  ///
  /// In es, this message translates to:
  /// **'Bloque extracurricular: {value}'**
  String institucionRegistroExtracurricularChipSemantics(Object value);

  /// No description provided for @cuentaHomeDeeplinkOwnerMismatch.
  ///
  /// In es, this message translates to:
  /// **'Este deeplink pertenece a otra cuenta.'**
  String get cuentaHomeDeeplinkOwnerMismatch;

  /// No description provided for @cuentaHomeDeeplinkAlumnoRequired.
  ///
  /// In es, this message translates to:
  /// **'Se requiere un perfil de alumno para este deeplink.'**
  String get cuentaHomeDeeplinkAlumnoRequired;

  /// No description provided for @cuentaHomeDestinoCalendario.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get cuentaHomeDestinoCalendario;

  /// No description provided for @cuentaHomeDestinoDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get cuentaHomeDestinoDocumentos;

  /// No description provided for @cuentaHomeDeeplinkMissingPerfilId.
  ///
  /// In es, this message translates to:
  /// **'Falta perfilId para abrir este deeplink: {path}'**
  String cuentaHomeDeeplinkMissingPerfilId(Object path);

  /// No description provided for @cuentaHomeCrearInstitucionTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear institución'**
  String get cuentaHomeCrearInstitucionTitle;

  /// No description provided for @cuentaHomeCrearInstitucionNombreLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get cuentaHomeCrearInstitucionNombreLabel;

  /// No description provided for @cuentaHomeCrearInstitucionNombreRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el nombre.'**
  String get cuentaHomeCrearInstitucionNombreRequired;

  /// No description provided for @cuentaHomeCrearInstitucionEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get cuentaHomeCrearInstitucionEmailLabel;

  /// No description provided for @cuentaHomeCrearInstitucionEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el email.'**
  String get cuentaHomeCrearInstitucionEmailRequired;

  /// No description provided for @cuentaHomeCrearInstitucionTelefonoLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get cuentaHomeCrearInstitucionTelefonoLabel;

  /// No description provided for @cuentaHomeCrearInstitucionTelefonoRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el teléfono.'**
  String get cuentaHomeCrearInstitucionTelefonoRequired;

  /// No description provided for @cuentaHomeCrearPerfilTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil'**
  String get cuentaHomeCrearPerfilTitle;

  /// No description provided for @cuentaHomeTipoAlumno.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get cuentaHomeTipoAlumno;

  /// No description provided for @cuentaHomeTipoInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get cuentaHomeTipoInstitucion;

  /// No description provided for @cuentaHomeContinuarUltimoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Continuar con el último perfil'**
  String get cuentaHomeContinuarUltimoPerfil;

  /// No description provided for @cuentaHomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get cuentaHomeTitle;

  /// No description provided for @cuentaHomeRedirectingInstitution.
  ///
  /// In es, this message translates to:
  /// **'Redirigiendo a institución…'**
  String get cuentaHomeRedirectingInstitution;

  /// No description provided for @cuentaHomePreparingInstitution.
  ///
  /// In es, this message translates to:
  /// **'Preparando institución…'**
  String get cuentaHomePreparingInstitution;

  /// No description provided for @cuentaHomeCreateProfileCta.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil'**
  String get cuentaHomeCreateProfileCta;

  /// No description provided for @cuentaHomeAccountLine.
  ///
  /// In es, this message translates to:
  /// **'Cuenta: {ownerId}'**
  String cuentaHomeAccountLine(Object ownerId);

  /// No description provided for @cuentaHomeNoProfiles.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay perfiles.'**
  String get cuentaHomeNoProfiles;

  /// No description provided for @cuentaHomeInstitutionsSection.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get cuentaHomeInstitutionsSection;

  /// No description provided for @cuentaHomeInstitutionIdLine.
  ///
  /// In es, this message translates to:
  /// **'Institución: {id}'**
  String cuentaHomeInstitutionIdLine(Object id);

  /// No description provided for @cuentaHomeStudentsSection.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get cuentaHomeStudentsSection;

  /// No description provided for @cuentaHomeNoStudents.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay alumnos.'**
  String get cuentaHomeNoStudents;

  /// No description provided for @cuentaHomeStudentDniLine.
  ///
  /// In es, this message translates to:
  /// **'DNI: {dni}'**
  String cuentaHomeStudentDniLine(Object dni);

  /// No description provided for @commonPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get commonPreview;

  /// No description provided for @alumnoBuscarInstitucionesHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar institución o actividad…'**
  String get alumnoBuscarInstitucionesHint;

  /// No description provided for @commonMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get commonMon;

  /// No description provided for @commonTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get commonTue;

  /// No description provided for @commonWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get commonWed;

  /// No description provided for @commonThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get commonThu;

  /// No description provided for @commonFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get commonFri;

  /// No description provided for @commonSat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get commonSat;

  /// No description provided for @commonSun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get commonSun;

  /// No description provided for @commonInvalidSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión inválida.'**
  String get commonInvalidSession;

  /// No description provided for @commonUnread.
  ///
  /// In es, this message translates to:
  /// **'No leída'**
  String get commonUnread;

  /// No description provided for @commonRead.
  ///
  /// In es, this message translates to:
  /// **'Leída'**
  String get commonRead;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonShiftMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get commonShiftMorning;

  /// No description provided for @commonShiftAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get commonShiftAfternoon;

  /// No description provided for @commonShiftNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get commonShiftNight;

  /// No description provided for @alumnoSeleccionGrupoOpenSolicitudError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Solicitudes: {error}'**
  String alumnoSeleccionGrupoOpenSolicitudError(Object error);

  /// No description provided for @alumnoSeleccionGrupoSlotsAvailable.
  ///
  /// In es, this message translates to:
  /// **'Cupos disponibles: {count}'**
  String alumnoSeleccionGrupoSlotsAvailable(Object count);

  /// No description provided for @institucionAreaSemanticsCroquisLocked.
  ///
  /// In es, this message translates to:
  /// **'Croquis no disponible'**
  String get institucionAreaSemanticsCroquisLocked;

  /// No description provided for @institucionPlanBillingTitle.
  ///
  /// In es, this message translates to:
  /// **'Facturación y cobro'**
  String get institucionPlanBillingTitle;

  /// No description provided for @institucionPlanBillingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona el cobro en ATENA (fase 2)'**
  String get institucionPlanBillingSubtitle;

  /// No description provided for @institucionPlanBillingIntro.
  ///
  /// In es, this message translates to:
  /// **'Antes de confirmar, tené en cuenta lo siguiente:'**
  String get institucionPlanBillingIntro;

  /// No description provided for @institucionPlanBillingPoint1.
  ///
  /// In es, this message translates to:
  /// **'ATENA solo cobra a instituciones (no a alumnos).'**
  String get institucionPlanBillingPoint1;

  /// No description provided for @institucionPlanBillingPoint2.
  ///
  /// In es, this message translates to:
  /// **'En fase 2 no hay cobros reales: la confirmación es local/prototipo.'**
  String get institucionPlanBillingPoint2;

  /// No description provided for @institucionPlanBillingPoint3.
  ///
  /// In es, this message translates to:
  /// **'El plan habilita niveles y módulos; podés cambiarlo más adelante.'**
  String get institucionPlanBillingPoint3;

  /// No description provided for @institucionPlanBillingPoint4.
  ///
  /// In es, this message translates to:
  /// **'Las instituciones pueden administrar sus perfiles de trabajo por actividad sin compartir credenciales.'**
  String get institucionPlanBillingPoint4;

  /// No description provided for @institucionPlanBillingPoint5.
  ///
  /// In es, this message translates to:
  /// **'Cuando integremos pagos reales, se aplicarán términos, facturación y políticas de reembolso según la configuración final.'**
  String get institucionPlanBillingPoint5;

  /// No description provided for @institutionProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil de institución – {name}'**
  String institutionProfileTitle(Object name);

  /// No description provided for @institutionProfileLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el perfil: {error}'**
  String institutionProfileLoadError(Object error);

  /// No description provided for @institutionProfileSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el perfil: {error}'**
  String institutionProfileSaveError(Object error);

  /// No description provided for @institutionProfileSectionIdentity.
  ///
  /// In es, this message translates to:
  /// **'Identidad'**
  String get institutionProfileSectionIdentity;

  /// No description provided for @institutionProfileSectionContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get institutionProfileSectionContact;

  /// No description provided for @institutionProfileSectionLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get institutionProfileSectionLocation;

  /// No description provided for @institutionProfileSectionSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get institutionProfileSectionSettings;

  /// No description provided for @institutionProfileFieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get institutionProfileFieldName;

  /// No description provided for @institutionProfileFieldCuit.
  ///
  /// In es, this message translates to:
  /// **'CUIT'**
  String get institutionProfileFieldCuit;

  /// No description provided for @institutionProfileFieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get institutionProfileFieldEmail;

  /// No description provided for @institutionProfileFieldPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get institutionProfileFieldPhone;

  /// No description provided for @institutionProfileFieldAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get institutionProfileFieldAddress;

  /// No description provided for @institutionProfileFieldCountry.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get institutionProfileFieldCountry;

  /// No description provided for @institutionProfileFieldProvince.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get institutionProfileFieldProvince;

  /// No description provided for @institutionProfileFieldCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get institutionProfileFieldCity;

  /// No description provided for @institutionProfileFieldModalidad.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get institutionProfileFieldModalidad;

  /// No description provided for @institutionProfileFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de institución'**
  String get institutionProfileFieldType;

  /// No description provided for @institutionProfileFieldCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get institutionProfileFieldCurricular;

  /// No description provided for @institutionProfileFieldExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get institutionProfileFieldExtracurricular;

  /// No description provided for @institutionProfileModalidadLabel.
  ///
  /// In es, this message translates to:
  /// **'{key}'**
  String institutionProfileModalidadLabel(Object key);

  /// No description provided for @institutionProfileTipoLabel.
  ///
  /// In es, this message translates to:
  /// **'{key}'**
  String institutionProfileTipoLabel(Object key);

  /// No description provided for @commonFixErrors.
  ///
  /// In es, this message translates to:
  /// **'Corregí los errores del formulario.'**
  String get commonFixErrors;

  /// No description provided for @commonRequiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio.'**
  String get commonRequiredField;

  /// No description provided for @commonSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado.'**
  String get commonSaved;

  /// No description provided for @saved.
  ///
  /// In es, this message translates to:
  /// **'Guardado.'**
  String get saved;

  /// No description provided for @primeroSeleccionaUnaActividad.
  ///
  /// In es, this message translates to:
  /// **'Primero seleccioná una actividad'**
  String get primeroSeleccionaUnaActividad;

  /// No description provided for @losPerfilesDeTrabajoSonInternos.
  ///
  /// In es, this message translates to:
  /// **'Los perfiles de trabajo son internos'**
  String get losPerfilesDeTrabajoSonInternos;

  /// No description provided for @perfilesDeTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Perfiles de trabajo'**
  String get perfilesDeTrabajo;

  /// No description provided for @entrar.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get entrar;

  /// No description provided for @bloqueadoPorVos.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por vos'**
  String get bloqueadoPorVos;

  /// No description provided for @bloqueado.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get bloqueado;

  /// No description provided for @bloqueadoPor.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por {who}'**
  String bloqueadoPor(Object who);

  /// No description provided for @seleccionarActividad.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar actividad'**
  String get seleccionarActividad;

  /// No description provided for @noHayActividadesHabilitadas.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay actividades configuradas'**
  String get noHayActividadesHabilitadas;

  /// No description provided for @institutionPublicProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil público – {name}'**
  String institutionPublicProfileTitle(Object name);

  /// No description provided for @institutionPublicProfileSectionOverview.
  ///
  /// In es, this message translates to:
  /// **'Presentación'**
  String get institutionPublicProfileSectionOverview;

  /// No description provided for @institutionPublicProfileSectionServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get institutionPublicProfileSectionServices;

  /// No description provided for @institutionPublicProfileSectionCourses.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get institutionPublicProfileSectionCourses;

  /// No description provided for @institutionPublicProfileSectionAdminHours.
  ///
  /// In es, this message translates to:
  /// **'Horarios de atención'**
  String get institutionPublicProfileSectionAdminHours;

  /// No description provided for @institutionPublicProfileSectionOnline.
  ///
  /// In es, this message translates to:
  /// **'Web y redes'**
  String get institutionPublicProfileSectionOnline;

  /// No description provided for @institutionPublicProfileSectionPhotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get institutionPublicProfileSectionPhotos;

  /// No description provided for @institutionPublicProfileAboutLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get institutionPublicProfileAboutLabel;

  /// No description provided for @institutionPublicProfileAboutHint.
  ///
  /// In es, this message translates to:
  /// **'Contá brevemente qué ofrece la institución (máx. 500 caracteres).'**
  String get institutionPublicProfileAboutHint;

  /// No description provided for @institutionPublicProfileServicesLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get institutionPublicProfileServicesLabel;

  /// No description provided for @institutionPublicProfileServicesHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: apoyo escolar, talleres, comedor, transporte…'**
  String get institutionPublicProfileServicesHint;

  /// No description provided for @institutionPublicProfileAddService.
  ///
  /// In es, this message translates to:
  /// **'Agregar servicio'**
  String get institutionPublicProfileAddService;

  /// No description provided for @institutionPublicProfileServiceNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get institutionPublicProfileServiceNameLabel;

  /// No description provided for @institutionPublicProfileServiceNameHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Apoyo escolar'**
  String get institutionPublicProfileServiceNameHint;

  /// No description provided for @institutionPublicProfileServiceInvalid.
  ///
  /// In es, this message translates to:
  /// **'Servicio inválido.'**
  String get institutionPublicProfileServiceInvalid;

  /// No description provided for @institutionPublicProfileShortCoursesLabel.
  ///
  /// In es, this message translates to:
  /// **'Ofrece cursos cortos'**
  String get institutionPublicProfileShortCoursesLabel;

  /// No description provided for @institutionPublicProfileCourseDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración (opcional)'**
  String get institutionPublicProfileCourseDurationLabel;

  /// No description provided for @institutionPublicProfileCourseDurationHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: 4 semanas / 2 meses'**
  String get institutionPublicProfileCourseDurationHint;

  /// No description provided for @institutionPublicProfileCourseDurationInvalid.
  ///
  /// In es, this message translates to:
  /// **'Duración inválida.'**
  String get institutionPublicProfileCourseDurationInvalid;

  /// No description provided for @institutionPublicProfileTeachingModeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cursado'**
  String get institutionPublicProfileTeachingModeLabel;

  /// No description provided for @institutionPublicProfileTeachingModePresencial.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get institutionPublicProfileTeachingModePresencial;

  /// No description provided for @institutionPublicProfileTeachingModeRemoto.
  ///
  /// In es, this message translates to:
  /// **'A distancia'**
  String get institutionPublicProfileTeachingModeRemoto;

  /// No description provided for @institutionPublicProfileTeachingModeHibrido.
  ///
  /// In es, this message translates to:
  /// **'Híbrido'**
  String get institutionPublicProfileTeachingModeHibrido;

  /// No description provided for @institutionPublicProfileAdminHoursLabel.
  ///
  /// In es, this message translates to:
  /// **'Horario de atención administrativa'**
  String get institutionPublicProfileAdminHoursLabel;

  /// No description provided for @institutionPublicProfileAdminHoursHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Lun a Vie 9:00 a 17:00'**
  String get institutionPublicProfileAdminHoursHint;

  /// No description provided for @institutionPublicProfilePhoneOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get institutionPublicProfilePhoneOptionalLabel;

  /// No description provided for @institutionPublicProfileWebsiteLabel.
  ///
  /// In es, this message translates to:
  /// **'Página web (opcional)'**
  String get institutionPublicProfileWebsiteLabel;

  /// No description provided for @institutionPublicProfileWebsiteHint.
  ///
  /// In es, this message translates to:
  /// **'https://…'**
  String get institutionPublicProfileWebsiteHint;

  /// No description provided for @institutionPublicProfileWebsiteInvalid.
  ///
  /// In es, this message translates to:
  /// **'URL inválida.'**
  String get institutionPublicProfileWebsiteInvalid;

  /// No description provided for @institutionPublicProfileInstagramLabel.
  ///
  /// In es, this message translates to:
  /// **'Instagram (opcional)'**
  String get institutionPublicProfileInstagramLabel;

  /// No description provided for @institutionPublicProfileFacebookLabel.
  ///
  /// In es, this message translates to:
  /// **'Facebook (opcional)'**
  String get institutionPublicProfileFacebookLabel;

  /// No description provided for @institutionPublicProfileXLabel.
  ///
  /// In es, this message translates to:
  /// **'X / Twitter (opcional)'**
  String get institutionPublicProfileXLabel;

  /// No description provided for @institutionPublicProfileYoutubeLabel.
  ///
  /// In es, this message translates to:
  /// **'YouTube (opcional)'**
  String get institutionPublicProfileYoutubeLabel;

  /// No description provided for @institutionPublicProfileTiktokLabel.
  ///
  /// In es, this message translates to:
  /// **'TikTok (opcional)'**
  String get institutionPublicProfileTiktokLabel;

  /// No description provided for @institutionPublicProfileLinkedinLabel.
  ///
  /// In es, this message translates to:
  /// **'LinkedIn (opcional)'**
  String get institutionPublicProfileLinkedinLabel;

  /// No description provided for @institutionPublicProfileOtherLinkLabel.
  ///
  /// In es, this message translates to:
  /// **'Otro link (opcional)'**
  String get institutionPublicProfileOtherLinkLabel;

  /// No description provided for @institutionPublicProfilePricesLabel.
  ///
  /// In es, this message translates to:
  /// **'Precios (opcional)'**
  String get institutionPublicProfilePricesLabel;

  /// No description provided for @institutionPublicProfilePricesHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: desde \$… / rango / consultar'**
  String get institutionPublicProfilePricesHint;

  /// No description provided for @institutionPublicProfilePricesTooLong.
  ///
  /// In es, this message translates to:
  /// **'Texto demasiado largo.'**
  String get institutionPublicProfilePricesTooLong;

  /// No description provided for @institutionPublicProfilePhotosLabel.
  ///
  /// In es, this message translates to:
  /// **'Galería (hasta {max})'**
  String institutionPublicProfilePhotosLabel(Object max);

  /// No description provided for @institutionPublicProfileAddPhoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get institutionPublicProfileAddPhoto;

  /// No description provided for @institutionPublicProfileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get institutionPublicProfileChangePhoto;

  /// No description provided for @institutionPublicProfileRemovePhoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get institutionPublicProfileRemovePhoto;

  /// No description provided for @institutionPublicProfilePhotoLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Ya cargaste el máximo de fotos ({max}).'**
  String institutionPublicProfilePhotoLimitReached(Object max);

  /// No description provided for @institutionPublicProfileNoPhotosYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay fotos.'**
  String get institutionPublicProfileNoPhotosYet;

  /// No description provided for @institutionPublicProfilePickPhotoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la foto: {error}'**
  String institutionPublicProfilePickPhotoError(Object error);

  /// No description provided for @institutionPublicProfileSaveOk.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado.'**
  String get institutionPublicProfileSaveOk;

  /// No description provided for @institutionPublicProfileSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el perfil: {error}'**
  String institutionPublicProfileSaveFailed(Object error);

  /// No description provided for @institucionGeneric.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get institucionGeneric;

  /// No description provided for @institucionExtracBaseEmitirFichaTitle.
  ///
  /// In es, this message translates to:
  /// **'Emitir ficha'**
  String get institucionExtracBaseEmitirFichaTitle;

  /// No description provided for @institucionExtracBaseEmitirFichaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crear una ficha para {group} y enviarla a alumnos/solicitudes.'**
  String institucionExtracBaseEmitirFichaSubtitle(Object group);

  /// No description provided for @institucionExtracBaseEmitirFichaGrupoLabel.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get institucionExtracBaseEmitirFichaGrupoLabel;

  /// No description provided for @institucionExtracBaseEmitirFichaTituloLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get institucionExtracBaseEmitirFichaTituloLabel;

  /// No description provided for @institucionExtracBaseEmitirFichaTituloHint.
  ///
  /// In es, this message translates to:
  /// **'ej.: Reunión informativa'**
  String get institucionExtracBaseEmitirFichaTituloHint;

  /// No description provided for @institucionExtracBaseEmitirFichaContenidoLabel.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get institucionExtracBaseEmitirFichaContenidoLabel;

  /// No description provided for @institucionExtracBaseEmitirFichaContenidoHint.
  ///
  /// In es, this message translates to:
  /// **'Escribí el detalle de la ficha…'**
  String get institucionExtracBaseEmitirFichaContenidoHint;

  /// No description provided for @institucionExtracBaseEmitirFichaAddToCalendar.
  ///
  /// In es, this message translates to:
  /// **'Agregar al calendario'**
  String get institucionExtracBaseEmitirFichaAddToCalendar;

  /// No description provided for @institucionExtracBaseEmitirFichaAddToCalendarHelp.
  ///
  /// In es, this message translates to:
  /// **'Si está activado, se crea un evento en el calendario del alumno.'**
  String get institucionExtracBaseEmitirFichaAddToCalendarHelp;

  /// No description provided for @institucionExtracBaseEmitirFichaRequireRsvp.
  ///
  /// In es, this message translates to:
  /// **'Requiere confirmación'**
  String get institucionExtracBaseEmitirFichaRequireRsvp;

  /// No description provided for @institucionExtracBaseEmitirFichaRequireRsvpHelp.
  ///
  /// In es, this message translates to:
  /// **'Si está activado, el alumno podrá confirmar asistencia (sí / quizás / no).'**
  String get institucionExtracBaseEmitirFichaRequireRsvpHelp;

  /// No description provided for @institucionExtracBaseEmitirFichaDestinatariosTitle.
  ///
  /// In es, this message translates to:
  /// **'Destinatarios'**
  String get institucionExtracBaseEmitirFichaDestinatariosTitle;

  /// No description provided for @institucionExtracBaseEmitirFichaDestinatariosEmptyHelp.
  ///
  /// In es, this message translates to:
  /// **'No hay destinatarios disponibles para este grupo.'**
  String get institucionExtracBaseEmitirFichaDestinatariosEmptyHelp;

  /// No description provided for @institucionExtracBaseEmitirFichaManualLabel.
  ///
  /// In es, this message translates to:
  /// **'Destinatarios manuales'**
  String get institucionExtracBaseEmitirFichaManualLabel;

  /// No description provided for @institucionExtracBaseEmitirFichaManualHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresá uno o más documentos/IDs, separados por coma'**
  String get institucionExtracBaseEmitirFichaManualHint;

  /// No description provided for @actionSelectAll.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar todo'**
  String get actionSelectAll;

  /// No description provided for @actionSelectNone.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ninguno'**
  String get actionSelectNone;

  /// No description provided for @actionEmit.
  ///
  /// In es, this message translates to:
  /// **'Emitir'**
  String get actionEmit;

  /// No description provided for @institucionExtracBaseEmitirFichaDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Ficha – {module}'**
  String institucionExtracBaseEmitirFichaDefaultTitle(Object module);

  /// No description provided for @institucionExtracBaseEmitirFichaDefaultBody.
  ///
  /// In es, this message translates to:
  /// **'Se generó una ficha para compartir información del grupo.'**
  String get institucionExtracBaseEmitirFichaDefaultBody;

  /// No description provided for @institucionExtracBaseEmitirFichaNoRecipients.
  ///
  /// In es, this message translates to:
  /// **'No hay destinatarios seleccionados.'**
  String get institucionExtracBaseEmitirFichaNoRecipients;

  /// No description provided for @institucionExtracBaseEmitirFichaOk.
  ///
  /// In es, this message translates to:
  /// **'Ficha emitida.'**
  String get institucionExtracBaseEmitirFichaOk;

  /// No description provided for @institucionExtracBaseEmitirFichaServiceMissing.
  ///
  /// In es, this message translates to:
  /// **'Servicio no disponible.'**
  String get institucionExtracBaseEmitirFichaServiceMissing;

  /// No description provided for @institucionExtracBaseEmitirFichaFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo emitir la ficha: {error}'**
  String institucionExtracBaseEmitirFichaFailed(Object error);

  /// No description provided for @institucionExtracBaseEmitirFichaBanner.
  ///
  /// In es, this message translates to:
  /// **'Emití fichas como notificación y, opcionalmente, como evento de calendario.'**
  String get institucionExtracBaseEmitirFichaBanner;

  /// No description provided for @institucionExtracBaseEmitirFichaCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Emitir ficha'**
  String get institucionExtracBaseEmitirFichaCardTitle;

  /// No description provided for @institucionExtracBaseEmitirFichaCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crear una ficha informativa para el grupo seleccionado'**
  String get institucionExtracBaseEmitirFichaCardSubtitle;

  /// No description provided for @institucionExtracBaseOpenInboxCta.
  ///
  /// In es, this message translates to:
  /// **'Abrir notificaciones'**
  String get institucionExtracBaseOpenInboxCta;

  /// No description provided for @institucionExtracBaseEmitirFichaCardFootnote.
  ///
  /// In es, this message translates to:
  /// **'Las fichas se guardan como notificación (prototipo).'**
  String get institucionExtracBaseEmitirFichaCardFootnote;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
