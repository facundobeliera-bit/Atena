import 'package:flutter/material.dart';

import '../../models/instituciones/area_operativa.dart';
import '../../models/instituciones/operador_institucional.dart';
import '../../models/instituciones/registro_auditoria_institucional.dart';
import '../../services/institucion_areas_service.dart';
import '../../services/institucion_auditoria_service.dart';
import '../../services/institucion_operadores_service.dart';

class InstitucionHistorialActividadPage extends StatefulWidget {
  final String institucionId;

  const InstitucionHistorialActividadPage({
    super.key,
    required this.institucionId,
  });

  @override
  State<InstitucionHistorialActividadPage> createState() =>
      _InstitucionHistorialActividadPageState();
}

class _InstitucionHistorialActividadPageState
    extends State<InstitucionHistorialActividadPage> {
  bool _loading = true;
  List<RegistroAuditoriaInstitucional> _records = const [];
  List<AreaOperativa> _areas = const [];
  List<OperadorInstitucional> _operators = const [];
  String? _areaId;
  String? _operatorId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _actionLabel(String action) => switch (action) {
    AccionAuditoriaInstitucional.requestConfirmed => 'Confirmó una solicitud',
    AccionAuditoriaInstitucional.requestRejected => 'Rechazó una solicitud',
    AccionAuditoriaInstitucional.groupCapacityChanged =>
      'Cambió la capacidad de un grupo',
    AccionAuditoriaInstitucional.groupUpdated => 'Actualizó un grupo',
    AccionAuditoriaInstitucional.eventCreated => 'Creó un evento',
    AccionAuditoriaInstitucional.eventUpdated => 'Actualizó un evento',
    AccionAuditoriaInstitucional.communicationSent => 'Emitió una comunicación',
    _ => 'Realizó una operación',
  };

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _load() async {
    final values = await Future.wait([
      InstitucionAuditoriaService.instance.listarAutorizado(
        institucionId: widget.institucionId,
        areaId: _areaId,
        operatorId: _operatorId,
      ),
      InstitucionAreasService.instance.listar(widget.institucionId),
      InstitucionOperadoresService.instance.listar(widget.institucionId),
    ]);
    if (!mounted) return;
    setState(() {
      _records = values[0] as List<RegistroAuditoriaInstitucional>;
      _areas = values[1] as List<AreaOperativa>;
      _operators = values[2] as List<OperadorInstitucional>;
      _loading = false;
    });
  }

  String _operatorName(String id) =>
      _operators
          .where((value) => value.id == id)
          .map((value) => value.nombreVisible)
          .firstOrNull ??
      'Operador histórico';

  String _areaName(String? id) =>
      _areas
          .where((value) => value.id == id)
          .map((value) => value.nombre)
          .firstOrNull ??
      'Sin área';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de actividad')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Trazabilidad funcional guardada localmente en este dispositivo.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    DropdownButton<String?>(
                      value: _areaId,
                      hint: const Text('Todas las áreas'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las áreas'),
                        ),
                        ..._areas.map(
                          (area) => DropdownMenuItem<String?>(
                            value: area.id,
                            child: Text(area.nombre),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _areaId = value);
                        _load();
                      },
                    ),
                    DropdownButton<String?>(
                      value: _operatorId,
                      hint: const Text('Todos los operadores'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los operadores'),
                        ),
                        ..._operators.map(
                          (operator) => DropdownMenuItem<String?>(
                            value: operator.id,
                            child: Text(operator.nombreVisible),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _operatorId = value);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_records.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Todavía no hay actividad visible.'),
                    ),
                  ),
                for (final record in _records)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_actionLabel(record.action)),
                      subtitle: Text(
                        '${_operatorName(record.operatorId)} · '
                        '${_areaName(record.areaId)} · '
                        '${record.resourceType} ${record.resourceId}',
                      ),
                      trailing: Text(_date(record.occurredAt)),
                    ),
                  ),
              ],
            ),
    );
  }
}
