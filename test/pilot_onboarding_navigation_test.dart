import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/auth/alumno_forgot_password_page.dart';
import 'package:atena_app/screens/auth/alumno_registro_page.dart';
import 'package:atena_app/screens/auth/institucion_forgot_password_page.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp(Widget home) {
    return MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/direct',
      onGenerateInitialRoutes: (_) => <Route<dynamic>>[
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/direct'),
          builder: (_) => home,
        ),
      ],
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LandingPage(
              locale: const Locale('es'),
              themeMode: ThemeMode.light,
              onLocaleChanged: (_) async {},
              onThemeModeChanged: (_) async {},
            ),
          );
        }
        return null;
      },
    );
  }

  group('onboarding directo', () {
    for (final entry in <({String name, Widget page})>[
      (name: 'registro de alumno', page: const AlumnoRegistroPage()),
      (name: 'recuperación de alumno', page: const AlumnoForgotPasswordPage()),
      (
        name: 'recuperación institucional',
        page: const InstitucionForgotPasswordPage(),
      ),
    ]) {
      testWidgets('${entry.name} permite volver al inicio sin ruta previa', (
        tester,
      ) async {
        await tester.pumpWidget(testApp(entry.page));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(LandingPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('plan nuevo pide una actividad sin mostrar un error falso', (
    tester,
  ) async {
    const draft = InstitucionRegistroDraft(
      nombre: 'Instituto Demo',
      cuit: '30123456789',
      direccion: 'Calle Demo 123',
      pais: 'Argentina',
      provincia: 'Buenos Aires',
      ciudad: 'La Plata',
      modalidad: ModalidadCursado.presencial,
      email: 'instituto.demo@atena.test',
      telefono: '1122334455',
      pass: 'demo1234',
      tipo: TipoInstitucion.otra,
      nivelesSeleccionados: <NivelCurricular>[],
      bloquesSeleccionados: <BloqueExtracurricular>[],
    );

    await tester.pumpWidget(testApp(const InstitucionPlanPage(draft: draft)));
    await tester.pumpAndSettle();

    expect(find.text('Seleccioná al menos 1 actividad.'), findsWidgets);
    expect(find.text('Error.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
