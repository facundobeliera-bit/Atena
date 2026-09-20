/// Contract for the isolated remote pilot. This does not replace local
/// requests, groups, sessions or institutional audit records.
class PilotOperation {
  final String id;
  final String institutionId;
  final String areaId;
  final String operatorId;
  final String resourceId;
  final String note;

  const PilotOperation({
    required this.id,
    required this.institutionId,
    required this.areaId,
    required this.operatorId,
    required this.resourceId,
    required this.note,
  });
}

abstract interface class PilotOperationRepository {
  Future<String> recordNote({
    required String institutionId,
    required String areaId,
    required String operatorId,
    required String resourceId,
    required String note,
  });

  Future<List<PilotOperation>> listNotes({
    required String institutionId,
    required String areaId,
  });
}
