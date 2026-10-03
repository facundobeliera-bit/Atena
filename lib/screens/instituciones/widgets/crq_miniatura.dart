// lib/screens/instituciones/widgets/crq_miniatura.dart
//
// ATENA – Vista en miniatura de un croquis: el frente del aula y los bancos
// libres u ocupados. Al cambiar el tamaño también marca los lugares que se
// perderían.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../ui/atena_ui.dart';

/// Estado de un lugar en la miniatura.
enum CrqCelda {
  libre,
  ocupado,

  /// Ocupado, pero queda fuera del nuevo tamaño.
  perdido,

  /// Libre y fuera del nuevo tamaño.
  fuera,

  /// No se dibuja.
  vacia,
}

class CrqMiniatura extends StatelessWidget {
  final int filas;
  final int columnas;

  /// Estado de cada lugar, fila por fila (filas × columnas).
  final List<CrqCelda> celdas;

  final double ancho;
  final double alto;

  const CrqMiniatura({
    super.key,
    required this.filas,
    required this.columnas,
    required this.celdas,
    this.ancho = 84,
    this.alto = 64,
  });

  /// Miniatura de un croquis tal como está guardado.
  factory CrqMiniatura.de(
    Croquis croquis, {
    Key? key,
    double ancho = 84,
    double alto = 64,
  }) {
    return CrqMiniatura(
      key: key,
      filas: croquis.filas,
      columnas: croquis.columnas,
      celdas: [
        for (final a in croquis.asientos)
          a.trim().isEmpty ? CrqCelda.libre : CrqCelda.ocupado,
      ],
      ancho: ancho,
      alto: alto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(ancho, alto),
        painter: _MiniaturaPainter(
          filas: filas,
          columnas: columnas,
          celdas: celdas,
          libre: cs.outlineVariant,
          ocupado: cs.primary,
          perdido: cs.error,
          fuera: cs.outlineVariant.withValues(alpha: 0.4),
          frente: AtenaBrand.of(context).success.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _MiniaturaPainter extends CustomPainter {
  final int filas;
  final int columnas;
  final List<CrqCelda> celdas;
  final Color libre;
  final Color ocupado;
  final Color perdido;
  final Color fuera;
  final Color frente;

  const _MiniaturaPainter({
    required this.filas,
    required this.columnas,
    required this.celdas,
    required this.libre,
    required this.ocupado,
    required this.perdido,
    required this.fuera,
    required this.frente,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (filas <= 0 || columnas <= 0 || size.isEmpty) return;

    const altoFrente = 4.0;
    const separacion = 5.0;
    final gap = math.max(1.5, size.shortestSide * 0.035);
    final altoGrilla = size.height - altoFrente - separacion;
    final lado = math.min(
      (size.width - gap * (columnas - 1)) / columnas,
      (altoGrilla - gap * (filas - 1)) / filas,
    );
    if (lado <= 0) return;

    final anchoGrilla = lado * columnas + gap * (columnas - 1);
    final x0 = (size.width - anchoGrilla) / 2;
    final y0 = altoFrente + separacion;
    final pintura = Paint();

    // Frente del aula.
    pintura.color = frente;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, 0, anchoGrilla, altoFrente),
        const Radius.circular(2),
      ),
      pintura,
    );

    final radio = Radius.circular(lado * 0.24);
    for (var f = 0; f < filas; f++) {
      for (var c = 0; c < columnas; c++) {
        final i = f * columnas + c;
        final color = switch (i < celdas.length ? celdas[i] : CrqCelda.libre) {
          CrqCelda.libre => libre,
          CrqCelda.ocupado => ocupado,
          CrqCelda.perdido => perdido,
          CrqCelda.fuera => fuera,
          CrqCelda.vacia => null,
        };
        if (color == null) continue;
        pintura.color = color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x0 + c * (lado + gap),
              y0 + f * (lado + gap),
              lado,
              lado,
            ),
            radio,
          ),
          pintura,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniaturaPainter old) =>
      old.filas != filas ||
      old.columnas != columnas ||
      old.libre != libre ||
      old.ocupado != ocupado ||
      old.perdido != perdido ||
      old.fuera != fuera ||
      old.frente != frente ||
      !listEquals(old.celdas, celdas);
}
