// lib/models/extracurriculares/extracurricular_modulo.dart
//
// ATENA – EXTRACURRICULARES – MÓDULOS (FACHADA CANÓNICA)
// ------------------------------------------------------
// Objetivo real (estado actual del proyecto):
// - Mantener una “API de módulos” para la parte de INSTITUCIONES (HUB / filtros),
//   pero SIN duplicar reglas de negocio ni “legacy”.
// - La fuente de verdad funcional para UI/Alumno es: BloqueExtracurricular
//   (label completo + descripcionCorta + ejemplos).
//
// Decisión canónica (enero 2026):
// - ExtracurricularModulo se mantiene como enum “fachada” para no romper imports
//   en pantallas ya creadas del lado Instituciones.
// - NO hay mapeos legacy. Solo existe 1:1 con BloqueExtracurricular.
// - Keys backend-ready (snake_case) y estables.
// - Normalización PERMITIDA en esta fachada: trim + lower (nada más).
//
// Importante:
// - La validación estricta se delega a BloqueExtracurricularX.isValidKey(...).
// - No “arreglamos” keys con heurísticas, para mantener fail-fast del flujo canónico.

import 'bloque_extracurricular.dart';

enum ExtracurricularModulo {
  deporteYMovimiento,
  arteYExpresion,
  idiomasYComunicacion,
  cienciaTecnologiaYRobotica,
  apoyoAcademico,
  desarrolloPersonalYBienestar,
  otros,
}

extension ExtracurricularModuloX on ExtracurricularModulo {
  /// ✅ Conversión 1:1 a la fuente de verdad de Alumno/UI.
  BloqueExtracurricular get bloque {
    switch (this) {
      case ExtracurricularModulo.deporteYMovimiento:
        return BloqueExtracurricular.deporteYMovimiento;
      case ExtracurricularModulo.arteYExpresion:
        return BloqueExtracurricular.arteYExpresion;
      case ExtracurricularModulo.idiomasYComunicacion:
        return BloqueExtracurricular.idiomasYComunicacion;
      case ExtracurricularModulo.cienciaTecnologiaYRobotica:
        return BloqueExtracurricular.cienciaTecnologiaYRobotica;
      case ExtracurricularModulo.apoyoAcademico:
        return BloqueExtracurricular.apoyoAcademico;
      case ExtracurricularModulo.desarrolloPersonalYBienestar:
        return BloqueExtracurricular.desarrolloPersonalYBienestar;
      case ExtracurricularModulo.otros:
        return BloqueExtracurricular.otros;
    }
  }

  /// ✅ Key canónica (backend-ready). Fuente: BloqueExtracurricular.key
  String get key => bloque.key;

  /// Label “lindo” (reutiliza la fuente de verdad del lado Alumno).
  String get label => bloque.label;

  /// Descripción corta para UI.
  String get descripcionCorta => bloque.descripcionCorta;

  /// Ejemplos/leyenda (orientativo).
  List<String> get ejemplos => bloque.ejemplos;
}

class ExtracurricularModulos {
  const ExtracurricularModulos._();

  static String _normKey(String v) => v.trim().toLowerCase();

  /// Orden estable para UI (HUB / menú / filtros).
  static List<ExtracurricularModulo> allOrdered() =>
      const <ExtracurricularModulo>[
        ExtracurricularModulo.deporteYMovimiento,
        ExtracurricularModulo.arteYExpresion,
        ExtracurricularModulo.idiomasYComunicacion,
        ExtracurricularModulo.cienciaTecnologiaYRobotica,
        ExtracurricularModulo.apoyoAcademico,
        ExtracurricularModulo.desarrolloPersonalYBienestar,
        ExtracurricularModulo.otros,
      ];

  /// Keys válidas en orden (derivadas de la fuente de verdad).
  static List<String> allKeysOrdered() =>
      allOrdered().map((e) => e.key).toList(growable: false);

  /// Devuelve el módulo por key CANÓNICA (tolerante solo a trim/lower).
  /// Si no matchea una key canónica, devuelve null (fail-fast).
  static ExtracurricularModulo? fromKey(String keyOrAny) {
    final k = _normKey(keyOrAny);
    if (k.isEmpty) return null;

    // ✅ Estricto: solo keys canónicas del set fuente de verdad.
    if (!BloqueExtracurricularX.isValidKey(k)) return null;

    // Resolver con fuente de verdad
    final b = BloqueExtracurricularX.fromKey(k);
    if (b == null) return null;

    return fromBloque(b);
  }

  /// True si la key corresponde a un módulo válido (canónico).
  static bool isValidKey(String keyOrAny) => fromKey(keyOrAny) != null;

  /// Label por key (null si no existe).
  static String? labelForKey(String keyOrAny) => fromKey(keyOrAny)?.label;

  /// ✅ Conversión 1:1 desde BloqueExtracurricular (fuente de verdad).
  static ExtracurricularModulo fromBloque(BloqueExtracurricular b) {
    switch (b) {
      case BloqueExtracurricular.deporteYMovimiento:
        return ExtracurricularModulo.deporteYMovimiento;
      case BloqueExtracurricular.arteYExpresion:
        return ExtracurricularModulo.arteYExpresion;
      case BloqueExtracurricular.idiomasYComunicacion:
        return ExtracurricularModulo.idiomasYComunicacion;
      case BloqueExtracurricular.cienciaTecnologiaYRobotica:
        return ExtracurricularModulo.cienciaTecnologiaYRobotica;
      case BloqueExtracurricular.apoyoAcademico:
        return ExtracurricularModulo.apoyoAcademico;
      case BloqueExtracurricular.desarrolloPersonalYBienestar:
        return ExtracurricularModulo.desarrolloPersonalYBienestar;
      case BloqueExtracurricular.otros:
        return ExtracurricularModulo.otros;
    }
  }

  /// ✅ Conversión a BloqueExtracurricular (fuente de verdad).
  static BloqueExtracurricular toBloque(ExtracurricularModulo m) => m.bloque;
}
