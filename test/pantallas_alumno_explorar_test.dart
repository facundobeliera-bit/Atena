// test/pantallas_alumno_explorar_test.dart
//
// Pantallas del alumno para buscar instituciones y pedir vacante.
// - Explorar: listado con vacantes libres, búsqueda con espera (sin perder el
//   foco), filtros por nivel y por edad del alumno, y estados vacíos.
// - Ficha pública: con y sin fotos, galería, contacto, vacantes agrupadas con
//   sus estados (completa, últimas, solicitud en curso) e institución
//   inexistente.
// - Pedir vacante: envío correcto, aviso de edad y rechazos del núcleo
//   (duplicada, sin cupo, vacante retirada).
// - Mis solicitudes: pestañas, detalle según el estado, cancelación,
//   comprobante e institución dada de baja.
// - Tamaños, idiomas, texto grande y tema oscuro: nada se desborda.

import 'dart:convert';

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/core/repos/bajas_repo.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/alumnos/explorar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/institucion_publica_page.dart';
import 'package:atena_app/screens/alumnos/mis_solicitudes_page.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/ui/atena_labels.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const _colegio = 'INST_COLEGIO';
const _jardin = 'INST_JARDIN';
const _club = 'INST_CLUB';

const _nColegio = 'Colegio San Martín';
const _nJardin = 'Jardín Arcoíris';
const _nClub = 'Club Atlético Los Andes';

/// Textos en español: las pruebas comparan contra las mismas claves que usa
/// la interfaz.
final AppLocalizations _t = lookupAppLocalizations(const Locale('es'));

// -----------------------------------------------------------------------------
// Datos
// -----------------------------------------------------------------------------

class _Datos {
  final String cuentaId;

  /// 8 años.
  final PerfilAlumno lucia;

  /// 12 años.
  final PerfilAlumno tomas;

  /// Colegio · 1° grado · A (de 6 a 7 años).
  final Oferta primero;

  /// Colegio · 3° grado · A (de 8 a 9 años).
  final Oferta tercero;

  /// Colegio · 1° año · A, secundaria (de 12 a 13 años).
  final Oferta anio;

  /// Colegio · Inglés · Kids, extracurricular (de 8 a 12 años).
  final Oferta ingles;

  /// Jardín · Sala de 3 · Turno mañana (3 años).
  final Oferta sala;

  const _Datos({
    required this.cuentaId,
    required this.lucia,
    required this.tomas,
    required this.primero,
    required this.tercero,
    required this.anio,
    required this.ingles,
    required this.sala,
  });
}

Oferta _oferta(
  String institucionId,
  String titulo, {
  String grupo = 'A',
  NivelCurricular nivel = NivelCurricular.primaria,
  BloqueExtracurricular? bloque,
  int cupo = 20,
  int? min,
  int? max,
  String arancel = '',
  String descripcion = '',
}) {
  final ahora = DateTime.now();
  return Oferta(
    id: '',
    institucionId: institucionId,
    tipo: bloque == null ? TipoOferta.curricular : TipoOferta.extracurricular,
    nivel: bloque == null ? nivel : null,
    bloque: bloque,
    titulo: titulo,
    grupo: grupo,
    turno: Turno.manana,
    horario: '08:00 a 12:00',
    dias: 'Lun a Vie',
    cupoTotal: cupo,
    edadMinima: min,
    edadMaxima: max,
    arancel: arancel,
    descripcion: descripcion,
    creadaEl: ahora,
    actualizadaEl: ahora,
  );
}

/// Una familia con dos alumnos y tres instituciones con vacantes.
Future<_Datos> _sembrar({bool fotos = false}) async {
  final hoy = DateTime.now();
  final familia = await AuthService.registrarFamilia(
    email: 'familia@mail.com',
    password: 'clave1234',
    remember: true,
    nombre: 'Lucía',
    apellido: 'Gómez',
    dni: '45123456',
    fechaNacimiento: DateTime(hoy.year - 8, 1, 1),
  );
  final cuentaId = familia.cuenta.id;
  final tomas = await AlumnosRepo.instance.crear(
    cuentaId: cuentaId,
    nombre: 'Tomás',
    apellido: 'Gómez',
    dni: '43123456',
    fechaNacimiento: DateTime(hoy.year - 12, 1, 1),
  );

  final repo = InstitucionesRepo.instance;
  await repo.guardar(
    institucionDemo(
      id: _colegio,
      nombre: _nColegio,
      niveles: const [NivelCurricular.primaria, NivelCurricular.secundaria],
      bloques: const [BloqueExtracurricular.idiomasYComunicacion],
    ),
  );
  await repo.guardar(
    institucionDemo(
      id: _jardin,
      nombre: _nJardin,
      ciudad: 'Rosario',
      provincia: 'Santa Fe',
      niveles: const [NivelCurricular.jardin],
      bloques: const [],
    ).copyWith(tipoInstitucion: TipoInstitucion.jardin),
  );
  await repo.guardar(
    institucionDemo(
      id: _club,
      nombre: _nClub,
      ciudad: 'Mendoza',
      provincia: 'Mendoza',
      niveles: const [],
    ).copyWith(tipoInstitucion: TipoInstitucion.club),
  );

  var perfil = const PerfilPublico(
    descripcion:
        'Colegio bilingüe con más de 40 años de trayectoria. Acompañamos a '
        'cada alumno con grupos reducidos, talleres de robótica y deporte. '
        'Contamos con jornada extendida, comedor propio y un equipo de '
        'orientación que acompaña a cada familia durante todo el año. Nuestro '
        'proyecto integra idiomas, tecnología y deporte desde los primeros '
        'años, con salidas educativas, campamentos y talleres abiertos a la '
        'comunidad. Las familias participan de reuniones periódicas y cuentan '
        'con un canal de comunicación directo con cada docente.',
    horarioAtencion: 'Lunes a viernes de 7:30 a 17:00',
    horarioClases: 'Mañana 8:00 a 12:30 · Tarde 13:30 a 17:30',
    telefono: '351 412-3456',
    whatsapp: '+54 9 351 412-3456',
    email: 'secretaria@colegiosanmartin.edu.ar',
    sitioWeb: 'https://www.colegiosanmartin.edu.ar/',
    instagram: '@colegiosanmartin',
    facebook: 'facebook.com/colegiosanmartin',
    youtube: 'colegiosanmartin',
    servicios: ['Bilingüe', 'Comedor', 'Gabinete psicopedagógico'],
  );
  if (fotos) {
    final bytes = base64Decode(_png1x1);
    perfil = perfil.copyWith(
      fotoIds: [
        await repo.guardarImagen(bytes),
        await repo.guardarImagen(bytes),
      ],
      logoId: await repo.guardarImagen(bytes),
    );
  }
  await repo.guardarPerfilPublico(_colegio, perfil);
  await repo.guardarPerfilPublico(
    _jardin,
    const PerfilPublico(
      descripcion: 'Aprendemos jugando, con música, arte y mucho cariño.',
    ),
  );

  final ofertas = OfertasRepo.instance;
  final primero = await ofertas.guardar(
    _oferta(_colegio, '1° grado', cupo: 25, min: 6, max: 7),
  );
  final tercero = await ofertas.guardar(
    _oferta(_colegio, '3° grado', cupo: 25, min: 8, max: 9),
  );
  final anio = await ofertas.guardar(
    _oferta(
      _colegio,
      '1° año',
      nivel: NivelCurricular.secundaria,
      cupo: 30,
      min: 12,
      max: 13,
    ),
  );
  final ingles = await ofertas.guardar(
    _oferta(
      _colegio,
      'Inglés',
      grupo: 'Kids',
      bloque: BloqueExtracurricular.idiomasYComunicacion,
      cupo: 12,
      min: 8,
      max: 12,
      arancel: r'$ 18.000 por mes',
      descripcion: 'Conversación en grupos chicos, dos veces por semana.',
    ),
  );
  final sala = await ofertas.guardar(
    _oferta(
      _jardin,
      'Sala de 3',
      grupo: 'Turno mañana',
      nivel: NivelCurricular.jardin,
      cupo: 18,
      min: 3,
      max: 3,
    ),
  );
  await ofertas.guardar(
    _oferta(
      _club,
      'Natación',
      grupo: 'Escuelita',
      bloque: BloqueExtracurricular.deporteYMovimiento,
      cupo: 16,
      min: 5,
      max: 12,
    ),
  );

  return _Datos(
    cuentaId: cuentaId,
    lucia: familia.perfil,
    tomas: tomas,
    primero: primero,
    tercero: tercero,
    anio: anio,
    ingles: ingles,
    sala: sala,
  );
}

String _institucionDe(Oferta o) => switch (o.institucionId) {
  _jardin => _nJardin,
  _club => _nClub,
  _ => _nColegio,
};

Future<Solicitud> _pedir(
  _Datos d,
  PerfilAlumno alumno,
  Oferta oferta, {
  String mensaje = '',
}) {
  return SolicitudesRepo.instance.crear(
    alumno: AlumnosRepo.instance.snapshot(d.cuentaId, alumno),
    institucionNombre: _institucionDe(oferta),
    oferta: oferta,
    mensaje: mensaje,
  );
}

Future<Solicitud> _confirmar(
  _Datos d,
  PerfilAlumno alumno,
  Oferta oferta, {
  String nota = '',
  String mensaje = '',
}) async {
  final s = await _pedir(d, alumno, oferta, mensaje: mensaje);
  return SolicitudesRepo.instance.responder(
    s.id,
    institucionId: oferta.institucionId,
    aceptar: true,
    nota: nota,
  );
}

Future<Solicitud> _rechazar(
  _Datos d,
  PerfilAlumno alumno,
  Oferta oferta, {
  String nota = '',
}) async {
  final s = await _pedir(d, alumno, oferta);
  return SolicitudesRepo.instance.responder(
    s.id,
    institucionId: oferta.institucionId,
    aceptar: false,
    nota: nota,
  );
}

// -----------------------------------------------------------------------------
// Utilidades de interfaz
// -----------------------------------------------------------------------------

/// Con las tipografías de la app el texto mide lo mismo que en un dispositivo
/// (la fuente de prueba es más ancha y produce desbordes que no existen).
Future<void> _fuentes() async {
  Future<void> cargar(String familia, List<String> assets) async {
    final loader = FontLoader(familia);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await cargar('PlusJakartaSans', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/PlusJakartaSans-$w.ttf',
  ]);
  await cargar('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
}

Future<void> _abrir(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('es'),
  ThemeMode mode = ThemeMode.light,
  double escalaTexto = 1,
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

/// Baja por la lista principal hasta que el elemento existe y queda a la vista.
Future<void> _hasta(WidgetTester tester, Finder finder, {Finder? en}) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: en ?? find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Vuelve al comienzo de la lista principal.
Future<void> _arriba(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 8000));
  await tester.pumpAndSettle();
}

/// Recorre la lista de punta a punta para construir (y validar) todo.
Future<void> _recorrer(WidgetTester tester, Finder lista) async {
  for (var i = 0; i < 14; i++) {
    await tester.drag(lista, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 60));
  }
  await tester.pumpAndSettle();
}

Future<void> _volver(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

/// Espera a que se vaya el aviso (snackbar) visible.
Future<void> _sinAviso(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Escribe en el buscador y deja pasar la espera antes de buscar.
Future<void> _buscar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

const _canalEnlaces = MethodChannel('plugins.flutter.io/url_launcher');

/// Registra los enlaces que la app pide abrir y simula si el dispositivo pudo
/// abrirlos (en las pruebas no hay teléfono, navegador ni mapas).
List<String> _capturarEnlaces(
  WidgetTester tester, {
  required bool sePuedeAbrir,
}) {
  final enlaces = <String>[];
  final mensajero = tester.binding.defaultBinaryMessenger;
  mensajero.setMockMethodCallHandler(_canalEnlaces, (llamada) async {
    final args = llamada.arguments;
    if (llamada.method == 'launch' && args is Map) {
      enlaces.add('${args['url']}');
    }
    return sePuedeAbrir;
  });
  addTearDown(() => mensajero.setMockMethodCallHandler(_canalEnlaces, null));
  return enlaces;
}

/// Tarjeta (de oferta o de solicitud) que contiene ese texto.
Finder _tarjeta(String texto) =>
    find.ancestor(of: find.text(texto), matching: find.byType(AtenaCard));

Finder _dentro(Finder tarjeta, String texto) =>
    find.descendant(of: tarjeta, matching: find.text(texto));

Widget _explorar(_Datos d, PerfilAlumno alumno) =>
    ExplorarInstitucionesPage(cuentaId: d.cuentaId, perfilId: alumno.id);

Widget _ficha(_Datos d, PerfilAlumno alumno, String institucionId) =>
    InstitucionPublicaPage(
      cuentaId: d.cuentaId,
      perfilId: alumno.id,
      institucionId: institucionId,
    );

Widget _solicitudes(_Datos d, PerfilAlumno alumno) =>
    MisSolicitudesPage(cuentaId: d.cuentaId, perfilId: alumno.id);

Widget _detalle(_Datos d, PerfilAlumno alumno, Solicitud s) =>
    SolicitudAlumnoDetallePage(
      cuentaId: d.cuentaId,
      perfilId: alumno.id,
      solicitudId: s.id,
    );

/// Abre la hoja "Pedir vacante" de la oferta con ese nombre.
Future<void> _abrirHoja(WidgetTester tester, String oferta) async {
  await _hasta(tester, find.text(oferta));
  await tester.tap(_dentro(_tarjeta(oferta), _t.explorarPedirVacante));
  await tester.pumpAndSettle();
  expect(find.text(_t.solAlEnviar), findsOneWidget);
}

const _tamanos = [
  (
    'teléfono angosto en inglés con texto grande',
    Size(360, 640),
    Locale('en'),
    ThemeMode.light,
    1.3,
  ),
  (
    'teléfono en portugués, oscuro y con texto grande',
    Size(360, 780),
    Locale('pt'),
    ThemeMode.dark,
    1.3,
  ),
  ('teléfono en español', Size(390, 844), Locale('es'), ThemeMode.light, 1.0),
  ('tableta oscura', Size(800, 1100), Locale('es'), ThemeMode.dark, 1.0),
  ('escritorio', Size(1366, 768), Locale('es'), ThemeMode.light, 1.0),
  (
    'escritorio oscuro en inglés',
    Size(1366, 768),
    Locale('en'),
    ThemeMode.dark,
    1.0,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_fuentes);
  setUp(resetStorage);

  // ---------------------------------------------------------------------------
  group('Explorar', () {
    testWidgets('lista las instituciones con sus vacantes y abre la ficha', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _explorar(d, d.lucia));

      expect(find.text(_t.explorarTitulo), findsOneWidget);
      expect(find.textContaining(_t.explorarPara('Lucía')), findsOneWidget);
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);
      for (final nombre in [_nClub, _nColegio, _nJardin]) {
        expect(find.text(nombre), findsOneWidget);
      }
      // Vacantes libres de cada una (suma de sus ofertas activas).
      expect(find.text(_t.lblCupos(92)), findsOneWidget);
      expect(find.text(_t.lblCupos(18)), findsOneWidget);
      expect(find.text(_t.lblCupos(16)), findsOneWidget);
      // Niveles y actividades como etiquetas.
      expect(find.text(_t.nivel(NivelCurricular.secundaria)), findsOneWidget);
      expect(
        find.text(_t.bloque(BloqueExtracurricular.deporteYMovimiento)),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text(_nJardin));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_nJardin));
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionPublicaPage), findsOneWidget);
      expect(find.text(_t.explorarVacantes), findsOneWidget);
      await _volver(tester);
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);

      await tester.tap(find.byTooltip(_t.homeActionRequests));
      await tester.pumpAndSettle();
      expect(find.byType(MisSolicitudesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la búsqueda espera, filtra y no le quita el foco al campo', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _explorar(d, d.lucia));

      await tester.enterText(find.byType(TextField), 'rosario');
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        find.text(_t.explorarResultados(3)),
        findsOneWidget,
        reason: 'todavía no pasó la espera',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text(_t.explorarResultados(1)), findsOneWidget);
      expect(find.text(_nJardin), findsOneWidget);
      expect(find.text(_nColegio), findsNothing);
      final campo = tester.widget<EditableText>(find.byType(EditableText));
      expect(campo.focusNode.hasFocus, isTrue);
      expect(campo.controller.text, 'rosario');

      // También busca por nombre, sin importar tildes ni mayúsculas.
      await _buscar(tester, 'ATLETICO');
      expect(find.text(_nClub), findsOneWidget);
      expect(find.text(_nJardin), findsNothing);

      await tester.tap(find.byTooltip(_t.explorarBorrarBusqueda));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);
      expect(find.byTooltip(_t.explorarBorrarBusqueda), findsNothing);
    });

    testWidgets('filtra por nivel y por vacantes para la edad del alumno', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _explorar(d, d.lucia));

      // Nivel: se elige en una hoja y el chip muestra lo elegido.
      await tester.tap(find.widgetWithText(FilterChip, _t.explorarFiltroNivel));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarCualquierNivel), findsOneWidget);
      final secundaria = _t.nivel(NivelCurricular.secundaria);
      await tester.tap(find.text(secundaria).last);
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(1)), findsOneWidget);
      expect(find.text(_nColegio), findsOneWidget);
      expect(find.widgetWithText(FilterChip, secundaria), findsOneWidget);

      await tester.tap(find.text(_t.explorarLimpiarFiltros));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);
      expect(find.text(_t.explorarLimpiarFiltros), findsNothing);

      // Edad: Lucía tiene 8 y el jardín solo ofrece sala de 3.
      await tester.tap(
        find.widgetWithText(FilterChip, _t.explorarConLugarPara('Lucía')),
      );
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(2)), findsOneWidget);
      expect(find.text(_nJardin), findsNothing);
      expect(find.text(_nColegio), findsOneWidget);
      expect(find.text(_nClub), findsOneWidget);
    });

    testWidgets('sin resultados ofrece limpiar los filtros', (tester) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _explorar(d, d.lucia));

      await _buscar(tester, 'zzzz');
      expect(find.text(_t.explorarSinResultadosTitulo), findsOneWidget);
      expect(find.text(_nColegio), findsNothing);

      await tester.tap(
        find.widgetWithText(OutlinedButton, _t.explorarLimpiarFiltros),
      );
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
    });

    testWidgets('sin instituciones publicadas lo explica', (tester) async {
      final familia = (await tester.runAsync(
        () => AuthService.registrarFamilia(
          email: 'sola@mail.com',
          password: 'clave1234',
          remember: true,
          nombre: 'Ana',
          apellido: 'Paz',
          dni: '40111222',
          fechaNacimiento: DateTime(2016, 1, 1),
        ),
      ))!;
      await _abrir(
        tester,
        ExplorarInstitucionesPage(
          cuentaId: familia.cuenta.id,
          perfilId: familia.perfil.id,
        ),
      );
      expect(find.text(_t.explorarVacioTitulo), findsOneWidget);
      expect(find.text(_t.explorarVacioMensaje), findsOneWidget);
      expect(find.text(_t.explorarSinResultadosTitulo), findsNothing);
      // El buscador sigue disponible.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('escritorio: panel de filtros a la vista y grilla', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(
        tester,
        _explorar(d, d.lucia),
        size: const Size(1366, 768),
        mode: ThemeMode.dark,
      );
      expect(find.text(_t.explorarFiltros), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);

      final inicial = _t.nivel(NivelCurricular.jardin);
      await tester.tap(find.widgetWithText(ChoiceChip, inicial));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(1)), findsOneWidget);
      expect(find.text(_nJardin), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, inicial));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(2)), findsOneWidget);
      await tester.tap(find.text(_t.explorarLimpiarFiltros));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarResultados(3)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('Ficha pública', () {
    testWidgets('con fotos: portada, galería, descripción y contacto', (
      tester,
    ) async {
      final d = (await tester.runAsync(() => _sembrar(fotos: true)))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));

      expect(find.text(_nColegio), findsWidgets);
      expect(
        find.text(AtenaLabels(_t).tipoInstitucion(TipoInstitucion.primaria)),
        findsOneWidget,
      );
      expect(
        find.text(_t.modalidad(ModalidadCursado.presencial)),
        findsOneWidget,
      );
      expect(find.text(_t.lblCupos(92)), findsOneWidget);
      // Dirección completa, sin repetir ciudad y provincia iguales.
      expect(
        find.text('Av. Siempre Viva 123, Córdoba, Argentina'),
        findsOneWidget,
      );

      // Galería a pantalla completa: se desliza y responde al teclado.
      await tester.tap(find.byTooltip(_t.explorarVerFotos));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip(_t.uiClose));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsNothing);

      // Descripción larga: se despliega.
      await _hasta(tester, find.text(_t.explorarLeerMas));
      await tester.tap(find.text(_t.explorarLeerMas));
      await tester.pumpAndSettle();
      expect(find.text(_t.explorarLeerMenos), findsOneWidget);

      // Contacto: enlaces armados a partir del perfil público.
      await _hasta(tester, find.text(_t.explorarContacto));
      await _hasta(tester, find.text(_t.explorarComoLlegar));
      for (final texto in [
        _t.explorarLlamar,
        _t.explorarWhatsapp,
        _t.explorarSitioWeb,
        'colegiosanmartin.edu.ar',
        _t.explorarInstagram,
        'facebook.com/colegiosanmartin',
        _t.explorarYoutube,
      ]) {
        expect(find.text(texto), findsOneWidget);
      }
      expect(find.text('@colegiosanmartin'), findsNWidgets(2));

      Future<void> tocar(String titulo) async {
        await tester.ensureVisible(find.text(titulo));
        await tester.pumpAndSettle();
        await tester.tap(find.text(titulo));
        await tester.pumpAndSettle();
      }

      // Si el dispositivo no puede abrir el enlace, hay un aviso amable.
      var enlaces = _capturarEnlaces(tester, sePuedeAbrir: false);
      await tocar(_t.explorarLlamar);
      expect(enlaces, ['tel:3514123456']);
      expect(find.text(_t.explorarNoSePudoAbrir), findsOneWidget);
      await _sinAviso(tester);

      // Cada vía de contacto abre el enlace que corresponde.
      enlaces = _capturarEnlaces(tester, sePuedeAbrir: true);
      for (final titulo in [
        _t.explorarWhatsapp,
        _t.commonEmail,
        _t.explorarSitioWeb,
        _t.explorarInstagram,
        _t.explorarFacebook,
        _t.explorarYoutube,
        _t.explorarComoLlegar,
      ]) {
        await tocar(titulo);
      }
      expect(find.text(_t.explorarNoSePudoAbrir), findsNothing);
      expect(enlaces.take(6), [
        'https://wa.me/5493514123456',
        'mailto:secretaria@colegiosanmartin.edu.ar',
        'https://www.colegiosanmartin.edu.ar/',
        'https://www.instagram.com/colegiosanmartin',
        'https://facebook.com/colegiosanmartin',
        'https://www.youtube.com/@colegiosanmartin',
      ]);
      final mapa = Uri.parse(enlaces.last);
      expect(mapa.host, 'www.google.com');
      expect(
        mapa.queryParameters['query'],
        'Av. Siempre Viva 123, Córdoba, Argentina',
      );

      await _hasta(tester, find.text(_t.explorarHorarios));
      await _hasta(tester, find.text(_t.explorarServicios));
      await _hasta(tester, find.text('Gabinete psicopedagógico'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin fotos: portada de marca y solo lo que hay para mostrar', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, _jardin));

      expect(find.byTooltip(_t.explorarVerFotos), findsNothing);
      expect(find.byType(PageView), findsNothing);
      expect(
        find.text(AtenaLabels(_t).tipoInstitucion(TipoInstitucion.jardin)),
        findsOneWidget,
      );
      expect(
        find.text('Av. Siempre Viva 123, Rosario, Santa Fe, Argentina'),
        findsOneWidget,
      );
      expect(find.text(_t.explorarLeerMas), findsNothing);

      // Un solo tipo de oferta: no hace falta el selector.
      await _hasta(tester, find.text('Sala de 3 · Turno mañana'));
      expect(find.byType(SegmentedButton<TipoOferta>), findsNothing);
      expect(find.text(_t.nivel(NivelCurricular.jardin)), findsWidgets);
      final sala = _tarjeta('Sala de 3 · Turno mañana');
      // Rango de una sola edad, sin repetirla.
      expect(_dentro(sala, _t.lblEdadAnios(3)), findsOneWidget);
      expect(_dentro(sala, _t.lblCuposDeTotal(18, 18)), findsOneWidget);
      expect(_dentro(sala, _t.explorarFueraDeEdad('Lucía')), findsOneWidget);

      // Sin horarios ni servicios cargados; el contacto es solo el mapa.
      await _recorrer(tester, find.byType(Scrollable).first);
      expect(find.text(_t.explorarComoLlegar), findsOneWidget);
      expect(find.text(_t.explorarLlamar), findsNothing);
      expect(find.text(_t.explorarHorarios), findsNothing);
      expect(find.text(_t.explorarServicios), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vacantes: solicitud en curso, completa y últimas', (
      tester,
    ) async {
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        await _confirmar(d, d.lucia, d.tercero);
        final ofertas = OfertasRepo.instance;
        final unica = await ofertas.guardar(
          _oferta(_colegio, 'Sala única', cupo: 1),
        );
        await _confirmar(d, d.tomas, unica);
        final doble = await ofertas.guardar(
          _oferta(_colegio, 'Sala doble', cupo: 2),
        );
        await _confirmar(d, d.tomas, doble);
        return d;
      }))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));

      // Curricular y extracurricular: hay selector.
      await _hasta(tester, find.byType(SegmentedButton<TipoOferta>));

      // 1° grado es para 6 y 7 años: se avisa, pero se puede pedir.
      await _hasta(tester, find.text('1° grado · A'));
      final primero = _tarjeta('1° grado · A');
      expect(_dentro(primero, _t.explorarFueraDeEdad('Lucía')), findsOneWidget);
      expect(_dentro(primero, _t.explorarPedirVacante), findsOneWidget);

      // 3° grado: Lucía ya está confirmada.
      await _hasta(tester, find.text('3° grado · A'));
      final tercero = _tarjeta('3° grado · A');
      expect(_dentro(tercero, _t.lblEstadoConfirmada), findsOneWidget);
      expect(_dentro(tercero, _t.explorarPedirVacante), findsNothing);
      expect(_dentro(tercero, _t.lblCuposDeTotal(24, 25)), findsOneWidget);
      expect(_dentro(tercero, _t.explorarFueraDeEdad('Lucía')), findsNothing);
      await tester.tap(_dentro(tercero, _t.explorarVerSolicitud));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitudAlumnoDetallePage), findsOneWidget);
      expect(find.text(_t.solAlEstadoConfirmadaTitulo), findsOneWidget);
      await _volver(tester);

      // Queda 1 de 2.
      await _hasta(tester, find.text('Sala doble · A'));
      final doble = _tarjeta('Sala doble · A');
      expect(_dentro(doble, _t.explorarUltimasVacantes), findsOneWidget);
      expect(_dentro(doble, _t.lblCuposDeTotal(1, 2)), findsOneWidget);

      // Sin lugar: no se puede pedir.
      await _hasta(tester, find.text('Sala única · A'));
      final unica = _tarjeta('Sala única · A');
      expect(_dentro(unica, _t.explorarCompleto), findsOneWidget);
      expect(_dentro(unica, _t.explorarPedirVacante), findsNothing);
      final sinVacantes = find.descendant(
        of: unica,
        matching: find.widgetWithText(FilledButton, _t.lblCupos(0)),
      );
      expect(tester.widget<FilledButton>(sinVacantes).onPressed, isNull);

      // Extracurricular, agrupado por actividad.
      await _arriba(tester);
      await _hasta(tester, find.text(_t.lblExtracurricular));
      await tester.tap(find.text(_t.lblExtracurricular));
      await tester.pumpAndSettle();
      await _hasta(tester, find.text('Inglés · Kids'));
      expect(find.text('3° grado · A'), findsNothing);
      expect(
        find.text(_t.bloque(BloqueExtracurricular.idiomasYComunicacion)),
        findsWidgets,
      );
      expect(
        find.text(_t.explorarArancel(r'$ 18.000 por mes')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('institución inexistente: aviso amable y volver', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, 'NO_EXISTE'));
      expect(find.text(_t.explorarInstNoEncontradaTitulo), findsOneWidget);
      expect(find.text(_t.explorarInstNoEncontradaMensaje), findsOneWidget);
      expect(find.text(_t.commonBack), findsOneWidget);
      expect(find.text(_t.explorarVacantes), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  group('Pedir vacante', () {
    testWidgets('envía la solicitud con el mensaje y queda pendiente', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));
      await _abrirHoja(tester, '3° grado · A');

      // Resumen del alumno; la edad coincide: sin aviso.
      expect(find.textContaining('Lucía Gómez'), findsOneWidget);
      expect(find.text(_t.solAlFueraDeEdadTitulo), findsNothing);

      const mensaje = 'Hola, nos mudamos en marzo.';
      await tester.enterText(find.byType(TextField), mensaje);
      await tester.pump();
      expect(find.text('${mensaje.length}/500'), findsOneWidget);
      await tester.ensureVisible(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();

      // La hoja se cierra, hay aviso y la tarjeta muestra el estado.
      expect(find.text(_t.solAlEnviar), findsNothing);
      expect(find.text(_t.solAlEnviadaOk), findsOneWidget);
      final tercero = _tarjeta('3° grado · A');
      expect(_dentro(tercero, _t.lblEstadoPendiente), findsOneWidget);
      expect(_dentro(tercero, _t.explorarVerSolicitud), findsOneWidget);
      expect(_dentro(tercero, _t.explorarPedirVacante), findsNothing);

      final creadas = (await tester.runAsync(
        () => SolicitudesRepo.instance.porPerfil(d.lucia.id),
      ))!;
      expect(creadas, hasLength(1));
      expect(creadas.single.estado, EstadoSolicitud.pendiente);
      expect(creadas.single.mensaje, mensaje);
      expect(creadas.single.institucionNombre, _nColegio);
      expect(creadas.single.ofertaId, d.tercero.id);
      expect(creadas.single.alumno.cuentaId, d.cuentaId);

      // El aviso lleva directo al detalle.
      await tester.tap(find.text(_t.commonView));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitudAlumnoDetallePage), findsOneWidget);
      expect(find.text(_t.solAlEstadoPendienteTitulo), findsOneWidget);
      await _sinAviso(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edad fuera de rango: avisa y deja enviar igual', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));
      await _abrirHoja(tester, '1° grado · A');

      expect(find.text(_t.solAlFueraDeEdadTitulo), findsOneWidget);
      expect(
        find.text(_t.solAlFueraDeEdadMensaje('Lucía', _t.lblEdadAnios(8))),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlEnviadaOk), findsOneWidget);
      final creadas = (await tester.runAsync(
        () => SolicitudesRepo.instance.porPerfil(d.lucia.id),
      ))!;
      expect(creadas.single.ofertaId, d.primero.id);
      await _sinAviso(tester);
    });

    testWidgets('duplicada: muestra el motivo y no cierra la hoja', (
      tester,
    ) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));
      await _abrirHoja(tester, '3° grado · A');

      // Mientras la hoja está abierta, la misma solicitud entra por otro lado.
      await tester.runAsync(() => _pedir(d, d.lucia, d.tercero));
      await tester.ensureVisible(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();

      expect(find.text(_t.errSolicitudDuplicada), findsOneWidget);
      expect(find.text(_t.solAlEnviar), findsOneWidget);
      expect(find.text(_t.solAlEnviadaOk), findsNothing);
      final guardadas = (await tester.runAsync(
        () => SolicitudesRepo.instance.porPerfil(d.lucia.id),
      ))!;
      expect(guardadas, hasLength(1));

      // Al cerrar, la ficha se actualiza con la solicitud existente.
      await tester.ensureVisible(find.text(_t.commonCancel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.commonCancel));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlEnviar), findsNothing);
      expect(
        _dentro(_tarjeta('3° grado · A'), _t.explorarVerSolicitud),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin cupo: otro alumno ocupó el último lugar', (tester) async {
      late Oferta unica;
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        unica = await OfertasRepo.instance.guardar(
          _oferta(_colegio, 'Sala única', cupo: 1),
        );
        return d;
      }))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));
      await _abrirHoja(tester, 'Sala única · A');

      await tester.runAsync(() => _confirmar(d, d.tomas, unica));
      await tester.ensureVisible(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();

      expect(find.text(_t.errSinCupo), findsOneWidget);
      expect(find.text(_t.solAlEnviar), findsOneWidget);
      final deLucia = (await tester.runAsync(
        () => SolicitudesRepo.instance.porPerfil(d.lucia.id),
      ))!;
      expect(deLucia, isEmpty);
    });

    testWidgets('vacante retirada: no se envía el pedido', (tester) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _ficha(d, d.lucia, _colegio));
      await _abrirHoja(tester, '3° grado · A');

      await tester.runAsync(
        () => OfertasRepo.instance.eliminar(_colegio, d.tercero.id),
      );
      await tester.ensureVisible(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlEnviar));
      await tester.pumpAndSettle();

      expect(find.text(_t.errOfertaInactiva), findsOneWidget);
      final deLucia = (await tester.runAsync(
        () => SolicitudesRepo.instance.porPerfil(d.lucia.id),
      ))!;
      expect(deLucia, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('Mis solicitudes', () {
    testWidgets('pestañas con contadores y respuesta de la institución', (
      tester,
    ) async {
      const motivo = 'Por la edad le corresponde otro grado. ¡Gracias!';
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        await _confirmar(d, d.lucia, d.tercero);
        await _pedir(d, d.lucia, d.ingles);
        await _rechazar(d, d.lucia, d.primero, nota: motivo);
        return d;
      }))!;
      await _abrir(tester, _solicitudes(d, d.lucia));

      expect(find.text(_t.solAlTitulo), findsOneWidget);
      expect(find.text('Lucía Gómez'), findsOneWidget);
      final pestanas = find.byType(TabBar);
      expect(
        find.descendant(of: pestanas, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: pestanas, matching: find.text('1')),
        findsOneWidget,
      );

      // Activas: pendiente y confirmada.
      expect(find.text(_nColegio), findsNWidgets(2));
      expect(find.text(_t.lblEstadoConfirmada), findsOneWidget);
      expect(find.text(_t.lblEstadoPendiente), findsOneWidget);
      expect(find.text(_t.lblEstadoRechazada), findsNothing);

      // Historial: la no aceptada, con el extracto de la respuesta.
      await tester.tap(find.text(_t.solAlTabHistorial));
      await tester.pumpAndSettle();
      expect(find.text(_t.lblEstadoRechazada), findsOneWidget);
      expect(find.text(_t.solAlRespuestaDe(_nColegio)), findsOneWidget);
      expect(find.text(motivo), findsOneWidget);

      await tester.tap(find.text(motivo));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitudAlumnoDetallePage), findsOneWidget);
      expect(find.text(_t.solAlEstadoRechazadaTitulo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin solicitudes: invita a explorar', (tester) async {
      final d = (await tester.runAsync(_sembrar))!;
      await _abrir(tester, _solicitudes(d, d.tomas));

      expect(find.text(_t.solAlActivasVacioTitulo), findsOneWidget);
      await tester.tap(find.text(_t.homeActionExplore));
      await tester.pumpAndSettle();
      expect(find.byType(ExplorarInstitucionesPage), findsOneWidget);
      expect(find.textContaining(_t.explorarPara('Tomás')), findsOneWidget);
      await _volver(tester);

      await tester.tap(find.text(_t.solAlTabHistorial));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlHistorialVacioTitulo), findsOneWidget);
      expect(find.text(_t.homeActionExplore), findsOneWidget);
    });

    testWidgets('detalle: explica cada estado y ofrece el paso que sigue', (
      tester,
    ) async {
      const bienvenida = 'Bienvenida Lucía. Te esperamos el primer día.';
      const baja = 'El grupo se cerró por falta de inscriptos.';
      late Solicitud pendiente;
      late Solicitud confirmada;
      late Solicitud rechazada;
      late Solicitud cancelada;
      late Solicitud deBaja;
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        final repo = SolicitudesRepo.instance;
        pendiente = await _pedir(d, d.lucia, d.ingles);
        confirmada = await _confirmar(
          d,
          d.lucia,
          d.tercero,
          nota: bienvenida,
          mensaje: 'Nos mudamos a Córdoba en marzo.',
        );
        rechazada = await _rechazar(d, d.lucia, d.primero);
        final s = await _pedir(d, d.lucia, d.anio);
        cancelada = await repo.cancelar(s.id, perfilId: d.lucia.id);
        final c = await _confirmar(d, d.lucia, d.sala);
        deBaja = await repo.darDeBaja(c.id, institucionId: _jardin, nota: baja);
        return d;
      }))!;
      final lista = find.byType(Scrollable).first;

      // Pendiente: se puede cancelar.
      await _abrir(tester, _detalle(d, d.lucia, pendiente));
      expect(find.text(_t.solAlDetalleTitulo), findsOneWidget);
      expect(find.text(_t.solAlEstadoPendienteTitulo), findsOneWidget);
      expect(
        find.text(_t.solAlEstadoPendienteMensaje(_nColegio)),
        findsOneWidget,
      );
      expect(find.text(_t.homeActionDocuments), findsNothing);
      await _hasta(tester, find.text('Inglés · Kids'));
      await _hasta(tester, find.text(_t.solAlCancelar));
      expect(find.text(_t.solAlComprobante), findsOneWidget);
      expect(find.text(_t.solAlHitoEnviada), findsOneWidget);
      expect(find.text(_t.solAlTuMensaje), findsNothing);

      // Confirmada: próximos pasos, respuesta, mensaje y seguimiento.
      await _abrir(tester, _detalle(d, d.lucia, confirmada));
      expect(find.text(_t.solAlEstadoConfirmadaTitulo), findsOneWidget);
      expect(find.text(_t.homeActionDocuments), findsOneWidget);
      expect(find.text(_t.homeActionCalendar), findsOneWidget);
      expect(find.text(_t.solAlRespuestaDe(_nColegio)), findsOneWidget);
      expect(find.text(bienvenida), findsWidgets);
      await _hasta(tester, find.text(_t.solAlTuMensaje));
      expect(find.text('Nos mudamos a Córdoba en marzo.'), findsOneWidget);
      await _hasta(tester, find.text(_t.solAlHitoConfirmada));
      expect(find.text(_t.solAlHitoEnviada), findsOneWidget);
      await _hasta(tester, find.text(_t.solAlCancelar));

      // No aceptada: invita a seguir buscando; ya no se cancela.
      await _abrir(tester, _detalle(d, d.lucia, rechazada));
      expect(find.text(_t.solAlEstadoRechazadaTitulo), findsOneWidget);
      expect(find.text(_t.homeActionExplore), findsOneWidget);
      await _recorrer(tester, lista);
      expect(find.text(_t.solAlHitoRechazada), findsOneWidget);
      expect(find.text(_t.solAlComprobante), findsOneWidget);
      expect(find.text(_t.solAlCancelar), findsNothing);

      // Cancelada por la familia.
      await _abrir(tester, _detalle(d, d.lucia, cancelada));
      expect(find.text(_t.solAlEstadoCanceladaTitulo), findsOneWidget);
      expect(find.text(_t.solAlEstadoCanceladaMensaje), findsOneWidget);
      await _recorrer(tester, lista);
      expect(find.text(_t.solAlHitoCancelada), findsOneWidget);
      expect(find.text(_t.solAlCancelar), findsNothing);

      // Dada de baja por la institución, con su nota y acceso a la ficha.
      await _abrir(tester, _detalle(d, d.lucia, deBaja));
      expect(find.text(_t.solAlEstadoBajaTitulo), findsOneWidget);
      expect(find.text(_t.solAlEstadoBajaMensaje(_nJardin)), findsOneWidget);
      // La nota figura en la respuesta (y más abajo, en el seguimiento).
      expect(find.text(baja), findsWidgets);
      await _hasta(tester, find.text(_t.explorarVerInstitucion));
      // Rango de una sola edad junto a la del alumno.
      expect(
        find.textContaining(_t.solAlEdadAlumno('Lucía', _t.lblEdadAnios(8))),
        findsOneWidget,
      );
      await tester.tap(find.text(_t.explorarVerInstitucion));
      await tester.pumpAndSettle();
      expect(find.byType(InstitucionPublicaPage), findsOneWidget);
      expect(find.text(_nJardin), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelar pide confirmación y libera la vacante', (
      tester,
    ) async {
      late Solicitud confirmada;
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        confirmada = await _confirmar(d, d.lucia, d.tercero);
        return d;
      }))!;
      await _abrir(tester, _detalle(d, d.lucia, confirmada));

      await _hasta(tester, find.text(_t.solAlCancelar));
      await tester.tap(find.text(_t.solAlCancelar));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlCancelarTitulo), findsOneWidget);
      expect(
        find.text(_t.solAlCancelarMsgConfirmada('3° grado · A', _nColegio)),
        findsOneWidget,
      );

      // Arrepentirse no cambia nada.
      await tester.tap(find.text(_t.solAlMantener));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlCancelarTitulo), findsNothing);
      Future<EstadoSolicitud?> estado() async {
        final s = await tester.runAsync(
          () => SolicitudesRepo.instance.obtener(confirmada.id),
        );
        return s?.estado;
      }

      expect(await estado(), EstadoSolicitud.confirmada);

      await tester.tap(find.text(_t.solAlCancelar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.solAlCancelarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(_t.solAlCanceladaOk), findsOneWidget);
      expect(await estado(), EstadoSolicitud.canceladaPorAlumno);
      final cupos = (await tester.runAsync(
        () => OfertasRepo.instance.conCupo(_colegio),
      ))!;
      expect(
        cupos.firstWhere((o) => o.oferta.id == d.tercero.id).disponibles,
        25,
      );
      await _sinAviso(tester);

      await _arriba(tester);
      expect(find.text(_t.solAlEstadoCanceladaTitulo), findsOneWidget);
      await _recorrer(tester, find.byType(Scrollable).first);
      expect(find.text(_t.solAlCancelar), findsNothing);
      expect(find.text(_t.solAlHitoCancelada), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la solicitud de otro alumno no se muestra', (tester) async {
      late Solicitud deTomas;
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        deTomas = await _pedir(d, d.tomas, d.anio);
        return d;
      }))!;

      await _abrir(tester, _detalle(d, d.lucia, deTomas));
      expect(find.text(_t.solAlNoEncontradaTitulo), findsOneWidget);
      expect(find.text(_t.solAlEstadoPendienteTitulo), findsNothing);
      expect(find.text('1° año · A'), findsNothing);

      // Su dueño sí la ve.
      await _abrir(tester, _detalle(d, d.tomas, deTomas));
      expect(find.text(_t.solAlEstadoPendienteTitulo), findsOneWidget);
    });

    testWidgets('comprobante: si no se puede compartir, avisa sin romper', (
      tester,
    ) async {
      late Solicitud confirmada;
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        confirmada = await _confirmar(d, d.lucia, d.tercero);
        return d;
      }))!;
      await _abrir(tester, _detalle(d, d.lucia, confirmada));

      await _hasta(tester, find.text(_t.solAlComprobante));
      await tester.tap(find.text(_t.solAlComprobante));
      await tester.pump();
      // El PDF se arma con trabajo real (tipografías y logo de la app).
      for (var i = 0; i < 80; i++) {
        if (find.text(_t.solAlComprobante).evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }

      // Termine bien o con el aviso amable, el botón vuelve a estar listo.
      expect(find.text(_t.solAlComprobante), findsOneWidget);
      expect(find.text(_t.commonGenerating), findsNothing);
      expect(tester.takeException(), isNull);
      await _sinAviso(tester);
    });

    testWidgets('institución dada de baja: lo explica y no ofrece su ficha', (
      tester,
    ) async {
      final d = (await tester.runAsync(() async {
        final d = await _sembrar();
        await _pedir(d, d.tomas, d.anio);
        await BajasRepo.instance.eliminarInstitucion(
          institucionId: _colegio,
          ownerAccountId: '',
        );
        return d;
      }))!;

      // La solicitud pasa al historial de la familia.
      await _abrir(tester, _solicitudes(d, d.tomas));
      expect(find.text(_t.solAlActivasVacioTitulo), findsOneWidget);
      await tester.tap(find.text(_t.solAlTabHistorial));
      await tester.pumpAndSettle();
      expect(find.text(_nColegio), findsOneWidget);
      expect(find.text(_t.lblEstadoCanceladaInstitucion), findsOneWidget);

      await tester.tap(find.text(_nColegio));
      await tester.pumpAndSettle();
      expect(find.text(_t.solAlEstadoBajaTitulo), findsOneWidget);
      expect(
        find.text(_t.solAlEstadoBajaSinInstMensaje(_nColegio)),
        findsOneWidget,
      );
      expect(find.text(_t.homeActionExplore), findsOneWidget);
      await _hasta(tester, find.text(_t.solAlInstNoDisponible));
      expect(find.text(_t.explorarVerInstitucion), findsNothing);
      await _recorrer(tester, find.byType(Scrollable).first);
      expect(find.text(_t.solAlComprobante), findsOneWidget);
      expect(find.text(_t.solAlCancelar), findsNothing);

      // Ya no aparece al explorar y su ficha avisa que no está.
      await _abrir(tester, _explorar(d, d.tomas));
      expect(find.text(_t.explorarResultados(2)), findsOneWidget);
      expect(find.text(_nColegio), findsNothing);
      await _abrir(tester, _ficha(d, d.tomas, _colegio));
      expect(find.text(_t.explorarInstNoEncontradaTitulo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('Tamaños, idiomas y tema', () {
    for (final (nombre, size, locale, mode, escala) in _tamanos) {
      testWidgets('nada se desborda: $nombre', (tester) async {
        late Solicitud confirmada;
        late Solicitud rechazada;
        final d = (await tester.runAsync(() async {
          final d = await _sembrar(fotos: true);
          confirmada = await _confirmar(
            d,
            d.lucia,
            d.tercero,
            nota: 'Bienvenida Lucía. Te esperamos el primer día de clases.',
            mensaje: 'Nos mudamos a Córdoba en marzo. ¡Gracias!',
          );
          await _pedir(d, d.lucia, d.ingles);
          rechazada = await _rechazar(
            d,
            d.lucia,
            d.primero,
            nota: 'Por la edad de Lucía le corresponde otro grado.',
          );
          return d;
        }))!;
        final t = lookupAppLocalizations(locale);

        Future<void> abrir(Widget page) => _abrir(
          tester,
          page,
          size: size,
          locale: locale,
          mode: mode,
          escalaTexto: escala,
        );
        Future<void> revisar(String pantalla) async {
          expect(tester.takeException(), isNull, reason: '$pantalla ($nombre)');
        }

        // Explorar: la lista de resultados es el último desplazable.
        await abrir(_explorar(d, d.lucia));
        expect(find.text(t.explorarResultados(3)), findsOneWidget);
        await _recorrer(tester, find.byType(Scrollable).last);
        await revisar('explorar');

        // Ficha con fotos, de punta a punta, y la hoja de pedido.
        await abrir(_ficha(d, d.lucia, _colegio));
        final lista = find.byType(Scrollable).first;
        await _recorrer(tester, lista);
        await revisar('ficha');
        await _arriba(tester);
        await _hasta(tester, find.text('1° año · A'));
        await tester.tap(
          _dentro(_tarjeta('1° año · A'), t.explorarPedirVacante),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.solAlEnviar), findsOneWidget);
        expect(find.text(t.solAlFueraDeEdadTitulo), findsOneWidget);
        await revisar('hoja de pedido');

        // Ficha sin fotos ni perfil completo.
        await abrir(_ficha(d, d.lucia, _club));
        await _recorrer(tester, find.byType(Scrollable).first);
        await revisar('ficha sin fotos');

        // Mis solicitudes: las dos pestañas.
        await abrir(_solicitudes(d, d.lucia));
        expect(find.text(t.solAlTabActivas), findsOneWidget);
        await tester.tap(find.text(t.solAlTabHistorial));
        await tester.pumpAndSettle();
        expect(find.text(t.solAlRespuestaDe(_nColegio)), findsOneWidget);
        await revisar('mis solicitudes');

        // Detalle con respuesta, mensaje y seguimiento; y uno no aceptado.
        for (final s in [confirmada, rechazada]) {
          await abrir(_detalle(d, d.lucia, s));
          await _recorrer(tester, find.byType(Scrollable).first);
          expect(find.text(t.solAlComprobante), findsOneWidget);
          await revisar('detalle');
        }
      });
    }
  });
}
