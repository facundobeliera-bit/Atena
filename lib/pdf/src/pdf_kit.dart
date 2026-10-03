// lib/pdf/src/pdf_kit.dart
//
// Sistema de diseño de los PDF de ATENA: paleta, tipografía, marco de página
// (banda de marca arriba y pie con fecha y numeración) y piezas reutilizables
// (secciones, tarjetas, campos, tablas y estados de solicitud).

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_labels.dart';
import 'pdf_recursos.dart';

/// Paleta de los documentos: la misma identidad que la app.
abstract final class PdfPaleta {
  static const PdfColor azul = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor indigo = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor violeta = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor indigoProfundo = PdfColor.fromInt(0xFF312E81);
  static const PdfColor tinta = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor tintaSuave = PdfColor.fromInt(0xFF475569);
  static const PdfColor apagado = PdfColor.fromInt(0xFF64748B);
  static const PdfColor tenue = PdfColor.fromInt(0xFF94A3B8);
  static const PdfColor borde = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor bordeFuerte = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor divisor = PdfColor.fromInt(0xFFEDF0F5);
  static const PdfColor fondo = PdfColor.fromInt(0xFFF7F8FC);
  static const PdfColor tinteMarca = PdfColor.fromInt(0xFFEEF0FE);
  static const PdfColor sobreBanda = PdfColor.fromInt(0xFFE0E7FF);
  static const PdfColor blanco = PdfColors.white;

  /// Gradiente insignia (azul → índigo → violeta).
  static const pw.LinearGradient marca = pw.LinearGradient(
    colors: [azul, indigo, violeta],
    stops: [0, 0.55, 1],
  );

  static const pw.LinearGradient marcaDiagonal = pw.LinearGradient(
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
    colors: [azul, indigo, violeta],
  );

  static const pw.LinearGradient marcaVertical = pw.LinearGradient(
    begin: pw.Alignment.topCenter,
    end: pw.Alignment.bottomCenter,
    colors: [azul, violeta],
  );

  /// Pendiente ámbar, confirmada verde, rechazada roja, cancelada gris.
  static PdfColor estado(EstadoSolicitud e) => switch (e) {
    EstadoSolicitud.pendiente => const PdfColor.fromInt(0xFFD97706),
    EstadoSolicitud.confirmada => const PdfColor.fromInt(0xFF16A34A),
    EstadoSolicitud.rechazada => const PdfColor.fromInt(0xFFDC2626),
    EstadoSolicitud.canceladaPorAlumno ||
    EstadoSolicitud.canceladaPorInstitucion => const PdfColor.fromInt(
      0xFF64748B,
    ),
  };

  static PdfColor mezcla(PdfColor a, PdfColor b, double t) => PdfColor(
    a.red + (b.red - a.red) * t,
    a.green + (b.green - a.green) * t,
    a.blue + (b.blue - a.blue) * t,
  );

  /// Versión clara del color (sobre blanco).
  static PdfColor tinte(PdfColor c, double intensidad) =>
      mezcla(blanco, c, intensidad);

  /// Versión oscura del color (para texto legible sobre su tinte).
  static PdfColor oscuro(PdfColor c, double cantidad) =>
      mezcla(c, PdfColors.black, cantidad);
}

// -----------------------------------------------------------------------------
// Formato
// -----------------------------------------------------------------------------

String _dos(int n) => n.toString().padLeft(2, '0');

/// Fecha mostrable, o null si falta (el modelo guarda 1970 como "sin fecha").
DateTime? fechaValida(DateTime? d) {
  if (d == null || d.millisecondsSinceEpoch == 0 || d.year < 1900) return null;
  return d.isUtc ? d.toLocal() : d;
}

/// "dd/MM/yyyy" o "—".
String fecha(DateTime? d) {
  final f = fechaValida(d);
  if (f == null) return '—';
  return '${_dos(f.day)}/${_dos(f.month)}/${f.year}';
}

/// "dd/MM/yyyy HH:mm" o "—".
String fechaHora(DateTime? d) {
  final f = fechaValida(d);
  if (f == null) return '—';
  return '${fecha(f)} ${_dos(f.hour)}:${_dos(f.minute)}';
}

/// Recorta con "…" si supera [max] caracteres.
String recortar(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max - 1).trimRight()}…';
}

// -----------------------------------------------------------------------------
// Kit de un documento
// -----------------------------------------------------------------------------

/// Marco y piezas de un documento con la marca de ATENA.
class PdfKit {
  PdfKit({
    required this.r,
    required this.t,
    required this.titulo,
    this.subtitulo = '',
    this.formato = PdfPageFormat.a4,
  }) : emitido = DateTime.now(),
       _emblemaClaro = r.emblema(sobreColor: true),
       _emblemaMarca = r.emblema(sobreColor: false);

  static const double margen = 40;
  static const double altoBanda = 104;
  static const double altoBandaCompacta = 40;
  static const double separacionBanda = 22;
  static const double altoPie = 26;
  static const double margenInferior = 22;

  final PdfRecursos r;
  final AppLocalizations t;
  final String titulo;
  final String subtitulo;
  final PdfPageFormat formato;

  /// Momento de generación (pie de página y fecha de emisión).
  final DateTime emitido;

  final pw.ImageProvider? _emblemaClaro;
  final pw.ImageProvider? _emblemaMarca;

  double get anchoContenido => formato.width - margen * 2;

  /// Alto disponible para el contenido de la primera página.
  double get altoContenido =>
      formato.height - altoBanda - separacionBanda - altoPie - margenInferior;

  late final pw.ThemeData _tema = pw.ThemeData.withFont(
    base: r.regular,
    bold: r.bold,
    italic: r.regular,
    boldItalic: r.bold,
  ).copyWith(defaultTextStyle: estilo());

  pw.Document documento() => pw.Document(
    title: linea(titulo),
    subject: linea(subtitulo),
    author: 'ATENA',
    creator: 'ATENA',
    producer: 'ATENA',
  );

  /// Página con banda de marca, pie y salto automático para listas largas.
  pw.MultiPage multipagina(List<pw.Widget> contenido) => pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: formato,
      margin: const pw.EdgeInsets.fromLTRB(margen, 0, margen, margenInferior),
      theme: _tema,
      buildBackground: (ctx) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Align(
          alignment: pw.Alignment.topCenter,
          child: ctx.pageNumber == 1 ? _banda() : _bandaCompacta(),
        ),
      ),
    ),
    maxPages: 500,
    header: (ctx) => pw.SizedBox(
      height:
          (ctx.pageNumber == 1 ? altoBanda : altoBandaCompacta) +
          separacionBanda,
    ),
    footer: _pie,
    build: (_) => contenido,
  );

  // ---------------------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------------------

  pw.TextStyle estilo({
    double tam = 9.5,
    pw.Font? fuente,
    PdfColor color = PdfPaleta.tinta,
    double espaciado = 0,
    double interlineado = 0,
  }) => pw.TextStyle(
    font: fuente ?? r.regular,
    fontSize: tam,
    color: color,
    letterSpacing: espaciado,
    lineSpacing: interlineado,
  );

  /// Texto de una línea, adaptado a la tipografía y recortado.
  String linea(String s, {int max = 140}) => recortar(r.limpiar(s), max);

  /// Texto con saltos de línea, adaptado y recortado.
  String parrafo(String s, {int max = 1600}) =>
      recortar(r.limpiar(s, multilinea: true), max);

  /// Edad en años cumplidos ("7 años"), o '' si no hay fecha de nacimiento.
  String edad(DateTime? nacimiento) {
    final f = fechaValida(nacimiento);
    return f == null ? '' : t.lblEdadAnios(edadEnAnios(f));
  }

  /// Iniciales para el avatar ("LG").
  String iniciales(String nombre, String apellido) {
    String primera(String s) {
      final limpio = r.limpiar(s);
      return limpio.isEmpty ? '' : limpio.substring(0, 1).toUpperCase();
    }

    return '${primera(nombre)}${primera(apellido)}';
  }

  /// Texto que ocupa como mucho [maxLineas] renglones: si no entra en el ancho
  /// disponible, se corta con "…" (nunca se pierde contenido en silencio).
  /// El [contenido] ya debe estar adaptado con [linea].
  pw.Widget texto(
    String contenido, {
    required pw.TextStyle estilo,
    int maxLineas = 1,
    pw.TextAlign? alineacion,
  }) => _TextoAcotado(
    contenido,
    estilo: estilo,
    maxLineas: maxLineas,
    alineacion: alineacion,
  );

  /// Contenido que nunca se parte ni se recorta, aunque el alto esté justo.
  pw.Widget indivisible(pw.Widget hijo) => _Indivisible(child: hijo);

  pw.Widget _valor(
    String contenido, {
    double tam = 10,
    int maxLineas = 2,
    int max = 140,
    pw.Font? fuente,
    PdfColor color = PdfPaleta.tinta,
  }) {
    final v = linea(contenido, max: max);
    final sinDato = v.isEmpty || v == '—';
    return texto(
      sinDato ? '—' : v,
      maxLineas: maxLineas,
      estilo: estilo(
        tam: tam,
        fuente: fuente ?? r.semiBold,
        color: sinDato ? PdfPaleta.tenue : color,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Marco de página
  // ---------------------------------------------------------------------------

  pw.Widget _logotipo({required double alto}) {
    final emblema = _emblemaClaro;
    final tam = alto * 0.74;
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (emblema != null) ...[
          pw.Image(emblema, width: alto * 1.3, height: alto * 1.3),
          pw.SizedBox(width: alto * 0.42),
        ],
        pw.Text(
          'ATENA',
          style: pw.TextStyle(
            font: r.cinzel,
            fontSize: tam,
            letterSpacing: tam * 0.18,
            color: PdfPaleta.blanco,
          ),
        ),
      ],
    );
  }

  pw.Widget _banda() {
    final emblema = _emblemaClaro;
    return pw.Container(
      width: formato.width,
      height: altoBanda,
      decoration: const pw.BoxDecoration(gradient: PdfPaleta.marca),
      child: pw.Stack(
        fit: pw.StackFit.expand,
        children: [
          if (emblema != null)
            pw.Positioned(
              right: margen - 30,
              top: -34,
              child: pw.Opacity(
                opacity: 0.1,
                child: pw.Image(emblema, width: 170, height: 170),
              ),
            ),
          // Logotipo arriba y títulos abajo, cada uno anclado a su borde: así
          // ninguno desplaza al otro aunque cambie el alto del texto.
          pw.Positioned(left: margen, top: 18, child: _logotipo(alto: 18)),
          pw.Positioned(
            left: margen,
            right: margen,
            bottom: 16,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                texto(
                  linea(titulo, max: 120),
                  estilo: estilo(
                    tam: 19,
                    fuente: r.bold,
                    color: PdfPaleta.blanco,
                  ),
                ),
                if (subtitulo.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  texto(
                    linea(subtitulo, max: 200),
                    estilo: estilo(tam: 9.5, color: PdfPaleta.sobreBanda),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _bandaCompacta() => pw.Container(
    width: formato.width,
    height: altoBandaCompacta,
    alignment: pw.Alignment.centerLeft,
    padding: const pw.EdgeInsets.symmetric(horizontal: margen),
    decoration: const pw.BoxDecoration(gradient: PdfPaleta.marca),
    child: pw.Row(
      children: [
        _logotipo(alto: 13),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: texto(
            linea(titulo, max: 120),
            alineacion: pw.TextAlign.right,
            estilo: estilo(
              tam: 8.5,
              fuente: r.semiBold,
              color: PdfPaleta.sobreBanda,
            ),
          ),
        ),
      ],
    ),
  );

  pw.Widget _pie(pw.Context ctx) {
    final emblema = _emblemaMarca;
    final estiloPie = estilo(tam: 7.2, color: PdfPaleta.apagado);
    return pw.SizedBox(
      height: altoPie,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(height: 0.6, color: PdfPaleta.borde),
          pw.SizedBox(height: 7),
          pw.Row(
            children: [
              if (emblema != null) ...[
                pw.Image(emblema, width: 10, height: 10),
                pw.SizedBox(width: 5),
              ],
              pw.Expanded(
                child: pw.Text(
                  linea(t.pdfGeneradoCon(fechaHora(emitido))),
                  maxLines: 1,
                  style: estiloPie,
                ),
              ),
              pw.Text(
                linea(t.pdfPagina(ctx.pageNumber, ctx.pagesCount)),
                style: estilo(
                  tam: 7.2,
                  fuente: r.semiBold,
                  color: PdfPaleta.apagado,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Piezas
  // ---------------------------------------------------------------------------

  /// Título de sección con acento de marca y, opcionalmente, un contador.
  pw.Widget seccion(String titulo, {String? detalle, double arriba = 18}) {
    final extra = detalle == null ? '' : linea(detalle, max: 60);
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: arriba, bottom: 9),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 14,
            decoration: const pw.BoxDecoration(
              gradient: PdfPaleta.marcaVertical,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 7),
          pw.Text(
            linea(titulo, max: 80),
            style: estilo(tam: 11.5, fuente: r.bold),
          ),
          if (extra.isNotEmpty) ...[
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: const pw.BoxDecoration(
                color: PdfPaleta.tinteMarca,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6.5)),
              ),
              child: pw.Text(
                extra,
                style: estilo(
                  tam: 7.5,
                  fuente: r.semiBold,
                  color: PdfPaleta.indigo,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta de bordes redondeados. Con [gradiente] se pinta con los colores
  /// de la marca (sin borde); si no, con [fondo] y un borde suave.
  pw.Widget tarjeta(
    pw.Widget hijo, {
    pw.EdgeInsets padding = const pw.EdgeInsets.all(14),
    PdfColor fondo = PdfPaleta.blanco,
    pw.Gradient? gradiente,
  }) => pw.Container(
    width: double.infinity,
    padding: padding,
    decoration: pw.BoxDecoration(
      color: gradiente == null ? fondo : null,
      gradient: gradiente,
      border: gradiente == null
          ? pw.Border.all(color: PdfPaleta.borde, width: 0.8)
          : null,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: _Indivisible(child: hijo),
  );

  /// Etiqueta corta en versalitas ("FECHA DE NACIMIENTO").
  pw.Widget etiqueta(
    String rotulo, {
    PdfColor color = PdfPaleta.apagado,
    double tam = 6.8,
  }) => pw.Text(
    linea(rotulo, max: 60).toUpperCase(),
    maxLines: 1,
    style: estilo(tam: tam, fuente: r.semiBold, color: color, espaciado: 0.7),
  );

  /// Dato con su etiqueta arriba. Vacío se muestra como "—".
  pw.Widget campo(
    String titulo,
    String contenido, {
    int maxLineas = 2,
    double tam = 10,
    int max = 140,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      etiqueta(titulo),
      pw.SizedBox(height: 3),
      _valor(contenido, tam: tam, maxLineas: maxLineas, max: max),
    ],
  );

  /// Dato principal, más grande y en color de marca (p. ej. un código).
  pw.Widget campoDestacado(String titulo, String contenido) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      etiqueta(titulo),
      pw.SizedBox(height: 2),
      pw.Text(
        contenido.isEmpty ? '—' : linea(contenido, max: 24),
        maxLines: 1,
        style: estilo(
          tam: 15,
          fuente: r.bold,
          color: PdfPaleta.indigoProfundo,
          espaciado: 1.6,
        ),
      ),
    ],
  );

  /// Filas de campos; cada celda ocupa el mismo ancho dentro de su fila.
  pw.Widget grilla(
    List<List<pw.Widget>> filas, {
    double separacionV = 13,
    double separacionH = 18,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < filas.length; i++) ...[
        if (i > 0) pw.SizedBox(height: separacionV),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < filas[i].length; j++) ...[
              if (j > 0) pw.SizedBox(width: separacionH),
              pw.Expanded(child: filas[i][j]),
            ],
          ],
        ),
      ],
    ],
  );

  /// Bloques lado a lado con la misma altura (la del más alto). Cada bloque
  /// usa el ancho indicado en [anchos]; sin indicación, se reparten por igual.
  pw.Widget filaIgualada(
    List<pw.Widget> hijos, {
    List<pw.TableColumnWidth> anchos = const [],
    double separacion = 12,
  }) {
    final columnas = <int, pw.TableColumnWidth>{};
    final celdas = <pw.Widget>[];
    for (var i = 0; i < hijos.length; i++) {
      if (i > 0) {
        columnas[celdas.length] = pw.FixedColumnWidth(separacion);
        celdas.add(pw.SizedBox());
      }
      columnas[celdas.length] = i < anchos.length
          ? anchos[i]
          : const pw.FlexColumnWidth();
      // Margen mínimo para que el borde de la tarjeta no quede recortado.
      celdas.add(
        pw.Padding(padding: const pw.EdgeInsets.all(0.5), child: hijos[i]),
      );
    }
    return pw.Table(
      columnWidths: columnas,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      children: [pw.TableRow(children: celdas)],
    );
  }

  pw.Widget divisor({double vertical = 10}) => pw.Padding(
    padding: pw.EdgeInsets.symmetric(vertical: vertical),
    child: pw.Container(height: 0.6, color: PdfPaleta.divisor),
  );

  /// Chip de estado: punto de color + texto (no depende solo del color).
  pw.Widget chipEstado(EstadoSolicitud e) {
    final base = PdfPaleta.estado(e);
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(6, 2.6, 7.5, 2.6),
      decoration: pw.BoxDecoration(
        color: PdfPaleta.tinte(base, 0.12),
        border: pw.Border.all(color: PdfPaleta.tinte(base, 0.4), width: 0.6),
        // El radio no puede superar la mitad del alto del chip.
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 4.6,
            height: 4.6,
            decoration: pw.BoxDecoration(
              color: base,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            linea(t.estadoSolicitud(e)),
            maxLines: 1,
            style: estilo(
              tam: 7.3,
              fuente: r.semiBold,
              color: PdfPaleta.oscuro(base, 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Ícono vectorial del estado (círculo de color con símbolo blanco).
  pw.Widget iconoEstado(EstadoSolicitud e, {double tam = 28}) {
    final color = PdfPaleta.estado(e);
    return pw.CustomPaint(
      size: PdfPoint(tam, tam),
      painter: (PdfGraphics canvas, PdfPoint size) {
        final u = size.x / 24;
        // Coordenadas de un ícono de 24 × 24 con el eje Y hacia abajo.
        void moverA(double x, double y) => canvas.moveTo(x * u, (24 - y) * u);
        void lineaA(double x, double y) => canvas.lineTo(x * u, (24 - y) * u);

        canvas
          ..setFillColor(color)
          ..drawEllipse(12 * u, 12 * u, 12 * u, 12 * u)
          ..fillPath()
          ..setStrokeColor(PdfPaleta.blanco)
          ..setLineWidth(2.1 * u)
          ..setLineCap(PdfLineCap.round)
          ..setLineJoin(PdfLineJoin.round);
        switch (e) {
          case EstadoSolicitud.confirmada:
            moverA(7, 12.4);
            lineaA(10.6, 16);
            lineaA(17.2, 8.8);
          case EstadoSolicitud.pendiente:
            moverA(12, 6.8);
            lineaA(12, 12.4);
            lineaA(15.6, 14.6);
          case EstadoSolicitud.rechazada:
            moverA(8.4, 8.4);
            lineaA(15.6, 15.6);
            moverA(15.6, 8.4);
            lineaA(8.4, 15.6);
          case EstadoSolicitud.canceladaPorAlumno ||
              EstadoSolicitud.canceladaPorInstitucion:
            moverA(7.6, 12);
            lineaA(16.4, 12);
        }
        canvas.strokePath();
      },
    );
  }

  /// Avatar circular: foto con aro de marca, o iniciales sobre el gradiente.
  pw.Widget avatar({
    required String iniciales,
    pw.ImageProvider? imagen,
    double tam = 92,
  }) {
    if (imagen != null) {
      return pw.Container(
        width: tam,
        height: tam,
        padding: const pw.EdgeInsets.all(3),
        decoration: const pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          gradient: PdfPaleta.marcaDiagonal,
        ),
        child: pw.Container(
          padding: const pw.EdgeInsets.all(2),
          decoration: const pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: PdfPaleta.blanco,
          ),
          child: pw.ClipOval(child: pw.Image(imagen, fit: pw.BoxFit.cover)),
        ),
      );
    }
    final emblema = _emblemaClaro;
    return pw.Container(
      width: tam,
      height: tam,
      alignment: pw.Alignment.center,
      decoration: const pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        gradient: PdfPaleta.marcaDiagonal,
      ),
      child: iniciales.isEmpty && emblema != null
          ? pw.Image(emblema, width: tam * 0.6, height: tam * 0.6)
          : pw.Text(
              iniciales,
              style: estilo(
                tam: tam * 0.34,
                fuente: r.bold,
                color: PdfPaleta.blanco,
                espaciado: 1,
              ),
            ),
    );
  }

  /// Texto citado (mensajes y respuestas) con acento a la izquierda. Si es
  /// largo, continúa en la página siguiente.
  pw.Widget cita(String contenido, {PdfColor acento = PdfPaleta.indigo}) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: pw.BoxDecoration(
          color: PdfPaleta.fondo,
          border: pw.Border(left: pw.BorderSide(color: acento, width: 2.6)),
        ),
        child: pw.Text(
          parrafo(contenido),
          overflow: pw.TextOverflow.span,
          style: estilo(
            tam: 9.5,
            color: PdfPaleta.tintaSuave,
            interlineado: 2.5,
          ),
        ),
      );

  /// Recuadro para listas vacías.
  pw.Widget vacio(String mensaje) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 22),
    decoration: pw.BoxDecoration(
      color: PdfPaleta.fondo,
      border: pw.Border.all(
        color: PdfPaleta.bordeFuerte,
        width: 0.8,
        style: pw.BorderStyle.dashed,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Text(
      linea(mensaje),
      textAlign: pw.TextAlign.center,
      style: estilo(tam: 9.5, color: PdfPaleta.apagado),
    ),
  );

  /// Nota final en letra chica, centrada.
  pw.Widget aclaracion(String texto) => pw.Center(
    child: pw.Text(
      linea(texto, max: 300),
      textAlign: pw.TextAlign.center,
      style: estilo(tam: 7.8, color: PdfPaleta.apagado),
    ),
  );

  /// Tabla con encabezado tintado (se repite en cada página), filas
  /// alternadas y divisores suaves. Puede continuar en varias páginas.
  pw.Widget tabla({
    required List<String> encabezados,
    required Map<int, pw.TableColumnWidth> anchos,
    required List<List<pw.Widget>> filas,
  }) => pw.Table(
    columnWidths: anchos,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfPaleta.divisor, width: 0.7),
      bottom: pw.BorderSide(color: PdfPaleta.borde, width: 0.7),
    ),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfPaleta.tinteMarca),
        children: [
          for (final e in encabezados)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 7,
              ),
              child: pw.Text(
                linea(e, max: 40).toUpperCase(),
                maxLines: 1,
                style: estilo(
                  tam: 6.8,
                  fuente: r.bold,
                  color: PdfPaleta.indigoProfundo,
                  espaciado: 0.6,
                ),
              ),
            ),
        ],
      ),
      for (var i = 0; i < filas.length; i++)
        pw.TableRow(
          decoration: i.isOdd
              ? const pw.BoxDecoration(color: PdfPaleta.fondo)
              : null,
          children: [
            for (final celda in filas[i])
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 6,
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: celda,
                ),
              ),
          ],
        ),
    ],
  );

  /// Celda de texto (vacía se muestra como "—").
  pw.Widget celda(
    String texto, {
    bool fuerte = false,
    int maxLineas = 2,
    double tam = 8.6,
    PdfColor color = PdfPaleta.tinta,
  }) => _valor(
    texto,
    tam: tam,
    maxLineas: maxLineas,
    max: 160,
    fuente: fuerte ? r.semiBold : r.regular,
    color: color,
  );
}

/// Contenido que nunca se parte ni se recorta: siempre recibe el alto que
/// necesita y queda alineado arriba.
///
/// En el paquete `pdf` una columna deja afuera a los hijos que no entran en el
/// alto disponible (para seguir en otra página). Dentro de una tarjeta de alto
/// fijo eso es un riesgo: una diferencia de redondeo alcanzaría para que
/// desaparezca el último dato.
class _Indivisible extends pw.SingleChildWidget {
  _Indivisible({required pw.Widget child}) : super(child: child);

  @override
  bool get canSpan => false;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final hijo = child!;
    hijo.layout(
      context,
      pw.BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    final medida = hijo.box!;
    final alto = constraints.constrainHeight(medida.height);
    box = PdfRect(0, 0, constraints.constrainWidth(medida.width), alto);
    hijo.box = PdfRect(0, alto - medida.height, medida.width, medida.height);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}

/// Texto limitado a una cantidad de renglones que, si no entra en el ancho
/// disponible, termina en "…".
///
/// El paquete `pdf` solo sabe descartar los renglones que sobran; acá se busca
/// con el propio motor de composición el texto más largo que entra.
class _TextoAcotado extends pw.SingleChildWidget {
  _TextoAcotado(
    this.texto, {
    required this.estilo,
    required this.maxLineas,
    this.alineacion,
  });

  final String texto;
  final pw.TextStyle estilo;
  final int maxLineas;
  final pw.TextAlign? alineacion;

  pw.Text? _hijo;
  double? _anchoMedido;

  @override
  pw.Widget? get child => _hijo;

  @override
  bool get canSpan => false;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final ancho = constraints.maxWidth;
    var hijo = _hijo;
    if (hijo == null || _anchoMedido != ancho) {
      hijo = pw.Text(
        ancho.isFinite ? _ajustado(context, ancho) : texto,
        style: estilo,
        textAlign: alineacion,
        maxLines: maxLineas,
      );
      _hijo = hijo;
      _anchoMedido = ancho;
    }
    hijo.layout(context, constraints, parentUsesSize: parentUsesSize);
    box = hijo.box;
  }

  /// El texto completo si entra en [maxLineas] renglones de [ancho]; si no, el
  /// comienzo más largo que entra seguido de "…".
  String _ajustado(pw.Context context, double ancho) {
    final limites = pw.BoxConstraints(maxWidth: ancho);
    double alto(String s) {
      final prueba = pw.Text(s, style: estilo)..layout(context, limites);
      return prueba.box!.height;
    }

    final interlineado = estilo.lineSpacing ?? 0;
    final maximo =
        alto('X') * maxLineas + interlineado * (maxLineas - 1) + 0.01;
    if (alto(texto) <= maximo) return texto;

    // Búsqueda binaria de la cantidad de caracteres que entran.
    var entran = 0;
    var noEntran = texto.length;
    while (noEntran - entran > 1) {
      final medio = (entran + noEntran) ~/ 2;
      if (alto('${texto.substring(0, medio).trimRight()}…') <= maximo) {
        entran = medio;
      } else {
        noEntran = medio;
      }
    }
    return '${texto.substring(0, entran).trimRight()}…';
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}
