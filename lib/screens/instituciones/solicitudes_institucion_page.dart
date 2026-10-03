// lib/screens/instituciones/solicitudes_institucion_page.dart
//
// ATENA – Solicitudes de vacante recibidas por la institución.
// Pestañas por estado con contadores, filtro por vacante y búsqueda por
// nombre o DNI. Las pendientes se responden desde la tarjeta o desde el
// detalle, que además permite contactar a la familia, pedir documentos y
// descargar el comprobante.
//
// La lista se actualiza sola cuando cambian los datos guardados (por ejemplo,
// si una familia cancela o elimina su cuenta).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/sol_inst_acciones.dart';
import 'widgets/sol_inst_comun.dart';
import 'widgets/sol_inst_detalle.dart';

class SolicitudesInstitucionPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;

  /// Vacante por la que se filtra al abrir (opcional).
  final String? ofertaId;

  /// Solicitud cuyo detalle se abre al cargar (opcional).
  final String? initialSolicitudId;

  const SolicitudesInstitucionPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.ofertaId,
    this.initialSolicitudId,
  });

  @override
  Widget build(BuildContext context) {
    // El tema del área envuelve toda la página para que diálogos, menús y
    // hojas también usen los colores de la institución.
    return AtenaRoleTheme(
      role: AtenaRole.institucion,
      child: _SolicitudesView(
        institucionId: institucionId,
        institucionNombre: institucionNombre,
        ofertaId: ofertaId,
        initialSolicitudId: initialSolicitudId,
      ),
    );
  }
}

enum _Pestana { pendientes, confirmadas, noAceptadas, canceladas }

extension on _Pestana {
  bool incluye(EstadoSolicitud e) => switch (this) {
    _Pestana.pendientes => e == EstadoSolicitud.pendiente,
    _Pestana.confirmadas => e == EstadoSolicitud.confirmada,
    _Pestana.noAceptadas => e == EstadoSolicitud.rechazada,
    _Pestana.canceladas =>
      e == EstadoSolicitud.canceladaPorAlumno ||
          e == EstadoSolicitud.canceladaPorInstitucion,
  };

  String titulo(AppLocalizations t) => switch (this) {
    _Pestana.pendientes => t.solInstTabPendientes,
    _Pestana.confirmadas => t.solInstTabConfirmadas,
    _Pestana.noAceptadas => t.solInstTabNoAceptadas,
    _Pestana.canceladas => t.solInstTabCanceladas,
  };
}

class _SolicitudesView extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final String? ofertaId;
  final String? initialSolicitudId;

  const _SolicitudesView({
    required this.institucionId,
    required this.institucionNombre,
    required this.ofertaId,
    required this.initialSolicitudId,
  });

  @override
  State<_SolicitudesView> createState() => _SolicitudesViewState();
}

class _SolicitudesViewState extends State<_SolicitudesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _buscar = TextEditingController();

  List<Solicitud> _solicitudes = const [];
  List<OfertaConCupo> _ofertas = const [];
  List<Oferta> _opciones = const [];
  String _nombre = '';

  bool _loading = true;
  bool _cargado = false;
  bool _recargando = false;
  Object? _error;
  int _carga = 0;
  Timer? _recarga;

  String? _ofertaId;
  String _consulta = '';
  bool _inicialResuelta = false;

  /// Solicitudes que se están respondiendo desde la tarjeta (true = confirmar).
  final Map<String, bool> _procesando = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _Pestana.values.length, vsync: this);
    _nombre = widget.institucionNombre.trim();
    final oferta = (widget.ofertaId ?? '').trim();
    _ofertaId = oferta.isEmpty ? null : oferta;
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _recarga?.cancel();
    _tabs.dispose();
    _buscar.dispose();
    super.dispose();
  }

  /// Los datos guardados cambiaron (una respuesta, una familia que cancela o
  /// elimina su cuenta…): se recarga sin interrumpir lo que se está viendo.
  void _alCambiarDatos() {
    _recarga?.cancel();
    _recarga = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool avisar = false}) async {
    final carga = ++_carga;
    try {
      final id = widget.institucionId;
      final solicitudes = await SolicitudesRepo.instance.porInstitucion(id);
      final ofertas = await OfertasRepo.instance.conCupo(id);
      var nombre = _nombre;
      if (nombre.isEmpty) {
        final inst = await InstitucionesRepo.instance.obtener(id);
        nombre = inst?.nombre.trim() ?? '';
      }
      if (!mounted || carga != _carga) return;

      final opciones = _opcionesDe(solicitudes, ofertas);
      setState(() {
        _solicitudes = solicitudes;
        _ofertas = ofertas;
        _opciones = opciones;
        _nombre = nombre;
        if (!opciones.any((o) => o.id == _ofertaId)) _ofertaId = null;
        _loading = false;
        _cargado = true;
        _error = null;
      });
      _abrirInicial();
    } catch (e) {
      if (!mounted || carga != _carga) return;
      setState(() {
        _loading = false;
        if (!_cargado) _error = e;
      });
      if (_cargado && avisar) {
        AtenaFeedback.error(
          context,
          coreErrorText(AppLocalizations.of(context), e),
        );
      }
    }
  }

  /// Vacantes para el filtro: las que tienen solicitudes y la que llegó
  /// preseleccionada, con sus datos actuales cuando siguen publicadas.
  List<Oferta> _opcionesDe(
    List<Solicitud> solicitudes,
    List<OfertaConCupo> ofertas,
  ) {
    final porId = <String, Oferta>{
      for (final s in solicitudes) s.ofertaId: s.oferta,
    };
    for (final c in ofertas) {
      final id = c.oferta.id;
      if (porId.containsKey(id) || id == _ofertaId) porId[id] = c.oferta;
    }
    return porId.values.toList()..sort(solInstOrdenOfertas);
  }

  Future<void> _refrescar() async {
    setState(() => _recargando = true);
    await _load(avisar: true);
    if (mounted) setState(() => _recargando = false);
  }

  void _reintentar() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  /// Abre la solicitud indicada al entrar (desde una notificación o el panel).
  void _abrirInicial() {
    if (_inicialResuelta) return;
    _inicialResuelta = true;
    final id = (widget.initialSolicitudId ?? '').trim();
    if (id.isEmpty) return;

    final s = _solicitudes.where((x) => x.id == id).firstOrNull;
    if (s == null) {
      AtenaFeedback.info(
        context,
        AppLocalizations.of(context).solInstYaNoExiste,
      );
      return;
    }
    if (_ofertaId != null && _ofertaId != s.ofertaId) {
      setState(() => _ofertaId = null);
    }
    _tabs.index = _Pestana.values.indexWhere((p) => p.incluye(s.estado));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _abrirDetalle(s);
    });
  }

  OfertaConCupo? _cupoDe(Solicitud s) =>
      _ofertas.where((o) => o.oferta.id == s.ofertaId).firstOrNull;

  Future<void> _abrirDetalle(Solicitud s) async {
    final mensaje = await showSolInstDetalle(
      context,
      solicitud: s,
      institucionId: widget.institucionId,
      institucionNombre: _nombre,
      cupo: _cupoDe(s),
    );
    if (!mounted) return;
    if (mensaje != null) AtenaFeedback.success(context, mensaje);
    await _load();
  }

  /// Respuesta rápida desde la tarjeta de una solicitud pendiente.
  Future<void> _responder(Solicitud s, {required bool aceptar}) async {
    void procesando(bool activo) {
      if (!mounted) return;
      setState(() {
        if (activo) {
          _procesando[s.id] = aceptar;
        } else {
          _procesando.remove(s.id);
        }
      });
    }

    final mensaje = aceptar
        ? await solInstConfirmar(
            context,
            s,
            institucionId: widget.institucionId,
            institucionNombre: _nombre,
            onProcesando: procesando,
          )
        : await solInstRechazar(
            context,
            s,
            institucionId: widget.institucionId,
            onProcesando: procesando,
          );
    if (!mounted) return;
    if (mensaje != null) AtenaFeedback.success(context, mensaje);
    await _load();
  }

  Future<void> _irAVacantes() async {
    await solInstAbrirVacantes(
      context,
      institucionId: widget.institucionId,
      institucionNombre: _nombre,
    );
    if (mounted) await _load();
  }

  void _limpiarFiltros() {
    _buscar.clear();
    setState(() {
      _consulta = '';
      _ofertaId = null;
    });
  }

  bool get _hayFiltros => _consulta.trim().isNotEmpty || _ofertaId != null;

  List<Solicitud> _de(_Pestana p, List<Solicitud> filtradas) {
    final lista = filtradas.where((s) => p.incluye(s.estado)).toList();
    if (p == _Pestana.pendientes) {
      lista.sort((a, b) => a.creadaEl.compareTo(b.creadaEl));
    } else {
      lista.sort((a, b) => b.actualizadaEl.compareTo(a.actualizadaEl));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.instActionRequests,
        subtitle: _nombre,
        actions: [
          IconButton(
            tooltip: t.commonRefresh,
            onPressed: _loading || _recargando ? null : _refrescar,
            icon: _recargando
                ? const SolInstSpinner(size: 20)
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const AtenaLoading()
          : _error != null
          ? AtenaErrorState(
              message: coreErrorText(t, _error!),
              onRetry: _reintentar,
            )
          : _contenido(context),
    );
  }

  Widget _contenido(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filtradas = _solicitudes
        .where(
          (s) =>
              (_ofertaId == null || s.ofertaId == _ofertaId) &&
              solInstCoincide(s, _consulta),
        )
        .toList();
    final listas = {for (final p in _Pestana.values) p: _de(p, filtradas)};
    final lado = atenaPagePadding(context).left;
    final seleccion = _opciones.where((o) => o.id == _ofertaId).firstOrNull;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(lado, AtenaSpace.xs, lado, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SolInstBuscador(
                      controller: _buscar,
                      onChanged: (v) => setState(() => _consulta = v),
                    ),
                  ),
                  if (_opciones.length > 1 || seleccion != null) ...[
                    const SizedBox(width: 10),
                    _FiltroOferta(
                      opciones: _opciones,
                      seleccion: _ofertaId,
                      onChanged: (id) => setState(() => _ofertaId = id),
                    ),
                  ],
                ],
              ),
              if (seleccion != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: Icon(iconoOferta(seleccion)),
                    label: Text(
                      solInstNombreOferta(t, seleccion),
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteButtonTooltipMessage: t.solInstQuitarFiltro,
                    onDeleted: () => setState(() => _ofertaId = null),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final p in _Pestana.values)
                    Tab(
                      child: _EtiquetaPestana(
                        texto: p.titulo(t),
                        cantidad: listas[p]!.length,
                        resaltar: p == _Pestana.pendientes,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final p in _Pestana.values) _lista(context, p, listas[p]!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lista(BuildContext context, _Pestana p, List<Solicitud> items) {
    final padding = atenaPagePadding(context, top: AtenaSpace.md);
    final conNota = p == _Pestana.pendientes && items.length > 1;

    return RefreshIndicator(
      onRefresh: () => _load(avisar: true),
      child: items.isEmpty
          ? ListView(
              padding: padding,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_vacio(context, p)],
            )
          : ListView.separated(
              padding: padding,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: items.length + (conNota ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AtenaSpace.sm),
              itemBuilder: (context, i) {
                if (conNota && i == 0) return const _NotaOrden();
                final s = items[conNota ? i - 1 : i];
                return _SolicitudCard(
                  key: ValueKey(s.id),
                  solicitud: s,
                  procesando: _procesando[s.id],
                  onTap: () => _abrirDetalle(s),
                  onConfirmar: () => _responder(s, aceptar: true),
                  onRechazar: () => _responder(s, aceptar: false),
                );
              },
            ),
    );
  }

  Widget _vacio(BuildContext context, _Pestana p) {
    final t = AppLocalizations.of(context);

    if (_hayFiltros) {
      return AtenaEmptyState(
        icon: Icons.search_off_rounded,
        title: t.solInstSinResultadosTitulo,
        message: t.solInstSinResultadosMsg,
        compact: true,
        action: OutlinedButton.icon(
          onPressed: _limpiarFiltros,
          icon: const Icon(Icons.filter_alt_off_rounded),
          label: Text(t.solInstLimpiarFiltros),
        ),
      );
    }

    if (p == _Pestana.pendientes && _solicitudes.isEmpty) {
      return AtenaEmptyState(
        icon: Icons.move_to_inbox_rounded,
        title: t.solInstVacioInicialTitulo,
        message: t.solInstVacioInicialMsg,
        action: FilledButton.icon(
          onPressed: _irAVacantes,
          icon: const Icon(Icons.event_seat_rounded),
          label: Text(t.solInstIrAVacantes),
        ),
      );
    }

    final (icono, titulo, mensaje) = switch (p) {
      _Pestana.pendientes => (
        Icons.task_alt_rounded,
        t.solInstVacioPendientesTitulo,
        t.solInstVacioPendientesMsg,
      ),
      _Pestana.confirmadas => (
        Icons.how_to_reg_rounded,
        t.solInstVacioConfirmadasTitulo,
        t.solInstVacioConfirmadasMsg,
      ),
      _Pestana.noAceptadas => (
        Icons.cancel_outlined,
        t.solInstVacioNoAceptadasTitulo,
        t.solInstVacioNoAceptadasMsg,
      ),
      _Pestana.canceladas => (
        Icons.event_busy_rounded,
        t.solInstVacioCanceladasTitulo,
        t.solInstVacioCanceladasMsg,
      ),
    };
    return AtenaEmptyState(
      icon: icono,
      title: titulo,
      message: mensaje,
      compact: true,
    );
  }
}

/// Botón con el menú de vacantes para filtrar la lista.
class _FiltroOferta extends StatelessWidget {
  final List<Oferta> opciones;
  final String? seleccion;
  final ValueChanged<String?> onChanged;

  const _FiltroOferta({
    required this.opciones,
    required this.seleccion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final conTexto = MediaQuery.sizeOf(context).width >= 600;
    final activo = seleccion != null;

    Widget opcion(String? id, String texto) => MenuItemButton(
      leadingIcon: Icon(id == seleccion ? Icons.check_rounded : null),
      onPressed: () => onChanged(id),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Text(texto, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        opcion(null, t.solInstTodasLasVacantes),
        const Divider(),
        for (final o in opciones) opcion(o.id, solInstNombreOferta(t, o)),
      ],
      builder: (context, menu, _) {
        void alternar() => menu.isOpen ? menu.close() : menu.open();

        if (conTexto) {
          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              shape: const RoundedRectangleBorder(
                borderRadius: AtenaRadius.field,
              ),
              backgroundColor: activo ? cs.primaryContainer : null,
              foregroundColor: activo ? cs.onPrimaryContainer : null,
            ),
            onPressed: alternar,
            icon: const Icon(Icons.filter_list_rounded),
            label: Text(t.solInstVacanteFiltro),
          );
        }
        return IconButton.outlined(
          tooltip: t.solInstFiltrarVacante,
          isSelected: activo,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            shape: const RoundedRectangleBorder(
              borderRadius: AtenaRadius.field,
            ),
          ),
          onPressed: alternar,
          icon: const Icon(Icons.filter_list_rounded),
        );
      },
    );
  }
}

class _EtiquetaPestana extends StatelessWidget {
  final String texto;
  final int cantidad;
  final bool resaltar;

  const _EtiquetaPestana({
    required this.texto,
    required this.cantidad,
    required this.resaltar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tono = AtenaTone.of(
      context,
      resaltar && cantidad > 0
          ? AtenaStatusColors.pending
          : theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(texto),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(minWidth: 24),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: tono.background,
            borderRadius: AtenaRadius.pill,
          ),
          child: Text(
            '$cantidad',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tono.foreground,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Aclara el orden de las pendientes (primero las que llegaron antes).
class _NotaOrden extends StatelessWidget {
  const _NotaOrden();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(t.solInstOrdenLlegada, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;

  /// null = libre; true = confirmando; false = respondiendo que no.
  final bool? procesando;

  final VoidCallback onTap;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  const _SolicitudCard({
    super.key,
    required this.solicitud,
    required this.procesando,
    required this.onTap,
    required this.onConfirmar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = solicitud;
    final pendiente = s.estado == EstadoSolicitud.pendiente;
    final fecha = pendiente ? s.creadaEl : s.actualizadaEl;

    final datos = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtenaAvatar(name: s.alumno.nombreCompleto, size: 46),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.alumno.apellidoNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AtenaFormat.haceTiempo(context, fecha),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                solInstResumenAlumno(t, s.alumno),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(iconoOferta(s.oferta), size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      solInstNombreOferta(t, s.oferta),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (s.mensaje.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: t.solInstConMensaje,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (!pendiente) ...[
                const SizedBox(height: 10),
                AtenaStatusChip(
                  label: t.estadoSolicitud(s.estado),
                  color: colorEstadoSolicitud(s.estado),
                  icon: iconoEstadoSolicitud(s.estado),
                  dense: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return AtenaCard(
      onTap: onTap,
      child: !pendiente
          ? datos
          : LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 620) {
                  return Row(
                    children: [
                      Expanded(child: datos),
                      const SizedBox(width: 16),
                      _acciones(context, expandir: false),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    datos,
                    const SizedBox(height: 14),
                    _acciones(context, expandir: true),
                  ],
                );
              },
            ),
    );
  }

  /// Respuesta rápida: no aceptar / confirmar.
  Widget _acciones(BuildContext context, {required bool expandir}) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ocupado = procesando != null;
    const medida = Size(0, 44);
    const relleno = EdgeInsets.symmetric(horizontal: 16);

    final rechazar = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.error,
        side: BorderSide(color: cs.error.withValues(alpha: 0.5), width: 1.2),
        minimumSize: medida,
        padding: relleno,
      ),
      onPressed: ocupado ? null : onRechazar,
      child: procesando == false
          ? const SolInstSpinner()
          : Text(
              t.solInstNoAceptar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
    final confirmar = FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: medida, padding: relleno),
      onPressed: ocupado ? null : onConfirmar,
      icon: procesando == true
          ? const SolInstSpinner()
          : const Icon(Icons.check_rounded, size: 20),
      label: Text(
        t.solInstConfirmar,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Row(
      mainAxisSize: expandir ? MainAxisSize.max : MainAxisSize.min,
      children: expandir
          ? [
              Expanded(child: rechazar),
              const SizedBox(width: 10),
              Expanded(child: confirmar),
            ]
          : [rechazar, const SizedBox(width: 8), confirmar],
    );
  }
}
