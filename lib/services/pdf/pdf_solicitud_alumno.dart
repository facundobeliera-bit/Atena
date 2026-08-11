// lib/services/pdf/pdf_solicitud_alumno.dart
//
// ATENA – PDF FICHA DE SOLICITUD (ALUMNO)
//
// RESPONSABILIDAD:
// - Renderizar UNA SolicitudAlumno
// - No conocer lógica de negocio
// - No filtrar
// - No mutar
//
// DEPENDE DE:
// - PdfBase (layout común)
// - SolicitudAlumno (modelo canónico)
//
// OUTPUT:
// - pw.Document listo para guardar / compartir

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/solicitudes/solicitud_alumno.dart';
import 'pdf_base.dart';

class PdfSolicitudAlumno {
  PdfSolicitudAlumno._();

  static String _s(dynamic v, {String fallback = '-'}) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
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

  static pw.Document build({
    required SolicitudAlumno solicitud,
    required String ownerAccountId,
    required String generadoPor, // Ej: "Alumno"
  }) {
    final s = solicitud;

    final contenido = <pw.Widget>[
      _sectionTitulo('Datos generales'),
      _kv('ID solicitud', s.id),
      _kv('Estado', _estadoLabel(s.estado)),
      _kv('Tipo', s.esCurricular ? 'Curricular' : 'Extracurricular'),
      _kv('Fecha creación', _fmtDate(s.fechaCreacion)),
      _kv('Última actualización', _fmtDate(s.fechaUltimoCambio)),
      pw.SizedBox(height: 16),

      _sectionTitulo('Institución'),
      _kv('Nombre', s.institucionNombre),
      _kv('ID (perfil institución)', s.institucionId),
      pw.SizedBox(height: 16),

      _sectionTitulo('Actividad'),
      _kv('Nombre', s.actividadNombre),
      if (s.aula.trim().isNotEmpty) _kv('Aula / Grupo', s.aula),
      if (s.turno.trim().isNotEmpty) _kv('Turno', s.turno),
      if (!s.esCurricular && s.moduleKey.trim().isNotEmpty)
        _kv('Módulo extracurricular (moduleKey)', s.moduleKey),

      if ((s.notaInstitucion ?? '').trim().isNotEmpty ||
          (s.motivoRechazo ?? '').trim().isNotEmpty) ...[
        pw.SizedBox(height: 16),
        _sectionTitulo('Observaciones de la institución'),
        if ((s.notaInstitucion ?? '').trim().isNotEmpty)
          _blockText('Nota', s.notaInstitucion ?? ''),
        if ((s.motivoRechazo ?? '').trim().isNotEmpty)
          _blockText('Motivo de rechazo', s.motivoRechazo ?? ''),
      ],
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Ficha de solicitud',
        subtitulo:
            'Solicitud ${s.esCurricular ? 'curricular' : 'extracurricular'}',
        generadoPor: generadoPor,
        ownerAccountId: ownerAccountId.trim(),
        // ✅ FIX: perfilId puede venir nullable en el modelo; lo sanitizamos.
        perfilId: _s(s.perfilId, fallback: 'N/A'),
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI HELPERS (LOCAL AL ARCHIVO)
  // ─────────────────────────────────────────────

  static pw.Widget _sectionTitulo(String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        _s(text, fallback: ''),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  // ✅ Acepta dynamic para evitar String? -> String en llamadas.
  static pw.Widget _kv(String k, dynamic v) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              _s(k, fallback: ''),
              // ✅ sin const: evita const_eval_* en ciertas versiones del paquete pdf
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _s(v),
              // ✅ sin const (mismo motivo)
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _blockText(String titulo, String contenido) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _s(titulo, fallback: ''),
            // ✅ sin const (mismo motivo)
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _s(contenido),
            // ✅ sin const (mismo motivo)
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
