// lib/pdf/src/pdf_ficha_alumno.dart
//
// Ficha del alumno: foto, datos personales y solicitudes de vacante.

import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../ui/atena_labels.dart';
import 'pdf_kit.dart';
import 'pdf_recursos.dart';

Future<Uint8List> pdfFichaAlumno({
  required PdfRecursos r,
  required AppLocalizations t,
  required PerfilAlumno perfil,
  required pw.ImageProvider? foto,
  required List<Solicitud> solicitudes,
}) {
  final dni = perfil.documento.trim();
  final k = PdfKit(
    r: r,
    t: t,
    titulo: t.pdfFichaTitulo,
    subtitulo: [
      perfil.displayName,
      if (dni.isNotEmpty) t.pdfDniValor(dni),
    ].where((s) => s.isNotEmpty).join(' · '),
  );
  // Las más recientes primero.
  final ordenadas = [...solicitudes]
    ..sort((a, b) => b.creadaEl.compareTo(a.creadaEl));

  final doc = k.documento()
    ..addPage(
      k.multipagina([
        k.seccion(t.pdfDatosPersonales, arriba: 0),
        _datosPersonales(k, perfil, foto),
        pw.NewPage(freeSpace: 120),
        k.seccion(
          t.pdfSolicitudes,
          detalle: t.pdfSolicitudesCantidad(ordenadas.length),
          arriba: 24,
        ),
        if (ordenadas.isEmpty)
          k.vacio(t.pdfSinSolicitudes)
        else
          _tablaSolicitudes(k, ordenadas),
      ]),
    );
  return doc.save();
}

pw.Widget _datosPersonales(PdfKit k, PerfilAlumno p, pw.ImageProvider? foto) {
  final t = k.t;
  final nacimiento = fechaValida(p.fechaNacimiento);
  return k.tarjeta(
    padding: const pw.EdgeInsets.all(18),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        k.avatar(
          iniciales: k.iniciales(p.nombre, p.apellido),
          imagen: foto,
          tam: 96,
        ),
        pw.SizedBox(width: 22),
        pw.Expanded(
          child: k.grilla([
            [
              k.campo(t.pdfNombre, p.nombre),
              k.campo(t.pdfApellido, p.apellido),
            ],
            [
              k.campo(t.pdfDni, p.documento),
              k.campo(
                t.pdfFechaNacimiento,
                nacimiento == null ? '' : fecha(nacimiento),
              ),
            ],
            [
              k.campo(t.pdfEdad, k.edad(nacimiento)),
              k.campo(t.pdfTelefono, p.telefono),
            ],
            [k.campo(t.pdfEmail, p.email)],
          ]),
        ),
      ],
    ),
  );
}

pw.Widget _tablaSolicitudes(PdfKit k, List<Solicitud> solicitudes) {
  final t = k.t;
  return k.tabla(
    encabezados: [
      t.pdfInstitucion,
      t.pdfOferta,
      t.pdfCategoria,
      t.pdfEstado,
      t.pdfFecha,
    ],
    anchos: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2.5),
      2: pw.FlexColumnWidth(2),
      3: pw.FixedColumnWidth(88),
      4: pw.FixedColumnWidth(74),
    },
    filas: [
      for (final s in solicitudes)
        [
          k.celda(s.institucionNombre, fuerte: true),
          k.celda(s.oferta.nombreCompleto),
          k.celda(t.categoriaOferta(s.oferta), color: PdfPaleta.tintaSuave),
          k.chipEstado(s.estado),
          k.celda(fecha(s.creadaEl), color: PdfPaleta.tintaSuave),
        ],
    ],
  );
}
