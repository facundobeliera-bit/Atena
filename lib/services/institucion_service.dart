// lib/services/institucion_service.dart
//
// Credenciales y datos de registro de las instituciones (almacenamiento local).
//
// - Credenciales: email + contraseña con hash PBKDF2 (ver PasswordHasher).
//   Las cuentas creadas por versiones anteriores, que guardaban la contraseña
//   en claro, se migran solas al ingresar.
// - Índice email → id para el ingreso y para impedir emails repetidos.
// - Cada institución tiene además una cuenta contenedora en CuentaService con
//   el mismo id y un email interno (`inst_<id>@atena.local`): así sus
//   credenciales no sirven en el ingreso de familias.
// - Este servicio no abre sesiones: eso lo hace AuthService.
//
// Las claves de versiones anteriores ("v1") solo se leen.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cuentas/cuenta.dart';
import '../models/instituciones/instituciones_integrado.dart';
import 'auth_errors.dart';
import 'cuenta_service.dart';
import 'password_hasher.dart';

class InstitucionService {
  const InstitucionService._();

  // ---------------------------------------------------------------------------
  // Normalización y validaciones
  // ---------------------------------------------------------------------------

  static String _normEmail(String email) => email.trim().toLowerCase();

  /// Ids como clave estable: sin espacios al inicio, al final ni internos.
  static String _normId(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  static bool _emailValido(String email) {
    final e = _normEmail(email);
    final at = e.indexOf('@');
    if (at <= 0 || at == e.length - 1) return false;
    final dot = e.lastIndexOf('.');
    return dot > at + 1 && dot < e.length - 1;
  }

  static bool _passValida(String pass) =>
      pass.length >= PasswordHasher.minLength && pass.trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Claves de almacenamiento
  // ---------------------------------------------------------------------------

  static String _kAuthById(String id) => 'atena_inst_auth_by_id_${_normId(id)}';

  static String _kAuthIdByEmail(String email) =>
      'atena_inst_auth_email_to_id_${_normEmail(email)}';

  static String _kInstitucionById(String id) =>
      'atena_institucion_by_id_${_normId(id)}';

  /// Alias de versiones anteriores: id alternativo → id de la institución.
  static String _kInstitucionAlias(String id) =>
      'atena_institucion_alias_${_normId(id)}';

  static String _kAuthByIdV1(String id) => 'inst_${id.trim()}';

  static String _kAuthIdByEmailV1(String email) =>
      'inst_email_${_normEmail(email)}';

  static String _newId() => 'INST_${DateTime.now().microsecondsSinceEpoch}';

  // ---------------------------------------------------------------------------
  // Credenciales
  // ---------------------------------------------------------------------------

  static _InstAccount? _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final id = (m['id'] ?? '').toString().trim();
      final email = _normEmail((m['email'] ?? '').toString());
      if (id.isEmpty || email.isEmpty) return null;
      return _InstAccount(
        id: id,
        email: email,
        // "password" es el nombre que usaban las versiones más antiguas.
        passwordHash: (m['passwordHash'] ?? m['password'] ?? '').toString(),
        nombre: (m['nombre'] ?? '').toString().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<_InstAccount?> _cargarPorId(String institucionId) async {
    final id = institucionId.trim();
    if (id.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_kAuthById(id))) ??
        _decode(prefs.getString(_kAuthByIdV1(id)));
  }

  static Future<_InstAccount?> _cargarPorEmail(String email) async {
    final e = _normEmail(email);
    if (e.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();

    final id = (prefs.getString(_kAuthIdByEmail(e)) ?? '').trim();
    if (id.isNotEmpty) {
      final a = await _cargarPorId(id);
      if (a != null) return a;
    }

    final idV1 = (prefs.getString(_kAuthIdByEmailV1(e)) ?? '').trim();
    return idV1.isEmpty ? null : _cargarPorId(idV1);
  }

  static Future<void> _guardar(_InstAccount a) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAuthById(a.id),
      jsonEncode({
        'id': a.id.trim(),
        'email': _normEmail(a.email),
        'passwordHash': a.passwordHash,
        'nombre': a.nombre.trim(),
      }),
    );
    await prefs.setString(_kAuthIdByEmail(a.email), _normId(a.id));
  }

  /// Garantiza la cuenta contenedora de la institución (mismo id, email
  /// interno). No abre sesión ni crea perfiles; si falla, no bloquea el acceso.
  static Future<void> _asegurarCuentaContenedora({
    required String institucionId,
    required String passwordHash,
  }) async {
    final id = _normId(institucionId);
    if (id.isEmpty) return;
    final emailInterno = 'inst_$id@atena.local';

    try {
      final existente = await CuentaService.getCuentaById(id);
      if (existente == null) {
        await CuentaService.actualizarCuenta(
          Cuenta(
            id: id,
            email: emailInterno,
            passwordHash: passwordHash,
            perfilesAlumnoIds: <String>[],
            perfilesInstitucionIds: <String>[],
            recordarme: true,
            creadaEl: DateTime.now(),
            ultimaSesion: DateTime.now(),
          ),
        );
        return;
      }

      // Cuentas de versiones anteriores usaban el email real: se pasa al
      // interno para liberar ese email y separar ambos ingresos.
      if (_normEmail(existente.email) != emailInterno) {
        final otra = await CuentaService.getCuentaByEmail(emailInterno);
        if (otra == null || _normId(otra.id) == id) {
          await CuentaService.actualizarCuenta(
            Cuenta(
              id: existente.id,
              email: emailInterno,
              passwordHash: existente.passwordHash,
              perfilesAlumnoIds: existente.perfilesAlumnoIds,
              perfilesInstitucionIds: existente.perfilesInstitucionIds,
              recordarme: existente.recordarme,
              creadaEl: existente.creadaEl,
              ultimaSesion: existente.ultimaSesion,
            ),
          );
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Registro e ingreso
  // ---------------------------------------------------------------------------

  static Future<String?> getNombreInstitucionById(String institucionId) async =>
      (await _cargarPorId(institucionId))?.nombre.trim();

  static Future<String?> getInstitucionIdByEmail(String email) async =>
      (await _cargarPorEmail(email))?.id;

  /// Crea las credenciales de una institución.
  ///
  /// [passwordHash] recibe la contraseña tal como la escribió el usuario (el
  /// nombre del parámetro se conserva por compatibilidad); acá se guarda su
  /// hash. El id devuelto es también el de su cuenta contenedora.
  static Future<InstitucionLoginResult> registrarInstitucion({
    required String email,
    required String passwordHash,
    required String nombre,
  }) async {
    final e = _normEmail(email);
    final n = nombre.trim();

    if (!_emailValido(e)) throw const AuthException(AuthErrorCode.invalidEmail);
    if (!_passValida(passwordHash)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }
    if (n.isEmpty) throw const AuthException(AuthErrorCode.invalidName);
    if (await _cargarPorEmail(e) != null) {
      throw const AuthException(AuthErrorCode.emailInUse);
    }

    final nuevo = _InstAccount(
      id: _newId(),
      email: e,
      passwordHash: PasswordHasher.hash(passwordHash),
      nombre: n,
    );
    await _guardar(nuevo);
    await _asegurarCuentaContenedora(
      institucionId: nuevo.id,
      passwordHash: nuevo.passwordHash,
    );

    return InstitucionLoginResult(
      institucionId: nuevo.id,
      institucionNombre: nuevo.nombre,
    );
  }

  /// Verifica email y contraseña. Devuelve null si no coinciden.
  ///
  /// [passwordHash] recibe la contraseña tal como la escribió el usuario.
  static Future<InstitucionLoginResult?> loginInstitucion({
    required String email,
    required String passwordHash,
  }) async {
    final e = _normEmail(email);
    if (e.isEmpty || passwordHash.isEmpty) return null;

    final found = await _cargarPorEmail(e);
    if (found == null ||
        !PasswordHasher.verify(
          passwordHash,
          found.passwordHash,
          legacy: LegacyPasswordFormat.plain,
        )) {
      return null;
    }

    // Migración transparente de contraseñas guardadas en claro.
    var cuenta = found;
    if (PasswordHasher.needsRehash(found.passwordHash)) {
      cuenta = _InstAccount(
        id: found.id,
        email: found.email,
        passwordHash: PasswordHasher.hash(passwordHash),
        nombre: found.nombre,
      );
      await _guardar(cuenta);
    }

    await _asegurarCuentaContenedora(
      institucionId: cuenta.id,
      passwordHash: cuenta.passwordHash,
    );

    return InstitucionLoginResult(
      institucionId: cuenta.id,
      institucionNombre: cuenta.nombre.trim(),
    );
  }

  /// true si la contraseña corresponde a la institución (para confirmar
  /// acciones).
  static Future<bool> verificarPassword(
    String institucionId,
    String password,
  ) async {
    if (password.isEmpty) return false;
    final a = await _cargarPorId(institucionId);
    return a != null &&
        PasswordHasher.verify(
          password,
          a.passwordHash,
          legacy: LegacyPasswordFormat.plain,
        );
  }

  // ---------------------------------------------------------------------------
  // Datos de la institución
  // ---------------------------------------------------------------------------

  static Future<void> upsertInstitucion(Institucion institucion) async {
    final id = _normId(institucion.id);
    if (id.isEmpty) throw ArgumentError('La institución necesita un id');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInstitucionById(id), institucion.toJson());
  }

  static Future<Institucion?> getInstitucionById(String institucionId) async {
    final id = _normId(institucionId);
    if (id.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();

    Institucion? leer(String clave) {
      final s = prefs.getString(_kInstitucionById(clave));
      if (s == null || s.trim().isEmpty) return null;
      try {
        return Institucion.fromJson(s);
      } catch (_) {
        return null;
      }
    }

    final directa = leer(id);
    if (directa != null) return directa;

    final alias = _normId(prefs.getString(_kInstitucionAlias(id)) ?? '');
    return alias.isEmpty ? null : leer(alias);
  }

  // ---------------------------------------------------------------------------
  // Cambios de credenciales
  // ---------------------------------------------------------------------------

  static Future<void> actualizarCredenciales({
    required String institucionId,
    String? nuevoEmail,
    String? nuevoPassword,
    String? nuevoNombre,
  }) async {
    final actual = await _cargarPorId(institucionId);
    if (actual == null) {
      throw const AuthException(AuthErrorCode.accountNotFound);
    }

    final email = _normEmail(nuevoEmail ?? actual.email);
    final nombre = (nuevoNombre ?? actual.nombre).trim();

    if (!_emailValido(email)) {
      throw const AuthException(AuthErrorCode.invalidEmail);
    }
    if (nuevoPassword != null && !_passValida(nuevoPassword)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }
    if (nombre.isEmpty) throw const AuthException(AuthErrorCode.invalidName);

    final prefs = await SharedPreferences.getInstance();
    if (email != actual.email) {
      for (final clave in [_kAuthIdByEmail(email), _kAuthIdByEmailV1(email)]) {
        final tomado = _normId(prefs.getString(clave) ?? '');
        if (tomado.isNotEmpty && tomado != _normId(actual.id)) {
          throw const AuthException(AuthErrorCode.emailInUse);
        }
      }
      await prefs.remove(_kAuthIdByEmail(actual.email));
      await prefs.remove(_kAuthIdByEmailV1(actual.email));
    }

    await _guardar(
      _InstAccount(
        id: actual.id,
        email: email,
        passwordHash: nuevoPassword == null
            ? actual.passwordHash
            : PasswordHasher.hash(nuevoPassword),
        nombre: nombre,
      ),
    );
  }

  /// Restablece la contraseña verificando la identidad con el CUIT registrado
  /// (no hay envío de emails en esta versión).
  static Future<void> restablecerPasswordVerificado({
    required String email,
    required String cuit,
    required String nuevoPassword,
  }) async {
    final id = await getInstitucionIdByEmail(email);
    final digits = cuit.replaceAll(RegExp(r'[^0-9]'), '');
    if (id == null || id.trim().isEmpty || digits.isEmpty) {
      throw const AuthException(AuthErrorCode.identityMismatch);
    }

    final inst = await getInstitucionById(id);
    final registrado = (inst?.cuit ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (registrado.isEmpty || registrado != digits) {
      throw const AuthException(AuthErrorCode.identityMismatch);
    }

    await actualizarCredenciales(
      institucionId: id,
      nuevoPassword: nuevoPassword,
    );
  }
}

class InstitucionLoginResult {
  /// Id de la institución; también es el de su cuenta contenedora.
  final String institucionId;

  final String institucionNombre;

  const InstitucionLoginResult({
    required this.institucionId,
    required this.institucionNombre,
  });

  String get ownerAccountId => institucionId;
}

class _InstAccount {
  final String id;
  final String email;
  final String passwordHash;
  final String nombre;

  const _InstAccount({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.nombre,
  });
}
