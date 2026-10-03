// lib/screens/alumnos/alumno_calendario_page.dart
//
// ATENA – Calendario del alumno.
// Vista de mes con los eventos de las instituciones donde el alumno tiene la
// vacante confirmada y sus notas personales. Agenda del día elegido (o los
// próximos si ese día está libre), detalle de eventos con confirmación de
// asistencia, y notas propias (alta, edición y baja).
// En escritorio, el mes y la agenda se muestran lado a lado.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/cal_al_evento_sheet.dart';
import 'widgets/cal_al_items.dart';
import 'widgets/cal_al_mes.dart';
import 'widgets/cal_al_nota_sheet.dart';

class AlumnoCalendarioPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;

  /// Día a mostrar al abrir ("YYYY-MM-DD").
  final String? initialDateKey;

  /// Evento a abrir al entrar (por ejemplo, desde una notificación).
  final String? initialItemId;

  const AlumnoCalendarioPage({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
    this.initialDateKey,
    this.initialItemId,
  });

  @override
  State<AlumnoCalendarioPage> createState() => _AlumnoCalendarioPageState();
}

class _AlumnoCalendarioPageState extends State<AlumnoCalendarioPage> {
  static const int _maxProximos = 5;

  PerfilAlumno? _perfil;
  List<Evento> _eventos = const [];
  List<NotaPersonal> _notas = const [];
  Map<String, Asistencia> _respuestas = const {};

  /// Primer día del mes visible.
  late DateTime _mes;

  /// Día elegido (sin hora).
  late DateTime _dia;

  bool _loading = true;
  Object? _error;
  bool _inicioAplicado = false;
  Timer? _recarga;

  @override
  void initState() {
    super.initState();
    _irA(DateTime.now());
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _recarga?.cancel();
    super.dispose();
  }

  /// Los datos cambiaron (un evento nuevo, o la baja de una institución, que
  /// se lleva sus eventos): vuelve a cargar cuando terminan las escrituras.
  void _alCambiarDatos() {
    _recarga?.cancel();
    _recarga = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final perfil = await AlumnosRepo.instance.perfilDeCuenta(
        widget.ownerAccountId,
        widget.perfilId,
      );
      if (perfil == null) throw const AtenaException(AtenaError.noEncontrado);

      final repo = CalendarioRepo.instance;
      final eventos = await repo.eventosAlumno(widget.perfilId);
      final notas = await repo.notas(widget.perfilId);
      final conConfirmacion = eventos.where((e) => e.pideConfirmacion).toList();
      final respuestas = await Future.wait(
        conConfirmacion.map(
          (e) => repo.miRespuesta(e.institucionId, e.id, widget.perfilId),
        ),
      );

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _eventos = eventos;
        _notas = notas;
        _respuestas = {
          for (final r in respuestas)
            if (r != null) r.eventoId: r.asistencia,
        };
        _loading = false;
        _error = null;
      });
      _aplicarInicio();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Posiciona el calendario en el día o evento pedido al abrir (una vez).
  void _aplicarInicio() {
    if (_inicioAplicado) return;
    _inicioAplicado = true;

    final fecha = DateTime.tryParse((widget.initialDateKey ?? '').trim());
    final id = (widget.initialItemId ?? '').trim();

    if (id.isNotEmpty) {
      final iEvento = _eventos.indexWhere((e) => e.id == id);
      if (iEvento >= 0) {
        final evento = _eventos[iEvento];
        setState(() {
          _irA(fecha != null && evento.ocurreEl(fecha) ? fecha : evento.inicio);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _abrirEvento(evento);
        });
        return;
      }
      final iNota = _notas.indexWhere((n) => n.id == id);
      if (iNota >= 0) {
        setState(() => _irA(_notas[iNota].fecha));
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AtenaFeedback.info(
          context,
          AppLocalizations.of(context).calAlEventoNoDisponible,
        );
      });
    }
    if (fecha != null) setState(() => _irA(fecha));
  }

  void _irA(DateTime dia) {
    _dia = DateUtils.dateOnly(dia);
    _mes = DateTime(dia.year, dia.month);
  }

  void _seleccionar(DateTime dia) => setState(() => _irA(dia));

  void _irAHoy() => setState(() => _irA(DateTime.now()));

  void _cambiarMes(int delta) {
    setState(() {
      _mes = DateUtils.addMonthsToMonthDate(_mes, delta);
      final hoy = DateUtils.dateOnly(DateTime.now());
      final esEsteMes = _mes.year == hoy.year && _mes.month == hoy.month;
      _dia = esEsteMes ? hoy : _mes;
    });
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _abrirEvento(Evento evento) async {
    final perfil = _perfil;
    if (perfil == null) return;
    final t = AppLocalizations.of(context);
    final respuesta = await mostrarCalAlEvento(
      context,
      evento: evento,
      perfilId: widget.perfilId,
      alumnoNombre: perfil.displayName,
      respuesta: _respuestas[evento.id],
    );
    if (respuesta == null || !mounted) return;
    setState(() => _respuestas = {..._respuestas, evento.id: respuesta});
    AtenaFeedback.success(
      context,
      t.calAlAsistenciaGuardada(t.asistencia(respuesta)),
    );
  }

  Future<void> _editarNota({NotaPersonal? existente}) async {
    final t = AppLocalizations.of(context);
    final resultado = await mostrarCalAlNota(
      context,
      perfilId: widget.perfilId,
      fecha: existente?.fecha ?? _dia,
      nota: existente,
    );
    if (resultado == null || !mounted) return;
    switch (resultado) {
      case CalAlNotaGuardada(:final nota):
        setState(() => _irA(nota.fecha));
        AtenaFeedback.success(context, t.calAlNotaGuardada);
      case CalAlNotaEliminada():
        AtenaFeedback.success(context, t.calAlNotaEliminada);
    }
    await _load();
  }

  Future<void> _eliminarNota(NotaPersonal nota) async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.calAlEliminarNotaConfirm,
      message: t.calAlEliminarNotaMensaje(nota.titulo),
      confirmLabel: t.commonDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    try {
      await CalendarioRepo.instance.eliminarNota(widget.perfilId, nota.id);
      if (!mounted) return;
      AtenaFeedback.success(context, t.calAlNotaEliminada);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
  }

  // ---------------------------------------------------------------------------
  // Datos para la vista
  // ---------------------------------------------------------------------------

  /// Puntos de color de cada día del mes visible.
  Map<DateTime, CalAlMarcasDia> _marcasDelMes() {
    final out = <DateTime, CalAlMarcasDia>{};
    final dias = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    for (var d = 1; d <= dias; d++) {
      final dia = DateTime(_mes.year, _mes.month, d);
      final eventos = _eventos.where((e) => e.ocurreEl(dia)).toList();
      final notas = _notas.where((n) => DateUtils.isSameDay(n.fecha, dia));
      if (eventos.isEmpty && notas.isEmpty) continue;

      final colores = <Color>[];
      for (final e in eventos) {
        final c = colorTipoEvento(e.tipo);
        if (!colores.contains(c)) colores.add(c);
      }
      out[dia] = CalAlMarcasDia(
        colores: [
          ...colores.take(notas.isEmpty ? 3 : 2),
          if (notas.isNotEmpty) calAlColorNota,
        ],
        cantidad: eventos.length + notas.length,
      );
    }
    return out;
  }

  List<CalAlItem> _itemsDelDia(DateTime dia) {
    final items = <CalAlItem>[
      for (final e in _eventos)
        if (e.ocurreEl(dia)) CalAlItemEvento(e),
      for (final n in _notas)
        if (DateUtils.isSameDay(n.fecha, dia)) CalAlItemNota(n),
    ];
    items.sort((a, b) => calAlComparar(a, b, dia));
    return items;
  }

  /// Próximos eventos y notas a partir del día siguiente al elegido
  /// (o de hoy, si el día elegido ya pasó), con el día en que se muestran.
  List<(DateTime, CalAlItem)> _proximos() {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final siguiente = DateTime(_dia.year, _dia.month, _dia.day + 1);
    final desde = siguiente.isAfter(hoy) ? siguiente : hoy;

    DateTime desdeElDia(DateTime d) {
      final dia = DateUtils.dateOnly(d);
      return dia.isBefore(desde) ? desde : dia;
    }

    final items = <(DateTime, CalAlItem)>[
      for (final e in _eventos)
        if (!DateUtils.dateOnly(e.finEfectivo).isBefore(desde))
          (desdeElDia(e.inicio), CalAlItemEvento(e)),
      for (final n in _notas)
        if (!DateUtils.dateOnly(n.fecha).isBefore(desde))
          (DateUtils.dateOnly(n.fecha), CalAlItemNota(n)),
    ];
    items.sort((a, b) {
      final porDia = a.$1.compareTo(b.$1);
      return porDia != 0 ? porDia : calAlComparar(a.$2, b.$2, a.$1);
    });
    return items.take(_maxProximos).toList();
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;
    final listo = !_loading && error == null;

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(
        title: t.calAlTitulo,
        subtitle: _perfil?.displayName,
        actions: [
          if (listo) TextButton(onPressed: _irAHoy, child: Text(t.uiToday)),
        ],
      ),
      floatingActionButton: listo
          ? FloatingActionButton.extended(
              onPressed: _editarNota,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.calAlNuevaNota),
            )
          : null,
      body: _loading
          ? const AtenaLoading()
          : error != null
          ? AtenaErrorState(
              message: coreErrorText(t, error),
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : _contenido(context),
    );
  }

  Widget _contenido(BuildContext context) {
    final calendario = CalAlMes(
      mes: _mes,
      seleccionado: _dia,
      marcas: _marcasDelMes(),
      onSeleccionar: _seleccionar,
      onCambiarMes: _cambiarMes,
    );
    final agenda = _agenda(context);
    // Espacio libre al final para que el botón flotante no tape la lista.
    const finLista = 104.0;

    if (!AtenaLayout.isDesktop(context)) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: atenaPagePadding(context, bottom: finLista),
          children: [calendario, const SizedBox(height: 20), ...agenda],
        ),
      );
    }

    final lateral = atenaPagePadding(context).left;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: lateral),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 400,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: AtenaSpace.xs,
                bottom: AtenaSpace.xxl,
              ),
              child: calendario,
            ),
          ),
          const SizedBox(width: AtenaSpace.xl),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: AtenaSpace.xs,
                  bottom: finLista,
                ),
                children: agenda,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _agenda(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_eventos.isEmpty && _notas.isEmpty) {
      return [_Bienvenida(onNuevaNota: _editarNota)];
    }

    final items = _itemsDelDia(_dia);
    final hoy = DateUtils.dateOnly(DateTime.now());
    final String? relativo;
    if (_dia == hoy) {
      relativo = t.uiToday;
    } else if (_dia == DateTime(hoy.year, hoy.month, hoy.day + 1)) {
      relativo = t.uiTomorrow;
    } else if (_dia == DateTime(hoy.year, hoy.month, hoy.day - 1)) {
      relativo = t.uiYesterday;
    } else {
      relativo = null;
    }
    final proximos = items.isEmpty
        ? _proximos()
        : const <(DateTime, CalAlItem)>[];

    return [
      if (_eventos.isEmpty) ...[
        AtenaBanner(message: t.calAlSinEventos),
        const SizedBox(height: 12),
      ],
      AtenaSectionHeader(
        title: calAlCapitalizar(AtenaFormat.fechaLarga(context, _dia)),
        subtitle: [
          ?relativo,
          if (items.isNotEmpty) t.calAlDiaItems(items.length),
        ].join(' · '),
      ),
      if (items.isNotEmpty)
        _ListaItems(children: [for (final i in items) _tile(i)])
      else ...[
        _DiaLibre(onAgregar: _editarNota),
        if (proximos.isNotEmpty) ...[
          AtenaSectionHeader(
            title: t.calAlProximos,
            padding: const EdgeInsets.only(top: 24, bottom: 10),
          ),
          _ListaItems(
            children: [for (final (dia, i) in proximos) _tile(i, fecha: dia)],
          ),
        ],
      ],
    ];
  }

  /// Fila de la agenda. Con [fecha], muestra el día y al tocarla lo elige.
  Widget _tile(CalAlItem item, {DateTime? fecha}) {
    void irAlDia() {
      if (fecha != null) _seleccionar(fecha);
    }

    return switch (item) {
      CalAlItemEvento(:final evento) => CalAlEventoTile(
        evento: evento,
        respuesta: _respuestas[evento.id],
        fecha: fecha,
        onTap: () {
          irAlDia();
          _abrirEvento(evento);
        },
      ),
      CalAlItemNota(:final nota) => CalAlNotaTile(
        nota: nota,
        fecha: fecha,
        onTap: () {
          irAlDia();
          _editarNota(existente: nota);
        },
        onEditar: () => _editarNota(existente: nota),
        onEliminar: () => _eliminarNota(nota),
      ),
    };
  }
}

/// Tarjeta que agrupa filas de la agenda con divisores.
class _ListaItems extends StatelessWidget {
  final List<Widget> children;

  const _ListaItems({required this.children});

  @override
  Widget build(BuildContext context) {
    return AtenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 76),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Día sin eventos ni notas.
class _DiaLibre extends StatelessWidget {
  final VoidCallback onAgregar;

  const _DiaLibre({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AtenaIconBadge(
                icon: Icons.wb_sunny_rounded,
                color: AtenaColors.gold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.calAlNadaEsteDia,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.calAlAgregarNota),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío: todavía no hay eventos ni notas.
class _Bienvenida extends StatelessWidget {
  final VoidCallback onNuevaNota;

  const _Bienvenida({required this.onNuevaNota});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtenaIconBadge(
            icon: Icons.event_available_rounded,
            color: AtenaColors.violet,
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(t.calAlVacioTitulo, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            t.calAlVacioMensaje,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onNuevaNota,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(t.calAlNuevaNota),
          ),
        ],
      ),
    );
  }
}
