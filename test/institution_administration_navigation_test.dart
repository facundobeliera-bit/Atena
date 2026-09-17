import 'dart:convert';

import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/screens/instituciones/institucion_historial_actividad_page.dart';
import 'package:atena_app/screens/instituciones/institucion_operadores_page.dart';
import 'package:atena_app/screens/instituciones/institucion_perfiles_selector_page.dart';
import 'package:atena_app/screens/instituciones/institucion_respuestas_calendario_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/storage_service.dart';
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

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstitucionPerfilesSelectorPage(
            ownerAccountId: _ownerId,
            institucionPerfilId: _institutionId,
            institucionNombre: institution.nombre,
            institucion: institution,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final activity = find
          .textContaining('Primaria', findRichText: true)
          .first;
      expect(activity, findsOneWidget);
      await tester.tap(activity);
      await tester.pumpAndSettle();

      final historicalProfile = find.text('Perfil de trabajo 1');
      expect(historicalProfile, findsOneWidget);
      await tester.tap(historicalProfile);
      await tester.pumpAndSettle();
      final enter = find.text('Entrar');
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(enter);
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
        hasLength(1),
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
      expect(
        await InstitucionWorkProfilesStore.getActiveProfileId(
          _institutionId,
          'primaria',
        ),
        'wp_primaria_1',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
