import 'dart:convert';

import 'package:atena_app/services/alumno_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:atena_app/services/local_password_hasher.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const oldPassword = 'synthetic-old-497';
const newPassword = 'synthetic-new-905';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetCache();
  });

  test('Windows y web aceptan el mismo vector PBKDF2-SHA256', () async {
    final salt = List<int>.generate(16, (index) => index);
    const derived =
        'BD4C3CB991AC9A7239FC0839B5E7D6C254E7DBC4D8270AE757C8C931E4364340';
    final bytes = List<int>.generate(
      32,
      (index) =>
          int.parse(derived.substring(index * 2, index * 2 + 2), radix: 16),
    );
    final encoded =
        'pbkdf2-sha256:600000:${base64UrlEncode(salt)}:${base64UrlEncode(bytes)}';
    expect(
      await LocalPasswordHasher.verify('atena-benchmark-password', encoded),
      isTrue,
    );
    expect(
      await LocalPasswordHasher.verify('wrong-password', encoded),
      isFalse,
    );
  });

  test('la cuenta migra Base64 solo tras un ingreso válido', () async {
    final account = await CuentaService.registrarCuenta(
      email: 'legacy-account@example.test',
      password: oldPassword,
    );
    await CuentaService.logoutCuenta();
    final p = await SharedPreferences.getInstance();
    final key = 'cuenta_${account.id}';
    final data = jsonDecode(p.getString(key)!) as Map<String, dynamic>;
    data['passwordHash'] = base64Encode(utf8.encode(oldPassword));
    await p.setString(key, jsonEncode(data));
    StorageService.instance.resetCache();

    expect(
      () => CuentaService.loginCuenta(
        email: account.email,
        password: newPassword,
      ),
      throwsException,
    );
    expect(
      (jsonDecode(p.getString(key)!) as Map)['passwordHash'],
      data['passwordHash'],
    );
    await CuentaService.loginCuenta(
      email: account.email,
      password: oldPassword,
    );
    final migrated =
        (jsonDecode(p.getString(key)!) as Map)['passwordHash'] as String;
    expect(LocalPasswordHasher.isModern(migrated), isTrue);
    expect(await LocalPasswordHasher.verify(oldPassword, migrated), isTrue);
    expect(p.getString(key), isNot(contains(data['passwordHash'])));
    await CuentaService.logoutCuenta();
    StorageService.instance.resetCache();
    expect(
      (await CuentaService.loginCuenta(
        email: account.email,
        password: oldPassword,
      )).id,
      account.id,
    );
    expect((jsonDecode(p.getString(key)!) as Map)['passwordHash'], migrated);
  });

  test('institución y propietaria se migran sin copias reversibles', () async {
    final institution = await InstitucionService.registrarInstitucion(
      email: 'legacy-institution@example.test',
      passwordHash: oldPassword,
      nombre: 'Institución sintética',
    );
    final p = await SharedPreferences.getInstance();
    final id = institution.institucionId;
    final instKey = 'atena_inst_auth_by_id_$id';
    final ownerKey = 'cuenta_$id';
    final inst = jsonDecode(p.getString(instKey)!) as Map<String, dynamic>;
    final owner = jsonDecode(p.getString(ownerKey)!) as Map<String, dynamic>;
    inst['passwordHash'] = oldPassword;
    owner['passwordHash'] = base64Encode(utf8.encode(oldPassword));
    await p.setString(instKey, jsonEncode(inst));
    await p.setString(ownerKey, jsonEncode(owner));
    await p.setString('inst_$id', jsonEncode(inst));
    await p.setString('inst_email_legacy-institution@example.test', id);
    StorageService.instance.resetCache();

    expect(
      await InstitucionService.loginInstitucion(
        email: 'legacy-institution@example.test',
        passwordHash: newPassword,
      ),
      isNull,
    );
    expect(
      (jsonDecode(p.getString(instKey)!) as Map)['passwordHash'],
      oldPassword,
    );
    expect(
      await InstitucionService.loginInstitucion(
        email: 'legacy-institution@example.test',
        passwordHash: oldPassword,
      ),
      isNotNull,
    );
    final newInst =
        (jsonDecode(p.getString(instKey)!) as Map)['passwordHash'] as String;
    final stillLegacyOwner =
        (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'] as String;
    expect(LocalPasswordHasher.isModern(newInst), isTrue);
    expect(p.getString('inst_$id'), isNull);
    expect(p.getString('inst_email_legacy-institution@example.test'), isNull);
    expect(stillLegacyOwner, base64Encode(utf8.encode(oldPassword)));
    expect(p.getBool('atena_credential_divergent_$id'), isNull);
    final account = await CuentaService.loginCuenta(
      email: 'legacy-institution@example.test',
      password: oldPassword,
    );
    expect(account.id, id);
    final newOwner =
        (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'] as String;
    expect(LocalPasswordHasher.isModern(newOwner), isTrue);
    expect(newInst, isNot(newOwner));
    expect(await LocalPasswordHasher.verify(oldPassword, newInst), isTrue);
    expect(await LocalPasswordHasher.verify(oldPassword, newOwner), isTrue);
    expect(p.getString(instKey), isNot(contains(oldPassword)));
    expect(
      p.getString(ownerKey),
      isNot(contains(base64Encode(utf8.encode(oldPassword)))),
    );
    await CuentaService.logoutCuenta();
    StorageService.instance.resetCache();
    expect(
      (await InstitucionService.loginInstitucion(
        email: 'legacy-institution@example.test',
        passwordHash: oldPassword,
      ))?.institucionId,
      id,
    );
    expect(
      (await CuentaService.loginCuenta(
        email: 'legacy-institution@example.test',
        password: oldPassword,
      )).id,
      id,
    );
    expect((jsonDecode(p.getString(instKey)!) as Map)['passwordHash'], newInst);
    expect(
      (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'],
      newOwner,
    );
  });

  test(
    'credenciales divergentes migran separadas y mantienen identidad',
    () async {
      final institution = await InstitucionService.registrarInstitucion(
        email: 'divergent-institution@example.test',
        passwordHash: oldPassword,
        nombre: 'Institución divergente',
      );
      final id = institution.institucionId;
      final p = await SharedPreferences.getInstance();
      final instKey = 'atena_inst_auth_by_id_$id';
      final ownerKey = 'cuenta_$id';
      final inst = jsonDecode(p.getString(instKey)!) as Map<String, dynamic>;
      final owner = jsonDecode(p.getString(ownerKey)!) as Map<String, dynamic>;
      inst['passwordHash'] = oldPassword;
      owner['passwordHash'] = base64Encode(utf8.encode(newPassword));
      await p.setString(instKey, jsonEncode(inst));
      await p.setString(ownerKey, jsonEncode(owner));
      StorageService.instance.resetCache();

      final signedIn = await InstitucionService.loginInstitucion(
        email: 'divergent-institution@example.test',
        passwordHash: oldPassword,
      );
      expect(signedIn?.institucionId, id);
      expect(p.getBool('atena_credential_divergent_$id'), isTrue);
      expect(
        LocalPasswordHasher.isModern(
          (jsonDecode(p.getString(instKey)!) as Map)['passwordHash'] as String,
        ),
        isTrue,
      );
      expect(
        (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'],
        base64Encode(utf8.encode(newPassword)),
      );

      final account = await CuentaService.loginCuenta(
        email: 'divergent-institution@example.test',
        password: newPassword,
      );
      expect(account.id, id);
      expect(p.getBool('atena_credential_divergent_$id'), isTrue);
      final ownerHash =
          (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'] as String;
      expect(LocalPasswordHasher.isModern(ownerHash), isTrue);
      expect(await LocalPasswordHasher.verify(newPassword, ownerHash), isTrue);
      expect(await LocalPasswordHasher.verify(oldPassword, ownerHash), isFalse);
      await CuentaService.logoutCuenta();
      StorageService.instance.resetCache();
      expect(
        (await InstitucionService.loginInstitucion(
          email: 'divergent-institution@example.test',
          passwordHash: oldPassword,
        ))?.institucionId,
        id,
      );
      expect(
        (await CuentaService.loginCuenta(
          email: 'divergent-institution@example.test',
          password: newPassword,
        )).id,
        id,
      );
      expect(p.getBool('atena_credential_divergent_$id'), isTrue);
      expect(
        (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'],
        ownerHash,
      );
    },
  );

  test(
    'cambiar la clave institucional no cambia la de la propietaria',
    () async {
      final institution = await InstitucionService.registrarInstitucion(
        email: 'independent-owner@example.test',
        passwordHash: oldPassword,
        nombre: 'Institución independiente',
      );
      final id = institution.institucionId;
      final p = await SharedPreferences.getInstance();
      final ownerKey = 'cuenta_$id';
      final before =
          (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'];
      await p.setString(
        'inst_$id',
        jsonEncode({
          'id': id,
          'email': 'independent-owner@example.test',
          'passwordHash': oldPassword,
          'nombre': 'Institución independiente',
        }),
      );

      await InstitucionService.actualizarCredenciales(
        institucionId: id,
        nuevoPassword: newPassword,
      );
      expect(
        (jsonDecode(p.getString(ownerKey)!) as Map)['passwordHash'],
        before,
      );
      expect(p.getString('inst_$id'), isNull);
      expect(p.getBool('atena_credential_divergent_$id'), isTrue);
      expect(
        await InstitucionService.loginInstitucion(
          email: 'independent-owner@example.test',
          passwordHash: oldPassword,
        ),
        isNull,
      );
      expect(
        (await InstitucionService.loginInstitucion(
          email: 'independent-owner@example.test',
          passwordHash: newPassword,
        ))?.institucionId,
        id,
      );
      expect(
        (await CuentaService.loginCuenta(
          email: 'independent-owner@example.test',
          password: oldPassword,
        )).id,
        id,
      );
    },
  );

  test('acceso antiguo de alumno migra la lista tras ingreso válido', () async {
    final storage = StorageService.instance;
    await storage.setJsonList('v2_alumno_usuarios', [
      {
        'documento': '12345678',
        'email': 'old-student@example.test',
        'passwordHash': oldPassword,
      },
    ]);
    final service = AlumnoService.instance;
    expect(
      await service.loginAlumno(
        email: 'old-student@example.test',
        passwordHash: newPassword,
      ),
      isNull,
    );
    final migrated = await service.loginAlumno(
      email: 'old-student@example.test',
      passwordHash: oldPassword,
    );
    expect(migrated, isNotNull);
    expect(LocalPasswordHasher.isModern(migrated!.passwordHash), isTrue);
    expect(
      await LocalPasswordHasher.verify(oldPassword, migrated.passwordHash),
      isTrue,
    );
    final raw = await storage.getJsonList('v2_alumno_usuarios');
    expect(jsonEncode(raw), isNot(contains(oldPassword)));
  });
}
