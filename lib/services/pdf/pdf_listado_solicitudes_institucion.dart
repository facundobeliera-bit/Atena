// lib/services/pdf/pdf_listado_solicitudes_institucion.dart
//
// ATENA – PDF LISTADO DE SOLICITUDES (INSTITUCIÓN)
//
// RESPONSABILIDAD:
// - Renderizar listado operativo de solicitudes
// - La lista ya viene filtrada desde UI / Service
// - Documento reutilizable (Institución / Admin)
//
// FUENTE:
// - List<SolicitudAlumno>
//
// DEPENDE DE:
// - PdfBase
//
// ✅ FIX (enero 2026):
// - Trazabilidad canónica: NO inventar ownerAccountId='institucion'.
//   En listados, puede haber múltiples owners; por lo tanto, ownerAccountId no es estable.
//   -> Se deja vacío ('') y PdfBase lo maneja.
// - Subtítulo más informativo: incluye institución + criterio si aplica.
// - Robustez: helpers _kv/_row toleran vacíos y normalizan a '—'.
// - Fechas toleran null si el modelo lo permitiese (sin romper).
// - Evita .trim() repetidos y normaliza moduleKey/aula/turno.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/solicitudes/solicitud_alumno.dart';
import 'pdf_base.dart';

class PdfListadoSolicitudesInstitucion {
  static pw.Document build({
    required List<SolicitudAlumno> solicitudes,
    required String institucionNombre,
    required String generadoPor, // "Institución" | "Sistema"
    String? criterio, // ej: "Pendientes", "Módulo: deporte_y_movimiento"
  }) {
    final ordenadas = List<SolicitudAlumno>.from(solicitudes)
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    final instNombre = institucionNombre.trim().isEmpty
        ? 'Institución'
        : institucionNombre.trim();

    final crit = (criterio ?? '').trim();
    final subtitulo = crit.isEmpty ? instNombre : '$instNombre · $crit';

    final contenido = <pw.Widget>[
      _section('Institución'),
      _kv('Nombre', instNombre),
      _kv('Total de solicitudes', ordenadas.length.toString()),
      if (crit.isNotEmpty) _kv('Criterio', crit),
      pw.SizedBox(height: 14),

      _section('Listado'),
      if (ordenadas.isEmpty)
        pw.Text(
          'No hay solicitudes para mostrar.',
          style: const pw.TextStyle(fontSize: 9),
        ),

      for (final s in ordenadas) _row(s),
    ];

    // Contexto institucional (perfil institución) si está presente en la data.
    final perfilId = ordenadas.isNotEmpty ? ordenadas.first.institucionId : '';

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Listado de solicitudes',
        subtitulo: subtitulo,
        generadoPor: generadoPor,

        // ✅ No hay un owner único en listados: no inventar.
        ownerAccountId: '',

        perfilId: perfilId,
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
            width: 150,
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

  static pw.Widget _row(SolicitudAlumno s) {
    final actividad = _safe(s.actividadNombre);
    final doc = _safe(s.alumnoDocumento);

    final mk = s.moduleKey.trim();
    final aula = s.aula.trim();
    final turno = s.turno.trim();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            actividad,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Alumno: $doc · ${s.esCurricular ? 'Curricular' : 'Extracurricular'}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (!s.esCurricular && mk.isNotEmpty)
            pw.Text('Módulo: $mk', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Estado: ${s.estado.label} · Creada: ${_fmtDate(s.fechaCreacion)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (aula.isNotEmpty || turno.isNotEmpty)
            pw.Text(
              [
                if (aula.isNotEmpty) 'Aula: $aula',
                if (turno.isNotEmpty) 'Turno: $turno',
              ].join(' · '),
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
