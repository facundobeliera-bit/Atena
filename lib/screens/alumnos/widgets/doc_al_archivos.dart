// lib/screens/alumnos/widgets/doc_al_archivos.dart
//
// ATENA – Documentos del alumno: elegir el archivo a entregar (archivo,
// cámara o galería) y ver el archivo entregado (imágenes en un visor a
// pantalla completa, PDF en la vista de impresión del sistema).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../pdf/atena_pdf.dart';
import '../../../ui/atena_ui.dart';

/// Archivo elegido para entregar.
typedef DocAlArchivo = ({String nombre, Uint8List bytes});

enum _Fuente { archivo, camara, galeria }

bool get _esMovil =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Muestra las opciones para subir un documento y devuelve el archivo elegido
/// (null si el usuario canceló). Las fotos sacadas con la cámara se nombran a
/// partir de [nombreBase] (el nombre del documento pedido).
/// Lanza una excepción si el sistema no permite abrir el archivo o la cámara.
Future<DocAlArchivo?> elegirArchivoDocAl(
  BuildContext context, {
  required String nombreBase,
}) async {
  final fuente = await showModalBottomSheet<_Fuente>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        const AtenaRoleTheme(role: AtenaRole.alumno, child: _FuentesSheet()),
  );
  return switch (fuente) {
    null => null,
    _Fuente.archivo => await _desdeArchivo(),
    _Fuente.camara => await _desdeImagen(ImageSource.camera, nombreBase),
    _Fuente.galeria => await _desdeImagen(ImageSource.gallery, nombreBase),
  };
}

Future<DocAlArchivo?> _desdeArchivo() async {
  final archivo = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
  );
  if (archivo == null) return null;
  return (nombre: archivo.name, bytes: await archivo.readAsBytes());
}

Future<DocAlArchivo?> _desdeImagen(
  ImageSource fuente,
  String nombreBase,
) async {
  final foto = await ImagePicker().pickImage(
    source: fuente,
    maxWidth: 2000,
    imageQuality: 80,
  );
  if (foto == null) return null;
  final bytes = await foto.readAsBytes();
  final nombreValido = DocumentosRepo.mimesPermitidos.contains(
    DocumentosRepo.mimeDesdeNombre(foto.name),
  );
  final base = docAlNombreArchivo(nombreBase);
  final nombre = nombreValido && (fuente == ImageSource.gallery || base.isEmpty)
      ? foto.name
      : '${base.isEmpty ? DateTime.now().millisecondsSinceEpoch : base}'
            '.${_extension(foto)}';
  return (nombre: nombre, bytes: bytes);
}

String _extension(XFile foto) =>
    switch (foto.mimeType ?? DocumentosRepo.mimeDesdeNombre(foto.name)) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      _ => 'jpg',
    };

/// Nombre de archivo a partir del nombre del documento
/// ("DNI del alumno" → "dni-del-alumno"). Vacío si no queda ningún carácter.
String docAlNombreArchivo(String nombreDocumento) {
  const conAcento = 'áàâãäéèêëíìîïóòôõöúùûüñç';
  const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';
  return nombreDocumento
      .toLowerCase()
      .split('')
      .map((c) {
        final i = conAcento.indexOf(c);
        return i < 0 ? c : sinAcento[i];
      })
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Tamaño legible de un archivo ("850 KB", "1,4 MB").
String docAlTamano(BuildContext context, int bytes) {
  const mega = 1024 * 1024;
  if (bytes < mega) return '${(bytes / 1024).ceil()} KB';
  final valor = (bytes / mega).toStringAsFixed(1);
  final ingles = Localizations.localeOf(context).languageCode == 'en';
  return '${ingles ? valor : valor.replaceAll('.', ',')} MB';
}

/// Abre el archivo entregado de un pedido: las imágenes en el visor y los PDF
/// en la vista de impresión del sistema. Devuelve un mensaje de error para
/// mostrar, o null si se abrió bien.
Future<String?> abrirArchivoDocAl(
  BuildContext context,
  PedidoDocumento pedido, {
  Uint8List? bytes,
}) async {
  final t = AppLocalizations.of(context);
  final archivo = pedido.archivo;
  if (archivo == null) return t.docAlErrorArchivo;
  final datos = bytes ?? await DocumentosRepo.instance.archivo(pedido.id);
  if (datos == null || datos.isEmpty) return t.docAlErrorArchivo;
  if (!context.mounted) return null;

  if (archivo.esPdf) {
    try {
      await AtenaPdf.imprimir(context, datos, archivo.nombre);
      return null;
    } catch (_) {
      return t.docAlErrorPdf;
    }
  }
  await mostrarDocAlVisor(context, bytes: datos, nombre: archivo.nombre);
  return null;
}

/// Visor de imágenes a pantalla completa (zoom con pellizco o rueda).
Future<void> mostrarDocAlVisor(
  BuildContext context, {
  required Uint8List bytes,
  required String nombre,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _Visor(bytes: bytes, nombre: nombre),
  );
}

class _Visor extends StatelessWidget {
  final Uint8List bytes;
  final String nombre;

  const _Visor({required this.bytes, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final claro = Colors.white.withValues(alpha: 0.85);

    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.scrim,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  semanticLabel: nombre,
                  errorBuilder: (_, _, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: claro,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.docAlSinVistaPrevia,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: claro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: t.uiClose,
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opciones para subir el documento.
class _FuentesSheet extends StatelessWidget {
  const _FuentesSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    void elegir(_Fuente f) => Navigator.of(context).pop(f);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.docAlFuenteTitulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            AtenaActionTile(
              icon: Icons.upload_file_rounded,
              title: t.docAlFuenteArchivo,
              subtitle: t.docAlFuenteArchivoSub,
              onTap: () => elegir(_Fuente.archivo),
            ),
            if (_esMovil) ...[
              const SizedBox(height: 10),
              AtenaActionTile(
                icon: Icons.photo_camera_rounded,
                title: t.docAlFuenteCamara,
                subtitle: t.docAlFuenteCamaraSub,
                accent: AtenaColors.indigo,
                onTap: () => elegir(_Fuente.camara),
              ),
            ],
            const SizedBox(height: 10),
            AtenaActionTile(
              icon: Icons.photo_library_rounded,
              title: t.docAlFuenteGaleria,
              subtitle: t.docAlFuenteGaleriaSub,
              accent: AtenaColors.violet,
              onTap: () => elegir(_Fuente.galeria),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.docAlFuenteTip,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
