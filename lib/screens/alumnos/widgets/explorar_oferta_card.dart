// lib/screens/alumnos/widgets/explorar_oferta_card.dart
//
// ATENA – Tarjeta de una vacante (oferta) en la ficha pública de la
// institución: datos del curso o actividad, ocupación y la acción para pedir
// vacante o ver la solicitud que ya está en curso.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'explorar_comun.dart';

class ExplorarOfertaCard extends StatelessWidget {
  final OfertaConCupo item;

  /// Solicitud activa del alumno para esta oferta (si la hay).
  final Solicitud? solicitud;

  /// Para avisar si la edad del alumno no coincide con la oferta.
  final ExplorarAlumnoEdad? alumno;
  final VoidCallback onPedir;
  final VoidCallback onVerSolicitud;

  const ExplorarOfertaCard({
    super.key,
    required this.item,
    required this.solicitud,
    required this.alumno,
    required this.onPedir,
    required this.onVerSolicitud,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final o = item.oferta;
    final s = solicitud;
    final a = alumno;

    final horario = o.horario.trim();
    final dias = o.dias.trim();
    final arancel = o.arancel.trim();
    final descripcion = o.descripcion.trim();
    final rango = explorarRangoEdad(t, o.edadMinima, o.edadMaxima);
    final fueraDeEdad = a != null && !o.aceptaEdad(a.edad);
    final aviso = AtenaBrand.of(context).warning;

    final accion = s != null
        ? OutlinedButton.icon(
            onPressed: onVerSolicitud,
            icon: const Icon(Icons.assignment_rounded),
            label: Text(t.explorarVerSolicitud),
          )
        : FilledButton.icon(
            onPressed: item.completa ? null : onPedir,
            icon: Icon(
              item.completa ? Icons.event_busy_rounded : Icons.send_rounded,
            ),
            label: Text(item.completa ? t.lblCupos(0) : t.explorarPedirVacante),
          );

    return AtenaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(icon: iconoOferta(o), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.nombreCompleto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.categoriaOferta(o),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (s != null) ...[
                const SizedBox(width: 8),
                AtenaStatusChip(
                  label: t.estadoSolicitud(s.estado),
                  color: colorEstadoSolicitud(s.estado),
                  icon: iconoEstadoSolicitud(s.estado),
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              ExplorarDato(
                icon: Icons.schedule_rounded,
                texto: [
                  t.turno(o.turno),
                  if (horario.isNotEmpty) horario,
                ].join(' · '),
              ),
              if (dias.isNotEmpty)
                ExplorarDato(icon: Icons.calendar_month_rounded, texto: dias),
              if (rango.isNotEmpty)
                ExplorarDato(
                  icon: Icons.cake_rounded,
                  texto: rango,
                  color: fueraDeEdad ? aviso : null,
                ),
              if (arancel.isNotEmpty)
                ExplorarDato(
                  icon: Icons.payments_rounded,
                  texto: t.explorarArancel(arancel),
                ),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              descripcion,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (a != null && fueraDeEdad) ...[
            const SizedBox(height: 12),
            _AvisoEdad(texto: t.explorarFueraDeEdad(a.nombre), color: aviso),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final ocupacion = _Ocupacion(item: item);
              if (c.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [ocupacion, const SizedBox(height: 14), accion],
                );
              }
              return Row(
                children: [
                  Expanded(child: ocupacion),
                  const SizedBox(width: 24),
                  accion,
                ],
              );
            },
          ),
        ],
      ),
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
    final cs = theme.colorScheme;
    final brand = AtenaBrand.of(context);
    final total = item.oferta.cupoTotal;
    final libres = item.disponibles;
    final pocas = !item.completa && libres <= (total * 0.2).ceil();

    final color = item.completa
        ? cs.outline
        : pocas
        ? brand.warning
        : cs.primary;
    final texto = item.completa
        ? t.explorarCompleto
        : t.lblCuposDeTotal(libres, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              item.completa ? Icons.lock_rounded : Icons.event_seat_rounded,
              size: 16,
              color: item.completa ? cs.onSurfaceVariant : color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: item.completa ? cs.onSurfaceVariant : cs.onSurface,
                ),
              ),
            ),
            if (pocas)
              AtenaStatusChip(
                label: t.explorarUltimasVacantes,
                color: AtenaColors.warning,
                icon: Icons.local_fire_department_rounded,
                dense: true,
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: item.ocupacion,
          color: color,
          backgroundColor: cs.surfaceContainerHighest,
          semanticsLabel: t.explorarOcupacion,
        ),
      ],
    );
  }
}

class _AvisoEdad extends StatelessWidget {
  final String texto;
  final Color color;

  const _AvisoEdad({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    final tono = AtenaTone.of(context, color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tono.background,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.sm)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: tono.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tono.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
