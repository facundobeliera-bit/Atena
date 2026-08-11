// lib/services/pdf/pdf_service.dart
//
// ATENA – PDF SERVICE (LOCAL, BACKEND-READY)
//
// Objetivo:
// - Utilidades de nombres/guardado local (sin backend)
// - API canónica: recibe bytes y guarda archivo
//
// ✅ FIX (enero 2026):
// - Sanitización robusta cross-platform.
// - Evita path traversal (se guarda siempre en app dir).
// - Helper de timestamp estable (sin caracteres inválidos).
// - buildFilename: deja claro que perfilId puede ser perfil alumno o institución.
// - savePdfToAppDir: garantiza extensión .pdf.
//
// Nota:
// - Este service NO genera contenido PDF (eso va en templates/builders).
// - Para compartir/guardar desde pw.Document, usar PdfOutputService.
// - Para templates que devuelven Uint8List, usar PdfService.savePdfToAppDir o PdfOutputService.saveBytes.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class PdfService {
  PdfService._();

  static String _sanitizeFilename(
    String input, {
    String fallback = 'document',
  }) {
    final trimmed = input.trim();
    final base = trimmed.isEmpty ? fallback : trimmed;

    // Reemplaza caracteres inválidos en Windows/macOS/Linux
    final safe = base
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return safe.isEmpty ? fallback : safe;
  }

  static String _ensureExtension(String filename, {String ext = 'pdf'}) {
    final e = ext.trim().isEmpty ? 'pdf' : ext.trim();
    final lower = filename.toLowerCase();
    final dotExt = '.${e.toLowerCase()}';
    if (lower.endsWith(dotExt)) return filename;
    return '$filename.$e';
  }

  /// Guarda bytes PDF en el directorio de documentos de la app y retorna la ruta completa.
  static Future<String> savePdfToAppDir({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();

    final safeBase = _sanitizeFilename(filename, fallback: 'atena_pdf');
    final safe = _ensureExtension(safeBase, ext: 'pdf');

    final file = File('${dir.path}/$safe');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Helper: nombre de archivo con timestamp (sin caracteres inválidos).
  ///
  /// - prefix: ej "ficha_alumno", "croquis", "fichas_curso"
  /// - perfilId: perfil canónico (alumno o institución según el documento)
  static String buildFilename({
    required String prefix,
    required String perfilId,
    String ext = 'pdf',
  }) {
    final safePrefix = _sanitizeFilename(prefix, fallback: 'ATENA');
    final safePerfil = _sanitizeFilename(perfilId, fallback: 'perfil');

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');

    final base = '${safePrefix}_${safePerfil}_$ts';
    final safeBase = _sanitizeFilename(base, fallback: 'ATENA_$ts');
    return _ensureExtension(safeBase, ext: ext);
  }
}
