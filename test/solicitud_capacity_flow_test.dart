import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/screens/instituciones/institucion_extracurricular_grupo_form_page.dart';
import 'package:atena_app/screens/instituciones/institucion_extracurricular_modulo_base.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/models/extracurriculares/grupo_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';

class FailOneWrite extends SharedPreferencesStorePlatform {
  final SharedPreferencesStorePlatform delegate;
  final String target;
  bool failed = false;
  FailOneWrite(this.delegate, this.target);
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (!failed && key.endsWith(target)) {
      failed = true;
      throw StateError('Fallo de escritura simulado');
    }
    return delegate.setValue(type, key, value);
  }

  @override
  Future<Map<String, Object>> getAll() => delegate.getAll();
  @override
  Future<bool> remove(String key) => delegate.remove(key);
  @override
  Future<bool> clear() => delegate.clear();
}

Future<Map<String, Object?>> snapshot() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

final repo = SolicitudesRepositoryPrefs();

class Fixture {
  final String inst;
  final bool extra;
  Fixture(this.inst, {this.extra = false});
  String get gid => 'grupo-$inst';
  Future<void> group({
    int capacity = 1,
    int occupied = 0,
    bool deleted = false,
  }) async {
    if (extra) {
      await ExtracurricularesService.instance.guardarGrupos(
        inst,
        deleted
            ? []
            : [
                GrupoExtracurricular(
                  id: gid,
                  institucionId: inst,
                  bloque: BloqueExtracurricular.otros,
                  actividadNombre: 'Taller',
                  nombreGrupo: 'Grupo',
                  turno: 'manana',
                  cupoMaximo: capacity,
                  cupoOcupado: occupied,
                  activo: true,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ],
      );
    } else {
      await ih.guardarGruposInstitucion(
        inst,
        deleted
            ? []
            : [
                GrupoInstitucional(
                  id: gid,
                  institucionId: inst,
                  actividadNombre: 'Taller',
                  nombreGrupo: 'Grupo',
                  aula: 'Grupo',
                  turno: 'manana',
                  cupoMaximo: capacity,
                  cupoOcupado: occupied,
                  estado: EstadoCupo.disponible,
                ),
              ],
      );
    }
  }

  Future<String> create(String suffix) async {
    final id = 'sol-$inst-$suffix';
    await SolicitudesService.crearSolicitudDesdePerfil(
      ownerAccountId: 'owner-$suffix',
      perfilId: 'perfil-$suffix',
      solicitudAlumno: SolicitudAlumno(
        id: id,
        alumnoDocumento: 'doc-$suffix',
        institucionId: inst,
        institucionNombre: inst,
        actividadNombre: 'Taller',
        esCurricular: !extra,
        grupoCurricularId: extra ? '' : gid,
        aula: 'Grupo',
        turno: 'manana',
        moduleKey: extra ? 'otros' : '',
        estado: EstadoSolicitud.pendiente,
        fechaCreacion: DateTime(2026),
        fechaUltimoCambio: DateTime(2026),
        dedupKey: '',
      ),
    );
    return id;
  }

  Future<int> accepted() async =>
      (await SolicitudesService.obtenerSolicitudesParaInstitucion(
        institucionId: inst,
      )).where((s) => s.estado == EstadoSolicitud.confirmada).length;
  Future<int> occupied() async => extra
      ? (await ExtracurricularesService.instance.cargarGrupos(
          inst,
        )).single.cupoOcupado
      : (await ih.cargarGruposInstitucion(inst)).single.cupoOcupado;
}

Future<Object?> respond(
  String id, [
  EstadoSolicitud state = EstadoSolicitud.confirmada,
]) async {
  try {
    await SolicitudesService.responderSolicitud(
      solicitudId: id,
      nuevoEstado: state,
    );
    return null;
  } catch (e) {
    return e;
  }
}

Future<void> mustNotAccept(String id) async {
  final error = await respond(id);
  final s = await repo.getSolicitudAlumnoById(id);
  // Rejection must retain pending state.
  expect(
    s?.estado,
    EstadoSolicitud.pendiente,
    reason: 'Confirmación inválida persistida; error=$error',
  );
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
  for (final extra in [false, true]) {
    final type = extra ? 'extra' : 'curricular';
    test('$type: último cupo acepta una solicitud', () async {
      final f = Fixture('inst-$type', extra: extra);
      await f.group();
      final id = await f.create('uno');
      expect(await f.occupied(), 0, reason: 'Pendiente no reserva');
      expect(await respond(id), isNull);
      expect(await f.accepted(), 1);
      // ignore: avoid_print
      print('$type confirmados=1 contador=${await f.occupied()}');
    });
    for (final reverse in [false, true]) {
      test('$type: dos pendientes compiten, inverso=$reverse', () async {
        final f = Fixture('inst-$type', extra: extra);
        await f.group();
        final a = await f.create('a');
        final b = await f.create('b');
        expect(await f.occupied(), 0);
        expect(await respond(reverse ? b : a), isNull);
        await respond(reverse ? a : b);
        // ignore: avoid_print
        print(
          '$type confirmados=${await f.accepted()} contador=${await f.occupied()} máximo=1',
        );
        expect(await f.accepted(), lessThanOrEqualTo(1));
      });
    }
  }
  for (final change in ['lleno', 'eliminado', 'reducido']) {
    test('curricular: grupo $change antes de responder', () async {
      final f = Fixture('inst-cambio');
      await f.group();
      final id = await f.create('a');
      await f.group(
        capacity: change == 'reducido' ? 0 : 1,
        occupied: change == 'lleno' ? 1 : 0,
        deleted: change == 'eliminado',
      );
      await mustNotAccept(id);
    });
  }
  test('curricular: aceptación repetida no duplica cupo', () async {
    final f = Fixture('inst-doble');
    await f.group();
    final id = await f.create('a');
    await respond(id);
    await respond(id);
    expect(await f.accepted(), 1);
  });
  for (final initial in [
    EstadoSolicitud.rechazada,
    EstadoSolicitud.confirmada,
  ]) {
    test('estado terminal $initial no se cambia por responder', () async {
      final f = Fixture('inst-estados');
      await f.group();
      final id = await f.create('a');
      expect(await respond(id, initial), isNull);
      await respond(
        id,
        initial == EstadoSolicitud.rechazada
            ? EstadoSolicitud.confirmada
            : EstadoSolicitud.rechazada,
      );
      expect((await repo.getSolicitudAlumnoById(id))!.estado, initial);
    });
  }
  test('pendiente se puede rechazar sin ocupar', () async {
    final f = Fixture('inst-rechazo');
    await f.group();
    final id = await f.create('a');
    expect(await respond(id, EstadoSolicitud.rechazada), isNull);
    expect(await f.accepted(), 0);
  });
  test('inexistente no crea registros ni modifica almacenamiento', () async {
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final error = await respond('sol-inexistente');
    // ignore: avoid_print
    print('Inexistente: error=$error');
    expect(await repo.getSolicitudAlumnoById('sol-inexistente'), isNull);
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
  });
  test('grupo de otra institución no se acepta', () async {
    final a = Fixture('inst-A');
    final b = Fixture('inst-B');
    await a.group();
    await b.group();
    final id = await a.create('a');
    final s = (await repo.getSolicitudAlumnoById(id))!;
    // Deliberate persisted inconsistency via the real repository, not a fake validator.
    await repo.saveSolicitudAlumno(s.copyWith(grupoCurricularId: b.gid));
    await mustNotAccept(id);
  });
  test('dos instituciones mantienen solicitudes y grupos aislados', () async {
    final a = Fixture('inst-A');
    final b = Fixture('inst-B');
    await a.group();
    await b.group();
    final x = await a.create('a');
    final y = await b.create('b');
    await respond(x);
    expect(await a.accepted(), 1);
    expect(await b.accepted(), 0);
    expect(
      (await repo.getSolicitudAlumnoById(y))!.estado,
      EstadoSolicitud.pendiente,
    );
    await respond(y);
    expect(await b.accepted(), 1);
    expect((await ih.cargarGruposInstitucion(a.inst)).single.id, a.gid);
    expect((await ih.cargarGruposInstitucion(b.inst)).single.id, b.gid);
  });

  for (final terminal in [
    EstadoSolicitud.confirmada,
    EstadoSolicitud.rechazada,
  ]) {
    test('idempotencia completa: $terminal', () async {
      final f = Fixture('inst-idem');
      await f.group();
      final id = await f.create('a');
      expect(await respond(id, terminal), isNull);
      final before = await snapshot();
      expect(await respond(id, terminal), isNull);
      expect(await snapshot(), before);
    });
  }
  for (final extra in [false, true]) {
    for (final occupied in [1, 2]) {
      test(
        'histórico lleno/sobrecupo $occupied extra=$extra intacto',
        () async {
          final f = Fixture('inst-hist', extra: extra);
          await f.group();
          final id = await f.create('a');
          await f.group(occupied: occupied);
          final before = await snapshot();
          await mustNotAccept(id);
          expect(await snapshot(), before);
          if (!extra && occupied > 1) {
            await expectLater(f.occupied(), throwsFormatException);
          } else {
            expect(await f.occupied(), occupied);
          }
        },
      );
    }
    test('cancelación libera sólo su lugar extra=$extra', () async {
      final f = Fixture('inst-cancel', extra: extra);
      await f.group(capacity: 3, occupied: 1);
      final id = await f.create('a');
      expect(await respond(id), isNull);
      expect(await f.occupied(), 2);
      await SolicitudesService.cancelarSolicitudDesdePerfil(
        ownerAccountId: 'owner-a',
        perfilId: 'perfil-a',
        solicitudId: id,
        institucionId: f.inst,
        institucionNombre: f.inst,
        actividadNombre: 'Taller',
      );
      expect(await f.occupied(), 1);
      expect(await f.accepted(), 0);
      final next = await f.create('b');
      expect(await respond(next), isNull);
      expect(await f.occupied(), 2);
    });
  }
  test('rechazar pendiente conserva ocupación previa', () async {
    final f = Fixture('inst-reject');
    await f.group(capacity: 3, occupied: 2);
    final id = await f.create('a');
    expect(await respond(id, EstadoSolicitud.rechazada), isNull);
    expect(await f.occupied(), 2);
  });
  for (final target in ['capacity', 'request']) {
    test('fallo $target revierte sin confirmar ni notificar', () async {
      final f = Fixture('inst-fallo');
      await f.group();
      final id = await f.create('a');
      final before = await snapshot();
      final old = SharedPreferencesStorePlatform.instance;
      final failing = FailOneWrite(
        old,
        target == 'capacity' ? ih.kGruposInstitucion(f.inst) : 'sol_alumno_$id',
      );
      SharedPreferencesStorePlatform.instance = failing;
      try {
        expect(await respond(id), isNotNull);
        expect(failing.failed, isTrue);
        expect(
          (await repo.getSolicitudAlumnoById(id))!.estado,
          EstadoSolicitud.pendiente,
        );
        expect(await snapshot(), before);
      } finally {
        SharedPreferencesStorePlatform.instance = old;
      }
    });
  }
  test(
    'dos grupos curriculares de una institución permanecen aislados',
    () async {
      final f = Fixture('inst-dos');
      await f.group();
      final groups = await ih.cargarGruposInstitucion(f.inst);
      final other = GrupoInstitucional(
        id: 'grupo-otro',
        institucionId: f.inst,
        actividadNombre: 'Taller',
        nombreGrupo: 'Otro',
        aula: 'Otro',
        turno: 'manana',
        cupoMaximo: 1,
        cupoOcupado: 0,
        estado: EstadoCupo.disponible,
      );
      await ih.guardarGruposInstitucion(f.inst, [...groups, other]);
      final id = await f.create('a');
      expect(await respond(id), isNull);
      final result = await ih.cargarGruposInstitucion(f.inst);
      expect(result.firstWhere((g) => g.id == other.id).cupoOcupado, 0);
      expect(result.firstWhere((g) => g.id == f.gid).cupoOcupado, 1);
    },
  );
  for (final ambiguous in [false, true]) {
    test('grupos extra similares; ambiguo=$ambiguous', () async {
      final f = Fixture('inst-extra-similar', extra: true);
      await f.group();
      final groups = await ExtracurricularesService.instance.cargarGrupos(
        f.inst,
      );
      final other = groups.single.copyWith(
        id: 'otro-grupo',
        nombreGrupo: ambiguous ? 'Grupo' : 'Grupo avanzado',
      );
      await ExtracurricularesService.instance.guardarGrupos(f.inst, [
        ...groups,
        other,
      ]);
      final id = await f.create('a');
      final before = await snapshot();
      if (ambiguous) {
        await mustNotAccept(id);
        expect(await snapshot(), before);
      } else {
        expect(await respond(id), isNull);
        final result = await ExtracurricularesService.instance.cargarGrupos(
          f.inst,
        );
        expect(result.firstWhere((g) => g.id == 'otro-grupo').cupoOcupado, 0);
        expect(result.firstWhere((g) => g.id == f.gid).cupoOcupado, 1);
      }
    });
  }
  test('grupo suspendido no admite confirmación', () async {
    final f = Fixture('inst-suspend');
    await f.group();
    final id = await f.create('a');
    final groups = await ih.cargarGruposInstitucion(f.inst);
    groups.single.estado = EstadoCupo.suspendido;
    await ih.guardarGruposInstitucion(f.inst, groups);
    await mustNotAccept(id);
  });

  test('confirmaciones históricas sobrecupo no se borran ni agravan', () async {
    final f = Fixture('inst-historic-confirm');
    await f.group();
    final a = await f.create('a');
    final b = await f.create('b');
    final c = await f.create('c');
    for (final id in [a, b]) {
      final row = (await repo.getSolicitudAlumnoById(id))!;
      await repo.saveSolicitudAlumno(
        row.copyWith(estado: EstadoSolicitud.confirmada),
      );
    }
    final before = await snapshot();
    await mustNotAccept(c);
    expect(await f.accepted(), 2);
    expect(await snapshot(), before);
  });

  Future<void> openPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => page));
    await tester.pumpAndSettle();
  }

  for (final scenario in [
    (12, 10, 10, false),
    (12, 15, 10, false),
    (5, 15, 10, false),
    (0, 10, 10, false),
    (5, 10, 10, false),
    (10, 10, 10, false),
    (5, 10, 15, false),
    (12, 10, 10, true),
  ]) {
    testWidgets('formulario real cupos $scenario', (tester) async {
      final (occupied, oldMax, newMax, metadata) = scenario;
      final f = Fixture('inst-form', extra: true);
      await f.group(capacity: oldMax, occupied: occupied);
      final group = (await ExtracurricularesService.instance.cargarGrupos(
        f.inst,
      )).single;
      await openPage(
        tester,
        InstitucionExtracurricularGrupoFormPage(
          institucionId: f.inst,
          institucionNombre: f.inst,
          bloque: BloqueExtracurricular.otros,
          moduleKey: 'otros',
          initial: group,
        ),
      );
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(5)).controller!.text,
        '$occupied',
      );
      await tester.enterText(fields.at(4), '$newMax');
      if (metadata) await tester.enterText(fields.at(1), 'Grupo editado');
      final save = find.byTooltip('Guardar');
      await tester.tap(save);
      await tester.pumpAndSettle();
      final rejected = newMax < occupied && newMax != oldMax;
      expect(
        find.byType(InstitucionExtracurricularGrupoFormPage),
        rejected ? findsOneWidget : findsNothing,
      );
      final stored = (await ExtracurricularesService.instance.cargarGrupos(
        f.inst,
      )).single;
      expect(stored.id, group.id);
      expect(stored.cupoOcupado, occupied);
      expect(stored.cupoMaximo, rejected ? oldMax : newMax);
      if (metadata) expect(stored.nombreGrupo, 'Grupo editado');
      if (!metadata && !rejected && occupied >= newMax) {
        final id = await f.create('post-form');
        await mustNotAccept(id);
        expect(await f.occupied(), occupied);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('formulario rechaza ocupacion negativa sin escribir', (
    tester,
  ) async {
    final f = Fixture('inst-negative-form', extra: true);
    await f.group(capacity: 10, occupied: 5);
    final group = (await ExtracurricularesService.instance.cargarGrupos(
      f.inst,
    )).single;
    final before = await snapshot();
    await openPage(
      tester,
      InstitucionExtracurricularGrupoFormPage(
        institucionId: f.inst,
        institucionNombre: f.inst,
        bloque: BloqueExtracurricular.otros,
        moduleKey: 'otros',
        initial: group,
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(5), '-1');
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.byType(InstitucionExtracurricularGrupoFormPage),
      findsOneWidget,
    );
    expect(await snapshot(), before);
  });

  testWidgets('modulo muestra 12 de 10 y guardar sin cambios no escribe', (
    tester,
  ) async {
    final f = Fixture('inst-module', extra: true);
    await f.group(capacity: 10, occupied: 12);
    final before = await snapshot();
    await openPage(
      tester,
      InstitucionExtracurricularModuloBase(
        institucionId: f.inst,
        institucionNombre: f.inst,
        bloque: BloqueExtracurricular.otros,
        moduleKey: 'otros',
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InstitucionExtracurricularModuloBase)),
    );
    final cupos = find.text(l10n.institucionExtracBaseActionCupos);
    await tester.ensureVisible(cupos);
    await tester.tap(cupos);
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.institucionExtracBaseCuposDialogOcupado(12)),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.actionSave));
    await tester.pumpAndSettle();
    expect(await snapshot(), before);
    expect(tester.takeException(), isNull);
  });
}
