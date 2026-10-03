// lib/screens/alumnos/widgets/explorar_institucion_card.dart
//
// ATENA – Tarjeta de una institución en los resultados de Explorar.
// El logo y las vacantes libres se piden al crear la tarjeta (carga perezosa)
// y se vuelven a pedir cuando cambia la versión de los datos.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'explorar_comun.dart';

class ExplorarInstitucionCard extends StatefulWidget {
  final InstitucionResumen institucion;
  final Future<Uint8List?> Function() cargarLogo;

  /// Ofertas activas con su ocupación (null si no se pudieron leer).
  final Future<List<OfertaConCupo>?> Function() cargarOfertas;

  /// Cambia cuando hay que volver a pedir los datos (al refrescar).
  final int version;
  final VoidCallback onTap;

  /// En grilla: la tarjeta toma el alto de la fila y el pie queda abajo.
  final bool llenarAlto;

  const ExplorarInstitucionCard({
    super.key,
    required this.institucion,
    required this.cargarLogo,
    required this.cargarOfertas,
    required this.version,
    required this.onTap,
    this.llenarAlto = false,
  });

  @override
  State<ExplorarInstitucionCard> createState() =>
      _ExplorarInstitucionCardState();
}

class _ExplorarInstitucionCardState extends State<ExplorarInstitucionCard> {
  static const int _maxEtiquetas = 3;

  late Future<Uint8List?> _logo;
  late Future<List<OfertaConCupo>?> _ofertas;

  @override
  void initState() {
    super.initState();
    _logo = widget.cargarLogo();
    _ofertas = widget.cargarOfertas();
  }

  @override
  void didUpdateWidget(covariant ExplorarInstitucionCard old) {
    super.didUpdateWidget(old);
    if (old.version != widget.version ||
        old.institucion.id != widget.institucion.id) {
      _logo = widget.cargarLogo();
      _ofertas = widget.cargarOfertas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inst = widget.institucion;

    final niveles = [...inst.niveles]
      ..sort((a, b) => a.index.compareTo(b.index));
    final bloques = [...inst.bloques]
      ..sort((a, b) => a.index.compareTo(b.index));
    final etiquetas = <({IconData icon, String label})>[
      for (final n in niveles) (icon: iconoNivel(n), label: t.nivel(n)),
      for (final b in bloques) (icon: iconoBloque(b), label: t.bloque(b)),
    ];
    final extra = etiquetas.length - _maxEtiquetas;
    final descripcion = inst.descripcion.trim();
    final ubicacion = inst.ubicacion;
    final tipo = t.tipoInstitucion(inst.tipo);

    final pie = Row(
      children: [
        FutureBuilder<List<OfertaConCupo>?>(
          future: _ofertas,
          builder: (context, snap) {
            final lista = snap.data;
            if (lista == null) {
              return snap.connectionState == ConnectionState.done
                  ? const SizedBox.shrink()
                  : const _PildoraCargando();
            }
            final libres = lista.fold<int>(0, (acc, o) => acc + o.disponibles);
            return AtenaStatusChip(
              label: t.lblCupos(libres),
              color: libres > 0
                  ? AtenaColors.success
                  : AtenaStatusColors.cancelled,
              icon: libres > 0
                  ? Icons.event_seat_rounded
                  : Icons.event_busy_rounded,
              dense: true,
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t.explorarVerInstitucion,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: cs.primary, size: 22),
      ],
    );

    return AtenaCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FutureBuilder<Uint8List?>(
                future: _logo,
                builder: (context, snap) => AtenaAvatar(
                  name: inst.nombre,
                  imageBytes: snap.data,
                  size: 56,
                  fallbackIcon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inst.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tipo · ${t.modalidad(inst.modalidad)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ubicacion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ubicacion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (etiquetas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in etiquetas.take(_maxEtiquetas))
                  ExplorarEtiqueta(icon: e.icon, label: e.label),
                if (extra > 0) ExplorarEtiqueta(label: '+$extra'),
              ],
            ),
          ],
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (widget.llenarAlto) const Spacer() else const SizedBox(height: 4),
          const SizedBox(height: 12),
          pie,
        ],
      ),
    );
  }
}

class _PildoraCargando extends StatelessWidget {
  const _PildoraCargando();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 22,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: AtenaRadius.pill,
      ),
    );
  }
}
