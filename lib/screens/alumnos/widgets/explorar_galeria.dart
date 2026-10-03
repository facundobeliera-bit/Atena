// lib/screens/alumnos/widgets/explorar_galeria.dart
//
// ATENA – Fotos de la institución:
// - ExplorarCarrusel: portada deslizable con indicadores (flechas en pantallas
//   anchas; también se arrastra con el mouse).
// - abrirExplorarGaleria: visor a pantalla completa con zoom (pellizco o doble
//   toque), flechas y teclado (← → Esc).

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

typedef ExplorarCargarFoto = Future<Uint8List?> Function(String fotoId);

/// Permite deslizar con mouse y trackpad además del dedo.
ScrollBehavior _arrastreLibre(BuildContext context) => ScrollConfiguration.of(
  context,
).copyWith(dragDevices: PointerDeviceKind.values.toSet());

// -----------------------------------------------------------------------------
// Carrusel de portada
// -----------------------------------------------------------------------------

class ExplorarCarrusel extends StatefulWidget {
  final List<String> fotoIds;
  final ExplorarCargarFoto cargar;
  final double alto;

  /// Abre el visor a pantalla completa en la foto indicada.
  final ValueChanged<int> onAbrir;

  const ExplorarCarrusel({
    super.key,
    required this.fotoIds,
    required this.cargar,
    required this.alto,
    required this.onAbrir,
  });

  @override
  State<ExplorarCarrusel> createState() => _ExplorarCarruselState();
}

class _ExplorarCarruselState extends State<ExplorarCarrusel> {
  final _ctrl = PageController();
  int _actual = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ir(int i) {
    if (i < 0 || i >= widget.fotoIds.length) return;
    _ctrl.animateToPage(
      i,
      duration: AtenaMotion.medium,
      curve: AtenaMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final n = widget.fotoIds.length;
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      height: widget.alto,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScrollConfiguration(
            behavior: _arrastreLibre(context),
            child: PageView.builder(
              controller: _ctrl,
              itemCount: n,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (context, i) => LayoutBuilder(
                builder: (context, c) => Semantics(
                  button: true,
                  label: t.explorarFotoDe(i + 1, n),
                  child: GestureDetector(
                    onTap: () => widget.onAbrir(i),
                    child: ExplorarFoto(
                      key: ValueKey(widget.fotoIds[i]),
                      cargar: () => widget.cargar(widget.fotoIds[i]),
                      fit: BoxFit.cover,
                      cacheWidth: (c.maxWidth * dpr).round(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.scrim.withValues(alpha: 0),
                      cs.scrim.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (n > 1)
            Positioned(
              right: 14,
              bottom: 12,
              child: _Puntos(total: n, actual: _actual),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: _BotonSobreFoto(
              icon: Icons.fullscreen_rounded,
              tooltip: t.explorarVerFotos,
              onPressed: () => widget.onAbrir(_actual),
            ),
          ),
          if (ancho && n > 1) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _BotonSobreFoto(
                  icon: Icons.chevron_left_rounded,
                  tooltip: t.explorarFotoAnterior,
                  onPressed: _actual > 0 ? () => _ir(_actual - 1) : null,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _BotonSobreFoto(
                  icon: Icons.chevron_right_rounded,
                  tooltip: t.explorarFotoSiguiente,
                  onPressed: _actual < n - 1 ? () => _ir(_actual + 1) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Puntos extends StatelessWidget {
  final int total;
  final int actual;

  const _Puntos({required this.total, required this.actual});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.scrim.withValues(alpha: 0.35),
        borderRadius: AtenaRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: AtenaMotion.fast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == actual ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == actual ? 1 : 0.55),
                borderRadius: AtenaRadius.pill,
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón circular translúcido que se lee sobre cualquier foto.
class _BotonSobreFoto extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _BotonSobreFoto({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: cs.scrim.withValues(alpha: 0.42),
        foregroundColor: Colors.white,
        disabledBackgroundColor: cs.scrim.withValues(alpha: 0.18),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon),
    );
  }
}

// -----------------------------------------------------------------------------
// Foto con carga perezosa
// -----------------------------------------------------------------------------

class ExplorarFoto extends StatefulWidget {
  final Future<Uint8List?> Function() cargar;
  final BoxFit fit;
  final int? cacheWidth;

  /// Fondo oscuro (visor a pantalla completa).
  final bool sobreOscuro;

  const ExplorarFoto({
    super.key,
    required this.cargar,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.sobreOscuro = false,
  });

  @override
  State<ExplorarFoto> createState() => _ExplorarFotoState();
}

class _ExplorarFotoState extends State<ExplorarFoto> {
  late final Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = widget.sobreOscuro ? null : cs.surfaceContainerHigh;
    final tinta = widget.sobreOscuro
        ? Colors.white.withValues(alpha: 0.7)
        : cs.onSurfaceVariant;

    Widget sinFoto() => ColoredBox(
      color: fondo ?? Colors.transparent,
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, size: 40, color: tinta),
      ),
    );

    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: fondo ?? Colors.transparent,
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: tinta,
                ),
              ),
            ),
          );
        }
        final bytes = snap.data;
        if (bytes == null) return sinFoto();
        // Mientras se decodifica queda el fondo neutro; la foto entra suave.
        return ColoredBox(
          color: fondo ?? Colors.transparent,
          child: Image.memory(
            bytes,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sincrono) => sincrono
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: AtenaMotion.medium,
                    curve: AtenaMotion.curve,
                    child: child,
                  ),
            errorBuilder: (context, error, stackTrace) => sinFoto(),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Visor a pantalla completa
// -----------------------------------------------------------------------------

Future<void> abrirExplorarGaleria(
  BuildContext context, {
  required List<String> fotoIds,
  required int inicial,
  required ExplorarCargarFoto cargar,
}) {
  if (fotoIds.isEmpty) return Future<void>.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _Galeria(
        fotoIds: fotoIds,
        inicial: inicial.clamp(0, fotoIds.length - 1),
        cargar: cargar,
      ),
    ),
  );
}

class _Galeria extends StatefulWidget {
  final List<String> fotoIds;
  final int inicial;
  final ExplorarCargarFoto cargar;

  const _Galeria({
    required this.fotoIds,
    required this.inicial,
    required this.cargar,
  });

  @override
  State<_Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<_Galeria> {
  late final PageController _ctrl;
  late int _actual;
  bool _zoom = false;

  @override
  void initState() {
    super.initState();
    _actual = widget.inicial;
    _ctrl = PageController(initialPage: widget.inicial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ir(int i) {
    if (_zoom || i < 0 || i >= widget.fotoIds.length) return;
    _ctrl.animateToPage(
      i,
      duration: AtenaMotion.medium,
      curve: AtenaMotion.curve,
    );
  }

  void _cerrar() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final n = widget.fotoIds.length;
    final ancho = MediaQuery.sizeOf(context).width >= 600;

    return AtenaScaffold(
      role: AtenaRole.alumno,
      backdrop: false,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _ir(_actual - 1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _ir(_actual + 1),
          const SingleActivator(LogicalKeyboardKey.escape): _cerrar,
        },
        child: Focus(
          autofocus: true,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScrollConfiguration(
                    behavior: _arrastreLibre(context),
                    child: PageView.builder(
                      controller: _ctrl,
                      physics: _zoom
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemCount: n,
                      onPageChanged: (i) => setState(() {
                        _actual = i;
                        _zoom = false;
                      }),
                      itemBuilder: (context, i) => Semantics(
                        image: true,
                        label: t.explorarFotoDe(i + 1, n),
                        child: _FotoZoom(
                          key: ValueKey(widget.fotoIds[i]),
                          cargar: () => widget.cargar(widget.fotoIds[i]),
                          onZoom: (z) {
                            if (z != _zoom) setState(() => _zoom = z);
                          },
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BotonSobreFoto(
                            icon: Icons.close_rounded,
                            tooltip: t.uiClose,
                            onPressed: _cerrar,
                          ),
                          const Spacer(),
                          if (n > 1)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.scrim.withValues(
                                  alpha: 0.42,
                                ),
                                borderRadius: AtenaRadius.pill,
                              ),
                              child: Text(
                                '${_actual + 1} / $n',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (ancho && n > 1) ...[
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _BotonSobreFoto(
                          icon: Icons.chevron_left_rounded,
                          tooltip: t.explorarFotoAnterior,
                          onPressed: _actual > 0 && !_zoom
                              ? () => _ir(_actual - 1)
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _BotonSobreFoto(
                          icon: Icons.chevron_right_rounded,
                          tooltip: t.explorarFotoSiguiente,
                          onPressed: _actual < n - 1 && !_zoom
                              ? () => _ir(_actual + 1)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto ampliable: pellizco o doble toque. Avisa si quedó ampliada para que
/// el visor no cambie de foto mientras se recorre la imagen.
class _FotoZoom extends StatefulWidget {
  final Future<Uint8List?> Function() cargar;
  final ValueChanged<bool> onZoom;

  const _FotoZoom({super.key, required this.cargar, required this.onZoom});

  @override
  State<_FotoZoom> createState() => _FotoZoomState();
}

class _FotoZoomState extends State<_FotoZoom> {
  static const double _escalaDobleToque = 2.5;

  final _transform = TransformationController();
  Offset _toque = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _ampliada => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _dobleToque() {
    if (_ampliada) {
      _transform.value = Matrix4.identity();
      widget.onZoom(false);
      return;
    }
    const s = _escalaDobleToque;
    _transform.value = Matrix4.diagonal3Values(s, s, 1)
      ..setTranslationRaw(-_toque.dx * (s - 1), -_toque.dy * (s - 1), 0);
    widget.onZoom(true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _toque = d.localPosition,
      onDoubleTap: _dobleToque,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) => widget.onZoom(_ampliada),
        child: SizedBox.expand(
          child: ExplorarFoto(
            cargar: widget.cargar,
            fit: BoxFit.contain,
            sobreOscuro: true,
          ),
        ),
      ),
    );
  }
}
