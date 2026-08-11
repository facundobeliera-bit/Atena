// lib/services/pdf/templates/solicitud_alumno_pdf.dart
//
// ATENA – TEMPLATE PDF: SOLICITUD (V1)
//
// - 100% local
// - No depende de UI
// - Reutilizable por Alumno / Institución
// - Incluye trazabilidad canónica (ownerAccountId + perfilId + institucionId)
// - Incluye módulo (si es extracurricular), validado contra BloqueExtracurricularX
//
// ✅ Nota canónica:
// - moduleKey se muestra como:
//   * Label del bloque si moduleKey es válida
//   * "Otros" si moduleKey es inválida o vacía (en extracurriculares)
// - Se imprime moduleKey (raw) en trazabilidad para auditoría.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/solicitudes/solicitud_alumno.dart';
import '../../../models/extracurriculares/bloque_extracurricular.dart';

class SolicitudAlumnoPdf {
  SolicitudAlumnoPdf._();

  static String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }

  static pw.Widget _kv(String k, String v) {
    final value = v.trim().isEmpty ? '-' : v.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              k,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }

  static String _estadoLabel(EstadoSolicitud e) {
    switch (e) {
      case EstadoSolicitud.pendiente:
        return 'Pendiente';
      case EstadoSolicitud.confirmada:
        return 'Confirmada';
      case EstadoSolicitud.rechazada:
        return 'Rechazada';
      case EstadoSolicitud.canceladaPorAlumno:
        return 'Cancelada (alumno)';
      case EstadoSolicitud.canceladaPorInstitucion:
        return 'Cancelada (institución)';
    }
  }

  static String _normalizeMk(String raw) => raw.trim().toLowerCase();

  static String _moduleLabel(String moduleKey) {
    final mk = _normalizeMk(moduleKey);
    if (mk.isEmpty) return 'Otros';
    final b = BloqueExtracurricularX.fromKey(mk);
    return b?.label ?? 'Otros';
  }

  /// Genera bytes del PDF de una solicitud.
  ///
  /// - `ownerAccountId` y `perfilId` deberían corresponder al ALUMNO (canónico).
  /// - Si se emite desde institución, igual se imprime el estado real y los ids.
  static Future<Uint8List> build({
    required SolicitudAlumno solicitud,
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    final s = solicitud;

    final tipo = s.esCurricular ? 'Curricular' : 'Extracurricular';
    final aula = s.aula.trim();
    final turno = s.turno.trim();

    final mkRaw = s.esCurricular ? '' : (s.moduleKey).trim();
    final mk = s.esCurricular ? '' : _normalizeMk(mkRaw);

    final bool mkValida =
        (!s.esCurricular) &&
        mk.isNotEmpty &&
        BloqueExtracurricularX.isValidKey(mk);

    final String moduloLabel = s.esCurricular
        ? '-'
        : (mkValida ? _moduleLabel(mk) : 'Otros');

    final String instNombre = s.institucionNombre.trim().isEmpty
        ? '-'
        : s.institucionNombre.trim();

    final String ownerSafe = ownerAccountId.trim().isEmpty
        ? '-'
        : ownerAccountId.trim();

    final String perfilSafe = perfilId.trim().isEmpty ? '-' : perfilId.trim();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 44,
                  height: 44,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'A',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ATENA',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Comprobante de solicitud',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Emitido: ${_fmtDate(now)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Solicitud: ${s.id}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          // Datos de la solicitud
          pw.Text(
            'Detalle de la solicitud',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _kv('Estado', _estadoLabel(s.estado)),
                _kv('Tipo', tipo),
                _kv('Institución', instNombre),
                _kv('Actividad', s.actividadNombre),
                if (!s.esCurricular) _kv('Módulo extracurricular', moduloLabel),
                if (aula.isNotEmpty) _kv('Aula/Grupo', aula),
                if (turno.isNotEmpty) _kv('Turno', turno),
                _kv('Fecha creación', _fmtDateTime(s.fechaCreacion)),
                _kv('Último cambio', _fmtDateTime(s.fechaUltimoCambio)),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // Datos del alumno (mínimos)
          pw.Text(
            'Alumno (referencias)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _kv('Documento (DNI)', s.alumnoDocumento),
                _kv('OwnerAccountId', ownerSafe),
                _kv('PerfilId (alumno)', perfilSafe),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // Trazabilidad canónica
          pw.Text(
            'Trazabilidad (canónico)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _kv('InstitucionId (perfil institución)', s.institucionId),
                _kv('DedupKey', (s.dedupKey).trim().isEmpty ? '-' : s.dedupKey),
                _kv(
                  'moduleKey (raw)',
                  s.esCurricular ? '-' : (mkRaw.isEmpty ? '-' : mkRaw),
                ),
                _kv('Generación', 'Local (sin backend)'),
              ],
            ),
          ),

          // Nota / motivo si existen
          if ((s.notaInstitucion ?? '').trim().isNotEmpty ||
              (s.motivoRechazo ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'Respuesta de la institución',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if ((s.motivoRechazo ?? '').trim().isNotEmpty)
                    _kv('Motivo de rechazo', (s.motivoRechazo ?? '').trim()),
                  if ((s.notaInstitucion ?? '').trim().isNotEmpty)
                    _kv('Nota', (s.notaInstitucion ?? '').trim()),
                ],
              ),
            ),
          ],
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return doc.save();
  }
}
