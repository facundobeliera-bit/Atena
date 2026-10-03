// lib/screens/instituciones/widgets/ofertas_tarjeta.dart
//
// ATENA – Piezas de la lista de vacantes de la institución: resumen de cupos,
// encabezado de cada nivel o categoría y tarjeta de una vacante (datos,
// ocupación del cupo, estado y acciones).

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'ofertas_campos.dart';

enum OfertasAccion { editar, pausar, duplicar, solicitudes, eliminar }

// -----------------------------------------------------------------------------
// Resumen
// -----------------------------------------------------------------------------

/// Vacantes libres, ofertas activas y solicitudes pendientes.
class OfertasResumen extends StatelessWidget {
  final int libres;
  final int activas;
  final int pendientes;

  const OfertasResumen({
    super.key,
    required this.libres,
    required this.activas,
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final brand = AtenaBrand.of(context);

    Widget divisor() => SizedBox(
      height: 88,
      child: VerticalDivider(
        width: 1,
        indent: 8,
        endIndent: 8,
        color: cs.outlineVariant,
      ),
    );

    return AtenaCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Row(
        // Arriba: los números quedan alineados aunque una etiqueta ocupe dos
        // renglones.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Indicador(
              icono: Icons.event_seat_rounded,
              color: brand.success,
              valor: libres,
              etiqueta: t.instStatFreeSpotsN(libres),
            ),
          ),
          divisor(),
          Expanded(
            child: _Indicador(
              icono: Icons.play_circle_rounded,
              color: cs.primary,
              valor: activas,
              etiqueta: t.instStatOffersN(activas),
            ),
          ),
          divisor(),
          Expanded(
            child: _Indicador(
              icono: Icons.hourglass_top_rounded,
              color: brand.warning,
              valor: pendientes,
              etiqueta: t.instStatPendingN(pendientes),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final int valor;
  final String etiqueta;

  const _Indicador({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            AtenaIconBadge(icon: icono, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              '$valor',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Encabezado de grupo (nivel o categoría)
// -----------------------------------------------------------------------------

class OfertasGrupoEncabezado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final bool fueraDelPlan;
  final VoidCallback? onAgregar;

  const OfertasGrupoEncabezado({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.fueraDelPlan = false,
    this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          AtenaIconBadge(icon: icono, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(detalle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (fueraDelPlan) ...[
            const SizedBox(width: 8),
            AtenaStatusChip(
              label: t.ofertasFueraDelPlan,
              color: AtenaColors.warning,
              icon: Icons.info_rounded,
              dense: true,
            ),
          ],
          if (onAgregar != null)
            IconButton(
              tooltip: t.ofertasAgregarEn(titulo),
              onPressed: onAgregar,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tarjeta de vacante
// -----------------------------------------------------------------------------

class OfertasTarjeta extends StatelessWidget {
  final OfertaConCupo item;

  /// Hay una acción en curso sobre esta vacante.
  final bool procesando;

  /// El plan permite crear otra vacante en el mismo nivel o categoría.
  final bool puedeDuplicar;

  final ValueChanged<OfertasAccion> onAccion;

  const OfertasTarjeta({
    super.key,
    required this.item,
    required this.onAccion,
    this.procesando = false,
    this.puedeDuplicar = true,
  });

  @override
  Widget build(BuildContext context) {
    final o = item.oferta;
    final pausada = !o.activa;

    return AtenaCard(
      onTap: procesando ? null : () => onAccion(OfertasAccion.editar),
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final icono = _Atenuado(
            activo: pausada,
            child: AtenaIconBadge(
              icon: iconoOferta(o),
              color: pausada ? AtenaColors.neutral : null,
            ),
          );
          final datos = _Atenuado(
            activo: pausada,
            child: _Datos(oferta: o),
          );
          final ocupacion = _Atenuado(
            activo: pausada,
            child: _Ocupacion(item: item),
          );
          final estado = _Estado(item: item);
          final pendientes = item.pendientes > 0
              ? _BotonPendientes(
                  cantidad: item.pendientes,
                  onPressed: () => onAccion(OfertasAccion.solicitudes),
                )
              : null;
          final menu = _Menu(
            oferta: o,
            procesando: procesando,
            puedeDuplicar: puedeDuplicar,
            onAccion: onAccion,
          );

          if (c.maxWidth >= 600) {
            return Row(
              children: [
                icono,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [datos, const SizedBox(height: 10), estado],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 230,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ocupacion,
                      if (pendientes != null) ...[
                        const SizedBox(height: 4),
                        pendientes,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                menu,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icono,
                  const SizedBox(width: 14),
                  Expanded(child: datos),
                  menu,
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ocupacion,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: estado),
                  ?pendientes,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Atenuado extends StatelessWidget {
  final bool activo;
  final Widget child;

  const _Atenuado({required this.activo, required this.child});

  @override
  Widget build(BuildContext context) =>
      activo ? Opacity(opacity: 0.55, child: child) : child;
}

class _Datos extends StatelessWidget {
  final Oferta oferta;

  const _Datos({required this.oferta});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final o = oferta;
    final edad = t.rangoEdad(o.edadMinima, o.edadMaxima);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          o.nombreCompleto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _Dato(icono: ofertasIconoTurno(o.turno), texto: t.turno(o.turno)),
            if (o.horario.trim().isNotEmpty)
              _Dato(icono: Icons.access_time_rounded, texto: o.horario.trim()),
            if (o.dias.trim().isNotEmpty)
              _Dato(icono: Icons.calendar_today_rounded, texto: o.dias.trim()),
            if (edad.isNotEmpty) _Dato(icono: Icons.cake_rounded, texto: edad),
            if (o.arancel.trim().isNotEmpty)
              _Dato(icono: Icons.payments_rounded, texto: o.arancel.trim()),
          ],
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Ocupacion extends StatelessWidget {
  final OfertaConCupo item;

  const _Ocupacion({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = item.completa
        ? AtenaBrand.of(context).success
        : theme.colorScheme.primary;
    final cupo = item.oferta.cupoTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.ofertasConfirmados(item.confirmados),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              t.lblCuposDeTotal(item.disponibles, cupo),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: item.ocupacion,
          minHeight: 8,
          color: color,
          backgroundColor: AtenaTone.of(context, color).background,
          borderRadius: const BorderRadius.all(Radius.circular(99)),
          semanticsLabel: t.ofertasOcupacion(item.confirmados, cupo),
        ),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  final OfertaConCupo item;

  const _Estado({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final activa = item.oferta.activa;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        AtenaStatusChip(
          label: activa ? t.ofertasActiva : t.ofertasPausada,
          color: activa ? AtenaColors.success : AtenaColors.neutral,
          icon: activa ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
          dense: true,
        ),
        if (item.completa)
          AtenaStatusChip(
            label: t.ofertasCompleta,
            color: AtenaColors.info,
            icon: Icons.event_busy_rounded,
            dense: true,
          ),
      ],
    );
  }
}

class _BotonPendientes extends StatelessWidget {
  final int cantidad;
  final VoidCallback onPressed;

  const _BotonPendientes({required this.cantidad, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AtenaTone.of(context, AtenaColors.warning).foreground,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      icon: const Icon(Icons.hourglass_top_rounded, size: 18),
      label: Text(t.ofertasPendientes(cantidad)),
    );
  }
}

class _Menu extends StatelessWidget {
  final Oferta oferta;
  final bool procesando;
  final bool puedeDuplicar;
  final ValueChanged<OfertasAccion> onAccion;

  const _Menu({
    required this.oferta,
    required this.procesando,
    required this.puedeDuplicar,
    required this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    if (procesando) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    PopupMenuItem<OfertasAccion> opcion(
      OfertasAccion valor,
      IconData icono,
      String texto, {
      Color? color,
    }) {
      return PopupMenuItem<OfertasAccion>(
        value: valor,
        child: ListTile(
          leading: Icon(icono, color: color),
          title: Text(
            texto,
            style: color == null ? null : TextStyle(color: color),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    return PopupMenuButton<OfertasAccion>(
      tooltip: t.uiMoreOptions,
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
      onSelected: onAccion,
      itemBuilder: (context) => [
        opcion(OfertasAccion.editar, Icons.edit_rounded, t.commonEdit),
        opcion(
          OfertasAccion.pausar,
          oferta.activa
              ? Icons.pause_circle_rounded
              : Icons.play_circle_rounded,
          oferta.activa ? t.ofertasPausar : t.ofertasReanudar,
        ),
        if (puedeDuplicar)
          opcion(
            OfertasAccion.duplicar,
            Icons.content_copy_rounded,
            t.ofertasDuplicar,
          ),
        opcion(
          OfertasAccion.solicitudes,
          Icons.move_to_inbox_rounded,
          t.ofertasVerSolicitudes,
        ),
        const PopupMenuDivider(),
        opcion(
          OfertasAccion.eliminar,
          Icons.delete_outline_rounded,
          t.commonDelete,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}
