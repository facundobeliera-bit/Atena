import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/documentacion_operativa_service.dart';
import 'package:atena_app/services/documentos_temporales_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_emisiones_service.dart';
import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/notificaciones_service.dart';
import 'package:atena_app/services/alumno_instituciones_search_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/models/alumnos/modulo_educativo.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/models/extracurriculares/actividad_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/models/calendario/evento_calendario.dart';
import 'package:atena_app/repositories/solicitudes_repository_prefs.dart';
import 'package:atena_app/screens/instituciones/institucion_documentos_page.dart';
import 'package:atena_app/screens/alumnos/alumno_pdfs_page.dart';
import 'package:atena_app/models/alumnos/alumnos_integrados.dart';
import 'education_operational_flow_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });
  tearDown(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'PDF rechaza sesión ajena y enlaza documentos educativos reales',
    (tester) async {
      await tester.runAsync(fixture.seed);
      await tester.pumpWidget(
        fixture.shell(
          AlumnoPdfsPage(
            ownerAccountId: fixture.family,
            perfilId: fixture.profile,
            alumno: Alumno(
              documento: '12345678',
              nombre: 'Ana',
              apellido: 'Prueba',
              fechaNacimiento: DateTime(2015),
              email: '',
              telefono: '',
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.picture_as_pdf));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Iniciá sesión con la cuenta del alumno.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Documentos educativos'));
      await tester.pumpAndSettle();
      expect(find.text('Trayectoria educativa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'publicar educación notifica sin copiar datos internos y actualizar no duplica',
    () async {
      await fixture.seed();
      await fixture.save(ModuloEducativo.sanciones);
      expect(await NotificacionesService.listarOwner(fixture.family), isEmpty);
      await fixture.save(ModuloEducativo.sanciones, visible: true, revision: 1);
      var notices = await NotificacionesService.listarOwner(fixture.family);
      expect(notices, hasLength(1));
      expect(notices.single.deeplink, contains('/sanciones?'));
      expect(notices.single.mensaje, isNot(contains('Incumplimiento')));
      await fixture.save(ModuloEducativo.sanciones, visible: true, revision: 2);
      expect(
        await NotificacionesService.listarOwner(fixture.family),
        hasLength(1),
      );
      await fixture.save(
        ModuloEducativo.sanciones,
        visible: false,
        revision: 3,
      );
      await fixture.loginStudent();
      expect(await fixture.readStudent(ModuloEducativo.sanciones), isEmpty);
    },
  );

  test(
    'Dirección conserva identidad y capacidades; no se puede autodesignar',
    () async {
      await fixture.seed();
      final service = InstitucionOperadoresService.instance;
      final op = await service.crearLocal(
        institucionId: fixture.institution,
        nombreVisible: 'Dirección ficticia',
      );
      await service.establecerDireccion(
        institucionId: fixture.institution,
        operadorId: op.id,
        esDirector: true,
      );
      StorageService.instance.resetCache();
      final saved = (await service.buscar(fixture.institution, op.id))!;
      expect(saved.esDirector, isTrue);
      expect(saved.esPropietario, isFalse);
      expect(saved.capacidades, isEmpty);
      expect(saved.cuentaId, isNull);
      expect(
        (await service.buscar(
          fixture.institution,
          fixture.operator.id,
        ))!.esDirector,
        isFalse,
      );
      await service.activar(
        institucionId: fixture.institution,
        operadorId: op.id,
      );
      await expectLater(
        service.establecerDireccion(
          institucionId: fixture.institution,
          operadorId: op.id,
          esDirector: false,
        ),
        throwsStateError,
      );
      await fixture.loginInstitution();
      await service.establecerDireccion(
        institucionId: fixture.institution,
        operadorId: op.id,
        esDirector: false,
      );
      expect(
        (await service.buscar(fixture.institution, op.id))!.esDirector,
        isFalse,
      );
      final historical = op.toMap()..remove('esDirector');
      expect(OperadorInstitucional.fromMap(historical).esDirector, isFalse);
    },
  );

  test(
    'documentación: solicitud autorizada, archivo real, reingreso y aislamiento',
    () async {
      await fixture.seed();
      await DocumentacionOperativaService.solicitar(
        fixture.institution,
        'enrollment-a',
        TipoDocumento.values.first,
        'Adjuntar comprobante ficticio',
      );
      var requests = await DocumentacionOperativaService.solicitudesInstitucion(
        fixture.institution,
      );
      expect(requests.single.areaId, fixture.area.id);
      expect(requests.single.emittedByOperatorId, fixture.operator.id);
      final id = requests.single.id;
      await expectLater(
        DocumentacionOperativaService.solicitar(
          fixture.institution,
          'ajena',
          TipoDocumento.values.first,
          '',
        ),
        throwsStateError,
      );
      await fixture.loginStudent();
      final bytes = Uint8List.fromList(
        utf8.encode('%PDF-1.4\n%fictitious test content\n%%EOF'),
      );
      await DocumentacionOperativaService.adjuntar(
        fixture.family,
        fixture.profile,
        id,
        bytes,
      );
      await expectLater(
        DocumentacionOperativaService.adjuntar(
          fixture.family,
          fixture.profile,
          id,
          bytes,
        ),
        throwsStateError,
      );
      await expectLater(
        DocumentacionOperativaService.validarAlumno(
          fixture.owner,
          fixture.profile,
        ),
        throwsStateError,
      );
      StorageService.instance.resetCache();
      await fixture.loginInstitution();
      final docs = await DocumentacionOperativaService.documentosInstitucion(
        fixture.institution,
      );
      expect(docs, hasLength(1));
      expect(Uri.parse(docs.single.ref).data!.contentAsBytes(), bytes);
      expect(
        (await DocumentacionOperativaService.solicitudesInstitucion(
          fixture.institution,
        )).single.estado,
        EstadoSolicitudDocumento.cumplida,
      );
      expect(
        (await DocumentacionOperativaService.abrir(docs.single)).id,
        docs.single.id,
      );
      await CuentaService.logoutCuenta();
      await expectLater(
        DocumentacionOperativaService.abrir(docs.single),
        throwsStateError,
      );
    },
  );

  test(
    'documentación rechaza archivo inválido, excesivo y solicitud cancelada',
    () async {
      await fixture.seed();
      expect(
        () => DocumentacionOperativaService.referencia(Uint8List(1)),
        throwsArgumentError,
      );
      expect(
        () => DocumentacionOperativaService.referencia(
          Uint8List(DocumentacionOperativaService.maxBytes + 1),
        ),
        throwsArgumentError,
      );
      await DocumentacionOperativaService.solicitar(
        fixture.institution,
        'enrollment-a',
        TipoDocumento.values.first,
        'Prueba',
      );
      final s = (await DocumentacionOperativaService.solicitudesInstitucion(
        fixture.institution,
      )).single;
      await DocumentacionOperativaService.cancelar(fixture.institution, s.id);
      await fixture.loginStudent();
      await expectLater(
        DocumentacionOperativaService.adjuntar(
          fixture.family,
          fixture.profile,
          s.id,
          Uint8List.fromList(utf8.encode('%PDF-1.4')),
        ),
        throwsStateError,
      );
      expect(
        await DocumentosTemporalesService.listarDocumentosPerfil(
          perfilId: fixture.profile,
        ),
        isEmpty,
      );
    },
  );

  test(
    'comunicaciones rechazan destinatario manipulado antes de escribir y deduplican',
    () async {
      await fixture.seed();
      final s = (await SolicitudesRepositoryPrefs().getSolicitudAlumnoById(
        'enrollment-a',
      ))!;
      Future<Map<String, String>> emit(List<SolicitudAlumno> list) =>
          InstitucionEmisionesService.instance.emitirEventoEspecialAutorizado(
            institucionId: fixture.institution,
            institucionNombre: 'Escuela ficticia',
            confirmados: list,
            esCurricular: true,
            areaId: fixture.area.id,
            inicio: DateTime(2026, 10, 1),
            titulo: 'Reunión',
            descripcion: 'Encuentro ficticio',
            tipoEspecial: TipoEventoEspecial.otro,
          );
      await expectLater(
        emit([s, s.copyWith(ownerAccountId: 'otro-owner')]),
        throwsStateError,
      );
      expect(
        await AlumnoService.instance.getCalendarioRaw(
          ownerAccountId: fixture.family,
          perfilId: fixture.profile,
        ),
        isEmpty,
      );
      final result = await emit([s, s]);
      expect(result, hasLength(1));
      final events = await AlumnoService.instance.getCalendarioRaw(
        ownerAccountId: fixture.family,
        perfilId: fixture.profile,
      );
      expect(events, hasLength(1));
      expect(events.single['emittedByOperatorId'], fixture.operator.id);
      await SolicitudesRepositoryPrefs().saveSolicitudAlumno(
        s.copyWith(areaId: 'otra-area'),
      );
      await expectLater(emit([s]), throwsStateError);
    },
  );

  testWidgets(
    'documentación usa inscripción visible sin IDs manuales a 320 px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(fixture.seed);
      await tester.pumpWidget(
        fixture.shell(
          const InstitucionDocumentosPage(
            institucionId: fixture.institution,
            institucionNombre: 'Escuela ficticia',
          ),
          narrow: true,
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Alumno e inscripción'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Alumno e inscripción'), findsOneWidget);
      expect(find.text('Simular subida'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final entry in <(String?, AlumnoPrecioFiltro, bool)>[
    (null, AlumnoPrecioFiltro.gratuitos, false),
    ('Consultar', AlumnoPrecioFiltro.conCosto, false),
    (r'$0,00', AlumnoPrecioFiltro.gratuitos, true),
    (r'$15.000', AlumnoPrecioFiltro.conCosto, true),
  ]) {
    test(
      'búsqueda de actividad distingue precio ${entry.$1} / ${entry.$2.name}',
      () async {
        await fixture.seed();
        final inst = (await ih.cargarInstitucionPorId(fixture.institution))!;
        await ih.upsertInstitucion(inst.copyWith(extracurricular: true));
        await ih.guardarActividadesExtracurricularesEnInstitucion(
          institucionId: fixture.institution,
          actividades: [
            ActividadExtracurricular(
              id: 'actividad-artes',
              institucionId: fixture.institution,
              bloque: BloqueExtracurricular.otros,
              nombre: 'Taller de cerámica',
              activa: true,
              cupoMaximo: 10,
              cupoOcupado: 0,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              edades: 'Desde 12 años',
              precio: entry.$1,
            ),
          ],
        );
        final results = await AlumnoInstitucionesSearchService.search(
          AlumnoInstitucionSearchFilters(
            scope: AlumnoBusquedaScope.extracurricular,
            texto: 'cerámica',
            precio: entry.$2,
            edad: 16,
          ),
        );
        expect(results.isNotEmpty, entry.$3);
        expect(
          await AlumnoInstitucionesSearchService.search(
            const AlumnoInstitucionSearchFilters(
              scope: AlumnoBusquedaScope.extracurricular,
              texto: 'cerámica',
              edad: 8,
            ),
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'documentación corrupta no se convierte en vacío ni se sobrescribe',
    () async {
      await fixture.seed();
      final prefs = await SharedPreferences.getInstance();
      final key = 'docs_temporales_v1_solicitudes_${fixture.profile}';
      await prefs.setString(key, '{broken');
      StorageService.instance.resetCache();
      await expectLater(
        DocumentacionOperativaService.solicitar(
          fixture.institution,
          'enrollment-a',
          TipoDocumento.values.first,
          '',
        ),
        throwsFormatException,
      );
      expect(prefs.getString(key), '{broken');
    },
  );

  test(
    'documentación: subidas simultáneas no duplican ni cruzan perfiles',
    () async {
      await fixture.seed();
      await DocumentacionOperativaService.solicitar(
        fixture.institution,
        'enrollment-a',
        TipoDocumento.values.first,
        'Prueba',
      );
      final s = (await DocumentacionOperativaService.solicitudesInstitucion(
        fixture.institution,
      )).single;
      await fixture.loginStudent();
      final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4'));
      final first = DocumentacionOperativaService.adjuntar(
        fixture.family,
        fixture.profile,
        s.id,
        bytes,
      );
      await expectLater(
        DocumentacionOperativaService.adjuntar(
          fixture.family,
          fixture.profile,
          s.id,
          bytes,
        ),
        throwsStateError,
      );
      await first;
      expect(
        await DocumentosTemporalesService.listarDocumentosPerfil(
          perfilId: fixture.profile,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'reintento documental completa estado pendiente sin duplicar el archivo persistido',
    () async {
      await fixture.seed();
      await DocumentacionOperativaService.solicitar(
        fixture.institution,
        'enrollment-a',
        TipoDocumento.values.first,
        'Prueba',
      );
      final s = (await DocumentacionOperativaService.solicitudesInstitucion(
        fixture.institution,
      )).single;
      await fixture.loginStudent();
      final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4'));
      await DocumentacionOperativaService.adjuntar(
        fixture.family,
        fixture.profile,
        s.id,
        bytes,
      );
      final prefs = await SharedPreferences.getInstance();
      final key = 'docs_temporales_v1_solicitudes_${fixture.profile}';
      final rows = (jsonDecode(prefs.getString(key)!) as List);
      rows.single['estado'] = 'pendiente';
      await prefs.setString(key, jsonEncode(rows));
      StorageService.instance.resetCache();
      await DocumentacionOperativaService.adjuntar(
        fixture.family,
        fixture.profile,
        s.id,
        bytes,
      );
      expect(
        await DocumentosTemporalesService.listarDocumentosPerfil(
          perfilId: fixture.profile,
        ),
        hasLength(1),
      );
      expect(
        (await DocumentosTemporalesService.listarSolicitudesPerfil(
          perfilId: fixture.profile,
        )).single.estado,
        EstadoSolicitudDocumento.cumplida,
      );
    },
  );

  test(
    'ficha extracurricular usa confirmadas reales, autor actual y rechaza destinatario ajeno',
    () async {
      await fixture.seed();
      final area = (await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: fixture.institution,
        tipo: TipoAreaOperativa.extracurricular,
        claveOrigen: 'otros',
        nombre: 'Talleres',
      ))!;
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: fixture.institution,
        operadorId: fixture.operator.id,
        areaId: area.id,
      );
      await InstitucionContextoOperativoService.instance
          .activarContextoOperativo(
            institucionId: fixture.institution,
            ownerAccountId: fixture.owner,
            areaId: area.id,
            operadorId: fixture.operator.id,
          );
      final repo = SolicitudesRepositoryPrefs();
      final old = (await repo.getSolicitudAlumnoById('enrollment-a'))!;
      await repo.saveSolicitudAlumno(
        SolicitudAlumno.fromMap({
          ...old.toMap(),
          'areaId': area.id,
          'esCurricular': false,
          'moduleKey': 'otros',
        }),
      );
      final service = ExtracurricularesService.instance;
      final recipients = await service.destinatariosOperativos(
        institucionId: fixture.institution,
        moduleKey: 'otros',
      );
      expect(recipients, hasLength(1));
      final payload = <String, dynamic>{
        'version': 1,
        'institucionId': fixture.institution,
        'moduleKey': 'otros',
        'bloqueKey': 'otros',
        'bloqueLabel': 'Talleres',
        'title': 'Reunión',
        'content': 'Información ficticia',
        'date': '2026-10-01',
        'time': '09:00',
        'addToCalendar': true,
        'recipients': recipients,
      };
      await expectLater(
        service.emitirFichaAutorizada({
          ...payload,
          'recipients': [
            {'ownerAccountId': 'ajeno', 'perfilId': fixture.profile},
          ],
        }),
        throwsStateError,
      );
      await service.emitirFichaAutorizada({
        ...payload,
        'emittedByOperatorId': 'suplantado',
      });
      final events = await AlumnoService.instance.getCalendarioRaw(
        ownerAccountId: fixture.family,
        perfilId: fixture.profile,
      );
      expect(events.single['emittedByOperatorId'], fixture.operator.id);
      expect(events.single['areaId'], area.id);
      await repo.saveSolicitudAlumno(
        SolicitudAlumno.fromMap({
          ...old.toMap(),
          'areaId': area.id,
          'esCurricular': false,
          'moduleKey': 'otros',
        }).copyWith(estado: EstadoSolicitud.canceladaPorAlumno),
      );
      expect(
        await service.destinatariosOperativos(
          institucionId: fixture.institution,
          moduleKey: 'otros',
        ),
        isEmpty,
      );
      await expectLater(
        service.emitirFichaAutorizada(payload),
        throwsStateError,
      );
    },
  );
}
