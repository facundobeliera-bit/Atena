import 'institution_onboarding.dart';

/// Reuses Supabase identity and the existing reviewers; never edits Auth users.
class IdentityRectification extends InstitutionOnboarding {
  IdentityRectification(super.session);
  @override
  Future<Map<String, dynamic>> state() =>
      request('atena_identity_correction_state');
  @override
  Future<Map<String, dynamic>> command(
    String action,
    Map<String, dynamic> data,
  ) => request('atena_identity_correction_command', {
    'p_action': action,
    'p_data': data,
  });
  @override
  Future<Map<String, dynamic>> request(
    String rpc, [
    Map<String, dynamic>? params,
  ]) {
    if (!session.essentialOperationsReady) {
      throw StateError(
        'La rectificación todavía no está habilitada en este entorno.',
      );
    }
    return super.request(rpc, params);
  }
}
