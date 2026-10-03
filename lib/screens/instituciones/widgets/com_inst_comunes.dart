// lib/screens/instituciones/widgets/com_inst_comunes.dart
//
// ATENA – Piezas compartidas de Comunicaciones (calendario y avisos):
// textos de destinatarios, conteo de alcance, bloque de fecha, resumen de
// asistencia, selector de destinatarios y vista previa del alcance.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// Ofertas indexadas por id (para mostrar los nombres de los destinatarios).
Map<String, Oferta> comInstOfertasPorId(List<OfertaConCupo> ofertas) => {
  for (final o in ofertas) o.oferta.id: o.oferta,
};

/// "Todos los alumnos" o los nombres de las ofertas destinatarias.
/// Si [completo] es false, abrevia la lista cuando son más de tres.
String comInstTextoDestinatarios(
  AppLocalizations t,
  List<String> ofertaIds,
  Map<String, Oferta> ofertas, {
  bool completo = false,
}) {
  if (ofertaIds.isEmpty) return t.comInstParaTodos;
  final nombres = {
    for (final id in ofertaIds)
      ofertas[id]?.nombreCompleto ?? t.comInstOfertaEliminada,
  }.toList();
  if (completo || nombres.length <= 3) return nombres.join(', ');
  return t.comInstYMas(nombres.take(2).join(', '), nombres.length - 2);
}

/// Primera letra en mayúscula ("octubre de 2026" → "Octubre de 2026").
String comInstCapitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Mes abreviado en mayúsculas ("OCT", "OUT", "SEP").
String comInstMesCorto(BuildContext context, DateTime fecha) {
  final mes = MaterialLocalizations.of(
    context,
  ).formatMonthYear(fecha).split(' ').first;
  return (mes.length <= 3 ? mes : mes.substring(0, 3)).toUpperCase();
}

/// true si el evento terminó antes de hoy.
bool comInstEventoPasado(Evento e, DateTime ahora) =>
    DateUtils.dateOnly(e.finEfectivo).isBefore(DateUtils.dateOnly(ahora));

/// true si el evento empezó antes de hoy y todavía no terminó.
bool comInstEventoEnCurso(Evento e, DateTime ahora) =>
    DateUtils.dateOnly(e.inicio).isBefore(DateUtils.dateOnly(ahora)) &&
    !comInstEventoPasado(e, ahora);

Color comInstColorAsistencia(Asistencia a) => switch (a) {
  Asistencia.asistire => AtenaColors.success,
  Asistencia.talVez => AtenaColors.warning,
  Asistencia.noAsistire => AtenaColors.danger,
};

IconData comInstIconoAsistencia(Asistencia a) => switch (a) {
  Asistencia.asistire => Icons.check_circle_rounded,
  Asistencia.talVez => Icons.help_rounded,
  Asistencia.noAsistire => Icons.cancel_rounded,
};

/// Cantidad de respuestas por tipo de asistencia.
Map<Asistencia, int> comInstConteoAsistencia(List<RespuestaEvento> lista) {
  final conteo = {for (final a in Asistencia.values) a: 0};
  for (final r in lista) {
    conteo[r.asistencia] = (conteo[r.asistencia] ?? 0) + 1;
  }
  return conteo;
}

/// Confirmación para salir de un formulario con cambios sin guardar.
Future<bool> comInstConfirmarDescarte(BuildContext context) {
  final t = AppLocalizations.of(context);
  return showAtenaConfirm(
    context,
    title: t.comInstDescartarTitulo,
    message: t.comInstDescartarMensaje,
    confirmLabel: t.comInstDescartar,
    cancelLabel: t.comInstSeguirEditando,
    destructive: true,
    icon: Icons.edit_off_rounded,
  );
}

/// Avisa cuando cambian los datos guardados (agrupando ráfagas de escrituras)
/// para que la pantalla vuelva a cargar: así refleja lo que pasa en otras
/// pantallas y tolera datos que desaparecen (por ejemplo, una familia que
/// elimina su cuenta).
class InstAutoRecarga {
  final VoidCallback onCambio;
  Timer? _espera;

  InstAutoRecarga(this.onCambio) {
    AtenaStore.instance.revision.addListener(_programar);
  }

  void _programar() {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), onCambio);
  }

  void dispose() {
    AtenaStore.instance.revision.removeListener(_programar);
    _espera?.cancel();
  }
}

/// Achica el contenido si no entra en el ancho disponible (letra grande o
/// pantallas angostas): evita desbordes en chips de una sola línea.
class InstAjustable extends StatelessWidget {
  final Widget child;

  const InstAjustable({super.key, required this.child});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

/// Cuenta los alumnos confirmados que alcanza una selección de destinatarios.
/// Si la selección cambia mientras se calcula, el resultado anterior se
/// descarta (devuelve null).
class ComInstAlcance {
  final String institucionId;
  int _consulta = 0;

  ComInstAlcance(this.institucionId);

  /// Invalida las consultas en curso.
  void cancelar() => _consulta++;

  Future<int?> contar(List<String> ofertaIds) async {
    final consulta = ++_consulta;
    final alumnos = await CalendarioRepo.instance.destinatarios(
      institucionId,
      ofertaIds,
    );
    return consulta == _consulta ? alumnos.length : null;
  }
}

/// Bloque de calendario: día y mes abreviado con el color del tipo de evento.
class ComInstFechaBloque extends StatelessWidget {
  final DateTime fecha;
  final Color color;
  final double size;

  const ComInstFechaBloque({
    super.key,
    required this.fecha,
    required this.color,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = AtenaTone.of(context, color);
    return Semantics(
      label: AtenaFormat.fechaLarga(context, fecha),
      excludeSemantics: true,
      child: Container(
        width: size,
        padding: EdgeInsets.symmetric(vertical: size * 0.15),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${fecha.day}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
                height: 1.1,
              ),
            ),
            Text(
              comInstMesCorto(context, fecha),
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tone.foreground,
                fontSize: size * 0.19,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Línea de detalle con ícono (horario, lugar, destinatarios…).
class ComInstLinea extends StatelessWidget {
  final IconData icon;
  final String texto;
  final int maxLines;

  const ComInstLinea({
    super.key,
    required this.icon,
    required this.texto,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: soft),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: soft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen compacto de las respuestas de asistencia de un evento.
class ComInstResumenAsistencia extends StatelessWidget {
  final List<RespuestaEvento> respuestas;

  const ComInstResumenAsistencia({super.key, required this.respuestas});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (respuestas.isEmpty) {
      return ComInstLinea(
        icon: Icons.how_to_reg_outlined,
        texto: t.comInstSinRespuestas,
      );
    }
    final conteo = comInstConteoAsistencia(respuestas);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final MapEntry(key: a, value: n) in conteo.entries)
          if (n > 0)
            InstAjustable(
              child: AtenaStatusChip(
                label: switch (a) {
                  Asistencia.asistire => t.comInstAsistiran(n),
                  Asistencia.talVez => t.comInstTalVez(n),
                  Asistencia.noAsistire => t.comInstNoAsistiran(n),
                },
                color: comInstColorAsistencia(a),
                icon: comInstIconoAsistencia(a),
                dense: true,
              ),
            ),
      ],
    );
  }
}

/// Elección de destinatarios: todos los alumnos o cursos/grupos puntuales.
class ComInstDestinatariosSelector extends StatelessWidget {
  final List<OfertaConCupo> ofertas;
  final bool paraTodos;
  final Set<String> seleccion;
  final bool mostrarError;
  final bool enabled;
  final ValueChanged<bool> onParaTodosChanged;
  final ValueChanged<Set<String>> onSeleccionChanged;

  const ComInstDestinatariosSelector({
    super.key,
    required this.ofertas,
    required this.paraTodos,
    required this.seleccion,
    required this.onParaTodosChanged,
    required this.onSeleccionChanged,
    this.mostrarError = false,
    this.enabled = true,
  });

  void _cambiar(String id, bool elegida) {
    final nueva = {...seleccion};
    if (elegida) {
      nueva.add(id);
    } else {
      nueva.remove(id);
    }
    onSeleccionChanged(nueva);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hayOfertas = ofertas.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.groups_rounded),
              label: Text(t.comInstParaTodos),
              selected: paraTodos,
              showCheckmark: false,
              onSelected: enabled ? (_) => onParaTodosChanged(true) : null,
            ),
            ChoiceChip(
              avatar: const Icon(Icons.checklist_rounded),
              label: Text(t.comInstDestOfertas),
              selected: !paraTodos,
              showCheckmark: false,
              onSelected: enabled && hayOfertas
                  ? (_) => onParaTodosChanged(false)
                  : null,
            ),
          ],
        ),
        if (!hayOfertas) ...[
          const SizedBox(height: 8),
          Text(t.comInstDestSinOfertas, style: theme.textTheme.bodySmall),
        ] else if (!paraTodos) ...[
          const SizedBox(height: 12),
          Text(t.comInstDestElegirAyuda, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Material(
            color: cs.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: AtenaRadius.field,
              side: BorderSide(
                color: mostrarError ? cs.error : cs.outlineVariant,
                width: mostrarError ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < ofertas.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  CheckboxListTile(
                    value: seleccion.contains(ofertas[i].oferta.id),
                    onChanged: enabled
                        ? (v) => _cambiar(ofertas[i].oferta.id, v ?? false)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: const RoundedRectangleBorder(),
                    title: Text(
                      ofertas[i].oferta.nombreCompleto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${t.categoriaOferta(ofertas[i].oferta)} · '
                      '${t.comInstAlumnosConfirmados(ofertas[i].confirmados)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (mostrarError)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                t.comInstDestErrorVacio,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
        ],
      ],
    );
  }
}

/// Vista previa de cuántos alumnos recibirán un envío.
class ComInstAlcanceBanner extends StatelessWidget {
  final bool calculando;

  /// null = no se pudo calcular (no se muestra nada).
  final int? cantidad;
  final String Function(int n) texto;
  final String? ayuda;
  final String sinAlumnos;

  const ComInstAlcanceBanner({
    super.key,
    required this.calculando,
    required this.cantidad,
    required this.texto,
    required this.sinAlumnos,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = cantidad;
    if (calculando) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).comInstCalculando,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (n == null) return const SizedBox.shrink();
    if (n == 0) {
      return AtenaBanner(
        tone: AtenaBannerTone.warning,
        icon: Icons.group_off_rounded,
        message: sinAlumnos,
      );
    }
    final extra = (ayuda ?? '').trim();
    return AtenaBanner(
      tone: AtenaBannerTone.info,
      icon: Icons.notifications_active_rounded,
      title: extra.isEmpty ? null : texto(n),
      message: extra.isEmpty ? texto(n) : extra,
    );
  }
}
