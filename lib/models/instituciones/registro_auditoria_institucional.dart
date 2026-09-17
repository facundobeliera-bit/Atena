class AccionAuditoriaInstitucional {
  static const requestConfirmed = 'request.confirmed';
  static const requestRejected = 'request.rejected';
  static const groupCapacityChanged = 'group.capacity_changed';
  static const groupUpdated = 'group.updated';
  static const eventCreated = 'event.created';
  static const eventUpdated = 'event.updated';
  static const communicationSent = 'communication.sent';

  static const all = <String>{
    requestConfirmed,
    requestRejected,
    groupCapacityChanged,
    groupUpdated,
    eventCreated,
    eventUpdated,
    communicationSent,
  };
}

class RegistroAuditoriaInstitucional {
  static const currentSchemaVersion = 1;

  final String id;
  final String institucionId;
  final String? areaId;
  final String operatorId;
  final String action;
  final String resourceType;
  final String resourceId;
  final DateTime occurredAt;
  final int? previousVersion;
  final int? resultingVersion;
  final Map<String, Object?> metadata;
  final int schemaVersion;

  const RegistroAuditoriaInstitucional({
    required this.id,
    required this.institucionId,
    required this.areaId,
    required this.operatorId,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.occurredAt,
    required this.previousVersion,
    required this.resultingVersion,
    required this.metadata,
    this.schemaVersion = currentSchemaVersion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'institucionId': institucionId,
    if ((areaId ?? '').trim().isNotEmpty) 'areaId': areaId,
    'operatorId': operatorId,
    'action': action,
    'resourceType': resourceType,
    'resourceId': resourceId,
    'occurredAtIso': occurredAt.toUtc().toIso8601String(),
    if (previousVersion != null) 'previousVersion': previousVersion,
    if (resultingVersion != null) 'resultingVersion': resultingVersion,
    if (metadata.isNotEmpty) 'metadata': metadata,
    'schemaVersion': schemaVersion,
  };

  factory RegistroAuditoriaInstitucional.fromMap(Map<String, dynamic> map) {
    final rawMetadata = map['metadata'];
    return RegistroAuditoriaInstitucional(
      id: (map['id'] ?? '').toString().trim(),
      institucionId: (map['institucionId'] ?? '').toString().trim(),
      areaId: (map['areaId'] ?? '').toString().trim().isEmpty
          ? null
          : (map['areaId'] ?? '').toString().trim(),
      operatorId: (map['operatorId'] ?? '').toString().trim(),
      action: (map['action'] ?? '').toString().trim(),
      resourceType: (map['resourceType'] ?? '').toString().trim(),
      resourceId: (map['resourceId'] ?? '').toString().trim(),
      occurredAt:
          DateTime.tryParse((map['occurredAtIso'] ?? '').toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      previousVersion: map['previousVersion'] is num
          ? (map['previousVersion'] as num).toInt()
          : null,
      resultingVersion: map['resultingVersion'] is num
          ? (map['resultingVersion'] as num).toInt()
          : null,
      metadata: rawMetadata is Map
          ? Map<String, Object?>.from(rawMetadata)
          : const {},
      schemaVersion: map['schemaVersion'] is num
          ? (map['schemaVersion'] as num).toInt()
          : currentSchemaVersion,
    );
  }
}
