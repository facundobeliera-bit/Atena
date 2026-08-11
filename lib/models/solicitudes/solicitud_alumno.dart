// lib/models/solicitudes/solicitud_alumno.dart
//
// ATENA – SOLICITUD ALUMNO (CANÓNICO)
//
// HARDENING (enero 2026):
// - Helpers robustos: _s ahora TRIM (evita ids/strings con espacios).
// - DNI/doc y valores usados en dedupKey pasan por normalización conservadora.
// - moduleKey: sanitizador canónico (snake_case + set oficial BloqueExtracurricularX).
// - aula/turno/moduleKey: NO null (default '') para evitar null-trim en UI.
// - Fechas: _dtFrom tolera int/double/String ISO o epoch String.
// - EstadoSolicitud.fromString tolerante (legacy + variantes).
// - DEDUP KEY incluye moduleKey para extracurriculares (evita colisiones cross-módulo).
// - fromMap: compat de keys legacy (institución, actividad, fechas, ids).
//
// ✅ NUEVO (feb 2026) – CANÓNICO CURRICULAR:
// - grupoCurricularId: ID estable del grupo/cupo emitido por Gestión Vacantes.
// - Para curricular: si existe grupoCurricularId, es la referencia primaria.
// - aula/turno quedan como snapshot/compat/UI (no como referencia estable).
//
// Nota:
// - Fuente de verdad de moduleKey es el flujo de creación (UI/service).
// - fromMap solo acepta moduleKey si pasa validación canónica.
// - Fuente de verdad del grupo curricular es Gestión Vacantes (grupoCurricularId).
//

import 'dart:convert';

// ✅ Validación canónica de moduleKey (set oficial)
import '../extracurriculares/bloque_extracurricular.dart';

// =====================================================
// HELPERS SEGUROS
// =====================================================

DateTime _dtFrom(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.round());
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

// ✅ TRIM por defecto (evita “ghost data”)
String _s(dynamic v) => (v ?? '').toString().trim();

bool _b(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'si' || s == 'sí') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

String _norm(String v) => v.trim().toLowerCase();

/// IDs canónicos: trim + elimina whitespace interno.
/// (alineado a SolicitudesService._kid para evitar solicitudes “huérfanas”)
String _kid(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

String _newSolicitudId() => 'SOL_${DateTime.now().microsecondsSinceEpoch}';

bool _isSnakeCase(String v) {
  final s = _norm(v);
  if (s.isEmpty) return false;
  final re = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
  return re.hasMatch(s);
}

// ✅ Sanitizador mínimo canónico de moduleKey (fail-safe)
String _sanitizeModuleKey({required bool esCurricular, required String raw}) {
  if (esCurricular) return '';
  final mk = _norm(raw);
  if (mk.isEmpty) return '';
  if (!_isSnakeCase(mk)) return '';
  if (!BloqueExtracurricularX.isValidKey(mk)) return '';
  return mk;
}

// =====================================================
// DEDUP KEY (CANÓNICA)
// =====================================================

/// Genera una key estable anti-duplicado.
///
/// ✅ CANÓNICO feb 2026:
/// - Para curricular: si hay grupoCurricularId, dedupea por ese ID
///   (más fuerte que aula/turno strings).
/// - Para extracurricular: incluye moduleKey (evita colisiones cross-módulo).
String _buildDedupKey({
  required String ownerAccountId,
  required String perfilId,
  required String alumnoDocumento,
  required String institucionId,
  required String actividadNombre,
  required bool esCurricular,
  String grupoCurricularId = '',
  String aula = '',
  String turno = '',
  String moduleKey = '',
}) {
  // Anchor: owner/perfil canónicos; si no hay (legacy), usamos DNI.
  final o = _kid(ownerAccountId);
  final p = _kid(perfilId);
  final anchor = (o.isNotEmpty && p.isNotEmpty)
      ? '$o|$p'
      : 'LEGACY|${_norm(alumnoDocumento)}';

  final tipo = esCurricular ? 'curricular' : 'extracurricular';

  // Para curricular, moduleKey debe quedar vacío.
  final mk = esCurricular ? '' : _norm(moduleKey);

  // ✅ Para curricular, si hay grupoCurricularId, lo usamos como ancla primaria.
  final gid = esCurricular ? _kid(grupoCurricularId).toLowerCase() : '';

  // ✅ institucionId se considera CANÓNICA (trim + sin whitespace interno).
  final inst = _kid(institucionId).toLowerCase();

  // ✅ FIX CANÓNICO:
  // Si hay grupoCurricularId, NO usamos aula/turno para dedup (son snapshot/UI).
  final aulaKey = (esCurricular && gid.isNotEmpty) ? '' : _norm(aula);
  final turnoKey = (esCurricular && gid.isNotEmpty) ? '' : _norm(turno);

  return [
    anchor,
    inst,
    _norm(actividadNombre),
    tipo,
    // Orden estable: primero grupoId (si aplica), luego snapshot aula/turno.
    gid,
    aulaKey,
    turnoKey,
    mk,
  ].join('|');
}

// =====================================================
// ESTADO SOLICITUD (CANÓNICO)
// =====================================================

enum EstadoSolicitud {
  pendiente,
  confirmada,
  rechazada,
  canceladaPorAlumno,
  canceladaPorInstitucion,
}

extension EstadoSolicitudX on EstadoSolicitud {
  String get label {
    switch (this) {
      case EstadoSolicitud.pendiente:
        return 'Pendiente';
      case EstadoSolicitud.confirmada:
        return 'Confirmada';
      case EstadoSolicitud.rechazada:
        return 'Rechazada';
      case EstadoSolicitud.canceladaPorAlumno:
        return 'Cancelada por alumno';
      case EstadoSolicitud.canceladaPorInstitucion:
        return 'Cancelada por institución';
    }
  }

  static EstadoSolicitud fromString(String v) {
    final raw = v.trim();
    final low = raw.toLowerCase();

    // Vacío / null-like
    if (low.isEmpty || low == 'null') {
      return EstadoSolicitud.pendiente;
    }

    // Canon por name exacto
    for (final e in EstadoSolicitud.values) {
      if (e.name.toLowerCase() == low) {
        return e;
      }
    }

    // Compat humana
    if (low == 'pendiente') return EstadoSolicitud.pendiente;
    if (low == 'confirmada' || low == 'confirmado') {
      return EstadoSolicitud.confirmada;
    }
    if (low == 'rechazada' || low == 'rechazado') {
      return EstadoSolicitud.rechazada;
    }

    // Cancelaciones (tolerante a variantes)
    if (low.contains('cancel') &&
        (low.contains('institu') || low.contains('instituc'))) {
      return EstadoSolicitud.canceladaPorInstitucion;
    }
    if (low.contains('cancel')) {
      // Por defecto, si no dice institución, asumimos alumno (legacy típico)
      return EstadoSolicitud.canceladaPorAlumno;
    }

    return EstadoSolicitud.pendiente;
  }
}

// =====================================================
// SOLICITUD ALUMNO (CANÓNICO)
// =====================================================
//
// ✅ Ajuste canónico para evitar null-trim en UI:
// - aula y turno pasan a ser String no-null (default '').
// - moduleKey pasa a ser String no-null (default '').
//   * Para curricular: ''.
//   * Para extracurricular: snake_case canónica (validada).
//
// ✅ NUEVO (feb 2026):
// - grupoCurricularId: String no-null (default '').
//   * Curricular: recomendado/idealmente requerido.
//   * Extracurricular: ''.
//
// =====================================================

class SolicitudAlumno {
  final String id;

  // Canónico: owner/perfil
  final String? ownerAccountId;
  final String? perfilId;

  // Compat alumno (sin romper prototipo)
  final String alumnoDocumento;

  // Institución (CANÓNICO: trim + sin whitespace interno al persistir/consumir)
  final String institucionId;
  final String institucionNombre;

  // Actividad
  final String actividadNombre;

  /// ✅ CANÓNICO CURRICULAR:
  /// ID estable del grupo/cupo publicado por Gestión Vacantes.
  /// - Curricular: recomendado/idealmente requerido.
  /// - Extracurricular: ''.
  final String grupoCurricularId;

  // Opcionales (NO null) – snapshot/UI/compat
  final String aula;
  final String turno;

  /// ✅ Extracurriculares: moduleKey snake_case canónica (set BloqueExtracurricularX).
  /// Curricular: ''.
  final String moduleKey;

  // Curricular/extracurricular
  final bool esCurricular;

  // Estado
  final EstadoSolicitud estado;

  // Institución: nota/motivo
  final String? notaInstitucion;
  final String? motivoRechazo;

  // Fechas
  final DateTime fechaCreacion;
  final DateTime fechaUltimoCambio;

  // Anti-duplicado (persistible)
  final String dedupKey;

  const SolicitudAlumno({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.institucionNombre,
    required this.actividadNombre,
    required this.esCurricular,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaUltimoCambio,
    required this.dedupKey,
    this.ownerAccountId,
    this.perfilId,
    this.grupoCurricularId = '',
    this.aula = '',
    this.turno = '',
    this.moduleKey = '',
    this.notaInstitucion,
    this.motivoRechazo,
  });

  /// ✅ institucionId canónico para consultas/índices.
  /// (Trim + sin whitespace interno; evita “huérfanas”)
  String get institucionIdCanonico => _kid(institucionId);

  /// ✅ Normaliza y valida canónicamente moduleKey (sin romper llamadas existentes).
  /// - Curricular: siempre ''.
  /// - Extracurricular: snake_case válida (o '' si inválida).
  String get moduleKeyCanonica =>
      _sanitizeModuleKey(esCurricular: esCurricular, raw: moduleKey);

  /// ✅ grupoCurricularId canónico:
  /// - Curricular: trim (y conserva), si viene vacío queda '' (compat).
  /// - Extracurricular: siempre ''.
  String get grupoCurricularIdCanonico {
    if (!esCurricular) return '';
    return _s(grupoCurricularId);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerAccountId': ownerAccountId,
    'perfilId': perfilId,
    'alumnoDocumento': alumnoDocumento,

    // ✅ Persistimos institucionId CANONIZADO (alineado a service).
    'institucionId': institucionIdCanonico,
    'institucionNombre': institucionNombre,

    'actividadNombre': actividadNombre,

    // ✅ Canon curricular
    'grupoCurricularId': grupoCurricularIdCanonico,

    // Snapshot/UI/compat
    'aula': aula,
    'turno': turno,

    // ✅ Siempre persistimos el valor canónico
    'moduleKey': moduleKeyCanonica,

    'esCurricular': esCurricular,
    'estado': estado.name,
    'notaInstitucion': notaInstitucion,
    'motivoRechazo': motivoRechazo,
    'fechaCreacionIso': fechaCreacion.toIso8601String(),
    'fechaUltimoCambioIso': fechaUltimoCambio.toIso8601String(),
    'dedupKey': dedupKey,
  };

  factory SolicitudAlumno.fromMap(Map<String, dynamic> m) {
    // ----------------------------
    // Institución (compat)
    // ----------------------------
    final instNombre = _s(m['institucionNombre']).isNotEmpty
        ? _s(m['institucionNombre'])
        : (_s(m['nombreInstitucion']).isNotEmpty
              ? _s(m['nombreInstitucion'])
              : _s(m['institucion']));

    final instIdRaw = _s(m['institucionId']).isNotEmpty
        ? _s(m['institucionId'])
        : (_s(m['idInstitucion']).isNotEmpty
              ? _s(m['idInstitucion'])
              : (_s(m['instId']).isNotEmpty
                    ? _s(m['instId'])
                    : _s(m['institucion_id'])));

    // ✅ CANÓNICO: institucionId canonizado (trim + sin whitespace interno)
    final instId = _kid(instIdRaw);

    // ----------------------------
    // Actividad (compat)
    // ----------------------------
    final actNombre = _s(m['actividadNombre']).isNotEmpty
        ? _s(m['actividadNombre'])
        : (_s(m['actividad']).isNotEmpty
              ? _s(m['actividad'])
              : _s(m['nombreActividad']));

    // ----------------------------
    // Aula/Grupo + Turno (compat)
    // ----------------------------
    final aulaRaw = _s(m['aula']);
    final grupoRaw = _s(m['grupo']);
    final aulaFinal = aulaRaw.isNotEmpty ? aulaRaw : grupoRaw;

    final turnoRaw = _s(m['turno']);

    // ----------------------------
    // Owner/Perfil (canon)
    // ----------------------------
    final owner = _kid(_s(m['ownerAccountId']));
    final perfil = _kid(_s(m['perfilId']));

    // ----------------------------
    // Documento compat
    // ----------------------------
    final doc = _s(m['alumnoDocumento']).isNotEmpty
        ? _s(m['alumnoDocumento'])
        : (_s(m['documentoAlumno']).isNotEmpty
              ? _s(m['documentoAlumno'])
              : _s(m['dni']));

    // ----------------------------
    // Curricular (compat adicional)
    // ----------------------------
    bool esCurricular = _b(m['esCurricular']);
    if (!m.containsKey('esCurricular')) {
      final tipo = _s(m['tipo']).toLowerCase();
      if (tipo == 'curricular') esCurricular = true;
      if (tipo == 'extracurricular' || tipo == 'extra') esCurricular = false;
    }

    // ----------------------------
    // grupoCurricularId (CANÓNICO curricular)
    // ----------------------------
    String readGrupoId() {
      // Canon
      final g1 = _s(m['grupoCurricularId']);
      if (g1.isNotEmpty) return g1;

      // Variantes comunes legacy
      final g2 = _s(m['grupoId']);
      if (g2.isNotEmpty) return g2;

      final g3 = _s(m['grupo_id']);
      if (g3.isNotEmpty) return g3;

      final g4 = _s(m['grupoCurricular']);
      if (g4.isNotEmpty) return g4;

      final g5 = _s(m['grupoCurricular_id']);
      if (g5.isNotEmpty) return g5;

      final g6 = _s(m['grupo_curricular_id']);
      if (g6.isNotEmpty) return g6;

      // Algunos legacies usan "cursoId"/"grupoCursoId"
      final g7 = _s(m['grupoCursoId']);
      if (g7.isNotEmpty) return g7;

      final g8 = _s(m['cursoId']);
      if (g8.isNotEmpty) return g8;

      return '';
    }

    final grupoCurricularId = esCurricular ? _s(readGrupoId()) : '';

    // ----------------------------
    // moduleKey (CANÓNICA)
    // ----------------------------
    final mkRaw = _s(m['moduleKey']).isNotEmpty
        ? _s(m['moduleKey'])
        : (_s(m['moduloKey']).isNotEmpty
              ? _s(m['moduloKey'])
              : (_s(m['bloqueKey']).isNotEmpty
                    ? _s(m['bloqueKey'])
                    : _s(m['module_key'])));

    final moduleKey = _sanitizeModuleKey(
      esCurricular: esCurricular,
      raw: mkRaw,
    );

    // ----------------------------
    // Fechas compat
    // ----------------------------
    final fCre = m.containsKey('fechaCreacionIso')
        ? _dtFrom(m['fechaCreacionIso'])
        : (m.containsKey('fechaCreacion')
              ? _dtFrom(m['fechaCreacion'])
              : _dtFrom(m['fechaIso']));

    final fUlt = m.containsKey('fechaUltimoCambioIso')
        ? _dtFrom(m['fechaUltimoCambioIso'])
        : (m.containsKey('fechaUltimoCambio')
              ? _dtFrom(m['fechaUltimoCambio'])
              : _dtFrom(m['fechaUltimoCambioMs']));

    final fechaCreacion = (fCre.millisecondsSinceEpoch == 0)
        ? DateTime.now()
        : fCre;
    final fechaUlt = (fUlt.millisecondsSinceEpoch == 0) ? fechaCreacion : fUlt;

    // ----------------------------
    // Estado (compat)
    // ----------------------------
    final estado = EstadoSolicitudX.fromString(_s(m['estado']));

    // ----------------------------
    // ID (si falta lo generamos)
    // ----------------------------
    final id = _s(m['id']).isNotEmpty ? _s(m['id']) : _newSolicitudId();

    // ----------------------------
    // DEDUP KEY
    // ----------------------------
    final dedupRaw = _s(m['dedupKey']);
    final dedup = dedupRaw.isNotEmpty
        ? dedupRaw
        : _buildDedupKey(
            ownerAccountId: owner,
            perfilId: perfil,
            alumnoDocumento: doc,
            institucionId: instId,
            actividadNombre: actNombre,
            esCurricular: esCurricular,
            grupoCurricularId: grupoCurricularId,
            aula: aulaFinal,
            turno: turnoRaw,
            moduleKey: moduleKey,
          );

    final nota = _s(m['notaInstitucion']);
    final motivo = _s(m['motivoRechazo']);

    return SolicitudAlumno(
      id: id,
      ownerAccountId: owner.isEmpty ? null : owner,
      perfilId: perfil.isEmpty ? null : perfil,
      alumnoDocumento: doc,
      institucionId: instId,
      institucionNombre: instNombre,
      actividadNombre: actNombre,
      grupoCurricularId: grupoCurricularId,
      aula: aulaFinal,
      turno: turnoRaw,
      moduleKey: moduleKey,
      esCurricular: esCurricular,
      estado: estado,
      notaInstitucion: nota.isEmpty ? null : nota,
      motivoRechazo: motivo.isEmpty ? null : motivo,
      fechaCreacion: fechaCreacion,
      fechaUltimoCambio: fechaUlt,
      dedupKey: dedup,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SolicitudAlumno.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return SolicitudAlumno.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('SolicitudAlumno.fromJson: JSON inválido');
  }

  SolicitudAlumno copyWith({
    String? ownerAccountId,
    String? perfilId,
    EstadoSolicitud? estado,
    String? notaInstitucion,
    String? motivoRechazo,
    DateTime? fechaUltimoCambio,
    String? dedupKey,
    String? grupoCurricularId,
    String? aula,
    String? turno,
    String? moduleKey,
  }) {
    final nextEsCurricular = esCurricular;

    final mk = _sanitizeModuleKey(
      esCurricular: nextEsCurricular,
      raw: moduleKey ?? this.moduleKey,
    );

    final gid = nextEsCurricular
        ? _s(grupoCurricularId ?? this.grupoCurricularId)
        : '';

    // ✅ owner/perfil canonizados (sin whitespace interno) si el caller los setea.
    final nextOwner = (ownerAccountId == null)
        ? this.ownerAccountId
        : _kid(ownerAccountId);
    final nextPerfil = (perfilId == null) ? this.perfilId : _kid(perfilId);

    return SolicitudAlumno(
      id: id,
      ownerAccountId: (nextOwner ?? '').trim().isEmpty ? null : nextOwner,
      perfilId: (nextPerfil ?? '').trim().isEmpty ? null : nextPerfil,
      alumnoDocumento: alumnoDocumento,

      // ✅ institucionId NO cambia aquí (fuente de verdad ya persistida).
      institucionId: institucionId,
      institucionNombre: institucionNombre,

      actividadNombre: actividadNombre,
      grupoCurricularId: gid,
      aula: aula ?? this.aula,
      turno: turno ?? this.turno,
      moduleKey: mk,
      esCurricular: nextEsCurricular,
      estado: estado ?? this.estado,
      notaInstitucion: notaInstitucion ?? this.notaInstitucion,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      fechaCreacion: fechaCreacion,
      fechaUltimoCambio: fechaUltimoCambio ?? this.fechaUltimoCambio,
      dedupKey: dedupKey ?? this.dedupKey,
    );
  }

  /// Público: para que UI / services puedan construir dedupKey estable.
  static String buildDedupKeyPublic({
    required String ownerAccountId,
    required String perfilId,
    required String alumnoDocumento,
    required String institucionId,
    required String actividadNombre,
    required bool esCurricular,
    String grupoCurricularId = '',
    String aula = '',
    String turno = '',
    String moduleKey = '',
  }) {
    return _buildDedupKey(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      alumnoDocumento: alumnoDocumento,
      institucionId: institucionId,
      actividadNombre: actividadNombre,
      esCurricular: esCurricular,
      grupoCurricularId: grupoCurricularId,
      aula: aula,
      turno: turno,
      moduleKey: moduleKey,
    );
  }

  /// Público: ID estándar
  static String newSolicitudId() => _newSolicitudId();
}
