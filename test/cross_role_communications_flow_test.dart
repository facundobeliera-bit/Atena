import 'dart:convert';

import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/routes/atena_deeplink.dart';
import 'package:atena_app/services/alumno_calendario_interacciones_service.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ownerA = 'owner-comunicado-A';
const ownerB = 'owner-comunicado-B';
const profileA = 'perfil-comunicado-A';
const profileB = 'perfil-comunicado-B';
const institutionA = 'institucion-comunicado-A';

Future<void> _seed() async {
  for (final entry in const [
    (ownerA, profileA, 'comunicado-a@example.invalid', '34000001'),
    (ownerB, profileB, 'comunicado-b@example.invalid', '34000002'),
  ]) {
    await CuentaService.actualizarCuenta(
      Cuenta(
        id: entry.$1,
        email: entry.$3,
        passwordHash: base64Encode(utf8.encode('prueba123')),
        perfilesAlumnoIds: [entry.$2],
        perfilesInstitucionIds: const [],
        recordarme: true,
        creadaEl: DateTime(2026),
        ultimaSesion: DateTime(2026),
      ),
    );
    await CuentaService.actualizarPerfilAlumno(
      PerfilAlumno(
        id: entry.$2,
        cuentaId: entry.$1,
        ownerAccountId: entry.$1,
        documento: entry.$4,
        nombre: entry.$1 == ownerA ? 'Ana' : 'Berta',
        apellido: 'Comunicado',
        fechaNacimiento: DateTime(2012),
        email: '',
        telefono: '',
        emancipado: false,
        fechaEmancipacion: null,
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
  }
}

Map<String, dynamic> _payload({required bool addToCalendar}) => {
  'version': 1,
  'institucionId': institutionA,
  'moduleKey': 'otros',
  'bloqueKey': 'otros',
  'bloqueLabel': 'Otros',
  'date': '2026-05-20',
  'time': '18:30',
  'title': 'Comunicado de familias',
  'content': 'Revisar la información de la reunión.',
  'addToCalendar': addToCalendar,
  'requiresRsvp': true,
  'rsvpPolicy': 'optional',
  'recipients': const [
    {
      'ownerAccountId': ownerA,
      'perfilId': profileA,
      'displayName': 'Ana Comunicado',
    },
    {
      'ownerAccountId': ownerA,
      'perfilId': profileA,
      'displayName': 'Ana duplicada',
    },
  ],
  'createdAtIso': '2026-05-01T10:00:00.000',
};

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
    'comunicado llega una vez, abre su evento y conserva leído tras reinicio',
    () async {
      await ExtracurricularesService.instance.emitirFichaExtracurricular(
        _payload(addToCalendar: true),
      );

      var notifications = await NotificacionesService.listarOwner(ownerA);
      expect(notifications, hasLength(1));
      expect(await NotificacionesService.listarOwner(ownerB), isEmpty);
      expect(notifications.single.perfilId, profileA);
      expect(notifications.single.leida, isFalse);

      final deeplink = AtenaDeeplink.parse(notifications.single.deeplink!);
      expect(deeplink.isCalendario, isTrue);
      expect(deeplink.ownerAccountId, ownerA);
      expect(deeplink.perfilId, profileA);
      expect(deeplink.dateKey, '2026-05-20');
      expect(deeplink.itemId, notifications.single.id);

      final eventsA = await AlumnoService.instance.getCalendarioRaw(
        ownerAccountId: ownerA,
        perfilId: profileA,
      );
      expect(eventsA, hasLength(1));
      expect(eventsA.single['id'], notifications.single.id);
      expect(eventsA.single['title'], 'Comunicado de familias');
      expect(eventsA.single['institucionId'], institutionA);
      expect(eventsA.single['requiresRsvp'], isTrue);
      expect(
        await AlumnoService.instance.getCalendarioRaw(
          ownerAccountId: ownerB,
          perfilId: profileB,
        ),
        isEmpty,
      );

      await NotificacionesService.instance.setLeida(
        ownerAccountId: ownerA,
        notificacionId: notifications.single.id,
        perfilId: profileA,
        leida: true,
      );
      await AlumnoCalendarioInteraccionesService.instance.setRsvp(
        ownerAccountId: ownerA,
        perfilId: profileA,
        eventId: eventsA.single['id'] as String,
        status: RsvpStatusAtena.maybe,
        notificarOwner: false,
      );

      StorageService.instance.resetCache();
      notifications = await NotificacionesService.listarOwner(ownerA);
      expect(notifications.single.leida, isTrue);
      expect(
        (await AlumnoService.instance.getCalendarioRaw(
          ownerAccountId: ownerA,
          perfilId: profileA,
        )).single['rsvpStatus'],
        'maybe',
      );
      final responses = await AlumnoCalendarioInteraccionesService.instance
          .listarRespuestasInstitucion(institutionA);
      expect(responses.single.perfilId, profileA);
      expect(responses.single.status, RsvpStatusAtena.maybe);
    },
  );

  test('comunicado sin opción de calendario no crea un evento', () async {
    await ExtracurricularesService.instance.emitirFichaExtracurricular(
      _payload(addToCalendar: false),
    );

    expect(await NotificacionesService.listarOwner(ownerA), hasLength(1));
    expect(
      await AlumnoService.instance.getCalendarioRaw(
        ownerAccountId: ownerA,
        perfilId: profileA,
      ),
      isEmpty,
    );
  });
}
