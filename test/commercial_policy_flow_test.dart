// Run this file with and without
// --dart-define=ATENA_COMMERCIAL_ENFORCEMENT=true. No runtime override.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/services/plan_habilitacion_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/alumno_solicitar_vacante_page.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/routes/solicitud_publica_intent.dart';
import 'package:atena_app/models/catalogo/ficha_publica.dart';
import 'catalogo_publicable_flow_test.dart' as fx;
import 'public_discovery_flow_test.dart' as public;
import 'solicitud_capacity_flow_test.dart' as capacity;

const enforced = PlanHabilitacionService.commercialEnforcementEnabled;
final repo = SolicitudesRepositoryPrefs();
Future<void> plan(
  String name, {
  EstadoPlanInstitucion status = EstadoPlanInstitucion.activo,
}) async {
  final inst = (await InstitucionService.getInstitucionById(fx.instId))!;
  // Same write path as the plan screen, intentionally leave older caches intact.
  await InstitucionService.upsertInstitucion(
    inst.copyWith(tipoPlan: name, estadoPlan: status),
  );
}

SolicitudAlumno request(
  String id, {
  bool extra = false,
  String group = 'group-A',
}) => SolicitudAlumno(
  id: id,
  alumnoDocumento: 'fictional-document-$id',
  institucionId: fx.instId,
  institucionNombre: 'Escuela Ficticia',
  actividadNombre: extra ? 'Inglés' : 'Primaria',
  esCurricular: !extra,
  grupoCurricularId: extra ? '' : group,
  aula: extra ? 'Inicial' : 'Primero A',
  turno: extra ? 'Tarde · 16:00–18:00' : 'Mañana · 08:00–12:00',
  moduleKey: extra ? 'idiomas_y_comunicacion' : '',
  estado: EstadoSolicitud.pendiente,
  fechaCreacion: DateTime(2026),
  fechaUltimoCambio: DateTime(2026),
  dedupKey: '',
);
Future<void> create(
  String id, {
  bool extra = false,
  String group = 'group-A',
  String? owner,
}) => SolicitudesService.crearSolicitudDesdePerfil(
  ownerAccountId: owner ?? 'family-$id',
  perfilId: 'student-$id',
  solicitudAlumno: request(id, extra: extra, group: group),
);
Matcher get commercialError => isA<SolicitudesException>().having(
  (e) => e.code,
  'code',
  'digital_enrollment_disabled',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(fx.seed); // resets preferences + StorageService cache for EVERY case

  test('configuration is a compile-time value, default OFF', () {
    expect(
      enforced,
      const bool.fromEnvironment('ATENA_COMMERCIAL_ENFORCEMENT'),
    );
    expect(
      PlanHabilitacionService.planComercial(' PREMIUM '),
      PlanComercial.premium,
    );
    expect(PlanHabilitacionService.planComercial('Free'), PlanComercial.free);
    for (final legacy in [
      '',
      'Prueba',
      'FASE2-CUR-PREM-EXT-PREM',
      'paid',
      'unknown',
    ]) {
      expect(
        PlanHabilitacionService.planComercial(legacy),
        PlanComercial.desconocido,
      );
    }
  });
  for (final tier in ['Free', 'Premium', 'FASE2-CUR-PREM-EXT-PREM', '']) {
    test(
      'service $tier enforcement=$enforced, rejected writes leave no traces',
      () async {
        await plan(tier);
        final before = await capacity.snapshot();
        if (enforced && tier != 'Premium') {
          await expectLater(create('direct'), throwsA(commercialError));
          expect(await capacity.snapshot(), before);
        } else {
          await create('direct');
          expect(
            (await repo.getSolicitudAlumnoById('direct'))?.estado,
            EstadoSolicitud.pendiente,
          );
        }
      },
    );
  }
  for (final status in EstadoPlanInstitucion.values) {
    test('Premium respects existing operational state $status', () async {
      await plan('Premium', status: status);
      expect(
        await PlanHabilitacionService.puedeRecibirPorId(fx.instId),
        !enforced || status == EstadoPlanInstitucion.activo,
      );
    });
  }
  test('missing institution has no inferred entitlement', () async {
    expect(
      await PlanHabilitacionService.puedeRecibirPorId('missing'),
      !enforced,
    );
  });
  for (final tier in ['Free', 'Premium']) {
    for (final type in ['escolar', 'universidad', 'extra']) {
      test(
        '$tier $type remains public and uses the same request policy',
        () async {
          if (type == 'extra') {
            await public.extra(price: '12000');
          } else {
            await public.publish(type: type, price: 'Gratuito');
          }
          await plan(tier);
          await SessionService.logout();
          final all = await public.catalog.buscarPublico();
          expect(all, hasLength(1));
          expect(all.single.ofertas, hasLength(1));
          // Pricing filters use offer cost, not the commercial plan.
          final free = await public.catalog.buscarPublico(
            costo: CostoOferta.gratuito,
          );
          expect(free, type == 'extra' ? isEmpty : hasLength(1));
          if (enforced && tier == 'Free') {
            await expectLater(
              create('category', extra: type == 'extra'),
              throwsA(commercialError),
            );
          } else {
            await create('category', extra: type == 'extra');
            expect(await repo.getSolicitudAlumnoById('category'), isNotNull);
          }
        },
      );
    }
  }
  test(
    'Premium → Free → Premium preserves history, ids, catalog and occupancy',
    () async {
      await public.publish();
      await plan('Premium');
      final original = (await InstitucionService.getInstitucionById(
        fx.instId,
      ))!.toMap()..remove('tipoPlan');
      final publicBefore = jsonEncode(
        (await public.catalog.buscarPublico()).single.toMap(),
      );
      await create('A');
      final requestA = (await repo.getSolicitudAlumnoById('A'))!.toJson();
      final groupsBefore = await capacity.snapshot();
      await plan('Free');
      expect((await repo.getSolicitudAlumnoById('A'))!.toJson(), requestA);
      expect(
        (await SolicitudesService.obtenerSolicitudesParaInstitucion(
          institucionId: fx.instId,
        )).single.id,
        'A',
      );
      expect(
        jsonEncode((await public.catalog.buscarPublico()).single.toMap()),
        publicBefore,
      );
      if (enforced) {
        await expectLater(create('B'), throwsA(commercialError));
      } else {
        await create('B');
      }
      // Downgrade does not free seats or erase any group storage.
      final after = await capacity.snapshot();
      for (final key in groupsBefore.keys.where(
        (k) => k.startsWith('grupos_'),
      )) {
        expect(after[key], groupsBefore[key]);
      }
      // Existing requests remain manageable after downgrade.
      await SolicitudesService.responderSolicitud(
        solicitudId: 'A',
        nuevoEstado: EstadoSolicitud.confirmada,
      );
      expect(
        (await repo.getSolicitudAlumnoById('A'))!.estado,
        EstadoSolicitud.confirmada,
      );
      final occupied = (await ih.cargarGruposInstitucion(
        fx.instId,
      )).single.cupoOcupado;
      expect(occupied, 3);
      await plan('Premium');
      await create('C');
      expect(await repo.getSolicitudAlumnoById('C'), isNotNull);
      expect(
        (await ih.cargarGruposInstitucion(fx.instId)).single.cupoOcupado,
        occupied,
      );
      final updated = (await InstitucionService.getInstitucionById(
        fx.instId,
      ))!.toMap()..remove('tipoPlan');
      expect(updated, original);
      expect((await public.catalog.buscarPublico()).single.id, fx.instId);
    },
  );
  test(
    'canonical plan takes priority over stale Premium in discovery cache',
    () async {
      final inst = (await InstitucionService.getInstitucionById(fx.instId))!;
      await ih.upsertInstitucion(
        inst.copyWith(
          tipoPlan: 'Premium',
          estadoPlan: EstadoPlanInstitucion.activo,
        ),
      );
      await plan('Free');
      expect((await ih.cargarInstitucionPorId(fx.instId))!.tipoPlan, 'Premium');
      expect(
        await PlanHabilitacionService.puedeRecibirPorId(fx.instId),
        !enforced,
      );
    },
  );
  test(
    'Premium does not bypass invalid context, group or duplicate checks',
    () async {
      await plan('Premium');
      await expectLater(
        create('bad-owner', owner: ''),
        throwsA(isA<SolicitudesException>()),
      );
      await expectLater(
        create('bad-group', group: 'other-institution-group'),
        throwsA(isA<SolicitudesException>()),
      );
      await create('same');
      await expectLater(create('same'), throwsA(isA<SolicitudesException>()));
    },
  );
  test('Premium cannot confirm above effective capacity', () async {
    await plan('Premium');
    await ih.guardarGruposInstitucion(fx.instId, [
      fx.group('group-A', occupied: 2, capacity: 2),
    ]);
    await create('full');
    await capacity.mustNotAccept('full');
    expect((await ih.cargarGruposInstitucion(fx.instId)).single.cupoOcupado, 2);
  });
  test('commercial selection never publishes private records', () async {
    await plan('Premium');
    expect(await public.catalog.buscarPublico(), isEmpty);
    await plan('Free');
    expect(await public.catalog.buscarPublico(), isEmpty);
  });
  testWidgets(
    'anonymous Free sees institution and offer; digital action matches policy',
    (tester) async {
      await public.publish();
      await plan('Free');
      await SessionService.logout();
      await tester.pumpWidget(
        public.harness(const AlumnoBuscarInstitucionesPage.publica()),
      );
      await tester.pumpAndSettle();
      await public.tapText(tester, 'Ver institución y ofertas');
      final cta = find.ancestor(
        of: find.text('Solicitar inscripción'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      await tester.ensureVisible(cta);
      expect(tester.widget<FilledButton>(cta).onPressed == null, enforced);
      expect(
        find.text(PlanHabilitacionService.inscripcionNoHabilitada),
        enforced ? findsOneWidget : findsNothing,
      );
      if (!enforced) {
        await public.tapText(tester, 'Solicitar inscripción');
        expect(find.byType(AlumnoLoginPage), findsOneWidget);
      }
      expect(await SessionService.getSession(), isNull);
      expect(await repo.getSolicitudAlumnoById('none'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('stale intent is checked before login', (tester) async {
    await plan('Free');
    await SessionService.logout();
    await tester.pumpWidget(
      public.harness(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => const SolicitudPublicaIntent(
                institucionId: fx.instId,
                grupoId: 'group-A',
                categoria: CategoriaPublica.formal,
              ).continuar(context),
              child: const Text('Intento'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Intento'));
    await tester.pumpAndSettle();
    expect(
      find.byType(AlumnoLoginPage),
      enforced ? findsNothing : findsOneWidget,
    );
  });
  testWidgets('direct request page uses the same policy', (tester) async {
    await plan('Free');
    await tester.pumpWidget(
      public.harness(
        const AlumnoSolicitarVacantePage(
          alumnoDocumento: 'fictional',
          institucionId: fx.instId,
          institucionNombre: 'Ficticia',
          actividadNombre: 'Primaria',
          esCurricular: true,
          ownerAccountId: 'family',
          perfilId: 'student',
          grupoCurricularId: 'group-A',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cta = find.ancestor(
      of: find.text('Enviar solicitud'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(tester.widget<FilledButton>(cta).onPressed == null, enforced);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Premium anonymous → real login → profile → canonical request', (
    tester,
  ) async {
    await public.publish();
    await plan('Premium');
    await public.student();
    await SessionService.logout();
    await tester.pumpWidget(
      public.harness(
        const AlumnoBuscarInstitucionesPage.publica(textoInicial: 'primaria'),
      ),
    );
    await tester.pumpAndSettle();
    await public.tapText(tester, 'Ver institución y ofertas');
    await public.tapText(tester, 'Solicitar inscripción');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'public@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'DemoPublica123!');
    final login = find.byWidgetPredicate((w) => w is ElevatedButton);
    await tester.runAsync(() async {
      await tester.ensureVisible(login);
      await tester.tap(login);
      for (var n = 0; n < 100; n++) {
        if ((await SessionService.getSession())?.role == SessionRole.cuenta) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(CuentaHomePage), findsOneWidget);
    await public.tapText(tester, 'Ficticia, Ana');
    final page = tester.widget<AlumnoSolicitarVacantePage>(
      find.byType(AlumnoSolicitarVacantePage),
    );
    expect(page.grupoCurricularId, 'group-A');
    expect(page.ownerAccountId, 'public-owner');
    expect(page.perfilId, 'public-profile');
    await public.tapText(tester, 'Enviar solicitud');
    await public.tapText(tester, 'Enviar');
    final requests = await SolicitudesService.obtenerSolicitudesParaInstitucion(
      institucionId: fx.instId,
    );
    expect(requests, hasLength(1));
    expect(requests.single.ownerAccountId, 'public-owner');
    expect(requests.single.grupoCurricularId, 'group-A');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'plan screen changes Free/Premium without replacing identity or historical state',
    (tester) async {
      const email = 'commercial-owner@example.invalid';
      const password = 'FicticiaPrueba123!';
      final account = (await tester.runAsync(
        () => InstitucionService.registrarInstitucion(
          email: email,
          passwordHash: password,
          nombre: 'Institución Plan',
        ),
      ))!;
      final id = account.institucionId;
      await CuentaService.crearPerfilInstitucion(
        cuentaId: id,
        nombre: 'Institución Plan',
        emailContacto: email,
        telefonoContacto: '00000000',
      );
      final source = (await InstitucionService.getInstitucionById(fx.instId))!;
      final original = source.copyWith(
        id: id,
        email: email,
        tipoPlan: 'Free',
        estadoPlan: EstadoPlanInstitucion.activo,
        planConfig: PlanInstitucionConfig(
          niveles: [
            PlanNivelCurricular(
              nivel: NivelCurricular.primaria,
              habilitado: true,
            ),
          ],
          modulos: const [],
        ),
      );
      await InstitucionService.upsertInstitucion(original);
      await CuentaService.iniciarSesionAutenticada(id, recordarme: true);
      await CuentaService.activarContextoInstitucion(id, id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('promo_used_ATHENA2026', 4);
      for (final selection in ['Premium', 'Free', 'Premium']) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          public.harness(
            InstitucionPlanPage.manage(
              ownerAccountId: id,
              institucionPerfilId: id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('USD'), findsNothing);
        expect(find.byType(SwitchListTile), findsNothing);
        await public.tapText(tester, selection);
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        final save = find.byWidgetPredicate((w) => w is ElevatedButton).last;
        await tester.runAsync(() async {
          tester.widget<ElevatedButton>(save).onPressed!();
          for (var i = 0; i < 40; i++) {
            if ((await InstitucionService.getInstitucionById(id))?.tipoPlan ==
                selection) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        final current = (await InstitucionService.getInstitucionById(id))!;
        expect(current.tipoPlan, selection);
        expect((await ih.cargarInstitucionPorId(id))!.tipoPlan, selection);
        expect(
          current.toMap()..remove('tipoPlan'),
          original.toMap()..remove('tipoPlan'),
        );
        expect(
          await PlanHabilitacionService.puedeRecibirPorId(id),
          !enforced || selection == 'Premium',
        );
        expect((await SessionService.getSession())?.userId, id);
        expect(await SessionService.getInstitucionOwnerAccountIdLogueado(), id);
        expect(prefs.getInt('promo_used_ATHENA2026'), 4);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('downgrade after opening request form is rechecked on submit', (
    tester,
  ) async {
    await plan('Premium');
    await tester.pumpWidget(
      public.harness(
        const AlumnoSolicitarVacantePage(
          alumnoDocumento: 'fictional',
          institucionId: fx.instId,
          institucionNombre: 'Ficticia',
          actividadNombre: 'Primaria',
          esCurricular: true,
          ownerAccountId: 'family',
          perfilId: 'student',
          grupoCurricularId: 'group-A',
          aula: 'Primero A',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await plan('Free');
    await public.tapText(tester, 'Enviar solicitud');
    expect(find.byType(AlertDialog), enforced ? findsNothing : findsOneWidget);
    expect(
      await SolicitudesService.obtenerSolicitudesParaInstitucion(
        institucionId: fx.instId,
      ),
      isEmpty,
    );
    expect(
      find.text(PlanHabilitacionService.inscripcionNoHabilitada),
      enforced ? findsOneWidget : findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets('plan selection mobile large text $brightness', (tester) async {
      await plan('Free');
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        public.harness(
          const InstitucionPlanPage.manage(
            ownerAccountId: 'owner-A',
            institucionPerfilId: fx.instId,
          ),
          brightness: brightness,
          scale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      await public.tapText(tester, 'Premium');
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
