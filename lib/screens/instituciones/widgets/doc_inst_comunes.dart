// lib/screens/instituciones/widgets/doc_inst_comunes.dart
//
// ATENA – Piezas compartidas de Documentación (institución): alumnos a los
// que se les puede pedir documentos, tarjeta de pedido, datos del archivo
// entregado, visor de imágenes y acciones de ver / descargar.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../pdf/atena_pdf.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'com_inst_comunes.dart' show InstAjustable;

/// Alumno al que la institución le puede pedir documentos.
class DocInstAlumno {
  final AlumnoSnapshot alumno;

  /// Nombres de las ofertas donde tiene solicitudes activas.
  final List<String> ofertas;

  /// true si tiene al menos una vacante confirmada.
  final bool confirmado;

  const DocInstAlumno({
    required this.alumno,
    required this.ofertas,
    required this.confirmado,
  });
}

/// Alumnos con solicitudes pendientes o confirmadas, uno por perfil y
/// ordenados por apellido.
List<DocInstAlumno> docInstAlumnosDe(List<Solicitud> solicitudes) {
  final alumnos = <String, AlumnoSnapshot>{};
  final ofertas = <String, List<String>>{};
  final confirmados = <String>{};

  for (final s in solicitudes) {
    final id = s.alumno.perfilId;
    if (!s.estado.esActiva || id.isEmpty || s.alumno.cuentaId.isEmpty) {
      continue;
    }
    alumnos.putIfAbsent(id, () => s.alumno);
    final nombres = ofertas.putIfAbsent(id, () => <String>[]);
    if (!nombres.contains(s.ofertaNombre)) nombres.add(s.ofertaNombre);
    if (s.estado == EstadoSolicitud.confirmada) confirmados.add(id);
  }

  final lista = [
    for (final entry in alumnos.entries)
      DocInstAlumno(
        alumno: entry.value,
        ofertas: ofertas[entry.key] ?? const <String>[],
        confirmado: confirmados.contains(entry.key),
      ),
  ];
  lista.sort(
    (a, b) => normalizarBusqueda(
      a.alumno.apellidoNombre,
    ).compareTo(normalizarBusqueda(b.alumno.apellidoNombre)),
  );
  return lista;
}

/// Tamaño legible de un archivo ("340 KB", "1,2 MB").
String docInstTamano(BuildContext context, int bytes) {
  final t = AppLocalizations.of(context);
  const mega = 1024 * 1024;
  if (bytes < mega) {
    final kb = (bytes / 1024).ceil();
    return t.docInstTamanoKb('${kb < 1 ? 1 : kb}');
  }
  final ingles = Localizations.localeOf(context).languageCode == 'en';
  final mb = (bytes / mega).toStringAsFixed(1);
  return t.docInstTamanoMb(ingles ? mb : mb.replaceAll('.', ','));
}

/// "Documento PDF", "Imagen" o "Archivo".
String docInstTipoArchivo(AppLocalizations t, ArchivoAdjunto archivo) =>
    archivo.esPdf
    ? t.docInstTipoPdf
    : archivo.esImagen
    ? t.docInstTipoImagen
    : t.docInstTipoArchivo;

IconData docInstIconoArchivo(ArchivoAdjunto archivo) => archivo.esPdf
    ? Icons.picture_as_pdf_rounded
    : archivo.esImagen
    ? Icons.image_rounded
    : Icons.insert_drive_file_rounded;

/// true si el archivo se puede ver dentro de la app.
bool docInstSePuedeVer(ArchivoAdjunto archivo) =>
    archivo.esPdf || archivo.esImagen;

/// Abre el archivo entregado: las imágenes en un visor a pantalla completa y
/// los PDF en la vista previa del sistema.
Future<void> docInstVerArchivo(
  BuildContext context, {
  required ArchivoAdjunto archivo,
  required Uint8List bytes,
}) async {
  final t = AppLocalizations.of(context);
  if (archivo.esImagen) {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _VisorImagen(archivo: archivo, bytes: bytes),
    );
    return;
  }
  if (!archivo.esPdf) return;
  try {
    await AtenaPdf.imprimir(context, bytes, archivo.nombre);
  } catch (_) {
    if (context.mounted) AtenaFeedback.error(context, t.docInstArchivoError);
  }
}

/// Descarga o comparte el archivo entregado.
Future<void> docInstDescargarArchivo(
  BuildContext context, {
  required ArchivoAdjunto archivo,
  required Uint8List bytes,
}) async {
  final t = AppLocalizations.of(context);
  // En tabletas el panel de compartir se ancla a esta zona de la pantalla.
  final caja = context.findRenderObject();
  final origen = caja is RenderBox && caja.hasSize
      ? caja.localToGlobal(Offset.zero) & caja.size
      : null;
  try {
    if (archivo.esPdf) {
      await AtenaPdf.compartir(context, bytes, archivo.nombre);
      return;
    }
    final mime = archivo.mime.isNotEmpty
        ? archivo.mime
        : DocumentosRepo.mimeDesdeNombre(archivo.nombre);
    final file = XFile.fromData(bytes, mimeType: mime, name: archivo.nombre);
    if (kIsWeb) {
      // En el navegador se descarga directo (no todos permiten compartir).
      await file.saveTo(archivo.nombre);
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [file], sharePositionOrigin: origen),
      );
    }
  } catch (_) {
    if (context.mounted) AtenaFeedback.error(context, t.docInstArchivoError);
  }
}

/// Pedido de documento en los listados de la institución.
class DocInstPedidoCard extends StatelessWidget {
  final PedidoDocumento pedido;
  final VoidCallback onTap;

  const DocInstPedidoCard({
    super.key,
    required this.pedido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = pedido;
    final color = colorEstadoDocumento(p.estado);
    final limite = p.fechaLimite;
    final archivo = p.archivo;
    final fechas = [
      t.docInstPedidoEl(AtenaFormat.fechaCorta(context, p.creadoEl)),
      if (limite != null)
        t.docInstLimite(AtenaFormat.fechaCorta(context, limite)),
    ].join(' · ');

    return AtenaCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtenaIconBadge(icon: iconoDocumento(p.tipo), color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nombreDocumento(p.tipo, p.detalle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  p.alumnoNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
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
                        dense: true,
                      ),
                    ),
                    if (p.vencido)
                      InstAjustable(
                        child: AtenaStatusChip(
                          label: t.lblDocVencido,
                          color: AtenaColors.danger,
                          icon: Icons.alarm_rounded,
                          dense: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  fechas,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (p.estado == EstadoPedidoDocumento.entregado &&
                    archivo != null)
                  Text(
                    t.docInstEntregadoEl(
                      AtenaFormat.fechaCorta(context, archivo.subidoEl),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Visor de imágenes a pantalla completa (zoom y desplazamiento).
class _VisorImagen extends StatelessWidget {
  final ArchivoAdjunto archivo;
  final Uint8List bytes;

  const _VisorImagen({required this.archivo, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fondo = theme.colorScheme.scrim;

    // Con su propio Scaffold, los mensajes (por ejemplo, un error al
    // descargar) se ven sobre el visor y no detrás.
    return Dialog.fullscreen(
      backgroundColor: fondo,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: fondo,
          body: Builder(
            builder: (context) => Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        semanticLabel: archivo.nombre,
                        errorBuilder: (context, _, _) => Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            t.docInstSinVistaPrevia,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          fondo.withValues(alpha: 0.75),
                          fondo.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: t.uiClose,
                              color: Colors.white,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                archivo.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: t.docInstDescargar,
                              color: Colors.white,
                              onPressed: () => docInstDescargarArchivo(
                                context,
                                archivo: archivo,
                                bytes: bytes,
                              ),
                              icon: const Icon(Icons.download_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
