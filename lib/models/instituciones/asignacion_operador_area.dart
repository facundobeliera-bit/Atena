import 'operador_institucional.dart';

enum EstadoAsignacionOperadorArea { activa, suspendida, revocada }

class AsignacionOperadorArea {
  static const int currentSchemaVersion = 2;

  final String institucionId;
  final String areaId;
  final String operadorId;
  final EstadoAsignacionOperadorArea estado;
  final Set<String> capacidades;
  final bool esResponsable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  const AsignacionOperadorArea({
    required this.institucionId,
    required this.areaId,
    required this.operadorId,
    required this.estado,
    required this.capacidades,
    required this.esResponsable,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get estaActiva => estado == EstadoAsignacionOperadorArea.activa;

  String get identidadLogica => '$institucionId::$areaId::$operadorId';

  AsignacionOperadorArea copyWith({
    EstadoAsignacionOperadorArea? estado,
    Set<String>? capacidades,
    bool? esResponsable,
    DateTime? updatedAt,
  }) => AsignacionOperadorArea(
    institucionId: institucionId,
    areaId: areaId,
    operadorId: operadorId,
    estado: estado ?? this.estado,
    capacidades: capacidades ?? this.capacidades,
    esResponsable: esResponsable ?? this.esResponsable,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion,
  );

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'areaId': areaId,
    'operadorId': operadorId,
    'estado': estado.name,
    'capacidades': capacidades.toList()..sort(),
    'esResponsable': esResponsable,
    'createdAtIso': createdAt.toUtc().toIso8601String(),
    'updatedAtIso': updatedAt.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory AsignacionOperadorArea.fromMap(Map<String, dynamic> map) {
    final state = (map['estado'] ?? '').toString().trim();
    return AsignacionOperadorArea(
      institucionId: (map['institucionId'] ?? '').toString().trim(),
      areaId: (map['areaId'] ?? '').toString().trim(),
      operadorId: (map['operadorId'] ?? '').toString().trim(),
      estado: EstadoAsignacionOperadorArea.values.firstWhere(
        (value) => value.name == state,
        orElse: () => EstadoAsignacionOperadorArea.revocada,
      ),
      capacidades: map['capacidades'] is List
          ? (map['capacidades'] as List)
                .map((value) => value.toString().trim())
                .where(CapacidadInstitucional.all.contains)
                .toSet()
          : const {},
      esResponsable: map['esResponsable'] == true,
      createdAt:
          DateTime.tryParse((map['createdAtIso'] ?? '').toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse((map['updatedAtIso'] ?? '').toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: map['schemaVersion'] is num
          ? (map['schemaVersion'] as num).toInt()
          : currentSchemaVersion,
    );
  }
}
