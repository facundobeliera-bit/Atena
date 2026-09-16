import 'dart:convert';

import 'package:atena_app/models/calendario/evento_calendario.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/screens/instituciones/institucion_respuestas_calendario_page.dart';
import 'package:atena_app/services/alumno_calendario_interacciones_service.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_emisiones_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionOwnerA = 'owner-institucion-A';
const institutionOwnerB = 'owner-institucion-B';
const institutionA = 'institucion-A';
const institutionB = 'institucion-B';
const studentOwnerA = 'owner-alumno-A';
const studentOwnerB = 'owner-alumno-B';
const studentA = 'perfil-alumno-A';
const siblingA = 'perfil-hermano-A';
const studentB = 'perfil-alumno-B';

Future<void> _account({
  required String id,
  required String email,
  List<String> students = const <String>[],
  List<String> institutions = const <String>[],
}) async {
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: id,
      email: email,
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: students,
      perfilesInstitucionIds: institutions,
      recordarme: true,
      creadaEl: DateTime(2026),
      ultimaSesion: DateTime(2026),
    ),
  );
}

Future<void> _seedIdentity() async {
  await _account(
    id: institutionOwnerA,
    email: 'institucion-a@example.invalid',
    institutions: const [institutionA],
  );
  await _account(
    id: institutionOwnerB,
    email: 'institucion-b@example.invalid',
    institutions: const [institutionB],
  );
  await _account(
    id: studentOwnerA,
    email: 'alumno-a@example.invalid',
    students: const [studentA, siblingA],
  );
  await _account(
    id: studentOwnerB,
    email: 'alumno-b@example.invalid',
    students: const [studentB],
  );

  for (final profile in const [
    (studentA, studentOwnerA, 'Ana', '31000001'),
    (siblingA, studentOwnerA, 'Hermano', '31000002'),
    (studentB, studentOwnerB, 'Bruno', '32000001'),
  ]) {
    await CuentaService.actualizarPerfilAlumno(
      PerfilAlumno(
        id: profile.$1,
        cuentaId: profile.$2,
        ownerAccountId: profile.$2,
        documento: profile.$4,
        nombre: profile.$3,
        apellido: 'Prueba',
        fechaNacimiento: DateTime(2012),
        email: '',
        telefono: '',
        emancipado: false,
        fechaEmancipacion: null,
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
  }

  await ih.upsertInstitucion(
    Institucion.fromMap({'id': institutionA, 'nombre': 'Institución A'}),
  );

  for (final profile in const [
    (institutionA, institutionOwnerA, 'Institución A'),
    (institutionB, institutionOwnerB, 'Institución B'),
  ]) {
    await CuentaService.actualizarPerfilInstitucion(
      PerfilInstitucion(
        id: profile.$1,
        cuentaId: profile.$2,
        ownerAccountId: profile.$2,
        institucionId: profile.$1,
        nombre: profile.$3,
        emailContacto: '',
        telefonoContacto: '',
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
  }
}

SolicitudAlumno _confirmedStudent({
  required String id,
  required String owner,
  required String profile,
  required String document,
  required String institution,
}) {
  return SolicitudAlumno(
    id: id,
    ownerAccountId: owner,
    perfilId: profile,
    alumnoDocumento: document,
    institucionId: institution,
    institucionNombre: institution,
    actividadNombre: 'Primaria',
    esCurricular: true,
    grupoCurricularId: 'grupo-$institution',
    aula: '1 A',
    turno: 'mañana',
    estado: EstadoSolicitud.confirmada,
    fechaCreacion: DateTime(2026),
    fechaUltimoCambio: DateTime(2026),
    dedupKey: 'dedup-$id',
  );
}

Future<String> _emitAndRespond({
  required String institution,
  required String institutionName,
  required String owner,
  required String profile,
  required String document,
  required RsvpStatusAtena response,
  String actividadKey = 'primaria',
  String? grupoId,
  bool esCurricular = true,
}) async {
  final emitted = await InstitucionEmisionesService.instance
      .emitirEventoEspecialAConfirmados(
        institucionId: institution,
        institucionNombre: institutionName,
        confirmados: [
          _confirmedStudent(
            id: 'sol-$institution-$profile',
            owner: owner,
            profile: profile,
            document: document,
            institution: institution,
          ),
        ],
        esCurricular: esCurricular,
        actividadKey: actividadKey,
        grupoId: grupoId,
        inicio: DateTime(2026, 4, 15, 18),
        titulo: 'Reunión de familias',
        descripcion: 'Encuentro institucional',
        tipoEspecial: TipoEventoEspecial.otro,
        requiresRsvp: true,
      );
  final eventId = emitted[profile]!;
  await AlumnoCalendarioInteraccionesService.instance.setRsvp(
    ownerAccountId: owner,
    perfilId: profile,
    eventId: eventId,
    status: response,
    notificarOwner: false,
  );
  return eventId;
}

Future<void> _activateInstitutionA() async {
  await CuentaService.loginCuenta(
    email: 'institucion-a@example.invalid',
    password: 'prueba123',
    recordarme: true,
  );
  await CuentaService.activarContextoInstitucion(
    institutionOwnerA,
    institutionA,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
    await _seedIdentity();
  });

  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'institución emite, alumno responde y la institución consume tras reinicio',
    () async {
      final eventId = await _emitAndRespond(
        institution: institutionA,
        institutionName: 'Institución A',
        owner: studentOwnerA,
        profile: studentA,
        document: '31000001',
        response: RsvpStatusAtena.yes,
      );

      final studentEvents = await AlumnoService.instance.getCalendarioRaw(
        ownerAccountId: studentOwnerA,
        perfilId: studentA,
      );
      expect(studentEvents.single['id'], eventId);
      expect(studentEvents.single['rsvpStatus'], 'yes');

      StorageService.instance.resetCache();
      final responses = await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionA);
      expect(responses, hasLength(1));
      expect(responses.single.institucionId, institutionA);
      expect(responses.single.ownerAccountId, studentOwnerA);
      expect(responses.single.perfilId, studentA);
      expect(responses.single.eventId, eventId);
      expect(responses.single.eventTitle, 'Reunión de familias');
      expect(responses.single.status, RsvpStatusAtena.yes);
    },
  );

  test(
    'instituciones, perfiles hermanos y eventos homónimos quedan aislados',
    () async {
      final eventA = await _emitAndRespond(
        institution: institutionA,
        institutionName: 'Institución A',
        owner: studentOwnerA,
        profile: studentA,
        document: '31000001',
        response: RsvpStatusAtena.yes,
      );
      final eventB = await _emitAndRespond(
        institution: institutionB,
        institutionName: 'Institución B',
        owner: studentOwnerB,
        profile: studentB,
        document: '32000001',
        response: RsvpStatusAtena.no,
      );

      final responsesA = await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionA);
      final responsesB = await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionB);
      expect(responsesA.single.eventId, eventA);
      expect(responsesA.single.perfilId, studentA);
      expect(responsesA.single.status, RsvpStatusAtena.yes);
      expect(responsesB.single.eventId, eventB);
      expect(responsesB.single.perfilId, studentB);
      expect(responsesB.single.status, RsvpStatusAtena.no);
      expect(eventA, isNot(eventB));
      expect(
        await AlumnoService.instance.getCalendarioRaw(
          ownerAccountId: studentOwnerA,
          perfilId: siblingA,
        ),
        isEmpty,
      );
    },
  );

  test(
    'la institución recibe sólo la última respuesta vigente por evento',
    () async {
      final eventId = await _emitAndRespond(
        institution: institutionA,
        institutionName: 'Institución A',
        owner: studentOwnerA,
        profile: studentA,
        document: '31000001',
        response: RsvpStatusAtena.maybe,
      );
      await AlumnoCalendarioInteraccionesService.instance.setRsvp(
        ownerAccountId: studentOwnerA,
        perfilId: studentA,
        eventId: eventId,
        status: RsvpStatusAtena.no,
        notificarOwner: false,
      );

      final responses = await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionA);
      expect(responses, hasLength(1));
      expect(responses.single.eventId, eventId);
      expect(responses.single.status, RsvpStatusAtena.no);
    },
  );

  testWidgets('pantalla institucional muestra alumno, evento y respuesta', (
    tester,
  ) async {
    await _emitAndRespond(
      institution: institutionA,
      institutionName: 'Institución A',
      owner: studentOwnerA,
      profile: studentA,
      document: '31000001',
      response: RsvpStatusAtena.yes,
    );
    await _activateInstitutionA();

    await tester.pumpWidget(
      const MaterialApp(
        home: InstitucionRespuestasCalendarioPage(
          ownerAccountId: institutionOwnerA,
          institucionId: institutionA,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reunión de familias'), findsOneWidget);
    expect(find.textContaining('Ana Prueba'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('argumentos contradictorios no exponen otra institución', (
    tester,
  ) async {
    await _emitAndRespond(
      institution: institutionB,
      institutionName: 'Institución B',
      owner: studentOwnerB,
      profile: studentB,
      document: '32000001',
      response: RsvpStatusAtena.no,
    );
    await _activateInstitutionA();

    await tester.pumpWidget(
      const MaterialApp(
        home: InstitucionRespuestasCalendarioPage(
          ownerAccountId: institutionOwnerB,
          institucionId: institutionB,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo validar la sesión para esta institución.'),
      findsOneWidget,
    );
    expect(find.text('Reunión de familias'), findsNothing);
    expect(find.text('Bruno Prueba'), findsNothing);
    expect((await SessionService.getSession())?.userId, institutionA);
    expect(
      await SessionService.getInstitucionOwnerAccountIdLogueado(),
      institutionOwnerA,
    );
  });

  testWidgets('acceso directo por área sin sesión es rechazado', (
    tester,
  ) async {
    final area = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionA,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'primaria',
      nombre: 'Primaria',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InstitucionRespuestasCalendarioPage(
          ownerAccountId: institutionOwnerA,
          institucionId: institutionA,
          areaId: area!.id,
          areaNombre: area.nombre,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo validar la sesión para esta institución.'),
      findsOneWidget,
    );
  });

  testWidgets('menú institucional ya no ofrece respuestas globales', (
    tester,
  ) async {
    await _activateInstitutionA();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InstitucionMenuPage(
          ownerAccountId: institutionOwnerA,
          institucionPerfilId: institutionA,
          institucionNombre: 'Institución A',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Respuestas de calendario'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Administración de Primaria abre respuestas y Back conserva área',
    (tester) async {
      await _activateInstitutionA();
      final institution = await ih.cargarInstitucionPorId(institutionA);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstitucionAreaPage(
            ownerAccountId: institutionOwnerA,
            institucionId: institutionA,
            institucionNombre: 'Institución A',
            institucion: institution,
            actividadKey: 'primaria',
            actividadLabel: 'Primaria',
            workProfileId: 'wp_primaria_1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text('Respuestas de calendario');
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionRespuestasCalendarioPage), findsOneWidget);
      expect(find.text('Primaria — Respuestas de calendario'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionAreaPage), findsOneWidget);
      expect(find.textContaining('Primaria'), findsWidgets);
    },
  );

  test('respuestas quedan aisladas por área y conservan grupo', () async {
    await _emitAndRespond(
      institution: institutionA,
      institutionName: 'Institución A',
      owner: studentOwnerA,
      profile: studentA,
      document: '31000001',
      response: RsvpStatusAtena.yes,
      actividadKey: 'primaria',
      grupoId: 'grupo-1A',
    );
    await _emitAndRespond(
      institution: institutionA,
      institutionName: 'Institución A',
      owner: studentOwnerA,
      profile: siblingA,
      document: '31000002',
      response: RsvpStatusAtena.no,
      actividadKey: 'secundaria',
      grupoId: 'grupo-2B',
    );
    await _emitAndRespond(
      institution: institutionA,
      institutionName: 'Institución A',
      owner: studentOwnerB,
      profile: studentB,
      document: '32000001',
      response: RsvpStatusAtena.maybe,
      actividadKey: 'futbol',
      grupoId: 'grupo-futbol-1',
      esCurricular: false,
    );
    final primary = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionA,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'primaria',
      nombre: 'Primaria',
    );
    final secondary = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionA,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'secundaria',
      nombre: 'Secundaria',
    );
    final football = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionA,
      tipo: TipoAreaOperativa.extracurricular,
      claveOrigen: 'futbol',
      nombre: 'Fútbol',
    );
    final primaryResponses = await AlumnoCalendarioInteraccionesService.instance
        .listarRespuestasArea(institucionId: institutionA, areaId: primary!.id);
    final secondaryResponses = await AlumnoCalendarioInteraccionesService
        .instance
        .listarRespuestasArea(
          institucionId: institutionA,
          areaId: secondary!.id,
        );
    final footballResponses = await AlumnoCalendarioInteraccionesService
        .instance
        .listarRespuestasArea(
          institucionId: institutionA,
          areaId: football!.id,
        );
    expect(primaryResponses.single.perfilId, studentA);
    expect(primaryResponses.single.grupoId, 'grupo-1A');
    expect(secondaryResponses.single.perfilId, siblingA);
    expect(secondaryResponses.single.grupoId, 'grupo-2B');
    expect(footballResponses.single.perfilId, studentB);
    expect(footballResponses.single.grupoId, 'grupo-futbol-1');
    expect(
      await AlumnoCalendarioInteraccionesService.instance.listarRespuestasArea(
        institucionId: institutionB,
        areaId: primary.id,
      ),
      isEmpty,
    );
    expect(
      await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionA),
      hasLength(3),
    );
  });
}
