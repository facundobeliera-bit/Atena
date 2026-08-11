// lib/services/pdf/pdf_ficha_alumno_institucion.dart
//
// ATENA – PDF FICHA DE ALUMNO (VISTA INSTITUCIÓN)
//
// RESPONSABILIDAD:
// - Renderizar datos básicos del Alumno para uso institucional
// - NO acceder a services
// - NO mutar
// - NO inferir datos fuera del modelo
//
// FUENTE:
// - Alumno (modelo canónico)
//
// DEPENDE DE:
// - PdfBase
//
// ✅ FIX (enero 2026):
// - Corrige trazabilidad canónica: ownerAccountId != institucionId (era un bug conceptual).
//   En vista institución, el "ownerAccountId" del PDF NO puede ser el institucionId.
//   PdfBaseParams debe recibir ownerAccountId y perfilId reales del dueño del perfil (owner→perfiles).
//   Como este builder no recibe ownerAccountId, NO inventamos.
//   -> Solución segura: pasamos ownerAccountId vacío ('') y dejamos perfilId=institucionId,
//      y trazabilidad institucional en subtítulo.
// - Robustez: _kv tolera strings vacíos y normaliza a '—'.
// - _fmtDate tolera null (si el modelo permite null; si no, funciona igual).
// - Evita .trim() repetidos y evita posibles null issues.
//
// Nota:
// - Si querés trazabilidad perfecta, este builder debe recibir:
//   (required String ownerAccountId, required String perfilIdInstitucion)
//   pero no lo cambiamos hoy sin revisar PdfBase/PdfBaseParams para no romper factory.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/alumnos/alumnos_integrados.dart';
import 'pdf_base.dart';

class PdfFichaAlumnoInstitucion {
  static pw.Document build({
    required Alumno alumno,
    required String institucionId, // perfilId institución
    required String institucionNombre,
    required String generadoPor, // "Institución"
  }) {
    final instNombre = institucionNombre.trim().isEmpty
        ? '—'
        : institucionNombre.trim();

    final contenido = <pw.Widget>[
      _section('Datos del alumno'),
      _kv('Documento', alumno.documento),
      _kv('Nombre completo', alumno.nombreCompleto),
      _kv('Fecha de nacimiento', _fmtDate(alumno.fechaNacimiento)),

      pw.SizedBox(height: 16),

      _section('Contacto'),
      _kv('Email', alumno.email),
      _kv('Teléfono', alumno.telefono),

      pw.SizedBox(height: 20),

      pw.Text(
        'Esta ficha corresponde a datos declarados por el alumno '
        'y es utilizada exclusivamente con fines administrativos.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Ficha de alumno',
        subtitulo: 'Institución: $instNombre',
        generadoPor: generadoPor,

        // ✅ No inventar ownerAccountId.
        // Si PdfBaseParams lo usa solo como texto de trazabilidad,
        // pasar vacío es más seguro que usar institucionId.
        ownerAccountId: '',

        // En vista institución, el perfil relevante aquí es el perfil institución.
        perfilId: institucionId,
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────

  static pw.Widget _section(String title) {
    final t = title.trim().isEmpty ? '—' : title.trim();
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

  static String _safe(String v) {
    final s = v.trim();
    return s.isEmpty ? '—' : s;
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
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

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
