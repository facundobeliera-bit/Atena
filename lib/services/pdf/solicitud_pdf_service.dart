// lib/services/pdf/solicitud_pdf_service.dart
//
// ATENA – PDF ORQUESTADOR: SOLICITUD
//
// Responsabilidad:
// - Cargar SolicitudAlumno por id (fuente de verdad)
// - Generar PDF usando SolicitudAlumnoPdf (template V1)
// - Guardar PDF localmente con PdfService
// - Devolver path absoluto
//
// ✅ Canónico / sin legacy:
// - Validación: ownerAccountId + perfilId del alumno deben coincidir con la solicitud.
// - Repo: usamos SolicitudesRepositoryPrefs (mismo backend local que el service).
//
// ✅ FIX (enero 2026):
// - Validaciones trim + errores más específicos.
// - Normalización segura (helper _n).
// - Mantiene control de acceso canónico.
//
// Nota:
// - Este service es del flujo ALUMNO (owner/perfil alumno).
// - El CROQUIS es flujo INSTITUCIÓN (perfil institución), por lo que NO se agrega acá.

import 'dart:typed_data';

import '../../models/solicitudes/solicitud_alumno.dart';
import '../../repositories/solicitudes_repository.dart';
import '../../repositories/solicitudes_repository_prefs.dart';

import 'pdf_service.dart';
import 'templates/solicitud_alumno_pdf.dart';

class SolicitudPdfService {
  SolicitudPdfService._();

  static final SolicitudesRepository _repo = SolicitudesRepositoryPrefs();

  static String _n(String? v) => (v ?? '').trim();

  /// Genera y guarda el PDF de una solicitud por su id.
  ///
  /// Requiere:
  /// - ownerAccountId + perfilId del ALUMNO (canónico)
  ///
  /// Retorna:
  /// - path absoluto del archivo PDF generado
  static Future<String> generarPdfSolicitud({
    required String ownerAccountId,
    required String perfilId,
    required String solicitudId,
  }) async {
    final sid = solicitudId.trim();
    if (sid.isEmpty) {
      throw Exception('Solicitud inválida (id vacío).');
    }

    final oCaller = ownerAccountId.trim();
    final pCaller = perfilId.trim();

    if (oCaller.isEmpty || pCaller.isEmpty) {
      throw Exception('Contexto canónico inválido (owner/perfil).');
    }

    // 1) Buscar solicitud (fuente de verdad: repo por id)
    final SolicitudAlumno? s = await _repo.getSolicitudAlumnoById(sid);
    if (s == null) {
      throw Exception('No se encontró la solicitud indicada (id=$sid).');
    }

    // 2) Validación canónica: el caller (alumno) debe coincidir.
    final oSolicitud = _n(s.ownerAccountId);
    final pSolicitud = _n(s.perfilId);

    if (oSolicitud != oCaller || pSolicitud != pCaller) {
      throw Exception('No podés generar un PDF de una solicitud ajena.');
    }

    // 3) Generar bytes PDF (template V1)
    final Uint8List bytes = await SolicitudAlumnoPdf.build(
      solicitud: s,
      ownerAccountId: oCaller,
      perfilId: pCaller,
    );

    // 4) Guardar
    final filename = PdfService.buildFilename(
      prefix: 'solicitud',
      perfilId: pCaller,
    );

    final path = await PdfService.savePdfToAppDir(
      bytes: bytes,
      filename: filename,
    );

    return path;
  }
}
