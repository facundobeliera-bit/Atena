// lib/screens/instituciones/widgets/sol_inst_acciones.dart
//
// ATENA – Acciones de la institución sobre una solicitud (confirmar, no
// aceptar, dar de baja, pedir documento) y utilidades de PDF y contacto.
// Las usan la lista de solicitudes, la de alumnos y el detalle.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../pdf/atena_pdf.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../ofertas_page.dart';
import 'sol_inst_dialogos.dart';
import 'sol_inst_pedir_documento_sheet.dart';

/// Recibe un mensaje de error para mostrarlo donde corresponda (por defecto
/// se muestra como aviso al pie de la pantalla).
typedef SolInstAviso = void Function(String mensaje);

/// Confirma una solicitud pendiente (antes pide un mensaje opcional).
/// Devuelve el mensaje de éxito; null si se canceló o no se pudo (en ese
/// caso el problema ya se informó).
Future<String?> solInstConfirmar(
  BuildContext context,
  Solicitud s, {
  required String institucionId,
  required String institucionNombre,
  ValueChanged<bool>? onProcesando,
  SolInstAviso? onError,
}) async {
  final t = AppLocalizations.of(context);
  final nota = await solInstDialogoConfirmar(context, s);
  if (nota == null || !context.mounted) return null;

  onProcesando?.call(true);
  try {
    await SolicitudesRepo.instance.responder(
      s.id,
      institucionId: institucionId,
      aceptar: true,
      nota: nota,
    );
    return t.solInstOkConfirmada(s.alumno.nombreCompleto);
  } catch (e) {
    onProcesando?.call(false);
    if (!context.mounted) return null;
    if (e is AtenaException && e.error == AtenaError.sinCupo) {
      final irAVacantes = await solInstDialogoSinCupo(context, s);
      if (irAVacantes && context.mounted) {
        await solInstAbrirVacantes(
          context,
          institucionId: institucionId,
          institucionNombre: institucionNombre,
        );
      }
    } else {
      _informar(context, onError, _textoError(t, e));
    }
    return null;
  } finally {
    onProcesando?.call(false);
  }
}

/// No acepta una solicitud pendiente (antes pide el motivo).
/// Devuelve el mensaje de éxito; null si se canceló o no se pudo.
Future<String?> solInstRechazar(
  BuildContext context,
  Solicitud s, {
  required String institucionId,
  ValueChanged<bool>? onProcesando,
  SolInstAviso? onError,
}) async {
  final t = AppLocalizations.of(context);
  final motivo = await solInstDialogoRechazar(context, s);
  if (motivo == null || !context.mounted) return null;

  onProcesando?.call(true);
  try {
    await SolicitudesRepo.instance.responder(
      s.id,
      institucionId: institucionId,
      aceptar: false,
      nota: motivo,
    );
    return t.solInstOkRechazada(s.alumno.nombreCompleto);
  } catch (e) {
    if (context.mounted) _informar(context, onError, _textoError(t, e));
    return null;
  } finally {
    onProcesando?.call(false);
  }
}

/// Da de baja a un alumno confirmado (antes pide confirmación).
/// Devuelve el mensaje de éxito; null si se canceló o no se pudo.
Future<String?> solInstDarDeBaja(
  BuildContext context,
  Solicitud s, {
  required String institucionId,
  ValueChanged<bool>? onProcesando,
  SolInstAviso? onError,
}) async {
  final t = AppLocalizations.of(context);
  final nota = await solInstDialogoBaja(context, s);
  if (nota == null || !context.mounted) return null;

  onProcesando?.call(true);
  try {
    await SolicitudesRepo.instance.darDeBaja(
      s.id,
      institucionId: institucionId,
      nota: nota,
    );
    return t.solInstOkBaja(s.alumno.nombreCompleto);
  } catch (e) {
    if (context.mounted) _informar(context, onError, _textoError(t, e));
    return null;
  } finally {
    onProcesando?.call(false);
  }
}

/// Pide un documento al alumno de la solicitud. Devuelve el mensaje de éxito,
/// o null si se cerró sin enviar.
Future<String?> solInstPedirDocumento(
  BuildContext context,
  Solicitud s, {
  required String institucionId,
  required String institucionNombre,
}) async {
  final t = AppLocalizations.of(context);
  final pedido = await showSolInstPedirDocumento(
    context,
    institucionId: institucionId,
    institucionNombre: institucionNombre,
    alumno: s.alumno,
    solicitudId: s.id,
  );
  if (pedido == null) return null;
  return t.solInstOkDocumento(t.nombreDocumento(pedido.tipo, pedido.detalle));
}

/// Genera un PDF y lo comparte (en web, lo descarga).
Future<void> solInstCompartirPdf(
  BuildContext context, {
  required Future<Uint8List> Function() generar,
  required String nombreArchivo,
  SolInstAviso? onError,
}) async {
  final t = AppLocalizations.of(context);
  try {
    final bytes = await generar();
    if (!context.mounted) return;
    await AtenaPdf.compartir(context, bytes, nombreArchivo);
  } catch (_) {
    if (context.mounted) _informar(context, onError, t.solInstPdfError);
  }
}

/// Abre la pantalla de Vacantes de la institución.
Future<void> solInstAbrirVacantes(
  BuildContext context, {
  required String institucionId,
  required String institucionNombre,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OfertasPage(
        institucionId: institucionId,
        institucionNombre: institucionNombre,
      ),
    ),
  );
}

/// Abre un enlace de contacto (teléfono, email o WhatsApp).
/// Devuelve false si el dispositivo no pudo abrirlo.
Future<bool> solInstAbrirEnlace(Uri uri) async {
  final web = uri.scheme == 'https' || uri.scheme == 'http';
  try {
    return await launchUrl(
      uri,
      mode: web ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
  } catch (_) {
    return false;
  }
}

/// Si la solicitud desapareció (por ejemplo, la familia eliminó su cuenta),
/// lo explica; para el resto usa el texto general de errores.
String _textoError(AppLocalizations t, Object error) {
  if (error is AtenaException && error.error == AtenaError.noEncontrado) {
    return t.solInstYaNoExiste;
  }
  return coreErrorText(t, error);
}

void _informar(BuildContext context, SolInstAviso? onError, String mensaje) {
  if (onError != null) {
    onError(mensaje);
  } else {
    AtenaFeedback.error(context, mensaje);
  }
}
