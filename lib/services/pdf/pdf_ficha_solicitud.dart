// lib/services/pdf/pdf_ficha_solicitud.dart
//
// ATENA – PDF FICHA DE SOLICITUD (INDIVIDUAL)
//
// RESPONSABILIDAD:
// - Renderizar una SolicitudAlumno completa
// - Documento formal y trazable
// - NO acceder a services
// - NO mutar estado
//
// FUENTE:
// - SolicitudAlumno (modelo canónico)
//
// DEPENDE DE:
// - PdfBase

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/solicitudes/solicitud_alumno.dart';
import 'pdf_base.dart';

class PdfFichaSolicitud {
  static pw.Document build({
    required SolicitudAlumno solicitud,
    required String generadoPor, // "Alumno" | "Institución" | "Sistema"
  }) {
    final contenido = <pw.Widget>[
      _section('Datos de la solicitud'),
      _kv('ID solicitud', solicitud.id),
      _kv('Estado', solicitud.estado.label),
      _kv('Fecha de creación', _fmtDate(solicitud.fechaCreacion)),
      _kv('Última actualización', _fmtDate(solicitud.fechaUltimoCambio)),

      pw.SizedBox(height: 14),

      _section('Alumno'),
      _kv('Documento', solicitud.alumnoDocumento),

      pw.SizedBox(height: 14),

      _section('Institución'),
      _kv('Nombre', solicitud.institucionNombre),
      _kv('ID institución', solicitud.institucionId),

      pw.SizedBox(height: 14),

      _section('Actividad'),
      _kv('Nombre', solicitud.actividadNombre),
      _kv('Tipo', solicitud.esCurricular ? 'Curricular' : 'Extracurricular'),
      if (!solicitud.esCurricular && solicitud.moduleKey.isNotEmpty)
        _kv('Módulo extracurricular', solicitud.moduleKey),
      if (solicitud.aula.trim().isNotEmpty) _kv('Aula / Grupo', solicitud.aula),
      if (solicitud.turno.trim().isNotEmpty) _kv('Turno', solicitud.turno),

      if (_hasNotaOrMotivo(solicitud)) ...[
        pw.SizedBox(height: 14),
        _section('Observaciones'),
        if (solicitud.notaInstitucion != null &&
            solicitud.notaInstitucion!.trim().isNotEmpty)
          _multiline('Nota de la institución', solicitud.notaInstitucion!),
        if (solicitud.motivoRechazo != null &&
            solicitud.motivoRechazo!.trim().isNotEmpty)
          _multiline('Motivo de rechazo', solicitud.motivoRechazo!),
      ],

      pw.SizedBox(height: 20),

      pw.Text(
        'Este documento refleja el estado actual de la solicitud '
        'según los datos registrados en la plataforma ATENA.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Ficha de solicitud',
        subtitulo: 'Comprobante individual',
        generadoPor: generadoPor,
        ownerAccountId: solicitud.ownerAccountId ?? solicitud.alumnoDocumento,
        perfilId: solicitud.perfilId ?? solicitud.institucionId,
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static pw.Widget _section(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 160,
            child: pw.Text(
              k,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(v, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _multiline(String k, String v) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            k,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(v, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static bool _hasNotaOrMotivo(SolicitudAlumno s) {
    final n = s.notaInstitucion;
    final m = s.motivoRechazo;
    return (n != null && n.trim().isNotEmpty) ||
        (m != null && m.trim().isNotEmpty);
  }

  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
