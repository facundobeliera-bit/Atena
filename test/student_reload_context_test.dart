import 'dart:convert';

import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/screens/alumno/alumno_area_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StorageService.instance.resetCache();
  });

  Future<void> seedAccount({
    required String accountId,
    required List<(String, String)> students,
  }) async {
    final date = DateTime(2026, 9, 15);
    await CuentaService.actualizarCuenta(
      Cuenta(
        id: accountId,
        email: '$accountId@example.invalid',
        passwordHash: base64Encode(utf8.encode('prueba123')),
        perfilesAlumnoIds: students.map((student) => student.$1).toList(),
        perfilesInstitucionIds: const <String>[],
        recordarme: true,
        creadaEl: date,
        ultimaSesion: date,
      ),
    );
    for (final student in students) {
      await CuentaService.actualizarPerfilAlumno(
        PerfilAlumno(
          id: student.$1,
          cuentaId: accountId,
          ownerAccountId: accountId,
          documento: student.$2,
          nombre: student.$1,
          apellido: 'Prueba',
          fechaNacimiento: DateTime(2015),
          email: '',
          telefono: '',
          emancipado: false,
          fechaEmancipacion: null,
          prefs: PreferenciasPerfil.defaults(),
        ),
      );
    }
  }

  Future<void> authenticate(String accountId) async {
    await CuentaService.setSesionCuentaId(accountId, recordarme: true);
    await SessionService.setSession(
      userId: accountId,
      role: SessionRole.cuenta,
      rememberMe: true,
    );
  }

  Future<void> restart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    StorageService.instance.resetCache();
    await app.main();
    await tester.pumpAndSettle();
  }

  testWidgets('F5 restaura el perfil de alumno activo y su área', (
    tester,
  ) async {
    await seedAccount(
      accountId: 'cuenta-A',
      students: const [('perfil-A', '30111222')],
    );
    await authenticate('cuenta-A');
    await CuentaService.activarContextoCuenta(
      'cuenta-A',
      perfilAlumnoId: 'perfil-A',
    );

    await restart(tester);

    final area = tester.widget<AlumnoAreaPage>(find.byType(AlumnoAreaPage));
    expect(area.cuentaId, 'cuenta-A');
    expect(area.perfilId, 'perfil-A');
    expect(area.documentoAlumno, '30111222');
    expect(tester.takeException(), isNull);
  });

  testWidgets('F5 no elige entre varios perfiles sin contexto activo', (
    tester,
  ) async {
    await seedAccount(
      accountId: 'cuenta-A',
      students: const [('perfil-A', '30111222'), ('perfil-B', '30222333')],
    );
    await authenticate('cuenta-A');
    await CuentaService.clearUltimoPerfil('cuenta-A');
    await SessionService.clearPerfilSeleccionado();

    await restart(tester);

    expect(find.byType(CuentaHomePage), findsOneWidget);
    expect(find.byType(AlumnoAreaPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F5 rechaza un perfil activo perteneciente a otra cuenta', (
    tester,
  ) async {
    await seedAccount(
      accountId: 'cuenta-A',
      students: const [('perfil-A', '30111222')],
    );
    await seedAccount(
      accountId: 'cuenta-B',
      students: const [('perfil-B', '30999888')],
    );
    await authenticate('cuenta-A');
    await CuentaService.setUltimoPerfil('cuenta-A', 'A|perfil-B');
    await SessionService.setPerfilSeleccionado('30999888');

    await restart(tester);

    expect(find.byType(CuentaHomePage), findsOneWidget);
    expect(find.byType(AlumnoAreaPage), findsNothing);
    expect((await SessionService.getSession())?.userId, 'cuenta-A');
    expect(tester.takeException(), isNull);
  });
}
