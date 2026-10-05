import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/models/extracurriculares/grupo_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/services/institucion_grupos_autorizacion_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';

GrupoInstitucional group({
  String id = 'grado',
  String? area,
  EstadoCupo state = EstadoCupo.disponible,
}) => GrupoInstitucional(
  id: id,
  institucionId: 'escuela',
  actividadNombre: 'Primaria',
  nombreGrupo: '1 A',
  aula: 'Primaria • 1 A',
  turno: 'manana • 08:00-12:00',
  cupoMaximo: 2,
  cupoOcupado: 0,
  estado: state,
  areaId: area,
);

SolicitudAlumno request(String id, {bool extra = false}) => SolicitudAlumno(
  id: id,
  ownerAccountId: 'familia-$id',
  perfilId: 'alumno-$id',
  alumnoDocumento: '12345678',
  institucionId: 'escuela',
  institucionNombre: 'Escuela',
  actividadNombre: extra ? 'Taller' : 'Primaria',
  grupoCurricularId: extra ? '' : 'grado',
  aula: extra ? 'Inicial' : 'Primaria • 1 A',
  turno: extra ? 'tarde' : 'manana • 08:00-12:00',
  moduleKey: extra ? 'otros' : '',
  esCurricular: !extra,
  estado: EstadoSolicitud.confirmada,
  fechaCreacion: DateTime(2026),
  fechaUltimoCambio: DateTime(2026),
  dedupKey: id,
);

Future<String> areaSession(String name) async {
  final area = (await InstitucionAreasService.instance.resolverYGuardar(
    institucionId: 'escuela',
    tipo: TipoAreaOperativa.curricular,
    claveOrigen: name,
    nombre: name,
  ))!;
  await SessionService.setSession(
    userId: 'escuela',
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId('propietario');
  final operator = await InstitucionOperadoresService.instance
      .asegurarPropietario(
        institucionId: 'escuela',
        ownerAccountId: 'propietario',
        perfilInstitucionId: 'escuela',
        nombreVisible: 'Propietario ficticio',
      );
  await InstitucionOperadoresService.instance.asignarArea(
    institucionId: 'escuela',
    operadorId: operator.id,
    areaId: area.id,
  );
  expect(
    await InstitucionContextoOperativoService.instance.activarContextoOperativo(
      institucionId: 'escuela',
      ownerAccountId: 'propietario',
      areaId: area.id,
      operadorId: operator.id,
    ),
    isNotNull,
  );
  return area.id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });

  test(
    'lectura curricular no ofrece suspendidos ni cupos consumidos por confirmadas',
    () async {
      await ih.guardarGruposInstitucion('escuela', [
        group(),
        group(id: 'suspendido', state: EstadoCupo.suspendido),
        group(id: 'cerrado-inconsistente', state: EstadoCupo.completo),
      ]);
      final repo = SolicitudesRepositoryPrefs();
      await repo.saveSolicitudAlumno(request('uno'));
      var read = await SolicitudesService.gruposCurricularesParaAlumno(
        'escuela',
      );
      expect(read.map((g) => g.id), ['grado']);
      expect(read.single.cuposDisponibles, 1);
      await repo.saveSolicitudAlumno(request('dos'));
      read = await SolicitudesService.gruposCurricularesParaAlumno('escuela');
      expect(read.single.tieneCuposDisponibles, isFalse);
      expect(
        (await ih.cargarGruposInstitucion('escuela')).first.cupoOcupado,
        0,
        reason: 'Consultar no reescribe los grupos',
      );
    },
  );

  test(
    'extra usa el máximo y conserva cupo no gestionado e inactividad',
    () async {
      await ExtracurricularesService.instance.guardarGrupos('escuela', [
        for (final id in ['taller', 'libre', 'pausado'])
          GrupoExtracurricular(
            id: id,
            institucionId: 'escuela',
            bloque: BloqueExtracurricular.otros,
            actividadNombre: 'Taller',
            nombreGrupo: id == 'taller' ? 'Inicial' : id,
            turno: 'tarde',
            cupoMaximo: id == 'libre' ? 0 : 2,
            cupoOcupado: 1,
            activo: id != 'pausado',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
      ]);
      final repo = SolicitudesRepositoryPrefs();
      await repo.saveSolicitudAlumno(request('uno', extra: true));
      var read = await SolicitudesService.gruposExtracurricularesParaAlumno(
        'escuela',
      );
      expect(read.singleWhere((g) => g.id == 'taller').cuposDisponibles, 1);
      await repo.saveSolicitudAlumno(request('dos', extra: true));
      read = await SolicitudesService.gruposExtracurricularesParaAlumno(
        'escuela',
      );
      expect(read.singleWhere((g) => g.id == 'taller').tieneCupos, isFalse);
      expect(read.singleWhere((g) => g.id == 'libre').tieneCupos, isTrue);
      expect(read.singleWhere((g) => g.id == 'pausado').tieneCupos, isFalse);
    },
  );

  test(
    'guardar y eliminar en un área conserva intactos los grupos de otra',
    () async {
      final a = await areaSession('primaria');
      final b = await areaSession('secundaria');
      await areaSession('primaria');
      final other = group(id: 'secundario', area: b);
      await ih.guardarGruposInstitucion('escuela', [group(area: a), other]);
      await InstitucionGruposAutorizacionService.guardarCurriculares(
        institucionId: 'escuela',
        areaId: a,
        grupos: [group(area: a)],
      );
      expect(
        (await ih.cargarGruposInstitucion(
          'escuela',
        )).singleWhere((g) => g.id == other.id).toMap(),
        other.toMap(),
      );
      await expectLater(
        InstitucionGruposAutorizacionService.guardarCurriculares(
          institucionId: 'escuela',
          areaId: a,
          grupos: [other],
        ),
        throwsStateError,
      );
      await InstitucionGruposAutorizacionService.guardarCurriculares(
        institucionId: 'escuela',
        areaId: a,
        grupos: [],
      );
      expect(
        (await ih.cargarGruposInstitucion('escuela')).single.toMap(),
        other.toMap(),
      );
    },
  );

  test(
    'solicitud recibe área del grupo y otra área no puede confirmarla',
    () async {
      final a = await areaSession('primaria');
      final b = await areaSession('secundaria');
      await ih.guardarGruposInstitucion('escuela', [group(area: a)]);
      await SolicitudesService.crearSolicitudDesdePerfil(
        ownerAccountId: 'familia',
        perfilId: 'alumna',
        solicitudAlumno: request('asignada'),
      );
      final saved = (await SolicitudesService.obtenerSolicitudesParaInstitucion(
        institucionId: 'escuela',
      )).single;
      expect(saved.areaId, a);
      await expectLater(
        SolicitudesService.responderSolicitudInstitucional(
          solicitudId: saved.id,
          institucionId: 'escuela',
          areaId: b,
          nuevoEstado: EstadoSolicitud.confirmada,
        ),
        throwsA(isA<SolicitudesException>()),
      );
      expect(
        (await ih.cargarGruposInstitucion('escuela')).single.cupoOcupado,
        0,
      );
    },
  );

  test('cuenta e institución nuevas pueden leer solicitudes vacías', () async {
    expect(
      await SolicitudesService.cargarSolicitudesPorOwner(
        ownerAccountId: 'familia-nueva',
      ),
      isEmpty,
    );
    expect(
      await SolicitudesService.obtenerPendientesParaInstitucion(
        institucionId: 'escuela-nueva',
      ),
      isEmpty,
    );
  });

  test(
    'turno visible del alumno puede confirmarse sin cambiar el horario',
    () async {
      await ih.guardarGruposInstitucion('escuela', [
        GrupoInstitucional(
          id: 'grado',
          institucionId: 'escuela',
          actividadNombre: 'Primaria',
          nombreGrupo: '1 A',
          aula: 'Primaria • 1 A',
          turno: 'manana • 08:00-12:00',
          cupoMaximo: 2,
          cupoOcupado: 0,
          estado: EstadoCupo.disponible,
        ),
      ]);
      await SolicitudesService.crearSolicitudDesdePerfil(
        ownerAccountId: 'familia',
        perfilId: 'alumna',
        solicitudAlumno: SolicitudAlumno(
          id: 'solicitud',
          alumnoDocumento: '12345678',
          institucionId: 'escuela',
          institucionNombre: 'Escuela',
          actividadNombre: 'Primaria • 1 A',
          grupoCurricularId: 'grado',
          aula: 'Primaria • 1 A',
          turno: 'Mañana • 08:00-12:00',
          esCurricular: true,
          estado: EstadoSolicitud.pendiente,
          fechaCreacion: DateTime(2026),
          fechaUltimoCambio: DateTime(2026),
          dedupKey: '',
        ),
      );
      await SolicitudesService.responderSolicitud(
        solicitudId: 'solicitud',
        nuevoEstado: EstadoSolicitud.confirmada,
      );
      expect(
        (await ih.cargarGruposInstitucion('escuela')).single.cupoOcupado,
        1,
      );
    },
  );
}
