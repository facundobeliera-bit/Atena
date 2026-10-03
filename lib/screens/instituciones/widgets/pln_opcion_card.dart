// lib/screens/instituciones/widgets/pln_opcion_card.dart
//
// Tarjetas seleccionables de niveles y módulos del plan, y la grilla que las
// acomoda según el ancho disponible.

import 'package:flutter/material.dart';

import '../../../models/extracurriculares/bloque_extracurricular.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_ui.dart';

Color plnColorNivel(NivelCurricular n) => switch (n) {
  NivelCurricular.jardin => AtenaColors.warning,
  NivelCurricular.primaria => AtenaColors.blue,
  NivelCurricular.secundaria => AtenaColors.indigo,
  NivelCurricular.tecnica => AtenaColors.goldDeep,
  NivelCurricular.terciario => AtenaColors.violet,
};

Color plnColorBloque(BloqueExtracurricular b) => switch (b) {
  BloqueExtracurricular.deporteYMovimiento => AtenaColors.success,
  BloqueExtracurricular.arteYExpresion => AtenaColors.violet,
  BloqueExtracurricular.idiomasYComunicacion => AtenaColors.info,
  BloqueExtracurricular.cienciaTecnologiaYRobotica => AtenaColors.indigo,
  BloqueExtracurricular.apoyoAcademico => AtenaColors.goldDeep,
  BloqueExtracurricular.desarrolloPersonalYBienestar => AtenaColors.blue,
  BloqueExtracurricular.otros => AtenaColors.neutral,
};

/// Opción del plan (un nivel o un módulo) que se marca o desmarca al tocarla.
class PlnOpcionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final String? descripcion;
  final String precio;

  /// Aclaración bajo el precio (por ejemplo, vacantes publicadas).
  final String? nota;
  final bool notaAlerta;

  final bool seleccionada;

  /// Ícono a la izquierda y textos al costado (para celdas anchas).
  final bool horizontal;

  /// null = deshabilitada.
  final VoidCallback? onTap;

  const PlnOpcionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.titulo,
    this.descripcion,
    required this.precio,
    this.nota,
    this.notaAlerta = false,
    required this.seleccionada,
    required this.horizontal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final desc = (descripcion ?? '').trim();
    final aclaracion = (nota ?? '').trim();

    final textos = <Widget>[
      Text(
        titulo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      if (desc.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          desc,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 6),
      Text(
        precio,
        style: theme.textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (aclaracion.isNotEmpty) ...[
        const SizedBox(height: 6),
        _Nota(texto: aclaracion, alerta: notaAlerta),
      ],
    ];

    final contenido = horizontal
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(icon: icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: textos,
                ),
              ),
              const SizedBox(width: 8),
              _Marca(seleccionada: seleccionada),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AtenaIconBadge(icon: icon, color: color, size: 40),
                  const Spacer(),
                  _Marca(seleccionada: seleccionada),
                ],
              ),
              const SizedBox(height: 12),
              ...textos,
            ],
          );

    return MergeSemantics(
      child: Semantics(
        checked: seleccionada,
        enabled: onTap != null,
        child: AnimatedContainer(
          duration: AtenaMotion.fast,
          curve: AtenaMotion.curve,
          decoration: BoxDecoration(
            color: seleccionada
                ? Color.alphaBlend(
                    cs.primary.withValues(alpha: 0.07),
                    cs.surface,
                  )
                : cs.surface,
            borderRadius: AtenaRadius.card,
            border: Border.all(
              color: seleccionada ? cs.primary : cs.outlineVariant,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AtenaRadius.card,
              child: Padding(
                // Compensa el borde más grueso para que el contenido no salte.
                padding: EdgeInsets.all(seleccionada ? 15 : 16),
                child: contenido,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  final bool seleccionada;

  const _Marca({required this.seleccionada});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AtenaMotion.fast,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seleccionada ? cs.primary : cs.surface,
        border: Border.all(
          color: seleccionada ? cs.primary : cs.outline,
          width: 1.6,
        ),
      ),
      child: seleccionada
          ? Icon(Icons.check_rounded, size: 18, color: cs.onPrimary)
          : null,
    );
  }
}

class _Nota extends StatelessWidget {
  final String texto;
  final bool alerta;

  const _Nota({required this.texto, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = alerta
        ? AtenaTone.of(context, AtenaBrand.of(context).warning).foreground
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          alerta
              ? Icons.pause_circle_outline_rounded
              : Icons.event_seat_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Grilla de opciones: reparte las tarjetas en columnas iguales y empareja
/// la altura de cada fila.
class PlnGrilla extends StatelessWidget {
  final int cantidad;
  final double anchoMinimo;
  final int maxColumnas;

  /// Ancho de celda desde el cual la tarjeta se arma en horizontal.
  final double anchoHorizontal;

  final Widget Function(BuildContext context, int index, bool horizontal)
  itemBuilder;

  const PlnGrilla({
    super.key,
    required this.cantidad,
    required this.anchoMinimo,
    required this.maxColumnas,
    required this.anchoHorizontal,
    required this.itemBuilder,
  });

  static const double _espacio = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = ((c.maxWidth + _espacio) / (anchoMinimo + _espacio))
            .floor()
            .clamp(1, maxColumnas);
        final ancho = (c.maxWidth - _espacio * (columnas - 1)) / columnas;
        final horizontal = ancho >= anchoHorizontal;

        return Column(
          children: [
            for (var i = 0; i < cantidad; i += columnas) ...[
              if (i > 0) const SizedBox(height: _espacio),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columnas; j++) ...[
                      if (j > 0) const SizedBox(width: _espacio),
                      Expanded(
                        child: i + j < cantidad
                            ? itemBuilder(context, i + j, horizontal)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
