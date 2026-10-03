// lib/screens/instituciones/widgets/com_inst_tarjetas.dart
//
// ATENA – Tarjetas de Comunicaciones: evento del calendario y aviso enviado,
// más la hoja con el aviso completo.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'com_inst_comunes.dart';

/// Evento del calendario: fecha, tipo, horario, lugar, destinatarios y, si
/// pide confirmación, el resumen de respuestas.
class ComInstEventoCard extends StatelessWidget {
  final Evento evento;
  final String destinatarios;

  /// Respuestas de asistencia (null si el evento no pide confirmación).
  final List<RespuestaEvento>? respuestas;
  final VoidCallback onTap;

  const ComInstEventoCard({
    super.key,
    required this.evento,
    required this.destinatarios,
    required this.respuestas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = evento;
    final color = colorTipoEvento(e.tipo);
    final ahora = DateTime.now();
    final fin = e.fin;
    final variosDias = fin != null && !DateUtils.isSameDay(e.inicio, fin);
    final lugar = e.lugar.trim();
    final resp = respuestas;

    // Cuándo ocurre respecto de hoy: en curso, hoy o mañana.
    final (String, Color, IconData)? momento = comInstEventoEnCurso(e, ahora)
        ? (t.comInstEnCurso, AtenaColors.success, Icons.play_circle_rounded)
        : DateUtils.isSameDay(e.inicio, ahora)
        ? (t.uiToday, AtenaColors.success, Icons.today_rounded)
        : DateUtils.isSameDay(e.inicio, ahora.add(const Duration(days: 1)))
        ? (t.uiTomorrow, AtenaColors.info, Icons.event_rounded)
        : null;

    return AtenaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComInstFechaBloque(fecha: e.inicio, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InstAjustable(
                      child: AtenaStatusChip(
                        label: t.tipoEvento(e.tipo),
                        color: color,
                        icon: iconoTipoEvento(e.tipo),
                        dense: true,
                      ),
                    ),
                    if (momento != null)
                      InstAjustable(
                        child: AtenaStatusChip(
                          label: momento.$1,
                          color: momento.$2,
                          icon: momento.$3,
                          dense: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  e.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                ComInstLinea(
                  icon: Icons.schedule_rounded,
                  texto: e.todoElDia
                      ? t.comInstTodoElDia
                      : AtenaFormat.hora(context, e.inicio),
                ),
                if (variosDias)
                  ComInstLinea(
                    icon: Icons.date_range_rounded,
                    texto: t.comInstRangoFechas(
                      AtenaFormat.fechaCorta(context, e.inicio),
                      AtenaFormat.fechaCorta(context, fin),
                    ),
                  ),
                if (lugar.isNotEmpty)
                  ComInstLinea(icon: Icons.place_outlined, texto: lugar),
                ComInstLinea(icon: Icons.groups_outlined, texto: destinatarios),
                if (resp != null) ...[
                  const SizedBox(height: 10),
                  ComInstResumenAsistencia(respuestas: resp),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso enviado: título, fecha, extracto, destinatarios y alcance.
class ComInstAvisoCard extends StatelessWidget {
  final Aviso aviso;
  final String destinatarios;
  final VoidCallback onTap;

  const ComInstAvisoCard({
    super.key,
    required this.aviso,
    required this.destinatarios,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtenaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AtenaIconBadge(
                icon: Icons.campaign_rounded,
                color: AtenaColors.goldDeep,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aviso.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AtenaFormat.haceTiempo(context, aviso.fecha),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            aviso.mensaje,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          ComInstLinea(icon: Icons.groups_outlined, texto: destinatarios),
          const SizedBox(height: 10),
          _AlcanceChip(cantidad: aviso.destinatarios),
        ],
      ),
    );
  }
}

class _AlcanceChip extends StatelessWidget {
  final int cantidad;

  const _AlcanceChip({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final llego = cantidad > 0;
    return InstAjustable(
      child: AtenaStatusChip(
        label: t.comInstAvisoAlcance(cantidad),
        color: llego ? AtenaColors.success : AtenaColors.neutral,
        icon: llego ? Icons.mark_email_read_rounded : Icons.group_off_rounded,
        dense: true,
      ),
    );
  }
}

/// Muestra el aviso completo en una hoja.
Future<void> showComInstAvisoDetalle(
  BuildContext context, {
  required Aviso aviso,
  required String destinatarios,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) {
      final t = AppLocalizations.of(ctx);
      final theme = Theme.of(ctx);
      final cuando =
          '${AtenaFormat.fechaLarga(ctx, aviso.fecha)} · '
          '${AtenaFormat.hora(ctx, aviso.fecha)}';
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtenaIconBadge(
              icon: Icons.campaign_rounded,
              color: AtenaColors.goldDeep,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(aviso.titulo, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(t.comInstEnviadoEl(cuando), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            _AlcanceChip(cantidad: aviso.destinatarios),
            const SizedBox(height: 4),
            ComInstLinea(
              icon: Icons.groups_outlined,
              texto: destinatarios,
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            SelectableText(aviso.mensaje, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(t.uiClose),
              ),
            ),
          ],
        ),
      );
    },
  );
}
