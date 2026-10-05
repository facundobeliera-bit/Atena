import 'dart:convert';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/alumnos/modulo_educativo.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart'
    hide PerfilInstitucion;
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/trayectoria_educativa_service.dart';
import 'package:atena_app/services/pdf/pdf_trayectoria.dart';
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/models/notificaciones/notificacion_atena.dart';
import 'package:atena_app/screens/alumnos/alumno_notificaciones_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/alumnos/trayectoria_educativa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institution = 'edu-school-a',
    owner = 'edu-owner-a',
    family = 'edu-family-a',
    profile = 'edu-student-a';
final service = TrayectoriaEducativaService.instance;
late AreaOperativa area;
late OperadorInstitucional operator;

Map<String, dynamic> fields(ModuloEducativo m) => switch (m) {
  ModuloEducativo.progreso => {'porcentaje': 35},
  ModuloEducativo.boletines => {
    'anio': 2026,
    'periodo': 'Primer trimestre',
    'calificaciones': {'Matemática': 8.5},
    'observaciones': 'Evaluación del período',
  },
  ModuloEducativo.titulos => {
    'titulo': 'Certificado de participación',
    'entidadEmisora': 'Escuela de prueba',
    'fechaEmision': '2026-09-28',
  },
  ModuloEducativo.becas => {
    'nombre': 'Beca institucional',
    'descripcion': 'Decisión ficticia',
    'fechaInicio': '2026-09-01',
    'fechaFin': '2026-12-31',
    'activa': true,
  },
  ModuloEducativo.sanciones => {
    'motivo': 'Incumplimiento de acuerdo',
    'detalle': 'Registro ficticio reservado',
    'tipo': 'Apercibimiento',
    'fecha': '2026-09-28',
    'hasta': '',
    'activa': true,
  },
  ModuloEducativo.equivalencias => {
    'institucionOrigenId': 'edu-school-origin',
    'materiaOrigen': 'Taller inicial',
    'materiaDestino': 'Tecnología',
    'observacion': 'Acta ficticia 1',
    'fecha': '2026-09-28',
    'aprobada': true,
  },
};

Future<void> loginInstitution({bool activate = true}) async {
  await CuentaService.loginCuenta(
    email: 'edu-owner@example.invalid',
    password: 'Prueba123!',
    recordarme: true,
  );
  await CuentaService.activarContextoInstitucion(owner, institution);
  if (activate) {
    await InstitucionContextoOperativoService.instance.activarContextoOperativo(
      institucionId: institution,
      ownerAccountId: owner,
      areaId: area.id,
      operadorId: operator.id,
    );
  }
}

Future<void> loginStudent() async {
  await CuentaService.loginCuenta(
    email: 'edu-family@example.invalid',
    password: 'Prueba123!',
    recordarme: true,
  );
  await CuentaService.activarContextoCuenta(family, perfilAlumnoId: profile);
}

Future<void> seed() async {
  for (final id in [owner, family]) {
    await CuentaService.actualizarCuenta(
      Cuenta(
        id: id,
        email: id == owner
            ? 'edu-owner@example.invalid'
            : 'edu-family@example.invalid',
        passwordHash: base64Encode(utf8.encode('Prueba123!')),
        perfilesAlumnoIds: id == family ? [profile] : [],
        perfilesInstitucionIds: id == owner ? [institution] : [],
        recordarme: true,
        creadaEl: DateTime(2026),
        ultimaSesion: DateTime(2026),
      ),
    );
  }
  await CuentaService.actualizarPerfilAlumno(
    PerfilAlumno(
      id: profile,
      cuentaId: family,
      ownerAccountId: family,
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
  final inst = Institucion(
    id: institution,
    nombre: 'Escuela de prueba',
    cuit: '30111111118',
    direccion: 'Calle ficticia',
    pais: 'Argentina',
    provincia: 'Buenos Aires',
    ciudad: 'La Plata',
    modalidad: ModalidadCursado.presencial,
    email: 'edu-owner@example.invalid',
    telefono: '',
    curricular: true,
    extracurricular: false,
    tipoInstitucion: TipoInstitucion.primaria,
    tipoPlan: 'premium',
    estadoPlan: EstadoPlanInstitucion.activo,
    planInicio: DateTime(2024),
    planFin: DateTime(2030),
    planConfig: null,
  );
  await ih.upsertInstitucion(inst);
  await CuentaService.actualizarPerfilInstitucion(
    PerfilInstitucion(
      id: institution,
      cuentaId: owner,
      ownerAccountId: owner,
      institucionId: institution,
      nombre: inst.nombre,
      emailContacto: inst.email,
      telefonoContacto: '',
      prefs: PreferenciasPerfil.defaults(),
    ),
  );
  area = (await InstitucionAreasService.instance.resolverYGuardar(
    institucionId: institution,
    tipo: TipoAreaOperativa.curricular,
    claveOrigen: 'primaria',
    nombre: 'Primaria',
  ))!;
  operator = await InstitucionOperadoresService.instance.asegurarPropietario(
    institucionId: institution,
    ownerAccountId: owner,
    perfilInstitucionId: institution,
    nombreVisible: 'Dirección ficticia',
  );
  await InstitucionOperadoresService.instance.asignarArea(
    institucionId: institution,
    operadorId: operator.id,
    areaId: area.id,
  );
  await SolicitudesRepositoryPrefs().saveSolicitudAlumno(
    SolicitudAlumno(
      id: 'enrollment-a',
      ownerAccountId: family,
      perfilId: profile,
      alumnoDocumento: '12345678',
      institucionId: institution,
      institucionNombre: inst.nombre,
      actividadNombre: 'Primaria',
      grupoCurricularId: 'group-a',
      areaId: area.id,
      aula: '1 A',
      turno: 'Mañana',
      esCurricular: true,
      estado: EstadoSolicitud.confirmada,
      fechaCreacion: DateTime(2026),
      fechaUltimoCambio: DateTime(2026),
      dedupKey: 'enrollment-a',
    ),
  );
  await loginInstitution();
}

Future<void> save(
  ModuloEducativo m, {
  String? id,
  bool visible = false,
  int? revision,
  Map<String, dynamic>? data,
}) => service.guardar(
  institucionId: institution,
  areaId: area.id,
  solicitudId: 'enrollment-a',
  modulo: m,
  id: id ?? m.name,
  datos: data ?? fields(m),
  visibleAlumno: visible,
  revisionEsperada: revision,
);
Future<List<Map<String, dynamic>>> readInstitution(ModuloEducativo m) =>
    service.leerInstitucion(
      institucionId: institution,
      areaId: area.id,
      solicitudId: 'enrollment-a',
      modulo: m,
    );
Future<List<Map<String, dynamic>>> readStudent(ModuloEducativo m) =>
    service.leerAlumno(ownerAccountId: family, perfilId: profile, modulo: m);
Widget shell(Widget page, {bool narrow = false}) => MaterialApp(
  key: UniqueKey(),
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: narrow
      ? ThemeData.dark()
      : ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
  builder: narrow
      ? (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        )
      : null,
  home: page,
);
Future<void> tapText(WidgetTester tester, String text) async {
  final matches = find.text(text);
  final finder = matches.evaluate().length > 1 ? matches.first : matches;
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });
  test(
    'registro con documento contradictorio no se muestra ni se sobrescribe',
    () async {
      await seed();
      await save(ModuloEducativo.sanciones, visible: true);
      final records = await AlumnoService.instance.leerEducacion(
        ownerAccountId: family,
        perfilId: profile,
        modulo: 'sanciones',
      );
      records.single['alumnoDocumento'] = '87654321';
      await AlumnoService.instance.guardarEducacion(
        ownerAccountId: family,
        perfilId: profile,
        modulo: 'sanciones',
        registros: records,
      );
      expect(await readInstitution(ModuloEducativo.sanciones), isEmpty);
      await expectLater(
        save(ModuloEducativo.sanciones, revision: 1),
        throwsStateError,
      );
      await loginStudent();
      expect(await readStudent(ModuloEducativo.sanciones), isEmpty);
      expect(
        await AlumnoService.instance.leerEducacion(
          ownerAccountId: family,
          perfilId: profile,
          modulo: 'sanciones',
        ),
        records,
      );
    },
  );
  testWidgets(
    'notificación de boletín abre el registro publicado del perfil autorizado',
    (tester) async {
      await tester.runAsync(seed);
      await save(ModuloEducativo.boletines, visible: true);
      await NotificacionesService.instance.pushToOwner(
        ownerAccountId: family,
        notificacion: NotificacionAtena(
          id: 'edu-noti',
          ownerAccountId: family,
          perfilId: profile,
          scope: NotificacionScopeAtena.owner,
          leida: false,
          tipo: TipoNotificacionAtena.boletinActualizado,
          titulo: 'Boletín disponible',
          mensaje: 'Consultá tu boletín',
          fecha: DateTime(2026, 9, 28),
          deeplink: '/boletines?ownerAccountId=$family&perfilId=$profile',
        ),
      );
      await tester.runAsync(loginStudent);
      await tester.pumpWidget(
        shell(
          const AlumnoNotificacionesPage(
            alumnoDocumento: '12345678',
            perfilIdFiltro: profile,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boletín disponible'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Matemática: 8.5'), findsOneWidget);
      expect(find.text('Registrar información'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final module in ModuloEducativo.values) {
    testWidgets(
      '${module.label}: formulario y registro en 320 px con texto doble',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(seed);
        await tester.pumpWidget(
          shell(
            TrayectoriaEducativaPage.institucion(
              institucionId: institution,
              areaId: area.id,
              solicitudId: 'enrollment-a',
            ).pagina(module),
            narrow: true,
          ),
        );
        await tester.pumpAndSettle();
        await tapText(tester, 'Registrar información');
        for (final entry in fields(module).entries) {
          if (!module.campos.containsKey(entry.key)) continue;
          final field = find.byKey(ValueKey('edu_${entry.key}'));
          await tester.scrollUntilVisible(
            field,
            140,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.enterText(
            field,
            entry.value is Map ? 'Matemática = 8.5' : entry.value.toString(),
          );
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tapText(tester, 'Guardar registro');
        await tester.scrollUntilVisible(
          find.text('Actualizar registro'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Actualizar registro'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(await readInstitution(module), hasLength(1));
      },
    );
  }
  for (final module in ModuloEducativo.values) {
    test(
      '${module.label}: crear, corregir, persistir, reingresar y publicar sin exponer historial interno',
      () async {
        await seed();
        expect(await readInstitution(module), isEmpty);
        await save(module);
        var records = await readInstitution(module);
        expect(records.single['createdByOperatorId'], operator.id);
        expect(records.single['grupoId'], 'group-a');
        records.single['notaInternaLegacy'] =
            'No publicar metadatos desconocidos';
        await AlumnoService.instance.guardarEducacion(
          ownerAccountId: family,
          perfilId: profile,
          modulo: module.name,
          registros: records,
        );
        await CuentaService.logoutCuenta();
        await loginStudent();
        expect(await readStudent(module), isEmpty);
        await CuentaService.logoutCuenta();
        StorageService.instance.resetCache();
        await loginInstitution();
        final updated = {...fields(module)};
        final change = switch (module) {
          ModuloEducativo.progreso => ('porcentaje', 70),
          ModuloEducativo.boletines => (
            'observaciones',
            'Revisión del período',
          ),
          ModuloEducativo.titulos => ('titulo', 'Certificado corregido'),
          ModuloEducativo.becas => ('descripcion', 'Vigencia revisada'),
          ModuloEducativo.sanciones => ('detalle', 'Corrección institucional'),
          ModuloEducativo.equivalencias => ('observacion', 'Acta rectificada'),
        };
        updated[change.$1] = change.$2;
        await save(module, visible: true, revision: 1, data: updated);
        records = await readInstitution(module);
        expect(records, hasLength(1));
        expect(records.single['revision'], 2);
        expect(records.single[change.$1], change.$2);
        expect(
          (records.single['historial'] as List).single['visibleAlumno'],
          false,
        );
        await CuentaService.logoutCuenta();
        StorageService.instance.resetCache();
        await loginStudent();
        final visible = await readStudent(module);
        expect(visible.single['id'], module.name);
        expect(visible.single.containsKey('historial'), false);
        expect(visible.single.containsKey('notaInternaLegacy'), false);
        await expectLater(save(module, revision: 2), throwsStateError);
        await CuentaService.logoutCuenta();
        await expectLater(readStudent(module), throwsStateError);
        await loginStudent();
        expect(await readStudent(module), hasLength(1));
      },
    );
  }
  test(
    'institución, área, propietario y perfil ajenos son rechazados',
    () async {
      await seed();
      await expectLater(
        service.leerInstitucion(
          institucionId: 'foreign',
          areaId: area.id,
          solicitudId: 'enrollment-a',
          modulo: ModuloEducativo.sanciones,
        ),
        throwsStateError,
      );
      await expectLater(
        service.leerInstitucion(
          institucionId: institution,
          areaId: 'foreign-area',
          solicitudId: 'enrollment-a',
          modulo: ModuloEducativo.sanciones,
        ),
        throwsStateError,
      );
      await save(ModuloEducativo.sanciones, visible: true);
      await loginStudent();
      await expectLater(
        service.leerAlumno(
          ownerAccountId: owner,
          perfilId: profile,
          modulo: ModuloEducativo.sanciones,
        ),
        throwsStateError,
      );
      await expectLater(
        service.leerAlumno(
          ownerAccountId: family,
          perfilId: 'foreign-profile',
          modulo: ModuloEducativo.sanciones,
        ),
        throwsStateError,
      );
    },
  );
  test('permisos educativos explícitos, consulta sola y revocación', () async {
    await seed();
    final restricted = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: 'Sólo grupos',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institution,
      operadorId: restricted.id,
      areaId: area.id,
    );
    await InstitucionContextoOperativoService.instance.activarContextoOperativo(
      institucionId: institution,
      ownerAccountId: owner,
      areaId: area.id,
      operadorId: restricted.id,
    );
    await expectLater(
      readInstitution(ModuloEducativo.progreso),
      throwsStateError,
    );
    await expectLater(save(ModuloEducativo.progreso), throwsStateError);
    await InstitucionOperadoresService.instance.setCapacidadesEnArea(
      institucionId: institution,
      operadorId: restricted.id,
      areaId: area.id,
      capacidades: {CapacidadInstitucional.educationRead},
    );
    expect(await readInstitution(ModuloEducativo.progreso), isEmpty);
    await expectLater(save(ModuloEducativo.progreso), throwsStateError);
    await InstitucionOperadoresService.instance.setCapacidadesEnArea(
      institucionId: institution,
      operadorId: restricted.id,
      areaId: area.id,
      capacidades: {
        CapacidadInstitucional.educationRead,
        CapacidadInstitucional.educationWrite,
      },
    );
    await save(ModuloEducativo.progreso);
    expect(
      (await readInstitution(
        ModuloEducativo.progreso,
      )).single['createdByOperatorId'],
      restricted.id,
    );
    await InstitucionOperadoresService.instance.setCapacidadesEnArea(
      institucionId: institution,
      operadorId: restricted.id,
      areaId: area.id,
      capacidades: {},
    );
    await expectLater(
      readInstitution(ModuloEducativo.progreso),
      throwsStateError,
    );
    await expectLater(
      save(ModuloEducativo.progreso, revision: 1),
      throwsStateError,
    );
  });
  test(
    'legacy intacto; corrupción no se interpreta como lista vacía',
    () async {
      await seed();
      final prefs = await SharedPreferences.getInstance();
      final historical = {
        'motivo': 'Histórico sin publicación',
        'institucionId': institution,
      };
      await AlumnoService.instance.setSancionesRaw(
        ownerAccountId: family,
        perfilId: profile,
        sanciones: [historical],
      );
      await save(ModuloEducativo.sanciones);
      expect(
        (await AlumnoService.instance.getSancionesRaw(
          ownerAccountId: family,
          perfilId: profile,
        )).first,
        historical,
      );
      await loginStudent();
      expect(await readStudent(ModuloEducativo.sanciones), isEmpty);
      await loginInstitution();
      await prefs.setString('v3_alumno_progresos_$profile', '{roto');
      await expectLater(save(ModuloEducativo.progreso), throwsFormatException);
      expect(prefs.getString('v3_alumno_progresos_$profile'), '{roto');
    },
  );
  test('duplicados, revisiones simultáneas y boletín incompleto', () async {
    await seed();
    await save(ModuloEducativo.progreso);
    await expectLater(
      save(ModuloEducativo.progreso, id: 'otro'),
      throwsStateError,
    );
    await expectLater(save(ModuloEducativo.progreso), throwsStateError);
    await save(
      ModuloEducativo.boletines,
      data: {
        ...fields(ModuloEducativo.boletines),
        'calificaciones': <String, double>{},
      },
    );
    expect(
      (await readInstitution(ModuloEducativo.boletines)).single['completo'],
      false,
    );
    await expectLater(
      save(ModuloEducativo.boletines, id: 'repetido'),
      throwsStateError,
    );
    await save(ModuloEducativo.becas, id: 'beca-1');
    await save(ModuloEducativo.becas, id: 'beca-2');
    expect(await readInstitution(ModuloEducativo.becas), hasLength(2));
    await expectLater(
      save(ModuloEducativo.progreso, revision: 1, data: {'porcentaje': 101}),
      throwsArgumentError,
    );
    final results = await Future.wait([
      save(
        ModuloEducativo.progreso,
        revision: 1,
        data: {'porcentaje': 40},
      ).then((_) => true, onError: (_) => false),
      save(
        ModuloEducativo.progreso,
        revision: 1,
        data: {'porcentaje': 50},
      ).then((_) => true, onError: (_) => false),
    ]);
    expect(results, [true, false]);
    expect(
      (await readInstitution(ModuloEducativo.progreso)).single['porcentaje'],
      40,
    );
  });
  test(
    'PDF de boletín incompleto y título usa datos guardados; no modifica registros',
    () async {
      await seed();
      for (final m in [ModuloEducativo.boletines, ModuloEducativo.titulos]) {
        await save(
          m,
          data: m == ModuloEducativo.boletines
              ? {...fields(m), 'calificaciones': <String, double>{}}
              : fields(m),
        );
        final before = await readInstitution(m);
        final bytes = await PdfTrayectoria.build(m, before.single).save();
        expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
        expect(bytes.length, greaterThan(1000));
        expect(await readInstitution(m), before);
      }
    },
  );
  test(
    'rechaza inscripción de otra área y contradicción de propietario institucional',
    () async {
      await seed();
      final original = (await SolicitudesRepositoryPrefs()
          .getSolicitudAlumnoById('enrollment-a'))!;
      await SolicitudesRepositoryPrefs().saveSolicitudAlumno(
        original.copyWith(areaId: 'otra-area'),
      );
      await expectLater(save(ModuloEducativo.sanciones), throwsStateError);
      await SolicitudesRepositoryPrefs().saveSolicitudAlumno(original);
      await SessionService.setInstitucionOwnerAccountId('propietario-ajeno');
      await expectLater(save(ModuloEducativo.sanciones), throwsStateError);
      expect(
        await AlumnoService.instance.getSancionesRaw(
          ownerAccountId: family,
          perfilId: profile,
        ),
        isEmpty,
      );
    },
  );
  testWidgets(
    'menú → área → operador → seis módulos → reingreso institucional y familiar',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(seed);
      Future<void> enterInstitution() async {
        await tester.runAsync(() => loginInstitution(activate: false));
        await tester.pumpWidget(
          shell(
            const InstitucionMenuPage(
              ownerAccountId: owner,
              institucionPerfilId: institution,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.admin_panel_settings));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('enter-area-${area.id}')));
        await tester.pumpAndSettle();
        expect(find.text('¿Quién está ingresando?'), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('operator-${operator.id}')));
        await tester.pumpAndSettle();
        expect(find.byType(InstitucionAreaPage), findsOneWidget);
        await tapText(tester, 'Trayectoria del alumnado');
        await tapText(tester, 'Alumno 12345678');
      }

      await enterInstitution();
      for (final module in ModuloEducativo.values) {
        await tapText(tester, module.label);
        await tapText(tester, 'Registrar información');
        for (final e in fields(module).entries) {
          if (!module.campos.containsKey(e.key)) continue;
          final value = e.value is Map
              ? 'Matemática = 8.5'
              : e.value.toString();
          await tester.enterText(find.byKey(ValueKey('edu_${e.key}')), value);
        }
        await tapText(tester, 'Compartir con el alumno/familia');
        await tapText(tester, 'Guardar registro');
        expect(
          find.text('Actualizar registro'),
          findsOneWidget,
          reason:
              '${module.name}: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | ')}',
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      await CuentaService.logoutCuenta();
      StorageService.instance.resetCache();
      await enterInstitution();
      await tapText(tester, ModuloEducativo.sanciones.label);
      expect(find.textContaining('Incumplimiento de acuerdo'), findsOneWidget);
      await CuentaService.logoutCuenta();
      Future<void> enterStudent() async {
        await tester.runAsync(loginStudent);
        await tester.pumpWidget(shell(const CuentaHomePage(cuentaId: family)));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Prueba, Ana'));
        await tester.pumpAndSettle();
        expect(find.byType(AlumnoAreaPage), findsOneWidget);
        await tapText(tester, 'Trayectoria educativa');
      }

      await enterStudent();
      for (final m in ModuloEducativo.values) {
        await tapText(tester, m.label);
        expect(find.textContaining('Dirección ficticia'), findsOneWidget);
        expect(find.text('Actualizar registro'), findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      await CuentaService.logoutCuenta();
      StorageService.instance.resetCache();
      await enterStudent();
      await tapText(tester, ModuloEducativo.boletines.label);
      expect(find.textContaining('Matemática: 8.5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'móvil, modo oscuro y texto doble: vacío, formulario y validación',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(seed);
      await tester.pumpWidget(
        shell(
          TrayectoriaEducativaPage.institucion(
            institucionId: institution,
            areaId: area.id,
            solicitudId: 'enrollment-a',
          ),
          narrow: true,
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Boletines');
      await tester.scrollUntilVisible(
        find.text('Todavía no hay información disponible en esta sección.'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Todavía no hay información disponible en esta sección.'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tapText(tester, 'Registrar información');
      await tapText(tester, 'Guardar registro');
      expect(find.textContaining('Ingresá un año válido'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
