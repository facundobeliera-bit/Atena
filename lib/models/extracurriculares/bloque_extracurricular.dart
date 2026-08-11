// lib/models/extracurriculares/bloque_extracurricular.dart
//
// ATENA – EXTRACURRICULARES (CANÓNICO)
//
// Fuente de verdad (CANÓNICA) para los bloques extracurriculares.
// - Sin legacy.
// - Backend-ready.
// - Labels completos (lado Alumno) + "Otros".
// - Incluye guía: descripcionCorta + ejemplos (leyenda) para UI.
//
// Reglas (decisión final):
// - tryParse/tryParseAny solo aceptan:
//   1) key exacta (case-insensitive)
//   2) name exacto (case-insensitive)
//   3) label exacto (case-insensitive)
// - NO hay heurísticas por keywords.
// - Si no matchea: devuelve null (y el caller decide fallback).
//
// Nota:
// - Se agrega set canónico de keys + helpers isValidKey/fromKey para validación
//   (sin heurísticas, sin mapeos mágicos).
//
// ✅ Compat canónica (enero 2026):
// - Se agrega fromAny(...dynamic) porque ya lo consumen pantallas como wrapper estricto.
// - Se agrega fromAnyOrOtros(...) opcional para callers que NO quieran nulls
//   (fallback explícito y controlado).

enum BloqueExtracurricular {
  deporteYMovimiento,
  arteYExpresion,
  idiomasYComunicacion,
  cienciaTecnologiaYRobotica,
  apoyoAcademico,
  desarrolloPersonalYBienestar,
  otros,
}

extension BloqueExtracurricularX on BloqueExtracurricular {
  // =====================================================
  // Metadatos canónicos
  // =====================================================

  /// Key estable (snake_case) para backend/storage/URLs.
  String get key {
    switch (this) {
      case BloqueExtracurricular.deporteYMovimiento:
        return 'deporte_y_movimiento';
      case BloqueExtracurricular.arteYExpresion:
        return 'arte_y_expresion';
      case BloqueExtracurricular.idiomasYComunicacion:
        return 'idiomas_y_comunicacion';
      case BloqueExtracurricular.cienciaTecnologiaYRobotica:
        return 'ciencia_tecnologia_y_robotica';
      case BloqueExtracurricular.apoyoAcademico:
        return 'apoyo_academico';
      case BloqueExtracurricular.desarrolloPersonalYBienestar:
        return 'desarrollo_personal_y_bienestar';
      case BloqueExtracurricular.otros:
        return 'otros';
    }
  }

  /// Label “lindo” (UI).
  String get label {
    switch (this) {
      case BloqueExtracurricular.deporteYMovimiento:
        return 'Deporte y Movimiento';
      case BloqueExtracurricular.arteYExpresion:
        return 'Arte y Expresión';
      case BloqueExtracurricular.idiomasYComunicacion:
        return 'Idiomas y Comunicación';
      case BloqueExtracurricular.cienciaTecnologiaYRobotica:
        return 'Ciencia, Tecnología y Robótica';
      case BloqueExtracurricular.apoyoAcademico:
        return 'Apoyo Académico';
      case BloqueExtracurricular.desarrolloPersonalYBienestar:
        return 'Desarrollo Personal y Bienestar';
      case BloqueExtracurricular.otros:
        return 'Otros';
    }
  }

  /// Descripción corta para UI (chips, filtros, headers).
  String get descripcionCorta {
    switch (this) {
      case BloqueExtracurricular.deporteYMovimiento:
        return 'Actividades físicas, deportivas y motrices.';
      case BloqueExtracurricular.arteYExpresion:
        return 'Expresión artística: música, teatro, danza y artes visuales.';
      case BloqueExtracurricular.idiomasYComunicacion:
        return 'Idiomas, conversación y habilidades de comunicación.';
      case BloqueExtracurricular.cienciaTecnologiaYRobotica:
        return 'Ciencia aplicada, informática, programación y robótica.';
      case BloqueExtracurricular.apoyoAcademico:
        return 'Tutorías, refuerzo, técnicas de estudio y preparación de exámenes.';
      case BloqueExtracurricular.desarrolloPersonalYBienestar:
        return 'Bienestar, convivencia, hábitos saludables y desarrollo personal.';
      case BloqueExtracurricular.otros:
        return 'Propuestas fuera de las categorías principales.';
    }
  }

  /// Ejemplos/leyenda (orientativo, no restrictivo).
  List<String> get ejemplos {
    switch (this) {
      case BloqueExtracurricular.deporteYMovimiento:
        return const [
          'Fútbol, básquet, vóley, handball',
          'Gimnasia, atletismo, natación',
          'Artes marciales, yoga, entrenamiento funcional',
          'Recreación, coordinación, motricidad',
        ];
      case BloqueExtracurricular.arteYExpresion:
        return const [
          'Música, canto, instrumentos',
          'Dibujo, pintura, escultura',
          'Teatro, danza, expresión corporal',
          'Fotografía, diseño, artes visuales',
        ];
      case BloqueExtracurricular.idiomasYComunicacion:
        return const [
          'Inglés, portugués, francés, italiano',
          'Club de conversación / speaking clubs',
          'Lengua de señas (si aplica)',
          'Comunicación oral y escrita',
        ];
      case BloqueExtracurricular.cienciaTecnologiaYRobotica:
        return const [
          'Robótica, programación, informática',
          'Club de ciencia/tecnología, impresión 3D (si aplica)',
          'Pensamiento lógico, proyectos STEAM',
          'Tecnología aplicada y prototipado',
        ];
      case BloqueExtracurricular.apoyoAcademico:
        return const [
          'Apoyo escolar, tutorías, refuerzo',
          'Técnicas de estudio y organización',
          'Preparación de exámenes',
          'Acompañamiento académico por materia',
        ];
      case BloqueExtracurricular.desarrolloPersonalYBienestar:
        return const [
          'Bienestar emocional, habilidades socioemocionales',
          'Mindfulness, manejo del estrés (si aplica)',
          'Orientación vocacional / desarrollo personal',
          'Convivencia, hábitos saludables',
        ];
      case BloqueExtracurricular.otros:
        return const [
          'Catequesis u otras formaciones específicas',
          'Clubes/actividades no contempladas arriba',
          'Propuestas temporales o especiales',
        ];
    }
  }

  /// Orden estable para UI (chips/filtros/listas).
  static List<BloqueExtracurricular> ordered() => const [
    BloqueExtracurricular.deporteYMovimiento,
    BloqueExtracurricular.arteYExpresion,
    BloqueExtracurricular.idiomasYComunicacion,
    BloqueExtracurricular.cienciaTecnologiaYRobotica,
    BloqueExtracurricular.apoyoAcademico,
    BloqueExtracurricular.desarrolloPersonalYBienestar,
    BloqueExtracurricular.otros,
  ];

  static String _norm(String v) => v.trim().toLowerCase();

  // =====================================================
  // Validación / parsing (estrictos)
  // =====================================================

  /// Set canónico de keys (backend-ready).
  static const Set<String> canonicalKeys = <String>{
    'deporte_y_movimiento',
    'arte_y_expresion',
    'idiomas_y_comunicacion',
    'ciencia_tecnologia_y_robotica',
    'apoyo_academico',
    'desarrollo_personal_y_bienestar',
    'otros',
  };

  // Maps O(1) construidos una sola vez (sin cambiar reglas).
  static final Map<String, BloqueExtracurricular> _byKey = {
    for (final e in BloqueExtracurricular.values) _norm(e.key): e,
  };

  static final Map<String, BloqueExtracurricular> _byName = {
    for (final e in BloqueExtracurricular.values) _norm(e.name): e,
  };

  static final Map<String, BloqueExtracurricular> _byLabel = {
    for (final e in BloqueExtracurricular.values) _norm(e.label): e,
  };

  static void _debugAssertCoherencia() {
    assert(() {
      // canonicalKeys debe coincidir con keys reales del enum (normalizadas).
      final real = _byKey.keys.toSet();
      final ok =
          real.length == canonicalKeys.length &&
          real.containsAll(canonicalKeys) &&
          canonicalKeys.containsAll(real);

      if (!ok) {
        // ignore: avoid_print
        print(
          '[ATENA][BloqueExtracurricular] canonicalKeys desalineado. '
          'real=$real canonical=$canonicalKeys',
        );
      }
      return true;
    }());
  }

  /// Validación estricta (sin heurísticas).
  static bool isValidKey(String v) {
    _debugAssertCoherencia();
    return canonicalKeys.contains(_norm(v));
  }

  /// Resolver por key (estricto).
  static BloqueExtracurricular? fromKey(String v) {
    _debugAssertCoherencia();
    final s = _norm(v);
    if (s.isEmpty) return null;
    return _byKey[s];
  }

  /// Parser canónico (sin legacy / sin heurísticas).
  /// Acepta SOLO:
  /// - key exacta (case-insensitive)
  /// - name exacto (case-insensitive)
  /// - label exacto (case-insensitive)
  /// Si no matchea => null.
  static BloqueExtracurricular? tryParse(String v) {
    _debugAssertCoherencia();
    final s = _norm(v);
    if (s.isEmpty) return null;

    final byKey = _byKey[s];
    if (byKey != null) return byKey;

    final byName = _byName[s];
    if (byName != null) return byName;

    final byLabel = _byLabel[s];
    if (byLabel != null) return byLabel;

    return null;
  }

  static BloqueExtracurricular? tryParseAny(dynamic v) {
    if (v == null) return null;
    return tryParse(v.toString());
  }

  // =====================================================
  // ✅ COMPAT CANÓNICA (sin heurísticas)
  // =====================================================

  /// Wrapper estricto usado por pantallas:
  /// - Misma lógica que tryParse (key/name/label exactos, case-insensitive).
  static BloqueExtracurricular? fromAny(dynamic v) => tryParseAny(v);

  /// Variante “no-null” para callers UI que prefieren fallback explícito.
  static BloqueExtracurricular fromAnyOrOtros(dynamic v) =>
      fromAny(v) ?? BloqueExtracurricular.otros;
}
