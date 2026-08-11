// lib/models/instituciones/grupo_curricular.dart
//
// ATENA – GRUPO CURRICULAR (CANÓNICO / E2E)
//
// Objetivo:
// - Modelo simple y estable para cupos por curso/sala + turno.
// - Keys canónicas: id, nombreCurso, turno, cuposTotales, cuposOcupados.
// - (Opcional) horario para UI: horaInicio/horaFin (string "HH:MM").
// - HARDENING: fromMap tolera variantes legacy comunes (sin forzar escrituras legacy).
//
// Nota:
// - TurnoCurricular.key == name (manana/tarde/noche) para persistencia estable.
// - id es CANÓNICO y debe ser estable entre:
//     Gestión Vacantes (institución)  <->  Solicitudes (alumno)
//   Si legacy no trae id, generamos uno determinístico (fallback) para NO romper.
//   En backend real, id vendrá desde la fuente de verdad.
// ------------------------------------------------------------

import 'dart:convert';

enum TurnoCurricular { manana, tarde, noche }

extension TurnoCurricularX on TurnoCurricular {
  String get key => name; // 'manana' | 'tarde' | 'noche'

  static TurnoCurricular parse(
    dynamic v, {
    TurnoCurricular fallback = TurnoCurricular.manana,
  }) {
    if (v == null) return fallback;

    // Acepta el enum directo.
    if (v is TurnoCurricular) return v;

    final raw = v.toString().trim();
    final s = raw.toLowerCase();
    if (s.isEmpty) return fallback;

    // Tolerancia típica (acentos / alias)
    if (s == 'mañana' || s == 'maniana') return TurnoCurricular.manana;

    // Heurística best-effort para legacy:
    // - "tarde", "pm", "afternoon"
    // - "noche", "night"
    // - "mañana", "am", "morning"
    if (s.contains('tarde') || s.contains('pm') || s.contains('afternoon')) {
      return TurnoCurricular.tarde;
    }
    if (s.contains('noche') || s.contains('night')) {
      return TurnoCurricular.noche;
    }
    if (s.contains('mañ') ||
        s.contains('maniana') ||
        s.contains('morning') ||
        s.contains('am')) {
      return TurnoCurricular.manana;
    }

    // Match exacto por enum
    for (final t in TurnoCurricular.values) {
      if (t.name == s) return t;
    }

    return fallback;
  }
}

class GrupoCurricular {
  /// ✅ CANÓNICO E2E: ID estable del grupo (curso + turno + (opcional) horario).
  /// Fuente de verdad: backend/inst.
  /// Fallback: id determinístico si legacy no trae id.
  final String id;

  final String nombreCurso;

  /// Turno canónico (E2E): lo define backend/inst.
  final TurnoCurricular turno;

  /// (Opcional) Horario para UI, no afecta reglas de cupo.
  /// Formato recomendado: "HH:MM" (best-effort).
  final String? horaInicio;
  final String? horaFin;

  final int cuposTotales;
  final int cuposOcupados;

  const GrupoCurricular._({
    required this.id,
    required this.nombreCurso,
    required this.turno,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.horaInicio,
    required this.horaFin,
  });

  /// Fallback determinístico: no random, no UUID.
  /// - Normaliza nombreCurso a snake-ish (solo [a-z0-9_])
  /// - Incluye turno
  /// - Incluye horario si existe (para distinguir “mismo curso, mismo turno, distinto horario”)
  static String makeDeterministicId({
    required String nombreCurso,
    required TurnoCurricular turno,
    String? horaInicio,
    String? horaFin,
  }) {
    String normKey(String s) {
      final t = s.trim().toLowerCase();
      if (t.isEmpty) return '';
      final buf = StringBuffer();

      for (final r in t.runes) {
        final c = String.fromCharCode(r);
        final isAz = (r >= 97 && r <= 122); // a-z
        final is09 = (r >= 48 && r <= 57); // 0-9
        if (isAz || is09) {
          buf.write(c);
        } else if (c == ' ' || c == '-' || c == '_') {
          buf.write('_');
        }
        // otros chars: se omiten (best-effort)
      }

      var out = buf.toString().replaceAll(RegExp(r'_+'), '_');
      out = out.replaceAll(RegExp(r'^_+'), '').replaceAll(RegExp(r'_+$'), '');
      return out;
    }

    String normTimeForId(String? v) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return '';
      // extraemos solo dígitos para un id “safe” (ej: "08:30" => "0830")
      final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
      return digits;
    }

    final n = normKey(nombreCurso);

    final hi = normTimeForId(horaInicio);
    final hf = normTimeForId(horaFin);

    final hasHorario = hi.isNotEmpty || hf.isNotEmpty;
    final horarioPart = hasHorario ? '__${hi}_$hf' : '';

    final base = '${turno.key}__${n.isEmpty ? 'grupo' : n}$horarioPart';
    return base;
  }

  factory GrupoCurricular({
    String? id,
    required String nombreCurso,
    TurnoCurricular turno = TurnoCurricular.manana,
    String? horaInicio,
    String? horaFin,
    int cuposTotales = 30,
    int cuposOcupados = 0,
  }) {
    final n = nombreCurso.trim();
    if (n.isEmpty) {
      throw ArgumentError('GrupoCurricular: nombreCurso vacío');
    }

    String? normTime(String? v) {
      final t = (v ?? '').trim();
      return t.isEmpty ? null : t;
    }

    final hi = normTime(horaInicio);
    final hf = normTime(horaFin);

    final tot = cuposTotales < 1 ? 1 : cuposTotales;
    final occ = cuposOcupados < 0 ? 0 : cuposOcupados;
    final occClamped = occ > tot ? tot : occ;

    final idFinal = (id ?? '').trim().isNotEmpty
        ? (id ?? '').trim()
        : makeDeterministicId(
            nombreCurso: n,
            turno: turno,
            horaInicio: hi,
            horaFin: hf,
          );

    return GrupoCurricular._(
      id: idFinal,
      nombreCurso: n,
      turno: turno,
      cuposTotales: tot,
      cuposOcupados: occClamped,
      horaInicio: hi,
      horaFin: hf,
    );
  }

  // Alias semántico (UI)
  String get nombre => nombreCurso;

  int get cuposDisponibles => (cuposTotales - cuposOcupados).clamp(0, 9999);
  bool get tieneCuposDisponibles => cuposDisponibles > 0;

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      // ✅ claves canónicas E2E
      'id': id,
      'nombreCurso': nombreCurso,
      'turno': turno.key,
      'cuposTotales': cuposTotales,
      'cuposOcupados': cuposOcupados,
    };

    final hi = (horaInicio ?? '').trim();
    final hf = (horaFin ?? '').trim();
    if (hi.isNotEmpty) m['horaInicio'] = hi;
    if (hf.isNotEmpty) m['horaFin'] = hf;

    return m;
  }

  factory GrupoCurricular.fromMap(Map<String, dynamic> m) {
    int asInt(dynamic v, {required int fallback}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.round();
      final s = v.toString().trim();
      return int.tryParse(s) ?? fallback;
    }

    String asString(dynamic v) => (v ?? '').toString().trim();

    // ✅ Lectura tolerante (sin romper canónico)
    // - id legacy: grupoCurricularId / grupoId / idGrupo / key
    String readId() {
      final a = asString(m['id']);
      if (a.isNotEmpty) return a;

      final b = asString(m['grupoCurricularId']);
      if (b.isNotEmpty) return b;

      final c = asString(m['grupoId']);
      if (c.isNotEmpty) return c;

      final d = asString(m['idGrupo']);
      if (d.isNotEmpty) return d;

      final e = asString(m['key']);
      if (e.isNotEmpty) return e;

      return '';
    }

    // - nombreCurso legacy: nombre / curso / sala / grupo / nombreGrupo
    String readNombre() {
      final n1 = asString(m['nombreCurso']);
      if (n1.isNotEmpty) return n1;

      final n2 = asString(m['nombre']);
      if (n2.isNotEmpty) return n2;

      final n3 = asString(m['curso']);
      if (n3.isNotEmpty) return n3;

      final n4 = asString(m['sala']);
      if (n4.isNotEmpty) return n4;

      final n5 = asString(m['grupo']);
      if (n5.isNotEmpty) return n5;

      final n6 = asString(m['nombreGrupo']);
      if (n6.isNotEmpty) return n6;

      return '';
    }

    // - turno legacy: turnoKey / turnoNombre / horario (best-effort)
    dynamic readTurnoRaw() =>
        m['turno'] ?? m['turnoKey'] ?? m['turnoNombre'] ?? m['horario'];

    // - horario legacy (si existía como string libre)
    String? readHoraInicio() {
      final hi = asString(m['horaInicio']);
      if (hi.isNotEmpty) return hi;

      final h1 = asString(m['horarioInicio']);
      if (h1.isNotEmpty) return h1;

      final legacy = asString(m['hora_desde']);
      if (legacy.isNotEmpty) return legacy;

      return null;
    }

    String? readHoraFin() {
      final hf = asString(m['horaFin']);
      if (hf.isNotEmpty) return hf;

      final h2 = asString(m['horarioFin']);
      if (h2.isNotEmpty) return h2;

      final legacy = asString(m['hora_hasta']);
      if (legacy.isNotEmpty) return legacy;

      return null;
    }

    // - cupos legacy: cupoMaximo/cupoOcupado (muy común), cuposMaximos, etc.
    int readTot() {
      if (m.containsKey('cuposTotales')) {
        return asInt(m['cuposTotales'], fallback: 30);
      }
      if (m.containsKey('cupoMaximo')) {
        return asInt(m['cupoMaximo'], fallback: 30);
      }
      if (m.containsKey('cuposMaximos')) {
        return asInt(m['cuposMaximos'], fallback: 30);
      }
      if (m.containsKey('maxCupos')) {
        return asInt(m['maxCupos'], fallback: 30);
      }
      return 30;
    }

    int readOcc() {
      if (m.containsKey('cuposOcupados')) {
        return asInt(m['cuposOcupados'], fallback: 0);
      }
      if (m.containsKey('cupoOcupado')) {
        return asInt(m['cupoOcupado'], fallback: 0);
      }
      if (m.containsKey('ocupados')) {
        return asInt(m['ocupados'], fallback: 0);
      }
      if (m.containsKey('inscriptos')) {
        return asInt(m['inscriptos'], fallback: 0);
      }
      return 0;
    }

    final nombre = readNombre();
    if (nombre.isEmpty) {
      throw FormatException('GrupoCurricular.fromMap: falta nombreCurso');
    }

    final turno = TurnoCurricularX.parse(readTurnoRaw());
    final tot = readTot();
    final occ = readOcc();

    final hi = readHoraInicio();
    final hf = readHoraFin();

    final idRaw = readId();
    final idFinal = idRaw.trim().isNotEmpty
        ? idRaw.trim()
        : GrupoCurricular.makeDeterministicId(
            nombreCurso: nombre,
            turno: turno,
            horaInicio: hi,
            horaFin: hf,
          );

    return GrupoCurricular(
      id: idFinal,
      nombreCurso: nombre,
      turno: turno,
      horaInicio: hi,
      horaFin: hf,
      cuposTotales: tot,
      cuposOcupados: occ,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GrupoCurricular.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return GrupoCurricular.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('GrupoCurricular.fromJson: JSON inválido');
  }

  GrupoCurricular copyWith({
    String? id,
    String? nombreCurso,
    TurnoCurricular? turno,
    String? horaInicio,
    String? horaFin,
    int? cuposTotales,
    int? cuposOcupados,
  }) {
    return GrupoCurricular(
      id: (id ?? this.id),
      nombreCurso: (nombreCurso ?? this.nombreCurso),
      turno: turno ?? this.turno,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      cuposTotales: cuposTotales ?? this.cuposTotales,
      cuposOcupados: cuposOcupados ?? this.cuposOcupados,
    );
  }

  @override
  String toString() {
    return 'GrupoCurricular(id=$id, nombreCurso=$nombreCurso, turno=${turno.key}, '
        'cuposTotales=$cuposTotales, cuposOcupados=$cuposOcupados, '
        'horaInicio=${horaInicio ?? ''}, horaFin=${horaFin ?? ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrupoCurricular &&
        other.id == id &&
        other.nombreCurso == nombreCurso &&
        other.turno == turno &&
        other.horaInicio == horaInicio &&
        other.horaFin == horaFin &&
        other.cuposTotales == cuposTotales &&
        other.cuposOcupados == cuposOcupados;
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombreCurso,
    turno,
    horaInicio,
    horaFin,
    cuposTotales,
    cuposOcupados,
  );
}
