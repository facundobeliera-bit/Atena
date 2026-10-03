// lib/screens/alumnos/widgets/sol_al_widgets.dart
//
// ATENA – Piezas de las solicitudes del alumno: tarjeta de la lista, cita
// con la respuesta de la institución y línea de tiempo del seguimiento.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// Título de cada paso del seguimiento.
String solAlTituloHito(AppLocalizations t, EstadoSolicitud e) => switch (e) {
  EstadoSolicitud.pendiente => t.solAlHitoEnviada,
  EstadoSolicitud.confirmada => t.solAlHitoConfirmada,
  EstadoSolicitud.rechazada => t.solAlHitoRechazada,
  EstadoSolicitud.canceladaPorAlumno => t.solAlHitoCancelada,
  EstadoSolicitud.canceladaPorInstitucion => t.solAlHitoBaja,
};

/// Nombre de la institución de una solicitud. Si falta, usa un genérico
/// ("la institución"), con mayúscula cuando abre la oración.
String solAlInstitucion(
  AppLocalizations t,
  Solicitud s, {
  bool inicio = false,
}) {
  final nombre = s.institucionNombre.trim();
  if (nombre.isNotEmpty) return nombre;
  final generico = t.solAlLaInstitucion;
  if (!inicio || generico.isEmpty) return generico;
  return generico[0].toUpperCase() + generico.substring(1);
}

/// Tarjeta de una solicitud en "Mis solicitudes".
class SolAlSolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const SolAlSolicitudCard({
    super.key,
    required this.solicitud,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = solicitud;
    final color = colorEstadoSolicitud(s.estado);
    final respuesta = s.respuesta.trim();
    final mostrarRespuesta =
        respuesta.isNotEmpty &&
        (s.estado == EstadoSolicitud.rechazada ||
            s.estado == EstadoSolicitud.canceladaPorInstitucion);

    return AtenaCard(
      onTap: onTap,
      borderColor: s.estado == EstadoSolicitud.confirmada
          ? AtenaBrand.of(context).success.withValues(alpha: 0.45)
          : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtenaIconBadge(icon: iconoOferta(s.oferta), size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solAlInstitucion(t, s, inicio: true),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.ofertaNombre} · ${t.categoriaOferta(s.oferta)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AtenaStatusChip(
                      label: t.estadoSolicitud(s.estado),
                      color: color,
                      icon: iconoEstadoSolicitud(s.estado),
                      dense: true,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AtenaFormat.haceTiempo(context, s.actualizadaEl),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                if (mostrarRespuesta) ...[
                  const SizedBox(height: 12),
                  SolAlCita(
                    titulo: t.solAlRespuestaDe(solAlInstitucion(t, s)),
                    texto: respuesta,
                    color: color,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje citado (respuesta de la institución o mensaje del alumno).
class SolAlCita extends StatelessWidget {
  final String titulo;
  final String texto;
  final Color color;
  final int? maxLines;
  final IconData icon;

  const SolAlCita({
    super.key,
    required this.titulo,
    required this.texto,
    required this.color,
    this.maxLines,
    this.icon = Icons.format_quote_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tono = AtenaTone.of(context, color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: tono.background,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.sm)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tono.foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tono.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Seguimiento de la solicitud: un paso por cada cambio de estado.
class SolAlLineaDeTiempo extends StatelessWidget {
  /// Cambios en orden cronológico (el último es el estado actual).
  final List<CambioEstado> hitos;

  const SolAlLineaDeTiempo({super.key, required this.hitos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < hitos.length; i++)
          _Hito(cambio: hitos[i], ultimo: i == hitos.length - 1),
      ],
    );
  }
}

class _Hito extends StatelessWidget {
  final CambioEstado cambio;
  final bool ultimo;

  const _Hito({required this.cambio, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Un envío ya respondido deja de estar "en espera": se muestra como hecho.
    final enviada = cambio.estado == EstadoSolicitud.pendiente && !ultimo;
    final tono = AtenaTone.of(
      context,
      enviada ? AtenaColors.info : colorEstadoSolicitud(cambio.estado),
    );
    final icono = enviada
        ? Icons.send_rounded
        : iconoEstadoSolicitud(cambio.estado);
    final nota = cambio.nota.trim();
    final cuando =
        '${AtenaFormat.fechaCorta(context, cambio.fecha)} · '
        '${AtenaFormat.hora(context, cambio.fecha)}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tono.background,
                    shape: BoxShape.circle,
                    border: ultimo
                        ? Border.all(color: tono.foreground, width: 1.5)
                        : null,
                  ),
                  child: Icon(icono, size: 17, color: tono.foreground),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cs.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: ultimo ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    solAlTituloHito(t, cambio.estado),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(cuando, style: theme.textTheme.bodySmall),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(nota, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
