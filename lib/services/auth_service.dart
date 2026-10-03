// lib/services/auth_service.dart
//
// Punto único de autenticación y sesión de ATENA.
//
// - Familias/alumnos: cuenta (CuentaService) con uno o más perfiles de alumno.
// - Instituciones: credenciales propias (InstitucionService) + cuenta contenedora
//   + perfil institucional.
//
// Reglas:
// - Iniciar sesión con un rol limpia cualquier sesión del otro rol.
// - "Recordarme" desactivado: la sesión se descarta al reiniciar la app.
// - Cerrar sesión limpia ambas sesiones.

import '../core/repos/bajas_repo.dart';
import '../models/cuentas/cuenta.dart';
import 'auth_errors.dart';
import 'cuenta_service.dart';
import 'institucion_service.dart';
import 'session_service.dart';

/// Datos mínimos para abrir el inicio de una institución.
class InstitucionSesion {
  final String ownerAccountId;
  final String institucionPerfilId;
  final String? nombre;

  const InstitucionSesion({
    required this.ownerAccountId,
    required this.institucionPerfilId,
    this.nombre,
  });
}

/// Destino inicial según la sesión guardada.
sealed class AtenaHomeTarget {
  const AtenaHomeTarget();
}

class HomeLanding extends AtenaHomeTarget {
  const HomeLanding();
}

class HomeFamilia extends AtenaHomeTarget {
  final String cuentaId;
  const HomeFamilia(this.cuentaId);
}

class HomeInstitucion extends AtenaHomeTarget {
  final InstitucionSesion sesion;
  const HomeInstitucion(this.sesion);
}

class AuthService {
  const AuthService._();

  static String _norm(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  // ===========================================================================
  // FAMILIAS / ALUMNOS
  // ===========================================================================

  static Future<Cuenta> loginFamilia({
    required String email,
    required String password,
    required bool remember,
  }) async {
    await SessionService.logout();
    final cuenta = await CuentaService.loginCuenta(
      email: email,
      password: password,
      recordarme: remember,
    );

    // Las cuentas contenedoras de instituciones no ingresan como familia.
    if (cuenta.perfilesAlumnoIds.isEmpty &&
        cuenta.perfilesInstitucionIds.isNotEmpty) {
      await CuentaService.logoutCuenta();
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }
    return cuenta;
  }

  /// Crea la cuenta y su primer perfil de alumno.
  /// Valida los datos del perfil antes de crear la cuenta para no dejar
  /// cuentas a medio registrar.
  static Future<({Cuenta cuenta, PerfilAlumno perfil})> registrarFamilia({
    required String email,
    required String password,
    required bool remember,
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
    String? telefono,
  }) async {
    final dniDigits = dni.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^\d{7,9}$').hasMatch(dniDigits)) {
      throw const AuthException(AuthErrorCode.invalidDni);
    }
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      throw const AuthException(AuthErrorCode.invalidName);
    }

    await SessionService.logout();

    final cuenta = await CuentaService.registrarCuenta(
      email: email,
      password: password,
      recordarme: remember,
    );

    final perfil = await CuentaService.crearPerfilAlumno(
      cuentaId: cuenta.id,
      documento: dniDigits,
      nombre: nombre,
      apellido: apellido,
      fechaNacimiento: fechaNacimiento,
      email: email,
      telefono: telefono,
    );

    return (cuenta: cuenta, perfil: perfil);
  }

  static Future<void> restablecerPasswordFamilia({
    required String email,
    required String dni,
    required String nuevoPassword,
  }) {
    return CuentaService.restablecerPasswordVerificado(
      email: email,
      dni: dni,
      nuevoPassword: nuevoPassword,
    );
  }

  // ===========================================================================
  // INSTITUCIONES
  // ===========================================================================

  static Future<InstitucionSesion> loginInstitucion({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final auth = await InstitucionService.loginInstitucion(
      email: email,
      passwordHash: password,
    );
    if (auth == null) {
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }

    final owner = _norm(auth.institucionId);
    if (owner.isEmpty) throw const AuthException(AuthErrorCode.invalidAccount);

    final perfilId = await _resolverPerfilInstitucion(owner);

    return iniciarSesionInstitucion(
      ownerAccountId: owner,
      institucionPerfilId: perfilId,
      remember: remember,
      nombre: auth.institucionNombre,
    );
  }

  /// Abre la sesión institucional (después del login o del registro).
  static Future<InstitucionSesion> iniciarSesionInstitucion({
    required String ownerAccountId,
    required String institucionPerfilId,
    required bool remember,
    String? nombre,
  }) async {
    final owner = _norm(ownerAccountId);
    final perfil = _norm(institucionPerfilId);
    if (owner.isEmpty || perfil.isEmpty) {
      throw const AuthException(AuthErrorCode.invalidAccount);
    }

    await SessionService.setSession(
      userId: perfil,
      role: SessionRole.institucion,
      rememberMe: remember,
    );
    await SessionService.setInstitucionOwnerAccountId(owner);
    await CuentaService.setSesionCuentaId(owner, recordarme: remember);

    return InstitucionSesion(
      ownerAccountId: owner,
      institucionPerfilId: perfil,
      nombre: nombre,
    );
  }

  static Future<void> restablecerPasswordInstitucion({
    required String email,
    required String cuit,
    required String nuevoPassword,
  }) {
    return InstitucionService.restablecerPasswordVerificado(
      email: email,
      cuit: cuit,
      nuevoPassword: nuevoPassword,
    );
  }

  /// Perfil institucional a abrir: el último usado o el primero de la cuenta.
  static Future<String> _resolverPerfilInstitucion(String owner) async {
    try {
      final ultimo = (await CuentaService.getUltimoPerfil(owner) ?? '').trim();
      if (ultimo.startsWith('I|')) {
        final id = _norm(ultimo.substring(2));
        if (id.isNotEmpty &&
            await CuentaService.ownerTienePerfil(
              ownerAccountId: owner,
              perfilId: id,
            )) {
          return id;
        }
      }
    } catch (_) {}

    try {
      final perfiles = await CuentaService.listarPerfilesInstitucion(owner);
      if (perfiles.isNotEmpty) return _norm(perfiles.first.id);
    } catch (_) {}

    // Cuentas creadas por el registro: el primer perfil comparte id con la cuenta.
    return owner;
  }

  // ===========================================================================
  // BAJA DE CUENTA
  // ===========================================================================

  /// Elimina la cuenta familiar y sus alumnos. Pide la contraseña.
  static Future<void> eliminarCuentaFamilia({
    required String cuentaId,
    required String password,
  }) async {
    if (!await CuentaService.verificarPassword(cuentaId, password)) {
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }
    await BajasRepo.instance.eliminarFamilia(_norm(cuentaId));
    await logout();
  }

  /// Elimina la institución y todos sus datos. Pide la contraseña.
  static Future<void> eliminarCuentaInstitucion({
    required InstitucionSesion sesion,
    required String password,
  }) async {
    if (!await InstitucionService.verificarPassword(
      sesion.ownerAccountId,
      password,
    )) {
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }
    await BajasRepo.instance.eliminarInstitucion(
      institucionId: sesion.institucionPerfilId,
      ownerAccountId: sesion.ownerAccountId,
    );
    await logout();
  }

  // ===========================================================================
  // SESIÓN
  // ===========================================================================

  static Future<void> logout() async {
    try {
      await CuentaService.logoutCuenta();
    } catch (_) {}
    try {
      await SessionService.logout();
    } catch (_) {}
  }

  static bool _arranqueLimpio = false;

  /// Decide la pantalla inicial al abrir la app.
  static Future<AtenaHomeTarget> resolveHome() async {
    // Las sesiones sin "Recordarme" se descartan una sola vez, al arrancar.
    if (!_arranqueLimpio) {
      _arranqueLimpio = true;
      try {
        if (await CuentaService.isSesionTemporal()) {
          await logout();
          return const HomeLanding();
        }
        await SessionService.clearTempIfNeeded();
      } catch (_) {}
    }

    SessionData? session;
    try {
      session = await SessionService.getSession();
    } catch (_) {
      session = null;
    }

    var owner = '';
    try {
      owner = _norm(await CuentaService.getSesionCuentaId() ?? '');
    } catch (_) {}

    if (session != null && session.role == SessionRole.institucion) {
      if (owner.isEmpty) {
        try {
          owner = _norm(
            await SessionService.getInstitucionOwnerAccountIdLogueado() ?? '',
          );
        } catch (_) {}
      }
      final perfil = _norm(session.userId);
      if (owner.isEmpty || perfil.isEmpty) return const HomeLanding();
      return HomeInstitucion(
        InstitucionSesion(ownerAccountId: owner, institucionPerfilId: perfil),
      );
    }

    if (owner.isEmpty) return const HomeLanding();

    // Una cuenta de institución sin sesión institucional (sesión incompleta):
    // reabrimos su perfil institucional en lugar del hub de familias.
    try {
      final alumnos = await CuentaService.listarPerfilesAlumno(owner);
      if (alumnos.isEmpty) {
        final inst = await CuentaService.listarPerfilesInstitucion(owner);
        if (inst.isNotEmpty) {
          return HomeInstitucion(
            InstitucionSesion(
              ownerAccountId: owner,
              institucionPerfilId: _norm(inst.first.id),
            ),
          );
        }
      }
    } catch (_) {}

    return HomeFamilia(owner);
  }
}
