import 'multiuser_session.dart';

/// Transport for the existing institutional emissions/calendar/inbox contract.
/// Server RPCs revalidate scope and enrollment; no local persistence fallback.
class EmisionesSupabaseRepository {
  final MultiuserSession session;
  EmisionesSupabaseRepository(this.session);

  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    final identity = session.userId;
    if (identity.isEmpty) throw StateError('Ingresá con tu cuenta remota.');
    final value = await session.client.rpc(name, params: params);
    if (session.userId != identity) throw StateError('La sesión cambió.');
    return value;
  }

  Future<void> _profile(String profile) async {
    if (!(await session.context()).profiles.contains(profile)) {
      throw StateError('Perfil no autorizado.');
    }
  }

  Future<List<Map<String, dynamic>>> enrollments(
    String institution,
    String area,
  ) async {
    final contexts = (await session.context()).institutions.where(
      (c) =>
          c.institutionId == institution &&
          c.areaId == area &&
          (c.capabilities.contains('calendar.write') ||
              c.capabilities.contains('communications.write')),
    );
    if (contexts.length != 1) throw StateError('Área no autorizada.');
    return _rows(
      await _rpc('atena_emission_enrollments', {
        'p_institution': institution,
        'p_area': area,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> student(
    String profile, {
    bool calendar = true,
  }) async {
    await _profile(profile);
    return _rows(
      await _rpc('atena_emissions_student', {
        'p_profile': profile,
        'p_kind': calendar ? 'calendar' : 'communication',
      }),
    );
  }

  Future<Map<String, dynamic>> save({
    required String institution,
    required String area,
    required String id,
    required String operation,
    required String kind,
    required String title,
    required String body,
    required List<String> requests,
    int revision = 0,
    String? group,
    DateTime? start,
    DateTime? end,
    String special = 'otro',
    String rsvp = 'none',
    bool active = true,
  }) async {
    await session.institution(
      institution,
      area,
      kind == 'calendar' ? 'calendar.write' : 'communications.write',
    );
    return Map<String, dynamic>.from(
      await _rpc('atena_emission_save', {
        'p_institution': institution,
        'p_area': area,
        'p_id': id,
        'p_operation': operation,
        'p_revision': revision,
        'p_kind': kind,
        'p_title': title,
        'p_body': body,
        'p_requests': requests,
        'p_group': group,
        'p_start': start?.toIso8601String(),
        'p_end': end?.toIso8601String(),
        'p_special': special,
        'p_rsvp': rsvp,
        'p_active': active,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> institutional(
    String institution,
    String area, {
    bool calendar = true,
  }) async {
    await session.institution(
      institution,
      area,
      calendar ? 'calendar.write' : 'communications.write',
    );
    return _rows(
      await _rpc('atena_emissions_institution', {
        'p_institution': institution,
        'p_area': area,
        'p_kind': calendar ? 'calendar' : 'communication',
      }),
    );
  }

  Future<Map<String, dynamic>?> respond(
    String profile,
    String id,
    String status,
  ) async {
    await _profile(profile);
    await _rpc('atena_emission_respond', {
      'p_profile': profile,
      'p_id': id,
      'p_status': status,
    });
    return (await student(profile)).where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> inboxState(
    String profile,
    String id, {
    required bool read,
    bool hidden = false,
  }) async {
    await _profile(profile);
    await _rpc('atena_emission_inbox_state', {
      'p_profile': profile,
      'p_id': id,
      'p_read': read,
      'p_hidden': hidden,
    });
  }

  Future<List<Map<String, dynamic>>> responses(
    String institution,
    String area,
  ) async {
    await session.institution(institution, area, 'responses.read');
    return _rows(
      await _rpc('atena_emission_responses', {
        'p_institution': institution,
        'p_area': area,
      }),
    );
  }

  static List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}
