import 'package:flutter/material.dart';

import '../../models/instituciones/area_operativa.dart';
import '../../models/instituciones/operador_institucional.dart';
import '../../services/institucion_areas_service.dart';
import '../../services/institucion_operadores_service.dart';
import '../../services/session_service.dart';

class InstitucionOperadoresPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionId;
  final String institucionNombre;

  const InstitucionOperadoresPage({
    super.key,
    required this.ownerAccountId,
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  State<InstitucionOperadoresPage> createState() =>
      _InstitucionOperadoresPageState();
}

class _InstitucionOperadoresPageState extends State<InstitucionOperadoresPage> {
  bool _loading = true;
  bool _denied = false;
  List<OperadorInstitucional> _operators = const [];
  List<AreaOperativa> _areas = const [];
  String? _activeId;

  Future<bool> _validSession() async {
    final session = await SessionService.getSession();
    final owner = await SessionService.getInstitucionOwnerAccountIdLogueado();
    return session?.role == SessionRole.institucion &&
        session?.userId.trim() == widget.institucionId.trim() &&
        (owner ?? '').trim() == widget.ownerAccountId.trim();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!await _validSession()) {
      if (mounted) {
        setState(() {
          _loading = false;
          _denied = true;
        });
      }
      return;
    }
    final service = InstitucionOperadoresService.instance;
    final owner = await service.asegurarPropietario(
      institucionId: widget.institucionId,
      ownerAccountId: widget.ownerAccountId,
      perfilInstitucionId: widget.institucionId,
      nombreVisible: '${widget.institucionNombre} · Propietario',
    );
    if (await service.operadorActivo(widget.institucionId) == null) {
      await service.activar(
        institucionId: widget.institucionId,
        operadorId: owner.id,
      );
    }
    final operators = await service.listar(widget.institucionId);
    final areas = await InstitucionAreasService.instance.listar(
      widget.institucionId,
    );
    if (mounted) {
      setState(() {
        _operators = operators;
        _areas = areas;
        _activeId = null;
        _loading = false;
        _denied = false;
      });
      final active = await service.operadorActivo(widget.institucionId);
      if (mounted) setState(() => _activeId = active?.id);
    }
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear operador local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este operador funciona en este dispositivo. No es una cuenta remota independiente.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nombre visible'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if ((name ?? '').isEmpty) {
      return;
    }
    await InstitucionOperadoresService.instance.crearLocal(
      institucionId: widget.institucionId,
      nombreVisible: name!,
    );
    await _load();
  }

  Future<void> _editAreas(OperadorInstitucional operator) async {
    final assigned =
        (await InstitucionOperadoresService.instance.areasAsignadas(
          widget.institucionId,
          operator.id,
        )).toSet();
    if (!mounted) {
      return;
    }
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Áreas de ${operator.nombreVisible}'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: _areas
                  .where((area) => area.activa)
                  .map(
                    (area) => CheckboxListTile(
                      value:
                          operator.esPropietario || assigned.contains(area.id),
                      onChanged: operator.esPropietario
                          ? null
                          : (value) => setLocalState(() {
                              if (value == true) {
                                assigned.add(area.id);
                              } else {
                                assigned.remove(area.id);
                              }
                            }),
                      title: Text(area.nombre),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: operator.esPropietario
                  ? null
                  : () => Navigator.pop(context, assigned),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) {
      return;
    }
    final service = InstitucionOperadoresService.instance;
    for (final area in _areas) {
      if (selected.contains(area.id)) {
        await service.asignarArea(
          institucionId: widget.institucionId,
          operadorId: operator.id,
          areaId: area.id,
        );
      } else {
        await service.desasignarArea(
          institucionId: widget.institucionId,
          operadorId: operator.id,
          areaId: area.id,
        );
      }
    }
    await _load();
  }

  String _capabilityLabel(String capability) => switch (capability) {
    CapacidadInstitucional.areaManage => 'Administrar áreas',
    CapacidadInstitucional.groupsRead => 'Consultar grupos y cupos',
    CapacidadInstitucional.groupsWrite => 'Modificar grupos y cupos',
    CapacidadInstitucional.requestsRead => 'Consultar solicitudes',
    CapacidadInstitucional.requestsDecide => 'Decidir solicitudes',
    CapacidadInstitucional.calendarRead => 'Consultar calendario',
    CapacidadInstitucional.calendarWrite => 'Modificar calendario',
    CapacidadInstitucional.responsesRead => 'Consultar respuestas',
    CapacidadInstitucional.communicationsWrite => 'Emitir comunicaciones',
    _ => capability,
  };

  Future<void> _editCapabilities(OperadorInstitucional operator) async {
    final selected = operator.capacidades.toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Capacidades de ${operator.nombreVisible}'),
          content: SizedBox(
            width: 460,
            child: ListView(
              shrinkWrap: true,
              children: CapacidadInstitucional.all
                  .map(
                    (capability) => CheckboxListTile(
                      value:
                          operator.esPropietario ||
                          selected.contains(capability),
                      onChanged: operator.esPropietario
                          ? null
                          : (enabled) => setLocalState(() {
                              if (enabled == true) {
                                selected.add(capability);
                              } else {
                                selected.remove(capability);
                              }
                            }),
                      title: Text(_capabilityLabel(capability)),
                      subtitle: Text(capability),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: operator.esPropietario
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: widget.institucionId,
      operadorId: operator.id,
      capacidades: result,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operadores')),
      floatingActionButton: _denied
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.person_add),
              label: const Text('Crear operador'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denied
          ? const Center(
              child: Text('No se pudo validar la sesión institucional.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Operadores locales',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Las identidades adicionales todavía no son cuentas remotas independientes.',
                ),
                const SizedBox(height: 12),
                for (final operator in _operators)
                  Card(
                    child: ListTile(
                      title: Text(operator.nombreVisible),
                      subtitle: Text(
                        operator.esPropietario
                            ? 'Propietario · acceso administrativo completo'
                            : '${operator.estado.name} · ${operator.capacidades.length} capacidades',
                      ),
                      trailing: Wrap(
                        children: [
                          if (_activeId != operator.id)
                            TextButton(
                              onPressed: operator.puedeActivarse
                                  ? () async {
                                      await InstitucionOperadoresService
                                          .instance
                                          .activar(
                                            institucionId: widget.institucionId,
                                            operadorId: operator.id,
                                          );
                                      await _load();
                                    }
                                  : null,
                              child: const Text('Usar'),
                            )
                          else
                            const Chip(label: Text('Activo')),
                          TextButton(
                            onPressed: () => _editAreas(operator),
                            child: const Text('Áreas'),
                          ),
                          TextButton(
                            onPressed: () => _editCapabilities(operator),
                            child: const Text('Capacidades'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
