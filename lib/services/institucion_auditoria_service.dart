import '../models/instituciones/operador_institucional.dart';
import '../models/instituciones/registro_auditoria_institucional.dart';
import 'institucion_operadores_service.dart';
import 'storage_service.dart';

class InstitucionAuditoriaService {
  InstitucionAuditoriaService._();
  static final instance = InstitucionAuditoriaService._();

  static const maxRecordsPerInstitution = 1000;
  static const _prefix = 'inst_audit_v1_';
  static int _sequence = 0;
  static const _forbiddenMetadataFragments = <String>{
    'password',
    'contrasena',
    'contraseña',
    'hash',
    'dni',
    'documento',
    'image',
    'imagen',
    'contenido',
    'message',
    'mensaje',
    'descripcion',
  };

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');
  String _key(String institution) => '$_prefix${_id(institution)}';

  Map<String, Object?> _sanitizeMetadata(Map<String, Object?> source) {
    final result = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key.trim();
      final lower = key.toLowerCase();
      if (key.isEmpty || _forbiddenMetadataFragments.any(lower.contains)) {
        continue;
      }
      final value = entry.value;
      if (value == null || value is num || value is bool) {
        result[key] = value;
      } else if (value is String && value.length <= 160) {
        result[key] = value;
      }
    }
    return result;
  }

  Future<List<RegistroAuditoriaInstitucional>> listarInterno(
    String institucionId,
  ) async {
    final institution = _id(institucionId);
    if (institution.isEmpty) return const [];
    final raw = await StorageService.instance.getJsonList(_key(institution));
    final records = raw
        .map(RegistroAuditoriaInstitucional.fromMap)
        .where(
          (record) =>
              record.id.isNotEmpty && record.institucionId == institution,
        )
        .toList();
    records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return records;
  }

  Future<RegistroAuditoriaInstitucional> append({
    required String institucionId,
    required String? areaId,
    required String operatorId,
    required String action,
    required String resourceType,
    required String resourceId,
    int? previousVersion,
    int? resultingVersion,
    Map<String, Object?> metadata = const {},
    DateTime? occurredAt,
  }) async {
    final institution = _id(institucionId);
    final operator = _id(operatorId);
    final resource = _id(resourceId);
    if (institution.isEmpty ||
        operator.isEmpty ||
        resource.isEmpty ||
        !AccionAuditoriaInstitucional.all.contains(action)) {
      throw ArgumentError('Registro de auditoría incompleto.');
    }
    final persistedOperator = await InstitucionOperadoresService.instance
        .buscar(institution, operator);
    if (persistedOperator == null) {
      throw StateError('El operador no pertenece a la institución.');
    }
    final timestamp = (occurredAt ?? DateTime.now()).toUtc();
    _sequence++;
    final record = RegistroAuditoriaInstitucional(
      id: 'audit_${timestamp.microsecondsSinceEpoch}_${_sequence.toRadixString(16)}',
      institucionId: institution,
      areaId: (areaId ?? '').trim().isEmpty ? null : areaId!.trim(),
      operatorId: operator,
      action: action,
      resourceType: resourceType.trim(),
      resourceId: resource,
      occurredAt: timestamp,
      previousVersion: previousVersion,
      resultingVersion: resultingVersion,
      metadata: _sanitizeMetadata(metadata),
    );
    final records = await listarInterno(institution);
    records.insert(0, record);
    if (records.length > maxRecordsPerInstitution) {
      records.removeRange(maxRecordsPerInstitution, records.length);
    }
    await StorageService.instance.setJsonList(
      _key(institution),
      records.map((value) => value.toMap()).toList(),
    );
    return record;
  }

  Future<List<RegistroAuditoriaInstitucional>> listarAutorizado({
    required String institucionId,
    String? areaId,
    String? operatorId,
  }) async {
    final active = await InstitucionOperadoresService.instance.operadorActivo(
      institucionId,
    );
    if (active == null) return const [];
    final records = await listarInterno(institucionId);
    Iterable<RegistroAuditoriaInstitucional> visible = records;
    if (!active.esPropietario) {
      final permittedAreas = <String>{};
      for (final assignment
          in await InstitucionOperadoresService.instance
              .listarAsignacionesOperador(institucionId, active.id)) {
        if (await InstitucionOperadoresService.instance.puedeRealizar(
          institucionId: institucionId,
          operadorId: active.id,
          areaId: assignment.areaId,
          capacidad: CapacidadInstitucional.auditRead,
        )) {
          permittedAreas.add(assignment.areaId);
        }
      }
      visible = visible.where(
        (record) =>
            record.areaId != null && permittedAreas.contains(record.areaId),
      );
    }
    final area = (areaId ?? '').trim();
    final operator = (operatorId ?? '').trim();
    if (area.isNotEmpty) {
      visible = visible.where((record) => record.areaId == area);
    }
    if (operator.isNotEmpty) {
      visible = visible.where((record) => record.operatorId == operator);
    }
    return visible.toList();
  }
}
