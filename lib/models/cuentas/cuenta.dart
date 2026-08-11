// ─────────────────────────────────────────────
// ATENA – MODELOS CUENTAS (CONSOLIDADO)
// Archivo: lib/models/cuentas/cuenta.dart
// ─────────────────────────────────────────────
//
// HARDENING (enero 2026):
// - _s ahora TRIM (evita ids/email con espacios).
// - _listStr ahora TRIM + filtra vacíos + DEDUPE (evita duplicados y contains() fallando por legacy).
// - Cuenta.fromMap normaliza email a lower-case (consistencia con CuentaService).
// - PreferenciasPerfil.fromMap: tolera valores "true"/"false" (String/int) además de bool.
// - PerfilAlumno/Institucion: ownerAccountId trim + null si vacío (fallback coherente).
// - _dtFrom robusto: tolera String numérica con espacios.
//
// ✅ HARDENING CANÓNICO (enero 2026):
// - PERFIL INSTITUCIÓN: institucionId se fuerza a ser == id (regla canónica).
//   * fromMap(): si viene vacío o distinto, lo normaliza a id.
//   * toMap(): siempre exporta institucionId = id.
//   Esto evita inconsistencias de dominio al migrar a backend.
//
// ✅ HARDENING EXTRA (enero 2026) – aplicado:
// - TipoPerfil.fromString tolerante (case-insensitive + aliases legacy).
// - PerfilInstitucion.fromMap repara legacy: si 'id' viene vacío pero 'institucionId' existe,
//   usa institucionId como id para no romper storage/keys (y mantiene institucionId==id).
// - Cuenta.fromMap tolera legacy passwordHash keys ('password'/'passHash').
// - Cuenta.fromMap tolera legacy cuentaId como fallback de id (best-effort).
//
// ✅ HARDENING EXTRA 2 (enero 2026) – aplicado:
// - CuentaSnapshot.fromMap: tolera 'cuenta' como Map o como String JSON legacy o null.
//
// ✅ MICRO-HARDENING (enero 2026) – aplicado ahora:
// - PerfilAlumno.fromMap: tolera legacy 'perfilId' como fallback de 'id' (best-effort).
//
// ✅ MICRO-CONSISTENCIA aplicada AHORA (enero 2026):
// - PerfilInstitucion.fromMap: normaliza emailContacto a lower-case (consistencia con CuentaService/_savePerfilInstitucion).
// - PerfilAlumno.fromMap: normaliza documento a solo dígitos (consistencia con CuentaService/_normDni).
//
// NOTA CANÓNICA (enero 2026):
// - Notificaciones NO viven en este archivo.
// - La fuente de verdad de notificaciones es:
//   lib/models/notificaciones/notificacion_atena.dart
//

import 'dart:convert';

DateTime _dtFrom(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);

  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final p = DateTime.tryParse(s);
    if (p != null) return p;

    final asInt = int.tryParse(s);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _dtToIso(DateTime d) => d.toIso8601String();

// ✅ TRIM por defecto (evita espacios en ids / emails / etc.)
String _s(dynamic v) => (v ?? '').toString().trim();

// ✅ bool robusto: soporta bool, int(0/1), String("true"/"false"/"1"/"0")
bool _b(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return v == true;
}

Map<String, dynamic>? _map(dynamic v) =>
    (v is Map) ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> _listMap(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return <Map<String, dynamic>>[];
}

// ✅ TRIM + filtra vacíos + DEDUPE conservador (preserva orden)
List<String> _listStr(dynamic v) {
  if (v is List) {
    final out = <String>[];
    final seen = <String>{};
    for (final it in v) {
      final s = (it ?? '').toString().trim();
      if (s.isEmpty) continue;
      if (seen.contains(s)) continue;
      seen.add(s);
      out.add(s);
    }
    return out;
  }
  return <String>[];
}

Map<String, dynamic> _safeMapFromDynamic(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return <String, dynamic>{};
}

// ✅ Consistencia con CuentaService: DNI solo dígitos
String _dniDigits(String v) => v.replaceAll(RegExp(r'[^0-9]'), '').trim();

// =====================================================
// ENUMS
// =====================================================

enum TipoPerfil { alumno, institucion }

extension TipoPerfilX on TipoPerfil {
  String get label {
    switch (this) {
      case TipoPerfil.alumno:
        return 'Alumno';
      case TipoPerfil.institucion:
        return 'Institución';
    }
  }

  /// ✅ Robust/compat:
  /// - case-insensitive
  /// - tolera labels y aliases legacy
  static TipoPerfil fromString(String v) {
    final raw = v.trim();
    if (raw.isEmpty) return TipoPerfil.alumno;

    final s = raw.toLowerCase();

    // match exact enum name (case-insensitive)
    for (final it in TipoPerfil.values) {
      if (it.name.toLowerCase() == s) return it;
    }

    // aliases legacy / humanos
    if (s == 'institución' || s == 'institucion' || s == 'inst' || s == 'i') {
      return TipoPerfil.institucion;
    }
    if (s == 'alumno' || s == 'a' || s == 'estudiante' || s == 'student') {
      return TipoPerfil.alumno;
    }

    return TipoPerfil.alumno;
  }
}

// =====================================================
// PREFERENCIAS (OPCIONAL)
// =====================================================

class PreferenciasPerfil {
  bool recibirNotificaciones;
  bool incluirEnCalendario;

  PreferenciasPerfil({
    required this.recibirNotificaciones,
    required this.incluirEnCalendario,
  });

  factory PreferenciasPerfil.defaults() => PreferenciasPerfil(
    recibirNotificaciones: true,
    incluirEnCalendario: true,
  );

  Map<String, dynamic> toMap() => {
    'recibirNotificaciones': recibirNotificaciones,
    'incluirEnCalendario': incluirEnCalendario,
  };

  /// ✅ COMPAT ROBUSTA:
  /// Si el campo no existe en JSON viejo, conserva el default (true).
  factory PreferenciasPerfil.fromMap(Map<String, dynamic> m) =>
      PreferenciasPerfil(
        recibirNotificaciones: m.containsKey('recibirNotificaciones')
            ? _b(m['recibirNotificaciones'])
            : true,
        incluirEnCalendario: m.containsKey('incluirEnCalendario')
            ? _b(m['incluirEnCalendario'])
            : true,
      );
}

// =====================================================
// PERFIL BASE (para cuenta única)
// =====================================================

abstract class PerfilBase {
  String get id;
  String get cuentaId;
  TipoPerfil get tipo;
  String get displayName;

  /// Owner actual del perfil (en emancipación puede cambiar).
  String? get ownerAccountId;
}

// =====================================================
// PERFIL: ALUMNO
// =====================================================

class PerfilAlumno implements PerfilBase {
  @override
  final String id;

  /// Cuenta “contenedora” donde se creó el perfil originalmente.
  @override
  final String cuentaId;

  /// Owner actual (si null, se asume cuentaId como owner).
  @override
  final String? ownerAccountId;

  /// DNI del alumno (solo dígitos)
  final String documento;

  String nombre;
  String apellido;

  DateTime fechaNacimiento;

  String email;
  String telefono;

  bool emancipado;

  DateTime? fechaEmancipacion;

  PreferenciasPerfil prefs;

  PerfilAlumno({
    required this.id,
    required this.cuentaId,
    required this.ownerAccountId,
    required this.documento,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.email,
    required this.telefono,
    required this.emancipado,
    required this.fechaEmancipacion,
    required this.prefs,
  });

  @override
  TipoPerfil get tipo => TipoPerfil.alumno;

  @override
  String get displayName => '${nombre.trim()} ${apellido.trim()}'.trim();

  Map<String, dynamic> toMap() => {
    'id': id,
    'cuentaId': cuentaId,
    'ownerAccountId': ownerAccountId,
    'tipo': tipo.name,
    'documento': documento,
    'nombre': nombre,
    'apellido': apellido,
    'fechaNacimiento': _dtToIso(fechaNacimiento),
    'email': email,
    'telefono': telefono,
    'emancipado': emancipado,
    'fechaEmancipacion': fechaEmancipacion?.toIso8601String(),
    'prefs': prefs.toMap(),
  };

  factory PerfilAlumno.fromMap(Map<String, dynamic> m) {
    final prefsMap = _map(m['prefs']);

    final ownerRaw = _s(m['ownerAccountId']);
    final owner = ownerRaw.isEmpty ? null : ownerRaw;

    // ✅ MICRO-HARDENING: tolerar legacy 'perfilId' si 'id' vino vacío.
    final idRaw = _s(m['id']);
    final id = idRaw.isNotEmpty ? idRaw : _s(m['perfilId']);

    // ✅ Consistencia con CuentaService: DNI solo dígitos
    final doc = _dniDigits(_s(m['documento']));

    return PerfilAlumno(
      id: id,
      cuentaId: _s(m['cuentaId']),
      ownerAccountId: owner,
      documento: doc,
      nombre: _s(m['nombre']),
      apellido: _s(m['apellido']),
      fechaNacimiento: _dtFrom(m['fechaNacimiento']),
      email: _s(m['email']),
      telefono: _s(m['telefono']),
      emancipado: _b(m['emancipado']),
      fechaEmancipacion: _s(m['fechaEmancipacion']).isEmpty
          ? null
          : _dtFrom(m['fechaEmancipacion']),
      prefs: (prefsMap == null)
          ? PreferenciasPerfil.defaults()
          : PreferenciasPerfil.fromMap(prefsMap),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PerfilAlumno.fromJson(String s) =>
      PerfilAlumno.fromMap(jsonDecode(s));
}

// =====================================================
// PERFIL: INSTITUCIÓN
// =====================================================

class PerfilInstitucion implements PerfilBase {
  @override
  final String id;

  @override
  final String cuentaId;

  @override
  final String? ownerAccountId;

  /// 🔒 Regla canónica: institucionId == id
  final String institucionId;

  String nombre;

  String emailContacto;
  String telefonoContacto;

  PreferenciasPerfil prefs;

  PerfilInstitucion({
    required this.id,
    required this.cuentaId,
    required this.ownerAccountId,
    required this.institucionId,
    required this.nombre,
    required this.emailContacto,
    required this.telefonoContacto,
    required this.prefs,
  });

  @override
  TipoPerfil get tipo => TipoPerfil.institucion;

  @override
  String get displayName => nombre.trim();

  Map<String, dynamic> toMap() => {
    'id': id,
    'cuentaId': cuentaId,
    'ownerAccountId': ownerAccountId,
    'tipo': tipo.name,
    // ✅ Export canónico: institucionId SIEMPRE == id
    'institucionId': id,
    'nombre': nombre,
    'emailContacto': emailContacto,
    'telefonoContacto': telefonoContacto,
    'prefs': prefs.toMap(),
  };

  factory PerfilInstitucion.fromMap(Map<String, dynamic> m) {
    final prefsMap = _map(m['prefs']);

    final ownerRaw = _s(m['ownerAccountId']);
    final owner = ownerRaw.isEmpty ? null : ownerRaw;

    final idRaw = _s(m['id']);
    final instRaw = _s(m['institucionId']);

    // ✅ Compat crítico:
    // Si viene legacy con id vacío pero institucionId presente, usar institucionId como id.
    final id = idRaw.isNotEmpty ? idRaw : instRaw;

    // ✅ Normalización canónica: institucionId == id (siempre)
    final inst = id;

    // ✅ Consistencia con CuentaService: emailContacto lower-case
    final email = _s(m['emailContacto']).toLowerCase();

    return PerfilInstitucion(
      id: id,
      cuentaId: _s(m['cuentaId']),
      ownerAccountId: owner,
      institucionId: inst,
      nombre: _s(m['nombre']),
      emailContacto: email,
      telefonoContacto: _s(m['telefonoContacto']),
      prefs: (prefsMap == null)
          ? PreferenciasPerfil.defaults()
          : PreferenciasPerfil.fromMap(prefsMap),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PerfilInstitucion.fromJson(String s) =>
      PerfilInstitucion.fromMap(jsonDecode(s));
}

// =====================================================
// CUENTA (OWNER PRINCIPAL)
// =====================================================

class Cuenta {
  final String id;

  /// Email principal de la cuenta.
  final String email;

  /// Hash/clave (prototipo); backend reemplaza.
  final String passwordHash;

  /// Perfiles vinculados a esta cuenta (ids).
  List<String> perfilesAlumnoIds;
  List<String> perfilesInstitucionIds;

  /// “Recordarme” a nivel CUENTA (owner).
  bool recordarme;

  /// Metadatos / estado
  final DateTime creadaEl;
  DateTime ultimaSesion;

  Cuenta({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.perfilesAlumnoIds,
    required this.perfilesInstitucionIds,
    this.recordarme = true,
    required this.creadaEl,
    required this.ultimaSesion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'passwordHash': passwordHash,
    'perfilesAlumnoIds': perfilesAlumnoIds,
    'perfilesInstitucionIds': perfilesInstitucionIds,
    'recordarme': recordarme,
    'creadaEl': _dtToIso(creadaEl),
    'ultimaSesion': _dtToIso(ultimaSesion),
  };

  factory Cuenta.fromMap(Map<String, dynamic> m) {
    // ✅ normalización directa (trim + lower)
    final emailNorm = _s(m['email']).toLowerCase();

    // ✅ Compat defensiva (si alguna vez guardaste otra key):
    final passHash = _s(m['passwordHash']).isNotEmpty
        ? _s(m['passwordHash'])
        : (_s(m['passHash']).isNotEmpty
              ? _s(m['passHash'])
              : _s(m['password']));

    // ✅ Compat extra: si id viene vacío pero existe cuentaId legacy, usarlo.
    final idRaw = _s(m['id']);
    final id = idRaw.isNotEmpty ? idRaw : _s(m['cuentaId']);

    return Cuenta(
      id: id,
      email: emailNorm,
      passwordHash: passHash,
      perfilesAlumnoIds: _listStr(m['perfilesAlumnoIds']),
      perfilesInstitucionIds: _listStr(m['perfilesInstitucionIds']),
      recordarme: (m.containsKey('recordarme')) ? _b(m['recordarme']) : true,
      creadaEl: _dtFrom(m['creadaEl']),
      ultimaSesion: _dtFrom(m['ultimaSesion']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Cuenta.fromJson(String s) => Cuenta.fromMap(jsonDecode(s));
}

// =====================================================
// CONTENEDOR (OPCIONAL): Export de perfiles mixtos
// =====================================================

class CuentaSnapshot {
  final Cuenta cuenta;
  final List<PerfilAlumno> alumnos;
  final List<PerfilInstitucion> instituciones;

  CuentaSnapshot({
    required this.cuenta,
    required this.alumnos,
    required this.instituciones,
  });

  Map<String, dynamic> toMap() => {
    'cuenta': cuenta.toMap(),
    'alumnos': alumnos.map((e) => e.toMap()).toList(),
    'instituciones': instituciones.map((e) => e.toMap()).toList(),
  };

  factory CuentaSnapshot.fromMap(Map<String, dynamic> m) {
    // ✅ Tolerar null / Map / String JSON legacy.
    final cuentaMap = _safeMapFromDynamic(m['cuenta']);
    return CuentaSnapshot(
      cuenta: Cuenta.fromMap(cuentaMap),
      alumnos: _listMap(m['alumnos']).map(PerfilAlumno.fromMap).toList(),
      instituciones: _listMap(
        m['instituciones'],
      ).map(PerfilInstitucion.fromMap).toList(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CuentaSnapshot.fromJson(String s) =>
      CuentaSnapshot.fromMap(jsonDecode(s));
}
