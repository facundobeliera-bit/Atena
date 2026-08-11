// lib/services/pdf/pdf_output_service.dart
//
// ATENA – PDF OUTPUT SERVICE (UI)
//
// RESPONSABILIDAD:
// - Guardar PDFs generados en almacenamiento local
// - Compartir PDFs
//
// NO:
// - Genera PDFs
// - Conoce modelos
// - Accede a lógica de dominio
//
// USO:
// - UI (botones Descargar / Compartir)
//
// ✅ FIX (enero 2026):
// - Elimina imports no usados.
// - Sanitiza filename + asegura extensión .pdf (cross-platform).
// - Evita path traversal y caracteres inválidos.
// - Permite guardar/compartir desde bytes o desde pw.Document.
// - Mantiene API actual (save/share con pw.Document) para no romper UI.
// - Agrega helpers opcionales: saveBytes / shareBytes (útiles para templates que devuelven Uint8List).

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfOutputService {
  // =====================================================
  // API PRINCIPAL (compat UI actual)
  // =====================================================

  /// Guarda un PDF en almacenamiento local y retorna el archivo.
  static Future<File> save({
    required pw.Document document,
    required String fileName,
  }) async {
    final bytes = await document.save();
    return saveBytes(bytes: bytes, fileName: fileName);
  }

  /// Guarda y comparte un PDF.
  static Future<void> share({
    required pw.Document document,
    required String fileName,
  }) async {
    final bytes = await document.save();
    await shareBytes(bytes: bytes, fileName: fileName, text: fileName);
  }

  // =====================================================
  // API BYTES (útil para templates que devuelven Uint8List)
  // =====================================================

  static Future<File> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safe = _ensurePdfExtension(_sanitizeFilename(fileName));
    return _saveBytes(bytes: bytes, fileName: safe);
  }

  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    String? text,
  }) async {
    final safe = _ensurePdfExtension(_sanitizeFilename(fileName));
    final file = await _saveBytes(bytes: bytes, fileName: safe);
    await Share.shareXFiles([XFile(file.path)], text: text ?? safe);
  }

  // =====================================================
  // HELPERS
  // =====================================================

  static String _sanitizeFilename(
    String input, {
    String fallback = 'atena_pdf',
  }) {
    final trimmed = input.trim();
    final base = trimmed.isEmpty ? fallback : trimmed;

    // Evita path traversal y caracteres inválidos en Windows/macOS/Linux
    final safe = base
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return safe.isEmpty ? fallback : safe;
  }

  static String _ensurePdfExtension(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.pdf') ? filename : '$filename.pdf';
  }

  static Future<File> _saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
