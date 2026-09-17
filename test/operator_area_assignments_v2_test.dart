import 'dart:convert';

import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/asignacion_operador_area.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionA = 'v2-institution-a';
const institutionB = 'v2-institution-b';

Future<AreaOperativa> createArea(String institution, String key) async =>
    (await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institution,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: key,
      nombre: key,
    ))!;

Future<OperadorInstitucional> createOperator(String institution, String name) =>
    InstitucionOperadoresService.instance.crearLocal(
      institucionId: institution,
      nombreVisible: name,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'capacidades son independientes por área para el mismo operador',
    () async {
      final primary = await createArea(institutionA, 'primaria');
      final secondary = await createArea(institutionA, 'secundaria');
      final operator = await createOperator(institutionA, 'Facu');
      final service = InstitucionOperadoresService.instance;
      await service.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: primary.id,
      );
      await service.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: secondary.id,
      );
      await service.concederCapacidadEnArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      );

      expect(
        await service.puedeRealizar(
          institucionId: institutionA,
          operadorId: operator.id,
          areaId: primary.id,
          capacidad: CapacidadInstitucional.groupsWrite,
        ),
        isTrue,
      );
      expect(
        await service.puedeRealizar(
          institucionId: institutionA,
          operadorId: operator.id,
          areaId: secondary.id,
          capacidad: CapacidadInstitucional.groupsWrite,
        ),
        isFalse,
      );
    },
  );

  test('retirar una capacidad no afecta otra asignación', () async {
    final primary = await createArea(institutionA, 'primaria');
    final secondary = await createArea(institutionA, 'secundaria');
    final operator = await createOperator(institutionA, 'Operador');
    final service = InstitucionOperadoresService.instance;
    for (final area in [primary, secondary]) {
      await service.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
      );
      await service.concederCapacidadEnArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      );
    }
    await service.retirarCapacidadEnArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: primary.id,
      capacidad: CapacidadInstitucional.groupsWrite,
    );
    expect(
      await service.puedeRealizar(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: primary.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      ),
      isFalse,
    );
    expect(
      await service.puedeRealizar(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: secondary.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      ),
      isTrue,
    );
  });

  test('asignación, operador o área inactivos deniegan capacidades', () async {
    final area = await createArea(institutionA, 'primaria');
    final operator = await createOperator(institutionA, 'Operador');
    final service = InstitucionOperadoresService.instance;
    await service.asignarArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
    );
    await service.concederCapacidadEnArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
      capacidad: CapacidadInstitucional.groupsRead,
    );
    await service.setEstadoAsignacion(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
      estado: EstadoAsignacionOperadorArea.suspendida,
    );
    expect(await _canRead(operator.id, area.id), isFalse);
    await service.setEstadoAsignacion(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
      estado: EstadoAsignacionOperadorArea.activa,
    );
    await service.actualizar(
      institucionId: institutionA,
      operadorId: operator.id,
      estado: EstadoOperadorInstitucional.suspendido,
    );
    expect(await _canRead(operator.id, area.id), isFalse);
    await service.actualizar(
      institucionId: institutionA,
      operadorId: operator.id,
      estado: EstadoOperadorInstitucional.activo,
    );
    await InstitucionAreasService.instance.setActiva(
      institucionId: institutionA,
      areaId: area.id,
      activa: false,
    );
    expect(await _canRead(operator.id, area.id), isFalse);
  });

  test('V2 sin permiso prevalece sobre capacidad global legacy', () async {
    final area = await createArea(institutionA, 'primaria');
    final operator = await createOperator(institutionA, 'Legacy');
    final service = InstitucionOperadoresService.instance;
    await service.setCapacidades(
      institucionId: institutionA,
      operadorId: operator.id,
      capacidades: {CapacidadInstitucional.groupsWrite},
    );
    await service.asignarArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
    );
    await service.retirarCapacidadEnArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
      capacidad: CapacidadInstitucional.groupsWrite,
    );
    expect(
      (await service.buscar(institutionA, operator.id))!.capacidades,
      contains(CapacidadInstitucional.groupsWrite),
    );
    expect(
      await service.puedeRealizar(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
        capacidad: CapacidadInstitucional.groupsWrite,
      ),
      isFalse,
    );
  });

  test('migración V1 es idempotente, completa y aislada', () async {
    final areaA = await createArea(institutionA, 'primaria');
    final areaB = await createArea(institutionB, 'primaria');
    final operatorA = await createOperator(institutionA, 'A');
    final operatorB = await createOperator(institutionB, 'B');
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institutionA,
      operadorId: operatorA.id,
      capacidades: {CapacidadInstitucional.requestsRead},
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institutionB,
      operadorId: operatorB.id,
      capacidades: {CapacidadInstitucional.calendarRead},
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'inst_operator_areas_v1_v2_institution_a',
      jsonEncode([
        AsignacionOperador(
          institucionId: institutionA,
          operadorId: operatorA.id,
          areaIds: [areaA.id, areaA.id],
          updatedAt: DateTime.utc(2026),
        ).toMap(),
      ]),
    );
    await prefs.setString(
      'inst_operator_areas_v1_v2_institution_b',
      jsonEncode([
        AsignacionOperador(
          institucionId: institutionB,
          operadorId: operatorB.id,
          areaIds: [areaB.id],
          updatedAt: DateTime.utc(2026),
        ).toMap(),
      ]),
    );
    final first = await InstitucionOperadoresService.instance
        .listarAsignacionesOperador(institutionA, operatorA.id);
    final second = await InstitucionOperadoresService.instance
        .listarAsignacionesOperador(institutionA, operatorA.id);
    expect(first, hasLength(1));
    expect(second, hasLength(1));
    expect(first.single.capacidades, {CapacidadInstitucional.requestsRead});
    expect(first.single.institucionId, institutionA);
    expect(
      await InstitucionOperadoresService.instance.listarAsignacionesOperador(
        institutionB,
        operatorB.id,
      ),
      hasLength(1),
    );
  });

  test('responsable es único y suspenderlo deja el área vacante', () async {
    final area = await createArea(institutionA, 'primaria');
    final first = await createOperator(institutionA, 'Primero');
    final second = await createOperator(institutionA, 'Segundo');
    final service = InstitucionOperadoresService.instance;
    for (final operator in [first, second]) {
      await service.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
      );
    }
    expect(await service.responsableArea(institutionA, area.id), isNull);
    await service.establecerResponsable(
      institucionId: institutionA,
      areaId: area.id,
      operadorId: first.id,
    );
    await service.establecerResponsable(
      institucionId: institutionA,
      areaId: area.id,
      operadorId: second.id,
    );
    expect(
      (await service.responsableArea(institutionA, area.id))?.operadorId,
      second.id,
    );
    await service.setEstadoAsignacion(
      institucionId: institutionA,
      operadorId: second.id,
      areaId: area.id,
      estado: EstadoAsignacionOperadorArea.suspendida,
    );
    expect(await service.responsableArea(institutionA, area.id), isNull);
  });

  test(
    'propietario conserva administración sin asignación ni responsabilidad',
    () async {
      final area = await createArea(institutionA, 'primaria');
      final owner = await InstitucionOperadoresService.instance
          .asegurarPropietario(
            institucionId: institutionA,
            ownerAccountId: 'owner-a',
            perfilInstitucionId: institutionA,
            nombreVisible: 'Propietario',
          );
      expect(
        await InstitucionOperadoresService.instance.listarAsignacionesOperador(
          institutionA,
          owner.id,
        ),
        isEmpty,
      );
      expect(
        await InstitucionOperadoresService.instance.responsableArea(
          institutionA,
          area.id,
        ),
        isNull,
      );
      expect(
        await InstitucionOperadoresService.instance.puedeRealizar(
          institucionId: institutionA,
          operadorId: owner.id,
          areaId: area.id,
          capacidad: CapacidadInstitucional.areaManage,
        ),
        isTrue,
      );
    },
  );
}

Future<bool> _canRead(String operatorId, String areaId) =>
    InstitucionOperadoresService.instance.puedeRealizar(
      institucionId: institutionA,
      operadorId: operatorId,
      areaId: areaId,
      capacidad: CapacidadInstitucional.groupsRead,
    );
