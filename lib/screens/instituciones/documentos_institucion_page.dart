// lib/screens/instituciones/documentos_institucion_page.dart
//
// ATENA – Documentación pedida a los alumnos (institución).
// Bandejas por estado (para revisar, pendientes, aprobados, cancelados),
// alta de pedidos y acceso al detalle para revisar cada entrega.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/com_inst_comunes.dart' show InstAutoRecarga;
import 'widgets/doc_inst_comunes.dart';
import 'widgets/doc_inst_detalle_page.dart';
import 'widgets/doc_inst_pedir_sheet.dart';

class DocumentosInstitucionPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final String? initialPedidoId;

  const DocumentosInstitucionPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.initialPedidoId,
  });

  // El tema del área se aplica por encima del estado para que las hojas,
  // diálogos y selectores de fecha usen también el acento de instituciones.
  @override
  Widget build(BuildContext context) => AtenaRoleTheme(
    role: AtenaRole.institucion,
    child: _Documentos(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      initialPedidoId: initialPedidoId,
    ),
  );
}

class _Documentos extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final String? initialPedidoId;

  const _Documentos({
    required this.institucionId,
    required this.institucionNombre,
    required this.initialPedidoId,
  });

  @override
  State<_Documentos> createState() => _DocumentosState();
}

/// Bandejas en las que se reparten los pedidos según su estado.
enum _Bandeja { revisar, pendientes, aprobados, cancelados }

_Bandeja _bandejaDe(EstadoPedidoDocumento estado) => switch (estado) {
  EstadoPedidoDocumento.entregado => _Bandeja.revisar,
  EstadoPedidoDocumento.pendiente ||
  EstadoPedidoDocumento.rechazado => _Bandeja.pendientes,
  EstadoPedidoDocumento.aprobado => _Bandeja.aprobados,
  EstadoPedidoDocumento.cancelado => _Bandeja.cancelados,
};

/// Pendientes: primero los vencidos, después por fecha límite más cercana.
int _porUrgencia(PedidoDocumento a, PedidoDocumento b) {
  if (a.vencido != b.vencido) return a.vencido ? -1 : 1;
  final la = a.fechaLimite;
  final lb = b.fechaLimite;
  if (la != null && lb != null) {
    final c = la.compareTo(lb);
    if (c != 0) return c;
  } else if (la != null) {
    return -1;
  } else if (lb != null) {
    return 1;
  }
  return b.creadoEl.compareTo(a.creadoEl);
}

class _DocumentosState extends State<_Documentos>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final InstAutoRecarga _recarga;

  Map<_Bandeja, List<PedidoDocumento>> _bandejas = const {};
  List<DocInstAlumno> _alumnos = const [];
  int _carga = 0;
  bool _loading = true;
  bool _inicialResuelto = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _Bandeja.values.length, vsync: this);
    _recarga = InstAutoRecarga(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    _recarga.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _alCambiarDatos() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    // Si llega otra recarga mientras tanto, gana la más nueva.
    final carga = ++_carga;
    try {
      final id = widget.institucionId;
      final pedidos = await DocumentosRepo.instance.porInstitucion(id);
      final solicitudes = await SolicitudesRepo.instance.porInstitucion(id);

      final bandejas = {
        for (final b in _Bandeja.values) b: <PedidoDocumento>[],
      };
      for (final p in pedidos) {
        bandejas[_bandejaDe(p.estado)]!.add(p);
      }
      bandejas[_Bandeja.pendientes]!.sort(_porUrgencia);

      if (!mounted || carga != _carga) return;
      setState(() {
        _bandejas = bandejas;
        _alumnos = docInstAlumnosDe(solicitudes);
        _loading = false;
        _error = null;
      });
      _abrirInicial(pedidos);
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

  /// Abre el pedido indicado al entrar (por ejemplo, desde una notificación)
  /// en la bandeja que le corresponde.
  void _abrirInicial(List<PedidoDocumento> pedidos) {
    final id = (widget.initialPedidoId ?? '').trim();
    if (_inicialResuelto || id.isEmpty) return;
    _inicialResuelto = true;

    final pedido = pedidos.where((p) => p.id == id).firstOrNull;
    if (pedido == null) {
      AtenaFeedback.info(context, AppLocalizations.of(context).errNoEncontrado);
      return;
    }
    _tabs.index = _bandejaDe(pedido.estado).index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _abrir(pedido);
    });
  }

  Future<void> _abrir(PedidoDocumento pedido) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocInstDetallePage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          pedido: pedido,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _pedir() async {
    final t = AppLocalizations.of(context);
    final pedido = await showDocInstPedirSheet(
      context,
      institucionId: widget.institucionId,
      institucionNombre: widget.institucionNombre,
      alumnos: _alumnos,
    );
    if (pedido == null || !mounted) return;
    AtenaFeedback.success(
      context,
      t.docInstPedidoEnviado(
        t.nombreDocumento(pedido.tipo, pedido.detalle),
        pedido.alumnoNombre,
      ),
    );
    _tabs.animateTo(_Bandeja.pendientes.index);
    await _load();
  }

  List<PedidoDocumento> _de(_Bandeja b) =>
      _bandejas[b] ?? const <PedidoDocumento>[];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;
    final listo = !_loading && error == null;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.docInstTitle,
        subtitle: widget.institucionNombre,
        bottom: _Pestanas(
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final b in _Bandeja.values)
                _Pestana(
                  label: switch (b) {
                    _Bandeja.revisar => t.docInstTabRevisar,
                    _Bandeja.pendientes => t.docInstTabPendientes,
                    _Bandeja.aprobados => t.docInstTabAprobados,
                    _Bandeja.cancelados => t.docInstTabCancelados,
                  },
                  cantidad: _de(b).length,
                  destacar: b == _Bandeja.revisar,
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: !listo
          ? null
          : FloatingActionButton.extended(
              onPressed: _pedir,
              icon: const Icon(Icons.note_add_rounded),
              label: Text(t.docInstPedirDocumento),
            ),
      body: _loading
          ? const AtenaLoading()
          : error != null
          ? AtenaErrorState(
              title: t.docInstLoadError,
              message: coreErrorText(t, error),
              onRetry: _reintentar,
            )
          : TabBarView(
              controller: _tabs,
              children: [for (final b in _Bandeja.values) _lista(context, b)],
            ),
    );
  }

  Widget _lista(BuildContext context, _Bandeja bandeja) {
    final pedidos = _de(bandeja);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: atenaPagePadding(context, top: 16, bottom: 104),
        children: [
          if (pedidos.isEmpty)
            _vacio(context, bandeja)
          else
            for (final p in pedidos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DocInstPedidoCard(pedido: p, onTap: () => _abrir(p)),
              ),
        ],
      ),
    );
  }

  Widget _vacio(BuildContext context, _Bandeja bandeja) {
    final t = AppLocalizations.of(context);
    return switch (bandeja) {
      _Bandeja.revisar => AtenaEmptyState(
        icon: Icons.fact_check_rounded,
        title: t.docInstVacioRevisarTitulo,
        message: t.docInstVacioRevisarMensaje,
      ),
      _Bandeja.pendientes => AtenaEmptyState(
        icon: Icons.folder_open_rounded,
        title: t.docInstVacioPendientesTitulo,
        message: t.docInstVacioPendientesMensaje,
        action: FilledButton.icon(
          onPressed: _pedir,
          icon: const Icon(Icons.note_add_rounded),
          label: Text(t.docInstPedirDocumento),
        ),
      ),
      _Bandeja.aprobados => AtenaEmptyState(
        icon: Icons.task_alt_rounded,
        title: t.docInstVacioAprobadosTitulo,
        message: t.docInstVacioAprobadosMensaje,
      ),
      _Bandeja.cancelados => AtenaEmptyState(
        icon: Icons.block_rounded,
        title: t.docInstVacioCanceladosTitulo,
        message: t.docInstVacioCanceladosMensaje,
      ),
    };
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

/// Pestaña con contador de pedidos.
class _Pestana extends StatelessWidget {
  final String label;
  final int cantidad;
  final bool destacar;

  const _Pestana({
    required this.label,
    required this.cantidad,
    required this.destacar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final resaltar = destacar && cantidad > 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: resaltar ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: AtenaRadius.pill,
            ),
            child: Text(
              cantidad > 99 ? '99+' : '$cantidad',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: resaltar ? cs.onPrimary : cs.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
