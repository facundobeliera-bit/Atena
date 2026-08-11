// lib/services/institucion_service.dart
//
// ATENA – INSTITUCION SERVICE (AUTH LOCAL PROTOTIPO)
//
// Objetivo:
// - Mantener login/registro simple para instituciones (fase prototipo).
// - Seguir el flujo CANÓNICO: sesión global se maneja por CuentaService.
// - Este service NO crea flujos paralelos de sesión; solo resuelve credenciales locales.
//
// Canon (contexto):
// - Identidad funcional final de institución (DOMINIO): Institucion.id = perfilId (modelo canónico).
// - Este servicio administra credenciales locales y devuelve un ID de AUTH LOCAL.
//   En Fase 2 ese ID se usa como ownerAccountId (cuenta contenedora) para crear perfiles.
//
// Notas:
// - Password plano (legacy/prototipo). A futuro: backend + hash real.
// - Índice email -> institucionId para unicidad y login.
// - Storage: se escribe SOLO en keys canónicas de este servicio (v2). Legacy (v1): solo lectura.
//
// ✅ CIERRE CANÓNICO (enero 2026):
// - Best-effort: asegurar existencia de Cuenta owner en CuentaService con id = institucionId.
//   Esto evita inconsistencias al usar CuentaHomePage(cuentaId: ownerId) + sesion_cuenta.
//
// HARDENING (enero 2026):
// - Evita colisión del índice cuenta_email_*: si el email real ya pertenece a otra Cuenta,
//   se usa un email sintético para la Cuenta owner de institución (inst_<id>@atena.local).
//
// ✅ FIX CRÍTICO (feb 2026 · DOMINIO INSTITUCIÓN / ID MISMATCH):
// - upsertInstitucion persiste el dominio bajo múltiples IDs candidatos (id/institucionId/perfilId/...)
//   y mantiene un alias map (idAlternativo -> idPrimario).
// - getInstitucionById resuelve alias + variantes normalizadas para evitar "not-found" por divergencias.
//
// Importante:
// - NO setea sesión aquí (eso lo hace el Login/Plan con CuentaService.setSesionCuentaId y SessionService).
// - La Cuenta creada aquí es “owner contenedor” y puede estar vacía de perfiles.
//
// Dependencias:
// - CuentaService + Cuenta model (prototipo local / SharedPreferences).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// ✅ Modelo dominio Institucion (persistencia local del registro)
import '../models/instituciones/instituciones_integrado.dart';

// ✅ Para asegurar owner canónico existente
import 'cuenta_service.dart';
import '../models/cuentas/cuenta.dart';

class InstitucionService {
  // =====================================================
  // NORMALIZACIÓN / VALIDACIONES
  // =====================================================

  static const int _minPassLen = 4;

  static String _normEmail(String email) => email.trim().toLowerCase();

  // IDs/keys CANÓNICAS: trim + elimina whitespace interno (tabs/espacios/newlines).
  // ✅ Alinear con helpers (CuentaService/_normKey) para evitar mismatches en WEB.
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  static String _safeStr(Object? v) => v == null ? '' : v.toString();

  static bool _emailValido(String email) {
    final e = _normEmail(email);
    if (e.isEmpty) return false;

    final at = e.indexOf('@');
    if (at <= 0) return false;
    if (at == e.length - 1) return false;

    // Hardening mínimo: requiere un punto luego del @ (evita “a@b”).
    final dot = e.lastIndexOf('.');
    if (dot <= at + 1) return false;
    if (dot == e.length - 1) return false;

    return true;
  }

  static bool _passValida(String pass) => pass.trim().length >= _minPassLen;

  static String _nombreDefault(String nombre) {
    final n = nombre.trim();
    return n.isEmpty ? 'Institución' : n;
  }

  /// Hash simple (para compat con CuentaService prototipo, que usa base64).
  /// No apto producción, pero mantiene coherencia si algún día se usa loginCuenta.
  static String _hashPassCuenta(String pass) {
    return base64Encode(utf8.encode(pass.trim()));
  }

  // =====================================================
  // KEYS (v2 canónico del servicio) — AUTH LOCAL
  // =====================================================

  static String _kInstByIdV2(String id) =>
      'atena_inst_auth_by_id_${_normIdKey(id)}';

  // Índice: email -> id (para login y unicidad)
  static String _kInstIdByEmailV2(String email) =>
      'atena_inst_auth_email_to_id_${_normEmail(email)}';

  // =====================================================
  // KEYS (v2 canónico del servicio) — DOMINIO INSTITUCION
  // =====================================================

  // ✅ Persistencia del objeto Institucion (datos de registro/plan).
  static String _kInstitucionDomainByIdV2(String id) =>
      'atena_institucion_by_id_${_normIdKey(id)}';

  // ✅ Alias: idSolicitado -> idPrimario (normalizado)
  static String _kInstitucionAliasV2(String id) =>
      'atena_institucion_alias_${_normIdKey(id)}';

  // =====================================================
  // KEYS (v1 legacy) — SOLO LECTURA
  // =====================================================

  static String _kInstByIdV1(String id) => 'inst_${id.trim()}';

  static String _kInstIdByEmailV1(String email) =>
      'inst_email_${_normEmail(email)}';

  // =====================================================
  // ID GENERATION
  // =====================================================

  // Hardening simple: evita colisiones por mismo ms.
  static String _newId() => 'INST_${DateTime.now().microsecondsSinceEpoch}';

  // =====================================================
  // MODELO SIMPLE (auth local)
  // =====================================================

  static Map<String, dynamic> _toMap({
    required String id,
    required String email,
    required String passwordHash,
    required String nombre,
  }) {
    return <String, dynamic>{
      'id': id.trim(),
      'email': _normEmail(email),

      // Nota: en prototipo esto es password plano. El nombre se conserva para
      // no romper referencias existentes; en backend se reemplazará por hash real.
      'passwordHash': passwordHash,

      'nombre': nombre.trim(),
    };
  }

  static _InstAccount? _fromMap(Map<String, dynamic> m) {
    final id = (m['id'] ?? '').toString().trim();
    final email = _normEmail((m['email'] ?? '').toString());

    // Tolerancia a mapas viejos:
    // - passwordHash (actual)
    // - password (muy antiguo)
    final pass = (m['passwordHash'] ?? m['password'] ?? '').toString();

    final nombre = (m['nombre'] ?? '').toString().trim();

    if (id.isEmpty || email.isEmpty) return null;

    return _InstAccount(
      id: id,
      email: email,
      passwordHash: pass,
      nombre: nombre,
    );
  }

  // =====================================================
  // CUENTA OWNER (best-effort)
  // =====================================================

  static String _syntheticOwnerEmail(String institucionId) {
    final id = _normIdKey(institucionId);
    return 'inst_$id@atena.local';
  }

  /// ✅ Asegura que exista una Cuenta owner con id = institucionId.
  /// - No setea sesión.
  /// - No crea perfiles.
  ///
  /// HARDENING:
  /// - Evita pisar índice cuenta_email_* si el email real ya está tomado por otra cuenta.
  ///   En ese caso usa un email sintético para la Cuenta owner de institución.
  static Future<void> _ensureOwnerCuentaBestEffort({
    required String institucionId,
    required String email,
    required String passwordPlano,
    required String nombreInstitucion,
  }) async {
    final id = _normIdKey(institucionId);
    final eReal = _normEmail(email);
    if (id.isEmpty) return;

    try {
      // 1) Resolver si el email real ya pertenece a otra cuenta.
      //    Si sí, usamos email sintético para evitar colisión del índice.
      String emailOwner = eReal.isNotEmpty ? eReal : _syntheticOwnerEmail(id);

      if (eReal.isNotEmpty) {
        final cuentaPorEmail = await CuentaService.getCuentaByEmail(eReal);
        if (cuentaPorEmail != null && _normIdKey(cuentaPorEmail.id) != id) {
          emailOwner = _syntheticOwnerEmail(id);
        }
      }

      // 2) Crear o actualizar cuenta owner fija por id.
      final existente = await CuentaService.getCuentaById(id);

      if (existente == null) {
        final nueva = Cuenta(
          id: id,
          email: emailOwner,
          passwordHash: _hashPassCuenta(passwordPlano),
          perfilesAlumnoIds: <String>[],
          perfilesInstitucionIds: <String>[],
          recordarme: true,
          creadaEl: DateTime.now(),
          ultimaSesion: DateTime.now(),
        );
        await CuentaService.actualizarCuenta(nueva);
        return;
      }

      // 3) Best-effort: mantener coherencia del email del owner,
      //    pero sin generar colisiones (misma lógica).
      final emailActual = _normEmail(existente.email);
      if (emailActual != emailOwner) {
        // Antes de cambiarlo, verificar que emailOwner no esté tomado por otra cuenta.
        final cuentaEmailOwner = await CuentaService.getCuentaByEmail(
          emailOwner,
        );
        if (cuentaEmailOwner == null || _normIdKey(cuentaEmailOwner.id) == id) {
          final actualizada = Cuenta(
            id: existente.id,
            email: emailOwner,
            passwordHash: existente.passwordHash,
            perfilesAlumnoIds: existente.perfilesAlumnoIds,
            perfilesInstitucionIds: existente.perfilesInstitucionIds,
            recordarme: existente.recordarme,
            creadaEl: existente.creadaEl,
            ultimaSesion: existente.ultimaSesion,
          );
          await CuentaService.actualizarCuenta(actualizada);
        }
      }
    } catch (_) {
      // Best-effort: no bloquear auth local.
    }
  }

  // =====================================================
  // CRUD (interno)
  // =====================================================

  static Future<_InstAccount?> _cargarCuentaPorId(String institucionId) async {
    final rawId = institucionId.trim();
    if (rawId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();

    // 1) v2 (canónico del servicio) — probar raw y normalized (por compat)
    final rawV2 = prefs.getString(_kInstByIdV2(rawId));
    final aV2 = _tryDecode(rawV2);
    if (aV2 != null) return aV2;

    final n = _normIdKey(rawId);
    if (n.isNotEmpty && n != rawId) {
      final rawV2N = prefs.getString(_kInstByIdV2(n));
      final aV2N = _tryDecode(rawV2N);
      if (aV2N != null) return aV2N;
    }

    // 2) v1 (legacy, solo lectura)
    final rawV1 = prefs.getString(_kInstByIdV1(rawId));
    return _tryDecode(rawV1);
  }

  static Future<_InstAccount?> _cargarCuentaPorEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final e = _normEmail(email);
    if (e.isEmpty) return null;

    // 1) v2 (canónico del servicio)
    final idV2 = prefs.getString(_kInstIdByEmailV2(e));
    if (idV2 != null && idV2.trim().isNotEmpty) {
      final a = await _cargarCuentaPorId(idV2.trim());
      if (a != null) return a;
    }

    // 2) v1 (legacy, solo lectura)
    final idV1 = prefs.getString(_kInstIdByEmailV1(e));
    if (idV1 == null || idV1.trim().isEmpty) return null;

    return _cargarCuentaPorId(idV1.trim());
  }

  static _InstAccount? _tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _guardarCuenta(_InstAccount a) async {
    final prefs = await SharedPreferences.getInstance();

    final idRaw = a.id.trim();
    final idN = _normIdKey(idRaw);

    // 1) Persistir entidad (v2) — bajo raw y normalized si difieren (cierra mismatch histórico)
    final payload = jsonEncode(
      _toMap(
        id: idRaw,
        email: a.email,
        passwordHash: a.passwordHash,
        nombre: a.nombre,
      ),
    );

    await prefs.setString(_kInstByIdV2(idRaw), payload);
    if (idN.isNotEmpty && idN != idRaw) {
      await prefs.setString(_kInstByIdV2(idN), payload);
    }

    // 2) Persistir índice email->id (v2) — guardar id NORMALIZADO (más estable)
    final idForIndex = idN.isNotEmpty ? idN : idRaw;
    await prefs.setString(_kInstIdByEmailV2(a.email), idForIndex);

    // Nota: NO escribimos keys legacy v1 (solo lectura).
  }

  // =====================================================
  // API PÚBLICA (sin exponer tipos privados)
  // =====================================================

  static Future<String?> getNombreInstitucionById(String institucionId) async {
    final a = await _cargarCuentaPorId(institucionId);
    if (a == null) return null;
    return _nombreDefault(a.nombre);
  }

  static Future<String?> getInstitucionIdByEmail(String email) async {
    final a = await _cargarCuentaPorEmail(email);
    return a?.id;
  }

  // =====================================================
  // REGISTRO / LOGIN
  // =====================================================

  /// Registro mínimo: email + password + nombre.
  ///
  /// Regla de negocio:
  /// - Si el email ya existe: NO duplica (y NO pisa contraseña). Lanza Exception.
  ///
  /// ✅ CIERRE CANÓNICO:
  /// - Best-effort crea Cuenta owner con id = institucionId.
  ///
  /// Nota: el parámetro se llama passwordHash por compat histórica,
  /// pero en prototipo se usa password PLANO.
  ///
  /// Importante (FASE 2):
  /// - El `institucionId` que devuelve este método se usa como ownerAccountId
  ///   (cuenta contenedora) para crear el perfil institución canónico.
  static Future<InstitucionLoginResult> registrarInstitucion({
    required String email,
    required String passwordHash,
    required String nombre,
  }) async {
    final e = _normEmail(email);
    final p = passwordHash.trim();
    final n = nombre.trim();

    if (!_emailValido(e)) throw Exception('Email inválido');
    if (!_passValida(p)) {
      throw Exception('Contraseña inválida (mín. $_minPassLen)');
    }
    if (n.isEmpty) throw Exception('Nombre de institución inválido');

    final existente = await _cargarCuentaPorEmail(e);
    if (existente != null) {
      throw Exception('Email ya registrado');
    }

    final nuevo = _InstAccount(
      id: _newId(), // ✅ AUTH LOCAL ID (FASE 2: se usa como ownerAccountId)
      email: e,
      passwordHash: p, // prototipo: plano
      nombre: n,
    );

    await _guardarCuenta(nuevo);

    // ✅ Asegurar owner cuenta canónica (best-effort)
    await _ensureOwnerCuentaBestEffort(
      institucionId: nuevo.id,
      email: nuevo.email,
      passwordPlano: p,
      nombreInstitucion: nuevo.nombre,
    );

    return InstitucionLoginResult(
      institucionId: nuevo.id,
      institucionNombre: _nombreDefault(nuevo.nombre),
    );
  }

  /// Login mínimo: email + password (plano en prototipo).
  ///
  /// ✅ CIERRE CANÓNICO:
  /// - Best-effort asegura Cuenta owner con id = institucionId.
  ///
  /// Nota: el parámetro se llama passwordHash por compat histórica,
  /// pero en prototipo se usa password PLANO.
  ///
  /// Importante (FASE 2):
  /// - El `institucionId` devuelto se usa como ownerAccountId.
  static Future<InstitucionLoginResult?> loginInstitucion({
    required String email,
    required String passwordHash,
  }) async {
    final e = _normEmail(email);
    final p = passwordHash.trim();

    if (e.isEmpty || p.isEmpty) return null;

    final a = await _cargarCuentaPorEmail(e);
    if (a == null) return null;

    if (a.passwordHash != p) return null;

    // ✅ Asegurar owner cuenta canónica (best-effort)
    await _ensureOwnerCuentaBestEffort(
      institucionId: a.id,
      email: a.email,
      passwordPlano: p,
      nombreInstitucion: a.nombre,
    );

    return InstitucionLoginResult(
      institucionId: a.id,
      institucionNombre: _nombreDefault(a.nombre),
    );
  }

  // =====================================================
  // DOMINIO INSTITUCIÓN (persistencia del modelo Institucion)
  // =====================================================

  static List<String> _candidateDomainIdsFromInstitucion(Institucion inst) {
    final set = <String>{};

    void addId(String v) {
      final s = v.trim();
      if (s.isEmpty) return;
      set.add(s);

      final n = _normIdKey(s);
      if (n.isNotEmpty) set.add(n);
    }

    // 1) id explícito del modelo
    addId(inst.id);

    // 2) Best-effort por reflection (no rompe compilación si no existe)
    try {
      final dyn = inst as dynamic;

      // ignore: avoid_dynamic_calls
      addId(_safeStr(dyn.institucionId));
      // ignore: avoid_dynamic_calls
      addId(_safeStr(dyn.perfilId));
      // ignore: avoid_dynamic_calls
      addId(_safeStr(dyn.institucionPerfilId));
      // ignore: avoid_dynamic_calls
      addId(_safeStr(dyn.ownerAccountId));
    } catch (_) {
      // NO-OP
    }

    return set.toList(growable: false);
  }

  static Future<void> _setAlias({
    required SharedPreferences prefs,
    required String fromId,
    required String toId,
  }) async {
    final from = _normIdKey(fromId);
    final to = _normIdKey(toId);
    if (from.isEmpty || to.isEmpty) return;
    if (from == to) return;

    // Si ya existe alias, no lo pisamos salvo que sea basura.
    final k = _kInstitucionAliasV2(from);
    final cur = prefs.getString(k);
    if (cur != null && cur.trim().isNotEmpty) {
      final curN = _normIdKey(cur);
      if (curN == to) return;

      // Si apunta a sí mismo o vacío, lo corregimos.
      if (curN.isEmpty || curN == from) {
        await prefs.setString(k, to);
      }
      return;
    }

    await prefs.setString(k, to);
  }

  static String? _resolveAliasOnceSync({
    required SharedPreferences prefs,
    required String id,
  }) {
    final k = _kInstitucionAliasV2(id);
    final v = prefs.getString(k);
    final s = (v ?? '').trim();
    final n = _normIdKey(s);
    return n.isEmpty ? null : n;
  }

  /// ✅ Necesario para cerrar InstitucionPlanPage:
  /// persiste (upsert) la entidad Institucion en SharedPreferences.
  ///
  /// Diseño:
  /// - Se guarda como String JSON mediante `Institucion.toJson()`.
  /// - Se lee con `Institucion.fromJson(raw)`.
  ///
  /// ✅ FIX (feb 2026):
  /// - Se guarda bajo múltiples IDs candidatos.
  /// - Se mantiene alias map para resolver mismatches históricos.
  static Future<void> upsertInstitucion(Institucion institucion) async {
    final rawPrimary = institucion.id.trim();
    if (rawPrimary.isEmpty) {
      throw Exception('Institución inválida (id vacío).');
    }

    final prefs = await SharedPreferences.getInstance();

    final json = institucion.toJson();
    if (json.trim().isEmpty) {
      throw Exception('Institución inválida (json vacío).');
    }

    // primary id = el id actual del objeto (normalizado como fuente estable)
    final primaryId = _normIdKey(rawPrimary);

    // Guardamos bajo todos los ids candidatos
    final ids = _candidateDomainIdsFromInstitucion(institucion);

    final set = <String>{};
    set.add(primaryId);

    for (final id in ids) {
      final n = _normIdKey(id);
      if (n.isNotEmpty) set.add(n);
    }

    final finalIds = set.toList(growable: false);

    for (final id in finalIds) {
      await prefs.setString(_kInstitucionDomainByIdV2(id), json);

      // alias: cualquiera que no sea el primary apunta al primary
      if (id != primaryId) {
        await _setAlias(prefs: prefs, fromId: id, toId: primaryId);
      }
    }
  }

  /// Helper de lectura (por si lo necesitás en pantallas posteriores).
  ///
  /// ✅ FIX (feb 2026):
  /// - Resuelve directo por id.
  /// - Si no existe, busca alias y reintenta.
  /// - Prueba variantes normalizadas (trim + remove whitespace).
  static Future<Institucion?> getInstitucionById(String institucionId) async {
    final raw = institucionId.trim();
    if (raw.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();

    Institucion? tryRead(String id) {
      final k = _kInstitucionDomainByIdV2(id);
      final s = prefs.getString(k);
      if (s == null || s.trim().isEmpty) return null;
      try {
        return Institucion.fromJson(s);
      } catch (_) {
        return null;
      }
    }

    final rawN = _normIdKey(raw);

    // 1) directo (raw normalized)
    final direct = tryRead(rawN);
    if (direct != null) return direct;

    // 2) alias (raw)
    final alias = _resolveAliasOnceSync(prefs: prefs, id: rawN);
    if (alias != null) {
      final a = tryRead(alias);
      if (a != null) return a;
    }

    return null;
  }

  /// ✅ Alias de compatibilidad:
  /// Varias screens/services históricos usan `getById(...)`.
  /// En canónico, el nombre explícito es `getInstitucionById(...)`.
  static Future<Institucion?> getById(String institucionId) {
    return getInstitucionById(institucionId);
  }

  // =====================================================
  // ACTUALIZAR CREDENCIALES (solo si ya existe)
  // =====================================================

  static Future<void> actualizarCredenciales({
    required String institucionId,
    String? nuevoEmail,
    String? nuevoPassword,
    String? nuevoNombre,
  }) async {
    final actual = await _cargarCuentaPorId(institucionId);
    if (actual == null) throw Exception('Institución inexistente');

    final emailFinal = _normEmail(nuevoEmail ?? actual.email);
    final passFinal = (nuevoPassword ?? actual.passwordHash).trim();
    final nombreFinal = (nuevoNombre ?? actual.nombre).trim();

    if (!_emailValido(emailFinal)) throw Exception('Email inválido');
    if (!_passValida(passFinal)) {
      throw Exception('Contraseña inválida (mín. $_minPassLen)');
    }
    if (nombreFinal.isEmpty) throw Exception('Nombre inválido');

    final prefs = await SharedPreferences.getInstance();

    if (emailFinal != actual.email) {
      final tomadoV2 = prefs.getString(_kInstIdByEmailV2(emailFinal));
      if (tomadoV2 != null &&
          tomadoV2.trim().isNotEmpty &&
          _normIdKey(tomadoV2) != _normIdKey(actual.id)) {
        throw Exception('Ese email ya está en uso');
      }

      final tomadoV1 = prefs.getString(_kInstIdByEmailV1(emailFinal));
      if (tomadoV1 != null &&
          tomadoV1.trim().isNotEmpty &&
          _normIdKey(tomadoV1) != _normIdKey(actual.id)) {
        throw Exception('Ese email ya está en uso');
      }

      // Remover índice viejo del email anterior (limpieza segura).
      await prefs.remove(_kInstIdByEmailV2(actual.email));

      // Legacy v1: si existiera el índice, limpiarlo no rompe (solo lectura).
      await prefs.remove(_kInstIdByEmailV1(actual.email));
    }

    final actualizado = _InstAccount(
      id: actual.id,
      email: emailFinal,
      passwordHash: passFinal, // prototipo: plano
      nombre: nombreFinal,
    );

    await _guardarCuenta(actualizado);

    // ✅ Mantener coherencia de Cuenta owner (best-effort)
    await _ensureOwnerCuentaBestEffort(
      institucionId: actualizado.id,
      email: actualizado.email,
      passwordPlano: actualizado.passwordHash,
      nombreInstitucion: actualizado.nombre,
    );
  }
}

class InstitucionLoginResult {
  /// En Fase 2 se usa como ownerAccountId (Cuenta owner contenedora).
  final String institucionId;

  final String institucionNombre;

  const InstitucionLoginResult({
    required this.institucionId,
    required this.institucionNombre,
  });

  /// Alias semántico: en Fase 2, este id se usa como ownerAccountId.
  String get ownerAccountId => institucionId;
}

// =====================================================
// TIPO PRIVADO (interno del service)
// =====================================================

class _InstAccount {
  final String id;
  final String email;

  // En prototipo esto es password plano. Se mantiene el nombre por compatibilidad.
  final String passwordHash;

  final String nombre;

  const _InstAccount({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.nombre,
  });
}
