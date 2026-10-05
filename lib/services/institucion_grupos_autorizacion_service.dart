import '../models/instituciones/instituciones_integrado.dart';
import '../models/instituciones/operador_institucional.dart';
import '../models/instituciones/registro_auditoria_institucional.dart';
import 'institucion_auditoria_service.dart';
import 'institucion_operadores_service.dart';
import 'institucion_areas_service.dart';
import '../models/instituciones/area_operativa.dart';
import 'instituciones_helpers.dart' as helpers;

class InstitucionGruposAutorizacionService {
  InstitucionGruposAutorizacionService._();

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  static bool perteneceAlArea(
    GrupoInstitucional group,
    AreaOperativa area, {
    required int cantidadAreas,
  }) {
    final assigned = (group.areaId ?? '').trim();
    if (assigned.isNotEmpty) return assigned == area.id;
    // An unassigned historical group is unambiguous only with a single area
    // or an exact activity key/name. Never move groups between assigned areas.
    final activity = group.actividadNombre.trim().toLowerCase();
    return cantidadAreas == 1 ||
        activity == area.claveOrigen.toLowerCase() ||
        activity == area.nombre.toLowerCase();
  }

  static Future<void> guardarCurriculares({
    required String institucionId,
    required String areaId,
    required List<GrupoInstitucional> grupos,
  }) async {
    final institution = _id(institucionId);
    if (institution.isEmpty || areaId.trim().isEmpty) {
      throw StateError('No se pudo comprobar el ámbito de los grupos.');
    }
    final operator = await InstitucionOperadoresService.instance
        .autorizarActivo(
          institucionId: institution,
          areaId: areaId,
          capacidad: CapacidadInstitucional.groupsWrite,
        );
    if (operator == null) {
      throw StateError(
        'El operador activo no puede modificar grupos en esta área.',
      );
    }
    if (grupos.any((group) => _id(group.institucionId) != institution)) {
      throw StateError('La lista contiene un grupo de otra institución.');
    }
    final previous = {
      for (final group in await helpers.cargarGruposInstitucion(institution))
        group.id: group,
    };
    final areas = (await InstitucionAreasService.instance.listar(
      institution,
    )).where((a) => a.tipo == TipoAreaOperativa.curricular).toList();
    final matches = areas.where((a) => a.id == areaId.trim()).toList();
    if (matches.length != 1) {
      throw StateError('No se pudo comprobar el área curricular.');
    }
    final area = matches.single;
    bool belongs(GrupoInstitucional g) =>
        perteneceAlArea(g, area, cantidadAreas: areas.length);
    for (final group in grupos) {
      final before = previous[group.id];
      if ((before != null && !belongs(before)) ||
          ((group.areaId ?? '').isNotEmpty && group.areaId != area.id)) {
        throw StateError('No se pueden modificar grupos de otra área.');
      }
    }
    final now = DateTime.now().toUtc();
    for (final group in grupos) {
      group.areaId = areaId.trim();
      group.updatedByOperatorId = operator.id;
      group.updatedAt = now;
    }
    await helpers.guardarGruposInstitucion(institution, [
      ...previous.values.where((g) => !belongs(g)),
      ...grupos,
    ]);
    for (final group in grupos) {
      final before = previous[group.id];
      final capacityChanged =
          before != null && before.cupoMaximo != group.cupoMaximo;
      final updated =
          before == null ||
          capacityChanged ||
          before.nombreGrupo != group.nombreGrupo ||
          before.aula != group.aula ||
          before.turno != group.turno ||
          before.estado != group.estado;
      if (!updated) continue;
      try {
        await InstitucionAuditoriaService.instance.append(
          institucionId: institution,
          areaId: areaId,
          operatorId: operator.id,
          action: capacityChanged
              ? AccionAuditoriaInstitucional.groupCapacityChanged
              : AccionAuditoriaInstitucional.groupUpdated,
          resourceType: 'group',
          resourceId: group.id,
          metadata: {
            if (capacityChanged) 'previousCapacity': before.cupoMaximo,
            if (capacityChanged) 'resultingCapacity': group.cupoMaximo,
          },
        );
      } catch (_) {
        // La persistencia del grupo tiene prioridad sobre la traza local.
      }
    }
  }
}
