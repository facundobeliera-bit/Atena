import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/instituciones/institucion_gestion_vacantes_page.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/instituciones_helpers.dart' as ih;
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(Widget home) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  test('horas válidas se normalizan al formato de 24 horas', () {
    expect(
      formatCurricularClockTime(parseCurricularClockTime('8:05')!),
      '08:05',
    );
    expect(
      formatCurricularClockTime(parseCurricularClockTime('23:59')!),
      '23:59',
    );
    expect(
      formatCurricularClockTime(parseCurricularClockTime('00:00')!),
      '00:00',
    );
  });

  test('horas imposibles o incompletas se rechazan', () {
    for (final invalid in ['25:00', '12:60', '8:5', '1234', '-1:00']) {
      expect(parseCurricularClockTime(invalid), isNull, reason: invalid);
    }
  });

  testWidgets('plan local guardado se recupera sin presentarlo como pago', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 21);
    await InstitucionService.upsertInstitucion(
      Institucion(
        id: 'perfil-plan-prueba',
        nombre: 'Institución Ficticia',
        cuit: '30123456789',
        direccion: 'Calle Ejemplo',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: 'plan@atena.test',
        telefono: '1122334455',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.otra,
        tipoPlan: 'FASE2-CUR-STD-EXT-BAS-N1-M0',
        estadoPlan: EstadoPlanInstitucion.enPrueba,
        planInicio: now,
        planFin: now.add(const Duration(days: 30)),
        planConfig: PlanInstitucionConfig(
          niveles: [
            PlanNivelCurricular(
              nivel: NivelCurricular.primaria,
              habilitado: true,
            ),
          ],
          modulos: const [],
        ),
      ),
    );

    await tester.pumpWidget(
      app(
        const InstitucionPlanPage.manage(
          ownerAccountId: 'owner-plan-prueba',
          institucionPerfilId: 'perfil-plan-prueba',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Plan institucional guardado'), findsOneWidget);
    expect(
      find.textContaining('Curricular: 1 nivel (Standard)'),
      findsOneWidget,
    );
    expect(find.text('Estado local: En prueba'), findsOneWidget);
    expect(find.textContaining('no acredita una suscripción'), findsOneWidget);
  });

  testWidgets('sin dato local se muestra ausencia de plan', (tester) async {
    await tester.pumpWidget(
      app(
        const InstitucionPlanPage.manage(
          ownerAccountId: 'owner-sin-plan',
          institucionPerfilId: 'perfil-sin-plan',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('No hay un plan local guardado'),
      findsOneWidget,
    );
  });

  testWidgets('editar selección no reinicia vigencia ni estado del plan', (
    tester,
  ) async {
    const email = 'plan-vigencia@atena.test';
    const password = 'ClaveFicticia2026!';
    final auth = (await tester.runAsync(
      () => InstitucionService.registrarInstitucion(
        email: email,
        passwordHash: password,
        nombre: 'Institución Ficticia',
      ),
    ))!;
    final id = auth.institucionId;
    await CuentaService.crearPerfilInstitucion(
      cuentaId: id,
      nombre: 'Institución Ficticia',
      emailContacto: email,
      telefonoContacto: '1122334455',
    );
    final start = DateTime(2026, 8, 1);
    final end = DateTime(2026, 9, 1);
    await InstitucionService.upsertInstitucion(
      Institucion(
        id: id,
        nombre: 'Institución Ficticia',
        cuit: '30123456789',
        direccion: 'Calle Ejemplo',
        pais: 'Argentina',
        provincia: 'Buenos Aires',
        ciudad: 'La Plata',
        modalidad: ModalidadCursado.presencial,
        email: email,
        telefono: '1122334455',
        curricular: true,
        extracurricular: false,
        tipoInstitucion: TipoInstitucion.otra,
        tipoPlan: 'FASE2-CUR-STD-EXT-BAS-N1-M0',
        estadoPlan: EstadoPlanInstitucion.vencido,
        planInicio: start,
        planFin: end,
        planConfig: PlanInstitucionConfig(
          niveles: [
            PlanNivelCurricular(
              nivel: NivelCurricular.primaria,
              habilitado: true,
            ),
          ],
          modulos: const [],
        ),
      ),
    );
    await CuentaService.iniciarSesionAutenticada(id, recordarme: false);
    await CuentaService.activarContextoInstitucion(id, id);
    await tester.pumpWidget(
      app(
        InstitucionPlanPage.manage(ownerAccountId: id, institucionPerfilId: id),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final save = find
        .byWidgetPredicate((widget) => widget is ElevatedButton)
        .last;
    await tester.runAsync(() async {
      tester.widget<ElevatedButton>(save).onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    final stored = await InstitucionService.getInstitucionById(id);
    expect(stored?.estadoPlan, EstadoPlanInstitucion.vencido);
    expect(stored?.planInicio, start);
    expect(stored?.planFin, end);
  });

  testWidgets('formulario curricular ofrece selector horario sin teclado', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const InstitucionGestionVacantesPage(
          institucionId: 'inst-horario-prueba',
          institucionNombre: 'Institución Ficticia',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final startField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Horario inicio',
    );
    final endField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Horario fin',
    );
    expect(tester.widget<TextField>(startField).readOnly, isTrue);
    expect(tester.widget<TextField>(endField).readOnly, isTrue);
    await tester.tap(startField);
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('horas elegidas conservan el formato al persistir un grupo', (
    tester,
  ) async {
    const id = 'inst-horario-persistido';
    await tester.pumpWidget(
      app(
        const InstitucionGestionVacantesPage(
          institucionId: id,
          institucionNombre: 'Institución Ficticia',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    for (final item in <(String, String)>[
      ('Nombre del grupo', '3° A'),
      ('Actividad', 'Primaria'),
      ('Capacidad máxima', '20'),
    ]) {
      await tester.ensureVisible(field(item.$1));
      await tester.enterText(field(item.$1), item.$2);
    }

    for (final label in ['Horario inicio', 'Horario fin']) {
      await tester.ensureVisible(field(label));
      await tester.tap(field(label));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('ACEPTAR').last);
      await tester.pumpAndSettle();
    }

    final start = tester
        .widget<TextField>(field('Horario inicio'))
        .controller!
        .text;
    final end = tester.widget<TextField>(field('Horario fin')).controller!.text;
    expect(start, '08:00');
    expect(end, '12:00');
    await ih.guardarGruposInstitucion(id, [
      GrupoInstitucional(
        id: 'grupo-horario-prueba',
        institucionId: id,
        actividadNombre: 'Primaria',
        nombreGrupo: '3° A',
        turno: 'Mañana • $start-$end',
        cupoMaximo: 20,
        cupoOcupado: 0,
        estado: EstadoCupo.disponible,
      ),
    ]);
    final groups = await ih.cargarGruposInstitucion(id);
    expect(groups, hasLength(1));
    expect(groups.single.turno, contains('08:00-12:00'));
    StorageService.instance.resetCache();
    expect(
      (await ih.cargarGruposInstitucion(id)).single.turno,
      contains('08:00-12:00'),
    );
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
