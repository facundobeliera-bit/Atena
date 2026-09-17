import 'dart:convert';

import 'package:atena_app/models/calendario/evento_calendario.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/services/calendario_service.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_emisiones_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_grupos_autorizacion_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as helpers;
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institution = 'capability-institution';
const otherInstitution = 'other-institution';
const owner = 'capability-owner';

Future<AreaOperativa> area(String institutionId, String key) async =>
    (await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionId,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: key,
      nombre: key,
    ))!;

Future<OperadorInstitucional> ownerOperator() async =>
    InstitucionOperadoresService.instance.asegurarPropietario(
      institucionId: institution,
      ownerAccountId: owner,
      perfilInstitucionId: institution,
      nombreVisible: 'Propietario',
    );

Future<void> institutionalSession() async {
  await SessionService.setSession(
    userId: institution,
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId(owner);
}

Future<void> seedStudentIdentity() async {
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: 'student-owner',
      email: 'student@example.invalid',
      passwordHash: base64Encode(utf8.encode('prueba123')),
      perfilesAlumnoIds: const ['student-profile'],
      perfilesInstitucionIds: const [],
      recordarme: false,
      creadaEl: DateTime(2026),
      ultimaSesion: DateTime(2026),
    ),
  );
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: 'student-profile',
      cuentaId: 'student-owner',
      ownerAccountId: 'student-owner',
      documento: '12345678',
      nombre: 'Ana',
      apellido: 'Prueba',
      fechaNacimiento: DateTime(2015),
      email: '',
      telefono: '',
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
}

SolicitudAlumno pendingRequest(String areaId) => SolicitudAlumno(
  id: 'request-${DateTime.now().microsecondsSinceEpoch}',
  ownerAccountId: 'student-owner',
  perfilId: 'student-profile',
  alumnoDocumento: '12345678',
  institucionId: institution,
  institucionNombre: 'Institución',
  actividadNombre: 'Primaria',
  areaId: areaId,
  esCurricular: true,
  estado: EstadoSolicitud.pendiente,
  fechaCreacion: DateTime(2026, 9, 16),
  fechaUltimoCambio: DateTime(2026, 9, 16),
  dedupKey: 'dedup-${DateTime.now().microsecondsSinceEpoch}',
);

EventoCalendario calendarEvent(String areaId) => EventoCalendario(
  id: 'event-1',
  ownerAccountId: owner,
  perfilId: null,
  titulo: 'Reunión',
  descripcion: '',
  inicio: DateTime(2026, 9, 17),
  fin: null,
  institucionId: institution,
  institucionNombre: 'Institución',
  solicitudId: null,
  alumnoDni: null,
  actividadNombre: 'Primaria',
  esCurricular: true,
  areaId: areaId,
  tipo: TipoEventoCalendario.eventoEspecial,
  tipoEspecial: TipoEventoEspecial.otro,
  segmentoEspecial: null,
  cerrado: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'propietario administra áreas propias pero no otra institución',
    () async {
      await institutionalSession();
      final primary = await area(institution, 'primaria');
      final foreign = await area(otherInstitution, 'primaria');
      final operator = await ownerOperator();
      await InstitucionOperadoresService.instance.activar(
        institucionId: institution,
        operadorId: operator.id,
      );
      expect(
        await InstitucionOperadoresService.instance.puedeRealizar(
          institucionId: institution,
          operadorId: operator.id,
          areaId: primary.id,
          capacidad: CapacidadInstitucional.areaManage,
        ),
        isTrue,
      );
      expect(
        await InstitucionOperadoresService.instance.puedeRealizar(
          institucionId: otherInstitution,
          operadorId: operator.id,
          areaId: foreign.id,
          capacidad: CapacidadInstitucional.areaManage,
        ),
        isFalse,
      );
    },
  );

  test('área y capacidad son requisitos independientes', () async {
    final primary = await area(institution, 'primaria');
    final secondary = await area(institution, 'secundaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'María',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: operator.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institution,
      operadorId: operator.id,
      capacidades: {CapacidadInstitucional.requestsDecide},
    );
    expect(
      await InstitucionOperadoresService.instance.puedeRealizar(
        institucionId: institution,
        operadorId: operator.id,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.requestsDecide,
      ),
      isTrue,
    );
    expect(
      await InstitucionOperadoresService.instance.puedeRealizar(
        institucionId: institution,
        operadorId: operator.id,
        areaId: secondary.id,
        capacidad: CapacidadInstitucional.requestsDecide,
      ),
      isFalse,
    );
    expect(
      await InstitucionOperadoresService.instance.puedeRealizar(
        institucionId: institution,
        operadorId: operator.id,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      ),
      isFalse,
    );
  });

  test('suspendido no opera aunque conserve área y capacidad', () async {
    final primary = await area(institution, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'Suspendido',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: operator.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institution,
      operadorId: operator.id,
      capacidades: {CapacidadInstitucional.calendarWrite},
    );
    await InstitucionOperadoresService.instance.actualizar(
      institucionId: institution,
      operadorId: operator.id,
      estado: EstadoOperadorInstitucional.suspendido,
    );
    expect(
      await InstitucionOperadoresService.instance.puedeRealizar(
        institucionId: institution,
        operadorId: operator.id,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.calendarWrite,
      ),
      isFalse,
    );
  });

  test('operador autorizado rechaza solicitud y conserva autoría', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'Decisor',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: operator.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institution,
      operadorId: operator.id,
      capacidades: {CapacidadInstitucional.requestsDecide},
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: operator.id,
    );
    final request = pendingRequest(primary.id);
    final repository = SolicitudesRepositoryPrefs();
    await repository.saveSolicitudAlumno(request);
    await SolicitudesService.responderSolicitudInstitucional(
      solicitudId: request.id,
      institucionId: institution,
      areaId: primary.id,
      nuevoEstado: EstadoSolicitud.rechazada,
    );
    final saved = await repository.getSolicitudAlumnoById(request.id);
    expect(saved?.estado, EstadoSolicitud.rechazada);
    expect(saved?.updatedByOperatorId, operator.id);
    expect(saved?.areaId, primary.id);
  });

  test('sólo lectura y manipulación de área no deciden solicitud', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final secondary = await area(institution, 'secundaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'Lector',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: operator.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institution,
      operadorId: operator.id,
      capacidades: {CapacidadInstitucional.requestsRead},
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: operator.id,
    );
    final request = pendingRequest(primary.id);
    await SolicitudesRepositoryPrefs().saveSolicitudAlumno(request);
    for (final attemptedArea in [primary.id, secondary.id]) {
      await expectLater(
        SolicitudesService.responderSolicitudInstitucional(
          solicitudId: request.id,
          institucionId: institution,
          areaId: attemptedArea,
          nuevoEstado: EstadoSolicitud.rechazada,
        ),
        throwsA(isA<SolicitudesException>()),
      );
    }
  });

  test('evento autorizado conserva creador y última modificación', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final ownerOp = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: ownerOp.id,
    );
    await CalendarioService.addEventoInstitucional(calendarEvent(primary.id));
    final saved = (await CalendarioService.getEventos(
      ownerAccountId: owner,
    )).single;
    expect(saved.createdByOperatorId, ownerOp.id);
    expect(saved.updatedByOperatorId, ownerOp.id);
    expect(saved.areaId, primary.id);
  });

  test('modificación de grupos autorizada conserva actor y área', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final ownerOp = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: ownerOp.id,
    );
    final group = GrupoInstitucional(
      id: 'group-1',
      institucionId: institution,
      actividadNombre: 'Primaria',
      nombreGrupo: '1° A',
      cupoMaximo: 20,
      cupoOcupado: 3,
      estado: EstadoCupo.disponible,
    );
    await InstitucionGruposAutorizacionService.guardarCurriculares(
      institucionId: institution,
      areaId: primary.id,
      grupos: [group],
    );
    final saved = (await helpers.cargarGruposInstitucion(institution)).single;
    expect(saved.updatedByOperatorId, ownerOp.id);
    expect(saved.areaId, primary.id);
    expect(saved.cupoOcupado, 3);
  });

  test('grupo cruzado se rechaza sin modificar almacenamiento', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final ownerOp = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: ownerOp.id,
    );
    final foreign = GrupoInstitucional(
      id: 'foreign-group',
      institucionId: otherInstitution,
      actividadNombre: 'Primaria',
      nombreGrupo: 'Ajeno',
      cupoMaximo: 20,
      cupoOcupado: 0,
      estado: EstadoCupo.disponible,
    );
    await expectLater(
      InstitucionGruposAutorizacionService.guardarCurriculares(
        institucionId: institution,
        areaId: primary.id,
        grupos: [foreign],
      ),
      throwsStateError,
    );
    expect(await helpers.cargarGruposInstitucion(institution), isEmpty);
  });

  test('evento histórico sin actor continúa legible', () {
    final historical = EventoCalendario.fromMap(
      calendarEvent('area-historical').toMap()
        ..remove('createdByOperatorId')
        ..remove('updatedByOperatorId'),
    );
    expect(historical.createdByOperatorId, isNull);
    expect(historical.updatedByOperatorId, isNull);
  });

  test('comunicación autorizada conserva operador emisor', () async {
    await seedStudentIdentity();
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final ownerOp = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: ownerOp.id,
    );
    final student = pendingRequest(
      primary.id,
    ).copyWith(estado: EstadoSolicitud.confirmada);
    final emitted = await InstitucionEmisionesService.instance
        .emitirEventoEspecialAutorizado(
          institucionId: institution,
          institucionNombre: 'Institución',
          confirmados: [student],
          esCurricular: true,
          areaId: primary.id,
          inicio: DateTime(2026, 9, 18),
          titulo: 'Comunicado',
          descripcion: 'Mensaje',
          tipoEspecial: TipoEventoEspecial.otro,
        );
    expect(emitted, isNotEmpty);
    final raw = await AlumnoService.instance.getCalendarioRaw(
      ownerAccountId: student.ownerAccountId!,
      perfilId: student.perfilId!,
    );
    expect(raw.single['emittedByOperatorId'], ownerOp.id);
  });

  test('operador sin communications.write no emite', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'Sin emisión',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: operator.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: operator.id,
    );
    await expectLater(
      InstitucionEmisionesService.instance.emitirEventoEspecialAutorizado(
        institucionId: institution,
        institucionNombre: 'Institución',
        confirmados: [pendingRequest(primary.id)],
        esCurricular: true,
        areaId: primary.id,
        inicio: DateTime(2026, 9, 18),
        titulo: 'No autorizado',
        descripcion: '',
        tipoEspecial: TipoEventoEspecial.otro,
      ),
      throwsStateError,
    );
  });

  test('logout elimina autorización activa', () async {
    await institutionalSession();
    final primary = await area(institution, 'primaria');
    final ownerOp = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institution,
      operadorId: ownerOp.id,
    );
    await SessionService.logout();
    expect(
      await InstitucionOperadoresService.instance.autorizarActivo(
        institucionId: institution,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.calendarWrite,
      ),
      isNull,
    );
  });
}
