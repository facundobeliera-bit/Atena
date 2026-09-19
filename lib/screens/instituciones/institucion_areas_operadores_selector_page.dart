import 'package:flutter/material.dart';

import '../../models/instituciones/area_operativa.dart';
import '../../models/instituciones/asignacion_operador_area.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/instituciones/operador_institucional.dart';
import '../../services/institucion_areas_service.dart';
import '../../services/institucion_contexto_operativo_service.dart';
import '../../services/institucion_operadores_service.dart';
import '../../services/session_service.dart';
import 'institucion_area_page.dart';
import 'institucion_operadores_page.dart';

class InstitucionAreasOperadoresSelectorPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionId;
  final String institucionNombre;
  final Institucion institucion;

  const InstitucionAreasOperadoresSelectorPage({
    super.key,
    required this.ownerAccountId,
    required this.institucionId,
    required this.institucionNombre,
    required this.institucion,
  });

  @override
  State<InstitucionAreasOperadoresSelectorPage> createState() =>
      _InstitucionAreasOperadoresSelectorPageState();
}

class _InstitucionAreasOperadoresSelectorPageState
    extends State<InstitucionAreasOperadoresSelectorPage> {
  bool _loading = true;
  List<AreaOperativa> _areas = const [];
  Map<String, List<AsignacionOperadorArea>> _assignments = const {};
  Map<String, OperadorInstitucional> _operators = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SessionService.clearInstitutionOperationalContext();
    for (final level in widget.institucion.planSafe.niveles) {
      if (!level.habilitado) continue;
      await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: widget.institucionId,
        tipo: TipoAreaOperativa.curricular,
        claveOrigen: level.nivel.name,
        nombre: (level.nombrePropio ?? '').trim().isEmpty
            ? _title(level.nivel.name)
            : level.nombrePropio!.trim(),
      );
    }
    for (final module in widget.institucion.planSafe.modulos) {
      if (!module.habilitado) continue;
      await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: widget.institucionId,
        tipo: TipoAreaOperativa.extracurricular,
        claveOrigen: module.bloque.name,
        nombre: _title(module.bloque.name),
      );
    }
    final areas = (await InstitucionAreasService.instance.listar(
      widget.institucionId,
    )).where((value) => value.activa).toList();
    final operators = {
      for (final value in await InstitucionOperadoresService.instance.listar(
        widget.institucionId,
      ))
        value.id: value,
    };
    final assignments = <String, List<AsignacionOperadorArea>>{};
    for (final area in areas) {
      assignments[area.id] =
          (await InstitucionOperadoresService.instance.listarAsignacionesArea(
                widget.institucionId,
                area.id,
              ))
              .where(
                (value) =>
                    value.estaActiva &&
                    operators[value.operadorId]?.puedeActivarse == true,
              )
              .toList();
    }
    if (!mounted) return;
    setState(() {
      _areas = areas;
      _operators = operators;
      _assignments = assignments;
      _loading = false;
    });
  }

  String _title(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).replaceAll('_', ' ')}';

  Future<void> _enter(AreaOperativa area) async {
    final assignments = _assignments[area.id] ?? const [];
    if (assignments.isEmpty) return;
    final selected = await showDialog<AsignacionOperadorArea>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Quién está ingresando?'),
        children: [
          for (final assignment in assignments)
            SimpleDialogOption(
              key: ValueKey('operator-${assignment.operadorId}'),
              onPressed: () => Navigator.pop(context, assignment),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _operators[assignment.operadorId]?.nombreVisible ??
                      assignment.operadorId,
                ),
                subtitle: assignment.esResponsable
                    ? const Text('Responsable del área')
                    : null,
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final contextValue = await InstitucionContextoOperativoService.instance
        .activarContextoOperativo(
          institucionId: widget.institucionId,
          ownerAccountId: widget.ownerAccountId,
          areaId: area.id,
          operadorId: selected.operadorId,
        );
    if (contextValue == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo validar el acceso al área.'),
          ),
        );
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstitucionAreaPage(
          ownerAccountId: widget.ownerAccountId,
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          institucion: widget.institucion,
          areaId: area.id,
          operatorId: selected.operadorId,
          actividadKey: area.claveOrigen,
          actividadLabel: area.nombre,
          workProfileId: 'legacy_operator_${selected.operadorId}',
        ),
      ),
    );
    await SessionService.clearInstitutionOperationalContext();
    if (mounted) await _load();
  }

  Future<void> _manageOperators() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstitucionOperadoresPage(
          ownerAccountId: widget.ownerAccountId,
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Áreas operativas')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final area in _areas) _areaCard(area),
                if (_areas.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Todavía no hay áreas operativas habilitadas.',
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );

  Widget _areaCard(AreaOperativa area) {
    final assignments = _assignments[area.id] ?? const [];
    final responsible = assignments
        .where((value) => value.esResponsable)
        .firstOrNull;
    final responsibleName = responsible == null
        ? 'Sin responsable asignado'
        : _operators[responsible.operadorId]?.nombreVisible ??
              responsible.operadorId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Responsable: $responsibleName'),
            Text('Operadores habilitados: ${assignments.length}'),
            const SizedBox(height: 12),
            if (assignments.isEmpty) ...[
              const Text('Sin operadores asignados'),
              TextButton(
                onPressed: _manageOperators,
                child: const Text('Configurar equipo'),
              ),
            ] else
              FilledButton(
                key: ValueKey('enter-area-${area.id}'),
                onPressed: () => _enter(area),
                child: const Text('Entrar'),
              ),
          ],
        ),
      ),
    );
  }
}
