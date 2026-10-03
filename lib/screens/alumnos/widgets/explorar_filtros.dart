// lib/screens/alumnos/widgets/explorar_filtros.dart
//
// ATENA – Filtros de Explorar instituciones.
// - Teléfono: fila desplazable de chips; cada categoría abre una hoja con
//   sus opciones.
// - Escritorio: panel lateral con todas las opciones a la vista.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../models/extracurriculares/bloque_extracurricular.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'explorar_comun.dart';

/// Filtros elegidos (además del texto de búsqueda).
@immutable
class ExplorarFiltrosData {
  final NivelCurricular? nivel;
  final BloqueExtracurricular? bloque;
  final ModalidadCursado? modalidad;

  /// Solo instituciones con vacantes libres para la edad del alumno.
  final bool soloEdad;

  const ExplorarFiltrosData({
    this.nivel,
    this.bloque,
    this.modalidad,
    this.soloEdad = false,
  });

  bool get activos =>
      nivel != null || bloque != null || modalidad != null || soloEdad;

  ExplorarFiltrosData conNivel(NivelCurricular? v) => ExplorarFiltrosData(
    nivel: v,
    bloque: bloque,
    modalidad: modalidad,
    soloEdad: soloEdad,
  );

  ExplorarFiltrosData conBloque(BloqueExtracurricular? v) =>
      ExplorarFiltrosData(
        nivel: nivel,
        bloque: v,
        modalidad: modalidad,
        soloEdad: soloEdad,
      );

  ExplorarFiltrosData conModalidad(ModalidadCursado? v) => ExplorarFiltrosData(
    nivel: nivel,
    bloque: bloque,
    modalidad: v,
    soloEdad: soloEdad,
  );

  ExplorarFiltrosData conSoloEdad(bool v) => ExplorarFiltrosData(
    nivel: nivel,
    bloque: bloque,
    modalidad: modalidad,
    soloEdad: v,
  );
}

// -----------------------------------------------------------------------------
// Teléfono
// -----------------------------------------------------------------------------

/// Fila horizontal de chips: edad del alumno, Nivel ▾, Actividades ▾ y
/// Modalidad ▾.
class ExplorarFiltrosChips extends StatelessWidget {
  final ExplorarFiltrosData filtros;

  /// null = edad desconocida (no se ofrece el filtro por edad).
  final ExplorarAlumnoEdad? alumno;
  final ValueChanged<ExplorarFiltrosData> onChanged;
  final EdgeInsetsGeometry padding;

  const ExplorarFiltrosChips({
    super.key,
    required this.filtros,
    required this.alumno,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: AtenaSpace.page),
  });

  Future<void> _nivel(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final r = await _elegirOpcion<NivelCurricular>(
      context,
      titulo: t.explorarFiltroNivel,
      cualquiera: t.explorarCualquierNivel,
      iconoCualquiera: Icons.apps_rounded,
      opciones: NivelCurricular.values,
      actual: filtros.nivel,
      etiqueta: t.nivel,
      icono: iconoNivel,
    );
    if (r != null) onChanged(filtros.conNivel(r.valor));
  }

  Future<void> _bloque(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final r = await _elegirOpcion<BloqueExtracurricular>(
      context,
      titulo: t.explorarFiltroActividad,
      cualquiera: t.explorarCualquierActividad,
      iconoCualquiera: Icons.apps_rounded,
      opciones: BloqueExtracurricularX.ordered(),
      actual: filtros.bloque,
      etiqueta: t.bloque,
      icono: iconoBloque,
    );
    if (r != null) onChanged(filtros.conBloque(r.valor));
  }

  Future<void> _modalidad(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final r = await _elegirOpcion<ModalidadCursado>(
      context,
      titulo: t.explorarFiltroModalidad,
      cualquiera: t.explorarCualquierModalidad,
      iconoCualquiera: Icons.apps_rounded,
      opciones: ModalidadCursado.values,
      actual: filtros.modalidad,
      etiqueta: t.modalidad,
      icono: iconoModalidad,
    );
    if (r != null) onChanged(filtros.conModalidad(r.valor));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final f = filtros;
    final a = alumno;
    const gap = SizedBox(width: 8);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          // El filtro por edad va primero: es el más útil y queda a la vista.
          if (a != null) ...[
            FilterChip(
              avatar: Icon(
                f.soloEdad ? Icons.check_rounded : Icons.cake_rounded,
              ),
              label: Text(t.explorarConLugarPara(a.nombre)),
              selected: f.soloEdad,
              showCheckmark: false,
              onSelected: (v) => onChanged(f.conSoloEdad(v)),
            ),
            gap,
          ],
          _ChipDesplegable(
            icon: f.nivel == null ? Icons.school_rounded : iconoNivel(f.nivel!),
            label: f.nivel == null ? t.explorarFiltroNivel : t.nivel(f.nivel!),
            activo: f.nivel != null,
            onTap: () => _nivel(context),
          ),
          gap,
          _ChipDesplegable(
            icon: f.bloque == null
                ? Icons.interests_rounded
                : iconoBloque(f.bloque!),
            label: f.bloque == null
                ? t.explorarFiltroActividad
                : t.bloque(f.bloque!),
            activo: f.bloque != null,
            onTap: () => _bloque(context),
          ),
          gap,
          _ChipDesplegable(
            icon: f.modalidad == null
                ? Icons.public_rounded
                : iconoModalidad(f.modalidad!),
            label: f.modalidad == null
                ? t.explorarFiltroModalidad
                : t.modalidad(f.modalidad!),
            activo: f.modalidad != null,
            onTap: () => _modalidad(context),
          ),
        ],
      ),
    );
  }
}

class _ChipDesplegable extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _ChipDesplegable({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon),
      selected: activo,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ],
      ),
    );
  }
}

/// Hoja con las opciones de una categoría.
/// Devuelve null si se cerró sin elegir; `(valor: null)` = cualquiera.
Future<({T? valor})?> _elegirOpcion<T>(
  BuildContext context, {
  required String titulo,
  required String cualquiera,
  required IconData iconoCualquiera,
  required List<T> opciones,
  required T? actual,
  required String Function(T) etiqueta,
  required IconData Function(T) icono,
}) {
  return showModalBottomSheet<({T? valor})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;

      Widget opcion(T? valor, IconData icon, String label) {
        final elegida = valor == actual;
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          selected: elegida,
          selectedTileColor: cs.primaryContainer.withValues(alpha: 0.55),
          trailing: elegida ? const Icon(Icons.check_rounded) : null,
          onTap: () => Navigator.of(ctx).pop((valor: valor)),
        );
      }

      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(titulo, style: theme.textTheme.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  opcion(null, iconoCualquiera, cualquiera),
                  for (final o in opciones) opcion(o, icono(o), etiqueta(o)),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// Escritorio
// -----------------------------------------------------------------------------

/// Panel lateral con todos los filtros visibles.
class ExplorarFiltrosPanel extends StatelessWidget {
  final ExplorarFiltrosData filtros;
  final ExplorarAlumnoEdad? alumno;
  final ValueChanged<ExplorarFiltrosData> onChanged;

  /// null = no hay nada que limpiar (ni filtros ni texto de búsqueda).
  final VoidCallback? onLimpiar;

  const ExplorarFiltrosPanel({
    super.key,
    required this.filtros,
    required this.alumno,
    required this.onChanged,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = filtros;
    final a = alumno;

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.explorarFiltros,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onLimpiar,
                child: Text(t.explorarLimpiarFiltros),
              ),
            ],
          ),
          if (a != null) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              value: f.soloEdad,
              onChanged: (v) => onChanged(f.conSoloEdad(v)),
              contentPadding: EdgeInsets.zero,
              title: Text(t.explorarConLugarPara(a.nombre)),
              subtitle: Text(
                t.explorarConLugarAyuda(a.nombre, t.lblEdadAnios(a.edad)),
              ),
            ),
            const Divider(height: 24),
          ] else
            const SizedBox(height: 8),
          _Grupo(
            titulo: t.explorarFiltroNivel,
            chips: [
              for (final n in NivelCurricular.values)
                ChoiceChip(
                  avatar: Icon(iconoNivel(n)),
                  label: Text(t.nivel(n)),
                  selected: f.nivel == n,
                  onSelected: (v) => onChanged(f.conNivel(v ? n : null)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Grupo(
            titulo: t.explorarFiltroActividad,
            chips: [
              for (final b in BloqueExtracurricularX.ordered())
                ChoiceChip(
                  avatar: Icon(iconoBloque(b)),
                  label: Text(t.bloque(b)),
                  selected: f.bloque == b,
                  onSelected: (v) => onChanged(f.conBloque(v ? b : null)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Grupo(
            titulo: t.explorarFiltroModalidad,
            chips: [
              for (final m in ModalidadCursado.values)
                ChoiceChip(
                  avatar: Icon(iconoModalidad(m)),
                  label: Text(t.modalidad(m)),
                  selected: f.modalidad == m,
                  onSelected: (v) => onChanged(f.conModalidad(v ? m : null)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  final String titulo;
  final List<Widget> chips;

  const _Grupo({required this.titulo, required this.chips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        // Cada chip ya reserva 48 px de alto táctil: no hace falta más aire.
        Wrap(spacing: 8, children: chips),
      ],
    );
  }
}
