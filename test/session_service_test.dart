import 'package:atena_app/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Sesión temporal válida durante el uso, eliminada al reiniciar', () async {
    await SessionService.setSession(
      userId: 'cuenta-prueba',
      role: SessionRole.cuenta,
      rememberMe: false,
    );
    expect((await SessionService.getSession())?.userId, 'cuenta-prueba');

    await SessionService.clearTempIfNeeded();
    expect(await SessionService.getSession(), isNull);
  });

  test('Recordarme conserva la sesión durante la limpieza de arranque', () async {
    await SessionService.setSession(
      userId: 'cuenta-prueba',
      role: SessionRole.cuenta,
      rememberMe: true,
    );

    await SessionService.clearTempIfNeeded();
    expect((await SessionService.getSession())?.userId, 'cuenta-prueba');
  });
}
