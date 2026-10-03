// lib/screens/instituciones/widgets/pln_resumen.dart
//
// Resumen del plan (detalle, descuentos y total mensual), barra inferior con
// el total para teléfonos y botón principal con estado de carga.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';
import 'pln_precios.dart';

/// Aviso destacado del resumen (prueba gratis, plan sin costo, prueba vencida…).
class PlnAviso {
  final IconData icon;
  final AtenaBannerTone tono;
  final String titulo;
  final String mensaje;

  const PlnAviso({
    required this.icon,
    required this.tono,
    required this.titulo,
    required this.mensaje,
  });
}

class PlnResumen extends StatelessWidget {
  final PlnCalculo calculo;

  /// Nombres de los niveles y módulos elegidos.
  final List<String> niveles;
  final List<String> modulos;

  final PlnAviso aviso;

  /// "Plan actual: USD 20 por mes" (gestión, cuando hay cambios sin guardar).
  final String? planActual;

  final Widget? error;
  final Widget? accion;

  const PlnResumen({
    super.key,
    required this.calculo,
    required this.niveles,
    required this.modulos,
    required this.aviso,
    this.planActual,
    this.error,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ahorro = AtenaTone.of(
      context,
      AtenaBrand.of(context).success,
    ).foreground;
    final actual = (planActual ?? '').trim();

    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AtenaIconBadge(icon: Icons.receipt_long_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.plnResumen, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (calculo.vacio)
            Text(
              t.plnElegiAlMenosUno,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else ...[
            if (calculo.niveles > 0)
              _Linea(
                titulo: t.plnResumenNiveles(calculo.niveles),
                detalle: niveles.join(', '),
                importe: plnUsd(t, calculo.importeNiveles),
              ),
            if (calculo.modulos > 0)
              _Linea(
                titulo: t.plnResumenModulos(calculo.modulos),
                detalle: modulos.join(', '),
                importe: plnUsd(t, calculo.importeModulos),
              ),
            const Divider(height: 24),
            _Linea(titulo: t.plnSubtotal, importe: plnUsd(t, calculo.subtotal)),
            if (calculo.conDescuento)
              _Linea(
                titulo: t.plnDescuentoVolumen(
                  PlnPrecios.itemsParaDescuento,
                  PlnPrecios.porcentajeDescuento,
                ),
                importe: '− ${plnUsd(t, calculo.descuento)}',
                color: ahorro,
              ),
            if (calculo.promo)
              _Linea(
                titulo: t.plnDescuentoPromo(PlnPromo.porcentaje),
                importe: '− ${plnUsd(t, calculo.descuentoPromo)}',
                color: ahorro,
              ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(t.plnTotalMes, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(width: 12),
                Text(
                  plnUsd(t, calculo.total),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (actual.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                actual,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (calculo.faltanParaDescuento > 0 && !calculo.promo) ...[
              const SizedBox(height: 12),
              _Sugerencia(
                texto: t.plnFaltanItems(
                  calculo.faltanParaDescuento,
                  PlnPrecios.porcentajeDescuento,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          AtenaBanner(
            tone: aviso.tono,
            icon: aviso.icon,
            title: aviso.titulo,
            message: aviso.mensaje,
          ),
          if (error != null) ...[const SizedBox(height: 12), error!],
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  final String titulo;
  final String? detalle;
  final String importe;
  final Color? color;

  const _Linea({
    required this.titulo,
    this.detalle,
    required this.importe,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final det = (detalle ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
                if (det.isNotEmpty)
                  Text(
                    det,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            importe,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sugerencia extends StatelessWidget {
  final String texto;

  const _Sugerencia({required this.texto});

  @override
  Widget build(BuildContext context) {
    final tone = AtenaTone.of(context, AtenaColors.goldDeep);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.sm)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, size: 18, color: tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra fija inferior (teléfonos): total mensual y acción principal.
/// Al tocar el total se muestra el resumen con el detalle.
class PlnBarraTotal extends StatelessWidget {
  final PlnCalculo calculo;
  final Widget accion;
  final VoidCallback onVerResumen;

  const PlnBarraTotal({
    super.key,
    required this.calculo,
    required this.accion,
    required this.onVerResumen,
  });

  static const double _anchoTotal = 150;
  static const double _anchoAccion = 320;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final total = calculo.vacio
        ? Text(
            t.plnElegiAlMenosUnoCorto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: t.plnTotalMes,
                  children: [
                    const TextSpan(text: ' '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  plnUsd(t, calculo.total),
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: atenaPagePadding(
              context,
              maxWidth: 720,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                // El total ocupa lo que necesita (con tope) y el botón, el
                // resto.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _anchoTotal),
                  child: Tooltip(
                    message: t.plnVerResumen,
                    child: InkWell(
                      onTap: onVerResumen,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AtenaRadius.sm),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          heightFactor: 1,
                          child: total,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _anchoAccion),
                      child: accion,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón principal del plan (a todo el ancho), con indicador mientras se
/// procesa. Si el texto no entra, se achica en lugar de cortarse.
class PlnBotonAccion extends StatelessWidget {
  final String label;
  final String cargandoLabel;
  final IconData icon;
  final bool cargando;

  /// null = deshabilitado.
  final VoidCallback? onPressed;

  const PlnBotonAccion({
    super.key,
    required this.label,
    required this.cargandoLabel,
    required this.icon,
    required this.cargando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: cargando ? null : onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: cargando
                ? [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(cargandoLabel),
                  ]
                : [Text(label), const SizedBox(width: 8), Icon(icon, size: 20)],
          ),
        ),
      ),
    );
  }
}
