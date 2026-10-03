// lib/screens/alumnos/widgets/doc_al_tarjeta.dart
//
// ATENA – Documentos del alumno: tarjeta de un pedido y piezas compartidas
// con el detalle (chips de estado, fecha más relevante).

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// true si el alumno puede subir (o reemplazar) el archivo del pedido.
bool docAlPuedeSubir(PedidoDocumento p) =>
    p.requiereAccionAlumno || p.estado == EstadoPedidoDocumento.entregado;

/// Detalle del pedido para mostrar aparte del nombre (en "Otro documento" el
/// detalle ya es el nombre).
String docAlDetalle(PedidoDocumento p) =>
    p.tipo == TipoDocumento.otro ? '' : p.detalle.trim();

IconData docAlIconoEstado(EstadoPedidoDocumento e) => switch (e) {
  EstadoPedidoDocumento.pendiente => Icons.upload_rounded,
  EstadoPedidoDocumento.entregado => Icons.hourglass_top_rounded,
  EstadoPedidoDocumento.aprobado => Icons.check_circle_rounded,
  EstadoPedidoDocumento.rechazado => Icons.report_rounded,
  EstadoPedidoDocumento.cancelado => Icons.block_rounded,
};

/// Chip del estado y, si corresponde, chip "Vencido".
class DocAlChips extends StatelessWidget {
  final PedidoDocumento pedido;

  const DocAlChips({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estado = pedido.estado;
    // Cada chip se achica si no entra (pantallas angostas con letra grande).
    Widget chip(String label, Color color, IconData icon) => FittedBox(
      fit: BoxFit.scaleDown,
      child: AtenaStatusChip(
        label: label,
        color: color,
        icon: icon,
        dense: true,
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        chip(
          t.estadoDocumento(estado),
          colorEstadoDocumento(estado),
          docAlIconoEstado(estado),
        ),
        if (pedido.vencido)
          chip(
            t.lblDocVencido,
            AtenaColors.danger,
            Icons.warning_amber_rounded,
          ),
      ],
    );
  }
}

/// Fecha más relevante del pedido: límite, entrega, aprobación o cancelación.
class DocAlLineaFecha extends StatelessWidget {
  final PedidoDocumento pedido;

  const DocAlLineaFecha({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brand = AtenaBrand.of(context);
    final p = pedido;
    String fecha(DateTime d) => AtenaFormat.fechaCorta(context, d);

    final normal = cs.onSurfaceVariant;
    final aviso = AtenaTone.of(context, brand.warning).foreground;
    final (
      String texto,
      IconData icono,
      Color color,
      bool destacar,
    ) = switch (p.estado) {
      EstadoPedidoDocumento.pendiente ||
      EstadoPedidoDocumento.rechazado => _limite(context, normal, aviso),
      EstadoPedidoDocumento.entregado => (
        t.docAlEntregadoEl(fecha(p.archivo?.subidoEl ?? p.actualizadoEl)),
        Icons.outbox_rounded,
        normal,
        false,
      ),
      EstadoPedidoDocumento.aprobado => (
        t.docAlAprobadoEl(fecha(p.actualizadoEl)),
        Icons.verified_rounded,
        AtenaTone.of(context, brand.success).foreground,
        false,
      ),
      EstadoPedidoDocumento.cancelado => (
        t.docAlCanceladoEl(fecha(p.actualizadoEl)),
        Icons.block_rounded,
        normal,
        false,
      ),
    };

    return Row(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: destacar ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );
  }

  (String, IconData, Color, bool) _limite(
    BuildContext context,
    Color normal,
    Color aviso,
  ) {
    final t = AppLocalizations.of(context);
    final p = pedido;
    final limite = p.fechaLimite;
    if (limite == null) {
      return (
        t.docAlPedidoEl(AtenaFormat.fechaCorta(context, p.creadoEl)),
        Icons.event_note_rounded,
        normal,
        false,
      );
    }
    if (p.vencido) {
      return (
        t.docAlVencio(AtenaFormat.fechaCorta(context, limite)),
        Icons.event_busy_rounded,
        Theme.of(context).colorScheme.error,
        true,
      );
    }
    final hoy = DateUtils.dateOnly(DateTime.now());
    final dia = DateUtils.dateOnly(limite);
    if (dia == hoy) return (t.docAlVenceHoy, Icons.alarm_rounded, aviso, true);
    if (dia == DateTime(hoy.year, hoy.month, hoy.day + 1)) {
      return (t.docAlVenceManiana, Icons.alarm_rounded, aviso, true);
    }
    return (
      t.docAlEntregarHasta(AtenaFormat.fechaCorta(context, limite)),
      Icons.event_rounded,
      normal,
      false,
    );
  }
}

/// Tarjeta de un pedido de documentación con su acción principal.
class DocAlTarjeta extends StatelessWidget {
  final PedidoDocumento pedido;
  final bool subiendo;
  final VoidCallback onTap;
  final VoidCallback onSubir;
  final VoidCallback onVerArchivo;

  const DocAlTarjeta({
    super.key,
    required this.pedido,
    required this.subiendo,
    required this.onTap,
    required this.onSubir,
    required this.onVerArchivo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = pedido;
    final detalle = docAlDetalle(p);
    final motivo = p.observacion.trim();
    final archivo = p.archivo;

    return AtenaCard(
      onTap: onTap,
      borderColor: p.vencido ? cs.error.withValues(alpha: 0.45) : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(
                icon: iconoDocumento(p.tipo),
                color: colorEstadoDocumento(p.estado),
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nombreDocumento(p.tipo, p.detalle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.institucionNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DocAlChips(pedido: p),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detalle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (p.estado == EstadoPedidoDocumento.rechazado) ...[
            const SizedBox(height: 12),
            AtenaBanner(
              tone: AtenaBannerTone.error,
              title: t.docAlMotivo,
              message: motivo.isEmpty ? t.docAlRechazadoSinMotivo : motivo,
            ),
          ],
          const SizedBox(height: 12),
          DocAlLineaFecha(pedido: p),
          if (archivo != null) ...[
            const SizedBox(height: 12),
            _ArchivoFila(
              archivo: archivo,
              onVer: subiendo ? null : onVerArchivo,
            ),
          ],
          if (docAlPuedeSubir(p)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DocAlBotonSubir(
                pedido: p,
                subiendo: subiendo,
                onPressed: onSubir,
                compacto: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Archivo entregado: nombre y acceso para verlo.
class _ArchivoFila extends StatelessWidget {
  final ArchivoAdjunto archivo;
  final VoidCallback? onVer;

  const _ArchivoFila({required this.archivo, required this.onVer});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.sm)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onVer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                archivo.esPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                size: 22,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  archivo.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.docAlVerArchivo,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón para subir o reemplazar el archivo, con estado de carga.
/// Es la acción principal si el pedido espera al alumno; si ya está en
/// revisión se muestra como secundaria.
class DocAlBotonSubir extends StatelessWidget {
  final PedidoDocumento pedido;
  final bool subiendo;
  final VoidCallback onPressed;

  /// Altura reducida para usarlo dentro de tarjetas.
  final bool compacto;

  const DocAlBotonSubir({
    super.key,
    required this.pedido,
    required this.subiendo,
    required this.onPressed,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final reemplazar = pedido.archivo != null;
    final label = Text(
      subiendo
          ? t.docAlSubiendo
          : (reemplazar ? t.docAlReemplazarArchivo : t.docAlSubirArchivo),
    );
    final icon = subiendo
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          )
        : Icon(reemplazar ? Icons.sync_rounded : Icons.upload_rounded);
    final minimo = compacto ? const Size(0, 44) : null;
    final onTap = subiendo ? null : onPressed;

    if (pedido.requiereAccionAlumno) {
      return FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(minimumSize: minimo),
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(minimumSize: minimo),
      icon: icon,
      label: label,
    );
  }
}

/// Fila compacta para el historial (pedidos cancelados).
class DocAlFilaCompacta extends StatelessWidget {
  final PedidoDocumento pedido;
  final VoidCallback onTap;

  const DocAlFilaCompacta({
    super.key,
    required this.pedido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = pedido;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            AtenaIconBadge(
              icon: iconoDocumento(p.tipo),
              color: AtenaColors.neutral,
              size: 40,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nombreDocumento(p.tipo, p.detalle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.institucionNombre} · '
                    '${t.docAlCanceladoEl(AtenaFormat.fechaCorta(context, p.actualizadoEl))}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
