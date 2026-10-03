// test/pantallas_institucion_vacantes_croquis_test.dart
//
// Pantallas de la institución: vacantes (lista y formulario) y croquis de aula.

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/instituciones/croquis_editor_page.dart';
import 'package:atena_app/screens/instituciones/croquis_page.dart';
import 'package:atena_app/screens/instituciones/oferta_form_page.dart';
import 'package:atena_app/screens/instituciones/ofertas_page.dart';
import 'package:atena_app/screens/instituciones/widgets/crq_banco.dart';
import 'package:atena_app/screens/instituciones/widgets/ofertas_campos.dart';
import 'package:atena_app/screens/instituciones/widgets/ofertas_tarjeta.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _nombreLargo =
    'Instituto Superior de Formación Integral San Martín de los Andes';

Future<void> _abrir(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('es'),
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      locale: locale,
      themeMode: mode,
      theme: AtenaTheme.light(),
      darkTheme: AtenaTheme.dark(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: page,
    ),
  );
  await _asentar(tester);
}

/// Deja correr el almacenamiento (tiempo real) y termina las animaciones.
Future<void> _asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pumpAndSettle();
}

/// Espera a que se cierren los avisos (snackbars) visibles.
Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<Institucion> _institucion({
  List<NivelCurricular> niveles = const [
    NivelCurricular.primaria,
    NivelCurricular.secundaria,
  ],
  List<BloqueExtracurricular> bloques = const [
    BloqueExtracurricular.deporteYMovimiento,
    BloqueExtracurricular.cienciaTecnologiaYRobotica,
  ],
}) async {
  final inst = institucionDemo(
    nombre: _nombreLargo,
    niveles: niveles,
    bloques: bloques,
  );
  await InstitucionesRepo.instance.guardar(inst);
  return inst;
}

Oferta _oferta({
  String titulo = '1° grado',
  String grupo = 'A',
  TipoOferta tipo = TipoOferta.curricular,
  NivelCurricular? nivel = NivelCurricular.primaria,
  BloqueExtracurricular? bloque,
  int cupo = 3,
  bool activa = true,
}) {
  final now = DateTime(2026, 3, 1);
  return Oferta(
    id: '',
    institucionId: 'INST_1',
    tipo: tipo,
    nivel: tipo == TipoOferta.curricular ? nivel : null,
    bloque: tipo == TipoOferta.curricular ? null : bloque,
    titulo: titulo,
    grupo: grupo,
    turno: Turno.manana,
    horario: '08:00 a 12:00',
    dias: 'Lun a Vie',
    cupoTotal: cupo,
    edadMinima: 6,
    edadMaxima: 7,
    arancel: r'$ 15.000 por mes',
    descripcion: 'Con comedor.',
    activa: activa,
    creadaEl: now,
    actualizadaEl: now,
  );
}

Future<Solicitud> _solicitar(
  Oferta oferta, {
  required String perfil,
  required String nombre,
  required String apellido,
  bool confirmar = false,
}) async {
  final s = await SolicitudesRepo.instance.crear(
    alumno: alumnoDemo(perfilId: perfil, nombre: nombre, apellido: apellido),
    institucionNombre: _nombreLargo,
    oferta: oferta,
  );
  if (!confirmar) return s;
  return SolicitudesRepo.instance.responder(
    s.id,
    institucionId: 'INST_1',
    aceptar: true,
  );
}

const _tamanos = [
  ('teléfono angosto en', Size(360, 640), Locale('en'), ThemeMode.light),
  ('teléfono pt oscuro', Size(390, 844), Locale('pt'), ThemeMode.dark),
  ('tablet es oscuro', Size(820, 1100), Locale('es'), ThemeMode.dark),
  ('escritorio es', Size(1366, 768), Locale('es'), ThemeMode.light),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  group('Utilidades de vacantes', () {
    testWidgets('días y horario ida y vuelta en los tres idiomas', (
      tester,
    ) async {
      for (final idioma in ['es', 'en', 'pt']) {
        final t = await AppLocalizations.delegate.load(Locale(idioma));
        for (var mascara = 0; mascara < 128; mascara++) {
          final dias = {
            for (var d = 0; d < 7; d++)
              if (mascara & (1 << d) != 0) d,
          };
          final texto = ofertasTextoDias(t, dias);
          expect(ofertasLeerDias(t, texto), dias, reason: '$idioma: $texto');
        }
        final rango = t.ofertasHorarioRango('08:05', '12:30');
        final leido = ofertasLeerHorario(rango);
        expect(leido, isNotNull, reason: rango);
        expect(ofertasHora(leido!.$1), '08:05');
        expect(ofertasHora(leido.$2), '12:30');
      }
      final es = await AppLocalizations.delegate.load(const Locale('es'));
      expect(ofertasTextoDias(es, {0, 1, 2, 3, 4}), 'Lun a Vie');
      expect(ofertasTextoDias(es, {0, 2, 4}), 'Lun, Mié y Vie');
      expect(ofertasTextoDias(es, {5, 6}), 'Sáb y Dom');
      expect(ofertasLeerDias(es, 'Lunes y miércoles por la tarde'), isNull);
      expect(ofertasLeerHorario('Lunes 8 a 12'), isNull);
      expect(ofertasLeerHorario('8:00 - 12:00'), isNotNull);
      expect(ofertasLeerHorario('25:00 a 26:00'), isNull);
      expect(crqNombreCorto('Lucía Gómez', amplio: true), 'Lucía G.');
      expect(crqNombreCorto('Gómez, Lucía', amplio: true), 'Lucía G.');
      expect(crqNombreCorto('María José Pérez', amplio: false), 'María');

      // Los días guardados en otro idioma también se reconocen.
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final pt = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(ofertasLeerDias(en, 'Lun a Vie'), {0, 1, 2, 3, 4});
      expect(ofertasLeerDias(pt, 'Mon, Wed and Fri'), {0, 2, 4});
      expect(ofertasLeerDias(es, 'Seg e Qua'), {0, 2});
    });
  });

  group('Vacantes', () {
    testWidgets('institución solo extracurricular con una categoría', (
      tester,
    ) async {
      await tester.runAsync(
        () => _institucion(
          niveles: [],
          bloques: [BloqueExtracurricular.deporteYMovimiento],
        ),
      );
      await _abrir(
        tester,
        const OfertasPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
        ),
      );
      expect(find.byType(TabBar), findsNothing);
      expect(
        find.text('Todavía no publicaste actividades extracurriculares'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Nueva vacante'));
      await _asentar(tester);
      expect(find.text('Tipo de vacante'), findsNothing);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Ej.: Fútbol, Vóley, Natación'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Actividad'),
        'Natación',
      );
      await tester.ensureVisible(find.text('Crear vacante'));
      await tester.tap(find.text('Crear vacante'));
      await _asentar(tester);
      expect(find.byType(OfertaFormPage), findsNothing);
      expect(find.text('Natación'), findsOneWidget);
      expect(find.text('Deporte y movimiento'), findsOneWidget);
      final o = (await tester.runAsync(
        () => OfertasRepo.instance.listar('INST_1'),
      ))!.single;
      expect(o.tipo, TipoOferta.extracurricular);
      expect(o.bloque, BloqueExtracurricular.deporteYMovimiento);
      expect(o.nivel, isNull);
      expect(o.cupoTotal, 15);
      expect(o.dias, '');
      expect(o.horario, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('editar en otro idioma conserva horario y días', (
      tester,
    ) async {
      late Oferta original;
      final inst = (await tester.runAsync(() async {
        final inst = await _institucion();
        original = await OfertasRepo.instance.guardar(_oferta());
        return inst;
      }))!;
      await _abrir(
        tester,
        OfertaFormPage(institucion: inst, oferta: original),
        locale: const Locale('en'),
      );
      // Los días guardados en español quedan marcados.
      expect(find.textContaining('Current days'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Total capacity'),
        '9',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await _asentar(tester);
      var guardada = (await tester.runAsync<Oferta?>(
        () => OfertasRepo.instance.obtener('INST_1', original.id),
      ))!;
      expect(guardada.cupoTotal, 9);
      expect(guardada.dias, 'Lun a Vie');
      expect(guardada.horario, '08:00 a 12:00');

      // Si se cambian los días, se guardan en el idioma actual.
      await _abrir(
        tester,
        OfertaFormPage(institucion: inst, oferta: guardada),
        locale: const Locale('en'),
      );
      await tester.ensureVisible(find.text('Fri'));
      await tester.tap(find.text('Fri'));
      await _asentar(tester);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await _asentar(tester);
      guardada = (await tester.runAsync<Oferta?>(
        () => OfertasRepo.instance.obtener('INST_1', original.id),
      ))!;
      expect(guardada.dias, 'Mon to Thu');
      expect(guardada.horario, '08:00 a 12:00');
      expect(tester.takeException(), isNull);
    });

    testWidgets('plan sin niveles ni actividades', (tester) async {
      await tester.runAsync(() => _institucion(niveles: [], bloques: []));
      await _abrir(
        tester,
        const OfertasPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
        ),
      );
      expect(
        find.text('Tu plan todavía no incluye niveles ni actividades'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('institución inexistente muestra error con reintento', (
      tester,
    ) async {
      await _abrir(
        tester,
        const OfertasPage(institucionId: 'NO_EXISTE', institucionNombre: 'X'),
      );
      expect(find.text('No pudimos cargar las vacantes.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('alta desde vacío con sugerencia y validaciones', (
      tester,
    ) async {
      await tester.runAsync(_institucion);
      await _abrir(
        tester,
        const OfertasPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
        ),
      );
      expect(find.byType(TabBar), findsOneWidget);
      expect(
        find.text('Todavía no publicaste vacantes curriculares'),
        findsOneWidget,
      );

      // Sin vacantes hay un solo botón para crear: el del estado vacío.
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Nueva vacante'));
      await _asentar(tester);
      expect(find.byType(OfertaFormPage), findsOneWidget);
      expect(find.text('Tipo de vacante'), findsOneWidget);

      // Sin nivel ni título: no guarda y marca los errores.
      await tester.ensureVisible(find.text('Crear vacante'));
      await tester.tap(find.text('Crear vacante'));
      await _asentar(tester);
      expect(find.text('Elegí un nivel.'), findsOneWidget);
      expect(find.text('Campo obligatorio.'), findsWidgets);
      expect(find.text('Revisá los campos marcados.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.ensureVisible(find.text('Primaria'));
      await tester.tap(find.text('Primaria'));
      await _asentar(tester);
      expect(find.text('Elegí un nivel.'), findsNothing);
      await tester.ensureVisible(find.text('3° grado'));
      await tester.tap(find.text('3° grado'));
      await _asentar(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'División o grupo (opcional)'),
        'B',
      );
      // Cupo con los botones.
      await tester.ensureVisible(find.byTooltip('Sumar uno'));
      await tester.tap(find.byTooltip('Sumar uno'));
      await tester.pump();
      // Edades inválidas.
      await tester.enterText(
        find.widgetWithText(TextField, 'Edad mínima'),
        '9',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Edad máxima'),
        '8',
      );
      await tester.ensureVisible(find.text('Crear vacante'));
      await tester.tap(find.text('Crear vacante'));
      await _asentar(tester);
      expect(
        find.text('Tiene que ser igual o mayor que la edad mínima.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Edad máxima'),
        '10',
      );
      await tester.ensureVisible(find.text('Crear vacante'));
      await tester.tap(find.text('Crear vacante'));
      await _asentar(tester);

      expect(find.byType(OfertaFormPage), findsNothing);
      expect(find.text('3° grado · B'), findsOneWidget);
      final ofertas = (await tester.runAsync(
        () => OfertasRepo.instance.listar('INST_1'),
      ))!;
      expect(ofertas, hasLength(1));
      expect(ofertas.single.nivel, NivelCurricular.primaria);
      expect(ofertas.single.cupoTotal, 26);
      expect(ofertas.single.dias, 'Lun a Vie');
      expect(ofertas.single.edadMinima, 9);
      expect(ofertas.single.edadMaxima, 10);
      expect(ofertas.single.activa, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pausar, eliminar con solicitudes, duplicar y editar', (
      tester,
    ) async {
      late Oferta primero;
      await tester.runAsync(() async {
        await _institucion();
        primero = await OfertasRepo.instance.guardar(_oferta());
        await OfertasRepo.instance.guardar(
          _oferta(titulo: '2° grado', grupo: '', cupo: 1),
        );
        await _solicitar(
          primero,
          perfil: 'P_1',
          nombre: 'Lucía',
          apellido: 'Gómez',
          confirmar: true,
        );
        await _solicitar(
          primero,
          perfil: 'P_2',
          nombre: 'Tomás',
          apellido: 'Pérez',
        );
      });
      await _abrir(
        tester,
        const OfertasPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
        ),
      );
      expect(find.byType(OfertasTarjeta), findsNWidgets(2));
      expect(find.text('1° grado · A'), findsOneWidget);
      expect(find.text('1 confirmado'), findsOneWidget);
      expect(find.text('2 de 3 libres'), findsOneWidget);
      expect(find.text('1 pendiente'), findsOneWidget);
      expect(find.text('Primaria'), findsOneWidget);

      // Eliminar con solicitudes activas: sugiere pausar.
      await tester.tap(find.byTooltip('Más opciones').first);
      await _asentar(tester);
      await tester.tap(find.text('Eliminar'));
      await _asentar(tester);
      expect(find.text('¿Eliminar «1° grado · A»?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await _asentar(tester);
      expect(find.textContaining('Podés pausarla'), findsOneWidget);
      expect(find.byType(OfertasTarjeta), findsNWidgets(2));
      await tester.tap(find.widgetWithText(SnackBarAction, 'Pausar'));
      await _asentar(tester);
      expect(find.text('Pausada'), findsOneWidget);
      var guardada = (await tester.runAsync(
        () => OfertasRepo.instance.obtener('INST_1', primero.id),
      ))!;
      expect(guardada.activa, isFalse);

      // Deshacer la pausa.
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await _asentar(tester);
      expect(find.text('Pausada'), findsNothing);

      // Duplicar: abre el formulario precargado y crea otra vacante.
      await tester.tap(find.byTooltip('Más opciones').first);
      await _asentar(tester);
      await tester.tap(find.text('Duplicar'));
      await _asentar(tester);
      expect(find.text('Duplicar vacante'), findsOneWidget);
      expect(find.textContaining('copia de «1° grado · A»'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'División o grupo (opcional)'),
        'C',
      );
      await tester.ensureVisible(find.text('Crear vacante'));
      await tester.tap(find.text('Crear vacante'));
      await _asentar(tester);
      expect(find.byType(OfertaFormPage), findsNothing);
      expect(find.text('1° grado · C'), findsOneWidget);
      final copia = (await tester.runAsync(
        () => OfertasRepo.instance.listar('INST_1'),
      ))!.firstWhere((o) => o.grupo == 'C');
      expect(copia.horario, '08:00 a 12:00');
      expect(copia.dias, 'Lun a Vie');
      expect(copia.arancel, r'$ 15.000 por mes');
      expect(copia.id, isNot(primero.id));
      await _cerrarAvisos(tester);

      // Editar: el cupo no puede bajar de los confirmados.
      await tester.tap(find.text('1° grado · A'));
      await _asentar(tester);
      expect(find.text('Editar vacante'), findsOneWidget);
      expect(find.text('Tipo de vacante'), findsNothing);
      expect(find.textContaining('1 alumno confirmado'), findsWidgets);
      await tester.ensureVisible(find.byTooltip('Restar uno'));
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Restar uno'), warnIfMissed: false);
        await tester.pump();
      }
      await tester.enterText(find.widgetWithText(TextField, 'Cupo total'), '0');
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await _asentar(tester);
      expect(find.text('El cupo tiene que ser de al menos 1.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Cupo total'), '5');

      // Salir con cambios pide confirmación.
      await tester.tap(find.byType(BackButton));
      await _asentar(tester);
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _asentar(tester);
      expect(find.byType(OfertaFormPage), findsOneWidget);

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await _asentar(tester);
      expect(find.byType(OfertaFormPage), findsNothing);
      guardada = (await tester.runAsync<Oferta?>(
        () => OfertasRepo.instance.obtener('INST_1', primero.id),
      ))!;
      expect(guardada.cupoTotal, 5);
      expect(guardada.horario, '08:00 a 12:00');
      expect(guardada.dias, 'Lun a Vie');
      expect(guardada.creadaEl, primero.creadaEl);
      expect(tester.takeException(), isNull);
    });

    for (final (nombre, size, locale, mode) in _tamanos) {
      testWidgets('lista y formulario se acomodan: $nombre', (tester) async {
        late Oferta primero;
        await tester.runAsync(() async {
          await _institucion();
          primero = await OfertasRepo.instance.guardar(
            _oferta(
              titulo: 'Primer grado de jornada extendida con orientación',
              grupo: 'División A del turno mañana',
            ),
          );
          await OfertasRepo.instance.guardar(
            _oferta(titulo: '2° grado', activa: false, cupo: 1),
          );
          await OfertasRepo.instance.guardar(
            _oferta(
              titulo: '1° año',
              nivel: NivelCurricular.secundaria,
              cupo: 1,
            ),
          );
          final futbol = await OfertasRepo.instance.guardar(
            _oferta(
              titulo: 'Fútbol infantil',
              grupo: 'Sábados',
              tipo: TipoOferta.extracurricular,
              bloque: BloqueExtracurricular.deporteYMovimiento,
              cupo: 1,
            ),
          );
          await _solicitar(
            futbol,
            perfil: 'P_1',
            nombre: 'Lucía',
            apellido: 'Gómez',
            confirmar: true,
          );
          for (var i = 0; i < 3; i++) {
            await _solicitar(
              primero,
              perfil: 'P_$i',
              nombre: 'Alumno$i',
              apellido: 'Apellido$i',
              confirmar: i == 0,
            );
          }
        });
        await _abrir(
          tester,
          const OfertasPage(
            institucionId: 'INST_1',
            institucionNombre: _nombreLargo,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(OfertasTarjeta), findsWidgets);
        expect(tester.takeException(), isNull);

        // Pestaña extracurricular.
        await tester.tap(find.byType(Tab).last);
        await _asentar(tester);
        expect(find.textContaining('Fútbol infantil'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Menú de acciones.
        await tester.tap(find.byType(PopupMenuButton<OfertasAccion>).first);
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(2, 2));
        await _asentar(tester);

        // Formulario de edición completo.
        final inst = (await tester.runAsync(
          () => InstitucionesRepo.instance.obtener('INST_1'),
        ))!;
        await _abrir(
          tester,
          OfertaFormPage(institucion: inst, oferta: primero, confirmados: 1),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -900),
        );
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1500),
        );
        await _asentar(tester);
        expect(tester.takeException(), isNull);

        // Formulario nuevo extracurricular.
        await _abrir(
          tester,
          OfertaFormPage(
            institucion: inst,
            tipoInicial: TipoOferta.extracurricular,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Croquis', () {
    testWidgets('alta, asignación, intercambio y acciones', (tester) async {
      late Oferta oferta;
      await tester.runAsync(() async {
        await _institucion();
        oferta = await OfertasRepo.instance.guardar(_oferta(cupo: 10));
        await _solicitar(
          oferta,
          perfil: 'P_1',
          nombre: 'Lucía',
          apellido: 'Gómez',
          confirmar: true,
        );
        await _solicitar(
          oferta,
          perfil: 'P_2',
          nombre: 'Tomás',
          apellido: 'Pérez',
          confirmar: true,
        );
      });
      await _abrir(
        tester,
        const CroquisPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
        ),
      );
      expect(find.text('Todavía no armaste ningún croquis'), findsOneWidget);

      // Alta: nombre obligatorio, vacante asociada y tamaño.
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Nuevo croquis'));
      await _asentar(tester);
      await tester.ensureVisible(find.text('Crear croquis'));
      await tester.tap(find.text('Crear croquis'));
      await _asentar(tester);
      expect(find.text('Campo obligatorio.'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await _asentar(tester);
      await tester.tap(find.textContaining('1° grado · A').last);
      await _asentar(tester);
      // El nombre se propone solo.
      expect(
        find.widgetWithText(TextFormField, '1° grado · A'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byTooltip('Quitar uno').first);
      await tester.tap(find.byTooltip('Quitar uno').first);
      await tester.pump();
      await tester.ensureVisible(find.text('Crear croquis'));
      await tester.tap(find.text('Crear croquis'));
      await _asentar(tester);

      expect(find.byType(CroquisEditorPage), findsOneWidget);
      expect(find.byType(CrqBanco), findsNWidgets(24));
      expect(find.text('0 de 24 lugares ocupados'), findsOneWidget);
      expect(find.text('Frente del aula · Pizarrón'), findsOneWidget);

      // Asignar un alumno confirmado.
      await tester.tap(find.byType(CrqBanco).first);
      await _asentar(tester);
      expect(find.text('Banco 1'), findsOneWidget);
      expect(find.text('Gómez, Lucía'), findsOneWidget);
      expect(find.text('Pérez, Tomás'), findsOneWidget);
      await tester.tap(find.text('Gómez, Lucía'));
      await _asentar(tester);
      expect(find.text('1 de 24 lugares ocupados'), findsOneWidget);
      expect(find.text('Guardado'), findsOneWidget);
      var c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos.first, 'Lucía Gómez');
      expect(c.ofertaId, oferta.id);

      // El alumno ya sentado no se vuelve a ofrecer; nombre libre.
      await tester.tap(find.byType(CrqBanco).at(1));
      await _asentar(tester);
      expect(find.text('Gómez, Lucía'), findsNothing);
      expect(find.text('Pérez, Tomás'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre y apellido'),
        'Invitado Especial',
      );
      await tester.pump();
      await tester.tap(find.text('Ubicar'));
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[1], 'Invitado Especial');

      // Escribir el nombre de un confirmado ya sentado lo muda de banco y
      // guarda su nombre exacto.
      await tester.tap(find.byType(CrqBanco).at(5));
      await _asentar(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre y apellido'),
        'lucia gomez',
      );
      await tester.pump();
      await tester.tap(find.text('Ubicar'));
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[0], '');
      expect(c.asientos[5], 'Lucía Gómez');
      expect(find.textContaining('pasó del banco 1 al 6'), findsOneWidget);

      // Arrastrar para intercambiar.
      final origen = tester.getCenter(find.byType(CrqBanco).at(5));
      final destino = tester.getCenter(find.byType(CrqBanco).at(1));
      final gesto = await tester.startGesture(origen);
      await tester.pump(const Duration(milliseconds: 700));
      await gesto.moveTo(Offset.lerp(origen, destino, 0.5)!);
      await tester.pump();
      await gesto.moveTo(destino);
      await tester.pump();
      await gesto.up();
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[1], 'Lucía Gómez');
      expect(c.asientos[5], 'Invitado Especial');

      // Con el mouse el arrastre es inmediato (a un banco libre: se muda).
      final raton = await tester.startGesture(
        tester.getCenter(find.byType(CrqBanco).at(1)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await raton.moveBy(const Offset(6, 6));
      await tester.pump();
      await raton.moveTo(tester.getCenter(find.byType(CrqBanco).at(7)));
      await tester.pump();
      await raton.up();
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[1], '');
      expect(c.asientos[7], 'Lucía Gómez');

      // Un clic con el mouse apenas movido sigue abriendo la hoja.
      final clic = await tester.startGesture(
        tester.getCenter(find.byType(CrqBanco).at(7)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await clic.moveBy(const Offset(3, 0));
      await tester.pump();
      await clic.up();
      await _asentar(tester);
      expect(find.text('Ocupado por Lucía Gómez'), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await _asentar(tester);
      // Vuelve al banco 2 con un arrastre táctil.
      final vuelta = await tester.startGesture(
        tester.getCenter(find.byType(CrqBanco).at(7)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await vuelta.moveBy(const Offset(10, 10));
      await tester.pump();
      await vuelta.moveTo(tester.getCenter(find.byType(CrqBanco).at(1)));
      await tester.pump();
      await vuelta.up();
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[1], 'Lucía Gómez');
      expect(c.asientos[7], '');

      // Dejar libre.
      await tester.tap(find.byType(CrqBanco).at(5));
      await _asentar(tester);
      expect(find.text('Ocupado por Invitado Especial'), findsOneWidget);
      await tester.tap(find.text('Dejar libre'));
      await _asentar(tester);
      expect(find.text('1 de 24 lugares ocupados'), findsOneWidget);

      // Renombrar.
      await tester.tap(find.text('Renombrar'));
      await _asentar(tester);
      await tester.enterText(find.byType(TextField).last, 'Aula 3');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await _asentar(tester);
      expect(find.text('Aula 3'), findsOneWidget);

      // Achicar: avisa que se pierde un alumno y pide confirmación.
      await tester.tap(find.text('Tamaño'));
      await _asentar(tester);
      expect(find.text('Tamaño del aula'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byTooltip('Quitar uno').last);
        await tester.pump();
      }
      expect(find.textContaining('1 alumno quedaría fuera'), findsOneWidget);
      await tester.ensureVisible(find.text('Aplicar'));
      await tester.tap(find.text('Aplicar'));
      await _asentar(tester);
      expect(find.text('¿Achicar el aula?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _asentar(tester);
      expect(find.byType(CrqBanco), findsNWidgets(24));

      // Agrandar no pide confirmación.
      await tester.tap(find.text('Tamaño'));
      await _asentar(tester);
      await tester.tap(find.byTooltip('Agregar uno').first);
      await tester.pump();
      await tester.ensureVisible(find.text('Aplicar'));
      await tester.tap(find.text('Aplicar'));
      await _asentar(tester);
      expect(find.byType(CrqBanco), findsNWidgets(30));
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.filas, 5);
      expect(c.asientos[1], 'Lucía Gómez');

      // PDF: genera el documento; compartir falla en pruebas (no hay
      // plataforma) y se avisa sin romper.
      await _cerrarAvisos(tester);
      await tester.tap(find.text('PDF'));
      for (var i = 0; i < 40; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await _cerrarAvisos(tester);

      // Vaciar y deshacer.
      await tester.tap(find.text('Vaciar'));
      await _asentar(tester);
      expect(find.text('¿Vaciar el croquis?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Vaciar'));
      await _asentar(tester);
      expect(find.text('0 de 30 lugares ocupados'), findsOneWidget);
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await _asentar(tester);
      expect(find.text('1 de 30 lugares ocupados'), findsOneWidget);

      // Quitar la vacante asociada.
      await tester.tap(find.byType(ActionChip));
      await _asentar(tester);
      await tester.tap(find.text('Sin vacante asociada'));
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.ofertaId, '');
      expect(c.nombre, 'Aula 3');
      expect(find.text('Asociar una vacante'), findsOneWidget);

      // Volver a la lista y eliminar.
      await tester.tap(find.byType(BackButton));
      await _asentar(tester);
      expect(find.byType(CroquisEditorPage), findsNothing);
      expect(find.text('Aula 3'), findsOneWidget);
      expect(find.text('1 de 30 lugares ocupados'), findsOneWidget);
      await tester.tap(find.text('Aula 3'));
      await _asentar(tester);
      await tester.tap(find.text('Eliminar'));
      await _asentar(tester);
      expect(find.text('¿Eliminar «Aula 3»?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await _asentar(tester);
      expect(find.byType(CroquisEditorPage), findsNothing);
      expect(find.text('Todavía no armaste ningún croquis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (nombre, size, locale, mode) in _tamanos) {
      testWidgets('lista, editor y hojas se acomodan: $nombre', (tester) async {
        late Croquis grande;
        await tester.runAsync(() async {
          await _institucion();
          final oferta = await OfertasRepo.instance.guardar(_oferta(cupo: 30));
          for (var i = 0; i < 9; i++) {
            await _solicitar(
              oferta,
              perfil: 'P_$i',
              nombre: 'Maximiliano$i',
              apellido: 'Fernández Etchegaray$i',
              confirmar: true,
            );
          }
          grande = await CroquisRepo.instance.crear(
            institucionId: 'INST_1',
            nombre: 'Aula magna del edificio anexo de la sede central',
            ofertaId: oferta.id,
            filas: 10,
            columnas: 10,
          );
          grande = grande
              .conAsiento(0, 0, 'Maximiliano0 Fernández Etchegaray0')
              .conAsiento(9, 9, 'Ana');
          await CroquisRepo.instance.guardar(grande);
          await CroquisRepo.instance.crear(
            institucionId: 'INST_1',
            nombre: 'Laboratorio',
          );
        });

        await _abrir(
          tester,
          const CroquisPage(
            institucionId: 'INST_1',
            institucionNombre: _nombreLargo,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(tester.takeException(), isNull);

        // Hoja de alta.
        await tester.tap(find.byType(FloatingActionButton));
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await _asentar(tester);

        // Editor con la grilla más grande.
        await _abrir(
          tester,
          CroquisEditorPage(
            institucionId: 'INST_1',
            institucionNombre: _nombreLargo,
            croquis: grande,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(CrqBanco), findsWidgets);
        expect(tester.takeException(), isNull);
        for (final banco in tester.widgetList<CrqBanco>(
          find.byType(CrqBanco),
        )) {
          expect(banco.tamano, greaterThanOrEqualTo(44));
        }

        // Hoja de asignación con búsqueda.
        await tester.tap(find.byType(CrqBanco).at(1));
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await _asentar(tester);

        // Hoja de tamaño.
        final barra = find.byIcon(Icons.aspect_ratio_rounded);
        await tester.tap(barra);
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.remove_rounded).first);
        await _asentar(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await _asentar(tester);

        // Editor chico (5 × 6).
        final chico = (await tester.runAsync(
          () => CroquisRepo.instance.listar('INST_1'),
        ))!.firstWhere((c) => c.nombre == 'Laboratorio');
        await _abrir(
          tester,
          CroquisEditorPage(
            institucionId: 'INST_1',
            institucionNombre: _nombreLargo,
            croquis: chico,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(CrqBanco), findsNWidgets(30));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('hoja de asignación con teclado en teléfono chico', (
      tester,
    ) async {
      late Croquis croquis;
      await tester.runAsync(() async {
        await _institucion();
        final oferta = await OfertasRepo.instance.guardar(_oferta(cupo: 30));
        for (var i = 0; i < 9; i++) {
          await _solicitar(
            oferta,
            perfil: 'P_$i',
            nombre: 'Alumno$i',
            apellido: 'Apellido$i',
            confirmar: true,
          );
        }
        croquis = await CroquisRepo.instance.crear(
          institucionId: 'INST_1',
          nombre: 'Aula',
          ofertaId: oferta.id,
        );
        croquis = croquis.conAsiento(0, 0, 'Ana Suelta');
        await CroquisRepo.instance.guardar(croquis);
      });
      await _abrir(
        tester,
        CroquisEditorPage(
          institucionId: 'INST_1',
          institucionNombre: _nombreLargo,
          croquis: croquis,
        ),
        size: const Size(360, 640),
      );
      addTearDown(tester.view.resetViewInsets);

      // Banco ocupado: nombre libre con el teclado abierto.
      await tester.tap(find.byType(CrqBanco).first);
      await _asentar(tester);
      expect(find.text('Dejar libre'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
      await tester.tap(find.widgetWithText(TextField, 'Nombre y apellido'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Dejar libre'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Nombre y apellido'),
            )
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre y apellido'),
        'Bruno Díaz',
      );
      await tester.pump();
      await tester.tap(find.text('Ubicar'));
      tester.view.resetViewInsets();
      await _asentar(tester);
      var c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[0], 'Bruno Díaz');

      // Búsqueda con el teclado abierto: quedan solo los resultados.
      await tester.tap(find.byType(CrqBanco).at(1));
      await _asentar(tester);
      await tester.tap(find.widgetWithText(TextField, 'Buscar alumno'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('O escribí un nombre'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar alumno'),
        'APELLIDO7',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      tester.view.resetViewInsets();
      await _asentar(tester);
      c = (await tester.runAsync(
        () => CroquisRepo.instance.listar('INST_1'),
      ))!.single;
      expect(c.asientos[1], 'Alumno7 Apellido7');
      expect(tester.takeException(), isNull);
    });
  });
}
