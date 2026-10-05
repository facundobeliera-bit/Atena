import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote requests never reuse local session IDs as evidence of authorization.
/// The server resolves applicant/actor, availability and commercial entitlement.
/// Callers retain the operation UUID across retries; a failed call is NOT a
/// local success and must never fall back to SolicitudesService.
class SolicitudesSupabaseRepository {
  final SupabaseClient client;
  const SolicitudesSupabaseRepository(this.client);

  Future<Map<String, dynamic>> crear({
    required String perfilVerificado,
    required String grupoPublico,
    required String operationId,
  }) async {
    final row = await client.rpc(
      'atena_request_create',
      params: {
        'p_profile_id': perfilVerificado,
        'p_group_id': grupoPublico,
        'p_operation_id': operationId,
      },
    );
    final result = _registro(row);
    if (result['applicant_profile_id'] != perfilVerificado ||
        result['group_id'] != grupoPublico ||
        result['operation_id'] != operationId) {
      throw const FormatException('Respuesta de solicitud contradictoria.');
    }
    return result;
  }

  Future<Map<String, dynamic>> decidir(
    String solicitudId,
    String estado,
  ) async {
    final result = _registro(
      await client.rpc(
        'atena_request_decide',
        params: {'p_request_id': solicitudId, 'p_state': estado},
      ),
    );
    if (result['id'] != solicitudId || result['state'] != estado) {
      throw const FormatException('Confirmación remota contradictoria.');
    }
    return result;
  }

  /// RLS defines the user's visible requests. No local actor or owner filter
  /// can grant access. Pagination is explicit, never a hidden partial history.
  Future<List<Map<String, dynamic>>> listar({
    int offset = 0,
    int limit = 100,
  }) async {
    if (offset < 0 || limit < 1 || limit > 200) {
      throw ArgumentError('Página inválida.');
    }
    final rows = await client
        .from('atena_requests')
        .select()
        .order('created_at')
        .order('id')
        .range(offset, offset + limit - 1);
    return List.unmodifiable(rows.map(_registro));
  }

  static Map<String, dynamic> _registro(dynamic row) {
    if (row is! Map ||
        row['id'] is! String ||
        !const [
          'pending',
          'confirmed',
          'rejected',
          'cancelled_by_student',
          'cancelled_by_institution',
        ].contains(row['state'])) {
      throw const FormatException('Solicitud remota inválida.');
    }
    return Map.unmodifiable(Map<String, dynamic>.from(row));
  }
}
