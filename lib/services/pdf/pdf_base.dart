// lib/services/pdf/pdf_base.dart
//
// ATENA – PDF BASE (CANÓNICO + BRANDING)
//
// RESPONSABILIDAD:
// - Layout base de TODOS los PDFs
// - Header institucional
// - Footer legal
// - Colores
// - Tipografía
//
// ÚNICA FUENTE DE VERDAD VISUAL PARA PDFs
//
// Los PDFs individuales:
// - SOLO definen contenido
// - NO manejan estilo global
//
// ✅ FIX (enero 2026):
// - Footer: no imprime owner/perfil si vienen vacíos (evita “Owner:  | Perfil:”).
// - Sanitiza strings (trim) para evitar renders raros.
// - Mantiene DefaultTextStyle como fuente de verdad del body.
// - Mantiene ThemeData.withFont (Helvetica) estable.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBaseParams {
  final String titulo;
  final String subtitulo;
  final String generadoPor;

  /// Contexto (auditoría / backend-ready)
  final String ownerAccountId;
  final String perfilId;

  final List<pw.Widget> contenido;

  const PdfBaseParams({
    required this.titulo,
    required this.subtitulo,
    required this.generadoPor,
    required this.ownerAccountId,
    required this.perfilId,
    required this.contenido,
  });
}

class PdfBase {
  // ─────────────────────────────────────────────
  // BRANDING ATENA
  // ─────────────────────────────────────────────

  static const String _brandName = 'ATENA';

  static const PdfColor _colorPrimary = PdfColor.fromInt(0xFF1E3A8A); // azul
  static const PdfColor _colorText = PdfColors.black;
  static const PdfColor _colorMuted = PdfColors.grey600;
  static const PdfColor _colorBorder = PdfColors.grey300;

  static String _t(String v, {String fallback = '—'}) {
    final s = v.trim();
    return s.isEmpty ? fallback : s;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  static pw.Document build(PdfBaseParams params) {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        pageTheme: _pageTheme(),
        header: (_) => _header(params),
        footer: (ctx) => _footer(params, ctx),
        build: (_) => [
          // Fuente de verdad del estilo base para todo el contenido.
          pw.DefaultTextStyle(
            style: const pw.TextStyle(fontSize: 9, color: _colorText),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: params.contenido,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  // ─────────────────────────────────────────────
  // PAGE THEME
  // ─────────────────────────────────────────────

  static pw.PageTheme _pageTheme() {
    return pw.PageTheme(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  static pw.Widget _header(PdfBaseParams p) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _colorBorder, width: 0.8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _brandName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _colorPrimary,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _t(p.titulo),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _t(p.subtitulo),
                  style: pw.TextStyle(fontSize: 9, color: _colorMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────

  static pw.Widget _footer(PdfBaseParams p, pw.Context ctx) {
    final owner = p.ownerAccountId.trim();
    final perfil = p.perfilId.trim();

    final hasTrace = owner.isNotEmpty || perfil.isNotEmpty;
    final traceText = hasTrace
        ? 'Owner: ${owner.isEmpty ? '—' : owner} | Perfil: ${perfil.isEmpty ? '—' : perfil}'
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Documento generado por $_brandName – ${_t(p.generadoPor)}. '
            'Uso administrativo. No sustituye documentación oficial.',
            style: pw.TextStyle(fontSize: 7, color: _colorMuted),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                traceText ?? 'Trazabilidad: —',
                style: pw.TextStyle(fontSize: 7, color: _colorMuted),
              ),
              pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: _colorMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
