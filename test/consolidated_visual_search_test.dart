import 'package:atena_app/main.dart' as app;
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/extracurriculares/actividad_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/services/alumno_instituciones_search_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/ui/atena_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'education_operational_flow_test.dart' as fixture;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
    AlumnoInstitucionesSearchService.ultimaBusqueda = null;
  });
  testWidgets(
    'tema del arranque real recorre claro, oscuro y sistema sin crear sesión',
    (tester) async {
      await tester.pumpWidget(
        const app.AtenaApp(
          initialLocale: Locale('es'),
          initialThemeMode: ThemeMode.system,
        ),
      );
      await tester.pumpAndSettle();
      for (final step in [
        (Icons.brightness_auto, ThemeMode.light),
        (Icons.light_mode, ThemeMode.dark),
        (Icons.dark_mode, ThemeMode.system),
      ]) {
        await tester.tap(find.byIcon(step.$1));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          step.$2,
        );
        expect(
          (await SharedPreferences.getInstance()).getString('atena_theme_mode'),
          step.$2.name,
        );
        expect(await SessionService.getSession(), isNull);
        expect(tester.takeException(), isNull);
      }
    },
  );
  test(
    'la búsqueda sin acentos no fusiona identificadores institucionales distintos',
    () async {
      await fixture.seed();
      final institution = (await ih.cargarInstitucionPorId(
        fixture.institution,
      ))!;
      for (final id in ['institución-ficticia', 'institucion-ficticia']) {
        await ih.upsertInstitucion(
          institution.copyWith(
            id: id,
            nombre: 'Academia integración',
            curricular: true,
          ),
        );
      }
      final result = await AlumnoInstitucionesSearchService.search(
        const AlumnoInstitucionSearchFilters(
          scope: AlumnoBusquedaScope.curricular,
          texto: 'integracion',
        ),
      );
      expect(result.map((e) => e.institucion.id).toSet(), {
        'institución-ficticia',
        'institucion-ficticia',
      });
    },
  );
  for (final size in [const Size(320, 640), const Size(1440, 1000)]) {
    testWidgets('buscador consolidado, filtros y vacío ${size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AtenaTheme.build(Brightness.dark),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const AlumnoBuscarInstitucionesPage(
            alumnoDni: '12345678',
            ownerAccountId: 'cuenta-ficticia',
            perfilId: 'perfil-ficticio',
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> reveal(Finder finder) async {
        for (
          var i = 0;
          i < 60 && finder.hitTestable().evaluate().isEmpty;
          i++
        ) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -220));
          await tester.pumpAndSettle();
        }
        expect(finder.hitTestable(), findsOneWidget);
      }

      final category = find.text(AtenaOfferLabels.activities);
      await reveal(category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      final search = find.ancestor(
        of: find.text('Buscar instituciones'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      await reveal(search);
      await tester.tap(search);
      await tester.pumpAndSettle();
      await reveal(find.byType(AtenaEmptyState));
      expect(find.byType(AtenaEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'nombres sin acento y precio de oferta no dependen del plan institucional',
    () async {
      await fixture.seed();
      final inst = (await ih.cargarInstitucionPorId(fixture.institution))!;
      for (final plan in ['Free', 'Premium', 'Prueba']) {
        await ih.upsertInstitucion(
          inst.copyWith(extracurricular: true, tipoPlan: plan),
        );
        await ih.guardarActividadesExtracurricularesEnInstitucion(
          institucionId: fixture.institution,
          actividades: [
            ActividadExtracurricular(
              id: 'oferta-musica',
              institucionId: fixture.institution,
              bloque: BloqueExtracurricular.otros,
              nombre: 'Música y programación',
              activa: true,
              cupoMaximo: 10,
              cupoOcupado: 0,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              precio: 'Gratis',
            ),
          ],
        );
        final result = await AlumnoInstitucionesSearchService.search(
          const AlumnoInstitucionSearchFilters(
            scope: AlumnoBusquedaScope.extracurricular,
            texto: 'MUSICA',
            precio: AlumnoPrecioFiltro.gratuitos,
          ),
        );
        expect(
          result.map((e) => e.institucion.id),
          contains(fixture.institution),
          reason: plan,
        );
        expect(
          await AlumnoInstitucionesSearchService.search(
            const AlumnoInstitucionSearchFilters(
              scope: AlumnoBusquedaScope.extracurricular,
              texto: 'programacion',
              precio: AlumnoPrecioFiltro.conCosto,
            ),
          ),
          isEmpty,
        );
      }
    },
  );
}
