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

  /// No description provided for @instituciones.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get instituciones;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @curricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get curricular;

  /// No description provided for @extracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get extracurricular;

  /// No description provided for @code.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get code;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

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

  /// No description provided for @commonInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get commonInstitution;

  /// No description provided for @commonGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando…'**
  String get commonGenerating;

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

  /// No description provided for @commonLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonLogout;

  /// No description provided for @commonNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get commonNameLabel;

  /// No description provided for @commonLastNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get commonLastNameLabel;

  /// No description provided for @commonEmailOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Email (opcional)'**
  String get commonEmailOptionalLabel;

  /// No description provided for @commonPhoneOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get commonPhoneOptionalLabel;

  /// No description provided for @commonDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get commonDate;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

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

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get commonTitle;

  /// No description provided for @commonView.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get commonView;

  /// No description provided for @commonSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando…'**
  String get commonSending;

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

  /// No description provided for @commonContinuing.
  ///
  /// In es, this message translates to:
  /// **'Continuando…'**
  String get commonContinuing;

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

  /// No description provided for @commonRequiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio.'**
  String get commonRequiredField;

  /// No description provided for @uiSomethingWentWrong.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get uiSomethingWentWrong;

  /// No description provided for @landingTagline.
  ///
  /// In es, this message translates to:
  /// **'Educación conectada'**
  String get landingTagline;

  /// No description provided for @landingHeadline.
  ///
  /// In es, this message translates to:
  /// **'Alumnos e instituciones, en un mismo lugar.'**
  String get landingHeadline;

  /// No description provided for @landingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones, vacantes, documentos y calendario, sin papeles ni idas y vueltas.'**
  String get landingSubtitle;

  /// No description provided for @landingStudentTitle.
  ///
  /// In es, this message translates to:
  /// **'Soy alumno o familia'**
  String get landingStudentTitle;

  /// No description provided for @landingStudentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Buscá instituciones, pedí tu vacante y seguí cada trámite.'**
  String get landingStudentSubtitle;

  /// No description provided for @landingInstitutionTitle.
  ///
  /// In es, this message translates to:
  /// **'Soy una institución'**
  String get landingInstitutionTitle;

  /// No description provided for @landingInstitutionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestioná vacantes, solicitudes, grupos y comunicaciones.'**
  String get landingInstitutionSubtitle;

  /// No description provided for @landingChooseHowToEnter.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo querés ingresar?'**
  String get landingChooseHowToEnter;

  /// No description provided for @landingChooseHowToEnterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu perfil para continuar.'**
  String get landingChooseHowToEnterSubtitle;

  /// No description provided for @landingBulletRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de vacantes en línea'**
  String get landingBulletRequests;

  /// No description provided for @landingBulletDocuments.
  ///
  /// In es, this message translates to:
  /// **'Fichas y documentos en PDF'**
  String get landingBulletDocuments;

  /// No description provided for @landingBulletCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario y avisos al instante'**
  String get landingBulletCalendar;

  /// No description provided for @landingFooter.
  ///
  /// In es, this message translates to:
  /// **'© {year} ATENA · Plataforma educativa'**
  String landingFooter(Object year);

  /// No description provided for @prefsTitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get prefsTitle;

  /// No description provided for @prefsTheme.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get prefsTheme;

  /// No description provided for @prefsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get prefsThemeSystem;

  /// No description provided for @prefsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get prefsThemeLight;

  /// No description provided for @prefsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get prefsThemeDark;

  /// No description provided for @prefsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get prefsLanguage;

  /// No description provided for @prefsLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático (idioma del dispositivo)'**
  String get prefsLanguageSystem;

  /// No description provided for @authFamiliaLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresá a tu cuenta'**
  String get authFamiliaLoginTitle;

  /// No description provided for @authFamiliaLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Alumnos y familias'**
  String get authFamiliaLoginSubtitle;

  /// No description provided for @authInstitucionLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingreso de instituciones'**
  String get authInstitucionLoginTitle;

  /// No description provided for @authInstitucionLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestioná vacantes, solicitudes y comunicaciones.'**
  String get authInstitucionLoginSubtitle;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Todavía no tenés cuenta?'**
  String get authNoAccount;

  /// No description provided for @authNoInstitution.
  ///
  /// In es, this message translates to:
  /// **'¿Tu institución todavía no está en ATENA?'**
  String get authNoInstitution;

  /// No description provided for @authRegisterInstitution.
  ///
  /// In es, this message translates to:
  /// **'Registrar institución'**
  String get authRegisterInstitution;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tenés cuenta?'**
  String get authHaveAccount;

  /// No description provided for @authFamiliaRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Creá tu cuenta'**
  String get authFamiliaRegisterTitle;

  /// No description provided for @authFamiliaRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'En dos minutos vas a poder buscar instituciones y pedir vacantes.'**
  String get authFamiliaRegisterSubtitle;

  /// No description provided for @authStudentSection.
  ///
  /// In es, this message translates to:
  /// **'Datos del alumno'**
  String get authStudentSection;

  /// No description provided for @authStudentSectionHelp.
  ///
  /// In es, this message translates to:
  /// **'Si sos madre, padre o tutor, cargá los datos del alumno. Después podés sumar más alumnos a la misma cuenta.'**
  String get authStudentSectionHelp;

  /// No description provided for @authAccessSection.
  ///
  /// In es, this message translates to:
  /// **'Datos de acceso'**
  String get authAccessSection;

  /// No description provided for @authBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get authBirthDate;

  /// No description provided for @authBirthDateRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí la fecha de nacimiento.'**
  String get authBirthDateRequired;

  /// No description provided for @authDniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get authDniLabel;

  /// No description provided for @authDniHelper.
  ///
  /// In es, this message translates to:
  /// **'Solo números, sin puntos.'**
  String get authDniHelper;

  /// No description provided for @authPasswordHelper.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres.'**
  String get authPasswordHelper;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In es, this message translates to:
  /// **'Repetí la contraseña'**
  String get authPasswordConfirm;

  /// No description provided for @authResetTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get authResetTitle;

  /// No description provided for @authResetFamiliaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmá tu identidad con el DNI de un alumno de la cuenta y elegí una contraseña nueva.'**
  String get authResetFamiliaSubtitle;

  /// No description provided for @authResetInstitucionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmá tu identidad con el CUIT registrado y elegí una contraseña nueva.'**
  String get authResetInstitucionSubtitle;

  /// No description provided for @authResetDniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI de un alumno de la cuenta'**
  String get authResetDniLabel;

  /// No description provided for @authCuitHelper.
  ///
  /// In es, this message translates to:
  /// **'11 dígitos, sin guiones.'**
  String get authCuitHelper;

  /// No description provided for @authResetCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña nueva'**
  String get authResetCta;

  /// No description provided for @authResetDone.
  ///
  /// In es, this message translates to:
  /// **'Listo. Ya podés ingresar con tu contraseña nueva.'**
  String get authResetDone;

  /// No description provided for @authInstRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrá tu institución'**
  String get authInstRegisterTitle;

  /// No description provided for @authInstRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completá los datos y en el siguiente paso elegí los módulos de tu plan.'**
  String get authInstRegisterSubtitle;

  /// No description provided for @authStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de {total}'**
  String authStepOf(Object step, Object total);

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El email no es válido.'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con ese email.'**
  String get authErrEmailInUse;

  /// No description provided for @authErrAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos una cuenta con esos datos.'**
  String get authErrAccountNotFound;

  /// No description provided for @authErrWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get authErrWrongCredentials;

  /// No description provided for @authErrInvalidDni.
  ///
  /// In es, this message translates to:
  /// **'El DNI debe tener entre 7 y 9 dígitos.'**
  String get authErrInvalidDni;

  /// No description provided for @authErrDuplicateDni.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un alumno con ese DNI en tu cuenta.'**
  String get authErrDuplicateDni;

  /// No description provided for @authErrIdentityMismatch.
  ///
  /// In es, this message translates to:
  /// **'Los datos no coinciden con los de la cuenta.'**
  String get authErrIdentityMismatch;

  /// No description provided for @authErrInvalidName.
  ///
  /// In es, this message translates to:
  /// **'Completá nombre y apellido.'**
  String get authErrInvalidName;

  /// No description provided for @authErrInvalidAccount.
  ///
  /// In es, this message translates to:
  /// **'La sesión no es válida. Volvé a ingresar.'**
  String get authErrInvalidAccount;

  /// No description provided for @lblNivelJardin.
  ///
  /// In es, this message translates to:
  /// **'Nivel inicial'**
  String get lblNivelJardin;

  /// No description provided for @lblNivelPrimaria.
  ///
  /// In es, this message translates to:
  /// **'Primaria'**
  String get lblNivelPrimaria;

  /// No description provided for @lblNivelSecundaria.
  ///
  /// In es, this message translates to:
  /// **'Secundaria'**
  String get lblNivelSecundaria;

  /// No description provided for @lblNivelTecnica.
  ///
  /// In es, this message translates to:
  /// **'Técnica'**
  String get lblNivelTecnica;

  /// No description provided for @lblNivelTerciario.
  ///
  /// In es, this message translates to:
  /// **'Terciario'**
  String get lblNivelTerciario;

  /// No description provided for @lblBloqueDeporte.
  ///
  /// In es, this message translates to:
  /// **'Deporte y movimiento'**
  String get lblBloqueDeporte;

  /// No description provided for @lblBloqueArte.
  ///
  /// In es, this message translates to:
  /// **'Arte y expresión'**
  String get lblBloqueArte;

  /// No description provided for @lblBloqueIdiomas.
  ///
  /// In es, this message translates to:
  /// **'Idiomas y comunicación'**
  String get lblBloqueIdiomas;

  /// No description provided for @lblBloqueCiencia.
  ///
  /// In es, this message translates to:
  /// **'Ciencia, tecnología y robótica'**
  String get lblBloqueCiencia;

  /// No description provided for @lblBloqueApoyo.
  ///
  /// In es, this message translates to:
  /// **'Apoyo académico'**
  String get lblBloqueApoyo;

  /// No description provided for @lblBloqueBienestar.
  ///
  /// In es, this message translates to:
  /// **'Desarrollo personal y bienestar'**
  String get lblBloqueBienestar;

  /// No description provided for @lblBloqueOtros.
  ///
  /// In es, this message translates to:
  /// **'Otras actividades'**
  String get lblBloqueOtros;

  /// No description provided for @lblTurnoManana.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get lblTurnoManana;

  /// No description provided for @lblTurnoTarde.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get lblTurnoTarde;

  /// No description provided for @lblTurnoNoche.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get lblTurnoNoche;

  /// No description provided for @lblTurnoCompleto.
  ///
  /// In es, this message translates to:
  /// **'Jornada completa'**
  String get lblTurnoCompleto;

  /// No description provided for @lblModalidadPresencial.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get lblModalidadPresencial;

  /// No description provided for @lblModalidadRemoto.
  ///
  /// In es, this message translates to:
  /// **'A distancia'**
  String get lblModalidadRemoto;

  /// No description provided for @lblModalidadHibrido.
  ///
  /// In es, this message translates to:
  /// **'Híbrida'**
  String get lblModalidadHibrido;

  /// No description provided for @lblTipoInstJardin.
  ///
  /// In es, this message translates to:
  /// **'Jardín de infantes'**
  String get lblTipoInstJardin;

  /// No description provided for @lblTipoInstPrimaria.
  ///
  /// In es, this message translates to:
  /// **'Escuela primaria'**
  String get lblTipoInstPrimaria;

  /// No description provided for @lblTipoInstSecundaria.
  ///
  /// In es, this message translates to:
  /// **'Escuela secundaria'**
  String get lblTipoInstSecundaria;

  /// No description provided for @lblTipoInstTecnica.
  ///
  /// In es, this message translates to:
  /// **'Escuela técnica'**
  String get lblTipoInstTecnica;

  /// No description provided for @lblTipoInstTerciario.
  ///
  /// In es, this message translates to:
  /// **'Instituto terciario'**
  String get lblTipoInstTerciario;

  /// No description provided for @lblTipoInstTaller.
  ///
  /// In es, this message translates to:
  /// **'Taller o academia'**
  String get lblTipoInstTaller;

  /// No description provided for @lblTipoInstClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get lblTipoInstClub;

  /// No description provided for @lblTipoInstOtra.
  ///
  /// In es, this message translates to:
  /// **'Otra institución'**
  String get lblTipoInstOtra;

  /// No description provided for @lblCurricular.
  ///
  /// In es, this message translates to:
  /// **'Curricular'**
  String get lblCurricular;

  /// No description provided for @lblExtracurricular.
  ///
  /// In es, this message translates to:
  /// **'Extracurricular'**
  String get lblExtracurricular;

  /// No description provided for @lblEstadoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get lblEstadoPendiente;

  /// No description provided for @lblEstadoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get lblEstadoConfirmada;

  /// No description provided for @lblEstadoRechazada.
  ///
  /// In es, this message translates to:
  /// **'No aceptada'**
  String get lblEstadoRechazada;

  /// No description provided for @lblEstadoCanceladaAlumno.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get lblEstadoCanceladaAlumno;

  /// No description provided for @lblEstadoCanceladaInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Dada de baja'**
  String get lblEstadoCanceladaInstitucion;

  /// No description provided for @lblDocDni.
  ///
  /// In es, this message translates to:
  /// **'DNI del alumno'**
  String get lblDocDni;

  /// No description provided for @lblDocDniResponsable.
  ///
  /// In es, this message translates to:
  /// **'DNI del adulto responsable'**
  String get lblDocDniResponsable;

  /// No description provided for @lblDocPartida.
  ///
  /// In es, this message translates to:
  /// **'Partida de nacimiento'**
  String get lblDocPartida;

  /// No description provided for @lblDocCertMedico.
  ///
  /// In es, this message translates to:
  /// **'Certificado médico'**
  String get lblDocCertMedico;

  /// No description provided for @lblDocVacunas.
  ///
  /// In es, this message translates to:
  /// **'Carnet de vacunas'**
  String get lblDocVacunas;

  /// No description provided for @lblDocBoletin.
  ///
  /// In es, this message translates to:
  /// **'Boletín de calificaciones'**
  String get lblDocBoletin;

  /// No description provided for @lblDocPase.
  ///
  /// In es, this message translates to:
  /// **'Constancia de pase'**
  String get lblDocPase;

  /// No description provided for @lblDocFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto carnet'**
  String get lblDocFoto;

  /// No description provided for @lblDocDomicilio.
  ///
  /// In es, this message translates to:
  /// **'Constancia de domicilio'**
  String get lblDocDomicilio;

  /// No description provided for @lblDocOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro documento'**
  String get lblDocOtro;

  /// No description provided for @lblDocEstadoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Por entregar'**
  String get lblDocEstadoPendiente;

  /// No description provided for @lblDocEstadoEntregado.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get lblDocEstadoEntregado;

  /// No description provided for @lblDocEstadoAprobado.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get lblDocEstadoAprobado;

  /// No description provided for @lblDocEstadoRechazado.
  ///
  /// In es, this message translates to:
  /// **'Para corregir'**
  String get lblDocEstadoRechazado;

  /// No description provided for @lblDocEstadoCancelado.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get lblDocEstadoCancelado;

  /// No description provided for @lblDocVencido.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get lblDocVencido;

  /// No description provided for @lblEvGeneral.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get lblEvGeneral;

  /// No description provided for @lblEvReunion.
  ///
  /// In es, this message translates to:
  /// **'Reunión'**
  String get lblEvReunion;

  /// No description provided for @lblEvExamen.
  ///
  /// In es, this message translates to:
  /// **'Evaluación'**
  String get lblEvExamen;

  /// No description provided for @lblEvActo.
  ///
  /// In es, this message translates to:
  /// **'Acto escolar'**
  String get lblEvActo;

  /// No description provided for @lblEvSalida.
  ///
  /// In es, this message translates to:
  /// **'Salida educativa'**
  String get lblEvSalida;

  /// No description provided for @lblEvInicioClases.
  ///
  /// In es, this message translates to:
  /// **'Inicio de clases'**
  String get lblEvInicioClases;

  /// No description provided for @lblEvFinClases.
  ///
  /// In es, this message translates to:
  /// **'Fin de clases'**
  String get lblEvFinClases;

  /// No description provided for @lblEvVacaciones.
  ///
  /// In es, this message translates to:
  /// **'Vacaciones'**
  String get lblEvVacaciones;

  /// No description provided for @lblEvFeriado.
  ///
  /// In es, this message translates to:
  /// **'Feriado'**
  String get lblEvFeriado;

  /// No description provided for @lblAsisSi.
  ///
  /// In es, this message translates to:
  /// **'Asistiré'**
  String get lblAsisSi;

  /// No description provided for @lblAsisTalVez.
  ///
  /// In es, this message translates to:
  /// **'Tal vez'**
  String get lblAsisTalVez;

  /// No description provided for @lblAsisNo.
  ///
  /// In es, this message translates to:
  /// **'No asistiré'**
  String get lblAsisNo;

  /// No description provided for @lblEdadAnios.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 año} other{{n} años}}'**
  String lblEdadAnios(int n);

  /// No description provided for @lblRangoEdad.
  ///
  /// In es, this message translates to:
  /// **'De {min} a {max} años'**
  String lblRangoEdad(Object min, Object max);

  /// No description provided for @lblEdadDesde.
  ///
  /// In es, this message translates to:
  /// **'Desde {min} años'**
  String lblEdadDesde(Object min);

  /// No description provided for @lblEdadHasta.
  ///
  /// In es, this message translates to:
  /// **'Hasta {max} años'**
  String lblEdadHasta(Object max);

  /// No description provided for @lblCupos.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin vacantes} =1{1 vacante} other{{n} vacantes}}'**
  String lblCupos(int n);

  /// No description provided for @lblCuposDeTotal.
  ///
  /// In es, this message translates to:
  /// **'{libres} de {total} libres'**
  String lblCuposDeTotal(int libres, int total);

  /// No description provided for @notiBienvenidaTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Te damos la bienvenida a ATENA!'**
  String get notiBienvenidaTitle;

  /// No description provided for @notiBienvenidaBody.
  ///
  /// In es, this message translates to:
  /// **'Ya podés buscar instituciones y pedir vacantes.'**
  String get notiBienvenidaBody;

  /// No description provided for @notiSolicitudEnviadaTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get notiSolicitudEnviadaTitle;

  /// No description provided for @notiSolicitudEnviadaBody.
  ///
  /// In es, this message translates to:
  /// **'{alumno} · {oferta} en {institucion}. Te avisamos cuando respondan.'**
  String notiSolicitudEnviadaBody(
    Object alumno,
    Object oferta,
    Object institucion,
  );

  /// No description provided for @notiSolicitudRecibidaTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud'**
  String get notiSolicitudRecibidaTitle;

  /// No description provided for @notiSolicitudRecibidaBody.
  ///
  /// In es, this message translates to:
  /// **'{alumno} pidió vacante en {oferta}.'**
  String notiSolicitudRecibidaBody(Object alumno, Object oferta);

  /// No description provided for @notiSolicitudConfirmadaTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Vacante confirmada!'**
  String get notiSolicitudConfirmadaTitle;

  /// No description provided for @notiSolicitudConfirmadaBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} confirmó a {alumno} en {oferta}.'**
  String notiSolicitudConfirmadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  );

  /// No description provided for @notiSolicitudRechazadaTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud no aceptada'**
  String get notiSolicitudRechazadaTitle;

  /// No description provided for @notiSolicitudRechazadaBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} no pudo aceptar la solicitud de {alumno} para {oferta}.'**
  String notiSolicitudRechazadaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  );

  /// No description provided for @notiSolicitudCanceladaTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get notiSolicitudCanceladaTitle;

  /// No description provided for @notiSolicitudCanceladaBody.
  ///
  /// In es, this message translates to:
  /// **'{alumno} canceló su solicitud para {oferta}.'**
  String notiSolicitudCanceladaBody(Object alumno, Object oferta);

  /// No description provided for @notiSolicitudBajaTitle.
  ///
  /// In es, this message translates to:
  /// **'Baja de vacante'**
  String get notiSolicitudBajaTitle;

  /// No description provided for @notiSolicitudBajaBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} dio de baja a {alumno} de {oferta}.'**
  String notiSolicitudBajaBody(
    Object institucion,
    Object alumno,
    Object oferta,
  );

  /// No description provided for @notiDocSolicitadoTitle.
  ///
  /// In es, this message translates to:
  /// **'Te pidieron un documento'**
  String get notiDocSolicitadoTitle;

  /// No description provided for @notiDocSolicitadoBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} necesita: {documento}.'**
  String notiDocSolicitadoBody(Object institucion, Object documento);

  /// No description provided for @notiDocEntregadoTitle.
  ///
  /// In es, this message translates to:
  /// **'Documento recibido'**
  String get notiDocEntregadoTitle;

  /// No description provided for @notiDocEntregadoBody.
  ///
  /// In es, this message translates to:
  /// **'{alumno} entregó: {documento}.'**
  String notiDocEntregadoBody(Object alumno, Object documento);

  /// No description provided for @notiDocAprobadoTitle.
  ///
  /// In es, this message translates to:
  /// **'Documento aprobado'**
  String get notiDocAprobadoTitle;

  /// No description provided for @notiDocAprobadoBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} aprobó: {documento}.'**
  String notiDocAprobadoBody(Object institucion, Object documento);

  /// No description provided for @notiDocRechazadoTitle.
  ///
  /// In es, this message translates to:
  /// **'Documento para corregir'**
  String get notiDocRechazadoTitle;

  /// No description provided for @notiDocRechazadoBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion} pidió corregir: {documento}.'**
  String notiDocRechazadoBody(Object institucion, Object documento);

  /// No description provided for @notiEventoTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento en el calendario'**
  String get notiEventoTitle;

  /// No description provided for @notiEventoBody.
  ///
  /// In es, this message translates to:
  /// **'{institucion}: {evento}, el {fecha}.'**
  String notiEventoBody(Object institucion, Object evento, Object fecha);

  /// No description provided for @notiAvisoDe.
  ///
  /// In es, this message translates to:
  /// **'Aviso de {institucion}'**
  String notiAvisoDe(Object institucion);

  /// No description provided for @notiNota.
  ///
  /// In es, this message translates to:
  /// **'Mensaje: {nota}'**
  String notiNota(Object nota);

  /// No description provided for @errNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'No encontramos lo que buscabas. Puede que se haya eliminado.'**
  String get errNoEncontrado;

  /// No description provided for @errNoAutorizado.
  ///
  /// In es, this message translates to:
  /// **'No tenés permiso para hacer esto.'**
  String get errNoAutorizado;

  /// No description provided for @errDatosInvalidos.
  ///
  /// In es, this message translates to:
  /// **'Revisá los datos ingresados.'**
  String get errDatosInvalidos;

  /// No description provided for @errOfertaInactiva.
  ///
  /// In es, this message translates to:
  /// **'Esta vacante no está recibiendo solicitudes por ahora.'**
  String get errOfertaInactiva;

  /// No description provided for @errSinCupo.
  ///
  /// In es, this message translates to:
  /// **'No quedan vacantes disponibles.'**
  String get errSinCupo;

  /// No description provided for @errSolicitudDuplicada.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una solicitud activa para esta vacante.'**
  String get errSolicitudDuplicada;

  /// No description provided for @errEstadoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Esta acción ya no está disponible.'**
  String get errEstadoInvalido;

  /// No description provided for @errOfertaConSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar porque tiene solicitudes activas. Podés pausarla.'**
  String get errOfertaConSolicitudes;

  /// No description provided for @errArchivoMuyGrande.
  ///
  /// In es, this message translates to:
  /// **'El archivo es demasiado grande.'**
  String get errArchivoMuyGrande;

  /// No description provided for @errFormatoNoSoportado.
  ///
  /// In es, this message translates to:
  /// **'Formato no admitido. Usá PDF o una imagen.'**
  String get errFormatoNoSoportado;

  /// No description provided for @errSinEspacio.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio suficiente en el dispositivo.'**
  String get errSinEspacio;

  /// No description provided for @uiJustNow.
  ///
  /// In es, this message translates to:
  /// **'Recién'**
  String get uiJustNow;

  /// No description provided for @uiMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {n} min'**
  String uiMinutesAgo(int n);

  /// No description provided for @uiHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {n} h'**
  String uiHoursAgo(int n);

  /// No description provided for @uiYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get uiYesterday;

  /// No description provided for @uiToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get uiToday;

  /// No description provided for @uiTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get uiTomorrow;

  /// No description provided for @uiUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get uiUndo;

  /// No description provided for @uiMoreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get uiMoreOptions;

  /// No description provided for @uiSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get uiSeeAll;

  /// No description provided for @uiClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get uiClose;

  /// No description provided for @uiLogoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Querés cerrar la sesión?'**
  String get uiLogoutConfirm;

  /// No description provided for @notifTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifTitle;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get notifMarkAllRead;

  /// No description provided for @notifDeleteAll.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get notifDeleteAll;

  /// No description provided for @notifDeleteAllConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar todas las notificaciones?'**
  String get notifDeleteAllConfirm;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás al día'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Acá vas a ver las novedades de solicitudes, documentos y eventos.'**
  String get notifEmptyBody;

  /// No description provided for @notifFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get notifFilterAll;

  /// No description provided for @notifFilterUnread.
  ///
  /// In es, this message translates to:
  /// **'No leídas'**
  String get notifFilterUnread;

  /// No description provided for @notifDeleted.
  ///
  /// In es, this message translates to:
  /// **'Notificación eliminada'**
  String get notifDeleted;

  /// No description provided for @notifMarkRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leída'**
  String get notifMarkRead;

  /// No description provided for @notifMarkUnread.
  ///
  /// In es, this message translates to:
  /// **'Marcar como no leída'**
  String get notifMarkUnread;

  /// No description provided for @notifDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get notifDelete;

  /// No description provided for @notifUnreadCount.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 sin leer} other{{n} sin leer}}'**
  String notifUnreadCount(int n);

  /// No description provided for @homeHello.
  ///
  /// In es, this message translates to:
  /// **'Hola, {nombre}'**
  String homeHello(Object nombre);

  /// No description provided for @homeStudentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué querés hacer hoy?'**
  String get homeStudentSubtitle;

  /// No description provided for @homeSwitchStudent.
  ///
  /// In es, this message translates to:
  /// **'Cambiar alumno'**
  String get homeSwitchStudent;

  /// No description provided for @homeStatActiveRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes activas'**
  String get homeStatActiveRequests;

  /// No description provided for @homeStatUpcomingEvents.
  ///
  /// In es, this message translates to:
  /// **'Próximos eventos'**
  String get homeStatUpcomingEvents;

  /// No description provided for @homeStatPendingDocs.
  ///
  /// In es, this message translates to:
  /// **'Documentos por entregar'**
  String get homeStatPendingDocs;

  /// No description provided for @homeActionExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar instituciones'**
  String get homeActionExplore;

  /// No description provided for @homeActionExploreSub.
  ///
  /// In es, this message translates to:
  /// **'Buscá y pedí tu vacante'**
  String get homeActionExploreSub;

  /// No description provided for @homeActionRequests.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get homeActionRequests;

  /// No description provided for @homeActionRequestsSub.
  ///
  /// In es, this message translates to:
  /// **'Seguí el estado de cada trámite'**
  String get homeActionRequestsSub;

  /// No description provided for @homeActionCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get homeActionCalendar;

  /// No description provided for @homeActionCalendarSub.
  ///
  /// In es, this message translates to:
  /// **'Eventos y recordatorios'**
  String get homeActionCalendarSub;

  /// No description provided for @homeActionDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get homeActionDocuments;

  /// No description provided for @homeActionDocumentsSub.
  ///
  /// In es, this message translates to:
  /// **'Lo que te piden las instituciones'**
  String get homeActionDocumentsSub;

  /// No description provided for @homeActionNotificationsSub.
  ///
  /// In es, this message translates to:
  /// **'Novedades y avisos'**
  String get homeActionNotificationsSub;

  /// No description provided for @homeActionProfile.
  ///
  /// In es, this message translates to:
  /// **'Ficha del alumno'**
  String get homeActionProfile;

  /// No description provided for @homeActionProfileSub.
  ///
  /// In es, this message translates to:
  /// **'Datos personales y PDF'**
  String get homeActionProfileSub;

  /// No description provided for @homeRecentRequests.
  ///
  /// In es, this message translates to:
  /// **'Tus solicitudes'**
  String get homeRecentRequests;

  /// No description provided for @homeNoRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no pediste vacantes'**
  String get homeNoRequestsTitle;

  /// No description provided for @homeNoRequestsBody.
  ///
  /// In es, this message translates to:
  /// **'Explorá instituciones y enviá tu primera solicitud en pocos pasos.'**
  String get homeNoRequestsBody;

  /// No description provided for @homeNoEvents.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos próximos.'**
  String get homeNoEvents;

  /// No description provided for @hubTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Con qué alumno querés continuar?'**
  String get hubTitle;

  /// No description provided for @hubSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Podés gestionar a varios alumnos desde la misma cuenta.'**
  String get hubSubtitle;

  /// No description provided for @hubAddStudent.
  ///
  /// In es, this message translates to:
  /// **'Agregar alumno'**
  String get hubAddStudent;

  /// No description provided for @hubAddStudentSub.
  ///
  /// In es, this message translates to:
  /// **'Sumá a otro hijo o hija a tu cuenta'**
  String get hubAddStudentSub;

  /// No description provided for @hubEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregá el primer alumno'**
  String get hubEmptyTitle;

  /// No description provided for @hubEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cargá los datos del alumno para empezar a buscar instituciones.'**
  String get hubEmptyBody;

  /// No description provided for @hubLastUsed.
  ///
  /// In es, this message translates to:
  /// **'Último usado'**
  String get hubLastUsed;

  /// No description provided for @hubAccountLine.
  ///
  /// In es, this message translates to:
  /// **'Cuenta: {email}'**
  String hubAccountLine(Object email);

  /// No description provided for @studentFormTitleNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo alumno'**
  String get studentFormTitleNew;

  /// No description provided for @studentFormTitleEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar datos'**
  String get studentFormTitleEdit;

  /// No description provided for @studentFormSaved.
  ///
  /// In es, this message translates to:
  /// **'Datos guardados.'**
  String get studentFormSaved;

  /// No description provided for @studentFormCreated.
  ///
  /// In es, this message translates to:
  /// **'Alumno agregado.'**
  String get studentFormCreated;

  /// No description provided for @instHomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de la institución'**
  String get instHomeSubtitle;

  /// No description provided for @instPlanTrialUntil.
  ///
  /// In es, this message translates to:
  /// **'Prueba hasta el {fecha}'**
  String instPlanTrialUntil(Object fecha);

  /// No description provided for @instPlanTrialEnded.
  ///
  /// In es, this message translates to:
  /// **'Prueba vencida'**
  String get instPlanTrialEnded;

  /// No description provided for @instPlanActive.
  ///
  /// In es, this message translates to:
  /// **'Plan activo'**
  String get instPlanActive;

  /// No description provided for @instPlanSuspended.
  ///
  /// In es, this message translates to:
  /// **'Plan suspendido'**
  String get instPlanSuspended;

  /// No description provided for @instPlanNone.
  ///
  /// In es, this message translates to:
  /// **'Sin plan'**
  String get instPlanNone;

  /// No description provided for @instStatPending.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes pendientes'**
  String get instStatPending;

  /// No description provided for @instStatStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos confirmados'**
  String get instStatStudents;

  /// No description provided for @instStatFreeSpots.
  ///
  /// In es, this message translates to:
  /// **'Vacantes libres'**
  String get instStatFreeSpots;

  /// No description provided for @instStatOffers.
  ///
  /// In es, this message translates to:
  /// **'Ofertas activas'**
  String get instStatOffers;

  /// No description provided for @instActionRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get instActionRequests;

  /// No description provided for @instActionRequestsSub.
  ///
  /// In es, this message translates to:
  /// **'Revisá y respondé pedidos de vacante'**
  String get instActionRequestsSub;

  /// No description provided for @instActionOffers.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get instActionOffers;

  /// No description provided for @instActionOffersSub.
  ///
  /// In es, this message translates to:
  /// **'Cursos, grupos y cupos'**
  String get instActionOffersSub;

  /// No description provided for @instActionStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get instActionStudents;

  /// No description provided for @instActionStudentsSub.
  ///
  /// In es, this message translates to:
  /// **'Inscriptos por curso y grupo'**
  String get instActionStudentsSub;

  /// No description provided for @instActionComms.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones'**
  String get instActionComms;

  /// No description provided for @instActionCommsSub.
  ///
  /// In es, this message translates to:
  /// **'Calendario y avisos'**
  String get instActionCommsSub;

  /// No description provided for @instActionDocs.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get instActionDocs;

  /// No description provided for @instActionDocsSub.
  ///
  /// In es, this message translates to:
  /// **'Pedidos y revisión de documentos'**
  String get instActionDocsSub;

  /// No description provided for @instActionCroquis.
  ///
  /// In es, this message translates to:
  /// **'Croquis de aula'**
  String get instActionCroquis;

  /// No description provided for @instActionCroquisSub.
  ///
  /// In es, this message translates to:
  /// **'Distribución de bancos'**
  String get instActionCroquisSub;

  /// No description provided for @instActionProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil público'**
  String get instActionProfile;

  /// No description provided for @instActionProfileSub.
  ///
  /// In es, this message translates to:
  /// **'Cómo te ven las familias'**
  String get instActionProfileSub;

  /// No description provided for @instActionPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get instActionPlan;

  /// No description provided for @instActionPlanSub.
  ///
  /// In es, this message translates to:
  /// **'Niveles, módulos y costo'**
  String get instActionPlanSub;

  /// No description provided for @instGettingStarted.
  ///
  /// In es, this message translates to:
  /// **'Primeros pasos'**
  String get instGettingStarted;

  /// No description provided for @instGettingStartedSub.
  ///
  /// In es, this message translates to:
  /// **'Completá estos pasos para empezar a recibir alumnos.'**
  String get instGettingStartedSub;

  /// No description provided for @instStepProfile.
  ///
  /// In es, this message translates to:
  /// **'Completá tu perfil público'**
  String get instStepProfile;

  /// No description provided for @instStepOffer.
  ///
  /// In es, this message translates to:
  /// **'Publicá tu primera vacante'**
  String get instStepOffer;

  /// No description provided for @instStepRequest.
  ///
  /// In es, this message translates to:
  /// **'Recibí tu primera solicitud'**
  String get instStepRequest;

  /// No description provided for @instToReview.
  ///
  /// In es, this message translates to:
  /// **'Para revisar'**
  String get instToReview;

  /// No description provided for @instNoPending.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes. ¡Todo al día!'**
  String get instNoPending;

  /// No description provided for @instLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los datos de la institución.'**
  String get instLoadError;

  /// No description provided for @instSignInAgain.
  ///
  /// In es, this message translates to:
  /// **'Volver a ingresar'**
  String get instSignInAgain;

  /// No description provided for @notifOlder.
  ///
  /// In es, this message translates to:
  /// **'Anteriores'**
  String get notifOlder;

  /// No description provided for @prefsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de ATENA'**
  String get prefsAbout;

  /// No description provided for @prefsVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String prefsVersion(Object version);

  /// No description provided for @prefsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y datos'**
  String get prefsPrivacyTitle;

  /// No description provided for @prefsPrivacyBody.
  ///
  /// In es, this message translates to:
  /// **'En esta versión, ATENA guarda toda la información (cuentas, alumnos, solicitudes, documentos y fotos) únicamente en este dispositivo. No se envía a servidores ni a terceros. Las contraseñas se guardan protegidas con un hash seguro. Podés eliminar tu cuenta cuando quieras desde el menú «Más opciones» de tu inicio.'**
  String get prefsPrivacyBody;

  /// No description provided for @prefsDeleteData.
  ///
  /// In es, this message translates to:
  /// **'Borrar todos los datos de este dispositivo'**
  String get prefsDeleteData;

  /// No description provided for @prefsDeleteDataConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todos los datos?'**
  String get prefsDeleteDataConfirmTitle;

  /// No description provided for @prefsDeleteDataConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán todas las cuentas, alumnos, instituciones, solicitudes y documentos guardados en este dispositivo. Esta acción no se puede deshacer.'**
  String get prefsDeleteDataConfirm;

  /// No description provided for @prefsDeleteDataCta.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get prefsDeleteDataCta;

  /// No description provided for @prefsDeleteDataDone.
  ///
  /// In es, this message translates to:
  /// **'Se borraron todos los datos.'**
  String get prefsDeleteDataDone;

  /// No description provided for @demoLink.
  ///
  /// In es, this message translates to:
  /// **'Probar con datos de ejemplo'**
  String get demoLink;

  /// No description provided for @demoConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cargar datos de ejemplo?'**
  String get demoConfirmTitle;

  /// No description provided for @demoConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Vamos a crear en este dispositivo tres instituciones y una familia de ejemplo para que recorras ATENA. Podés borrarlos cuando quieras desde Preferencias.'**
  String get demoConfirmBody;

  /// No description provided for @demoConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Cargar ejemplo'**
  String get demoConfirmCta;

  /// No description provided for @demoLoading.
  ///
  /// In es, this message translates to:
  /// **'Preparando los datos de ejemplo…'**
  String get demoLoading;

  /// No description provided for @demoReadyTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Ya podés recorrer ATENA'**
  String get demoReadyTitle;

  /// No description provided for @demoReadyBody.
  ///
  /// In es, this message translates to:
  /// **'Usá estas cuentas de ejemplo. La contraseña de todas es {password}.'**
  String demoReadyBody(Object password);

  /// No description provided for @demoFamilyLabel.
  ///
  /// In es, this message translates to:
  /// **'Familia con dos alumnos'**
  String get demoFamilyLabel;

  /// No description provided for @demoInstitutionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get demoInstitutionsLabel;

  /// No description provided for @demoEnterFamily.
  ///
  /// In es, this message translates to:
  /// **'Entrar como familia'**
  String get demoEnterFamily;

  /// No description provided for @demoEnterInstitution.
  ///
  /// In es, this message translates to:
  /// **'Entrar como el colegio'**
  String get demoEnterInstitution;

  /// No description provided for @demoAlreadyLoaded.
  ///
  /// In es, this message translates to:
  /// **'Los datos de ejemplo ya estaban cargados.'**
  String get demoAlreadyLoaded;

  /// No description provided for @calAlTitulo.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calAlTitulo;

  /// No description provided for @calAlNuevaNota.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get calAlNuevaNota;

  /// No description provided for @calAlEditarNota.
  ///
  /// In es, this message translates to:
  /// **'Editar nota'**
  String get calAlEditarNota;

  /// No description provided for @calAlEliminarNota.
  ///
  /// In es, this message translates to:
  /// **'Eliminar nota'**
  String get calAlEliminarNota;

  /// No description provided for @calAlEliminarNotaConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la nota?'**
  String get calAlEliminarNotaConfirm;

  /// No description provided for @calAlEliminarNotaMensaje.
  ///
  /// In es, this message translates to:
  /// **'«{titulo}» se va a quitar de tu calendario.'**
  String calAlEliminarNotaMensaje(String titulo);

  /// No description provided for @calAlNotaGuardada.
  ///
  /// In es, this message translates to:
  /// **'Nota guardada.'**
  String get calAlNotaGuardada;

  /// No description provided for @calAlNotaEliminada.
  ///
  /// In es, this message translates to:
  /// **'Nota eliminada.'**
  String get calAlNotaEliminada;

  /// No description provided for @calAlNotaTituloHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Llevar la autorización firmada'**
  String get calAlNotaTituloHint;

  /// No description provided for @calAlNotaHora.
  ///
  /// In es, this message translates to:
  /// **'Hora (opcional)'**
  String get calAlNotaHora;

  /// No description provided for @calAlNotaQuitarHora.
  ///
  /// In es, this message translates to:
  /// **'Quitar hora'**
  String get calAlNotaQuitarHora;

  /// No description provided for @calAlNotaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Detalle (opcional)'**
  String get calAlNotaDetalle;

  /// No description provided for @calAlNotaPersonal.
  ///
  /// In es, this message translates to:
  /// **'Nota personal'**
  String get calAlNotaPersonal;

  /// No description provided for @calAlNotaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Tus notas son privadas: solo las ves vos.'**
  String get calAlNotaAyuda;

  /// No description provided for @calAlTodoElDia.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get calAlTodoElDia;

  /// No description provided for @calAlRango.
  ///
  /// In es, this message translates to:
  /// **'Del {desde} al {hasta}'**
  String calAlRango(String desde, String hasta);

  /// No description provided for @calAlCuando.
  ///
  /// In es, this message translates to:
  /// **'Cuándo'**
  String get calAlCuando;

  /// No description provided for @calAlLugar.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get calAlLugar;

  /// No description provided for @calAlAsistenciaTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Vas a asistir?'**
  String get calAlAsistenciaTitulo;

  /// No description provided for @calAlAsistenciaAyuda.
  ///
  /// In es, this message translates to:
  /// **'La institución te pide que confirmes tu asistencia.'**
  String get calAlAsistenciaAyuda;

  /// No description provided for @calAlAsistenciaPasado.
  ///
  /// In es, this message translates to:
  /// **'Este evento ya pasó.'**
  String get calAlAsistenciaPasado;

  /// No description provided for @calAlAsistenciaGuardada.
  ///
  /// In es, this message translates to:
  /// **'Respuesta enviada: {respuesta}.'**
  String calAlAsistenciaGuardada(String respuesta);

  /// No description provided for @calAlResponder.
  ///
  /// In es, this message translates to:
  /// **'Confirmá tu asistencia'**
  String get calAlResponder;

  /// No description provided for @calAlNadaEsteDia.
  ///
  /// In es, this message translates to:
  /// **'No tenés nada agendado para este día.'**
  String get calAlNadaEsteDia;

  /// No description provided for @calAlAgregarNota.
  ///
  /// In es, this message translates to:
  /// **'Agregar una nota'**
  String get calAlAgregarNota;

  /// No description provided for @calAlProximos.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get calAlProximos;

  /// No description provided for @calAlVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu calendario está listo'**
  String get calAlVacioTitulo;

  /// No description provided for @calAlVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Acá vas a ver los eventos que publiquen las instituciones donde tengas la vacante confirmada: reuniones, actos, salidas y más. También podés agregar tus propias notas y recordatorios.'**
  String get calAlVacioMensaje;

  /// No description provided for @calAlSinEventos.
  ///
  /// In es, this message translates to:
  /// **'Los eventos de tus instituciones van a aparecer acá cuando tengas una vacante confirmada.'**
  String get calAlSinEventos;

  /// No description provided for @calAlDiaItems.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Nada agendado} =1{1 actividad} other{{n} actividades}}'**
  String calAlDiaItems(int n);

  /// No description provided for @calAlEventoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este evento ya no está disponible.'**
  String get calAlEventoNoDisponible;

  /// No description provided for @docAlTitulo.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get docAlTitulo;

  /// No description provided for @docAlHeroPendientes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Tenés 1 documento para entregar} other{Tenés {n} documentos para entregar}}'**
  String docAlHeroPendientes(int n);

  /// No description provided for @docAlHeroPendientesSub.
  ///
  /// In es, this message translates to:
  /// **'Subilos desde acá: podés sacar una foto o elegir un archivo.'**
  String get docAlHeroPendientesSub;

  /// No description provided for @docAlHeroAlDia.
  ///
  /// In es, this message translates to:
  /// **'¡Todo al día!'**
  String get docAlHeroAlDia;

  /// No description provided for @docAlHeroAlDiaSub.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos si una institución te pide algo nuevo.'**
  String get docAlHeroAlDiaSub;

  /// No description provided for @docAlSeccionEntregar.
  ///
  /// In es, this message translates to:
  /// **'Para entregar'**
  String get docAlSeccionEntregar;

  /// No description provided for @docAlSeccionEntregarSub.
  ///
  /// In es, this message translates to:
  /// **'Subilos para completar la inscripción.'**
  String get docAlSeccionEntregarSub;

  /// No description provided for @docAlSeccionRevision.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get docAlSeccionRevision;

  /// No description provided for @docAlSeccionRevisionSub.
  ///
  /// In es, this message translates to:
  /// **'La institución los está revisando. Te avisamos cuando responda.'**
  String get docAlSeccionRevisionSub;

  /// No description provided for @docAlSeccionAprobados.
  ///
  /// In es, this message translates to:
  /// **'Aprobados'**
  String get docAlSeccionAprobados;

  /// No description provided for @docAlSeccionHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get docAlSeccionHistorial;

  /// No description provided for @docAlSeccionHistorialSub.
  ///
  /// In es, this message translates to:
  /// **'Pedidos que la institución canceló'**
  String get docAlSeccionHistorialSub;

  /// No description provided for @docAlNadaParaEntregar.
  ///
  /// In es, this message translates to:
  /// **'No tenés documentos para entregar.'**
  String get docAlNadaParaEntregar;

  /// No description provided for @docAlVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'No tenés documentos pendientes'**
  String get docAlVacioTitulo;

  /// No description provided for @docAlVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Cuando una institución te pida un documento, como el DNI o un certificado médico, lo vas a ver acá y vas a poder subirlo en un par de pasos.'**
  String get docAlVacioMensaje;

  /// No description provided for @docAlSubirArchivo.
  ///
  /// In es, this message translates to:
  /// **'Subir archivo'**
  String get docAlSubirArchivo;

  /// No description provided for @docAlReemplazarArchivo.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar archivo'**
  String get docAlReemplazarArchivo;

  /// No description provided for @docAlVerArchivo.
  ///
  /// In es, this message translates to:
  /// **'Ver archivo'**
  String get docAlVerArchivo;

  /// No description provided for @docAlSubiendo.
  ///
  /// In es, this message translates to:
  /// **'Subiendo…'**
  String get docAlSubiendo;

  /// No description provided for @docAlEntregado.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Enviamos el documento a la institución.'**
  String get docAlEntregado;

  /// No description provided for @docAlMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get docAlMotivo;

  /// No description provided for @docAlRechazadoSinMotivo.
  ///
  /// In es, this message translates to:
  /// **'La institución pidió que vuelvas a subirlo.'**
  String get docAlRechazadoSinMotivo;

  /// No description provided for @docAlEntregarHasta.
  ///
  /// In es, this message translates to:
  /// **'Entregar hasta el {fecha}'**
  String docAlEntregarHasta(String fecha);

  /// No description provided for @docAlVencio.
  ///
  /// In es, this message translates to:
  /// **'Venció el {fecha}'**
  String docAlVencio(String fecha);

  /// No description provided for @docAlVenceHoy.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy'**
  String get docAlVenceHoy;

  /// No description provided for @docAlVenceManiana.
  ///
  /// In es, this message translates to:
  /// **'Vence mañana'**
  String get docAlVenceManiana;

  /// No description provided for @docAlPedidoEl.
  ///
  /// In es, this message translates to:
  /// **'Pedido el {fecha}'**
  String docAlPedidoEl(String fecha);

  /// No description provided for @docAlEntregadoEl.
  ///
  /// In es, this message translates to:
  /// **'Entregado el {fecha}'**
  String docAlEntregadoEl(String fecha);

  /// No description provided for @docAlAprobadoEl.
  ///
  /// In es, this message translates to:
  /// **'Aprobado el {fecha}'**
  String docAlAprobadoEl(String fecha);

  /// No description provided for @docAlCanceladoEl.
  ///
  /// In es, this message translates to:
  /// **'Cancelado el {fecha}'**
  String docAlCanceladoEl(String fecha);

  /// No description provided for @docAlIndicaciones.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones'**
  String get docAlIndicaciones;

  /// No description provided for @docAlFechaPedido.
  ///
  /// In es, this message translates to:
  /// **'Fecha del pedido'**
  String get docAlFechaPedido;

  /// No description provided for @docAlFechaLimite.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite'**
  String get docAlFechaLimite;

  /// No description provided for @docAlArchivoEntregado.
  ///
  /// In es, this message translates to:
  /// **'Archivo entregado'**
  String get docAlArchivoEntregado;

  /// No description provided for @docAlAyudaPendiente.
  ///
  /// In es, this message translates to:
  /// **'Subí el archivo para que la institución pueda revisarlo.'**
  String get docAlAyudaPendiente;

  /// No description provided for @docAlAyudaVencido.
  ///
  /// In es, this message translates to:
  /// **'La fecha límite ya pasó. Subilo lo antes posible.'**
  String get docAlAyudaVencido;

  /// No description provided for @docAlAyudaRevision.
  ///
  /// In es, this message translates to:
  /// **'La institución lo está revisando. Si te equivocaste de archivo, podés reemplazarlo.'**
  String get docAlAyudaRevision;

  /// No description provided for @docAlAyudaAprobado.
  ///
  /// In es, this message translates to:
  /// **'La institución aprobó este documento. No tenés que hacer nada más.'**
  String get docAlAyudaAprobado;

  /// No description provided for @docAlAyudaCancelado.
  ///
  /// In es, this message translates to:
  /// **'La institución canceló este pedido. Ya no hace falta entregarlo.'**
  String get docAlAyudaCancelado;

  /// No description provided for @docAlFuenteTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo querés subirlo?'**
  String get docAlFuenteTitulo;

  /// No description provided for @docAlFuenteArchivo.
  ///
  /// In es, this message translates to:
  /// **'Elegir un archivo'**
  String get docAlFuenteArchivo;

  /// No description provided for @docAlFuenteArchivoSub.
  ///
  /// In es, this message translates to:
  /// **'PDF o imagen (JPG, PNG, WEBP o HEIC) de hasta 3 MB'**
  String get docAlFuenteArchivoSub;

  /// No description provided for @docAlFuenteCamara.
  ///
  /// In es, this message translates to:
  /// **'Sacar una foto'**
  String get docAlFuenteCamara;

  /// No description provided for @docAlFuenteCamaraSub.
  ///
  /// In es, this message translates to:
  /// **'Fotografiá el documento con la cámara'**
  String get docAlFuenteCamaraSub;

  /// No description provided for @docAlFuenteGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir una foto'**
  String get docAlFuenteGaleria;

  /// No description provided for @docAlFuenteGaleriaSub.
  ///
  /// In es, this message translates to:
  /// **'De las imágenes guardadas en tu dispositivo'**
  String get docAlFuenteGaleriaSub;

  /// No description provided for @docAlFuenteTip.
  ///
  /// In es, this message translates to:
  /// **'Consejo: sacá la foto con buena luz y asegurate de que se lea todo el documento.'**
  String get docAlFuenteTip;

  /// No description provided for @docAlErrorSeleccion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el archivo ni la cámara. Revisá los permisos e intentá de nuevo.'**
  String get docAlErrorSeleccion;

  /// No description provided for @docAlErrorArchivo.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el archivo entregado.'**
  String get docAlErrorArchivo;

  /// No description provided for @docAlErrorPdf.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el PDF. Probá de nuevo en unos minutos.'**
  String get docAlErrorPdf;

  /// No description provided for @docAlSinVistaPrevia.
  ///
  /// In es, this message translates to:
  /// **'No se puede mostrar la vista previa de esta imagen.'**
  String get docAlSinVistaPrevia;

  /// No description provided for @docAlNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este pedido ya no está disponible.'**
  String get docAlNoDisponible;

  /// No description provided for @fichaAlTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ficha del alumno'**
  String get fichaAlTitulo;

  /// No description provided for @fichaAlDni.
  ///
  /// In es, this message translates to:
  /// **'DNI {dni}'**
  String fichaAlDni(String dni);

  /// No description provided for @fichaAlAgregarFoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get fichaAlAgregarFoto;

  /// No description provided for @fichaAlCambiarFoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get fichaAlCambiarFoto;

  /// No description provided for @fichaAlFotoCamara.
  ///
  /// In es, this message translates to:
  /// **'Sacar una foto'**
  String get fichaAlFotoCamara;

  /// No description provided for @fichaAlFotoGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get fichaAlFotoGaleria;

  /// No description provided for @fichaAlFotoArchivo.
  ///
  /// In es, this message translates to:
  /// **'Elegir una imagen'**
  String get fichaAlFotoArchivo;

  /// No description provided for @fichaAlQuitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get fichaAlQuitarFoto;

  /// No description provided for @fichaAlQuitarFotoConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar la foto?'**
  String get fichaAlQuitarFotoConfirm;

  /// No description provided for @fichaAlQuitarFotoMensaje.
  ///
  /// In es, this message translates to:
  /// **'En su lugar se van a mostrar las iniciales del alumno.'**
  String get fichaAlQuitarFotoMensaje;

  /// No description provided for @fichaAlFotoGuardada.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada.'**
  String get fichaAlFotoGuardada;

  /// No description provided for @fichaAlFotoEliminada.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada.'**
  String get fichaAlFotoEliminada;

  /// No description provided for @fichaAlFotoError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir la cámara ni la galería. Revisá los permisos e intentá de nuevo.'**
  String get fichaAlFotoError;

  /// No description provided for @fichaAlDatosPersonales.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get fichaAlDatosPersonales;

  /// No description provided for @fichaAlEditarDatos.
  ///
  /// In es, this message translates to:
  /// **'Editar datos'**
  String get fichaAlEditarDatos;

  /// No description provided for @fichaAlInstituciones.
  ///
  /// In es, this message translates to:
  /// **'Instituciones'**
  String get fichaAlInstituciones;

  /// No description provided for @fichaAlInstitucionesSub.
  ///
  /// In es, this message translates to:
  /// **'Donde tiene la vacante confirmada'**
  String get fichaAlInstitucionesSub;

  /// No description provided for @fichaAlSinInstituciones.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay vacantes confirmadas. Cuando una institución confirme una solicitud, la vas a ver acá.'**
  String get fichaAlSinInstituciones;

  /// No description provided for @fichaAlConfirmadaEl.
  ///
  /// In es, this message translates to:
  /// **'Confirmada el {fecha}'**
  String fichaAlConfirmadaEl(String fecha);

  /// No description provided for @fichaAlPdf.
  ///
  /// In es, this message translates to:
  /// **'Ficha en PDF'**
  String get fichaAlPdf;

  /// No description provided for @fichaAlPdfSub.
  ///
  /// In es, this message translates to:
  /// **'Para presentar en una institución o guardar una copia'**
  String get fichaAlPdfSub;

  /// No description provided for @fichaAlDescargarPdf.
  ///
  /// In es, this message translates to:
  /// **'Descargar ficha en PDF'**
  String get fichaAlDescargarPdf;

  /// No description provided for @fichaAlDescargarPdfSub.
  ///
  /// In es, this message translates to:
  /// **'Con los datos personales, la foto y las instituciones'**
  String get fichaAlDescargarPdfSub;

  /// No description provided for @fichaAlImprimir.
  ///
  /// In es, this message translates to:
  /// **'Imprimir'**
  String get fichaAlImprimir;

  /// No description provided for @fichaAlImprimirSub.
  ///
  /// In es, this message translates to:
  /// **'Abrí la vista previa para imprimir la ficha'**
  String get fichaAlImprimirSub;

  /// No description provided for @fichaAlGenerando.
  ///
  /// In es, this message translates to:
  /// **'Generando PDF…'**
  String get fichaAlGenerando;

  /// No description provided for @fichaAlPdfError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos generar el PDF. Probá de nuevo en unos minutos.'**
  String get fichaAlPdfError;

  /// No description provided for @ofertasNueva.
  ///
  /// In es, this message translates to:
  /// **'Nueva vacante'**
  String get ofertasNueva;

  /// No description provided for @ofertasErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las vacantes.'**
  String get ofertasErrorCarga;

  /// No description provided for @ofertasSinPlanTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu plan todavía no incluye niveles ni actividades'**
  String get ofertasSinPlanTitulo;

  /// No description provided for @ofertasSinPlanMensaje.
  ///
  /// In es, this message translates to:
  /// **'Para publicar vacantes, habilitá niveles curriculares o actividades extracurriculares en Plan, desde el panel de la institución.'**
  String get ofertasSinPlanMensaje;

  /// No description provided for @ofertasVolverPanel.
  ///
  /// In es, this message translates to:
  /// **'Volver al panel'**
  String get ofertasVolverPanel;

  /// No description provided for @ofertasTipoFueraDelPlan.
  ///
  /// In es, this message translates to:
  /// **'Tu plan actual no incluye este tipo de vacantes. Podés editar, pausar o eliminar las que ya publicaste.'**
  String get ofertasTipoFueraDelPlan;

  /// No description provided for @ofertasFueraDelPlan.
  ///
  /// In es, this message translates to:
  /// **'Fuera de tu plan'**
  String get ofertasFueraDelPlan;

  /// No description provided for @ofertasVacioCurricularTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no publicaste vacantes curriculares'**
  String get ofertasVacioCurricularTitulo;

  /// No description provided for @ofertasVacioCurricularMensaje.
  ///
  /// In es, this message translates to:
  /// **'Creá los grados, años o salas con su cupo para que las familias puedan pedir vacante.'**
  String get ofertasVacioCurricularMensaje;

  /// No description provided for @ofertasVacioExtraTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no publicaste actividades extracurriculares'**
  String get ofertasVacioExtraTitulo;

  /// No description provided for @ofertasVacioExtraMensaje.
  ///
  /// In es, this message translates to:
  /// **'Sumá talleres, deportes o idiomas con su cupo y horario para que las familias puedan inscribirse.'**
  String get ofertasVacioExtraMensaje;

  /// No description provided for @ofertasNOfertas.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 oferta} other{{n} ofertas}}'**
  String ofertasNOfertas(int n);

  /// No description provided for @ofertasNLibres.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin vacantes libres} =1{1 vacante libre} other{{n} vacantes libres}}'**
  String ofertasNLibres(int n);

  /// No description provided for @ofertasAgregarEn.
  ///
  /// In es, this message translates to:
  /// **'Agregar vacante en {categoria}'**
  String ofertasAgregarEn(Object categoria);

  /// No description provided for @ofertasActiva.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get ofertasActiva;

  /// No description provided for @ofertasPausada.
  ///
  /// In es, this message translates to:
  /// **'Pausada'**
  String get ofertasPausada;

  /// No description provided for @ofertasCompleta.
  ///
  /// In es, this message translates to:
  /// **'Completa'**
  String get ofertasCompleta;

  /// No description provided for @ofertasConfirmados.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin confirmados} =1{1 confirmado} other{{n} confirmados}}'**
  String ofertasConfirmados(int n);

  /// No description provided for @ofertasPendientes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 pendiente} other{{n} pendientes}}'**
  String ofertasPendientes(int n);

  /// No description provided for @ofertasOcupacion.
  ///
  /// In es, this message translates to:
  /// **'{confirmados} de {total} lugares ocupados'**
  String ofertasOcupacion(int confirmados, int total);

  /// No description provided for @ofertasPausar.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get ofertasPausar;

  /// No description provided for @ofertasReanudar.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get ofertasReanudar;

  /// No description provided for @ofertasDuplicar.
  ///
  /// In es, this message translates to:
  /// **'Duplicar'**
  String get ofertasDuplicar;

  /// No description provided for @ofertasVerSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Ver solicitudes'**
  String get ofertasVerSolicitudes;

  /// No description provided for @ofertasPausadaOk.
  ///
  /// In es, this message translates to:
  /// **'Vacante pausada: no recibe nuevas solicitudes.'**
  String get ofertasPausadaOk;

  /// No description provided for @ofertasReanudadaOk.
  ///
  /// In es, this message translates to:
  /// **'Vacante reanudada: ya recibe solicitudes.'**
  String get ofertasReanudadaOk;

  /// No description provided for @ofertasEliminarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar «{nombre}»?'**
  String ofertasEliminarTitulo(Object nombre);

  /// No description provided for @ofertasEliminarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Las familias ya no la van a ver. Esta acción no se puede deshacer.'**
  String get ofertasEliminarMensaje;

  /// No description provided for @ofertasEliminadaOk.
  ///
  /// In es, this message translates to:
  /// **'Vacante eliminada.'**
  String get ofertasEliminadaOk;

  /// No description provided for @ofertasFormEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar vacante'**
  String get ofertasFormEditar;

  /// No description provided for @ofertasFormDuplicar.
  ///
  /// In es, this message translates to:
  /// **'Duplicar vacante'**
  String get ofertasFormDuplicar;

  /// No description provided for @ofertasFormCopiaAviso.
  ///
  /// In es, this message translates to:
  /// **'Estás creando una copia de «{nombre}». Cambiá lo que necesites (por ejemplo, el grupo) y guardala.'**
  String ofertasFormCopiaAviso(Object nombre);

  /// No description provided for @ofertasFormConfirmadosAviso.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Esta vacante tiene 1 alumno confirmado. Las solicitudes ya enviadas conservan los datos originales.} other{Esta vacante tiene {n} alumnos confirmados. Las solicitudes ya enviadas conservan los datos originales.}}'**
  String ofertasFormConfirmadosAviso(int n);

  /// No description provided for @ofertasSeccionTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vacante'**
  String get ofertasSeccionTipo;

  /// No description provided for @ofertasTipoCurricularDesc.
  ///
  /// In es, this message translates to:
  /// **'Grados, años y salas'**
  String get ofertasTipoCurricularDesc;

  /// No description provided for @ofertasTipoExtraDesc.
  ///
  /// In es, this message translates to:
  /// **'Talleres, deportes y actividades'**
  String get ofertasTipoExtraDesc;

  /// No description provided for @ofertasSeccionNivel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get ofertasSeccionNivel;

  /// No description provided for @ofertasSeccionCategoria.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get ofertasSeccionCategoria;

  /// No description provided for @ofertasElegiNivel.
  ///
  /// In es, this message translates to:
  /// **'Elegí un nivel.'**
  String get ofertasElegiNivel;

  /// No description provided for @ofertasElegiCategoria.
  ///
  /// In es, this message translates to:
  /// **'Elegí una categoría.'**
  String get ofertasElegiCategoria;

  /// No description provided for @ofertasSeccionDatos.
  ///
  /// In es, this message translates to:
  /// **'Datos de la vacante'**
  String get ofertasSeccionDatos;

  /// No description provided for @ofertasTituloCurricularLabel.
  ///
  /// In es, this message translates to:
  /// **'Grado, año o sala'**
  String get ofertasTituloCurricularLabel;

  /// No description provided for @ofertasTituloExtraLabel.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get ofertasTituloExtraLabel;

  /// No description provided for @ofertasSugerenciasAyuda.
  ///
  /// In es, this message translates to:
  /// **'Tocá una sugerencia o escribilo a tu manera.'**
  String get ofertasSugerenciasAyuda;

  /// No description provided for @ofertasSugSala.
  ///
  /// In es, this message translates to:
  /// **'Sala de {n}'**
  String ofertasSugSala(int n);

  /// No description provided for @ofertasSugGrado.
  ///
  /// In es, this message translates to:
  /// **'{n}° grado'**
  String ofertasSugGrado(int n);

  /// No description provided for @ofertasSugAnio.
  ///
  /// In es, this message translates to:
  /// **'{n}° año'**
  String ofertasSugAnio(int n);

  /// No description provided for @ofertasEjemplosGeneral.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Fútbol, Inglés, Robótica'**
  String get ofertasEjemplosGeneral;

  /// No description provided for @ofertasEjemplosDeporte.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Fútbol, Vóley, Natación'**
  String get ofertasEjemplosDeporte;

  /// No description provided for @ofertasEjemplosArte.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Teatro, Coro, Pintura'**
  String get ofertasEjemplosArte;

  /// No description provided for @ofertasEjemplosIdiomas.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Inglés inicial, Portugués, Oratoria'**
  String get ofertasEjemplosIdiomas;

  /// No description provided for @ofertasEjemplosCiencia.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Robótica, Programación, Club de ciencias'**
  String get ofertasEjemplosCiencia;

  /// No description provided for @ofertasEjemplosApoyo.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Apoyo escolar, Técnicas de estudio'**
  String get ofertasEjemplosApoyo;

  /// No description provided for @ofertasEjemplosBienestar.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Yoga, Taller de emociones, Orientación vocacional'**
  String get ofertasEjemplosBienestar;

  /// No description provided for @ofertasEjemplosOtros.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Ajedrez, Cocina, Huerta'**
  String get ofertasEjemplosOtros;

  /// No description provided for @ofertasGrupoLabel.
  ///
  /// In es, this message translates to:
  /// **'División o grupo (opcional)'**
  String get ofertasGrupoLabel;

  /// No description provided for @ofertasGrupoHelper.
  ///
  /// In es, this message translates to:
  /// **'Ej.: A, B, Grupo sábados'**
  String get ofertasGrupoHelper;

  /// No description provided for @ofertasSeccionHorario.
  ///
  /// In es, this message translates to:
  /// **'Turno y horario'**
  String get ofertasSeccionHorario;

  /// No description provided for @ofertasTurnoLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get ofertasTurnoLabel;

  /// No description provided for @ofertasHoraDesde.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get ofertasHoraDesde;

  /// No description provided for @ofertasHoraHasta.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get ofertasHoraHasta;

  /// No description provided for @ofertasHorarioRango.
  ///
  /// In es, this message translates to:
  /// **'{desde} a {hasta}'**
  String ofertasHorarioRango(Object desde, Object hasta);

  /// No description provided for @ofertasHorarioInvalido.
  ///
  /// In es, this message translates to:
  /// **'La hora de fin tiene que ser posterior a la de inicio.'**
  String get ofertasHorarioInvalido;

  /// No description provided for @ofertasHorarioIncompleto.
  ///
  /// In es, this message translates to:
  /// **'Completá las dos horas o dejá ambas vacías.'**
  String get ofertasHorarioIncompleto;

  /// No description provided for @ofertasHorarioActual.
  ///
  /// In es, this message translates to:
  /// **'Horario actual: {horario}. Elegí las horas para reemplazarlo.'**
  String ofertasHorarioActual(Object horario);

  /// No description provided for @ofertasQuitarHorario.
  ///
  /// In es, this message translates to:
  /// **'Quitar horario'**
  String get ofertasQuitarHorario;

  /// No description provided for @ofertasDiasLabel.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get ofertasDiasLabel;

  /// No description provided for @ofertasDiaLun.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get ofertasDiaLun;

  /// No description provided for @ofertasDiaMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get ofertasDiaMar;

  /// No description provided for @ofertasDiaMie.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get ofertasDiaMie;

  /// No description provided for @ofertasDiaJue.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get ofertasDiaJue;

  /// No description provided for @ofertasDiaVie.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get ofertasDiaVie;

  /// No description provided for @ofertasDiaSab.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get ofertasDiaSab;

  /// No description provided for @ofertasDiaDom.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get ofertasDiaDom;

  /// No description provided for @ofertasDiasRango.
  ///
  /// In es, this message translates to:
  /// **'{desde} a {hasta}'**
  String ofertasDiasRango(Object desde, Object hasta);

  /// No description provided for @ofertasDiasLista.
  ///
  /// In es, this message translates to:
  /// **'{lista} y {ultimo}'**
  String ofertasDiasLista(Object lista, Object ultimo);

  /// No description provided for @ofertasDiasTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos los días'**
  String get ofertasDiasTodos;

  /// No description provided for @ofertasDiasActual.
  ///
  /// In es, this message translates to:
  /// **'Días actuales: {dias}. Elegilos para reemplazarlos.'**
  String ofertasDiasActual(Object dias);

  /// No description provided for @ofertasSeccionCupo.
  ///
  /// In es, this message translates to:
  /// **'Cupo y requisitos'**
  String get ofertasSeccionCupo;

  /// No description provided for @ofertasCupoLabel.
  ///
  /// In es, this message translates to:
  /// **'Cupo total'**
  String get ofertasCupoLabel;

  /// No description provided for @ofertasCupoHelper.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de alumnos que pueden inscribirse.'**
  String get ofertasCupoHelper;

  /// No description provided for @ofertasCupoConfirmadosHelper.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Hay 1 alumno confirmado.} other{Hay {n} alumnos confirmados.}}'**
  String ofertasCupoConfirmadosHelper(int n);

  /// No description provided for @ofertasCupoMinimo.
  ///
  /// In es, this message translates to:
  /// **'El cupo tiene que ser de al menos 1.'**
  String get ofertasCupoMinimo;

  /// No description provided for @ofertasCupoMenorConfirmados.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Ya hay 1 alumno confirmado: el cupo no puede ser menor.} other{Ya hay {n} alumnos confirmados: el cupo no puede ser menor.}}'**
  String ofertasCupoMenorConfirmados(int n);

  /// No description provided for @ofertasRestarUno.
  ///
  /// In es, this message translates to:
  /// **'Restar uno'**
  String get ofertasRestarUno;

  /// No description provided for @ofertasSumarUno.
  ///
  /// In es, this message translates to:
  /// **'Sumar uno'**
  String get ofertasSumarUno;

  /// No description provided for @ofertasEdadMinLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad mínima'**
  String get ofertasEdadMinLabel;

  /// No description provided for @ofertasEdadMaxLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad máxima'**
  String get ofertasEdadMaxLabel;

  /// No description provided for @ofertasAniosSufijo.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get ofertasAniosSufijo;

  /// No description provided for @ofertasEdadHelper.
  ///
  /// In es, this message translates to:
  /// **'Opcional: dejalas vacías si no hay límite de edad.'**
  String get ofertasEdadHelper;

  /// No description provided for @ofertasEdadRangoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Tiene que ser igual o mayor que la edad mínima.'**
  String get ofertasEdadRangoInvalido;

  /// No description provided for @ofertasArancelLabel.
  ///
  /// In es, this message translates to:
  /// **'Arancel (opcional)'**
  String get ofertasArancelLabel;

  /// No description provided for @ofertasArancelHelper.
  ///
  /// In es, this message translates to:
  /// **'Ej.: \$ 15.000 por mes. Dejalo vacío si es gratuita.'**
  String get ofertasArancelHelper;

  /// No description provided for @ofertasDescripcionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get ofertasDescripcionLabel;

  /// No description provided for @ofertasDescripcionHelper.
  ///
  /// In es, this message translates to:
  /// **'Contales a las familias qué incluye, requisitos o materiales.'**
  String get ofertasDescripcionHelper;

  /// No description provided for @ofertasSeccionPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Publicación'**
  String get ofertasSeccionPublicacion;

  /// No description provided for @ofertasActivaLabel.
  ///
  /// In es, this message translates to:
  /// **'Recibe solicitudes'**
  String get ofertasActivaLabel;

  /// No description provided for @ofertasActivaOn.
  ///
  /// In es, this message translates to:
  /// **'Activa: las familias pueden pedir vacante.'**
  String get ofertasActivaOn;

  /// No description provided for @ofertasActivaOff.
  ///
  /// In es, this message translates to:
  /// **'Pausada: las familias no pueden pedir vacante por ahora.'**
  String get ofertasActivaOff;

  /// No description provided for @ofertasCrear.
  ///
  /// In es, this message translates to:
  /// **'Crear vacante'**
  String get ofertasCrear;

  /// No description provided for @ofertasCreadaOk.
  ///
  /// In es, this message translates to:
  /// **'Vacante creada.'**
  String get ofertasCreadaOk;

  /// No description provided for @ofertasGuardadaOk.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados.'**
  String get ofertasGuardadaOk;

  /// No description provided for @ofertasDescartarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar los cambios?'**
  String get ofertasDescartarTitulo;

  /// No description provided for @ofertasDescartarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Los cambios que hiciste no se van a guardar.'**
  String get ofertasDescartarMensaje;

  /// No description provided for @ofertasDescartar.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get ofertasDescartar;

  /// No description provided for @ofertasRevisaCampos.
  ///
  /// In es, this message translates to:
  /// **'Revisá los campos marcados.'**
  String get ofertasRevisaCampos;

  /// No description provided for @crqNuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo croquis'**
  String get crqNuevo;

  /// No description provided for @crqErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los croquis.'**
  String get crqErrorCarga;

  /// No description provided for @crqVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no armaste ningún croquis'**
  String get crqVacioTitulo;

  /// No description provided for @crqVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Diseñá la distribución de bancos de cada aula y ubicá a tus alumnos. Después podés exportarla en PDF.'**
  String get crqVacioMensaje;

  /// No description provided for @crqFilasColumnas.
  ///
  /// In es, this message translates to:
  /// **'{filas} × {columnas} bancos'**
  String crqFilasColumnas(int filas, int columnas);

  /// No description provided for @crqOcupados.
  ///
  /// In es, this message translates to:
  /// **'{ocupados} de {total} lugares ocupados'**
  String crqOcupados(int ocupados, int total);

  /// No description provided for @crqSinVacante.
  ///
  /// In es, this message translates to:
  /// **'Sin vacante asociada'**
  String get crqSinVacante;

  /// No description provided for @crqVacanteAsociada.
  ///
  /// In es, this message translates to:
  /// **'Vacante asociada'**
  String get crqVacanteAsociada;

  /// No description provided for @crqVacanteAsociadaHelper.
  ///
  /// In es, this message translates to:
  /// **'Te vamos a sugerir sus alumnos confirmados al ubicar los bancos.'**
  String get crqVacanteAsociadaHelper;

  /// No description provided for @crqVacanteNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'La vacante asociada ya no existe'**
  String get crqVacanteNoDisponible;

  /// No description provided for @crqCambiarVacante.
  ///
  /// In es, this message translates to:
  /// **'Cambiar vacante asociada'**
  String get crqCambiarVacante;

  /// No description provided for @crqAsociarVacante.
  ///
  /// In es, this message translates to:
  /// **'Asociar una vacante'**
  String get crqAsociarVacante;

  /// No description provided for @crqVacanteActualizada.
  ///
  /// In es, this message translates to:
  /// **'Vacante asociada actualizada.'**
  String get crqVacanteActualizada;

  /// No description provided for @crqNombreLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del croquis'**
  String get crqNombreLabel;

  /// No description provided for @crqNombreHelper.
  ///
  /// In es, this message translates to:
  /// **'Ej.: 1° grado A, Aula 3, Laboratorio'**
  String get crqNombreHelper;

  /// No description provided for @crqFilas.
  ///
  /// In es, this message translates to:
  /// **'Filas'**
  String get crqFilas;

  /// No description provided for @crqColumnas.
  ///
  /// In es, this message translates to:
  /// **'Columnas'**
  String get crqColumnas;

  /// No description provided for @crqQuitarUno.
  ///
  /// In es, this message translates to:
  /// **'Quitar uno'**
  String get crqQuitarUno;

  /// No description provided for @crqAgregarUno.
  ///
  /// In es, this message translates to:
  /// **'Agregar uno'**
  String get crqAgregarUno;

  /// No description provided for @crqCrear.
  ///
  /// In es, this message translates to:
  /// **'Crear croquis'**
  String get crqCrear;

  /// No description provided for @crqVistaPrevia.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get crqVistaPrevia;

  /// No description provided for @crqFrente.
  ///
  /// In es, this message translates to:
  /// **'Frente del aula · Pizarrón'**
  String get crqFrente;

  /// No description provided for @crqBanco.
  ///
  /// In es, this message translates to:
  /// **'Banco {n}'**
  String crqBanco(int n);

  /// No description provided for @crqBancoLibre.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get crqBancoLibre;

  /// No description provided for @crqAyuda.
  ///
  /// In es, this message translates to:
  /// **'Tocá un banco para ubicar a un alumno. Mantenelo presionado y arrastralo para cambiarlo de lugar.'**
  String get crqAyuda;

  /// No description provided for @crqAyudaScroll.
  ///
  /// In es, this message translates to:
  /// **'Deslizá hacia los costados para ver toda el aula.'**
  String get crqAyudaScroll;

  /// No description provided for @crqOcupadoPor.
  ///
  /// In es, this message translates to:
  /// **'Ocupado por {nombre}'**
  String crqOcupadoPor(Object nombre);

  /// No description provided for @crqBuscarAlumno.
  ///
  /// In es, this message translates to:
  /// **'Buscar alumno'**
  String get crqBuscarAlumno;

  /// No description provided for @crqAlumnosDeVacante.
  ///
  /// In es, this message translates to:
  /// **'Alumnos confirmados en {oferta}'**
  String crqAlumnosDeVacante(Object oferta);

  /// No description provided for @crqAlumnosInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Alumnos confirmados de la institución'**
  String get crqAlumnosInstitucion;

  /// No description provided for @crqTodosSentados.
  ///
  /// In es, this message translates to:
  /// **'Todos los alumnos confirmados ya tienen banco.'**
  String get crqTodosSentados;

  /// No description provided for @crqSinConfirmados.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay alumnos confirmados. Podés escribir un nombre.'**
  String get crqSinConfirmados;

  /// No description provided for @crqSinResultados.
  ///
  /// In es, this message translates to:
  /// **'No hay alumnos que coincidan con la búsqueda.'**
  String get crqSinResultados;

  /// No description provided for @crqErrorAlumnos.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los alumnos confirmados. Podés escribir un nombre.'**
  String get crqErrorAlumnos;

  /// No description provided for @crqNombreLibre.
  ///
  /// In es, this message translates to:
  /// **'O escribí un nombre'**
  String get crqNombreLibre;

  /// No description provided for @crqNombreLibreLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre y apellido'**
  String get crqNombreLibreLabel;

  /// No description provided for @crqAsignar.
  ///
  /// In es, this message translates to:
  /// **'Ubicar'**
  String get crqAsignar;

  /// No description provided for @crqDejarLibre.
  ///
  /// In es, this message translates to:
  /// **'Dejar libre'**
  String get crqDejarLibre;

  /// No description provided for @crqMovidoDesde.
  ///
  /// In es, this message translates to:
  /// **'{nombre} pasó del banco {desde} al {hasta}.'**
  String crqMovidoDesde(Object nombre, int desde, int hasta);

  /// No description provided for @crqGuardado.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get crqGuardado;

  /// No description provided for @crqSinGuardar.
  ///
  /// In es, this message translates to:
  /// **'Sin guardar'**
  String get crqSinGuardar;

  /// No description provided for @crqErrorGuardar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el último cambio. Tocá «Sin guardar» para reintentar.'**
  String get crqErrorGuardar;

  /// No description provided for @crqRenombrar.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get crqRenombrar;

  /// No description provided for @crqRenombrarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Renombrar croquis'**
  String get crqRenombrarTitulo;

  /// No description provided for @crqTamanoCorto.
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get crqTamanoCorto;

  /// No description provided for @crqTamanoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tamaño del aula'**
  String get crqTamanoTitulo;

  /// No description provided for @crqTamanoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Las filas van del pizarrón hacia el fondo; las columnas, de izquierda a derecha.'**
  String get crqTamanoAyuda;

  /// No description provided for @crqTamanoPierde.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 alumno quedaría fuera del aula y se quitaría del croquis.} other{{n} alumnos quedarían fuera del aula y se quitarían del croquis.}}'**
  String crqTamanoPierde(int n);

  /// No description provided for @crqTamanoConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Achicar el aula?'**
  String get crqTamanoConfirmarTitulo;

  /// No description provided for @crqAplicar.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get crqAplicar;

  /// No description provided for @crqVaciar.
  ///
  /// In es, this message translates to:
  /// **'Vaciar'**
  String get crqVaciar;

  /// No description provided for @crqVaciarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Vaciar el croquis?'**
  String get crqVaciarTitulo;

  /// No description provided for @crqVaciarMensaje.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Se va a liberar 1 lugar ocupado. La distribución de bancos se mantiene.} other{Se van a liberar {n} lugares ocupados. La distribución de bancos se mantiene.}}'**
  String crqVaciarMensaje(int n);

  /// No description provided for @crqVaciadoOk.
  ///
  /// In es, this message translates to:
  /// **'Croquis vaciado.'**
  String get crqVaciadoOk;

  /// No description provided for @crqYaVacio.
  ///
  /// In es, this message translates to:
  /// **'El croquis ya está vacío.'**
  String get crqYaVacio;

  /// No description provided for @crqPdfCorto.
  ///
  /// In es, this message translates to:
  /// **'PDF'**
  String get crqPdfCorto;

  /// No description provided for @crqExportarPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF'**
  String get crqExportarPdf;

  /// No description provided for @crqPdfError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos generar el PDF. Probá de nuevo en un momento.'**
  String get crqPdfError;

  /// No description provided for @crqPdfArchivo.
  ///
  /// In es, this message translates to:
  /// **'croquis_{nombre}'**
  String crqPdfArchivo(Object nombre);

  /// No description provided for @crqEliminarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar «{nombre}»?'**
  String crqEliminarTitulo(Object nombre);

  /// No description provided for @crqEliminarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se va a borrar la distribución de bancos. Esta acción no se puede deshacer.'**
  String get crqEliminarMensaje;

  /// No description provided for @crqEliminadoOk.
  ///
  /// In es, this message translates to:
  /// **'Croquis eliminado.'**
  String get crqEliminadoOk;

  /// No description provided for @comInstTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones'**
  String get comInstTitle;

  /// No description provided for @comInstTabCalendario.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get comInstTabCalendario;

  /// No description provided for @comInstTabAvisos.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get comInstTabAvisos;

  /// No description provided for @comInstLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las comunicaciones.'**
  String get comInstLoadError;

  /// No description provided for @comInstProximos.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get comInstProximos;

  /// No description provided for @comInstPasados.
  ///
  /// In es, this message translates to:
  /// **'Pasados'**
  String get comInstPasados;

  /// No description provided for @comInstNuevoEvento.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento'**
  String get comInstNuevoEvento;

  /// No description provided for @comInstEditarEvento.
  ///
  /// In es, this message translates to:
  /// **'Editar evento'**
  String get comInstEditarEvento;

  /// No description provided for @comInstEliminarEvento.
  ///
  /// In es, this message translates to:
  /// **'Eliminar evento'**
  String get comInstEliminarEvento;

  /// No description provided for @comInstTodoElDia.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get comInstTodoElDia;

  /// No description provided for @comInstRangoFechas.
  ///
  /// In es, this message translates to:
  /// **'Del {desde} al {hasta}'**
  String comInstRangoFechas(Object desde, Object hasta);

  /// No description provided for @comInstParaTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos los alumnos'**
  String get comInstParaTodos;

  /// No description provided for @comInstEnCurso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get comInstEnCurso;

  /// No description provided for @comInstOfertaEliminada.
  ///
  /// In es, this message translates to:
  /// **'Curso o grupo eliminado'**
  String get comInstOfertaEliminada;

  /// No description provided for @comInstYMas.
  ///
  /// In es, this message translates to:
  /// **'{nombres} y {n} más'**
  String comInstYMas(Object nombres, int n);

  /// No description provided for @comInstAsistiran.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 asistirá} other{{n} asistirán}}'**
  String comInstAsistiran(int n);

  /// No description provided for @comInstTalVez.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 tal vez} other{{n} tal vez}}'**
  String comInstTalVez(int n);

  /// No description provided for @comInstNoAsistiran.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 no asistirá} other{{n} no asistirán}}'**
  String comInstNoAsistiran(int n);

  /// No description provided for @comInstSinRespuestas.
  ///
  /// In es, this message translates to:
  /// **'Sin respuestas todavía'**
  String get comInstSinRespuestas;

  /// No description provided for @comInstSinProximosTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos próximos'**
  String get comInstSinProximosTitulo;

  /// No description provided for @comInstSinProximosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Publicá reuniones, actos, evaluaciones o vacaciones: aparecen en el calendario de cada familia y les llega un aviso.'**
  String get comInstSinProximosMensaje;

  /// No description provided for @comInstSinPasadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay eventos pasados'**
  String get comInstSinPasadosTitulo;

  /// No description provided for @comInstSinPasadosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Acá vas a ver los eventos que ya ocurrieron.'**
  String get comInstSinPasadosMensaje;

  /// No description provided for @comInstSeccionTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de evento'**
  String get comInstSeccionTipo;

  /// No description provided for @comInstSeccionTipoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ayuda a las familias a reconocerlo de un vistazo.'**
  String get comInstSeccionTipoAyuda;

  /// No description provided for @comInstSeccionDatos.
  ///
  /// In es, this message translates to:
  /// **'Datos del evento'**
  String get comInstSeccionDatos;

  /// No description provided for @comInstCampoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get comInstCampoTitulo;

  /// No description provided for @comInstCampoTituloAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Reunión de familias de 1.er grado'**
  String get comInstCampoTituloAyuda;

  /// No description provided for @comInstCampoDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get comInstCampoDescripcion;

  /// No description provided for @comInstCampoDescripcionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Lo que las familias necesitan saber: qué llevar, cómo llegar, horarios.'**
  String get comInstCampoDescripcionAyuda;

  /// No description provided for @comInstCampoLugar.
  ///
  /// In es, this message translates to:
  /// **'Lugar (opcional)'**
  String get comInstCampoLugar;

  /// No description provided for @comInstSeccionCuando.
  ///
  /// In es, this message translates to:
  /// **'Cuándo'**
  String get comInstSeccionCuando;

  /// No description provided for @comInstCampoFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get comInstCampoFecha;

  /// No description provided for @comInstCampoFechaFin.
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin (opcional)'**
  String get comInstCampoFechaFin;

  /// No description provided for @comInstCampoFechaFinAyuda.
  ///
  /// In es, this message translates to:
  /// **'Para eventos de varios días, como vacaciones.'**
  String get comInstCampoFechaFinAyuda;

  /// No description provided for @comInstQuitarFechaFin.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha de fin'**
  String get comInstQuitarFechaFin;

  /// No description provided for @comInstErrorFecha.
  ///
  /// In es, this message translates to:
  /// **'Elegí la fecha.'**
  String get comInstErrorFecha;

  /// No description provided for @comInstErrorFechaFin.
  ///
  /// In es, this message translates to:
  /// **'Tiene que ser posterior a la fecha de inicio.'**
  String get comInstErrorFechaFin;

  /// No description provided for @comInstTodoElDiaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Desactivalo para indicar la hora de inicio.'**
  String get comInstTodoElDiaAyuda;

  /// No description provided for @comInstCampoHora.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get comInstCampoHora;

  /// No description provided for @comInstErrorHora.
  ///
  /// In es, this message translates to:
  /// **'Elegí la hora de inicio.'**
  String get comInstErrorHora;

  /// No description provided for @comInstSeccionDestinatarios.
  ///
  /// In es, this message translates to:
  /// **'Destinatarios'**
  String get comInstSeccionDestinatarios;

  /// No description provided for @comInstSeccionDestinatariosAyuda.
  ///
  /// In es, this message translates to:
  /// **'Lo reciben las familias de los alumnos confirmados.'**
  String get comInstSeccionDestinatariosAyuda;

  /// No description provided for @comInstDestOfertas.
  ///
  /// In es, this message translates to:
  /// **'Cursos o grupos'**
  String get comInstDestOfertas;

  /// No description provided for @comInstDestElegirAyuda.
  ///
  /// In es, this message translates to:
  /// **'Elegí uno o más cursos o grupos.'**
  String get comInstDestElegirAyuda;

  /// No description provided for @comInstDestErrorVacio.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un curso o grupo.'**
  String get comInstDestErrorVacio;

  /// No description provided for @comInstDestSinOfertas.
  ///
  /// In es, this message translates to:
  /// **'Cuando publiques vacantes vas a poder elegir cursos o grupos puntuales.'**
  String get comInstDestSinOfertas;

  /// No description provided for @comInstAlumnosConfirmados.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin alumnos confirmados} =1{1 alumno confirmado} other{{n} alumnos confirmados}}'**
  String comInstAlumnosConfirmados(int n);

  /// No description provided for @comInstPedirConfirmacion.
  ///
  /// In es, this message translates to:
  /// **'Pedir confirmación de asistencia'**
  String get comInstPedirConfirmacion;

  /// No description provided for @comInstPedirConfirmacionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Las familias podrán responder si asisten y vas a ver las respuestas acá.'**
  String get comInstPedirConfirmacionAyuda;

  /// No description provided for @comInstSeAvisaraA.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Se avisará a 1 alumno} other{Se avisará a {n} alumnos}}'**
  String comInstSeAvisaraA(int n);

  /// No description provided for @comInstSeAvisaraAyuda.
  ///
  /// In es, this message translates to:
  /// **'Les llega una notificación y el evento aparece en su calendario.'**
  String get comInstSeAvisaraAyuda;

  /// No description provided for @comInstCalculando.
  ///
  /// In es, this message translates to:
  /// **'Calculando destinatarios…'**
  String get comInstCalculando;

  /// No description provided for @comInstSinDestinatariosEvento.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay alumnos confirmados en esta selección. Nadie recibirá el aviso ahora, pero el evento va a aparecer en el calendario de quienes se sumen.'**
  String get comInstSinDestinatariosEvento;

  /// No description provided for @comInstEditarSinAviso.
  ///
  /// In es, this message translates to:
  /// **'Los cambios se guardan sin enviar una notificación nueva.'**
  String get comInstEditarSinAviso;

  /// No description provided for @comInstPublicar.
  ///
  /// In es, this message translates to:
  /// **'Publicar evento'**
  String get comInstPublicar;

  /// No description provided for @comInstPublicando.
  ///
  /// In es, this message translates to:
  /// **'Publicando…'**
  String get comInstPublicando;

  /// No description provided for @comInstGuardarCambios.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get comInstGuardarCambios;

  /// No description provided for @comInstEventoPublicado.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Evento publicado.} =1{Evento publicado. Le avisamos a 1 alumno.} other{Evento publicado. Les avisamos a {n} alumnos.}}'**
  String comInstEventoPublicado(int n);

  /// No description provided for @comInstEventoActualizado.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados.'**
  String get comInstEventoActualizado;

  /// No description provided for @comInstEventoEliminado.
  ///
  /// In es, this message translates to:
  /// **'Evento eliminado.'**
  String get comInstEventoEliminado;

  /// No description provided for @comInstEliminarEventoTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este evento?'**
  String get comInstEliminarEventoTitulo;

  /// No description provided for @comInstEliminarEventoMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se quita del calendario de las familias junto con sus respuestas. No se puede deshacer.'**
  String get comInstEliminarEventoMensaje;

  /// No description provided for @comInstDescartarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar los cambios?'**
  String get comInstDescartarTitulo;

  /// No description provided for @comInstDescartarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Lo que completaste no se va a guardar.'**
  String get comInstDescartarMensaje;

  /// No description provided for @comInstDescartar.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get comInstDescartar;

  /// No description provided for @comInstSeguirEditando.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get comInstSeguirEditando;

  /// No description provided for @comInstDetalleTitulo.
  ///
  /// In es, this message translates to:
  /// **'Detalle del evento'**
  String get comInstDetalleTitulo;

  /// No description provided for @comInstInfoFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get comInstInfoFecha;

  /// No description provided for @comInstInfoHorario.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get comInstInfoHorario;

  /// No description provided for @comInstInfoLugar.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get comInstInfoLugar;

  /// No description provided for @comInstInfoAlcance.
  ///
  /// In es, this message translates to:
  /// **'Alumnos alcanzados'**
  String get comInstInfoAlcance;

  /// No description provided for @comInstInfoDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get comInstInfoDescripcion;

  /// No description provided for @comInstPublicadoEl.
  ///
  /// In es, this message translates to:
  /// **'Publicado el {fecha}'**
  String comInstPublicadoEl(Object fecha);

  /// No description provided for @comInstRespuestasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Confirmaciones de asistencia'**
  String get comInstRespuestasTitulo;

  /// No description provided for @comInstRespuestasConteo.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Nadie respondió todavía} =1{1 respuesta} other{{n} respuestas}}'**
  String comInstRespuestasConteo(int n);

  /// No description provided for @comInstStatAsistiran.
  ///
  /// In es, this message translates to:
  /// **'Asistirán'**
  String get comInstStatAsistiran;

  /// No description provided for @comInstStatTalVez.
  ///
  /// In es, this message translates to:
  /// **'Tal vez'**
  String get comInstStatTalVez;

  /// No description provided for @comInstStatNoAsistiran.
  ///
  /// In es, this message translates to:
  /// **'No asistirán'**
  String get comInstStatNoAsistiran;

  /// No description provided for @comInstStatSinResponder.
  ///
  /// In es, this message translates to:
  /// **'Sin responder'**
  String get comInstStatSinResponder;

  /// No description provided for @comInstSinRespuestasDetalle.
  ///
  /// In es, this message translates to:
  /// **'Todavía nadie respondió. Las respuestas aparecen acá a medida que las familias confirman.'**
  String get comInstSinRespuestasDetalle;

  /// No description provided for @comInstNoPideConfirmacion.
  ///
  /// In es, this message translates to:
  /// **'Este evento no pide confirmación de asistencia. Podés activarla editándolo.'**
  String get comInstNoPideConfirmacion;

  /// No description provided for @comInstNuevoAviso.
  ///
  /// In es, this message translates to:
  /// **'Nuevo aviso'**
  String get comInstNuevoAviso;

  /// No description provided for @comInstNuevoAvisoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Llega como notificación a las familias de tus alumnos confirmados.'**
  String get comInstNuevoAvisoAyuda;

  /// No description provided for @comInstAvisoCampoTituloAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Cambio de horario de salida'**
  String get comInstAvisoCampoTituloAyuda;

  /// No description provided for @comInstAvisoCampoMensaje.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get comInstAvisoCampoMensaje;

  /// No description provided for @comInstLlegaraA.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Llegará a 1 alumno} other{Llegará a {n} alumnos}}'**
  String comInstLlegaraA(int n);

  /// No description provided for @comInstSinDestinatariosAviso.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay alumnos confirmados en esta selección. Cuando confirmes solicitudes vas a poder enviarles avisos.'**
  String get comInstSinDestinatariosAviso;

  /// No description provided for @comInstEnviarAviso.
  ///
  /// In es, this message translates to:
  /// **'Enviar aviso'**
  String get comInstEnviarAviso;

  /// No description provided for @comInstConfirmarEnvio.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{¿Enviar a 1 alumno?} other{¿Enviar a {n} alumnos?}}'**
  String comInstConfirmarEnvio(int n);

  /// No description provided for @comInstConfirmarEnvioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Las familias lo reciben como notificación. Una vez enviado, no se puede editar ni borrar.'**
  String get comInstConfirmarEnvioMensaje;

  /// No description provided for @comInstAvisoEnviado.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Aviso enviado a 1 alumno.} other{Aviso enviado a {n} alumnos.}}'**
  String comInstAvisoEnviado(int n);

  /// No description provided for @comInstAvisosVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no enviaste avisos'**
  String get comInstAvisosVacioTitulo;

  /// No description provided for @comInstAvisosVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Los avisos llegan como notificación a las familias de los alumnos confirmados. Usalos para recordatorios, cambios de horario o novedades.'**
  String get comInstAvisosVacioMensaje;

  /// No description provided for @comInstAvisosEnviados.
  ///
  /// In es, this message translates to:
  /// **'Avisos enviados'**
  String get comInstAvisosEnviados;

  /// No description provided for @comInstAvisoAlcance.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{No llegó a ningún alumno} =1{Llegó a 1 alumno} other{Llegó a {n} alumnos}}'**
  String comInstAvisoAlcance(int n);

  /// No description provided for @comInstEnviadoEl.
  ///
  /// In es, this message translates to:
  /// **'Enviado el {fecha}'**
  String comInstEnviadoEl(Object fecha);

  /// No description provided for @docInstTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get docInstTitle;

  /// No description provided for @docInstTabRevisar.
  ///
  /// In es, this message translates to:
  /// **'Para revisar'**
  String get docInstTabRevisar;

  /// No description provided for @docInstTabPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get docInstTabPendientes;

  /// No description provided for @docInstTabAprobados.
  ///
  /// In es, this message translates to:
  /// **'Aprobados'**
  String get docInstTabAprobados;

  /// No description provided for @docInstTabCancelados.
  ///
  /// In es, this message translates to:
  /// **'Cancelados'**
  String get docInstTabCancelados;

  /// No description provided for @docInstLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar la documentación.'**
  String get docInstLoadError;

  /// No description provided for @docInstPedirDocumento.
  ///
  /// In es, this message translates to:
  /// **'Pedir documento'**
  String get docInstPedirDocumento;

  /// No description provided for @docInstPedidoEl.
  ///
  /// In es, this message translates to:
  /// **'Pedido el {fecha}'**
  String docInstPedidoEl(Object fecha);

  /// No description provided for @docInstLimite.
  ///
  /// In es, this message translates to:
  /// **'Límite: {fecha}'**
  String docInstLimite(Object fecha);

  /// No description provided for @docInstEntregadoEl.
  ///
  /// In es, this message translates to:
  /// **'Entregado el {fecha}'**
  String docInstEntregadoEl(Object fecha);

  /// No description provided for @docInstVacioRevisarTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay documentos para revisar'**
  String get docInstVacioRevisarTitulo;

  /// No description provided for @docInstVacioRevisarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Cuando una familia suba un documento que pediste, lo vas a ver acá.'**
  String get docInstVacioRevisarMensaje;

  /// No description provided for @docInstVacioPendientesTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay pedidos pendientes'**
  String get docInstVacioPendientesTitulo;

  /// No description provided for @docInstVacioPendientesMensaje.
  ///
  /// In es, this message translates to:
  /// **'Pedí DNI, partida de nacimiento, certificados y más. A la familia le llega un aviso y lo sube desde la app.'**
  String get docInstVacioPendientesMensaje;

  /// No description provided for @docInstVacioAprobadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no aprobaste documentos'**
  String get docInstVacioAprobadosTitulo;

  /// No description provided for @docInstVacioAprobadosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Los documentos que apruebes quedan guardados acá.'**
  String get docInstVacioAprobadosMensaje;

  /// No description provided for @docInstVacioCanceladosTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay pedidos cancelados'**
  String get docInstVacioCanceladosTitulo;

  /// No description provided for @docInstVacioCanceladosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Si cancelás un pedido que ya no necesitás, aparece acá.'**
  String get docInstVacioCanceladosMensaje;

  /// No description provided for @docInstPedirTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pedir un documento'**
  String get docInstPedirTitulo;

  /// No description provided for @docInstPedirAyuda.
  ///
  /// In es, this message translates to:
  /// **'Le avisamos a la familia y lo sube desde la app.'**
  String get docInstPedirAyuda;

  /// No description provided for @docInstElegirAlumno.
  ///
  /// In es, this message translates to:
  /// **'¿A qué alumno?'**
  String get docInstElegirAlumno;

  /// No description provided for @docInstBuscarAlumno.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o DNI'**
  String get docInstBuscarAlumno;

  /// No description provided for @docInstLimpiarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get docInstLimpiarBusqueda;

  /// No description provided for @docInstSinResultados.
  ///
  /// In es, this message translates to:
  /// **'No encontramos alumnos con esa búsqueda.'**
  String get docInstSinResultados;

  /// No description provided for @docInstSinAlumnosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés alumnos'**
  String get docInstSinAlumnosTitulo;

  /// No description provided for @docInstSinAlumnosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Podés pedir documentos a los alumnos con solicitudes pendientes o confirmadas. Cuando recibas la primera solicitud, vas a poder hacerlo desde acá.'**
  String get docInstSinAlumnosMensaje;

  /// No description provided for @docInstSolicitudPendiente.
  ///
  /// In es, this message translates to:
  /// **'Solicitud pendiente'**
  String get docInstSolicitudPendiente;

  /// No description provided for @docInstCambiarAlumno.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get docInstCambiarAlumno;

  /// No description provided for @docInstQueDocumento.
  ///
  /// In es, this message translates to:
  /// **'¿Qué documento necesitás?'**
  String get docInstQueDocumento;

  /// No description provided for @docInstIndicacionesLabel.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones (opcional)'**
  String get docInstIndicacionesLabel;

  /// No description provided for @docInstIndicacionesAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Fotocopia de ambos lados'**
  String get docInstIndicacionesAyuda;

  /// No description provided for @docInstNombreOtroLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del documento'**
  String get docInstNombreOtroLabel;

  /// No description provided for @docInstNombreOtroAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Autorización para salidas educativas'**
  String get docInstNombreOtroAyuda;

  /// No description provided for @docInstFechaLimiteLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite (opcional)'**
  String get docInstFechaLimiteLabel;

  /// No description provided for @docInstQuitarFechaLimite.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha límite'**
  String get docInstQuitarFechaLimite;

  /// No description provided for @docInstPedidoEnviado.
  ///
  /// In es, this message translates to:
  /// **'Pedido enviado: {documento} · {alumno}'**
  String docInstPedidoEnviado(Object documento, Object alumno);

  /// No description provided for @docInstDetalleTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pedido de documento'**
  String get docInstDetalleTitulo;

  /// No description provided for @docInstAlumno.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get docInstAlumno;

  /// No description provided for @docInstFechaPedido.
  ///
  /// In es, this message translates to:
  /// **'Fecha del pedido'**
  String get docInstFechaPedido;

  /// No description provided for @docInstFechaLimite.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite'**
  String get docInstFechaLimite;

  /// No description provided for @docInstSinFechaLimite.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha límite'**
  String get docInstSinFechaLimite;

  /// No description provided for @docInstIndicaciones.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones'**
  String get docInstIndicaciones;

  /// No description provided for @docInstEsperandoArchivo.
  ///
  /// In es, this message translates to:
  /// **'Esperando que la familia suba el archivo.'**
  String get docInstEsperandoArchivo;

  /// No description provided for @docInstRevisarAyuda.
  ///
  /// In es, this message translates to:
  /// **'Revisá el archivo y aprobalo o pedí una corrección.'**
  String get docInstRevisarAyuda;

  /// No description provided for @docInstMotivoCorreccion.
  ///
  /// In es, this message translates to:
  /// **'Pediste una corrección'**
  String get docInstMotivoCorreccion;

  /// No description provided for @docInstAprobadoInfo.
  ///
  /// In es, this message translates to:
  /// **'Aprobado el {fecha}.'**
  String docInstAprobadoInfo(Object fecha);

  /// No description provided for @docInstCanceladoInfo.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste este pedido el {fecha}.'**
  String docInstCanceladoInfo(Object fecha);

  /// No description provided for @docInstArchivoEntregado.
  ///
  /// In es, this message translates to:
  /// **'Archivo entregado'**
  String get docInstArchivoEntregado;

  /// No description provided for @docInstArchivoAnterior.
  ///
  /// In es, this message translates to:
  /// **'Último archivo entregado'**
  String get docInstArchivoAnterior;

  /// No description provided for @docInstSubidoEl.
  ///
  /// In es, this message translates to:
  /// **'Subido el {fecha}'**
  String docInstSubidoEl(Object fecha);

  /// No description provided for @docInstTipoPdf.
  ///
  /// In es, this message translates to:
  /// **'Documento PDF'**
  String get docInstTipoPdf;

  /// No description provided for @docInstTipoImagen.
  ///
  /// In es, this message translates to:
  /// **'Imagen'**
  String get docInstTipoImagen;

  /// No description provided for @docInstTipoArchivo.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get docInstTipoArchivo;

  /// No description provided for @docInstTamanoKb.
  ///
  /// In es, this message translates to:
  /// **'{n} KB'**
  String docInstTamanoKb(Object n);

  /// No description provided for @docInstTamanoMb.
  ///
  /// In es, this message translates to:
  /// **'{n} MB'**
  String docInstTamanoMb(Object n);

  /// No description provided for @docInstVerArchivo.
  ///
  /// In es, this message translates to:
  /// **'Ver archivo'**
  String get docInstVerArchivo;

  /// No description provided for @docInstDescargar.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get docInstDescargar;

  /// No description provided for @docInstArchivoError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el archivo. Probá de nuevo en un rato.'**
  String get docInstArchivoError;

  /// No description provided for @docInstSinVistaPrevia.
  ///
  /// In es, this message translates to:
  /// **'No hay vista previa para este formato. Descargalo para verlo.'**
  String get docInstSinVistaPrevia;

  /// No description provided for @docInstAprobar.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get docInstAprobar;

  /// No description provided for @docInstPedirCorreccion.
  ///
  /// In es, this message translates to:
  /// **'Pedir corrección'**
  String get docInstPedirCorreccion;

  /// No description provided for @docInstAprobarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Aprobar el documento?'**
  String get docInstAprobarTitulo;

  /// No description provided for @docInstAprobarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Le avisaremos a la familia de {alumno}.'**
  String docInstAprobarMensaje(Object alumno);

  /// No description provided for @docInstAprobado.
  ///
  /// In es, this message translates to:
  /// **'Documento aprobado.'**
  String get docInstAprobado;

  /// No description provided for @docInstCorreccionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Contale a la familia qué tiene que corregir. Va a poder subir un archivo nuevo.'**
  String get docInstCorreccionAyuda;

  /// No description provided for @docInstMotivoLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get docInstMotivoLabel;

  /// No description provided for @docInstMotivoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ej.: La foto está borrosa y no se lee el número.'**
  String get docInstMotivoAyuda;

  /// No description provided for @docInstMotivoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Contanos qué hay que corregir.'**
  String get docInstMotivoRequerido;

  /// No description provided for @docInstCorreccionEnviada.
  ///
  /// In es, this message translates to:
  /// **'Le pedimos la corrección a la familia.'**
  String get docInstCorreccionEnviada;

  /// No description provided for @docInstCancelarPedido.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pedido'**
  String get docInstCancelarPedido;

  /// No description provided for @docInstCancelarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar este pedido?'**
  String get docInstCancelarTitulo;

  /// No description provided for @docInstCancelarMensaje.
  ///
  /// In es, this message translates to:
  /// **'La familia ya no va a tener que entregarlo. No se puede deshacer.'**
  String get docInstCancelarMensaje;

  /// No description provided for @docInstMantener.
  ///
  /// In es, this message translates to:
  /// **'Mantener'**
  String get docInstMantener;

  /// No description provided for @docInstPedidoCancelado.
  ///
  /// In es, this message translates to:
  /// **'Pedido cancelado.'**
  String get docInstPedidoCancelado;

  /// No description provided for @pdfGeneradoCon.
  ///
  /// In es, this message translates to:
  /// **'Generado con ATENA · {fecha}'**
  String pdfGeneradoCon(String fecha);

  /// No description provided for @pdfPagina.
  ///
  /// In es, this message translates to:
  /// **'Página {actual} de {total}'**
  String pdfPagina(int actual, int total);

  /// No description provided for @pdfNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get pdfNombre;

  /// No description provided for @pdfApellido.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get pdfApellido;

  /// No description provided for @pdfApellidoNombre.
  ///
  /// In es, this message translates to:
  /// **'Apellido y nombre'**
  String get pdfApellidoNombre;

  /// No description provided for @pdfDni.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get pdfDni;

  /// No description provided for @pdfDniValor.
  ///
  /// In es, this message translates to:
  /// **'DNI {dni}'**
  String pdfDniValor(String dni);

  /// No description provided for @pdfFechaNacimiento.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get pdfFechaNacimiento;

  /// No description provided for @pdfEdad.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get pdfEdad;

  /// No description provided for @pdfEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get pdfEmail;

  /// No description provided for @pdfTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get pdfTelefono;

  /// No description provided for @pdfContacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get pdfContacto;

  /// No description provided for @pdfInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get pdfInstitucion;

  /// No description provided for @pdfOferta.
  ///
  /// In es, this message translates to:
  /// **'Oferta'**
  String get pdfOferta;

  /// No description provided for @pdfCategoria.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get pdfCategoria;

  /// No description provided for @pdfTurno.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get pdfTurno;

  /// No description provided for @pdfHorario.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get pdfHorario;

  /// No description provided for @pdfDias.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get pdfDias;

  /// No description provided for @pdfEdades.
  ///
  /// In es, this message translates to:
  /// **'Edades'**
  String get pdfEdades;

  /// No description provided for @pdfEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get pdfEstado;

  /// No description provided for @pdfFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get pdfFecha;

  /// No description provided for @pdfNota.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get pdfNota;

  /// No description provided for @pdfFichaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ficha del alumno'**
  String get pdfFichaTitulo;

  /// No description provided for @pdfDatosPersonales.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get pdfDatosPersonales;

  /// No description provided for @pdfSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get pdfSolicitudes;

  /// No description provided for @pdfSolicitudesCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin solicitudes} =1{1 solicitud} other{{n} solicitudes}}'**
  String pdfSolicitudesCantidad(int n);

  /// No description provided for @pdfSinSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay solicitudes registradas.'**
  String get pdfSinSolicitudes;

  /// No description provided for @pdfComprobanteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de solicitud'**
  String get pdfComprobanteTitulo;

  /// No description provided for @pdfCodigo.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get pdfCodigo;

  /// No description provided for @pdfEnviadaEl.
  ///
  /// In es, this message translates to:
  /// **'Enviada el'**
  String get pdfEnviadaEl;

  /// No description provided for @pdfEmitidoEl.
  ///
  /// In es, this message translates to:
  /// **'Emitido el'**
  String get pdfEmitidoEl;

  /// No description provided for @pdfEstadoActual.
  ///
  /// In es, this message translates to:
  /// **'Estado actual'**
  String get pdfEstadoActual;

  /// No description provided for @pdfVacanteSolicitada.
  ///
  /// In es, this message translates to:
  /// **'Vacante solicitada'**
  String get pdfVacanteSolicitada;

  /// No description provided for @pdfAlumno.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get pdfAlumno;

  /// No description provided for @pdfMensajeAlumno.
  ///
  /// In es, this message translates to:
  /// **'Mensaje del alumno'**
  String get pdfMensajeAlumno;

  /// No description provided for @pdfRespuestaInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Respuesta de la institución'**
  String get pdfRespuestaInstitucion;

  /// No description provided for @pdfHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get pdfHistorial;

  /// No description provided for @pdfComprobanteAclaracion.
  ///
  /// In es, this message translates to:
  /// **'Este comprobante refleja el estado de la solicitud al momento de su emisión.'**
  String get pdfComprobanteAclaracion;

  /// No description provided for @pdfEstadoDescPendiente.
  ///
  /// In es, this message translates to:
  /// **'La institución todavía no respondió esta solicitud.'**
  String get pdfEstadoDescPendiente;

  /// No description provided for @pdfEstadoDescConfirmada.
  ///
  /// In es, this message translates to:
  /// **'La institución confirmó la vacante.'**
  String get pdfEstadoDescConfirmada;

  /// No description provided for @pdfEstadoDescRechazada.
  ///
  /// In es, this message translates to:
  /// **'La institución no aceptó la solicitud.'**
  String get pdfEstadoDescRechazada;

  /// No description provided for @pdfEstadoDescCanceladaAlumno.
  ///
  /// In es, this message translates to:
  /// **'La solicitud fue cancelada por el alumno o la familia.'**
  String get pdfEstadoDescCanceladaAlumno;

  /// No description provided for @pdfEstadoDescCanceladaInstitucion.
  ///
  /// In es, this message translates to:
  /// **'La institución dio de baja la vacante.'**
  String get pdfEstadoDescCanceladaInstitucion;

  /// No description provided for @pdfListadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Alumnos confirmados'**
  String get pdfListadoTitulo;

  /// No description provided for @pdfTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get pdfTotal;

  /// No description provided for @pdfAlumnosCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin alumnos} =1{1 alumno} other{{n} alumnos}}'**
  String pdfAlumnosCantidad(int n);

  /// No description provided for @pdfListadoVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay alumnos confirmados para mostrar.'**
  String get pdfListadoVacio;

  /// No description provided for @pdfCroquisTitulo.
  ///
  /// In es, this message translates to:
  /// **'Croquis del aula'**
  String get pdfCroquisTitulo;

  /// No description provided for @pdfFrenteAula.
  ///
  /// In es, this message translates to:
  /// **'Frente del aula'**
  String get pdfFrenteAula;

  /// No description provided for @pdfLugares.
  ///
  /// In es, this message translates to:
  /// **'Lugares'**
  String get pdfLugares;

  /// No description provided for @pdfOcupados.
  ///
  /// In es, this message translates to:
  /// **'Ocupados'**
  String get pdfOcupados;

  /// No description provided for @pdfLibres.
  ///
  /// In es, this message translates to:
  /// **'Libres'**
  String get pdfLibres;

  /// No description provided for @pdfLugarOcupado.
  ///
  /// In es, this message translates to:
  /// **'Ocupado'**
  String get pdfLugarOcupado;

  /// No description provided for @pdfLugarLibre.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get pdfLugarLibre;

  /// No description provided for @solInstTabPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get solInstTabPendientes;

  /// No description provided for @solInstTabConfirmadas.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas'**
  String get solInstTabConfirmadas;

  /// No description provided for @solInstTabNoAceptadas.
  ///
  /// In es, this message translates to:
  /// **'No aceptadas'**
  String get solInstTabNoAceptadas;

  /// No description provided for @solInstTabCanceladas.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get solInstTabCanceladas;

  /// No description provided for @solInstBuscarHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o DNI'**
  String get solInstBuscarHint;

  /// No description provided for @solInstLimpiarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get solInstLimpiarBusqueda;

  /// No description provided for @solInstFiltrarVacante.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por vacante'**
  String get solInstFiltrarVacante;

  /// No description provided for @solInstVacanteFiltro.
  ///
  /// In es, this message translates to:
  /// **'Vacante'**
  String get solInstVacanteFiltro;

  /// No description provided for @solInstTodasLasVacantes.
  ///
  /// In es, this message translates to:
  /// **'Todas las vacantes'**
  String get solInstTodasLasVacantes;

  /// No description provided for @solInstQuitarFiltro.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtro'**
  String get solInstQuitarFiltro;

  /// No description provided for @solInstOrdenLlegada.
  ///
  /// In es, this message translates to:
  /// **'Por orden de llegada: las más antiguas primero.'**
  String get solInstOrdenLlegada;

  /// No description provided for @solInstDni.
  ///
  /// In es, this message translates to:
  /// **'DNI {dni}'**
  String solInstDni(Object dni);

  /// No description provided for @solInstConMensaje.
  ///
  /// In es, this message translates to:
  /// **'La familia dejó un mensaje'**
  String get solInstConMensaje;

  /// No description provided for @solInstConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get solInstConfirmar;

  /// No description provided for @solInstNoAceptar.
  ///
  /// In es, this message translates to:
  /// **'No aceptar'**
  String get solInstNoAceptar;

  /// No description provided for @solInstConfirmarVacante.
  ///
  /// In es, this message translates to:
  /// **'Confirmar vacante'**
  String get solInstConfirmarVacante;

  /// No description provided for @solInstDarDeBaja.
  ///
  /// In es, this message translates to:
  /// **'Dar de baja'**
  String get solInstDarDeBaja;

  /// No description provided for @solInstPedirDocumento.
  ///
  /// In es, this message translates to:
  /// **'Pedir documento'**
  String get solInstPedirDocumento;

  /// No description provided for @solInstDescargarComprobante.
  ///
  /// In es, this message translates to:
  /// **'Descargar comprobante'**
  String get solInstDescargarComprobante;

  /// No description provided for @solInstPdfError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos generar el PDF. Probá de nuevo en unos minutos.'**
  String get solInstPdfError;

  /// No description provided for @solInstArchivoComprobante.
  ///
  /// In es, this message translates to:
  /// **'comprobante'**
  String get solInstArchivoComprobante;

  /// No description provided for @solInstVacioInicialTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no recibiste solicitudes'**
  String get solInstVacioInicialTitulo;

  /// No description provided for @solInstVacioInicialMsg.
  ///
  /// In es, this message translates to:
  /// **'Las familias te envían solicitudes desde tu ficha pública en ATENA. Publicá tus vacantes y completá tu perfil público para que te encuentren más fácil.'**
  String get solInstVacioInicialMsg;

  /// No description provided for @solInstIrAVacantes.
  ///
  /// In es, this message translates to:
  /// **'Ir a Vacantes'**
  String get solInstIrAVacantes;

  /// No description provided for @solInstVacioPendientesTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes'**
  String get solInstVacioPendientesTitulo;

  /// No description provided for @solInstVacioPendientesMsg.
  ///
  /// In es, this message translates to:
  /// **'¡Todo al día! Las nuevas solicitudes van a aparecer acá para que las revises.'**
  String get solInstVacioPendientesMsg;

  /// No description provided for @solInstVacioConfirmadasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no confirmaste vacantes'**
  String get solInstVacioConfirmadasTitulo;

  /// No description provided for @solInstVacioConfirmadasMsg.
  ///
  /// In es, this message translates to:
  /// **'Cuando confirmes una solicitud, la vas a ver acá y el alumno va a aparecer en Alumnos.'**
  String get solInstVacioConfirmadasMsg;

  /// No description provided for @solInstVacioNoAceptadasTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes no aceptadas'**
  String get solInstVacioNoAceptadasTitulo;

  /// No description provided for @solInstVacioNoAceptadasMsg.
  ///
  /// In es, this message translates to:
  /// **'Acá vas a ver las solicitudes que no aceptaste, con el motivo que le diste a la familia.'**
  String get solInstVacioNoAceptadasMsg;

  /// No description provided for @solInstVacioCanceladasTitulo.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes canceladas'**
  String get solInstVacioCanceladasTitulo;

  /// No description provided for @solInstVacioCanceladasMsg.
  ///
  /// In es, this message translates to:
  /// **'Acá aparecen las solicitudes que cancelaron las familias y las bajas que diste.'**
  String get solInstVacioCanceladasMsg;

  /// No description provided for @solInstSinResultadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get solInstSinResultadosTitulo;

  /// No description provided for @solInstSinResultadosMsg.
  ///
  /// In es, this message translates to:
  /// **'No encontramos solicitudes con esos filtros.'**
  String get solInstSinResultadosMsg;

  /// No description provided for @solInstLimpiarFiltros.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get solInstLimpiarFiltros;

  /// No description provided for @solInstRecibidaEl.
  ///
  /// In es, this message translates to:
  /// **'Recibida el {fecha} a las {hora}'**
  String solInstRecibidaEl(Object fecha, Object hora);

  /// No description provided for @solInstConfirmadaEl.
  ///
  /// In es, this message translates to:
  /// **'Confirmada el {fecha} a las {hora}'**
  String solInstConfirmadaEl(Object fecha, Object hora);

  /// No description provided for @solInstRechazadaEl.
  ///
  /// In es, this message translates to:
  /// **'No aceptada el {fecha} a las {hora}'**
  String solInstRechazadaEl(Object fecha, Object hora);

  /// No description provided for @solInstCanceladaEl.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por la familia el {fecha} a las {hora}'**
  String solInstCanceladaEl(Object fecha, Object hora);

  /// No description provided for @solInstBajaEl.
  ///
  /// In es, this message translates to:
  /// **'Dada de baja el {fecha} a las {hora}'**
  String solInstBajaEl(Object fecha, Object hora);

  /// No description provided for @solInstSecContacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get solInstSecContacto;

  /// No description provided for @solInstSecVacante.
  ///
  /// In es, this message translates to:
  /// **'Vacante solicitada'**
  String get solInstSecVacante;

  /// No description provided for @solInstSecMensaje.
  ///
  /// In es, this message translates to:
  /// **'Mensaje de la familia'**
  String get solInstSecMensaje;

  /// No description provided for @solInstSecHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get solInstSecHistorial;

  /// No description provided for @solInstSinContacto.
  ///
  /// In es, this message translates to:
  /// **'La familia no dejó email ni teléfono.'**
  String get solInstSinContacto;

  /// No description provided for @solInstLlamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get solInstLlamar;

  /// No description provided for @solInstWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get solInstWhatsapp;

  /// No description provided for @solInstEscribirEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar email'**
  String get solInstEscribirEmail;

  /// No description provided for @solInstCopiar.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get solInstCopiar;

  /// No description provided for @solInstCopiado.
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles.'**
  String get solInstCopiado;

  /// No description provided for @solInstNoSePudoAbrir.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir esa aplicación en este dispositivo. Podés copiar el dato y usarlo desde otro.'**
  String get solInstNoSePudoAbrir;

  /// No description provided for @solInstOcupacion.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get solInstOcupacion;

  /// No description provided for @solInstPendientesOferta.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 solicitud pendiente en esta vacante} other{{n} solicitudes pendientes en esta vacante}}'**
  String solInstPendientesOferta(int n);

  /// No description provided for @solInstVacanteNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Esta vacante ya no está publicada.'**
  String get solInstVacanteNoDisponible;

  /// No description provided for @solInstVacantePausada.
  ///
  /// In es, this message translates to:
  /// **'Pausada'**
  String get solInstVacantePausada;

  /// No description provided for @solInstVacanteCompleta.
  ///
  /// In es, this message translates to:
  /// **'Completa'**
  String get solInstVacanteCompleta;

  /// No description provided for @solInstSinCupoAviso.
  ///
  /// In es, this message translates to:
  /// **'No quedan lugares libres en esta vacante. Para confirmar, ampliá el cupo en Vacantes.'**
  String get solInstSinCupoAviso;

  /// No description provided for @solInstEdadFueraDeRango.
  ///
  /// In es, this message translates to:
  /// **'La edad del alumno ({edad}) está fuera del rango de la vacante ({rango}).'**
  String solInstEdadFueraDeRango(Object edad, Object rango);

  /// No description provided for @solInstHistRecibida.
  ///
  /// In es, this message translates to:
  /// **'Solicitud recibida'**
  String get solInstHistRecibida;

  /// No description provided for @solInstHistConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Vacante confirmada'**
  String get solInstHistConfirmada;

  /// No description provided for @solInstHistRechazada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud no aceptada'**
  String get solInstHistRechazada;

  /// No description provided for @solInstHistCanceladaFamilia.
  ///
  /// In es, this message translates to:
  /// **'Cancelada por la familia'**
  String get solInstHistCanceladaFamilia;

  /// No description provided for @solInstHistBaja.
  ///
  /// In es, this message translates to:
  /// **'Baja de la vacante'**
  String get solInstHistBaja;

  /// No description provided for @solInstOkConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Confirmaste la vacante de {alumno}. Le avisamos a la familia.'**
  String solInstOkConfirmada(Object alumno);

  /// No description provided for @solInstOkRechazada.
  ///
  /// In es, this message translates to:
  /// **'La solicitud de {alumno} no fue aceptada. Le avisamos a la familia.'**
  String solInstOkRechazada(Object alumno);

  /// No description provided for @solInstOkBaja.
  ///
  /// In es, this message translates to:
  /// **'Diste de baja a {alumno}. Le avisamos a la familia.'**
  String solInstOkBaja(Object alumno);

  /// No description provided for @solInstOkDocumento.
  ///
  /// In es, this message translates to:
  /// **'Pedido enviado: {documento}. Le avisamos a la familia.'**
  String solInstOkDocumento(Object documento);

  /// No description provided for @solInstConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar la vacante?'**
  String get solInstConfirmarTitulo;

  /// No description provided for @solInstConfirmarMsg.
  ///
  /// In es, this message translates to:
  /// **'Vas a confirmar a {alumno} en {oferta}. Le avisamos a la familia al instante.'**
  String solInstConfirmarMsg(Object alumno, Object oferta);

  /// No description provided for @solInstNotaFamiliaLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para la familia (opcional)'**
  String get solInstNotaFamiliaLabel;

  /// No description provided for @solInstNotaConfirmarHelper.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: fecha de la entrevista o qué traer el primer día.'**
  String get solInstNotaConfirmarHelper;

  /// No description provided for @solInstRechazarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿No aceptar la solicitud?'**
  String get solInstRechazarTitulo;

  /// No description provided for @solInstRechazarMsg.
  ///
  /// In es, this message translates to:
  /// **'Contale a la familia de {alumno} por qué no podés aceptar la solicitud. Va a recibir este mensaje.'**
  String solInstRechazarMsg(Object alumno);

  /// No description provided for @solInstMotivosFrecuentes.
  ///
  /// In es, this message translates to:
  /// **'Motivos frecuentes'**
  String get solInstMotivosFrecuentes;

  /// No description provided for @solInstMotivoSinVacantes.
  ///
  /// In es, this message translates to:
  /// **'Sin vacantes'**
  String get solInstMotivoSinVacantes;

  /// No description provided for @solInstMotivoSinVacantesTexto.
  ///
  /// In es, this message translates to:
  /// **'No quedan vacantes disponibles en esta oferta.'**
  String get solInstMotivoSinVacantesTexto;

  /// No description provided for @solInstMotivoEdad.
  ///
  /// In es, this message translates to:
  /// **'Edad fuera de rango'**
  String get solInstMotivoEdad;

  /// No description provided for @solInstMotivoEdadTexto.
  ///
  /// In es, this message translates to:
  /// **'La edad del alumno no corresponde al rango de esta oferta.'**
  String get solInstMotivoEdadTexto;

  /// No description provided for @solInstMotivoDocumentacion.
  ///
  /// In es, this message translates to:
  /// **'Documentación incompleta'**
  String get solInstMotivoDocumentacion;

  /// No description provided for @solInstMotivoDocumentacionTexto.
  ///
  /// In es, this message translates to:
  /// **'La documentación presentada está incompleta.'**
  String get solInstMotivoDocumentacionTexto;

  /// No description provided for @solInstMotivoOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get solInstMotivoOtro;

  /// No description provided for @solInstMotivoLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo para la familia'**
  String get solInstMotivoLabel;

  /// No description provided for @solInstMotivoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Escribí el motivo para la familia.'**
  String get solInstMotivoRequerido;

  /// No description provided for @solInstBajaTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Dar de baja a {alumno}?'**
  String solInstBajaTitulo(Object alumno);

  /// No description provided for @solInstBajaMsg.
  ///
  /// In es, this message translates to:
  /// **'Se libera su lugar en {oferta} y le avisamos a la familia. Esta acción no se puede deshacer.'**
  String solInstBajaMsg(Object oferta);

  /// No description provided for @solInstNotaBajaHelper.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: el motivo de la baja.'**
  String get solInstNotaBajaHelper;

  /// No description provided for @solInstSinCupoTitulo.
  ///
  /// In es, this message translates to:
  /// **'No quedan vacantes'**
  String get solInstSinCupoTitulo;

  /// No description provided for @solInstSinCupoMsg.
  ///
  /// In es, this message translates to:
  /// **'{oferta} ya tiene todos sus lugares ocupados. Para confirmar esta solicitud, ampliá el cupo en Vacantes.'**
  String solInstSinCupoMsg(Object oferta);

  /// No description provided for @solInstDocPara.
  ///
  /// In es, this message translates to:
  /// **'Para {alumno}'**
  String solInstDocPara(Object alumno);

  /// No description provided for @solInstDocAyuda.
  ///
  /// In es, this message translates to:
  /// **'La familia recibe el aviso al instante y puede subir el archivo desde la app.'**
  String get solInstDocAyuda;

  /// No description provided for @solInstDocTipoLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Qué documento necesitás?'**
  String get solInstDocTipoLabel;

  /// No description provided for @solInstDocTipoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Elegí un documento.'**
  String get solInstDocTipoRequerido;

  /// No description provided for @solInstDocNombreLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del documento'**
  String get solInstDocNombreLabel;

  /// No description provided for @solInstDocNombreRequerido.
  ///
  /// In es, this message translates to:
  /// **'Indicá qué documento necesitás.'**
  String get solInstDocNombreRequerido;

  /// No description provided for @solInstDocDetalleLabel.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones (opcional)'**
  String get solInstDocDetalleLabel;

  /// No description provided for @solInstDocDetalleHelper.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: fotocopia de ambos lados.'**
  String get solInstDocDetalleHelper;

  /// No description provided for @solInstDocFechaLimite.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite (opcional)'**
  String get solInstDocFechaLimite;

  /// No description provided for @solInstDocQuitarFecha.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha'**
  String get solInstDocQuitarFecha;

  /// No description provided for @solInstDocEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar pedido'**
  String get solInstDocEnviar;

  /// No description provided for @alumInstSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin alumnos confirmados} =1{1 alumno confirmado} other{{n} alumnos confirmados}}'**
  String alumInstSubtitulo(int n);

  /// No description provided for @alumInstExportarPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar listado (PDF)'**
  String get alumInstExportarPdf;

  /// No description provided for @alumInstExportarSeccion.
  ///
  /// In es, this message translates to:
  /// **'Exportar listado de {oferta} (PDF)'**
  String alumInstExportarSeccion(Object oferta);

  /// No description provided for @alumInstCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 alumno} other{{n} alumnos}}'**
  String alumInstCantidad(int n);

  /// No description provided for @alumInstVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay alumnos confirmados'**
  String get alumInstVacioTitulo;

  /// No description provided for @alumInstVacioMsg.
  ///
  /// In es, this message translates to:
  /// **'Acá aparecen los alumnos a medida que confirmás sus solicitudes, agrupados por vacante.'**
  String get alumInstVacioMsg;

  /// No description provided for @alumInstRevisarSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Revisar 1 solicitud pendiente} other{Revisar {n} solicitudes pendientes}}'**
  String alumInstRevisarSolicitudes(int n);

  /// No description provided for @alumInstSinResultadosMsg.
  ///
  /// In es, this message translates to:
  /// **'No encontramos alumnos con ese nombre o DNI.'**
  String get alumInstSinResultadosMsg;

  /// No description provided for @alumInstArchivoListado.
  ///
  /// In es, this message translates to:
  /// **'alumnos'**
  String get alumInstArchivoListado;

  /// No description provided for @notiCuentaEliminadaTitle.
  ///
  /// In es, this message translates to:
  /// **'Una familia eliminó su cuenta'**
  String get notiCuentaEliminadaTitle;

  /// No description provided for @notiCuentaEliminadaBody.
  ///
  /// In es, this message translates to:
  /// **'{alumno} ya no figura en {oferta}: su familia eliminó la cuenta y el lugar quedó libre.'**
  String notiCuentaEliminadaBody(Object alumno, Object oferta);

  /// No description provided for @notiInstitucionEliminadaTitle.
  ///
  /// In es, this message translates to:
  /// **'{institucion} dejó ATENA'**
  String notiInstitucionEliminadaTitle(Object institucion);

  /// No description provided for @notiInstitucionEliminadaBody.
  ///
  /// In es, this message translates to:
  /// **'La solicitud de {alumno} para {oferta} quedó sin efecto porque la institución eliminó su cuenta.'**
  String notiInstitucionEliminadaBody(Object alumno, Object oferta);

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la cuenta?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountFamilyBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán la cuenta, los alumnos y sus solicitudes, documentos, notas y notificaciones. Las instituciones serán avisadas y se liberarán los lugares confirmados.'**
  String get deleteAccountFamilyBody;

  /// No description provided for @deleteAccountInstitutionBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán la institución, sus vacantes, eventos, avisos, croquis, pedidos de documentos y el perfil público. Las familias con solicitudes activas serán avisadas.'**
  String get deleteAccountInstitutionBody;

  /// No description provided for @deleteAccountIrreversible.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get deleteAccountIrreversible;

  /// No description provided for @deleteAccountPasswordHelper.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu contraseña para confirmar.'**
  String get deleteAccountPasswordHelper;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDone.
  ///
  /// In es, this message translates to:
  /// **'La cuenta fue eliminada.'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es correcta.'**
  String get deleteAccountWrongPassword;

  /// No description provided for @perfInstTitulo.
  ///
  /// In es, this message translates to:
  /// **'Perfil de la institución'**
  String get perfInstTitulo;

  /// No description provided for @perfInstTabDatos.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get perfInstTabDatos;

  /// No description provided for @perfInstTabPublico.
  ///
  /// In es, this message translates to:
  /// **'Perfil público'**
  String get perfInstTabPublico;

  /// No description provided for @perfInstTabVista.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get perfInstTabVista;

  /// No description provided for @perfInstErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el perfil de la institución.'**
  String get perfInstErrorCarga;

  /// No description provided for @perfInstSecIdentidad.
  ///
  /// In es, this message translates to:
  /// **'Identificación'**
  String get perfInstSecIdentidad;

  /// No description provided for @perfInstSecIdentidadAyuda.
  ///
  /// In es, this message translates to:
  /// **'Así aparece tu institución en ATENA y en el buscador de las familias.'**
  String get perfInstSecIdentidadAyuda;

  /// No description provided for @perfInstNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la institución'**
  String get perfInstNombre;

  /// No description provided for @perfInstNombreCorto.
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 3 caracteres.'**
  String get perfInstNombreCorto;

  /// No description provided for @perfInstCuit.
  ///
  /// In es, this message translates to:
  /// **'CUIT'**
  String get perfInstCuit;

  /// No description provided for @perfInstCuitAyuda.
  ///
  /// In es, this message translates to:
  /// **'11 dígitos, sin guiones. Lo usamos para verificar tu identidad si olvidás la contraseña.'**
  String get perfInstCuitAyuda;

  /// No description provided for @perfInstTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de institución'**
  String get perfInstTipo;

  /// No description provided for @perfInstModalidad.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get perfInstModalidad;

  /// No description provided for @perfInstSecUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get perfInstSecUbicacion;

  /// No description provided for @perfInstDireccion.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get perfInstDireccion;

  /// No description provided for @perfInstCiudad.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get perfInstCiudad;

  /// No description provided for @perfInstProvincia.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get perfInstProvincia;

  /// No description provided for @perfInstPais.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get perfInstPais;

  /// No description provided for @perfInstSecAdmin.
  ///
  /// In es, this message translates to:
  /// **'Contacto administrativo'**
  String get perfInstSecAdmin;

  /// No description provided for @perfInstSecAdminAyuda.
  ///
  /// In es, this message translates to:
  /// **'Lo usamos para comunicarnos con tu institución. No cambia el email con el que ingresás; los datos para las familias se cargan en Perfil público.'**
  String get perfInstSecAdminAyuda;

  /// No description provided for @perfInstEmailAdmin.
  ///
  /// In es, this message translates to:
  /// **'Email de contacto'**
  String get perfInstEmailAdmin;

  /// No description provided for @perfInstTelefonoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Revisá el número: debe tener entre 8 y 15 dígitos.'**
  String get perfInstTelefonoInvalido;

  /// No description provided for @perfInstCompleto.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil está completo al {pct}%'**
  String perfInstCompleto(int pct);

  /// No description provided for @perfInstCompletoListo.
  ///
  /// In es, this message translates to:
  /// **'¡Tu perfil está completo!'**
  String get perfInstCompletoListo;

  /// No description provided for @perfInstCompletoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Un perfil completo ayuda a las familias a conocerte y elegirte.'**
  String get perfInstCompletoAyuda;

  /// No description provided for @perfInstCompletoListoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Las familias ya pueden conocer todo lo que ofrecés.'**
  String get perfInstCompletoListoAyuda;

  /// No description provided for @perfInstPorcentaje.
  ///
  /// In es, this message translates to:
  /// **'{pct}%'**
  String perfInstPorcentaje(int pct);

  /// No description provided for @perfInstConsejoLogo.
  ///
  /// In es, this message translates to:
  /// **'Subí el logo de tu institución.'**
  String get perfInstConsejoLogo;

  /// No description provided for @perfInstConsejoDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Escribí una descripción de al menos {min} caracteres.'**
  String perfInstConsejoDescripcion(int min);

  /// No description provided for @perfInstConsejoFotos.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Sumá 1 foto más de tus espacios.} other{Sumá {n} fotos más de tus espacios.}}'**
  String perfInstConsejoFotos(int n);

  /// No description provided for @perfInstConsejoAtencion.
  ///
  /// In es, this message translates to:
  /// **'Indicá tu horario de atención.'**
  String get perfInstConsejoAtencion;

  /// No description provided for @perfInstConsejoClases.
  ///
  /// In es, this message translates to:
  /// **'Contá en qué horario se dictan las clases.'**
  String get perfInstConsejoClases;

  /// No description provided for @perfInstConsejoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Agregá un teléfono o WhatsApp para que las familias te contacten.'**
  String get perfInstConsejoTelefono;

  /// No description provided for @perfInstConsejoEmailWeb.
  ///
  /// In es, this message translates to:
  /// **'Sumá un email o tu sitio web.'**
  String get perfInstConsejoEmailWeb;

  /// No description provided for @perfInstConsejoRedes.
  ///
  /// In es, this message translates to:
  /// **'Vinculá al menos una red social.'**
  String get perfInstConsejoRedes;

  /// No description provided for @perfInstConsejoServicios.
  ///
  /// In es, this message translates to:
  /// **'Contá qué servicios ofrecés.'**
  String get perfInstConsejoServicios;

  /// No description provided for @perfInstSecImagenes.
  ///
  /// In es, this message translates to:
  /// **'Logo y fotos'**
  String get perfInstSecImagenes;

  /// No description provided for @perfInstLogo.
  ///
  /// In es, this message translates to:
  /// **'Logo'**
  String get perfInstLogo;

  /// No description provided for @perfInstLogoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Imagen cuadrada en JPG o PNG, de hasta 1,5 MB. Se ve en el buscador y en tu ficha.'**
  String get perfInstLogoAyuda;

  /// No description provided for @perfInstLogoSubir.
  ///
  /// In es, this message translates to:
  /// **'Subir logo'**
  String get perfInstLogoSubir;

  /// No description provided for @perfInstLogoCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar logo'**
  String get perfInstLogoCambiar;

  /// No description provided for @perfInstLogoQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar logo'**
  String get perfInstLogoQuitar;

  /// No description provided for @perfInstLogoQuitarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el logo?'**
  String get perfInstLogoQuitarTitulo;

  /// No description provided for @perfInstLogoQuitarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Las familias van a ver las iniciales de tu institución en su lugar.'**
  String get perfInstLogoQuitarMensaje;

  /// No description provided for @perfInstLogoListo.
  ///
  /// In es, this message translates to:
  /// **'Logo actualizado.'**
  String get perfInstLogoListo;

  /// No description provided for @perfInstLogoQuitado.
  ///
  /// In es, this message translates to:
  /// **'Quitamos el logo.'**
  String get perfInstLogoQuitado;

  /// No description provided for @perfInstFotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get perfInstFotos;

  /// No description provided for @perfInstFotosCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n} de {max}'**
  String perfInstFotosCantidad(int n, int max);

  /// No description provided for @perfInstFotosAyuda.
  ///
  /// In es, this message translates to:
  /// **'Mostrá tus espacios: aulas, patio, laboratorio, actividades. Hasta {max} fotos de 1,5 MB.'**
  String perfInstFotosAyuda(int max);

  /// No description provided for @perfInstFotoAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get perfInstFotoAgregar;

  /// No description provided for @perfInstFotoQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get perfInstFotoQuitar;

  /// No description provided for @perfInstFotoQuitarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta foto?'**
  String get perfInstFotoQuitarTitulo;

  /// No description provided for @perfInstFotoQuitarMensaje.
  ///
  /// In es, this message translates to:
  /// **'La foto se va a eliminar de tu perfil público.'**
  String get perfInstFotoQuitarMensaje;

  /// No description provided for @perfInstFotoAgregada.
  ///
  /// In es, this message translates to:
  /// **'Foto agregada.'**
  String get perfInstFotoAgregada;

  /// No description provided for @perfInstFotoQuitada.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada.'**
  String get perfInstFotoQuitada;

  /// No description provided for @perfInstFotoVer.
  ///
  /// In es, this message translates to:
  /// **'Ver foto {n}'**
  String perfInstFotoVer(int n);

  /// No description provided for @perfInstFotoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Foto no disponible'**
  String get perfInstFotoNoDisponible;

  /// No description provided for @perfInstGaleriaError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tus imágenes. Revisá los permisos e intentá de nuevo.'**
  String get perfInstGaleriaError;

  /// No description provided for @perfInstSecSobre.
  ///
  /// In es, this message translates to:
  /// **'Sobre la institución'**
  String get perfInstSecSobre;

  /// No description provided for @perfInstDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get perfInstDescripcion;

  /// No description provided for @perfInstDescripcionHint.
  ///
  /// In es, this message translates to:
  /// **'Contá tu propuesta educativa, tus valores y lo que hace única a tu institución.'**
  String get perfInstDescripcionHint;

  /// No description provided for @perfInstSecHorarios.
  ///
  /// In es, this message translates to:
  /// **'Horarios'**
  String get perfInstSecHorarios;

  /// No description provided for @perfInstHorarioAtencion.
  ///
  /// In es, this message translates to:
  /// **'Horario de atención'**
  String get perfInstHorarioAtencion;

  /// No description provided for @perfInstHorarioAtencionHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: lunes a viernes de 8 a 16 h'**
  String get perfInstHorarioAtencionHint;

  /// No description provided for @perfInstHorarioClases.
  ///
  /// In es, this message translates to:
  /// **'Horario de clases'**
  String get perfInstHorarioClases;

  /// No description provided for @perfInstHorarioClasesHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: turno mañana de 7:30 a 12:30'**
  String get perfInstHorarioClasesHint;

  /// No description provided for @perfInstSecContacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto para familias'**
  String get perfInstSecContacto;

  /// No description provided for @perfInstSecContactoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Lo ven las familias en tu ficha. Completá al menos un medio de contacto.'**
  String get perfInstSecContactoAyuda;

  /// No description provided for @perfInstWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get perfInstWhatsapp;

  /// No description provided for @perfInstWhatsappAyuda.
  ///
  /// In es, this message translates to:
  /// **'Incluí el código de área.'**
  String get perfInstWhatsappAyuda;

  /// No description provided for @perfInstEmailFamilias.
  ///
  /// In es, this message translates to:
  /// **'Email para familias'**
  String get perfInstEmailFamilias;

  /// No description provided for @perfInstWeb.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get perfInstWeb;

  /// No description provided for @perfInstWebHint.
  ///
  /// In es, this message translates to:
  /// **'tuescuela.edu.ar'**
  String get perfInstWebHint;

  /// No description provided for @perfInstWebInvalida.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una dirección web válida.'**
  String get perfInstWebInvalida;

  /// No description provided for @perfInstSecRedes.
  ///
  /// In es, this message translates to:
  /// **'Redes sociales'**
  String get perfInstSecRedes;

  /// No description provided for @perfInstSecRedesAyuda.
  ///
  /// In es, this message translates to:
  /// **'Escribí tu @usuario o pegá el enlace de tu página.'**
  String get perfInstSecRedesAyuda;

  /// No description provided for @perfInstInstagram.
  ///
  /// In es, this message translates to:
  /// **'Instagram'**
  String get perfInstInstagram;

  /// No description provided for @perfInstFacebook.
  ///
  /// In es, this message translates to:
  /// **'Facebook'**
  String get perfInstFacebook;

  /// No description provided for @perfInstYoutube.
  ///
  /// In es, this message translates to:
  /// **'YouTube'**
  String get perfInstYoutube;

  /// No description provided for @perfInstRedInvalida.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un @usuario o un enlace válido.'**
  String get perfInstRedInvalida;

  /// No description provided for @perfInstSecServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get perfInstSecServicios;

  /// No description provided for @perfInstSecServiciosAyuda.
  ///
  /// In es, this message translates to:
  /// **'Contá qué ofrecés además de las clases.'**
  String get perfInstSecServiciosAyuda;

  /// No description provided for @perfInstServicioAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar servicio'**
  String get perfInstServicioAgregar;

  /// No description provided for @perfInstServicioHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: huerta escolar'**
  String get perfInstServicioHint;

  /// No description provided for @perfInstServicioQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar {servicio}'**
  String perfInstServicioQuitar(Object servicio);

  /// No description provided for @perfInstServiciosSugeridos.
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get perfInstServiciosSugeridos;

  /// No description provided for @perfInstServiciosMax.
  ///
  /// In es, this message translates to:
  /// **'Podés cargar hasta {max} servicios.'**
  String perfInstServiciosMax(int max);

  /// No description provided for @perfInstServicioRepetido.
  ///
  /// In es, this message translates to:
  /// **'Ese servicio ya está en la lista.'**
  String get perfInstServicioRepetido;

  /// No description provided for @perfInstSrvComedor.
  ///
  /// In es, this message translates to:
  /// **'Comedor'**
  String get perfInstSrvComedor;

  /// No description provided for @perfInstSrvTransporte.
  ///
  /// In es, this message translates to:
  /// **'Transporte escolar'**
  String get perfInstSrvTransporte;

  /// No description provided for @perfInstSrvGabinete.
  ///
  /// In es, this message translates to:
  /// **'Gabinete psicopedagógico'**
  String get perfInstSrvGabinete;

  /// No description provided for @perfInstSrvJornadaExtendida.
  ///
  /// In es, this message translates to:
  /// **'Jornada extendida'**
  String get perfInstSrvJornadaExtendida;

  /// No description provided for @perfInstSrvBilingue.
  ///
  /// In es, this message translates to:
  /// **'Educación bilingüe'**
  String get perfInstSrvBilingue;

  /// No description provided for @perfInstSrvDeportes.
  ///
  /// In es, this message translates to:
  /// **'Deportes'**
  String get perfInstSrvDeportes;

  /// No description provided for @perfInstSrvBecas.
  ///
  /// In es, this message translates to:
  /// **'Becas'**
  String get perfInstSrvBecas;

  /// No description provided for @perfInstSrvLaboratorio.
  ///
  /// In es, this message translates to:
  /// **'Laboratorio'**
  String get perfInstSrvLaboratorio;

  /// No description provided for @perfInstSrvBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get perfInstSrvBiblioteca;

  /// No description provided for @perfInstSrvAccesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get perfInstSrvAccesibilidad;

  /// No description provided for @perfInstCambiosPendientes.
  ///
  /// In es, this message translates to:
  /// **'Tenés cambios sin guardar'**
  String get perfInstCambiosPendientes;

  /// No description provided for @perfInstDescartar.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get perfInstDescartar;

  /// No description provided for @perfInstDescartarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar los cambios?'**
  String get perfInstDescartarTitulo;

  /// No description provided for @perfInstDescartarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Vas a perder lo que modificaste desde la última vez que guardaste.'**
  String get perfInstDescartarMensaje;

  /// No description provided for @perfInstGuardado.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados.'**
  String get perfInstGuardado;

  /// No description provided for @perfInstRevisarCampos.
  ///
  /// In es, this message translates to:
  /// **'Revisá los campos marcados.'**
  String get perfInstRevisarCampos;

  /// No description provided for @perfInstSalirTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Salir sin guardar?'**
  String get perfInstSalirTitulo;

  /// No description provided for @perfInstSalirMensaje.
  ///
  /// In es, this message translates to:
  /// **'Tenés cambios sin guardar. Si salís ahora, se van a perder.'**
  String get perfInstSalirMensaje;

  /// No description provided for @perfInstSalir.
  ///
  /// In es, this message translates to:
  /// **'Salir sin guardar'**
  String get perfInstSalir;

  /// No description provided for @perfInstVistaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Así te ven las familias'**
  String get perfInstVistaTitulo;

  /// No description provided for @perfInstVistaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Es la ficha que aparece cuando te encuentran en ATENA.'**
  String get perfInstVistaAyuda;

  /// No description provided for @perfInstVistaSinGuardar.
  ///
  /// In es, this message translates to:
  /// **'Incluye cambios que todavía no guardaste.'**
  String get perfInstVistaSinGuardar;

  /// No description provided for @perfInstVistaCompletar.
  ///
  /// In es, this message translates to:
  /// **'Completar perfil'**
  String get perfInstVistaCompletar;

  /// No description provided for @perfInstVistaSinDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay una descripción.'**
  String get perfInstVistaSinDescripcion;

  /// No description provided for @perfInstVistaContacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get perfInstVistaContacto;

  /// No description provided for @perfInstVistaSinContacto.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay datos de contacto.'**
  String get perfInstVistaSinContacto;

  /// No description provided for @perfInstSinNombre.
  ///
  /// In es, this message translates to:
  /// **'Tu institución'**
  String get perfInstSinNombre;

  /// No description provided for @plnTitulo.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu plan'**
  String get plnTitulo;

  /// No description provided for @plnHeroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Armá tu plan a medida'**
  String get plnHeroTitulo;

  /// No description provided for @plnHeroAyuda.
  ///
  /// In es, this message translates to:
  /// **'Pagás solo por los niveles y módulos que usás, y podés cambiarlos cuando quieras.'**
  String get plnHeroAyuda;

  /// No description provided for @plnPrueba.
  ///
  /// In es, this message translates to:
  /// **'{dias} días de prueba gratis'**
  String plnPrueba(int dias);

  /// No description provided for @plnSinPagos.
  ///
  /// In es, this message translates to:
  /// **'Sin pagos por ahora'**
  String get plnSinPagos;

  /// No description provided for @plnFlexible.
  ///
  /// In es, this message translates to:
  /// **'Cambialo cuando quieras'**
  String get plnFlexible;

  /// No description provided for @plnNiveles.
  ///
  /// In es, this message translates to:
  /// **'Niveles curriculares'**
  String get plnNiveles;

  /// No description provided for @plnNivelesAyuda.
  ///
  /// In es, this message translates to:
  /// **'Salas, grados y años de tu propuesta oficial · {precio} por nivel al mes'**
  String plnNivelesAyuda(Object precio);

  /// No description provided for @plnModulos.
  ///
  /// In es, this message translates to:
  /// **'Módulos extracurriculares'**
  String get plnModulos;

  /// No description provided for @plnModulosAyuda.
  ///
  /// In es, this message translates to:
  /// **'Talleres y actividades fuera del horario escolar · {precio} por módulo al mes'**
  String plnModulosAyuda(Object precio);

  /// No description provided for @plnPorMes.
  ///
  /// In es, this message translates to:
  /// **'{precio} / mes'**
  String plnPorMes(Object precio);

  /// No description provided for @plnUsd.
  ///
  /// In es, this message translates to:
  /// **'USD {monto}'**
  String plnUsd(int monto);

  /// No description provided for @plnUsdDecimal.
  ///
  /// In es, this message translates to:
  /// **'USD {monto}'**
  String plnUsdDecimal(double monto);

  /// No description provided for @plnBloqueDeporte.
  ///
  /// In es, this message translates to:
  /// **'Fútbol, natación, gimnasia, artes marciales y más.'**
  String get plnBloqueDeporte;

  /// No description provided for @plnBloqueArte.
  ///
  /// In es, this message translates to:
  /// **'Música, teatro, danza y artes visuales.'**
  String get plnBloqueArte;

  /// No description provided for @plnBloqueIdiomas.
  ///
  /// In es, this message translates to:
  /// **'Idiomas, conversación y comunicación oral y escrita.'**
  String get plnBloqueIdiomas;

  /// No description provided for @plnBloqueCiencia.
  ///
  /// In es, this message translates to:
  /// **'Robótica, programación y proyectos STEAM.'**
  String get plnBloqueCiencia;

  /// No description provided for @plnBloqueApoyo.
  ///
  /// In es, this message translates to:
  /// **'Apoyo escolar, tutorías y preparación de exámenes.'**
  String get plnBloqueApoyo;

  /// No description provided for @plnBloqueBienestar.
  ///
  /// In es, this message translates to:
  /// **'Bienestar, habilidades socioemocionales y orientación vocacional.'**
  String get plnBloqueBienestar;

  /// No description provided for @plnBloqueOtros.
  ///
  /// In es, this message translates to:
  /// **'Propuestas que no entran en las otras categorías.'**
  String get plnBloqueOtros;

  /// No description provided for @plnVacantesActivas.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 vacante publicada} other{{n} vacantes publicadas}}'**
  String plnVacantesActivas(int n);

  /// No description provided for @plnSePausan.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Se va a pausar 1 vacante} other{Se van a pausar {n} vacantes}}'**
  String plnSePausan(int n);

  /// No description provided for @plnPromoTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Tenés un código promocional?'**
  String get plnPromoTitulo;

  /// No description provided for @plnPromoCampo.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get plnPromoCampo;

  /// No description provided for @plnPromoHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu código'**
  String get plnPromoHint;

  /// No description provided for @plnPromoAplicar.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get plnPromoAplicar;

  /// No description provided for @plnPromoVacio.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un código.'**
  String get plnPromoVacio;

  /// No description provided for @plnPromoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Ese código no es válido. Revisalo e intentá de nuevo.'**
  String get plnPromoInvalido;

  /// No description provided for @plnPromoAgotado.
  ///
  /// In es, this message translates to:
  /// **'Este código ya alcanzó su límite de usos.'**
  String get plnPromoAgotado;

  /// No description provided for @plnPromoValido.
  ///
  /// In es, this message translates to:
  /// **'¡Código aplicado! Tenés un {pct}% de descuento.'**
  String plnPromoValido(int pct);

  /// No description provided for @plnPromoActivo.
  ///
  /// In es, this message translates to:
  /// **'Tenés un código promocional activo: {pct}% de descuento.'**
  String plnPromoActivo(int pct);

  /// No description provided for @plnPromoQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar código'**
  String get plnPromoQuitar;

  /// No description provided for @plnResumen.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get plnResumen;

  /// No description provided for @plnResumenNiveles.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 nivel curricular} other{{n} niveles curriculares}}'**
  String plnResumenNiveles(int n);

  /// No description provided for @plnResumenModulos.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 módulo extracurricular} other{{n} módulos extracurriculares}}'**
  String plnResumenModulos(int n);

  /// No description provided for @plnSubtotal.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get plnSubtotal;

  /// No description provided for @plnDescuentoVolumen.
  ///
  /// In es, this message translates to:
  /// **'Descuento por {min} o más ítems ({pct}%)'**
  String plnDescuentoVolumen(int min, int pct);

  /// No description provided for @plnDescuentoPromo.
  ///
  /// In es, this message translates to:
  /// **'Código promocional ({pct}%)'**
  String plnDescuentoPromo(int pct);

  /// No description provided for @plnTotalMes.
  ///
  /// In es, this message translates to:
  /// **'Total por mes'**
  String get plnTotalMes;

  /// No description provided for @plnFaltanItems.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Sumá 1 ítem más y obtené un {pct}% de descuento.} other{Sumá {n} ítems más y obtené un {pct}% de descuento.}}'**
  String plnFaltanItems(int n, int pct);

  /// No description provided for @plnElegiAlMenosUno.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un nivel o un módulo para armar tu plan.'**
  String get plnElegiAlMenosUno;

  /// No description provided for @plnElegiAlMenosUnoCorto.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un nivel o módulo'**
  String get plnElegiAlMenosUnoCorto;

  /// No description provided for @plnPruebaTexto.
  ///
  /// In es, this message translates to:
  /// **'Durante la prueba no se cobra nada; te vamos a avisar antes de habilitar el pago.'**
  String get plnPruebaTexto;

  /// No description provided for @plnPruebaEmpieza.
  ///
  /// In es, this message translates to:
  /// **'Tu prueba gratis de {dias} días empieza cuando guardás los cambios.'**
  String plnPruebaEmpieza(int dias);

  /// No description provided for @plnPruebaTerminada.
  ///
  /// In es, this message translates to:
  /// **'Tu prueba terminó el {fecha}. Todavía no hay pagos habilitados: te vamos a avisar antes de cobrar.'**
  String plnPruebaTerminada(Object fecha);

  /// No description provided for @plnSinCobros.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay pagos habilitados en ATENA: no se te va a cobrar nada sin avisarte antes.'**
  String get plnSinCobros;

  /// No description provided for @plnGratisTitulo.
  ///
  /// In es, this message translates to:
  /// **'Plan sin costo'**
  String get plnGratisTitulo;

  /// No description provided for @plnGratisTexto.
  ///
  /// In es, this message translates to:
  /// **'Con tu código promocional, el plan queda activo sin costo.'**
  String get plnGratisTexto;

  /// No description provided for @plnDiasRestantes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Hoy es el último día de prueba.} =1{Queda 1 día de prueba.} other{Quedan {n} días de prueba.}}'**
  String plnDiasRestantes(int n);

  /// No description provided for @plnCrear.
  ///
  /// In es, this message translates to:
  /// **'Crear institución'**
  String get plnCrear;

  /// No description provided for @plnCreando.
  ///
  /// In es, this message translates to:
  /// **'Creando…'**
  String get plnCreando;

  /// No description provided for @plnGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get plnGuardar;

  /// No description provided for @plnCreada.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu institución ya está en ATENA.'**
  String get plnCreada;

  /// No description provided for @plnGuardado.
  ///
  /// In es, this message translates to:
  /// **'Plan actualizado.'**
  String get plnGuardado;

  /// No description provided for @plnPausadas.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Plan actualizado. Pausamos 1 vacante.} other{Plan actualizado. Pausamos {n} vacantes.}}'**
  String plnPausadas(int n);

  /// No description provided for @plnCorregirDatos.
  ///
  /// In es, this message translates to:
  /// **'Corregir mis datos'**
  String get plnCorregirDatos;

  /// No description provided for @plnPausarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Pausar vacantes publicadas?'**
  String get plnPausarTitulo;

  /// No description provided for @plnPausarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Quitaste {categorias} de tu plan. {n, plural, =1{Vamos a pausar 1 vacante publicada para que las familias dejen de verla.} other{Vamos a pausar {n} vacantes publicadas para que las familias dejen de verlas.}} Podés reactivarlas cuando vuelvas a sumar la categoría.'**
  String plnPausarMensaje(Object categorias, int n);

  /// No description provided for @plnPausarAccion.
  ///
  /// In es, this message translates to:
  /// **'Guardar y pausar'**
  String get plnPausarAccion;

  /// No description provided for @plnErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu plan.'**
  String get plnErrorCarga;

  /// No description provided for @plnTuPlan.
  ///
  /// In es, this message translates to:
  /// **'Tu plan'**
  String get plnTuPlan;

  /// No description provided for @plnPlanActual.
  ///
  /// In es, this message translates to:
  /// **'Plan actual: {precio} por mes'**
  String plnPlanActual(Object precio);

  /// No description provided for @explorarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Explorar instituciones'**
  String get explorarTitulo;

  /// No description provided for @explorarPara.
  ///
  /// In es, this message translates to:
  /// **'Para {nombre}'**
  String explorarPara(Object nombre);

  /// No description provided for @explorarBuscarHint.
  ///
  /// In es, this message translates to:
  /// **'Buscá por nombre, ciudad o provincia'**
  String get explorarBuscarHint;

  /// No description provided for @explorarBorrarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get explorarBorrarBusqueda;

  /// No description provided for @explorarFiltros.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get explorarFiltros;

  /// No description provided for @explorarFiltroNivel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get explorarFiltroNivel;

  /// No description provided for @explorarFiltroActividad.
  ///
  /// In es, this message translates to:
  /// **'Actividades'**
  String get explorarFiltroActividad;

  /// No description provided for @explorarFiltroModalidad.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get explorarFiltroModalidad;

  /// No description provided for @explorarCualquierNivel.
  ///
  /// In es, this message translates to:
  /// **'Cualquier nivel'**
  String get explorarCualquierNivel;

  /// No description provided for @explorarCualquierActividad.
  ///
  /// In es, this message translates to:
  /// **'Cualquier actividad'**
  String get explorarCualquierActividad;

  /// No description provided for @explorarCualquierModalidad.
  ///
  /// In es, this message translates to:
  /// **'Cualquier modalidad'**
  String get explorarCualquierModalidad;

  /// No description provided for @explorarConLugarPara.
  ///
  /// In es, this message translates to:
  /// **'Con vacantes para {nombre}'**
  String explorarConLugarPara(Object nombre);

  /// No description provided for @explorarConLugarAyuda.
  ///
  /// In es, this message translates to:
  /// **'Solo instituciones con lugar disponible para la edad de {nombre} ({edad}).'**
  String explorarConLugarAyuda(Object nombre, Object edad);

  /// No description provided for @explorarLimpiarFiltros.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get explorarLimpiarFiltros;

  /// No description provided for @explorarResultados.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 institución} other{{n} instituciones}}'**
  String explorarResultados(int n);

  /// No description provided for @explorarVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay instituciones publicadas'**
  String get explorarVacioTitulo;

  /// No description provided for @explorarVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Las instituciones aparecen acá a medida que se registran en ATENA. Volvé a mirar pronto.'**
  String get explorarVacioMensaje;

  /// No description provided for @explorarSinResultadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'No encontramos instituciones'**
  String get explorarSinResultadosTitulo;

  /// No description provided for @explorarSinResultadosMensaje.
  ///
  /// In es, this message translates to:
  /// **'Probá con otras palabras o quitá algún filtro para ver más opciones.'**
  String get explorarSinResultadosMensaje;

  /// No description provided for @explorarVerInstitucion.
  ///
  /// In es, this message translates to:
  /// **'Ver institución'**
  String get explorarVerInstitucion;

  /// No description provided for @explorarFotoDe.
  ///
  /// In es, this message translates to:
  /// **'Foto {n} de {total}'**
  String explorarFotoDe(int n, int total);

  /// No description provided for @explorarVerFotos.
  ///
  /// In es, this message translates to:
  /// **'Ver fotos en pantalla completa'**
  String get explorarVerFotos;

  /// No description provided for @explorarFotoAnterior.
  ///
  /// In es, this message translates to:
  /// **'Foto anterior'**
  String get explorarFotoAnterior;

  /// No description provided for @explorarFotoSiguiente.
  ///
  /// In es, this message translates to:
  /// **'Foto siguiente'**
  String get explorarFotoSiguiente;

  /// No description provided for @explorarSobre.
  ///
  /// In es, this message translates to:
  /// **'Sobre la institución'**
  String get explorarSobre;

  /// No description provided for @explorarLeerMas.
  ///
  /// In es, this message translates to:
  /// **'Leer más'**
  String get explorarLeerMas;

  /// No description provided for @explorarLeerMenos.
  ///
  /// In es, this message translates to:
  /// **'Leer menos'**
  String get explorarLeerMenos;

  /// No description provided for @explorarHorarios.
  ///
  /// In es, this message translates to:
  /// **'Horarios'**
  String get explorarHorarios;

  /// No description provided for @explorarHorarioAtencion.
  ///
  /// In es, this message translates to:
  /// **'Atención al público'**
  String get explorarHorarioAtencion;

  /// No description provided for @explorarHorarioClases.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get explorarHorarioClases;

  /// No description provided for @explorarServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get explorarServicios;

  /// No description provided for @explorarContacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get explorarContacto;

  /// No description provided for @explorarLlamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get explorarLlamar;

  /// No description provided for @explorarWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get explorarWhatsapp;

  /// No description provided for @explorarSitioWeb.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get explorarSitioWeb;

  /// No description provided for @explorarInstagram.
  ///
  /// In es, this message translates to:
  /// **'Instagram'**
  String get explorarInstagram;

  /// No description provided for @explorarFacebook.
  ///
  /// In es, this message translates to:
  /// **'Facebook'**
  String get explorarFacebook;

  /// No description provided for @explorarYoutube.
  ///
  /// In es, this message translates to:
  /// **'YouTube'**
  String get explorarYoutube;

  /// No description provided for @explorarComoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get explorarComoLlegar;

  /// No description provided for @explorarNoSePudoAbrir.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrirlo desde este dispositivo. Probá de nuevo en un rato.'**
  String get explorarNoSePudoAbrir;

  /// No description provided for @explorarVacantes.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get explorarVacantes;

  /// No description provided for @explorarPropuestas.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 propuesta} other{{n} propuestas}}'**
  String explorarPropuestas(int n);

  /// No description provided for @explorarSinVacantesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay vacantes publicadas'**
  String get explorarSinVacantesTitulo;

  /// No description provided for @explorarSinVacantesMensaje.
  ///
  /// In es, this message translates to:
  /// **'Esta institución aún no publicó cursos ni actividades. Podés contactarla para consultar.'**
  String get explorarSinVacantesMensaje;

  /// No description provided for @explorarPedirVacante.
  ///
  /// In es, this message translates to:
  /// **'Pedir vacante'**
  String get explorarPedirVacante;

  /// No description provided for @explorarVerSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Ver solicitud'**
  String get explorarVerSolicitud;

  /// No description provided for @explorarCompleto.
  ///
  /// In es, this message translates to:
  /// **'Completo'**
  String get explorarCompleto;

  /// No description provided for @explorarUltimasVacantes.
  ///
  /// In es, this message translates to:
  /// **'Últimas vacantes'**
  String get explorarUltimasVacantes;

  /// No description provided for @explorarArancel.
  ///
  /// In es, this message translates to:
  /// **'Arancel: {valor}'**
  String explorarArancel(Object valor);

  /// No description provided for @explorarFueraDeEdad.
  ///
  /// In es, this message translates to:
  /// **'No coincide con la edad de {nombre}'**
  String explorarFueraDeEdad(Object nombre);

  /// No description provided for @explorarOcupacion.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get explorarOcupacion;

  /// No description provided for @explorarInstNoEncontradaTitulo.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta institución'**
  String get explorarInstNoEncontradaTitulo;

  /// No description provided for @explorarInstNoEncontradaMensaje.
  ///
  /// In es, this message translates to:
  /// **'Puede que haya dejado de publicar su perfil en ATENA.'**
  String get explorarInstNoEncontradaMensaje;

  /// No description provided for @solAlPedirTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pedir vacante'**
  String get solAlPedirTitulo;

  /// No description provided for @solAlAlumno.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get solAlAlumno;

  /// No description provided for @solAlFueraDeEdadTitulo.
  ///
  /// In es, this message translates to:
  /// **'La edad no coincide'**
  String get solAlFueraDeEdadTitulo;

  /// No description provided for @solAlFueraDeEdadMensaje.
  ///
  /// In es, this message translates to:
  /// **'{nombre} tiene {edad} y esta vacante es para otra edad. Podés enviar la solicitud igual: la institución va a decidir.'**
  String solAlFueraDeEdadMensaje(Object nombre, Object edad);

  /// No description provided for @solAlMensajeLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para la institución (opcional)'**
  String get solAlMensajeLabel;

  /// No description provided for @solAlMensajeAyuda.
  ///
  /// In es, this message translates to:
  /// **'Contales algo del alumno o hacé una consulta.'**
  String get solAlMensajeAyuda;

  /// No description provided for @solAlComoSigue.
  ///
  /// In es, this message translates to:
  /// **'La institución revisa tu pedido y te avisamos por notificación apenas responda.'**
  String get solAlComoSigue;

  /// No description provided for @solAlEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get solAlEnviar;

  /// No description provided for @solAlEnviadaOk.
  ///
  /// In es, this message translates to:
  /// **'¡Solicitud enviada! Te avisamos cuando la institución responda.'**
  String get solAlEnviadaOk;

  /// No description provided for @solAlTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get solAlTitulo;

  /// No description provided for @solAlTabActivas.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get solAlTabActivas;

  /// No description provided for @solAlTabHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get solAlTabHistorial;

  /// No description provided for @solAlActivasVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'No tenés solicitudes activas'**
  String get solAlActivasVacioTitulo;

  /// No description provided for @solAlActivasVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Cuando pidas una vacante, vas a poder seguir cada paso desde acá.'**
  String get solAlActivasVacioMensaje;

  /// No description provided for @solAlHistorialVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu historial está vacío'**
  String get solAlHistorialVacioTitulo;

  /// No description provided for @solAlHistorialVacioMensaje.
  ///
  /// In es, this message translates to:
  /// **'Acá vas a ver las solicitudes que ya se cerraron: no aceptadas, canceladas o dadas de baja.'**
  String get solAlHistorialVacioMensaje;

  /// No description provided for @solAlRespuestaDe.
  ///
  /// In es, this message translates to:
  /// **'Respuesta de {institucion}'**
  String solAlRespuestaDe(Object institucion);

  /// No description provided for @solAlDetalleTitulo.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la solicitud'**
  String get solAlDetalleTitulo;

  /// No description provided for @solAlNoEncontradaTitulo.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta solicitud'**
  String get solAlNoEncontradaTitulo;

  /// No description provided for @solAlNoEncontradaMensaje.
  ///
  /// In es, this message translates to:
  /// **'Puede que se haya eliminado o que corresponda a otro alumno.'**
  String get solAlNoEncontradaMensaje;

  /// No description provided for @solAlEstadoPendienteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud está en revisión'**
  String get solAlEstadoPendienteTitulo;

  /// No description provided for @solAlEstadoPendienteMensaje.
  ///
  /// In es, this message translates to:
  /// **'{institucion} la está revisando. Te vamos a avisar por notificación apenas responda.'**
  String solAlEstadoPendienteMensaje(Object institucion);

  /// No description provided for @solAlEstadoConfirmadaTitulo.
  ///
  /// In es, this message translates to:
  /// **'¡Tenés la vacante!'**
  String get solAlEstadoConfirmadaTitulo;

  /// No description provided for @solAlEstadoConfirmadaMensaje.
  ///
  /// In es, this message translates to:
  /// **'{institucion} confirmó tu lugar. Próximos pasos: revisá Documentos por si te piden papeles y seguí las fechas importantes en el Calendario.'**
  String solAlEstadoConfirmadaMensaje(Object institucion);

  /// No description provided for @solAlEstadoRechazadaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Esta vez no fue posible'**
  String get solAlEstadoRechazadaTitulo;

  /// No description provided for @solAlEstadoRechazadaMensaje.
  ///
  /// In es, this message translates to:
  /// **'{institucion} no pudo aceptar la solicitud. No te desanimes: hay otras instituciones con vacantes disponibles.'**
  String solAlEstadoRechazadaMensaje(Object institucion);

  /// No description provided for @solAlEstadoCanceladaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste esta solicitud'**
  String get solAlEstadoCanceladaTitulo;

  /// No description provided for @solAlEstadoCanceladaMensaje.
  ///
  /// In es, this message translates to:
  /// **'Si cambiás de opinión, podés volver a pedir la vacante mientras haya lugar.'**
  String get solAlEstadoCanceladaMensaje;

  /// No description provided for @solAlEstadoBajaTitulo.
  ///
  /// In es, this message translates to:
  /// **'La institución dio de baja la vacante'**
  String get solAlEstadoBajaTitulo;

  /// No description provided for @solAlEstadoBajaMensaje.
  ///
  /// In es, this message translates to:
  /// **'{institucion} dio de baja esta vacante. Si tenés dudas, comunicate con la institución.'**
  String solAlEstadoBajaMensaje(Object institucion);

  /// No description provided for @solAlLaVacante.
  ///
  /// In es, this message translates to:
  /// **'La vacante'**
  String get solAlLaVacante;

  /// No description provided for @solAlTurnoHorario.
  ///
  /// In es, this message translates to:
  /// **'Turno y horario'**
  String get solAlTurnoHorario;

  /// No description provided for @solAlDias.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get solAlDias;

  /// No description provided for @solAlEdad.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get solAlEdad;

  /// No description provided for @solAlEdadAlumno.
  ///
  /// In es, this message translates to:
  /// **'{nombre} tiene {edad}'**
  String solAlEdadAlumno(Object nombre, Object edad);

  /// No description provided for @solAlArancel.
  ///
  /// In es, this message translates to:
  /// **'Arancel'**
  String get solAlArancel;

  /// No description provided for @solAlTuMensaje.
  ///
  /// In es, this message translates to:
  /// **'Tu mensaje'**
  String get solAlTuMensaje;

  /// No description provided for @solAlSeguimiento.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento'**
  String get solAlSeguimiento;

  /// No description provided for @solAlHitoEnviada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get solAlHitoEnviada;

  /// No description provided for @solAlHitoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Vacante confirmada'**
  String get solAlHitoConfirmada;

  /// No description provided for @solAlHitoRechazada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud no aceptada'**
  String get solAlHitoRechazada;

  /// No description provided for @solAlHitoCancelada.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste la solicitud'**
  String get solAlHitoCancelada;

  /// No description provided for @solAlHitoBaja.
  ///
  /// In es, this message translates to:
  /// **'Baja de la vacante'**
  String get solAlHitoBaja;

  /// No description provided for @solAlCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get solAlCancelar;

  /// No description provided for @solAlCancelarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar esta solicitud?'**
  String get solAlCancelarTitulo;

  /// No description provided for @solAlCancelarMsgPendiente.
  ///
  /// In es, this message translates to:
  /// **'Vas a retirar tu pedido para {oferta} en {institucion}. Si cambiás de opinión, podés volver a pedirla mientras haya lugar.'**
  String solAlCancelarMsgPendiente(Object oferta, Object institucion);

  /// No description provided for @solAlCancelarMsgConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Vas a liberar tu vacante confirmada en {oferta} ({institucion}) y otra familia podrá ocupar ese lugar.'**
  String solAlCancelarMsgConfirmada(Object oferta, Object institucion);

  /// No description provided for @solAlCancelarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get solAlCancelarConfirmar;

  /// No description provided for @solAlMantener.
  ///
  /// In es, this message translates to:
  /// **'No, mantenerla'**
  String get solAlMantener;

  /// No description provided for @solAlCanceladaOk.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste la solicitud.'**
  String get solAlCanceladaOk;

  /// No description provided for @solAlComprobante.
  ///
  /// In es, this message translates to:
  /// **'Descargar comprobante'**
  String get solAlComprobante;

  /// No description provided for @solAlComprobanteError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos generar el comprobante. Probá de nuevo en unos minutos.'**
  String get solAlComprobanteError;

  /// No description provided for @comInstAvisosEnviadosAyuda.
  ///
  /// In es, this message translates to:
  /// **'Llegan como notificación a las familias de los alumnos confirmados.'**
  String get comInstAvisosEnviadosAyuda;

  /// No description provided for @comInstEventoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este evento ya no está disponible'**
  String get comInstEventoNoDisponible;

  /// No description provided for @comInstEventoNoDisponibleMensaje.
  ///
  /// In es, this message translates to:
  /// **'Puede que se haya eliminado. Volvé al calendario para ver los eventos vigentes.'**
  String get comInstEventoNoDisponibleMensaje;

  /// No description provided for @docInstErrorTipo.
  ///
  /// In es, this message translates to:
  /// **'Elegí qué documento necesitás.'**
  String get docInstErrorTipo;

  /// No description provided for @docInstPedidoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este pedido ya no está disponible'**
  String get docInstPedidoNoDisponible;

  /// No description provided for @docInstPedidoNoDisponibleMensaje.
  ///
  /// In es, this message translates to:
  /// **'Puede que la familia haya eliminado su cuenta o que el pedido se haya borrado.'**
  String get docInstPedidoNoDisponibleMensaje;

  /// No description provided for @solInstYaNoExisteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no existe'**
  String get solInstYaNoExisteTitulo;

  /// No description provided for @solInstYaNoExisteMsg.
  ///
  /// In es, this message translates to:
  /// **'Es posible que la familia haya eliminado su cuenta. Si tenía un lugar confirmado, ya quedó libre.'**
  String get solInstYaNoExisteMsg;

  /// No description provided for @solInstYaNoExiste.
  ///
  /// In es, this message translates to:
  /// **'Esa solicitud ya no existe. Es posible que la familia haya eliminado su cuenta.'**
  String get solInstYaNoExiste;

  /// No description provided for @solAlLaInstitucion.
  ///
  /// In es, this message translates to:
  /// **'la institución'**
  String get solAlLaInstitucion;

  /// No description provided for @solAlInstNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Ya no está en ATENA'**
  String get solAlInstNoDisponible;

  /// No description provided for @solAlEstadoBajaSinInstMensaje.
  ///
  /// In es, this message translates to:
  /// **'{institucion} ya no forma parte de ATENA, por eso esta vacante se dio de baja. Podés buscar otras instituciones con lugar.'**
  String solAlEstadoBajaSinInstMensaje(Object institucion);

  /// No description provided for @plnVerResumen.
  ///
  /// In es, this message translates to:
  /// **'Ver resumen'**
  String get plnVerResumen;

  /// No description provided for @perfInstConsejoFotosPrimeras.
  ///
  /// In es, this message translates to:
  /// **'Subí al menos {n} fotos de tus espacios.'**
  String perfInstConsejoFotosPrimeras(int n);

  /// No description provided for @homeStatActiveRequestsN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Solicitud activa} other{Solicitudes activas}}'**
  String homeStatActiveRequestsN(int n);

  /// No description provided for @homeStatUpcomingEventsN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Próximo evento} other{Próximos eventos}}'**
  String homeStatUpcomingEventsN(int n);

  /// No description provided for @homeStatPendingDocsN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Documento por entregar} other{Documentos por entregar}}'**
  String homeStatPendingDocsN(int n);

  /// No description provided for @instStatPendingN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Solicitud pendiente} other{Solicitudes pendientes}}'**
  String instStatPendingN(int n);

  /// No description provided for @instStatStudentsN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Alumno confirmado} other{Alumnos confirmados}}'**
  String instStatStudentsN(int n);

  /// No description provided for @instStatFreeSpotsN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Vacante libre} other{Vacantes libres}}'**
  String instStatFreeSpotsN(int n);

  /// No description provided for @instStatOffersN.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Oferta activa} other{Ofertas activas}}'**
  String instStatOffersN(int n);
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
