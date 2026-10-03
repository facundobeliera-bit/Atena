// lib/pdf/src/pdf_comprobante.dart
//
// Comprobante de una solicitud de vacante: código, estado actual destacado,
// vacante pedida, alumno, mensajes e historial de cambios.

import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_labels.dart';
import 'pdf_kit.dart';
import 'pdf_recursos.dart';

Future<Uint8List> pdfComprobante({
  required PdfRecursos r,
  required AppLocalizations t,
  required Solicitud solicitud,
}) {
  final s = solicitud;
  final k = PdfKit(
    r: r,
    t: t,
    titulo: t.pdfComprobanteTitulo,
    subtitulo: s.institucionNombre,
  );
  final historial = [...s.historial]
    ..sort((a, b) => a.fecha.compareTo(b.fecha));

  final doc = k.documento()
    ..addPage(
      k.multipagina([
        _resumen(k, s),
        pw.SizedBox(height: 12),
        _estadoActual(k, s.estado),
        pw.SizedBox(height: 12),
        _vacanteYAlumno(k, s),
        // Antes de cada sección se pide lugar para el título y algo de
        // contenido: si no lo hay, la sección empieza en otra página.
        if (s.mensaje.trim().isNotEmpty) ...[
          pw.NewPage(freeSpace: 90),
          k.seccion(t.pdfMensajeAlumno),
          k.cita(s.mensaje, acento: PdfPaleta.azul),
        ],
        if (s.respuesta.trim().isNotEmpty) ...[
          pw.NewPage(freeSpace: 90),
          k.seccion(t.pdfRespuestaInstitucion),
          k.cita(s.respuesta, acento: PdfPaleta.violeta),
        ],
        if (historial.isNotEmpty) ...[
          pw.NewPage(freeSpace: 110),
          k.seccion(t.pdfHistorial),
          _tablaHistorial(k, historial),
        ],
        pw.SizedBox(height: 18),
        k.aclaracion(t.pdfComprobanteAclaracion),
      ]),
    );
  return doc.save();
}

/// Código legible: últimos 8 caracteres del id, en mayúsculas.
String codigoSolicitud(String id) {
  final alfanumerico = id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
  final desde = alfanumerico.length > 8 ? alfanumerico.length - 8 : 0;
  return alfanumerico.substring(desde).toUpperCase();
}

String _descripcionEstado(AppLocalizations t, EstadoSolicitud e) => switch (e) {
  EstadoSolicitud.pendiente => t.pdfEstadoDescPendiente,
  EstadoSolicitud.confirmada => t.pdfEstadoDescConfirmada,
  EstadoSolicitud.rechazada => t.pdfEstadoDescRechazada,
  EstadoSolicitud.canceladaPorAlumno => t.pdfEstadoDescCanceladaAlumno,
  EstadoSolicitud.canceladaPorInstitucion =>
    t.pdfEstadoDescCanceladaInstitucion,
};

/// Encabezado tipo ticket: código, fecha de envío y de emisión.
pw.Widget _resumen(PdfKit k, Solicitud s) {
  final t = k.t;
  pw.Widget separador() => pw.Container(
    width: 0.7,
    height: 30,
    margin: const pw.EdgeInsets.symmetric(horizontal: 14),
    color: PdfPaleta.borde,
  );
  const radio = pw.BorderRadius.all(pw.Radius.circular(10));

  return pw.Container(
    decoration: const pw.BoxDecoration(
      color: PdfPaleta.blanco,
      borderRadius: radio,
    ),
    foregroundDecoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfPaleta.borde, width: 0.8),
      borderRadius: radio,
    ),
    child: pw.ClipRRect(
      horizontalRadius: 10,
      verticalRadius: 10,
      child: pw.Column(
        children: [
          pw.Container(
            height: 4,
            decoration: const pw.BoxDecoration(gradient: PdfPaleta.marca),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 13),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: k.campoDestacado(t.pdfCodigo, codigoSolicitud(s.id)),
                ),
                separador(),
                pw.Expanded(
                  child: k.campo(t.pdfEnviadaEl, fechaHora(s.creadaEl)),
                ),
                separador(),
                pw.Expanded(
                  child: k.campo(t.pdfEmitidoEl, fechaHora(k.emitido)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Estado actual, destacado con su color, ícono y explicación.
pw.Widget _estadoActual(PdfKit k, EstadoSolicitud e) {
  final t = k.t;
  final color = PdfPaleta.estado(e);
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 12, 16, 12),
    decoration: pw.BoxDecoration(
      color: PdfPaleta.tinte(color, 0.08),
      border: pw.Border.all(color: PdfPaleta.tinte(color, 0.35), width: 0.8),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Row(
      children: [
        k.iconoEstado(e, tam: 30),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              k.etiqueta(
                t.pdfEstadoActual,
                color: PdfPaleta.oscuro(color, 0.15),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                k.linea(t.estadoSolicitud(e)),
                style: k.estilo(
                  tam: 13,
                  fuente: k.r.bold,
                  color: PdfPaleta.oscuro(color, 0.3),
                ),
              ),
              pw.SizedBox(height: 1.5),
              pw.Text(
                k.linea(_descripcionEstado(t, e)),
                style: k.estilo(tam: 9, color: PdfPaleta.tintaSuave),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _encabezadoTarjeta(
  PdfKit k, {
  required String etiqueta,
  required String titulo,
  String detalle = '',
}) {
  final principal = k.linea(titulo);
  final secundario = k.linea(detalle);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      k.etiqueta(etiqueta, color: PdfPaleta.indigo),
      pw.SizedBox(height: 6),
      k.texto(
        principal.isEmpty ? '—' : principal,
        maxLineas: 2,
        estilo: k.estilo(tam: 13, fuente: k.r.bold),
      ),
      if (secundario.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        k.texto(
          secundario,
          maxLineas: 2,
          estilo: k.estilo(tam: 9, color: PdfPaleta.tintaSuave),
        ),
      ],
      k.divisor(vertical: 11),
    ],
  );
}

/// Vacante pedida y alumno, lado a lado y con la misma altura.
pw.Widget _vacanteYAlumno(PdfKit k, Solicitud s) {
  final t = k.t;
  final o = s.oferta;
  final a = s.alumno;
  return k.filaIgualada(
    anchos: const [pw.FlexColumnWidth(3), pw.FlexColumnWidth(2)],
    [
      k.tarjeta(
        padding: const pw.EdgeInsets.all(16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _encabezadoTarjeta(
              k,
              etiqueta: t.pdfVacanteSolicitada,
              titulo: o.nombreCompleto,
              detalle: s.institucionNombre,
            ),
            k.grilla([
              [
                k.campo(t.pdfCategoria, t.categoriaOferta(o)),
                k.campo(t.pdfTurno, t.turno(o.turno)),
              ],
              [k.campo(t.pdfHorario, o.horario), k.campo(t.pdfDias, o.dias)],
              [
                k.campo(t.pdfEdades, t.rangoEdad(o.edadMinima, o.edadMaxima)),
                pw.SizedBox(),
              ],
            ], separacionV: 11),
          ],
        ),
      ),
      k.tarjeta(
        padding: const pw.EdgeInsets.all(16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _encabezadoTarjeta(
              k,
              etiqueta: t.pdfAlumno,
              titulo: a.nombreCompleto,
            ),
            k.grilla([
              [k.campo(t.pdfDni, a.dni)],
              [k.campo(t.pdfEdad, k.edad(a.fechaNacimiento))],
            ], separacionV: 11),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _tablaHistorial(PdfKit k, List<CambioEstado> historial) {
  final t = k.t;
  return k.tabla(
    encabezados: [t.pdfFecha, t.pdfEstado, t.pdfNota],
    anchos: const {
      0: pw.FixedColumnWidth(100),
      1: pw.FixedColumnWidth(112),
      2: pw.FlexColumnWidth(),
    },
    filas: [
      for (final c in historial)
        [
          k.celda(fechaHora(c.fecha), color: PdfPaleta.tintaSuave),
          k.chipEstado(c.estado),
          k.celda(c.nota, maxLineas: 4),
        ],
    ],
  );
}
