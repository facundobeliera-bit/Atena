import 'dart:convert';

import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/screens/instituciones/institucion_areas_operadores_selector_page.dart';
import 'package:atena_app/screens/instituciones/institucion_historial_actividad_page.dart';
import 'package:atena_app/screens/instituciones/institucion_operadores_page.dart';
import 'package:atena_app/screens/instituciones/institucion_perfiles_selector_page.dart';
import 'package:atena_app/screens/instituciones/institucion_respuestas_calendario_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ownerId = 'owner-historico';
const _institutionId = 'institucion-historica';

Future<Institucion> _seedHistoricalInstitution() async {
  final institution = Institucion(
    id: _institutionId,
    nombre: 'Instituto Atena Histórico',
    cuit: '30111111118',
    direccion: 'Calle Histórica 123',
    pais: 'Argentina',
    provincia: 'Buenos Aires',
    ciudad: 'La Plata',
    modalidad: ModalidadCursado.presencial,
    email: 'historica@example.invalid',
    telefono: '1111111111',
    curricular: true,
    extracurricular: false,
    tipoInstitucion: TipoInstitucion.primaria,
    tipoPlan: 'premium',
    estadoPlan: EstadoPlanInstitucion.activo,
    planInicio: DateTime(2024),
    planFin: DateTime(2030),
    planConfig: null,
  );
  await ih.upsertInstitucion(institution);
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: _ownerId,
      email: 'owner.historico@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const [],
      perfilesInstitucionIds: const [_institutionId],
      recordarme: true,
      creadaEl: DateTime(2024),
      ultimaSesion: DateTime(2026),
    ),
  );
  await CuentaService.actualizarPerfilInstitucion(
    PerfilInstitucion(
      id: _institutionId,
      cuentaId: _ownerId,
      ownerAccountId: _ownerId,
      institucionId: _institutionId,
      nombre: institution.nombre,
      emailContacto: institution.email,
      telefonoContacto: institution.telefono,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await CuentaService.loginCuenta(
    email: 'owner.historico@example.invalid',
    password: 'prueba123',
    recordarme: true,
  );
  await CuentaService.activarContextoInstitucion(_ownerId, _institutionId);
  return institution;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'institución histórica recorre selector, administración y funciones nuevas',
    (tester) async {
      final institution = await _seedHistoricalInstitution();
      final area = (await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: _institutionId,
        tipo: TipoAreaOperativa.curricular,
        claveOrigen: 'primaria',
        nombre: 'Primaria',
      ))!;
      final operator = await InstitucionOperadoresService.instance.crearLocal(
        institucionId: _institutionId,
        nombreVisible: 'Facu',
      );
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: _institutionId,
        operadorId: operator.id,
        areaId: area.id,
      );
      final secondary = (await InstitucionAreasService.instance
          .resolverYGuardar(
            institucionId: _institutionId,
            tipo: TipoAreaOperativa.curricular,
            claveOrigen: 'secundaria',
            nombre: 'Secundaria',
          ))!;
      final secondaryOnly = await InstitucionOperadoresService.instance
          .crearLocal(
            institucionId: _institutionId,
            nombreVisible: 'Sólo Secundaria',
          );
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: _institutionId,
        operadorId: secondaryOnly.id,
        areaId: secondary.id,
      );
      for (var index = 1; index <= 3; index++) {
        await InstitucionWorkProfilesStore.setProfileName(
          instIdLocks: _institutionId,
          actividadKey: 'primaria',
          profileId: 'wp_primaria_$index',
          name: 'Perfil de trabajo $index',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstitucionAreasOperadoresSelectorPage(
            ownerAccountId: _ownerId,
            institucionId: _institutionId,
            institucionNombre: institution.nombre,
            institucion: institution,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primaria'), findsOneWidget);
      expect(find.textContaining('Perfil de trabajo'), findsNothing);
      await tester.tap(find.byKey(ValueKey('enter-area-${area.id}')));
      await tester.pumpAndSettle();
      expect(find.text('¿Quién está ingresando?'), findsOneWidget);
      expect(find.text('Facu'), findsOneWidget);
      expect(find.text('Sólo Secundaria'), findsNothing);
      await tester.tap(find.text('Facu'));
      await tester.pumpAndSettle();

      expect(find.byType(InstitucionAreaPage), findsOneWidget);
      expect(find.text('Administración institucional'), findsOneWidget);
      expect(find.text('Operadores'), findsOneWidget);
      expect(find.text('Historial de actividad'), findsOneWidget);

      final operators = find.text('Operadores');
      await tester.ensureVisible(operators);
      await tester.tap(operators);
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionOperadoresPage), findsOneWidget);
      expect(
        await InstitucionOperadoresService.instance.listar(_institutionId),
        hasLength(3),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionAreaPage), findsOneWidget);

      final history = find.text('Historial de actividad');
      await tester.ensureVisible(history);
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionHistorialActividadPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionAreaPage), findsOneWidget);

      final responses = find.text('Respuestas de calendario');
      await tester.scrollUntilVisible(
        responses,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(responses);
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionRespuestasCalendarioPage), findsOneWidget);
      expect(find.textContaining('Primaria'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(InstitucionAreaPage), findsOneWidget);
      expect(find.textContaining('Primaria'), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      for (var index = 1; index <= 3; index++) {
        expect(
          prefs.getKeys().any((key) => key.contains('wp_primaria_$index')),
          isTrue,
        );
      }
      await tester.tap(find.byTooltip('Volver a áreas'));
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionAreasOperadoresSelectorPage), findsOneWidget);
      expect(await SessionService.getInstitutionOperationalContext(), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
