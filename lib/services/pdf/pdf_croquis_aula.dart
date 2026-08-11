// lib/services/pdf/pdf_croquis_aula.dart
//
// ATENA – PDF CROQUIS DE AULA (INSTITUCIÓN) – V1
//
// - Grilla 10x10
// - Solo nombres
// - Soporte de grupos (bloques) superpuestos
//
// DEPENDE DE:
// - PdfBase
// - CroquisAula

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/croquis/croquis_aula.dart';
import 'pdf_base.dart';

class PdfCroquisAula {
  static pw.Document build({
    required CroquisAula croquis,
    required String institucionNombre,
    required String generadoPor, // "Institución" | "Sistema"
  }) {
    final instNombre = institucionNombre.trim().isEmpty
        ? 'Institución'
        : institucionNombre.trim();

    final aula = croquis.aula.trim().isEmpty ? '—' : croquis.aula.trim();
    final turno = croquis.turno.trim().isEmpty ? '—' : croquis.turno.trim();

    final contenido = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Aula/Grupo: $aula',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.Text(
              'Turno: $turno',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      _gridWithGroups(croquis),
      pw.SizedBox(height: 10),
      pw.Text(
        'Referencia: cada celda representa un lugar. El croquis se usa con fines organizativos.',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ];

    return PdfBase.build(
      PdfBaseParams(
        titulo: 'Croquis de aula',
        subtitulo: '$instNombre · $aula · $turno',
        generadoPor: generadoPor,
        ownerAccountId: '', // institucional (no owner único)
        perfilId: croquis.institucionId,
        contenido: contenido,
      ),
    );
  }

  static pw.Widget _gridWithGroups(CroquisAula c) {
    final filas = c.filas;
    final cols = c.columnas;

    // En 10x10 entra bien en A4.
    const double cellW = 48;
    const double cellH = 24;

    final gridWidth = cols * cellW;
    final gridHeight = filas * cellH;

    final grid = pw.Container(
      width: gridWidth,
      height: gridHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
      ),
      child: pw.Column(
        children: List.generate(filas, (r) {
          return pw.Row(
            children: List.generate(cols, (col) {
              final name = (c.nombreEn(r, col) ?? '').trim();
              return pw.Container(
                width: cellW,
                height: cellH,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(
                      color: PdfColors.grey300,
                      width: col == cols - 1 ? 0 : 0.6,
                    ),
                    bottom: pw.BorderSide(
                      color: PdfColors.grey300,
                      width: r == filas - 1 ? 0 : 0.6,
                    ),
                  ),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Text(
                    name.isEmpty ? '' : _truncate(name, 18),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7.5),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );

    final overlays = <pw.Widget>[];
    for (final g in c.grupos) {
      final top = (g.fila < 0 ? 0 : g.fila) * cellH;
      final left = (g.col < 0 ? 0 : g.col) * cellW;

      final ancho = (g.ancho <= 0 ? 1 : g.ancho);
      final alto = (g.alto <= 0 ? 1 : g.alto);

      final w = (left + ancho * cellW > gridWidth)
          ? (gridWidth - left)
          : (ancho * cellW);
      final h = (top + alto * cellH > gridHeight)
          ? (gridHeight - top)
          : (alto * cellH);

      final titulo = g.titulo.trim();

      overlays.add(
        pw.Positioned(
          left: left,
          top: top,
          child: pw.Container(
            width: w,
            height: h,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey700, width: 1),
              color: PdfColors.blueGrey50,
            ),
            child: titulo.isEmpty
                ? pw.SizedBox()
                : pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Align(
                      alignment: pw.Alignment.topLeft,
                      child: pw.Text(
                        _truncate(titulo, 24),
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    return pw.Center(child: pw.Stack(children: [grid, ...overlays]));
  }

  static String _truncate(String s, int max) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }
}
