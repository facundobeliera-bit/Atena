// test/pantallas_alumno_calendario_documentos_ficha_test.dart
//
// Pantallas del alumno: calendario, documentos y ficha.

import 'dart:convert';

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/core/repos/bajas_repo.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/screens/alumno/alumno_ficha_page.dart';
import 'package:atena_app/screens/alumnos/alumno_calendario_page.dart';
import 'package:atena_app/screens/alumnos/alumno_documentos_page.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const _institucion =
    'Instituto Superior de Formación Integral San Martín de los Andes';

class _Familia {
  final String cuentaId;
  final PerfilAlumno perfil;
  _Familia(this.cuentaId, this.perfil);
}

Future<_Familia> _registrar() async {
  final res = await AuthService.registrarFamilia(
    email: 'familia@mail.com',
    password: 'clave1234',
    remember: true,
    nombre: 'Lucía',
    apellido: 'Gómez',
    dni: '45123456',
    fechaNacimiento: DateTime(2015, 1, 1),
  );
  return _Familia(res.cuenta.id, res.perfil);
}

Future<void> _confirmarVacante(_Familia f) async {
  final oferta = await OfertasRepo.instance.guardar(ofertaDemo(cupo: 5));
  final s = await SolicitudesRepo.instance.crear(
    alumno: AlumnosRepo.instance.snapshot(f.cuentaId, f.perfil),
    institucionNombre: _institucion,
    oferta: oferta,
  );
  await SolicitudesRepo.instance.responder(
    s.id,
    institucionId: 'INST_1',
    aceptar: true,
  );
}

Evento _evento(
  String titulo, {
  required DateTime inicio,
  DateTime? fin,
  bool todoElDia = false,
  bool confirma = false,
  TipoEvento tipo = TipoEvento.reunion,
}) => Evento(
  id: '',
  institucionId: 'INST_1',
  institucionNombre: _institucion,
  tipo: tipo,
  titulo: titulo,
  descripcion: 'Traer el cuaderno de comunicaciones firmado.',
  lugar: 'Salón de actos',
  inicio: inicio,
  fin: fin,
  todoElDia: todoElDia,
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

/// Deja pasar el tiempo (real y simulado) para que corra la recarga diferida.
Future<void> _esperarRecarga(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// Espera a que se vaya el aviso (snackbar) visible.
Future<void> _sinAviso(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _hasta(WidgetTester tester, Finder finder, {double paso = 250}) {
  return tester.scrollUntilVisible(
    finder,
    paso,
    scrollable: find.byType(Scrollable).first,
  );
}

const _tamanos = [
  ('teléfono angosto en', Size(360, 640), Locale('en'), ThemeMode.light),
  ('teléfono pt oscuro', Size(360, 780), Locale('pt'), ThemeMode.dark),
  ('teléfono es', Size(390, 844), Locale('es'), ThemeMode.light),
  ('tablet es oscuro', Size(900, 700), Locale('es'), ThemeMode.dark),
  ('escritorio es', Size(1366, 768), Locale('es'), ThemeMode.light),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  group('Calendario', () {
    testWidgets('vacío, nota nueva y baja de la nota', (tester) async {
      final f = (await tester.runAsync(_registrar))!;
      await _abrir(
        tester,
        AlumnoCalendarioPage(ownerAccountId: f.cuentaId, perfilId: f.perfil.id),
      );
      expect(find.text('Tu calendario está listo'), findsOneWidget);
      expect(find.text('Lucía Gómez'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Nueva nota'), findsWidgets);

      // Sin título no guarda.
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Campo obligatorio.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Llevar la autorización',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pump();
      await _esperarRecarga(tester);

      expect(find.text('Nota guardada.'), findsOneWidget);
      expect(find.text('Llevar la autorización'), findsOneWidget);
      expect(find.text('Nota personal'), findsOneWidget);
      final notas = (await tester.runAsync(
        () => CalendarioRepo.instance.notas(f.perfil.id),
      ))!;
      expect(notas, hasLength(1));
      await _sinAviso(tester);

      // Navegación de meses y volver a hoy.
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Llevar la autorización'), findsNothing);
      expect(find.text('Próximos'), findsNothing);
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      await _hasta(tester, find.text('Próximos'));
      await tester.pumpAndSettle();
      expect(find.text('Llevar la autorización'), findsOneWidget);
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('Próximos'), findsNothing);
      expect(find.text('Llevar la autorización'), findsOneWidget);

      // Editar: la hoja se abre con los datos de la nota.
      await tester.tap(find.text('Llevar la autorización'));
      await tester.pumpAndSettle();
      expect(find.text('Editar nota'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Llevar la autorización firmada',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.text('Llevar la autorización firmada'), findsOneWidget);
      await _sinAviso(tester);

      // Eliminar desde el menú de la nota.
      await tester.tap(find.byTooltip('Más opciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar nota'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.text('Llevar la autorización firmada'), findsNothing);
      expect(find.text('Tu calendario está listo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('evento con asistencia y baja de la institución', (
      tester,
    ) async {
      final hoy = DateTime.now();
      late String eventoId;
      final f = (await tester.runAsync(() async {
        final f = await _registrar();
        await _confirmarVacante(f);
        final cal = CalendarioRepo.instance;
        final e = await cal.guardarEvento(
          _evento(
            'Reunión de padres y madres de primer grado del turno mañana',
            inicio: DateTime(hoy.year, hoy.month, hoy.day, 18),
            fin: DateTime(hoy.year, hoy.month, hoy.day, 19, 30),
            confirma: true,
          ),
        );
        eventoId = e.id;
        await cal.guardarEvento(
          _evento(
            'Vacaciones de invierno',
            inicio: DateTime(hoy.year, hoy.month, hoy.day + 3),
            fin: DateTime(hoy.year, hoy.month, hoy.day + 12),
            todoElDia: true,
            tipo: TipoEvento.vacaciones,
          ),
        );
        return f;
      }))!;

      await _abrir(
        tester,
        AlumnoCalendarioPage(
          ownerAccountId: f.cuentaId,
          perfilId: f.perfil.id,
          initialItemId: eventoId,
        ),
      );

      // Se abre el detalle del evento pedido.
      expect(find.text('¿Vas a asistir?'), findsOneWidget);
      expect(find.text('Salón de actos'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Asistiré'));
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.text('¿Vas a asistir?'), findsNothing);
      expect(find.text('Respuesta enviada: Asistiré.'), findsOneWidget);
      await _hasta(tester, find.text('Asistiré'));
      expect(tester.takeException(), isNull);

      final r = await tester.runAsync(
        () => CalendarioRepo.instance.miRespuesta(
          'INST_1',
          eventoId,
          f.perfil.id,
        ),
      );
      expect(r?.asistencia, Asistencia.asistire);
      await _sinAviso(tester);

      // La institución se da de baja: sus eventos desaparecen sin romper nada.
      await tester.runAsync(
        () => BajasRepo.instance.eliminarInstitucion(
          institucionId: 'INST_1',
          ownerAccountId: '',
        ),
      );
      await _esperarRecarga(tester);
      expect(find.textContaining('Reunión de padres'), findsNothing);
      expect(find.text('Tu calendario está listo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('evento eliminado con el detalle abierto', (tester) async {
      final hoy = DateTime.now();
      late String eventoId;
      final f = (await tester.runAsync(() async {
        final f = await _registrar();
        await _confirmarVacante(f);
        final e = await CalendarioRepo.instance.guardarEvento(
          _evento(
            'Acto de fin de año',
            inicio: DateTime(hoy.year, hoy.month, hoy.day, 18),
            confirma: true,
            tipo: TipoEvento.acto,
          ),
        );
        eventoId = e.id;
        return f;
      }))!;
      await _abrir(
        tester,
        AlumnoCalendarioPage(ownerAccountId: f.cuentaId, perfilId: f.perfil.id),
      );
      await _hasta(tester, find.text('Acto de fin de año'));
      await tester.tap(find.text('Acto de fin de año'));
      await tester.pumpAndSettle();
      expect(find.text('¿Vas a asistir?'), findsOneWidget);

      await tester.runAsync(
        () => CalendarioRepo.instance.eliminarEvento('INST_1', eventoId),
      );
      await _esperarRecarga(tester);
      await tester.tap(find.text('Tal vez'));
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.text('Este evento ya no está disponible.'), findsOneWidget);
      final r = await tester.runAsync(
        () => CalendarioRepo.instance.miRespuesta(
          'INST_1',
          eventoId,
          f.perfil.id,
        ),
      );
      expect(r, isNull);
      expect(tester.takeException(), isNull);
    });

    for (final (nombre, size, locale, mode) in _tamanos) {
      testWidgets('se acomoda: $nombre', (tester) async {
        final hoy = DateTime.now();
        final f = (await tester.runAsync(() async {
          final f = await _registrar();
          await _confirmarVacante(f);
          final cal = CalendarioRepo.instance;
          for (final tipo in TipoEvento.values) {
            await cal.guardarEvento(
              _evento(
                'Evento ${tipo.name} con un título bastante largo para probar',
                inicio: DateTime(hoy.year, hoy.month, hoy.day, 8 + tipo.index),
                confirma: tipo.index.isEven,
                tipo: tipo,
              ),
            );
          }
          await cal.guardarNota(
            NotaPersonal(
              id: '',
              perfilId: f.perfil.id,
              titulo: 'Comprar los útiles para la clase de plástica del lunes',
              detalle: 'Témperas, pinceles, hojas canson y un delantal viejo.',
              fecha: DateTime(hoy.year, hoy.month, hoy.day),
              hora: '17:30',
            ),
          );
          return f;
        }))!;

        await _abrir(
          tester,
          AlumnoCalendarioPage(
            ownerAccountId: f.cuentaId,
            perfilId: f.perfil.id,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Recorre toda la agenda.
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(Scrollable).last, const Offset(0, 3000));
        await tester.pumpAndSettle();

        // Detalle de un evento.
        final evento = find.textContaining('Evento general');
        await tester.scrollUntilVisible(
          evento,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(evento);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        // Hoja de nota nueva.
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Documentos', () {
    Future<_Familia> preparar() async {
      final f = await _registrar();
      final docs = DocumentosRepo.instance;
      final hoy = DateTime.now();
      Future<PedidoDocumento> pedir(
        TipoDocumento tipo, {
        String detalle = '',
        DateTime? limite,
      }) => docs.solicitar(
        institucionId: 'INST_1',
        institucionNombre: _institucion,
        cuentaId: f.cuentaId,
        perfilId: f.perfil.id,
        alumnoNombre: f.perfil.displayName,
        tipo: tipo,
        detalle: detalle,
        fechaLimite: limite,
      );
      final bytes = base64Decode(_png1x1);

      await pedir(
        TipoDocumento.dni,
        detalle: 'Fotocopia de ambos lados, legible y sin recortes.',
        limite: DateTime(hoy.year, hoy.month, hoy.day - 2),
      );
      await pedir(
        TipoDocumento.certificadoMedico,
        limite: DateTime(hoy.year, hoy.month, hoy.day + 1),
      );
      final rechazado = await pedir(TipoDocumento.carnetVacunas);
      await docs.entregar(
        pedidoId: rechazado.id,
        perfilId: f.perfil.id,
        nombreArchivo: 'vacunas.png',
        bytes: bytes,
      );
      await docs.revisar(
        pedidoId: rechazado.id,
        institucionId: 'INST_1',
        aprobado: false,
        observacion: 'La foto está borrosa, por favor volvé a subirla.',
      );
      final entregado = await pedir(TipoDocumento.foto);
      await docs.entregar(
        pedidoId: entregado.id,
        perfilId: f.perfil.id,
        nombreArchivo: 'foto-carnet.png',
        bytes: bytes,
      );
      final aprobado = await pedir(
        TipoDocumento.otro,
        detalle: 'Autorización para salidas educativas',
      );
      await docs.entregar(
        pedidoId: aprobado.id,
        perfilId: f.perfil.id,
        nombreArchivo: 'autorizacion.pdf',
        bytes: bytes,
      );
      await docs.revisar(
        pedidoId: aprobado.id,
        institucionId: 'INST_1',
        aprobado: true,
      );
      final cancelado = await pedir(TipoDocumento.boletin);
      await docs.cancelar(pedidoId: cancelado.id, institucionId: 'INST_1');
      return f;
    }

    testWidgets('vacío', (tester) async {
      final f = (await tester.runAsync(_registrar))!;
      await _abrir(
        tester,
        AlumnoDocumentosPage(ownerAccountId: f.cuentaId, perfilId: f.perfil.id),
      );
      expect(find.text('No tenés documentos pendientes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('secciones, detalle, visor y baja de la institución', (
      tester,
    ) async {
      final f = (await tester.runAsync(preparar))!;
      await _abrir(
        tester,
        AlumnoDocumentosPage(ownerAccountId: f.cuentaId, perfilId: f.perfil.id),
      );
      expect(find.text('Tenés 3 documentos para entregar'), findsOneWidget);
      expect(find.text('Para entregar'), findsWidgets);
      expect(find.text('Vencido'), findsOneWidget);
      expect(find.text('DNI del alumno'), findsOneWidget);
      await _hasta(tester, find.text('Vence mañana'));
      await _hasta(tester, find.text('Motivo'));
      expect(
        find.text('La foto está borrosa, por favor volvé a subirla.'),
        findsOneWidget,
      );
      await _hasta(tester, find.text('Foto carnet'));
      await _hasta(tester, find.text('Autorización para salidas educativas'));
      await _hasta(tester, find.text('Historial (1)'));
      await tester.tap(find.text('Historial (1)'));
      await tester.pumpAndSettle();
      await _hasta(tester, find.text('Boletín de calificaciones'));
      expect(tester.takeException(), isNull);

      // Detalle del pedido aprobado.
      final aprobado = find.text('Autorización para salidas educativas');
      await _hasta(tester, aprobado, paso: -200);
      await tester.tap(aprobado);
      await tester.pumpAndSettle();
      expect(find.text('Fecha del pedido'), findsOneWidget);
      expect(find.text('Archivo entregado'), findsOneWidget);
      expect(find.text('autorizacion.pdf'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
      await tester.pumpAndSettle();

      // Visor de la imagen entregada (pedido en revisión).
      final foto = find.text('Foto carnet');
      await _hasta(tester, foto, paso: -200);
      final ver = find.descendant(
        of: find.ancestor(of: foto, matching: find.byType(AtenaCard)),
        matching: find.text('Ver archivo'),
      );
      await tester.ensureVisible(ver);
      await tester.pumpAndSettle();
      await tester.tap(ver);
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('foto-carnet.png'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(tester.takeException(), isNull);

      // Una entrega hecha en otro lado se refleja sola.
      final pedidos = (await tester.runAsync(
        () => DocumentosRepo.instance.porPerfil(f.perfil.id),
      ))!;
      final pendiente = pedidos.firstWhere(
        (p) => p.tipo == TipoDocumento.certificadoMedico,
      );
      await tester.runAsync(
        () => DocumentosRepo.instance.entregar(
          pedidoId: pendiente.id,
          perfilId: f.perfil.id,
          nombreArchivo: 'certificado.png',
          bytes: base64Decode(_png1x1),
        ),
      );
      await _esperarRecarga(tester);
      await _hasta(
        tester,
        find.text('Tenés 2 documentos para entregar'),
        paso: -250,
      );

      // Baja de la institución: los pedidos desaparecen.
      await tester.runAsync(
        () => BajasRepo.instance.eliminarInstitucion(
          institucionId: 'INST_1',
          ownerAccountId: '',
        ),
      );
      await _esperarRecarga(tester);
      expect(find.text('No tenés documentos pendientes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (nombre, size, locale, mode) in _tamanos) {
      testWidgets('se acomoda: $nombre', (tester) async {
        late String pedidoId;
        final f = (await tester.runAsync(() async {
          final f = await preparar();
          final pedidos = await DocumentosRepo.instance.porPerfil(f.perfil.id);
          pedidoId = pedidos
              .firstWhere((p) => p.estado == EstadoPedidoDocumento.rechazado)
              .id;
          return f;
        }))!;
        await _abrir(
          tester,
          AlumnoDocumentosPage(
            ownerAccountId: f.cuentaId,
            perfilId: f.perfil.id,
            initialDocumentoId: pedidoId,
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        // Se abre el detalle del pedido indicado.
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Ficha', () {
    for (final (nombre, size, locale, mode) in _tamanos) {
      testWidgets('datos, instituciones y PDF: $nombre', (tester) async {
        final f = (await tester.runAsync(() async {
          final f = await _registrar();
          await _confirmarVacante(f);
          return f;
        }))!;
        await _abrir(
          tester,
          AlumnoFichaPage(cuentaId: f.cuentaId, perfilId: f.perfil.id),
          size: size,
          locale: locale,
          mode: mode,
        );
        expect(find.text('Lucía Gómez'), findsOneWidget);
        await _hasta(tester, find.text('45.123.456'));
        await _hasta(tester, find.text(_institucion));
        expect(tester.takeException(), isNull);

        await _hasta(tester, find.byIcon(Icons.print_rounded));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // PDF: se genera o avisa el error, sin romper.
        await tester.tap(find.byIcon(Icons.print_rounded));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1500)),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sin vacantes confirmadas', (tester) async {
      final f = (await tester.runAsync(_registrar))!;
      await _abrir(
        tester,
        AlumnoFichaPage(cuentaId: f.cuentaId, perfilId: f.perfil.id),
        size: const Size(360, 640),
      );
      await _hasta(tester, find.text('Explorar instituciones'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('editar datos y baja de la institución', (tester) async {
      final f = (await tester.runAsync(() async {
        final f = await _registrar();
        await _confirmarVacante(f);
        return f;
      }))!;
      await _abrir(
        tester,
        AlumnoFichaPage(cuentaId: f.cuentaId, perfilId: f.perfil.id),
      );
      await tester.tap(find.text('Editar datos'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'),
        'Ana',
      );
      final guardar = find.widgetWithText(FilledButton, 'Guardar');
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await tester.pump();
      await _esperarRecarga(tester);
      expect(find.text('Ana Gómez'), findsOneWidget);
      await _sinAviso(tester);

      await _hasta(tester, find.text(_institucion));
      await tester.runAsync(
        () => BajasRepo.instance.eliminarInstitucion(
          institucionId: 'INST_1',
          ownerAccountId: '',
        ),
      );
      await _esperarRecarga(tester);
      expect(find.text(_institucion), findsNothing);
      await _hasta(tester, find.text('Explorar instituciones'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('perfil de otra cuenta', (tester) async {
      final f = (await tester.runAsync(_registrar))!;
      await _abrir(
        tester,
        AlumnoFichaPage(cuentaId: 'OTRA_CUENTA', perfilId: f.perfil.id),
      );
      expect(find.text('Lucía Gómez'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
