enum TipoAreaOperativa { curricular, extracurricular }

class AreaOperativa {
  static const int currentSchemaVersion = 1;

  final String id;
  final String institucionId;
  final TipoAreaOperativa tipo;
  final String claveOrigen;
  final String nombre;
  final bool activa;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  const AreaOperativa({
    required this.id,
    required this.institucionId,
    required this.tipo,
    required this.claveOrigen,
    required this.nombre,
    required this.activa,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  AreaOperativa copyWith({String? nombre, bool? activa, DateTime? updatedAt}) {
    return AreaOperativa(
      id: id,
      institucionId: institucionId,
      tipo: tipo,
      claveOrigen: claveOrigen,
      nombre: nombre ?? this.nombre,
      activa: activa ?? this.activa,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    'tipo': tipo.name,
    'claveOrigen': claveOrigen,
    'nombre': nombre,
    'activa': activa,
    'createdAtIso': createdAt.toIso8601String(),
    'updatedAtIso': updatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory AreaOperativa.fromMap(Map<String, dynamic> map) {
    final type = (map['tipo'] ?? '').toString();
    return AreaOperativa(
      id: (map['id'] ?? '').toString().trim(),
      institucionId: (map['institucionId'] ?? '').toString().trim(),
      tipo: TipoAreaOperativa.values.firstWhere(
        (value) => value.name == type,
        orElse: () => TipoAreaOperativa.curricular,
      ),
      claveOrigen: (map['claveOrigen'] ?? '').toString().trim(),
      nombre: (map['nombre'] ?? '').toString().trim(),
      activa: map['activa'] is bool ? map['activa'] as bool : true,
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

class AmbitoOperativo {
  final String institucionId;
  final String areaId;
  final String? grupoId;

  const AmbitoOperativo({
    required this.institucionId,
    required this.areaId,
    this.grupoId,
  });

  bool get isComplete =>
      institucionId.trim().isNotEmpty && areaId.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId.trim(),
    'areaId': areaId.trim(),
    if ((grupoId ?? '').trim().isNotEmpty) 'grupoId': grupoId!.trim(),
  };

  factory AmbitoOperativo.fromMap(Map<String, dynamic> map) => AmbitoOperativo(
    institucionId: (map['institucionId'] ?? '').toString().trim(),
    areaId: (map['areaId'] ?? '').toString().trim(),
    grupoId: (map['grupoId'] ?? '').toString().trim().isEmpty
        ? null
        : (map['grupoId'] ?? '').toString().trim(),
  );
}
