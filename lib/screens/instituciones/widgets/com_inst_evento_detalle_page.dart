// lib/screens/instituciones/widgets/com_inst_evento_detalle_page.dart
//
// ATENA – Detalle de un evento del calendario de la institución:
// datos, destinatarios y respuestas de asistencia de las familias.
// Permite editarlo (sin volver a notificar) y eliminarlo.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'com_inst_comunes.dart';
import 'com_inst_evento_form_page.dart';

class ComInstEventoDetallePage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final Evento evento;
  final List<OfertaConCupo> ofertas;

  const ComInstEventoDetallePage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.evento,
    required this.ofertas,
  });

  @override
  Widget build(BuildContext context) => AtenaRoleTheme(
    role: AtenaRole.institucion,
    child: _EventoDetalle(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      evento: evento,
      ofertas: ofertas,
    ),
  );
}

class _EventoDetalle extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final Evento evento;
  final List<OfertaConCupo> ofertas;

  const _EventoDetalle({
    required this.institucionId,
    required this.institucionNombre,
    required this.evento,
    required this.ofertas,
  });

  @override
  State<_EventoDetalle> createState() => _EventoDetalleState();
}

class _EventoDetalleState extends State<_EventoDetalle> {
  late Evento _evento = widget.evento;
  late final InstAutoRecarga _recarga;

  List<RespuestaEvento> _respuestas = const [];
  int _alcance = 0;
  int _sinResponder = 0;
  int _carga = 0;
  bool _loading = true;
  bool _noDisponible = false;
  bool _eliminando = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _recarga = InstAutoRecarga(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  void _alCambiarDatos() {
    if (mounted && !_eliminando) _load();
  }

  static int _ordenRespuestas(RespuestaEvento a, RespuestaEvento b) {
    if (a.asistencia != b.asistencia) {
      return a.asistencia.index.compareTo(b.asistencia.index);
    }
    return normalizarBusqueda(
      a.alumnoNombre,
    ).compareTo(normalizarBusqueda(b.alumnoNombre));
  }

  Future<void> _load() async {
    // Si llega otra recarga mientras tanto, gana la más nueva.
    final carga = ++_carga;
    try {
      final repo = CalendarioRepo.instance;
      final actual = await repo.evento(widget.institucionId, _evento.id);
      if (actual == null) {
        if (!mounted || carga != _carga) return;
        setState(() {
          _noDisponible = true;
          _loading = false;
        });
        return;
      }
      final respuestas = await repo.respuestas(widget.institucionId, actual.id);
      final destinatarios = await repo.destinatarios(
        widget.institucionId,
        actual.ofertaIds,
      );
      final respondieron = {for (final r in respuestas) r.perfilId};
      respuestas.sort(_ordenRespuestas);

      if (!mounted || carga != _carga) return;
      setState(() {
        _evento = actual;
        _respuestas = respuestas;
        _alcance = destinatarios.length;
        _sinResponder = destinatarios
            .where((a) => !respondieron.contains(a.perfilId))
            .length;
        _noDisponible = false;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || carga != _carga) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _editar() async {
    final guardado = await Navigator.of(context).push<Evento>(
      MaterialPageRoute(
        builder: (_) => ComInstEventoFormPage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          ofertas: widget.ofertas,
          evento: _evento,
        ),
      ),
    );
    if (!mounted) return;
    if (guardado != null) setState(() => _evento = guardado);
    await _load();
  }

  Future<void> _eliminar() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.comInstEliminarEventoTitulo,
      message: t.comInstEliminarEventoMensaje,
      confirmLabel: t.commonDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await CalendarioRepo.instance.eliminarEvento(
        widget.institucionId,
        _evento.id,
      );
      if (!mounted) return;
      AtenaFeedback.success(context, t.comInstEventoEliminado);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ocupado = _loading || _eliminando;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.comInstDetalleTitulo,
        subtitle: widget.institucionNombre,
        actions: _noDisponible
            ? null
            : [
                IconButton(
                  tooltip: t.comInstEditarEvento,
                  onPressed: ocupado ? null : _editar,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: t.comInstEliminarEvento,
                  onPressed: ocupado ? null : _eliminar,
                  icon: _eliminando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                ),
              ],
      ),
      body: _noDisponible
          ? AtenaEmptyState(
              icon: Icons.event_busy_rounded,
              title: t.comInstEventoNoDisponible,
              message: t.comInstEventoNoDisponibleMensaje,
              action: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.commonBack),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: atenaPagePadding(context, maxWidth: 720),
                children: [
                  _Encabezado(evento: _evento),
                  const SizedBox(height: 12),
                  _Datos(
                    evento: _evento,
                    destinatarios: comInstTextoDestinatarios(
                      t,
                      _evento.ofertaIds,
                      comInstOfertasPorId(widget.ofertas),
                      completo: true,
                    ),
                    alcance: _loading || _error != null ? null : _alcance,
                  ),
                  const SizedBox(height: 16),
                  ..._seccionRespuestas(context),
                ],
              ),
            ),
    );
  }

  List<Widget> _seccionRespuestas(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;

    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: AtenaLoading(),
        ),
      ];
    }
    if (error != null) {
      return [
        AtenaErrorState(
          message: coreErrorText(t, error),
          onRetry: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _load();
          },
        ),
      ];
    }
    if (!_evento.pideConfirmacion) {
      return [
        AtenaBanner(
          icon: Icons.how_to_reg_outlined,
          message: t.comInstNoPideConfirmacion,
        ),
      ];
    }

    return [
      AtenaSectionHeader(
        title: t.comInstRespuestasTitulo,
        subtitle: t.comInstRespuestasConteo(_respuestas.length),
      ),
      _ResumenRespuestas(
        conteo: comInstConteoAsistencia(_respuestas),
        sinResponder: _sinResponder,
      ),
      const SizedBox(height: 12),
      if (_respuestas.isEmpty)
        AtenaCard(
          child: Row(
            children: [
              const AtenaIconBadge(icon: Icons.how_to_reg_rounded),
              const SizedBox(width: 14),
              Expanded(child: Text(t.comInstSinRespuestasDetalle)),
            ],
          ),
        )
      else
        AtenaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _respuestas.length; i++) ...[
                if (i > 0) const Divider(indent: 70),
                _RespuestaTile(respuesta: _respuestas[i]),
              ],
            ],
          ),
        ),
    ];
  }
}

class _Encabezado extends StatelessWidget {
  final Evento evento;

  const _Encabezado({required this.evento});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = colorTipoEvento(evento.tipo);
    final enCurso = comInstEventoEnCurso(evento, DateTime.now());

    return AtenaCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComInstFechaBloque(fecha: evento.inicio, color: color, size: 64),
          const SizedBox(width: 16),
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
                        label: t.tipoEvento(evento.tipo),
                        color: color,
                        icon: iconoTipoEvento(evento.tipo),
                      ),
                    ),
                    if (enCurso)
                      InstAjustable(
                        child: AtenaStatusChip(
                          label: t.comInstEnCurso,
                          color: AtenaColors.success,
                          icon: Icons.play_circle_rounded,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(evento.titulo, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Datos extends StatelessWidget {
  final Evento evento;
  final String destinatarios;

  /// Alumnos alcanzados (null mientras se calcula).
  final int? alcance;

  const _Datos({
    required this.evento,
    required this.destinatarios,
    required this.alcance,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = evento;
    final fin = e.fin;
    final variosDias = fin != null && !DateUtils.isSameDay(e.inicio, fin);
    final lugar = e.lugar.trim();
    final descripcion = e.descripcion.trim();
    final n = alcance;

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtenaInfoRow(
            icon: Icons.event_rounded,
            label: t.comInstInfoFecha,
            value: variosDias
                ? t.comInstRangoFechas(
                    AtenaFormat.fechaLarga(context, e.inicio),
                    AtenaFormat.fechaLarga(context, fin),
                  )
                : comInstCapitalizar(AtenaFormat.fechaLarga(context, e.inicio)),
          ),
          AtenaInfoRow(
            icon: Icons.schedule_rounded,
            label: t.comInstInfoHorario,
            value: e.todoElDia
                ? t.comInstTodoElDia
                : AtenaFormat.hora(context, e.inicio),
          ),
          if (lugar.isNotEmpty)
            AtenaInfoRow(
              icon: Icons.place_outlined,
              label: t.comInstInfoLugar,
              value: lugar,
            ),
          AtenaInfoRow(
            icon: Icons.groups_outlined,
            label: t.comInstSeccionDestinatarios,
            value: destinatarios,
          ),
          if (n != null)
            AtenaInfoRow(
              icon: Icons.notifications_active_outlined,
              label: t.comInstInfoAlcance,
              value: t.comInstAlumnosConfirmados(n),
            ),
          if (descripcion.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            Text(t.comInstInfoDescripcion, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            SelectableText(descripcion, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 10),
          Text(
            t.comInstPublicadoEl(AtenaFormat.fechaCorta(context, e.creadoEl)),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Totales de asistencia: asistirán, tal vez, no asistirán y sin responder.
class _ResumenRespuestas extends StatelessWidget {
  final Map<Asistencia, int> conteo;
  final int sinResponder;

  const _ResumenRespuestas({required this.conteo, required this.sinResponder});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cajas = [
      for (final a in Asistencia.values)
        _Total(
          valor: conteo[a] ?? 0,
          label: switch (a) {
            Asistencia.asistire => t.comInstStatAsistiran,
            Asistencia.talVez => t.comInstStatTalVez,
            Asistencia.noAsistire => t.comInstStatNoAsistiran,
          },
          icon: comInstIconoAsistencia(a),
          color: comInstColorAsistencia(a),
        ),
      _Total(
        valor: sinResponder,
        label: t.comInstStatSinResponder,
        icon: Icons.hourglass_empty_rounded,
        color: AtenaColors.neutral,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final porFila = c.maxWidth < 460 ? 2 : 4;
        final ancho = (c.maxWidth - gap * (porFila - 1)) / porFila;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final caja in cajas) SizedBox(width: ancho, child: caja),
          ],
        );
      },
    );
  }
}

class _Total extends StatelessWidget {
  final int valor;
  final String label;
  final IconData icon;
  final Color color;

  const _Total({
    required this.valor,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = AtenaTone.of(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.md)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valor',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tone.foreground,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tone.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RespuestaTile extends StatelessWidget {
  final RespuestaEvento respuesta;

  const _RespuestaTile({required this.respuesta});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = respuesta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          AtenaAvatar(name: r.alumnoNombre, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.alumnoNombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InstAjustable(
                      child: AtenaStatusChip(
                        label: t.asistencia(r.asistencia),
                        color: comInstColorAsistencia(r.asistencia),
                        icon: comInstIconoAsistencia(r.asistencia),
                        dense: true,
                      ),
                    ),
                    Text(
                      AtenaFormat.haceTiempo(context, r.fecha),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
