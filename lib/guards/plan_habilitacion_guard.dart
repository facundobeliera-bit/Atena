// ─────────────────────────────────────────────────────────────
// ATENA – PLAN HABILITACIÓN GUARD
// Archivo: lib/guards/plan_habilitacion_guard.dart
// ─────────────────────────────────────────────────────────────
//
// RESPONSABILIDAD ÚNICA:
// - Interrumpir el flujo institucional si el plan NO está activo.
// - Redirigir SIEMPRE a la pantalla de Plan de forma explícita.
// - Nunca dejar spinners, awaits colgados o estados intermedios.
//
// ❌ NO define reglas de plan (eso es del Service)
// ❌ NO muestra dialogs
// ❌ NO tiene loaders
//
// CANÓNICO – FASE 2 (CIERRE COMERCIAL)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// Service canónico (FUENTE de verdad)
import '../services/plan_habilitacion_service.dart';

class PlanHabilitacionGuard {
  PlanHabilitacionGuard._(); // static-only

  /// ✅ Ruta canónica a la pantalla de plan.
  static const String kRouteInstitucionPlan = '/institucion/plan';

  /// Arguments canónicos (mínimos) para la pantalla de plan.
  static const String kArgPlanStatus = 'planStatus';

  /// Arguments canónicos recomendados (cuando existan).
  static const String kArgOwnerAccountId = 'ownerAccountId';
  static const String kArgInstitucionPerfilId = 'institucionPerfilId';
  static const String kArgInstitucionNombre = 'institucionNombre';

  static const Set<String> _kCanonicalArgKeys = <String>{
    kArgPlanStatus,
    kArgOwnerAccountId,
    kArgInstitucionPerfilId,
    kArgInstitucionNombre,
  };

  static PlanStatus? _asPlanStatusOrNull(Object? v) {
    if (v == null) return null;
    if (v is PlanStatus) return v;
    return null; // no adivinamos estructuras acá (no reglas, no reflection)
  }

  static void ensureOperativo({
    required BuildContext context,

    /// ✅ Acepta Object? para permitir "best-effort" desde pantallas (sin romper compile).
    /// IMPORTANTE (CANÓNICO):
    /// - Si NO llega un PlanStatus real (o llega null), el guard NO decide.
    ///   Esto evita redirecciones falsas a Plan por falta de datos.
    required Object? plan,

    String? ownerAccountId,
    String? institucionPerfilId,
    String? institucionNombre,

    Map<String, dynamic>? extraArguments,
  }) {
    if (!context.mounted) return;

    // ✅ Anti-loop: si ya estamos en Plan, no re-navegamos.
    try {
      final current = ModalRoute.of(context)?.settings.name ?? '';
      if (current == kRouteInstitucionPlan) return;
    } catch (_) {}

    // ✅ CANÓNICO: si no hay PlanStatus real, NO redirigimos (evita falsos positivos).
    final PlanStatus? incoming = _asPlanStatusOrNull(plan);
    if (incoming == null) return;

    final PlanStatus normalizedPlan = PlanHabilitacionService.normalize(
      incoming,
    );

    final bool operativo = PlanHabilitacionService.isInstitucionOperativa(
      normalizedPlan,
    );

    if (operativo) return;

    // ✅ Sanitizar extraArguments: NUNCA puede pisar keys canónicas.
    final Map<String, dynamic> safeExtra = <String, dynamic>{};
    if (extraArguments != null && extraArguments.isNotEmpty) {
      for (final entry in extraArguments.entries) {
        if (_kCanonicalArgKeys.contains(entry.key)) continue;
        safeExtra[entry.key] = entry.value;
      }
    }

    final args = <String, dynamic>{
      ...safeExtra,
      kArgPlanStatus: normalizedPlan,
      if ((ownerAccountId ?? '').trim().isNotEmpty)
        kArgOwnerAccountId: ownerAccountId!.trim(),
      if ((institucionPerfilId ?? '').trim().isNotEmpty)
        kArgInstitucionPerfilId: institucionPerfilId!.trim(),
      if ((institucionNombre ?? '').trim().isNotEmpty)
        kArgInstitucionNombre: institucionNombre!.trim(),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      // Re-check anti-loop
      try {
        final current = ModalRoute.of(context)?.settings.name ?? '';
        if (current == kRouteInstitucionPlan) return;
      } catch (_) {}

      try {
        // ignore: discarded_futures
        Navigator.of(
          context,
        ).pushReplacementNamed(kRouteInstitucionPlan, arguments: args);
      } catch (_) {
        return; // ruta no registrada / navegación falló → no crash
      }
    });
  }
}
