// lib/screens/alumnos/widgets/cal_al_items.dart
//
// ATENA – Calendario del alumno: ítems de la agenda (eventos y notas
// personales) y formatos compartidos por la grilla, la agenda y los detalles.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// Ítem de la agenda: un evento de una institución o una nota personal.
sealed class CalAlItem {
  const CalAlItem();
}

final class CalAlItemEvento extends CalAlItem {
  final Evento evento;

  const CalAlItemEvento(this.evento);
}

final class CalAlItemNota extends CalAlItem {
  final NotaPersonal nota;

  const CalAlItemNota(this.nota);
}

/// Color de las notas personales (puntos de la grilla e íconos).
const Color calAlColorNota = AtenaColors.neutral;

/// Primera letra en mayúscula ("octubre de 2026" → "Octubre de 2026").
String calAlCapitalizar(String s) {
  if (s.isEmpty) return s;
  final letras = s.characters;
  return letras.first.toUpperCase() + letras.skip(1).string;
}

/// Hora de una nota ("HH:MM") o null si no tiene.
TimeOfDay? calAlHoraNota(NotaPersonal nota) {
  final partes = nota.hora.trim().split(':');
  if (partes.length != 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return TimeOfDay(hour: h, minute: m);
}

/// Hora en el formato del dispositivo ("14:30" o "2:30 PM").
String calAlHoraTexto(BuildContext context, TimeOfDay hora) =>
    AtenaFormat.hora(context, DateTime(2000, 1, 1, hora.hour, hora.minute));

/// Minutos desde la medianoche para ordenar la agenda de [dia]
/// (-1 = todo el día o sin hora).
int calAlMinutos(CalAlItem item, DateTime dia) {
  switch (item) {
    case CalAlItemEvento(:final evento):
      if (evento.todoElDia || !DateUtils.isSameDay(evento.inicio, dia)) {
        return -1;
      }
      return evento.inicio.hour * 60 + evento.inicio.minute;
    case CalAlItemNota(:final nota):
      final hora = calAlHoraNota(nota);
      return hora == null ? -1 : hora.hour * 60 + hora.minute;
  }
}

/// Orden de la agenda de [dia]: primero lo de todo el día, después por hora;
/// a igual hora, los eventos antes que las notas.
int calAlComparar(CalAlItem a, CalAlItem b, DateTime dia) {
  final porHora = calAlMinutos(a, dia).compareTo(calAlMinutos(b, dia));
  if (porHora != 0) return porHora;
  int tipo(CalAlItem i) => i is CalAlItemEvento ? 0 : 1;
  return tipo(a).compareTo(tipo(b));
}

/// Fechas del evento: "Viernes, 2 de octubre de 2026" o "Del 3 oct. al 7 oct.".
String calAlFechasEvento(BuildContext context, Evento e) {
  if (DateUtils.isSameDay(e.inicio, e.finEfectivo)) {
    return calAlCapitalizar(AtenaFormat.fechaLarga(context, e.inicio));
  }
  return AppLocalizations.of(context).calAlRango(
    AtenaFormat.fechaCorta(context, e.inicio),
    AtenaFormat.fechaCorta(context, e.finEfectivo),
  );
}

/// Horario del evento: "Todo el día", "14:30" o "14:30 – 16:00".
String calAlHorarioEvento(BuildContext context, Evento e) {
  if (e.todoElDia) return AppLocalizations.of(context).calAlTodoElDia;
  final desde = AtenaFormat.hora(context, e.inicio);
  final fin = e.fin;
  if (fin == null || fin == e.inicio) return desde;
  return '$desde – ${AtenaFormat.hora(context, fin)}';
}

/// Resumen para listas: el horario si dura un día, el rango si dura varios.
String calAlCuandoCorto(BuildContext context, Evento e) =>
    DateUtils.isSameDay(e.inicio, e.finEfectivo)
    ? calAlHorarioEvento(context, e)
    : calAlFechasEvento(context, e);

Color calAlColorAsistencia(Asistencia a) => switch (a) {
  Asistencia.asistire => AtenaColors.success,
  Asistencia.talVez => AtenaColors.warning,
  Asistencia.noAsistire => AtenaColors.danger,
};

IconData calAlIconoAsistencia(Asistencia a) => switch (a) {
  Asistencia.asistire => Icons.check_circle_rounded,
  Asistencia.talVez => Icons.help_rounded,
  Asistencia.noAsistire => Icons.cancel_rounded,
};

/// Caja con el día y el mes abreviado (lista de próximos).
class CalAlCajaFecha extends StatelessWidget {
  final DateTime fecha;
  final Color color;

  const CalAlCajaFecha({super.key, required this.fecha, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = AtenaTone.of(context, color);
    final mes = AtenaFormat.mesAnio(
      context,
      fecha,
    ).split(' ').first.characters.take(3).string.toUpperCase();

    return Semantics(
      label: calAlCapitalizar(AtenaFormat.fechaLarga(context, fecha)),
      excludeSemantics: true,
      child: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.sm)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${fecha.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              mes,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tone.foreground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de un evento en la agenda.
class CalAlEventoTile extends StatelessWidget {
  final Evento evento;

  /// Respuesta de asistencia guardada (solo cuenta si el evento la pide).
  final Asistencia? respuesta;

  /// Día a mostrar en la caja de fecha (lista de próximos). Null = ícono.
  final DateTime? fecha;

  final VoidCallback onTap;

  const CalAlEventoTile({
    super.key,
    required this.evento,
    required this.respuesta,
    required this.onTap,
    this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = colorTipoEvento(evento.tipo);
    final dia = fecha;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            if (dia == null)
              AtenaIconBadge(
                icon: iconoTipoEvento(evento.tipo),
                color: color,
                size: 46,
              )
            else
              CalAlCajaFecha(fecha: dia, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.tipoEvento(evento.tipo)} · ${evento.institucionNombre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  _LineaIcono(
                    icon: Icons.schedule_rounded,
                    texto: calAlCuandoCorto(context, evento),
                  ),
                  if (evento.pideConfirmacion) ...[
                    const SizedBox(height: 8),
                    _ChipAsistencia(respuesta: respuesta),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
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

enum _AccionNota { editar, eliminar }

/// Fila de una nota personal en la agenda.
class CalAlNotaTile extends StatelessWidget {
  final NotaPersonal nota;

  /// Día a mostrar en la caja de fecha (lista de próximos). Null = ícono.
  final DateTime? fecha;

  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const CalAlNotaTile({
    super.key,
    required this.nota,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
    this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hora = calAlHoraNota(nota);
    final detalle = nota.detalle.trim();
    final dia = fecha;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          children: [
            if (dia == null)
              const AtenaIconBadge(
                icon: Icons.sticky_note_2_rounded,
                color: calAlColorNota,
                size: 46,
              )
            else
              CalAlCajaFecha(fecha: dia, color: calAlColorNota),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nota.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      t.calAlNotaPersonal,
                      if (hora != null) calAlHoraTexto(context, hora),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (detalle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<_AccionNota>(
              tooltip: t.uiMoreOptions,
              icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
              onSelected: (accion) {
                switch (accion) {
                  case _AccionNota.editar:
                    onEditar();
                  case _AccionNota.eliminar:
                    onEliminar();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _AccionNota.editar,
                  child: ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: Text(t.calAlEditarNota),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _AccionNota.eliminar,
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: cs.error,
                    ),
                    title: Text(
                      t.calAlEliminarNota,
                      style: TextStyle(color: cs.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaIcono extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LineaIcono({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
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

class _ChipAsistencia extends StatelessWidget {
  final Asistencia? respuesta;

  const _ChipAsistencia({required this.respuesta});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final r = respuesta;
    // Se achica si no entra (pantallas angostas con letra grande).
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: r == null
          ? AtenaStatusChip(
              label: t.calAlResponder,
              color: Theme.of(context).colorScheme.primary,
              icon: Icons.how_to_reg_rounded,
              dense: true,
            )
          : AtenaStatusChip(
              label: t.asistencia(r),
              color: calAlColorAsistencia(r),
              icon: calAlIconoAsistencia(r),
              dense: true,
            ),
    );
  }
}
