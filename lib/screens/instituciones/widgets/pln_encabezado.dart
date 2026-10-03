// lib/screens/instituciones/widgets/pln_encabezado.dart
//
// Encabezados destacados de la pantalla del plan: el del registro (paso y
// ventajas) y el de la gestión (estado del plan vigente).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_ui.dart';
import 'pln_precios.dart';

/// Encabezado del registro: paso actual y ventajas del plan.
class PlnEncabezadoRegistro extends StatelessWidget {
  const PlnEncabezadoRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AtenaGradientPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.authStepOf('2', '2').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.plnHeroTitulo,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.plnHeroAyuda,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pastilla(
                icon: Icons.card_giftcard_rounded,
                texto: t.plnPrueba(PlnPrecios.diasPrueba),
              ),
              _Pastilla(icon: Icons.money_off_rounded, texto: t.plnSinPagos),
              _Pastilla(icon: Icons.tune_rounded, texto: t.plnFlexible),
            ],
          ),
        ],
      ),
    );
  }
}

/// Encabezado de la gestión: estado del plan vigente, costo y contenido.
class PlnEncabezadoGestion extends StatelessWidget {
  final Institucion inst;

  /// Plan guardado (no la selección en pantalla).
  final PlnCalculo plan;

  const PlnEncabezadoGestion({
    super.key,
    required this.inst,
    required this.plan,
  });

  /// Días de calendario que faltan para el fin de la prueba.
  static int _diasRestantes(DateTime fin) {
    final hoy = DateTime.now();
    final desde = DateTime(hoy.year, hoy.month, hoy.day);
    final hasta = DateTime(fin.year, fin.month, fin.day);
    return math.max(0, (hasta.difference(desde).inHours / 24).round());
  }

  ({String etiqueta, IconData icon, String? detalle}) _estado(
    BuildContext context,
  ) {
    final t = AppLocalizations.of(context);
    final vencida = DateTime.now().isAfter(inst.planFin);
    return switch (inst.estadoPlan) {
      EstadoPlanInstitucion.activo => (
        etiqueta: t.instPlanActive,
        icon: Icons.verified_rounded,
        detalle: plan.promo ? t.plnPromoActivo(PlnPromo.porcentaje) : null,
      ),
      EstadoPlanInstitucion.enPrueba when !vencida => (
        etiqueta: t.instPlanTrialUntil(
          AtenaFormat.fechaCorta(context, inst.planFin),
        ),
        icon: Icons.hourglass_bottom_rounded,
        detalle: t.plnDiasRestantes(_diasRestantes(inst.planFin)),
      ),
      EstadoPlanInstitucion.enPrueba || EstadoPlanInstitucion.vencido => (
        etiqueta: t.instPlanTrialEnded,
        icon: Icons.timer_off_rounded,
        detalle: null,
      ),
      EstadoPlanInstitucion.suspendido => (
        etiqueta: t.instPlanSuspended,
        icon: Icons.pause_circle_rounded,
        detalle: null,
      ),
      EstadoPlanInstitucion.sinPlan => (
        etiqueta: t.instPlanNone,
        icon: Icons.info_rounded,
        detalle: null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final estado = _estado(context);
    final detalle = (estado.detalle ?? '').trim();
    final suave = Colors.white.withValues(alpha: 0.88);

    return AtenaGradientPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Icon(estado.icon, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.plnTuPlan,
                      style: theme.textTheme.bodyMedium?.copyWith(color: suave),
                    ),
                    Text(
                      estado.etiqueta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detalle,
              style: theme.textTheme.bodyMedium?.copyWith(color: suave),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pastilla(
                icon: Icons.payments_rounded,
                texto: t.plnPlanActual(plnUsd(t, plan.total)),
              ),
              if (plan.niveles > 0)
                _Pastilla(
                  icon: Icons.school_rounded,
                  texto: t.plnResumenNiveles(plan.niveles),
                ),
              if (plan.modulos > 0)
                _Pastilla(
                  icon: Icons.interests_rounded,
                  texto: t.plnResumenModulos(plan.modulos),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta translúcida sobre el panel con gradiente.
class _Pastilla extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _Pastilla({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AtenaRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
