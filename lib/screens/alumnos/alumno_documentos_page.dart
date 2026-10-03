// lib/screens/alumnos/alumno_documentos_page.dart
//
// ATENA – Documentos del alumno.
// Pedidos de documentación de las instituciones, agrupados por lo que falta
// hacer: para entregar (pendientes y para corregir), en revisión, aprobados
// e historial de cancelados. Desde acá se sube el archivo (archivo, cámara o
// galería) y se puede ver lo que ya se entregó.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/doc_al_archivos.dart';
import 'widgets/doc_al_detalle_sheet.dart';
import 'widgets/doc_al_tarjeta.dart';

class AlumnoDocumentosPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;

  /// Pedido a abrir al entrar (por ejemplo, desde una notificación).
  final String? initialDocumentoId;

  /// Se conserva por compatibilidad con los enlaces existentes; no se usa.
  final String? initialSolicitudId;

  const AlumnoDocumentosPage({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
    this.initialDocumentoId,
    this.initialSolicitudId,
  });

  @override
  State<AlumnoDocumentosPage> createState() => _AlumnoDocumentosPageState();
}

class _AlumnoDocumentosPageState extends State<AlumnoDocumentosPage> {
  PerfilAlumno? _perfil;
  List<PedidoDocumento> _pedidos = const [];

  /// Pedidos con una subida en curso (evita el doble envío).
  final Set<String> _subiendo = <String>{};

  bool _loading = true;
  Object? _error;
  bool _inicioAplicado = false;
  Timer? _recarga;

  @override
  void initState() {
    super.initState();
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _recarga?.cancel();
    super.dispose();
  }

  /// Los datos cambiaron (una revisión, o la baja de una institución, que se
  /// lleva sus pedidos): vuelve a cargar cuando terminan las escrituras.
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
      final pedidos = await DocumentosRepo.instance.porPerfil(widget.perfilId);

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _pedidos = pedidos;
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

  /// Abre el pedido indicado al entrar (una sola vez).
  void _aplicarInicio() {
    if (_inicioAplicado) return;
    _inicioAplicado = true;
    final id = (widget.initialDocumentoId ?? '').trim();
    if (id.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pedido = _vigente(id);
      if (pedido == null) {
        AtenaFeedback.info(
          context,
          AppLocalizations.of(context).docAlNoDisponible,
        );
      } else {
        _abrirDetalle(pedido);
      }
    });
  }

  /// Versión actual del pedido, o null si ya no existe.
  PedidoDocumento? _vigente(String id) {
    for (final p in _pedidos) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _abrirDetalle(PedidoDocumento pedido) async {
    final accion = await mostrarDocAlDetalle(context, pedido);
    if (accion != DocAlAccion.subir || !mounted) return;

    final vigente = _vigente(pedido.id);
    if (vigente == null) {
      AtenaFeedback.info(
        context,
        AppLocalizations.of(context).docAlNoDisponible,
      );
      return;
    }
    await _subir(vigente);
  }

  Future<void> _verArchivo(PedidoDocumento pedido) async {
    final error = await abrirArchivoDocAl(context, pedido);
    if (error != null && mounted) AtenaFeedback.error(context, error);
  }

  Future<void> _subir(PedidoDocumento pedido) async {
    if (_subiendo.contains(pedido.id)) return;
    final t = AppLocalizations.of(context);

    final DocAlArchivo? elegido;
    try {
      elegido = await elegirArchivoDocAl(
        context,
        nombreBase: t.nombreDocumento(pedido.tipo, pedido.detalle),
      );
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.docAlErrorSeleccion);
      return;
    }
    if (elegido == null || !mounted) return;

    setState(() => _subiendo.add(pedido.id));
    try {
      await DocumentosRepo.instance.entregar(
        pedidoId: pedido.id,
        perfilId: widget.perfilId,
        nombreArchivo: elegido.nombre,
        bytes: elegido.bytes,
      );
      if (!mounted) return;
      AtenaFeedback.success(context, t.docAlEntregado);
    } catch (e) {
      if (!mounted) return;
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
    await _load();
    if (mounted) setState(() => _subiendo.remove(pedido.id));
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(title: t.docAlTitulo, subtitle: _perfil?.displayName),
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
          : RefreshIndicator(onRefresh: _load, child: _contenido(context)),
    );
  }

  Widget _contenido(BuildContext context) {
    final t = AppLocalizations.of(context);
    final padding = atenaPagePadding(context, maxWidth: 760);

    List<PedidoDocumento> enEstado(EstadoPedidoDocumento e) =>
        _pedidos.where((p) => p.estado == e).toList();

    final entregar = _pedidos.where((p) => p.requiereAccionAlumno).toList()
      ..sort(_porUrgencia);
    final revision = enEstado(EstadoPedidoDocumento.entregado);
    final aprobados = enEstado(EstadoPedidoDocumento.aprobado);
    final cancelados = enEstado(EstadoPedidoDocumento.cancelado);
    final sinActivos =
        entregar.isEmpty && revision.isEmpty && aprobados.isEmpty;

    List<Widget> tarjetas(List<PedidoDocumento> pedidos) => [
      for (final p in pedidos) ...[
        DocAlTarjeta(
          pedido: p,
          subiendo: _subiendo.contains(p.id),
          onTap: () => _abrirDetalle(p),
          onSubir: () => _subir(p),
          onVerArchivo: () => _verArchivo(p),
        ),
        const SizedBox(height: 12),
      ],
    ];

    final historial = cancelados.isEmpty
        ? null
        : _Historial(pedidos: cancelados, onTap: _abrirDetalle);

    if (sinActivos) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          AtenaEmptyState(
            icon: Icons.folder_open_rounded,
            title: t.docAlVacioTitulo,
            message: t.docAlVacioMensaje,
          ),
          ?historial,
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        _Resumen(
          entregar: entregar.length,
          revision: revision.length,
          aprobados: aprobados.length,
        ),
        const SizedBox(height: 16),
        AtenaSectionHeader(
          title: t.docAlSeccionEntregar,
          subtitle: entregar.isEmpty ? null : t.docAlSeccionEntregarSub,
        ),
        if (entregar.isEmpty) ...[
          const _NadaParaEntregar(),
          const SizedBox(height: 12),
        ] else
          ...tarjetas(entregar),
        if (revision.isNotEmpty) ...[
          AtenaSectionHeader(
            title: t.docAlSeccionRevision,
            subtitle: t.docAlSeccionRevisionSub,
          ),
          ...tarjetas(revision),
        ],
        if (aprobados.isNotEmpty) ...[
          AtenaSectionHeader(title: t.docAlSeccionAprobados),
          ...tarjetas(aprobados),
        ],
        if (historial != null) ...[const SizedBox(height: 8), historial],
      ],
    );
  }
}

/// Primero lo que vence antes; sin fecha límite, lo más reciente.
int _porUrgencia(PedidoDocumento a, PedidoDocumento b) {
  final la = a.fechaLimite;
  final lb = b.fechaLimite;
  if (la != null && lb != null) {
    final porLimite = la.compareTo(lb);
    if (porLimite != 0) return porLimite;
  } else if (la != null) {
    return -1;
  } else if (lb != null) {
    return 1;
  }
  return b.actualizadoEl.compareTo(a.actualizadoEl);
}

/// Encabezado con el resumen de la documentación.
class _Resumen extends StatelessWidget {
  final int entregar;
  final int revision;
  final int aprobados;

  const _Resumen({
    required this.entregar,
    required this.revision,
    required this.aprobados,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final alDia = entregar == 0;

    return AtenaGradientPanel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AtenaRadius.md),
                  ),
                ),
                child: Icon(
                  alDia ? Icons.task_alt_rounded : Icons.upload_file_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alDia
                          ? t.docAlHeroAlDia
                          : t.docAlHeroPendientes(entregar),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alDia ? t.docAlHeroAlDiaSub : t.docAlHeroPendientesSub,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AtenaStat(
                  value: '$entregar',
                  label: t.docAlSeccionEntregar,
                  onGradient: true,
                ),
              ),
              Expanded(
                child: AtenaStat(
                  value: '$revision',
                  label: t.docAlSeccionRevision,
                  onGradient: true,
                ),
              ),
              Expanded(
                child: AtenaStat(
                  value: '$aprobados',
                  label: t.docAlSeccionAprobados,
                  onGradient: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NadaParaEntregar extends StatelessWidget {
  const _NadaParaEntregar();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AtenaCard(
      child: Row(
        children: [
          AtenaIconBadge(
            icon: Icons.task_alt_rounded,
            color: AtenaBrand.of(context).success,
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(t.docAlNadaParaEntregar)),
        ],
      ),
    );
  }
}

/// Pedidos cancelados, plegados para no distraer de lo pendiente.
class _Historial extends StatelessWidget {
  final List<PedidoDocumento> pedidos;
  final ValueChanged<PedidoDocumento> onTap;

  const _Historial({required this.pedidos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AtenaCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.history_rounded),
        title: Text('${t.docAlSeccionHistorial} (${pedidos.length})'),
        subtitle: Text(t.docAlSeccionHistorialSub),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final p in pedidos)
            DocAlFilaCompacta(pedido: p, onTap: () => onTap(p)),
        ],
      ),
    );
  }
}
