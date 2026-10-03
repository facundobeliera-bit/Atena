// lib/services/cuenta_service.dart
//
// Cuentas y perfiles (almacenamiento local).
//
// - Una cuenta (email + contraseña con hash PBKDF2) agrupa perfiles de alumno
//   (familias) o de institución (cuenta contenedora de una institución).
// - Índices: email → cuenta y DNI → perfil de alumno.
// - Sesión de cuenta, con marca de "temporal" cuando el usuario no eligió
//   "Recordarme" (AuthService la descarta al arrancar la app).
// - "Último perfil usado" por cuenta, etiquetado por rol (`A|id` / `I|id`).
//
// Tolerancia con datos de versiones anteriores:
// - Las claves se leen primero en su forma actual (id sin espacios) y, si no
//   están, en la forma anterior; al leerlas se vuelven a guardar en la actual.
// - Las contraseñas guardadas con el formato anterior se migran al ingresar.
// - Si un perfil quedó en la lista del rol equivocado, se corrige al listar.
//
// Modelos: ../models/cuentas/cuenta.dart

import 'dart:convert';
import 'dart:math';

import '../models/cuentas/cuenta.dart';
import 'auth_errors.dart';
import 'password_hasher.dart';
import 'storage_service.dart';

class CuentaService {
  CuentaService._();
  static final CuentaService instance = CuentaService._();

  // =====================================================
  // NORMALIZACIÓN
  // =====================================================

  /// ✅ Igual criterio que SessionService para ids como key estable:
  /// - trim
  /// - elimina whitespace interno (tabs/espacios/newlines)
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  /// ✅ Para valores "humanos" (no keys): trim + colapsa a 1 espacio.
  /// Útil si alguna UI/servicio guarda ids con espacios internos por error.
  static String _normIdValue(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _normEmail(String email) => email.trim().toLowerCase();

  // ✅ HARDENING: DNI solo dígitos (índice estable)
  static String _normDni(String dni) =>
      dni.replaceAll(RegExp(r'[^0-9]'), '').trim();

  // =====================================================
  // KEYS (canónicas + compat legacy)
  // =====================================================

  // --- Key builders canónicos (usan _normIdKey)
  static String _kCuentaById(String id) => 'cuenta_${_normIdKey(id)}';
  static String _kPerfilAlumnoById(String perfilId) =>
      'perfil_alumno_${_normIdKey(perfilId)}';
  static String _kPerfilInstitucionById(String perfilId) =>
      'perfil_institucion_${_normIdKey(perfilId)}';
  static String _kUltimoPerfilByCuenta(String cuentaId) =>
      'cuenta_ultimo_perfil_${_normIdKey(cuentaId)}';

  // --- Legacy key builders (trim-only) para leer data vieja
  static String _kCuentaByIdLegacyTrim(String id) => 'cuenta_${id.trim()}';
  static String _kPerfilAlumnoByIdLegacyTrim(String perfilId) =>
      'perfil_alumno_${perfilId.trim()}';
  static String _kPerfilInstitucionByIdLegacyTrim(String perfilId) =>
      'perfil_institucion_${perfilId.trim()}';
  static String _kUltimoPerfilByCuentaLegacyTrim(String cuentaId) =>
      'cuenta_ultimo_perfil_${cuentaId.trim()}';

  static String _kCuentaIdByEmail(String email) =>
      'cuenta_email_${_normEmail(email)}';

  // Sesión: SOLO Cuenta
  static const String _kSesionCuenta = 'sesion_cuenta';

  // ✅ Sesión temporal (si recordarme=false)
  static const String _kSesionCuentaTemp = 'sesion_cuenta_temp';

  // Índices opcionales (para búsquedas rápidas / migración)
  static String _kIndexPerfilAlumnoByDni(String dni) =>
      'idx_perfil_dni_${_normDni(dni)}';

  // =====================================================
  // ÚLTIMO PERFIL (Recordarme / cuenta única)
  // =====================================================

  // ✅ Tags anti-cruce (CuentaHomePage ya los entiende)
  static const String _lpAlumno = 'A|';
  static const String _lpInstitucion = 'I|';

  // ✅ Guardar ids en tags con formato estable
  static String _encodeUltimoAlumno(String perfilId) =>
      '$_lpAlumno${_normIdKey(perfilId)}';

  static String _encodeUltimoInstitucion(String perfilId) =>
      '$_lpInstitucion${_normIdKey(perfilId)}';

  static bool _isTaggedUltimoPerfil(String v) {
    final t = v.trim();
    return t.startsWith(_lpAlumno) || t.startsWith(_lpInstitucion);
  }

  static Future<void> setUltimoPerfil(String cuentaId, String perfilId) async {
    return instance.setUltimoPerfilInst(cuentaId, perfilId);
  }

  /// ✅ CANÓNICO:
  /// - Si ya viene taggeado (A| / I|), lo guarda tal cual.
  /// - Si viene “pelado” (legacy), intenta inferir el tipo mirando la cuenta
  ///   (perfilesAlumnoIds / perfilesInstitucionIds) y lo guarda con tag.
  /// - Si no puede inferir, guarda legacy (compat).
  ///
  /// ✅ Compat keys:
  /// - Guarda en key canónica y legacy-trim si difieren.
  Future<void> setUltimoPerfilInst(String cuentaId, String perfilId) async {
    final cRaw = cuentaId.trim();
    final pRaw = perfilId.trim();
    if (cRaw.isEmpty || pRaw.isEmpty) return;

    final cKey = _normIdKey(cRaw);
    if (cKey.isEmpty) return;

    String toStore = pRaw;

    if (!_isTaggedUltimoPerfil(pRaw)) {
      // Intento inferencia robusta (comparación por key estable)
      try {
        final cuenta = await getCuentaById(cKey);
        if (cuenta != null) {
          final pidKey = _normIdKey(pRaw);

          final a = cuenta.perfilesAlumnoIds.map(_normIdKey).toList();
          final i = cuenta.perfilesInstitucionIds.map(_normIdKey).toList();

          if (pidKey.isNotEmpty && a.contains(pidKey)) {
            toStore = _encodeUltimoAlumno(pidKey);
          } else if (pidKey.isNotEmpty && i.contains(pidKey)) {
            toStore = _encodeUltimoInstitucion(pidKey);
          } else {
            // compat legacy (pelado)
            toStore = pRaw;
          }
        }
      } catch (_) {
        // compat legacy
        toStore = pRaw;
      }
    }

    final storage = StorageService.instance;

    final kCanon = _kUltimoPerfilByCuenta(cKey);
    final kLegacy = _kUltimoPerfilByCuentaLegacyTrim(cRaw);

    await storage.setString(kCanon, toStore);
    if (kLegacy != kCanon) {
      await storage.setString(kLegacy, toStore);
    }
  }

  static Future<String?> getUltimoPerfil(String cuentaId) async {
    return instance.getUltimoPerfilInst(cuentaId);
  }

  Future<String?> getUltimoPerfilInst(String cuentaId) async {
    final cRaw = cuentaId.trim();
    if (cRaw.isEmpty) return null;

    final storage = StorageService.instance;

    // 1) Canónico
    final v1 = await storage.getString(_kUltimoPerfilByCuenta(cRaw));
    if (v1 != null && v1.trim().isNotEmpty) return v1.trim();

    // 2) Legacy trim
    final v2 = await storage.getString(_kUltimoPerfilByCuentaLegacyTrim(cRaw));
    if (v2 != null && v2.trim().isNotEmpty) return v2.trim();

    return null;
  }

  // =====================================================
  // IDS
  // =====================================================

  static String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${prefix}_${now}_$rnd';
  }

  static String _newCuentaId() => _newId('C');
  static String _newPerfilId() => _newId('P');

  // =====================================================
  // VALIDACIONES
  // =====================================================

  static bool _emailValido(String email) {
    final e = _normEmail(email);
    final at = e.indexOf('@');
    if (at <= 0) return false;
    if (at == e.length - 1) return false;
    final dot = e.lastIndexOf('.');
    if (dot <= at + 1) return false;
    if (dot == e.length - 1) return false;
    return true;
  }

  /// Contraseñas nuevas (registro / cambio).
  static bool _passValida(String pass) =>
      pass.length >= PasswordHasher.minLength && pass.trim().isNotEmpty;

  static bool _dniValido(String doc) {
    final d = _normDni(doc);
    if (d.isEmpty) return false;
    return RegExp(r'^\d{7,9}$').hasMatch(d);
  }

  static String _hashPass(String pass) => PasswordHasher.hash(pass);

  // =====================================================
  // SESIÓN
  // =====================================================

  static Future<void> logoutCuenta() async {
    final storage = StorageService.instance;
    await storage.remove(_kSesionCuenta);
    await storage.remove(_kSesionCuentaTemp);
  }

  static Future<String?> getSesionCuentaId() async {
    final storage = StorageService.instance;
    final raw = await storage.getString(_kSesionCuenta);
    if (raw == null || raw.trim().isEmpty) return null;

    String? extracted;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        extracted =
            (decoded['cuentaId'] ??
                    decoded['id'] ??
                    decoded['ownerAccountId'] ??
                    '')
                .toString()
                .trim();
      } else if (decoded is String) {
        extracted = decoded.trim();
      } else {
        extracted = null;
      }
    } catch (_) {
      extracted = raw.trim(); // compat: legacy guardaba el id plano
    }

    // ✅ key estable (sin whitespace interno)
    final id = _normIdKey(extracted ?? '');
    if (id.isNotEmpty) return id;

    // ✅ fallback extra
    final id2 = _normIdKey(_normIdValue(extracted ?? ''));
    return id2.isEmpty ? null : id2;
  }

  /// ✅ NUEVO (CIERRE CANÓNICO):
  /// setea sesión de cuenta (ownerAccountId) desde flujos no-email/pass.
  ///
  /// ✅ FIX (recordarme):
  /// - Guardamos SIEMPRE la sesión para la ejecución actual.
  /// - Si recordarme=false, marcamos flag temporal (para limpieza en boot/logout).
  static Future<void> setSesionCuentaId(
    String cuentaId, {
    bool recordarme = true,
  }) async {
    final id = _normIdKey(cuentaId);
    if (id.isEmpty) return;

    await _setSesionCuenta(id);

    final storage = StorageService.instance;
    if (recordarme) {
      await storage.remove(_kSesionCuentaTemp);
    } else {
      await storage.setBool(_kSesionCuentaTemp, true);
    }
  }

  static Future<void> _setSesionCuenta(String cuentaId) async {
    final id = _normIdKey(cuentaId);
    if (id.isEmpty) return;

    final storage = StorageService.instance;
    final payload = jsonEncode({
      'cuentaId': id,
      'ts': DateTime.now().toIso8601String(),
    });
    await storage.setString(_kSesionCuenta, payload);
  }

  static Future<void> _clearSesionCuenta() async {
    final storage = StorageService.instance;
    await storage.remove(_kSesionCuenta);
    await storage.remove(_kSesionCuentaTemp);
  }

  /// ✅ Opcional recomendado:
  /// Si la sesión está marcada como temporal, la limpiamos.
  /// Esto sirve si querés que "Recordarme" OFF no sobreviva reinicios.
  static Future<void> clearSesionTemporalIfNeeded() async {
    if (!await isSesionTemporal()) return;
    await _clearSesionCuenta();
  }

  /// true si la sesión actual se inició con "Recordarme" desactivado.
  static Future<bool> isSesionTemporal() async {
    final storage = StorageService.instance;
    return await storage.getBool(_kSesionCuentaTemp) ?? false;
  }

  // =====================================================
  // CUENTA: CRUD + AUTH
  // =====================================================

  static Future<Cuenta?> getCuentaById(String cuentaId) async {
    final id = _normIdKey(cuentaId);
    if (id.isEmpty) return null;

    final storage = StorageService.instance;

    // 1) Canónico
    final raw1 = await storage.getString(_kCuentaById(id));
    if (raw1 != null && raw1.trim().isNotEmpty) {
      try {
        return Cuenta.fromJson(raw1);
      } catch (_) {}
    }

    // 2) Legacy trim
    final raw2 = await storage.getString(_kCuentaByIdLegacyTrim(cuentaId));
    if (raw2 != null && raw2.trim().isNotEmpty) {
      try {
        final c = Cuenta.fromJson(raw2);

        // Migración suave: re-save en key canónica (best-effort)
        try {
          await _saveCuenta(c);
        } catch (_) {}

        return c;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static Future<Cuenta?> getCuentaByEmail(String email) async {
    final storage = StorageService.instance;
    final e = _normEmail(email);
    final id = await storage.getString(_kCuentaIdByEmail(e));
    if (id == null || id.trim().isEmpty) return null;
    return getCuentaById(id.trim());
  }

  static Future<String?> getCuentaIdByEmail(String email) async {
    final e = _normEmail(email);
    if (!_emailValido(e)) return null;

    final storage = StorageService.instance;
    final id = (await storage.getString(_kCuentaIdByEmail(e)) ?? '').trim();
    return id.isEmpty ? null : id;
  }

  static Future<void> actualizarPasswordCuenta({
    required String cuentaId,
    required String nuevoPassword,
  }) async {
    final id = _normIdKey(cuentaId);
    final pass = nuevoPassword;

    if (id.isEmpty) throw const AuthException(AuthErrorCode.invalidAccount);
    if (!_passValida(pass)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }

    final cuenta = await getCuentaById(id);
    if (cuenta == null) {
      throw const AuthException(AuthErrorCode.accountNotFound);
    }

    final updated = Cuenta(
      id: cuenta.id.trim(),
      email: _normEmail(cuenta.email),
      passwordHash: _hashPass(pass),
      perfilesAlumnoIds: List<String>.from(cuenta.perfilesAlumnoIds),
      perfilesInstitucionIds: List<String>.from(cuenta.perfilesInstitucionIds),
      recordarme: cuenta.recordarme,
      creadaEl: cuenta.creadaEl,
      ultimaSesion: DateTime.now(),
    );

    await _saveCuenta(updated);
  }

  static Future<void> _saveCuenta(Cuenta cuenta) async {
    final storage = StorageService.instance;

    final idCanon = _normIdKey(cuenta.id);
    if (idCanon.isEmpty) return;

    final normalizedEmail = _normEmail(cuenta.email);

    // Si el email cambió, limpiamos mapeo previo (best-effort)
    try {
      final rawPrev = await storage.getString(_kCuentaById(idCanon));
      if (rawPrev != null && rawPrev.trim().isNotEmpty) {
        final prev = Cuenta.fromJson(rawPrev);
        final prevEmail = _normEmail(prev.email);
        if (prevEmail.isNotEmpty && prevEmail != normalizedEmail) {
          final oldKey = _kCuentaIdByEmail(prevEmail);
          final mappedId = (await storage.getString(oldKey) ?? '').trim();
          if (_normIdKey(mappedId) == idCanon) {
            await storage.remove(oldKey);
          }
        }
      }
    } catch (_) {}

    final canon = Cuenta(
      id: idCanon,
      email: normalizedEmail,
      passwordHash: cuenta.passwordHash,
      perfilesAlumnoIds: List<String>.from(cuenta.perfilesAlumnoIds),
      perfilesInstitucionIds: List<String>.from(cuenta.perfilesInstitucionIds),
      recordarme: cuenta.recordarme,
      creadaEl: cuenta.creadaEl,
      ultimaSesion: cuenta.ultimaSesion,
    );

    // ✅ Write canónico
    await storage.setString(_kCuentaById(idCanon), canon.toJson());

    // ✅ Write legacy-trim si difiere (migración suave)
    final legacyKey = _kCuentaByIdLegacyTrim(cuenta.id);
    final canonKey = _kCuentaById(idCanon);
    if (legacyKey != canonKey) {
      await storage.setString(legacyKey, canon.toJson());
    }

    if (normalizedEmail.isNotEmpty) {
      await storage.setString(_kCuentaIdByEmail(normalizedEmail), idCanon);
    }
  }

  static Future<void> actualizarCuenta(Cuenta cuenta) async {
    await _saveCuenta(cuenta);
  }

  static Future<Cuenta> registrarCuenta({
    required String email,
    required String password,
    bool recordarme = true,
  }) async {
    final e = _normEmail(email);
    if (!_emailValido(e)) throw const AuthException(AuthErrorCode.invalidEmail);
    if (!_passValida(password)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }

    final storage = StorageService.instance;
    final existenteId = (await storage.getString(_kCuentaIdByEmail(e)) ?? '')
        .trim();
    if (existenteId.isNotEmpty) {
      throw const AuthException(AuthErrorCode.emailInUse);
    }

    final cuenta = Cuenta(
      id: _newCuentaId(),
      email: e,
      passwordHash: _hashPass(password),
      perfilesAlumnoIds: <String>[],
      perfilesInstitucionIds: <String>[],
      recordarme: recordarme,
      creadaEl: DateTime.now(),
      ultimaSesion: DateTime.now(),
    );

    await _saveCuenta(cuenta);
    await setSesionCuentaId(cuenta.id, recordarme: recordarme);

    return cuenta;
  }

  static Future<Cuenta> loginCuenta({
    required String email,
    required String password,
    bool recordarme = true,
  }) async {
    final e = _normEmail(email);
    if (!_emailValido(e)) throw const AuthException(AuthErrorCode.invalidEmail);
    if (password.isEmpty) {
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }

    final found = await getCuentaByEmail(e);
    // Mismo mensaje para email inexistente y contraseña errónea
    // (no revela qué emails están registrados).
    if (found == null || !PasswordHasher.verify(password, found.passwordHash)) {
      throw const AuthException(AuthErrorCode.wrongCredentials);
    }

    // Migración transparente de hashes viejos.
    final cuenta = PasswordHasher.needsRehash(found.passwordHash)
        ? Cuenta(
            id: found.id,
            email: found.email,
            passwordHash: _hashPass(password),
            perfilesAlumnoIds: found.perfilesAlumnoIds,
            perfilesInstitucionIds: found.perfilesInstitucionIds,
            recordarme: found.recordarme,
            creadaEl: found.creadaEl,
            ultimaSesion: found.ultimaSesion,
          )
        : found;

    cuenta.ultimaSesion = DateTime.now();
    cuenta.recordarme = recordarme;
    await _saveCuenta(cuenta);

    await setSesionCuentaId(cuenta.id, recordarme: recordarme);

    return cuenta;
  }

  /// true si la contraseña corresponde a la cuenta (para confirmar acciones).
  static Future<bool> verificarPassword(
    String cuentaId,
    String password,
  ) async {
    if (password.isEmpty) return false;
    final cuenta = await getCuentaById(cuentaId);
    return cuenta != null &&
        PasswordHasher.verify(password, cuenta.passwordHash);
  }

  /// Restablece la contraseña verificando la identidad con el DNI de un
  /// perfil de alumno de la cuenta (no hay envío de emails en esta versión).
  static Future<void> restablecerPasswordVerificado({
    required String email,
    required String dni,
    required String nuevoPassword,
  }) async {
    final e = _normEmail(email);
    if (!_emailValido(e)) throw const AuthException(AuthErrorCode.invalidEmail);
    if (!_passValida(nuevoPassword)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }

    final cuenta = await getCuentaByEmail(e);
    final doc = _normDni(dni);
    if (cuenta == null || doc.isEmpty) {
      throw const AuthException(AuthErrorCode.identityMismatch);
    }

    final perfiles = await listarPerfilesAlumno(cuenta.id);
    final coincide = perfiles.any((p) => _normDni(p.documento) == doc);
    if (!coincide) throw const AuthException(AuthErrorCode.identityMismatch);

    await actualizarPasswordCuenta(
      cuentaId: cuenta.id,
      nuevoPassword: nuevoPassword,
    );
  }

  // =====================================================
  // OWNER RESOLVER
  // =====================================================

  static Future<String?> getOwnerAccountIdForPerfilAlumno(
    String perfilId,
  ) async {
    final p = await getPerfilAlumnoById(perfilId);
    if (p == null) return null;
    final owner = _normIdKey((p.ownerAccountId ?? '').trim());
    if (owner.isNotEmpty) return owner;
    final c = _normIdKey(p.cuentaId.trim());
    return c.isNotEmpty ? c : null;
  }

  static Future<String?> getOwnerAccountIdForPerfilInstitucion(
    String perfilId,
  ) async {
    final p = await getPerfilInstitucionById(perfilId);
    if (p == null) return null;
    final owner = _normIdKey((p.ownerAccountId ?? '').trim());
    if (owner.isNotEmpty) return owner;
    final c = _normIdKey(p.cuentaId.trim());
    return c.isNotEmpty ? c : null;
  }

  // =====================================================
  // VALIDACIÓN CANÓNICA: ownerTienePerfil
  // =====================================================

  /// ✅ Implementación interna (canónico)
  Future<bool> _ownerTienePerfilImpl({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final owner = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (owner.isEmpty || pid.isEmpty) return false;

    final c = await getCuentaById(owner);
    if (c == null) return false;

    final a = c.perfilesAlumnoIds.map((x) => _normIdKey(x)).toList();
    final i = c.perfilesInstitucionIds.map((x) => _normIdKey(x)).toList();

    return a.contains(pid) || i.contains(pid);
  }

  /// ✅ Static wrapper (para compat con callers que esperan static)
  static Future<bool> ownerTienePerfil({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    return instance._ownerTienePerfilImpl(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
    );
  }

  // =====================================================
  // PERFIL LIST GUARD + AUTO-REPAIR (NO MEZCLAR ROLES)
  // =====================================================

  static bool _isTipoAlumno(dynamic p) {
    try {
      return (p as PerfilAlumno).tipo == TipoPerfil.alumno;
    } catch (_) {
      return false;
    }
  }

  static bool _isTipoInstitucion(dynamic p) {
    try {
      return (p as PerfilInstitucion).tipo == TipoPerfil.institucion;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _repairCuentaLists({
    required Cuenta cuenta,
    List<String>? moveToAlumno,
    List<String>? moveToInstitucion,
    List<String>? removeFromAlumno,
    List<String>? removeFromInstitucion,
  }) async {
    final toA = (moveToAlumno ?? <String>[]).map(_normIdKey).toSet();
    final toI = (moveToInstitucion ?? <String>[]).map(_normIdKey).toSet();
    final rmA = (removeFromAlumno ?? <String>[]).map(_normIdKey).toSet();
    final rmI = (removeFromInstitucion ?? <String>[]).map(_normIdKey).toSet();

    final beforeA = cuenta.perfilesAlumnoIds.map(_normIdKey).toList();
    final beforeI = cuenta.perfilesInstitucionIds.map(_normIdKey).toList();

    final setA = <String>{...beforeA};
    final setI = <String>{...beforeI};

    // removals explícitos
    setA.removeWhere((x) => rmA.contains(x));
    setI.removeWhere((x) => rmI.contains(x));

    // moves (quitar del otro y agregar al correcto)
    for (final id in toA) {
      if (id.isEmpty) continue;
      setI.remove(id);
      setA.add(id);
    }
    for (final id in toI) {
      if (id.isEmpty) continue;
      setA.remove(id);
      setI.add(id);
    }

    final afterA = setA.toList();
    final afterI = setI.toList();

    bool changed = false;
    if (afterA.length != beforeA.length ||
        afterI.length != beforeI.length ||
        !_sameSet(afterA, beforeA) ||
        !_sameSet(afterI, beforeI)) {
      changed = true;
    }

    if (!changed) return;

    cuenta.perfilesAlumnoIds = afterA;
    cuenta.perfilesInstitucionIds = afterI;

    try {
      await _saveCuenta(cuenta);
    } catch (_) {
      // NO-OP: no romper listing por falla de repair
    }
  }

  static bool _sameSet(List<String> a, List<String> b) {
    final sa = a.map(_normIdKey).toSet();
    final sb = b.map(_normIdKey).toSet();
    if (sa.length != sb.length) return false;
    for (final x in sa) {
      if (!sb.contains(x)) return false;
    }
    return true;
  }

  // =====================================================
  // PERFILES ALUMNO
  // =====================================================

  static Future<PerfilAlumno?> getPerfilAlumnoById(String perfilId) async {
    final pid = _normIdKey(perfilId);
    if (pid.isEmpty) return null;

    final storage = StorageService.instance;

    // 1) Canónico
    final raw1 = await storage.getString(_kPerfilAlumnoById(pid));
    if (raw1 != null && raw1.trim().isNotEmpty) {
      try {
        return PerfilAlumno.fromJson(raw1);
      } catch (_) {}
    }

    // 2) Legacy trim
    final raw2 = await storage.getString(
      _kPerfilAlumnoByIdLegacyTrim(perfilId),
    );
    if (raw2 != null && raw2.trim().isNotEmpty) {
      try {
        final p = PerfilAlumno.fromJson(raw2);
        // Migración suave
        try {
          await _savePerfilAlumno(p);
        } catch (_) {}
        return p;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static Future<void> _savePerfilAlumno(PerfilAlumno perfil) async {
    final storage = StorageService.instance;

    final pid = _normIdKey(perfil.id);
    if (pid.isEmpty) return;

    try {
      final rawPrev = await storage.getString(_kPerfilAlumnoById(pid));
      if (rawPrev != null && rawPrev.trim().isNotEmpty) {
        final prev = PerfilAlumno.fromJson(rawPrev);
        final prevDni = _normDni(prev.documento);
        final nextDni = _normDni(perfil.documento);

        if (prevDni.isNotEmpty && prevDni != nextDni) {
          final oldKey = _kIndexPerfilAlumnoByDni(prevDni);
          final mapped = (await storage.getString(oldKey) ?? '').trim();
          if (_normIdKey(mapped) == pid) {
            await storage.remove(oldKey);
          }
        }
      }
    } catch (_) {}

    final canon = PerfilAlumno(
      id: pid,
      cuentaId: _normIdKey(perfil.cuentaId),
      ownerAccountId: _normIdKey(perfil.ownerAccountId ?? perfil.cuentaId),
      documento: _normDni(perfil.documento),
      nombre: perfil.nombre.trim(),
      apellido: perfil.apellido.trim(),
      fechaNacimiento: perfil.fechaNacimiento,
      email: (perfil.email).trim(),
      telefono: (perfil.telefono).trim(),
      emancipado: perfil.emancipado,
      fechaEmancipacion: perfil.fechaEmancipacion,
      prefs: perfil.prefs,
    );

    // ✅ Write canónico
    await storage.setString(_kPerfilAlumnoById(pid), canon.toJson());

    // ✅ Write legacy-trim si difiere
    final legacyKey = _kPerfilAlumnoByIdLegacyTrim(perfil.id);
    final canonKey = _kPerfilAlumnoById(pid);
    if (legacyKey != canonKey) {
      await storage.setString(legacyKey, canon.toJson());
    }

    final dni = _normDni(canon.documento);
    if (dni.isNotEmpty) {
      await storage.setString(_kIndexPerfilAlumnoByDni(dni), pid);
    }
  }

  static Future<PerfilAlumno> crearPerfilAlumno({
    required String cuentaId,
    required String documento,
    required String nombre,
    required String apellido,
    required DateTime fechaNacimiento,
    String? email,
    String? telefono,
  }) async {
    final cId = _normIdKey(cuentaId);
    if (cId.isEmpty) throw const AuthException(AuthErrorCode.invalidAccount);

    final cuenta = await getCuentaById(cId);
    if (cuenta == null) {
      throw const AuthException(AuthErrorCode.accountNotFound);
    }

    final doc = _normDni(documento);
    if (!_dniValido(doc)) {
      throw const AuthException(AuthErrorCode.invalidDni);
    }
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      throw const AuthException(AuthErrorCode.invalidName);
    }

    final perfiles = await listarPerfilesAlumno(cId);
    final ya = perfiles.any((p) => _normDni(p.documento) == doc);
    if (ya) {
      throw const AuthException(AuthErrorCode.duplicateDni);
    }

    final perfil = PerfilAlumno(
      id: _newPerfilId(),
      cuentaId: cId,
      ownerAccountId: cId,
      documento: doc,
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      fechaNacimiento: fechaNacimiento,
      email: (email ?? '').trim(),
      telefono: (telefono ?? '').trim(),
      emancipado: false,
      fechaEmancipacion: null,
      prefs: PreferenciasPerfil.defaults(),
    );

    await _savePerfilAlumno(perfil);

    final actuales = cuenta.perfilesAlumnoIds.map(_normIdKey).toList();
    final pid = _normIdKey(perfil.id);
    if (!actuales.contains(pid)) {
      cuenta.perfilesAlumnoIds = List<String>.from(actuales)..add(pid);
    } else {
      cuenta.perfilesAlumnoIds = List<String>.from(actuales);
    }
    await _saveCuenta(cuenta);

    // ✅ FIX: guardar con tag anti-cruce
    try {
      await instance.setUltimoPerfilInst(cId, _encodeUltimoAlumno(pid));
    } catch (_) {}

    return perfil;
  }

  static Future<List<PerfilAlumno>> listarPerfilesAlumno(
    String cuentaId,
  ) async {
    final cId = _normIdKey(cuentaId);
    if (cId.isEmpty) return <PerfilAlumno>[];

    final cuenta = await getCuentaById(cId);
    if (cuenta == null) return <PerfilAlumno>[];

    final storage = StorageService.instance;
    final out = <PerfilAlumno>[];

    // ✅ Auto-repair bookkeeping
    final moveToInstitucion = <String>[];
    final removeFromAlumno = <String>[];

    for (final pidRaw in cuenta.perfilesAlumnoIds) {
      final pid = _normIdKey(pidRaw);
      if (pid.isEmpty) continue;

      String? raw = await storage.getString(_kPerfilAlumnoById(pid));
      if (raw == null || raw.trim().isEmpty) {
        // fallback legacy alumno
        raw = await storage.getString(_kPerfilAlumnoByIdLegacyTrim(pidRaw));
      }

      // ✅ fallback cruzado (si quedó guardado como institución)
      if (raw == null || raw.trim().isEmpty) {
        raw = await storage.getString(_kPerfilInstitucionById(pid));
        if (raw == null || raw.trim().isEmpty) {
          raw = await storage.getString(
            _kPerfilInstitucionByIdLegacyTrim(pidRaw),
          );
        }
        if (raw != null && raw.trim().isNotEmpty) {
          // está en key de institución -> este id NO debería estar en lista alumno
          moveToInstitucion.add(pid);
          removeFromAlumno.add(pid);
        }
      }

      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final p = PerfilAlumno.fromJson(raw);

        // ✅ Guard tipo: si no es alumno, no lo devolvemos y reparamos listas
        if (!_isTipoAlumno(p)) {
          moveToInstitucion.add(pid);
          removeFromAlumno.add(pid);
          continue;
        }

        out.add(p);
      } catch (_) {
        // si ni siquiera parsea como alumno, intentamos parsear como institución
        try {
          final inst = PerfilInstitucion.fromJson(raw);
          if (_isTipoInstitucion(inst)) {
            moveToInstitucion.add(pid);
            removeFromAlumno.add(pid);
          }
        } catch (_) {
          // si no parsea nada: data corrupta -> remover de lista alumno (soft)
          removeFromAlumno.add(pid);
        }
      }
    }

    // ✅ Auto-repair efectivo (best-effort)
    if (moveToInstitucion.isNotEmpty || removeFromAlumno.isNotEmpty) {
      await _repairCuentaLists(
        cuenta: cuenta,
        moveToInstitucion: moveToInstitucion,
        removeFromAlumno: removeFromAlumno,
      );
    }

    out.sort((a, b) {
      final aa = '${a.apellido.toLowerCase()}_${a.nombre.toLowerCase()}';
      final bb = '${b.apellido.toLowerCase()}_${b.nombre.toLowerCase()}';
      return aa.compareTo(bb);
    });

    return out;
  }

  static Future<PerfilAlumno?> getPerfilAlumnoByDni(String dni) async {
    final d = _normDni(dni);
    if (d.isEmpty) return null;

    final storage = StorageService.instance;
    final id = await storage.getString(_kIndexPerfilAlumnoByDni(d));
    if (id == null || id.trim().isEmpty) return null;

    return getPerfilAlumnoById(id.trim());
  }

  static Future<void> actualizarPerfilAlumno(PerfilAlumno perfil) async {
    await _savePerfilAlumno(perfil);
  }

  // =====================================================
  // PERFILES INSTITUCIÓN
  // =====================================================

  static Future<PerfilInstitucion?> getPerfilInstitucionById(
    String perfilId,
  ) async {
    final pid = _normIdKey(perfilId);
    if (pid.isEmpty) return null;

    final storage = StorageService.instance;

    // 1) Canónico
    final raw1 = await storage.getString(_kPerfilInstitucionById(pid));
    if (raw1 != null && raw1.trim().isNotEmpty) {
      try {
        return PerfilInstitucion.fromJson(raw1);
      } catch (_) {}
    }

    // 2) Legacy trim
    final raw2 = await storage.getString(
      _kPerfilInstitucionByIdLegacyTrim(perfilId),
    );
    if (raw2 != null && raw2.trim().isNotEmpty) {
      try {
        final p = PerfilInstitucion.fromJson(raw2);
        // Migración suave
        try {
          await _savePerfilInstitucion(p);
        } catch (_) {}
        return p;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static Future<void> _savePerfilInstitucion(PerfilInstitucion perfil) async {
    final storage = StorageService.instance;

    final id = _normIdKey(perfil.id);
    if (id.isEmpty) return;

    // ✅ CRN: ownerAccountId SIEMPRE presente (canónico)
    final owner = _normIdKey(
      ((perfil.ownerAccountId ?? '').trim().isNotEmpty
          ? (perfil.ownerAccountId ?? '').trim()
          : perfil.cuentaId.trim()),
    );

    final canon = PerfilInstitucion(
      id: id,
      cuentaId: _normIdKey(perfil.cuentaId),
      ownerAccountId: owner,
      institucionId: id, // 🔒 canónico: institucionId == perfil.id
      nombre: perfil.nombre.trim(),
      emailContacto: _normEmail(perfil.emailContacto),
      telefonoContacto: perfil.telefonoContacto.trim(),
      prefs: perfil.prefs,
    );

    // ✅ Write canónico
    await storage.setString(_kPerfilInstitucionById(id), canon.toJson());

    // ✅ Write legacy-trim si difiere
    final legacyKey = _kPerfilInstitucionByIdLegacyTrim(perfil.id);
    final canonKey = _kPerfilInstitucionById(id);
    if (legacyKey != canonKey) {
      await storage.setString(legacyKey, canon.toJson());
    }
  }

  static Future<PerfilInstitucion> crearPerfilInstitucion({
    required String cuentaId,
    @Deprecated(
      'Canónico: se ignora (institucionId == perfil.id). Mantener solo por compat; remover en cleanup.',
    )
    String? institucionId,
    required String nombre,
    required String emailContacto,
    required String telefonoContacto,
  }) async {
    final cId = _normIdKey(cuentaId);
    if (cId.isEmpty) throw Exception('Cuenta inválida.');

    final cuenta = await getCuentaById(cId);
    if (cuenta == null) throw Exception('Cuenta inexistente.');

    final emailNorm = _normEmail(emailContacto);
    if (!_emailValido(emailNorm)) {
      throw Exception('Email de contacto inválido.');
    }

    // El primer perfil de institución comparte id con la cuenta contenedora.
    String pid;
    final idsExistentes = cuenta.perfilesInstitucionIds
        .map(_normIdKey)
        .toList();
    final esPrimero = idsExistentes.isEmpty;

    if (esPrimero) {
      final candidato = cId;
      final existente = await getPerfilInstitucionById(candidato);
      pid = (existente == null) ? candidato : _newPerfilId();
    } else {
      pid = _newPerfilId();
    }

    final perfil = PerfilInstitucion(
      id: pid,
      cuentaId: cId,
      ownerAccountId: cId,
      institucionId: _normIdKey(pid), // 🔒 canónico
      nombre: nombre.trim(),
      emailContacto: emailNorm,
      telefonoContacto: telefonoContacto.trim(),
      prefs: PreferenciasPerfil.defaults(),
    );

    await _savePerfilInstitucion(perfil);

    final pidTrim = _normIdKey(perfil.id);
    if (!idsExistentes.contains(pidTrim)) {
      cuenta.perfilesInstitucionIds = List<String>.from(idsExistentes)
        ..add(pidTrim);
    } else {
      cuenta.perfilesInstitucionIds = List<String>.from(idsExistentes);
    }
    await _saveCuenta(cuenta);

    // ✅ FIX: guardar con tag anti-cruce
    try {
      await instance.setUltimoPerfilInst(
        cId,
        _encodeUltimoInstitucion(pidTrim),
      );
    } catch (_) {}

    return perfil;
  }

  static Future<List<PerfilInstitucion>> listarPerfilesInstitucion(
    String cuentaId,
  ) async {
    final cId = _normIdKey(cuentaId);
    if (cId.isEmpty) return <PerfilInstitucion>[];

    final cuenta = await getCuentaById(cId);
    if (cuenta == null) return <PerfilInstitucion>[];

    final storage = StorageService.instance;
    final out = <PerfilInstitucion>[];

    // ✅ Auto-repair bookkeeping
    final moveToAlumno = <String>[];
    final removeFromInstitucion = <String>[];

    for (final pidRaw in cuenta.perfilesInstitucionIds) {
      final pid = _normIdKey(pidRaw);
      if (pid.isEmpty) continue;

      String? raw = await storage.getString(_kPerfilInstitucionById(pid));
      if (raw == null || raw.trim().isEmpty) {
        // fallback legacy institución
        raw = await storage.getString(
          _kPerfilInstitucionByIdLegacyTrim(pidRaw),
        );
      }

      // ✅ fallback cruzado (si quedó guardado como alumno)
      if (raw == null || raw.trim().isEmpty) {
        raw = await storage.getString(_kPerfilAlumnoById(pid));
        if (raw == null || raw.trim().isEmpty) {
          raw = await storage.getString(_kPerfilAlumnoByIdLegacyTrim(pidRaw));
        }
        if (raw != null && raw.trim().isNotEmpty) {
          // está en key de alumno -> este id NO debería estar en lista institución
          moveToAlumno.add(pid);
          removeFromInstitucion.add(pid);
        }
      }

      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final p = PerfilInstitucion.fromJson(raw);

        // ✅ Guard tipo: si no es institución, no lo devolvemos y reparamos listas
        if (!_isTipoInstitucion(p)) {
          moveToAlumno.add(pid);
          removeFromInstitucion.add(pid);
          continue;
        }

        out.add(p);
      } catch (_) {
        // si ni siquiera parsea como institución, intentamos parsear como alumno
        try {
          final al = PerfilAlumno.fromJson(raw);
          if (_isTipoAlumno(al)) {
            moveToAlumno.add(pid);
            removeFromInstitucion.add(pid);
          }
        } catch (_) {
          // si no parsea nada: data corrupta -> remover de lista institución (soft)
          removeFromInstitucion.add(pid);
        }
      }
    }

    // ✅ Auto-repair efectivo (best-effort)
    if (moveToAlumno.isNotEmpty || removeFromInstitucion.isNotEmpty) {
      await _repairCuentaLists(
        cuenta: cuenta,
        moveToAlumno: moveToAlumno,
        removeFromInstitucion: removeFromInstitucion,
      );
    }

    out.sort((a, b) {
      final aa = a.nombre.toLowerCase().trim();
      final bb = b.nombre.toLowerCase().trim();
      return aa.compareTo(bb);
    });

    return out;
  }

  static Future<void> actualizarPerfilInstitucion(
    PerfilInstitucion perfil,
  ) async {
    await _savePerfilInstitucion(perfil);
  }
}
