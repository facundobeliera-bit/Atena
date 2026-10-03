// lib/services/session_service.dart
//
// Sesión abierta en el dispositivo: quién entró y con qué rol.
//
// - Una sola sesión a la vez (id + rol).
// - Si el usuario no eligió "Recordarme", la sesión queda marcada como
//   temporal y se descarta al reiniciar la app (ver AuthService.resolveHome).
// - Para instituciones se guarda además el id de su cuenta contenedora.
//
// La sesión de las cuentas familiares la lleva CuentaService; AuthService
// coordina ambas.

import 'package:shared_preferences/shared_preferences.dart';

enum SessionRole { cuenta, institucion }

class SessionData {
  final String userId;
  final SessionRole role;
  final bool rememberMe;

  const SessionData({
    required this.userId,
    required this.role,
    required this.rememberMe,
  });
}

class SessionService {
  const SessionService._();

  static const String _kUserId = 'v2_session_userId';
  static const String _kRole = 'v2_session_role';
  static const String _kRemember = 'v2_session_rememberMe';
  static const String _kTemp = 'v2_session_temp';
  static const String _kInstitucionOwnerAccountId =
      'v2_session_instOwnerAccountId';

  /// Clave de versiones anteriores; solo se limpia.
  static const String _kPerfilSeleccionadoDni = 'v2_perfil_seleccionado_dni';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// Ids como clave estable: sin espacios al inicio, al final ni internos.
  static String _normId(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  static SessionRole _roleFromString(String v) {
    final s = v.trim().toLowerCase();
    return s == 'institucion' || s == 'institución'
        ? SessionRole.institucion
        : SessionRole.cuenta;
  }

  static Future<void> setSession({
    required String userId,
    required SessionRole role,
    required bool rememberMe,
  }) async {
    final id = _normId(userId);
    if (id.isEmpty) return logout();

    try {
      final p = await _prefs();
      final idAnterior = _normId(p.getString(_kUserId) ?? '');
      final rolAnterior = (p.getString(_kRole) ?? '').trim();
      // La cuenta contenedora guardada solo vale para la misma institución.
      final mismaInstitucion =
          role == SessionRole.institucion &&
          idAnterior == id &&
          rolAnterior.isNotEmpty &&
          _roleFromString(rolAnterior) == SessionRole.institucion;

      await p.setString(_kUserId, id);
      await p.setString(_kRole, role.name);
      await p.setBool(_kRemember, rememberMe);
      await p.setBool(_kTemp, !rememberMe);
      await p.remove(_kPerfilSeleccionadoDni);
      if (!mismaInstitucion) await p.remove(_kInstitucionOwnerAccountId);
    } catch (_) {
      await logout();
    }
  }

  static Future<SessionData?> getSession() async {
    try {
      final p = await _prefs();
      final id = _normId(p.getString(_kUserId) ?? '');
      final rol = (p.getString(_kRole) ?? '').trim();

      if (id.isEmpty || rol.isEmpty) {
        // Una sesión a medio guardar no sirve: se limpia.
        if (id.isNotEmpty || rol.isNotEmpty) await logout();
        return null;
      }

      return SessionData(
        userId: id,
        role: _roleFromString(rol),
        rememberMe: p.getBool(_kRemember) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Descarta la sesión si se abrió sin "Recordarme".
  static Future<void> clearTempIfNeeded() async {
    try {
      final p = await _prefs();
      // Sesiones de versiones anteriores no traen la marca: se deduce.
      final temporal = p.getBool(_kTemp) ?? !(p.getBool(_kRemember) ?? true);
      if (temporal) await logout();
    } catch (_) {}
  }

  static Future<void> logout() async {
    try {
      final p = await _prefs();
      for (final k in const [
        _kUserId,
        _kRole,
        _kRemember,
        _kTemp,
        _kPerfilSeleccionadoDni,
        _kInstitucionOwnerAccountId,
      ]) {
        await p.remove(k);
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Cuenta contenedora de la institución en sesión
  // ---------------------------------------------------------------------------

  static Future<String?> getInstitucionOwnerAccountIdLogueado() async {
    final s = await getSession();
    if (s == null || s.role != SessionRole.institucion) return null;
    try {
      final p = await _prefs();
      final v = _normId(p.getString(_kInstitucionOwnerAccountId) ?? '');
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setInstitucionOwnerAccountId(
    String? ownerAccountId,
  ) async {
    final v = _normId(ownerAccountId ?? '');
    final s = await getSession();
    try {
      final p = await _prefs();
      if (v.isEmpty || s == null || s.role != SessionRole.institucion) {
        await p.remove(_kInstitucionOwnerAccountId);
      } else {
        await p.setString(_kInstitucionOwnerAccountId, v);
      }
    } catch (_) {}
  }
}
