import 'package:atena_app/main.dart' as app;
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/actividad_extracurricular.dart';
import 'package:atena_app/models/extracurriculares/grupo_extracurricular.dart';
import 'package:atena_app/models/solicitudes/solicitud_alumno.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/instituciones/institucion_mis_solicitudes_page.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/alumno_solicitar_vacante_page.dart';
import 'package:atena_app/screens/alumnos/alumno_seleccion_grupo_extracurricular_page.dart';
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/alumnos/alumno_documentos_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/institucion_grupos_autorizacion_service.dart';
import 'package:atena_app/services/extracurriculares_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/solicitudes_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget shell(Widget page) => MaterialApp(
  key: UniqueKey(),
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: page,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });

  testWidgets('solicitud legible en teléfono pequeño con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const AlumnoSolicitarVacantePage(
          alumnoDocumento: '12345678',
          institucionId: 'escuela',
          institucionNombre:
              'Institución educativa ficticia de formación municipal',
          actividadNombre: 'Taller de programación y robótica educativa',
          esCurricular: false,
          ownerAccountId: 'familia',
          perfilId: 'alumna',
          aula: 'Grupo inicial de formación',
          turno: 'Lunes y miércoles de 14:00 a 17:00',
          moduleKey: 'otros',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Enviar solicitud'), 250);
    await Scrollable.ensureVisible(
      tester.element(find.text('Enviar solicitud')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      await SolicitudesService.cargarSolicitudesPorOwner(
        ownerAccountId: 'familia',
      ),
      isEmpty,
    );
  });

  testWidgets(
    'recorrido local: registro y plan → grupos → alumno solicita → operador confirma → reingreso',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const email = 'escuela-circuito@example.invalid';
      const password = 'SoloPrueba2026!';
      await tester.pumpWidget(
        shell(
          InstitucionPlanPage(
            draft: InstitucionRegistroDraft(
              nombre: 'Escuela Circuito',
              cuit: '30123456789',
              direccion: 'Calle Ficticia 123',
              pais: 'Argentina',
              provincia: 'Buenos Aires',
              ciudad: 'La Plata',
              modalidad: ModalidadCursado.presencial,
              email: email,
              telefono: '1122334455',
              pass: password,
              tipo: TipoInstitucion.otra,
              nivelesSeleccionados: [NivelCurricular.primaria],
              bloquesSeleccionados: [BloqueExtracurricular.otros],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(Icons.check),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.runAsync(() async {
        tester
            .widget<ElevatedButton>(
              find.byWidgetPredicate((w) => w is ElevatedButton).last,
            )
            .onPressed!();
        for (var i = 0; i < 60; i++) {
          final id = await InstitucionService.getInstitucionIdByEmail(email);
          if (id != null &&
              await InstitucionService.getInstitucionById(id) != null) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionMenuPage), findsOneWidget);
      final institution = (await InstitucionService.getInstitucionIdByEmail(
        email,
      ))!;
      final owner = (await CuentaService.getPerfilInstitucionById(
        institution,
      ))!.cuentaId;
      final primary = (await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: institution,
        tipo: TipoAreaOperativa.curricular,
        claveOrigen: 'primaria',
        nombre: 'Primaria',
      ))!;
      final extra = (await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: institution,
        tipo: TipoAreaOperativa.extracurricular,
        claveOrigen: 'otros',
        nombre: 'Talleres',
      ))!;
      final operator = await InstitucionOperadoresService.instance
          .asegurarPropietario(
            institucionId: institution,
            ownerAccountId: owner,
            perfilInstitucionId: institution,
            nombreVisible: 'Dirección ficticia',
          );
      Future<void> activate(String area) async {
        await InstitucionOperadoresService.instance.asignarArea(
          institucionId: institution,
          operadorId: operator.id,
          areaId: area,
        );
        expect(
          await InstitucionContextoOperativoService.instance
              .activarContextoOperativo(
                institucionId: institution,
                ownerAccountId: owner,
                areaId: area,
                operadorId: operator.id,
              ),
          isNotNull,
        );
      }

      await activate(primary.id);
      await InstitucionGruposAutorizacionService.guardarCurriculares(
        institucionId: institution,
        areaId: primary.id,
        grupos: [
          GrupoInstitucional(
            id: 'grado-circuito',
            institucionId: institution,
            actividadNombre: 'Primaria',
            nombreGrupo: '1 A',
            aula: 'Primaria • 1 A',
            turno: 'Mañana • 08:00-12:00',
            cupoMaximo: 2,
            cupoOcupado: 0,
            estado: EstadoCupo.disponible,
          ),
        ],
      );
      await ih.upsertActividadExtracurricular(
        institucionId: institution,
        actividad: ActividadExtracurricular(
          id: 'taller-circuito',
          institucionId: institution,
          bloque: BloqueExtracurricular.otros,
          nombre: 'Robótica',
          activa: true,
          cupoMaximo: 2,
          cupoOcupado: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      await ExtracurricularesService.instance.upsertGrupo(
        institution,
        GrupoExtracurricular(
          id: 'grupo-robotica',
          institucionId: institution,
          bloque: BloqueExtracurricular.otros,
          actividadNombre: 'Robótica',
          nombreGrupo: 'Inicial',
          turno: 'tarde',
          cupoMaximo: 2,
          cupoOcupado: 0,
          activo: true,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          areaId: extra.id,
        ),
      );
      await CuentaService.logoutCuenta();
      final family = (await tester.runAsync(
        () => CuentaService.registrarCuenta(
          email: 'familia-circuito@example.invalid',
          password: password,
          recordarme: true,
        ),
      ))!;
      final pupil = await CuentaService.crearPerfilAlumno(
        cuentaId: family.id,
        documento: '12345678',
        nombre: 'Ana',
        apellido: 'Ficticia',
        fechaNacimiento: DateTime(2015),
      );
      await tester.pumpWidget(shell(CuentaHomePage(cuentaId: family.id)));
      await tester.pumpAndSettle();
      final profileTile = find.ancestor(
        of: find.text('Ficticia, Ana'),
        matching: find.byType(ListTile),
      );
      await tester.ensureVisible(profileTile.last);
      await tester.tap(profileTile.last);
      await tester.pumpAndSettle();
      expect(find.byType(AlumnoAreaPage), findsOneWidget);
      await CuentaService.activarContextoCuenta(
        family.id,
        perfilAlumnoId: pupil.id,
      );
      await tester.pumpWidget(
        shell(
          AlumnoBuscarInstitucionesPage(
            alumnoDni: pupil.documento,
            ownerAccountId: family.id,
            perfilId: pupil.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Educación formal').first);
      await tester.pumpAndSettle();
      final search = find.ancestor(
        of: find.text('Buscar instituciones'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      await tester.ensureVisible(search);
      await tester.tap(search);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver perfil').last);
      await tester.tap(find.text('Ver perfil').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Solicitar vacante').last);
      await tester.tap(find.text('Solicitar vacante').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Educación formal').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Solicitar esta vacante').last);
      await tester.tap(find.text('Solicitar esta vacante').last);
      await tester.pumpAndSettle();
      Future<void> send() async {
        expect(find.byType(AlumnoSolicitarVacantePage), findsOneWidget);
        await tester.tap(find.text('Enviar solicitud'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enviar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await send();
      await tester.pumpWidget(
        shell(
          AlumnoSeleccionGrupoExtracurricularPage(
            institucionId: institution,
            institucionNombre: 'Escuela Circuito',
            alumnoDocumento: pupil.documento,
            ownerAccountId: family.id,
            perfilId: pupil.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Robótica').last);
      await tester.pumpAndSettle();
      await send();
      final pending = await SolicitudesService.cargarSolicitudesPorPerfil(
        ownerAccountId: family.id,
        perfilId: pupil.id,
      );
      expect(pending, hasLength(2));
      expect(pending.map((s) => s.areaId).toSet(), {primary.id, extra.id});
      await CuentaService.logoutCuenta();
      await tester.runAsync(
        () => CuentaService.loginCuenta(
          email: email,
          password: password,
          recordarme: true,
        ),
      );
      await CuentaService.activarContextoInstitucion(owner, institution);
      for (final s in pending) {
        await activate(s.areaId!);
        await tester.pumpWidget(
          shell(
            InstitucionMisSolicitudesPage(
              institucionId: institution,
              institucionNombre: 'Escuela Circuito',
              ownerAccountId: owner,
              institucionPerfilId: institution,
              areaId: s.areaId,
              initialSolicitudId: s.id,
              moduleKey: s.esCurricular ? null : 'otros',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Confirmar').first);
        await tester.tap(find.text('Confirmar').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();
        expect(
          (await SolicitudesService.cargarSolicitudesPorPerfil(
            ownerAccountId: family.id,
            perfilId: pupil.id,
          )).singleWhere((x) => x.id == s.id).estado,
          EstadoSolicitud.confirmada,
        );
      }
      expect(
        (await ih.cargarGruposInstitucion(institution)).single.cupoOcupado,
        1,
      );
      expect(
        (await ExtracurricularesService.instance.cargarGrupos(
          institution,
        )).single.cupoOcupado,
        1,
      );
      expect(
        await InstitucionContextoOperativoService.instance
            .reconstruirContextoOperativo(),
        isNotNull,
      );
      await CuentaService.logoutCuenta();
      expect(await SessionService.getInstitutionOperationalContext(), isNull);
      await tester.runAsync(
        () => CuentaService.loginCuenta(
          email: family.email,
          password: password,
          recordarme: true,
        ),
      );
      await CuentaService.activarContextoCuenta(
        family.id,
        perfilAlumnoId: pupil.id,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      StorageService.instance.resetCache();
      await app.main();
      await tester.pumpAndSettle();
      expect(find.byType(AlumnoAreaPage), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.folder_open_outlined));
      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();
      final documents = tester.widget<AlumnoDocumentosPage>(
        find.byType(AlumnoDocumentosPage),
      );
      expect(documents.ownerAccountId, family.id);
      expect(documents.perfilId, pupil.id);
      expect(
        (await SolicitudesService.cargarSolicitudesPorPerfil(
          ownerAccountId: family.id,
          perfilId: pupil.id,
        )).every((s) => s.estado == EstadoSolicitud.confirmada),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
