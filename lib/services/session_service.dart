// lib/services/session_service.dart
//
// ATENA – SESSION SERVICE (CANÓNICO ÚNICO)
//
// Objetivo:
// - Mantener una sola sesión a la vez (userId + role).
// - Persistencia controlada por rememberMe.
// - Mantener compatibilidad con flujo CUENTA (perfil seleccionado),
//   pero evitando arrastres entre roles.
// - Helpers/guards claros para cuenta e institución.
//
// ✅ EXTENSIÓN (enero 2026) – Owner institución (best-effort):
// - Key v2_session_instOwnerAccountId para resolver ownerAccountId de institución
//   en pantallas operativas (ej: Documentos) sin mezclar stacks.
// - No rompe llamadas existentes: NO cambia la firma de setSession().
//
// ✅ FIX (feb 2026) – No inferir/pisar owner institucional:
// - El ownerAccountId institucional NO se puede inferir desde userId cuando userId = institucionPerfilId.
// - setSession()/setRole() NO setean owner institucional automáticamente.
// - El owner institucional se setea explícitamente vía setInstitucionOwnerAccountId()
//   (ej: desde CuentaHome al entrar a institución).
//
// ✅ FIX (feb 2026) – rememberMe=false NO puede borrar rol:
// - Aunque no persista entre reinicios, durante la ejecución actual necesitamos role/userId
//   para boot routing y pantallas operativas.
// - Solución: guardamos userId+role siempre, y marcamos sesión como temporal si rememberMe=false.
//   Luego puede limpiarse en boot con clearTempIfNeeded().
//
// ✅ HARDENING (feb 2026) – Anti-stale owner institucional:
// - Al entrar/switch a rol institución, limpiamos v2_session_instOwnerAccountId.
//   (evita que quede “owner viejo” si alguien setea rol/sesión sin setear owner explícito)
//
// ✅ HARDENING (feb 2026) – Anti-bug silencioso:
// - getSession() si ve residuos parciales, limpia y deja debug log claro.
// - setRole() preserva flags existentes (remember/temp) cuando es posible.
// - Todas las operaciones prefs están envueltas en try/catch (no debe crashear la app).
//
// ✅ FIX CRÍTICO (feb 2026 · E2E):
// - NO borrar instOwner “siempre” en setRole()/setSession() cuando NO hubo switch real.
//   Solo limpiamos instOwner cuando:
//   - cambia role (cuenta ↔ institución), o
//   - cambia userId (otra institución), o
//   - se entra a rol institución desde otro rol.
//   Esto evita el bug: setInstitucionOwnerAccountId() → luego setRole(institucion) → instOwner se borra.

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
  // =====================================================
  // KEYS
  // =====================================================

  static const String _kUserId = 'v2_session_userId';
  static const String _kRole = 'v2_session_role';
  static const String _kRemember = 'v2_session_rememberMe';

  /// ✅ Sesión temporal (si rememberMe=false)
  static const String _kTemp = 'v2_session_temp';

  /// Perfil seleccionado dentro de la CUENTA (legacy controlado)
  static const String _kPerfilSeleccionadoDni = 'v2_perfil_seleccionado_dni';

  /// ✅ Owner de institución (best-effort) para notificaciones / operaciones institucionales.
  static const String _kInstitucionOwnerAccountId =
      'v2_session_instOwnerAccountId';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // =====================================================
  // NORMALIZACIÓN
  // =====================================================

  static String _n(String v) => v.trim();

  /// IDs: trim + colapsa whitespace interno (lo elimina) para uso como key/lookup estable.
  /// ⚠️ Importante: NO lower-case. IDs canónicos pueden ser case-sensitive.
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  static String _roleToString(SessionRole r) => r.name;

  static SessionRole _roleFromString(String? v) {
    final raw = _n(v ?? '');
    if (raw.isEmpty) return SessionRole.cuenta;

    final needle = raw.toLowerCase();

    if (needle == 'cuenta') return SessionRole.cuenta;
    if (needle == 'institucion' || needle == 'institución') {
      return SessionRole.institucion;
    }

    try {
      return SessionRole.values.firstWhere(
        (e) => e.name.toLowerCase() == needle,
      );
    } catch (_) {
      return SessionRole.cuenta;
    }
  }

  // =====================================================
  // SESIÓN
  // =====================================================

  static Future<void> setSession({
    required String userId,
    required SessionRole role,
    required bool rememberMe,
  }) async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    final id = _normIdKey(userId);
    if (id.isEmpty) {
      await logout();
      return;
    }

    // 🔒 FIX: detectar cambios reales para limpiar instOwner solo cuando corresponde
    final prevUserId = _normIdKey(p.getString(_kUserId) ?? '');
    final prevRoleStr = _n(p.getString(_kRole) ?? '');
    final prevRole = _roleFromString(prevRoleStr);

    final roleChanged = prevRoleStr.isNotEmpty && prevRole != role;
    final userChanged = prevUserId.isNotEmpty && prevUserId != id;

    try {
      await p.setString(_kUserId, id);
      await p.setString(_kRole, _roleToString(role));
      await p.setBool(_kRemember, rememberMe);
      await p.setBool(_kTemp, !rememberMe);

      if (role == SessionRole.cuenta) {
        // Cuenta: nunca arrastrar owner institucional
        await p.remove(_kInstitucionOwnerAccountId);
      } else {
        // Institución: limpiar perfil seleccionado de cuenta SIEMPRE
        await p.remove(_kPerfilSeleccionadoDni);

        // Institución: limpiar instOwner SOLO si hubo switch real (role/user)
        // (anti-stale sin romper E2E cuando solo “refrescamos” el rol)
        final shouldClearInstOwner =
            roleChanged || userChanged || prevRole != SessionRole.institucion;
        if (shouldClearInstOwner) {
          await p.remove(_kInstitucionOwnerAccountId);
        }
      }
    } catch (_) {
      await logout();
    }
  }

  static Future<void> setRole(SessionRole role) async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    try {
      // 🔒 FIX: si setRole se llama con el mismo rol, NO borres instOwner.
      final prevRoleStr = _n(p.getString(_kRole) ?? '');
      final prevRole = _roleFromString(prevRoleStr);
      final roleChanged = prevRoleStr.isNotEmpty && prevRole != role;

      await p.setString(_kRole, _roleToString(role));

      final remember = p.getBool(_kRemember);
      final temp = p.getBool(_kTemp);

      if (remember != null && temp == null) {
        await p.setBool(_kTemp, !remember);
      }

      if (remember == null && temp == null) {
        await p.setBool(_kTemp, false);
      }

      // Limpiezas SOLO si hubo cambio real de rol
      if (roleChanged) {
        if (role == SessionRole.institucion) {
          await p.remove(_kPerfilSeleccionadoDni);
          await p.remove(_kInstitucionOwnerAccountId); // anti-stale al ENTRAR
        } else {
          await p.remove(_kInstitucionOwnerAccountId);
        }
      } else {
        // Si no cambió, solo asegurar coherencia mínima:
        if (role == SessionRole.institucion) {
          await p.remove(_kPerfilSeleccionadoDni);
        }
      }
    } catch (_) {}
  }

  static Future<SessionData?> getSession() async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return null;
    }

    final id = _normIdKey(p.getString(_kUserId) ?? '');
    final roleStr = _n(p.getString(_kRole) ?? '');

    if (id.isEmpty || roleStr.isEmpty) {
      final hasResidue =
          id.isNotEmpty ||
          roleStr.isNotEmpty ||
          (p.getBool(_kRemember) != null) ||
          (p.getBool(_kTemp) != null) ||
          _normIdKey(
            p.getString(_kInstitucionOwnerAccountId) ?? '',
          ).isNotEmpty ||
          _normIdKey(p.getString(_kPerfilSeleccionadoDni) ?? '').isNotEmpty;

      if (hasResidue) {
        // ignore: avoid_print
        print(
          '[ATENA][SESSION][getSession] residue detected (userId="$id", role="$roleStr") -> logout()',
        );
        await logout();
      }
      return null;
    }

    final role = _roleFromString(roleStr);
    final remember = p.getBool(_kRemember) ?? false;

    try {
      final temp = p.getBool(_kTemp);
      if (remember && temp == true) {
        await p.setBool(_kTemp, false);
      } else if (!remember && temp == null) {
        await p.setBool(_kTemp, true);
      }
    } catch (_) {}

    return SessionData(userId: id, role: role, rememberMe: remember);
  }

  static Future<void> clearTempIfNeeded() async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    final isTemp = p.getBool(_kTemp) ?? false;
    if (!isTemp) return;

    await logout();
  }

  static Future<void> logout() async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    try {
      await p.remove(_kUserId);
      await p.remove(_kRole);
      await p.remove(_kRemember);
      await p.remove(_kTemp);
      await p.remove(_kPerfilSeleccionadoDni);
      await p.remove(_kInstitucionOwnerAccountId);
    } catch (_) {}
  }

  static Future<void> clearAllSessionOnly() => logout();

  // =====================================================
  // PERFIL SELECCIONADO (DNI) – SOLO CUENTA
  // =====================================================

  static Future<void> setPerfilSeleccionado(String? dni) async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    final v = _normIdKey(dni ?? '');

    if (v.isEmpty) {
      try {
        await p.remove(_kPerfilSeleccionadoDni);
      } catch (_) {}
      return;
    }

    final s = await getSession();
    if (s == null || s.role != SessionRole.cuenta) {
      try {
        await p.remove(_kPerfilSeleccionadoDni);
      } catch (_) {}
      return;
    }

    try {
      await p.setString(_kPerfilSeleccionadoDni, v);
    } catch (_) {}
  }

  static Future<String?> getPerfilSeleccionado() async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return null;
    }

    final s = await getSession();
    if (s == null || s.role != SessionRole.cuenta) return null;

    final v = _normIdKey(p.getString(_kPerfilSeleccionadoDni) ?? '');
    return v.isEmpty ? null : v;
  }

  static Future<void> clearPerfilSeleccionado() => setPerfilSeleccionado(null);

  // =====================================================
  // OWNER INSTITUCIÓN (BEST-EFFORT)
  // =====================================================

  static Future<String?> getInstitucionOwnerAccountIdLogueado() async {
    final s = await getSession();
    if (s == null) return null;
    if (s.role != SessionRole.institucion) return null;

    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return null;
    }

    final v = _normIdKey(p.getString(_kInstitucionOwnerAccountId) ?? '');
    return v.isEmpty ? null : v;
  }

  static Future<void> setInstitucionOwnerAccountId(
    String? ownerAccountId,
  ) async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return;
    }

    final v = _normIdKey(ownerAccountId ?? '');
    if (v.isEmpty) {
      try {
        await p.remove(_kInstitucionOwnerAccountId);
      } catch (_) {}
      return;
    }

    final s = await getSession();
    if (s == null || s.role != SessionRole.institucion) {
      try {
        await p.remove(_kInstitucionOwnerAccountId);
      } catch (_) {}
      return;
    }

    try {
      await p.setString(_kInstitucionOwnerAccountId, v);
    } catch (_) {}
  }

  static Future<void> clearInstitucionOwnerAccountId() =>
      setInstitucionOwnerAccountId(null);

  // =====================================================
  // GUARDS / HELPERS
  // =====================================================

  static Future<bool> isRole(SessionRole role) async {
    final s = await getSession();
    return s != null && s.role == role && _normIdKey(s.userId).isNotEmpty;
  }

  static Future<SessionRole?> getRoleLogueado() async {
    final s = await getSession();
    return s?.role;
  }

  static Future<String?> getUserIdLogueado() async {
    final s = await getSession();
    if (s == null) return null;
    final id = _normIdKey(s.userId);
    return id.isEmpty ? null : id;
  }

  static Future<bool> hayCuentaLogueada() async {
    final s = await getSession();
    return s != null &&
        s.role == SessionRole.cuenta &&
        _normIdKey(s.userId).isNotEmpty;
  }

  static Future<String?> getCuentaIdLogueada() async {
    final s = await getSession();
    if (s == null) return null;
    if (s.role != SessionRole.cuenta) return null;
    final id = _normIdKey(s.userId);
    return id.isEmpty ? null : id;
  }

  static Future<bool> hayInstitucionLogueada() async {
    final s = await getSession();
    return s != null &&
        s.role == SessionRole.institucion &&
        _normIdKey(s.userId).isNotEmpty;
  }

  static Future<String?> getInstitucionIdLogueada() async {
    final s = await getSession();
    if (s == null) return null;
    if (s.role != SessionRole.institucion) return null;
    final id = _normIdKey(s.userId);
    return id.isEmpty ? null : id;
  }

  // =====================================================
  // DEBUG
  // =====================================================

  static Future<Map<String, dynamic>> debugSnapshot() async {
    SharedPreferences p;
    try {
      p = await _prefs();
    } catch (_) {
      return <String, dynamic>{'error': 'prefs_unavailable'};
    }

    final userId = _normIdKey(p.getString(_kUserId) ?? '');
    final roleRaw = _n(p.getString(_kRole) ?? '');
    final remember = p.getBool(_kRemember);
    final temp = p.getBool(_kTemp);

    final instOwner = _normIdKey(
      p.getString(_kInstitucionOwnerAccountId) ?? '',
    );
    final perfilSel = _normIdKey(p.getString(_kPerfilSeleccionadoDni) ?? '');

    final role = _roleFromString(roleRaw);

    return <String, dynamic>{
      'userId': userId,
      'roleRaw': roleRaw,
      'role': role.name,
      'rememberMe': remember,
      'temp': temp,
      'instOwner': instOwner,
      'perfilSeleccionadoDni': perfilSel,
    };
  }

  static Future<void> debugPrintSnapshot(String tag) async {
    try {
      final snap = await debugSnapshot();
      // ignore: avoid_print
      print('[ATENA][SESSION][$tag] $snap');
    } catch (_) {}
  }
}
