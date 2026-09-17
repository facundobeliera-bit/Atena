import '../models/instituciones/asignacion_operador_area.dart';
import '../models/instituciones/operador_institucional.dart';
import 'institucion_areas_service.dart';
import 'session_service.dart';
import 'storage_service.dart';

class InstitucionOperadoresService {
  InstitucionOperadoresService._();
  static final instance = InstitucionOperadoresService._();
  static const _operatorsPrefix = 'inst_operators_v1_';
  static const _legacyPrefix = 'inst_operator_areas_v1_';
  static const _v2Prefix = 'inst_operator_area_assignments_v2_';
  static const _migratedPrefix = 'inst_operator_area_assignments_v2_migrated_';
  final Map<String, Future<void>> _migrations = {};

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

  String _key(String prefix, String institution) =>
      '$prefix${InstitucionAreasService.normalizeKey(institution)}';

  Future<List<OperadorInstitucional>> listar(String institucionId) async {
    final institution = _id(institucionId);
    if (institution.isEmpty) return const [];
    final raw = await StorageService.instance.getJsonList(
      _key(_operatorsPrefix, institution),
    );
    return raw
        .map(OperadorInstitucional.fromMap)
        .where(
          (value) => value.id.isNotEmpty && value.institucionId == institution,
        )
        .toList();
  }

  Future<void> _saveOperators(
    String institution,
    List<OperadorInstitucional> values,
  ) => StorageService.instance.setJsonList(
    _key(_operatorsPrefix, institution),
    values.map((value) => value.toMap()).toList(),
  );

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
    final operatorId =
        'operator_owner_${_hash('$institution::$owner::$profile').toRadixString(16)}';
    final operators = await listar(institution);
    final existing = operators
        .where((value) => value.id == operatorId)
        .firstOrNull;
    if (existing != null) return existing;
    final now = DateTime.now().toUtc();
    final result = OperadorInstitucional(
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
    operators.add(result);
    await _saveOperators(institution, operators);
    return result;
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
    final prefix =
        'operator_local_${_hash(institution).toRadixString(16)}_${now.microsecondsSinceEpoch.toRadixString(16)}';
    var id = prefix;
    var suffix = 1;
    while (operators.any((value) => value.id == id)) {
      id = '${prefix}_${suffix++}';
    }
    final result = OperadorInstitucional(
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
    operators.add(result);
    await _saveOperators(institution, operators);
    return result;
  }

  Future<OperadorInstitucional?> buscar(
    String institution,
    String operatorId,
  ) async => (await listar(
    institution,
  )).where((value) => value.id == _id(operatorId)).firstOrNull;

  Future<bool> actualizar({
    required String institucionId,
    required String operadorId,
    String? nombreVisible,
    EstadoOperadorInstitucional? estado,
    Set<String>? capacidades,
  }) async {
    final institution = _id(institucionId);
    final operators = await listar(institution);
    final index = operators.indexWhere((value) => value.id == _id(operadorId));
    if (index < 0 ||
        (operators[index].esPropietario &&
            estado != null &&
            estado != EstadoOperadorInstitucional.activo)) {
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
    await _saveOperators(institution, operators);
    if (estado != null && estado != EstadoOperadorInstitucional.activo) {
      await _clearResponsibilityForOperator(institution, current.id);
    }
    if (!operators[index].puedeActivarse &&
        await SessionService.getInstitucionOperatorIdLogueado() == current.id) {
      await SessionService.clearInstitucionOperatorId();
    }
    return true;
  }

  /// API V1 conservada para compatibilidad. Si V2 ya existe, la operación es
  /// un cambio masivo explícito; nunca se usa como fallback al autorizar.
  Future<bool> setCapacidades({
    required String institucionId,
    required String operadorId,
    required Set<String> capacidades,
  }) async {
    final institution = _id(institucionId);
    final ok = await actualizar(
      institucionId: institution,
      operadorId: operadorId,
      capacidades: capacidades,
    );
    if (!ok ||
        await StorageService.instance.getString(
              _key(_migratedPrefix, institution),
            ) !=
            'done') {
      return ok;
    }
    final all = await _readV2(institution, migrate: false);
    final filtered = capacidades
        .where(CapacidadInstitucional.all.contains)
        .toSet();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].operadorId == _id(operadorId)) {
        all[i] = all[i].copyWith(
          capacidades: filtered,
          updatedAt: DateTime.now().toUtc(),
        );
        changed = true;
      }
    }
    if (changed) await _saveV2(institution, all);
    return true;
  }

  Future<void> _ensureMigrated(String institution) =>
      _migrations.putIfAbsent(institution, () async {
        try {
          if (await StorageService.instance.getString(
                _key(_migratedPrefix, institution),
              ) ==
              'done') {
            return;
          }
          final values = await _readV2(institution, migrate: false);
          final unique = {
            for (final value in values) value.identidadLogica: value,
          };
          final operators = {
            for (final value in await listar(institution)) value.id: value,
          };
          final raw = await StorageService.instance.getJsonList(
            _key(_legacyPrefix, institution),
          );
          final legacy = raw
              .map(AsignacionOperador.fromMap)
              .where((value) => value.institucionId == institution);
          for (final old in legacy) {
            final operator = operators[old.operadorId];
            if (operator == null || operator.esPropietario) continue;
            for (final areaId in old.areaIds.toSet()) {
              final area = _id(areaId);
              final identity = '$institution::$area::${operator.id}';
              unique.putIfAbsent(
                identity,
                () => AsignacionOperadorArea(
                  institucionId: institution,
                  areaId: area,
                  operadorId: operator.id,
                  estado: EstadoAsignacionOperadorArea.activa,
                  capacidades: operator.capacidades.toSet(),
                  esResponsable: false,
                  createdAt: old.updatedAt.toUtc(),
                  updatedAt: old.updatedAt.toUtc(),
                ),
              );
            }
          }
          await _saveV2(institution, unique.values.toList());
          await StorageService.instance.setString(
            _key(_migratedPrefix, institution),
            'done',
          );
        } finally {
          _migrations.remove(institution);
        }
      });

  Future<List<AsignacionOperadorArea>> _readV2(
    String institution, {
    bool migrate = true,
  }) async {
    if (migrate) await _ensureMigrated(institution);
    final raw = await StorageService.instance.getJsonList(
      _key(_v2Prefix, institution),
    );
    final unique = <String, AsignacionOperadorArea>{};
    for (final map in raw) {
      final value = AsignacionOperadorArea.fromMap(map);
      if (value.institucionId == institution &&
          value.areaId.isNotEmpty &&
          value.operadorId.isNotEmpty) {
        unique[value.identidadLogica] = value;
      }
    }
    return unique.values.toList();
  }

  Future<void> _saveV2(
    String institution,
    List<AsignacionOperadorArea> values,
  ) async {
    final unique = <String, AsignacionOperadorArea>{};
    for (final value in values.where(
      (value) => value.institucionId == institution,
    )) {
      unique[value.identidadLogica] = value;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => a.identidadLogica.compareTo(b.identidadLogica));
    await StorageService.instance.setJsonList(
      _key(_v2Prefix, institution),
      sorted.map((value) => value.toMap()).toList(),
    );
  }

  Future<List<AsignacionOperadorArea>> listarAsignacionesArea(
    String institucionId,
    String areaId,
  ) async => (await _readV2(
    _id(institucionId),
  )).where((value) => value.areaId == _id(areaId)).toList();

  Future<List<AsignacionOperadorArea>> listarAsignacionesOperador(
    String institucionId,
    String operadorId,
  ) async => (await _readV2(
    _id(institucionId),
  )).where((value) => value.operadorId == _id(operadorId)).toList();

  Future<AsignacionOperadorArea?> obtenerAsignacion({
    required String institucionId,
    required String areaId,
    required String operadorId,
  }) async {
    final institution = _id(institucionId);
    final identity = '$institution::${_id(areaId)}::${_id(operadorId)}';
    return (await _readV2(
      institution,
    )).where((value) => value.identidadLogica == identity).firstOrNull;
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
        area == null ||
        !area.activa ||
        !operator.puedeActivarse) {
      return false;
    }
    if (operator.esPropietario) return true;
    final all = await _readV2(institution);
    final index = all.indexWhere(
      (value) => value.areaId == area.id && value.operadorId == operator.id,
    );
    final now = DateTime.now().toUtc();
    if (index < 0) {
      all.add(
        AsignacionOperadorArea(
          institucionId: institution,
          areaId: area.id,
          operadorId: operator.id,
          estado: EstadoAsignacionOperadorArea.activa,
          capacidades: operator.capacidades.toSet(),
          esResponsable: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      all[index] = all[index].copyWith(
        estado: EstadoAsignacionOperadorArea.activa,
        updatedAt: now,
      );
    }
    await _saveV2(institution, all);
    return true;
  }

  Future<bool> desasignarArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
  }) => setEstadoAsignacion(
    institucionId: institucionId,
    operadorId: operadorId,
    areaId: areaId,
    estado: EstadoAsignacionOperadorArea.revocada,
  );

  Future<bool> setEstadoAsignacion({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required EstadoAsignacionOperadorArea estado,
  }) async {
    final institution = _id(institucionId);
    final all = await _readV2(institution);
    final index = all.indexWhere(
      (value) =>
          value.areaId == _id(areaId) && value.operadorId == _id(operadorId),
    );
    if (index < 0) return false;
    if (estado == EstadoAsignacionOperadorArea.activa) {
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
    }
    all[index] = all[index].copyWith(
      estado: estado,
      esResponsable: estado == EstadoAsignacionOperadorArea.activa
          ? all[index].esResponsable
          : false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveV2(institution, all);
    return true;
  }

  Future<bool> setCapacidadesEnArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required Set<String> capacidades,
  }) async {
    final institution = _id(institucionId);
    final all = await _readV2(institution);
    final index = all.indexWhere(
      (value) =>
          value.areaId == _id(areaId) && value.operadorId == _id(operadorId),
    );
    if (index < 0) return false;
    all[index] = all[index].copyWith(
      capacidades: capacidades
          .where(CapacidadInstitucional.all.contains)
          .toSet(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveV2(institution, all);
    return true;
  }

  Future<bool> concederCapacidadEnArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required String capacidad,
  }) async {
    if (!CapacidadInstitucional.all.contains(capacidad)) return false;
    final current = await obtenerAsignacion(
      institucionId: institucionId,
      areaId: areaId,
      operadorId: operadorId,
    );
    if (current == null) return false;
    return setCapacidadesEnArea(
      institucionId: institucionId,
      operadorId: operadorId,
      areaId: areaId,
      capacidades: {...current.capacidades, capacidad},
    );
  }

  Future<bool> retirarCapacidadEnArea({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required String capacidad,
  }) async {
    final current = await obtenerAsignacion(
      institucionId: institucionId,
      areaId: areaId,
      operadorId: operadorId,
    );
    if (current == null) return false;
    return setCapacidadesEnArea(
      institucionId: institucionId,
      operadorId: operadorId,
      areaId: areaId,
      capacidades: current.capacidades.toSet()..remove(capacidad),
    );
  }

  Future<bool> puedeRealizar({
    required String institucionId,
    required String operadorId,
    required String areaId,
    required String capacidad,
  }) async {
    if (!CapacidadInstitucional.all.contains(capacidad)) return false;
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
    if (operator.esPropietario) return true;
    final assignment = await obtenerAsignacion(
      institucionId: institution,
      areaId: area.id,
      operadorId: operator.id,
    );
    return assignment?.estaActiva == true &&
        assignment!.capacidades.contains(capacidad);
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
    return operator != null &&
            await puedeRealizar(
              institucionId: institucionId,
              operadorId: operator.id,
              areaId: areaId,
              capacidad: capacidad,
            )
        ? operator
        : null;
  }

  Future<List<String>> areasAsignadas(
    String institution,
    String operatorId,
  ) async {
    final operator = await buscar(institution, operatorId);
    if (operator == null) return const [];
    if (operator.esPropietario) {
      return (await InstitucionAreasService.instance.listar(
        institution,
      )).where((area) => area.activa).map((area) => area.id).toList();
    }
    return (await listarAsignacionesOperador(institution, operator.id))
        .where((value) => value.estaActiva)
        .map((value) => value.areaId)
        .toSet()
        .toList();
  }

  Future<List<OperadorInstitucional>> operadoresDelArea(
    String institution,
    String areaId,
  ) async {
    final result = <OperadorInstitucional>[];
    for (final operator in await listar(institution)) {
      if (operator.puedeActivarse &&
          (await areasAsignadas(
            institution,
            operator.id,
          )).contains(_id(areaId))) {
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
    final area = await InstitucionAreasService.instance.buscarPorId(
      institucionId,
      areaId,
    );
    if (operator == null ||
        !operator.puedeActivarse ||
        area == null ||
        !area.activa) {
      return false;
    }
    if (operator.esPropietario) return true;
    return (await obtenerAsignacion(
          institucionId: institucionId,
          areaId: area.id,
          operadorId: operator.id,
        ))?.estaActiva ==
        true;
  }

  Future<bool> establecerResponsable({
    required String institucionId,
    required String areaId,
    required String operadorId,
  }) async {
    final institution = _id(institucionId);
    final operator = await buscar(institution, operadorId);
    if (operator == null ||
        operator.esPropietario ||
        !operator.puedeActivarse) {
      return false;
    }
    final all = await _readV2(institution);
    final target = all.indexWhere(
      (value) => value.areaId == _id(areaId) && value.operadorId == operator.id,
    );
    if (target < 0 || !all[target].estaActiva) return false;
    final now = DateTime.now().toUtc();
    for (var i = 0; i < all.length; i++) {
      if (all[i].areaId == _id(areaId) && all[i].esResponsable) {
        all[i] = all[i].copyWith(esResponsable: false, updatedAt: now);
      }
    }
    all[target] = all[target].copyWith(esResponsable: true, updatedAt: now);
    await _saveV2(institution, all);
    return true;
  }

  Future<bool> quitarResponsable({
    required String institucionId,
    required String areaId,
  }) async {
    final institution = _id(institucionId);
    final all = await _readV2(institution);
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].areaId == _id(areaId) && all[i].esResponsable) {
        all[i] = all[i].copyWith(
          esResponsable: false,
          updatedAt: DateTime.now().toUtc(),
        );
        changed = true;
      }
    }
    if (changed) await _saveV2(institution, all);
    return true;
  }

  Future<AsignacionOperadorArea?> responsableArea(
    String institution,
    String areaId,
  ) async => (await listarAsignacionesArea(
    institution,
    areaId,
  )).where((value) => value.estaActiva && value.esResponsable).firstOrNull;

  Future<void> _clearResponsibilityForOperator(
    String institution,
    String operatorId,
  ) async {
    final all = await _readV2(institution);
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].operadorId == operatorId && all[i].esResponsable) {
        all[i] = all[i].copyWith(
          esResponsable: false,
          updatedAt: DateTime.now().toUtc(),
        );
        changed = true;
      }
    }
    if (changed) await _saveV2(institution, all);
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
    if (operator == null || !operator.puedeActivarse) return false;
    await SessionService.setInstitucionOperatorId(operator.id);
    return true;
  }

  Future<OperadorInstitucional?> operadorActivo(String institution) async {
    final id = await SessionService.getInstitucionOperatorIdLogueado();
    if (id == null) return null;
    final operator = await buscar(institution, id);
    if (operator == null || !operator.puedeActivarse) {
      await SessionService.clearInstitucionOperatorId();
      return null;
    }
    return operator;
  }
}
