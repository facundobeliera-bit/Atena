// lib/services/pdf/institucion_pdf_service.dart
//
// ATENA – PDF ORQUESTADOR: INSTITUCIÓN
//
// Responsabilidad:
// - Generar PDFs desde el contexto institucional (perfil institución)
// - Guardar PDF localmente
// - Retornar path absoluto
//
// V1:
// - Croquis 10x10 con grupos (solo nombres)
//
// Nota:
// - No accede a repos canónicos (el croquis llega desde UI como modelo listo).

import 'dart:typed_data';

import '../../models/croquis/croquis_aula.dart';
import 'pdf_service.dart';
import 'pdf_croquis_aula.dart';

class InstitucionPdfService {
  InstitucionPdfService._();

  /// Genera y guarda el PDF del croquis de aula (10x10).
  ///
  /// Requiere:
  /// - institucionId: perfilId institución (canónico)
  ///
  /// Retorna:
  /// - path absoluto del archivo PDF
  static Future<String> generarCroquisAula({
    required String institucionId,
    required String institucionNombre,
    required CroquisAula croquis,
  }) async {
    final instId = institucionId.trim();
    if (instId.isEmpty) {
      throw Exception('institucionId vacío (perfil institución).');
    }

    // Seguridad canónica: el modelo debe corresponder a la institución
    if (croquis.institucionId.trim() != instId) {
      throw Exception('El croquis no corresponde a la institución indicada.');
    }

    final doc = PdfCroquisAula.build(
      croquis: croquis,
      institucionNombre: institucionNombre,
      generadoPor: 'Institución',
    );

    // Guardamos bytes
    final Uint8List bytes = await doc.save();

    final filename = PdfService.buildFilename(
      prefix: 'croquis_aula',
      perfilId: instId,
    );

    final path = await PdfService.savePdfToAppDir(
      bytes: bytes,
      filename: filename,
    );

    return path;
  }
}
