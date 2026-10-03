// lib/screens/alumnos/widgets/cal_al_mes.dart
//
// ATENA – Calendario del alumno: vista de mes.
// Grilla con las iniciales de los días según el idioma, navegación entre
// meses (flechas o deslizando), día de hoy y día elegido resaltados, y
// puntos de color por evento o nota personal.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_ui.dart';
import 'cal_al_items.dart';

/// Marcas de un día: colores de los puntos (hasta tres) y cantidad de ítems.
class CalAlMarcasDia {
  final List<Color> colores;
  final int cantidad;

  const CalAlMarcasDia({required this.colores, required this.cantidad});
}

const double _altoCelda = 52;

class CalAlMes extends StatelessWidget {
  /// Primer día del mes visible.
  final DateTime mes;

  final DateTime seleccionado;

  /// Marcas por día (fechas sin hora).
  final Map<DateTime, CalAlMarcasDia> marcas;

  final ValueChanged<DateTime> onSeleccionar;

  /// Recibe -1 (mes anterior) o 1 (mes siguiente).
  final ValueChanged<int> onCambiarMes;

  const CalAlMes({
    super.key,
    required this.mes,
    required this.seleccionado,
    required this.marcas,
    required this.onSeleccionar,
    required this.onCambiarMes,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final titulo = calAlCapitalizar(AtenaFormat.mesAnio(context, mes));

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: t.commonPrevMonth,
                onPressed: () => onCambiarMes(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.commonNextMonth,
                onPressed: () => onCambiarMes(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const _Semana(),
          const SizedBox(height: 4),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 250) return;
              onCambiarMes(v < 0 ? 1 : -1);
            },
            child: AnimatedSize(
              duration: AtenaMotion.medium,
              curve: AtenaMotion.curve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AtenaMotion.medium,
                switchInCurve: AtenaMotion.curve,
                child: _Grilla(
                  key: ValueKey(mes),
                  mes: mes,
                  seleccionado: seleccionado,
                  marcas: marcas,
                  onSeleccionar: onSeleccionar,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Iniciales de los días, empezando por el primer día de la semana local.
class _Semana extends StatelessWidget {
  const _Semana();

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelSmall;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  loc.narrowWeekdays[(loc.firstDayOfWeekIndex + i) % 7],
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Grilla extends StatelessWidget {
  final DateTime mes;
  final DateTime seleccionado;
  final Map<DateTime, CalAlMarcasDia> marcas;
  final ValueChanged<DateTime> onSeleccionar;

  const _Grilla({
    super.key,
    required this.mes,
    required this.seleccionado,
    required this.marcas,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final primero = DateTime(mes.year, mes.month);
    final desfase = (primero.weekday % 7 - loc.firstDayOfWeekIndex + 7) % 7;
    final dias = DateUtils.getDaysInMonth(mes.year, mes.month);
    final filas = ((desfase + dias) / 7).ceil();
    final hoy = DateUtils.dateOnly(DateTime.now());

    Widget celda(int numero) {
      if (numero < 1 || numero > dias) {
        return const SizedBox(height: _altoCelda);
      }
      final dia = DateTime(mes.year, mes.month, numero);
      return _Dia(
        dia: dia,
        hoy: dia == hoy,
        pasado: dia.isBefore(hoy),
        seleccionado: DateUtils.isSameDay(dia, seleccionado),
        marcas: marcas[dia],
        onTap: () => onSeleccionar(dia),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var f = 0; f < filas; f++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: celda(f * 7 + c - desfase + 1)),
            ],
          ),
      ],
    );
  }
}

class _Dia extends StatelessWidget {
  final DateTime dia;
  final bool hoy;
  final bool pasado;
  final bool seleccionado;
  final CalAlMarcasDia? marcas;
  final VoidCallback onTap;

  const _Dia({
    required this.dia,
    required this.hoy,
    required this.pasado,
    required this.seleccionado,
    required this.marcas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final oscuro = theme.brightness == Brightness.dark;
    final colores = marcas?.colores ?? const <Color>[];
    final cantidad = marcas?.cantidad ?? 0;

    final Color texto;
    if (seleccionado) {
      texto = cs.onPrimary;
    } else if (hoy) {
      texto = cs.primary;
    } else {
      texto = pasado ? cs.onSurfaceVariant : cs.onSurface;
    }

    final etiqueta = [
      if (hoy) t.uiToday,
      calAlCapitalizar(AtenaFormat.fechaLarga(context, dia)),
      if (cantidad > 0) t.calAlDiaItems(cantidad),
    ].join(', ');

    return Semantics(
      button: true,
      selected: seleccionado,
      label: etiqueta,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.md)),
        child: SizedBox(
          height: _altoCelda,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AtenaMotion.fast,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seleccionado
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0),
                  border: Border.all(
                    color: hoy && !seleccionado
                        ? cs.primary
                        : cs.primary.withValues(alpha: 0),
                    width: 1.6,
                  ),
                ),
                child: Text(
                  '${dia.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: texto,
                    fontWeight: seleccionado || hoy
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < colores.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: oscuro
                              ? AtenaTone.of(context, colores[i]).foreground
                              : colores[i],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
