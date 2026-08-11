// lib/services/pdf/pdf_datos_alumno.dart
//
// ATENA – PDF DATOS DEL ALUMNO (PERFIL)
//
// RESPONSABILIDAD:
// - Renderizar los datos canónicos del Alumno
// - NO acceder a services
// - NO inferir campos
// - NO mutar estado
//
// FUENTE:
// - Alumno (modelos_integrados)
//
// DEPENDE DE:
// - PdfBase
//
// ✅ FIX (enero 2026):
// - Robustez: tolera strings vacíos (usa '—').
// - _fmtDate tolera null.
// - Evita trim repetido.
// - Mantiene trazabilidad canónica (owner + perfil).

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/alumnos/alumnos_integrados.dart';
import 'pdf_base.dart';

class PdfDatosAlumno {
  static pw.Document build({
    required Alumno alumno,
    required String ownerAccountId,
    required String perfilId,
    required String generadoPor, // "Alumno" | "Sistema"
  }) {
    final contenido = <pw.Widget>[
      _section('Identificación'),
      _kv('Documento', alumno.documento),
      _kv('Nombre completo', alumno.nombreCompleto),
      _kv('Fecha de nacimiento', _fmtDate(alumno.fechaNacimiento)),

      pw.SizedBox(height: 16),

      _section('Datos de contacto'),
      _kv('Email', alumno.email),
      _kv('Teléfono', alumno.telefono),

      if ((alumno.fotoPerfilLocalPath ?? '').trim().isNotEmpty) ...[
        pw.SizedBox(height: 16),
        _section('Foto de perfil'),
        pw.Text(
          'La foto de perfil se encuentra almacenada localmente '
          'en el dispositivo del usuario.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Datos del alumno',
        subtitulo: 'Ficha de perfil',
        generadoPor: generadoPor,
        ownerAccountId: ownerAccountId,
        perfilId: perfilId,
        contenido: contenido,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static String _safe(String v) {
    final s = v.trim();
    return s.isEmpty ? '—' : s;
  }

  static pw.Widget _section(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        _safe(title),
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
