// lib/screens/alumnos/widgets/explorar_comun.dart
//
// ATENA – Piezas compartidas de Explorar, la ficha pública de la institución
// y el pedido de vacante: íconos de modalidad, etiquetas y datos con ícono.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// Datos del alumno necesarios para comparar con el rango de edad de una oferta.
typedef ExplorarAlumnoEdad = ({String nombre, int edad});

IconData iconoModalidad(ModalidadCursado m) => switch (m) {
  ModalidadCursado.presencial => Icons.apartment_rounded,
  ModalidadCursado.remoto => Icons.laptop_rounded,
  ModalidadCursado.hibrido => Icons.devices_rounded,
};

/// Rango de edad de una oferta; si es una sola edad ("Sala de 3"), la muestra
/// sin repetirla ("3 años" en lugar de "De 3 a 3 años").
String explorarRangoEdad(AppLocalizations t, int? min, int? max) =>
    min != null && min == max ? t.lblEdadAnios(min) : t.rangoEdad(min, max);

/// Dirección completa de la institución, sin partes repetidas.
String explorarDireccion(Institucion i) {
  final vistas = <String>{};
  final partes = <String>[];
  for (final p in [i.direccion, i.ciudad, i.provincia, i.pais]) {
    final v = p.trim();
    if (v.isEmpty || !vistas.add(v.toLowerCase())) continue;
    partes.add(v);
  }
  return partes.join(', ');
}

/// Etiqueta neutra con ícono opcional (niveles, actividades, servicios).
class ExplorarEtiqueta extends StatelessWidget {
  final IconData? icon;
  final String label;

  const ExplorarEtiqueta({super.key, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.xs)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dato breve con ícono (turno, días, edad, arancel…).
class ExplorarDato extends StatelessWidget {
  final IconData icon;
  final String texto;

  /// Color de aviso (por ejemplo, edad fuera de rango).
  final Color? color;

  const ExplorarDato({
    super.key,
    required this.icon,
    required this.texto,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tono = color == null ? null : AtenaTone.of(context, color!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: tono?.foreground ?? cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tono?.foreground ?? cs.onSurface,
              fontWeight: tono == null ? null : FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
