import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/models/catalogo/ficha_publica.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/extracurriculares/actividad_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/grupo_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/services/catalogo_publicable_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/alumno_institucion_perfil_page.dart';
import 'package:atena_app/screens/alumnos/alumno_solicitar_vacante_page.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/auth/alumno_registro_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/instituciones/institucion_catalogo_page.dart';
import 'package:atena_app/routes/atena_router.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/ui/atena_workspace.dart';
import 'catalogo_publicable_flow_test.dart' as fixture;

final catalog = CatalogoPublicableService();
Future<void> publish({String price = '', String type = 'escolar'}) async {
  final id = await CatalogoPublicableService.identificador(
    'curricular-group',
    fixture.instId,
    'group-A',
  );
  await catalog.publicarLocal(
    fixture.instId,
    fixture.areaId,
    precios: {id: price},
    tipoFormal: type,
  );
}

Future<String> extra({String price = 'Gratuito'}) async {
  final area = (await InstitucionAreasService.instance.resolverYGuardar(
    institucionId: fixture.instId,
    tipo: TipoAreaOperativa.extracurricular,
    claveOrigen: 'idiomas_y_comunicacion',
    nombre: 'Idiomas',
  ))!;
  await InstitucionOperadoresService.instance.asignarArea(
    institucionId: fixture.instId,
    operadorId: fixture.operatorId,
    areaId: area.id,
  );
  await InstitucionOperadoresService.instance.setCapacidadesEnArea(
    institucionId: fixture.instId,
    operadorId: fixture.operatorId,
    areaId: area.id,
    capacidades: {
      CapacidadInstitucional.groupsRead,
      CapacidadInstitucional.groupsWrite,
    },
  );
  await InstitucionContextoOperativoService.instance.activarContextoOperativo(
    institucionId: fixture.instId,
    ownerAccountId: 'owner-A',
    areaId: area.id,
    operadorId: fixture.operatorId,
  );
  final inst = (await ih.cargarInstitucionPorId(fixture.instId))!;
  await ih.upsertInstitucion(
    inst.copyWith(
      actividadesExtracurriculares: [
        ActividadExtracurricular(
          id: 'activity-english',
          institucionId: fixture.instId,
          bloque: BloqueExtracurricular.idiomasYComunicacion,
          nombre: 'Inglés',
          activa: true,
          cupoMaximo: 0,
          cupoOcupado: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          precio: price,
          edades: '12 a 18',
          contacto: 'secret-contact',
        ),
      ],
    ),
  );
  await ExtracurricularesService.instance.guardarGrupos(fixture.instId, [
    GrupoExtracurricular(
      id: 'english-group',
      institucionId: fixture.instId,
      bloque: BloqueExtracurricular.idiomasYComunicacion,
      actividadNombre: 'Inglés',
      nombreGrupo: 'Inicial',
      cupoMaximo: 10,
      cupoOcupado: 1,
      activo: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      areaId: area.id,
      turno: 'Tarde · 16:00–18:00',
    ),
  ]);
  await catalog.publicarLocal(fixture.instId, area.id);
  return area.id;
}

Future<void> student() async {
  await CuentaService.actualizarCuenta(
    Cuenta(
      id: 'public-owner',
      email: 'public@example.invalid',
      passwordHash: base64Encode(utf8.encode('DemoPublica123!')),
      perfilesAlumnoIds: ['public-profile'],
      perfilesInstitucionIds: [],
      recordarme: true,
      creadaEl: DateTime(2026),
      ultimaSesion: DateTime(2026),
    ),
  );
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: 'public-profile',
      cuentaId: 'public-owner',
      ownerAccountId: 'public-owner',
      documento: '30991122',
      nombre: 'Ana',
      apellido: 'Ficticia',
      fechaNacimiento: DateTime(2010),
      email: '',
      telefono: '',
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
}

Widget harness(
  Widget home, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => MaterialApp(
  theme: AtenaTheme.build(brightness),
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  onGenerateRoute: AtenaRouter.onGenerateRoute,
  builder: (ctx, child) => MediaQuery(
    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);
Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  for (var n = 0; n < 35 && f.hitTestable().evaluate().isEmpty; n++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  expect(f.hitTestable(), findsWidgets, reason: text);
  await tester.tap(f.hitTestable().first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(fixture.seed);
  test('datos privados y preparación no publican automáticamente', () async {
    await catalog.preparar(fixture.instId, fixture.areaId);
    await SessionService.logout();
    expect(await catalog.buscarPublico(), isEmpty);
  });
  test(
    'búsqueda anónima por institución y oferta, sin modificar sesión',
    () async {
      await publish();
      await SessionService.logout();
      for (final q in ['ESCUELA', 'primaria', '  primero   a  ']) {
        expect(await catalog.buscarPublico(texto: q), hasLength(1));
      }
      expect(await SessionService.getSession(), isNull);
      expect(await catalog.buscarPublico(texto: 'inexistente'), isEmpty);
    },
  );
  test('actividad por nombre y sin tilde; institución mixta', () async {
    await publish();
    await extra();
    await SessionService.logout();
    final all = await catalog.buscarPublico();
    expect(all, hasLength(1));
    expect(all.single.ofertas, hasLength(2));
    expect(
      (await catalog.buscarPublico(
        texto: '  INGLES ',
      )).single.ofertas.single.nombre,
      'Inglés',
    );
    for (final c in CategoriaPublica.values) {
      expect(
        (await catalog.buscarPublico(
          categoria: c,
        )).single.ofertas.single.categoria,
        c,
      );
    }
  });
  test('universidad y carrera pertenecen a educación formal', () async {
    await ih.guardarGruposInstitucion(fixture.instId, [
      GrupoInstitucional(
        id: 'group-A',
        institucionId: fixture.instId,
        actividadNombre: 'Abogacía',
        nombreGrupo: 'Comisión A',
        cupoMaximo: 20,
        cupoOcupado: 0,
        estado: EstadoCupo.disponible,
        areaId: fixture.areaId,
      ),
    ]);
    await publish(type: 'universidad');
    await SessionService.logout();
    for (final q in ['universidad', 'abogacia']) {
      final o = (await catalog.buscarPublico(texto: q)).single.ofertas.single;
      expect(o.categoria, CategoriaPublica.formal);
      expect(o.nivelLabel, contains('Carrera'));
    }
    expect(
      await catalog.buscarPublico(categoria: CategoriaPublica.actividades),
      isEmpty,
    );
  });
  for (final pair in [
    ('', CostoOferta.consultar),
    ('Consultar', CostoOferta.consultar),
    ('Gratuito', CostoOferta.gratuito),
    ('0', CostoOferta.gratuito),
    ('2500', CostoOferta.arancelado),
  ]) {
    test(
      'precio explícito ${pair.$1}; desconocido nunca gratuito ni plan',
      () async {
        await publish(price: pair.$1);
        await SessionService.logout();
        expect(
          (await catalog.buscarPublico()).single.ofertas.single.costo,
          pair.$2,
        );
        expect(
          await catalog.buscarPublico(costo: CostoOferta.gratuito),
          pair.$2 == CostoOferta.gratuito ? hasLength(1) : isEmpty,
        );
      },
    );
  }
  test('costos se filtran en la misma oferta y no cruzan categorías', () async {
    await publish(price: '1500');
    await extra();
    await SessionService.logout();
    expect(
      await catalog.buscarPublico(
        categoria: CategoriaPublica.formal,
        costo: CostoOferta.gratuito,
      ),
      isEmpty,
    );
    expect(
      (await catalog.buscarPublico(
        costo: CostoOferta.gratuito,
      )).single.ofertas.single.nombre,
      'Inglés',
    );
  });
  test(
    'localidad provincia país modalidad horario y edades utilizan datos publicados',
    () async {
      await extra();
      await SessionService.logout();
      expect(
        await catalog.buscarPublico(
          localidad: 'la plata',
          provincia: 'buenos aires',
          pais: 'argentina',
          modalidad: 'presencial',
          horario: 'tarde',
          edades: '12',
        ),
        hasLength(1),
      );
      expect(await catalog.buscarPublico(provincia: 'Córdoba'), isEmpty);
    },
  );
  test(
    'la proyección excluye credenciales propietarios operadores y contactos privados',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'inst_public_profile_v1_${fixture.instId}',
        jsonEncode({
          'telefonoPublico': 'contacto-publico',
          'descripcion': 'Descripción pública',
          'ownerAccountId': 'secreto-adicional',
        }),
      );
      await publish();
      await extra();
      await SessionService.logout();
      final json = jsonEncode((await catalog.buscarPublico()).single.toMap());
      for (final secret in [
        'private-cuit',
        'private@example.invalid',
        'private-phone',
        'owner-A',
        'secret-contact',
        'secreto-adicional',
        fixture.operatorId,
      ]) {
        expect(json, isNot(contains(secret)));
      }
      expect(json, contains('contacto-publico'));
    },
  );
  test('publicar y retirar requieren capacidad vigente del área', () async {
    await publish();
    await SessionService.logout();
    await expectLater(publish(), throwsStateError);
    await expectLater(
      catalog.retirarLocal(fixture.instId, fixture.areaId),
      throwsStateError,
    );
    expect(await catalog.buscarPublico(), hasLength(1));
  });
  test(
    'retiro explícito, eliminación y suspensión ocultan oferta publicada',
    () async {
      await publish();
      await catalog.retirarLocal(fixture.instId, fixture.areaId);
      expect(await catalog.buscarPublico(), isEmpty);
      await publish();
      await ih.guardarGruposInstitucion(fixture.instId, [
        fixture.group('group-A')..estado = EstadoCupo.suspendido,
      ]);
      expect(await catalog.buscarPublico(), isEmpty);
      await ih.guardarGruposInstitucion(fixture.instId, []);
      expect(await catalog.buscarPublico(), isEmpty);
    },
  );
  test(
    'cupos actuales usan máximo de ocupación y confirmaciones sin sumarlos',
    () async {
      await publish();
      for (var i = 0; i < 4; i++) {
        await fixture.request('confirmed-$i');
      }
      await SessionService.logout();
      expect(
        (await catalog.buscarPublico()).single.ofertas.single.disponibles,
        16,
      );
      await ih.guardarGruposInstitucion(fixture.instId, [
        fixture.group('group-A', occupied: 20),
      ]);
      expect(await catalog.buscarPublico(soloDisponibles: true), isEmpty);
    },
  );
  test(
    'publicación corrupta falla cerrada sin corregir almacenamiento',
    () async {
      await publish();
      final p = await SharedPreferences.getInstance();
      final k = p.getKeys().singleWhere(
        (k) => k.startsWith('atena_catalog_public_local_'),
      );
      await p.setString(k, '{roto');
      expect(await catalog.buscarPublico(), isEmpty);
      expect(p.getString(k), '{roto');
    },
  );
  test('publicación persiste tras reconstruir el almacenamiento', () async {
    await publish();
    await SessionService.logout();
    StorageService.instance.resetCache();
    expect(await CatalogoPublicableService().buscarPublico(), hasLength(1));
  });
  testWidgets(
    'anónimo busca, ve perfil, inicia login y conserva intención en registro',
    (tester) async {
      await publish();
      await SessionService.logout();
      await tester.pumpWidget(
        harness(
          const AlumnoBuscarInstitucionesPage.publica(textoInicial: 'primaria'),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Ver institución y ofertas');
      await tapText(tester, 'Solicitar inscripción');
      final login = tester.widget<AlumnoLoginPage>(
        find.byType(AlumnoLoginPage),
      );
      expect(login.solicitudPublica?.grupoId, 'group-A');
      final register = find.byWidgetPredicate(
        (w) =>
            w is TextButton &&
            w.child is Text &&
            ((w.child as Text).data ?? '').toLowerCase().contains('registr'),
      );
      // The actual registration control is asserted below by its localized text.
      expect(await SessionService.getSession(), isNull);
      expect(register.evaluate().length, lessThanOrEqualTo(1));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where(
            (t) =>
                t.toLowerCase().contains('cuenta') ||
                t.toLowerCase().contains('registr'),
          )
          .toList();
      final label = texts.firstWhere(
        (t) =>
            t.toLowerCase().contains('registr') ||
            t.toLowerCase().contains('crear'),
      );
      await tapText(tester, label);
      expect(
        tester
            .widget<AlumnoRegistroPage>(find.byType(AlumnoRegistroPage))
            .solicitudPublica
            ?.grupoId,
        'group-A',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'anónimo → login real → perfil → misma oferta → solicitud canónica',
    (tester) async {
      await publish();
      await student();
      await SessionService.logout();
      await tester.pumpWidget(
        harness(
          const AlumnoBuscarInstitucionesPage.publica(textoInicial: 'primaria'),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Ver institución y ofertas');
      await tapText(tester, 'Solicitar inscripción');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'public@example.invalid',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'DemoPublica123!',
      );
      final loginButton = find.byWidgetPredicate((w) => w is ElevatedButton);
      // PBKDF2 uses the real native implementation, outside the fake test clock.
      await tester.runAsync(() async {
        await tester.ensureVisible(loginButton);
        await tester.tap(loginButton);
        for (var n = 0; n < 100; n++) {
          if ((await SessionService.getSession())?.role == SessionRole.cuenta) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(CuentaHomePage), findsOneWidget);
      expect(
        tester
            .widget<CuentaHomePage>(find.byType(CuentaHomePage))
            .solicitudPublica
            ?.grupoId,
        'group-A',
      );
      await tapText(tester, 'Ficticia, Ana');
      final request = tester.widget<AlumnoSolicitarVacantePage>(
        find.byType(AlumnoSolicitarVacantePage),
      );
      expect(request.grupoCurricularId, 'group-A');
      expect(request.ownerAccountId, 'public-owner');
      expect(request.perfilId, 'public-profile');
      await tapText(tester, 'Enviar solicitud');
      await tapText(tester, 'Enviar');
      final requests =
          await SolicitudesService.obtenerSolicitudesParaInstitucion(
            institucionId: fixture.instId,
          );
      expect(requests, hasLength(1));
      expect(requests.single.grupoCurricularId, 'group-A');
      expect(requests.single.ownerAccountId, 'public-owner');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('autenticado explora y vuelve sin perder cuenta ni perfil', (
    tester,
  ) async {
    await publish();
    await student();
    await SessionService.logout();
    await tester.runAsync(
      () => CuentaService.loginCuenta(
        email: 'public@example.invalid',
        password: 'DemoPublica123!',
        recordarme: true,
      ),
    );
    await CuentaService.activarContextoCuenta(
      'public-owner',
      perfilAlumnoId: 'public-profile',
    );
    await tester.pumpWidget(
      harness(
        const AlumnoAreaPage(
          cuentaId: 'public-owner',
          perfilId: 'public-profile',
          documentoAlumno: '30991122',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Explorar instituciones'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ver institución y ofertas');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoAreaPage), findsOneWidget);
    expect(
      (await CuentaService.getPerfilAlumnoActivoValidado('public-owner'))?.id,
      'public-profile',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'cambios de oferta requieren republicar antes de una nueva solicitud',
    () async {
      await publish();
      await ih.guardarGruposInstitucion(fixture.instId, [
        fixture.group('group-A', name: 'Otro grupo'),
      ]);
      expect(await catalog.buscarPublico(), isEmpty);
      await publish();
      expect(
        (await catalog.buscarPublico()).single.ofertas.single.grupo,
        'Otro grupo',
      );
    },
  );
  test('sólo lectura y áreas ajenas no pueden publicar', () async {
    await expectLater(
      catalog.publicarLocal(fixture.instId, fixture.otherAreaId),
      throwsStateError,
    );
    await InstitucionOperadoresService.instance.setCapacidadesEnArea(
      institucionId: fixture.instId,
      operadorId: fixture.operatorId,
      areaId: fixture.areaId,
      capacidades: {CapacidadInstitucional.groupsRead},
    );
    await expectLater(publish(), throwsStateError);
    expect(await catalog.buscarPublico(), isEmpty);
  });
  test(
    'exploración no cambia sesión institucional ni operador activo',
    () async {
      await publish();
      final before = await SessionService.getSession();
      final prefs = await SharedPreferences.getInstance();
      final snapshot = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      await catalog.buscarPublico(texto: 'primaria');
      expect((await SessionService.getSession())?.userId, before?.userId);
      expect(
        (await SessionService.getSession())?.role,
        SessionRole.institucion,
      );
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, snapshot);
    },
  );
  testWidgets('ruta buscar abre directamente sin cuenta', (tester) async {
    await SessionService.logout();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AtenaRouter.onGenerateRoute,
        initialRoute: '/buscar',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlumnoBuscarInstitucionesPage), findsOneWidget);
    expect(await SessionService.getSession(), isNull);
  });
  testWidgets('publicación desde la pantalla requiere confirmación explícita', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        InstitucionCatalogoPage(
          institucionId: fixture.instId,
          areaId: fixture.areaId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Publicar en el buscador local');
    expect(await catalog.buscarPublico(), isEmpty);
    await tapText(tester, 'Publicar');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(await catalog.buscarPublico(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 640),
    const Size(412, 892),
    const Size(1440, 1000),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('buscador público ${size.width} $brightness texto ampliado', (
        tester,
      ) async {
        await publish();
        await SessionService.logout();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          harness(
            const AlumnoBuscarInstitucionesPage.publica(),
            brightness: brightness,
            scale: 1.6,
          ),
        );
        await tester.pumpAndSettle();
        await tapText(tester, 'Ubicación y más filtros');
        await tapText(tester, 'Buscar');
        await tapText(tester, 'Ver institución y ofertas');
        expect(find.byType(AlumnoInstitucionPerfilPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
