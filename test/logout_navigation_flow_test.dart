import 'dart:convert';

import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/alumnos/alumnos_integrados.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/auth/institucion_login_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _owner = 'cuenta-logout';
const _student = 'perfil-alumno-logout';
const _studentDocument = '30111222';
const _institution = 'perfil-institucion-logout';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StorageService.instance.resetCache();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const app.AtenaApp(
        initialLocale: Locale('es'),
        initialThemeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedAccount() async {
    final date = DateTime(2026, 9, 16);
    await CuentaService.actualizarCuenta(
      Cuenta(
        id: _owner,
        email: 'logout@example.invalid',
        passwordHash: base64Encode(utf8.encode('prueba123')),
        perfilesAlumnoIds: const <String>[_student],
        perfilesInstitucionIds: const <String>[_institution],
        recordarme: true,
        creadaEl: date,
        ultimaSesion: date,
      ),
    );
    await CuentaService.actualizarPerfilAlumno(
      PerfilAlumno(
        id: _student,
        cuentaId: _owner,
        ownerAccountId: _owner,
        documento: _studentDocument,
        nombre: 'Ana',
        apellido: 'Logout',
        fechaNacimiento: DateTime(2015),
        email: '',
        telefono: '',
        emancipado: false,
        fechaEmancipacion: null,
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
    await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
      ownerAccountId: _owner,
      perfilId: _student,
      alumno: Alumno(
        documento: _studentDocument,
        nombre: 'Ana',
        apellido: 'Logout',
        fechaNacimiento: DateTime(2015),
        email: '',
        telefono: '',
      ),
    );
    await CuentaService.actualizarPerfilInstitucion(
      PerfilInstitucion(
        id: _institution,
        cuentaId: _owner,
        ownerAccountId: _owner,
        institucionId: _institution,
        nombre: 'Institución Logout',
        emailContacto: 'institucion@example.invalid',
        telefonoContacto: '',
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
    await InstitucionService.upsertInstitucion(
      Institucion(
        id: _institution,
        nombre: 'Institución Logout',
        cuit: '30123456789',
        direccion: 'Calle Prueba 123',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: 'institucion@example.invalid',
        telefono: '',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.primaria,
        tipoPlan: 'prueba',
        estadoPlan: EstadoPlanInstitucion.enPrueba,
        planInicio: DateTime(2026),
        planFin: DateTime(2030),
      ),
    );
    await CuentaService.iniciarSesionAutenticada(_owner, recordarme: true);
  }

  Future<void> expectSessionClosed() async {
    expect(await CuentaService.getSesionCuentaId(), isNull);
    expect(await SessionService.getSession(), isNull);
    expect(await SessionService.getPerfilSeleccionado(), isNull);
    expect(await SessionService.getInstitucionOwnerAccountIdLogueado(), isNull);
  }

  Future<void> openStudentArea(WidgetTester tester) async {
    await seedAccount();
    await CuentaService.activarContextoCuenta(_owner, perfilAlumnoId: _student);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const AlumnoAreaPage(
              documentoAlumno: _studentDocument,
              cuentaId: _owner,
              perfilId: _student,
            ),
          ),
          (_) => false,
        );
    await tester.pumpAndSettle();
  }

  Future<void> logoutStudent(WidgetTester tester) async {
    final context = tester.element(find.byType(AlumnoAreaPage));
    await tester.tap(find.byTooltip(AppLocalizations.of(context).cerrarSesion));
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoLoginPage), findsOneWidget);
    expect(find.byType(AlumnoAreaPage), findsNothing);
    await expectSessionClosed();
  }

  testWidgets('alumno: logout bloquea Back y permite volver al inicio', (
    tester,
  ) async {
    await pumpApp(tester);
    await openStudentArea(tester);
    await logoutStudent(tester);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(AlumnoAreaPage), findsNothing);
    await expectSessionClosed();
  });

  testWidgets('institución: logout bloquea Back y permite volver al inicio', (
    tester,
  ) async {
    await pumpApp(tester);
    await seedAccount();
    await CuentaService.activarContextoInstitucion(_owner, _institution);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const InstitucionMenuPage(
              ownerAccountId: _owner,
              institucionPerfilId: _institution,
              institucionNombre: 'Institución Logout',
            ),
          ),
          (_) => false,
        );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InstitucionMenuPage));
    await tester.tap(
      find.widgetWithText(TextButton, AppLocalizations.of(context).signOut),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InstitucionLoginPage), findsOneWidget);
    expect(find.byType(InstitucionMenuPage), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
      isFalse,
    );
    await expectSessionClosed();

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(InstitucionMenuPage), findsNothing);
    await expectSessionClosed();
  });

  testWidgets('alumno: F5 después del logout no reconstruye el perfil', (
    tester,
  ) async {
    await pumpApp(tester);
    await openStudentArea(tester);
    await logoutStudent(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    StorageService.instance.resetCache();
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(AlumnoAreaPage), findsNothing);
    await expectSessionClosed();
  });
}
