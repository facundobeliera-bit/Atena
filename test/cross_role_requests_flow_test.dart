import 'dart:convert';

import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/models/notificaciones/notificacion_atena.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/routes/atena_deeplink.dart';
import 'package:atena_app/routes/atena_router.dart';
import 'package:atena_app/screens/instituciones/institucion_mis_solicitudes_page.dart';
import 'package:atena_app/screens/instituciones/institucion_notificaciones_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionOwner = 'owner-institucion-operacion';
const institution = 'institucion-operacion';
const studentOwner = 'owner-alumno-operacion';
const student = 'perfil-alumno-operacion';
const group = 'grupo-operacion';

Future<void> _seed() async {
  final date = DateTime(2026);
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: institutionOwner,
      email: 'institucion-operacion@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const [],
      perfilesInstitucionIds: const [institution],
      recordarme: true,
      creadaEl: date,
      ultimaSesion: date,
    ),
  );
  await CuentaService.actualizarPerfilInstitucion(
    PerfilInstitucion(
      id: institution,
      cuentaId: institutionOwner,
      ownerAccountId: institutionOwner,
      institucionId: institution,
      nombre: 'Institución Operación',
      emailContacto: '',
      telefonoContacto: '',
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: studentOwner,
      email: 'alumno-operacion@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const [student],
      perfilesInstitucionIds: const [],
      recordarme: true,
      creadaEl: date,
      ultimaSesion: date,
    ),
  );
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: student,
      cuentaId: studentOwner,
      ownerAccountId: studentOwner,
      documento: '33000001',
      nombre: 'Alma',
      apellido: 'Solicitud',
      fechaNacimiento: DateTime(2012),
      email: '',
      telefono: '',
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  await ih.guardarGruposInstitucion(institution, [
    GrupoInstitucional(
      id: group,
      institucionId: institution,
      actividadNombre: 'Primaria',
      nombreGrupo: '1 A',
      aula: '1 A',
      turno: 'mañana',
      cupoMaximo: 2,
      cupoOcupado: 0,
      estado: EstadoCupo.disponible,
    ),
  ]);
}

SolicitudAlumno _request(String id) => SolicitudAlumno(
  id: id,
  ownerAccountId: studentOwner,
  perfilId: student,
  alumnoDocumento: '33000001',
  institucionId: institution,
  institucionNombre: 'Institución Operación',
  actividadNombre: 'Primaria',
  grupoCurricularId: group,
  aula: '1 A',
  turno: 'mañana',
  esCurricular: true,
  estado: EstadoSolicitud.pendiente,
  fechaCreacion: DateTime.now(),
  fechaUltimoCambio: DateTime.now(),
  dedupKey: '',
);

Future<void> _create(String id) => SolicitudesService.crearSolicitudDesdePerfil(
  ownerAccountId: studentOwner,
  perfilId: student,
  solicitudAlumno: _request(id),
);

Future<void> _activateInstitution() async {
  await CuentaService.loginCuenta(
    email: 'institucion-operacion@example.invalid',
    password: 'prueba123',
    recordarme: true,
  );
  await CuentaService.activarContextoInstitucion(institutionOwner, institution);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
    await _seed();
  });

  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'solicitud confirmada cruza ambos roles con cupo y destino correctos',
    () async {
      await _create('solicitud-confirmada');

      final institutionRequests =
          await SolicitudesService.obtenerSolicitudesParaInstitucion(
            institucionId: institution,
          );
      expect(institutionRequests.single.id, 'solicitud-confirmada');
      expect(institutionRequests.single.estado, EstadoSolicitud.pendiente);

      final institutionNotifications =
          await NotificacionesService.listarOwnerFiltradoPorPerfil(
            ownerAccountId: institutionOwner,
            perfilId: institution,
          );
      expect(institutionNotifications, hasLength(1));
      expect(
        institutionNotifications.single.tipo,
        TipoNotificacionAtena.solicitudCreada,
      );
      expect(
        institutionNotifications.single.data?['solicitudId'],
        'solicitud-confirmada',
      );

      await SolicitudesService.responderSolicitud(
        solicitudId: 'solicitud-confirmada',
        nuevoEstado: EstadoSolicitud.confirmada,
      );

      final studentRequests =
          await SolicitudesService.cargarSolicitudesPorPerfil(
            ownerAccountId: studentOwner,
            perfilId: student,
          );
      expect(studentRequests.single.estado, EstadoSolicitud.confirmada);
      expect(
        (await ih.cargarGruposInstitucion(institution)).single.cupoOcupado,
        1,
      );

      final studentNotifications = await NotificacionesService.listarOwner(
        studentOwner,
      );
      final confirmation = studentNotifications.singleWhere(
        (notification) => notification.tipo == TipoNotificacionAtena.confirmada,
      );
      final deeplink = AtenaDeeplink.parse(confirmation.deeplink!);
      expect(deeplink.isSolicitudes, isTrue);
      expect(deeplink.ownerAccountId, studentOwner);
      expect(deeplink.perfilId, student);
      expect(deeplink.solicitudId, 'solicitud-confirmada');

      await NotificacionesService.instance.setLeida(
        ownerAccountId: studentOwner,
        notificacionId: confirmation.id,
        perfilId: student,
        leida: true,
      );
      StorageService.instance.resetCache();
      expect(
        (await NotificacionesService.listarOwner(studentOwner))
            .singleWhere((notification) => notification.id == confirmation.id)
            .leida,
        isTrue,
      );
    },
  );

  test('rechazo es visible para alumno y no modifica capacidad', () async {
    await _create('solicitud-rechazada');
    await SolicitudesService.responderSolicitud(
      solicitudId: 'solicitud-rechazada',
      nuevoEstado: EstadoSolicitud.rechazada,
      motivoRechazo: 'Sin vacante compatible',
    );

    final studentRequests = await SolicitudesService.cargarSolicitudesPorPerfil(
      ownerAccountId: studentOwner,
      perfilId: student,
    );
    expect(studentRequests.single.estado, EstadoSolicitud.rechazada);
    expect(studentRequests.single.motivoRechazo, 'Sin vacante compatible');
    expect(
      (await ih.cargarGruposInstitucion(institution)).single.cupoOcupado,
      0,
    );

    final notification = (await NotificacionesService.listarOwner(
      studentOwner,
    )).singleWhere((item) => item.tipo == TipoNotificacionAtena.rechazada);
    expect(
      AtenaDeeplink.parse(notification.deeplink!).solicitudId,
      'solicitud-rechazada',
    );
  });

  testWidgets('notificación institucional abre la solicitud que la originó', (
    tester,
  ) async {
    await _create('solicitud-desde-notificacion');
    await _activateInstitution();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InstitucionNotificacionesPage(
          institucionId: institution,
          institucionNombre: 'Institución Operación',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva solicitud'), findsOneWidget);
    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();

    final page = tester.widget<InstitucionMisSolicitudesPage>(
      find.byType(InstitucionMisSolicitudesPage),
    );
    expect(page.institucionId, institution);
    expect(page.ownerAccountId, institutionOwner);
    expect(page.institucionPerfilId, institution);
    expect(page.initialSolicitudId, 'solicitud-desde-notificacion');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ruta institucional directa reconstruye IDs desde la sesión', (
    tester,
  ) async {
    await _create('solicitud-ruta-directa');
    await _activateInstitution();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AtenaRouter.onGenerateRoute,
        initialRoute:
            '/institucion/solicitudes?institucionId=$institution&solicitudId=solicitud-ruta-directa',
      ),
    );
    await tester.pumpAndSettle();

    final page = tester.widget<InstitucionMisSolicitudesPage>(
      find.byType(InstitucionMisSolicitudesPage),
    );
    expect(page.institucionId, institution);
    expect(page.ownerAccountId, institutionOwner);
    expect(page.initialSolicitudId, 'solicitud-ruta-directa');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ruta institucional contradictoria no adopta otra identidad', (
    tester,
  ) async {
    await _activateInstitution();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AtenaRouter.onGenerateRoute,
        initialRoute:
            '/institucion/solicitudes?institucionId=institucion-ajena&solicitudId=ajena',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InstitucionMisSolicitudesPage), findsNothing);
    expect((await SessionService.getSession())?.userId, institution);
    expect(
      await SessionService.getInstitucionOwnerAccountIdLogueado(),
      institutionOwner,
    );
    expect(tester.takeException(), isNull);
  });
}
