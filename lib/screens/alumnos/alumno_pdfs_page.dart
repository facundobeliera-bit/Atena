// lib/screens/alumnos/alumno_pdfs_page.dart
//
// ATENA – ALUMNO PDFs (LOCAL)
//
// - Preview (Printing.layoutPdf)
// - Compartir (Printing.sharePdf)
// - Guardar local en app dir (PdfService.savePdfToAppDir)
//
// Nota: Croquis queda preparado como placeholder por ahora.
//       Cuando confirmes el modelo de croquis, se reemplaza el builder.
//

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/alumnos/alumnos_integrados.dart';
import '../../services/pdf/pdf_service.dart';
import '../../services/pdf/templates/ficha_alumno_pdf.dart';

class AlumnoPdfsPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;
  final Alumno alumno;

  const AlumnoPdfsPage({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
    required this.alumno,
  });

  @override
  State<AlumnoPdfsPage> createState() => _AlumnoPdfsPageState();
}

class _AlumnoPdfsPageState extends State<AlumnoPdfsPage> {
  bool _generando = false;

  String get _owner => widget.ownerAccountId.trim();
  String get _perfil => widget.perfilId.trim();

  // -------------------------------
  // Helpers
  // -------------------------------

  void _snack(ScaffoldMessengerState? messenger, String msg) {
    if (messenger == null) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _runGuarded(
    Future<void> Function(ScaffoldMessengerState? messenger) fn,
  ) async {
    if (_generando) return;

    // ✅ Capturar antes de awaits (harden)
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (mounted) setState(() => _generando = true);
    try {
      await fn(messenger);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  bool _validateCanon(ScaffoldMessengerState? messenger) {
    final l = AppLocalizations.of(context);

    if (_owner.isEmpty) {
      _snack(messenger, l.commonInvalidSession);
      return false;
    }
    if (_perfil.isEmpty) {
      _snack(messenger, l.alumnoPdfsInvalidPerfil);
      return false;
    }
    return true;
  }

  // -------------------------------
  // PDF builders
  // -------------------------------

  Future<Uint8List> _buildFichaBytes() async {
    return FichaAlumnoPdf.build(
      alumno: widget.alumno,
      ownerAccountId: _owner,
      perfilId: _perfil,
    );
  }

  // -------------------------------
  // Actions
  // -------------------------------

  Future<void> _previewFicha() async {
    await _runGuarded((messenger) async {
      final l = AppLocalizations.of(context);
      if (!_validateCanon(messenger)) return;

      try {
        final bytes = await _buildFichaBytes();
        if (!mounted) return;

        final name = PdfService.buildFilename(
          prefix: 'FichaAlumno',
          perfilId: _perfil,
        );

        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      } catch (e) {
        _snack(messenger, l.commonErrorWithDetails(e.toString()));
      }
    });
  }

  Future<void> _shareFicha() async {
    await _runGuarded((messenger) async {
      final l = AppLocalizations.of(context);
      if (!_validateCanon(messenger)) return;

      try {
        final bytes = await _buildFichaBytes();
        if (!mounted) return;

        await Printing.sharePdf(
          bytes: bytes,
          filename: PdfService.buildFilename(
            prefix: 'FichaAlumno',
            perfilId: _perfil,
          ),
        );
      } catch (e) {
        _snack(messenger, l.commonErrorWithDetails(e.toString()));
      }
    });
  }

  Future<void> _saveFicha() async {
    await _runGuarded((messenger) async {
      final l = AppLocalizations.of(context);
      if (!_validateCanon(messenger)) return;

      try {
        final bytes = await _buildFichaBytes();

        final filename = PdfService.buildFilename(
          prefix: 'FichaAlumno',
          perfilId: _perfil,
        );

        final path = await PdfService.savePdfToAppDir(
          bytes: bytes,
          filename: filename,
        );

        if (!mounted) return;
        _snack(messenger, l.alumnoPdfsSavedPath(path));
      } catch (e) {
        _snack(messenger, l.commonErrorWithDetails(e.toString()));
      }
    });
  }

  // -------------------------------
  // UI
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final alumno = widget.alumno;

    final cs = Theme.of(context).colorScheme;

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    final subtitleStyle = Theme.of(context).textTheme.bodyMedium;

    final subtleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text(l.alumnoPdfsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.alumnoPdfsFichaTitle, style: titleStyle),
                  const SizedBox(height: 8),
                  Text(alumno.nombreCompleto, style: subtitleStyle),
                  const SizedBox(height: 4),
                  Text(
                    l.alumnoPdfsPerfilId(_perfil),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _generando ? null : _previewFicha,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(l.commonView),
                      ),
                      OutlinedButton.icon(
                        onPressed: _generando ? null : _shareFicha,
                        icon: const Icon(Icons.share),
                        label: Text(l.commonShare),
                      ),
                      OutlinedButton.icon(
                        onPressed: _generando ? null : _saveFicha,
                        icon: const Icon(Icons.save),
                        label: Text(l.commonSave),
                      ),
                    ],
                  ),
                  if (_generando) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Placeholder Croquis (V1)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.alumnoPdfsCroquisTitle, style: titleStyle),
                  const SizedBox(height: 8),
                  Text(l.alumnoPdfsCroquisPlaceholder, style: subtleStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
