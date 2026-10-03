// lib/pdf/src/pdf_listado_alumnos.dart
//
// Listado de alumnos confirmados de una institución (todos o de una oferta),
// ordenado por apellido. A4 vertical; continúa en las páginas que haga falta.

import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import 'pdf_kit.dart';
import 'pdf_recursos.dart';

Future<Uint8List> pdfListadoAlumnos({
  required PdfRecursos r,
  required AppLocalizations t,
  required String institucionNombre,
  required List<Solicitud> confirmadas,
  String? titulo,
}) {
  final propio = (titulo ?? '').trim();
  final k = PdfKit(
    r: r,
    t: t,
    titulo: propio.isEmpty ? t.pdfListadoTitulo : propio,
    subtitulo: institucionNombre,
  );
  final alumnos =
      confirmadas.where((s) => s.estado == EstadoSolicitud.confirmada).toList()
        ..sort(_porApellido);
  final ofertas = <String, String>{
    for (final s in alumnos) _claveOferta(s): s.oferta.nombreCompleto,
  };

  final doc = k.documento()
    ..addPage(
      k.multipagina([
        _resumen(
          k,
          institucion: institucionNombre,
          total: alumnos.length,
          ofertaUnica: ofertas.length == 1 ? ofertas.values.first : null,
        ),
        pw.SizedBox(height: 16),
        if (alumnos.isEmpty)
          k.vacio(t.pdfListadoVacio)
        else
          _tabla(k, alumnos, conOferta: ofertas.length > 1),
      ]),
    );
  return doc.save();
}

int _porApellido(Solicitud a, Solicitud b) {
  String clave(AlumnoSnapshot x) =>
      normalizarBusqueda('${x.apellido} ${x.nombre}');
  return clave(a.alumno).compareTo(clave(b.alumno));
}

String _claveOferta(Solicitud s) =>
    s.ofertaId.isNotEmpty ? s.ofertaId : s.oferta.nombreCompleto;

/// Total, institución, oferta (si es una sola) y fecha.
pw.Widget _resumen(
  PdfKit k, {
  required String institucion,
  required int total,
  required String? ofertaUnica,
}) {
  final t = k.t;
  pw.Widget dato(String etiqueta, String valor) => k.tarjeta(
    fondo: PdfPaleta.fondo,
    padding: const pw.EdgeInsets.fromLTRB(13, 11, 13, 12),
    k.campo(etiqueta, valor, tam: 10.5),
  );

  final destacado = k.tarjeta(
    gradiente: PdfPaleta.marcaDiagonal,
    padding: const pw.EdgeInsets.fromLTRB(13, 11, 13, 12),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        k.etiqueta(t.pdfTotal, color: PdfPaleta.sobreBanda),
        pw.SizedBox(height: 3),
        k.texto(
          k.linea(t.pdfAlumnosCantidad(total)),
          maxLineas: 2,
          estilo: k.estilo(
            tam: 12.5,
            fuente: k.r.bold,
            color: PdfPaleta.blanco,
          ),
        ),
      ],
    ),
  );

  // Total y fecha con ancho fijo; los nombres se reparten el resto.
  return k.filaIgualada(
    separacion: 10,
    anchos: [
      const pw.FixedColumnWidth(122),
      const pw.FlexColumnWidth(2),
      if (ofertaUnica != null) const pw.FlexColumnWidth(1.6),
      const pw.FixedColumnWidth(94),
    ],
    [
      destacado,
      dato(t.pdfInstitucion, institucion),
      if (ofertaUnica != null) dato(t.pdfOferta, ofertaUnica),
      dato(t.pdfFecha, fecha(k.emitido)),
    ],
  );
}

pw.Widget _tabla(PdfKit k, List<Solicitud> alumnos, {required bool conOferta}) {
  final t = k.t;
  final contacto = conOferta ? 5 : 4;
  return k.tabla(
    encabezados: [
      '#',
      t.pdfApellidoNombre,
      t.pdfDni,
      t.pdfEdad,
      if (conOferta) t.pdfOferta,
      t.pdfContacto,
    ],
    anchos: {
      0: const pw.FixedColumnWidth(28),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FixedColumnWidth(74),
      3: const pw.FixedColumnWidth(64),
      if (conOferta) 4: const pw.FlexColumnWidth(2.1),
      contacto: const pw.FlexColumnWidth(2.6),
    },
    filas: [
      for (final (i, s) in alumnos.indexed)
        [
          k.celda('${i + 1}', color: PdfPaleta.apagado),
          k.celda(s.alumno.apellidoNombre, fuerte: true),
          k.celda(s.alumno.dni),
          k.celda(k.edad(s.alumno.fechaNacimiento)),
          if (conOferta)
            k.celda(s.oferta.nombreCompleto, color: PdfPaleta.tintaSuave),
          _contacto(k, s.alumno),
        ],
    ],
  );
}

/// Teléfono y email, uno debajo del otro.
pw.Widget _contacto(PdfKit k, AlumnoSnapshot a) {
  final telefono = k.linea(a.telefono);
  final email = k.linea(a.email);
  if (telefono.isEmpty && email.isEmpty) return k.celda('');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (telefono.isNotEmpty) k.texto(telefono, estilo: k.estilo(tam: 8.4)),
      if (email.isNotEmpty)
        k.texto(
          email,
          maxLineas: 2,
          estilo: k.estilo(tam: 7.6, color: PdfPaleta.tintaSuave),
        ),
    ],
  );
}
