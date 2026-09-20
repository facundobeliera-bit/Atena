import 'package:atena_app/services/alumno_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/main.dart' as app;
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:atena_app/screens/auth/alumno_forgot_password_page.dart';
import 'package:atena_app/screens/auth/institucion_forgot_password_page.dart';

// Synthetic credentials only. Assertions expose booleans, never credentials.
const original = 'Synthetic-original-492';
const replacement = 'Synthetic-replacement-783';
const emailA = 'security-a@example.test';
const emailB = 'security-b@example.test';

Future<String> register(bool institution, String email) async {
  if (institution) {
    return (await InstitucionService.registrarInstitucion(
      email: email,
      passwordHash: original,
      nombre: 'Synthetic institution',
    )).institucionId;
  }
  return (await CuentaService.registrarCuenta(
    email: email,
    password: original,
  )).id;
}

Future<bool> login(bool institution, String email, String password) async {
  if (institution) {
    return await InstitucionService.loginInstitucion(
          email: email,
          passwordHash: password,
        ) !=
        null;
  }
  try {
    await CuentaService.loginCuenta(email: email, password: password);
    return true;
  } catch (_) {
    return false;
  }
}

Future<Map<String, Object?>> snapshot() async {
  final p = await SharedPreferences.getInstance();
  return {for (final k in p.getKeys()) k: p.get(k)};
}

Future<bool> recover(
  WidgetTester tester,
  bool institution,
  String email, {
  String next = replacement,
}) async {
  final before = await snapshot();
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: nav,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('Login')),
    ),
  );
  nav.currentState!.push(
    MaterialPageRoute<String>(
      builder: (_) => institution
          ? InstitucionForgotPasswordPage(initialEmail: email)
          : AlumnoForgotPasswordPage(initialEmail: email),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(TextFormField), findsNothing);
  expect(find.byType(TextField), findsNothing);
  expect(find.byIcon(Icons.save), findsNothing);
  expect(
    find.text(
      'La recuperación de contraseña todavía no está disponible en esta versión.',
    ),
    findsOneWidget,
  );
  expect(find.textContaining(email), findsNothing);
  expect(find.textContaining(next), findsNothing);
  expect(
    await snapshot(),
    before,
    reason:
        'Recovery no debe modificar registros, indices, owner ni ultimaSesion',
  );
  expect(await CuentaService.getSesionCuentaId(), isNull);
  expect(await SessionService.getSession(), isNull);
  await tester.tap(find.text('Volver al ingreso'));
  await tester.pumpAndSettle();
  expect(find.text('Login'), findsOneWidget);
  expect(await snapshot(), before);
  expect(tester.takeException(), isNull);
  return false; // No recovery action exists; navigating back is not success.
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });
  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });
  for (final institution in [false, true]) {
    final kind = institution ? 'institucion' : 'cuenta';
    for (final scenario in [
      'block',
      'new-login',
      'old-login',
      'missing',
      'isolation',
      'repeat',
      'enumeration',
    ]) {
      testWidgets('P0 / $kind / $scenario', (tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final idA = (await tester.runAsync(
          () => register(institution, emailA),
        ))!;
        // Real registration generates IDs from wall time; separate fixtures.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        final idB = (await tester.runAsync(
          () => register(institution, emailB),
        ))!;
        Future<bool> loginWithRealClock(String email, String password) async =>
            await tester.runAsync(() => login(institution, email, password)) ??
            false;
        expect(
          idA != idB,
          isTrue,
          reason: 'Fixtures A y B deben ser distintas',
        );
        await CuentaService.logoutCuenta();
        final before = await snapshot();
        final success = await recover(
          tester,
          institution,
          scenario == 'missing' ? 'absent@example.test' : emailA,
        );
        switch (scenario) {
          case 'block':
            expect(
              success,
              isFalse,
              reason: 'Sin factor verificado no debe completarse el reset',
            );
          case 'new-login':
            expect(
              await loginWithRealClock(emailA, replacement),
              isFalse,
              reason: 'No debe funcionar la clave impuesta sin verificacion',
            );
          case 'old-login':
            expect(
              await loginWithRealClock(emailA, original),
              isTrue,
              reason:
                  'El intento no autorizado no debe invalidar la credencial original',
            );
          case 'missing':
            expect(success, isFalse);
            expect(
              (await snapshot()).toString() == before.toString(),
              isTrue,
              reason: 'No debe crear registros para un email inexistente',
            );
          case 'isolation':
            expect(await loginWithRealClock(emailB, original), isTrue);
            expect(await loginWithRealClock(emailB, replacement), isFalse);
          case 'repeat':
            final again = await recover(
              tester,
              institution,
              emailA,
              next: 'Synthetic-third-294',
            );
            expect(
              success || again,
              isFalse,
              reason: 'Repetir no debe permitir recuperacion sin factor',
            );
          case 'enumeration':
            final absent = await recover(
              tester,
              institution,
              'absent@example.test',
            );
            expect(
              success == absent,
              isTrue,
              reason: 'La respuesta visible no debe revelar existencia',
            );
        }
      });
    }
    test('P1-B / $kind / almacenamiento no reversible', () async {
      final id = await register(institution, emailA);
      final p = await SharedPreferences.getInstance();
      final key = institution ? 'atena_inst_auth_by_id_$id' : 'cuenta_$id';
      final m = jsonDecode(p.getString(key)!) as Map;
      final value = m['passwordHash'] as String;
      bool reversible = value == original;
      try {
        reversible = reversible || utf8.decode(base64Decode(value)) == original;
      } catch (_) {}
      expect(
        reversible,
        isFalse,
        reason:
            'Una credencial persistida no debe ser texto plano ni Base64 reversible',
      );
    });
    test('P1-D / $kind / cambio invalida sesion persistente', () async {
      final id = await register(institution, emailA);
      await CuentaService.loginCuenta(
        email: emailA,
        password: original,
        recordarme: true,
      );
      if (institution) {
        final profile = await CuentaService.crearPerfilInstitucion(
          cuentaId: id,
          nombre: 'Institución de prueba',
          emailContacto: emailA,
          telefonoContacto: '',
        );
        await CuentaService.activarContextoInstitucion(id, profile.id);
        final session = await SessionService.getSession();
        expect(session?.role, SessionRole.institucion);
        expect(session?.userId, profile.id);
        expect(await SessionService.getInstitucionOwnerAccountIdLogueado(), id);
      } else {
        expect((await SessionService.getSession())?.role, SessionRole.cuenta);
      }
      expect(await CuentaService.getSesionCuentaId(), id);
      if (institution) {
        await InstitucionService.actualizarCredenciales(
          institucionId: id,
          nuevoPassword: replacement,
        );
      } else {
        await CuentaService.actualizarPasswordCuenta(
          cuentaId: id,
          nuevoPassword: replacement,
        );
      }
      StorageService.instance.resetCache();
      expect(
        await CuentaService.getSesionCuentaId() == null &&
            await SessionService.getSession() == null,
        isTrue,
        reason: 'La sesion previa al cambio debe invalidarse',
      );
      if (institution) {
        expect(
          await SessionService.getInstitucionOwnerAccountIdLogueado(),
          isNull,
        );
        expect(await SessionService.getPerfilSeleccionado(), isNull);
      }
    });
  }
  for (final institution in [false, true]) {
    final role = institution ? 'institución' : 'cuenta';
    testWidgets('P1-D / reinicio de $role no restaura áreas', (tester) async {
      await tester.runAsync(() async {
        final id = await register(institution, emailA);
        await CuentaService.loginCuenta(
          email: emailA,
          password: original,
          recordarme: true,
        );
        if (institution) {
          final profile = await CuentaService.crearPerfilInstitucion(
            cuentaId: id,
            nombre: 'Institución de prueba',
            emailContacto: emailA,
            telefonoContacto: '',
          );
          await CuentaService.activarContextoInstitucion(id, profile.id);
          await InstitucionService.actualizarCredenciales(
            institucionId: id,
            nuevoPassword: replacement,
          );
        } else {
          await CuentaService.actualizarPasswordCuenta(
            cuentaId: id,
            nuevoPassword: replacement,
          );
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
      StorageService.instance.resetCache();
      await app.main();
      await tester.pumpAndSettle();
      expect(find.byType(LandingPage), findsOneWidget);
      expect(await SessionService.getSession(), isNull);
      expect(await CuentaService.getSesionCuentaId(), isNull);
      expect(tester.takeException(), isNull);
    });
  }

  test('P1-D / cambiar otra credencial conserva la sesión actual', () async {
    final first = await register(false, emailA);
    final second = await register(false, emailB);
    await CuentaService.loginCuenta(
      email: emailA,
      password: original,
      recordarme: true,
    );
    await CuentaService.actualizarPasswordCuenta(
      cuentaId: second,
      nuevoPassword: replacement,
    );
    expect(await CuentaService.getSesionCuentaId(), first);
    expect((await SessionService.getSession())?.userId, first);
  });

  test('P0 / legacy reset deshabilitado sin mutaciones', () async {
    final service = AlumnoService.instance;
    await service.registrarAlumnoUsuario(
      dni: 'synthetic-document',
      email: emailA,
      passwordHash: original,
    );
    final before = await snapshot();
    for (final email in [emailA, 'absent@example.test']) {
      await expectLater(
        service.resetPasswordPorEmailPrototipo(email),
        throwsUnsupportedError,
      );
      expect(await snapshot(), before);
    }
    expect(
      await service.loginAlumno(email: emailA, passwordHash: original) != null,
      isTrue,
    );
  });
}
