import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/pilot_operation_repository.dart';
import '../../repositories/pilot_operation_repository_supabase.dart';

class PilotInstitution {
  final String id;
  final String name;
  const PilotInstitution(this.id, this.name);
}

class PilotArea {
  final String id;
  final String name;
  const PilotArea(this.id, this.name);
}

class PilotAssignment {
  final String institutionId;
  final String areaId;
  final String operatorId;
  final List<String> capabilities;

  const PilotAssignment({
    required this.institutionId,
    required this.areaId,
    required this.operatorId,
    required this.capabilities,
  });

  bool get canWrite => capabilities.contains('pilot.write');
}

abstract interface class PilotRemoteGateway {
  bool get isSignedIn;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<List<PilotInstitution>> institutions();
  Future<List<PilotArea>> areas(String institutionId);
  Future<List<PilotAssignment>> assignments();
  Future<String> recordNote({
    required String institutionId,
    required String areaId,
    required String operatorId,
    required String resourceId,
    required String note,
  });
  Future<List<PilotOperation>> notes(String institutionId, String areaId);
}

class SupabasePilotRemoteGateway implements PilotRemoteGateway {
  final SupabaseClient client;
  late final PilotOperationRepository _operations =
      SupabasePilotOperationRepository(client);

  SupabasePilotRemoteGateway(this.client);

  @override
  bool get isSignedIn => client.auth.currentUser != null;

  void _requireSession() {
    if (!isSignedIn) throw StateError('Se requiere autenticación remota.');
  }

  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
    _requireSession();
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<List<PilotInstitution>> institutions() async {
    _requireSession();
    final rows = await client
        .from('atena_pilot_institutions')
        .select('id,display_name');
    return rows
        .map(
          (r) =>
              PilotInstitution(r['id'] as String, r['display_name'] as String),
        )
        .toList(growable: false);
  }

  @override
  Future<List<PilotArea>> areas(String institutionId) async {
    _requireSession();
    final rows = await client
        .from('atena_pilot_areas')
        .select('id,display_name')
        .eq('institution_id', institutionId);
    return rows
        .map((r) => PilotArea(r['id'] as String, r['display_name'] as String))
        .toList(growable: false);
  }

  @override
  Future<List<PilotAssignment>> assignments() async {
    _requireSession();
    final userId = client.auth.currentUser!.id;
    final operators = await client
        .from('atena_pilot_operators')
        .select('institution_id,id')
        .eq('auth_user_id', userId);
    final result = <PilotAssignment>[];
    for (final operator in operators) {
      final institutionId = operator['institution_id'] as String;
      final operatorId = operator['id'] as String;
      final rows = await client
          .from('atena_pilot_assignments')
          .select('institution_id,area_id,operator_id,capabilities')
          .eq('institution_id', institutionId)
          .eq('operator_id', operatorId);
      for (final row in rows) {
        result.add(
          PilotAssignment(
            institutionId: row['institution_id'] as String,
            areaId: row['area_id'] as String,
            operatorId: row['operator_id'] as String,
            capabilities: List<String>.from(row['capabilities'] as List),
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<String> recordNote({
    required String institutionId,
    required String areaId,
    required String operatorId,
    required String resourceId,
    required String note,
  }) => _operations.recordNote(
    institutionId: institutionId,
    areaId: areaId,
    operatorId: operatorId,
    resourceId: resourceId,
    note: note,
  );

  @override
  Future<List<PilotOperation>> notes(String institutionId, String areaId) =>
      _operations.listNotes(institutionId: institutionId, areaId: areaId);
}
