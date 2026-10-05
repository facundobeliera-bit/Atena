enum EstadoOperadorInstitucional { activo, suspendido, revocado }

abstract final class CapacidadInstitucional {
  static const areaManage = 'area.manage';
  static const groupsRead = 'groups.read';
  static const groupsWrite = 'groups.write';
  static const requestsRead = 'requests.read';
  static const requestsDecide = 'requests.decide';
  static const calendarRead = 'calendar.read';
  static const calendarWrite = 'calendar.write';
  static const responsesRead = 'responses.read';
  static const communicationsWrite = 'communications.write';
  static const auditRead = 'audit.read';
  static const educationRead = 'education.read';
  static const educationWrite = 'education.write';
  static const documentsRead = 'documents.read';
  static const documentsWrite = 'documents.write';

  static const all = <String>{
    areaManage,
    groupsRead,
    groupsWrite,
    requestsRead,
    requestsDecide,
    calendarRead,
    calendarWrite,
    responsesRead,
    communicationsWrite,
    auditRead,
    educationRead,
    educationWrite,
    documentsRead,
    documentsWrite,
  };
}

class OperadorInstitucional {
  static const int currentSchemaVersion = 1;

  final String id;
  final String institucionId;
  final String? cuentaId;
  final String? perfilInstitucionId;
  final String nombreVisible;
  final bool esPropietario;

  /// Función organizativa; no concede permisos ni cambia la propiedad.
  final bool esDirector;
  final EstadoOperadorInstitucional estado;
  final Set<String> capacidades;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  const OperadorInstitucional({
    required this.id,
    required this.institucionId,
    required this.cuentaId,
    required this.perfilInstitucionId,
    required this.nombreVisible,
    required this.esPropietario,
    this.esDirector = false,
    required this.estado,
    this.capacidades = const {},
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get puedeActivarse => estado == EstadoOperadorInstitucional.activo;

  OperadorInstitucional copyWith({
    String? nombreVisible,
    bool? esDirector,
    EstadoOperadorInstitucional? estado,
    Set<String>? capacidades,
    DateTime? updatedAt,
  }) => OperadorInstitucional(
    id: id,
    institucionId: institucionId,
    cuentaId: cuentaId,
    perfilInstitucionId: perfilInstitucionId,
    nombreVisible: nombreVisible ?? this.nombreVisible,
    esPropietario: esPropietario,
    esDirector: esDirector ?? this.esDirector,
    estado: estado ?? this.estado,
    capacidades: capacidades ?? this.capacidades,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    'cuentaId': cuentaId,
    'perfilInstitucionId': perfilInstitucionId,
    'nombreVisible': nombreVisible,
    'esPropietario': esPropietario,
    'esDirector': esDirector,
    'estado': estado.name,
    'capacidades': capacidades.toList()..sort(),
    'createdAtIso': createdAt.toIso8601String(),
    'updatedAtIso': updatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory OperadorInstitucional.fromMap(Map<String, dynamic> map) {
    final state = (map['estado'] ?? '').toString();
    return OperadorInstitucional(
      id: (map['id'] ?? '').toString().trim(),
      institucionId: (map['institucionId'] ?? '').toString().trim(),
      cuentaId: (map['cuentaId'] ?? '').toString().trim().isEmpty
          ? null
          : (map['cuentaId'] ?? '').toString().trim(),
      perfilInstitucionId:
          (map['perfilInstitucionId'] ?? '').toString().trim().isEmpty
          ? null
          : (map['perfilInstitucionId'] ?? '').toString().trim(),
      nombreVisible: (map['nombreVisible'] ?? '').toString().trim(),
      esPropietario: map['esPropietario'] == true,
      esDirector: map['esDirector'] == true,
      estado: EstadoOperadorInstitucional.values.firstWhere(
        (value) => value.name == state,
        orElse: () => EstadoOperadorInstitucional.revocado,
      ),
      capacidades: map['capacidades'] is List
          ? (map['capacidades'] as List)
                .map((value) => value.toString().trim())
                .where(CapacidadInstitucional.all.contains)
                .toSet()
          : const {},
      createdAt:
          DateTime.tryParse((map['createdAtIso'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updatedAtIso'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion: map['schemaVersion'] is num
          ? (map['schemaVersion'] as num).toInt()
          : currentSchemaVersion,
    );
  }
}

class AsignacionOperador {
  final String institucionId;
  final String operadorId;
  final List<String> areaIds;
  final DateTime updatedAt;
  final int schemaVersion;

  const AsignacionOperador({
    required this.institucionId,
    required this.operadorId,
    required this.areaIds,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'operadorId': operadorId,
    'areaIds': areaIds,
    'updatedAtIso': updatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory AsignacionOperador.fromMap(Map<String, dynamic> map) =>
      AsignacionOperador(
        institucionId: (map['institucionId'] ?? '').toString().trim(),
        operadorId: (map['operadorId'] ?? '').toString().trim(),
        areaIds: (map['areaIds'] is List)
            ? (map['areaIds'] as List)
                  .map((value) => value.toString().trim())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList()
            : const [],
        updatedAt:
            DateTime.tryParse((map['updatedAtIso'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        schemaVersion: map['schemaVersion'] is num
            ? (map['schemaVersion'] as num).toInt()
            : 1,
      );
}
