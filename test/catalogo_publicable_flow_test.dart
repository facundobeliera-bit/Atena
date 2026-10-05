import 'dart:convert';
import 'package:atena_app/models/extracurriculares/grupo_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/actividad_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/services/catalogo_publicable_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/screens/instituciones/institucion_catalogo_page.dart';
import 'package:atena_app/ui/atena_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';

const instId = 'catalog-institution-A';
late String areaId, otherAreaId, operatorId;

GrupoInstitucional group(
  String id, {
  String? area,
  String name = 'Primero A',
  int occupied = 2,
  int capacity = 20,
}) => GrupoInstitucional(
  id: id,
  institucionId: instId,
  actividadNombre: 'Primaria',
  nombreGrupo: name,
  cupoMaximo: capacity,
  cupoOcupado: occupied,
  estado: EstadoCupo.disponible,
  turno: 'Mañana · 08:00–12:00',
  areaId: area ?? areaId,
  updatedByOperatorId: 'private-operator-not-for-publication',
);

/// Contract double only: no network, Supabase client or privileged credentials.
class MemoryServer implements TransporteCatalogo {
  int version = 0, calls = 0;
  bool loseFirstReply = false, forgedReply = false;
  final receipts = <String, ConfirmacionCatalogo>{};
  @override
  Future<ConfirmacionCatalogo> publicar({
    required String institutionId,
    required String areaId,
    required String operationId,
    required int expectedVersion,
    required CatalogoPublicable catalogo,
  }) async {
    calls++;
    if (receipts.containsKey(operationId)) return receipts[operationId]!;
    if (version != expectedVersion) throw ConflictoCatalogo();
    final receipt = ConfirmacionCatalogo(
      institutionId: forgedReply ? 'foreign' : institutionId,
      areaId: areaId,
      operationId: operationId,
      fingerprint: catalogo.huella,
      version: ++version,
    );
    receipts[operationId] = receipt;
    if (loseFirstReply) {
      loseFirstReply = false;
      throw ConexionCatalogo();
    }
    return receipt;
  }
}

Future<void> seed() async {
  SharedPreferences.setMockInitialValues({});
  StorageService.instance.resetCache();
  await ih.upsertInstitucion(
    Institucion(
      id: instId,
      nombre: 'Escuela Ficticia',
      cuit: 'private-cuit',
      direccion: 'private-address',
      pais: 'Argentina',
      provincia: 'Buenos Aires',
      ciudad: 'La Plata',
      modalidad: ModalidadCursado.presencial,
      email: 'private@example.invalid',
      telefono: 'private-phone',
      curricular: true,
      extracurricular: false,
      tipoInstitucion: TipoInstitucion.primaria,
      tipoPlan: 'prueba',
      estadoPlan: EstadoPlanInstitucion.enPrueba,
      planInicio: DateTime(2026),
      planFin: DateTime(2030),
    ),
  );
  final areas = InstitucionAreasService.instance;
  areaId = (await areas.resolverYGuardar(
    institucionId: instId,
    tipo: TipoAreaOperativa.curricular,
    claveOrigen: 'primaria',
    nombre: 'Primaria',
  ))!.id;
  otherAreaId = (await areas.resolverYGuardar(
    institucionId: instId,
    tipo: TipoAreaOperativa.curricular,
    claveOrigen: 'secundaria',
    nombre: 'Secundaria',
  ))!.id;
  operatorId = (await InstitucionOperadoresService.instance.crearLocal(
    institucionId: instId,
    nombreVisible: 'Operador ficticio',
  )).id;
  await InstitucionOperadoresService.instance.asignarArea(
    institucionId: instId,
    operadorId: operatorId,
    areaId: areaId,
  );
  await InstitucionOperadoresService.instance.setCapacidadesEnArea(
    institucionId: instId,
    operadorId: operatorId,
    areaId: areaId,
    capacidades: {
      CapacidadInstitucional.groupsRead,
      CapacidadInstitucional.groupsWrite,
    },
  );
  await SessionService.setSession(
    userId: instId,
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId('owner-A');
  expect(
    await InstitucionContextoOperativoService.instance.activarContextoOperativo(
      institucionId: instId,
      ownerAccountId: 'owner-A',
      areaId: areaId,
      operadorId: operatorId,
    ),
    isNotNull,
  );
  await ih.guardarGruposInstitucion(instId, [group('group-A')]);
}

Future<void> request(
  String id, {
  String institution = instId,
  String groupId = 'group-A',
  EstadoSolicitud state = EstadoSolicitud.confirmada,
  bool curricular = true,
}) => SolicitudesRepositoryPrefs().saveSolicitudAlumno(
  SolicitudAlumno(
    id: id,
    ownerAccountId: 'private-owner-$id',
    perfilId: 'private-profile-$id',
    alumnoDocumento: 'private-document-$id',
    institucionId: institution,
    institucionNombre: 'Ficticia',
    actividadNombre: curricular ? 'Primaria' : 'Taller ficticio',
    esCurricular: curricular,
    grupoCurricularId: curricular ? groupId : '',
    aula: curricular ? 'Primero A' : 'Taller A',
    turno: curricular ? 'Mañana · 08:00–12:00' : 'Sábados 10:00',
    moduleKey: curricular ? '' : 'otros',
    estado: state,
    fechaCreacion: DateTime(2026),
    fechaUltimoCambio: DateTime(2026),
    dedupKey: '',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(seed);
  tearDown(() => StorageService.instance.resetCache());

  test(
    'ocupación efectiva usa máximo sin sumar dos veces ni divulgar solicitudes',
    () async {
      for (var i = 0; i < 4; i++) {
        await request('confirmed-$i');
      }
      await request('pending', state: EstadoSolicitud.pendiente);
      await request('other', groupId: 'other-group');
      await request('foreign', institution: 'institution-B');
      final service = CatalogoPublicableService();
      var value = await service.consultar(instId, areaId);
      expect(value.catalogo.grupos.single['occupied'], 4);
      expect(value.catalogo.grupos.single['available'], 16);
      expect(value.catalogo.json, isNot(contains('private-')));
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', occupied: 8),
      ]);
      value = await service.consultar(instId, areaId);
      expect(value.catalogo.grupos.single['occupied'], 8);
      expect(value.catalogo.grupos.single['available'], 12);
    },
  );

  test(
    'capacidad cero y confirmaciones completas no se anuncian disponibles',
    () async {
      final service = CatalogoPublicableService();
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', capacity: 0, occupied: 0),
      ]);
      await expectLater(
        service.consultar(instId, areaId),
        throwsFormatException,
      );
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', capacity: 2, occupied: 0),
      ]);
      await request('one');
      await request('two');
      final value = await service.consultar(instId, areaId);
      expect(value.catalogo.grupos.single['available'], 0);
      expect(value.catalogo.grupos.single['availability'], 'full');
      await ih.guardarGruposInstitucion(instId, []);
      expect(
        (await service.consultar(instId, areaId)).catalogo.grupos,
        isEmpty,
      );
    },
  );

  test(
    'confirmadas sobre capacidad bloquean preparación sin ocultar inconsistencia',
    () async {
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', capacity: 1, occupied: 0),
      ]);
      await request('one');
      await request('two');
      await expectLater(
        CatalogoPublicableService().preparar(instId, areaId),
        throwsFormatException,
      );
      expect((await ih.cargarGruposInstitucion(instId)).single.cupoOcupado, 0);
    },
  );

  test(
    'preparación conserva fecha en reintentos y recibo tiene fecha separada',
    () async {
      final service = CatalogoPublicableService(transporte: MemoryServer());
      await service.preparar(instId, areaId);
      final first = await service.consultar(instId, areaId);
      expect(first.preparadoEn, isNotNull);
      expect(first.confirmadoEn, isNull);
      await service.preparar(instId, areaId);
      expect(
        (await service.consultar(instId, areaId)).preparadoEn,
        first.preparadoEn,
      );
      await service.sincronizar(instId, areaId);
      expect((await service.consultar(instId, areaId)).confirmadoEn, isNotNull);
    },
  );

  test(
    'proyección real: disponibilidad, turno, área y exclusión de datos privados',
    () async {
      await ih.guardarGruposInstitucion(instId, [
        group('group-A'),
        group('foreign-group', area: otherAreaId, name: 'No divulgar'),
      ]);
      final value = await CatalogoPublicableService().consultar(instId, areaId);
      expect(value.estado, EstadoCatalogo.local);
      expect(value.catalogo.grupos.single['available'], 18);
      expect(value.catalogo.grupos.single['schedule'], contains('08:00'));
      for (final secret in ['private-', 'owner-A', 'No divulgar', operatorId]) {
        expect(value.catalogo.json, isNot(contains(secret)));
      }
    },
  );

  test(
    'renombrar conserva ID; instituciones y tipos distintos no colisionan',
    () async {
      final service = CatalogoPublicableService();
      final before = await service.consultar(instId, areaId);
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', name: 'Nombre nuevo'),
      ]);
      final after = await service.consultar(instId, areaId);
      expect(
        after.catalogo.grupos.single['id'],
        before.catalogo.grupos.single['id'],
      );
      expect(after.catalogo.huella, isNot(before.catalogo.huella));
      expect(
        await CatalogoPublicableService.identificador('group', 'A', 'x'),
        isNot(await CatalogoPublicableService.identificador('group', 'B', 'x')),
      );
      expect(
        await CatalogoPublicableService.identificador('group', 'A', 'x'),
        isNot(
          await CatalogoPublicableService.identificador('activity', 'A', 'x'),
        ),
      );
    },
  );

  test(
    'preparación persistente e idempotente, incluso dos pulsaciones simultáneas',
    () async {
      final service = CatalogoPublicableService();
      await Future.wait([
        service.preparar(instId, areaId),
        service.preparar(instId, areaId),
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('atena_catalog_outbox_')),
        hasLength(1),
      );
      final value = await CatalogoPublicableService().consultar(instId, areaId);
      expect(value.estado, EstadoCatalogo.pendiente);
      expect(value.versionConfirmada, 0);
      expect(await ih.cargarGruposInstitucion(instId), hasLength(1));
    },
  );

  test(
    'eliminar último grupo prepara [] sin recuperar datos históricos',
    () async {
      final service = CatalogoPublicableService();
      await service.preparar(instId, areaId);
      await ih.guardarGruposInstitucion(instId, []);
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.cambiosLocales,
      );
      await service.preparar(instId, areaId);
      final value = await service.consultar(instId, areaId);
      expect(value.catalogo.vacio, isTrue);
      expect(value.estado, EstadoCatalogo.pendiente);
    },
  );

  test(
    'institución ajena, área ajena y logout no acceden al catálogo',
    () async {
      final service = CatalogoPublicableService();
      await expectLater(
        service.consultar('institution-B', areaId),
        throwsStateError,
      );
      await expectLater(
        service.consultar(instId, otherAreaId),
        throwsStateError,
      );
      await SessionService.logout();
      await expectLater(service.consultar(instId, areaId), throwsStateError);
    },
  );

  test(
    'lectura sin escritura y revocación posterior no preparan ni envían',
    () async {
      final remote = MemoryServer();
      final service = CatalogoPublicableService(transporte: remote);
      await service.preparar(instId, areaId);
      await InstitucionOperadoresService.instance.setCapacidadesEnArea(
        institucionId: instId,
        operadorId: operatorId,
        areaId: areaId,
        capacidades: {CapacidadInstitucional.groupsRead},
      );
      expect((await service.consultar(instId, areaId)).catalogo.vacio, isFalse);
      await expectLater(service.preparar(instId, areaId), throwsStateError);
      await expectLater(service.sincronizar(instId, areaId), throwsStateError);
      expect(remote.calls, 0);
    },
  );

  test(
    'grupos sin área o sobreocupados no se publican ni normalizan',
    () async {
      final unscoped = group('old')..areaId = null;
      await ih.guardarGruposInstitucion(instId, [unscoped]);
      await expectLater(
        CatalogoPublicableService().preparar(instId, areaId),
        throwsFormatException,
      );
      await ih.guardarGruposInstitucion(instId, [
        group('overbooked', occupied: 25),
      ]);
      await expectLater(
        CatalogoPublicableService().preparar(instId, areaId),
        throwsFormatException,
      );
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('grupos_$instId')!) as List;
      expect(stored.single['cupoOcupado'], 25);
    },
  );

  test('dato corrupto no se convierte en catálogo vacío', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('grupos_$instId', '{invalid');
    await expectLater(
      CatalogoPublicableService().consultar(instId, areaId),
      throwsFormatException,
    );
    expect(prefs.getString('grupos_$instId'), '{invalid');
  });

  test('sin adaptador configurado no existe publicación remota', () async {
    final service = CatalogoPublicableService();
    await service.preparar(instId, areaId);
    await expectLater(service.sincronizar(instId, areaId), throwsStateError);
    expect(
      (await service.consultar(instId, areaId)).estado,
      EstadoCatalogo.pendiente,
    );
  });

  test(
    'acuse válido confirma versión, reintento no duplica y cambios usan versión siguiente',
    () async {
      final remote = MemoryServer();
      final service = CatalogoPublicableService(transporte: remote);
      await service.preparar(instId, areaId);
      await service.sincronizar(instId, areaId);
      await service.sincronizar(instId, areaId);
      expect(remote.version, 1);
      expect(remote.calls, 1);
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.confirmado,
      );
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', name: 'Editado'),
      ]);
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.cambiosLocales,
      );
      await service.preparar(instId, areaId);
      await service.sincronizar(instId, areaId);
      expect((await service.consultar(instId, areaId)).versionConfirmada, 2);
    },
  );

  test(
    'respuesta perdida conserva clave y contenido para reintento después de reconstruir',
    () async {
      final remote = MemoryServer()..loseFirstReply = true;
      final service = CatalogoPublicableService(transporte: remote);
      await service.preparar(instId, areaId);
      await expectLater(
        service.sincronizar(instId, areaId),
        throwsA(isA<ConexionCatalogo>()),
      );
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.errorConexion,
      );
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', name: 'Cambio durante reintento'),
      ]);
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.errorConexion,
      );
      await expectLater(service.preparar(instId, areaId), throwsStateError);
      await CatalogoPublicableService(
        transporte: remote,
      ).sincronizar(instId, areaId);
      expect(remote.version, 1);
      expect(remote.receipts, hasLength(1));
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.cambiosLocales,
      );
    },
  );

  test(
    'conflicto no sobrescribe servidor ni se resuelve automáticamente',
    () async {
      final remote = MemoryServer()..version = 7;
      final service = CatalogoPublicableService(transporte: remote);
      await service.preparar(instId, areaId);
      await expectLater(
        service.sincronizar(instId, areaId),
        throwsA(isA<ConflictoCatalogo>()),
      );
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.conflicto,
      );
      await ih.guardarGruposInstitucion(instId, [
        group('group-A', name: 'Otro cambio'),
      ]);
      expect(
        (await service.consultar(instId, areaId)).estado,
        EstadoCatalogo.conflicto,
      );
      await expectLater(
        service.preparar(instId, areaId),
        throwsA(isA<ConflictoCatalogo>()),
      );
      expect(remote.version, 7);
    },
  );

  test('acuse de otra institución no confirma la preparación', () async {
    final service = CatalogoPublicableService(
      transporte: MemoryServer()..forgedReply = true,
    );
    await service.preparar(instId, areaId);
    await expectLater(
      service.sincronizar(instId, areaId),
      throwsA(isA<ConexionCatalogo>()),
    );
    expect((await service.consultar(instId, areaId)).versionConfirmada, 0);
  });

  test(
    'journal corrupto no se descarta ni convierte en versión inicial',
    () async {
      final service = CatalogoPublicableService();
      await service.preparar(instId, areaId);
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getKeys().singleWhere(
        (k) => k.startsWith('atena_catalog_outbox_'),
      );
      await prefs.setString(key, jsonEncode({'version': 'bad'}));
      await expectLater(
        service.consultar(instId, areaId),
        throwsFormatException,
      );
      expect(prefs.getString(key), jsonEncode({'version': 'bad'}));
      final incomplete = jsonEncode({'version': 1, 'state': 'confirmado'});
      await prefs.setString(key, incomplete);
      await expectLater(
        service.preparar(instId, areaId),
        throwsFormatException,
      );
      expect(prefs.getString(key), incomplete);
    },
  );

  test(
    'extracurricular conserva actividades y grupos sin inventar una relación por nombre',
    () async {
      final extraArea = (await InstitucionAreasService.instance
          .resolverYGuardar(
            institucionId: instId,
            tipo: TipoAreaOperativa.extracurricular,
            claveOrigen: 'otros',
            nombre: 'Talleres',
          ))!;
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: instId,
        operadorId: operatorId,
        areaId: extraArea.id,
      );
      await InstitucionOperadoresService.instance.setCapacidadesEnArea(
        institucionId: instId,
        operadorId: operatorId,
        areaId: extraArea.id,
        capacidades: {
          CapacidadInstitucional.groupsRead,
          CapacidadInstitucional.groupsWrite,
        },
      );
      await InstitucionContextoOperativoService.instance
          .activarContextoOperativo(
            institucionId: instId,
            ownerAccountId: 'owner-A',
            areaId: extraArea.id,
            operadorId: operatorId,
          );
      final institution = (await ih.cargarInstitucionPorId(instId))!;
      final now = DateTime(2026);
      await ih.upsertInstitucion(
        institution.copyWith(
          actividadesExtracurriculares: [
            ActividadExtracurricular(
              id: 'activity-existing',
              institucionId: instId,
              bloque: BloqueExtracurricular.otros,
              nombre: 'Taller ficticio',
              activa: true,
              cupoMaximo: 0,
              cupoOcupado: 0,
              createdAt: now,
              updatedAt: now,
              contacto: 'private-contact',
            ),
          ],
        ),
      );
      await ExtracurricularesService.instance.guardarGrupos(instId, [
        GrupoExtracurricular(
          id: 'group-extra-existing',
          institucionId: instId,
          bloque: BloqueExtracurricular.otros,
          actividadNombre: 'Taller ficticio',
          nombreGrupo: 'Taller A',
          cupoMaximo: 0,
          cupoOcupado: 3,
          activo: true,
          createdAt: now,
          updatedAt: now,
          areaId: extraArea.id,
          turno: 'Sábados 10:00',
        ),
      ]);
      for (var i = 0; i < 5; i++) {
        await request('extra-$i', curricular: false);
      }
      final value = await CatalogoPublicableService().consultar(
        instId,
        extraArea.id,
      );
      expect(value.catalogo.actividades, hasLength(1));
      expect(value.catalogo.datos['schema_version'], 2);
      expect(
        value.catalogo.actividades.single.keys,
        containsAll(['description', 'ages', 'price']),
      );
      expect(value.catalogo.grupos.single['available'], isNull);
      expect(value.catalogo.grupos.single['occupied'], 5);
      expect(value.catalogo.grupos.single['availability'], 'unmanaged');
      expect(value.catalogo.grupos.single['schedule'], 'Sábados 10:00');
      expect(value.catalogo.grupos.single.containsKey('activity_id'), isFalse);
      expect(value.catalogo.json, isNot(contains('private-contact')));
      final prefs = await SharedPreferences.getInstance();
      final key = ExtracurricularesService.kGruposExtracurriculares(instId);
      final raw = jsonDecode(prefs.getString(key)!) as List;
      raw.single['bloque'] = 'invalid-block';
      await prefs.setString(key, jsonEncode(raw));
      await expectLater(
        CatalogoPublicableService().consultar(instId, extraArea.id),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'grupo suspendido no anuncia sus plazas libres como vacantes disponibles',
    (tester) async {
      final suspended = group('group-A')..estado = EstadoCupo.suspendido;
      await ih.guardarGruposInstitucion(instId, [suspended]);
      await tester.pumpWidget(
        MaterialApp(
          theme: AtenaTheme.build(Brightness.light),
          home: InstitucionCatalogoPage(institucionId: instId, areaId: areaId),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('18 vacantes informadas'), findsNothing);
      expect(find.text('Inscripciones suspendidas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pantalla real prepara localmente, muestra estado y conserva la apariencia V1',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AtenaTheme.build(Brightness.light),
          home: InstitucionCatalogoPage(institucionId: instId, areaId: areaId),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sólo local'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Preparar versión local'), 200);
      await tester.tap(find.text('Preparar versión local'));
      await tester.pumpAndSettle();
      expect(find.text('Preparado · sincronización pendiente'), findsOneWidget);
      expect(
        (await CatalogoPublicableService().consultar(instId, areaId)).estado,
        EstadoCatalogo.pendiente,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
