import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/alumno_institucion_perfil_page.dart';
import 'package:atena_app/screens/alumnos/alumno_vacantes_curriculares_page.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StorageService.instance.resetCache();
  });

  testWidgets(
    'búsqueda abre el perfil correcto y conserva identidad al solicitar',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const institutionId = 'institucion-perfil-publico';
      const ownerId = 'cuenta-alumno-busqueda';
      const profileId = 'perfil-alumno-busqueda';
      const studentDocument = '30111222';

      final institution = Institucion(
        id: institutionId,
        nombre: 'Instituto Navegación',
        cuit: '30123456789',
        direccion: 'Calle 123',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: 'instituto@example.invalid',
        telefono: '1122334455',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.primaria,
        tipoPlan: 'prueba',
        estadoPlan: EstadoPlanInstitucion.activo,
        planInicio: DateTime(2026),
        planFin: DateTime(2030),
      );
      await ih.upsertInstitucion(institution);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlumnoBuscarInstitucionesPage(
            alumnoDni: studentDocument,
            ownerAccountId: ownerId,
            perfilId: profileId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Educación formal').first);
      await tester.pumpAndSettle();
      final searchButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Buscar instituciones'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      searchButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('Instituto Navegación'), findsOneWidget);
      await tester.tap(find.text('Ver perfil').last);
      await tester.pumpAndSettle();

      final profile = tester.widget<AlumnoInstitucionPerfilPage>(
        find.byType(AlumnoInstitucionPerfilPage),
      );
      expect(profile.institucion.id, institutionId);
      expect(profile.institucion.nombre, 'Instituto Navegación');

      await tester.tap(find.text('Solicitar vacante').last);
      await tester.pumpAndSettle();

      final vacancies = tester.widget<AlumnoVacantesCurricularesPage>(
        find.byType(AlumnoVacantesCurricularesPage),
      );
      expect(vacancies.institucionId, institutionId);
      expect(vacancies.ownerAccountId, ownerId);
      expect(vacancies.perfilId, profileId);
      expect(vacancies.alumnoDocumento, studentDocument);

      Navigator.of(
        tester.element(find.byType(AlumnoVacantesCurricularesPage)),
      ).pop();
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(AlumnoInstitucionPerfilPage)),
      ).pop();
      await tester.pumpAndSettle();

      expect(find.byType(AlumnoBuscarInstitucionesPage), findsOneWidget);
      expect(find.text('Instituto Navegación'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
