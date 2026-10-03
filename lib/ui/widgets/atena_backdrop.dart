// lib/ui/widgets/atena_backdrop.dart
//
// Fondos de marca pintados en código (livianos, nítidos en cualquier pantalla):
// - AtenaBackdrop: lienzo con resplandores suaves del color del área.
// - AtenaGradientPanel: panel con el gradiente del área (encabezados, héroes).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/atena_colors.dart';
import '../theme/atena_theme.dart';

class AtenaBackdrop extends StatelessWidget {
  final Widget child;

  /// 0 = sin resplandor, 1 = intensidad normal.
  final double intensity;

  const AtenaBackdrop({super.key, required this.child, this.intensity = 1});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = AtenaBrand.of(context);
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(color: brand.canvas),
      child: CustomPaint(
        painter: _GlowPainter(
          primary: theme.colorScheme.primary,
          secondary: brand.role == AtenaRole.institucion
              ? AtenaColors.indigo
              : (brand.role == AtenaRole.alumno
                    ? AtenaColors.indigo
                    : AtenaColors.violet),
          gold: AtenaColors.gold,
          dark: dark,
          intensity: intensity,
        ),
        child: child,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color gold;
  final bool dark;
  final double intensity;

  _GlowPainter({
    required this.primary,
    required this.secondary,
    required this.gold,
    required this.dark,
    required this.intensity,
  });

  void _glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 || size.isEmpty) return;
    final r = math.max(size.width, size.height);
    final a = dark ? 0.22 : 0.13;

    _glow(canvas, Offset(size.width * 0.05, -r * 0.05), r * 0.62, primary, a);
    _glow(
      canvas,
      Offset(size.width * 1.0, size.height * 0.12),
      r * 0.48,
      secondary,
      a * 0.8,
    );
    _glow(
      canvas,
      Offset(size.width * 0.85, size.height * 1.02),
      r * 0.42,
      gold,
      a * 0.35,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.dark != dark ||
      old.intensity != intensity;
}

/// Panel con gradiente del área + formas decorativas sutiles.
class AtenaGradientPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Gradient? gradient;
  final bool decorate;

  const AtenaGradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.gradient,
    this.decorate = true,
  });

  @override
  Widget build(BuildContext context) {
    final brand = AtenaBrand.of(context);
    final g = gradient ?? brand.gradient;
    final shadowColor = g.colors.isNotEmpty
        ? g.colors.last
        : AtenaColors.indigo;

    return Container(
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: decorate ? _PanelDecorPainter() : null,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.06);

    final c1 = Offset(size.width * 0.92, size.height * 0.05);
    canvas.drawCircle(c1, size.height * 0.75, fill);
    canvas.drawCircle(c1, size.height * 0.95, ring);
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 1.15),
      size.height * 0.45,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
