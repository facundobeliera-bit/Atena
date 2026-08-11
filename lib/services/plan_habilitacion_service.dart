// ─────────────────────────────────────────────────────────────
// ATENA – PLAN HABILITACIÓN SERVICE (CANÓNICO)
// Archivo: lib/services/plan_habilitacion_service.dart
// ─────────────────────────────────────────────────────────────
//
// RESPONSABILIDAD ÚNICA:
// - Ser la FUENTE de verdad del estado comercial/habilitación del plan.
// - Proveer helpers canónicos:
//   * normalize(planAny) -> PlanStatus
//   * isInstitucionOperativa(status) -> bool
//
// NOTA:
// - Este service NO navega, NO muestra UI, NO tiene dependencias de Widgets.
// - Soporta persistencias “sucias” del prototipo:
//   - PlanStatus tipado
//   - Enums (ej: EstadoPlanInstitucion.activo / enPrueba)
//   - String ("active", "activo", "EstadoPlanInstitucion.activo", etc.)
//   - Map / JSON ({"status":"active"} / {"activo":true} / {"isActive":1} ...)
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

/// ✅ Estado canónico de habilitación comercial.
///
/// Regla de oro para Fase 2:
/// - SOLO `active` permite operar.
/// - Todo lo demás => Guard redirige a /institucion/plan.
enum PlanStatus { active, inactive, pending, expired, unknown }

class PlanHabilitacionService {
  PlanHabilitacionService._(); // static-only

  /// ✅ Normaliza cualquier forma de plan/estado a un PlanStatus canónico.
  ///
  /// Acepta:
  /// - null
  /// - PlanStatus
  /// - Enum (ej: EstadoPlanInstitucion)
  /// - String
  /// - Map (dinámico)
  /// - JSON string con estructura de Map
  static PlanStatus normalize(dynamic planAny) {
    if (planAny == null) return PlanStatus.inactive;

    // 1) Ya viene tipado
    if (planAny is PlanStatus) return planAny;

    // 1.b) Enum (ej: EstadoPlanInstitucion.activo)
    // - Intentamos name (Dart moderno), y si no, toString().
    if (planAny is Enum) {
      String raw = '';
      try {
        // ignore: avoid_dynamic_calls
        final n = (planAny as dynamic).name;
        raw = (n == null) ? '' : n.toString();
      } catch (_) {
        raw = '';
      }
      raw = raw.trim().isNotEmpty ? raw : planAny.toString();
      final fromEnum = _fromString(raw);
      return fromEnum ?? PlanStatus.unknown;
    }

    // 2) Si viene como String: puede ser status o JSON
    if (planAny is String) {
      final t = planAny.trim();
      if (t.isEmpty) return PlanStatus.inactive;

      // 2.a) intentar JSON
      final decoded = _tryJsonDecode(t);
      if (decoded is Map) {
        final fromMap = _fromMap(decoded);
        if (fromMap != null) return fromMap;
      }

      // 2.b) interpretar literal
      final fromString = _fromString(t);
      if (fromString != null) return fromString;

      return PlanStatus.unknown;
    }

    // 3) Si viene como Map (o Map-like)
    if (planAny is Map) {
      final fromMap = _fromMap(planAny);
      if (fromMap != null) return fromMap;
      return PlanStatus.unknown;
    }

    // 4) Objeto tipado con campos (best-effort)
    try {
      // ignore: avoid_dynamic_calls
      final dyn = planAny as dynamic;

      // status directo
      try {
        // ignore: avoid_dynamic_calls
        final s = dyn.status;
        final ps = normalize(s);
        if (ps != PlanStatus.unknown) return ps;
      } catch (_) {}

      // ✅ estadoPlan / planEstado (ATENA)
      try {
        // ignore: avoid_dynamic_calls
        final ep =
            dyn.estadoPlan ?? dyn.planEstado ?? dyn.estado ?? dyn.plan_status;
        final ps = normalize(ep);
        if (ps != PlanStatus.unknown) return ps;
      } catch (_) {}

      // flags
      try {
        // ignore: avoid_dynamic_calls
        final v =
            dyn.activo ??
            dyn.active ??
            dyn.isActive ??
            dyn.enabled ??
            dyn.habilitado ??
            dyn.operativo;
        if (_truthy(v)) return PlanStatus.active;
        if (v != null) return PlanStatus.inactive;
      } catch (_) {}
    } catch (_) {}

    return PlanStatus.unknown;
  }

  /// ✅ ÚNICA regla de operación (Guard depende de esto).
  static bool isInstitucionOperativa(PlanStatus status) {
    return status == PlanStatus.active;
  }

  // ─────────────────────────────────────────────
  // Helpers internos
  // ─────────────────────────────────────────────

  static dynamic _tryJsonDecode(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return jsonDecode(t);
    } catch (_) {
      return null;
    }
  }

  static bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí';
  }

  static Set<String> _tokens(String raw) {
    final s = raw.trim().toLowerCase();

    // Normalizamos separadores comunes
    final normalized = s
        .replaceAll('.', ' ')
        .replaceAll(':', ' ')
        .replaceAll(';', ' ')
        .replaceAll(',', ' ')
        .replaceAll('|', ' ')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll('/', ' ')
        .replaceAll('\\', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return <String>{};
    return normalized.split(' ').where((x) => x.trim().isNotEmpty).toSet();
  }

  static bool _hasAny(Set<String> t, Iterable<String> opts) {
    for (final o in opts) {
      if (t.contains(o)) return true;
    }
    return false;
  }

  static PlanStatus? _fromString(String raw) {
    final t = _tokens(raw);
    if (t.isEmpty) return null;

    // ⚠️ Orden importa:
    // - Primero "inactive" para evitar substring traps tipo "inactive" -> "active".
    if (_hasAny(t, const [
      'inactive',
      'inactivo',
      'disabled',
      'deshabilitado',
    ])) {
      return PlanStatus.inactive;
    }

    // vencidos
    if (_hasAny(t, const [
      'expired',
      'vencido',
      'vencida',
      'caducado',
      'caducada',
    ])) {
      return PlanStatus.expired;
    }
    // también best-effort por prefijos (no substring de "active")
    if (t.any((x) => x.startsWith('venc')) ||
        t.any((x) => x.startsWith('caduc'))) {
      return PlanStatus.expired;
    }

    // pendientes / prueba / pago
    if (_hasAny(t, const ['pending', 'pendiente', 'trial', 'prueba'])) {
      return PlanStatus.pending;
    }
    if (t.contains('payment') || t.contains('pago') || t.contains('enprueba')) {
      return PlanStatus.pending;
    }

    // activos
    if (_hasAny(t, const ['active', 'activo', 'habilitado', 'enabled'])) {
      return PlanStatus.active;
    }

    // variantes tipo "estadoplaninstitucion activo" (ya tokenizado)
    // y variantes con "isactive" pegado:
    if (t.contains('isactive') ||
        t.contains('is_active') ||
        t.contains('isoperativo')) {
      // OJO: acá solo interpretamos "bandera", no su valor; el caso ideal es Map/obj.
      // Si viene como string suelta, la tratamos como señal de activación.
      return PlanStatus.active;
    }

    return null;
  }

  static PlanStatus? _fromMap(Map<dynamic, dynamic> mAny) {
    // Normalizamos keys a string
    final m = <String, dynamic>{};
    for (final e in mAny.entries) {
      final k = (e.key == null) ? '' : e.key.toString();
      if (k.trim().isEmpty) continue;
      m[k] = e.value;
    }

    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k)) return m[k];

        // variante case-insensitive / snake/camel
        final target = k.replaceAll('_', '').toLowerCase();
        for (final entry in m.entries) {
          final kk = entry.key.replaceAll('_', '').toLowerCase();
          if (kk == target) return entry.value;
        }
      }
      return null;
    }

    // 1) status explícito (incluye estadoPlan/planEstado)
    final statusRaw = pick(const [
      'status',
      'planStatus',
      'estado',
      'plan_estado',
      'estadoPlan',
      'planEstado',
    ]);
    final st = normalize(statusRaw);
    if (st != PlanStatus.unknown) return st;

    // 2) flags
    final activeFlag = pick(const [
      'activo',
      'active',
      'isActive',
      'enabled',
      'habilitado',
      'operativo',
      'isOperativo',
    ]);
    if (_truthy(activeFlag)) return PlanStatus.active;
    if (activeFlag != null) return PlanStatus.inactive;

    // 3) fecha / expiración (best-effort)
    final exp = pick(const ['expiresAt', 'expira', 'vencimiento', 'expiry']);
    if (exp != null) {
      final s = exp.toString().toLowerCase();
      if (s.contains('expired') || s.contains('venc') || s.contains('caduc')) {
        return PlanStatus.expired;
      }
    }

    // 4) pending flag
    final pendingFlag = pick(const [
      'pending',
      'pendiente',
      'pendingPayment',
      'pagoPendiente',
      'trial',
      'enPrueba',
      'en_prueba',
    ]);
    if (_truthy(pendingFlag)) return PlanStatus.pending;

    return null;
  }
}
