// lib/screens/instituciones/comunicaciones_page.dart
//
// ATENA – Comunicaciones de la institución.
// - Calendario: eventos próximos y pasados agrupados por mes, con alta,
//   edición, baja y respuestas de asistencia.
// - Avisos: mensajes a las familias de los alumnos confirmados e historial.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/com_inst_aviso_sheet.dart';
import 'widgets/com_inst_comunes.dart';
import 'widgets/com_inst_evento_detalle_page.dart';
import 'widgets/com_inst_evento_form_page.dart';
import 'widgets/com_inst_tarjetas.dart';

class ComunicacionesPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final String? initialEventoId;

  const ComunicacionesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.initialEventoId,
  });

  // El tema del área se aplica por encima del estado para que las hojas,
  // diálogos y selectores de fecha usen también el acento de instituciones.
  @override
  Widget build(BuildContext context) => AtenaRoleTheme(
    role: AtenaRole.institucion,
    child: _Comunicaciones(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      initialEventoId: initialEventoId,
    ),
  );
}

class _Comunicaciones extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final String? initialEventoId;

  const _Comunicaciones({
    required this.institucionId,
    required this.institucionNombre,
    required this.initialEventoId,
  });

  @override
  State<_Comunicaciones> createState() => _ComunicacionesState();
}

enum _Periodo { proximos, pasados }

typedef _GrupoMes = ({String titulo, List<Evento> eventos});

class _ComunicacionesState extends State<_Comunicaciones>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final InstAutoRecarga _recarga;

  List<Evento> _eventos = const [];
  Map<String, List<RespuestaEvento>> _respuestas = const {};
  List<Aviso> _avisos = const [];
  List<OfertaConCupo> _ofertas = const [];

  _Periodo _periodo = _Periodo.proximos;
  int _tab = 0;
  int _carga = 0;
  bool _loading = true;
  bool _inicialResuelto = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_alCambiarTab);
    _recarga = InstAutoRecarga(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    _recarga.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _alCambiarTab() {
    if (_tab != _tabs.index) setState(() => _tab = _tabs.index);
  }

  void _alCambiarDatos() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    // Si llega otra recarga mientras tanto, gana la más nueva.
    final carga = ++_carga;
    try {
      final cal = CalendarioRepo.instance;
      final id = widget.institucionId;
      final eventos = await cal.eventosInstitucion(id);
      final avisos = await cal.avisos(id);
      final ofertas = await OfertasRepo.instance.conCupo(id);
      final respuestas = <String, List<RespuestaEvento>>{
        for (final e in eventos)
          if (e.pideConfirmacion) e.id: await cal.respuestas(id, e.id),
      };

      if (!mounted || carga != _carga) return;
      setState(() {
        _eventos = eventos;
        _respuestas = respuestas;
        _avisos = avisos;
        _ofertas = ofertas;
        _loading = false;
        _error = null;
      });
      _abrirInicial();
    } catch (e) {
      if (!mounted || carga != _carga) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  /// Abre el evento indicado al entrar (por ejemplo, desde una notificación).
  void _abrirInicial() {
    final id = (widget.initialEventoId ?? '').trim();
    if (_inicialResuelto || id.isEmpty) return;
    _inicialResuelto = true;

    final evento = _eventos.where((e) => e.id == id).firstOrNull;
    if (evento == null) {
      AtenaFeedback.info(context, AppLocalizations.of(context).errNoEncontrado);
      return;
    }
    _tabs.index = 0;
    setState(() => _periodo = _periodoDe(evento));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _abrirEvento(evento);
    });
  }

  _Periodo _periodoDe(Evento e) => comInstEventoPasado(e, DateTime.now())
      ? _Periodo.pasados
      : _Periodo.proximos;

  Future<void> _abrirEvento(Evento e) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ComInstEventoDetallePage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          evento: e,
          ofertas: _ofertas,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _nuevoEvento() async {
    final creado = await Navigator.of(context).push<Evento>(
      MaterialPageRoute(
        builder: (_) => ComInstEventoFormPage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          ofertas: _ofertas,
        ),
      ),
    );
    if (!mounted) return;
    if (creado != null) setState(() => _periodo = _periodoDe(creado));
    await _load();
  }

  Future<void> _nuevoAviso() async {
    final aviso = await showComInstAvisoSheet(
      context,
      institucionId: widget.institucionId,
      institucionNombre: widget.institucionNombre,
      ofertas: _ofertas,
    );
    if (aviso == null || !mounted) return;
    AtenaFeedback.success(
      context,
      AppLocalizations.of(context).comInstAvisoEnviado(aviso.destinatarios),
    );
    await _load();
  }

  List<_GrupoMes> _porMes(List<Evento> eventos) {
    final grupos = <_GrupoMes>[];
    DateTime? mes;
    for (final e in eventos) {
      final m = DateTime(e.inicio.year, e.inicio.month);
      if (mes != m) {
        mes = m;
        grupos.add((
          titulo: comInstCapitalizar(AtenaFormat.mesAnio(context, m)),
          eventos: <Evento>[],
        ));
      }
      grupos.last.eventos.add(e);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;
    final listo = !_loading && error == null;
    final ancho = MediaQuery.sizeOf(context).width >= 600;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.comInstTitle,
        subtitle: widget.institucionNombre,
        bottom: _Pestanas(
          TabBar(
            controller: _tabs,
            isScrollable: ancho,
            tabAlignment: ancho ? TabAlignment.start : TabAlignment.fill,
            tabs: [
              _Pestana(
                icon: Icons.calendar_month_rounded,
                label: t.comInstTabCalendario,
              ),
              _Pestana(icon: Icons.campaign_rounded, label: t.comInstTabAvisos),
            ],
          ),
        ),
      ),
      floatingActionButton: !listo
          ? null
          : FloatingActionButton.extended(
              key: ValueKey(_tab),
              onPressed: _tab == 0 ? _nuevoEvento : _nuevoAviso,
              icon: Icon(_tab == 0 ? Icons.add_rounded : Icons.edit_rounded),
              label: Text(
                _tab == 0 ? t.comInstNuevoEvento : t.comInstNuevoAviso,
              ),
            ),
      body: _loading
          ? const AtenaLoading()
          : error != null
          ? AtenaErrorState(
              title: t.comInstLoadError,
              message: coreErrorText(t, error),
              onRetry: _reintentar,
            )
          : TabBarView(
              controller: _tabs,
              children: [_calendario(context), _avisosEnviados(context)],
            ),
    );
  }

  Widget _calendario(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ahora = DateTime.now();
    final proximos = [
      for (final e in _eventos)
        if (!comInstEventoPasado(e, ahora)) e,
    ];
    final pasados = [
      for (final e in _eventos.reversed)
        if (comInstEventoPasado(e, ahora)) e,
    ];
    final enProximos = _periodo == _Periodo.proximos;
    final lista = enProximos ? proximos : pasados;
    final ofertas = comInstOfertasPorId(_ofertas);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: atenaPagePadding(context, top: 16, bottom: 104),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('${t.comInstProximos} (${proximos.length})'),
                selected: enProximos,
                onSelected: (_) => setState(() => _periodo = _Periodo.proximos),
              ),
              ChoiceChip(
                label: Text('${t.comInstPasados} (${pasados.length})'),
                selected: !enProximos,
                onSelected: (_) => setState(() => _periodo = _Periodo.pasados),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (lista.isEmpty)
            enProximos
                ? AtenaEmptyState(
                    icon: Icons.event_available_rounded,
                    title: t.comInstSinProximosTitulo,
                    message: t.comInstSinProximosMensaje,
                    action: FilledButton.icon(
                      onPressed: _nuevoEvento,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t.comInstNuevoEvento),
                    ),
                  )
                : AtenaEmptyState(
                    icon: Icons.history_rounded,
                    title: t.comInstSinPasadosTitulo,
                    message: t.comInstSinPasadosMensaje,
                  )
          else
            for (final grupo in _porMes(lista)) ...[
              AtenaSectionHeader(
                title: grupo.titulo,
                padding: const EdgeInsets.only(top: 14, bottom: 8),
              ),
              for (final e in grupo.eventos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ComInstEventoCard(
                    evento: e,
                    destinatarios: comInstTextoDestinatarios(
                      t,
                      e.ofertaIds,
                      ofertas,
                    ),
                    respuestas: e.pideConfirmacion
                        ? (_respuestas[e.id] ?? const <RespuestaEvento>[])
                        : null,
                    onTap: () => _abrirEvento(e),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Widget _avisosEnviados(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ofertas = comInstOfertasPorId(_ofertas);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: atenaPagePadding(context, top: 16, bottom: 104),
        children: [
          if (_avisos.isEmpty)
            AtenaEmptyState(
              icon: Icons.campaign_rounded,
              title: t.comInstAvisosVacioTitulo,
              message: t.comInstAvisosVacioMensaje,
              action: FilledButton.icon(
                onPressed: _nuevoAviso,
                icon: const Icon(Icons.edit_rounded),
                label: Text(t.comInstNuevoAviso),
              ),
            )
          else ...[
            AtenaSectionHeader(
              title: t.comInstAvisosEnviados,
              subtitle: t.comInstAvisosEnviadosAyuda,
              padding: const EdgeInsets.only(bottom: 12),
            ),
            for (final a in _avisos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ComInstAvisoCard(
                  aviso: a,
                  destinatarios: comInstTextoDestinatarios(
                    t,
                    a.ofertaIds,
                    ofertas,
                  ),
                  onTap: () => showComInstAvisoDetalle(
                    context,
                    aviso: a,
                    destinatarios: comInstTextoDestinatarios(
                      t,
                      a.ofertaIds,
                      ofertas,
                      completo: true,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Barra de pestañas alineada con el ancho del contenido.
class _Pestanas extends StatelessWidget implements PreferredSizeWidget {
  final TabBar tabBar;

  const _Pestanas(this.tabBar);

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AtenaLayout.content),
        child: tabBar,
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pestana({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
