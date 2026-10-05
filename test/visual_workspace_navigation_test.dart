import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/auth/institucion_login_page.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/ui/atena_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });

  for (final scenario in [
    (size: const Size(360, 800), scale: 1.0, brightness: Brightness.light),
    (size: const Size(320, 640), scale: 2.0, brightness: Brightness.dark),
    (size: const Size(1440, 900), scale: 1.0, brightness: Brightness.light),
  ]) {
    testWidgets('portada navegable ${scenario.size} texto ${scenario.scale}', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AtenaTheme.build(scenario.brightness),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: child!,
          ),
          home: LandingPage(
            locale: const Locale('es'),
            themeMode: ThemeMode.system,
            onLocaleChanged: (_) async {},
            onThemeModeChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final student = find.text('Alumnos');
      await tester.scrollUntilVisible(
        student,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(student), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(student);
      await tester.pumpAndSettle();
      expect(find.byType(AlumnoLoginPage), findsOneWidget);
      // Only assess the renewed surface's layout; preserve the login contract.
      Navigator.of(tester.element(find.byType(AlumnoLoginPage))).pop();
      await tester.pumpAndSettle();
      final institution = find.text('Instituciones');
      await tester.scrollUntilVisible(
        institution,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(institution),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(institution);
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionLoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tarjeta bloqueada no ejecuta acciones y expone su estado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtenaTheme.build(Brightness.dark),
        home: const Scaffold(
          body: AtenaActionCard(
            icon: Icons.school,
            title: 'Vacantes',
            subtitle: 'Acceso no habilitado',
            onTap: null,
            locked: true,
          ),
        ),
      ),
    );
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.onTap, isNull);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
