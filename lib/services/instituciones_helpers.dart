// ─────────────────────────────────────────────
// HELPERS GLOBALES – INSTITUCIONES (ATENA)
// Fuente de verdad: Institucion.gruposCurriculares (CANÓNICO)
// Legacy: key dedicada de grupos curriculares se usa solo para migración.
// Archivo: lib/services/instituciones_helpers.dart
//
// ✅ EXTENSIÓN (CANÓNICO – EXTRACURRICULARES):
// - Dominio propio: ActividadExtracurricular.
// - En PROTOTIPO, mantenemos COMPAT con key directa en prefs:
//     extra_acts_inst_{institucionId}
//   porque pantallas/algunos services ya la leen así.
// - En paralelo, también sincronizamos el catálogo dentro de la Institución
//   (institucion.actividadesExtracurriculares) para transición a backend real.
//
// ✅ EXTENSIÓN (CANÓNICO – CROQUIS AULA 10x10):
// - Fuente de verdad: Institucion.croquisAula (serializable dentro de la Institución).
// - No se usa key paralela: persiste por upsertInstitucion (toMap/fromMap).
// - Helpers públicos para cargar/guardar/editar de forma segura.
//
// ✅ EXTENSIÓN (enero 2026) – SEARCH INDEX + PAGINACIÓN (backend-ready):
// - NO expone datos sensibles.
// - Índice liviano para búsqueda y filtros.
// - Devuelve páginas con cursor (offset hoy; cursor backend mañana).
//
// ✅ EXTENSIÓN (feb 2026) – GEO FILTER (backend-ready):
// - SearchIndex liviano incluye lat/lng (si existen en Institución.toMap()).
// - Query soporta userLat/userLng + maxDistanceKm + orderByDistance.
// - Si no hay coords -> fallback automático a orden alfabético.
// - NO obliga a tener Google Maps ahora: solo prepara el dominio.
//
// ⛔ No agrega flujos paralelos nuevos; solo consolida funciones necesarias.
// ⛔ CANÓNICO: institucionId == perfilId (fuente de verdad). Este archivo opera
//    SIEMPRE en términos de institucionId (que debe ser el perfilId).
//
// ✅ FIX CRÍTICO (feb 2026):
// - Evita “write-on-read” durante cargas (hidratar* ya NO hace upsert por defecto).
// - ✅ Anti-“spinner infinito” (web/prefs):
//   TODAS las lecturas/escrituras contra StorageService van con timeouts cortos.
//   Si prefs/localStorage se cuelga, devolvemos defaults seguros y log diagnóstico.
//
// ✅ FIX EXTRA (feb 2026):
// - “cargarInstitucionPorId” y “cargarInstitucionCachePorId” quedan blindadas:
//   no deben bloquearse aunque falle/hanguee StorageService.
//   Internamente se envuelven en timeouts y defaults seguros.
//
// ✅ FIX DEFINITIVO (feb 2026 · CIERRE BUG “NO SE PUDO CARGAR INSTITUCIÓN”):
// - ✅ DATA ID (DOMINIO): trim-only (NO remover whitespace interno).
// - ✅ KEY ID (STORAGE): trim + eliminar whitespace interno.
// - Lecturas son backward-compatible: prueban key canónica y key legacy (trim-only).
// - Escrituras críticas escriben ambas keys si difieren (acelera transición).
//
// ✅ FIX DEFINITIVO (feb 2026 · CIERRE BUG “NO SE PUDO CARGAR INSTITUCIÓN” #2):
// - cargarInstitucionPorId ahora intenta también resolver desde InstitucionService (SharedPreferences)
//   antes de caer a “instituciones_registradas”. Esto cubre casos donde el dominio se guardó
//   por InstitucionPlanPage/InstitucionService pero aún no está en la lista registrada.
//
// ✅ CIERRE CANÓNICO EXTRACURRICULARES (feb 2026):
// - Fuente de verdad ÚNICA: Institucion.actividadesExtracurriculares.
// - Prefs extra_acts_inst_* queda SOLO como compat transitoria:
//    * Lectura: SOLO fallback cuando la Institución no tiene catálogo.
//    * Migración: si legacy existe y la Institución está vacía -> inyecta y persiste 1 vez.
//    * Limpieza: si catálogo final queda vacío -> limpiar prefs legacy automáticamente.
// - No se permite que prefs gobierne el flujo.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;

import 'storage_service.dart';
import 'institucion_service.dart';
import '../models/instituciones/instituciones_integrado.dart';
import '../models/instituciones/grupo_curricular.dart';

// ✅ dominio extracurriculares
import '../models/extracurriculares/actividad_extracurricular.dart';
import '../models/extracurriculares/bloque_extracurricular.dart';

/// ===============================
/// NORMALIZACIÓN / CLAVES
/// ===============================

String _norm(String v) => v.trim();
String _normLower(String v) => v.trim().toLowerCase();

/// ✅ DATA (DOMINIO): trim-only.
/// Importante: NO remover whitespace interno para DATA (evita “mágica” corrección silenciosa).
String _normDataId(String v) => v.trim();

/// ✅ KEY (STORAGE): trim + remover whitespace interno.
/// Esto alinea con CuentaService._normIdKey y evita mismatches en WEB/localStorage.
String _normKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

/// ⚠️ LEGACY KEY: trim-only (histórico).
String _normKeyLegacy(String v) => v.trim();

/// Valida un institucionId de DOMINIO (trim-only).
/// Si el ID no es válido, devolvemos '' (y el caller corta).
String _normInstitucionId(String institucionId) {
  final id = _normDataId(institucionId);
  return id.isEmpty ? '' : id;
}

/// Variantes de KEY para backward-compat (STORAGE).
/// Orden: primero CANÓNICO, luego LEGACY.
/// ⚠️ Debe recibir RAW ID (no pre-normalizado) para no perder la variante legacy.
List<String> _keyVariantsFromRaw(String institucionIdRaw) {
  final a = _normKey(institucionIdRaw);
  final b = _normKeyLegacy(institucionIdRaw);

  final out = <String>[];
  if (a.isNotEmpty) out.add(a);
  if (b.isNotEmpty && b != a) out.add(b);
  return out;
}

/// Helper cuando ya tenés un DATA ID (trim-only) y necesitás keys:
/// - canónica: remove whitespace interno
/// - legacy: trim-only
List<String> _keyVariantsFromDataId(String institucionDataId) =>
    _keyVariantsFromRaw(institucionDataId);

/// ===============================
/// TIMEOUTS (anti-cuelgue prefs/web)
/// ===============================

const Duration _kIOTimeout = Duration(seconds: 2);
const Duration _kIOTimeoutHeavy = Duration(seconds: 4);

Future<T> _withTimeout<T>(
  Future<T> f, {
  Duration timeout = _kIOTimeout,
  required T fallback,
  String? tag,
}) async {
  try {
    return await f.timeout(timeout);
  } on TimeoutException catch (_) {
    debugPrint('[ATENA][IH][TIMEOUT] ${tag ?? 'io'}');
    return fallback;
  } catch (e, st) {
    debugPrint('[ATENA][IH][ERROR] ${tag ?? 'io'} $e\n$st');
    return fallback;
  }
}

Future<void> _withTimeoutVoid(
  Future<void> f, {
  Duration timeout = _kIOTimeout,
  String? tag,
}) async {
  try {
    await f.timeout(timeout);
  } on TimeoutException catch (_) {
    debugPrint('[ATENA][IH][TIMEOUT] ${tag ?? 'io'}');
  } catch (e, st) {
    debugPrint('[ATENA][IH][ERROR] ${tag ?? 'io'} $e\n$st');
  }
}

/// ===============================
/// GEO HELPERS (backend-ready)
/// ===============================

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', '.'));
}

/// Best-effort lectura de lat/lng desde toMap() sin depender del modelo tipado.
double? _readLatFromMap(Map<String, dynamic> m) => _toDoubleOrNull(
  m['lat'] ?? m['latitude'] ?? m['ubicacionLat'] ?? m['geoLat'],
);

double? _readLngFromMap(Map<String, dynamic> m) => _toDoubleOrNull(
  m['lng'] ?? m['lon'] ?? m['longitude'] ?? m['ubicacionLng'] ?? m['geoLng'],
);

double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

double _haversineKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const r = 6371.0; // Earth radius km
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);

  final a =
      (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          (math.sin(dLng / 2) * math.sin(dLng / 2));

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

/// ===============================
/// KEYS CONSISTENTES
/// ===============================

const String kInstitucionesRegistradas = 'instituciones_registradas';

String kNotificacionesInstitucion(String institucionIdRaw) =>
    'notificaciones_inst_${_normKey(institucionIdRaw)}';

String kNotificacionesInstitucionLegacy(String institucionIdRaw) =>
    'notificaciones_inst_${_normKeyLegacy(institucionIdRaw)}';

/// Sistema viejo (grupos institucionales extracurriculares)
String kGruposInstitucion(String institucionIdRaw) =>
    'grupos_${_normKey(institucionIdRaw)}';

String kGruposInstitucionLegacy(String institucionIdRaw) =>
    'grupos_${_normKeyLegacy(institucionIdRaw)}';

/// ⚠️ LEGACY: antes guardábamos grupos curriculares en key dedicada.
/// Ahora la fuente de verdad es Institucion.gruposCurriculares.
String kGruposCurricularesInstitucion(String institucionIdRaw) =>
    'grupos_curriculares_${_normKey(institucionIdRaw)}';

String kGruposCurricularesInstitucionLegacy(String institucionIdRaw) =>
    'grupos_curriculares_${_normKeyLegacy(institucionIdRaw)}';

String kPerfilInstitucionPorId(String institucionIdRaw) =>
    'institucion_perfil_${_normKey(institucionIdRaw)}';

String kPerfilInstitucionPorIdLegacy(String institucionIdRaw) =>
    'institucion_perfil_${_normKeyLegacy(institucionIdRaw)}';

/// ✅ PROTOTIPO: catálogo extracurriculares por institución (compat global)
String kActividadesExtracurricularesPrefs(String institucionIdRaw) =>
    'extra_acts_inst_${_normKey(institucionIdRaw)}';

String kActividadesExtracurricularesPrefsLegacy(String institucionIdRaw) =>
    'extra_acts_inst_${_normKeyLegacy(institucionIdRaw)}';

/// ✅ PROTOTIPO: índice de búsqueda liviano (opcional cache futuro)
const String kInstitucionesSearchIndex = 'instituciones_search_index_v1';

/// ===============================
/// INSTITUCIONES REGISTRADAS (LISTA)
/// ===============================

Future<List<Institucion>> cargarInstitucionesRegistradas() async {
  final lista = await _withTimeout<List<String>>(
    StorageService.instance.getStringList(kInstitucionesRegistradas),
    timeout: _kIOTimeoutHeavy,
    fallback: <String>[],
    tag: 'getStringList instituciones_registradas',
  );

  final out = <Institucion>[];
  for (final s in lista) {
    if (s.trim().isEmpty) continue;
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        out.add(Institucion.fromMap(Map<String, dynamic>.from(decoded)));
      } else {
        out.add(Institucion.fromJson(s));
      }
    } catch (_) {
      // ignora corruptas
    }
  }
  return out;
}

Future<void> guardarInstitucionesRegistradas(
  List<Institucion> instituciones,
) async {
  final packed = instituciones.map((i) => jsonEncode(i.toMap())).toList();

  await _withTimeoutVoid(
    StorageService.instance.setStringList(kInstitucionesRegistradas, packed),
    timeout: _kIOTimeoutHeavy,
    tag: 'setStringList instituciones_registradas',
  );
}

Future<void> borrarInstitucionRegistradaPorId(String institucionId) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final instituciones = await cargarInstitucionesRegistradas();
  instituciones.removeWhere(
    (i) =>
        _normKey(i.id) == _normKey(dataId) ||
        _normKeyLegacy(i.id) == _normKeyLegacy(dataId),
  );
  await guardarInstitucionesRegistradas(instituciones);

  // Limpiar cache (best-effort) -> borrar ambas keys (canónica + legacy)
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(kPerfilInstitucionPorId(kid), ''),
      tag: 'clear cache institucion_perfil',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(kPerfilInstitucionPorIdLegacy(kid), ''),
      tag: 'clear cache institucion_perfil legacy',
    );
  }

  // Limpiar notificaciones (best-effort) -> ambas keys
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucion(kid),
        <String>[],
      ),
      tag: 'clear notificaciones_inst',
    );
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucionLegacy(kid),
        <String>[],
      ),
      tag: 'clear notificaciones_inst legacy',
    );
  }

  // Limpiar grupos institucionales viejos (best-effort) -> ambas keys
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(kGruposInstitucion(kid), ''),
      tag: 'clear grupos_',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(kGruposInstitucionLegacy(kid), ''),
      tag: 'clear grupos_ legacy',
    );
  }

  // Limpiar catálogo extracurriculares prefs (best-effort) -> ambas keys
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefs(kid),
        '',
      ),
      tag: 'clear extra_acts_inst',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefsLegacy(kid),
        '',
      ),
      tag: 'clear extra_acts_inst legacy',
    );
  }

  // Limpiar legacy key grupos curriculares (best-effort) -> ambas keys
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kGruposCurricularesInstitucion(kid),
        '',
      ),
      tag: 'clear grupos_curriculares_',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kGruposCurricularesInstitucionLegacy(kid),
        '',
      ),
      tag: 'clear grupos_curriculares_ legacy',
    );
  }

  await invalidarInstitucionesSearchIndex();
}

/// ===============================
/// LEGACY: GRUPOS CURRICULARES EN KEY DEDICADA (solo migración)
/// ===============================

Future<List<GrupoCurricular>> _cargarGruposCurricularesLegacyKey(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <GrupoCurricular>[];

  // Probamos ambas keys (canónica/legacy) derivadas del RAW input
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    final raw = await _withTimeout<String?>(
      StorageService.instance.getString(kGruposCurricularesInstitucion(kid)),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString grupos_curriculares_',
    );

    if (raw == null || raw.trim().isEmpty) {
      final rawLegacy = await _withTimeout<String?>(
        StorageService.instance.getString(
          kGruposCurricularesInstitucionLegacy(kid),
        ),
        timeout: _kIOTimeoutHeavy,
        fallback: null,
        tag: 'getString grupos_curriculares_ legacy',
      );
      if (rawLegacy == null || rawLegacy.trim().isEmpty) continue;

      try {
        final decoded = jsonDecode(rawLegacy);
        if (decoded is! List) continue;

        final out = decoded
            .whereType<Map>()
            .map((e) => GrupoCurricular.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        out.sort(
          (a, b) => a.nombreCurso.toLowerCase().compareTo(
            b.nombreCurso.toLowerCase(),
          ),
        );
        return out;
      } catch (_) {
        continue;
      }
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;

      final out = decoded
          .whereType<Map>()
          .map((e) => GrupoCurricular.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      out.sort(
        (a, b) =>
            a.nombreCurso.toLowerCase().compareTo(b.nombreCurso.toLowerCase()),
      );
      return out;
    } catch (_) {
      continue;
    }
  }

  return <GrupoCurricular>[];
}

Future<void> _vaciarLegacyKeyGruposCurriculares(String institucionId) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  // vaciamos ambas variantes (best-effort)
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kGruposCurricularesInstitucion(kid),
        '',
      ),
      tag: 'setString grupos_curriculares_ empty',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kGruposCurricularesInstitucionLegacy(kid),
        '',
      ),
      tag: 'setString grupos_curriculares_ legacy empty',
    );
  }
}

/// ✅ Hidratación “read-only” por defecto.
Future<Institucion> hidratarInstitucionConGruposCurriculares(
  Institucion institucion, {
  bool persist = false,
  bool clearLegacyKey = false,
}) async {
  final dataId = _normInstitucionId(institucion.id);
  if (dataId.isEmpty) return institucion;

  try {
    if (institucion.gruposCurriculares.isNotEmpty) {
      return institucion;
    }
  } catch (_) {}

  // Importante: pasar RAW (institucion.id) para no perder legacy key.
  final legacy = await _cargarGruposCurricularesLegacyKey(institucion.id);
  if (legacy.isEmpty) return institucion;

  try {
    institucion.gruposCurriculares
      ..clear()
      ..addAll(legacy);
  } catch (_) {
    return institucion;
  }

  if (persist) {
    await upsertInstitucion(institucion);
    if (clearLegacyKey) {
      await _vaciarLegacyKeyGruposCurriculares(institucion.id);
    }
  }

  return institucion;
}

/// ===============================
/// ✅ CANÓNICO: GRUPOS CURRICULARES
/// ===============================
/// Fuente de verdad: Institucion.gruposCurriculares.
/// - Hidratación legacy controlada (si está vacío y existe grupos_curriculares_*).
/// - Orden estable.
/// - NO toca keys legacy salvo que se pida explícitamente por otros flujos.
///
/// 🔥 IMPORTANTE:
/// - Esto es lo que deben usar pantallas de alumnos para ver “aulas/cursos”.
Future<List<GrupoCurricular>> cargarGruposCurricularesInstitucion(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <GrupoCurricular>[];

  debugPrint(
    '[ATENA][IH] cargarGruposCurricularesInstitucion start id="$dataId"',
  );

  // Cargar institución canónica (ya viene con cache+domain+lista y timeouts).
  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (grupos curriculares canonico)',
  );

  if (inst == null) {
    debugPrint(
      '[ATENA][IH] cargarGruposCurricularesInstitucion inst=null id="$dataId"',
    );
    return <GrupoCurricular>[];
  }

  // Hidratación read-only (no upsert por defecto)
  final hydrated = await hidratarInstitucionConGruposCurriculares(
    inst,
    persist: false,
    clearLegacyKey: false,
  );

  List<GrupoCurricular> out;
  try {
    out = List<GrupoCurricular>.from(hydrated.gruposCurriculares);
  } catch (_) {
    out = <GrupoCurricular>[];
  }

  // Orden estable best-effort: nombreCurso, horaInicio, horaFin, id
  out.sort((a, b) {
    final an = a.nombreCurso.trim().toLowerCase();
    final bn = b.nombreCurso.trim().toLowerCase();
    final c = an.compareTo(bn);
    if (c != 0) return c;

    final ahi = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
    if (ahi != 0) return ahi;

    final ahf = (a.horaFin ?? '').compareTo(b.horaFin ?? '');
    if (ahf != 0) return ahf;

    return a.id.compareTo(b.id);
  });

  debugPrint(
    '[ATENA][IH] cargarGruposCurricularesInstitucion ok n=${out.length} id="$dataId"',
  );
  return out;
}

/// Compat API: alias explícito para curriculares (por legibilidad en pantallas)
Future<List<GrupoCurricular>> getGruposCurricularesInstitucion(
  String institucionId,
) => cargarGruposCurricularesInstitucion(institucionId);

/// ===============================
/// ✅ CANÓNICO: EXTRACURRICULARES
/// ===============================

Future<void> _limpiarActividadesExtracurricularesPrefs(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefs(kid),
        '',
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'clear extra_acts_inst',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefsLegacy(kid),
        '',
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'clear extra_acts_inst legacy',
    );
  }
}

/// ✅ Carga legacy prefs (compat) – NUNCA gobierna el flujo.
Future<List<ActividadExtracurricular>> _cargarActividadesExtracurricularesPrefs(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <ActividadExtracurricular>[];

  // Backward-compatible: probar ambas keys (RAW → variants)
  String? raw;
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    raw = await _withTimeout<String?>(
      StorageService.instance.getString(
        kActividadesExtracurricularesPrefs(kid),
      ),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString extra_acts_inst',
    );
    if (raw != null && raw.trim().isNotEmpty) break;

    raw = await _withTimeout<String?>(
      StorageService.instance.getString(
        kActividadesExtracurricularesPrefsLegacy(kid),
      ),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString extra_acts_inst legacy',
    );
    if (raw != null && raw.trim().isNotEmpty) break;
  }

  if (raw == null || raw.trim().isEmpty) return <ActividadExtracurricular>[];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <ActividadExtracurricular>[];

    return decoded
        .whereType<Map>()
        .map(
          (m) => ActividadExtracurricular.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
  } catch (_) {
    return <ActividadExtracurricular>[];
  }
}

/// ✅ Guarda prefs (compat). Canónica + legacy.
Future<void> _guardarActividadesExtracurricularesPrefs({
  required String institucionId,
  required List<ActividadExtracurricular> actividades,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final list = actividades.map((a) => a.toMap()).toList();
  final payload = jsonEncode(list);

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefs(kid),
        payload,
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString extra_acts_inst',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kActividadesExtracurricularesPrefsLegacy(kid),
        payload,
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString extra_acts_inst legacy',
    );
  }
}

/// ✅ Hidratación CANÓNICA con fallback legacy CONTROLADO.
Future<Institucion> hidratarInstitucionConExtracurriculares(
  Institucion institucion, {
  bool migrateIfLegacy = true,
}) async {
  final dataId = _normInstitucionId(institucion.id);
  if (dataId.isEmpty) return institucion;

  // A) CANÓNICO primero (si ya existe catálogo, cortar).
  try {
    if (institucion.actividadesExtracurriculares.isNotEmpty) {
      return institucion;
    }
  } catch (_) {}

  // B) Fallback legacy (solo si la institución está vacía).
  final prefsList = await _cargarActividadesExtracurricularesPrefs(
    institucion.id,
  );

  if (prefsList.isEmpty) {
    // C) Limpieza legacy automática (si el catálogo final queda vacío).
    await _limpiarActividadesExtracurricularesPrefs(institucion.id);
    return institucion;
  }

  // D) Migración silenciosa controlada (one-shot).
  try {
    institucion.actividadesExtracurriculares
      ..clear()
      ..addAll(prefsList);
  } catch (_) {
    return institucion;
  }

  if (migrateIfLegacy) {
    await upsertInstitucion(institucion);
  }

  return institucion;
}

/// ✅ Fuente de verdad ÚNICA: Institución.
Future<List<ActividadExtracurricular>> _cargarCatalogoExtracurricularCanonico(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <ActividadExtracurricular>[];

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (catalogo extra canonico)',
  );
  if (inst == null) return <ActividadExtracurricular>[];

  try {
    return List<ActividadExtracurricular>.from(
      inst.actividadesExtracurriculares,
    );
  } catch (_) {
    return <ActividadExtracurricular>[];
  }
}

Future<List<ActividadExtracurricular>>
cargarActividadesExtracurricularesPorInstitucion(String institucionId) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <ActividadExtracurricular>[];

  final list = await _cargarCatalogoExtracurricularCanonico(institucionId);

  final out = list.where((a) => a.activa == true).toList();
  out.sort(
    (a, b) =>
        a.nombre.trim().toLowerCase().compareTo(b.nombre.trim().toLowerCase()),
  );
  return out;
}

Future<void> guardarActividadesExtracurricularesEnInstitucion({
  required String institucionId,
  required List<ActividadExtracurricular> actividades,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (guardar extra)',
  );
  if (inst == null) return;

  try {
    inst.actividadesExtracurriculares
      ..clear()
      ..addAll(actividades);
  } catch (_) {
    return;
  }

  // Fuente de verdad: Institución.
  await upsertInstitucion(inst);

  // Limpieza automática si el catálogo queda vacío.
  if (actividades.isEmpty) {
    await _limpiarActividadesExtracurricularesPrefs(institucionId);
  }
}

Future<void> upsertActividadExtracurricular({
  required String institucionId,
  required ActividadExtracurricular actividad,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (upsert actividad extra)',
  );
  if (inst == null) return;

  final list = <ActividadExtracurricular>[];
  try {
    list.addAll(inst.actividadesExtracurriculares);
  } catch (_) {}

  final idx = list.indexWhere((a) => _normKey(a.id) == _normKey(actividad.id));
  if (idx >= 0) {
    list[idx] = actividad.copyWith(updatedAt: DateTime.now());
  } else {
    list.add(
      actividad.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  await guardarActividadesExtracurricularesEnInstitucion(
    institucionId: institucionId,
    actividades: list,
  );
}

Future<void> borrarActividadExtracurricular({
  required String institucionId,
  required String actividadId,
}) async {
  final dataId = _normInstitucionId(institucionId);
  final aid = _normKey(actividadId);
  if (dataId.isEmpty || aid.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (borrar actividad extra)',
  );
  if (inst == null) return;

  final list = <ActividadExtracurricular>[];
  try {
    list.addAll(inst.actividadesExtracurriculares);
  } catch (_) {}

  list.removeWhere((a) => _normKey(a.id) == aid);

  await guardarActividadesExtracurricularesEnInstitucion(
    institucionId: institucionId,
    actividades: list,
  );
}

Future<List<ActividadExtracurricular>>
filtrarActividadesExtracurricularesPorBloque({
  required String institucionId,
  required BloqueExtracurricular bloque,
}) async {
  final list = await cargarActividadesExtracurricularesPorInstitucion(
    institucionId,
  );
  return list.where((a) => a.bloque == bloque && a.activa == true).toList();
}

String newActividadExtracurricularId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'AE_$now';
}

/// ===============================
/// MIGRACIÓN EXPLÍCITA (persistente)
/// ===============================

Future<Institucion?> migrarPersistirLegacyEnInstitucion(
  String institucionId, {
  bool clearLegacyKeyCurricular = true,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return null;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (migrar)',
  );
  if (inst == null) return null;

  final a = await hidratarInstitucionConGruposCurriculares(
    inst,
    persist: true,
    clearLegacyKey: clearLegacyKeyCurricular,
  );

  // Extracurriculares: migración controlada (si está vacío y hay legacy).
  final b = await hidratarInstitucionConExtracurriculares(
    a,
    migrateIfLegacy: true,
  );
  return b;
}

/// ===============================
/// Busca por nombre
/// ===============================

Future<Institucion?> cargarInstitucionPorNombre(String nombre) async {
  final n = _norm(nombre);
  if (n.isEmpty) return null;

  final instituciones = await cargarInstitucionesRegistradas();
  for (final inst in instituciones) {
    if (_norm(inst.nombre) == n) {
      final a = await hidratarInstitucionConGruposCurriculares(inst);
      return hidratarInstitucionConExtracurriculares(a, migrateIfLegacy: true);
    }
  }
  return null;
}

Future<Institucion?> cargarInstitucionPorNombreFlexible(String nombre) async {
  final n = _normLower(nombre);
  if (n.isEmpty) return null;

  final instituciones = await cargarInstitucionesRegistradas();
  for (final inst in instituciones) {
    if (_normLower(inst.nombre) == n) {
      final a = await hidratarInstitucionConGruposCurriculares(inst);
      return hidratarInstitucionConExtracurriculares(a, migrateIfLegacy: true);
    }
  }
  return null;
}

/// ===============================
/// CARGA POR ID + CACHE (CANÓNICO)
/// ===============================

Future<Institucion?> cargarInstitucionCachePorId(String institucionId) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return null;

  String? raw;

  // Backward-compatible: probar cache con key canónica y legacy (derivadas del RAW input)
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    raw = await _withTimeout<String?>(
      StorageService.instance.getString(kPerfilInstitucionPorId(kid)),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString institucion_perfil_',
    );
    if (raw != null && raw.trim().isNotEmpty) break;

    raw = await _withTimeout<String?>(
      StorageService.instance.getString(kPerfilInstitucionPorIdLegacy(kid)),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString institucion_perfil_ legacy',
    );
    if (raw != null && raw.trim().isNotEmpty) break;
  }

  if (raw == null || raw.trim().isEmpty) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final inst = Institucion.fromMap(Map<String, dynamic>.from(decoded));
      final a = await hidratarInstitucionConGruposCurriculares(inst);
      return hidratarInstitucionConExtracurriculares(a, migrateIfLegacy: true);
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> guardarInstitucionCachePorId(
  String institucionId,
  Institucion institucion,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final payload = jsonEncode(institucion.toMap());

  // Escribimos en ambas keys (canónica y legacy) derivadas del RAW input.
  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(kPerfilInstitucionPorId(kid), payload),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString institucion_perfil_',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(
        kPerfilInstitucionPorIdLegacy(kid),
        payload,
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString institucion_perfil_ legacy',
    );
  }
}

Future<Institucion?> cargarInstitucionPorId(String institucionId) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return null;

  debugPrint('[ATENA][IH] cargarInstitucionPorId start id="$dataId"');

  // ✅ Cache primero
  final cached = await _withTimeout<Institucion?>(
    cargarInstitucionCachePorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionCachePorId',
  );
  if (cached != null) {
    debugPrint('[ATENA][IH] cargarInstitucionPorId hit-cache id="$dataId"');
    return cached;
  }

  // ✅ 2) Intentar DOMINIO por InstitucionService (SharedPreferences)
  final byDomain = await _withTimeout<Institucion?>(
    InstitucionService.getInstitucionById(dataId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'InstitucionService.getInstitucionById',
  );
  if (byDomain != null) {
    final a = await hidratarInstitucionConGruposCurriculares(byDomain);
    final b = await hidratarInstitucionConExtracurriculares(
      a,
      migrateIfLegacy: true,
    );
    await guardarInstitucionCachePorId(institucionId, b);
    debugPrint('[ATENA][IH] cargarInstitucionPorId ok(domain) id="$dataId"');
    return b;
  }

  // ✅ 3) Fallback: Lista registrada
  final instituciones = await cargarInstitucionesRegistradas();
  for (final inst in instituciones) {
    // Comparación por KEY (canónica + legacy) pero sin mutar DATA.
    if (_normKey(inst.id) == _normKey(dataId) ||
        _normKeyLegacy(inst.id) == _normKeyLegacy(dataId)) {
      final a = await hidratarInstitucionConGruposCurriculares(inst);
      final b = await hidratarInstitucionConExtracurriculares(
        a,
        migrateIfLegacy: true,
      );
      await guardarInstitucionCachePorId(institucionId, b);
      debugPrint('[ATENA][IH] cargarInstitucionPorId ok(list) id="$dataId"');
      return b;
    }
  }

  debugPrint('[ATENA][IH] cargarInstitucionPorId not-found id="$dataId"');
  return null;
}

/// Compat API: alias canónico
Future<Institucion?> getInstitucionById(String institucionId) async =>
    cargarInstitucionPorId(institucionId);

/// Compat API: alias canónico
Future<Institucion?> getInstitucionPorId(String institucionId) async =>
    cargarInstitucionPorId(institucionId);

Future<void> upsertInstitucion(Institucion institucion) async {
  final dataId = _normInstitucionId(institucion.id);
  if (dataId.isEmpty) return;

  final instituciones = await cargarInstitucionesRegistradas();
  bool reemplazada = false;

  final nueva = <Institucion>[];
  for (final inst in instituciones) {
    if (_normKey(inst.id) == _normKey(dataId) ||
        _normKeyLegacy(inst.id) == _normKeyLegacy(dataId)) {
      nueva.add(institucion);
      reemplazada = true;
    } else {
      nueva.add(inst);
    }
  }

  if (!reemplazada) {
    nueva.add(institucion);
  }

  await guardarInstitucionesRegistradas(nueva);

  // ✅ cache dual-key (usar RAW institucion.id para no perder legacy)
  await guardarInstitucionCachePorId(institucion.id, institucion);

  // ✅ Mantener sincronizado el DOMINIO en InstitucionService (best-effort)
  await _withTimeoutVoid(
    InstitucionService.upsertInstitucion(institucion),
    timeout: _kIOTimeoutHeavy,
    tag: 'InstitucionService.upsertInstitucion',
  );

  // ✅ COMPAT EXTRACURRICULARES (prefs) – SIEMPRE derivado desde la Institución.
  try {
    final acts = List<ActividadExtracurricular>.from(
      institucion.actividadesExtracurriculares,
    );
    if (acts.isEmpty) {
      await _limpiarActividadesExtracurricularesPrefs(institucion.id);
    } else {
      await _guardarActividadesExtracurricularesPrefs(
        institucionId: institucion.id,
        actividades: acts,
      );
    }
  } catch (_) {}

  await invalidarInstitucionesSearchIndex();
}

Future<void> upsertInstitucionPorNombre(Institucion institucion) async {
  final nombre = _norm(institucion.nombre);
  if (nombre.isEmpty) return;

  final dataId = _normInstitucionId(institucion.id);
  if (dataId.isNotEmpty) {
    await upsertInstitucion(institucion);
    return;
  }

  final instituciones = await cargarInstitucionesRegistradas();
  bool reemplazada = false;

  final nueva = <Institucion>[];
  for (final inst in instituciones) {
    if (_normLower(inst.nombre) == _normLower(nombre)) {
      nueva.add(institucion);
      reemplazada = true;
    } else {
      nueva.add(inst);
    }
  }

  if (!reemplazada) {
    nueva.add(institucion);
  }

  await guardarInstitucionesRegistradas(nueva);
  await invalidarInstitucionesSearchIndex();
}

Future<List<GrupoInstitucional>> cargarGruposInstitucion(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <GrupoInstitucional>[];

  debugPrint('[ATENA][IH] cargarGruposInstitucion start id="$dataId"');

  String? raw;

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    raw = await _withTimeout<String?>(
      StorageService.instance.getString(kGruposInstitucion(kid)),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString grupos_',
    );
    if (raw != null && raw.trim().isNotEmpty) break;

    raw = await _withTimeout<String?>(
      StorageService.instance.getString(kGruposInstitucionLegacy(kid)),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString grupos_ legacy',
    );
    if (raw != null && raw.trim().isNotEmpty) break;
  }

  if (raw == null || raw.trim().isEmpty) {
    debugPrint('[ATENA][IH] cargarGruposInstitucion empty id="$dataId"');
    return <GrupoInstitucional>[];
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <GrupoInstitucional>[];

    final out = decoded
        .whereType<Map>()
        .map((e) => GrupoInstitucional.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    out.sort(
      (a, b) =>
          a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
    );

    debugPrint(
      '[ATENA][IH] cargarGruposInstitucion ok n=${out.length} id="$dataId"',
    );
    return out;
  } catch (_) {
    debugPrint('[ATENA][IH] cargarGruposInstitucion decode-error id="$dataId"');
    return <GrupoInstitucional>[];
  }
}

Future<void> guardarGruposInstitucion(
  String institucionId,
  List<GrupoInstitucional> grupos,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final data = grupos.map((g) => g.toMap()).toList();
  final payload = jsonEncode(data);

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setString(kGruposInstitucion(kid), payload),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString grupos_',
    );
    await _withTimeoutVoid(
      StorageService.instance.setString(kGruposInstitucionLegacy(kid), payload),
      timeout: _kIOTimeoutHeavy,
      tag: 'setString grupos_ legacy',
    );
  }
}

Future<void> upsertGrupoInstitucional(
  String institucionId,
  GrupoInstitucional grupo,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final grupos = await cargarGruposInstitucion(institucionId);

  final nombre = _norm(grupo.nombreGrupo);
  final actividad = _norm(grupo.actividadNombre);

  bool reemplazado = false;
  final nueva = <GrupoInstitucional>[];

  for (final g in grupos) {
    final mismoGrupo = _norm(g.nombreGrupo) == nombre;
    final mismaActividad = _norm(g.actividadNombre) == actividad;

    if (mismoGrupo && mismaActividad) {
      nueva.add(grupo);
      reemplazado = true;
    } else {
      nueva.add(g);
    }
  }

  if (!reemplazado) nueva.add(grupo);

  nueva.sort(
    (a, b) =>
        a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
  );
  await guardarGruposInstitucion(institucionId, nueva);
}

Future<void> upsertGrupoInstitucionalPorId(
  String institucionId,
  GrupoInstitucional grupo,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final grupos = await cargarGruposInstitucion(institucionId);

  final idx = grupos.indexWhere((g) => _normKey(g.id) == _normKey(grupo.id));
  if (idx >= 0) {
    grupos[idx] = grupo;
  } else {
    grupos.add(grupo);
  }

  grupos.sort(
    (a, b) =>
        a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
  );
  await guardarGruposInstitucion(institucionId, grupos);
}

String newGrupoInstitucionalId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'GI_$now';
}

Future<List<Map<String, dynamic>>> cargarNotificacionesInstitucion(
  String institucionId,
) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return <Map<String, dynamic>>[];

  List<String> list = const <String>[];

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    final key = kNotificacionesInstitucion(kid);
    list = await _withTimeout<List<String>>(
      StorageService.instance.getStringList(key),
      timeout: _kIOTimeoutHeavy,
      fallback: <String>[],
      tag: 'getStringList notificaciones_inst',
    );
    if (list.isNotEmpty) break;

    final keyLegacy = kNotificacionesInstitucionLegacy(kid);
    list = await _withTimeout<List<String>>(
      StorageService.instance.getStringList(keyLegacy),
      timeout: _kIOTimeoutHeavy,
      fallback: <String>[],
      tag: 'getStringList notificaciones_inst legacy',
    );
    if (list.isNotEmpty) break;
  }

  final out = <Map<String, dynamic>>[];
  for (final s in list) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
    } catch (_) {}
  }

  out.sort((a, b) {
    final fa =
        DateTime.tryParse((a['fechaIso'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final fb =
        DateTime.tryParse((b['fechaIso'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return fb.compareTo(fa);
  });

  return out;
}

Future<void> guardarNotificacionesInstitucionRaw({
  required String institucionId,
  required List<Map<String, dynamic>> notificaciones,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final list = notificaciones.map((m) => jsonEncode(m)).toList();

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucion(kid),
        list,
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setStringList notificaciones_inst',
    );
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucionLegacy(kid),
        list,
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setStringList notificaciones_inst legacy',
    );
  }
}

Future<void> setNotificacionInstitucionLeida({
  required String institucionId,
  required String notificacionId,
  required bool leida,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final current = await cargarNotificacionesInstitucion(institucionId);

  final nueva = <Map<String, dynamic>>[];
  for (final m in current) {
    final map = Map<String, dynamic>.from(m);
    if ((map['id'] ?? '').toString() == notificacionId) {
      map['leida'] = leida;
    }
    nueva.add(map);
  }

  await guardarNotificacionesInstitucionRaw(
    institucionId: institucionId,
    notificaciones: nueva,
  );
}

Future<void> marcarNotificacionInstitucionLeida({
  required String institucionId,
  required String notificacionId,
}) async {
  await setNotificacionInstitucionLeida(
    institucionId: institucionId,
    notificacionId: notificacionId,
    leida: true,
  );
}

Future<void> borrarNotificacionInstitucion({
  required String institucionId,
  required String notificacionId,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final current = await cargarNotificacionesInstitucion(institucionId);

  final nueva = <Map<String, dynamic>>[];
  for (final m in current) {
    final rid = (m['id'] ?? '').toString();
    if (rid == notificacionId) continue;
    nueva.add(Map<String, dynamic>.from(m));
  }

  await guardarNotificacionesInstitucionRaw(
    institucionId: institucionId,
    notificaciones: nueva,
  );
}

Future<void> marcarTodasNotificacionesInstitucionLeidas({
  required String institucionId,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final current = await cargarNotificacionesInstitucion(institucionId);

  final nueva = <Map<String, dynamic>>[];
  for (final m in current) {
    final map = Map<String, dynamic>.from(m);
    map['leida'] = true;
    nueva.add(map);
  }

  await guardarNotificacionesInstitucionRaw(
    institucionId: institucionId,
    notificaciones: nueva,
  );
}

Future<void> borrarTodasNotificacionesInstitucion({
  required String institucionId,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final kids = _keyVariantsFromRaw(institucionId);
  for (final kid in kids) {
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucion(kid),
        <String>[],
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setStringList notificaciones_inst clear',
    );
    await _withTimeoutVoid(
      StorageService.instance.setStringList(
        kNotificacionesInstitucionLegacy(kid),
        <String>[],
      ),
      timeout: _kIOTimeoutHeavy,
      tag: 'setStringList notificaciones_inst legacy clear',
    );
  }
}

Future<void> guardarGruposCurricularesEnInstitucion({
  required String institucionId,
  required List<GrupoCurricular> grupos,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (guardar grupos curriculares)',
  );
  if (inst == null) return;

  await hidratarInstitucionConGruposCurriculares(inst, persist: false);

  try {
    inst.gruposCurriculares
      ..clear()
      ..addAll(grupos);
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
  await _vaciarLegacyKeyGruposCurriculares(institucionId);
}

/// ===============================
/// CROQUIS AULA 10x10 (CANÓNICO)
/// ===============================

Future<CroquisAula10x10?> cargarCroquisAulaDeInstitucion({
  required String institucionId,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return null;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis get)',
  );
  if (inst == null) return null;

  try {
    return inst.croquisAula;
  } catch (_) {
    return null;
  }
}

Future<void> guardarCroquisAulaEnInstitucion({
  required String institucionId,
  required CroquisAula10x10 croquis,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis set)',
  );
  if (inst == null) return;

  try {
    inst.croquisAula = croquis.copyWith(updatedAt: DateTime.now());
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
}

CroquisAula10x10 _croquisEmptySafe({
  String aula = 'Aula',
  String turno = 'Turno',
}) {
  try {
    return CroquisAula10x10.empty(aula: aula, turno: turno);
  } catch (_) {
    return CroquisAula10x10.empty();
  }
}

Future<CroquisAula10x10> asegurarCroquisAulaEnInstitucion({
  required String institucionId,
  String aula = 'Aula',
  String turno = 'Turno',
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return _croquisEmptySafe(aula: aula, turno: turno);

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis ensure)',
  );
  if (inst == null) return _croquisEmptySafe(aula: aula, turno: turno);

  try {
    final actual = inst.croquisAula;
    if (actual != null) return actual;
  } catch (_) {}

  final nuevo = _croquisEmptySafe(aula: aula, turno: turno);

  try {
    inst.croquisAula = nuevo;
  } catch (_) {
    return nuevo;
  }

  await upsertInstitucion(inst);
  return nuevo;
}

Future<void> setNombreEnCroquis({
  required String institucionId,
  required int row,
  required int col,
  required String nombre,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis setNombre)',
  );
  if (inst == null) return;

  CroquisAula10x10 croquis;
  try {
    croquis = inst.croquisAula ?? _croquisEmptySafe();
  } catch (_) {
    croquis = _croquisEmptySafe();
  }

  final rows = croquis.rows;
  final cols = croquis.cols;

  if (row < 0 || col < 0 || row >= rows || col >= cols) return;

  final idx = row * cols + col;
  if (idx < 0 || idx >= croquis.nombres.length) return;

  final nombres = List<String>.from(croquis.nombres);
  nombres[idx] = nombre.trim();

  final actualizado = croquis.copyWith(
    nombres: nombres,
    updatedAt: DateTime.now(),
  );

  try {
    inst.croquisAula = actualizado;
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
}

Future<void> setCroquisNombresGrid({
  required String institucionId,
  required List<String> nombres,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis setGrid)',
  );
  if (inst == null) return;

  CroquisAula10x10 croquis;
  try {
    croquis = inst.croquisAula ?? _croquisEmptySafe();
  } catch (_) {
    croquis = _croquisEmptySafe();
  }

  final expected = croquis.rows * croquis.cols;
  final normalized = List<String>.filled(expected, '');
  for (int i = 0; i < expected && i < nombres.length; i++) {
    normalized[i] = nombres[i].toString().trim();
  }

  final actualizado = croquis.copyWith(
    nombres: normalized,
    updatedAt: DateTime.now(),
  );

  try {
    inst.croquisAula = actualizado;
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
}

Future<void> setCroquisMeta({
  required String institucionId,
  String? aula,
  String? turno,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis meta)',
  );
  if (inst == null) return;

  CroquisAula10x10 croquis;
  try {
    croquis = inst.croquisAula ?? _croquisEmptySafe();
  } catch (_) {
    croquis = _croquisEmptySafe();
  }

  final actualizado = croquis.copyWith(
    aula: (aula ?? croquis.aula).trim(),
    turno: (turno ?? croquis.turno).trim(),
    updatedAt: DateTime.now(),
  );

  try {
    inst.croquisAula = actualizado;
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
}

Future<void> setCroquisGrupos({
  required String institucionId,
  required List<CroquisGrupo> grupos,
}) async {
  final dataId = _normInstitucionId(institucionId);
  if (dataId.isEmpty) return;

  final inst = await _withTimeout<Institucion?>(
    cargarInstitucionPorId(institucionId),
    timeout: _kIOTimeoutHeavy,
    fallback: null,
    tag: 'cargarInstitucionPorId (croquis grupos)',
  );
  if (inst == null) return;

  CroquisAula10x10 croquis;
  try {
    croquis = inst.croquisAula ?? _croquisEmptySafe();
  } catch (_) {
    croquis = _croquisEmptySafe();
  }

  final actualizado = croquis.copyWith(
    grupos: List<CroquisGrupo>.from(grupos),
    updatedAt: DateTime.now(),
  );

  try {
    inst.croquisAula = actualizado;
  } catch (_) {
    return;
  }

  await upsertInstitucion(inst);
}

/// ===============================
/// ✅ SEARCH INDEX + PAGINACIÓN
/// ===============================

class InstitucionSearchItem {
  final String institucionId;
  final String nombre;

  final String pais;
  final String provincia;
  final String ciudad;

  final ModalidadCursado modalidad;

  final bool curricular;
  final bool extracurricular;

  final Set<BloqueExtracurricular> bloquesExtra;

  /// ✅ GEO (opcional / backend-ready)
  final double? lat;
  final double? lng;

  const InstitucionSearchItem({
    required this.institucionId,
    required this.nombre,
    required this.pais,
    required this.provincia,
    required this.ciudad,
    required this.modalidad,
    required this.curricular,
    required this.extracurricular,
    required this.bloquesExtra,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'nombre': nombre,
    'pais': pais,
    'provincia': provincia,
    'ciudad': ciudad,
    'modalidad': modalidad.key,
    'curricular': curricular,
    'extracurricular': extracurricular,
    'bloquesExtra': bloquesExtra.map((b) => b.key).toList(),
    'lat': lat,
    'lng': lng,
  };

  factory InstitucionSearchItem.fromMap(Map<String, dynamic> m) {
    final raw = (m['bloquesExtra'] ?? m['bloques'] ?? m['extra'] ?? []);
    final bloques = <BloqueExtracurricular>{};
    if (raw is List) {
      for (final e in raw) {
        final b = BloqueExtracurricularX.tryParseAny(e?.toString());
        if (b != null) bloques.add(b);
      }
    }

    final modalidad = ModalidadCursadoX.fromString(
      (m['modalidad'] ?? '').toString(),
    );

    final lat = _toDoubleOrNull(
      m['lat'] ?? m['latitude'] ?? m['ubicacionLat'] ?? m['geoLat'],
    );
    final lng = _toDoubleOrNull(
      m['lng'] ??
          m['lon'] ??
          m['longitude'] ??
          m['ubicacionLng'] ??
          m['geoLng'],
    );

    return InstitucionSearchItem(
      institucionId: (m['institucionId'] ?? m['id'] ?? '').toString().trim(),
      nombre: (m['nombre'] ?? '').toString().trim(),
      pais: (m['pais'] ?? '').toString().trim(),
      provincia: (m['provincia'] ?? '').toString().trim(),
      ciudad: (m['ciudad'] ?? '').toString().trim(),
      modalidad: modalidad,
      curricular:
          (m['curricular'] == true) || (m['curricular'].toString() == 'true'),
      extracurricular:
          (m['extracurricular'] == true) ||
          (m['extracurricular'].toString() == 'true'),
      bloquesExtra: bloques,
      lat: lat,
      lng: lng,
    );
  }
}

class InstitucionSearchQuery {
  final String texto;
  final String? pais;
  final String? provincia;
  final String? ciudad;

  final ModalidadCursado? modalidad;

  final Set<BloqueExtracurricular> bloquesExtra;

  /// ✅ GEO (opcional / backend-ready)
  final double? userLat;
  final double? userLng;

  /// Si null -> no filtra por radio; solo permite ordenar por distancia (si hay coords).
  final double? maxDistanceKm;

  /// Si true -> ordena por distancia (si hay coords); si false -> orden alfabético.
  final bool orderByDistance;

  const InstitucionSearchQuery({
    this.texto = '',
    this.pais,
    this.provincia,
    this.ciudad,
    this.modalidad,
    this.bloquesExtra = const <BloqueExtracurricular>{},
    this.userLat,
    this.userLng,
    this.maxDistanceKm,
    this.orderByDistance = false,
  });

  InstitucionSearchQuery copyWith({
    String? texto,
    String? pais,
    String? provincia,
    String? ciudad,
    ModalidadCursado? modalidad,
    Set<BloqueExtracurricular>? bloquesExtra,
    double? userLat,
    double? userLng,
    double? maxDistanceKm,
    bool? orderByDistance,
  }) {
    return InstitucionSearchQuery(
      texto: texto ?? this.texto,
      pais: pais ?? this.pais,
      provincia: provincia ?? this.provincia,
      ciudad: ciudad ?? this.ciudad,
      modalidad: modalidad ?? this.modalidad,
      bloquesExtra: bloquesExtra ?? this.bloquesExtra,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      orderByDistance: orderByDistance ?? this.orderByDistance,
    );
  }
}

class InstitucionSearchPage {
  final List<InstitucionSearchItem> items;
  final int nextOffset;
  final bool hasMore;

  const InstitucionSearchPage({
    required this.items,
    required this.nextOffset,
    required this.hasMore,
  });
}

Future<List<InstitucionSearchItem>> cargarInstitucionSearchIndex({
  bool forceRebuild = false,
}) async {
  if (!forceRebuild) {
    final cached = await _withTimeout<String?>(
      StorageService.instance.getString(kInstitucionesSearchIndex),
      timeout: _kIOTimeoutHeavy,
      fallback: null,
      tag: 'getString search_index',
    );
    if (cached != null && cached.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (m) =>
                    InstitucionSearchItem.fromMap(Map<String, dynamic>.from(m)),
              )
              .where((x) => x.institucionId.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
  }

  final instituciones = await cargarInstitucionesRegistradas();
  final out = <InstitucionSearchItem>[];

  for (final inst in instituciones) {
    final dataId = _normInstitucionId(inst.id);
    if (dataId.isEmpty) continue;

    final bloques = <BloqueExtracurricular>{};

    // ✅ CANÓNICO primero: usar el catálogo en Institución.
    // Si está vacío y hay legacy prefs, migrar one-shot para cerrar source-of-truth.
    try {
      final hasCanon = inst.actividadesExtracurriculares.isNotEmpty;
      if (hasCanon) {
        for (final a in inst.actividadesExtracurriculares) {
          if (a.activa == true) bloques.add(a.bloque);
        }
      } else {
        final prefsActs = await _cargarActividadesExtracurricularesPrefs(
          inst.id,
        );
        if (prefsActs.isNotEmpty) {
          try {
            inst.actividadesExtracurriculares
              ..clear()
              ..addAll(prefsActs);
          } catch (_) {}
          await upsertInstitucion(inst);

          for (final a in prefsActs) {
            if (a.activa == true) bloques.add(a.bloque);
          }
        } else {
          await _limpiarActividadesExtracurricularesPrefs(inst.id);
        }
      }
    } catch (_) {}

    // ✅ GEO: lectura best-effort desde toMap (sin depender del modelo tipado).
    double? lat;
    double? lng;
    try {
      final m = inst.toMap();
      lat = _readLatFromMap(m);
      lng = _readLngFromMap(m);
      if (lat != null && lng != null) {
        if (lat.abs() > 90 || lng.abs() > 180) {
          lat = null;
          lng = null;
        }
      } else {
        lat = null;
        lng = null;
      }
    } catch (_) {
      lat = null;
      lng = null;
    }

    out.add(
      InstitucionSearchItem(
        institucionId: dataId,
        nombre: inst.nombre.trim(),
        pais: inst.pais.trim(),
        provincia: inst.provincia.trim(),
        ciudad: inst.ciudad.trim(),
        modalidad: inst.modalidad,
        curricular: inst.curricular == true,
        extracurricular: inst.extracurricular == true,
        bloquesExtra: bloques,
        lat: lat,
        lng: lng,
      ),
    );
  }

  out.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  await _withTimeoutVoid(
    StorageService.instance.setString(
      kInstitucionesSearchIndex,
      jsonEncode(out.map((e) => e.toMap()).toList()),
    ),
    timeout: _kIOTimeoutHeavy,
    tag: 'setString search_index',
  );

  return out;
}

Future<void> invalidarInstitucionesSearchIndex() async {
  await _withTimeoutVoid(
    StorageService.instance.setString(kInstitucionesSearchIndex, ''),
    tag: 'clear search_index',
  );
}

Future<InstitucionSearchPage> buscarInstitucionesPaginado({
  required InstitucionSearchQuery query,
  int offset = 0,
  int limit = 20,
}) async {
  final idx = await cargarInstitucionSearchIndex();

  final safeOffset = offset < 0 ? 0 : offset;
  final safeLimit = limit <= 0 ? 20 : limit;

  final qTxt = query.texto.trim().toLowerCase();
  final qPais = query.pais?.trim().toLowerCase();
  final qProv = query.provincia?.trim().toLowerCase();
  final qCiudad = query.ciudad?.trim().toLowerCase();
  final qMod = query.modalidad;
  final qBloques = query.bloquesExtra;

  final userLat = query.userLat;
  final userLng = query.userLng;
  final geoEnabled = (userLat != null && userLng != null);
  final maxKm = query.maxDistanceKm;
  final orderByDistance = query.orderByDistance == true;

  bool match(InstitucionSearchItem it) {
    if (qTxt.isNotEmpty) {
      final name = it.nombre.trim().toLowerCase();
      if (!name.contains(qTxt)) return false;
    }
    if (qPais != null && qPais.isNotEmpty) {
      if (it.pais.trim().toLowerCase() != qPais) return false;
    }
    if (qProv != null && qProv.isNotEmpty) {
      if (it.provincia.trim().toLowerCase() != qProv) return false;
    }
    if (qCiudad != null && qCiudad.isNotEmpty) {
      if (it.ciudad.trim().toLowerCase() != qCiudad) return false;
    }
    if (qMod != null) {
      if (it.modalidad != qMod) return false;
    }
    if (qBloques.isNotEmpty) {
      final ok = it.bloquesExtra.any((b) => qBloques.contains(b));
      if (!ok) return false;
    }

    // ✅ GEO filter (si está habilitado y hay radio)
    if (geoEnabled && maxKm != null) {
      final lat = it.lat;
      final lng = it.lng;
      if (lat == null || lng == null) return false;
      final d = _haversineKm(
        lat1: userLat,
        lng1: userLng,
        lat2: lat,
        lng2: lng,
      );
      if (d > maxKm) return false;
    }

    return true;
  }

  final filtered = idx.where(match).toList();

  // ✅ Orden: por distancia si aplica, si no -> alfabético como antes.
  if (geoEnabled && orderByDistance) {
    filtered.sort((a, b) {
      final al = a.lat;
      final ag = a.lng;
      final bl = b.lat;
      final bg = b.lng;

      // Los que no tienen coords van al final (pero sin romper UI)
      if (al == null || ag == null) return 1;
      if (bl == null || bg == null) return -1;

      final da = _haversineKm(lat1: userLat, lng1: userLng, lat2: al, lng2: ag);
      final db = _haversineKm(lat1: userLat, lng1: userLng, lat2: bl, lng2: bg);

      final c = da.compareTo(db);
      if (c != 0) return c;

      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  } else {
    filtered.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
  }

  final start = safeOffset;
  final end = (start + safeLimit) > filtered.length
      ? filtered.length
      : (start + safeLimit);

  final pageItems = start >= end
      ? <InstitucionSearchItem>[]
      : filtered.sublist(start, end);

  final nextOffset = end;
  final hasMore = nextOffset < filtered.length;

  return InstitucionSearchPage(
    items: pageItems,
    nextOffset: nextOffset,
    hasMore: hasMore,
  );
}

Future<InstitucionSearchPage> buscarInstitucionesPage({
  required InstitucionSearchQuery query,
  int offset = 0,
  int limit = 20,
}) => buscarInstitucionesPaginado(query: query, offset: offset, limit: limit);

Future<Institucion?> cargarInstitucionDesdeSearchItem(
  InstitucionSearchItem it,
) async {
  final dataId = _normInstitucionId(it.institucionId);
  if (dataId.isEmpty) return null;
  return cargarInstitucionPorId(it.institucionId);
}

Future<List<Institucion>> cargarInstitucionesRegistradasPageHidratada({
  int offset = 0,
  int limit = 20,
}) async {
  final rawList = await _withTimeout<List<String>>(
    StorageService.instance.getStringList(kInstitucionesRegistradas),
    timeout: _kIOTimeoutHeavy,
    fallback: <String>[],
    tag: 'getStringList instituciones_registradas (page)',
  );

  if (rawList.isEmpty) return <Institucion>[];

  final start = offset < 0 ? 0 : offset;
  final safeLimit = limit <= 0 ? 20 : limit;

  if (start >= rawList.length) return <Institucion>[];

  final end = (start + safeLimit) > rawList.length
      ? rawList.length
      : (start + safeLimit);

  final out = <Institucion>[];

  for (int i = start; i < end; i++) {
    final s = rawList[i];
    if (s.trim().isEmpty) continue;

    try {
      final decoded = jsonDecode(s);
      Institucion inst;

      if (decoded is Map) {
        inst = Institucion.fromMap(Map<String, dynamic>.from(decoded));
      } else {
        inst = Institucion.fromJson(s);
      }

      final a = await hidratarInstitucionConGruposCurriculares(inst);
      final b = await hidratarInstitucionConExtracurriculares(
        a,
        migrateIfLegacy: true,
      );

      out.add(b);
    } catch (_) {}
  }

  return out;
}

// ─────────────────────────────────────────────
// FIN DEL ARCHIVO
// ─────────────────────────────────────────────
