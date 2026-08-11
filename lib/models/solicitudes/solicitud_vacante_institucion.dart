// lib/models/solicitudes/solicitud_vacante_institucion.dart
//
// ATENA – SOLICITUD VACANTE (INSTITUCIÓN) — LEGACY/COMPAT
// Motivo:
// - Este modelo se mantiene SOLO por compatibilidad/compilación.
// - Se separa de instituciones_integrado.dart para evitar imports pesados/cíclicos.
// - El flujo canónico es SolicitudAlumno (ownerAccountId + perfilId).
//
// HARDENING (enero 2026):
// - fromString tolerante (case-insensitive + labels humanos).
// - Campos NO-NULL donde conviene para evitar null-trim en UI/servicios.
// - fromMap tolera aliases típicos (grupo/aula, fecha*Iso, etc.)
// - ID fallback si viene vacío.
//
// Nota:
// - Este modelo NO se usa como fuente de verdad.
// - Se preserva “shape” para no romper pantallas/servicios legacy aún vivos.
//

import 'dart:convert';

// =====================================================
// ESTADO (LEGACY)
// =====================================================

enum EstadoSolicitudInstitucion {
  pendiente,
  confirmada,
  rechazada,
  canceladaPorInstitucion,
}

extension EstadoSolicitudInstitucionX on EstadoSolicitudInstitucion {
  String get label {
    switch (this) {
      case EstadoSolicitudInstitucion.pendiente:
        return 'Pendiente';
      case EstadoSolicitudInstitucion.confirmada:
        return 'Confirmada';
      case EstadoSolicitudInstitucion.rechazada:
        return 'Rechazada';
      case EstadoSolicitudInstitucion.canceladaPorInstitucion:
        return 'Cancelada';
    }
  }

  static EstadoSolicitudInstitucion fromString(String v) {
    final raw = v.trim();
    final low = raw.toLowerCase();

    if (low.isEmpty || low == 'null') {
      return EstadoSolicitudInstitucion.pendiente;
    }

    // Canon por name (case-insensitive)
    for (final e in EstadoSolicitudInstitucion.values) {
      if (e.name.toLowerCase() == low) {
        return e;
      }
    }

    // Compat humana (labels / variantes)
    if (low == 'pendiente') {
      return EstadoSolicitudInstitucion.pendiente;
    }
    if (low == 'confirmada' || low == 'confirmado') {
      return EstadoSolicitudInstitucion.confirmada;
    }
    if (low == 'rechazada' || low == 'rechazado') {
      return EstadoSolicitudInstitucion.rechazada;
    }
    if (low.contains('cancel')) {
      return EstadoSolicitudInstitucion.canceladaPorInstitucion;
    }

    return EstadoSolicitudInstitucion.pendiente;
  }
}

// =====================================================
// Helpers internos (parsers seguros)
// =====================================================

String _asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'si' || s == 'sí') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

DateTime _asDate(dynamic v, {DateTime? fallback}) {
  final fb = fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (v == null) return fb;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.round());
  final s = v.toString().trim();
  if (s.isEmpty) return fb;
  final p = DateTime.tryParse(s);
  if (p != null) return p;
  final asInt = int.tryParse(s);
  if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  return fb;
}

String _newSolicitudInstId() => 'SOLI_${DateTime.now().microsecondsSinceEpoch}';

// =====================================================
// SOLICITUDES (DESDE INSTITUCIÓN) — LEGACY
// =====================================================

class SolicitudVacanteInstitucion {
  final String id;
  final String alumnoDocumento;

  final String institucionId;
  final String actividadNombre;

  /// Legacy: aula/grupo. Mantener para compat.
  /// Para evitar null-trim: default ''.
  final String grupo;

  final bool esCurricular;

  EstadoSolicitudInstitucion estado;
  DateTime fechaSolicitud;
  DateTime fechaUltimoCambio;

  String? notaInstitucion;

  SolicitudVacanteInstitucion({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.actividadNombre,
    required this.esCurricular,
    required this.fechaSolicitud,
    required this.fechaUltimoCambio,
    this.grupo = '',
    this.notaInstitucion,
    this.estado = EstadoSolicitudInstitucion.pendiente,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'alumnoDocumento': alumnoDocumento,
    'institucionId': institucionId,
    'actividadNombre': actividadNombre,
    // Compat: guardamos como 'grupo' (legacy)
    'grupo': grupo,
    'esCurricular': esCurricular,
    'estado': estado.name,
    'fechaSolicitud': fechaSolicitud.toIso8601String(),
    'fechaUltimoCambio': fechaUltimoCambio.toIso8601String(),
    'notaInstitucion': notaInstitucion,
  };

  factory SolicitudVacanteInstitucion.fromMap(Map<String, dynamic> m) {
    // IDs / strings
    final idRaw = _asString(m['id']).trim();
    final doc = _asString(m['alumnoDocumento']).trim().isNotEmpty
        ? _asString(m['alumnoDocumento']).trim()
        : _asString(m['documentoAlumno']).trim();

    final instId = _asString(m['institucionId']).trim().isNotEmpty
        ? _asString(m['institucionId']).trim()
        : _asString(m['idInstitucion']).trim();

    final act = _asString(m['actividadNombre']).trim().isNotEmpty
        ? _asString(m['actividadNombre']).trim()
        : _asString(m['actividad']).trim();

    // grupo/aula compat
    final grupoRaw = _asString(m['grupo']).trim();
    final aulaRaw = _asString(m['aula']).trim();
    final grupoFinal = grupoRaw.isNotEmpty ? grupoRaw : aulaRaw;

    // esCurricular compat adicional
    bool esCurricular = _asBool(m['esCurricular']);
    if (!m.containsKey('esCurricular')) {
      final tipo = _asString(m['tipo']).trim().toLowerCase();
      if (tipo == 'curricular') {
        esCurricular = true;
      }
      if (tipo == 'extracurricular' || tipo == 'extra') {
        esCurricular = false;
      }
    }

    // estado
    final estado = EstadoSolicitudInstitucionX.fromString(
      _asString(m['estado'], fallback: 'pendiente'),
    );

    // fechas (tolerante a iso/otros names)
    final fSol = m.containsKey('fechaSolicitudIso')
        ? _asDate(m['fechaSolicitudIso'], fallback: DateTime.now())
        : _asDate(m['fechaSolicitud'], fallback: DateTime.now());

    final fUlt = m.containsKey('fechaUltimoCambioIso')
        ? _asDate(m['fechaUltimoCambioIso'], fallback: fSol)
        : _asDate(m['fechaUltimoCambio'], fallback: fSol);

    final nota = _asString(m['notaInstitucion']).trim();

    return SolicitudVacanteInstitucion(
      id: idRaw.isEmpty ? _newSolicitudInstId() : idRaw,
      alumnoDocumento: doc,
      institucionId: instId,
      actividadNombre: act,
      grupo: grupoFinal,
      esCurricular: esCurricular,
      estado: estado,
      fechaSolicitud: fSol,
      fechaUltimoCambio: fUlt,
      notaInstitucion: nota.isEmpty ? null : nota,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SolicitudVacanteInstitucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return SolicitudVacanteInstitucion.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    }
    throw const FormatException(
      'SolicitudVacanteInstitucion.fromJson: JSON inválido',
    );
  }
}
