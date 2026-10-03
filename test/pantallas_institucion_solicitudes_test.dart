// test/pantallas_institucion_solicitudes_test.dart
//
// Pantallas de la institución: Solicitudes recibidas y Alumnos confirmados.
// Recorre los flujos de punta a punta (responder, pedir documentos, dar de
// baja, exportar) en teléfono y escritorio, en los tres idiomas y en claro y
// oscuro, y comprueba que nada se rompe cuando una solicitud desaparece
// (la familia eliminó su cuenta).

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/screens/instituciones/alumnos_institucion_page.dart';
import 'package:atena_app/screens/instituciones/solicitudes_institucion_page.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _inst = 'INST_1';
const _instNombre =
    'Instituto Superior de Formación Integral San Martín de los Andes';

const _telefono = Size(360, 740);
const _escritorio = Size(1366, 768);

/// Carga las tipografías de la app para medir los textos como en un
/// dispositivo real (con la fuente de prueba todo ocupa más y aparecen
/// desbordes que no existen).
Future<void> _cargarFuentes() async {
  for (final (familia, pesos) in const [
    ('PlusJakartaSans', ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']),
    ('Cinzel', ['SemiBold', 'Bold']),
  ]) {
    final loader = FontLoader(familia);
    for (final peso in pesos) {
      loader.addFont(rootBundle.load('assets/fonts/$familia-$peso.ttf'));
    }
    await loader.load();
  }
}

/// Alumno de ejemplo. La edad se fija respecto del año en curso para que las
/// pruebas no dependan de la fecha en que se ejecutan.
AlumnoSnapshot _alumno(
  int n,
  String nombre,
  String apellido, {
  int edad = 7,
  String email = '',
  String telefono = '',
}) => AlumnoSnapshot(
  cuentaId: 'C_$n',
  perfilId: 'P_$n',
  nombre: nombre,
  apellido: apellido,
  dni: '4512345$n',
  fechaNacimiento: DateTime(DateTime.now().year - edad),
  email: email,
  telefono: telefono,
);

class _Datos {
  late Oferta grado;
  late Oferta futbol;

  /// Pendiente en 1° grado, con mensaje y datos de contacto.
  late Solicitud lucia;

  /// Pendiente en 1° grado.
  late Solicitud mateo;

  /// Confirmada en 1° grado (con nota para la familia).
  late Solicitud sofia;

  /// No aceptada en 1° grado.
  late Solicitud bruno;

  /// Confirmada en fútbol: completa el cupo.
  late Solicitud emma;

  /// Pendiente en fútbol: sin cupo y con la edad fuera de rango.
  late Solicitud tomas;
}

Future<_Datos> _sembrar() async {
  final d = _Datos();
  final ofertas = OfertasRepo.instance;
  final sol = SolicitudesRepo.instance;
  final ahora = DateTime.now();

  d.grado = await ofertas.guardar(ofertaDemo(cupo: 3));
  d.futbol = await ofertas.guardar(
    Oferta(
      id: '',
      institucionId: _inst,
      tipo: TipoOferta.extracurricular,
      bloque: BloqueExtracurricular.deporteYMovimiento,
      titulo: 'Fútbol infantil mixto de los sábados por la mañana',
      grupo: 'Categoría inicial',
      turno: Turno.manana,
      dias: 'Sábados',
      horario: '10:00 a 11:30',
      cupoTotal: 1,
      edadMinima: 9,
      edadMaxima: 11,
      creadaEl: ahora,
      actualizadaEl: ahora,
    ),
  );

  d.lucia = await sol.crear(
    alumno: _alumno(
      1,
      'Lucía Valentina',
      'Gómez Fernández de la Vega',
      email: 'familia.gomez.fernandez@correo-electronico-largo.com.ar',
      telefono: '+54 9 351 555-1234',
    ),
    institucionNombre: _instNombre,
    oferta: d.grado,
    mensaje:
        'Hola, Lucía tiene un hermano en 4° grado y nos gustaría que '
        'compartan el turno. ¡Gracias!',
  );
  d.mateo = await sol.crear(
    alumno: _alumno(2, 'Mateo', 'Álvarez'),
    institucionNombre: _instNombre,
    oferta: d.grado,
  );
  d.sofia = await sol.crear(
    alumno: _alumno(3, 'Sofía', 'Ñandú', telefono: '3515550000'),
    institucionNombre: _instNombre,
    oferta: d.grado,
  );
  d.sofia = await sol.responder(
    d.sofia.id,
    institucionId: _inst,
    aceptar: true,
    nota: 'Los esperamos el lunes a las 8 con el DNI.',
  );
  d.bruno = await sol.crear(
    alumno: _alumno(4, 'Bruno', 'Díaz'),
    institucionNombre: _instNombre,
    oferta: d.grado,
  );
  d.bruno = await sol.responder(
    d.bruno.id,
    institucionId: _inst,
    aceptar: false,
    nota: 'La documentación presentada está incompleta.',
  );
  d.emma = await sol.crear(
    alumno: _alumno(5, 'Emma', 'Castro', edad: 10),
    institucionNombre: _instNombre,
    oferta: d.futbol,
  );
  d.tomas = await sol.crear(
    alumno: _alumno(6, 'Tomás', 'Benítez'),
    institucionNombre: _instNombre,
    oferta: d.futbol,
  );
  d.emma = await sol.responder(d.emma.id, institucionId: _inst, aceptar: true);
  return d;
}

/// Simula la baja de una familia: sus solicitudes dejan de existir.
Future<void> _borrarSolicitudes(WidgetTester tester, String cuentaId) async {
  await tester.runAsync(
    () => AtenaStore.instance.update<void>(
      'solicitudes',
      (docs) => docs.removeWhere((d) => d['cuentaId'] == cuentaId),
    ),
  );
}

Future<void> _abrir(
  WidgetTester tester,
  Widget page, {
  Size size = _telefono,
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
  await tester.pumpAndSettle();
}

/// Deja terminar las escrituras reales y la recarga diferida de las pantallas.
Future<void> _asentar(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// Toca un elemento que puede estar fuera de la zona visible.
Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Botón de respuesta rápida dentro de la tarjeta de una solicitud.
Finder _enTarjeta(Solicitud s, Finder boton) =>
    find.descendant(of: find.byKey(ValueKey(s.id)), matching: boton);

SolicitudesInstitucionPage _solicitudes({String? oferta, String? inicial}) =>
    SolicitudesInstitucionPage(
      institucionId: _inst,
      institucionNombre: _instNombre,
      ofertaId: oferta,
      initialSolicitudId: inicial,
    );

const _alumnos = AlumnosInstitucionPage(
  institucionId: _inst,
  institucionNombre: _instNombre,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_cargarFuentes);
  setUp(resetStorage);

  group('Solicitudes de la institución', () {
    testWidgets('sin solicitudes explica cómo llegan', (tester) async {
      await _abrir(tester, _solicitudes());
      expect(find.text('Todavía no recibiste solicitudes'), findsOneWidget);
      expect(find.text('Ir a Vacantes'), findsOneWidget);

      await tester.tap(find.text('Confirmadas'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no confirmaste vacantes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pestañas, búsqueda y respuesta rápida en teléfono', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _solicitudes());

      // Solo las pendientes, con sus acciones rápidas.
      expect(
        find.text('Gómez Fernández de la Vega, Lucía Valentina'),
        findsOneWidget,
      );
      expect(find.text('Álvarez, Mateo'), findsOneWidget);
      expect(find.text('Benítez, Tomás'), findsOneWidget);
      expect(find.text('Ñandú, Sofía'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Confirmar'), findsNWidgets(3));

      // Búsqueda sin tildes y por DNI con puntos.
      await tester.enterText(find.byType(TextField), 'alvarez');
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsOneWidget);
      expect(find.text('Benítez, Tomás'), findsNothing);
      await tester.enterText(find.byType(TextField), '45.123.456');
      await tester.pumpAndSettle();
      expect(find.text('Benítez, Tomás'), findsOneWidget);
      expect(find.text('Álvarez, Mateo'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados'), findsOneWidget);
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsOneWidget);

      // Confirmar desde la tarjeta, con mensaje para la familia.
      await tester.tap(
        _enTarjeta(d.mateo, find.widgetWithText(FilledButton, 'Confirmar')),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Confirmar la vacante?'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Los esperamos el lunes.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar vacante'));
      await tester.pump();
      await _asentar(tester);
      expect(
        find.textContaining('Confirmaste la vacante de Mateo'),
        findsOneWidget,
      );
      expect(find.text('Álvarez, Mateo'), findsNothing);
      final mateo = await tester.runAsync(
        () => SolicitudesRepo.instance.obtener(d.mateo.id),
      );
      expect(mateo?.estado, EstadoSolicitud.confirmada);
      expect(mateo?.respuesta, 'Los esperamos el lunes.');

      // Sin cupo: mensaje claro con acceso a Vacantes.
      await tester.tap(
        _enTarjeta(d.tomas, find.widgetWithText(FilledButton, 'Confirmar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar vacante'));
      await tester.pump();
      await _asentar(tester);
      expect(find.text('No quedan vacantes'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Ir a Vacantes'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // No aceptar exige un motivo; los motivos frecuentes lo completan.
      await tester.tap(_enTarjeta(d.tomas, find.text('No aceptar')));
      await tester.pumpAndSettle();
      expect(find.text('¿No aceptar la solicitud?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'No aceptar'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí el motivo para la familia.'), findsOneWidget);
      await tester.tap(find.text('Sin vacantes'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'No aceptar'));
      await tester.pump();
      await _asentar(tester);
      final tomas = await tester.runAsync(
        () => SolicitudesRepo.instance.obtener(d.tomas.id),
      );
      expect(tomas?.estado, EstadoSolicitud.rechazada);
      expect(
        tomas?.respuesta,
        'No quedan vacantes disponibles en esta oferta.',
      );

      // Las demás pestañas.
      await _tocar(tester, find.text('No aceptadas'));
      expect(find.text('Díaz, Bruno'), findsOneWidget);
      expect(find.text('Benítez, Tomás'), findsOneWidget);
      await _tocar(tester, find.text('Canceladas'));
      expect(find.text('No hay solicitudes canceladas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detalle en hoja: contacto, pedido de documento y rechazo', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _solicitudes(inicial: d.lucia.id));

      // Se abre el detalle de la solicitud pedida.
      expect(find.text('Datos del alumno'), findsOneWidget);
      expect(find.text('Mensaje de la familia'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Solicitud recibida'), findsOneWidget);
      expect(find.text('2 de 3 libres'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Enviar email'), findsOneWidget);
      expect(find.byTooltip('Descargar comprobante'), findsOneWidget);

      // Copiar un dato avisa dentro de la hoja.
      await tester.ensureVisible(find.byTooltip('Copiar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copiar').first);
      await tester.pump();
      await _asentar(tester);
      expect(find.text('Copiado al portapapeles.'), findsOneWidget);

      // Pedir documento: hay que elegir el tipo y "otro" exige el nombre.
      await _tocar(tester, find.text('Pedir documento'));
      expect(find.text('¿Qué documento necesitás?'), findsOneWidget);
      await tester.tap(find.text('Enviar pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Elegí un documento.'), findsOneWidget);
      await _tocar(tester, find.text('Otro documento'));
      await tester.tap(find.text('Enviar pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Indicá qué documento necesitás.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del documento'),
        'Certificado de alumno regular',
      );
      await tester.tap(find.text('Enviar pedido'));
      await tester.pump();
      await _asentar(tester);
      expect(
        find.textContaining('Pedido enviado: Certificado de alumno regular'),
        findsOneWidget,
      );
      final pedidos = (await tester.runAsync(
        () => DocumentosRepo.instance.porInstitucion(_inst),
      ))!;
      expect(pedidos, hasLength(1));
      expect(pedidos.single.perfilId, 'P_1');
      expect(pedidos.single.tipo, TipoDocumento.otro);

      // No aceptar desde el detalle cierra la hoja y avisa en la lista.
      await tester.tap(find.widgetWithText(OutlinedButton, 'No aceptar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Este año no abrimos el turno.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'No aceptar'));
      await tester.pump();
      await _asentar(tester);
      expect(find.text('Datos del alumno'), findsNothing);
      expect(find.textContaining('no fue aceptada'), findsOneWidget);
      final lucia = await tester.runAsync(
        () => SolicitudesRepo.instance.obtener(d.lucia.id),
      );
      expect(lucia?.estado, EstadoSolicitud.rechazada);
      expect(lucia?.respuesta, 'Este año no abrimos el turno.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('escritorio oscuro: panel lateral, filtro por vacante y baja', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(
        tester,
        _solicitudes(oferta: d.futbol.id),
        size: _escritorio,
        mode: ThemeMode.dark,
      );

      // Llega filtrada por la vacante de fútbol.
      expect(find.text('Benítez, Tomás'), findsOneWidget);
      expect(find.text('Álvarez, Mateo'), findsNothing);
      expect(find.byType(InputChip), findsOneWidget);

      // Pendiente con la vacante completa y la edad fuera de rango.
      await tester.tap(find.text('Benítez, Tomás'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No quedan lugares libres'), findsOneWidget);
      expect(find.textContaining('está fuera del rango'), findsOneWidget);
      expect(find.text('Completa'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      // Quitar el filtro y abrir una confirmada.
      await tester.tap(find.byTooltip('Quitar filtro'));
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsOneWidget);
      await tester.tap(find.text('Confirmadas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ñandú, Sofía'));
      await tester.pumpAndSettle();
      expect(find.text('Vacante confirmada'), findsOneWidget);
      expect(
        find.text('Los esperamos el lunes a las 8 con el DNI.'),
        findsOneWidget,
      );

      // Dar de baja pide confirmación.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Dar de baja'));
      await tester.pumpAndSettle();
      expect(find.text('¿Dar de baja a Sofía Ñandú?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pump();
      await _asentar(tester);
      expect(
        find.textContaining('Diste de baja a Sofía Ñandú'),
        findsOneWidget,
      );
      final sofia = await tester.runAsync(
        () => SolicitudesRepo.instance.obtener(d.sofia.id),
      );
      expect(sofia?.estado, EstadoSolicitud.canceladaPorInstitucion);
      expect(tester.takeException(), isNull);
    });

    testWidgets('una solicitud desaparece mientras se la está viendo', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _solicitudes());
      await tester.tap(find.text('Álvarez, Mateo'));
      await tester.pumpAndSettle();
      expect(find.text('Datos del alumno'), findsOneWidget);

      // La familia elimina su cuenta con el detalle abierto.
      await _borrarSolicitudes(tester, d.mateo.alumno.cuentaId);
      await _asentar(tester);
      expect(find.text('Esta solicitud ya no existe'), findsOneWidget);
      expect(find.text('Datos del alumno'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsNothing);
      expect(find.text('Benítez, Tomás'), findsOneWidget);

      // Otra se borra justo antes de responderla: aviso amable, sin romper.
      await tester.tap(_enTarjeta(d.tomas, find.text('No aceptar')));
      await tester.pumpAndSettle();
      await _borrarSolicitudes(tester, d.tomas.alumno.cuentaId);
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Sin lugar.');
      await tester.tap(find.widgetWithText(FilledButton, 'No aceptar'));
      await tester.pump();
      await _asentar(tester);
      expect(find.textContaining('Esa solicitud ya no existe'), findsOneWidget);
      expect(find.text('Benítez, Tomás'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('solicitud inicial inexistente: aviso amable', (tester) async {
      await tester.runAsync(_sembrar);
      await _abrir(tester, _solicitudes(inicial: 'SOL_no_existe'));
      expect(find.textContaining('Esa solicitud ya no existe'), findsOneWidget);
      expect(find.text('Datos del alumno'), findsNothing);
      expect(find.text('Álvarez, Mateo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('inglés y portugués sin desbordes', (tester) async {
      final d = (await tester.runAsync(_sembrar))!;
      for (final (idioma, cerrar, pendientes) in const [
        (Locale('en'), 'Close', 'Pending'),
        (Locale('pt'), 'Fechar', 'Pendentes'),
      ]) {
        await _abrir(tester, _solicitudes(inicial: d.lucia.id), locale: idioma);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(cerrar));
        await tester.pumpAndSettle();
        expect(find.text(pendientes), findsOneWidget);
        for (var i = 1; i < 4; i++) {
          await _tocar(tester, find.byType(Tab).at(i));
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  group('Alumnos de la institución', () {
    testWidgets('sin confirmados ofrece ir a solicitudes y vacantes', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final oferta = await OfertasRepo.instance.guardar(ofertaDemo());
        await SolicitudesRepo.instance.crear(
          alumno: alumnoDemo(),
          institucionNombre: _instNombre,
          oferta: oferta,
        );
      });
      await _abrir(tester, _alumnos);
      expect(find.text('Todavía no hay alumnos confirmados'), findsOneWidget);
      expect(find.text('Revisar 1 solicitud pendiente'), findsOneWidget);
      expect(find.text('Ir a Vacantes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('secciones por vacante, búsqueda, ficha, baja y exportación', (
      tester,
    ) async {
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        await SolicitudesRepo.instance.responder(
          d.mateo.id,
          institucionId: _inst,
          aceptar: true,
        );
        return d;
      }))!;
      await _abrir(tester, _alumnos);

      expect(find.text('3 alumnos confirmados'), findsOneWidget);
      expect(find.text('1° grado · A'), findsOneWidget);
      expect(find.text('Primaria · Mañana'), findsOneWidget);
      expect(find.text('2 alumnos · 1 de 3 libres'), findsOneWidget);
      expect(find.text('1 alumno · Completa'), findsOneWidget);
      expect(find.text('Álvarez, Mateo'), findsOneWidget);
      expect(find.text('Ñandú, Sofía'), findsOneWidget);
      expect(find.text('Castro, Emma'), findsOneWidget);

      // Plegar y desplegar una sección.
      await tester.tap(find.text('1° grado · A'));
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsNothing);
      await tester.tap(find.text('1° grado · A'));
      await tester.pumpAndSettle();
      expect(find.text('Álvarez, Mateo'), findsOneWidget);

      // Búsqueda sin tildes.
      await tester.enterText(find.byType(TextField), 'nandu');
      await tester.pumpAndSettle();
      expect(find.text('Ñandú, Sofía'), findsOneWidget);
      expect(find.text('Álvarez, Mateo'), findsNothing);
      expect(find.text('Castro, Emma'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados'), findsOneWidget);
      await tester.tap(find.text('Limpiar búsqueda').last);
      await tester.pumpAndSettle();
      expect(find.text('Castro, Emma'), findsOneWidget);

      // Exportar termina sin romper aunque el entorno no pueda compartir.
      await tester.tap(find.byTooltip('Exportar listado (PDF)'));
      await tester.pump();
      for (var i = 0; i < 120; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      // Ficha del alumno confirmado y baja.
      await tester.tap(find.text('Ñandú, Sofía'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirmada el'), findsOneWidget);
      expect(find.text('Pedir documento'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pump();
      await _asentar(tester);
      expect(find.text('Ñandú, Sofía'), findsNothing);
      expect(find.text('2 alumnos confirmados'), findsOneWidget);

      // La familia de Mateo elimina su cuenta: la lista se actualiza sola.
      await _borrarSolicitudes(tester, d.mateo.alumno.cuentaId);
      await _asentar(tester);
      expect(find.text('Álvarez, Mateo'), findsNothing);
      expect(find.text('1 alumno confirmado'), findsOneWidget);
      expect(find.text('Castro, Emma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('escritorio oscuro en inglés', (tester) async {
      await tester.runAsync(_sembrar);
      await _abrir(
        tester,
        _alumnos,
        size: _escritorio,
        locale: const Locale('en'),
        mode: ThemeMode.dark,
      );
      expect(find.text('2 confirmed students'), findsOneWidget);
      await tester.tap(find.text('Castro, Emma'));
      await tester.pumpAndSettle();
      expect(find.text('Student details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
