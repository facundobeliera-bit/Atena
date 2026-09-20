import 'package:supabase_flutter/supabase_flutter.dart';

import 'pilot_operation_repository.dart';

class SupabasePilotOperationRepository implements PilotOperationRepository {
  final SupabaseClient client;

  const SupabasePilotOperationRepository(this.client);

  @override
  Future<String> recordNote({
    required String institutionId,
    required String areaId,
    required String operatorId,
    required String resourceId,
    required String note,
  }) async {
    if (client.auth.currentUser == null) {
      throw StateError('Se requiere autenticación remota.');
    }
    final id = await client.rpc(
      'atena_pilot_record_note',
      params: {
        'p_institution_id': institutionId,
        'p_area_id': areaId,
        'p_operator_id': operatorId,
        'p_resource_id': resourceId,
        'p_note': note,
      },
    );
    if (id is! String || id.isEmpty) {
      throw StateError('La operación remota no devolvió un identificador.');
    }
    return id;
  }

  @override
  Future<List<PilotOperation>> listNotes({
    required String institutionId,
    required String areaId,
  }) async {
    if (client.auth.currentUser == null) {
      throw StateError('Se requiere autenticación remota.');
    }
    final rows = await client
        .from('atena_pilot_operations')
        .select('id,institution_id,area_id,operator_id,resource_id,note')
        .eq('institution_id', institutionId)
        .eq('area_id', areaId);
    return rows
        .map(
          (row) => PilotOperation(
            id: row['id'].toString(),
            institutionId: row['institution_id'].toString(),
            areaId: row['area_id'].toString(),
            operatorId: row['operator_id'].toString(),
            resourceId: row['resource_id'].toString(),
            note: row['note'].toString(),
          ),
        )
        .toList(growable: false);
  }
}
