// lib/services/pdf/pdf_ficha_solicitud_institucion.dart
//
// ATENA – PDF FICHA DE SOLICITUD (INSTITUCIÓN)
//
// RESPONSABILIDAD:
// - Renderizar una solicitud individual en formato imprimible
// - Uso institucional / administrativo
//
// FUENTE:
// - SolicitudAlumno
//
// DEPENDE DE:
// - PdfBase
//
// ✅ FIX (enero 2026):
// - Trazabilidad canónica: ownerAccountId debe ser el owner del alumno (si existe).
//   Si no existe, NO inventamos "institucion" (eso rompe la semántica).
//   -> Se deja vacío ('') y el footer lo maneja.
// - Robustez: _kv tolera strings vacíos y normaliza a '—'.
// - _fmtDate tolera null (por si el modelo lo permite; si no, funciona igual).
// - Título/subtítulo más informativos: incluye institución + módulo si aplica.
// - Evita .trim() repetidos en moduleKey/aula/turno.
//
// Nota:
// - Este PDF es institucional, pero la solicitud pertenece al alumno owner→perfil.
//   El institucionId se mantiene en perfilId del PdfBaseParams solo como trazabilidad
//   del contexto institucional (perfil institución). El footer ya evita vacíos.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/solicitudes/solicitud_alumno.dart';
import 'pdf_base.dart';

class PdfFichaSolicitudInstitucion {
  static pw.Document build({
    required SolicitudAlumno solicitud,
    required String generadoPor, // "Institución" | "Sistema"
  }) {
    final s = solicitud;

    final instNombre = (s.institucionNombre).trim();
    final instNombreSafe = instNombre.isEmpty ? 'Institución' : instNombre;

    final mk = (s.moduleKey).trim();
    final aula = (s.aula).trim();
    final turno = (s.turno).trim();

    final subtitulo = !s.esCurricular && mk.isNotEmpty
        ? '$instNombreSafe · Módulo: $mk'
        : instNombreSafe;

    final contenido = <pw.Widget>[
      _section('Solicitud'),
      _kv('ID', s.id),
      _kv('Estado', s.estado.label),
      _kv('Fecha de creación', _fmtDate(s.fechaCreacion)),
      _kv('Último cambio', _fmtDate(s.fechaUltimoCambio)),
      pw.SizedBox(height: 12),

      _section('Institución'),
      _kv('Nombre', s.institucionNombre),
      _kv('ID institución (perfil)', s.institucionId),
      pw.SizedBox(height: 12),

      _section('Alumno'),
      _kv('Documento', s.alumnoDocumento),
      if ((s.ownerAccountId ?? '').trim().isNotEmpty)
        _kv('Owner account', s.ownerAccountId!),
      if ((s.perfilId ?? '').trim().isNotEmpty)
        _kv('Perfil alumno', s.perfilId!),
      pw.SizedBox(height: 12),

      _section('Actividad'),
      _kv('Nombre', s.actividadNombre),
      _kv('Tipo', s.esCurricular ? 'Curricular' : 'Extracurricular'),
      if (!s.esCurricular && mk.isNotEmpty) _kv('Módulo', mk),
      if (aula.isNotEmpty) _kv('Aula / Grupo', aula),
      if (turno.isNotEmpty) _kv('Turno', turno),
      pw.SizedBox(height: 12),

      if (s.notaInstitucion != null &&
          s.notaInstitucion!.trim().isNotEmpty) ...[
        _section('Nota de la institución'),
        _box(s.notaInstitucion!),
        pw.SizedBox(height: 12),
      ],

      if (s.motivoRechazo != null && s.motivoRechazo!.trim().isNotEmpty) ...[
        _section('Motivo de rechazo'),
        _box(s.motivoRechazo!),
      ],
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Ficha de solicitud',
        subtitulo: subtitulo,
        generadoPor: generadoPor,

        // ✅ ownerAccountId: si no existe, no inventar.
        ownerAccountId: (s.ownerAccountId ?? '').trim(),

        // Contexto institucional: perfil de institución (siempre existe).
        perfilId: s.institucionId,
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────

  static String _safe(String v) {
    final s = v.trim();
    return s.isEmpty ? '—' : s;
  }

  static pw.Widget _section(String t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        _safe(t),
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
          pw.SizedBox(
            width: 170,
            child: pw.Text(
              _safe(k),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(_safe(v), style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _box(String text) {
    final t = text.trim().isEmpty ? '—' : text.trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(t, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
