// lib/screens/instituciones/widgets/doc_inst_detalle_page.dart
//
// ATENA – Detalle de un pedido de documento (institución):
// datos del pedido, archivo entregado (ver / descargar) y acciones según el
// estado: aprobar, pedir corrección o cancelar. Cierra con true si cambió.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'com_inst_comunes.dart'
    show InstAjustable, InstAutoRecarga, comInstCapitalizar;
import 'doc_inst_comunes.dart';

class DocInstDetallePage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final PedidoDocumento pedido;

  const DocInstDetallePage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) => AtenaRoleTheme(
    role: AtenaRole.institucion,
    child: _Detalle(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      pedido: pedido,
    ),
  );
}

class _Detalle extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final PedidoDocumento pedido;

  const _Detalle({
    required this.institucionId,
    required this.institucionNombre,
    required this.pedido,
  });

  @override
  State<_Detalle> createState() => _DetalleState();
}

enum _Accion { aprobar, corregir, cancelar }

class _DetalleState extends State<_Detalle> {
  late PedidoDocumento _pedido = widget.pedido;
  late final InstAutoRecarga _recarga;

  Uint8List? _bytes;
  String _bytesDe = '';
  int _carga = 0;
  bool _cargando = true;
  bool _archivoError = false;
  bool _noDisponible = false;
  _Accion? _accion;

  @override
  void initState() {
    super.initState();
    _recarga = InstAutoRecarga(_alCambiarDatos);
    _cargar();
  }

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  void _alCambiarDatos() {
    if (mounted && _accion == null) _cargar();
  }

  /// Relee el pedido (pudo cambiar o desaparecer) y trae el archivo entregado.
  Future<void> _cargar() async {
    final carga = ++_carga;
    try {
      final repo = DocumentosRepo.instance;
      final actual = await repo.obtener(_pedido.id);
      if (actual == null || actual.institucionId != widget.institucionId) {
        if (!mounted || carga != _carga) return;
        setState(() {
          _noDisponible = true;
          _cargando = false;
        });
        return;
      }

      final archivo = actual.archivo;
      var bytes = _bytes;
      var bytesDe = _bytesDe;
      if (archivo == null) {
        bytes = null;
        bytesDe = '';
      } else if (bytes == null || bytesDe != archivo.id) {
        bytes = await repo.archivo(actual.id);
        bytesDe = archivo.id;
      }

      if (!mounted || carga != _carga) return;
      setState(() {
        _pedido = actual;
        _bytes = bytes;
        _bytesDe = bytesDe;
        _archivoError = archivo != null && bytes == null;
        _noDisponible = false;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted || carga != _carga) return;
      setState(() {
        _archivoError = _pedido.archivo != null && _bytes == null;
        _cargando = false;
      });
    }
  }

  Future<void> _ejecutar(
    _Accion accion,
    Future<void> Function() tarea,
    String exito,
  ) async {
    if (_accion != null) return;
    final t = AppLocalizations.of(context);
    setState(() => _accion = accion);
    try {
      await tarea();
      if (!mounted) return;
      AtenaFeedback.success(context, exito);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accion = null);
      AtenaFeedback.error(context, coreErrorText(t, e));
      await _cargar();
    }
  }

  Future<void> _aprobar() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.docInstAprobarTitulo,
      message: t.docInstAprobarMensaje(_pedido.alumnoNombre),
      confirmLabel: t.docInstAprobar,
      icon: Icons.task_alt_rounded,
    );
    if (!ok || !mounted) return;
    await _ejecutar(
      _Accion.aprobar,
      () => DocumentosRepo.instance.revisar(
        pedidoId: _pedido.id,
        institucionId: widget.institucionId,
        aprobado: true,
      ),
      t.docInstAprobado,
    );
  }

  Future<void> _pedirCorreccion() async {
    final t = AppLocalizations.of(context);
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoDialog(),
    );
    if (motivo == null || !mounted) return;
    await _ejecutar(
      _Accion.corregir,
      () => DocumentosRepo.instance.revisar(
        pedidoId: _pedido.id,
        institucionId: widget.institucionId,
        aprobado: false,
        observacion: motivo,
      ),
      t.docInstCorreccionEnviada,
    );
  }

  Future<void> _cancelar() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.docInstCancelarTitulo,
      message: t.docInstCancelarMensaje,
      confirmLabel: t.docInstCancelarPedido,
      cancelLabel: t.docInstMantener,
      destructive: true,
      icon: Icons.block_rounded,
    );
    if (!ok || !mounted) return;
    await _ejecutar(
      _Accion.cancelar,
      () => DocumentosRepo.instance.cancelar(
        pedidoId: _pedido.id,
        institucionId: widget.institucionId,
      ),
      t.docInstPedidoCancelado,
    );
  }

  void _ver() {
    final archivo = _pedido.archivo;
    final bytes = _bytes;
    if (archivo == null || bytes == null) return;
    docInstVerArchivo(context, archivo: archivo, bytes: bytes);
  }

  void _descargar() {
    final archivo = _pedido.archivo;
    final bytes = _bytes;
    if (archivo == null || bytes == null) return;
    docInstDescargarArchivo(context, archivo: archivo, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = _pedido;
    final archivo = p.archivo;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.docInstDetalleTitulo,
        subtitle: p.alumnoNombre,
      ),
      body: _noDisponible
          ? AtenaEmptyState(
              icon: Icons.folder_off_rounded,
              title: t.docInstPedidoNoDisponible,
              message: t.docInstPedidoNoDisponibleMensaje,
              action: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t.commonBack),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: atenaPagePadding(context, maxWidth: 720),
                children: [
                  _Encabezado(pedido: p),
                  const SizedBox(height: 12),
                  _EstadoBanner(pedido: p),
                  if (archivo != null) ...[
                    const SizedBox(height: 8),
                    AtenaSectionHeader(
                      title: p.estado == EstadoPedidoDocumento.rechazado
                          ? t.docInstArchivoAnterior
                          : t.docInstArchivoEntregado,
                    ),
                    _ArchivoCard(
                      archivo: archivo,
                      bytes: _bytes,
                      cargando: _cargando,
                      error: _archivoError,
                      onVer: _ver,
                      onDescargar: _descargar,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _acciones(context),
                ],
              ),
            ),
    );
  }

  Widget _acciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ocupado = _accion != null;

    Widget icono(_Accion accion, IconData icon) => _accion == accion
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Icon(icon);

    switch (_pedido.estado) {
      case EstadoPedidoDocumento.entregado:
        return _Botones(
          children: [
            FilledButton.icon(
              onPressed: ocupado ? null : _aprobar,
              icon: icono(_Accion.aprobar, Icons.task_alt_rounded),
              label: Text(t.docInstAprobar),
            ),
            OutlinedButton.icon(
              onPressed: ocupado ? null : _pedirCorreccion,
              icon: icono(_Accion.corregir, Icons.edit_note_rounded),
              label: Text(t.docInstPedirCorreccion),
            ),
          ],
        );
      case EstadoPedidoDocumento.pendiente:
      case EstadoPedidoDocumento.rechazado:
        return _Botones(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
              ),
              onPressed: ocupado ? null : _cancelar,
              icon: icono(_Accion.cancelar, Icons.block_rounded),
              label: Text(t.docInstCancelarPedido),
            ),
          ],
        );
      case EstadoPedidoDocumento.aprobado:
      case EstadoPedidoDocumento.cancelado:
        return const SizedBox.shrink();
    }
  }
}

class _Encabezado extends StatelessWidget {
  final PedidoDocumento pedido;

  const _Encabezado({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = pedido;
    final color = colorEstadoDocumento(p.estado);
    final limite = p.fechaLimite;
    final indicaciones = p.tipo == TipoDocumento.otro ? '' : p.detalle.trim();

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(
                icon: iconoDocumento(p.tipo),
                color: color,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nombreDocumento(p.tipo, p.detalle),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        InstAjustable(
                          child: AtenaStatusChip(
                            label: t.estadoDocumento(p.estado),
                            color: color,
                          ),
                        ),
                        if (p.vencido)
                          InstAjustable(
                            child: AtenaStatusChip(
                              label: t.lblDocVencido,
                              color: AtenaColors.danger,
                              icon: Icons.alarm_rounded,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 6),
            child: Divider(),
          ),
          AtenaInfoRow(
            icon: Icons.person_outline_rounded,
            label: t.docInstAlumno,
            value: p.alumnoNombre,
          ),
          AtenaInfoRow(
            icon: Icons.event_note_rounded,
            label: t.docInstFechaPedido,
            value: comInstCapitalizar(
              AtenaFormat.fechaLarga(context, p.creadoEl),
            ),
          ),
          AtenaInfoRow(
            icon: Icons.event_rounded,
            label: t.docInstFechaLimite,
            value: limite == null
                ? t.docInstSinFechaLimite
                : comInstCapitalizar(AtenaFormat.fechaLarga(context, limite)),
          ),
          if (indicaciones.isNotEmpty)
            AtenaInfoRow(
              icon: Icons.notes_rounded,
              label: t.docInstIndicaciones,
              value: indicaciones,
            ),
        ],
      ),
    );
  }
}

/// Explica en qué punto está el pedido y qué se espera ahora.
class _EstadoBanner extends StatelessWidget {
  final PedidoDocumento pedido;

  const _EstadoBanner({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = pedido;
    final actualizado = AtenaFormat.fechaCorta(context, p.actualizadoEl);
    final motivo = p.observacion.trim();

    return switch (p.estado) {
      EstadoPedidoDocumento.pendiente => AtenaBanner(
        icon: Icons.hourglass_top_rounded,
        message: t.docInstEsperandoArchivo,
      ),
      EstadoPedidoDocumento.entregado => AtenaBanner(
        icon: Icons.rate_review_rounded,
        message: t.docInstRevisarAyuda,
      ),
      EstadoPedidoDocumento.rechazado => AtenaBanner(
        tone: AtenaBannerTone.warning,
        icon: Icons.report_rounded,
        title: t.docInstMotivoCorreccion,
        message: motivo.isEmpty ? t.docInstEsperandoArchivo : motivo,
      ),
      EstadoPedidoDocumento.aprobado => AtenaBanner(
        tone: AtenaBannerTone.success,
        message: t.docInstAprobadoInfo(actualizado),
      ),
      EstadoPedidoDocumento.cancelado => AtenaBanner(
        icon: Icons.block_rounded,
        message: t.docInstCanceladoInfo(actualizado),
      ),
    };
  }
}

/// Archivo entregado: vista previa (si es imagen), datos y acciones.
class _ArchivoCard extends StatelessWidget {
  final ArchivoAdjunto archivo;
  final Uint8List? bytes;
  final bool cargando;
  final bool error;
  final VoidCallback onVer;
  final VoidCallback onDescargar;

  const _ArchivoCard({
    required this.archivo,
    required this.bytes,
    required this.cargando,
    required this.error,
    required this.onVer,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final datos = bytes;
    final subido =
        '${AtenaFormat.fechaCorta(context, archivo.subidoEl)} · '
        '${AtenaFormat.hora(context, archivo.subidoEl)}';

    return AtenaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (archivo.esImagen && datos != null) ...[
            _Miniatura(bytes: datos, onTap: onVer),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              AtenaIconBadge(
                icon: docInstIconoArchivo(archivo),
                color: archivo.esPdf ? AtenaColors.danger : AtenaColors.info,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      archivo.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${docInstTipoArchivo(t, archivo)} · '
                      '${docInstTamano(context, archivo.bytes)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      t.docInstSubidoEl(subido),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (datos == null && cargando)
            const LinearProgressIndicator()
          else if (datos == null || error)
            AtenaBanner(
              tone: AtenaBannerTone.error,
              message: t.docInstArchivoError,
            )
          else ...[
            if (!docInstSePuedeVer(archivo)) ...[
              AtenaBanner(message: t.docInstSinVistaPrevia),
              const SizedBox(height: 12),
            ],
            _Botones(
              children: [
                if (docInstSePuedeVer(archivo))
                  FilledButton.tonalIcon(
                    onPressed: onVer,
                    icon: const Icon(Icons.visibility_rounded),
                    label: Text(t.docInstVerArchivo),
                  ),
                OutlinedButton.icon(
                  onPressed: onDescargar,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(t.docInstDescargar),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Vista previa de una imagen entregada; al tocarla se abre el visor.
class _Miniatura extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onTap;

  const _Miniatura({required this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    // La miniatura se decodifica al tamaño en que se muestra (las fotos del
    // celular pesan mucho a resolución completa).
    final anchoPx = (media.size.width.clamp(0, 720) * media.devicePixelRatio)
        .round();

    return Semantics(
      button: true,
      label: t.docInstVerArchivo,
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.md)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.memory(
              bytes,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              cacheWidth: anchoPx,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, _, _) => SizedBox(
                height: 120,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 40,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.scrim.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_out_map_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botones lado a lado en pantallas anchas y apilados en teléfonos.
class _Botones extends StatelessWidget {
  final List<Widget> children;

  const _Botones({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (children.length == 1 || c.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Pide el motivo de la corrección (obligatorio). Devuelve el texto o null.
class _MotivoDialog extends StatefulWidget {
  const _MotivoDialog();

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_motivo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      icon: Icon(Icons.edit_note_rounded, color: cs.primary, size: 30),
      title: Text(t.docInstPedirCorreccion),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.docInstCorreccionAyuda),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivo,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: t.docInstMotivoLabel,
                  hintText: t.docInstMotivoAyuda,
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? t.docInstMotivoRequerido : null,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: Text(t.docInstPedirCorreccion),
        ),
      ],
    );
  }
}
