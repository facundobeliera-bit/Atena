// test/pantallas_institucion_comunicaciones_documentos_test.dart
//
// Pantallas de la institución: comunicaciones y documentación.

import 'dart:convert';

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/core/repos/bajas_repo.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/screens/instituciones/comunicaciones_page.dart';
import 'package:atena_app/screens/instituciones/documentos_institucion_page.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const _inst = 'INST_1';
const _instNombre =
    'Instituto Superior de Formación Integral San Martín de los Andes';

class _Datos {
  final String cuentaId;
  final PerfilAlumno perfil;
  final Oferta oferta1;
  final Oferta oferta2;
  _Datos(this.cuentaId, this.perfil, this.oferta1, this.oferta2);
}

/// Una familia con un alumno confirmado en "1° grado · A"; "2° grado" vacío.
Future<_Datos> _preparar() async {
  final res = await AuthService.registrarFamilia(
    email: 'familia@mail.com',
    password: 'clave1234',
    remember: true,
    nombre: 'Lucía',
    apellido: 'Gómez',
    dni: '45123456',
    fechaNacimiento: DateTime(2015, 1, 1),
  );
  final o1 = await OfertasRepo.instance.guardar(ofertaDemo(cupo: 5));
  final o2 = await OfertasRepo.instance.guardar(
    ofertaDemo(cupo: 5, titulo: '2° grado'),
  );
  final s = await SolicitudesRepo.instance.crear(
    alumno: AlumnosRepo.instance.snapshot(res.cuenta.id, res.perfil),
    institucionNombre: _instNombre,
    oferta: o1,
  );
  await SolicitudesRepo.instance.responder(
    s.id,
    institucionId: _inst,
    aceptar: true,
  );
  return _Datos(res.cuenta.id, res.perfil, o1, o2);
}

Evento _evento(
  String titulo, {
  required DateTime inicio,
  DateTime? fin,
  bool todoElDia = false,
  bool confirma = false,
  TipoEvento tipo = TipoEvento.reunion,
  List<String> ofertaIds = const [],
}) => Evento(
  id: '',
  institucionId: _inst,
  institucionNombre: _instNombre,
  tipo: tipo,
  titulo: titulo,
  descripcion: 'Traer el cuaderno de comunicaciones firmado.',
  lugar: 'Salón de actos',
  inicio: inicio,
  fin: fin,
  todoElDia: todoElDia,
  ofertaIds: ofertaIds,
  pideConfirmacion: confirma,
  creadoEl: DateTime.now(),
);

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
  await tester.pumpAndSettle();
}

/// Deja pasar el tiempo real para que corran las escrituras y la recarga.
Future<void> _esperar(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// Desplaza la lista vertical visible hasta que aparezca [finder].
Future<void> _bajarHasta(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    final listas = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.drag(listas.last, const Offset(0, -220), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  // Sin foco ni mensajes flotantes que tapen o muevan lo que se va a tocar.
  FocusManager.instance.primaryFocus?.unfocus();
  for (final m in tester.stateList<ScaffoldMessengerState>(
    find.byType(ScaffoldMessenger),
  )) {
    m.clearSnackBars();
  }
  await tester.pumpAndSettle();
  await _bajarHasta(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Vuelve atrás como lo haría el sistema (respeta las confirmaciones).
Future<void> _volver(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Falla mostrando qué fila o columna se desbordó.
void _sinErrores(WidgetTester tester) {
  final error = tester.takeException();
  if (error == null) return;
  final detalle = StringBuffer('$error\n');
  for (final r in tester.allRenderObjects.whereType<RenderFlex>()) {
    if (!r.toStringShort().contains('OVERFLOWING')) continue;
    final creador = r.debugCreator;
    detalle.writeln(
      creador is DebugCreator
          ? creador.element.debugGetCreatorChain(14)
          : r.toStringShort(),
    );
  }
  fail(detalle.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  group('Comunicaciones', () {
    testWidgets('vacío: calendario y avisos', (tester) async {
      await _abrir(
        tester,
        const ComunicacionesPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
        ),
      );
      expect(find.text('No hay eventos próximos'), findsOneWidget);
      expect(find.text('Nuevo evento'), findsNWidgets(2));

      await tester.tap(find.text('Pasados (0)'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay eventos pasados'), findsOneWidget);

      await tester.tap(find.text('Avisos'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no enviaste avisos'), findsOneWidget);
      expect(find.text('Nuevo aviso'), findsNWidgets(2));

      // Sin alumnos confirmados no se puede enviar.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Todavía no hay alumnos'), findsOneWidget);
      final enviar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Enviar aviso'),
      );
      expect(enviar.onPressed, isNull);
      _sinErrores(tester);
    });

    testWidgets('alta de evento desde el formulario', (tester) async {
      final d = (await tester.runAsync(_preparar))!;
      await _abrir(
        tester,
        const ComunicacionesPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Tipo de evento'), findsOneWidget);
      expect(find.text('Se avisará a 1 alumno'), findsOneWidget);

      // Sin datos: valida título y fecha.
      await _tocar(tester, find.text('Publicar evento'));
      expect(find.text('Campo obligatorio.'), findsOneWidget);
      expect(find.text('Elegí la fecha.'), findsOneWidget);

      await tester.ensureVisible(find.text('Reunión'));
      await tester.tap(find.text('Reunión'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Reunión de familias',
      );
      await _tocar(tester, find.widgetWithText(TextFormField, 'Fecha'));
      final loc = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.text(loc.okButtonLabel));
      await tester.pumpAndSettle();

      // Con horario.
      await _tocar(tester, find.text('Todo el día'));
      await _tocar(
        tester,
        find.widgetWithText(TextFormField, 'Hora de inicio'),
      );
      await tester.tap(find.text(loc.okButtonLabel));
      await tester.pumpAndSettle();

      // Destinatarios por curso: el curso vacío no avisa a nadie.
      await _tocar(tester, find.text('Cursos o grupos'));
      expect(find.text('Se avisará a 1 alumno'), findsNothing);
      await _tocar(tester, find.text('2° grado · A'));
      await _esperar(tester);
      expect(find.textContaining('Todavía no hay alumnos'), findsOneWidget);
      await _tocar(tester, find.text('1° grado · A'));
      await _esperar(tester);
      expect(find.text('Se avisará a 1 alumno'), findsOneWidget);

      await _tocar(tester, find.text('Pedir confirmación de asistencia'));
      await _tocar(tester, find.text('Publicar evento'));
      await _esperar(tester);

      expect(find.text('Reunión de familias'), findsOneWidget);
      expect(find.text('Próximos (1)'), findsOneWidget);
      expect(find.text('Sin respuestas todavía'), findsOneWidget);
      expect(find.text('1° grado · A, 2° grado · A'), findsOneWidget);

      final eventos = (await tester.runAsync(
        () => CalendarioRepo.instance.eventosInstitucion(_inst),
      ))!;
      expect(eventos, hasLength(1));
      expect(eventos.single.pideConfirmacion, isTrue);
      expect(eventos.single.todoElDia, isFalse);
      expect(eventos.single.inicio.hour, 9);
      expect(eventos.single.ofertaIds, [d.oferta1.id, d.oferta2.id]);
      final notis = (await tester.runAsync(
        () => NotificacionesRepo.instance.listar(d.cuentaId),
      ))!;
      expect(
        notis.where((n) => n.tipo == TipoNotificacion.eventoPublicado),
        hasLength(1),
      );
      _sinErrores(tester);
    });

    testWidgets('detalle con respuestas, edición y baja', (tester) async {
      final hoy = DateTime.now();
      late String eventoId;
      final d = (await tester.runAsync(() async {
        final d = await _preparar();
        final cal = CalendarioRepo.instance;
        final e = await cal.guardarEvento(
          _evento(
            'Acto del 25 de Mayo',
            inicio: DateTime(hoy.year, hoy.month, hoy.day + 2, 10),
            confirma: true,
            tipo: TipoEvento.acto,
          ),
        );
        eventoId = e.id;
        await cal.responder(
          evento: e,
          perfilId: d.perfil.id,
          alumnoNombre: 'Lucía Gómez',
          asistencia: Asistencia.asistire,
        );
        await cal.guardarEvento(
          _evento(
            'Vacaciones de invierno',
            inicio: DateTime(hoy.year, hoy.month, hoy.day - 3),
            fin: DateTime(hoy.year, hoy.month, hoy.day + 6),
            todoElDia: true,
            tipo: TipoEvento.vacaciones,
          ),
        );
        await cal.guardarEvento(
          _evento(
            'Reunión pasada',
            inicio: DateTime(hoy.year, hoy.month, hoy.day - 20, 18),
          ),
        );
        return d;
      }))!;

      await _abrir(
        tester,
        ComunicacionesPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
          initialEventoId: eventoId,
        ),
      );

      // Se abre el detalle pedido, con la respuesta de la familia.
      expect(find.text('Detalle del evento'), findsOneWidget);
      expect(find.text('Acto del 25 de Mayo'), findsOneWidget);
      await _bajarHasta(tester, find.text('Lucía Gómez'));
      expect(find.text('Lucía Gómez'), findsOneWidget);
      expect(find.text('Asistiré'), findsOneWidget);

      // Editar: cambia el título sin volver a notificar.
      await tester.tap(find.byTooltip('Editar evento'));
      await tester.pumpAndSettle();
      expect(
        find.text('Los cambios se guardan sin enviar una notificación nueva.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Acto patrio',
      );
      await _tocar(tester, find.text('Guardar cambios'));
      await _esperar(tester);
      expect(find.text('Detalle del evento'), findsOneWidget);
      final editado = await tester.runAsync(
        () => CalendarioRepo.instance.evento(_inst, eventoId),
      );
      expect(editado?.titulo, 'Acto patrio');
      final notis = (await tester.runAsync(
        () => NotificacionesRepo.instance.listar(d.cuentaId),
      ))!;
      expect(
        notis.where((n) => n.tipo == TipoNotificacion.eventoPublicado),
        hasLength(3),
      );

      // La familia elimina su cuenta: la respuesta desaparece sin romper nada.
      await tester.runAsync(
        () => BajasRepo.instance.eliminarFamilia(d.cuentaId),
      );
      await _esperar(tester);
      expect(find.text('Lucía Gómez'), findsNothing);
      await _bajarHasta(tester, find.textContaining('Todavía nadie respondió'));
      expect(find.textContaining('Todavía nadie respondió'), findsOneWidget);
      _sinErrores(tester);

      // Eliminar el evento.
      await tester.tap(find.byTooltip('Eliminar evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pump();
      await _esperar(tester);
      expect(find.text('Detalle del evento'), findsNothing);
      expect(find.text('Acto patrio'), findsNothing);
      expect(find.text('Vacaciones de invierno'), findsOneWidget);
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('Pasados (1)'), findsOneWidget);
      _sinErrores(tester);
    });

    testWidgets('envío de un aviso', (tester) async {
      final d = (await tester.runAsync(_preparar))!;
      await _abrir(
        tester,
        const ComunicacionesPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
        ),
      );
      await tester.tap(find.text('Avisos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Llegará a 1 alumno'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Cambio de horario',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mensaje'),
        'Mañana salimos a las 12:00.',
      );
      await tester.pumpAndSettle();
      await _tocar(tester, find.widgetWithText(FilledButton, 'Enviar aviso'));
      expect(find.text('¿Enviar a 1 alumno?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar aviso').last);
      await tester.pump();
      await _esperar(tester);

      expect(find.text('Aviso enviado a 1 alumno.'), findsOneWidget);
      expect(find.text('Cambio de horario'), findsOneWidget);
      expect(find.text('Llegó a 1 alumno'), findsOneWidget);
      final notis = (await tester.runAsync(
        () => NotificacionesRepo.instance.listar(d.cuentaId),
      ))!;
      expect(
        notis.where((n) => n.tipo == TipoNotificacion.aviso),
        hasLength(1),
      );

      // Aviso completo.
      await tester.tap(find.text('Cambio de horario'));
      await tester.pumpAndSettle();
      expect(find.text('Mañana salimos a las 12:00.'), findsNWidgets(2));
      _sinErrores(tester);
    });

    for (final (nombre, size, locale, mode) in [
      (
        'teléfono angosto en',
        const Size(360, 640),
        const Locale('en'),
        ThemeMode.light,
      ),
      (
        'teléfono pt oscuro',
        const Size(360, 780),
        const Locale('pt'),
        ThemeMode.dark,
      ),
      (
        'escritorio es',
        const Size(1366, 768),
        const Locale('es'),
        ThemeMode.light,
      ),
      (
        'tablet es oscuro',
        const Size(900, 700),
        const Locale('es'),
        ThemeMode.dark,
      ),
    ]) {
      testWidgets('se acomoda: $nombre', (tester) async {
        final hoy = DateTime.now();
        await tester.runAsync(() async {
          final d = await _preparar();
          final cal = CalendarioRepo.instance;
          for (final tipo in TipoEvento.values) {
            final e = await cal.guardarEvento(
              _evento(
                'Evento ${tipo.name} con un título bastante largo para probar',
                inicio: DateTime(hoy.year, hoy.month, hoy.day + tipo.index, 8),
                fin: tipo.index.isOdd
                    ? DateTime(hoy.year, hoy.month, hoy.day + tipo.index + 9)
                    : null,
                todoElDia: tipo.index.isOdd,
                confirma: tipo.index.isEven,
                tipo: tipo,
                ofertaIds: tipo.index % 3 == 0
                    ? const []
                    : [d.oferta1.id, d.oferta2.id, 'OF_borrada'],
              ),
            );
            if (tipo.index == 0) {
              await cal.responder(
                evento: e,
                perfilId: d.perfil.id,
                alumnoNombre:
                    'María de los Ángeles Fernández de la Torre Etchegaray',
                asistencia: Asistencia.noAsistire,
              );
            }
          }
          await cal.enviarAviso(
            institucionId: _inst,
            institucionNombre: _instNombre,
            titulo: 'Aviso con un título largo para ver cómo corta el texto',
            mensaje: 'Mensaje largo. ' * 30,
            ofertaIds: [d.oferta1.id, d.oferta2.id],
          );
        });

        await _abrir(
          tester,
          const ComunicacionesPage(
            institucionId: _inst,
            institucionNombre: _instNombre,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(FloatingActionButton), findsOneWidget);
        _sinErrores(tester);

        // Detalle del primer evento (con una respuesta de nombre largo).
        await tester.tap(find.textContaining('Evento general').first);
        await tester.pumpAndSettle();
        _sinErrores(tester);
        await _volver(tester);

        // Formulario de evento con la selección por cursos abierta.
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        _sinErrores(tester);
        await _tocar(tester, find.byIcon(Icons.checklist_rounded));
        _sinErrores(tester);
        await _volver(tester);
        // Hay cambios sin guardar: pide confirmar.
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();

        // Avisos y hoja de aviso nuevo.
        await tester.tap(find.byIcon(Icons.campaign_rounded).first);
        await tester.pumpAndSettle();
        _sinErrores(tester);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await _tocar(tester, find.byIcon(Icons.checklist_rounded));
        _sinErrores(tester);
      });
    }
  });

  group('Documentación', () {
    testWidgets('sin alumnos: explica por qué no se puede pedir', (
      tester,
    ) async {
      await _abrir(
        tester,
        const DocumentosInstitucionPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
        ),
      );
      expect(find.text('No hay documentos para revisar'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no tenés alumnos'), findsOneWidget);
      _sinErrores(tester);
    });

    testWidgets('pedir, revisar, corregir, aprobar y cancelar', (tester) async {
      final d = (await tester.runAsync(_preparar))!;
      await _abrir(
        tester,
        const DocumentosInstitucionPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
        ),
      );

      // Pedir un documento.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('¿A qué alumno?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'gomez');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gómez, Lucía'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué documento necesitás?'), findsOneWidget);

      await _tocar(tester, find.text('Pedir documento').last);
      expect(find.text('Elegí qué documento necesitás.'), findsOneWidget);
      await _tocar(tester, find.text('Otro documento'));
      await _tocar(tester, find.text('Pedir documento').last);
      expect(find.text('Campo obligatorio.'), findsOneWidget);
      await _tocar(tester, find.text('Certificado médico'));
      await _tocar(tester, find.text('Pedir documento').last);
      await _esperar(tester);

      expect(find.textContaining('Pedido enviado'), findsOneWidget);
      expect(find.text('Certificado médico'), findsOneWidget);
      expect(find.text('Por entregar'), findsOneWidget);
      var pedidos = (await tester.runAsync(
        () => DocumentosRepo.instance.porInstitucion(_inst),
      ))!;
      expect(pedidos, hasLength(1));
      final pedidoId = pedidos.single.id;

      // La familia entrega: pasa sola a "Para revisar".
      await tester.runAsync(
        () => DocumentosRepo.instance.entregar(
          pedidoId: pedidoId,
          perfilId: d.perfil.id,
          nombreArchivo: 'certificado.png',
          bytes: base64Decode(_png1x1),
        ),
      );
      await _esperar(tester);
      await _tocar(tester, find.text('Para revisar'));
      expect(find.text('En revisión'), findsOneWidget);

      // Detalle: pedir corrección exige motivo.
      await tester.tap(find.text('Certificado médico'));
      await tester.pumpAndSettle();
      await _esperar(tester);
      await _bajarHasta(tester, find.text('Ver archivo'));
      expect(find.text('Archivo entregado'), findsOneWidget);
      expect(find.text('certificado.png'), findsOneWidget);
      expect(find.text('Ver archivo'), findsOneWidget);
      await _tocar(tester, find.text('Pedir corrección'));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Pedir corrección').last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Contanos qué hay que corregir.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motivo'),
        'La foto está borrosa.',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Pedir corrección').last,
      );
      await tester.pump();
      await _esperar(tester);
      expect(
        find.text('Le pedimos la corrección a la familia.'),
        findsOneWidget,
      );
      pedidos = (await tester.runAsync(
        () => DocumentosRepo.instance.porInstitucion(_inst),
      ))!;
      expect(pedidos.single.estado, EstadoPedidoDocumento.rechazado);
      expect(pedidos.single.observacion, 'La foto está borrosa.');

      // Vuelve a entregar y se aprueba.
      await tester.runAsync(
        () => DocumentosRepo.instance.entregar(
          pedidoId: pedidoId,
          perfilId: d.perfil.id,
          nombreArchivo: 'certificado-2.png',
          bytes: base64Decode(_png1x1),
        ),
      );
      await _esperar(tester);
      await tester.tap(find.text('Certificado médico'));
      await tester.pumpAndSettle();
      await _esperar(tester);
      await _tocar(tester, find.text('Aprobar'));
      expect(find.text('¿Aprobar el documento?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar').last);
      await tester.pump();
      await _esperar(tester);
      expect(find.text('Documento aprobado.'), findsOneWidget);
      pedidos = (await tester.runAsync(
        () => DocumentosRepo.instance.porInstitucion(_inst),
      ))!;
      expect(pedidos.single.estado, EstadoPedidoDocumento.aprobado);

      // Otro pedido, que se cancela.
      await tester.runAsync(
        () => DocumentosRepo.instance.solicitar(
          institucionId: _inst,
          institucionNombre: _instNombre,
          cuentaId: d.cuentaId,
          perfilId: d.perfil.id,
          alumnoNombre: 'Lucía Gómez',
          tipo: TipoDocumento.dni,
          fechaLimite: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      await _esperar(tester);
      await _tocar(tester, find.text('Pendientes'));
      expect(find.text('Vencido'), findsOneWidget);
      await tester.tap(find.text('DNI del alumno'));
      await tester.pumpAndSettle();
      await _esperar(tester);
      await _tocar(tester, find.text('Cancelar pedido'));
      expect(find.text('¿Cancelar este pedido?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar pedido'));
      await tester.pump();
      await _esperar(tester);
      expect(find.text('Pedido cancelado.'), findsOneWidget);
      expect(find.text('No hay pedidos pendientes'), findsOneWidget);
      _sinErrores(tester);
    });

    testWidgets('abre el pedido inicial y tolera la baja de la familia', (
      tester,
    ) async {
      late String pedidoId;
      final d = (await tester.runAsync(() async {
        final d = await _preparar();
        final docs = DocumentosRepo.instance;
        final p = await docs.solicitar(
          institucionId: _inst,
          institucionNombre: _instNombre,
          cuentaId: d.cuentaId,
          perfilId: d.perfil.id,
          alumnoNombre: 'Lucía Gómez',
          tipo: TipoDocumento.otro,
          detalle: 'Autorización para salidas educativas',
        );
        await docs.entregar(
          pedidoId: p.id,
          perfilId: d.perfil.id,
          nombreArchivo: 'autorizacion.pdf',
          bytes: base64Decode(_png1x1),
        );
        await docs.revisar(
          pedidoId: p.id,
          institucionId: _inst,
          aprobado: true,
        );
        pedidoId = p.id;
        return d;
      }))!;

      await _abrir(
        tester,
        DocumentosInstitucionPage(
          institucionId: _inst,
          institucionNombre: _instNombre,
          initialPedidoId: pedidoId,
        ),
      );
      await _esperar(tester);
      expect(find.text('Pedido de documento'), findsOneWidget);
      expect(find.text('autorizacion.pdf'), findsOneWidget);
      expect(find.text('Aprobado'), findsWidgets);

      // "Ver archivo" de un PDF no rompe aunque el visor falle.
      await _tocar(tester, find.text('Ver archivo'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => BajasRepo.instance.eliminarFamilia(d.cuentaId),
      );
      await _esperar(tester);
      expect(find.text('Este pedido ya no está disponible'), findsOneWidget);
      _sinErrores(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Volver'));
      await tester.pumpAndSettle();
      await _esperar(tester);
      // Quedó seleccionada la bandeja del pedido, ya sin pedidos.
      expect(find.text('Todavía no aprobaste documentos'), findsOneWidget);
      _sinErrores(tester);
    });

    for (final (nombre, size, locale, mode) in [
      (
        'teléfono angosto en',
        const Size(360, 640),
        const Locale('en'),
        ThemeMode.light,
      ),
      (
        'teléfono pt oscuro',
        const Size(360, 780),
        const Locale('pt'),
        ThemeMode.dark,
      ),
      (
        'escritorio es',
        const Size(1366, 768),
        const Locale('es'),
        ThemeMode.light,
      ),
      (
        'tablet es oscuro',
        const Size(900, 700),
        const Locale('es'),
        ThemeMode.dark,
      ),
    ]) {
      testWidgets('se acomoda: $nombre', (tester) async {
        await tester.runAsync(() async {
          final d = await _preparar();
          final docs = DocumentosRepo.instance;
          final hoy = DateTime.now();
          Future<PedidoDocumento> pedir(
            TipoDocumento tipo, {
            String detalle = '',
            DateTime? limite,
          }) => docs.solicitar(
            institucionId: _inst,
            institucionNombre: _instNombre,
            cuentaId: d.cuentaId,
            perfilId: d.perfil.id,
            alumnoNombre:
                'María de los Ángeles Fernández de la Torre Etchegaray',
            tipo: tipo,
            detalle: detalle,
            fechaLimite: limite,
          );
          final bytes = base64Decode(_png1x1);
          await pedir(
            TipoDocumento.dniResponsable,
            detalle: 'Fotocopia de ambos lados, legible y sin recortes.',
            limite: DateTime(hoy.year, hoy.month, hoy.day - 2),
          );
          final rechazado = await pedir(TipoDocumento.carnetVacunas);
          await docs.entregar(
            pedidoId: rechazado.id,
            perfilId: d.perfil.id,
            nombreArchivo: 'vacunas.png',
            bytes: bytes,
          );
          await docs.revisar(
            pedidoId: rechazado.id,
            institucionId: _inst,
            aprobado: false,
            observacion: 'La foto está borrosa, por favor volvé a subirla.',
          );
          final entregado = await pedir(
            TipoDocumento.otro,
            detalle:
                'Autorización para salidas educativas y actividades fuera del establecimiento',
            limite: DateTime(hoy.year, hoy.month, hoy.day + 5),
          );
          await docs.entregar(
            pedidoId: entregado.id,
            perfilId: d.perfil.id,
            nombreArchivo:
                'autorizacion-salidas-educativas-firmada-por-ambos-padres.png',
            bytes: bytes,
          );
        });

        await _abrir(
          tester,
          const DocumentosInstitucionPage(
            institucionId: _inst,
            institucionNombre: _instNombre,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(DocumentosInstitucionPage), findsOneWidget);
        _sinErrores(tester);

        // Detalle del entregado (imagen) y visor.
        await tester.tap(find.textContaining('Autorización').first);
        await tester.pumpAndSettle();
        await _esperar(tester);
        _sinErrores(tester);
        await _tocar(tester, find.byIcon(Icons.visibility_rounded));
        _sinErrores(tester);
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        await _tocar(tester, find.byIcon(Icons.edit_note_rounded));
        _sinErrores(tester);
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();
        await _volver(tester);

        // Pendientes (vencido + para corregir) y hoja de pedido.
        await _tocar(tester, find.byType(Tab).at(1));
        _sinErrores(tester);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        _sinErrores(tester);
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        _sinErrores(tester);
      });
    }
  });
}
