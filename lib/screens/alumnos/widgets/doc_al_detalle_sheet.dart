// lib/screens/alumnos/widgets/doc_al_detalle_sheet.dart
//
// ATENA – Documentos del alumno: detalle de un pedido (indicaciones, fechas,
// motivo de corrección, archivo entregado con vista previa) y sus acciones.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'doc_al_archivos.dart';
import 'doc_al_tarjeta.dart';

/// Acción elegida en el detalle que resuelve la pantalla.
enum DocAlAccion { subir }

Future<DocAlAccion?> mostrarDocAlDetalle(
  BuildContext context,
  PedidoDocumento pedido,
) {
  return showModalBottomSheet<DocAlAccion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AtenaRoleTheme(
      role: AtenaRole.alumno,
      child: _DetalleSheet(pedido: pedido),
    ),
  );
}

class _DetalleSheet extends StatefulWidget {
  final PedidoDocumento pedido;

  const _DetalleSheet({required this.pedido});

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  Future<Uint8List?>? _archivo;
  bool _abriendo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.pedido.archivo != null) {
      _archivo = DocumentosRepo.instance.archivo(widget.pedido.id);
    }
  }

  Future<void> _verArchivo() async {
    if (_abriendo) return;
    setState(() {
      _abriendo = true;
      _error = null;
    });
    final bytes = await _archivo;
    if (!mounted) return;
    final error = await abrirArchivoDocAl(context, widget.pedido, bytes: bytes);
    if (!mounted) return;
    setState(() {
      _abriendo = false;
      _error = error;
    });
  }

  /// Explicación del estado del pedido.
  AtenaBanner _ayuda(AppLocalizations t) {
    final p = widget.pedido;
    final motivo = p.observacion.trim();
    return switch (p.estado) {
      EstadoPedidoDocumento.pendiente => AtenaBanner(
        tone: p.vencido ? AtenaBannerTone.warning : AtenaBannerTone.info,
        message: p.vencido ? t.docAlAyudaVencido : t.docAlAyudaPendiente,
      ),
      EstadoPedidoDocumento.rechazado => AtenaBanner(
        tone: AtenaBannerTone.error,
        title: t.docAlMotivo,
        message: motivo.isEmpty ? t.docAlRechazadoSinMotivo : motivo,
      ),
      EstadoPedidoDocumento.entregado => AtenaBanner(
        message: t.docAlAyudaRevision,
      ),
      EstadoPedidoDocumento.aprobado => AtenaBanner(
        tone: AtenaBannerTone.success,
        message: t.docAlAyudaAprobado,
      ),
      EstadoPedidoDocumento.cancelado => AtenaBanner(
        message: t.docAlAyudaCancelado,
        icon: Icons.block_rounded,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = widget.pedido;
    final detalle = docAlDetalle(p);
    final limite = p.fechaLimite;
    final archivo = p.archivo;
    final error = _error;
    String fecha(DateTime d) =>
        _capitalizar(AtenaFormat.fechaLarga(context, d));

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AtenaIconBadge(
                  icon: iconoDocumento(p.tipo),
                  color: colorEstadoDocumento(p.estado),
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
                      const SizedBox(height: 2),
                      Text(
                        p.institucionNombre,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DocAlChips(pedido: p),
            const SizedBox(height: 16),
            _ayuda(t),
            const SizedBox(height: 10),
            if (detalle.isNotEmpty)
              AtenaInfoRow(
                icon: Icons.notes_rounded,
                label: t.docAlIndicaciones,
                value: detalle,
              ),
            AtenaInfoRow(
              icon: Icons.event_note_rounded,
              label: t.docAlFechaPedido,
              value: fecha(p.creadoEl),
            ),
            if (limite != null)
              AtenaInfoRow(
                icon: p.vencido
                    ? Icons.event_busy_rounded
                    : Icons.event_rounded,
                label: t.docAlFechaLimite,
                value: fecha(limite),
              ),
            if (archivo != null) ...[
              const SizedBox(height: 14),
              Text(t.docAlArchivoEntregado, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _ArchivoCard(
                archivo: archivo,
                datos: _archivo,
                abriendo: _abriendo,
                onVer: _verArchivo,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              AtenaBanner(tone: AtenaBannerTone.error, message: error),
            ],
            const SizedBox(height: 24),
            if (docAlPuedeSubir(p)) ...[
              SizedBox(
                width: double.infinity,
                child: DocAlBotonSubir(
                  pedido: p,
                  subiendo: false,
                  onPressed: () => Navigator.of(context).pop(DocAlAccion.subir),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.uiClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primera letra en mayúscula (las fechas largas empiezan en minúscula en
/// español y portugués).
String _capitalizar(String s) => s.isEmpty
    ? s
    : s.characters.first.toUpperCase() + s.characters.skip(1).string;

/// Archivo entregado: vista previa (si es imagen), nombre, tamaño y fecha.
class _ArchivoCard extends StatelessWidget {
  final ArchivoAdjunto archivo;
  final Future<Uint8List?>? datos;
  final bool abriendo;
  final VoidCallback onVer;

  const _ArchivoCard({
    required this.archivo,
    required this.datos,
    required this.abriendo,
    required this.onVer,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AtenaRadius.field,
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: abriendo ? null : onVer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (archivo.esImagen)
              FutureBuilder<Uint8List?>(
                future: datos,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final bytes = snap.data;
                  if (bytes == null) return const SizedBox.shrink();
                  return Image.memory(
                    bytes,
                    height: 180,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  AtenaIconBadge(
                    icon: archivo.esPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: archivo.esPdf
                        ? AtenaColors.danger
                        : AtenaColors.info,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          archivo.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${docAlTamano(context, archivo.bytes)} · '
                          '${t.docAlEntregadoEl(AtenaFormat.fechaCorta(context, archivo.subidoEl))}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (abriendo)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  else
                    Tooltip(
                      message: t.docAlVerArchivo,
                      child: Icon(
                        Icons.open_in_full_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
