import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/screens/auth/alumno_forgot_password_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'atena_locale': 'es',
      'atena_theme_mode': 'light',
    });
    StorageService.instance.resetCache();
  });

  Future<void> arrancar(WidgetTester tester) async {
    // runApp agenda un warm-up frame. Sin este primer frame, entre tests
    // puede reutilizar el timestamp del reloj simulado del caso anterior.
    await tester.pumpWidget(const SizedBox.shrink());
    await app.main();
    await tester.pumpAndSettle();
  }

  Future<void> guardarCuenta() async {
    final fecha = DateTime(2026, 9, 9);
    final cuenta = Cuenta(
      id: 'cuenta-prueba',
      email: 'prueba@example.com',
      passwordHash: 'solo-pruebas',
      perfilesAlumnoIds: [],
      perfilesInstitucionIds: [],
      creadaEl: fecha,
      ultimaSesion: fecha,
    );
    await CuentaService.actualizarCuenta(cuenta);
  }

  testWidgets('El main real abre la portada y carga idioma y tema', (
    tester,
  ) async {
    await arrancar(tester);

    expect(find.byType(LandingPage), findsOneWidget);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('es'));
    expect(materialApp.themeMode, ThemeMode.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El arranque limpia las dos sesiones temporales anteriores', (
    tester,
  ) async {
    await guardarCuenta();
    await CuentaService.setSesionCuentaId('cuenta-prueba', recordarme: false);
    await SessionService.setSession(
      userId: 'cuenta-prueba',
      role: SessionRole.cuenta,
      rememberMe: false,
    );

    await arrancar(tester);

    expect(await SessionService.getSession(), isNull);
    expect(await CuentaService.getSesionCuentaId(), isNull);
    expect(find.byType(LandingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recordarme abre el selector de perfiles de la cuenta', (
    tester,
  ) async {
    await guardarCuenta();
    await SessionService.setSession(
      userId: 'cuenta-prueba',
      role: SessionRole.cuenta,
      rememberMe: true,
    );

    await arrancar(tester);

    final home = tester.widget<CuentaHomePage>(find.byType(CuentaHomePage));
    expect(home.cuentaId, 'cuenta-prueba');
    expect((await SessionService.getSession())?.rememberMe, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Institución recibe su perfil y owner explícitos de sesión', (
    tester,
  ) async {
    await SessionService.setSession(
      userId: 'institucion-prueba',
      role: SessionRole.institucion,
      rememberMe: true,
    );
    await SessionService.setInstitucionOwnerAccountId('owner-prueba');

    await arrancar(tester);

    // Se comprueba el destino y la identidad, no la carga del dominio.
    final menu = tester.widget<InstitucionMenuPage>(
      find.byType(InstitucionMenuPage),
    );
    expect(menu.institucionPerfilId, 'institucion-prueba');
    expect(menu.ownerAccountId, 'owner-prueba');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Institución sin owner explícito vuelve a la portada', (
    tester,
  ) async {
    await SessionService.setSession(
      userId: 'institucion-prueba',
      role: SessionRole.institucion,
      rememberMe: true,
    );

    await arrancar(tester);

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(InstitucionMenuPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Volver a / conserva una sesión temporal creada durante el uso', (
    tester,
  ) async {
    await arrancar(tester);
    await guardarCuenta();
    await SessionService.setSession(
      userId: 'cuenta-prueba',
      role: SessionRole.cuenta,
      rememberMe: false,
    );

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamedAndRemoveUntil('/', (_) => false);
    await tester.pumpAndSettle();

    expect(find.byType(CuentaHomePage), findsOneWidget);
    expect((await SessionService.getSession())?.userId, 'cuenta-prueba');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Las rutas existentes conservan sus argumentos', (tester) async {
    await arrancar(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed(
      '/alumno_forgot_password',
      arguments: {'initialEmail': 'semilla@example.com'},
    );
    await tester.pumpAndSettle();

    final pagina = tester.widget<AlumnoForgotPasswordPage>(
      find.byType(AlumnoForgotPasswordPage),
    );
    expect(pagina.initialEmail, 'semilla@example.com');
    expect(tester.takeException(), isNull);
  });
}
