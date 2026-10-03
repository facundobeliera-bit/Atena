// test/auth_test.dart
//
// Contraseñas, registro, ingreso, restablecimiento y sesión.

import 'dart:convert';

import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/services/auth_errors.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/password_hasher.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> expectAuthError(Future<Object?> f, AuthErrorCode code) async {
  try {
    await f;
    fail('Se esperaba AuthException(${code.name})');
  } on AuthException catch (e) {
    expect(e.code, code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  group('PasswordHasher', () {
    test('hash con sal distinta y verificación', () {
      final a = PasswordHasher.hash('secreta123');
      final b = PasswordHasher.hash('secreta123');
      expect(a, isNot(b));
      expect(PasswordHasher.verify('secreta123', a), isTrue);
      expect(PasswordHasher.verify('otra', a), isFalse);
      expect(PasswordHasher.needsRehash(a), isFalse);
    });

    test('acepta formatos anteriores y pide migrarlos', () {
      final legacyB64 = base64Encode(utf8.encode('abcd'));
      expect(PasswordHasher.verify('abcd', legacyB64), isTrue);
      expect(PasswordHasher.needsRehash(legacyB64), isTrue);
      expect(
        PasswordHasher.verify(
          'abcd',
          'abcd',
          legacy: LegacyPasswordFormat.plain,
        ),
        isTrue,
      );
    });
  });

  group('Familias', () {
    Future<void> registrar() => AuthService.registrarFamilia(
      email: 'Familia@Mail.com',
      password: 'clave1234',
      remember: true,
      nombre: 'Lucía',
      apellido: 'Gómez',
      dni: '45.123.456',
      fechaNacimiento: DateTime(2015, 1, 1),
    );

    test('registro crea cuenta y primer alumno', () async {
      final res = await AuthService.registrarFamilia(
        email: 'familia@mail.com',
        password: 'clave1234',
        remember: true,
        nombre: 'Lucía',
        apellido: 'Gómez',
        dni: '45123456',
        fechaNacimiento: DateTime(2015, 1, 1),
      );
      expect(res.perfil.documento, '45123456');
      final perfiles = await CuentaService.listarPerfilesAlumno(res.cuenta.id);
      expect(perfiles.single.nombre, 'Lucía');
      expect(PasswordHasher.isModernHash(res.cuenta.passwordHash), isTrue);
    });

    test('valida datos antes de crear la cuenta', () async {
      await expectAuthError(
        AuthService.registrarFamilia(
          email: 'a@b.com',
          password: 'clave1234',
          remember: true,
          nombre: 'A',
          apellido: 'B',
          dni: '12',
          fechaNacimiento: DateTime(2015),
        ),
        AuthErrorCode.invalidDni,
      );
      // No quedó una cuenta a medio crear.
      expect(await CuentaService.getCuentaByEmail('a@b.com'), isNull);
    });

    test('contraseña corta y email repetido', () async {
      await expectAuthError(
        CuentaService.registrarCuenta(email: 'x@y.com', password: '123'),
        AuthErrorCode.weakPassword,
      );
      await registrar();
      await expectAuthError(registrar(), AuthErrorCode.emailInUse);
    });

    test('login correcto e incorrecto (mismo error)', () async {
      await registrar();
      final c = await AuthService.loginFamilia(
        email: 'FAMILIA@mail.com ',
        password: 'clave1234',
        remember: true,
      );
      expect(c.email, 'familia@mail.com');
      await expectAuthError(
        AuthService.loginFamilia(
          email: 'familia@mail.com',
          password: 'mala',
          remember: true,
        ),
        AuthErrorCode.wrongCredentials,
      );
      await expectAuthError(
        AuthService.loginFamilia(
          email: 'nadie@mail.com',
          password: 'clave1234',
          remember: true,
        ),
        AuthErrorCode.wrongCredentials,
      );
    });

    test('migra contraseñas viejas al ingresar', () async {
      await registrar();
      final c = (await CuentaService.getCuentaByEmail('familia@mail.com'))!;
      final vieja = Cuenta(
        id: c.id,
        email: c.email,
        passwordHash: base64Encode(utf8.encode('abcd')),
        perfilesAlumnoIds: c.perfilesAlumnoIds,
        perfilesInstitucionIds: c.perfilesInstitucionIds,
        creadaEl: c.creadaEl,
        ultimaSesion: c.ultimaSesion,
      );
      await CuentaService.actualizarCuenta(vieja);

      await AuthService.loginFamilia(
        email: 'familia@mail.com',
        password: 'abcd',
        remember: true,
      );
      final migrada = (await CuentaService.getCuentaByEmail(
        'familia@mail.com',
      ))!;
      expect(PasswordHasher.isModernHash(migrada.passwordHash), isTrue);
    });

    test('restablecer exige el DNI de un alumno de la cuenta', () async {
      await registrar();
      await expectAuthError(
        AuthService.restablecerPasswordFamilia(
          email: 'familia@mail.com',
          dni: '11111111',
          nuevoPassword: 'nueva12345',
        ),
        AuthErrorCode.identityMismatch,
      );
      await AuthService.restablecerPasswordFamilia(
        email: 'familia@mail.com',
        dni: '45123456',
        nuevoPassword: 'nueva12345',
      );
      await AuthService.loginFamilia(
        email: 'familia@mail.com',
        password: 'nueva12345',
        remember: true,
      );
    });
  });

  group('Sesión', () {
    test('ingresar como familia limpia una sesión institucional', () async {
      await SessionService.setSession(
        userId: 'INST_X',
        role: SessionRole.institucion,
        rememberMe: true,
      );
      await AuthService.registrarFamilia(
        email: 'f@mail.com',
        password: 'clave1234',
        remember: true,
        nombre: 'Ana',
        apellido: 'Paz',
        dni: '40111222',
        fechaNacimiento: DateTime(2012),
      );
      expect(await SessionService.getSession(), isNull);
      final target = await AuthService.resolveHome();
      expect(target, isA<HomeFamilia>());
    });

    test('logout limpia ambas sesiones', () async {
      await AuthService.iniciarSesionInstitucion(
        ownerAccountId: 'INST_1',
        institucionPerfilId: 'INST_1',
        remember: true,
      );
      expect(await AuthService.resolveHome(), isA<HomeInstitucion>());
      await AuthService.logout();
      expect(await AuthService.resolveHome(), isA<HomeLanding>());
    });
  });
}
