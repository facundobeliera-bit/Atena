// lib/ui/widgets/atena_logo.dart
//
// Logotipo de ATENA: emblema (casco + birrete + laureles) y logotipo en Cinzel.

import 'package:flutter/material.dart';

import '../theme/atena_colors.dart';
import '../theme/atena_theme.dart';

const String kAtenaMarkAsset = 'assets/brand/atena_mark.png';

/// Emblema de ATENA, coloreable (sólido o gradiente).
class AtenaMark extends StatelessWidget {
  final double size;
  final Color? color;
  final Gradient? gradient;

  const AtenaMark({super.key, this.size = 48, this.color, this.gradient});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      kAtenaMarkAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: gradient == null
          ? (color ?? Theme.of(context).colorScheme.primary)
          : Colors.white,
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
    );

    final g = gradient;
    if (g == null) return image;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => g.createShader(bounds),
      child: image,
    );
  }
}

/// Logotipo "ATENA" en tipografía clásica.
class AtenaWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final Gradient? gradient;

  const AtenaWordmark({
    super.key,
    this.fontSize = 28,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'ATENA',
      maxLines: 1,
      style: TextStyle(
        fontFamily: AtenaTheme.displayFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.0,
        letterSpacing: fontSize * 0.16,
        color: gradient == null
            ? (color ?? Theme.of(context).colorScheme.onSurface)
            : Colors.white,
      ),
    );

    final g = gradient;
    if (g == null) return text;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => g.createShader(bounds),
      child: text,
    );
  }
}

/// Emblema + logotipo, en fila o columna.
class AtenaLogo extends StatelessWidget {
  final double markSize;
  final Axis direction;
  final Color? color;
  final bool showTagline;
  final String? tagline;

  const AtenaLogo({
    super.key,
    this.markSize = 40,
    this.direction = Axis.horizontal,
    this.color,
    this.showTagline = false,
    this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSurface;
    final horizontal = direction == Axis.horizontal;
    final wordSize = horizontal ? markSize * 0.62 : markSize * 0.42;

    final word = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        AtenaWordmark(fontSize: wordSize, color: fg),
        if (showTagline && (tagline ?? '').isNotEmpty) ...[
          SizedBox(height: wordSize * 0.35),
          Text(
            tagline!,
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg.withValues(alpha: 0.72),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    final children = <Widget>[
      AtenaMark(
        size: markSize,
        color: color,
        gradient: color == null ? AtenaColors.brandGradient : null,
      ),
      SizedBox(
        width: horizontal ? markSize * 0.28 : 0,
        height: horizontal ? 0 : markSize * 0.22,
      ),
      word,
    ];

    return Semantics(
      label: 'ATENA',
      container: true,
      child: horizontal
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Ícono de app: cuadrado redondeado con gradiente de marca y emblema blanco.
class AtenaAppIcon extends StatelessWidget {
  final double size;
  final AtenaRole role;
  final bool glow;

  const AtenaAppIcon({
    super.key,
    this.size = 72,
    this.role = AtenaRole.brand,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AtenaColors.roleAccent(role);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AtenaColors.roleGradient(role),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.14),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: AtenaMark(size: size * 0.66, color: Colors.white),
    );
  }
}
