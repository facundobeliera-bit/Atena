// lib/services/pdf/alumno_pdf_service.dart
//
// ATENA – PDF ORQUESTADOR: ALUMNO
//
// Responsabilidad:
// - Cargar datos del alumno (canónico)
// - Generar PDF usando templates
// - Guardar PDF localmente
// - Devolver ruta final
//
// ✅ FIX (enero 2026):
// - Validaciones de strings (trim) para evitar requests vacíos.
// - Errores más informativos (incluye perfilId).
// - Punto único para agregar nuevos PDFs del alumno (extensible).
// - Mantiene canónico owner → perfiles.

import 'dart:typed_data';

import '../alumno_service.dart';
import 'pdf_service.dart';
import 'templates/ficha_alumno_pdf.dart';

class AlumnoPdfService {
  AlumnoPdfService._();

  /// Genera y guarda la ficha PDF del alumno.
  ///
  /// Retorna:
  /// - path absoluto del archivo PDF
  static Future<String> generarFichaAlumno({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final owner = ownerAccountId.trim();
    final pid = perfilId.trim();

    if (owner.isEmpty) {
      throw Exception('ownerAccountId vacío (canónico).');
    }
    if (pid.isEmpty) {
      throw Exception('perfilId vacío (canónico).');
    }

    // 1) Cargar modelo Alumno (canónico)
    final alumno = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
      ownerAccountId: owner,
      perfilId: pid,
    );

    if (alumno == null) {
      throw Exception('Alumno no encontrado para el perfilId=$pid.');
    }

    // 2) Generar bytes PDF
    final Uint8List bytes = await FichaAlumnoPdf.build(
      alumno: alumno,
      ownerAccountId: owner,
      perfilId: pid,
    );

    // 3) Construir nombre + guardar
    final filename = PdfService.buildFilename(
      prefix: 'ficha_alumno',
      perfilId: pid,
    );

    final path = await PdfService.savePdfToAppDir(
      bytes: bytes,
      filename: filename,
    );

    return path;
  }
}
