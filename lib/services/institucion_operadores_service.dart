import '../models/instituciones/operador_institucional.dart';
import 'institucion_areas_service.dart';
import 'session_service.dart';
import 'storage_service.dart';

class InstitucionOperadoresService {
  InstitucionOperadoresService._();
  static final instance = InstitucionOperadoresService._();

  static const _operatorsPrefix = 'inst_operators_v1_';
  static const _assignmentsPrefix = 'inst_operator_areas_v1_';

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');
  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  String _operatorsKey(String institution) =>
      '$_operatorsPrefix${InstitucionAreasService.normalizeKey(institution)}';
  String _assignmentsKey(String institution) =>
      '$_assignmentsPrefix${InstitucionAreasService.normalizeKey(institution)}';

  Future<List<OperadorInstitucional>> listar(String institucionId) async {
    final institution = _id(institucionId);
    if (institution.isEmpty) {
      return const [];
    }
    final raw = await StorageService.instance.getJsonList(
      _operatorsKey(institution),
    );
    return raw
        .map(OperadorInstitucional.fromMap)
        .where(
          (operator) =>
              operator.id.isNotEmpty && operator.institucionId == institution,
        )
        .toList(growable: true);
  }

  Future<void> _saveOperators(
    String institution,
    List<OperadorInstitucional> operators,
  ) async {
    await StorageService.instance.setJsonList(
      _operatorsKey(institution),
      operators.map((operator) => operator.toMap()).toList(),
    );
  }

  Future<OperadorInstitucional> asegurarPropietario({
    required String institucionId,
    required String ownerAccountId,
    required String perfilInstitucionId,
    required String nombreVisible,
  }) async {
    final institution = _id(institucionId);
    final owner = _id(ownerAccountId);
    final profile = _id(perfilInstitucionId);
    if (institution.isEmpty || owner.isEmpty || profile != institution) {
      throw StateError('Identidad propietaria institucional inválida.');
    }
    final stable = _hash('$institution::$owner::$profile').toRadixString(16);
    final operatorId = 'operator_owner_$stable';
    final operators = await listar(institution);
    final existing = operators
        .where((value) => value.id == operatorId)
        .firstOrNull;
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now().toUtc();
    final operator = OperadorInstitucional(
      id: operatorId,
      institucionId: institution,
      cuentaId: owner,
      perfilInstitucionId: profile,
      nombreVisible: nombreVisible.trim().isEmpty
          ? 'Propietario'
          : nombreVisible.trim(),
      esPropietario: true,
      estado: EstadoOperadorInstitucional.activo,
      createdAt: now,
      updatedAt: now,
    );
    operators.add(operator);
    await _saveOperators(institution, operators);
    return operator;
  }

  Future<OperadorInstitucional> crearLocal({
    required String institucionId,
    required String nombreVisible,
  }) async {
    final institution = _id(institucionId);
    final name = nombreVisible.trim();
    if (institution.isEmpty || name.isEmpty) {
      throw ArgumentError('Datos incompletos.');
    }
    final now = DateTime.now().toUtc();
    final operators = await listar(institution);
    final institutionHash = _hash(institution).toRadixString(16);
    var id =
        'operator_local_${institutionHash}_${now.microsecondsSinceEpoch.toRadixString(16)}';
    var counter = 1;
    while (operators.any((value) => value.id == id)) {
      id =
          'operator_local_${institutionHash}_${now.microsecondsSinceEpoch.toRadixString(16)}_$counter';
      counter++;
    }
    final operator = OperadorInstitucional(
      id: id,
      institucionId: institution,
      cuentaId: null,
      perfilInstitucionId: null,
      nombreVisible: name,
      esPropietario: false,
      estado: EstadoOperadorInstitucional.activo,
      createdAt: now,
      updatedAt: now,
    );
    operators.add(operator);
    await _saveOperators(institution, operators);
    return operator;
  }

  Future<OperadorInstitucional?> buscar(
    String institution,
    String operatorId,
  ) async {
    final id = _id(operatorId);
    for (final operator in await listar(institution)) {
      if (operator.id == id) {
        return operator;
      }
    }
    return null;
  }

  Future<bool> actualizar({
    required String institucionId,
    required String operadorId,
    String? nombreVisible,
    EstadoOperadorInstitucional? estado,
    Set<String>? capacidades,
  }) async {
    final operators = await listar(institucionId);
    final index = operators.indexWhere((value) => value.id == _id(operadorId));
    if (index < 0 ||
        operators[index].esPropietario &&
            estado != null &&
            estado != EstadoOperadorInstitucional.activo) {
      return false;
    }
    final current = operators[index];
    operators[index] = current.copyWith(
      nombreVisible: (nombreVisible ?? '').trim().isEmpty
          ? current.nombreVisible
          : nombreVisible!.trim(),
      estado: estado,
      capacidades: capacidades
          ?.where(CapacidadInstitucional.all.contains)
          .toSet(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveOperators(_id(institucionId), operators);
    if (!operators[index].puedeActivarse &&
        await SessionService.getInstitucionOperatorIdLogueado() ==
            operators[index].id) {
      await SessionService.clearInstitucionOperatorId();
    }
    return true;
  }

  Future<bool> setCapacidades({
    required String institucionId,
    required String operadorId,
    required Set<String> capacidades,
  }) => actualizar(
    institucionId: institucionId,
    operadorId: operadorId,
    capacidades: capacidades,
  );

  Future<bool> puedeRealizar({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required String capacidad,
  }) async {
    if (!CapacidadInstitucional.all.contains(capacidad)) return false;
    final operator = await buscar(institucionId, operadorId);
    if (operator == null || !operator.puedeActivarse) return false;
    if (!await puedeAccederArea(
      institucionId: institucionId,
      operadorId: operadorId,
      areaId: areaId,
    )) {
      return false;
    }
    return operator.esPropietario || operator.capacidades.contains(capacidad);
  }

  Future<OperadorInstitucional?> autorizarActivo({
    required String institucionId,
    required String areaId,
    required String capacidad,
  }) async {
    final session = await SessionService.getSession();
    if (session?.role != SessionRole.institucion ||
        _id(session!.userId) != _id(institucionId)) {
      return null;
    }
    final operator = await operadorActivo(institucionId);
    if (operator == null) return null;
    return await puedeRealizar(
          institucionId: institucionId,
          operadorId: operator.id,
          areaId: areaId,
          capacidad: capacidad,
        )
        ? operator
        : null;
  }

  Future<List<AsignacionOperador>> _assignments(String institution) async {
    final raw = await StorageService.instance.getJsonList(
      _assignmentsKey(institution),
    );
    return raw
        .map(AsignacionOperador.fromMap)
        .where((value) => value.institucionId == institution)
        .toList(growable: true);
  }

  Future<List<String>> areasAsignadas(
    String institution,
    String operatorId,
  ) async {
    final operator = await buscar(institution, operatorId);
    if (operator == null) {
      return const [];
    }
    if (operator.esPropietario) {
      return (await InstitucionAreasService.instance.listar(institution))
          .where((area) => area.activa)
          .map((area) => area.id)
          .toList(growable: false);
    }
    final all = await _assignments(_id(institution));
    return all
        .where((value) => value.operadorId == operator.id)
        .expand((value) => value.areaIds)
        .toSet()
        .toList();
  }

  Future<bool> asignarArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
  }) async {
    final institution = _id(institucionId);
    final operator = await buscar(institution, operadorId);
    final area = await InstitucionAreasService.instance.buscarPorId(
      institution,
      areaId,
    );
    if (operator == null ||
        !operator.puedeActivarse ||
        area == null ||
        !area.activa) {
      return false;
    }
    if (operator.esPropietario) {
      return true;
    }
    final all = await _assignments(institution);
    final index = all.indexWhere((value) => value.operadorId == operator.id);
    final ids = index < 0 ? <String>{} : all[index].areaIds.toSet();
    ids.add(area.id);
    final assignment = AsignacionOperador(
      institucionId: institution,
      operadorId: operator.id,
      areaIds: ids.toList()..sort(),
      updatedAt: DateTime.now().toUtc(),
    );
    if (index < 0) {
      all.add(assignment);
    } else {
      all[index] = assignment;
    }
    await StorageService.instance.setJsonList(
      _assignmentsKey(institution),
      all.map((value) => value.toMap()).toList(),
    );
    return true;
  }

  Future<bool> desasignarArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
  }) async {
    final institution = _id(institucionId);
    final operator = await buscar(institution, operadorId);
    if (operator == null || operator.esPropietario) {
      return false;
    }
    final all = await _assignments(institution);
    final index = all.indexWhere((value) => value.operadorId == operator.id);
    if (index < 0) {
      return true;
    }
    final ids = all[index].areaIds.toSet()..remove(_id(areaId));
    all[index] = AsignacionOperador(
      institucionId: institution,
      operadorId: operator.id,
      areaIds: ids.toList()..sort(),
      updatedAt: DateTime.now().toUtc(),
    );
    await StorageService.instance.setJsonList(
      _assignmentsKey(institution),
      all.map((value) => value.toMap()).toList(),
    );
    return true;
  }

  Future<List<OperadorInstitucional>> operadoresDelArea(
    String institution,
    String areaId,
  ) async {
    final result = <OperadorInstitucional>[];
    for (final operator in await listar(institution)) {
      if (!operator.puedeActivarse) {
        continue;
      }
      if ((await areasAsignadas(institution, operator.id)).contains(areaId)) {
        result.add(operator);
      }
    }
    return result;
  }

  Future<bool> puedeAccederArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
  }) async {
    final operator = await buscar(institucionId, operadorId);
    if (operator == null || !operator.puedeActivarse) {
      return false;
    }
    final area = await InstitucionAreasService.instance.buscarPorId(
      institucionId,
      areaId,
    );
    if (area == null || !area.activa) {
      return false;
    }
    return operator.esPropietario ||
        (await areasAsignadas(institucionId, operator.id)).contains(area.id);
  }

  Future<bool> activar({
    required String institucionId,
    required String operadorId,
  }) async {
    final session = await SessionService.getSession();
    if (session?.role != SessionRole.institucion ||
        _id(session!.userId) != _id(institucionId)) {
      return false;
    }
    final operator = await buscar(institucionId, operadorId);
    if (operator == null || !operator.puedeActivarse) {
      return false;
    }
    await SessionService.setInstitucionOperatorId(operator.id);
    return true;
  }

  Future<OperadorInstitucional?> operadorActivo(String institution) async {
    final id = await SessionService.getInstitucionOperatorIdLogueado();
    if (id == null) {
      return null;
    }
    final operator = await buscar(institution, id);
    if (operator == null || !operator.puedeActivarse) {
      await SessionService.clearInstitucionOperatorId();
      return null;
    }
    return operator;
  }
}
