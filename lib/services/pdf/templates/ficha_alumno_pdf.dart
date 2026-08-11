// lib/services/pdf/templates/ficha_alumno_pdf.dart
//
// ATENA – TEMPLATE PDF: FICHA ALUMNO (V1)
//
// - 100% local
// - Reutilizable para instituciones (mismo layout base)
// - No depende de UI
//
// ✅ FIX (enero 2026):
// - Elimina import no usado (Pdf.dart no se requiere si usamos PdfColors del package:pdf).
// - Robustez en strings nulos/empty (sin reventar por null).
// - Formatea fecha estable.
// - Ajuste menor en _kv para tolerar entradas vacías.
// - Mantiene firma canónica build(...) para trazabilidad.
// - (Opcional futuro) soporte foto alumno si el modelo la trae (NO se implementa acá sin ver el modelo).

import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../../../models/alumnos/alumnos_integrados.dart';

class FichaAlumnoPdf {
  FichaAlumnoPdf._();

  static String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  static String _safe(String? v, {String fallback = '-'}) {
    final s = (v ?? '').trim();
    return s.isEmpty ? fallback : s;
  }

  static pw.Widget _kv(String k, String? v) {
    final value = _safe(v);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              _safe(k, fallback: '-'),
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

  /// Genera bytes del PDF de ficha alumno.
  ///
  /// ownerAccountId y perfilId se incluyen por trazabilidad (no por seguridad).
  static Future<Uint8List> build({
    required Alumno alumno,
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
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
                        'Ficha del alumno',
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
                      'Perfil: ${_safe(perfilId)}',
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

          pw.Text(
            'Datos personales',
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
                _kv('Nombre completo', alumno.nombreCompleto),
                _kv('Documento (DNI)', alumno.documento),
                _kv('Fecha de nacimiento', _fmtDate(alumno.fechaNacimiento)),
                _kv('Email', alumno.email),
                _kv('Teléfono', alumno.telefono),
              ],
            ),
          ),

          pw.SizedBox(height: 14),
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
                _kv('OwnerAccountId', ownerAccountId),
                _kv('PerfilId', perfilId),
                _kv('Generación', 'Local (sin backend)'),
              ],
            ),
          ),

          pw.SizedBox(height: 18),
          pw.Text(
            'Observaciones',
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
            child: pw.Text(
              'Este documento fue generado por ATENA en el dispositivo del usuario. '
              'Puede reutilizarse para validación interna y descargas previstas.',
              style: pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700),
            ),
          ),
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
