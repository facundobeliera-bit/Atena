import 'dart:convert';

import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/notificaciones/notificacion_atena.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/routes/atena_deeplink.dart';
import 'package:atena_app/services/alumno_calendario_interacciones_service.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = 'owner-continuidad';
const profile = 'perfil-continuidad';
const otherProfile = 'perfil-continuidad-otro';
const institution = 'institucion-continuidad';

void simulateRestart() {
  StorageService.instance.resetCache();
}

Future<void> seedIdentity() async {
  final date = DateTime(2026);
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: owner,
      email: 'continuidad@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const [profile, otherProfile],
      perfilesInstitucionIds: const [],
      recordarme: true,
      creadaEl: date,
      ultimaSesion: date,
    ),
  );
  for (final data in const [
    (id: profile, dni: '31000001', name: 'Continuidad'),
    (id: otherProfile, dni: '31000002', name: 'Aislado'),
  ]) {
    await CuentaService.actualizarPerfilAlumno(
      PerfilAlumno(
        id: data.id,
        cuentaId: owner,
        ownerAccountId: owner,
        documento: data.dni,
        nombre: data.name,
        apellido: 'Prueba',
        fechaNacimiento: DateTime(2010),
        email: '',
        telefono: '',
        emancipado: false,
        fechaEmancipacion: null,
        prefs: PreferenciasPerfil.defaults(),
      ),
    );
  }
}

SolicitudAlumno request(EstadoSolicitud state) => SolicitudAlumno(
  id: 'solicitud-continuidad',
  ownerAccountId: owner,
  perfilId: profile,
  alumnoDocumento: '31000001',
  institucionId: institution,
  institucionNombre: 'Institución continuidad',
  actividadNombre: 'Primaria',
  esCurricular: true,
  grupoCurricularId: 'grupo-continuidad',
  aula: '1 A',
  turno: 'mañana',
  moduleKey: '',
  estado: state,
  fechaCreacion: DateTime(2026),
  fechaUltimoCambio: DateTime(2026, 1, 2),
  dedupKey: 'dedup-continuidad',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    simulateRestart();
    await seedIdentity();
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    simulateRestart();
  });

  test(
    'solicitudes e índices conservan estados después del reinicio',
    () async {
      var repository = SolicitudesRepositoryPrefs();
      await repository.saveSolicitudAlumno(request(EstadoSolicitud.pendiente));

      simulateRestart();
      repository = SolicitudesRepositoryPrefs();
      expect(
        (await repository.getSolicitudesPerfil(profile)).single.estado,
        EstadoSolicitud.pendiente,
      );
      expect(
        await repository.getSolicitudesInstitucionPendientes(institution),
        hasLength(1),
      );

      await repository.saveSolicitudAlumno(request(EstadoSolicitud.confirmada));
      simulateRestart();
      repository = SolicitudesRepositoryPrefs();
      expect(
        (await repository.getSolicitudesInstitucion(institution)).single.estado,
        EstadoSolicitud.confirmada,
      );
      expect(
        await repository.getSolicitudesInstitucionPendientes(institution),
        isEmpty,
      );

      await repository.saveSolicitudAlumno(
        request(EstadoSolicitud.canceladaPorAlumno),
      );
      simulateRestart();
      expect(
        (await SolicitudesRepositoryPrefs().getSolicitudesOwner(
          owner,
        )).single.estado,
        EstadoSolicitud.canceladaPorAlumno,
      );
    },
  );

  test('notificación y estado leído permanecen y conservan su destino', () async {
    const deeplink =
        '/alumno/solicitudes?ownerAccountId=$owner&perfilId=$profile&solicitudId=solicitud-continuidad';
    await NotificacionesService.instance.pushToOwner(
      ownerAccountId: owner,
      notificacion: NotificacionAtena(
        id: 'notificacion-continuidad',
        ownerAccountId: owner,
        perfilId: profile,
        titulo: 'Solicitud actualizada',
        mensaje: 'Hay novedades.',
        fecha: DateTime(2026),
        tipo: TipoNotificacionAtena.solicitudCreada,
        scope: NotificacionScopeAtena.owner,
        leida: false,
        deeplink: deeplink,
      ),
    );

    simulateRestart();
    var notifications = await NotificacionesService.listarOwner(owner);
    expect(notifications.single.leida, isFalse);
    final parsed = AtenaDeeplink.parse(notifications.single.deeplink!);
    expect(parsed.isSolicitudes, isTrue);
    expect(parsed.perfilId, profile);
    expect(parsed.solicitudId, 'solicitud-continuidad');

    await NotificacionesService.instance.setLeida(
      ownerAccountId: owner,
      notificacionId: notifications.single.id,
      leida: true,
      perfilId: profile,
    );
    simulateRestart();
    notifications = await NotificacionesService.listarOwner(owner);
    expect(notifications.single.leida, isTrue);
  });

  test('evento, respuesta y outbox institucional persisten', () async {
    final calendar = AlumnoCalendarioInteraccionesService.instance;
    await calendar.upsertEvento(
      ownerAccountId: owner,
      perfilId: profile,
      notificarOwner: false,
      evento: {
        'id': 'evento-continuidad',
        'date': '2026-03-10',
        'title': 'Reunión con familias',
        'source': 'institucion',
        'institucionId': institution,
        'requiresRsvp': true,
        'rsvpPolicy': 'optional',
        'rsvpStatus': 'pending',
      },
    );

    simulateRestart();
    expect(
      (await calendar.listarEventos(
        ownerAccountId: owner,
        perfilId: profile,
      )).single['title'],
      'Reunión con familias',
    );

    await calendar.setRsvp(
      ownerAccountId: owner,
      perfilId: profile,
      eventId: 'evento-continuidad',
      status: RsvpStatusAtena.yes,
      notificarOwner: false,
    );
    simulateRestart();

    final events = await calendar.listarEventos(
      ownerAccountId: owner,
      perfilId: profile,
    );
    final outbox = await calendar.listarOutboxInstitucion(institution);
    expect(events.single['rsvpStatus'], 'yes');
    expect(outbox.any((item) => item['kind'] == 'rsvp_changed'), isTrue);
  });

  test('datos académicos utilizables son persistentes y aislados', () async {
    final service = AlumnoService.instance;
    await service.setBoletinesRaw(
      ownerAccountId: owner,
      perfilId: profile,
      boletines: const [
        {'id': 'boletin-1'},
      ],
    );
    await service.setTitulosRaw(
      ownerAccountId: owner,
      perfilId: profile,
      titulos: const [
        {'id': 'titulo-1'},
      ],
    );
    await service.setProgresosRaw(
      ownerAccountId: owner,
      perfilId: profile,
      progresos: const [
        {'id': 'progreso-1'},
      ],
    );
    await service.setBecasRaw(
      ownerAccountId: owner,
      perfilId: profile,
      becas: const [
        {'id': 'beca-1'},
      ],
    );
    await service.setSancionesRaw(
      ownerAccountId: owner,
      perfilId: profile,
      sanciones: const [
        {'id': 'sancion-1'},
      ],
    );
    await service.setEquivalenciasRaw(
      ownerAccountId: owner,
      perfilId: profile,
      equivalencias: const [
        {'id': 'equivalencia-1'},
      ],
    );
    await service.setAgendaPersonalRaw(
      ownerAccountId: owner,
      perfilId: profile,
      items: const [
        {
          'id': 'recordatorio-1',
          'date': '2026-04-01',
          'title': 'Entregar autorización',
        },
      ],
    );

    simulateRestart();
    expect(
      await service.getBoletinesRaw(ownerAccountId: owner, perfilId: profile),
      const [
        {'id': 'boletin-1'},
      ],
    );
    expect(
      await service.getTitulosRaw(ownerAccountId: owner, perfilId: profile),
      const [
        {'id': 'titulo-1'},
      ],
    );
    expect(
      await service.getProgresosRaw(ownerAccountId: owner, perfilId: profile),
      const [
        {'id': 'progreso-1'},
      ],
    );
    expect(
      await service.getBecasRaw(ownerAccountId: owner, perfilId: profile),
      const [
        {'id': 'beca-1'},
      ],
    );
    expect(
      await service.getSancionesRaw(ownerAccountId: owner, perfilId: profile),
      const [
        {'id': 'sancion-1'},
      ],
    );
    expect(
      await service.getEquivalenciasRaw(
        ownerAccountId: owner,
        perfilId: profile,
      ),
      const [
        {'id': 'equivalencia-1'},
      ],
    );
    expect(
      (await service.getAgendaPersonalRaw(
        ownerAccountId: owner,
        perfilId: profile,
      )).single['id'],
      'recordatorio-1',
    );
    expect(
      await service.getBoletinesRaw(
        ownerAccountId: owner,
        perfilId: otherProfile,
      ),
      isEmpty,
    );
  });
}
