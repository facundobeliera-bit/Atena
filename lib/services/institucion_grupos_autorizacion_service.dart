import '../models/instituciones/instituciones_integrado.dart';
import '../models/instituciones/operador_institucional.dart';
import '../models/instituciones/registro_auditoria_institucional.dart';
import 'institucion_auditoria_service.dart';
import 'institucion_operadores_service.dart';
import 'instituciones_helpers.dart' as helpers;

class InstitucionGruposAutorizacionService {
  InstitucionGruposAutorizacionService._();

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

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
    final now = DateTime.now().toUtc();
    for (final group in grupos) {
      group.areaId = areaId.trim();
      group.updatedByOperatorId = operator.id;
      group.updatedAt = now;
    }
    await helpers.guardarGruposInstitucion(institution, grupos);
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
