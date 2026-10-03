// lib/screens/instituciones/widgets/perf_inst_servicios.dart
//
// Editor de servicios del perfil público: etiquetas que se quitan con un
// toque, campo para sumar uno propio y sugerencias frecuentes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Servicios frecuentes, en el idioma activo.
List<String> perfInstServiciosSugeridos(AppLocalizations t) => [
  t.perfInstSrvComedor,
  t.perfInstSrvTransporte,
  t.perfInstSrvGabinete,
  t.perfInstSrvJornadaExtendida,
  t.perfInstSrvBilingue,
  t.perfInstSrvDeportes,
  t.perfInstSrvBecas,
  t.perfInstSrvLaboratorio,
  t.perfInstSrvBiblioteca,
  t.perfInstSrvAccesibilidad,
];

class PerfInstServicios extends StatefulWidget {
  final List<String> servicios;
  final int maximo;
  final bool habilitado;
  final ValueChanged<List<String>> onChanged;

  const PerfInstServicios({
    super.key,
    required this.servicios,
    required this.maximo,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  State<PerfInstServicios> createState() => _PerfInstServiciosState();
}

class _PerfInstServiciosState extends State<PerfInstServicios> {
  static const int _largoMaximo = 40;

  final _nuevo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nuevo.dispose();
    super.dispose();
  }

  bool _yaEsta(String servicio) {
    final clave = normalizarBusqueda(servicio);
    return widget.servicios.any((s) => normalizarBusqueda(s) == clave);
  }

  void _agregar(String valor, {bool desdeCampo = false}) {
    final t = AppLocalizations.of(context);
    final servicio = valor.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (servicio.isEmpty) return;

    final String? error;
    if (_yaEsta(servicio)) {
      error = t.perfInstServicioRepetido;
    } else if (widget.servicios.length >= widget.maximo) {
      error = t.perfInstServiciosMax(widget.maximo);
    } else {
      error = null;
    }

    setState(() => _error = error);
    if (error != null) return;
    if (desdeCampo) _nuevo.clear();
    widget.onChanged([...widget.servicios, servicio]);
  }

  void _quitar(String servicio) {
    setState(() => _error = null);
    widget.onChanged(widget.servicios.where((s) => s != servicio).toList());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sugeridos = perfInstServiciosSugeridos(
      t,
    ).where((s) => !_yaEsta(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.servicios.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in widget.servicios)
                InputChip(
                  label: Text(s),
                  isEnabled: widget.habilitado,
                  onDeleted: widget.habilitado ? () => _quitar(s) : null,
                  deleteButtonTooltipMessage: t.perfInstServicioQuitar(s),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _nuevo,
          enabled: widget.habilitado,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(_largoMaximo)],
          onSubmitted: (v) => _agregar(v, desdeCampo: true),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            labelText: t.perfInstServicioAgregar,
            hintText: t.perfInstServicioHint,
            errorText: _error,
            suffixIcon: IconButton(
              tooltip: t.perfInstServicioAgregar,
              onPressed: widget.habilitado
                  ? () => _agregar(_nuevo.text, desdeCampo: true)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        if (sugeridos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            t.perfInstServiciosSugeridos,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in sugeridos)
                ActionChip(
                  avatar: const Icon(Icons.add_rounded),
                  label: Text(s),
                  onPressed: widget.habilitado ? () => _agregar(s) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
