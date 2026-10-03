// lib/pdf/src/pdf_croquis.dart
//
// Croquis de aula en A4 horizontal: frente del aula arriba, grilla de bancos
// con el nombre de cada alumno (los libres se ven atenuados) y leyenda con el
// total de lugares. Siempre ocupa una sola página.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import 'pdf_kit.dart';
import 'pdf_recursos.dart';

const double _altoFrente = 24;
const double _altoLeyenda = 16;
const double _separacion = 13;
const double _hueco = 7;

Future<Uint8List> pdfCroquis({
  required PdfRecursos r,
  required AppLocalizations t,
  required String institucionNombre,
  required Croquis croquis,
}) {
  final k = PdfKit(
    r: r,
    t: t,
    titulo: t.pdfCroquisTitulo,
    subtitulo: [
      croquis.nombre.trim(),
      institucionNombre.trim(),
    ].where((s) => s.isNotEmpty).join(' · '),
    formato: PdfPageFormat.a4.landscape,
  );
  // Un punto menos que el alto libre: garantiza que todo entre en la página.
  final alto = k.altoContenido - 1;

  final doc = k.documento()
    ..addPage(
      k.multipagina([
        k.indivisible(
          pw.SizedBox(
            width: k.anchoContenido,
            height: alto,
            child: _aula(k, croquis, ancho: k.anchoContenido, alto: alto),
          ),
        ),
      ]),
    );
  return doc.save();
}

pw.Widget _aula(
  PdfKit k,
  Croquis c, {
  required double ancho,
  required double alto,
}) {
  final filas = c.filas.clamp(1, Croquis.maxFilas);
  final columnas = c.columnas.clamp(1, Croquis.maxColumnas);
  String nombre(int fila, int columna) {
    final i = fila * columnas + columna;
    return i < c.asientos.length ? k.linea(c.asientos[i], max: 80) : '';
  }

  final altoGrilla = alto - _altoFrente - _altoLeyenda - _separacion * 2;
  final anchoBanco = math.min(
    132.0,
    (ancho - _hueco * (columnas - 1)) / columnas,
  );
  final altoBanco = math.min(72.0, (altoGrilla - _hueco * (filas - 1)) / filas);

  var ocupados = 0;
  final grilla = <pw.Widget>[];
  for (var f = 0; f < filas; f++) {
    final bancos = <pw.Widget>[];
    for (var col = 0; col < columnas; col++) {
      final alumno = nombre(f, col);
      if (alumno.isNotEmpty) ocupados++;
      if (col > 0) bancos.add(pw.SizedBox(width: _hueco));
      bancos.add(
        _banco(
          k,
          numero: f * columnas + col + 1,
          alumno: alumno,
          ancho: anchoBanco,
          alto: altoBanco,
        ),
      );
    }
    if (f > 0) grilla.add(pw.SizedBox(height: _hueco));
    grilla.add(pw.Row(mainAxisSize: pw.MainAxisSize.min, children: bancos));
  }

  return pw.Column(
    children: [
      _frente(k, ancho),
      pw.SizedBox(height: _separacion),
      pw.Expanded(
        // Pegada al frente del aula, como se ve desde el pizarrón.
        child: pw.Align(
          alignment: pw.Alignment.topCenter,
          // La grilla ocupa justo el alto disponible: no debe perder filas.
          child: k.indivisible(
            pw.Column(mainAxisSize: pw.MainAxisSize.min, children: grilla),
          ),
        ),
      ),
      pw.SizedBox(height: _separacion),
      pw.SizedBox(
        height: _altoLeyenda,
        child: _leyenda(k, total: filas * columnas, ocupados: ocupados),
      ),
    ],
  );
}

/// Barra que marca dónde está el frente del aula (pizarrón).
pw.Widget _frente(PdfKit k, double ancho) => pw.Container(
  width: math.min(ancho * 0.5, 380),
  height: _altoFrente,
  alignment: pw.Alignment.center,
  decoration: const pw.BoxDecoration(
    gradient: PdfPaleta.marca,
    borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
  ),
  child: pw.Text(
    k.linea(k.t.pdfFrenteAula, max: 50).toUpperCase(),
    maxLines: 1,
    style: k.estilo(
      tam: 8,
      fuente: k.r.bold,
      color: PdfPaleta.blanco,
      espaciado: 2.2,
    ),
  ),
);

pw.BoxDecoration _decoracionBanco({required bool ocupado, double radio = 7}) =>
    pw.BoxDecoration(
      color: ocupado ? PdfPaleta.blanco : PdfPaleta.fondo,
      border: pw.Border.all(
        color: ocupado
            ? PdfPaleta.tinte(PdfPaleta.indigo, 0.55)
            : PdfPaleta.bordeFuerte,
        width: ocupado ? 0.9 : 0.7,
        style: ocupado ? pw.BorderStyle.solid : pw.BorderStyle.dashed,
      ),
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(radio)),
    );

pw.Widget _banco(
  PdfKit k, {
  required int numero,
  required String alumno,
  required double ancho,
  required double alto,
}) {
  final ocupado = alumno.isNotEmpty;
  // La letra acompaña el tamaño del banco (grillas de 1 × 1 a 10 × 10).
  final tam = math.min(ancho / 8.2, alto / 3.3).clamp(6.5, 10.5).toDouble();
  // El número solo se muestra si no puede tocar un nombre de dos renglones.
  final conNumero = alto >= 48 && ancho >= 50;

  return pw.Container(
    width: ancho,
    height: alto,
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: _decoracionBanco(ocupado: ocupado),
    child: pw.Stack(
      children: [
        pw.Center(
          child: k.texto(
            ocupado ? alumno : k.linea(k.t.pdfLugarLibre),
            alineacion: pw.TextAlign.center,
            maxLineas: 2,
            estilo: ocupado
                ? k.estilo(tam: tam, fuente: k.r.semiBold)
                : k.estilo(tam: tam * 0.86, color: PdfPaleta.tenue),
          ),
        ),
        if (conNumero)
          pw.Positioned(
            left: 0,
            top: 0,
            child: pw.Text(
              '$numero',
              style: k.estilo(
                tam: 5.8,
                fuente: k.r.semiBold,
                color: ocupado ? PdfPaleta.indigo : PdfPaleta.tenue,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Referencias (ocupado / libre) y totales.
pw.Widget _leyenda(PdfKit k, {required int total, required int ocupados}) {
  final t = k.t;
  final texto = k.estilo(tam: 8, color: PdfPaleta.tintaSuave);

  List<pw.Widget> referencia(String etiqueta, {required bool ocupado}) => [
    pw.Container(
      width: 15,
      height: 10,
      decoration: _decoracionBanco(ocupado: ocupado, radio: 3),
    ),
    pw.SizedBox(width: 5),
    pw.Text(k.linea(etiqueta, max: 30), style: texto),
  ];

  List<pw.Widget> cantidad(String etiqueta, int n) => [
    pw.Text(k.linea(etiqueta, max: 30), style: texto),
    pw.SizedBox(width: 4),
    pw.Text('$n', style: k.estilo(tam: 9, fuente: k.r.bold)),
  ];

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      ...referencia(t.pdfLugarOcupado, ocupado: true),
      pw.SizedBox(width: 16),
      ...referencia(t.pdfLugarLibre, ocupado: false),
      pw.Container(
        width: 0.7,
        height: 11,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18),
        color: PdfPaleta.bordeFuerte,
      ),
      ...cantidad(t.pdfLugares, total),
      pw.SizedBox(width: 16),
      ...cantidad(t.pdfOcupados, ocupados),
      pw.SizedBox(width: 16),
      ...cantidad(t.pdfLibres, total - ocupados),
    ],
  );
}
