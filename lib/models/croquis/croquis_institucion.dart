// lib/models/croquis/croquis_institucion.dart
//
// ATENA – CROQUIS INSTITUCIÓN (CANÓNICO)
//
// Rol:
// - Contenedor/índice de croquis por institución.
// - Permite múltiples aulas/turnos sin mezclar datos.
// - Backend-ready (serializable), tolerante a legacy.
//
// Nota:
// - El contenido “pesado” del croquis está en CroquisAula (croquis_aula.dart).
// - Este modelo administra el catálogo + metadata.
//
// HARDENING (ene 2026):
// - Normalización de strings (trim + colapso whitespace).
// - fromMap tolerante a Map/List/String.
// - Sanitiza tamaños y evita crashes.

import 'dart:convert';

import 'croquis_aula.dart';

class CroquisInstitucion {
  final String institucionId;

  /// Versión de esquema para migraciones (cuando haga falta).
  final int schemaVersion;

  /// Última actualización global del catálogo.
  final DateTime updatedAt;

  /// Lista de croquis por aula/turno (cada uno puede tener data embebida).
  final List<CroquisAulaEntry> entries;

  const CroquisInstitucion({
    required this.institucionId,
    required this.schemaVersion,
    required this.updatedAt,
    required this.entries,
  });

  factory CroquisInstitucion.empty({required String institucionId}) {
    return CroquisInstitucion(
      institucionId: _norm(institucionId),
      schemaVersion: 1,
      updatedAt: DateTime.now(),
      entries: const <CroquisAulaEntry>[],
    );
  }

  CroquisInstitucion copyWith({
    String? institucionId,
    int? schemaVersion,
    DateTime? updatedAt,
    List<CroquisAulaEntry>? entries,
  }) {
    return CroquisInstitucion(
      institucionId: _norm(institucionId ?? this.institucionId),
      schemaVersion: schemaVersion ?? this.schemaVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
    );
  }

  /// Key estable para indexar por aula+turno.
  static String aulaTurnoKeyOf(String aula, String turno) {
    final a = _norm(aula).toLowerCase();
    final t = _norm(turno).toLowerCase();
    final aa = a.isEmpty ? 'aula' : a;
    final tt = t.isEmpty ? 'turno' : t;
    return '$aa|$tt';
  }

  CroquisAulaEntry? findEntry({required String aula, required String turno}) {
    final key = aulaTurnoKeyOf(aula, turno);
    for (final e in entries) {
      if (e.aulaTurnoKey == key) return e;
    }
    return null;
  }

  /// Upsert por aula+turno (mantiene un único entry).
  CroquisInstitucion upsertAula(CroquisAula aulaData) {
    final key = aulaTurnoKeyOf(aulaData.aula, aulaData.turno);
    final next = <CroquisAulaEntry>[];

    bool replaced = false;
    for (final e in entries) {
      if (e.aulaTurnoKey == key) {
        next.add(
          e.copyWith(
            aula: aulaData.aula,
            turno: aulaData.turno,
            croquis: aulaData,
            updatedAt: DateTime.now(),
          ),
        );
        replaced = true;
      } else {
        next.add(e);
      }
    }

    if (!replaced) {
      next.add(
        CroquisAulaEntry(
          aulaTurnoKey: key,
          aula: _norm(aulaData.aula),
          turno: _norm(aulaData.turno),
          croquis: aulaData,
          updatedAt: DateTime.now(),
        ),
      );
    }

    return copyWith(updatedAt: DateTime.now(), entries: next);
  }

  /// Elimina por aula+turno.
  CroquisInstitucion removeAula({required String aula, required String turno}) {
    final key = aulaTurnoKeyOf(aula, turno);
    final next = entries.where((e) => e.aulaTurnoKey != key).toList();
    return copyWith(updatedAt: DateTime.now(), entries: next);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'institucionId': institucionId,
    'schemaVersion': schemaVersion,
    'updatedAt': updatedAt.toIso8601String(),
    'entries': entries.map((e) => e.toMap()).toList(),
  };

  factory CroquisInstitucion.fromMap(Map<String, dynamic> m) {
    final instId = _norm(_asString(m['institucionId']));
    final ver = _asInt(m['schemaVersion'], fallback: 1);
    final upd = _asDate(m['updatedAt'], fallback: DateTime.now());

    final rawEntries = m['entries'] ?? m['aulas'] ?? m['croquisAulas'];
    final entries = _asList<CroquisAulaEntry>(
      rawEntries,
      (e) => CroquisAulaEntry.fromMap(_asMap(e)),
    );

    // hardening: si falta institucionId en entries embebidos, no explotamos
    final fixedEntries = <CroquisAulaEntry>[];
    for (final e in entries) {
      fixedEntries.add(e._ensureKey());
    }

    return CroquisInstitucion(
      institucionId: instId,
      schemaVersion: ver <= 0 ? 1 : ver,
      updatedAt: upd,
      entries: fixedEntries,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CroquisInstitucion.fromJson(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return CroquisInstitucion.fromMap(_asMap(decoded));
    }
    throw FormatException('CroquisInstitucion.fromJson: JSON inválido');
  }
}

class CroquisAulaEntry {
  /// Key estable (aula|turno) normalizado en lower-case.
  final String aulaTurnoKey;

  /// Metadata visible.
  final String aula;
  final String turno;

  /// Payload embebido (V1: adentro para prototipo local).
  final CroquisAula? croquis;

  /// Si más adelante separás persistencia, podés usar un refId.
  final String? refId;

  final DateTime updatedAt;

  const CroquisAulaEntry({
    required this.aulaTurnoKey,
    required this.aula,
    required this.turno,
    required this.croquis,
    required this.updatedAt,
    this.refId,
  });

  CroquisAulaEntry copyWith({
    String? aulaTurnoKey,
    String? aula,
    String? turno,
    CroquisAula? croquis,
    String? refId,
    DateTime? updatedAt,
  }) {
    return CroquisAulaEntry(
      aulaTurnoKey: _norm(aulaTurnoKey ?? this.aulaTurnoKey),
      aula: _norm(aula ?? this.aula),
      turno: _norm(turno ?? this.turno),
      croquis: croquis ?? this.croquis,
      refId: refId ?? this.refId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CroquisAulaEntry _ensureKey() {
    final k = CroquisInstitucion.aulaTurnoKeyOf(aula, turno);
    return aulaTurnoKey.trim().isEmpty ? copyWith(aulaTurnoKey: k) : this;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'aulaTurnoKey': aulaTurnoKey,
    'aula': aula,
    'turno': turno,
    'croquis': croquis?.toMap(),
    'refId': refId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CroquisAulaEntry.fromMap(Map<String, dynamic> m) {
    final aula = _norm(_asString(m['aula'], fallback: 'Aula'));
    final turno = _norm(_asString(m['turno'], fallback: 'Turno'));

    final keyRaw = _asString(m['aulaTurnoKey']).trim();
    final key = keyRaw.isEmpty
        ? CroquisInstitucion.aulaTurnoKeyOf(aula, turno)
        : _norm(keyRaw);

    CroquisAula? croquis;
    final rawCroquis = m['croquis'] ?? m['data'] ?? m['croquisAula'];
    if (rawCroquis != null) {
      try {
        if (rawCroquis is Map) {
          final map = _asMap(rawCroquis);
          if (map.isNotEmpty) croquis = CroquisAula.fromMap(map);
        } else if (rawCroquis is String) {
          final s = rawCroquis.trim();
          if (s.isNotEmpty) {
            final decoded = jsonDecode(s);
            if (decoded is Map) croquis = CroquisAula.fromMap(_asMap(decoded));
          }
        }
      } catch (_) {
        croquis = null;
      }
    }

    return CroquisAulaEntry(
      aulaTurnoKey: key,
      aula: aula,
      turno: turno,
      croquis: croquis,
      refId: m['refId']?.toString(),
      updatedAt: _asDate(m['updatedAt'], fallback: DateTime.now()),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers internos (parsers seguros)
// ─────────────────────────────────────────────

String _norm(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  return parts.join(' ');
}

int _asInt(dynamic v, {required int fallback}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.round();
  final s = v.toString().trim();
  if (s.isEmpty) return fallback;
  return int.tryParse(s) ?? fallback;
}

String _asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime _asDate(dynamic v, {required DateTime fallback}) {
  if (v == null) return fallback;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.round());
  final s = v.toString().trim();
  if (s.isEmpty) return fallback;
  final p = DateTime.tryParse(s);
  if (p != null) return p;
  final asInt = int.tryParse(s);
  if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  return fallback;
}

List<T> _asList<T>(dynamic v, T Function(dynamic e) mapFn) {
  if (v is! List) return <T>[];
  final out = <T>[];
  for (final e in v) {
    try {
      out.add(mapFn(e));
    } catch (_) {
      // tolerancia legacy
    }
  }
  return out;
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}
