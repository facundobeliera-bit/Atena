import 'dart:convert';

import 'package:atena_app/models/instituciones/grupo_curricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/alumno_instituciones_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Characterization uses real readers/writers. Red tests express the approved
// consistency contract, not assertions that preserve the current defect.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });

  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('C1 Gestión guarda y validación conserva el identificador', () async {
    final f = _Fixture('c1');
    await f.seed();
    await ih.guardarGruposInstitucion(f.institucionId, [f.actual]);
    final observed = await f.observe();
    expect(observed['gestion'], [f.actual.id]);
    expect(observed['validacion'], [f.actual.id]);
    expect(await ih.cargarGruposInstitucion(f.perfilAlumnoId), isEmpty);
  });

  test('C2 Alumno debe observar el grupo guardado por Gestión', () async {
    final f = _Fixture('c2');
    await f.seed();
    await ih.guardarGruposInstitucion(f.institucionId, [f.actual]);
    final observed = await f.observe();
    expect(observed['gestion'], [f.actual.id]);
    expect(observed['validacion'], [f.actual.id]);
    expect(observed['alumno'], [f.actual.id], reason: observed.toString());
  });

  for (final dedicatedKey in [false, true]) {
    final source = dedicatedKey ? 'clave histórica' : 'lista en Institucion';

    test('C3 $source: Gestión debe prevalecer sobre otro grupo', () async {
      final f = _Fixture(dedicatedKey ? 'c3-key' : 'c3-model');
      await f.seed(historical: true, dedicatedKey: dedicatedKey);
      await ih.guardarGruposInstitucion(f.institucionId, [f.actual]);
      final observed = await f.observe();
      expect(observed['gestion'], [f.actual.id]);
      expect(observed['validacion'], [f.actual.id]);
      expect(observed['alumno'], [f.actual.id], reason: observed.toString());
    });

    test(
      'C4 $source: ausencia y eliminación explícita son distintas',
      () async {
        final f = _Fixture(dedicatedKey ? 'c4-key' : 'c4-model');
        await f.seed(historical: true, dedicatedKey: dedicatedKey);
        final prefs = await SharedPreferences.getInstance();
        final key = ih.kGruposInstitucion(f.institucionId);
        expect(prefs.containsKey(key), isFalse);
        expect(prefs.getString(key), isNull);
        final before = await f.observe();
        // The old characterization observed empty here. The approved contract
        // now requires all readers to share the historical fallback.
        expect(before['gestion'], [f.historical.id]);
        expect(before['validacion'], [f.historical.id]);
        expect(before['alumno'], [f.historical.id]);

        await ih.guardarGruposInstitucion(f.institucionId, []);
        expect(prefs.containsKey(key), isTrue);
        expect(jsonDecode(prefs.getString(key)!), isEmpty);
        // Reload through production storage to exclude an in-memory artifact.
        StorageService.instance.resetCache();
        final after = await f.observe();
        expect(after['gestion'], isEmpty);
        expect(after['validacion'], isEmpty);
        expect(after['alumno'], isEmpty, reason: after.toString());
      },
    );
  }

  test('C5 Storage distingue clave inexistente de lista vacía', () async {
    final f = _Fixture('c5');
    await f.seed();
    final key = ih.kGruposInstitucion(f.institucionId);
    expect(await StorageService.instance.getString(key), isNull);
    expect(await ih.cargarGruposInstitucion(f.institucionId), isEmpty);
    await ih.guardarGruposInstitucion(f.institucionId, []);
    StorageService.instance.resetCache();
    expect(await StorageService.instance.getString(key), '[]');
    expect(await ih.cargarGruposInstitucion(f.institucionId), isEmpty);
  });

  test(
    'C6 históricos contradictorios: institución prevalece, sin escrituras',
    () async {
      final f = _Fixture('c6');
      await f.seed(historical: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ih.kGruposCurricularesInstitucion(f.institucionId),
        jsonEncode([
          GrupoCurricular(
            id: 'otro-historico',
            nombreCurso: 'Otro curso',
          ).toMap(),
        ]),
      );
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final observed = await f.observe();
      for (final ids in observed.values) {
        expect(ids, [f.historical.id]);
      }
      final inst = Institucion.fromJson(
        prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
      );
      final hydrated = await ih.hidratarInstitucionConGruposCurriculares(inst);
      expect(hydrated.gruposCurriculares.single.id, f.historical.id);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    },
  );

  test(
    'C7 campos actuales completos, hidratación sin mutar ni migrar',
    () async {
      final f = _Fixture('c7');
      await f.seed(historical: true);
      await ih.guardarGruposInstitucion(f.institucionId, [f.actual]);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final inst = Institucion.fromJson(
        prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
      );
      final hydrated = await ih.hidratarInstitucionConGruposCurriculares(inst);
      for (final groups in [
        hydrated.gruposCurriculares,
        await ih.cargarGruposCurricularesInstitucion(f.institucionId),
        await SolicitudesService.obtenerGruposCurricularesInstitucion(
          f.institucionId,
        ),
      ]) {
        final g = groups.single;
        expect(g.id, f.actual.id);
        expect(g.nombreCurso, f.actual.nombreGrupo);
        expect(g.turno, TurnoCurricular.tarde);
        expect(g.horaInicio, '13:15');
        expect(g.horaFin, '17:45');
        expect(g.cuposTotales, 20);
        expect(g.cuposOcupados, 3);
      }
      expect(
        (await ih.cargarGruposInstitucion(f.institucionId)).single.toMap(),
        f.actual.toMap(),
      );
      expect(inst.gruposCurriculares.single.id, f.historical.id);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    },
  );

  test(
    'C8 instituciones aisladas y solicitud con grupo ajeno rechazada',
    () async {
      final a = _Fixture('c8-a');
      final b = _Fixture('c8-b');
      await a.seed();
      await b.seed();
      await ih.guardarGruposInstitucion(a.institucionId, [a.actual]);
      await ih.guardarGruposInstitucion(b.institucionId, [b.actual]);
      for (final f in [a, b]) {
        for (final ids in (await f.observe()).values) {
          expect(ids, [f.actual.id]);
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      for (final gid in [b.actual.id, 'grupo-inexistente']) {
        await expectLater(
          SolicitudesService.crearSolicitudDesdePerfil(
            ownerAccountId: 'cuenta-c8-a',
            perfilId: a.perfilAlumnoId,
            solicitudAlumno: SolicitudAlumno(
              id: 'solicitud-$gid',
              alumnoDocumento: 'documento-c8-a',
              institucionId: a.institucionId,
              institucionNombre: 'Institución A',
              actividadNombre: 'Primaria',
              esCurricular: true,
              estado: EstadoSolicitud.pendiente,
              fechaCreacion: DateTime(2026),
              fechaUltimoCambio: DateTime(2026),
              dedupKey: '',
              grupoCurricularId: gid,
            ),
          ),
          throwsA(
            isA<SolicitudesException>().having(
              (e) => e.code,
              'code',
              'invalid_payload',
            ),
          ),
        );
      }
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    },
  );

  test(
    'C10 curso/año procede de aula, no del nombre libre del grupo',
    () async {
      final f = _Fixture('c10');
      await f.seed();
      final g = f.actual;
      g.aula = 'Primaria • 3 año';
      await ih.guardarGruposInstitucion(f.institucionId, [g]);
      for (final groups in [
        await ih.cargarGruposCurricularesInstitucion(f.institucionId),
        await SolicitudesService.obtenerGruposCurricularesInstitucion(
          f.institucionId,
        ),
      ]) {
        expect(groups.single.nombreCurso, g.aula);
        expect(groups.single.id, g.id);
      }
      expect(
        (await ih.cargarGruposInstitucion(f.institucionId)).single.nombreGrupo,
        g.nombreGrupo,
      );
    },
  );

  for (final cupos in [(0, 0), (2, 3)]) {
    test('C11 cupos no representables sin alteración: $cupos', () async {
      final f = _Fixture('c11');
      await f.seed(historical: true);
      final g = f.actual;
      g.cupoMaximo = cupos.$1;
      g.cupoOcupado = cupos.$2;
      await ih.guardarGruposInstitucion(f.institucionId, [g]);
      await expectLater(
        ih.cargarGruposInstitucion(f.institucionId),
        throwsFormatException,
      );
      await expectLater(
        ih.cargarGruposCurricularesInstitucion(f.institucionId),
        throwsFormatException,
      );
      await expectLater(
        SolicitudesService.obtenerGruposCurricularesInstitucion(
          f.institucionId,
        ),
        throwsFormatException,
      );
    });
  }

  test('C12 buscador: corrupción no recupera vacantes históricas', () async {
    final f = _Fixture('c12');
    await f.seed(historical: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ih.kGruposInstitucion(f.institucionId), '{');
    final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final vacancies = await AlumnoInstitucionesSearchService.search(
      const AlumnoInstitucionSearchFilters(
        scope: AlumnoBusquedaScope.curricular,
        soloConVacantes: true,
      ),
    );
    expect(vacancies, isEmpty);
    final general = await AlumnoInstitucionesSearchService.search(
      const AlumnoInstitucionSearchFilters(
        scope: AlumnoBusquedaScope.curricular,
      ),
    );
    expect(general.single.institucion.id, f.institucionId);
    expect(general.single.institucion.gruposCurriculares, isEmpty);
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
  });

  for (final dedicated in [false, true]) {
    test(
      'C13 persistido B prevalece sobre caller A; clave dedicada=$dedicated',
      () async {
        final f = _Fixture('c13');
        await f.seed(historical: true);
        final prefs = await SharedPreferences.getInstance();
        final inst = Institucion.fromJson(
          prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
        );
        final caller = inst.copyWith(
          gruposCurriculares: [
            GrupoCurricular(id: 'caller-A', nombreCurso: 'A'),
          ],
        );
        if (dedicated) {
          await prefs.setString(
            ih.kGruposCurricularesInstitucion(f.institucionId),
            jsonEncode([
              GrupoCurricular(id: 'dedicado-C', nombreCurso: 'C').toMap(),
            ]),
          );
        }
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        expect(
          (await ih.hidratarInstitucionConGruposCurriculares(
            caller,
          )).gruposCurriculares.single.id,
          f.historical.id,
        );
        for (final ids in (await f.observe()).values) {
          expect(ids, [f.historical.id]);
        }
        expect(caller.gruposCurriculares.single.id, 'caller-A');
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      },
    );
  }

  for (final clear in [false, true]) {
    test('C14 migración explícita; limpiar clave=$clear', () async {
      final f = _Fixture('c14');
      await f.seed(historical: true, dedicatedKey: true);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final migrated = await ih.migrarPersistirLegacyEnInstitucion(
        f.institucionId,
        clearLegacyKeyCurricular: clear,
      );
      expect(migrated!.gruposCurriculares.single.id, f.historical.id);
      final persisted = Institucion.fromJson(
        prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
      );
      expect(persisted.gruposCurriculares.single.id, f.historical.id);
      final legacyKey = ih.kGruposCurricularesInstitucion(f.institucionId);
      expect(prefs.getString(legacyKey), clear ? '' : before[legacyKey]);
      expect(
        prefs.containsKey(ih.kGruposInstitucion(f.institucionId)),
        isFalse,
      );
      final allowed = {
        ih.kInstitucionesRegistradas,
        ih.kPerfilInstitucionPorId(f.institucionId),
        'atena_institucion_by_id_${f.institucionId}',
        'atena_institucion_by_id_cuit-${f.caseId}',
        ih.kInstitucionesSearchIndex,
        if (clear) legacyKey,
      };
      for (final key in {...before.keys, ...prefs.getKeys()}) {
        if (!allowed.contains(key)) {
          expect(prefs.get(key), before[key], reason: key);
        }
      }
    });
  }

  test('C15 hidratación rechaza pedidos de escritura, sin efectos', () async {
    final f = _Fixture('c15');
    await f.seed(historical: true);
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final inst = Institucion.fromJson(
      prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
    );
    await expectLater(
      ih.hidratarInstitucionConGruposCurriculares(inst, persist: true),
      throwsUnsupportedError,
    );
    await expectLater(
      ih.hidratarInstitucionConGruposCurriculares(inst, clearLegacyKey: true),
      throwsUnsupportedError,
    );
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
  });

  test(
    'C16 loaders y búsqueda no escriben proyecciones sobre históricos',
    () async {
      final f = _Fixture('c16');
      await f.seed(historical: true);
      await ih.guardarGruposInstitucion(f.institucionId, [f.actual]);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final cache = await ih.cargarInstitucionCachePorId(f.institucionId);
      final byId = await ih.cargarInstitucionPorId(f.institucionId);
      final page = await ih.cargarInstitucionesRegistradasPageHidratada();
      final search = await AlumnoInstitucionesSearchService.search(
        const AlumnoInstitucionSearchFilters(
          scope: AlumnoBusquedaScope.curricular,
          soloConVacantes: true,
        ),
      );
      for (final inst in [
        cache!,
        byId!,
        page.single,
        search.single.institucion,
      ]) {
        expect(inst.gruposCurriculares.single.id, f.actual.id);
      }
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      // Cache miss may populate cache, but with raw historical B, never current A.
      final cacheKey = ih.kPerfilInstitucionPorId(f.institucionId);
      await prefs.remove(cacheKey);
      StorageService.instance.resetCache();
      final withoutCache = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      expect(
        (await ih.cargarInstitucionPorId(
          f.institucionId,
        ))!.gruposCurriculares.single.id,
        f.actual.id,
      );
      expect(
        Institucion.fromJson(
          prefs.getString(cacheKey)!,
        ).gruposCurriculares.single.id,
        f.historical.id,
      );
      expect({
        for (final k in prefs.getKeys())
          if (k != cacheKey) k: prefs.get(k),
      }, withoutCache);
    },
  );

  test('C17 corrupción se propaga por loaders sin escrituras', () async {
    final f = _Fixture('c17');
    await f.seed(historical: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ih.kGruposInstitucion(f.institucionId), '{');
    final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    await expectLater(
      ih.cargarInstitucionCachePorId(f.institucionId),
      throwsFormatException,
    );
    await expectLater(
      ih.cargarInstitucionPorId(f.institucionId),
      throwsFormatException,
    );
    await expectLater(
      ih.cargarInstitucionesRegistradasPageHidratada(),
      throwsFormatException,
    );
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
  });

  final corrupt = <String, Object>{
    'json roto': '{',
    'objeto en vez de lista': '{}',
    'cadena vacía': '',
    'tipo de almacenamiento incorrecto': 42,
    'elemento inválido': '[null]',
    'grupo sin ID': '[{"nombreGrupo":"Primero"}]',
  };
  for (final entry in corrupt.entries) {
    test('C9 vigente corrupto: ${entry.key}', () async {
      final f = _Fixture('c9');
      await f.seed(historical: true);
      final prefs = await SharedPreferences.getInstance();
      final key = ih.kGruposInstitucion(f.institucionId);
      if (entry.value is int) {
        await prefs.setInt(key, entry.value as int);
      } else {
        await prefs.setString(key, entry.value as String);
      }
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final inst = Institucion.fromJson(
        prefs.getString(ih.kPerfilInstitucionPorId(f.institucionId))!,
      );
      await expectLater(
        ih.cargarGruposInstitucion(f.institucionId),
        throwsFormatException,
      );
      await expectLater(
        ih.cargarGruposCurricularesInstitucion(f.institucionId),
        throwsFormatException,
      );
      await expectLater(
        SolicitudesService.obtenerGruposCurricularesInstitucion(
          f.institucionId,
        ),
        throwsFormatException,
      );
      await expectLater(
        ih.hidratarInstitucionConGruposCurriculares(inst),
        throwsFormatException,
      );
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    });
  }
}

class _Fixture {
  final String caseId;
  _Fixture(this.caseId);

  // Institution ID is also its institutional profile ID by domain contract.
  // The pupil profile is deliberately different; no fake account is needed
  // by these public group APIs.
  String get institucionId => 'institucion-$caseId';
  String get perfilAlumnoId => 'perfil-alumno-$caseId';

  GrupoInstitucional get actual => GrupoInstitucional(
    id: 'grupo-gestion-$caseId',
    institucionId: institucionId,
    actividadNombre: 'Primaria',
    nombreGrupo: 'Primaria primero A',
    aula: 'Primaria primero A',
    turno: 'Tarde • 13:15-17:45',
    cupoMaximo: 20,
    cupoOcupado: 3,
    estado: EstadoCupo.disponible,
  );

  GrupoCurricular get historical => GrupoCurricular(
    id: 'grupo-historico-$caseId',
    nombreCurso: 'Primaria segundo B',
    turno: TurnoCurricular.manana,
    cuposTotales: 10,
    cuposOcupados: 1,
  );

  Future<void> seed({
    bool historical = false,
    bool dedicatedKey = false,
  }) async {
    await ih.upsertInstitucion(
      Institucion(
        id: institucionId,
        nombre: 'Institución $caseId',
        cuit: 'cuit-$caseId',
        direccion: 'Dirección de prueba',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: '$caseId@example.invalid',
        telefono: '',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.primaria,
        tipoPlan: 'prueba',
        estadoPlan: EstadoPlanInstitucion.activo,
        planInicio: DateTime(2026),
        planFin: DateTime(2030),
        gruposCurriculares: historical && !dedicatedKey
            ? [this.historical]
            : [],
      ),
    );
    if (historical && dedicatedKey) {
      // Historical fixture only: serialize with the real model and exported
      // key builder. No current read or selection logic is recreated here.
      expect(
        await StorageService.instance.setString(
          ih.kGruposCurricularesInstitucion(institucionId),
          jsonEncode([this.historical.toMap()]),
        ),
        isTrue,
      );
    }
  }

  Future<Map<String, List<String>>> observe() async {
    final gestion = await ih.cargarGruposInstitucion(institucionId);
    final alumno = await ih.cargarGruposCurricularesInstitucion(institucionId);
    // This is the public method called by crearSolicitudDesdePerfil to
    // resolve/validate curricular group IDs. Does not create a request.
    final validacion =
        await SolicitudesService.obtenerGruposCurricularesInstitucion(
          institucionId,
        );
    final result = {
      'gestion': gestion.map((g) => g.id).toList(),
      'alumno': alumno.map((g) => g.id).toList(),
      'validacion': validacion.map((g) => g.id).toList(),
    };
    // ignore: avoid_print
    print('$caseId: $result');
    return result;
  }
}
