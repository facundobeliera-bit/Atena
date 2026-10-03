// lib/pdf/atena_pdf.dart
//
// Documentos PDF de ATENA (con la marca y en el idioma del usuario).
// Funcionan en Android, iOS, escritorio y web.
//
// Cada documento se arma en lib/pdf/src/ con el mismo marco (banda de marca,
// tipografías de la app y pie con fecha y numeración). Los textos salen de
// AppLocalizations; los datos vacíos o muy largos se muestran sin romper.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/atena_core.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/cuentas/cuenta.dart';
import 'src/pdf_comprobante.dart';
import 'src/pdf_croquis.dart';
import 'src/pdf_ficha_alumno.dart';
import 'src/pdf_listado_alumnos.dart';
import 'src/pdf_recursos.dart';

class AtenaPdf {
  const AtenaPdf._();

  /// Ficha del alumno: datos personales, foto y solicitudes.
  static Future<Uint8List> fichaAlumno({
    required AppLocalizations t,
    required PerfilAlumno perfil,
    Uint8List? foto,
    List<Solicitud> solicitudes = const <Solicitud>[],
  }) async {
    final recursos = await PdfRecursos.cargar();
    return pdfFichaAlumno(
      r: recursos,
      t: t,
      perfil: perfil,
      foto: await PdfRecursos.imagen(foto),
      solicitudes: solicitudes,
    );
  }

  /// Comprobante de una solicitud de vacante.
  static Future<Uint8List> comprobanteSolicitud({
    required AppLocalizations t,
    required Solicitud solicitud,
  }) async {
    final recursos = await PdfRecursos.cargar();
    return pdfComprobante(r: recursos, t: t, solicitud: solicitud);
  }

  /// Listado de alumnos confirmados (todos o de una oferta).
  static Future<Uint8List> listadoAlumnos({
    required AppLocalizations t,
    required String institucionNombre,
    required List<Solicitud> confirmadas,
    String? titulo,
  }) async {
    final recursos = await PdfRecursos.cargar();
    return pdfListadoAlumnos(
      r: recursos,
      t: t,
      institucionNombre: institucionNombre,
      confirmadas: confirmadas,
      titulo: titulo,
    );
  }

  /// Croquis de aula.
  static Future<Uint8List> croquis({
    required AppLocalizations t,
    required String institucionNombre,
    required Croquis croquis,
  }) async {
    final recursos = await PdfRecursos.cargar();
    return pdfCroquis(
      r: recursos,
      t: t,
      institucionNombre: institucionNombre,
      croquis: croquis,
    );
  }

  /// Comparte o descarga el PDF (en web, descarga el archivo).
  static Future<void> compartir(
    BuildContext context,
    Uint8List bytes,
    String nombreArchivo,
  ) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: _nombrePdf(nombreArchivo),
      bounds: _origen(context),
    );
  }

  /// Abre el diálogo de impresión / vista previa del sistema.
  static Future<void> imprimir(
    BuildContext context,
    Uint8List bytes,
    String nombreArchivo,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _nombrePdf(nombreArchivo),
    );
  }

  /// Zona de la pantalla desde la que se abre el panel de compartir (en
  /// tabletas el panel se ancla a ese punto).
  static Rect? _origen(BuildContext context) {
    if (!context.mounted) return null;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.hasSize) return null;
    return caja.localToGlobal(Offset.zero) & caja.size;
  }

  /// Nombre de archivo válido en cualquier sistema y terminado en ".pdf".
  static String _nombrePdf(String nombre) {
    var base = nombre
        .replaceAll(_noPermitidos, '-')
        .replaceAll(_espacios, ' ')
        .trim();
    if (base.toLowerCase().endsWith('.pdf')) {
      base = base.substring(0, base.length - 4).trim();
    }
    if (base.length > 80) base = base.substring(0, 80).trim();
    return '${base.isEmpty ? 'ATENA' : base}.pdf';
  }

  static final RegExp _noPermitidos = RegExp(r'[\\/:*?"<>|\u0000-\u001F]');
  static final RegExp _espacios = RegExp(r'\s+');
}
