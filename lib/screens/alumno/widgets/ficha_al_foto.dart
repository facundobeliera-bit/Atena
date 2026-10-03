// lib/screens/alumno/widgets/ficha_al_foto.dart
//
// ATENA – Ficha del alumno: opciones para la foto (cámara, galería, quitar)
// y ajuste de tamaño antes de guardarla.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

enum FichaAlFotoAccion { camara, galeria, quitar }

/// Hoja con las opciones de la foto. [camara] ofrece sacar una foto (solo en
/// teléfonos); [tieneFoto] agrega la opción de quitarla.
Future<FichaAlFotoAccion?> mostrarFichaAlFotoOpciones(
  BuildContext context, {
  required bool tieneFoto,
  required bool camara,
}) {
  return showModalBottomSheet<FichaAlFotoAccion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AtenaRoleTheme(
      role: AtenaRole.alumno,
      child: _Opciones(tieneFoto: tieneFoto, camara: camara),
    ),
  );
}

class _Opciones extends StatelessWidget {
  final bool tieneFoto;
  final bool camara;

  const _Opciones({required this.tieneFoto, required this.camara});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const margen = EdgeInsets.symmetric(horizontal: 24);
    void elegir(FichaAlFotoAccion a) => Navigator.of(context).pop(a);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tieneFoto ? t.fichaAlCambiarFoto : t.fichaAlAgregarFoto,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (camara)
              ListTile(
                contentPadding: margen,
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(t.fichaAlFotoCamara),
                onTap: () => elegir(FichaAlFotoAccion.camara),
              ),
            ListTile(
              contentPadding: margen,
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(camara ? t.fichaAlFotoGaleria : t.fichaAlFotoArchivo),
              onTap: () => elegir(FichaAlFotoAccion.galeria),
            ),
            if (tieneFoto)
              ListTile(
                contentPadding: margen,
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text(
                  t.fichaAlQuitarFoto,
                  style: TextStyle(color: cs.error),
                ),
                onTap: () => elegir(FichaAlFotoAccion.quitar),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reduce la foto si supera el máximo permitido (en escritorio el selector de
/// imágenes no achica el archivo). Si no se puede reducir, devuelve la
/// original y el guardado informa que es demasiado grande.
Future<Uint8List> ajustarFotoFichaAl(Uint8List bytes) async {
  if (bytes.length <= AlumnosRepo.maxBytesFoto) return bytes;
  for (final ancho in const [640, 480, 320]) {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: ancho);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data == null) return bytes;
      final reducida = data.buffer.asUint8List();
      if (reducida.length <= AlumnosRepo.maxBytesFoto) return reducida;
    } catch (_) {
      return bytes;
    }
  }
  return bytes;
}
