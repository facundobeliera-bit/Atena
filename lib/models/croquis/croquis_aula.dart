// lib/models/croquis/croquis_aula.dart
//
// ATENA – CROQUIS AULA (CANÓNICO)
//
// Objetivo:
// - Representar un croquis de aula en grilla (V1)
// - Celdas con nombre visible (sin DNI)
// - Soporte de "grupos" (bloques rectangulares que abarcan varias celdas)
//
// Nota:
// - Este modelo es backend-ready (serializable).
// - UI puede usarlo para drag & drop más adelante.
//
// ✅ CANÓNICO (feb 2026):
// - `turno` se almacena como TURNO KEY estable (ej: morning/afternoon/night/full_day),
//   NO como label traducible ("Mañana", "Tarde", ...).
//
// HARDENING (enero 2026):
// - Normalización de strings (trim + colapso whitespace).
// - fromMap tolerante a ints/doubles/strings.
// - Sanitiza tamaños y asegura invariantes (sin explotar).
// - Defiende copyWith ante celdas mal dimensionadas.
// - Helpers utilitarios: indexOf / inBounds / isEmpty / conCeldas.
//
// ✅ FIX (cierre):
// - `fromMap` tolerante a Map dinámico y a estructuras raras (sin tirar).
// - `grupos` siempre se guarda como lista inmutable.
// - Invariantes reforzados: dimensiones clamp + celdas siempre coinciden.
// - Helpers extra: `sameSizeAs`, `withSize`, `clearAll`, `withNombreEn`.
//

class CroquisAula {
  /// Perfil institución (canónico). Ayuda a separar datos por institución.
  final String institucionId;

  /// Identificación del aula/grupo (ej: "1A", "Sala 3", etc.)
  final String aula;

  /// Turno KEY estable (ej: "morning", "afternoon", "night", "full_day").
  final String turno;

  /// Grilla V1: default 10x10 (configurable)
  final int filas;
  final int columnas;

  /// Celdas: length = filas * columnas
  /// Cada celda guarda el NOMBRE (o null si está vacía).
  final List<String?> celdas;

  /// Bloques de grupo (opcional)
  final List<CroquisGrupo> grupos;

  const CroquisAula({
    required this.institucionId,
    required this.aula,
    required this.turno,
    this.filas = 10,
    this.columnas = 10,
    required this.celdas,
    this.grupos = const <CroquisGrupo>[],
  }) : assert(filas > 0),
       assert(columnas > 0),
       assert(celdas.length == filas * columnas);

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  bool inBounds(int fila, int col) =>
      fila >= 0 && col >= 0 && fila < filas && col < columnas;

  int indexOf(int fila, int col) => (fila * columnas) + col;

  bool sameSizeAs(CroquisAula other) =>
      filas == other.filas && columnas == other.columnas;

  String? nombreEn(int fila, int col) {
    if (!inBounds(fila, col)) return null;
    final idx = indexOf(fila, col);
    if (idx < 0 || idx >= celdas.length) return null;
    return celdas[idx];
  }

  bool get isEmpty {
    for (final v in celdas) {
      if (v != null && v.trim().isNotEmpty) return false;
    }
    return true;
  }

  CroquisAula conCeldas(List<String?> nuevas) {
    final fixed = _fixCeldas(raw: nuevas, filas: filas, columnas: columnas);
    return copyWith(celdas: fixed);
  }

  CroquisAula withNombreEn(int fila, int col, String? nombre) {
    if (!inBounds(fila, col)) return this;
    final idx = indexOf(fila, col);
    if (idx < 0 || idx >= celdas.length) return this;

    final next = List<String?>.from(celdas);
    final n = _cell(nombre);
    next[idx] = n;

    return copyWith(celdas: next);
  }

  CroquisAula clearAll({bool clearGrupos = false}) {
    final nextCeldas = List<String?>.filled(filas * columnas, null);
    return copyWith(
      celdas: nextCeldas,
      grupos: clearGrupos ? const <CroquisGrupo>[] : grupos,
    );
  }

  CroquisAula withSize({required int filas, required int columnas}) {
    return copyWith(filas: filas, columnas: columnas);
  }

  CroquisAula copyWith({
    String? institucionId,
    String? aula,
    String? turno,
    int? filas,
    int? columnas,
    List<String?>? celdas,
    List<CroquisGrupo>? grupos,
  }) {
    final nf = _safeDim(filas ?? this.filas, fallback: this.filas);
    final nc = _safeDim(columnas ?? this.columnas, fallback: this.columnas);

    final fixedCeldas = _fixCeldas(
      raw: celdas ?? this.celdas,
      filas: nf,
      columnas: nc,
    );

    final nextGrupos = (grupos ?? this.grupos)
        .map(_healGrupo)
        .toList(growable: false);

    final nextTurno = _norm(turno ?? this.turno);

    return CroquisAula(
      institucionId: _norm(institucionId ?? this.institucionId),
      aula: _norm(aula ?? this.aula),
      // ✅ si por compat viene vacío, usamos fallback estable (no label traducible)
      turno: nextTurno.isEmpty ? 'morning' : nextTurno,
      filas: nf,
      columnas: nc,
      celdas: fixedCeldas,
      grupos: nextGrupos,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'institucionId': institucionId,
    'aula': aula,
    'turno': turno,
    'filas': filas,
    'columnas': columnas,
    'celdas': celdas,
    'grupos': grupos.map((g) => g.toMap()).toList(growable: false),
  };

  factory CroquisAula.fromMap(Map<String, dynamic> map) {
    final filas = _intAny(map['filas'], fallback: 10);
    final columnas = _intAny(map['columnas'], fallback: 10);

    final safeFilas = _safeDim(filas, fallback: 10);
    final safeCols = _safeDim(columnas, fallback: 10);

    final fixed = _fixCeldas(
      raw: map['celdas'],
      filas: safeFilas,
      columnas: safeCols,
    );

    final grupos = _parseGrupos(
      map['grupos'],
    ).map(_healGrupo).toList(growable: false);

    final t = _norm((map['turno'] ?? '').toString());

    return CroquisAula(
      institucionId: _norm((map['institucionId'] ?? '').toString()),
      aula: _norm((map['aula'] ?? '').toString()),
      // ✅ fallback estable (no label traducible)
      turno: t.isEmpty ? 'morning' : t,
      filas: safeFilas,
      columnas: safeCols,
      celdas: fixed,
      grupos: grupos,
    );
  }

  /// Factory tolerante: acepta Map dinámico.
  factory CroquisAula.fromAny(dynamic raw) {
    if (raw is CroquisAula) return raw;
    if (raw is Map<String, dynamic>) return CroquisAula.fromMap(raw);
    if (raw is Map) {
      return CroquisAula.fromMap(Map<String, dynamic>.from(raw));
    }
    // fallback estable (no rompe)
    return CroquisAula(
      institucionId: '',
      aula: '',
      turno: 'morning',
      filas: 10,
      columnas: 10,
      celdas: List<String?>.filled(100, null),
      grupos: const <CroquisGrupo>[],
    );
  }

  // ─────────────────────────────────────────────
  // Internals (private)
  // ─────────────────────────────────────────────

  static String _norm(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return parts.join(' ');
  }

  static int _safeDim(int v, {required int fallback}) {
    if (v <= 0) return fallback > 0 ? fallback : 10;
    // límite defensivo: evita mapas absurdos que rompan UI
    if (v > 100) return 100;
    return v;
  }

  static int _intAny(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;
    return int.tryParse(s) ?? fallback;
  }

  static List<String?> _fixCeldas({
    required dynamic raw,
    required int filas,
    required int columnas,
  }) {
    final expected = filas * columnas;
    final fixed = List<String?>.filled(expected, null);

    if (raw is List<String?>) {
      for (int i = 0; i < expected && i < raw.length; i++) {
        fixed[i] = _cell(raw[i]);
      }
      return fixed;
    }

    if (raw is List) {
      for (int i = 0; i < expected && i < raw.length; i++) {
        fixed[i] = _cell(raw[i]);
      }
      return fixed;
    }

    return fixed;
  }

  static String? _cell(dynamic e) {
    if (e == null) return null;
    final s = e.toString().trim();
    if (s.isEmpty) return null;
    return _norm(s);
  }

  static List<CroquisGrupo> _parseGrupos(dynamic raw) {
    if (raw is List<CroquisGrupo>) return raw;
    if (raw is List) {
      final out = <CroquisGrupo>[];
      for (final e in raw) {
        if (e is CroquisGrupo) {
          out.add(e);
          continue;
        }
        if (e is Map<String, dynamic>) {
          out.add(CroquisGrupo.fromMap(e));
          continue;
        }
        if (e is Map) {
          out.add(CroquisGrupo.fromMap(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    }
    return const <CroquisGrupo>[];
  }

  static CroquisGrupo _healGrupo(CroquisGrupo g) {
    int safePos(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);
    int safeSize(int v) => v <= 0 ? 1 : (v > 100 ? 100 : v);

    final titulo = _norm(g.titulo);
    final fila = safePos(g.fila);
    final col = safePos(g.col);
    final alto = safeSize(g.alto);
    final ancho = safeSize(g.ancho);

    if (titulo == g.titulo &&
        fila == g.fila &&
        col == g.col &&
        alto == g.alto &&
        ancho == g.ancho) {
      return g;
    }

    return CroquisGrupo(
      titulo: titulo,
      fila: fila,
      col: col,
      alto: alto,
      ancho: ancho,
      colorHex: g.colorHex,
    );
  }
}

class CroquisGrupo {
  /// Título opcional del grupo (ej: "Grupo 1", "Mesa A")
  final String titulo;

  /// Coordenadas (fila/col) del rectángulo (top-left)
  final int fila;
  final int col;

  /// Tamaño del rectángulo (en celdas)
  final int alto;
  final int ancho;

  /// Opcional: color (UI futura). No obligatorio para V1.
  final String? colorHex;

  const CroquisGrupo({
    required this.titulo,
    required this.fila,
    required this.col,
    required this.alto,
    required this.ancho,
    this.colorHex,
  }) : assert(alto > 0),
       assert(ancho > 0);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'titulo': titulo,
    'fila': fila,
    'col': col,
    'alto': alto,
    'ancho': ancho,
    if ((colorHex ?? '').trim().isNotEmpty) 'colorHex': colorHex!.trim(),
  };

  factory CroquisGrupo.fromMap(Map<String, dynamic> map) {
    int intAny(dynamic v, {required int fallback}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is num) return v.round();
      final s = v.toString().trim();
      if (s.isEmpty) return fallback;
      return int.tryParse(s) ?? fallback;
    }

    String norm(String s) {
      final t = s.trim();
      if (t.isEmpty) return '';
      final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      return parts.join(' ');
    }

    int safePos(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);
    int safeSize(int v) => v <= 0 ? 1 : (v > 100 ? 100 : v);

    final titulo = norm((map['titulo'] ?? '').toString());
    final fila = safePos(intAny(map['fila'], fallback: 0));
    final col = safePos(intAny(map['col'], fallback: 0));
    final alto = safeSize(intAny(map['alto'], fallback: 1));
    final ancho = safeSize(intAny(map['ancho'], fallback: 1));

    final colorRaw = (map['colorHex'] ?? '').toString().trim();
    final colorHex = colorRaw.isEmpty ? null : colorRaw;

    return CroquisGrupo(
      titulo: titulo,
      fila: fila,
      col: col,
      alto: alto,
      ancho: ancho,
      colorHex: colorHex,
    );
  }

  CroquisGrupo copyWith({
    String? titulo,
    int? fila,
    int? col,
    int? alto,
    int? ancho,
    String? colorHex,
  }) {
    return CroquisGrupo(
      titulo: titulo ?? this.titulo,
      fila: fila ?? this.fila,
      col: col ?? this.col,
      alto: alto ?? this.alto,
      ancho: ancho ?? this.ancho,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
