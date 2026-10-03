// lib/screens/instituciones/widgets/perf_inst_fotos.dart
//
// Logo y galería de fotos del perfil público de la institución.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

/// En escritorio el selector de imágenes no las reduce. Si una supera el
/// máximo que admite el almacenamiento, se achica hasta que entre (si no se
/// puede, se devuelve tal cual y el guardado informa que es muy grande).
Future<Uint8List> perfInstAjustarImagen(
  Uint8List bytes, {
  required int anchoMaximo,
  required int maxBytes,
}) async {
  if (bytes.length <= maxBytes) return bytes;
  try {
    for (final ancho in [anchoMaximo, anchoMaximo * 3 ~/ 4, anchoMaximo ~/ 2]) {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: ancho,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data != null && data.lengthInBytes <= maxBytes) {
        return Uint8List.sublistView(data);
      }
    }
  } catch (_) {
    // Formato que no se puede leer acá: lo resuelve el guardado.
  }
  return bytes;
}

/// Abre una foto a pantalla completa (se puede ampliar con los dedos).
Future<void> perfInstVerFoto(BuildContext context, Uint8List bytes) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 4,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: AppLocalizations.of(ctx).uiClose,
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Logo actual (o iniciales) con las acciones para subirlo, cambiarlo o
/// quitarlo.
class PerfInstLogoEditor extends StatelessWidget {
  final String nombre;
  final Uint8List? logo;
  final bool cargando;
  final bool habilitado;
  final VoidCallback onElegir;

  /// null = no hay logo para quitar.
  final VoidCallback? onQuitar;

  const PerfInstLogoEditor({
    super.key,
    required this.nombre,
    required this.logo,
    required this.cargando,
    required this.habilitado,
    required this.onElegir,
    required this.onQuitar,
  });

  static const double _lado = 84;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const compacto = Size(0, 44);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AtenaAvatar(
              name: nombre,
              imageBytes: logo,
              size: _lado,
              fallbackIcon: Icons.account_balance_rounded,
            ),
            if (cargando)
              Container(
                width: _lado,
                height: _lado,
                decoration: BoxDecoration(
                  color: cs.scrim.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.perfInstLogo, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(t.perfInstLogoAyuda, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: compacto),
                    onPressed: habilitado ? onElegir : null,
                    icon: const Icon(Icons.upload_rounded, size: 20),
                    label: Text(
                      logo == null
                          ? t.perfInstLogoSubir
                          : t.perfInstLogoCambiar,
                    ),
                  ),
                  if (onQuitar != null)
                    TextButton.icon(
                      onPressed: habilitado ? onQuitar : null,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(t.perfInstLogoQuitar),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grilla de fotos con el botón para agregar y la opción de quitar cada una.
class PerfInstGaleria extends StatelessWidget {
  final List<String> ids;

  /// Bytes de cada foto por id (null si el archivo ya no está).
  final Map<String, Uint8List?> imagenes;

  final int maximo;
  final bool subiendo;
  final bool habilitado;
  final VoidCallback onAgregar;
  final ValueChanged<String> onQuitar;
  final ValueChanged<Uint8List> onVer;

  const PerfInstGaleria({
    super.key,
    required this.ids,
    required this.imagenes,
    required this.maximo,
    required this.subiendo,
    required this.habilitado,
    required this.onAgregar,
    required this.onQuitar,
    required this.onVer,
  });

  static const double _espacio = 10;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ocupadas = ids.length + (subiendo ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.perfInstFotos, style: theme.textTheme.titleSmall),
            ),
            Text(
              t.perfInstFotosCantidad(ids.length, maximo),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(t.perfInstFotosAyuda(maximo), style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final columnas = (c.maxWidth / 112).floor().clamp(3, 6);
            final lado = (c.maxWidth - _espacio * (columnas - 1)) / columnas;
            // Margen extra para que las fotos apaisadas no pierdan nitidez.
            final cache = (lado * 1.5 * MediaQuery.devicePixelRatioOf(context))
                .round();
            return Wrap(
              spacing: _espacio,
              runSpacing: _espacio,
              children: [
                for (final (i, id) in ids.indexed)
                  SizedBox.square(
                    dimension: lado,
                    child: _Foto(
                      bytes: imagenes[id],
                      anchoCache: cache,
                      etiqueta: t.perfInstFotoVer(i + 1),
                      onVer: onVer,
                      onQuitar: habilitado ? () => onQuitar(id) : null,
                    ),
                  ),
                if (subiendo)
                  SizedBox.square(dimension: lado, child: const _Subiendo()),
                if (ocupadas < maximo)
                  SizedBox.square(
                    dimension: lado,
                    child: _Agregar(onTap: habilitado ? onAgregar : null),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

const BorderRadius _radioFoto = BorderRadius.all(
  Radius.circular(AtenaRadius.md),
);

class _Foto extends StatelessWidget {
  final Uint8List? bytes;
  final int anchoCache;
  final String etiqueta;
  final ValueChanged<Uint8List> onVer;
  final VoidCallback? onQuitar;

  const _Foto({
    required this.bytes,
    required this.anchoCache,
    required this.etiqueta,
    required this.onVer,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final imagen = bytes;

    final rota = ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: cs.onSurfaceVariant,
          semanticLabel: t.perfInstFotoNoDisponible,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: _radioFoto,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagen == null)
            rota
          else ...[
            Image.memory(
              imagen,
              fit: BoxFit.cover,
              cacheWidth: anchoCache,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => rota,
            ),
            Semantics(
              button: true,
              label: etiqueta,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: () => onVer(imagen)),
              ),
            ),
          ],
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: t.perfInstFotoQuitar,
              onPressed: onQuitar,
              iconSize: 16,
              // Círculo chico a la vista, con el área táctil completa.
              style: IconButton.styleFrom(
                backgroundColor: cs.scrim.withValues(alpha: 0.6),
                disabledBackgroundColor: cs.scrim.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                minimumSize: const Size.square(28),
                fixedSize: const Size.square(28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _Subiendo extends StatelessWidget {
  const _Subiendo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: _radioFoto,
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.8),
        ),
      ),
    );
  }
}

class _Agregar extends StatelessWidget {
  final VoidCallback? onTap;

  const _Agregar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = onTap == null ? cs.onSurfaceVariant : cs.primary;

    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: _radioFoto,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded, color: color),
              const SizedBox(height: 4),
              Text(
                t.perfInstFotoAgregar,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
