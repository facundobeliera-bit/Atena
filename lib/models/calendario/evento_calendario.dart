// lib/models/calendario/evento_calendario.dart
import 'dart:convert';

/// ─────────────────────────────────────────────
/// ATENA – CALENDARIO (MODELO CANÓNICO)
/// Fase 2 (enero 2026): EventoEspecial institucional
///
/// Objetivo:
/// - Mantener compatibilidad total con EventoCalendario existente.
/// - Incorporar “Evento Especial” diferenciado para institución (curricular/extracurricular).
/// - Backend-ready: claves estables, enums con fallback, serialización robusta.
/// - NO introduce flujos paralelos: solo amplía el modelo.
/// ─────────────────────────────────────────────

enum TipoEventoCalendario {
  recordatorioSolicitud,
  solicitudConfirmada,
  solicitudRechazada,
  solicitudCancelada,

  /// Evento “normal” tipo fecha importante (legacy).
  fechaImportante,

  /// ✅ NUEVO (Fase 2): Evento Especial institucional (no mezclar con normales).
  eventoEspecial,
}

extension TipoEventoCalendarioX on TipoEventoCalendario {
  String get label {
    switch (this) {
      case TipoEventoCalendario.recordatorioSolicitud:
        return 'Recordatorio';
      case TipoEventoCalendario.solicitudConfirmada:
        return 'Confirmación';
      case TipoEventoCalendario.solicitudRechazada:
        return 'Rechazo';
      case TipoEventoCalendario.solicitudCancelada:
        return 'Cancelación';
      case TipoEventoCalendario.fechaImportante:
        return 'Fecha importante';
      case TipoEventoCalendario.eventoEspecial:
        return 'Evento especial';
    }
  }

  static TipoEventoCalendario fromString(String v) {
    final s = v.trim();
    return TipoEventoCalendario.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TipoEventoCalendario.fechaImportante,
    );
  }
}

/// ✅ NUEVO (Fase 2): Tipo de Evento Especial (institucional)
enum TipoEventoEspecial {
  inicioClases,
  finClases,
  receso,
  inicioCiclo,
  finCiclo,
  otro,
}

extension TipoEventoEspecialX on TipoEventoEspecial {
  String get label {
    switch (this) {
      case TipoEventoEspecial.inicioClases:
        return 'Inicio de clases';
      case TipoEventoEspecial.finClases:
        return 'Fin de clases';
      case TipoEventoEspecial.receso:
        return 'Receso';
      case TipoEventoEspecial.inicioCiclo:
        return 'Inicio de ciclo';
      case TipoEventoEspecial.finCiclo:
        return 'Fin de ciclo';
      case TipoEventoEspecial.otro:
        return 'Otro';
    }
  }

  static TipoEventoEspecial fromString(String v) {
    final s = v.trim();
    return TipoEventoEspecial.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TipoEventoEspecial.otro,
    );
  }
}

/// ✅ NUEVO (Fase 2): Nivel educativo (curricular)
enum NivelEducativo { jardin, primaria, secundaria, otro }

extension NivelEducativoX on NivelEducativo {
  String get label {
    switch (this) {
      case NivelEducativo.jardin:
        return 'Jardín';
      case NivelEducativo.primaria:
        return 'Primaria';
      case NivelEducativo.secundaria:
        return 'Secundaria';
      case NivelEducativo.otro:
        return 'Otro';
    }
  }

  static NivelEducativo fromString(String v) {
    final s = v.trim();
    return NivelEducativo.values.firstWhere(
      (e) => e.name == s,
      orElse: () => NivelEducativo.otro,
    );
  }
}

/// ✅ NUEVO (Fase 2): Turno (curricular/extracurricular si aplica)
enum TurnoInstitucion { manana, tarde, noche, otro }

extension TurnoInstitucionX on TurnoInstitucion {
  String get label {
    switch (this) {
      case TurnoInstitucion.manana:
        return 'Mañana';
      case TurnoInstitucion.tarde:
        return 'Tarde';
      case TurnoInstitucion.noche:
        return 'Noche';
      case TurnoInstitucion.otro:
        return 'Otro';
    }
  }

  static TurnoInstitucion fromString(String v) {
    final s = v.trim();
    return TurnoInstitucion.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TurnoInstitucion.otro,
    );
  }
}

/// ✅ NUEVO (Fase 2): Targeting/segmentación del Evento Especial
class SegmentoEventoEspecial {
  final NivelEducativo? nivel;
  final TurnoInstitucion? turno;

  /// - curricular: “Sala 4”, “1°A”, etc.
  /// - extracurricular: “Grupo 1”, “Avanzado”, etc.
  final String? grupoKey;

  /// Alias opcional más humano.
  final String? grupoLabel;

  const SegmentoEventoEspecial({
    required this.nivel,
    required this.turno,
    required this.grupoKey,
    required this.grupoLabel,
  });

  SegmentoEventoEspecial copyWith({
    NivelEducativo? nivel,
    TurnoInstitucion? turno,
    String? grupoKey,
    String? grupoLabel,
  }) {
    return SegmentoEventoEspecial(
      nivel: nivel ?? this.nivel,
      turno: turno ?? this.turno,
      grupoKey: grupoKey ?? this.grupoKey,
      grupoLabel: grupoLabel ?? this.grupoLabel,
    );
  }

  Map<String, dynamic> toMap() => {
    'nivel': nivel?.name,
    'turno': turno?.name,
    'grupoKey': grupoKey,
    'grupoLabel': grupoLabel,
  };

  static SegmentoEventoEspecial fromMap(Map<String, dynamic> m) {
    return SegmentoEventoEspecial(
      nivel: (m['nivel'] == null)
          ? null
          : NivelEducativoX.fromString((m['nivel'] ?? '').toString()),
      turno: (m['turno'] == null)
          ? null
          : TurnoInstitucionX.fromString((m['turno'] ?? '').toString()),
      grupoKey: m['grupoKey']?.toString(),
      grupoLabel: m['grupoLabel']?.toString(),
    );
  }
}

/// Evento unificado (sirve para curricular y extracurricular).
class EventoCalendario {
  final String id;

  /// Cuenta principal que recibe la vista completa del calendario.
  final String ownerAccountId;

  /// Perfil concreto (si aplica). Si es null, el evento es “global de la cuenta”.
  final String? perfilId;

  final String titulo;
  final String descripcion;

  final DateTime inicio;
  final DateTime? fin;

  /// Vinculación: institución / solicitud / actividad
  final String? institucionId;
  final String? institucionNombre;

  final String? solicitudId;
  final String? alumnoDni;

  final String? actividadNombre;
  final bool esCurricular;

  final TipoEventoCalendario tipo;

  /// ✅ Metadata opcional SOLO si tipo == eventoEspecial
  final TipoEventoEspecial? tipoEspecial;

  /// Segmentación institucional: nivel/turno/grupo.
  final SegmentoEventoEspecial? segmentoEspecial;

  /// Permite “cerrar” recordatorios sin borrarlos (historial).
  final bool cerrado;

  EventoCalendario({
    required this.id,
    required this.ownerAccountId,
    required this.perfilId,
    required this.titulo,
    required this.descripcion,
    required this.inicio,
    required this.fin,
    required this.institucionId,
    required this.institucionNombre,
    required this.solicitudId,
    required this.alumnoDni,
    required this.actividadNombre,
    required this.esCurricular,
    required this.tipo,
    required this.tipoEspecial,
    required this.segmentoEspecial,
    required this.cerrado,
  });

  EventoCalendario copyWith({
    String? id,
    String? ownerAccountId,
    String? perfilId,
    String? titulo,
    String? descripcion,
    DateTime? inicio,
    DateTime? fin,
    String? institucionId,
    String? institucionNombre,
    String? solicitudId,
    String? alumnoDni,
    String? actividadNombre,
    bool? esCurricular,
    TipoEventoCalendario? tipo,
    TipoEventoEspecial? tipoEspecial,
    SegmentoEventoEspecial? segmentoEspecial,
    bool? cerrado,
  }) {
    return EventoCalendario(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      perfilId: perfilId ?? this.perfilId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      institucionId: institucionId ?? this.institucionId,
      institucionNombre: institucionNombre ?? this.institucionNombre,
      solicitudId: solicitudId ?? this.solicitudId,
      alumnoDni: alumnoDni ?? this.alumnoDni,
      actividadNombre: actividadNombre ?? this.actividadNombre,
      esCurricular: esCurricular ?? this.esCurricular,
      tipo: tipo ?? this.tipo,
      tipoEspecial: tipoEspecial ?? this.tipoEspecial,
      segmentoEspecial: segmentoEspecial ?? this.segmentoEspecial,
      cerrado: cerrado ?? this.cerrado,
    );
  }

  bool get esEventoEspecial => tipo == TipoEventoCalendario.eventoEspecial;

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerAccountId': ownerAccountId,
    'perfilId': perfilId,
    'titulo': titulo,
    'descripcion': descripcion,
    'inicio': inicio.toIso8601String(),
    'fin': fin?.toIso8601String(),
    'institucionId': institucionId,
    'institucionNombre': institucionNombre,
    'solicitudId': solicitudId,
    'alumnoDni': alumnoDni,
    'actividadNombre': actividadNombre,
    'esCurricular': esCurricular,
    'tipo': tipo.name,
    'tipoEspecial': tipoEspecial?.name,
    'segmentoEspecial': segmentoEspecial?.toMap(),
    'cerrado': cerrado,
  };

  static bool _b(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v.toInt() != 0;
    final s = (v ?? '').toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static EventoCalendario fromMap(Map<String, dynamic> m) {
    DateTime dt(dynamic v) =>
        DateTime.tryParse((v ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final tipo = TipoEventoCalendarioX.fromString((m['tipo'] ?? '').toString());

    final tipoEspecialRaw = m['tipoEspecial'];
    final segRaw = m['segmentoEspecial'];

    final segMap = (segRaw is Map<String, dynamic>)
        ? segRaw
        : (segRaw is Map ? Map<String, dynamic>.from(segRaw) : null);

    return EventoCalendario(
      id: (m['id'] ?? '').toString(),
      ownerAccountId: (m['ownerAccountId'] ?? '').toString(),
      perfilId: m['perfilId']?.toString(),
      titulo: (m['titulo'] ?? '').toString(),
      descripcion: (m['descripcion'] ?? '').toString(),
      inicio: dt(m['inicio']),
      fin: (m['fin'] == null) ? null : dt(m['fin']),
      institucionId: m['institucionId']?.toString(),
      institucionNombre: m['institucionNombre']?.toString(),
      solicitudId: m['solicitudId']?.toString(),
      alumnoDni: m['alumnoDni']?.toString(),
      actividadNombre: m['actividadNombre']?.toString(),
      esCurricular: _b(m['esCurricular'], fallback: false),
      tipo: tipo,
      tipoEspecial: (tipoEspecialRaw == null)
          ? null
          : TipoEventoEspecialX.fromString(tipoEspecialRaw.toString()),
      segmentoEspecial: (segMap == null)
          ? null
          : SegmentoEventoEspecial.fromMap(segMap),
      cerrado: _b(m['cerrado'], fallback: false),
    );
  }

  String toJson() => jsonEncode(toMap());
  static EventoCalendario fromJson(String s) => fromMap(jsonDecode(s));
}
