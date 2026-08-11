// ─────────────────────────────────────────────
// ATENA – EXTRACURRICULARES SERVICE (PROTOTIPO / SharedPreferences)
// Archivo: lib/services/extracurriculares_service.dart
// ─────────────────────────────────────────────
//
// CANÓNICO (enero 2026):
// - institucionId = perfilId (perfil institución)
// - moduleKey validada exclusivamente contra BloqueExtracurricular
// - Fuente de verdad: GrupoExtracurricular.bloque
// - NO normalización agresiva de moduleKey
//
// HARDENING (fase 2):
// - Normalización estable (sin mutar semántica).
// - Fail-fast real en filtros inválidos (devuelve vacío + sin side effects).
// - Deduplicación defensiva en lectura y escritura.
// - Orden determinístico estable.
// - Guardado ordenado (persistencia estable -> diffs más limpios).
// - Migración legacy best-effort con dedupe y cleanup.
//
// ✅ UPDATE (enero 2026):
// - GrupoExtracurricular tiene `turno` y `aula` como campos reales.
//
// ✅ EXTENSIÓN (feb 2026 · solicitado):
// - Emisión de “Fichas Extracurriculares” (institución → alumnos) BACKEND-READY:
//   * Destinatarios confirmados por módulo (ownerAccountId + perfilId).
//   * Emisión: Notificación CANÓNICA (owner inbox) usando NotificacionesService.
//   * Calendario: pendiente de integración canónica hasta ver CalendarioService.
//
// Importante:
// - Persistencia grupos: lista completa por institución.
// - Sin flujos paralelos.
// - La aceptación de solicitudes debe alimentar el registry (upsertDestinatarioConfirmado).
//
// ─────────────────────────────────────────────

import 'dart:convert';

import 'storage_service.dart';
import 'notificaciones_service.dart';

import '../models/extracurriculares/bloque_extracurricular.dart';
import '../models/extracurriculares/grupo_extracurricular.dart';
import '../models/notificaciones/notificacion_atena.dart';
import '../routes/atena_deeplink.dart';

class ExtracurricularesService {
  ExtracurricularesService._();
  static final ExtracurricularesService instance = ExtracurricularesService._();

  // =====================================================
  // NORMALIZACIÓN (CANÓNICA Y ESTABLE)
  // =====================================================

  /// Normaliza IDs/keys SIN alterar caracteres:
  /// - trim
  /// - elimina whitespace interno (espacios, tabs, newlines)
  static String _normKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  /// moduleKey: trim + lower únicamente.
  static String _normModuleKey(String v) => v.trim().toLowerCase();

  static String _normSort(String v) => v.trim().toLowerCase();

  static bool _isValidModuleKey(String v) {
    final mk = _normModuleKey(v);
    if (mk.isEmpty) return false;
    return BloqueExtracurricularX.isValidKey(mk);
  }

  static bool _isValidBloque(BloqueExtracurricular bloque) {
    final mk = _normModuleKey(bloque.key);
    return mk.isNotEmpty && BloqueExtracurricularX.isValidKey(mk);
  }

  static String _turnoSort(GrupoExtracurricular g) => _normSort(g.turno);
  static String _aulaSort(GrupoExtracurricular g) => _normSort(g.aula);

  static String _s(dynamic v) => (v ?? '').toString();
  static String _sTrim(dynamic v) => _s(v).trim();

  // =====================================================
  // KEYS (GRUPOS)
  // =====================================================

  static String kGruposExtracurriculares(String institucionId) =>
      'extracurriculares_grupos_${_normKey(institucionId)}';

  // =====================================================
  // KEYS (DESTINATARIOS CONFIRMADOS POR MÓDULO)
  // =====================================================

  /// Registry mínima de alumnos confirmados para un módulo:
  /// Cada item:
  /// {
  ///   "ownerAccountId": "...",
  ///   "perfilId": "...",
  ///   "nombre": "..." (opcional),
  ///   "updatedAt": "...iso" (opcional)
  /// }
  static String kDestinatariosConfirmados({
    required String institucionId,
    required String moduleKey,
  }) {
    final id = _normKey(institucionId);
    final mk = _normModuleKey(moduleKey);
    return 'atena_extrac_destinatarios_${id}_$mk';
  }

  // =====================================================
  // ORDEN / DEDUP (determinísticos)
  // =====================================================

  static int _compareStable(GrupoExtracurricular a, GrupoExtracurricular b) {
    final ka = [
      _normSort(a.bloque.key),
      _normSort(a.actividadNombre),
      _normSort(a.nombreGrupo),
      _turnoSort(a),
      _aulaSort(a),
      _normSort(a.id),
    ].join('|');

    final kb = [
      _normSort(b.bloque.key),
      _normSort(b.actividadNombre),
      _normSort(b.nombreGrupo),
      _turnoSort(b),
      _aulaSort(b),
      _normSort(b.id),
    ].join('|');

    return ka.compareTo(kb);
  }

  static List<GrupoExtracurricular> _dedupById(
    Iterable<GrupoExtracurricular> xs,
  ) {
    final byId = <String, GrupoExtracurricular>{};
    for (final g in xs) {
      final gid = _normKey(g.id);
      if (gid.isNotEmpty) byId[gid] = g;
    }
    final out = byId.values.toList(growable: false);
    out.sort(_compareStable);
    return out;
  }

  static int _compareDestinatarioStable(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final ka =
        '${_normSort(_s(a['nombre']))}|${_normSort(_s(a['perfilId']))}|${_normSort(_s(a['ownerAccountId']))}';
    final kb =
        '${_normSort(_s(b['nombre']))}|${_normSort(_s(b['perfilId']))}|${_normSort(_s(b['ownerAccountId']))}';
    return ka.compareTo(kb);
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<List<GrupoExtracurricular>> cargarGrupos(String institucionId) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return <GrupoExtracurricular>[];

    final raw = await StorageService.instance.getJsonList(
      kGruposExtracurriculares(id),
    );

    final parsed = <GrupoExtracurricular>[];
    for (final m in raw) {
      try {
        final g = GrupoExtracurricular.fromMap(m);

        // Hardening: si el bloque es inválido, no lo incorporamos.
        if (!_isValidBloque(g.bloque)) continue;

        parsed.add(g);
      } catch (_) {
        // item corrupto → ignorar
      }
    }

    // Dedup defensivo + orden estable
    return _dedupById(parsed);
  }

  // =====================================================
  // SAVE
  // =====================================================

  Future<void> guardarGrupos(
    String institucionId,
    List<GrupoExtracurricular> grupos,
  ) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return;

    if (grupos.isEmpty) {
      await StorageService.instance.setJsonList(
        kGruposExtracurriculares(id),
        const <Map<String, dynamic>>[],
      );
      return;
    }

    // Hardening: filtramos elementos con bloque inválido antes de persistir
    final sane = grupos.where((g) => _normKey(g.id).isNotEmpty).where((g) {
      try {
        return _isValidBloque(g.bloque);
      } catch (_) {
        return false;
      }
    });

    // Dedup + orden antes de persistir (estabilidad de storage)
    final stable = _dedupById(sane);
    final data = stable.map((g) => g.toMap()).toList(growable: false);

    await StorageService.instance.setJsonList(
      kGruposExtracurriculares(id),
      data,
    );
  }

  // =====================================================
  // UPSERT / DELETE
  // =====================================================

  Future<void> upsertGrupo(
    String institucionId,
    GrupoExtracurricular grupo,
  ) async {
    final id = _normKey(institucionId);
    final gid = _normKey(grupo.id);
    if (id.isEmpty || gid.isEmpty) return;

    // Fail-fast canónico: no persistir grupos con bloque inválido
    if (!_isValidBloque(grupo.bloque)) return;

    final grupos = await cargarGrupos(id);

    final next = grupos.toList(growable: true);
    final idx = next.indexWhere((g) => _normKey(g.id) == gid);

    if (idx >= 0) {
      next[idx] = grupo;
    } else {
      next.add(grupo);
    }

    await guardarGrupos(id, next);
  }

  Future<void> borrarGrupo(String institucionId, String grupoId) async {
    final id = _normKey(institucionId);
    final gid = _normKey(grupoId);
    if (id.isEmpty || gid.isEmpty) return;

    final grupos = await cargarGrupos(id);
    final next = grupos.toList(growable: true)
      ..removeWhere((g) => _normKey(g.id) == gid);

    await guardarGrupos(id, next);
  }

  // =====================================================
  // FILTROS CANÓNICOS POR MÓDULO
  // =====================================================

  Future<List<GrupoExtracurricular>> cargarGruposPorModulo({
    required String institucionId,
    required String moduleKey,
  }) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return <GrupoExtracurricular>[];

    final mk = _normModuleKey(moduleKey);
    if (!_isValidModuleKey(mk)) return <GrupoExtracurricular>[];

    final grupos = await cargarGrupos(id);

    final out = grupos
        .where((g) => _normModuleKey(g.bloque.key) == mk)
        .toList(growable: false);

    return out;
  }

  Future<int> contarGruposConCupo(
    String institucionId, {
    String? moduleKey,
  }) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return 0;

    final mkRaw = (moduleKey ?? '').trim();
    if (mkRaw.isEmpty) {
      final grupos = await cargarGrupos(id);
      return grupos.where((g) => g.tieneCupos).length;
    }

    final mk = _normModuleKey(mkRaw);
    if (!_isValidModuleKey(mk)) return 0;

    final grupos = await cargarGruposPorModulo(
      institucionId: id,
      moduleKey: mk,
    );

    return grupos.where((g) => g.tieneCupos).length;
  }

  // =====================================================
  // ID FACTORY (FUENTE ÚNICA DE VERDAD)
  // =====================================================

  String newGrupoId() => GrupoExtracurricular.newGrupoId();

  // =====================================================
  // DESTINATARIOS CONFIRMADOS (REGISTRY CANÓNICA MÍNIMA)
  // =====================================================

  Future<List<Map<String, dynamic>>> listarDestinatariosConfirmadosPorModulo({
    required String institucionId,
    required String moduleKey,
  }) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return <Map<String, dynamic>>[];

    final mk = _normModuleKey(moduleKey);
    if (!_isValidModuleKey(mk)) return <Map<String, dynamic>>[];

    final raw = await StorageService.instance.getJsonList(
      kDestinatariosConfirmados(institucionId: id, moduleKey: mk),
    );

    final byKey = <String, Map<String, dynamic>>{};
    for (final m in raw) {
      try {
        final mm = Map<String, dynamic>.from(m);
        final owner = _normKey(_sTrim(mm['ownerAccountId']));
        final perfil = _normKey(_sTrim(mm['perfilId']));
        if (owner.isEmpty || perfil.isEmpty) continue;

        final key = '$owner|$perfil';
        mm['ownerAccountId'] = owner;
        mm['perfilId'] = perfil;
        mm['nombre'] = _sTrim(mm['nombre']);
        byKey[key] = mm;
      } catch (_) {}
    }

    final out = byKey.values.toList(growable: false)
      ..sort(_compareDestinatarioStable);

    return out;
  }

  Future<void> upsertDestinatarioConfirmado({
    required String institucionId,
    required String moduleKey,
    required String ownerAccountId,
    required String perfilId,
    String? nombre,
  }) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return;

    final mk = _normModuleKey(moduleKey);
    if (!_isValidModuleKey(mk)) return;

    final owner = _normKey(ownerAccountId);
    final perfil = _normKey(perfilId);
    if (owner.isEmpty || perfil.isEmpty) return;

    final key = '$owner|$perfil';
    final list = await listarDestinatariosConfirmadosPorModulo(
      institucionId: id,
      moduleKey: mk,
    );

    final byKey = <String, Map<String, dynamic>>{
      for (final m in list)
        '${_normKey(_sTrim(m['ownerAccountId']))}|${_normKey(_sTrim(m['perfilId']))}':
            m,
    };

    byKey[key] = <String, dynamic>{
      'ownerAccountId': owner,
      'perfilId': perfil,
      'nombre': (nombre ?? '').trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final ordered = byKey.values.toList(growable: false)
      ..sort(_compareDestinatarioStable);

    await StorageService.instance.setJsonList(
      kDestinatariosConfirmados(institucionId: id, moduleKey: mk),
      ordered,
    );
  }

  // =====================================================
  // EMISIÓN DE FICHA (NOTIFICACIÓN CANÓNICA)
  // =====================================================

  static String _buildFichaId({
    required String institucionId,
    required String moduleKey,
    required String ownerAccountId,
    required String perfilId,
    required String date,
    required String time,
    required String createdAtIso,
  }) {
    final a = _normKey(institucionId);
    final b = _normModuleKey(moduleKey);
    final c = _normKey(ownerAccountId);
    final d = _normKey(perfilId);
    final e = _normKey(date);
    final f = _normKey(time);
    final g = _normKey(createdAtIso);
    return 'xf_${a}_${b}_${c}_${d}_${e}_${f}_$g';
  }

  /// payload esperado (mínimo):
  /// {
  ///   "version": 1,
  ///   "institucionId": "...",
  ///   "moduleKey": "...",
  ///   "bloqueKey": "...",
  ///   "bloqueLabel": "...",
  ///   "date": "YYYY-MM-DD",
  ///   "time": "HH:mm",
  ///   "title": "...",
  ///   "content": "...",
  ///   "addToCalendar": true/false,  // (pendiente de integración canónica)
  ///   "recipients": [ {"ownerAccountId":"...","perfilId":"...","displayName":"..."} ],
  ///   "createdAtIso": "..."
  /// }
  ///
  /// ✅ CANÓNICO: siempre pushToOwner (owner inbox).
  /// ✅ Duplicado a perfil: opcional (UX) — hoy lo dejamos desactivado por defecto.
  Future<void> emitirFichaExtracurricular(Map<String, dynamic> payload) async {
    final version = payload['version'];
    if (version != 1) return;

    final institucionId = _normKey(_sTrim(payload['institucionId']));
    final moduleKey = _normModuleKey(_sTrim(payload['moduleKey']));
    if (institucionId.isEmpty) return;
    if (!_isValidModuleKey(moduleKey)) return;

    final date = _sTrim(payload['date']);
    final time = _sTrim(payload['time']);
    if (date.isEmpty || time.isEmpty) return;

    final createdAtIso = _sTrim(payload['createdAtIso']).isEmpty
        ? DateTime.now().toIso8601String()
        : _sTrim(payload['createdAtIso']);

    final recipientsRaw = payload['recipients'];
    if (recipientsRaw is! List) return;

    final bloqueKey = _normModuleKey(_sTrim(payload['bloqueKey']));
    final bloqueLabel = _sTrim(payload['bloqueLabel']);
    final title = _sTrim(payload['title']);
    final content = _sTrim(payload['content']);

    final fichaBase = <String, dynamic>{
      'version': 1,
      'type': 'extracurricular_ficha',
      'institucionId': institucionId,
      'moduleKey': moduleKey,
      'bloqueKey': bloqueKey,
      'bloqueLabel': bloqueLabel,
      'date': date,
      'time': time,
      'title': title,
      'content': content,
      'createdAtIso': createdAtIso,
    };

    // ✅ Dedup defensivo de recipients (evita doble push si payload trae duplicados).
    final seen = <String>{};

    for (final r in recipientsRaw) {
      if (r is! Map) continue;

      final owner = _normKey(_sTrim(r['ownerAccountId']));
      final perfil = _normKey(_sTrim(r['perfilId']));
      if (owner.isEmpty || perfil.isEmpty) continue;

      final rk = '$owner|$perfil';
      if (seen.contains(rk)) continue;
      seen.add(rk);

      final fichaId = _buildFichaId(
        institucionId: institucionId,
        moduleKey: moduleKey,
        ownerAccountId: owner,
        perfilId: perfil,
        date: date,
        time: time,
        createdAtIso: createdAtIso,
      );

      // ✅ Deeplink canónico (se re-canoniza igual por NotificacionesService).
      final deeplinkRaw =
          '/calendario?ownerAccountId=$owner&perfilId=$perfil&date=$date&time=$time&fichaId=$fichaId';

      final deeplink = AtenaDeeplink.ensureCanonicoString(
        deeplinkRaw,
        ownerAccountId: owner,
        perfilId: perfil,
      );

      // Notificación: construimos Map compatible y lo parseamos por NotificacionAtena.fromMap
      final notiMap = <String, dynamic>{
        'id': fichaId,
        'ownerAccountId': owner,
        'perfilId': perfil,
        'tipo': 'extracurricular_ficha',
        'titulo': title.isEmpty ? 'Ficha extracurricular' : title,
        'mensaje': content,
        'deeplink': deeplink,
        'fechaIso': createdAtIso,
        'leida': false,
        'payload': fichaBase,
      };

      NotificacionAtena noti;
      try {
        noti = NotificacionAtena.fromMap(notiMap);
      } catch (_) {
        // Fail-safe: no emitimos si el modelo no acepta el map.
        continue;
      }

      try {
        await NotificacionesService.instance.pushToOwner(
          ownerAccountId: owner,
          notificacion: noti,
          duplicarEnPerfil:
              false, // UX opcional: lo habilitamos cuando lo pidas.
        );
      } catch (_) {
        // Fail-safe: no frenamos el loop por 1 destinatario.
        continue;
      }

      // ⚠️ Calendario canónico: NO se escribe acá hasta ver CalendarioService real.
      // En cuanto me pegues CalendarioService, lo integramos y queda E2E:
      // - Upsert evento (owner calendar)
      // - deeplink a detalle “Ficha Extracurricular”
    }
  }

  // =====================================================
  // MIGRACIÓN LEGACY (BEST-EFFORT)
  // =====================================================

  Future<void> migrarDesdeLegacyKeySiExiste({
    required String legacyKey,
    required String institucionId,
  }) async {
    final id = _normKey(institucionId);
    if (id.isEmpty) return;

    final lk = legacyKey.trim();
    if (lk.isEmpty) return;

    final raw = await StorageService.instance.getString(lk);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final actuales = await cargarGrupos(id);
      final byId = <String, GrupoExtracurricular>{
        for (final g in actuales) _normKey(g.id): g,
      };

      for (final e in decoded) {
        if (e is Map) {
          try {
            final g = GrupoExtracurricular.fromMap(
              Map<String, dynamic>.from(e),
            );
            final gid = _normKey(g.id);
            if (gid.isEmpty) continue;

            if (!_isValidBloque(g.bloque)) continue;
            byId[gid] = g;
          } catch (_) {}
        }
      }

      await guardarGrupos(id, byId.values.toList(growable: false));
      await StorageService.instance.setString(lk, '');
    } catch (_) {
      // no-op
    }
  }
}
