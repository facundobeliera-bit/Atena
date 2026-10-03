// test/pantallas_institucion_perfil_plan_test.dart
//
// Pantallas de la institución: plan (registro y gestión) y perfil.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/screens/instituciones/institucion_menu_page.dart';
import 'package:atena_app/screens/instituciones/institucion_perfil_page.dart';
import 'package:atena_app/screens/instituciones/institucion_plan_page.dart';
import 'package:atena_app/screens/instituciones/widgets/perf_inst_campos.dart';
import 'package:atena_app/screens/instituciones/widgets/perf_inst_completitud.dart';
import 'package:atena_app/screens/instituciones/widgets/perf_inst_fotos.dart';
import 'package:atena_app/screens/instituciones/widgets/pln_precios.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/ui/atena_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _nombreLargo =
    'Instituto Superior de Formación Integral San Martín de los Andes';

const _telefono = Size(390, 844);
const _chico = Size(360, 640);
const _escritorio = Size(1366, 768);

Widget _app(
  Widget home, {
  Locale locale = const Locale('es'),
  ThemeMode mode = ThemeMode.light,
}) {
  return MaterialApp(
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
    home: home,
  );
}

/// Abre la página encima de una base (para poder volver atrás).
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
    _app(
      const Scaffold(body: Center(child: Text('BASE'))),
      locale: locale,
      mode: mode,
    ),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(MaterialPageRoute<void>(builder: (_) => page));
  await _asentar(tester);
}

/// Deja correr el almacenamiento (tiempo real) y termina las animaciones.
Future<void> _asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pumpAndSettle();
}

Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await _asentar(tester);
}

InstitucionRegistroDraft _draft({
  TipoInstitucion tipo = TipoInstitucion.otra,
  String email = 'nueva@escuela.edu.ar',
}) {
  return InstitucionRegistroDraft(
    nombre: _nombreLargo,
    cuit: '30712345678',
    direccion: 'Av. Siempre Viva 123',
    pais: 'Argentina',
    provincia: 'Córdoba',
    ciudad: 'Córdoba',
    modalidad: ModalidadCursado.presencial,
    email: email,
    telefono: '3511234567',
    pass: 'clave-segura-1',
    tipo: tipo,
    nivelesSeleccionados: const [],
    bloquesSeleccionados: const [],
  );
}

/// Tipografías reales: con la de prueba los textos miden casi el doble.
Future<void> _cargarFuentes() async {
  Future<ByteData> leer(String ruta) async =>
      ByteData.sublistView(await File(ruta).readAsBytes());

  final jakarta = FontLoader('PlusJakartaSans');
  for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(leer('assets/fonts/PlusJakartaSans-$peso.ttf'));
  }
  await jakarta.load();

  final iconos = FontLoader('MaterialIcons')
    ..addFont(
      leer(
        'D:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await iconos.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_cargarFuentes);
  setUp(resetStorage);

  group('precios', () {
    test('subtotal, descuento por cantidad y promoción', () {
      const uno = PlnCalculo(niveles: 1, modulos: 0);
      expect(uno.total, 1000);
      expect(uno.conDescuento, isFalse);
      expect(uno.faltanParaDescuento, 2);
      expect(uno.gratis, isFalse);

      const tres = PlnCalculo(niveles: 2, modulos: 1);
      expect(tres.subtotal, 3500);
      expect(tres.descuento, 175);
      expect(tres.total, 3325);
      expect(tres.faltanParaDescuento, 0);

      const promo = PlnCalculo(niveles: 2, modulos: 1, promo: true);
      expect(promo.descuentoPromo, 3325);
      expect(promo.total, 0);
      expect(promo.gratis, isTrue);

      const vacio = PlnCalculo(niveles: 0, modulos: 0);
      expect(vacio.vacio, isTrue);
      expect(vacio.gratis, isFalse);
    });

    test('clave del plan', () {
      expect(
        plnClavePlan(const PlnCalculo(niveles: 2, modulos: 1)),
        'modular-2n-1m',
      );
      final conPromo = plnClavePlan(
        const PlnCalculo(niveles: 0, modulos: 3, promo: true),
      );
      expect(conPromo, 'modular-0n-3m-promo');
      expect(plnPlanConPromo(conPromo), isTrue);
      expect(plnPlanConPromo('modular-2n-1m'), isFalse);
      expect(plnPlanConPromo('FASE2-CUR-STD-EXT-BAS-N1-M0'), isFalse);
    });

    test('código promocional: validez, cupo y canje', () async {
      expect(
        await PlnPromo.verificar('cualquiera'),
        PlnPromoResultado.invalido,
      );
      expect(
        await PlnPromo.verificar(' athena2026 '),
        PlnPromoResultado.valido,
      );

      for (var i = 0; i < PlnPromo.cupo; i++) {
        await PlnPromo.canjear('INST_$i');
      }
      await PlnPromo.canjear('INST_0');
      expect(await PlnPromo.verificar('ATHENA2026'), PlnPromoResultado.agotado);
      expect(await PlnPromo.hayCupo(institucionId: 'OTRA'), isFalse);
      // Quien ya lo canjeó puede volver a aplicarlo.
      expect(
        await PlnPromo.verificar('ATHENA2026', institucionId: 'INST_7'),
        PlnPromoResultado.valido,
      );
    });
  });

  group('perfil – formato', () {
    test('web y redes', () {
      expect(
        PerfInstFormato.normalizarWeb('escuela.edu.ar'),
        'https://escuela.edu.ar',
      );
      expect(
        PerfInstFormato.normalizarWeb('http://escuela.edu.ar/x'),
        'http://escuela.edu.ar/x',
      );
      expect(PerfInstFormato.normalizarWeb('  '), '');
      expect(PerfInstFormato.normalizarRed('escuela'), '@escuela');
      expect(PerfInstFormato.normalizarRed('@escuela.sm'), '@escuela.sm');
      expect(
        PerfInstFormato.normalizarRed('instagram.com/escuela'),
        'https://instagram.com/escuela',
      );
      expect(
        PerfInstFormato.normalizarRed('www.facebook.com/escuela'),
        'https://www.facebook.com/escuela',
      );
    });

    test('completitud', () {
      final vacio = PerfInstCompletitud.calcular(
        largoDescripcion: 0,
        fotos: 0,
        logo: false,
        telefono: false,
        horarioAtencion: false,
        servicios: false,
        horarioClases: false,
        emailOWeb: false,
        redes: false,
      );
      expect(vacio.porcentaje, 0);
      expect(vacio.pendientes.length, 9);
      expect(vacio.fotosFaltantes, 3);

      final completo = PerfInstCompletitud.calcular(
        largoDescripcion: 200,
        fotos: 4,
        logo: true,
        telefono: true,
        horarioAtencion: true,
        servicios: true,
        horarioClases: true,
        emailOWeb: true,
        redes: true,
      );
      expect(completo.porcentaje, 100);
      expect(completo.completo, isTrue);

      final parcial = PerfInstCompletitud.calcular(
        largoDescripcion: 20,
        fotos: 1,
        logo: true,
        telefono: false,
        horarioAtencion: false,
        servicios: false,
        horarioClases: false,
        emailOWeb: false,
        redes: false,
      );
      expect(parcial.porcentaje, 10 + 6 + 15);
      expect(parcial.fotosFaltantes, 2);
    });
  });

  testWidgets('imagen muy pesada: se achica hasta entrar', (tester) async {
    final resultado = await tester.runAsync(() async {
      const w = 2000, h = 1500;
      final azar = Random(7);
      final pixeles = Uint8List.fromList(
        List<int>.generate(
          w * h * 4,
          (i) => i % 4 == 3 ? 255 : azar.nextInt(256),
        ),
      );
      final listo = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixeles,
        w,
        h,
        ui.PixelFormat.rgba8888,
        listo.complete,
      );
      final original = await listo.future;
      final png = await original.toByteData(format: ui.ImageByteFormat.png);
      final pesada = Uint8List.sublistView(png!);
      expect(pesada.length, greaterThan(InstitucionesRepo.maxBytesImagen));

      final ajustada = await perfInstAjustarImagen(
        pesada,
        anchoMaximo: 1280,
        maxBytes: InstitucionesRepo.maxBytesImagen,
      );
      final codec = await ui.instantiateImageCodec(ajustada);
      final frame = await codec.getNextFrame();
      return (bytes: ajustada.length, ancho: frame.image.width);
    });
    expect(
      resultado!.bytes,
      lessThanOrEqualTo(InstitucionesRepo.maxBytesImagen),
    );
    expect(resultado.ancho, lessThanOrEqualTo(1280));

    // Una imagen liviana no se toca.
    final liviana = Uint8List.fromList([1, 2, 3]);
    expect(
      await perfInstAjustarImagen(liviana, anchoMaximo: 512, maxBytes: 10),
      same(liviana),
    );
  });

  group('plan – registro', () {
    testWidgets('exige al menos un nivel o módulo y crea la institución', (
      tester,
    ) async {
      await _abrir(tester, InstitucionPlanPage(draft: _draft()));

      expect(find.text('Elegí tu plan'), findsOneWidget);
      expect(find.text('PASO 2 DE 2'), findsOneWidget);
      expect(find.text('ATHENA2026'), findsNothing);

      // Sin selección no se crea nada: el botón explica qué falta.
      final crear = find.widgetWithText(FilledButton, 'Crear institución');
      await tester.tap(crear);
      await _asentar(tester);
      expect(
        find.text('Elegí al menos un nivel o un módulo para armar tu plan.'),
        findsWidgets,
      );
      expect(find.byType(InstitucionMenuPage), findsNothing);
      await _cerrarAvisos(tester);

      await _tocar(tester, find.text('Primaria'));
      await _tocar(tester, find.text('Deporte y movimiento'));
      await _tocar(tester, find.text('Arte y expresión'));
      expect(find.text('USD 38'), findsWidgets);

      await tester.tap(crear);
      await _asentar(tester);
      await _asentar(tester);

      expect(find.byType(InstitucionMenuPage), findsOneWidget);

      final owner = await tester.runAsync(
        () =>
            InstitucionService.getInstitucionIdByEmail('nueva@escuela.edu.ar'),
      );
      expect(owner, isNotNull);
      final perfiles = (await tester.runAsync(
        () => CuentaService.listarPerfilesInstitucion(owner!),
      ))!;
      expect(perfiles, hasLength(1));
      final inst = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener(perfiles.first.id),
      ))!;
      expect(inst.nombre, _nombreLargo);
      expect(inst.estadoPlan, EstadoPlanInstitucion.enPrueba);
      expect(inst.tipoPlan, 'modular-1n-2m');
      expect(inst.curricular, isTrue);
      expect(inst.extracurricular, isTrue);
      expect(inst.planFin.difference(inst.planInicio).inDays, 30);
      expect(inst.planSafe.niveles.map((n) => n.nivel), [
        NivelCurricular.primaria,
      ]);
      expect(inst.planSafe.modulos.map((m) => m.bloque), [
        BloqueExtracurricular.deporteYMovimiento,
        BloqueExtracurricular.arteYExpresion,
      ]);
      final enBuscador = (await tester.runAsync(
        InstitucionesRepo.instance.listar,
      ))!;
      expect(enBuscador.map((i) => i.id), contains(inst.id));
      await _cerrarAvisos(tester);
    });

    testWidgets('código promocional: inválido, válido y plan activo', (
      tester,
    ) async {
      await _abrir(
        tester,
        InstitucionPlanPage(draft: _draft(tipo: TipoInstitucion.secundaria)),
      );
      // El tipo de institución preselecciona su nivel.
      expect(find.text('USD 10'), findsWidgets);

      final campo = find.byType(TextField);
      await tester.ensureVisible(campo);
      await tester.enterText(campo, 'PROMO-FALSA');
      await _tocar(tester, find.text('Aplicar'));
      expect(
        find.text('Ese código no es válido. Revisalo e intentá de nuevo.'),
        findsOneWidget,
      );

      await tester.enterText(campo, 'athena2026');
      await _tocar(tester, find.text('Aplicar'));
      expect(find.text('USD 0'), findsWidgets);
      expect(find.text('Plan sin costo'), findsOneWidget);
      expect(find.textContaining('ATHENA'), findsNothing);
      await _cerrarAvisos(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Crear institución'));
      await _asentar(tester);
      await _asentar(tester);
      expect(find.byType(InstitucionMenuPage), findsOneWidget);

      final owner = (await tester.runAsync(
        () =>
            InstitucionService.getInstitucionIdByEmail('nueva@escuela.edu.ar'),
      ))!;
      final perfiles = (await tester.runAsync(
        () => CuentaService.listarPerfilesInstitucion(owner),
      ))!;
      final inst = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener(perfiles.first.id),
      ))!;
      expect(inst.estadoPlan, EstadoPlanInstitucion.activo);
      expect(inst.tipoPlan, 'modular-1n-0m-promo');
      // El canje quedó registrado: esa institución puede reaplicarlo.
      expect(await tester.runAsync(() => PlnPromo.hayCupo()), isTrue);
      await _cerrarAvisos(tester);
    });

    testWidgets('email ya registrado: muestra el error y deja corregir', (
      tester,
    ) async {
      await tester.runAsync(
        () => InstitucionService.registrarInstitucion(
          email: 'nueva@escuela.edu.ar',
          passwordHash: 'otra-clave-123',
          nombre: 'Otra',
        ),
      );
      await _abrir(tester, InstitucionPlanPage(draft: _draft()));
      await _tocar(tester, find.text('Primaria'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear institución'));
      await _asentar(tester);

      expect(find.text('Ya existe una cuenta con ese email.'), findsWidgets);
      expect(find.text('Corregir mis datos'), findsOneWidget);
      expect(find.byType(InstitucionMenuPage), findsNothing);
      await _cerrarAvisos(tester);
    });
  });

  group('plan – gestión', () {
    testWidgets(
      'quitar un nivel con vacantes las pausa sin reiniciar la prueba',
      (tester) async {
        final inst = institucionDemo(
          nombre: _nombreLargo,
          niveles: [NivelCurricular.primaria, NivelCurricular.secundaria],
          bloques: [BloqueExtracurricular.deporteYMovimiento],
        );
        await tester.runAsync(() => InstitucionesRepo.instance.guardar(inst));
        final oferta = (await tester.runAsync(
          () => OfertasRepo.instance.guardar(ofertaDemo()),
        ))!;

        await _abrir(
          tester,
          const InstitucionPlanPage.manage(
            ownerAccountId: 'INST_1',
            institucionPerfilId: 'INST_1',
          ),
        );
        expect(find.text('Prueba vencida'), findsWidgets);
        expect(find.text('1 vacante publicada'), findsOneWidget);

        // Sin cambios no hay nada para guardar.
        final guardar = find.widgetWithText(FilledButton, 'Guardar cambios');
        expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

        await _tocar(tester, find.text('Primaria').first);
        expect(find.text('Se va a pausar 1 vacante'), findsOneWidget);
        expect(tester.widget<FilledButton>(guardar).onPressed, isNotNull);

        await tester.tap(guardar);
        await _asentar(tester);
        expect(find.text('¿Pausar vacantes publicadas?'), findsOneWidget);
        await tester.tap(find.text('Guardar y pausar'));
        await _asentar(tester);
        await _asentar(tester);

        expect(find.text('BASE'), findsOneWidget);
        final guardada = (await tester.runAsync(
          () => InstitucionesRepo.instance.obtener('INST_1'),
        ))!;
        expect(guardada.planSafe.niveles.map((n) => n.nivel), [
          NivelCurricular.secundaria,
        ]);
        expect(guardada.tipoPlan, 'modular-1n-1m');
        expect(guardada.estadoPlan, EstadoPlanInstitucion.enPrueba);
        expect(guardada.planInicio, inst.planInicio);
        expect(guardada.planFin, inst.planFin);
        final pausada = (await tester.runAsync(
          () => OfertasRepo.instance.obtener('INST_1', oferta.id),
        ))!;
        expect(pausada.activa, isFalse);
        await _cerrarAvisos(tester);
      },
    );

    testWidgets('código promocional en gestión: plan activo y queda fijo', (
      tester,
    ) async {
      final inst = institucionDemo();
      await tester.runAsync(() => InstitucionesRepo.instance.guardar(inst));
      const pagina = InstitucionPlanPage.manage(
        ownerAccountId: 'INST_1',
        institucionPerfilId: 'INST_1',
      );
      await _abrir(tester, pagina);

      final campo = find.byType(TextField);
      await tester.ensureVisible(campo);
      await tester.enterText(campo, 'Athena2026');
      await _tocar(tester, find.text('Aplicar'));
      await _cerrarAvisos(tester);
      expect(find.text('USD 0'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await _asentar(tester);
      await _asentar(tester);
      expect(find.text('BASE'), findsOneWidget);

      final guardada = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener('INST_1'),
      ))!;
      expect(guardada.estadoPlan, EstadoPlanInstitucion.activo);
      expect(guardada.tipoPlan, 'modular-1n-1m-promo');
      expect(guardada.planFin, inst.planFin);
      await _cerrarAvisos(tester);

      // Al volver a entrar, el código sigue aplicado y no se puede quitar.
      await _abrir(tester, pagina);
      expect(find.text('Plan activo'), findsWidgets);
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Quitar código'), findsNothing);
      expect(find.textContaining('código promocional activo'), findsWidgets);
    });

    testWidgets('plan sin costo que pasa a tener costo: empieza la prueba', (
      tester,
    ) async {
      final antes = DateTime(2026, 1, 10);
      final inst = institucionDemo().copyWith(
        estadoPlan: EstadoPlanInstitucion.activo,
        planInicio: antes,
        planFin: antes.add(const Duration(days: 30)),
      );
      await tester.runAsync(() => InstitucionesRepo.instance.guardar(inst));
      await _abrir(
        tester,
        const InstitucionPlanPage.manage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
      );
      await _tocar(tester, find.text('Secundaria'));
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await _asentar(tester);
      await _asentar(tester);

      final guardada = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener('INST_1'),
      ))!;
      expect(guardada.estadoPlan, EstadoPlanInstitucion.enPrueba);
      expect(guardada.planInicio.isAfter(antes), isTrue);
      expect(guardada.planFin.difference(guardada.planInicio).inDays, 30);
      await _cerrarAvisos(tester);
    });

    testWidgets('salir con cambios pide confirmación', (tester) async {
      await tester.runAsync(
        () => InstitucionesRepo.instance.guardar(institucionDemo()),
      );
      await _abrir(
        tester,
        const InstitucionPlanPage.manage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
      );
      await _tocar(tester, find.text('Secundaria'));
      await tester.tap(find.byType(BackButton));
      await _asentar(tester);
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);
      await tester.tap(find.text('Salir sin guardar'));
      await _asentar(tester);
      expect(find.text('BASE'), findsOneWidget);
    });

    testWidgets('institución inexistente: error con reintento', (tester) async {
      await _abrir(
        tester,
        const InstitucionPlanPage.manage(
          ownerAccountId: 'X',
          institucionPerfilId: 'NO_EXISTE',
        ),
      );
      expect(find.text('No pudimos cargar tu plan.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('perfil', () {
    Future<void> sembrar(WidgetTester tester) async {
      await tester.runAsync(() async {
        await InstitucionService.registrarInstitucion(
          email: 'info@escuela.edu.ar',
          passwordHash: 'clave-segura-1',
          nombre: _nombreLargo,
        );
        await InstitucionesRepo.instance.guardar(
          institucionDemo(nombre: _nombreLargo),
        );
      });
    }

    testWidgets('edita y guarda datos y perfil público', (tester) async {
      await sembrar(tester);
      await _abrir(
        tester,
        const InstitucionPerfilPage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
      );
      expect(find.text('Perfil de la institución'), findsOneWidget);
      expect(find.text('Tenés cambios sin guardar'), findsNothing);
      // Abre en "Perfil público".
      expect(find.textContaining('Tu perfil está completo al'), findsOneWidget);

      await tester.tap(find.text('Datos'));
      await _asentar(tester);
      final nombre = find.widgetWithText(
        TextFormField,
        'Nombre de la institución',
      );
      await tester.enterText(nombre, 'Colegio Nuevo Sol');
      await _asentar(tester);
      expect(find.text('Tenés cambios sin guardar'), findsOneWidget);

      await tester.tap(find.text('Perfil público'));
      await _asentar(tester);
      expect(find.textContaining('Tu perfil está completo al'), findsOneWidget);

      final descripcion = find.widgetWithText(TextFormField, 'Descripción');
      await tester.ensureVisible(descripcion);
      await tester.enterText(
        descripcion,
        'Somos una escuela con más de cincuenta años de trayectoria, '
        'jornada extendida y talleres de arte, deporte y robótica.',
      );
      final web = find.widgetWithText(TextFormField, 'Sitio web');
      await tester.ensureVisible(web);
      await tester.enterText(web, 'nuevosol.edu.ar');
      final instagram = find.widgetWithText(TextFormField, 'Instagram');
      await tester.ensureVisible(instagram);
      await tester.enterText(instagram, 'nuevosol');
      await _tocar(tester, find.text('Comedor'));
      await _tocar(tester, find.text('Becas'));

      await tester.tap(find.text('Vista previa'));
      await _asentar(tester);
      expect(find.text('Así te ven las familias'), findsOneWidget);
      expect(find.text('Colegio Nuevo Sol'), findsWidgets);
      expect(find.text('https://nuevosol.edu.ar'), findsOneWidget);
      expect(find.text('@nuevosol'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await _asentar(tester);
      await _asentar(tester);
      expect(find.text('Cambios guardados.'), findsOneWidget);
      expect(find.text('Tenés cambios sin guardar'), findsNothing);

      final inst = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener('INST_1'),
      ))!;
      expect(inst.nombre, 'Colegio Nuevo Sol');
      final publico = (await tester.runAsync(
        () => InstitucionesRepo.instance.perfilPublico('INST_1'),
      ))!;
      expect(publico.descripcion, startsWith('Somos una escuela'));
      expect(publico.sitioWeb, 'https://nuevosol.edu.ar');
      expect(publico.instagram, '@nuevosol');
      expect(publico.servicios, ['Comedor', 'Becas']);
      final resumen = (await tester.runAsync(
        InstitucionesRepo.instance.listar,
      ))!;
      expect(resumen.single.nombre, 'Colegio Nuevo Sol');
      await _cerrarAvisos(tester);
    });

    testWidgets('con errores no guarda y muestra la pestaña que los tiene', (
      tester,
    ) async {
      await sembrar(tester);
      await _abrir(
        tester,
        const InstitucionPerfilPage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
      );
      await tester.tap(find.text('Datos'));
      await _asentar(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la institución'),
        '',
      );
      await _asentar(tester);
      await tester.tap(find.text('Vista previa'));
      await _asentar(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await _asentar(tester);

      expect(find.text('Revisá los campos marcados.'), findsOneWidget);
      expect(find.text('Campo obligatorio.'), findsOneWidget);
      final inst = (await tester.runAsync(
        () => InstitucionesRepo.instance.obtener('INST_1'),
      ))!;
      expect(inst.nombre, _nombreLargo);
      await _cerrarAvisos(tester);

      // Descartar vuelve a lo guardado y limpia los errores.
      await tester.tap(find.text('Descartar'));
      await _asentar(tester);
      await tester.tap(find.text('Descartar').last);
      await _asentar(tester);
      expect(find.text('Campo obligatorio.'), findsNothing);
      expect(find.text('Tenés cambios sin guardar'), findsNothing);
      expect(find.text(_nombreLargo), findsWidgets);
    });

    testWidgets('salir con cambios pide confirmación', (tester) async {
      await sembrar(tester);
      await _abrir(
        tester,
        const InstitucionPerfilPage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
      );
      await tester.tap(find.text('Datos'));
      await _asentar(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ciudad'),
        'Rosario',
      );
      await _asentar(tester);
      await tester.tap(find.byType(BackButton));
      await _asentar(tester);
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _asentar(tester);
      expect(find.text('Perfil de la institución'), findsOneWidget);
    });
  });

  group('letra grande', () {
    testWidgets('plan y perfil en 360 px con texto al 135 %', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _abrir(tester, InstitucionPlanPage(draft: _draft()), size: _chico);
      await _tocar(tester, find.text('Primaria'));
      await _tocar(tester, find.text('Secundaria'));
      await _tocar(tester, find.text('Deporte y movimiento'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await _asentar(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await _asentar(tester);

      await tester.runAsync(() async {
        await InstitucionesRepo.instance.guardar(
          institucionDemo(nombre: _nombreLargo),
        );
        await OfertasRepo.instance.guardar(ofertaDemo());
      });
      await _abrir(
        tester,
        const InstitucionPlanPage.manage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
        size: _chico,
      );
      await _tocar(tester, find.text('Primaria').first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await _asentar(tester);

      await _abrir(
        tester,
        const InstitucionPerfilPage(
          ownerAccountId: 'INST_1',
          institucionPerfilId: 'INST_1',
        ),
        size: _chico,
      );
      for (final pestana in ['Datos', 'Vista previa', 'Perfil público']) {
        await tester.tap(find.text(pestana));
        await _asentar(tester);
        final lista = find.byType(SingleChildScrollView).hitTestable().first;
        await tester.drag(lista, const Offset(0, -900));
        await _asentar(tester);
        await tester.drag(lista, const Offset(0, -900));
        await _asentar(tester);
      }
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción'),
        'Cambios',
      );
      await _asentar(tester);
      expect(find.text('Tenés cambios sin guardar'), findsOneWidget);
    });
  });

  group('sin desbordes', () {
    const vistas = [
      (_chico, Locale('es'), ThemeMode.light),
      (_chico, Locale('en'), ThemeMode.dark),
      (_chico, Locale('pt'), ThemeMode.light),
      (_escritorio, Locale('es'), ThemeMode.light),
      (_escritorio, Locale('en'), ThemeMode.dark),
    ];

    for (final (size, locale, mode) in vistas) {
      final etiqueta =
          '${size.width.round()} ${locale.languageCode} ${mode.name}';

      testWidgets('plan registro $etiqueta', (tester) async {
        await _abrir(
          tester,
          InstitucionPlanPage(draft: _draft()),
          size: size,
          locale: locale,
          mode: mode,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await _asentar(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await _asentar(tester);
      });

      testWidgets('plan gestión $etiqueta', (tester) async {
        await tester.runAsync(() async {
          await InstitucionesRepo.instance.guardar(
            institucionDemo(
              nombre: _nombreLargo,
              niveles: NivelCurricular.values,
              bloques: BloqueExtracurricularX.ordered(),
            ),
          );
          await OfertasRepo.instance.guardar(ofertaDemo());
        });
        await _abrir(
          tester,
          const InstitucionPlanPage.manage(
            ownerAccountId: 'INST_1',
            institucionPerfilId: 'INST_1',
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await _asentar(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await _asentar(tester);
      });

      testWidgets('perfil $etiqueta', (tester) async {
        await tester.runAsync(() async {
          await InstitucionesRepo.instance.guardar(
            institucionDemo(nombre: _nombreLargo),
          );
          await InstitucionesRepo.instance.guardarPerfilPublico(
            'INST_1',
            const PerfilPublico(
              descripcion:
                  'Escuela de gestión privada con orientación en ciencias y '
                  'una fuerte propuesta de idiomas, arte y deporte.',
              horarioAtencion: 'Lunes a viernes de 8 a 16 h',
              horarioClases: 'Turno mañana de 7:30 a 12:30',
              telefono: '351 123 4567',
              whatsapp: '+54 9 351 123 4567',
              email: 'inscripciones@institutosanmartindelosandes.edu.ar',
              sitioWeb:
                  'https://www.institutosanmartindelosandes.edu.ar/inscripciones',
              instagram: '@institutosanmartindelosandes',
              facebook: 'https://facebook.com/institutosanmartindelosandes',
              youtube: '@sanmartindelosandes',
              servicios: [
                'Comedor',
                'Transporte escolar',
                'Gabinete psicopedagógico',
                'Jornada extendida',
              ],
            ),
          );
        });
        await _abrir(
          tester,
          const InstitucionPerfilPage(
            ownerAccountId: 'INST_1',
            institucionPerfilId: 'INST_1',
          ),
          size: size,
          locale: locale,
          mode: mode,
        );
        final t = await AppLocalizations.delegate.load(locale);
        for (final pestana in [
          t.perfInstTabPublico,
          t.perfInstTabVista,
          t.perfInstTabDatos,
        ]) {
          await tester.tap(find.text(pestana));
          await _asentar(tester);
          final lista = find.byType(SingleChildScrollView).hitTestable().first;
          await tester.drag(lista, const Offset(0, -800));
          await _asentar(tester);
          await tester.drag(lista, const Offset(0, -800));
          await _asentar(tester);
        }
        // Con cambios pendientes aparece la barra de guardar.
        await tester.enterText(
          find.widgetWithText(TextFormField, t.perfInstNombre),
          'Otro nombre',
        );
        await _asentar(tester);
        expect(find.text(t.perfInstCambiosPendientes), findsOneWidget);
      });
    }
  });
}
