import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'dart:convert';
import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = 'cuenta-identidad';
const institution = 'perfil-institucion-identidad';
const pupilA = 'perfil-alumno-A';
const pupilB = 'perfil-alumno-B';

Future<void> seed({bool remember = false}) async {
  final date = DateTime(2026);
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: owner,
      email: 'identidad@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: [pupilA, pupilB],
      perfilesInstitucionIds: [institution],
      recordarme: remember,
      creadaEl: date,
      ultimaSesion: date,
    ),
  );
  for (final entry in [
    (pupilA, 'Ana', '12345678'),
    (pupilB, 'Beto', '23456789'),
  ]) {
    await CuentaService.actualizarPerfilAlumno(
      PerfilAlumno(
        id: entry.$1,
        cuentaId: owner,
        ownerAccountId: owner,
        documento: entry.$3,
        nombre: entry.$2,
        apellido: 'Prueba',
        fechaNacimiento: DateTime(2015),
        email: '',
        telefono: '',
        emancipado: false,
        fechaEmancipacion: null,
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
  }
  await CuentaService.actualizarPerfilInstitucion(
    PerfilInstitucion(
      id: institution,
      cuentaId: owner,
      ownerAccountId: owner,
      institucionId: institution,
      nombre: 'Institución Identidad',
      emailContacto: 'institucion@example.invalid',
      telefonoContacto: '',
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await CuentaService.loginCuenta(
    email: 'identidad@example.invalid',
    password: 'prueba123',
    recordarme: remember,
  );
  await CuentaService.clearUltimoPerfil(owner);
}

Future<void> restart(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  StorageService.instance.resetCache();
  await app.main();
  await tester.pumpAndSettle();
  // Landing schedules a 900 ms navigation watchdog even after navigating.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> openSelector(WidgetTester tester) async {
  // Reenter the real selector without modifying either session. This isolates
  // profile selection from the different institutional navigation gateways.
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const CuentaHomePage(cuentaId: owner),
    ),
    (_) => false,
  );
  await tester.pumpAndSettle();
  expect(find.byType(CuentaHomePage), findsOneWidget);
}

Future<void> prepare(WidgetTester tester, {bool remember = false}) async {
  await tester.pumpWidget(
    const app.AtenaApp(
      initialLocale: Locale('es'),
      initialThemeMode: ThemeMode.light,
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() => seed(remember: remember));
  await openSelector(tester);
}

Future<void> select(WidgetTester tester, String label) async {
  final tile = find.widgetWithText(ListTile, label);
  expect(tile, findsOneWidget);
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> root(WidgetTester tester) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamedAndRemoveUntil('/', (_) => false);
  await tester.pumpAndSettle();
}

Future<void> snapshot(String label) async {
  final s = await SessionService.getSession();
  // ignore: avoid_print
  print(
    '$label: cuenta=${await CuentaService.getSesionCuentaId()}, v2=${s?.userId}/${s?.role.name}, remember=${s?.rememberMe}, instOwner=${await SessionService.getInstitucionOwnerAccountIdLogueado()}, ultimo=${await CuentaService.getUltimoPerfil(owner)}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({
      'atena_locale': 'es',
      'atena_theme_mode': 'light',
    });
  });
  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  for (final remember in [false, true]) {
    test('S1 limpieza de ambos mecanismos; recordarme=$remember', () async {
      await seed(remember: remember);
      await SessionService.setSession(
        userId: owner,
        role: SessionRole.cuenta,
        rememberMe: remember,
      );
      await SessionService.clearTempIfNeeded();
      await CuentaService.clearSesionTemporalIfNeeded();
      expect(
        await CuentaService.getSesionCuentaId(),
        remember ? owner : isNull,
      );
      expect(
        (await SessionService.getSession())?.userId,
        remember ? owner : isNull,
      );
    });
  }

  testWidgets('S2 selección institucional conserva perfil y propietario', (
    tester,
  ) async {
    await prepare(tester);
    await select(tester, 'Institución Identidad');
    final menu = tester.widget<InstitucionMenuPage>(
      find.byType(InstitucionMenuPage),
    );
    expect(menu.institucionPerfilId, institution);
    expect(menu.ownerAccountId, owner);
    expect((await SessionService.getSession())?.userId, institution);
    expect(await SessionService.getInstitucionOwnerAccountIdLogueado(), owner);
    await snapshot('S2');
  });

  testWidgets('S3 seleccionar institución no debe forzar Recordarme', (
    tester,
  ) async {
    await prepare(tester);
    await select(tester, 'Institución Identidad');
    await snapshot('S3');
    expect((await SessionService.getSession())?.rememberMe, isFalse);
  });

  testWidgets('S4 institución a alumno debe abandonar rol institucional', (
    tester,
  ) async {
    await prepare(tester);
    await select(tester, 'Institución Identidad');
    await openSelector(tester);
    await select(tester, 'Prueba, Ana');
    expect(
      tester.widget<AlumnoAreaPage>(find.byType(AlumnoAreaPage)).perfilId,
      pupilA,
    );
    await snapshot('S4');
    expect((await SessionService.getSession())?.role, SessionRole.cuenta);
    expect(await SessionService.getInstitucionOwnerAccountIdLogueado(), isNull);
  });

  test(
    'S5 logout de cuenta debe cerrar también sesión v2 coexistente',
    () async {
      await seed();
      await SessionService.setSession(
        userId: institution,
        role: SessionRole.institucion,
        rememberMe: true,
      );
      await SessionService.setInstitucionOwnerAccountId(owner);
      await CuentaService.logoutCuenta();
      await snapshot('S5');
      expect(await CuentaService.getSesionCuentaId(), isNull);
      expect(await SessionService.getSession(), isNull);
    },
  );

  testWidgets('S6 institución a alumno a / no recupera institución', (
    tester,
  ) async {
    await prepare(tester);
    await select(tester, 'Institución Identidad');
    await openSelector(tester);
    await select(tester, 'Prueba, Ana');
    await root(tester);
    await snapshot('S6');
    expect(find.byType(InstitucionMenuPage), findsNothing);
    expect(find.byType(CuentaHomePage), findsOneWidget);
  });

  testWidgets('S7 alumno a institución a / usa institución elegida', (
    tester,
  ) async {
    await prepare(tester);
    await select(tester, 'Prueba, Ana');
    await openSelector(tester);
    await select(tester, 'Institución Identidad');
    await root(tester);
    final menu = tester.widget<InstitucionMenuPage>(
      find.byType(InstitucionMenuPage),
    );
    expect(menu.institucionPerfilId, institution);
    expect(menu.ownerAccountId, owner);
  });

  testWidgets(
    'S8 reinicio tras institución a alumno sin Recordarme limpia todo',
    (tester) async {
      await prepare(tester);
      await select(tester, 'Institución Identidad');
      await openSelector(tester);
      await select(tester, 'Prueba, Ana');
      await restart(tester);
      await snapshot('S8');
      expect(await CuentaService.getSesionCuentaId(), isNull);
      expect(await SessionService.getSession(), isNull);
      expect(find.byType(InstitucionMenuPage), findsNothing);
    },
  );

  testWidgets(
    'S9 alumno A a B conserva identidad de pantalla y último perfil',
    (tester) async {
      await prepare(tester, remember: true);
      await select(tester, 'Prueba, Ana');
      expect(
        tester.widget<AlumnoAreaPage>(find.byType(AlumnoAreaPage)).perfilId,
        pupilA,
      );
      await openSelector(tester);
      await select(tester, 'Prueba, Beto');
      final area = tester.widget<AlumnoAreaPage>(find.byType(AlumnoAreaPage));
      expect(area.perfilId, pupilB);
      expect(area.cuentaId, owner);
      expect(await CuentaService.getUltimoPerfil(owner), 'A|$pupilB');
      expect((await SessionService.getSession())?.role, SessionRole.cuenta);
      expect((await SessionService.getSession())?.userId, owner);
      expect(await SessionService.getPerfilSeleccionado(), '23456789');
    },
  );

  for (final remember in [false, true]) {
    testWidgets('S11 reinicio de alumno; Recordarme=$remember', (tester) async {
      await prepare(tester, remember: remember);
      await select(tester, 'Prueba, Ana');
      await restart(tester);
      expect(
        await CuentaService.getSesionCuentaId(),
        remember ? owner : isNull,
      );
      expect(
        (await SessionService.getSession())?.userId,
        remember ? owner : isNull,
      );
      expect(
        find.byType(AlumnoAreaPage),
        remember ? findsOneWidget : findsNothing,
      );
      expect(find.byType(InstitucionMenuPage), findsNothing);
    });
  }

  testWidgets(
    'S10 bootstrap prioriza v2 aunque cuenta antigua contradiga owner',
    (tester) async {
      await tester.runAsync(() => seed(remember: true));
      await CuentaService.setSesionCuentaId('otra-cuenta', recordarme: true);
      await SessionService.setSession(
        userId: institution,
        role: SessionRole.institucion,
        rememberMe: true,
      );
      await SessionService.setInstitucionOwnerAccountId(owner);
      await restart(tester);
      final menu = tester.widget<InstitucionMenuPage>(
        find.byType(InstitucionMenuPage),
      );
      expect(menu.institucionPerfilId, institution);
      expect(menu.ownerAccountId, owner);
    },
  );

  for (final remember in [false, true]) {
    testWidgets('S12 institución y reinicio: Recordarme=$remember', (
      tester,
    ) async {
      await prepare(tester, remember: remember);
      await select(tester, 'Institución Identidad');
      await restart(tester);
      expect(
        (await SessionService.getSession())?.userId,
        remember ? institution : isNull,
      );
      expect(
        await CuentaService.getSesionCuentaId(),
        remember ? owner : isNull,
      );
      expect(
        find.byType(InstitucionMenuPage),
        remember ? findsOneWidget : findsNothing,
      );
      if (remember) {
        final menu = tester.widget<InstitucionMenuPage>(
          find.byType(InstitucionMenuPage),
        );
        expect(menu.ownerAccountId, owner);
        expect(menu.institucionPerfilId, institution);
      }
    });
    test('S13 cambios repetidos conservan Recordarme=$remember', () async {
      await seed(remember: remember);
      for (var i = 0; i < 3; i++) {
        await CuentaService.activarContextoInstitucion(owner, institution);
        expect((await SessionService.getSession())?.rememberMe, remember);
        expect(await CuentaService.getUltimoPerfil(owner), 'I|$institution');
        await CuentaService.activarContextoCuenta(
          owner,
          perfilAlumnoId: pupilA,
        );
        expect((await SessionService.getSession())?.rememberMe, remember);
        expect((await SessionService.getSession())?.role, SessionRole.cuenta);
        expect(
          await SessionService.getInstitucionOwnerAccountIdLogueado(),
          isNull,
        );
        expect(
          (await CuentaService.getCuentaById(owner))?.recordarme,
          remember,
        );
      }
    });
  }
  testWidgets('S14 institución a alumno persistente y reinicio', (
    tester,
  ) async {
    await prepare(tester, remember: true);
    await select(tester, 'Institución Identidad');
    await openSelector(tester);
    await select(tester, 'Prueba, Ana');
    await restart(tester);
    expect((await SessionService.getSession())?.role, SessionRole.cuenta);
    expect((await SessionService.getSession())?.userId, owner);
    expect(await CuentaService.getUltimoPerfil(owner), 'A|$pupilA');
    expect(find.byType(InstitucionMenuPage), findsNothing);
  });
  for (final alumno in [false, true]) {
    test('S15 logout completo desde alumno=$alumno conserva datos', () async {
      await seed(remember: true);
      await CuentaService.activarContextoInstitucion(owner, institution);
      if (alumno) {
        await CuentaService.activarContextoCuenta(
          owner,
          perfilAlumnoId: pupilA,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      await CuentaService.logoutCuenta();
      expect(await CuentaService.getSesionCuentaId(), isNull);
      expect(await SessionService.getSession(), isNull);
      expect(await SessionService.getPerfilSeleccionado(), isNull);
      expect(
        await SessionService.getInstitucionOwnerAccountIdLogueado(),
        isNull,
      );
      for (final entry in before.entries) {
        if (entry.key.startsWith('v2_session_') ||
            entry.key == 'v2_perfil_seleccionado_dni' ||
            entry.key.startsWith('sesion_cuenta')) {
          expect(prefs.containsKey(entry.key), isFalse, reason: entry.key);
        } else {
          expect(prefs.get(entry.key), entry.value, reason: entry.key);
        }
      }
    });
  }
  for (final missing in [false, true]) {
    test(
      'S16 rechaza perfil con propietario ajeno o ausente: missing=$missing',
      () async {
        await seed();
        if (!missing) {
          final date = DateTime(2026);
          await CuentaService.actualizarCuenta(
            Cuenta(
              id: 'cuenta-ajena',
              email: 'ajena@example.invalid',
              passwordHash: '',
              perfilesAlumnoIds: [],
              perfilesInstitucionIds: [institution],
              recordarme: false,
              creadaEl: date,
              ultimaSesion: date,
            ),
          );
        }
        final perfil = await CuentaService.getPerfilInstitucionById(
          institution,
        );
        final prefs = await SharedPreferences.getInstance();
        // Corrupt the persisted relationship deliberately through its real writer.
        await CuentaService.actualizarPerfilInstitucion(
          PerfilInstitucion(
            id: institution,
            cuentaId: missing ? 'cuenta-inexistente' : 'cuenta-ajena',
            ownerAccountId: missing ? 'cuenta-inexistente' : 'cuenta-ajena',
            institucionId: institution,
            nombre: perfil!.nombre,
            emailContacto: '',
            telefonoContacto: '',
            prefs: PreferenciasPerfil.defaults(),
          ),
        );
        final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        await expectLater(
          CuentaService.activarContextoInstitucion(owner, institution),
          throwsStateError,
        );
        expect((await SessionService.getSession())?.role, SessionRole.cuenta);
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
      },
    );
  }
  testWidgets('S17 router no combina cuenta antigua con perfil v2', (
    tester,
  ) async {
    await prepare(tester, remember: true);
    await CuentaService.activarContextoInstitucion(owner, institution);
    await CuentaService.setSesionCuentaId('otra-cuenta', recordarme: true);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamedAndRemoveUntil('/ruta-inexistente-identidad', (_) => false);
    await tester.pumpAndSettle();
    final menu = tester.widget<InstitucionMenuPage>(
      find.byType(InstitucionMenuPage),
    );
    expect(menu.ownerAccountId, owner);
    expect(menu.institucionPerfilId, institution);
  });
  testWidgets('S18 Landing distingue cuenta de perfil institucional', (
    tester,
  ) async {
    await prepare(tester, remember: true);
    await CuentaService.activarContextoInstitucion(owner, institution);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => LandingPage(
              locale: const Locale('es'),
              themeMode: ThemeMode.light,
              onLocaleChanged: (_) async {},
              onThemeModeChanged: (_) async {},
            ),
          ),
          (_) => false,
        );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final menu = tester.widget<InstitucionMenuPage>(
      find.byType(InstitucionMenuPage),
    );
    expect(menu.ownerAccountId, owner);
    expect(menu.institucionPerfilId, institution);
  });

  testWidgets(
    'S19 volver al selector con solo instituciones no reactiva el contexto',
    (tester) async {
      await prepare(tester, remember: true);
      final cuenta = (await CuentaService.getCuentaById(owner))!;
      cuenta.perfilesAlumnoIds.clear();
      await CuentaService.actualizarCuenta(cuenta);
      await CuentaService.activarContextoInstitucion(owner, institution);
      await openSelector(tester);
      expect((await SessionService.getSession())?.role, SessionRole.cuenta);
      expect(
        await SessionService.getInstitucionOwnerAccountIdLogueado(),
        isNull,
      );
      expect(
        find.widgetWithText(ListTile, 'Institución Identidad'),
        findsOneWidget,
      );
      await root(tester);
      expect(find.byType(InstitucionMenuPage), findsNothing);
    },
  );

  for (final scenario in ['contradictorio', 'consistente', 'sin sesión']) {
    testWidgets('S20 área institucional: $scenario', (tester) async {
      await prepare(tester, remember: true);
      await CuentaService.activarContextoInstitucion(owner, institution);
      if (scenario == 'sin sesión') await CuentaService.logoutCuenta();
      String? areaId;
      String? operatorId;
      if (scenario != 'sin sesión') {
        final area = (await InstitucionAreasService.instance.resolverYGuardar(
          institucionId: institution,
          tipo: TipoAreaOperativa.curricular,
          claveOrigen: 'primaria',
          nombre: 'Primaria',
        ))!;
        final operator = await InstitucionOperadoresService.instance.crearLocal(
          institucionId: institution,
          nombreVisible: 'Operador válido',
        );
        await InstitucionOperadoresService.instance.asignarArea(
          institucionId: institution,
          operadorId: operator.id,
          areaId: area.id,
        );
        await InstitucionContextoOperativoService.instance
            .activarContextoOperativo(
              institucionId: institution,
              ownerAccountId: owner,
              areaId: area.id,
              operadorId: operator.id,
            );
        areaId = area.id;
        operatorId = operator.id;
      }
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final domain = Institucion(
        id: institution,
        nombre: 'Institución para área',
        cuit: 'cuit-area',
        direccion: 'Dirección',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: 'area@example.invalid',
        telefono: '',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.primaria,
        tipoPlan: 'prueba',
        estadoPlan: EstadoPlanInstitucion.enPrueba,
        planInicio: DateTime(2026),
        planFin: DateTime(2030),
      );
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushAndRemoveUntil(
            MaterialPageRoute<void>(
              settings: RouteSettings(
                arguments: {
                  'ownerAccountId': scenario == 'contradictorio'
                      ? 'cuenta-B-contradictoria'
                      : owner,
                },
              ),
              builder: (_) => InstitucionAreaPage(
                institucionId: institution,
                institucionNombre: domain.nombre,
                institucion: domain,
                actividadKey: 'curricular',
                actividadLabel: 'Primaria',
                workProfileId: 'direccion',
                areaId: areaId,
                operatorId: operatorId,
              ),
            ),
            (_) => false,
          );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(InstitucionAreaPage));
      final error = AppLocalizations.of(context).sessionInvalidPleaseLogin;
      expect(
        find.text(error),
        scenario == 'consistente' ? findsNothing : findsOneWidget,
      );
      if (scenario == 'consistente') {
        expect(find.text(domain.nombre), findsWidgets);
      }
      expect(
        (await SessionService.getSession())?.userId,
        scenario == 'sin sesión' ? isNull : institution,
      );
      expect(
        await SessionService.getInstitucionOwnerAccountIdLogueado(),
        scenario == 'sin sesión' ? isNull : owner,
      );
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    });
  }
}
