import 'document_error.dart';
import 'private_document_view.dart';
import '../services/remote/multiuser_session.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/documentacion_operativa_service.dart';
import '../services/documentos_temporales_service.dart';

Future<void> adjuntarDocumentoLocal(
  BuildContext context,
  SolicitudDocumento s,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (selection == null) return;
    final file = selection.files.single;
    if (file.size > DocumentacionOperativaService.maxBytes ||
        file.bytes == null) {
      throw StateError('Seleccioná un archivo de hasta 2 MB.');
    }
    await DocumentacionOperativaService.adjuntar(
      s.ownerAccountId,
      s.perfilId,
      s.id,
      file.bytes!,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          MultiuserSession.enabled
              ? 'Archivo privado confirmado por Supabase. Solicitud cumplida.'
              : 'Archivo guardado localmente. Solicitud cumplida.',
        ),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(documentError(e))));
  }
}

Future<void> abrirDocumentoLocal(
  BuildContext context,
  DocumentoTemporal supplied,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final remoteSession = MultiuserSession.enabled
      ? MultiuserSession.current
      : null;
  final actor = remoteSession?.userId;
  final token = remoteSession?.client.auth.currentSession?.accessToken;
  try {
    final d = await DocumentacionOperativaService.abrir(supplied);
    if (remoteSession != null &&
        (remoteSession.userId != actor ||
            remoteSession.client.auth.currentSession?.accessToken != token)) {
      throw StateError('La sesión cambió.');
    }
    final uri = Uri.tryParse(d.ref);
    if (uri?.scheme == 'https' && uri!.host.isNotEmpty) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No se pudo abrir la referencia.');
      }
      return;
    }
    final data = uri?.data;
    if (data == null ||
        ![
          'application/pdf',
          'image/png',
          'image/jpeg',
        ].contains(data.mimeType)) {
      throw StateError(
        'La referencia histórica no contiene un archivo accesible en este dispositivo.',
      );
    }
    final bytes = Uint8List.fromList(data.contentAsBytes());
    DocumentacionOperativaService.referencia(bytes);
    Future<Uint8List> revalidatedBytes() async {
      try {
        if (remoteSession != null &&
            (remoteSession.userId != actor ||
                remoteSession.client.auth.currentSession?.accessToken !=
                    token)) {
          throw StateError('La sesión cambió.');
        }
        await DocumentacionOperativaService.abrir(d);
        if (remoteSession != null &&
            (remoteSession.userId != actor ||
                remoteSession.client.auth.currentSession?.accessToken !=
                    token)) {
          throw StateError('La sesión cambió.');
        }
        return bytes;
      } catch (error) {
        // Printing reports callback errors through FlutterError: sanitize first.
        throw StateError(documentError(error));
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          final page = Scaffold(
            appBar: AppBar(title: Text(d.tipo.label)),
            body: data.mimeType == 'application/pdf'
                ? PdfPreview(
                    build: (_) => revalidatedBytes(),
                    pdfFileName: 'documento-atena.pdf',
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                  )
                : Column(
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          child: Image.memory(
                            bytes,
                            errorBuilder: (_, error, stack) =>
                                const Text('No se pudo visualizar la imagen.'),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: FilledButton.icon(
                          onPressed: () async {
                            try {
                              final authorizedBytes = await revalidatedBytes();
                              await Share.shareXFiles([
                                XFile.fromData(
                                  authorizedBytes,
                                  mimeType: data.mimeType,
                                  name: data.mimeType == 'image/png'
                                      ? 'documento.png'
                                      : 'documento.jpg',
                                ),
                              ]);
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(documentError(e))),
                              );
                            }
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Compartir archivo'),
                        ),
                      ),
                    ],
                  ),
          );
          return MultiuserSession.enabled
              ? PrivateDocumentView(
                  session: MultiuserSession.current,
                  child: page,
                )
              : page;
        },
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(documentError(e))));
  }
}
