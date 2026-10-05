import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/auth/institucion_registro_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(InstitucionRegistroDraft draft) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: InstitucionPlanPage(draft: draft),
  );

  InstitucionRegistroDraft draft(String email, String password) =>
      InstitucionRegistroDraft(
        nombre: 'Escuela Ficticia Municipal',
        cuit: '30123456789',
        direccion: 'Calle Ejemplo 123',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: email,
        telefono: '1122334455',
        pass: password,
        tipo: TipoInstitucion.otra,
        nivelesSeleccionados: [NivelCurricular.primaria],
        bloquesSeleccionados: const [],
      );

  Future<void> confirm(
    WidgetTester tester,
    String email, {
    bool success = true,
  }) async {
    // The action is at the end of a long, lazily built plan list.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byIcon(Icons.check),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    final button = find
        .byWidgetPredicate((widget) => widget is ElevatedButton)
        .last;
    await tester.ensureVisible(button);
    await tester.runAsync(() async {
      tester.widget<ElevatedButton>(button).onPressed!();
      for (var i = 0; i < (success ? 60 : 20); i++) {
        final id = await InstitucionService.getInstitucionIdByEmail(email);
        if (success &&
            id != null &&
            await InstitucionService.getInstitucionById(id) != null) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('datos del registro pasan al plan sin crear credenciales', (
    tester,
  ) async {
    const email = 'escuela-formulario@atena.test';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InstitucionRegistroPage(),
      ),
    );
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(9));
    for (final value in <String>[
      'Escuela Ficticia Municipal',
      '30123456789',
      'Calle Ejemplo 123',
      'Argentina',
      'Buenos Aires',
      'La Plata',
      email,
      '1122334455',
      'PruebaDemo2026!',
    ].indexed) {
      await tester.enterText(fields.at(value.$1), value.$2);
    }
    final continueButton = find.text('Continuar al plan');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InstitucionPlanPage), findsOneWidget);
    expect(await InstitucionService.getInstitucionIdByEmail(email), isNull);
  });

  testWidgets('registro, plan, logout y nuevo ingreso conservan perfil', (
    tester,
  ) async {
    const email = 'escuela-nueva@atena.test';
    const password = 'PruebaDemo2026!';
    await tester.pumpWidget(app(draft(email, password)));
    await tester.pumpAndSettle();
    await confirm(tester, email);

    expect(find.byType(InstitucionMenuPage), findsOneWidget);
    await tester.runAsync(() async {
      final id = await InstitucionService.getInstitucionIdByEmail(email);
      expect(id, isNotNull);
      final owner = await CuentaService.getCuentaById(id!);
      expect(owner?.perfilesInstitucionIds, [id]);
      expect((await CuentaService.getPerfilInstitucionById(id))?.cuentaId, id);
      expect(await InstitucionService.getInstitucionById(id), isNotNull);

      await CuentaService.logoutCuenta();
      await SessionService.logout();
      StorageService.instance.resetCache();
      final login = await InstitucionService.loginInstitucion(
        email: email,
        passwordHash: password,
      );
      expect(login?.institucionId, id);
      expect((await CuentaService.getCuentaById(id))?.perfilesInstitucionIds, [
        id,
      ]);
      expect(await InstitucionService.getInstitucionIdByEmail(email), id);
    });
  });

  testWidgets(
    'registro parcial se completa sin duplicar ni sustituir identidad',
    (tester) async {
      const email = 'escuela-parcial@atena.test';
      const password = 'PruebaDemo2026!';
      final auth = (await tester.runAsync(
        () => InstitucionService.registrarInstitucion(
          email: email,
          passwordHash: password,
          nombre: 'Escuela Ficticia Municipal',
        ),
      ))!;
      expect(
        (await CuentaService.getCuentaById(
          auth.institucionId,
        ))?.perfilesInstitucionIds,
        isEmpty,
      );

      await tester.pumpWidget(app(draft(email, password)));
      await tester.pumpAndSettle();
      await confirm(tester, email);

      expect(find.byType(InstitucionMenuPage), findsOneWidget);
      expect(
        await InstitucionService.getInstitucionIdByEmail(email),
        auth.institucionId,
      );
      expect(
        (await CuentaService.getCuentaById(
          auth.institucionId,
        ))?.perfilesInstitucionIds,
        [auth.institucionId],
      );
    },
  );

  testWidgets('credencial ajena no completa un registro parcial', (
    tester,
  ) async {
    const email = 'escuela-protegida@atena.test';
    const password = 'PruebaDemo2026!';
    final auth = (await tester.runAsync(
      () => InstitucionService.registrarInstitucion(
        email: email,
        passwordHash: password,
        nombre: 'Escuela Ficticia Municipal',
      ),
    ))!;
    await tester.pumpWidget(app(draft(email, 'OtraClave2026!')));
    await tester.pumpAndSettle();
    await confirm(tester, email, success: false);
    expect(find.byType(InstitucionMenuPage), findsNothing);
    expect(
      (await CuentaService.getCuentaById(
        auth.institucionId,
      ))?.perfilesInstitucionIds,
      isEmpty,
    );
    expect(
      await InstitucionService.getInstitucionIdByEmail(email),
      auth.institucionId,
    );
  });
}
