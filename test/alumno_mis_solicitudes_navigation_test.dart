import 'dart:convert';

import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/notificaciones/notificacion_atena.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/routes/atena_deeplink.dart';
import 'package:atena_app/routes/atena_router.dart';
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/alumnos/alumno_mis_solicitudes_page.dart';
import 'package:atena_app/screens/alumnos/alumno_notificaciones_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = 'owner-solicitudes';
const profile = 'perfil-solicitudes';
const otherProfile = 'perfil-sin-solicitudes';
const requestId = 'solicitud-visible';
const activity = 'Actividad visible del perfil';

Future<void> seed() async {
  final date = DateTime(2026);
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: owner,
      email: 'solicitudes@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const [profile, otherProfile],
      perfilesInstitucionIds: const [],
      recordarme: false,
      creadaEl: date,
      ultimaSesion: date,
    ),
  );
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: profile,
      cuentaId: owner,
      ownerAccountId: owner,
      documento: '30000001',
      nombre: 'Ana',
      apellido: 'Prueba',
      fechaNacimiento: DateTime(2010),
      email: '',
      telefono: '',
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: otherProfile,
      cuentaId: owner,
      ownerAccountId: owner,
      documento: '30000002',
      nombre: 'Bruno',
      apellido: 'Control',
      fechaNacimiento: DateTime(2011),
      email: '',
      telefono: '',
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await CuentaService.loginCuenta(
    email: 'solicitudes@example.invalid',
    password: 'prueba123',
    recordarme: false,
  );
  await CuentaService.clearUltimoPerfil(owner);
  final repo = SolicitudesRepositoryPrefs();
  await repo.saveSolicitudAlumno(
    SolicitudAlumno(
      id: requestId,
      ownerAccountId: owner,
      perfilId: profile,
      alumnoDocumento: '30000001',
      institucionId: 'institucion-solicitudes',
      institucionNombre: 'Institución de prueba',
      actividadNombre: activity,
      esCurricular: true,
      grupoCurricularId: 'grupo-solicitudes',
      aula: '1 A',
      turno: 'mañana',
      moduleKey: '',
      estado: EstadoSolicitud.pendiente,
      fechaCreacion: date,
      fechaUltimoCambio: date,
      dedupKey: 'dedup-solicitudes',
    ),
  );
  await repo.rebuildIndexes();
}

Future<void> pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AtenaRouter.onGenerateRoute,
      home: const Scaffold(body: Text('Inicio')),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({
      'atena_locale': 'es',
      'atena_theme_mode': 'light',
    });
    await seed();
  });
  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test('deeplink de solicitudes conserva identidad y solicitud', () {
    final parsed = AtenaDeeplink.parse(
      '/alumno/solicitudes?ownerAccountId=$owner&perfilId=$profile&solicitudId=$requestId',
    );
    expect(parsed.isSolicitudes, isTrue);
    expect(parsed.ownerAccountId, owner);
    expect(parsed.perfilId, profile);
    expect(parsed.solicitudId, requestId);
    expect(parsed.toRouteString(), contains('solicitudId=$requestId'));
  });

  testWidgets('ruta directa abre solicitudes del perfil activo', (
    tester,
  ) async {
    await pumpRouter(tester);
    Navigator.of(tester.element(find.text('Inicio'))).pushNamed(
      '/alumno/solicitudes?ownerAccountId=$owner&perfilId=$profile&solicitudId=$requestId',
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoMisSolicitudesPage), findsOneWidget);
    expect(find.text(activity), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('argumentos de otro owner no exponen solicitudes', (
    tester,
  ) async {
    await pumpRouter(tester);
    Navigator.of(tester.element(find.text('Inicio'))).pushNamed(
      '/alumno/solicitudes?ownerAccountId=otro-owner&perfilId=$profile',
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoMisSolicitudesPage), findsOneWidget);
    expect(find.text(activity), findsNothing);
  });

  testWidgets('notificación de solicitud abre la pantalla real', (
    tester,
  ) async {
    const notificationTitle = 'Solicitud actualizada para Ana';
    await NotificacionesService.instance.pushToOwner(
      ownerAccountId: owner,
      notificacion: NotificacionAtena(
        id: 'notificacion-solicitud-visible',
        ownerAccountId: owner,
        perfilId: profile,
        titulo: notificationTitle,
        mensaje: 'Revisá el estado de tu solicitud.',
        fecha: DateTime(2026, 1, 2),
        tipo: TipoNotificacionAtena.solicitudCreada,
        scope: NotificacionScopeAtena.owner,
        leida: false,
        deeplink:
            '/alumno/solicitudes?ownerAccountId=$owner&perfilId=$profile&solicitudId=$requestId',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AtenaRouter.onGenerateRoute,
        home: const AlumnoNotificacionesPage(
          alumnoDocumento: '30000001',
          perfilIdFiltro: profile,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, notificationTitle));
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoMisSolicitudesPage), findsOneWidget);
    expect(find.text(activity), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('área del alumno abre la pantalla real con sus datos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const app.AtenaApp(
        initialLocale: Locale('es'),
        initialThemeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const CuentaHomePage(cuentaId: owner),
      ),
      (_) => false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Prueba, Ana'));
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoAreaPage), findsOneWidget);
    final entry = find.widgetWithText(ListTile, 'Mis solicitudes');
    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoMisSolicitudesPage), findsOneWidget);
    expect(find.text(activity), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
