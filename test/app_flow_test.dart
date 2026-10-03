// test/app_flow_test.dart
//
// Flujo de interfaz de punta a punta: bienvenida → registro de familia →
// inicio del alumno → cerrar sesión.

import 'package:atena_app/main.dart';
import 'package:atena_app/services/app_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextFormField, label);
  expect(field, findsOneWidget, reason: 'campo "$label"');
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage();
    AppSettingsController.instance.init(locale: const Locale('es'));
  });

  testWidgets('registro de familia y llegada al inicio del alumno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AtenaApp());
    await tester.pumpAndSettle();

    // Bienvenida
    expect(find.text('Soy alumno o familia'), findsOneWidget);
    expect(find.text('Soy una institución'), findsOneWidget);

    await _tapText(tester, 'Soy alumno o familia');
    expect(find.text('Ingresá a tu cuenta'), findsOneWidget);

    await _tapText(tester, 'Crear cuenta');
    expect(find.text('Creá tu cuenta'), findsOneWidget);

    await _enter(tester, 'Nombre', 'Ana');
    await _enter(tester, 'Apellido', 'Paz');
    await _enter(tester, 'DNI', '40111222');
    await _enter(tester, 'Email', 'ana@demo.com');
    await _enter(tester, 'Contraseña', 'clave1234');
    await _enter(tester, 'Repetí la contraseña', 'clave1234');

    // Fecha de nacimiento: abre el selector y acepta la fecha propuesta.
    final fecha = find.widgetWithText(TextFormField, 'Fecha de nacimiento');
    await tester.ensureVisible(fecha);
    await tester.tap(fecha);
    await tester.pumpAndSettle();
    final dialog = find.byType(DatePickerDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(
      find.descendant(of: dialog, matching: find.byType(TextButton)).last,
    );
    await tester.pumpAndSettle();

    final crear = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();

    // Con un solo alumno se entra directo a su inicio.
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Explorar instituciones'), findsWidgets);

    // Cerrar sesión desde el menú.
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Soy alumno o familia'), findsOneWidget);
  });
}
