// lib/screens/instituciones/widgets/crq_banco.dart
//
// ATENA – Banco del croquis de aula: número discreto y el nombre abreviado del
// alumno, o "+" si el lugar está libre. Se usa en la grilla del editor y como
// vista mientras se arrastra un banco.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Nombre para mostrar dentro de un banco: "Lucía G." si hay lugar, o solo
/// "Lucía" en bancos chicos. Acepta también el formato "Gómez, Lucía".
String crqNombreCorto(String nombre, {required bool amplio}) {
  var limpio = nombre.trim();
  final coma = limpio.indexOf(',');
  if (coma > 0) {
    limpio =
        '${limpio.substring(coma + 1).trim()} ${limpio.substring(0, coma).trim()}'
            .trim();
  }
  final partes = limpio
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '';
  if (partes.length == 1 || !amplio) return partes.first;
  return '${partes.first} ${partes.last.characters.first.toUpperCase()}.';
}

class CrqBanco extends StatelessWidget {
  /// Número de banco (desde 1, contando por filas desde el frente).
  final int numero;

  /// Nombre del alumno; vacío si el lugar está libre.
  final String nombre;

  /// Lado del banco.
  final double tamano;

  /// Se está por soltar otro banco encima.
  final bool resaltado;

  /// Lugar de origen mientras se arrastra su banco.
  final bool fantasma;

  /// Vista flotante del banco que se arrastra.
  final bool elevado;

  final VoidCallback? onTap;

  const CrqBanco({
    super.key,
    required this.numero,
    required this.nombre,
    required this.tamano,
    this.resaltado = false,
    this.fantasma = false,
    this.elevado = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final completo = nombre.trim();
    final ocupado = completo.isNotEmpty && !fantasma;
    final amplio = tamano >= 64;

    final fondo = resaltado
        ? Color.alphaBlend(cs.primary.withValues(alpha: 0.18), cs.surface)
        : ocupado
        ? cs.primaryContainer
        : cs.surfaceContainerLow;
    final borde = resaltado
        ? cs.primary
        : ocupado
        ? cs.primary.withValues(alpha: 0.45)
        : cs.outlineVariant;
    final tinta = ocupado ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    final contenido = ocupado
        ? Text(
            crqNombreCorto(completo, amplio: amplio),
            textAlign: TextAlign.center,
            maxLines: amplio ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tinta,
              fontWeight: FontWeight.w700,
              fontSize: (tamano * 0.17).clamp(10.0, 13.5),
              height: 1.15,
              letterSpacing: 0,
            ),
          )
        : Icon(
            Icons.add_rounded,
            size: tamano * 0.36,
            color: tinta.withValues(alpha: fantasma ? 0.3 : 0.7),
          );

    final banco = SizedBox.square(
      dimension: tamano,
      child: Material(
        color: fondo,
        elevation: elevado ? 8 : 0,
        shadowColor: cs.shadow.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tamano * 0.2),
          side: BorderSide(color: borde, width: resaltado ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                top: tamano * 0.06,
                start: tamano * 0.11,
                child: Text(
                  '$numero',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: amplio ? 10 : 8.5,
                    letterSpacing: 0,
                    color: tinta.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(3, tamano * 0.2, 3, 3),
                  child: Center(child: contenido),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: '${t.crqBanco(numero)}: ${ocupado ? completo : t.crqBancoLibre}',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: ocupado && !elevado
          // En pantallas táctiles el toque largo queda para arrastrar el banco:
          // el nombre completo solo aparece al pasar el mouse.
          ? Tooltip(
              message: completo,
              triggerMode: TooltipTriggerMode.manual,
              child: banco,
            )
          : banco,
    );
  }
}
