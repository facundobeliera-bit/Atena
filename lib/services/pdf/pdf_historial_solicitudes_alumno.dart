// lib/services/pdf/pdf_historial_solicitudes_alumno.dart
//
// ATENA – PDF HISTORIAL DE SOLICITUDES (ALUMNO)
//
// RESPONSABILIDAD:
// - Renderizar historial completo de solicitudes
// - Vista cronológica (DESC)
// - Documento informativo / exportable
//
// FUENTE:
// - List<SolicitudAlumno>
//
// DEPENDE DE:
// - PdfBase

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/solicitudes/solicitud_alumno.dart';
import 'pdf_base.dart';

class PdfHistorialSolicitudesAlumno {
  static pw.Document build({
    required List<SolicitudAlumno> solicitudes,
    required String alumnoDocumento,
    required String generadoPor, // "Alumno" | "Institución" | "Sistema"
  }) {
    final ordenadas = List<SolicitudAlumno>.from(solicitudes)
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    final contenido = <pw.Widget>[
      _section('Alumno'),
      _kv('Documento', alumnoDocumento),
      _kv('Total de solicitudes', ordenadas.length.toString()),
      pw.SizedBox(height: 14),
      _section('Historial'),
      if (ordenadas.isEmpty)
        pw.Text(
          'No existen solicitudes registradas.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      for (final s in ordenadas) ..._cardSolicitud(s),
    ];

    final ownerId = ordenadas.isNotEmpty
        ? ordenadas.first.ownerAccountId ?? alumnoDocumento
        : alumnoDocumento;

    final perfilId = ordenadas.isNotEmpty ? ordenadas.first.perfilId ?? '' : '';

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Historial de solicitudes',
        subtitulo: 'Alumno',
        generadoPor: generadoPor,
        ownerAccountId: ownerId,
        perfilId: perfilId,
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECCIONES
  // ─────────────────────────────────────────────

  static pw.Widget _section(String t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        t,
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

  static List<pw.Widget> _cardSolicitud(SolicitudAlumno s) {
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              s.actividadNombre,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            _line('Institución', s.institucionNombre),
            _line('Tipo', s.esCurricular ? 'Curricular' : 'Extracurricular'),
            if (!s.esCurricular && s.moduleKey.trim().isNotEmpty)
              _line('Módulo', s.moduleKey),
            if (s.aula.trim().isNotEmpty) _line('Aula / Grupo', s.aula),
            if (s.turno.trim().isNotEmpty) _line('Turno', s.turno),
            _line('Estado', s.estado.label),
            _line('Creada', _fmtDate(s.fechaCreacion)),
            _line('Último cambio', _fmtDate(s.fechaUltimoCambio)),
            if (s.notaInstitucion != null &&
                s.notaInstitucion!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _boxed('Nota institución', s.notaInstitucion!),
            ],
            if (s.motivoRechazo != null &&
                s.motivoRechazo!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _boxed('Motivo rechazo', s.motivoRechazo!),
            ],
          ],
        ),
      ),
    ];
  }

  static pw.Widget _line(String k, String v) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text('$k: $v', style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _boxed(String k, String v) {
    return pw.Column(
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
    );
  }

  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
